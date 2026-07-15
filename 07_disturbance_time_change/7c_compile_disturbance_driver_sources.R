#!/usr/bin/env Rscript
# =============================================================================
# 7c: Compile disturbance driver source tables
# =============================================================================
# Builds auditable disturbance-driver input tables from available local sources.
# Current source coverage:
#   - finalized storage-paper catchment characteristics
#   - preliminary Holiday Farm Fire basal-area-mortality workbook
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
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
raw_driver_dir <- file.path(paths$raw_dir, "disturbance_drivers")
res_dir <- file.path(paths$out_dir, "07_disturbance_time_change", "disturbance_driver_audit")
dir.create(res_dir, recursive = TRUE, showWarnings = FALSE)

catchment_file <- file.path(
  paths$data_dir,
  "storage_paper_framework",
  "storage_paper_catchment_char.csv"
)
hff_workbook <- file.path(
  raw_driver_dir,
  "holiday_farm_fire_2020",
  "HJA_HF_Fire_Statistics_2020_Prelim_BEN.xlsx"
)

require_file <- function(path) {
  if (!file.exists(path)) {
    stop("Missing disturbance-driver source file: ", path)
  }
  path
}

normalize_ws_code <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x <- ifelse(x %in% c("1", "01"), "WS01", x)
  x <- ifelse(x %in% c("2", "02"), "WS02", x)
  x <- ifelse(x %in% c("3", "03", "3a", "03a"), "WS03", x)
  x <- ifelse(x %in% c("4", "04"), "WS04", x)
  x <- ifelse(x %in% c("6", "06"), "WS06", x)
  x <- ifelse(x %in% c("7", "07"), "WS07", x)
  x <- ifelse(x %in% c("8", "08"), "WS08", x)
  x <- ifelse(x %in% c("9", "09"), "WS09", x)
  x <- ifelse(x %in% c("10"), "WS10", x)
  x <- ifelse(toupper(x) == "MACK", "Mack", x)
  x <- ifelse(toupper(x) == "LOOK", "Look", x)
  x
}

storage_site_to_stream <- function(site) {
  case_when(
    site == "Look" ~ "GSLOOK",
    site == "Mack" ~ "GSMACK",
    grepl("^WS", site) ~ paste0("GS", site),
    TRUE ~ NA_character_
  )
}

safe_num <- function(x) {
  cleaned <- gsub("[^0-9eE+.-]", "", as.character(x))
  cleaned <- ifelse(cleaned == "", NA_character_, cleaned)
  suppressWarnings(as.numeric(cleaned))
}

catchment <- readr::read_csv(require_file(catchment_file), show_col_types = FALSE) %>%
  mutate(
    Stream_Name = standardize_wq_stream(Site),
    site = standardize_storage_site(Stream_Name),
    Area_km2 = safe_num(Area_km2),
    catchment_area_acres = Area_km2 * 247.105381
  ) %>%
  select(Stream_Name, site, everything())

hff_raw <- readxl::read_xlsx(require_file(hff_workbook), sheet = "HFF2020 (2)") %>%
  filter(Rowid %in% as.character(seq_len(6)), !is.na(WS_)) %>%
  mutate(ws_source = as.character(WS_)) %>%
  filter(ws_source %in% c("1", "2", "9", "1a", "2a", "4"))

severity_cols <- c(
  acres_0_ba_mortality = "A_1___0__BA_MORT",
  acres_0_to_10_ba_mortality = "A_2___0_TO_10__B",
  acres_10_to_25_ba_mortality = "A_3___10_TO_25__",
  acres_25_to_50_ba_mortality = "A_4___25_TO_50__",
  acres_50_to_75_ba_mortality = "A_5___50_TO_75__",
  acres_75_to_90_ba_mortality = "A_6___75_TO_90__",
  acres_90_to_100_ba_mortality = "A_7___90_TO_100_"
)

missing_cols <- setdiff(unname(severity_cols), names(hff_raw))
if (length(missing_cols) > 0) {
  stop("Holiday Farm Fire workbook is missing expected column(s): ", paste(missing_cols, collapse = ", "))
}

hff_by_ws <- hff_raw %>%
  transmute(
    ws_source,
    site = normalize_ws_code(ws_source),
    Stream_Name = storage_site_to_stream(site),
    across(all_of(unname(severity_cols)), safe_num, .names = "{names(severity_cols)[match(.col, severity_cols)]}")
  ) %>%
  mutate(
    event_id = "holiday_farm_fire_2020",
    event_name = "Holiday Farm Fire",
    disturbance_type = "wildfire",
    calendar_year = 2020L,
    first_full_water_year = 2021L,
    severity_basis = "basal_area_mortality",
    mapped_fire_overlap_acres = rowSums(across(starts_with("acres_")), na.rm = TRUE),
    mortality_gt0_acres = mapped_fire_overlap_acres - acres_0_ba_mortality,
    mortality_25plus_acres = acres_25_to_50_ba_mortality +
      acres_50_to_75_ba_mortality +
      acres_75_to_90_ba_mortality +
      acres_90_to_100_ba_mortality,
    mortality_50plus_acres = acres_50_to_75_ba_mortality +
      acres_75_to_90_ba_mortality +
      acres_90_to_100_ba_mortality,
    mortality_75plus_acres = acres_75_to_90_ba_mortality +
      acres_90_to_100_ba_mortality,
    mean_ba_mortality_midpoint = (
      acres_0_ba_mortality * 0 +
        acres_0_to_10_ba_mortality * 5 +
        acres_10_to_25_ba_mortality * 17.5 +
        acres_25_to_50_ba_mortality * 37.5 +
        acres_50_to_75_ba_mortality * 62.5 +
        acres_75_to_90_ba_mortality * 82.5 +
        acres_90_to_100_ba_mortality * 95
    ) / mapped_fire_overlap_acres
  ) %>%
  left_join(
    catchment %>% select(Stream_Name, catchment_area_km2 = Area_km2, catchment_area_acres),
    by = "Stream_Name"
  ) %>%
  mutate(
    direct_wq_site = !is.na(catchment_area_km2),
    mapped_fire_overlap_fraction = mapped_fire_overlap_acres / catchment_area_acres,
    mortality_gt0_fraction = mortality_gt0_acres / catchment_area_acres,
    mortality_25plus_fraction = mortality_25plus_acres / catchment_area_acres,
    mortality_50plus_fraction = mortality_50plus_acres / catchment_area_acres,
    mortality_75plus_fraction = mortality_75plus_acres / catchment_area_acres,
    source_file = hff_workbook,
    source_sheet = "HFF2020 (2)",
    source_note = paste(
      "Preliminary HJA Holiday Farm Fire spreadsheet; severity classes are basal-area mortality,",
      "not soil burn severity or dNBR. Non-gaged/lettered watersheds retained but not directly",
      "joined to chemistry sites unless Stream_Name is present."
    )
  ) %>%
  arrange(ws_source)

readr::write_csv(
  hff_by_ws,
  file.path(res_dir, "holiday_farm_fire_2020_basal_area_mortality_by_watershed.csv")
)

hff_direct <- catchment %>%
  filter(Stream_Name %in% site_order) %>%
  select(Stream_Name, site, catchment_area_km2 = Area_km2, catchment_area_acres) %>%
  mutate(
    event_id = "holiday_farm_fire_2020",
    event_name = "Holiday Farm Fire",
    disturbance_type = "wildfire",
    calendar_year = 2020L,
    first_full_water_year = 2021L
  ) %>%
  left_join(
    hff_by_ws %>%
      filter(direct_wq_site) %>%
      select(
        Stream_Name,
        starts_with("acres_"),
        mapped_fire_overlap_acres,
        mortality_gt0_acres,
        mortality_25plus_acres,
        mortality_50plus_acres,
        mortality_75plus_acres,
        mean_ba_mortality_midpoint,
        mapped_fire_overlap_fraction,
        mortality_gt0_fraction,
        mortality_25plus_fraction,
        mortality_50plus_fraction,
        mortality_75plus_fraction,
        source_file,
        source_sheet,
        source_note
      ),
    by = "Stream_Name"
  ) %>%
  mutate(
    hff_source_row_available = !is.na(mapped_fire_overlap_acres),
    across(
      c(
        starts_with("acres_"),
        mapped_fire_overlap_acres,
        mortality_gt0_acres,
        mortality_25plus_acres,
        mortality_50plus_acres,
        mortality_75plus_acres,
        mapped_fire_overlap_fraction,
        mortality_gt0_fraction,
        mortality_25plus_fraction,
        mortality_50plus_fraction,
        mortality_75plus_fraction
      ),
      ~ replace_na(.x, 0)
    ),
    exposure_class = case_when(
      mortality_50plus_fraction >= 0.10 ~ "high",
      mortality_25plus_fraction >= 0.10 ~ "moderate",
      mortality_gt0_fraction > 0 ~ "low",
      TRUE ~ "none"
    ),
    affected_fraction = mapped_fire_overlap_fraction,
    severity_index = mean_ba_mortality_midpoint,
    exposure_notes = case_when(
      hff_source_row_available ~ "Joined directly from preliminary HFF basal-area-mortality workbook.",
      TRUE ~ "No direct HFF workbook row for this WQ site; treated as zero mapped overlap for screening only."
    ),
    source_file = replace_na(source_file, hff_workbook),
    source_sheet = replace_na(source_sheet, "HFF2020 (2)"),
    source_note = replace_na(
      source_note,
      "No direct site row in preliminary workbook; zero exposure assumption should be checked against final perimeter overlay."
    )
  ) %>%
  arrange(Stream_Name)

readr::write_csv(
  hff_direct,
  file.path(res_dir, "holiday_farm_fire_2020_exposure_by_wq_site.csv")
)

source_inventory <- tibble::tribble(
  ~source_id, ~source_type, ~path, ~status, ~notes,
  "storage_paper_catchment_char", "catchment_characteristics", catchment_file, "copied",
  "Finalized storage-paper catchment characteristics copied into WQ Box data/storage_paper_framework.",
  "holiday_farm_fire_2020_prelim_ben", "wildfire_exposure_workbook", hff_workbook, "available",
  "Preliminary HJA Holiday Farm Fire basal-area-mortality classes by watershed/subwatershed.",
  "lookout_fire_2023", "wildfire_exposure", file.path(raw_driver_dir, "lookout_fire_2023"), "needed",
  "Need perimeter/burn-severity overlay or official watershed statistics.",
  "flood_event_drivers", "hydrologic_event_drivers", file.path(paths$out_dir, "07_disturbance_time_change", "flood_high_flow_drivers"), "built_by_7d",
  "Annual/site peak-flow and high-flow threshold metrics built from HF004; includes a February 1996 flood event summary."
)

readr::write_csv(source_inventory, file.path(res_dir, "disturbance_driver_source_inventory.csv"))

message("Disturbance driver audit tables written to: ", res_dir)
