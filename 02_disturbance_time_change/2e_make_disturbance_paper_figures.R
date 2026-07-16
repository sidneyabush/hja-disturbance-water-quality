# =============================================================================
# 2e: Prelim disturbance-paper figures
# =============================================================================
# Builds the first paper comparison figures from the temporal chemistry
# tables, Holiday Farm Fire watershed summaries, and February 1996 flood panel.
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
base_res_dir <- file.path(paths$out_dir, "02_disturbance_time_change")
base_fig_dir <- file.path(paths$fig_root, "02_disturbance_time_change")
res_dir <- file.path(base_res_dir, "prelim_paper_figures")
fig_dir <- file.path(base_fig_dir, "prelim_paper_figures")
dir.create(res_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_disturbance_fig <- function(base_size = 11) {
  if (exists("theme_hja")) {
    theme_hja(base_size = base_size)
  } else {
    theme_bw(base_size = base_size) +
      theme(panel.grid = element_blank())
  }
}

require_file <- function(path) {
  if (!file.exists(path)) {
    stop("Missing required disturbance figure input: ", path)
  }
  path
}

finite_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  mean(x)
}

finite_sd <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) <= 1) return(NA_real_)
  sd(x)
}

percent_from_log10 <- function(x) {
  (10^x - 1) * 100
}

hff_solutes <- c("NO3", "SO4", "DOC", "Ca", "Cl", "DSi")
flood_solutes <- c("NO3", "SO4", "Ca", "Mg", "Cl", "DSi")

annual_anomalies <- readr::read_csv(
  require_file(file.path(base_res_dir, "annual_chemistry_baseline_anomalies.csv")),
  show_col_types = FALSE
)

hff_watersheds <- readr::read_csv(
  require_file(file.path(
    base_res_dir,
    "disturbance_driver_audit",
    "holiday_farm_fire_2020_burned_area_by_wq_site.csv"
  )),
  show_col_types = FALSE
)

flood_lag_panel <- readr::read_csv(
  require_file(file.path(
    base_res_dir,
    "flood_high_flow_drivers",
    "hf004_1996_flood_chemistry_lag_panel.csv"
  )),
  show_col_types = FALSE
)

hff_site_summary <- annual_anomalies %>%
  filter(
    water_year >= 2021L,
    water_year <= 2023L,
    n_samples >= 3L,
    variable %in% hff_solutes,
    is.finite(log10_anomaly)
  ) %>%
  left_join(
    hff_watersheds %>%
      transmute(
        Stream_Name,
        mapped_fire_overlap_fraction,
        mortality_gt0_fraction,
        mortality_25plus_fraction,
        mortality_50plus_fraction,
        mortality_75plus_fraction,
        mean_ba_mortality_midpoint,
        burn_class = case_when(
          mortality_50plus_fraction >= 0.10 ~ "High burned",
          mortality_25plus_fraction >= 0.10 ~ "Moderate burned",
          mortality_gt0_fraction > 0 ~ "Low burned",
          TRUE ~ "No mapped HFF overlap"
        )
      ),
    by = "Stream_Name"
  ) %>%
  mutate(
    burn_class = replace_na(burn_class, "No mapped HFF overlap"),
    burn_class = factor(
      burn_class,
      levels = c("No mapped HFF overlap", "Low burned", "Moderate burned", "High burned")
    ),
    mortality_25plus_percent = 100 * replace_na(mortality_25plus_fraction, 0),
    mapped_fire_overlap_percent = 100 * replace_na(mapped_fire_overlap_fraction, 0),
    variable = factor(variable, levels = hff_solutes)
  ) %>%
  group_by(
    Stream_Name,
    site,
    variable,
    burn_class,
    mortality_25plus_percent,
    mapped_fire_overlap_percent,
    mortality_50plus_fraction,
    mortality_75plus_fraction,
    mean_ba_mortality_midpoint
  ) %>%
  summarise(
    first_post_water_year = min(water_year, na.rm = TRUE),
    last_post_water_year = max(water_year, na.rm = TRUE),
    n_post_years = n_distinct(water_year),
    n_site_years = n(),
    mean_log10_anomaly = finite_mean(log10_anomaly),
    sd_log10_anomaly = finite_sd(log10_anomaly),
    mean_percent_departure = percent_from_log10(mean_log10_anomaly),
    .groups = "drop"
  ) %>%
  arrange(variable, desc(mortality_25plus_percent), Stream_Name)

readr::write_csv(
  hff_site_summary,
  file.path(res_dir, "holiday_farm_fire_burned_area_chemistry_summary.csv")
)

burn_class_colors <- c(
  "No mapped HFF overlap" = "#9CA3AF",
  "Low burned" = "#C9A66B",
  "Moderate burned" = "#C07F2C",
  "High burned" = "#8F3B2F"
)

p_hff <- hff_site_summary %>%
  ggplot(aes(x = mortality_25plus_percent, y = mean_log10_anomaly, color = burn_class)) +
  geom_hline(yintercept = 0, color = "grey70", linewidth = 0.35) +
  geom_point(size = 2.4, alpha = 0.92) +
  geom_text(
    data = hff_site_summary %>% filter(mortality_25plus_percent > 0),
    aes(label = Stream_Name),
    size = 2.45,
    nudge_y = 0.035,
    color = "grey20",
    check_overlap = TRUE
  ) +
  facet_wrap(~ variable, scales = "free_y", ncol = 3) +
  scale_color_manual(values = burn_class_colors, name = NULL, drop = FALSE) +
  scale_x_continuous(
    breaks = seq(0, 50, 10),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0.04, 0.10))
  ) +
  labs(
    x = "Watershed area with >=25% basal-area mortality",
    y = "Mean WY2021-2023 log10 departure from WY1997-2020 baseline"
  ) +
  theme_disturbance_fig(base_size = 10.5) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(hjust = 0)
  )

ggsave(
  file.path(fig_dir, "holiday_farm_fire_burned_area_chemistry_comparison.png"),
  p_hff,
  width = 10.2,
  height = 7.4,
  dpi = PLOT_DPI,
  bg = "white"
)

flood_window_labels <- c(
  pre_1996_flood = "Pre\n1990-95",
  flood_water_year = "Flood\n1996",
  early_post_1996_flood = "Early post\n1997-00",
  late_post_1996_flood = "Late post\n2001-05"
)

flood_plot_data <- flood_lag_panel %>%
  filter(
    n_samples >= 3L,
    variable %in% flood_solutes,
    flood_1996_window %in% names(flood_window_labels),
    is.finite(log10_anomaly)
  ) %>%
  mutate(
    flood_1996_window = factor(flood_1996_window, levels = names(flood_window_labels)),
    flood_window_label = factor(
      flood_window_labels[as.character(flood_1996_window)],
      levels = unname(flood_window_labels)
    ),
    variable = factor(variable, levels = flood_solutes),
    Stream_Name = factor(Stream_Name, levels = site_order)
  )

flood_window_summary <- flood_plot_data %>%
  group_by(variable, flood_1996_window, flood_window_label) %>%
  summarise(
    n_site_years = n(),
    n_sites = n_distinct(Stream_Name),
    first_water_year = min(water_year, na.rm = TRUE),
    last_water_year = max(water_year, na.rm = TRUE),
    mean_log10_anomaly = finite_mean(log10_anomaly),
    sd_log10_anomaly = finite_sd(log10_anomaly),
    mean_percent_departure = percent_from_log10(mean_log10_anomaly),
    .groups = "drop"
  ) %>%
  arrange(variable, flood_1996_window)

readr::write_csv(
  flood_window_summary,
  file.path(res_dir, "february_1996_flood_before_after_chemistry_summary.csv")
)

p_flood <- ggplot(flood_plot_data, aes(x = flood_window_label, y = log10_anomaly)) +
  geom_hline(yintercept = 0, color = "grey72", linewidth = 0.35) +
  geom_boxplot(
    width = 0.62,
    outlier.shape = NA,
    fill = "#E8ECE8",
    color = "grey35",
    linewidth = 0.35
  ) +
  geom_point(
    aes(color = Stream_Name),
    position = position_jitter(width = 0.13, height = 0, seed = 1996),
    size = 1.35,
    alpha = 0.58
  ) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 2.7, color = "black") +
  facet_wrap(~ variable, scales = "free_y", ncol = 3) +
  scale_color_site(name = NULL, drop = FALSE) +
  labs(
    x = NULL,
    y = "Annual log10 departure from WY1997-2020 baseline"
  ) +
  theme_disturbance_fig(base_size = 10.5) +
  theme(
    axis.text.x = element_text(size = 8.8),
    legend.position = "bottom",
    strip.text = element_text(hjust = 0)
  )

ggsave(
  file.path(fig_dir, "february_1996_flood_before_after_chemistry.png"),
  p_flood,
  width = 10.2,
  height = 7.4,
  dpi = PLOT_DPI,
  bg = "white"
)

manifest <- tibble::tribble(
  ~artifact, ~type, ~path, ~role,
  "holiday_farm_fire_burned_area_chemistry_summary.csv", "table",
  file.path(res_dir, "holiday_farm_fire_burned_area_chemistry_summary.csv"),
  "WY2021-2023 chemistry departures joined to Holiday Farm Fire burned-area summaries",
  "holiday_farm_fire_burned_area_chemistry_comparison.png", "figure",
  file.path(fig_dir, "holiday_farm_fire_burned_area_chemistry_comparison.png"),
  "Prelim burned-area chemistry comparison for the Holiday Farm Fire",
  "february_1996_flood_before_after_chemistry_summary.csv", "table",
  file.path(res_dir, "february_1996_flood_before_after_chemistry_summary.csv"),
  "Before/after chemistry summary for the February 1996 flood window",
  "february_1996_flood_before_after_chemistry.png", "figure",
  file.path(fig_dir, "february_1996_flood_before_after_chemistry.png"),
  "Prelim February 1996 before/after chemistry panel"
) %>%
  mutate(exists = file.exists(path))

readr::write_csv(manifest, file.path(res_dir, "prelim_disturbance_paper_figure_manifest.csv"))

message("Prelim disturbance-paper tables written to: ", res_dir)
message("Prelim disturbance-paper figures written to: ", fig_dir)
