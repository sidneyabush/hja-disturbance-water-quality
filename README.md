# Shifts Over Time and Disturbance

## Main Idea

Use the long HJA chemistry record to ask whether stream chemistry changes over
time, especially before and after large disturbances like fire, floods, and
landslides.

This work is about chemistry changes through time.

## What To Run

From this project folder:

```r
Rscript run_disturbance_workflow.R
```

This rebuilds the compact chemistry master, then runs the disturbance workflow.
Outputs are written here:

`outputs/02_disturbance_time_change`

## Files To Edit

- `01_data_prep/1a_build_chemistry_master.R`: compact chemistry master used by
  the disturbance workflow.
- `02_disturbance_time_change/2b_synthesize_temporal_lag_results.R`: long-term
  chemistry-change summaries and screening figures.
- `02_disturbance_time_change/2c_compile_disturbance_driver_sources.R`: Holiday
  Farm Fire burned-area summaries.
- `02_disturbance_time_change/2e_make_disturbance_paper_figures.R`: Holiday
  Farm Fire and February 1996 flood comparison figures.

Generated tables and figures should be recreated by running the scripts, not
edited by hand.

Archived Step-01 scripts live in `_archive/non_disturbance_prep/`. Those
hydroseason, rolling C-Q, cluster, synchrony, and storage-framework prep steps
are not active disturbance-paper analyses.

## Inputs And Outputs

Watershed characteristics input: `storage_paper_catchment_char.csv`

Preliminary Holiday Farm Fire input: `HJA_HF_Fire_Statistics_2020_Prelim_BEN.xlsx`

Most useful Holiday Farm Fire site table:

`holiday_farm_fire_2020_burned_area_by_wq_site.csv`

Flood outputs:

- `hf004_annual_high_flow_drivers.csv`
- `hf004_1996_flood_site_summary.csv`
- `hf004_1996_flood_chemistry_lag_panel.csv`
