# Step 01: Active Data Prep

Only one Step-01 script is active for the disturbance paper:

```r
Rscript 01_data_prep/1a_build_chemistry_master.R
```

This script builds:

```text
HJA_CQ_master.csv
```

That table is the chemistry input used by `02_disturbance_time_change/2a_build_disturbance_chemistry_panel.R`.

The older hydroseason, rolling C-Q, clustering, synchrony, master-table, and storage-framework prep scripts are archived in `_archive/storage_water_quality_prep/` because they belong to the storage-water-quality workflow, not the current disturbance paper.
