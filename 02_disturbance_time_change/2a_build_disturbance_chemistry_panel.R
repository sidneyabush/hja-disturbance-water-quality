# =============================================================================
# 2a: Temporal lag disturbance-response chemistry panel
# =============================================================================
# Uses the full discrete chemistry record to build annual site-solute chemistry
# summaries, baseline anomalies, trend screens, and disturbance-era summaries.
# This base step writes only compact inputs needed by downstream synthesis.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
})

rm(list = ls())

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_flag <- "--file="
  matches <- grep(file_flag, cmd_args)
  if (length(matches) > 0) {
    script_path <- sub(file_flag, "", cmd_args[matches[1]])
    return(dirname(normalizePath(script_path)))
  }
  normalizePath(getwd())
}

find_repo_root <- function(start_dir) {
  current <- normalizePath(start_dir)
  repeat {
    if (dir.exists(file.path(current, "00_helpers")) || dir.exists(file.path(current, ".git"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Unable to locate project root from: ", start_dir)
    }
    current <- parent
  }
}

repo_dir <- find_repo_root(get_script_dir())
source(file.path(repo_dir, "00_helpers", "workflow_config.R"))
source(file.path(repo_dir, "00_helpers", "plot_prefs.R"))

paths <- get_project_paths()
out_dir <- paths$out_dir
res_dir <- file.path(out_dir, "02_disturbance_time_change")
dir.create(res_dir, recursive = TRUE, showWarnings = FALSE)

chem_file <- file.path(out_dir, "HJA_CQ_master.csv")
if (!file.exists(chem_file)) {
  stop("Missing chemistry master file: ", chem_file, "\nRun 01_data_prep/1a_build_chemistry_master.R first.")
}

baseline_start_wy <- 1997L
baseline_end_wy <- 2020L
min_annual_samples <- 3L

disturbance_events <- tibble::tribble(
  ~event_id, ~event_name, ~disturbance_type, ~calendar_year, ~first_full_water_year, ~analysis_role, ~notes,
  "holiday_farm_fire_2020", "Holiday Farm Fire", "wildfire", 2020L, 2021L,
  "Pre/post wildfire contrast to review",
  "Use site-level burn severity or burned-area fractions before treating sites as affected.",
  "lookout_fire_2023", "Lookout Fire", "wildfire", 2023L, 2024L,
  "Emerging post-fire contrast",
  "Chemistry record currently provides early post-fire years only; treat as exploratory until more years accrue.",
  "landslide_inventory", "Mapped landslide disturbances", "landslide", NA_integer_, NA_integer_,
  "Future disturbance table",
  "Attach dated landslide inventory or landslide-area fractions before formal modeling.",
  "large_flood_inventory", "Large flood events", "flood", NA_integer_, NA_integer_,
  "Future event layer",
  "Attach flood years or hydrologic-event indicators before formal modeling."
)

readr::write_csv(disturbance_events, file.path(res_dir, "disturbance_event_framework.csv"))

chem <- readr::read_csv(chem_file, show_col_types = FALSE) %>%
  mutate(
    Stream_Name = standardize_wq_stream(Stream_Name),
    site = standardize_storage_site(Stream_Name),
    Date = as.Date(Date),
    water_year = if_else(lubridate::month(Date) >= 10L, lubridate::year(Date) + 1L, lubridate::year(Date)),
    variable = as.character(variable),
    value = suppressWarnings(as.numeric(value)),
    Q_cms = suppressWarnings(as.numeric(Q_cms))
  ) %>%
  filter(
    !is.na(Stream_Name),
    !is.na(water_year),
    variable %in% solute_order,
    is.finite(value),
    value > 0
  )

annual_chem <- chem %>%
  group_by(Stream_Name, site, water_year, variable, units) %>%
  summarise(
    mean_conc = mean(value, na.rm = TRUE),
    median_conc = median(value, na.rm = TRUE),
    mean_log10_conc = mean(log10(value), na.rm = TRUE),
    median_log10_conc = median(log10(value), na.rm = TRUE),
    n_samples = n(),
    first_sample_date = min(Date, na.rm = TRUE),
    last_sample_date = max(Date, na.rm = TRUE),
    median_Q_cms = median(Q_cms, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    median_Q_cms = ifelse(is.nan(median_Q_cms), NA_real_, median_Q_cms),
    disturbance_era = case_when(
      water_year < baseline_start_wy ~ "Historic pre-baseline",
      water_year <= baseline_end_wy ~ "Storage-paper baseline",
      water_year >= 2021L & water_year <= 2023L ~ "Post-Holiday Farm Fire",
      water_year >= 2024L ~ "Post-Lookout Fire / recent",
      TRUE ~ "Other"
    ),
    disturbance_era = factor(
      disturbance_era,
      levels = c(
        "Historic pre-baseline",
        "Storage-paper baseline",
        "Post-Holiday Farm Fire",
        "Post-Lookout Fire / recent",
        "Other"
      )
    )
  ) %>%
  arrange(Stream_Name, variable, water_year)

baseline <- annual_chem %>%
  filter(
    water_year >= baseline_start_wy,
    water_year <= baseline_end_wy,
    n_samples >= min_annual_samples
  ) %>%
  group_by(Stream_Name, site, variable) %>%
  summarise(
    baseline_mean_log10 = mean(mean_log10_conc, na.rm = TRUE),
    baseline_sd_log10 = sd(mean_log10_conc, na.rm = TRUE),
    baseline_n_years = n_distinct(water_year),
    .groups = "drop"
  )

annual_anomalies <- annual_chem %>%
  left_join(baseline, by = c("Stream_Name", "site", "variable")) %>%
  mutate(
    log10_anomaly = mean_log10_conc - baseline_mean_log10,
    z_anomaly = ifelse(is.finite(baseline_sd_log10) & baseline_sd_log10 > 0, log10_anomaly / baseline_sd_log10, NA_real_),
    sample_weight = pmin(n_samples / min_annual_samples, 1)
  )

readr::write_csv(annual_anomalies, file.path(res_dir, "annual_chemistry_baseline_anomalies.csv"))

coverage_summary <- annual_chem %>%
  group_by(Stream_Name, site, variable) %>%
  summarise(
    first_water_year = min(water_year, na.rm = TRUE),
    last_water_year = max(water_year, na.rm = TRUE),
    n_water_years = n_distinct(water_year),
    n_annual_values = n(),
    n_values_after_2020 = sum(water_year >= 2021L),
    .groups = "drop"
  ) %>%
  arrange(Stream_Name, variable)

readr::write_csv(coverage_summary, file.path(res_dir, "full_record_chemistry_coverage.csv"))

fit_linear_trend <- function(df) {
  idx <- is.finite(df$water_year) & is.finite(df$mean_log10_conc)
  if (sum(idx) < 10 || sd(df$mean_log10_conc[idx]) == 0) {
    return(tibble(n_years = sum(idx), slope_log10_per_year = NA_real_, p = NA_real_, r2 = NA_real_))
  }
  fit <- lm(mean_log10_conc ~ water_year, data = df[idx, , drop = FALSE])
  fit_sum <- summary(fit)
  tibble(
    n_years = sum(idx),
    slope_log10_per_year = unname(coef(fit)[["water_year"]]),
    p = fit_sum$coefficients["water_year", "Pr(>|t|)"],
    r2 = fit_sum$r.squared
  )
}

trend_screen <- annual_chem %>%
  filter(n_samples >= min_annual_samples) %>%
  group_by(Stream_Name, site, variable) %>%
  group_modify(~ fit_linear_trend(.x)) %>%
  ungroup() %>%
  arrange(p, desc(abs(slope_log10_per_year)))

readr::write_csv(trend_screen, file.path(res_dir, "annual_chemistry_linear_trend_screen.csv"))

era_summary <- annual_anomalies %>%
  filter(n_samples >= min_annual_samples) %>%
  group_by(variable, disturbance_era) %>%
  summarise(
    n_site_years = n(),
    n_sites = n_distinct(Stream_Name),
    mean_log10_anomaly = mean(log10_anomaly, na.rm = TRUE),
    median_log10_anomaly = median(log10_anomaly, na.rm = TRUE),
    mean_z_anomaly = mean(z_anomaly, na.rm = TRUE),
    median_z_anomaly = median(z_anomaly, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(variable, disturbance_era)

readr::write_csv(era_summary, file.path(res_dir, "disturbance_era_chemistry_anomaly_summary.csv"))

message("Temporal lag disturbance-response tables written to: ", res_dir)
