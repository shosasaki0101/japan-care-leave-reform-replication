# Codebook

This document describes the variables used in the replication workflow for the prefecture-month analysis of Japan’s 2016 care-leave benefit reform.

The replication begins from two prepared input files:

- `data/derived/bpm_clean.csv`
- `data/derived/contextual_indicators_2015.csv`

The workflow does not reconstruct these files from the original administrative and statistical source tables. Instead, it uses them as the starting point for sample construction, model estimation, robustness checks, and figure/table generation.

## 1. `bpm_clean.csv`

`bpm_clean.csv` is the integrated prefecture-month analytical panel. Each row corresponds to one prefecture-month observation.

### Identifier and time variables

#### `pref_id`
Prefecture identifier code.

#### `pref_name`
Prefecture name.

#### `year`
Calendar year.

#### `month`
Calendar month.

#### `year_month`
Monthly identifier in `YYYYMM` format.

#### `date`
Monthly date variable, stored as the first day of each month.

#### `moy`
Month-of-year indicator used in estimation.

#### `t_index`
Linear time index used in estimation.

## 2. Outcome variables

### `n_m`
Number of male care-leave benefit recipients in the prefecture-month.

### `n_f`
Number of female care-leave benefit recipients in the prefecture-month.

### `n_total`
Total number of care-leave benefit recipients in the prefecture-month:

`n_total = n_m + n_f`

This variable is used as the weight in the auxiliary `ln(M/F)` specification.

### `ln_ratio_mf`
Log male-to-female recipient ratio:

`ln_ratio_mf = ln(M/F)`

This is the dependent variable in the auxiliary ratio-based specification used as a directional robustness check.

## 3. Time-varying prefectural controls

These variables are included as time-varying prefectural controls in the baseline PPML specification and in the main heterogeneity models.

### `u_rate`
Prefectural unemployment rate.

### `n_ei_insured`
Number of employment-insurance insured persons in the prefecture-month.

### `n_care_need_2to5`
Number of persons certified as care-need levels 2 to 5 in the prefecture-month.

### `n_ltc_facility_users`
Number of long-term-care facility users in the prefecture-month.

### `share_75plus`
Share of the population aged 75 and above in the prefecture-month.

## 4. Logged versions of selected controls

### `ln_ei`
Log of `n_ei_insured`.

### `ln_need`
Log of `n_care_need_2to5`.

### `ln_fac`
Log of `n_ltc_facility_users`.

## 5. Standardised control variables

These are standardised versions of the time-varying prefectural controls used directly in the estimation models.

### `z_u_rate`
Standardised unemployment rate.

### `z_ln_ei`
Standardised logged employment-insurance insured persons.

### `z_ln_need`
Standardised logged number of persons certified as care-need levels 2 to 5.

### `z_ln_fac`
Standardised logged number of long-term-care facility users.

### `z_oldshare75`
Standardised share of the population aged 75 and above.

## 6. `contextual_indicators_2015.csv`

`contextual_indicators_2015.csv` contains prefecture-level contextual indicators measured for 2015 and merged into the analytical panel during the replication workflow.

Each row corresponds to one prefecture.

### Identifier variables

#### `pref_id`
Prefecture identifier code.

#### `pref_name`
Prefecture name.

## 7. Main contextual variables

### `male_wage_premium_2015`
Prefectural male wage premium in 2015.

This variable captures the extent to which men’s earnings exceed women’s earnings in the prefecture and is used as the main contextual indicator in the heterogeneity analysis.

### `z_male_wage_premium_2015`
Standardised version of `male_wage_premium_2015`.

This is the version used in the main heterogeneity specification.

### `dual_earner_share_2015`
Prefectural dual-earner share in 2015.

This variable is retained in the contextual-indicator file for completeness but is not used in the final main-text models.

### `z_dual_earner_share_2015`
Standardised version of `dual_earner_share_2015`.

This variable is also retained for completeness but is not used in the final main-text models.

### `breadwinner_exposure_2015`
Prefectural breadwinner-exposure measure in 2015.

This variable captures a broader dimension of breadwinner-oriented household structure and is used in the supplementary heterogeneity analysis.

### `z_breadwinner_exposure_2015`
Standardised version of `breadwinner_exposure_2015`.

This is the version used in the supplementary heterogeneity specification.

## 8. Variables created during the replication workflow

The scripts generate additional variables and sample definitions during execution.

### Created in `03_prepare_analysis_samples.R`

#### `period_2016cw`
Categorical clean-window period indicator:

- `pre`
- `transition`
- `post`

The clean-window definition is:

- pre: `2014-01` to `2016-07`
- transition: `2016-08` to `2016-11`
- post: `2016-12` to `2017-03`

#### `post2016_clean`
Binary post-period indicator for the main clean-window design.

Takes value:
- `1` in the main post-reform period
- `0` in the pre-reform period

Transition observations are excluded before estimation.

### Created in the PPML long-format sample

#### `sexvar`
Temporary variable created during reshaping, indicating whether the count came from `n_m` or `n_f`.

#### `n`
Sex-specific count outcome in the long-format PPML panel.

#### `sex`
Binary sex-category label in the long-format PPML panel:
- `male`
- `female`

#### `male`
Binary indicator equal to 1 for male observations in the long-format PPML panel.

## 9. Variables used in the main models

### Baseline PPML model
The baseline PPML model uses:

- outcome: `n`
- key regressors:
  - `post2016_clean`
  - `male × post2016_clean`
- fixed effects:
  - prefecture fixed effects
  - sex fixed effects
- additional controls:
  - `t_index`
  - `i(moy)`
  - `z_u_rate`
  - `z_ln_ei`
  - `z_ln_need`
  - `z_ln_fac`
  - `z_oldshare75`

### Main heterogeneity model
The main heterogeneity model adds:

- `post2016_clean × z_male_wage_premium_2015`
- `male × post2016_clean × z_male_wage_premium_2015`

### Supplementary heterogeneity model
The supplementary heterogeneity model instead adds:

- `post2016_clean × z_breadwinner_exposure_2015`
- `male × post2016_clean × z_breadwinner_exposure_2015`

### Auxiliary ratio specification
The auxiliary `ln(M/F)` model uses:

- outcome: `ln_ratio_mf`
- weight: `n_total`
- key heterogeneity term:
  - `post2016_clean × z_male_wage_premium_2015`

This specification is treated as a directional robustness check rather than as a direct substitute for the PPML models.

## 10. Exclusions applied in sample construction

Two prefecture-month observations are treated as missing rather than as zeros and are excluded during sample preparation:

- Yamanashi in `2016-08`
- Saga in `2016-12`

These were blank cells in the source table underlying the prepared analytical panel.

## 11. Main-text outputs linked to variables

The main-text empirical outputs are built from the variables described above.

### Table 1
Uses the baseline PPML model estimated from the long-format panel.

### Table 2
Uses the main heterogeneity model with `z_male_wage_premium_2015`.

### Figure 1
Uses marginal effects derived from the main heterogeneity model with `z_male_wage_premium_2015`.

### Table 3
Uses the supplementary heterogeneity model with `z_breadwinner_exposure_2015`.

### Figure 2
Uses marginal effects derived from the supplementary heterogeneity model with `z_breadwinner_exposure_2015`.

### Table 4
Uses robustness outputs based on:
- alternative post windows
- models with and without time-varying prefectural controls
- the auxiliary `ln(M/F)` specification

## 12. Notes on interpretation

The variables in this codebook should be interpreted in light of the workflow’s scope.

In particular:

- `bpm_clean.csv` is already an integrated analytical panel
- the contextual variables are already prepared and standardised in `contextual_indicators_2015.csv`
- the repository reproduces the estimation workflow from these prepared inputs
- it does not reconstruct these inputs from the original underlying source tables

For further details on the role of each script and the correspondence between outputs and manuscript results, see:

- `README.md`
- `docs/output_mapping.md`
- `docs/replication_notes.md`
