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

archived_tbl <- comparison_tbl %>%
  filter(comparison_status == "archived_excluded")

stale_tbl <- comparison_tbl %>%
  filter(comparison_status == "stale_refit_required")

ppc_zero_tbl <- ppc_tbl %>%
  filter(metric == "total_below_detection_surveys") %>%
  select(model, observed, pred_median, pred_q05, pred_q95)

ppc_positive_tbl <- ppc_tbl %>%
  filter(metric %in% c(
    "aggregate_positive_signal_log_rmse",
    "aggregate_positive_signal_log_bias"
  )) %>%
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
      "- Strength: predicted surveyed zeros miss observed zeros by only ",
      round(practical_baseline$zero_calibration_gap, 1), "."
    ),
    paste0(
      "- Positive-magnitude check: aggregate log10 RMSE=",
      round(practical_baseline$positive_signal_log_rmse, 2),
      ", bias=", round(practical_baseline$positive_signal_log_bias, 2), "."
    )
  )
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
      "- Remaining weakness: predicted surveyed zeros miss observed zeros by ",
      round(current_reference$zero_calibration_gap, 1), "."
    )
  )
} else if (nrow(practical_baseline) == 0) {
  lines <- c(lines, "- No current sampler-clean reference model is available.")
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
    "- No surveyed-cell model currently passes both zero and positive-magnitude calibration gates."
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
  "- Do not advance richer process structure again unless a new branch first passes the observation-calibration gates."
)

writeLines(lines, file.path(diag_dir, "latest_model_status.md"))
cat(paste(lines, collapse = "\n"))
