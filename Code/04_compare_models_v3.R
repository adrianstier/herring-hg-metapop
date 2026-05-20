# ============================================================================
# 04_compare_models_v3.R
# Compact comparison table for completed herring models.
#
# Combines:
#   - sampler health / PSIS diagnostics,
#   - LOO summaries,
#   - posterior predictive calibration on detections / censored zeros,
#   - catch accounting/removal consistency.
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
  "pred_median__aggregate_positive_signal_log_bias",
  "pred_median__catch_log_rmse",
  "pred_median__catch_log_bias"
)) {
  if (!col %in% names(ppc_tbl)) {
    ppc_tbl[[col]] <- NA_real_
  }
}

exact_reloo_files <- list.files(
  diag_dir,
  pattern = "(_exact_reloo|_triage_reloo)\\.csv$",
  full.names = TRUE
)
exact_reloo_tbl <- if (length(exact_reloo_files) > 0) {
  raw_exact_reloo <- map_dfr(
    exact_reloo_files,
    ~ read_csv(.x, show_col_types = FALSE),
    .id = "source_id"
  )

  for (col in c("n_high_pareto_total", "n_exact_refit_completed")) {
    if (!col %in% names(raw_exact_reloo)) {
      raw_exact_reloo[[col]] <- NA_integer_
    }
  }
  if (!"exact_looic_point" %in% names(raw_exact_reloo)) {
    raw_exact_reloo$exact_looic_point <- -2 * raw_exact_reloo$exact_elpd
  }

  raw_exact_reloo %>%
    mutate(
      refit_clean = divergences == 0 & treedepth_hits == 0 & min_ebfmi >= 0.3
    ) %>%
    group_by(model) %>%
    summarise(
      n_required = if (all(is.na(n_high_pareto_total))) {
        n()
      } else {
        max(n_high_pareto_total, na.rm = TRUE)
      },
      n_completed = if (all(is.na(n_exact_refit_completed))) {
        n()
      } else {
        max(n_exact_refit_completed, na.rm = TRUE)
      },
      exact_reloo_completed = n_completed >= n_required,
      exact_reloo_refits_clean = all(refit_clean) &
        n_completed >= n_required,
      exact_reloo_resolved = exact_reloo_completed,
      exact_reloo_heldout_index = paste(heldout_log_lik_index, collapse = ";"),
      exact_reloo_year = paste(year, collapse = ";"),
      exact_reloo_site_name = paste(site_name, collapse = ";"),
      exact_reloo_pareto_k = max(pareto_k, na.rm = TRUE),
      exact_reloo_psis_elpd = sum(psis_elpd, na.rm = TRUE),
      exact_reloo_elpd = sum(exact_elpd, na.rm = TRUE),
      exact_reloo_looic_total = first(looic_total_psis) -
        sum(psis_looic_point, na.rm = TRUE) +
        sum(exact_looic_point, na.rm = TRUE),
      exact_reloo_looic_delta = exact_reloo_looic_total - first(looic_total_psis),
      exact_reloo_divergences = sum(divergences, na.rm = TRUE),
      exact_reloo_treedepth_hits = sum(treedepth_hits, na.rm = TRUE),
      exact_reloo_min_ebfmi = min(min_ebfmi, na.rm = TRUE),
      .groups = "drop"
    )
} else {
  tibble(
    model = character(),
    exact_reloo_completed = logical(),
    exact_reloo_refits_clean = logical(),
    exact_reloo_resolved = logical(),
    exact_reloo_heldout_index = character(),
    exact_reloo_year = character(),
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
    exact_reloo_completed = coalesce(exact_reloo_completed, FALSE),
    exact_reloo_refits_clean = coalesce(exact_reloo_refits_clean, FALSE),
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
    catch_log_rmse = coalesce(pred_median__catch_log_rmse, Inf),
    catch_log_bias = coalesce(pred_median__catch_log_bias, Inf),
    catch_fit_clean = catch_log_rmse <= 0.10 &
      abs(catch_log_bias) <= 0.05,
    stier_aligned = model == "m1_stier_11",
    observation_sensitivity = model %in% c(
      "m1_stier_method_sensitivity",
      "m1_stier_obs_hier"
    ),
    process_extension = model %in% c(
      "m2_stier_site_growth",
      "m3_stier_distance",
      "m5_stier_predation_pressure",
      "m5_stier_predator_demand_total",
      "m5_stier_doherty_mp_covariate",
      "m5_stier_doherty_proxy_removals",
      "m5_v5",
      "m5_combined"
    ),
    loo_unstable_live = artifact_current &
      sampler_health_clean &
      !loo_resolved &
      positive_magnitude_clean &
      catch_fit_clean
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
    promoted_baseline_positive_rmse = {
      baseline_rmse <- positive_signal_log_rmse[
        model == "m1_stier_11" &
          artifact_current &
          positive_magnitude_clean
      ]
      if (length(baseline_rmse) == 0) {
        NA_real_
      } else {
        baseline_rmse[1]
      }
    },
    process_extension_no_fit_gain = artifact_current &
      sampler_clean &
      likelihood_unit == "positive_only" &
      process_extension &
      positive_magnitude_clean &
      catch_fit_clean &
      !is.na(promoted_baseline_positive_rmse) &
      positive_signal_log_rmse >= promoted_baseline_positive_rmse - 0.02,
    observation_sensitivity_no_fit_gain = artifact_current &
      sampler_clean &
      likelihood_unit == "positive_only" &
      observation_sensitivity &
      positive_magnitude_clean &
      catch_fit_clean &
      !is.na(promoted_baseline_positive_rmse) &
      positive_signal_log_rmse >= promoted_baseline_positive_rmse - 0.02,
    promoted_baseline = sampler_clean &
      loo_resolved &
      artifact_current &
      positive_magnitude_clean &
      catch_fit_clean &
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
    process_extension_candidate = artifact_current &
      sampler_clean &
      loo_resolved &
      likelihood_unit == "positive_only" &
      process_extension &
      positive_magnitude_clean &
      catch_fit_clean &
      looic_rank_within_unit == 1,
    observation_sensitivity_candidate = artifact_current &
      sampler_clean &
      loo_resolved &
      likelihood_unit == "positive_only" &
      observation_sensitivity &
      positive_magnitude_clean &
      catch_fit_clean &
      looic_rank_within_unit == 1,
    comparison_status = case_when(
      model == "m5_combined" & !sampler_health_clean ~ "archived_excluded",
      model == "m5_combined" & !positive_magnitude_clean ~ "archived_excluded",
      model == "m5_combined" & !catch_fit_clean ~ "archived_excluded",
      !artifact_current ~ "stale_refit_required",
      !sampler_health_clean ~ "archived_excluded",
      observation_sensitivity_no_fit_gain ~ "hold_observation_sensitivity_no_fit_gain",
      process_extension_no_fit_gain ~ "hold_process_extension_no_fit_gain",
      loo_unstable_live ~ "loo_unstable_live_candidate",
      sampler_health_clean & !loo_resolved ~ "loo_unstable_review",
      sampler_health_clean & !catch_fit_clean ~ "hold_catch_fit_miscalibration",
      promoted_baseline ~ "promoted_baseline",
      observation_sensitivity_candidate ~ "observation_sensitivity_candidate",
      process_extension_candidate ~ "process_extension_candidate",
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
    desc(observation_sensitivity_candidate),
    desc(process_extension_candidate),
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
