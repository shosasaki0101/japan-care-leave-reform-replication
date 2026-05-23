# ==========================================
# 05_run_robustness.R
# Run robustness checks
# ==========================================

library(data.table)
library(fixest)

bpm_ctx <- readRDS("out/checks/02_bpm_with_context.rds")

# Same exclusions
bpm_ctx <- bpm_ctx[!(pref_name == "Yamanashi" & year_month == 201608)]
bpm_ctx <- bpm_ctx[!(pref_name == "Saga" & year_month == 201612)]

make_cleanwindow_long <- function(dt, post_start, post_end,
                                  pre_start = "2014-01-01",
                                  pre_end   = "2016-07-01") {
  d <- copy(dt)[
    (date >= as.Date(pre_start) & date <= as.Date(pre_end)) |
      (date >= as.Date(post_start) & date <= as.Date(post_end))
  ]
  d[, post2016_clean := as.integer(date >= as.Date(post_start) & date <= as.Date(post_end))]
  
  L <- melt(
    d,
    id.vars = c(
      "pref_id", "pref_name", "year", "month", "year_month", "date",
      "moy", "t_index", "post2016_clean",
      "u_rate", "n_ei_insured", "n_care_need_2to5", "n_ltc_facility_users", "share_75plus",
      "z_u_rate", "z_ln_ei", "z_ln_need", "z_ln_fac", "z_oldshare75",
      "ln_ratio_mf", "n_total",
      "male_wage_premium_2015", "z_male_wage_premium_2015"
    ),
    measure.vars = c("n_m", "n_f"),
    variable.name = "sexvar",
    value.name = "n"
  )
  L[, sex := fifelse(sexvar == "n_m", "male", "female")]
  L[, male := as.integer(sex == "male")]
  
  list(wide = d, long = L)
}

run_ppml_het <- function(L, with_controls = TRUE){
  if (with_controls) {
    fml <- n ~ post2016_clean +
      male:post2016_clean +
      post2016_clean:z_male_wage_premium_2015 +
      male:post2016_clean:z_male_wage_premium_2015 +
      t_index + i(moy) +
      z_u_rate + z_ln_ei + z_ln_need + z_ln_fac + z_oldshare75 |
      pref_id + sex
  } else {
    fml <- n ~ post2016_clean +
      male:post2016_clean +
      post2016_clean:z_male_wage_premium_2015 +
      male:post2016_clean:z_male_wage_premium_2015 +
      t_index + i(moy) |
      pref_id + sex
  }
  fepois(fml, data = L, cluster = ~pref_id)
}

run_lnratio_het <- function(d, with_controls = TRUE){
  if (with_controls) {
    fml <- ln_ratio_mf ~ post2016_clean +
      post2016_clean:z_male_wage_premium_2015 +
      t_index + i(moy) +
      z_u_rate + z_ln_ei + z_ln_need + z_ln_fac + z_oldshare75 |
      pref_id
  } else {
    fml <- ln_ratio_mf ~ post2016_clean +
      post2016_clean:z_male_wage_premium_2015 +
      t_index + i(moy) |
      pref_id
  }
  feols(fml, data = d, weights = ~n_total, cluster = ~pref_id)
}

extract_term <- function(m, term_name, spec_name){
  ct <- as.data.table(coeftable(m), keep.rownames = "term")
  zcol <- if ("z value" %in% names(ct)) "z value" else if ("t value" %in% names(ct)) "t value" else NA_character_
  pcol <- if ("Pr(>|z|)" %in% names(ct)) "Pr(>|z|)" else if ("Pr(>|t|)" %in% names(ct)) "Pr(>|t|)" else NA_character_
  
  out <- ct[term == term_name]
  data.table(
    spec = spec_name,
    term = term_name,
    estimate = out[["Estimate"]],
    std_error = out[["Std. Error"]],
    stat_value = out[[zcol]],
    p_value = out[[pcol]],
    n_obs = nobs(m)
  )
}

cw_A <- make_cleanwindow_long(bpm_ctx, "2016-12-01", "2017-03-01")
cw_B <- make_cleanwindow_long(bpm_ctx, "2016-12-01", "2017-04-01")
cw_C <- make_cleanwindow_long(bpm_ctx, "2017-01-01", "2017-03-01")
cw_D <- make_cleanwindow_long(bpm_ctx, "2016-11-01", "2017-02-01")

m_A <- run_ppml_het(cw_A$long, TRUE)
m_B <- run_ppml_het(cw_B$long, TRUE)
m_C <- run_ppml_het(cw_C$long, TRUE)
m_D <- run_ppml_het(cw_D$long, TRUE)

triple_term <- "post2016_clean:male:z_male_wage_premium_2015"

robustness_postwindow_summary <- rbindlist(list(
  extract_term(m_A, triple_term, "A_post_2016-12_to_2017-03"),
  extract_term(m_B, triple_term, "B_post_2016-12_to_2017-04"),
  extract_term(m_C, triple_term, "C_post_2017-01_to_2017-03"),
  extract_term(m_D, triple_term, "D_post_2016-11_to_2017-02")
), fill = TRUE)

m_controls_yes <- run_ppml_het(cw_A$long, TRUE)
m_controls_no  <- run_ppml_het(cw_A$long, FALSE)

robustness_controls_summary <- rbindlist(list(
  extract_term(m_controls_yes, triple_term, "with_controls"),
  extract_term(m_controls_no,  triple_term, "no_controls")
), fill = TRUE)

ratio_term <- "post2016_clean:z_male_wage_premium_2015"
m_ratio_yes <- run_lnratio_het(cw_A$wide, TRUE)
m_ratio_no  <- run_lnratio_het(cw_A$wide, FALSE)

robustness_lnratio_summary <- rbindlist(list(
  extract_term(m_ratio_yes, ratio_term, "lnratio_with_controls"),
  extract_term(m_ratio_no,  ratio_term, "lnratio_no_controls")
), fill = TRUE)

fwrite(robustness_postwindow_summary, "out/tables/robustness_postwindow_summary.csv")
fwrite(robustness_controls_summary, "out/tables/robustness_controls_summary.csv")
fwrite(robustness_lnratio_summary, "out/tables/robustness_lnratio_summary.csv")

saveRDS(m_A, "out/models/m_A.rds")
saveRDS(m_B, "out/models/m_B.rds")
saveRDS(m_C, "out/models/m_C.rds")
saveRDS(m_D, "out/models/m_D.rds")
saveRDS(m_controls_yes, "out/models/m_controls_yes.rds")
saveRDS(m_controls_no, "out/models/m_controls_no.rds")
saveRDS(m_ratio_yes, "out/models/m_ratio_yes.rds")
saveRDS(m_ratio_no, "out/models/m_ratio_no.rds")

cat("05 completed.\n")