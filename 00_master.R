# ==========================================
# 00_master.R
# Master script for full replication
# ==========================================

rm(list = ls())

required_pkgs <- c("data.table", "fixest", "ggplot2")
to_install <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(to_install) > 0) install.packages(to_install)

invisible(lapply(required_pkgs, library, character.only = TRUE))

dir.create("out", showWarnings = FALSE, recursive = TRUE)
dir.create("out/checks", showWarnings = FALSE, recursive = TRUE)
dir.create("out/samples", showWarnings = FALSE, recursive = TRUE)
dir.create("out/models", showWarnings = FALSE, recursive = TRUE)
dir.create("out/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("out/figures", showWarnings = FALSE, recursive = TRUE)

source("01_load_panel_and_check_inputs.R")
source("02_construct_contextual_variables.R")
source("03_prepare_analysis_samples.R")
source("04_run_main_models.R")
source("05_run_robustness.R")
source("06_compute_marginal_effects_and_export.R")
source("07_build_main_text_tables.R")

cat("\nAll scripts completed successfully.\n")