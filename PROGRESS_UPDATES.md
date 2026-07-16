# Shifts Over Time and Disturbance Progress Updates

Use this file for dated notes about work completed, decisions made, and what to
pick up next. Keep the current plan in [Roadmap](ROADMAP.md).

## 2026-07-16

### Progress

- Confirmed this repo has the same basic progress/roadmap documentation pattern
  as the DSi ungaged-basin and spatial-data workflow repos.
- Regenerated the temporal-lag chemistry tables, Holiday Farm Fire summaries,
  HF004 flood/high-flow tables, and candidate figures with
  `Rscript run_disturbance_workflow.R`.
- Spot-checked the post-2020 solute departure plot, site-solute heatmap, and
  February 1996 flood hydrograph.
- Updated the roadmap with a concrete candidate figure set and current next
  plot targets.

### Decisions

- Treat `temporal_lag_site_solute_post2020_heatmap.png` as the strongest current
  screening figure for the disturbance paper.
- Keep `temporal_lag_post2020_solute_departures.png` as an overview figure, but
  describe it as a screening result rather than a causal fire effect.
- Use the February 1996 hydrograph as event context; still need a chemistry
  before/after flood plot.

### Next

- Build a Holiday Farm Fire comparison plot for more-burned versus less-burned
  or unburned watersheds.
- Build a February 1996 before/after chemistry plot from
  `hf004_1996_flood_chemistry_lag_panel.csv`.
- Find or build the Lookout Fire burned-area and severity table by watershed.

## 2026-07-15

### Progress

- Updated the disturbance repo docs so they use the split-repo filenames.
- Kept the wording focused on the disturbance paper, not the old combined HJA
  water-quality repo.

### Decisions

- Keep this repo focused on chemistry changes through time and disturbance
  response.
- Keep the storage-water quality paper in the separate storage repo.

## 2026-07-14

### Progress

- Built a separate disturbance/time-change workflow under
  `07_disturbance_time_change`.
- Added preliminary Holiday Farm Fire watershed summaries.
- Built HF004-based flood/high-flow tables and identified the February 1996
  flood as a named event.
- Kept Holiday Farm Fire and flood results framed as early checks, not final
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
