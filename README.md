# Shifts Over Time and Disturbance

Project planning notes are maintained separately.

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

Generated tables and figures in Box should be recreated by running the scripts,
not edited by hand.

Archived Step-01 scripts live in `_archive/non_disturbance_prep/`. Those
hydroseason, rolling C-Q, cluster, synchrony, and storage-framework prep steps
are not active disturbance-paper analyses.

## What We Have Now

- Yearly chemistry summaries through water year 2024.
- Chemistry changes compared with the WY1997-2020 baseline.
- Preliminary Holiday Farm Fire watershed summaries.
- February 1996 flood dates and streamflow summaries from HF004.
- A first check of stream chemistry before and after the February 1996 flood.
- Notes on useful fire and water-quality papers.

## Data Needs

- Final Holiday Farm Fire area burned and how severely it burned by watershed.
- Lookout Fire area burned and how severely it burned by watershed.
- Landslide data by watershed, if we want to include landslides.
- Flood dates or summaries of very high streamflow years.
- A simple storage or streamflow variable if updated storage values are not ready.

## Local Data Notes

Watershed characteristics input:

`/Users/sidneybush/Library/CloudStorage/Box-Box/Sidney_Bush/HJA_Water_Quality/data/storage_paper_framework/storage_paper_catchment_char.csv`

Preliminary Holiday Farm Fire workbook:

`/Users/sidneybush/Library/CloudStorage/Box-Box/Sidney_Bush/HJA_Water_Quality/raw_data/disturbance_drivers/holiday_farm_fire_2020/HJA_HF_Fire_Statistics_2020_Prelim_BEN.xlsx`

Data-check outputs:

`/Users/sidneybush/Library/CloudStorage/Box-Box/Sidney_Bush/HJA_Water_Quality/outputs/02_disturbance_time_change/disturbance_driver_audit`

Most useful Holiday Farm Fire site table:

`holiday_farm_fire_2020_burned_area_by_wq_site.csv`

Flood outputs:

- `hf004_annual_high_flow_drivers.csv`
- `hf004_1996_flood_site_summary.csv`
- `hf004_1996_flood_chemistry_lag_panel.csv`

## Holiday Farm Fire Notes

The local workbook shows how much area burned in each watershed and subwatershed,
grouped by how many trees died. It is useful for a first HJA-specific fire
check, but it should not be treated as the final word on how severely different
areas burned unless we confirm that it is the best available source.

Current preliminary fire overlap is strongest for `GSWS09`, with smaller overlap
for `GSWS01` and `GSWS02`. Other chemistry sites currently show no direct overlap
in this workbook.

Useful paper to keep with this work:

Bush, Johnson, Bladon, and Sullivan (2024). Stream chemical response is mediated
by hydrologic connectivity and fire severity in a Pacific Northwest forest.
https://doi.org/10.1002/hyp.15231

## Lookout Fire Notes

We do not have a local Lookout Fire watershed table yet. We still need area
burned and how severely it burned by chemistry site.

## Flood Notes

The flood data are built from the local Andrews HF004 daily discharge file. These
are useful for timing and streamflow size. They are not mapped data on where the
stream channel or streamside area changed.

## First Table To Build

The first useful table should be yearly, by site and chemistry variable. It
should join:

- yearly chemistry changes;
- disturbance data by site;
- years since event;
- before/after event label;
- storage or simple streamflow variables, if available.

## Next Steps

Current next steps are maintained separately.

## Notes

- Keep water years 2021-2024 labeled as post-2020 disturbance-era chemistry
  unless updated storage values are explicitly added.
- Keep clusters, synchrony, hydroseasons, and storage-framework ordinations out
  of this repo's active workflow unless the disturbance paper explicitly needs
  them later.
- Describe the current results as preliminary checks until the disturbance data are
  fully joined.
- Do not make strong claims about fire, flood, or landslide effects until
  watersheds that were affected more and less are compared directly.
