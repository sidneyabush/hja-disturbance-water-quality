# Shifts Over Time and Disturbance

Start here:

- [Roadmap](ROADMAP.md)
- [Progress updates](PROGRESS_UPDATES.md)

## Main Idea

Use the long HJA chemistry record to ask whether stream chemistry changes over
time, especially before and after large disturbances like fire, floods, and
landslides.

This is separate from the storage-water quality paper. The storage paper is about
long-term storage and chemistry patterns. This work is about chemistry changes
through time.

## What To Run

From this project folder:

```r
Rscript run_disturbance_workflow.R
```

This uses the full chemistry record and writes outputs here:

`outputs/02_disturbance_time_change`

## Files To Edit

- [ROADMAP.md](ROADMAP.md): current plan, figure shortlist, and next steps.
- [PROGRESS_UPDATES.md](PROGRESS_UPDATES.md): dated notes on what changed.
- `02_disturbance_time_change/2b_synthesize_temporal_lag_results.R`: long-term
  chemistry-change summaries and screening figures.
- `02_disturbance_time_change/2c_compile_disturbance_driver_sources.R`: Holiday
  Farm Fire burned-area summaries.
- `02_disturbance_time_change/2e_make_disturbance_paper_figures.R`: Holiday
  Farm Fire and February 1996 flood comparison figures.

Generated tables and figures in Box should be recreated by running the scripts,
not edited by hand.

## What We Have Now

- Yearly chemistry summaries through water year 2024.
- Chemistry changes compared with the water years used in the storage paper.
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

Storage-paper watershed characteristics:

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

Current next steps are tracked in [Roadmap](ROADMAP.md).

## Notes

- Keep water years 2021-2024 separate from the main storage paper unless storage
  values are updated beyond water year 2020.
- Describe the current results as preliminary checks until the disturbance data are
  fully joined.
- Do not make strong claims about fire, flood, or landslide effects until
  watersheds that were affected more and less are compared directly.
