# Shifts Over Time and Disturbance Roadmap

Progress updates: [PROGRESS_UPDATES.md](PROGRESS_UPDATES.md)

## What This Is For

Use the long HJA chemistry record to ask whether stream chemistry changes over
time, especially before and after disturbances such as fire, floods, and
landslides.

## Current Work

Build the first site-year disturbance table and decide whether the disturbance
story is strong enough for a separate paper.

## What Exists Now

- The active workflow is `run_disturbance_workflow.R`.
- Outputs are written to `outputs/07_disturbance_time_change`.
- Yearly chemistry summaries are available through water year 2024.
- Preliminary Holiday Farm Fire summaries are available.
- February 1996 flood/high-flow summaries from HF004 are available.
- Prelim figures are written to
  `/Users/sidneybush/Library/CloudStorage/Box-Box/Sidney_Bush/HJA_Water_Quality/exploratory_plots/07_disturbance_time_change`.
- The temporal-lag and 1996 flood figure set was regenerated on 2026-07-16 with
  `Rscript run_disturbance_workflow.R`.
- Current strongest screening signal: post-2020 nitrate is high across the
  recent record, especially at `GSWS09` and `GSWS02`.
- Lookout Fire watershed data still need to be found or built.
- Landslide data should only be included if the data are ready enough.

## Prelim Figures

- `temporal_lag_site_solute_post2020_heatmap.png`: best current screening
  figure for showing which sites and solutes changed most after 2020.
- `temporal_lag_post2020_solute_departures.png`: useful overview of solute-level
  departures from the WY1997-2020 baseline; frame as a screening result.
- `temporal_lag_long_term_trend_heatmap.png`: useful for separating longer-term
  trends from post-2020 departures.
- `hf004_1996_flood_hydrograph.png`: event-context figure for the February 1996
  flood.

## Current Next Steps

1. Build a Holiday Farm Fire comparison plot using burned versus less-burned or
   unburned watersheds.
2. Use `hf004_1996_flood_chemistry_lag_panel.csv` to make a before/after flood
   chemistry plot.
3. Find or build the Lookout Fire burned-area and severity table by watershed.
4. Keep current post-2020 figures framed as early checks until disturbance
   tables are fully joined to chemistry.
5. Keep dated notes in [Progress updates](PROGRESS_UPDATES.md).

## Useful Files

- `run_disturbance_workflow.R`: active workflow entry point.
- `07_disturbance_time_change/7b_synthesize_temporal_lag_results.R`: temporal
  chemistry-change synthesis and figures.
- `07_disturbance_time_change/7c_compile_disturbance_driver_sources.R`:
  Holiday Farm Fire watershed summaries.
- `07_disturbance_time_change/7d_build_flood_high_flow_drivers.R`: HF004 flood
  and high-flow tables.
- `PROGRESS_UPDATES.md`: dated decisions and next actions.
