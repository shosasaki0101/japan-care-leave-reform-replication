# ==========================================
# 04_run_main_models.R
# Run main models
# ==========================================

library(data.table)
library(fixest)

ratio_panel <- readRDS("out/samples/ratio_panel_2016cw.rds")
ppml_panel  <- readRDS("out/samples/ppml_panel_2016cw_long.rds")

# Baseline PPML
m_base <- fepois(
  n ~ post2016_clean +
    male:post2016_clean +
    t_index + i(moy) +
    z_u_rate + z_ln_ei + z_ln_need + z_ln_fac + z_oldshare75 |
    pref_id + sex,
  data = ppml_panel,
  cluster = ~pref_id
)

# Main heterogeneity: male wage premium
m_het1 <- fepois(
  n ~ post2016_clean +
    male:post2016_clean +
    post2016_clean:z_male_wage_premium_2015 +
    male:post2016_clean:z_male_wage_premium_2015 +
    t_index + i(moy) +
    z_u_rate + z_ln_ei + z_ln_need + z_ln_fac + z_oldshare75 |
    pref_id + sex,
  data = ppml_panel,
  cluster = ~pref_id
)

# Supplementary heterogeneity: breadwinner exposure
m_bread <- fepois(
  n ~ post2016_clean +
    male:post2016_clean +
    post2016_clean:z_breadwinner_exposure_2015 +
    male:post2016_clean:z_breadwinner_exposure_2015 +
    t_index + i(moy) +
    z_u_rate + z_ln_ei + z_ln_need + z_ln_fac + z_oldshare75 |
    pref_id + sex,
  data = ppml_panel,
  cluster = ~pref_id
)

saveRDS(m_base, "out/models/m_base.rds")
saveRDS(m_het1, "out/models/m_het1.rds")
saveRDS(m_bread, "out/models/m_bread.rds")

tidy_fixest <- function(m){
  ct <- as.data.table(coeftable(m), keep.rownames = "term")
  setnames(ct,
           old = c("Estimate", "Std. Error", "z value", "Pr(>|z|)"),
           new = c("estimate", "std_error", "z_value", "p_value"),
           skip_absent = TRUE)
  ct[]
}

d1_base <- tidy_fixest(m_base)[
  term %in% c("post2016_clean", "post2016_clean:male")
][, model := "Baseline PPML"]

d1_mw <- tidy_fixest(m_het1)[
  term %in% c(
    "post2016_clean",
    "post2016_clean:male",
    "post2016_clean:z_male_wage_premium_2015",
    "post2016_clean:male:z_male_wage_premium_2015"
  )
][, model := "Main heterogeneity: male wage premium"]

d1_bw <- tidy_fixest(m_bread)[
  term %in% c(
    "post2016_clean",
    "post2016_clean:male",
    "post2016_clean:z_breadwinner_exposure_2015",
    "post2016_clean:male:z_breadwinner_exposure_2015"
  )
][, model := "Supplementary heterogeneity: breadwinner exposure"]

d1_all <- rbindlist(list(d1_base, d1_mw, d1_bw), fill = TRUE)
d1_all[, N := c(rep(nobs(m_base), nrow(d1_base)),
                rep(nobs(m_het1), nrow(d1_mw)),
                rep(nobs(m_bread), nrow(d1_bw)))]

fwrite(d1_all, "out/tables/D1_core_coefficients.csv")
cat("04 completed.\n")