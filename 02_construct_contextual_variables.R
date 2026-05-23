# ==========================================
# 02_construct_contextual_variables.R
# Load and merge 2015 contextual indicators
# ==========================================

library(data.table)

bpm <- readRDS("out/checks/01_bpm_loaded.rds")
ctx <- fread("data/derived/contextual_indicators_2015.csv")

required_ctx <- c(
  "pref_id", "pref_name",
  "male_wage_premium_2015", "z_male_wage_premium_2015",
  "dual_earner_share_2015", "z_dual_earner_share_2015",
  "breadwinner_exposure_2015", "z_breadwinner_exposure_2015"
)

missing_ctx <- setdiff(required_ctx, names(ctx))
if (length(missing_ctx) > 0) {
  stop("Missing required columns in contextual_indicators_2015.csv: ",
       paste(missing_ctx, collapse = ", "))
}

ctx[, pref_id := as.integer(pref_id)]

num_ctx <- c(
  "male_wage_premium_2015", "z_male_wage_premium_2015",
  "dual_earner_share_2015", "z_dual_earner_share_2015",
  "breadwinner_exposure_2015", "z_breadwinner_exposure_2015"
)
ctx[, (num_ctx) := lapply(.SD, as.numeric), .SDcols = num_ctx]

if (ctx[, uniqueN(pref_id)] != nrow(ctx)) {
  stop("contextual_indicators_2015.csv contains duplicated prefectures.")
}

# Merge
bpm_ctx <- merge(
  bpm,
  ctx,
  by = c("pref_id", "pref_name"),
  all.x = TRUE
)

# Check missing after merge
ctx_missing <- bpm_ctx[, .(
  n_missing_mw = sum(is.na(male_wage_premium_2015)),
  n_missing_z_mw = sum(is.na(z_male_wage_premium_2015)),
  n_missing_de = sum(is.na(dual_earner_share_2015)),
  n_missing_z_de = sum(is.na(z_dual_earner_share_2015)),
  n_missing_bw = sum(is.na(breadwinner_exposure_2015)),
  n_missing_z_bw = sum(is.na(z_breadwinner_exposure_2015))
)]
fwrite(ctx_missing, "out/checks/contextual_missing_after_merge.csv")

if (any(unlist(ctx_missing) > 0)) {
  stop("Missing contextual values after merge. See out/checks/contextual_missing_after_merge.csv")
}

fwrite(unique(
  bpm_ctx[, .(
    pref_id, pref_name,
    male_wage_premium_2015, z_male_wage_premium_2015,
    dual_earner_share_2015, z_dual_earner_share_2015,
    breadwinner_exposure_2015, z_breadwinner_exposure_2015
  )]
), "out/checks/contextual_variables_summary.csv")

saveRDS(bpm_ctx, "out/checks/02_bpm_with_context.rds")
cat("02 completed.\n")