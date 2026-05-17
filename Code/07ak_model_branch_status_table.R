# ============================================================================
# 07ak_model_branch_status_table.R
# Compact status table for fitted model branches.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

comparison <- read_csv(file.path(diag_dir, "model_comparison.csv"), show_col_types = FALSE)

m3_reloo_path <- file.path(diag_dir, "m3_stier_distance_triage_reloo.csv")
m3_reloo_completed <- FALSE
m3_reloo_treedepth_hits <- NA_real_
if (file.exists(m3_reloo_path)) {
  m3_reloo <- read_csv(m3_reloo_path, show_col_types = FALSE)
  m3_reloo_completed <- nrow(m3_reloo) > 0 &&
    max(m3_reloo$n_exact_refit_completed, na.rm = TRUE) >=
      max(m3_reloo$n_high_pareto_total, na.rm = TRUE)
  m3_reloo_treedepth_hits <- sum(m3_reloo$treedepth_hits, na.rm = TRUE)
}

model_use_class <- function(model, comparison_status, likelihood_unit) {
  case_when(
    comparison_status == "promoted_baseline" ~ "primary baseline",
    comparison_status %in% c(
      "hold_process_extension_no_fit_gain",
      "hold_observation_sensitivity_no_fit_gain"
    ) ~ "context / held sensitivity",
    comparison_status == "archived_excluded" ~ "archived - do not interpret",
    str_detect(coalesce(comparison_status, ""), "stale") ~ "stale - refit before use",
    likelihood_unit == "surveyed_cells" ~ "zero-treatment sensitivity only",
    str_detect(model, "doherty|predator|predation|m5") ~ "predator gate only",
    TRUE ~ "review before use"
  )
}

branch_guardrail <- function(model, comparison_status, likelihood_unit) {
  case_when(
    model == "m1_stier_11" ~
      "Headline baseline; zeros ambiguous, two-era q, 11 fitted sections, focal-9 reporting sensitivity.",
    model == "m1_stier_method_sensitivity" ~
      "Survey-method sensitivity only; three-era q does not replace the Stier two-era baseline.",
    model == "m1_stier_obs_hier" ~
      "Observation-variance negative result; do not use extra variance to claim better fit.",
    model == "m2_stier_site_growth" ~
      "Site-productivity sensitivity only; no material calibration gain.",
    model == "m3_stier_distance" ~
      "Spatial context only; exact re-LOO completed but one exact refit had treedepth pressure.",
    model == "m5_stier_predation_pressure" ~
      "Held predator-pressure screen; pressure ratio partly contains observed spawn and is not clean exogenous evidence.",
    model == "m5_stier_predator_demand_total" ~
      "Held total-demand screen; no group split or rerun without stronger residual, lag, and exposure gates.",
    model == "m5_combined" ~
      "Archived; do not use or spend exact re-LOO/combo-model time.",
    model == "m5_v5" ~
      "Archived; sampler pathologies override any apparent comparison benefit.",
    model == "m5_v3" ~
      "Legacy stale/pathological predator branch; not predator evidence.",
    likelihood_unit == "surveyed_cells" ~
      "Detection-aware sensitivity; raw LOOIC is not comparable to positive-only Stier-layer fits.",
    str_detect(coalesce(comparison_status, ""), "stale") ~
      "Historical artifact; do not use until refit and re-audited.",
    TRUE ~ "Check likelihood unit, zero treatment, sampler health, positive-spawn fit, catch fit, and provenance before interpretation."
  )
}

branch_tbl <- comparison %>%
  mutate(
    model_family = case_when(
      str_detect(model, "^m1_stier_11$") ~ "baseline",
      str_detect(model, "obs_hier") ~ "observation hierarchy",
      str_detect(model, "method_sensitivity") ~ "observation sensitivity",
      str_detect(model, "site_growth") ~ "site heterogeneity",
      str_detect(model, "distance") ~ "spatial process",
      model %in% c("m5_stier_predation_pressure", "m5_stier_predator_demand_total") ~ "predators",
      model == "m5_v5" ~ "predator / archived",
      str_detect(model, "m5|pred") ~ "predator / richer legacy",
      str_detect(model, "v[345]") ~ "legacy / stale branch",
      TRUE ~ "other"
    ),
    finished = if_else(!is.na(looic), "yes", "no"),
    fit_ok = case_when(
      sampler_clean & !str_detect(comparison_status, "stale") ~ "yes",
      sampler_clean & str_detect(comparison_status, "stale") ~ "stale artifact",
      TRUE ~ "no"
    ),
    use_for_monday = case_when(
      comparison_status == "promoted_baseline" ~ "yes - promoted baseline",
      comparison_status == "observation_sensitivity_candidate" ~ "candidate - review against baseline",
      comparison_status == "process_extension_candidate" ~ "candidate - review against baseline",
      comparison_status == "hold_process_extension_no_fit_gain" ~ "context only - held",
      comparison_status == "hold_observation_sensitivity_no_fit_gain" ~ "context only - held",
      str_detect(comparison_status, "stale") ~ "no - stale/refit required",
      TRUE ~ "no"
    ),
    model_use_class = model_use_class(model, comparison_status, likelihood_unit),
    interpretation_guardrail = branch_guardrail(model, comparison_status, likelihood_unit),
    short_read = case_when(
      model == "m1_stier_11" ~
        "Promoted Stier-aligned 11-section baseline; exact re-LOO resolved its high-k point.",
      model == "m1_stier_method_sensitivity" ~
        "Clean method/q sensitivity; no calibration gain, so keep as survey-method context.",
      model == "m1_stier_obs_hier" ~
        "Observation hierarchy using ambiguous zeros, Stier two-era q, section-specific observation error, and surface-era extra variance; clean but held because calibration worsened.",
      model == "m2_stier_site_growth" ~
        "Clean site-growth extension; no calibration gain, so hold.",
      model == "m3_stier_distance" ~
        if (m3_reloo_completed) {
          paste0(
            "Clean spatial distance-decay candidate; exact re-LOO triage completed but remains held",
            if_else(is.finite(m3_reloo_treedepth_hits) && m3_reloo_treedepth_hits > 0,
                    paste0(" because exact refits had ", m3_reloo_treedepth_hits, " treedepth hits."),
                    " because fit gain is small.")
          )
        } else {
          "Clean spatial distance-decay candidate; plausible range, slight RMSE gain, held pending re-LOO triage."
        },
      model == "m5_stier_predation_pressure" ~
        "Stier-aligned predator-pressure branch is sampler-usable, but positive-spawn calibration is indistinguishable from the promoted baseline.",
      model == "m5_stier_predator_demand_total" ~
        "Stier-aligned predator-demand branch is sampler-clean, but calibration gain is too small and PSIS remains unresolved.",
      model == "m5_v5" ~
        "Archived predator branch: current artifact is sampler-pathological despite superficially acceptable PSIS.",
      model == "m5_combined" ~
        "Archived combined-predator branch: cloud run had max-treedepth saturation and badly worsened spawn/catch calibration.",
      model == "m5_v3" ~
        "Old predator branch exists but is stale and sampler-pathological; do not use as predator evidence.",
      str_detect(model, "m3_v3|m3_v5") ~
        "Old richer process branch; stale and/or sampler-pathological.",
      str_detect(model, "m1_v4|m1_v5") ~
        "Old detection-aware zero sensitivity; not Stier-aligned for the promoted baseline and stale.",
      str_detect(model, "m1_v3") ~
        "Old positive-only baseline artifact; superseded by m1_stier_11.",
      TRUE ~ "Historical artifact or superseded branch."
    )
  ) %>%
  transmute(
    model,
    model_family,
    likelihood_unit,
    finished,
    fit_ok,
    use_for_monday,
    model_use_class,
    comparison_status,
    divergences,
    treedepth_hits,
    max_rhat = round(max_rhat, 3),
    min_ebfmi = round(min_ebfmi, 3),
    looic = round(looic, 2),
    max_pareto_k = round(max_pareto_k, 3),
    loo_resolved,
    positive_signal_log_rmse = round(positive_signal_log_rmse, 3),
    positive_signal_log_bias = round(positive_signal_log_bias, 3),
    interpretation_guardrail,
    short_read
  ) %>%
  arrange(
    factor(
      use_for_monday,
      levels = c(
        "yes - promoted baseline",
        "candidate - review against baseline",
        "context only - held",
        "no - stale/refit required",
        "no"
      )
    ),
    model_family,
    model
  )

write_csv(branch_tbl, file.path(diag_dir, "model_branch_status_table.csv"))

md_tbl <- branch_tbl %>%
  transmute(
    model,
    family = model_family,
    finished,
    fit_ok,
    `Monday use` = use_for_monday,
    `use class` = model_use_class,
    `div/td` = paste0(divergences, "/", treedepth_hits),
    `max k` = max_pareto_k,
    `pos RMSE` = positive_signal_log_rmse,
    read = short_read
  )

md_lines <- c(
  "# Model Branch Status Table",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This table answers which models have finished, which fit acceptably, and which should be used for Monday.",
  "",
  knitr::kable(md_tbl, format = "pipe"),
  "",
  "## Bottom Line",
  "",
  "- Use `m1_stier_11` as the promoted baseline.",
  "- Hold `m1_stier_obs_hier`; its sampler is clean, but positive-spawn calibration is worse than `m1_stier_11`.",
  if (m3_reloo_completed) {
    paste0(
      "- Treat `m3_stier_distance` as spatial context only: exact re-LOO triage completed",
      if_else(is.finite(m3_reloo_treedepth_hits) && m3_reloo_treedepth_hits > 0,
              paste0(" with ", m3_reloo_treedepth_hits, " treedepth hits in exact refits,"),
              ","),
      " and the positive-spawn fit gain is too small for promotion."
    )
  } else {
    "- Treat `m3_stier_distance` as a spatial candidate only after re-LOO triage resolves the three high-k points."
  },
  "- Hold `m5_stier_predation_pressure`; it is the defensible predator-pressure branch, but it does not improve positive-spawn calibration over `m1_stier_11`.",
  "- Hold `m5_stier_predator_demand_total`; it is the cleaner WCVI-aligned predator-demand screen, but the completed AWS fit does not materially improve calibration.",
  "- Archive `m5_combined` and `m5_v5`; ignore legacy `m5_v3` as predator evidence because these branches are sampler-pathological, stale, or badly miscalibrated.",
  "- Keep `m1_stier_method_sensitivity` and `m2_stier_site_growth` as context/held sensitivity results, not promoted inference models.",
  "- Treat detection-aware surveyed-cell branches as zero-treatment sensitivities only; their raw LOOIC is not directly comparable with the positive-only Stier-layer fits.",
  "- No predator coefficient is currently promoted. Predator branches must clear data-product provenance, future-lag control, section-control, positive-spawn, catch-fit, and sampler gates before interpretation.",
  "",
  "## Files",
  "",
  "- `Output/diagnostics/model_branch_status_table.csv`",
  "- `Output/diagnostics/model_branch_status_table.md`"
)

writeLines(md_lines, file.path(diag_dir, "model_branch_status_table.md"))

cat("Saved model branch status table:\n")
cat("  Output/diagnostics/model_branch_status_table.md\n")
