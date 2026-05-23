# Replication Notes

This document records the main analytical choices, implementation conventions, and scope conditions used in the replication workflow for the prefecture-month analysis of Japan’s 2016 care-leave benefit reform.

It is intended to supplement `README.md`, `docs/codebook.md`, and `docs/output_mapping.md` by documenting why the analysis is structured as it is and how specific implementation decisions should be interpreted.

## 1. Scope of the replication materials

The repository reproduces the empirical analysis from two prepared input files:

- `data/derived/bpm_clean.csv`
- `data/derived/contextual_indicators_2015.csv`

The workflow does **not** reconstruct the analytical panel from the original administrative and statistical source tables. Instead, it begins from the integrated prefecture-month analytical panel and the prefectural contextual-indicator file included in the repository.

Accordingly, the replication materials should be understood as reproducing:

- sample construction
- model estimation
- robustness checks
- marginal-effect calculations
- manuscript tables and figures

They do not reproduce the earlier data-integration stage that combined the original source tables into the final analytical panel.

## 2. Analytical unit and sample structure

The core analytical unit is the **prefecture-month** observation.

The main input panel in `bpm_clean.csv` contains one row per prefecture and month, with separate counts for men and women:

- `n_m`
- `n_f`

The PPML models are estimated on a **long-format prefecture-month-sex panel** created from this input panel. In this long format:

- each prefecture-month contributes one male observation and one female observation
- the dependent variable is the sex-specific count of care-leave benefit recipients
- `male` is a binary indicator for the male observation
- prefecture and sex fixed effects are included in the baseline specification

The auxiliary `ln(M/F)` specification is estimated on the wide prefecture-month panel.

## 3. Main clean-window design

The main analysis uses a conservative clean-window design around the 2016 reform.

The primary windows are:

- **Pre-reform baseline:** `2014-01` to `2016-07`
- **Transition interval excluded from the main specification:** `2016-08` to `2016-11`
- **Main post-reform period:** `2016-12` to `2017-03`

This design is used to reduce contamination from two sources.

First, care-leave benefit statistics are claims-based administrative data rather than contemporaneous measures of leave initiation. There may therefore be a lag between leave-taking, filing, claims processing, and the appearance of cases in the recorded monthly benefit data.

Second, an additional institutional change took effect in January 2017. The main post window is therefore chosen to isolate the 2016 reform as conservatively as possible while still allowing sufficient post-reform observations for estimation.

The public analytical panel extends to `2017-04` so that alternative post-window robustness checks can also be reproduced.

## 4. Blank source entries treated as missing

Two prefecture-month cells were blank in the source table and are treated as missing rather than as zeros:

- **Yamanashi, 2016-08**
- **Saga, 2016-12**

These observations are explicitly checked in `01_load_panel_and_check_inputs.R` and excluded in `03_prepare_analysis_samples.R`.

This treatment reflects the principle that blank source cells should not automatically be interpreted as true zero counts when the original table structure suggests missingness.

## 5. Contextual indicators and heterogeneity analysis

The heterogeneity analysis relies on prefecture-level contextual indicators measured for 2015 and stored in `contextual_indicators_2015.csv`.

The required indicators are:

- `male_wage_premium_2015`
- `z_male_wage_premium_2015`
- `dual_earner_share_2015`
- `z_dual_earner_share_2015`
- `breadwinner_exposure_2015`
- `z_breadwinner_exposure_2015`

The main heterogeneity analysis uses `z_male_wage_premium_2015`. This variable is intended to capture cross-prefectural differences in gendered earning structure and, by implication, differences in the opportunity-cost environment facing potential male leave-takers.

The supplementary heterogeneity analysis uses `z_breadwinner_exposure_2015`. This variable is intended to capture a broader dimension of breadwinner-oriented household structure.

`dual_earner_share_2015` and `z_dual_earner_share_2015` are retained in the merged panel for completeness, even though they are not used in the final main-text models.

## 6. Baseline model specification

The baseline model is estimated using Poisson pseudo-maximum likelihood (PPML) on the long prefecture-month-sex panel.

The baseline PPML specification includes:

- `post2016_clean`
- `male × post2016_clean`
- prefecture fixed effects
- sex fixed effects
- a linear time trend (`t_index`)
- month-of-year indicators (`i(moy)`)
- time-varying prefectural controls

The main baseline coefficient of interest is `male × post2016_clean`, which captures whether the post-reform shift for men differs from that for women in the average specification.

## 7. Time-varying prefectural controls

The baseline PPML specification includes the following time-varying prefectural controls:

- `z_u_rate`
- `z_ln_ei`
- `z_ln_need`
- `z_ln_fac`
- `z_oldshare75`

These correspond to:

- unemployment rate
- logged employment-insurance insured persons
- logged number of certified care-need persons
- logged number of long-term-care facility users
- share of the population aged 75 and above

In the robustness analysis, a no-controls specification removes these five time-varying prefectural controls while retaining:

- prefecture fixed effects
- sex fixed effects
- the linear time trend
- month-of-year indicators

This distinction is important: the “no-controls” specification is not an uncontrolled model in the broad sense, but rather a model without the additional time-varying prefectural covariates.

## 8. Main heterogeneity specification

The main heterogeneity model augments the baseline PPML specification with interactions involving the standardised male wage premium:

- `post2016_clean × z_male_wage_premium_2015`
- `male × post2016_clean × z_male_wage_premium_2015`

The first term captures whether the female baseline post-reform shift varies by prefectural wage structure.

The second term captures whether the additional male-specific post-reform shift is larger in prefectures with a higher male wage premium.

The main-text interpretation centres on the three-way interaction term.

## 9. Supplementary heterogeneity specification

The supplementary heterogeneity model parallels the main heterogeneity model but replaces the wage-premium variable with breadwinner exposure:

- `post2016_clean × z_breadwinner_exposure_2015`
- `male × post2016_clean × z_breadwinner_exposure_2015`

This model is treated as supplementary rather than primary. In the manuscript, its role is to assess whether a broader proxy for breadwinner-oriented household structure yields directionally similar evidence to the wage-premium specification.

## 10. Auxiliary ln-ratio specification

The auxiliary `ln(M/F)` specification uses `ln_ratio_mf` as the dependent variable in a prefecture fixed-effects linear model.

This specification serves as a **directional robustness check**, not as a direct substitute for the PPML models.

Accordingly, the coefficient reported in the auxiliary specification is not directly equivalent to the PPML three-way interaction term. It is used only to assess whether the sign and broad directional pattern of the main heterogeneity result remain consistent under an alternative outcome definition.

## 11. Robustness checks

The robustness workflow includes three groups of checks.

### 11.1 Alternative post windows

The main wage-premium heterogeneity coefficient is re-estimated under alternative post-window definitions:

- `2016-12` to `2017-03`
- `2016-12` to `2017-04`
- `2017-01` to `2017-03`
- `2016-11` to `2017-02`

These checks assess whether the main heterogeneity result depends narrowly on a single post-window choice.

### 11.2 With and without time-varying prefectural controls

The main wage-premium heterogeneity specification is estimated both with and without the five time-varying prefectural controls listed above.

These checks assess whether the main heterogeneity result is sensitive to the inclusion of those controls.

### 11.3 Auxiliary ln-ratio specification

The wage-premium heterogeneity term is also estimated in the auxiliary `ln(M/F)` specification, with and without controls.

This check is interpreted only as a directional comparison.

## 12. Marginal effects at representative values

Marginal effects are computed for the male-specific post-reform component at representative values of the contextual variables:

- low (`-1 SD`)
- mean (`0 SD`)
- high (`+1 SD`)

These are reported for:

- prefectural male wage premium
- breadwinner exposure

The marginal effects are exported both as appendix-style tables and as the basis for the main-text figures.

The figures report:

- the estimated percentage effect
- 95% confidence intervals
- representative low / mean / high values of the contextual variable

## 13. Main-text tables and figures

The manuscript’s main-text outputs are formatted in `07_build_main_text_tables.R`.

These outputs are:

- `Table1_baseline_clean_window_ppml.csv`
- `Table2_main_heterogeneity_male_wage_premium.csv`
- `Table3_supplementary_heterogeneity_breadwinner_exposure.csv`
- `Table4_robustness_main_wage_premium_result.csv`
- `Figure1_marginal_effects_wagepremium.png`
- `Figure2_marginal_effects_breadwinner_exposure.png`

The table-building script applies presentation-oriented formatting, including:

- manuscript-oriented term labels
- formatted p-values
- omission of repeated `N` columns in Tables 1–3
- separate note files for table footnotes

The earlier CSV outputs generated in `04`, `05`, and `06` are retained as raw or appendix-style empirical outputs.

## 14. Interpretation conventions

The empirical workflow is designed around a distinction between:

- **average post-reform shifts**
- **male-specific post-reform shifts**
- **heterogeneous male-specific post-reform shifts**

The manuscript therefore treats these as analytically distinct quantities.

In particular:

- the baseline `male × post2016_clean` term is interpreted as the average male-specific post-reform shift
- the three-way interactions in the heterogeneity models are interpreted as whether the male-specific shift varies systematically by prefectural context
- the marginal-effects figures are used to visualise those heterogeneous male-specific shifts at representative values

## 15. Scope limitations of the replication workflow

The workflow reproduces the statistical analysis from the prepared analytical inputs, but it has several built-in scope limitations.

First, it does not reconstruct the analytical panel from raw administrative and statistical releases.

Second, it operates on prefecture-level aggregate data and therefore cannot directly observe:

- household-level bargaining
- kin-network decision processes
- the spatial distribution of siblings or adult children across prefectures
- individual leave duration or filing timing

Third, the auxiliary `ln(M/F)` specification is included only as a supporting robustness check and should not be treated as numerically interchangeable with the PPML estimates.

These limitations should be taken into account when interpreting both the replication workflow and the manuscript’s substantive claims.

## 16. Recommended use

For replication of the manuscript’s final empirical results, the recommended sequence is:

1. run `00_master.R`
2. inspect `out/tables/` and `out/figures/`
3. use the files generated by `07_build_main_text_tables.R` for manuscript tables
4. use the figures generated by `06_compute_marginal_effects_and_export.R` for manuscript figures
5. consult `docs/output_mapping.md` for correspondence between output files and manuscript results

For troubleshooting or incremental verification, the scripts may also be run one by one in the order documented in `README.md`.
