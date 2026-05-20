# ============================================================================
# 04d_decide_next_after_m1_v4.R
# Decide whether m1_v4 is clean enough to promote as the baseline.
# ============================================================================

library(tidyverse)
library(here)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

audit_path <- if (file.exists(file.path(diag_dir, "bayesian_fit_audit.csv"))) {
  file.path(diag_dir, "bayesian_fit_audit.csv")
} else {
  file.path(diag_dir, "bayesian_fit_audit_v3.csv")
}

comparison_path <- if (file.exists(file.path(diag_dir, "model_comparison.csv"))) {
  file.path(diag_dir, "model_comparison.csv")
} else {
  file.path(diag_dir, "model_comparison_v3.csv")
}

ppc_path <- if (file.exists(file.path(diag_dir, "posterior_predictive_summary.csv"))) {
  file.path(diag_dir, "posterior_predictive_summary.csv")
} else {
  file.path(diag_dir, "posterior_predictive_summary_v3.csv")
}

stopifnot(
  file.exists(audit_path),
  file.exists(comparison_path),
  file.exists(ppc_path)
)

audit_tbl <- read_csv(audit_path, show_col_types = FALSE)
comparison_tbl <- read_csv(comparison_path, show_col_types = FALSE)
ppc_tbl <- read_csv(ppc_path, show_col_types = FALSE)
if (!"artifact_current" %in% names(audit_tbl)) {
  audit_tbl$artifact_current <- TRUE
}
if (!"artifact_current" %in% names(comparison_tbl)) {
  comparison_tbl$artifact_current <- TRUE
}

m1_audit <- audit_tbl %>%
  filter(model == "m1_v4") %>%
  slice(1)

m1_compare <- comparison_tbl %>%
  filter(model == "m1_v4") %>%
  slice(1)

m1_ppc_zero <- ppc_tbl %>%
  filter(model == "m1_v4", metric == "total_below_detection_surveys") %>%
  slice(1)

if (nrow(m1_audit) != 1 || nrow(m1_compare) != 1 || nrow(m1_ppc_zero) != 1) {
  stop("Could not find a complete m1_v4 diagnostic record.")
}

sampler_clean <- with(
  m1_audit,
  divergences == 0 &&
    treedepth_hits == 0 &&
    max_rhat <= 1.01 &&
    min_ebfmi >= 0.3 &&
    max_pareto_k < 0.7
)

zero_gap <- abs(m1_ppc_zero$pred_median - m1_ppc_zero$observed)
zero_good <- zero_gap <= 2
positive_rmse <- m1_compare$positive_signal_log_rmse
positive_bias <- m1_compare$positive_signal_log_bias
positive_good <- isTRUE(positive_rmse <= 0.75 && abs(positive_bias) <= 0.35)
artifact_current <- isTRUE(m1_compare$artifact_current)

promote_baseline <- artifact_current && sampler_clean && zero_good && positive_good

action_file <- file.path(diag_dir, "m1_v4_next_action.txt")
decision_file <- file.path(diag_dir, "m1_v4_next_step_decision.md")

action <- if (promote_baseline) "promote_m1_v4_hold_complexity" else "hold_for_cleanup"
writeLines(action, action_file)

lines <- c(
  "# m1_v4 Next-Step Decision",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Decision",
  "",
  paste0("- Action: `", action, "`."),
  "",
  "## m1_v4 Checks",
  "",
  paste0("- Divergences: ", m1_audit$divergences),
  paste0("- Treedepth hits: ", m1_audit$treedepth_hits),
  paste0("- Max R-hat: ", round(m1_audit$max_rhat, 4)),
  paste0("- Min E-BFMI: ", round(m1_audit$min_ebfmi, 4)),
  paste0("- Max Pareto k: ", round(m1_audit$max_pareto_k, 4)),
  paste0("- Artifact current: ", artifact_current),
  paste0("- Surveyed-zero gap: ", round(zero_gap, 1)),
  paste0("- Aggregate positive-signal log10 RMSE: ", round(positive_rmse, 3)),
  paste0("- Aggregate positive-signal log10 bias: ", round(positive_bias, 3)),
  ""
)

if (promote_baseline) {
  lines <- c(
    lines,
    "## Interpretation",
    "",
	    "- `m1_v4` is clean enough to promote as the working baseline.",
	    "- Freeze richer process branches by default.",
	    "- Do not auto-launch richer process branches unless a new branch is explicitly requested."
  )
} else {
  fail_reasons <- c()
  if (!sampler_clean) {
    fail_reasons <- c(fail_reasons, "- Sampler criteria not met.")
  }
  if (!artifact_current) {
    fail_reasons <- c(fail_reasons, "- Fit artifacts are stale relative to source files and need a refit.")
  }
  if (!zero_good) {
    fail_reasons <- c(fail_reasons, "- Surveyed-zero calibration is still too far off.")
  }
  if (!positive_good) {
    fail_reasons <- c(fail_reasons, "- Positive-magnitude calibration is still too far off.")
  }

  lines <- c(
    lines,
    "## Interpretation",
    "",
    "- `m1_v4` is not yet clean enough to promote.",
    fail_reasons,
    "- Do not advance process complexity yet. Do one more observation-model cleanup pass."
  )
}

writeLines(lines, decision_file)
cat(paste(lines, collapse = "\n"))
