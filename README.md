# Replication Materials for the Prefecture-Month Analysis of Japan’s 2016 Care-Leave Benefit Reform

This repository contains the replication materials for the prefecture-month analysis of Japan’s 2016 care-leave benefit reform. It provides the analytical panel, the prefecture-level contextual-indicator file, the R scripts used in the estimation workflow, and documentation required to reproduce the empirical results reported in the manuscript.

The replication workflow begins from an integrated monthly prefecture panel, `bpm_clean.csv`, rather than reconstructing all underlying administrative and statistical source tables from scratch. The pre-reform prefectural contextual indicators used in the heterogeneity analysis are provided separately in `contextual_indicators_2015.csv`.

## Repository structure

Place the files in the following structure:

```text
project/
  README.md
  LICENSE
  renv.lock
  .gitignore

  00_master.R
  01_load_panel_and_check_inputs.R
  02_construct_contextual_variables.R
  03_prepare_analysis_samples.R
  04_run_main_models.R
  05_run_robustness.R
  06_compute_marginal_effects_and_export.R
  07_build_main_text_tables.R

  data/
    derived/
      bpm_clean.csv
      contextual_indicators_2015.csv

  docs/
    codebook.md
    output_mapping.md
    replication_notes.md

  out/
```

The scripts automatically create the required subfolders under `out/`.

## Required input data

Two input files are required.

### `data/derived/bpm_clean.csv`

This file is the integrated prefecture-month analytical panel used as the starting point for the replication workflow. It should contain the following variables:

- `pref_id`
- `pref_name`
- `year`
- `month`
- `year_month`
- `date`
- `n_m`
- `n_f`
- `n_total`
- `ln_ratio_mf`
- `u_rate`
- `n_ei_insured`
- `n_care_need_2to5`
- `n_ltc_facility_users`
- `share_75plus`
- `z_u_rate`
- `z_ln_ei`
- `z_ln_need`
- `z_ln_fac`
- `z_oldshare75`
- `moy`
- `t_index`
- `ln_ei`
- `ln_need`
- `ln_fac`

### `data/derived/contextual_indicators_2015.csv`

This file contains the prefecture-level contextual indicators used in the heterogeneity analysis. It should contain at least:

- `pref_id`
- `pref_name`
- `male_wage_premium_2015`
- `z_male_wage_premium_2015`
- `dual_earner_share_2015`
- `z_dual_earner_share_2015`
- `breadwinner_exposure_2015`
- `z_breadwinner_exposure_2015`

## Software requirements

The code is written in R. The main packages used in the workflow are:

- `data.table`
- `fixest`
- `ggplot2`

The software environment can be documented through `renv.lock` or an equivalent `sessionInfo()` record.

## How to run the replication code

To run the full workflow, open the project directory in R or RStudio and execute:

```r
source("00_master.R")
```

This runs the scripts in sequence.

### `01_load_panel_and_check_inputs.R`

Loads the analytical panel and performs input checks. This script verifies required variables, duplicate `pref_id × year_month` combinations, time coverage, missingness, blank-string entries, and the two prefecture-month cells that were blank in the source table.

### `02_construct_contextual_variables.R`

Loads `contextual_indicators_2015.csv`, checks the required prefecture-level contextual variables, and merges them into the analytical panel.

### `03_prepare_analysis_samples.R`

Applies the clean-window rules, excludes the two blank source entries treated as missing, constructs the estimation samples, and reshapes the panel into the long format used for PPML estimation.

### `04_run_main_models.R`

Estimates the baseline PPML model, the main heterogeneity model using prefectural male wage premium, and the supplementary heterogeneity model using breadwinner exposure.

### `05_run_robustness.R`

Runs robustness checks for alternative post windows, specifications with and without time-varying prefectural controls, and the supplementary log-ratio specification.

### `06_compute_marginal_effects_and_export.R`

Computes marginal effects at representative values and exports the main figures and appendix marginal-effects tables.

### `07_build_main_text_tables.R`

Formats the manuscript tables for the main text, including the baseline estimates, the main and supplementary heterogeneity tables, and the robustness summary table.

## Expected outputs

The scripts write outputs to the `out/` folder.

### `out/checks/`

Input validation and data checks, including:

- duplicate checks
- missingness checks
- year-month range checks
- sample summaries
- contextual-indicator merge checks

### `out/samples/`

Prepared analysis samples, including:

- `ratio_panel_2016cw.csv`
- `ppml_panel_2016cw_long.csv`

### `out/models/`

Saved model objects for the main and robustness specifications.

### `out/tables/`

Tables used in the manuscript and appendix, including:

- `D1_core_coefficients.csv`
- `robustness_postwindow_summary.csv`
- `robustness_controls_summary.csv`
- `robustness_lnratio_summary.csv`
- `D3_marginal_effects_male_wage_premium.csv`
- `D3_marginal_effects_breadwinner_exposure.csv`
- `Table1_baseline_clean_window_ppml.csv`
- `Table2_main_heterogeneity_male_wage_premium.csv`
- `Table3_supplementary_heterogeneity_breadwinner_exposure.csv`
- `Table4_robustness_main_wage_premium_result.csv`

### `out/figures/`

Main figures, including:

- `Figure1_marginal_effects_wagepremium.png`
- `Figure2_marginal_effects_breadwinner_exposure.png`

## Analysis design notes

The main analysis uses a conservative clean-window design.

- Pre-reform baseline: `2014-01` to `2016-07`
- Transition interval excluded from the main specification: `2016-08` to `2016-11`
- Main post-reform period: `2016-12` to `2017-03`

This design is used to reduce contamination from implementation-to-observation delays in claims-based benefit data and from the subsequent institutional change introduced in January 2017.

The public analytical panel extends to `2017-04` so that alternative post-window robustness checks can also be reproduced.

Two prefecture-month observations were blank in the source table and are treated as missing rather than as zeros:

- Yamanashi in `2016-08`
- Saga in `2016-12`

## Mapping to manuscript outputs

The main manuscript outputs correspond to the following scripts:

- **Table 1. Baseline clean-window PPML estimates**  
  → `07_build_main_text_tables.R`

- **Table 2. Main heterogeneity estimates by prefectural male wage premium**  
  → `07_build_main_text_tables.R`

- **Figure 1. Male-specific post-reform effect by wage premium**  
  → `06_compute_marginal_effects_and_export.R`

- **Table 3. Supplementary heterogeneity estimates by breadwinner exposure**  
  → `07_build_main_text_tables.R`

- **Figure 2. Male-specific post-reform effect by breadwinner exposure**  
  → `06_compute_marginal_effects_and_export.R`

- **Table 4. Robustness of the main wage-premium heterogeneity result**  
  → `07_build_main_text_tables.R`

## Manual execution order

If you prefer to run the scripts manually rather than through the master script, execute them in this order:

```r
source("01_load_panel_and_check_inputs.R")
source("02_construct_contextual_variables.R")
source("03_prepare_analysis_samples.R")
source("04_run_main_models.R")
source("05_run_robustness.R")
source("06_compute_marginal_effects_and_export.R")
source("07_build_main_text_tables.R")
```

## Troubleshooting

If the code stops with an error, first check:

- whether both input files are located under `data/derived/`
- whether the required variable names match exactly
- whether `pref_id` is unique in `contextual_indicators_2015.csv`
- whether `bpm_clean.csv` contains one row per `pref_id × year_month`
- whether the expected year-month coverage is present
- whether the blank source entries are handled as missing rather than as numeric zeros

## Notes on scope

These replication materials are designed to reproduce the empirical analysis from the integrated analytical panel and contextual-indicator file provided in the repository. They do not rebuild the panel from the original administrative and statistical source tables. Documentation on variable definitions, output files, and replication notes is provided in the `docs/` folder.
