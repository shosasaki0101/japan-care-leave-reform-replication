# ==========================================
# 07_build_main_text_tables.R
# Build publication-ready main-text tables
# ==========================================

library(data.table)

dir.create("out/tables", showWarnings = FALSE, recursive = TRUE)

# -----------------------------
# 1. Read inputs from previous scripts
# -----------------------------
d1 <- fread("out/tables/D1_core_coefficients.csv")
rob_post <- fread("out/tables/robustness_postwindow_summary.csv")
rob_ctrl <- fread("out/tables/robustness_controls_summary.csv")
rob_ratio <- fread("out/tables/robustness_lnratio_summary.csv")

# -----------------------------
# 2. Helper functions
# -----------------------------

relabel_terms <- function(dt){
  label_map <- c(
    "post2016_clean" = "Post_t",
    "post2016_clean:male" = "Male × Post_t",
    "post2016_clean:z_male_wage_premium_2015" = "Post_t × z_male_wage_premium_2015",
    "post2016_clean:male:z_male_wage_premium_2015" = "Male × Post_t × z_male_wage_premium_2015",
    "post2016_clean:z_breadwinner_exposure_2015" = "Post_t × z_breadwinner_exposure_2015",
    "post2016_clean:male:z_breadwinner_exposure_2015" = "Male × Post_t × z_breadwinner_exposure_2015"
  )
  dt[term %in% names(label_map), term := label_map[term]]
  dt[]
}

format_p_value <- function(p){
  out <- ifelse(is.na(p), NA_character_,
                ifelse(p < 0.001, "<0.001", sprintf("%.3f", round(p, 3))))
  out
}

round_est_cols <- function(dt){
  for (v in intersect(c("estimate", "std_error"), names(dt))) {
    dt[, (v) := round(get(v), 3)]
  }
  dt[]
}

# -----------------------------
# 3. Table 1
# Baseline clean-window PPML estimates
# -----------------------------
table1_raw <- copy(d1)[
  model == "Baseline PPML" &
    term %in% c("post2016_clean", "post2016_clean:male"),
  .(term, estimate, std_error, p_value, N)
]

table1_n <- unique(table1_raw$N)

table1 <- copy(table1_raw)
table1 <- relabel_terms(table1)
table1[, term := factor(term, levels = c("Post_t", "Male × Post_t"))]
setorder(table1, term)
table1[, term := as.character(term)]
table1 <- round_est_cols(table1)
table1[, p_value := format_p_value(p_value)]
table1[, N := NULL]

fwrite(table1, "out/tables/Table1_baseline_clean_window_ppml.csv")
writeLines(
  paste0("Note: N = ", table1_n, "."),
  "out/tables/Table1_note.txt"
)

# -----------------------------
# 4. Table 2
# Main heterogeneity estimates by prefectural male wage premium
# -----------------------------
table2_raw <- copy(d1)[
  model == "Main heterogeneity: male wage premium" &
    term %in% c(
      "post2016_clean:z_male_wage_premium_2015",
      "post2016_clean:male:z_male_wage_premium_2015"
    ),
  .(term, estimate, std_error, p_value, N)
]

table2_n <- unique(table2_raw$N)

table2 <- copy(table2_raw)
table2 <- relabel_terms(table2)
table2[, term := factor(
  term,
  levels = c(
    "Post_t × z_male_wage_premium_2015",
    "Male × Post_t × z_male_wage_premium_2015"
  )
)]
setorder(table2, term)
table2[, term := as.character(term)]
table2 <- round_est_cols(table2)
table2[, p_value := format_p_value(p_value)]
table2[, N := NULL]

fwrite(table2, "out/tables/Table2_main_heterogeneity_male_wage_premium.csv")
writeLines(
  paste0("Note: N = ", table2_n, "."),
  "out/tables/Table2_note.txt"
)

# -----------------------------
# 5. Table 3
# Supplementary heterogeneity estimates by breadwinner exposure
# -----------------------------
table3_raw <- copy(d1)[
  model == "Supplementary heterogeneity: breadwinner exposure" &
    term %in% c(
      "post2016_clean:z_breadwinner_exposure_2015",
      "post2016_clean:male:z_breadwinner_exposure_2015"
    ),
  .(term, estimate, std_error, p_value, N)
]

table3_n <- unique(table3_raw$N)

table3 <- copy(table3_raw)
table3 <- relabel_terms(table3)
table3[, term := factor(
  term,
  levels = c(
    "Post_t × z_breadwinner_exposure_2015",
    "Male × Post_t × z_breadwinner_exposure_2015"
  )
)]
setorder(table3, term)
table3[, term := as.character(term)]
table3 <- round_est_cols(table3)
table3[, p_value := format_p_value(p_value)]
table3[, N := NULL]

fwrite(table3, "out/tables/Table3_supplementary_heterogeneity_breadwinner_exposure.csv")
writeLines(
  paste0("Note: N = ", table3_n, "."),
  "out/tables/Table3_note.txt"
)

# -----------------------------
# 6. Table 4
# Robustness of the main wage-premium heterogeneity result
# Keep N because it differs across specifications
# -----------------------------

# Panel A: Alternative post windows
table4A <- copy(rob_post)[, .(
  panel = "Panel A. Alternative post windows",
  specification = spec,
  estimate,
  std_error,
  p_value,
  N = n_obs
)]

table4A[specification == "A_post_2016-12_to_2017-03", specification := "A: 2016-12 to 2017-03"]
table4A[specification == "B_post_2016-12_to_2017-04", specification := "B: 2016-12 to 2017-04"]
table4A[specification == "C_post_2017-01_to_2017-03", specification := "C: 2017-01 to 2017-03"]
table4A[specification == "D_post_2016-11_to_2017-02", specification := "D: 2016-11 to 2017-02"]

# Panel B: Controls
table4B <- copy(rob_ctrl)[, .(
  panel = "Panel B. Controls",
  specification = spec,
  estimate,
  std_error,
  p_value,
  N = n_obs
)]

table4B[specification == "with_controls", specification := "With controls"]
table4B[specification == "no_controls", specification := "No controls"]

# Panel C: Supplementary log-ratio specification
table4C <- copy(rob_ratio)[, .(
  panel = "Panel C. Supplementary log-ratio specification",
  specification = spec,
  estimate,
  std_error,
  p_value,
  N = n_obs
)]

table4C[specification == "lnratio_with_controls", specification := "With controls"]
table4C[specification == "lnratio_no_controls", specification := "No controls"]

table4 <- rbindlist(list(table4A, table4B, table4C), fill = TRUE)
table4 <- round_est_cols(table4)
table4[, p_value := format_p_value(p_value)]
table4[, N := as.integer(N)]

fwrite(table4, "out/tables/Table4_robustness_main_wage_premium_result.csv")

writeLines(
  c(
    "Note: Panels A and B report the coefficient on Male × Post_t × z_male_wage_premium_2015.",
    "Panel C reports the coefficient on Post_t × z_male_wage_premium_2015 from the auxiliary ln-ratio specification.",
    "Panel C is included only as a directional check and is not directly equivalent to the PPML interaction term."
  ),
  "out/tables/Table4_note.txt"
)

# -----------------------------
# 7. Optional overview file
# -----------------------------
table1_overview <- copy(table1)[, table := "Table 1"]
table2_overview <- copy(table2)[, table := "Table 2"]
table3_overview <- copy(table3)[, table := "Table 3"]

overview_main_tables <- rbindlist(list(
  table1_overview[, .(table, row = term, estimate, std_error, p_value)],
  table2_overview[, .(table, row = term, estimate, std_error, p_value)],
  table3_overview[, .(table, row = term, estimate, std_error, p_value)]
), fill = TRUE)

fwrite(overview_main_tables, "out/tables/Overview_main_text_tables_1_to_3.csv")

cat("07 completed.\n")