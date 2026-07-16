# Shifts Over Time and Disturbance Progress Updates

Use this file for dated notes about work completed, decisions made, and what to
pick up next. Keep the current plan in [Roadmap](ROADMAP.md).

## 2026-07-16

### Progress

- Confirmed this project has progress notes and a roadmap like the DSi
  ungaged-basin and spatial-data projects.
- Regenerated the temporal-lag chemistry tables, Holiday Farm Fire summaries,
  HF004 flood/high-flow tables, and prelim figures with
  `Rscript run_disturbance_workflow.R`.
- Spot-checked the post-2020 solute departure plot, site-solute heatmap, and
  February 1996 flood hydrograph.
- Updated the roadmap with a concrete prelim figure set and current next
  plot targets.
- Added `2e_make_disturbance_paper_figures.R` to make first paper comparison
  plots.
- Generated `holiday_farm_fire_burned_area_chemistry_comparison.png` and
  `february_1996_flood_before_after_chemistry.png`.
- Renamed the disturbance workflow from the old step-07 path to
  `02_disturbance_time_change` to match this repo's workflow order.
- Renamed the Holiday Farm Fire site table to use burned-area language.
- Replaced the site-solute table name with
  `temporal_lag_site_solute_screening_signals.csv`.
- Removed old generated files with outdated names from Box.
- Replaced older jargon in active disturbance scripts where plain wording was
  clearer.
- Reduced routine startup messages from shared helper files.

### Decisions

- Treat `temporal_lag_site_solute_post2020_heatmap.png` as the strongest current
  screening figure for the disturbance paper.
- Keep `temporal_lag_post2020_solute_departures.png` as an overview figure, but
  describe it as a screening result rather than a causal fire effect.
- Use the February 1996 hydrograph as event context; still need a chemistry
  before/after flood plot.
- Treat the Holiday Farm Fire burned-area chemistry comparison as the strongest
  current disturbance-paper figure.
- Use burned area and basal-area mortality language for the Holiday Farm Fire
  comparison.
- Treat nitrate and sulfate as the clearest current post-fire chemistry signals.

### Next

- Review the Holiday Farm Fire burned-area chemistry figure for the first
  disturbance-paper results paragraph.
- Decide whether the February 1996 before/after chemistry panel belongs in the
  main paper or supplement.
- Find or build the Lookout Fire burned-area and severity table by watershed.

## 2026-07-15

### Progress

- Updated the disturbance notes so they use the split-project filenames.
- Kept the wording focused on the disturbance paper, not the older combined HJA
  water-quality project.

### Decisions

- Keep this project focused on chemistry changes through time and disturbance
  response.
- Keep the storage-water quality paper in the separate storage project.

## 2026-07-14

### Progress

- Built a separate disturbance/time-change analysis under
  `02_disturbance_time_change`.
- Added preliminary Holiday Farm Fire watershed summaries.
- Built HF004-based flood/high-flow tables and identified the February 1996
  flood as a named event.
- Kept Holiday Farm Fire and flood results framed as preliminary checks, not final
  manuscript results.

### Decisions

- Treat the preliminary Holiday Farm Fire workbook as useful but not final.
- Use HF004 discharge for the first flood/high-flow summaries.
- Do not make strong disturbance claims until affected and less-affected
  watersheds are compared directly.

### Next

- Join Holiday Farm Fire data to yearly chemistry summaries.
- Review chemistry before and after the February 1996 flood.
- Find or build the Lookout Fire watershed table.
- Decide whether landslide data are ready enough to include.
