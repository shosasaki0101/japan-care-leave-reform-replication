# ==========================================
# 01_load_panel_and_check_inputs.R
# Load bpm_clean.csv and perform input checks
# ==========================================

library(data.table)

bpm <- fread("data/derived/bpm_clean.csv")

required_cols <- c(
  "pref_id", "pref_name", "year", "month", "year_month", "date",
  "n_m", "n_f", "n_total", "ln_ratio_mf",
  "u_rate", "n_ei_insured", "n_care_need_2to5", "n_ltc_facility_users",
  "share_75plus", "z_u_rate", "z_ln_ei", "z_ln_need", "z_ln_fac", "z_oldshare75",
  "moy", "t_index", "ln_ei", "ln_need", "ln_fac"
)

missing_cols <- setdiff(required_cols, names(bpm))
if (length(missing_cols) > 0) {
  stop("Missing required columns in bpm_clean.csv: ",
       paste(missing_cols, collapse = ", "))
}

# Type handling
bpm[, pref_id := as.integer(pref_id)]
bpm[, year := as.integer(year)]
bpm[, month := as.integer(month)]
bpm[, year_month := as.integer(year_month)]
bpm[, date := as.Date(date)]

# Duplicate check
dup_dt <- bpm[duplicated(bpm, by = c("pref_id", "year_month"))]
fwrite(dup_dt, "out/checks/duplicate_prefid_yearmonth.csv")
if (nrow(dup_dt) > 0) {
  stop("Duplicate pref_id-year_month rows found. See out/checks/duplicate_prefid_yearmonth.csv")
}

# Range check
range_check <- bpm[, .(
  min_year_month = min(year_month, na.rm = TRUE),
  max_year_month = max(year_month, na.rm = TRUE),
  min_date = min(date, na.rm = TRUE),
  max_date = max(date, na.rm = TRUE),
  n_rows = .N,
  n_pref = uniqueN(pref_id)
)]
fwrite(range_check, "out/checks/year_month_range_check.csv")

# Missingness check
miss_check <- data.table(
  variable = names(bpm),
  n_missing = sapply(bpm, function(x) sum(is.na(x))),
  share_missing = sapply(bpm, function(x) mean(is.na(x)))
)
fwrite(miss_check, "out/checks/missingness_check.csv")

# Blank-string check
char_vars <- names(bpm)[sapply(bpm, is.character)]
blank_check <- rbindlist(lapply(char_vars, function(v){
  data.table(
    variable = v,
    n_blank = sum(trimws(bpm[[v]]) == "", na.rm = TRUE)
  )
}), fill = TRUE)
fwrite(blank_check, "out/checks/blank_string_check.csv")

# User-specified row checks
check_yamanashi_201608 <- bpm[pref_name == "Yamanashi" & year_month == 201608]
check_saga_201612      <- bpm[pref_name == "Saga" & year_month == 201612]

fwrite(check_yamanashi_201608, "out/checks/check_Yamanashi_201608.csv")
fwrite(check_saga_201612, "out/checks/check_Saga_201612.csv")

# Basic summary
summary_vars <- c(
  "n_m", "n_f", "n_total", "ln_ratio_mf",
  "u_rate", "n_ei_insured", "n_care_need_2to5", "n_ltc_facility_users",
  "share_75plus"
)

basic_summary <- rbindlist(lapply(summary_vars, function(v){
  x <- bpm[[v]]
  data.table(
    variable = v,
    mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE),
    p25 = as.numeric(quantile(x, 0.25, na.rm = TRUE)),
    median = median(x, na.rm = TRUE),
    p75 = as.numeric(quantile(x, 0.75, na.rm = TRUE)),
    max = max(x, na.rm = TRUE)
  )
}), fill = TRUE)
fwrite(basic_summary, "out/checks/basic_summary.csv")

saveRDS(bpm, "out/checks/01_bpm_loaded.rds")
cat("01 completed.\n")