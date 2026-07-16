# =============================================================================
# Run disturbance-water-quality workflow
# =============================================================================

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

repo_dir <- get_script_dir()
rscript <- file.path(R.home("bin"), "Rscript")
scripts <- c(
  file.path(repo_dir, "01_data_prep", "1a_build_chemistry_master.R"),
  file.path(repo_dir, "02_disturbance_time_change", "2a_build_disturbance_chemistry_panel.R"),
  file.path(repo_dir, "02_disturbance_time_change", "2b_synthesize_temporal_lag_results.R"),
  file.path(repo_dir, "02_disturbance_time_change", "2c_compile_disturbance_driver_sources.R"),
  file.path(repo_dir, "02_disturbance_time_change", "2d_build_flood_high_flow_drivers.R"),
  file.path(repo_dir, "02_disturbance_time_change", "2e_make_disturbance_paper_figures.R")
)

missing_scripts <- scripts[!file.exists(scripts)]
if (length(missing_scripts) > 0) {
  stop("Missing disturbance workflow script(s): ", paste(missing_scripts, collapse = ", "))
}

message("Running disturbance-water-quality workflow from: ", repo_dir)
for (script in scripts) {
  message("\n=== ", basename(script), " ===")
  status <- system2(rscript, args = normalizePath(script))
  if (!identical(status, 0L)) {
    stop("Disturbance-water-quality workflow failed at: ", basename(script))
  }
}
message("Disturbance-water-quality workflow complete.")
