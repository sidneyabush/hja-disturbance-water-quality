# =============================================================================
# 1a: Build chemistry master
# =============================================================================
# Creates the compact discrete chemistry table used by the disturbance workflow:
# HJA_CQ_master.csv. The older monthly, hydroseason, rolling C-Q, clustering,
# synchrony, and storage-framework prep steps are archived because this paper
# does not currently use them.
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

paths <- get_project_paths()
raw_dir <- paths$raw_dir
data_dir <- paths$data_dir
output_dir <- file.path(dirname(data_dir), "outputs")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

first_existing <- function(paths, label) {
  existing <- paths[file.exists(paths)]
  if (length(existing) == 0) {
    stop(label, " not found. Checked:\n", paste(paths, collapse = "\n"))
  }
  existing[[1]]
}

parse_hja_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  x_chr <- as.character(x)
  out <- suppressWarnings(lubridate::ymd(x_chr))
  missing <- is.na(out)
  if (any(missing)) {
    out[missing] <- suppressWarnings(lubridate::as_date(lubridate::parse_date_time(
      x_chr[missing],
      orders = c("ymd HMS z", "ymd HMS", "ymd HM z", "ymd HM", "ymd", "mdy HMS z", "mdy HMS", "mdy")
    )))
  }
  as.Date(out)
}

variable_rename_map <- c(
  "SI" = "DSi",
  "PO4P" = "PO4",
  "NH3N" = "NH3",
  "NO3N" = "NO3",
  "NA" = "Na",
  "K" = "K",
  "CA" = "Ca",
  "MG" = "Mg",
  "SO4S" = "SO4",
  "CL" = "Cl",
  "DOC" = "DOC"
)
keep_vars <- unname(variable_rename_map)

# CCAL detection limits (mg/L). Zeros are replaced with one-half MDL.
ccal_dl <- tibble::tribble(
  ~variable, ~MDL_mgL, ~ML_mgL,
  "PO4", 0.001, 0.003,
  "NH3", 0.003, 0.009,
  "NO3", 0.001, 0.003,
  "Na", 0.010, 0.030,
  "K", 0.030, 0.100,
  "Ca", 0.060, 0.190,
  "Mg", 0.020, 0.060,
  "SO4", 0.010, 0.030,
  "Cl", 0.010, 0.030,
  "DOC", 0.050, 0.160,
  "DSi", 0.200, 0.600
)

dl_tbl <- ccal_dl %>%
  dplyr::mutate(DL_mgL = MDL_mgL) %>%
  dplyr::select(variable, DL_mgL)

apply_dl_half_for_zeros <- function(df, dl_lookup = dl_tbl) {
  df %>%
    dplyr::left_join(dl_lookup, by = "variable") %>%
    dplyr::mutate(
      ReplacedZero_MDLhalf = dplyr::if_else(!is.na(value) & value == 0 & !is.na(DL_mgL), TRUE, FALSE),
      value = dplyr::if_else(ReplacedZero_MDLhalf, 0.5 * DL_mgL, value)
    ) %>%
    dplyr::select(-DL_mgL)
}

cf001_file <- first_existing(
  file.path(raw_dir, c("CF00201_v7.csv", "CF00201_v6.csv")),
  "CF00201 chemistry file"
)

cf001_raw <- readr::read_csv(cf001_file, show_col_types = FALSE) %>%
  dplyr::mutate(
    Date = parse_hja_date(DATE_TIME),
    Stream_Name = as.character(SITECODE),
    Q_cms = suppressWarnings(as.numeric(MEAN_LPS)) * 0.001
  )

cq_master <- cf001_raw %>%
  dplyr::select(
    -dplyr::any_of(c(
      "STCODE", "ENTITY", "SITECODE", "WATERYEAR", "DATE_TIME", "LABNO", "TYPE",
      "INTERVAL", "Q_AREA_CM", "QCODE", "PVOL", "PVOLCODE", "ANCA", "ANCACODE",
      "MEAN_LPS"
    ))
  ) %>%
  dplyr::select(-dplyr::ends_with("CODE")) %>%
  tidyr::pivot_longer(
    cols = -c(Stream_Name, Date, Q_cms),
    names_to = "variable",
    values_to = "value"
  ) %>%
  dplyr::filter(!is.na(value), !is.na(Date)) %>%
  dplyr::filter(variable %in% names(variable_rename_map)) %>%
  dplyr::mutate(
    variable = dplyr::recode(variable, !!!variable_rename_map),
    value = suppressWarnings(as.numeric(value)),
    units = "mg/L",
    source = "CF00201"
  ) %>%
  dplyr::select(Stream_Name, Date, variable, value, Q_cms, units, source) %>%
  apply_dl_half_for_zeros() %>%
  dplyr::filter(variable %in% keep_vars) %>%
  dplyr::mutate(
    Year = lubridate::year(Date),
    Month = lubridate::month(Date)
  ) %>%
  dplyr::arrange(Stream_Name, variable, Date)

out_file <- file.path(output_dir, "HJA_CQ_master.csv")
readr::write_csv(cq_master, out_file)

message("Chemistry master written to: ", out_file)
message("Rows: ", nrow(cq_master))
message(
  "Water years represented: ",
  min(ifelse(cq_master$Month >= 10, cq_master$Year + 1L, cq_master$Year), na.rm = TRUE),
  "-",
  max(ifelse(cq_master$Month >= 10, cq_master$Year + 1L, cq_master$Year), na.rm = TRUE)
)
