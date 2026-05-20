# ============================================================================
# 04b_interpret_model_outputs.R
# Write a compact narrative summary of the latest model diagnostics.
# ============================================================================

library(tidyverse)
library(here)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

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

if (!file.exists(comparison_path) || !file.exists(ppc_path)) {
  stop("Run audit/PPC/comparison scripts first.")
}

comparison_tbl <- read_csv(comparison_path, show_col_types = FALSE)
ppc_tbl <- read_csv(ppc_path, show_col_types = FALSE)
if (!"artifact_current" %in% names(comparison_tbl)) {
  comparison_tbl$artifact_current <- TRUE
}

clean_tbl <- comparison_tbl %>%
  filter(artifact_current, sampler_clean)

current_reference <- clean_tbl %>%
  filter(comparison_status == "within_unit_reference") %>%
  slice(1)

surveyed_unit_candidate <- comparison_tbl %>%
  filter(artifact_current, likelihood_unit == "surveyed_cells") %>%
  arrange(
    desc(sampler_clean),
    zero_calibration_gap,
    positive_signal_log_rmse,
    occupied_sections_rmse
  ) %>%
  slice(1)

historical_surveyed_unit_candidate <- comparison_tbl %>%
  filter(likelihood_unit == "surveyed_cells") %>%
  arrange(
    desc(sampler_clean),
    zero_calibration_gap,
    positive_signal_log_rmse,
    occupied_sections_rmse
  ) %>%
  slice(1)

practical_baseline <- comparison_tbl %>%
  filter(comparison_status == "promoted_baseline") %>%
  slice(1)

process_extension_tbl <- comparison_tbl %>%
  filter(comparison_status == "process_extension_candidate")

observation_sensitivity_tbl <- comparison_tbl %>%
  filter(comparison_status == "observation_sensitivity_candidate")

held_process_extension_tbl <- comparison_tbl %>%
  filter(comparison_status == "hold_process_extension_no_fit_gain")

held_observation_sensitivity_tbl <- comparison_tbl %>%
  filter(comparison_status == "hold_observation_sensitivity_no_fit_gain")

loo_unstable_tbl <- comparison_tbl %>%
  filter(comparison_status %in% c(
    "loo_unstable_live_candidate",
    "loo_unstable_review"
  ))

archived_tbl <- comparison_tbl %>%
  filter(comparison_status == "archived_excluded")

stale_tbl <- comparison_tbl %>%
  filter(comparison_status == "stale_refit_required")

exact_reloo_tbl <- comparison_tbl %>%
  filter("exact_reloo_resolved" %in% names(.), exact_reloo_resolved)

ppc_zero_tbl <- ppc_tbl %>%
  filter(metric == "total_below_detection_surveys") %>%
  select(model, observed, pred_median, pred_q05, pred_q95)

ppc_positive_tbl <- ppc_tbl %>%
  filter(metric %in% c(
    "aggregate_positive_signal_log_rmse",
    "aggregate_positive_signal_log_bias"
  )) %>%
  select(model, metric, observed, pred_median, pred_q05, pred_q95)

ppc_catch_tbl <- ppc_tbl %>%
  filter(metric %in% c("catch_log_rmse", "catch_log_bias")) %>%
  select(model, metric, observed, pred_median, pred_q05, pred_q95)

lines <- c(
  "# Latest Model Status",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Current Status",
  ""
)

if (nrow(practical_baseline) == 1) {
  lines <- c(
    lines,
    paste0(
      "- Promoted analysis baseline: `", practical_baseline$model,
      "` (likelihood unit `", practical_baseline$likelihood_unit, "`)."
    ),
    paste0(
      "- Sampler health: divergences=", practical_baseline$divergences,
      ", treedepth hits=", practical_baseline$treedepth_hits,
      ", max R-hat=", round(practical_baseline$max_rhat, 3),
      ", min E-BFMI=", round(practical_baseline$min_ebfmi, 3),
      ", max Pareto k=", round(practical_baseline$max_pareto_k, 3), "."
    ),
    paste0(
      "- Positive-magnitude check: aggregate log10 RMSE=",
      round(practical_baseline$positive_signal_log_rmse, 2),
      ", bias=", round(practical_baseline$positive_signal_log_bias, 2), "."
    ),
    paste0(
      "- Catch accounting check: log RMSE=",
      round(practical_baseline$catch_log_rmse, 3),
      ", bias=", round(practical_baseline$catch_log_bias, 3), "."
    )
  )
  if (practical_baseline$likelihood_unit == "surveyed_cells") {
    lines <- c(
      lines,
      paste0(
        "- Strength: predicted surveyed zeros miss observed zeros by only ",
        round(practical_baseline$zero_calibration_gap, 1), "."
      )
    )
  } else if (practical_baseline$model == "m1_stier_11") {
    lines <- c(
      lines,
      "- Zero-spawn records are treated as ambiguous/missing for this Stier-aligned baseline; zero calibration is descriptive only."
    )
  }
  if (
    "exact_reloo_resolved" %in% names(practical_baseline) &&
      isTRUE(practical_baseline$exact_reloo_resolved)
  ) {
    lines <- c(
      lines,
      paste0(
        "- Exact re-LOO resolved the high Pareto-k point: held-out ",
        practical_baseline$exact_reloo_year, " ",
        practical_baseline$exact_reloo_site_name,
        ", corrected LOOIC=", round(practical_baseline$exact_reloo_looic_total, 2),
        ", delta=", round(practical_baseline$exact_reloo_looic_delta, 2), "."
      )
    )
  }
}

if (nrow(current_reference) == 1) {
  lines <- c(
    lines,
    "",
    "## Within-Unit LOO Reference",
    "",
    paste0(
      "- Positive-only within-unit reference: `", current_reference$model, "` (likelihood unit `",
      current_reference$likelihood_unit, "`)."
    ),
    paste0(
      "- Sampler health: divergences=", current_reference$divergences,
      ", treedepth hits=", current_reference$treedepth_hits,
      ", max R-hat=", round(current_reference$max_rhat, 3),
      ", min E-BFMI=", round(current_reference$min_ebfmi, 3), "."
    ),
    paste0(
      "- Fit metric: LOOIC=", round(current_reference$looic, 2),
      " within the `", current_reference$likelihood_unit, "` comparison set."
    ),
    paste0(
      "- Data-fit gates: positive log10 RMSE=", round(current_reference$positive_signal_log_rmse, 2),
      ", catch log RMSE=", round(current_reference$catch_log_rmse, 3), "."
    ),
    paste0(
      "- Remaining weakness: predicted surveyed zeros miss observed zeros by ",
      round(current_reference$zero_calibration_gap, 1), "."
    )
  )
  if (current_reference$model == "m1_stier_11") {
    lines <- c(
      lines,
      "- For `m1_stier_11`, the zero check is descriptive because the model intentionally treats zero-spawn records as ambiguous/missing."
    )
  }
} else if (nrow(practical_baseline) == 0) {
  lines <- c(lines, "- No model currently passes all promotion gates.")
  if (nrow(loo_unstable_tbl) > 0) {
    live <- loo_unstable_tbl %>% slice(1)
    lines <- c(
      lines,
      paste0(
        "- Live review candidate: `", live$model,
        "` is sampler-clean but has unstable PSIS-LOO",
        " (max Pareto k=", round(live$max_pareto_k, 3),
        ", Pareto k > 1=", live$n_pareto_k_gt_1_0, ")."
      ),
      paste0(
        "- Positive-magnitude check for `", live$model,
        "`: aggregate log10 RMSE=", round(live$positive_signal_log_rmse, 2),
        ", bias=", round(live$positive_signal_log_bias, 2), "."
      )
    )
    if (live$model == "m1_stier_11") {
      lines <- c(
        lines,
        "- Zero-spawn records are intentionally treated as ambiguous/missing for `m1_stier_11`; zero calibration is descriptive only."
      )
    }
  }
}

if (nrow(process_extension_tbl) > 0) {
  process_lines <- pmap_chr(
    process_extension_tbl %>%
      select(
        model, looic_decision, max_pareto_k, divergences, treedepth_hits,
        max_rhat, min_ebfmi, positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
      ),
    function(
        model, looic_decision, max_pareto_k, divergences, treedepth_hits,
        max_rhat, min_ebfmi, positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
    ) {
      paste0(
        "- `", model, "` is a process-extension candidate: corrected/comparable LOOIC=",
        round(looic_decision, 2),
        ", divergences=", divergences,
        ", treedepth hits=", treedepth_hits,
        ", max R-hat=", round(max_rhat, 3),
        ", min E-BFMI=", round(min_ebfmi, 3),
        ", max Pareto k=", round(max_pareto_k, 3),
        ", positive RMSE=", round(positive_signal_log_rmse, 2),
        ", positive bias=", round(positive_signal_log_bias, 2),
        ", catch RMSE=", round(catch_log_rmse, 3),
        ", catch bias=", round(catch_log_bias, 3), "."
      )
    }
  )
  lines <- c(lines, "", "## Process-Extension Candidates", "", process_lines)
}

if (nrow(observation_sensitivity_tbl) > 0) {
  observation_lines <- pmap_chr(
    observation_sensitivity_tbl %>%
      select(
        model, looic_decision, max_pareto_k, divergences, treedepth_hits,
        max_rhat, min_ebfmi, positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
      ),
    function(
        model, looic_decision, max_pareto_k, divergences, treedepth_hits,
        max_rhat, min_ebfmi, positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
    ) {
      paste0(
        "- `", model, "` is an observation-sensitivity candidate: corrected/comparable LOOIC=",
        round(looic_decision, 2),
        ", divergences=", divergences,
        ", treedepth hits=", treedepth_hits,
        ", max R-hat=", round(max_rhat, 3),
        ", min E-BFMI=", round(min_ebfmi, 3),
        ", max Pareto k=", round(max_pareto_k, 3),
        ", positive RMSE=", round(positive_signal_log_rmse, 2),
        ", positive bias=", round(positive_signal_log_bias, 2),
        ", catch RMSE=", round(catch_log_rmse, 3),
        ", catch bias=", round(catch_log_bias, 3), "."
      )
    }
  )
  lines <- c(lines, "", "## Observation-Sensitivity Candidates", "", observation_lines)
}

if (nrow(held_process_extension_tbl) > 0) {
  held_lines <- pmap_chr(
    held_process_extension_tbl %>%
      select(
        model, looic_decision, max_pareto_k, n_pareto_k_gt_0_7,
        positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
      ),
    function(
        model, looic_decision, max_pareto_k, n_pareto_k_gt_0_7,
        positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
    ) {
      paste0(
        "- `", model, "` is held: sampler is usable, but the branch does not improve positive-spawn calibration",
        " relative to the promoted baseline",
        " (LOOIC=", round(looic_decision, 2),
        ", max Pareto k=", round(max_pareto_k, 3),
        ", Pareto k > 0.7=", n_pareto_k_gt_0_7,
        ", positive RMSE=", round(positive_signal_log_rmse, 2),
        ", positive bias=", round(positive_signal_log_bias, 2),
        ", catch RMSE=", round(catch_log_rmse, 3),
        ", catch bias=", round(catch_log_bias, 3), ")."
      )
    }
  )
  lines <- c(lines, "", "## Held Process Extensions", "", held_lines)
}

if (nrow(held_observation_sensitivity_tbl) > 0) {
  held_observation_lines <- pmap_chr(
    held_observation_sensitivity_tbl %>%
      select(
        model, looic_decision, max_pareto_k, n_pareto_k_gt_0_7,
        positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
      ),
    function(
        model, looic_decision, max_pareto_k, n_pareto_k_gt_0_7,
        positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
    ) {
      paste0(
        "- `", model, "` is held: the survey-method sensitivity is sampler-usable, but it does not improve",
        " positive-spawn calibration relative to the promoted baseline",
        " (LOOIC=", round(looic_decision, 2),
        ", max Pareto k=", round(max_pareto_k, 3),
        ", Pareto k > 0.7=", n_pareto_k_gt_0_7,
        ", positive RMSE=", round(positive_signal_log_rmse, 2),
        ", positive bias=", round(positive_signal_log_bias, 2),
        ", catch RMSE=", round(catch_log_rmse, 3),
        ", catch bias=", round(catch_log_bias, 3), ")."
      )
    }
  )
  lines <- c(lines, "", "## Held Observation Sensitivities", "", held_observation_lines)
}

if (nrow(stale_tbl) > 0) {
  stale_lines <- pmap_chr(
    stale_tbl %>%
      select(model, fit_mtime, loo_mtime, source_mtime),
    function(model, fit_mtime, loo_mtime, source_mtime) {
      paste0(
        "- `", model, "` requires refit because source files are newer than artifacts",
        " (fit=", format(as.POSIXct(fit_mtime, origin = "1970-01-01"), "%Y-%m-%d %H:%M"),
        ", LOO=", format(as.POSIXct(loo_mtime, origin = "1970-01-01"), "%Y-%m-%d %H:%M"),
        ", source=", format(as.POSIXct(source_mtime, origin = "1970-01-01"), "%Y-%m-%d %H:%M"), ")."
      )
    }
  )
  lines <- c(lines, "", "## Stale Fit Artifacts", "", stale_lines)
}

if (nrow(archived_tbl) > 0) {
  archived_lines <- pmap_chr(
    archived_tbl %>%
      select(
        model, divergences, treedepth_hits, max_rhat, min_ebfmi,
        max_pareto_k, n_pareto_k_gt_0_7, zero_calibration_gap
      ),
    function(
        model, divergences, treedepth_hits, max_rhat, min_ebfmi,
        max_pareto_k, n_pareto_k_gt_0_7, zero_calibration_gap
    ) {
      paste0(
        "- `", model, "` archived as excluded: divergences=", divergences,
        ", treedepth hits=", treedepth_hits,
        ", max R-hat=", round(max_rhat, 3),
        ", min E-BFMI=", round(min_ebfmi, 3),
        ", max Pareto k=", round(max_pareto_k, 3),
        ", Pareto k > 0.7=", n_pareto_k_gt_0_7,
        ", surveyed-zero gap=", round(zero_calibration_gap, 1), "."
      )
    }
  )
  lines <- c(lines, "", "## Archived Exclusions", "", archived_lines)
}

if (nrow(loo_unstable_tbl) > 0) {
  loo_lines <- pmap_chr(
    loo_unstable_tbl %>%
      select(
        model, max_pareto_k, n_pareto_k_gt_0_7, n_pareto_k_gt_1_0,
        divergences, treedepth_hits, max_rhat, min_ebfmi,
        positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
      ),
    function(
        model, max_pareto_k, n_pareto_k_gt_0_7, n_pareto_k_gt_1_0,
        divergences, treedepth_hits, max_rhat, min_ebfmi,
        positive_signal_log_rmse, positive_signal_log_bias,
        catch_log_rmse, catch_log_bias
    ) {
      paste0(
        "- `", model, "` remains live pending LOO review: divergences=",
        divergences, ", treedepth hits=", treedepth_hits,
        ", max R-hat=", round(max_rhat, 3),
        ", min E-BFMI=", round(min_ebfmi, 3),
        ", max Pareto k=", round(max_pareto_k, 3),
        ", Pareto k > 0.7=", n_pareto_k_gt_0_7,
        ", Pareto k > 1=", n_pareto_k_gt_1_0,
        ", positive RMSE=", round(positive_signal_log_rmse, 2),
        ", positive bias=", round(positive_signal_log_bias, 2),
        ", catch RMSE=", round(catch_log_rmse, 3),
        ", catch bias=", round(catch_log_bias, 3), "."
      )
    }
  )
  lines <- c(lines, "", "## LOO-Unstable Live Candidates", "", loo_lines)
}

if (nrow(exact_reloo_tbl) > 0) {
  exact_lines <- pmap_chr(
    exact_reloo_tbl %>%
      select(
        model, exact_reloo_year, exact_reloo_site_name,
        exact_reloo_pareto_k, exact_reloo_looic_total,
        exact_reloo_looic_delta, exact_reloo_divergences,
        exact_reloo_treedepth_hits, exact_reloo_min_ebfmi
      ),
    function(
        model, exact_reloo_year, exact_reloo_site_name,
        exact_reloo_pareto_k, exact_reloo_looic_total,
        exact_reloo_looic_delta, exact_reloo_divergences,
        exact_reloo_treedepth_hits, exact_reloo_min_ebfmi
    ) {
      paste0(
        "- `", model, "` exact re-LOO resolved held-out ",
        exact_reloo_year, " ", exact_reloo_site_name,
        " (original Pareto k=", round(exact_reloo_pareto_k, 3),
        "): corrected LOOIC=", round(exact_reloo_looic_total, 2),
        ", delta=", round(exact_reloo_looic_delta, 2),
        ", refit divergences=", exact_reloo_divergences,
        ", refit treedepth hits=", exact_reloo_treedepth_hits,
        ", refit min E-BFMI=", round(exact_reloo_min_ebfmi, 3), "."
      )
    }
  )
  lines <- c(lines, "", "## Exact Re-LOO Resolutions", "", exact_lines)
}

lines <- c(lines, "", "## Surveyed-Zero Calibration", "")

if (nrow(ppc_zero_tbl) > 0) {
  zero_lines <- pmap_chr(
    ppc_zero_tbl,
    function(model, observed, pred_median, pred_q05, pred_q95) {
      paste0(
        "- `", model, "`: observed=", observed,
        ", predicted median=", round(pred_median, 1),
        " (90% interval ", round(pred_q05, 1), " to ", round(pred_q95, 1), ")."
      )
    }
  )
  lines <- c(lines, zero_lines)
}

lines <- c(lines, "", "## Positive-Magnitude Calibration", "")

if (nrow(ppc_positive_tbl) > 0) {
  positive_lines <- pmap_chr(
    ppc_positive_tbl,
    function(model, metric, observed, pred_median, pred_q05, pred_q95) {
      label <- recode(
        metric,
        aggregate_positive_signal_log_rmse = "aggregate log10 RMSE",
        aggregate_positive_signal_log_bias = "aggregate log10 bias"
      )
      paste0(
        "- `", model, "` ", label, ": median=", round(pred_median, 2),
        " (90% interval ", round(pred_q05, 2), " to ", round(pred_q95, 2), ")."
      )
    }
  )
  lines <- c(lines, positive_lines)
}

lines <- c(lines, "", "## Catch Accounting Fit", "")

if (nrow(ppc_catch_tbl) > 0) {
  catch_lines <- pmap_chr(
    ppc_catch_tbl,
    function(model, metric, observed, pred_median, pred_q05, pred_q95) {
      label <- recode(
        metric,
        catch_log_rmse = "catch log RMSE",
        catch_log_bias = "catch log bias"
      )
      paste0(
        "- `", model, "` ", label, ": median=", round(pred_median, 3),
        " (90% interval ", round(pred_q05, 3), " to ", round(pred_q95, 3), ")."
      )
    }
  )
  lines <- c(lines, catch_lines)
}

lines <- c(
  lines,
  "",
  "## All-Model Interpretation Guardrails",
  "",
  "- `m1_stier_11` is the only promoted baseline. Use it for headline biomass, recovery, portfolio, and branch-comparison claims.",
  "- Held process and observation branches are context or sensitivity results. Do not interpret their coefficients as promoted mechanisms unless a future branch clears sampler, positive-spawn, catch-fit, and PSIS/exact-reLOO gates.",
  "- Predator branches are especially gated: pressure ratios can include the herring response in the denominator, total demand is regional and time-confounded, and section-year exposure still lacks model-ready humpback surfaces.",
  "- Legacy `v3`/`v4`/`v5` and surveyed-cell branches have different zero-treatment and/or likelihood units; raw LOOIC is not directly comparable to the positive-only Stier-layer models.",
  "- Doherty-style proxy branches are troubleshooting/data-product bridges only until exact HG age/weight/effective-sample-size inputs and predator selectivity assumptions are acquired and audited."
)

lines <- c(lines, "", "## Next Decision", "")

if (nrow(surveyed_unit_candidate) == 1) {
  lines <- c(
    lines,
    paste0(
      "- Best surveyed-cell model by current gates: `",
      surveyed_unit_candidate$model, "`."
    )
  )
} else if (nrow(historical_surveyed_unit_candidate) == 1) {
  lines <- c(
    lines,
    paste0(
      "- Best historical surveyed-cell model by current gates: `",
      historical_surveyed_unit_candidate$model,
      "`; it still requires refit before promotion."
    )
  )
}

if (nrow(practical_baseline) == 1) {
  lines <- c(
    lines,
    paste0(
      "- `", practical_baseline$model,
      "` is the promoted baseline for practical analysis and reporting."
    )
  )
} else {
  lines <- c(
    lines,
    "- No model currently passes the active promotion gates."
  )
}

if (nrow(loo_unstable_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Live LOO-review candidates: `",
      paste(loo_unstable_tbl$model, collapse = "`, `"), "`."
    )
  )
}

if (nrow(process_extension_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Process-extension candidates ready for scientific review: `",
      paste(process_extension_tbl$model, collapse = "`, `"), "`."
    )
  )
}

if (nrow(observation_sensitivity_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Observation-sensitivity candidates ready for scientific review: `",
      paste(observation_sensitivity_tbl$model, collapse = "`, `"), "`."
    )
  )
}

if (nrow(held_process_extension_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Held process extensions should not be promoted without a new reason to spend exact-reLOO/refit time: `",
      paste(held_process_extension_tbl$model, collapse = "`, `"), "`."
    )
  )
}

if (nrow(held_observation_sensitivity_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Held observation sensitivities should not replace the baseline without a clear calibration gain: `",
      paste(held_observation_sensitivity_tbl$model, collapse = "`, `"), "`."
    )
  )
}

if (nrow(stale_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Stale branches need refits before promotion: `",
      paste(stale_tbl$model, collapse = "`, `"), "`."
    )
  )
}

if (nrow(archived_tbl) > 0) {
  lines <- c(
    lines,
    paste0(
      "- Archived branches are not live promotion candidates: `",
      paste(archived_tbl$model, collapse = "`, `"), "`."
    )
  )
}

lines <- c(
  lines,
  "- Do not treat raw LOOIC as comparable across `positive_only` and `surveyed_cells` likelihood units.",
  "- For unresolved LOO-unstable candidates, resolve high Pareto-k points before using PSIS-LOO for promotion.",
  "- Do not advance richer process structure again unless a new branch first passes the observation-calibration and catch-fit gates."
)

writeLines(lines, file.path(diag_dir, "latest_model_status.md"))
cat(paste(lines, collapse = "\n"))
