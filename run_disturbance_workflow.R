# =============================================================================
# Run temporal lag disturbance-response scaffold
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
  file.path(repo_dir, "07_disturbance_time_change", "7a_build_disturbance_chemistry_panel.R"),
  file.path(repo_dir, "07_disturbance_time_change", "7b_synthesize_temporal_lag_results.R"),
  file.path(repo_dir, "07_disturbance_time_change", "7c_compile_disturbance_driver_sources.R"),
  file.path(repo_dir, "07_disturbance_time_change", "7d_build_flood_high_flow_drivers.R")
)

missing_scripts <- scripts[!file.exists(scripts)]
if (length(missing_scripts) > 0) {
  stop("Missing disturbance workflow script(s): ", paste(missing_scripts, collapse = ", "))
}

message("Running temporal lag disturbance-response scaffold from: ", repo_dir)
for (script in scripts) {
  message("\n=== ", basename(script), " ===")
  status <- system2(rscript, args = normalizePath(script))
  if (!identical(status, 0L)) {
    stop("Temporal lag disturbance-response scaffold failed at: ", basename(script))
  }
}
message("Temporal lag disturbance-response scaffold complete.")
