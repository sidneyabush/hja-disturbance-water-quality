# Shifts Over Time and Disturbance Roadmap

Progress updates: [PROGRESS_UPDATES.md](PROGRESS_UPDATES.md)

## Goal

Use the long HJA chemistry record to ask whether stream chemistry changes over
time, especially before and after disturbances such as fire, floods, and
landslides.

## Current Work

Build the first site-year disturbance table and decide whether the disturbance
story is strong enough for a separate paper.

## What Exists Now

- The main analysis script is `run_disturbance_workflow.R`.
- Active Step 01 has one script: `01_data_prep/1a_build_chemistry_master.R`.
- Outputs are written to `outputs/02_disturbance_time_change`.
- `HJA_CQ_master.csv` has been rebuilt with the full local chemistry record
  through water year 2024.
- Yearly chemistry summaries are available through water year 2024.
- Preliminary Holiday Farm Fire summaries are available.
- February 1996 flood/high-flow summaries from HF004 are available.
- Prelim figures are written to
  `/Users/sidneybush/Library/CloudStorage/Box-Box/Sidney_Bush/HJA_Water_Quality/exploratory_plots/02_disturbance_time_change`.
- First paper comparison figures are written to
  `/Users/sidneybush/Library/CloudStorage/Box-Box/Sidney_Bush/HJA_Water_Quality/exploratory_plots/02_disturbance_time_change/prelim_paper_figures`.
- The temporal-lag and 1996 flood figure set was regenerated on 2026-07-16 with
  `Rscript run_disturbance_workflow.R`.
- Current strongest disturbance signal: post-2020 nitrate is high in burned
  Holiday Farm Fire watersheds, especially `GSWS09`, with secondary support
  from sulfate.
- Lookout Fire watershed data still need to be found or built.
- Landslide data should only be included if the data are ready enough.
- The old hydroseason, rolling C-Q, cluster, synchrony, and storage-framework
  prep scripts are archived because they are not needed for this disturbance
  workflow.

## Prelim Figures

- `temporal_lag_site_solute_post2020_heatmap.png`: best current screening
  figure for showing which sites and solutes changed most after 2020.
- `temporal_lag_post2020_solute_departures.png`: useful overview of solute-level
  departures from the WY1997-2020 baseline; frame as a screening result.
- `temporal_lag_long_term_trend_heatmap.png`: useful for separating longer-term
  trends from post-2020 departures.
- `hf004_1996_flood_hydrograph.png`: event-context figure for the February 1996
  flood.
- `holiday_farm_fire_burned_area_chemistry_comparison.png`: strongest current
  disturbance-paper figure; compares WY2021-2023 chemistry departures with
  Holiday Farm Fire burned area and basal-area mortality by watershed.
- `february_1996_flood_before_after_chemistry.png`: first before/after chemistry
  panel for the February 1996 flood window.

## Current Next Steps

1. Review the Holiday Farm Fire burned-area chemistry figure as the first likely
   disturbance-paper result.
2. Decide whether the February 1996 flood chemistry panel belongs in the main
   paper or supplement.
3. Find or build the Lookout Fire burned-area and severity table by watershed.
4. Check whether WY2024 chemistry can be separated cleanly from lingering
   Holiday Farm Fire effects.
5. Decide whether landslide data are complete enough to include.
6. Keep dated notes in [Progress updates](PROGRESS_UPDATES.md).

## Useful Files

- `run_disturbance_workflow.R`: main analysis script.
- `01_data_prep/1a_build_chemistry_master.R`: compact discrete chemistry master
  builder.
- `02_disturbance_time_change/2b_synthesize_temporal_lag_results.R`: temporal
  chemistry-change synthesis and figures.
- `02_disturbance_time_change/2c_compile_disturbance_driver_sources.R`:
  Holiday Farm Fire burned-area summaries.
- `02_disturbance_time_change/2d_build_flood_high_flow_drivers.R`: HF004 flood
  and high-flow tables.
- `02_disturbance_time_change/2e_make_disturbance_paper_figures.R`: Holiday Farm
  Fire and February 1996 flood chemistry comparison figures.
- `PROGRESS_UPDATES.md`: dated decisions and next actions.
