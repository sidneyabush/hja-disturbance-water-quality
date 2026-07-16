# =============================================================================
# 2d: Build flood and high-flow drivers from HF004 discharge
# =============================================================================
# Creates compact, analysis-ready hydrologic disturbance drivers for the
# temporal-lag manuscript. The primary event isolated here is the February 1996
# flood, with annual peak/high-flow metrics retained for broader screening.
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

first_existing <- function(paths, label) {
  path <- paths[file.exists(paths)][1]
  if (is.na(path)) {
    stop("Missing ", label, ": tried ", paste(paths, collapse = ", "))
  }
  path
}

parse_hja_date <- function(x) {
  suppressWarnings(as.Date(x))
}

safe_num <- function(x) {
  cleaned <- gsub("[^0-9eE+.-]", "", as.character(x))
  cleaned <- ifelse(cleaned == "", NA_character_, cleaned)
  suppressWarnings(as.numeric(cleaned))
}

repo_dir <- find_repo_root(get_script_dir())
source(file.path(repo_dir, "00_helpers", "workflow_config.R"))
source(file.path(repo_dir, "00_helpers", "plot_prefs.R"))
theme_file <- file.path(repo_dir, "00_helpers", "plot_theme_set.R")
if (file.exists(theme_file)) source(theme_file)

paths <- get_project_paths()
res_dir <- file.path(paths$out_dir, "02_disturbance_time_change", "flood_high_flow_drivers")
fig_dir <- file.path(paths$fig_root, "02_disturbance_time_change", "flood_high_flow_drivers")
dir.create(res_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_driver <- function(base_size = 11) {
  if (exists("theme_hja")) {
    theme_hja(base_size = base_size)
  } else {
    theme_bw(base_size = base_size) +
      theme(panel.grid = element_blank())
  }
}

hf004_file <- first_existing(
  file.path(paths$raw_dir, c("HF00402_v15.csv", "HF00402_v14.csv")),
  "HF004 daily discharge file"
)

catchment_file <- file.path(
  paths$data_dir,
  "storage_paper_framework",
  "storage_paper_catchment_char.csv"
)

annual_chem_anomaly_file <- file.path(
  paths$out_dir,
  "02_disturbance_time_change",
  "annual_chemistry_baseline_anomalies.csv"
)

catchment_area <- if (file.exists(catchment_file)) {
  readr::read_csv(catchment_file, show_col_types = FALSE) %>%
    transmute(
      Stream_Name = standardize_wq_stream(Site),
      site = standardize_storage_site(Stream_Name),
      catchment_area_km2 = safe_num(Area_km2)
    ) %>%
    distinct(Stream_Name, .keep_all = TRUE)
} else {
  warning("Missing catchment file; specific peak flow will be NA: ", catchment_file)
  tibble(Stream_Name = character(), site = character(), catchment_area_km2 = numeric())
}

q_cfs_to_cms <- 0.028316846592
min_days_per_wy <- 300L
threshold_start_wy <- 1997L
threshold_end_wy <- 2020L

discharge_daily <- readr::read_csv(hf004_file, show_col_types = FALSE) %>%
  transmute(
    Stream_Name_raw = as.character(SITECODE),
    Stream_Name = case_when(
      Stream_Name_raw == "GSLOOK_FULL" ~ "GSLOOK",
      Stream_Name_raw %in% c("GSWSMC", "GSWSMC_FULL") ~ "GSMACK",
      TRUE ~ Stream_Name_raw
    ),
    date = parse_hja_date(DATE),
    water_year = as.integer(WATERYEAR),
    mean_q_cfs = safe_num(MEAN_Q),
    max_q_cfs = safe_num(MAX_Q),
    min_q_cfs = safe_num(MIN_Q),
    mean_q_area_mm_day = safe_num(MEAN_Q_AREA),
    estcode = as.character(ESTCODE)
  ) %>%
  mutate(
    mean_q_cms = mean_q_cfs * q_cfs_to_cms,
    max_q_cms = max_q_cfs * q_cfs_to_cms,
    month = month(date),
    site = standardize_storage_site(Stream_Name)
  ) %>%
  filter(!is.na(Stream_Name), !is.na(date), is.finite(mean_q_cms))

wq_discharge_daily <- discharge_daily %>%
  filter(Stream_Name %in% site_order)

thresholds <- wq_discharge_daily %>%
  filter(water_year >= threshold_start_wy, water_year <= threshold_end_wy) %>%
  group_by(Stream_Name, site) %>%
  summarise(
    q95_daily_cms = as.numeric(quantile(mean_q_cms, 0.95, na.rm = TRUE)),
    q99_daily_cms = as.numeric(quantile(mean_q_cms, 0.99, na.rm = TRUE)),
    q95_daily_mm_day = as.numeric(quantile(mean_q_area_mm_day, 0.95, na.rm = TRUE)),
    q99_daily_mm_day = as.numeric(quantile(mean_q_area_mm_day, 0.99, na.rm = TRUE)),
    threshold_start_wy = threshold_start_wy,
    threshold_end_wy = threshold_end_wy,
    .groups = "drop"
  )

annual_high_flow <- wq_discharge_daily %>%
  left_join(thresholds, by = c("Stream_Name", "site")) %>%
  group_by(Stream_Name, site, water_year) %>%
  summarise(
    n_days = n_distinct(date),
    first_date = min(date, na.rm = TRUE),
    last_date = max(date, na.rm = TRUE),
    peak_daily_q_cfs = max(mean_q_cfs, na.rm = TRUE),
    peak_daily_q_cms = max(mean_q_cms, na.rm = TRUE),
    peak_daily_q_area_mm_day = max(mean_q_area_mm_day, na.rm = TRUE),
    peak_daily_q_date = date[which.max(mean_q_cms)][1],
    annual_mean_q_cms = mean(mean_q_cms, na.rm = TRUE),
    annual_median_q_cms = median(mean_q_cms, na.rm = TRUE),
    days_ge_q95 = sum(mean_q_cms >= q95_daily_cms[1], na.rm = TRUE),
    days_ge_q99 = sum(mean_q_cms >= q99_daily_cms[1], na.rm = TRUE),
    q95_daily_cms = q95_daily_cms[1],
    q99_daily_cms = q99_daily_cms[1],
    q95_daily_mm_day = q95_daily_mm_day[1],
    q99_daily_mm_day = q99_daily_mm_day[1],
    threshold_start_wy = threshold_start_wy[1],
    threshold_end_wy = threshold_end_wy[1],
    .groups = "drop"
  ) %>%
  filter(n_days >= min_days_per_wy) %>%
  left_join(catchment_area, by = c("Stream_Name", "site")) %>%
  group_by(Stream_Name, site) %>%
  arrange(desc(peak_daily_q_cms), .by_group = TRUE) %>%
  mutate(
    peak_flow_rank_desc = row_number(),
    n_ranked_water_years = n(),
    empirical_peak_exceedance_probability = peak_flow_rank_desc / (n_ranked_water_years + 1),
    empirical_peak_recurrence_years = (n_ranked_water_years + 1) / peak_flow_rank_desc,
    peak_specific_q_cms_per_km2 = peak_daily_q_cms / catchment_area_km2,
    high_flow_driver_available = TRUE,
    flood_1996_event = water_year == 1996L,
    top5_peak_year = peak_flow_rank_desc <= 5L,
    event_label = if_else(flood_1996_event, "February 1996 flood", NA_character_)
  ) %>%
  ungroup() %>%
  arrange(Stream_Name, water_year)

readr::write_csv(
  annual_high_flow,
  file.path(res_dir, "hf004_annual_high_flow_drivers.csv")
)

flood_1996_event_window <- wq_discharge_daily %>%
  filter(date >= as.Date("1996-02-01"), date <= as.Date("1996-02-29")) %>%
  left_join(thresholds, by = c("Stream_Name", "site")) %>%
  left_join(catchment_area, by = c("Stream_Name", "site")) %>%
  group_by(Stream_Name, site) %>%
  summarise(
    n_event_window_days = n_distinct(date),
    event_peak_daily_q_date = date[which.max(mean_q_cms)][1],
    event_peak_daily_q_cms = max(mean_q_cms, na.rm = TRUE),
    event_peak_daily_q_cfs = max(mean_q_cfs, na.rm = TRUE),
    event_peak_daily_q_area_mm_day = max(mean_q_area_mm_day, na.rm = TRUE),
    event_days_ge_q95 = sum(mean_q_cms >= q95_daily_cms[1], na.rm = TRUE),
    event_days_ge_q99 = sum(mean_q_cms >= q99_daily_cms[1], na.rm = TRUE),
    q95_daily_cms = q95_daily_cms[1],
    q99_daily_cms = q99_daily_cms[1],
    catchment_area_km2 = catchment_area_km2[1],
    .groups = "drop"
  ) %>%
  mutate(
    event_peak_specific_q_cms_per_km2 = event_peak_daily_q_cms / catchment_area_km2
  )

flood_1996_summary <- flood_1996_event_window %>%
  left_join(
    annual_high_flow %>%
      filter(water_year == 1996L) %>%
      select(
        Stream_Name,
        complete_wy_n_days = n_days,
        wy1996_peak_daily_q_date = peak_daily_q_date,
        wy1996_peak_daily_q_cms = peak_daily_q_cms,
        wy1996_days_ge_q95 = days_ge_q95,
        wy1996_days_ge_q99 = days_ge_q99,
        peak_flow_rank_desc,
        n_ranked_water_years,
        empirical_peak_recurrence_years
      ),
    by = "Stream_Name"
  ) %>%
  transmute(
    Stream_Name,
    site,
    event_id = "february_1996_flood",
    event_name = "February 1996 flood",
    disturbance_type = "flood",
    water_year = 1996L,
    event_window_start = as.Date("1996-02-01"),
    event_window_end = as.Date("1996-02-29"),
    n_event_window_days,
    peak_daily_q_date = event_peak_daily_q_date,
    peak_daily_q_cms = event_peak_daily_q_cms,
    peak_daily_q_cfs = event_peak_daily_q_cfs,
    peak_daily_q_area_mm_day = event_peak_daily_q_area_mm_day,
    peak_specific_q_cms_per_km2 = event_peak_specific_q_cms_per_km2,
    days_ge_q95 = event_days_ge_q95,
    days_ge_q99 = event_days_ge_q99,
    complete_water_year_available = !is.na(complete_wy_n_days),
    complete_wy_n_days,
    wy1996_peak_daily_q_date,
    wy1996_peak_daily_q_cms,
    wy1996_days_ge_q95,
    wy1996_days_ge_q99,
    peak_flow_rank_desc,
    n_ranked_water_years,
    empirical_peak_recurrence_years,
    source_dataset = "HF004",
    source_file = hf004_file,
    source_note = paste(
      "Daily discharge-derived February 1996 flood streamflow metric.",
      "Use as a hydrologic-event driver, not a mapped geomorphic disturbance layer."
    )
  ) %>%
  arrange(is.na(peak_flow_rank_desc), peak_flow_rank_desc, Stream_Name)

readr::write_csv(
  flood_1996_summary,
  file.path(res_dir, "hf004_1996_flood_site_summary.csv")
)

if (file.exists(annual_chem_anomaly_file)) {
  flood_1996_chemistry_lag_panel <- readr::read_csv(annual_chem_anomaly_file, show_col_types = FALSE) %>%
    mutate(
      Stream_Name = standardize_wq_stream(Stream_Name),
      site = standardize_storage_site(Stream_Name),
      water_year = as.integer(water_year),
      years_since_1996_flood = water_year - 1996L,
      flood_1996_window = case_when(
        water_year < 1996L ~ "pre_1996_flood",
        water_year == 1996L ~ "flood_water_year",
        water_year >= 1997L & water_year <= 2000L ~ "early_post_1996_flood",
        water_year >= 2001L & water_year <= 2005L ~ "late_post_1996_flood",
        TRUE ~ "outside_1996_lag_window"
      )
    ) %>%
    filter(water_year >= 1990L, water_year <= 2005L) %>%
    left_join(
      flood_1996_summary %>%
        select(
          Stream_Name,
          flood_1996_peak_daily_q_cms = peak_daily_q_cms,
          flood_1996_peak_daily_q_area_mm_day = peak_daily_q_area_mm_day,
          flood_1996_peak_flow_rank_desc = peak_flow_rank_desc,
          flood_1996_recurrence_years = empirical_peak_recurrence_years
        ),
      by = "Stream_Name"
    ) %>%
    arrange(Stream_Name, variable, water_year)

  readr::write_csv(
    flood_1996_chemistry_lag_panel,
    file.path(res_dir, "hf004_1996_flood_chemistry_lag_panel.csv")
  )
} else {
  warning("Missing chemistry anomaly file; skipped 1996 flood chemistry lag panel: ", annual_chem_anomaly_file)
}

plot_daily <- wq_discharge_daily %>%
  filter(date >= as.Date("1996-01-01"), date <= as.Date("1996-03-31")) %>%
  mutate(Stream_Name = factor(Stream_Name, levels = site_order))

if (nrow(plot_daily) > 0) {
  p_1996 <- ggplot(plot_daily, aes(x = date, y = mean_q_area_mm_day, color = Stream_Name)) +
    geom_vline(xintercept = as.Date(c("1996-02-01", "1996-02-29")), color = "grey75", linewidth = 0.35) +
    geom_line(linewidth = 0.5, alpha = 0.88) +
    facet_wrap(~ Stream_Name, scales = "free_y", ncol = 2) +
    scale_color_site(name = NULL, drop = FALSE) +
    labs(
      x = NULL,
      y = "Daily discharge (mm/day)",
      title = "February 1996 flood hydrograph window",
      subtitle = "HF004 daily discharge, water-quality gages"
    ) +
    theme_driver(base_size = 10) +
    theme(legend.position = "none")

  ggsave(
    file.path(fig_dir, "hf004_1996_flood_hydrograph.png"),
    p_1996,
    width = 8.5,
    height = 10,
    dpi = 300,
    bg = "white"
  )
}

manifest <- tibble::tribble(
  ~file, ~description,
  "hf004_annual_high_flow_drivers.csv",
  "Annual high-flow driver table by water-quality site from HF004 daily discharge.",
  "hf004_1996_flood_site_summary.csv",
  "Compact February 1996 flood event summary by water-quality site.",
  "hf004_1996_flood_chemistry_lag_panel.csv",
  "Chemistry anomaly panel restricted to WY1990-2005 with 1996 flood lag fields.",
  "hf004_1996_flood_hydrograph.png",
  "Diagnostic hydrograph for Jan-Mar 1996 at water-quality gages."
)

readr::write_csv(manifest, file.path(res_dir, "flood_high_flow_driver_manifest.csv"))

message("Flood/high-flow driver outputs written to: ", res_dir)
message("Flood/high-flow figures written to: ", fig_dir)
