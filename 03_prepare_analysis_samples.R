# ==========================================
# 03_prepare_analysis_samples.R
# Prepare analysis samples
# ==========================================

library(data.table)

bpm_ctx <- readRDS("out/checks/02_bpm_with_context.rds")

# Exclude flagged cells
bpm_ctx <- bpm_ctx[!(pref_name == "Yamanashi" & year_month == 201608)]
bpm_ctx <- bpm_ctx[!(pref_name == "Saga" & year_month == 201612)]

# Main clean-window definition
# Pre: 2014-01 to 2016-07
# Transition: 2016-08 to 2016-11
# Post: 2016-12 to 2017-03
bpm_ctx[, period_2016cw := fifelse(
  date >= as.Date("2014-01-01") & date <= as.Date("2016-07-01"), "pre",
  fifelse(
    date >= as.Date("2016-08-01") & date <= as.Date("2016-11-01"), "transition",
    fifelse(
      date >= as.Date("2016-12-01") & date <= as.Date("2017-03-01"), "post",
      NA_character_
    )
  )
)]

# Keep only pre and post periods for the main clean-window sample
bpm_2016cw <- bpm_ctx[period_2016cw %in% c("pre", "post")]
bpm_2016cw[, post2016_clean := as.integer(period_2016cw == "post")]

# Ratio panel
ratio_panel <- copy(bpm_2016cw)

# PPML long panel
ppml_panel <- melt(
  bpm_2016cw,
  id.vars = c(
    "pref_id", "pref_name", "year", "month", "year_month", "date",
    "moy", "t_index", "period_2016cw", "post2016_clean",
    "u_rate", "n_ei_insured", "n_care_need_2to5", "n_ltc_facility_users", "share_75plus",
    "z_u_rate", "z_ln_ei", "z_ln_need", "z_ln_fac", "z_oldshare75",
    "ln_ratio_mf", "n_total",
    "male_wage_premium_2015", "z_male_wage_premium_2015",
    "dual_earner_share_2015", "z_dual_earner_share_2015",
    "breadwinner_exposure_2015", "z_breadwinner_exposure_2015"
  ),
  measure.vars = c("n_m", "n_f"),
  variable.name = "sexvar",
  value.name = "n"
)

ppml_panel[, sex := fifelse(sexvar == "n_m", "male", "female")]
ppml_panel[, male := as.integer(sex == "male")]

# Save samples
fwrite(ratio_panel, "out/samples/ratio_panel_2016cw.csv")
fwrite(ppml_panel, "out/samples/ppml_panel_2016cw_long.csv")

saveRDS(ratio_panel, "out/samples/ratio_panel_2016cw.rds")
saveRDS(ppml_panel, "out/samples/ppml_panel_2016cw_long.rds")

sample_summary <- rbindlist(list(
  data.table(sample = "ratio_panel_2016cw", n_obs = nrow(ratio_panel), n_pref = uniqueN(ratio_panel$pref_id)),
  data.table(sample = "ppml_panel_2016cw_long", n_obs = nrow(ppml_panel), n_pref = uniqueN(ppml_panel$pref_id))
))
fwrite(sample_summary, "out/checks/sample_summary.csv")

cat("03 completed.\n")