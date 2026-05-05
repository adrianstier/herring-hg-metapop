# ============================================================================
# 04_compare_models_v3.R
# Compact comparison table for completed herring models.
#
# Combines:
#   - sampler health / PSIS diagnostics,
#   - LOO summaries,
#   - posterior predictive calibration on detections / censored zeros.
#
# Raw LOOIC is only ranked within matching likelihood units.
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
ppc_path <- if (file.exists(file.path(diag_dir, "posterior_predictive_summary.csv"))) {
  file.path(diag_dir, "posterior_predictive_summary.csv")
} else {
  file.path(diag_dir, "posterior_predictive_summary_v3.csv")
}

if (!file.exists(audit_path) || !file.exists(ppc_path)) {
  stop("Run 03c_bayesian_fit_audit.R and 03d_posterior_predictive_checks_v3.R first.")
}

audit_tbl <- read_csv(audit_path, show_col_types = FALSE)
if (!"artifact_current" %in% names(audit_tbl)) {
  audit_tbl$artifact_current <- TRUE
}
ppc_tbl <- read_csv(ppc_path, show_col_types = FALSE) %>%
  mutate(abs_gap = abs(pred_median - observed)) %>%
  select(model, metric, observed, pred_median, abs_gap, ppc_p_lower, ppc_p_upper) %>%
  pivot_wider(
    names_from = metric,
    values_from = c(observed, pred_median, abs_gap, ppc_p_lower, ppc_p_upper),
    names_sep = "__"
  )

for (col in c(
  "pred_median__aggregate_positive_signal_log_rmse",
  "pred_median__aggregate_positive_signal_log_bias"
)) {
  if (!col %in% names(ppc_tbl)) {
    ppc_tbl[[col]] <- NA_real_
  }
}

comparison_tbl <- audit_tbl %>%
  left_join(ppc_tbl, by = "model") %>%
  mutate(
    sampler_clean = divergences == 0 &
      treedepth_hits == 0 &
      max_rhat <= 1.01 &
      min_ebfmi >= 0.3 &
      max_pareto_k < 0.7,
    zero_calibration_gap = abs_gap__total_below_detection_surveys,
    occupied_sections_rmse = pred_median__occupied_sections_rmse,
    positive_signal_log_rmse = coalesce(
      pred_median__aggregate_positive_signal_log_rmse,
      Inf
    ),
    positive_signal_log_bias = coalesce(
      pred_median__aggregate_positive_signal_log_bias,
      Inf
    ),
    positive_magnitude_clean = positive_signal_log_rmse <= 0.75 &
      abs(positive_signal_log_bias) <= 0.35
  ) %>%
  group_by(likelihood_unit) %>%
  mutate(
    n_models_same_likelihood = sum(!is.na(looic)),
    looic_comparable = n_models_same_likelihood > 1,
    looic_rank_within_unit = if_else(
      is.na(looic),
      NA_integer_,
      min_rank(looic)
    )
  ) %>%
  ungroup() %>%
  mutate(
    promoted_baseline = sampler_clean &
      artifact_current &
      likelihood_unit == "surveyed_cells" &
      zero_calibration_gap <= 2 &
      positive_magnitude_clean,
    comparison_status = case_when(
      !artifact_current ~ "stale_refit_required",
      !sampler_clean ~ "archived_excluded",
      promoted_baseline ~ "promoted_baseline",
      likelihood_unit == "surveyed_cells" &
        zero_calibration_gap <= 2 &
        !positive_magnitude_clean ~ "hold_positive_magnitude_miscalibration",
      likelihood_unit == "surveyed_cells" ~ "hold_for_future_cleanup",
      looic_rank_within_unit == 1 ~ "within_unit_reference",
      TRUE ~ "candidate"
    )
  ) %>%
  arrange(
    desc(promoted_baseline),
    desc(artifact_current),
    desc(sampler_clean),
    likelihood_unit,
    looic_rank_within_unit,
    zero_calibration_gap,
    positive_signal_log_rmse,
    occupied_sections_rmse
  )

write_csv(comparison_tbl, file.path(diag_dir, "model_comparison.csv"))
write_csv(comparison_tbl, file.path(diag_dir, "model_comparison_v3.csv"))
print(comparison_tbl)
