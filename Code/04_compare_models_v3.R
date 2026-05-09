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

exact_reloo_path <- file.path(diag_dir, "m1_stier_11_exact_reloo.csv")
exact_reloo_tbl <- if (file.exists(exact_reloo_path)) {
  read_csv(exact_reloo_path, show_col_types = FALSE) %>%
    transmute(
      model,
      exact_reloo_resolved = divergences == 0 &
        treedepth_hits == 0 &
        min_ebfmi >= 0.3,
      exact_reloo_heldout_index = heldout_log_lik_index,
      exact_reloo_year = year,
      exact_reloo_site_name = site_name,
      exact_reloo_pareto_k = pareto_k,
      exact_reloo_psis_elpd = psis_elpd,
      exact_reloo_elpd = exact_elpd,
      exact_reloo_looic_total = looic_total_exact_corrected,
      exact_reloo_looic_delta = looic_total_exact_corrected - looic_total_psis,
      exact_reloo_divergences = divergences,
      exact_reloo_treedepth_hits = treedepth_hits,
      exact_reloo_min_ebfmi = min_ebfmi
    )
} else {
  tibble(
    model = character(),
    exact_reloo_resolved = logical(),
    exact_reloo_heldout_index = integer(),
    exact_reloo_year = integer(),
    exact_reloo_site_name = character(),
    exact_reloo_pareto_k = double(),
    exact_reloo_psis_elpd = double(),
    exact_reloo_elpd = double(),
    exact_reloo_looic_total = double(),
    exact_reloo_looic_delta = double(),
    exact_reloo_divergences = integer(),
    exact_reloo_treedepth_hits = integer(),
    exact_reloo_min_ebfmi = double()
  )
}

comparison_tbl <- audit_tbl %>%
  left_join(ppc_tbl, by = "model") %>%
  left_join(exact_reloo_tbl, by = "model") %>%
  mutate(
    exact_reloo_resolved = coalesce(exact_reloo_resolved, FALSE),
    sampler_health_clean = divergences == 0 &
      treedepth_hits == 0 &
      max_rhat <= 1.01 &
      min_ebfmi >= 0.3,
    psis_loo_clean = max_pareto_k < 0.7,
    loo_resolved = psis_loo_clean | exact_reloo_resolved,
    looic_decision = if_else(
      exact_reloo_resolved & !is.na(exact_reloo_looic_total),
      exact_reloo_looic_total,
      looic
    ),
    sampler_clean = sampler_health_clean,
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
      abs(positive_signal_log_bias) <= 0.35,
    stier_aligned = model == "m1_stier_11",
    loo_unstable_live = artifact_current &
      sampler_health_clean &
      !loo_resolved &
      positive_magnitude_clean
  ) %>%
  group_by(likelihood_unit) %>%
  mutate(
    n_models_same_likelihood = sum(!is.na(looic_decision)),
    looic_comparable = n_models_same_likelihood > 1,
    looic_rank_within_unit = if_else(
      is.na(looic_decision),
      NA_integer_,
      min_rank(looic_decision)
    )
  ) %>%
  ungroup() %>%
  mutate(
    promoted_baseline = sampler_clean &
      loo_resolved &
      artifact_current &
      positive_magnitude_clean &
      (
        (
          likelihood_unit == "surveyed_cells" &
            zero_calibration_gap <= 2
        ) |
          (
            stier_aligned &
              likelihood_unit == "positive_only"
          )
      ),
    comparison_status = case_when(
      !artifact_current ~ "stale_refit_required",
      !sampler_health_clean ~ "archived_excluded",
      loo_unstable_live ~ "loo_unstable_live_candidate",
      sampler_health_clean & !loo_resolved ~ "loo_unstable_review",
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
    desc(loo_unstable_live),
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
