#!/usr/bin/env Rscript
# =============================================================================
# 7b: Synthesize temporal lag disturbance-response screening results
# =============================================================================
# Converts full-record chemistry trajectories, baseline anomalies, and trend
# screens into manuscript-facing screening tables, figures, and a short analysis
# brief. This is descriptive until disturbance exposure layers are filled.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
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
theme_file <- file.path(repo_dir, "00_helpers", "plot_theme_set.R")
if (file.exists(theme_file)) source(theme_file)

paths <- get_project_paths()
base_res_dir <- file.path(paths$out_dir, "07_disturbance_time_change")
base_fig_dir <- file.path(paths$fig_root, "07_disturbance_time_change")
synth_dir <- file.path(base_res_dir, "temporal_lag_synthesis")
synth_fig_dir <- file.path(base_fig_dir, "temporal_lag_synthesis")
dir.create(synth_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(synth_fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_synthesis <- function(base_size = 11) {
  if (exists("theme_hja")) {
    theme_hja(base_size = base_size)
  } else {
    theme_bw(base_size = base_size) +
      theme(panel.grid = element_blank())
  }
}

require_file <- function(path) {
  if (!file.exists(path)) {
    stop("Missing required temporal lag input: ", path, "\nRun 7a_build_disturbance_chemistry_panel.R first.")
  }
  path
}

finite_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  mean(x)
}

finite_median <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  median(x)
}

finite_max_abs <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  max(abs(x))
}

percent_from_log10 <- function(x) {
  (10^x - 1) * 100
}

format_markdown_table <- function(df, digits = 2) {
  if (nrow(df) == 0) return("_No rows._")
  df_fmt <- df %>%
    mutate(across(where(is.numeric), ~ ifelse(is.na(.x), "", formatC(.x, digits = digits, format = "f")))) %>%
    mutate(across(everything(), ~ ifelse(is.na(.x), "", as.character(.x))))

  header <- paste0("| ", paste(names(df_fmt), collapse = " | "), " |")
  separator <- paste0("| ", paste(rep("---", ncol(df_fmt)), collapse = " | "), " |")
  rows <- apply(df_fmt, 1, function(x) paste0("| ", paste(x, collapse = " | "), " |"))
  c(header, separator, rows)
}

annual_anomalies <- readr::read_csv(
  require_file(file.path(base_res_dir, "annual_chemistry_baseline_anomalies.csv")),
  show_col_types = FALSE
)

trend_screen <- readr::read_csv(
  require_file(file.path(base_res_dir, "annual_chemistry_linear_trend_screen.csv")),
  show_col_types = FALSE
)

era_summary <- readr::read_csv(
  require_file(file.path(base_res_dir, "disturbance_era_chemistry_anomaly_summary.csv")),
  show_col_types = FALSE
)

coverage_summary <- readr::read_csv(
  require_file(file.path(base_res_dir, "full_record_chemistry_coverage.csv")),
  show_col_types = FALSE
)

trend_ranked <- trend_screen %>%
  mutate(
    q = p.adjust(p, method = "BH"),
    slope_log10_per_decade = slope_log10_per_year * 10,
    percent_change_per_decade = percent_from_log10(slope_log10_per_decade),
    abs_percent_change_per_decade = abs(percent_change_per_decade),
    trend_direction = case_when(
      percent_change_per_decade > 0 ~ "increasing",
      percent_change_per_decade < 0 ~ "decreasing",
      TRUE ~ "flat"
    )
  ) %>%
  add_solute_type(solute_col = "variable", three_way = TRUE) %>%
  left_join(coverage_summary, by = c("Stream_Name", "site", "variable")) %>%
  arrange(q, desc(abs_percent_change_per_decade))

readr::write_csv(
  trend_ranked,
  file.path(synth_dir, "temporal_lag_long_term_trend_screen_ranked.csv")
)

post_era_levels <- c("Post-Holiday Farm Fire", "Post-Lookout Fire / recent")

post_era_signals <- era_summary %>%
  filter(disturbance_era %in% post_era_levels) %>%
  mutate(
    disturbance_era = factor(disturbance_era, levels = post_era_levels),
    percent_departure_from_baseline = percent_from_log10(mean_log10_anomaly),
    abs_percent_departure_from_baseline = abs(percent_departure_from_baseline)
  ) %>%
  add_solute_type(solute_col = "variable", three_way = TRUE) %>%
  arrange(disturbance_era, desc(abs_percent_departure_from_baseline))

readr::write_csv(
  post_era_signals,
  file.path(synth_dir, "temporal_lag_post2020_era_signals.csv")
)

post_years <- annual_anomalies %>%
  filter(
    water_year >= 2021L,
    n_samples >= 3L,
    is.finite(log10_anomaly)
  ) %>%
  mutate(
    post_window = case_when(
      water_year >= 2021L & water_year <= 2023L ~ "Post-Holiday Farm Fire (WY2021-2023)",
      water_year >= 2024L ~ "Post-Lookout/recent (WY2024+)",
      TRUE ~ NA_character_
    ),
    post_window = factor(
      post_window,
      levels = c("Post-Holiday Farm Fire (WY2021-2023)", "Post-Lookout/recent (WY2024+)")
    )
  )

site_solute_post_window <- post_years %>%
  group_by(Stream_Name, site, variable, post_window) %>%
  summarise(
    n_post_years = n_distinct(water_year),
    first_post_water_year = min(water_year, na.rm = TRUE),
    last_post_water_year = max(water_year, na.rm = TRUE),
    mean_log10_anomaly = finite_mean(log10_anomaly),
    median_log10_anomaly = finite_median(log10_anomaly),
    max_abs_log10_anomaly = finite_max_abs(log10_anomaly),
    mean_z_anomaly = finite_mean(z_anomaly),
    max_abs_z_anomaly = finite_max_abs(z_anomaly),
    mean_percent_departure = percent_from_log10(mean_log10_anomaly),
    peak_water_year = water_year[which.max(abs(log10_anomaly))][1],
    peak_log10_anomaly = log10_anomaly[which.max(abs(log10_anomaly))][1],
    .groups = "drop"
  ) %>%
  add_solute_type(solute_col = "variable", three_way = TRUE) %>%
  mutate(
    candidate_signal = case_when(
      abs(mean_log10_anomaly) >= 0.30 ~ "large mean anomaly",
      abs(mean_log10_anomaly) >= 0.10 ~ "moderate mean anomaly",
      is.finite(mean_z_anomaly) & abs(mean_z_anomaly) >= 2 ~ "large standardized anomaly",
      is.finite(mean_z_anomaly) & abs(mean_z_anomaly) >= 1 ~ "moderate standardized anomaly",
      TRUE ~ "screening background"
    )
  ) %>%
  arrange(post_window, desc(abs(mean_log10_anomaly)), desc(max_abs_log10_anomaly))

site_solute_post_all <- post_years %>%
  group_by(Stream_Name, site, variable) %>%
  summarise(
    n_post_years = n_distinct(water_year),
    first_post_water_year = min(water_year, na.rm = TRUE),
    last_post_water_year = max(water_year, na.rm = TRUE),
    mean_log10_anomaly = finite_mean(log10_anomaly),
    median_log10_anomaly = finite_median(log10_anomaly),
    max_abs_log10_anomaly = finite_max_abs(log10_anomaly),
    mean_z_anomaly = finite_mean(z_anomaly),
    max_abs_z_anomaly = finite_max_abs(z_anomaly),
    mean_percent_departure = percent_from_log10(mean_log10_anomaly),
    peak_water_year = water_year[which.max(abs(log10_anomaly))][1],
    peak_log10_anomaly = log10_anomaly[which.max(abs(log10_anomaly))][1],
    .groups = "drop"
  ) %>%
  add_solute_type(solute_col = "variable", three_way = TRUE) %>%
  arrange(desc(abs(mean_log10_anomaly)), desc(max_abs_log10_anomaly))

candidate_site_solute_signals <- site_solute_post_window %>%
  filter(candidate_signal != "screening background") %>%
  arrange(desc(abs(mean_log10_anomaly)), desc(max_abs_log10_anomaly))

readr::write_csv(
  candidate_site_solute_signals,
  file.path(synth_dir, "temporal_lag_candidate_site_solute_signals.csv")
)

top_trends_for_memo <- trend_ranked %>%
  filter(is.finite(q)) %>%
  select(Stream_Name, variable, solute_type, n_years, percent_change_per_decade, q, r2) %>%
  slice_head(n = 12)

top_era_for_memo <- post_era_signals %>%
  group_by(disturbance_era) %>%
  slice_max(order_by = abs_percent_departure_from_baseline, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  select(disturbance_era, variable, solute_type, n_sites, mean_log10_anomaly, percent_departure_from_baseline)

top_site_for_memo <- candidate_site_solute_signals %>%
  select(Stream_Name, variable, post_window, candidate_signal, n_post_years, mean_log10_anomaly, mean_percent_departure, peak_water_year) %>%
  slice_head(n = 15)

memo_lines <- c(
  "# Temporal Lag Disturbance-Response Analysis Brief",
  "",
  paste0("Generated: ", Sys.Date()),
  "",
  "## Current Defensible Claim",
  "",
  "The full chemistry record supports a temporal-lag screening analysis: annual site-solute chemistry can be expressed as departures from the WY1997-2020 storage-paper baseline, then ranked by long-term trend strength and post-2020 anomaly magnitude. These are candidate signals, not causal disturbance effects, until wildfire, landslide, and flood exposure data are added.",
  "",
  "## Strongest Long-Term Site-Solute Trends",
  "",
  format_markdown_table(top_trends_for_memo, digits = 3),
  "",
  "## Largest Post-2020 Solute Departures",
  "",
  format_markdown_table(top_era_for_memo, digits = 2),
  "",
  "## Candidate Site-Solute Temporal Lag Signals",
  "",
  format_markdown_table(top_site_for_memo, digits = 2),
  "",
  "## Immediate Analysis Moves",
  "",
  "1. Fill watershed-level exposure for the 2020 Holiday Farm Fire and 2023 Lookout Fire.",
  "2. Add dated landslide and flood-event exposure indicators.",
  "3. Recast the candidate site-solute signals as event-study panels once exposure classes exist.",
  "4. Add updated post-2020 storage metrics or simpler hydrologic proxies before claiming storage change.",
  "5. Keep this temporal lag manuscript analytically separate from the WY1997-2020 storage-architecture paper."
)

writeLines(memo_lines, file.path(synth_dir, "temporal_lag_analysis_brief.md"))

era_order <- post_era_signals %>%
  group_by(variable) %>%
  summarise(max_abs = max(abs_percent_departure_from_baseline, na.rm = TRUE), .groups = "drop") %>%
  arrange(max_abs) %>%
  pull(variable)

p_era_rank <- post_era_signals %>%
  mutate(variable = factor(variable, levels = era_order)) %>%
  ggplot(aes(x = variable, y = percent_departure_from_baseline, fill = solute_type)) +
  geom_hline(yintercept = 0, color = "grey75", linewidth = 0.35) +
  geom_col(width = 0.72) +
  coord_flip() +
  facet_wrap(~ disturbance_era, ncol = 1) +
  scale_fill_manual(
    values = c("Geogenic" = "#5E8AA1", "Biogenic" = "#8A5A83", "Nutrient" = "#4F7F52"),
    name = NULL,
    drop = FALSE
  ) +
  labs(x = NULL, y = "Mean departure from WY1997-2020 baseline (%)") +
  theme_synthesis(base_size = 11) +
  theme(legend.position = "bottom")

ggsave(
  file.path(synth_fig_dir, "temporal_lag_post2020_solute_departures.png"),
  p_era_rank,
  width = 8.2,
  height = 7.2,
  dpi = PLOT_DPI,
  bg = "white"
)

site_levels <- rev(site_order[site_order %in% unique(site_solute_post_all$Stream_Name)])

p_site_heat <- site_solute_post_all %>%
  mutate(
    Stream_Name = factor(Stream_Name, levels = site_levels),
    variable = factor(variable, levels = solute_order)
  ) %>%
  ggplot(aes(x = variable, y = Stream_Name, fill = mean_log10_anomaly)) +
  geom_tile(color = "white", linewidth = 0.35) +
  geom_text(aes(label = sprintf("%+.2f", mean_log10_anomaly)), size = 2.5, color = "grey15") +
  scale_fill_gradient2(
    low = diverging_low_color,
    mid = diverging_mid_color,
    high = diverging_high_color,
    midpoint = 0,
    name = "Mean log10\nanomaly"
  ) +
  labs(x = "Solute", y = NULL) +
  theme_synthesis(base_size = 10.5) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave(
  file.path(synth_fig_dir, "temporal_lag_site_solute_post2020_heatmap.png"),
  p_site_heat,
  width = 9.2,
  height = 5.8,
  dpi = PLOT_DPI,
  bg = "white"
)

trend_site_levels <- rev(site_order[site_order %in% unique(trend_ranked$Stream_Name)])
trend_limit <- trend_ranked %>%
  summarise(limit = quantile(abs(percent_change_per_decade), probs = 0.95, na.rm = TRUE)) %>%
  pull(limit)

p_trend_heat <- trend_ranked %>%
  mutate(
    Stream_Name = factor(Stream_Name, levels = trend_site_levels),
    variable = factor(variable, levels = solute_order),
    plot_percent_change = pmax(pmin(percent_change_per_decade, trend_limit), -trend_limit)
  ) %>%
  ggplot(aes(x = variable, y = Stream_Name, fill = plot_percent_change)) +
  geom_tile(color = "white", linewidth = 0.35) +
  geom_text(aes(label = sprintf("%+.1f", percent_change_per_decade)), size = 2.35, color = "grey15") +
  scale_fill_gradient2(
    low = diverging_low_color,
    mid = diverging_mid_color,
    high = diverging_high_color,
    midpoint = 0,
    limits = c(-trend_limit, trend_limit),
    name = "% change\nper decade"
  ) +
  labs(x = "Solute", y = NULL) +
  theme_synthesis(base_size = 10.5) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave(
  file.path(synth_fig_dir, "temporal_lag_long_term_trend_heatmap.png"),
  p_trend_heat,
  width = 9.2,
  height = 5.8,
  dpi = PLOT_DPI,
  bg = "white"
)

manifest <- tibble::tribble(
  ~artifact, ~type, ~path, ~role,
  "temporal_lag_analysis_brief.md", "memo",
  file.path(synth_dir, "temporal_lag_analysis_brief.md"),
  "Manuscript-facing screening interpretation",
  "temporal_lag_long_term_trend_screen_ranked.csv", "table",
  file.path(synth_dir, "temporal_lag_long_term_trend_screen_ranked.csv"),
  "Ranked site-solute long-term trends",
  "temporal_lag_post2020_era_signals.csv", "table",
  file.path(synth_dir, "temporal_lag_post2020_era_signals.csv"),
  "Post-2020 era-level solute departures",
  "temporal_lag_candidate_site_solute_signals.csv", "table",
  file.path(synth_dir, "temporal_lag_candidate_site_solute_signals.csv"),
  "Candidate site-solute lag signals",
  "temporal_lag_post2020_solute_departures.png", "figure",
  file.path(synth_fig_dir, "temporal_lag_post2020_solute_departures.png"),
  "Post-2020 solute departure ranking",
  "temporal_lag_site_solute_post2020_heatmap.png", "figure",
  file.path(synth_fig_dir, "temporal_lag_site_solute_post2020_heatmap.png"),
  "Site-solute post-2020 anomaly heatmap",
  "temporal_lag_long_term_trend_heatmap.png", "figure",
  file.path(synth_fig_dir, "temporal_lag_long_term_trend_heatmap.png"),
  "Long-term site-solute trend heatmap"
) %>%
  mutate(exists = file.exists(path))

readr::write_csv(manifest, file.path(synth_dir, "temporal_lag_synthesis_manifest.csv"))

message("Temporal lag synthesis tables and memo written to: ", synth_dir)
message("Temporal lag synthesis figures written to: ", synth_fig_dir)
