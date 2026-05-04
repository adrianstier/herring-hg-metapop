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

clean_tbl <- comparison_tbl %>%
  filter(sampler_clean)

current_reference <- clean_tbl %>%
  filter(comparison_status == "within_unit_reference") %>%
  slice(1)

surveyed_unit_candidate <- comparison_tbl %>%
  filter(likelihood_unit == "surveyed_cells") %>%
  arrange(desc(sampler_clean), zero_calibration_gap, occupied_sections_rmse) %>%
  slice(1)

practical_baseline <- comparison_tbl %>%
  filter(comparison_status == "promoted_baseline") %>%
  slice(1)

archived_tbl <- comparison_tbl %>%
  filter(comparison_status == "archived_excluded")

ppc_zero_tbl <- ppc_tbl %>%
  filter(metric == "total_below_detection_surveys") %>%
  select(model, observed, pred_median, pred_q05, pred_q95)

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
  lines <- c(lines, "- No sampler-clean reference model is currently available.")
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

lines <- c(lines, "", "## Next Decision", "")

if (nrow(surveyed_unit_candidate) == 1) {
  lines <- c(
    lines,
    paste0(
      "- Best surveyed-cell model remains `", surveyed_unit_candidate$model, "`."
    )
  )
}

lines <- c(
  lines,
  "- Do not treat raw LOOIC as comparable across `positive_only` and `surveyed_cells` likelihood units.",
  "- `m1_v4` is the promoted baseline for practical analysis and reporting.",
  "- `m3_v5` is archived as an excluded branch, not a live candidate for promotion.",
  "- Do not advance richer process structure again unless a new branch is explicitly started from the `m1_v4` baseline."
)

writeLines(lines, file.path(diag_dir, "latest_model_status.md"))
cat(paste(lines, collapse = "\n"))
