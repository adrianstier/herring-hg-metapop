# ============================================================================
# 07bi_model_decision_ledger.R
# Model-farm decision ledger built from local diagnostics and cloud manifests.
# ============================================================================

library(tidyverse)
library(here)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
cloud_dir <- file.path(proj_dir, "cloud")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_csv_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(tibble())
  }
  read_csv(path, show_col_types = FALSE)
}

fmt_num <- function(x, digits = 3) {
  if_else(is.na(x), "", format(round(x, digits), nsmall = digits, trim = TRUE))
}

comparison <- read_csv_if_exists(file.path(diag_dir, "model_comparison.csv"))
manifest <- read_csv_if_exists(file.path(cloud_dir, "model-farm-manifest.csv")) %>%
  filter(job_family != "smoke_test") %>%
  rename(model_id = job_id)

cloud_summary <- read_csv_if_exists(file.path(diag_dir, "cloud_model_farm_status.csv")) %>%
  filter(job_family != "smoke_test") %>%
  rename(model_id = job_id) %>%
  mutate(job_succeeded_flag = tolower(as.character(job_succeeded)) == "true") %>%
  transmute(
    model_id,
    downloaded_job_dirs,
    cloud_exit_codes = exit_codes,
    job_succeeded = job_succeeded_flag,
    artifacts_found = as.integer(artifacts_found),
    artifacts_expected = as.integer(artifacts_expected),
    artifact_paths
  )

batch_run_files <- list.files(
  file.path(cloud_dir, "aws_batch_runs"),
  pattern = "\\.csv$",
  full.names = TRUE
)

batch_runs <- map_dfr(batch_run_files, function(path) {
  read_csv(path, show_col_types = FALSE) %>%
    mutate(
      source_file = basename(path),
      source_mtime = as.numeric(file.info(path)$mtime)
    )
}) %>%
  rename(model_id = model) %>%
  mutate(
    status = if ("status" %in% names(.)) status else NA_character_,
    exit_code = if ("exit_code" %in% names(.)) as.character(exit_code) else NA_character_,
    updated_utc = if ("updated_utc" %in% names(.)) as.character(updated_utc) else NA_character_,
    batch_updated_time = suppressWarnings(lubridate::ymd_hms(updated_utc, tz = "UTC"))
  ) %>%
  arrange(model_id, desc(source_mtime)) %>%
  group_by(model_id) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(
    model_id,
    aws_job_id,
    queue,
    submitted_priority = priority,
    batch_status = status,
    batch_exit_code = exit_code,
    batch_updated_utc = updated_utc,
    batch_status_stale = !is.na(batch_updated_time) &
      difftime(Sys.time(), batch_updated_time, units = "hours") > 24,
    batch_source_file = source_file
  )

comparison_rows <- comparison %>%
  transmute(
    model_id = model,
    artifact_current,
    divergences,
    treedepth_hits,
    max_rhat,
    min_ebfmi,
    max_pareto_k,
    n_pareto_k_gt_0_7,
    looic_decision,
    positive_signal_log_rmse,
    positive_signal_log_bias,
    catch_log_rmse,
    catch_log_bias,
    comparison_status,
    likelihood_unit,
    sampler_clean,
    loo_resolved,
    exact_reloo_refits_clean,
    exact_reloo_treedepth_hits,
    positive_magnitude_clean,
    catch_fit_clean
  )

model_ids <- tibble(model_id = union(manifest$model_id, comparison_rows$model_id))

model_family_from_id <- function(model_id, manifest_family) {
  case_when(
    !is.na(manifest_family) & manifest_family != "" ~ manifest_family,
    model_id == "m1_stier_11" ~ "baseline",
    str_detect(model_id, "obs_hier|method_sensitivity") ~ "observation",
    str_detect(model_id, "site_growth") ~ "site_growth",
    str_detect(model_id, "distance") ~ "spatial_process",
    str_detect(model_id, "m5|pred") ~ "predators",
    str_detect(model_id, "v[345]") ~ "legacy",
    TRUE ~ "other"
  )
}

hypothesis_from_id <- function(model_id) {
  case_when(
    model_id == "m1_stier_11" ~
      "Promoted Stier-aligned biomass baseline for 11 HG sections.",
    model_id == "m1_stier_obs_hier" ~
      "Test whether section-specific observation error and surface-era extra variance improve calibration.",
    model_id == "m1_stier_method_sensitivity" ~
      "Test a three-era survey catchability sensitivity against the Stier two-era q split.",
    model_id == "m2_stier_site_growth" ~
      "Test whether section productivity differences improve process fit.",
    model_id == "m3_stier_distance" ~
      "Test distance-decaying spatial process covariance among sections.",
    model_id == "m3_stier_distance_reloo" ~
      "Resolve high Pareto-k points for the distance branch with exact re-LOO array refits.",
    model_id == "m5_stier_predation_pressure" ~
      "Test HG annual predator pressure on the Stier observation layer.",
    model_id == "m5_stier_predator_demand_total" ~
      "Test total HG predator demand on the Stier observation layer without dividing by observed spawn.",
    model_id == "m5_stier_doherty_proxy_removals" ~
      "Test scaled audited HG predator mortality as a Doherty-style catch-like biomass removal proxy on the Stier observation layer.",
    model_id == "m5_v5" ~
      "Legacy predator branch retained only to diagnose sampler failure.",
    model_id == "m5_combined" ~
      "Exploratory legacy combined-predator branch; not a Stier-aligned promotion candidate.",
    model_id == "m3_dd_global" ~
      "Legacy density-dependence sensitivity, pending Stier-layer rewrite if ever needed.",
    str_detect(model_id, "m1_v[345]") ~
      "Legacy observation/zero-treatment artifact, superseded for current interpretation.",
    str_detect(model_id, "m3_v[35]|m5_v3") ~
      "Legacy richer process artifact, superseded or sampler-pathological.",
    TRUE ~ "Planned or historical model branch."
  )
}

covariates_from_id <- function(model_id) {
  case_when(
    model_id == "m1_stier_11" ~ "catch removals; lag-1 PDO",
    model_id == "m1_stier_obs_hier" ~ "catch removals; lag-1 PDO; section sigma_obs; surface-era extra variance",
    model_id == "m1_stier_method_sensitivity" ~ "catch removals; lag-1 PDO; surface/mixed/dive q",
    model_id == "m2_stier_site_growth" ~ "catch removals; lag-1 PDO; site productivity",
    model_id == "m3_stier_distance" ~ "catch removals; lag-1 PDO; effective-distance covariance",
    model_id == "m5_stier_predation_pressure" ~ "catch removals; lag-1 PDO; HG predator pressure",
    model_id == "m5_stier_predator_demand_total" ~ "catch removals; lag-1 PDO; total HG predator demand",
    model_id == "m5_stier_doherty_proxy_removals" ~ "catch removals; lag-1 PDO; scaled HG predator Mp as catch-like proxy removals",
    model_id == "m5_combined" ~ "PDO; combined regional predator index; legacy density/spatial terms",
    str_detect(model_id, "m5") ~ "predator covariates",
    str_detect(model_id, "m3") ~ "process extension covariates",
    TRUE ~ "none beyond branch design"
  )
}

lag_from_id <- function(model_id) {
  case_when(
    str_detect(model_id, "stier_11|obs_hier|method_sensitivity|site_growth|distance|predation_pressure|predator_demand_total|doherty_proxy_removals") ~
      "PDO lag 1; predator pressure/demand as encoded in HG covariate product where present",
    model_id == "m5_combined" ~ "legacy annual predator index alignment",
    TRUE ~ "not applicable or branch-specific"
  )
}

observation_from_id <- function(model_id, likelihood_unit) {
  case_when(
    str_detect(model_id, "m1_stier_11|m1_stier_obs_hier|m1_stier_method_sensitivity|m2_stier_site_growth|m3_stier_distance|m5_stier_predation_pressure|m5_stier_predator_demand_total|m5_stier_doherty_proxy_removals") ~
      "Stier-aligned positive-only spawn likelihood; ambiguous zeros skipped; 11 sections",
    likelihood_unit == "surveyed_cells" ~
      "surveyed-cell detection-aware legacy likelihood",
    likelihood_unit == "positive_only" ~
      "legacy positive-only likelihood",
    TRUE ~ "planned or unavailable"
  )
}

decision_from_status <- function(model_id, comparison_status, aws_status, task_type) {
  case_when(
    comparison_status == "promoted_baseline" ~ "promoted_baseline",
    comparison_status %in% c(
      "hold_process_extension_no_fit_gain",
      "hold_observation_sensitivity_no_fit_gain"
    ) ~ "held_no_fit_gain",
    comparison_status == "archived_excluded" ~ "archived_sampler_pathology",
    str_detect(coalesce(comparison_status, ""), "stale") ~ "planned",
    str_detect(coalesce(task_type, ""), "planned") ~ "planned",
    aws_status %in% c("RUNNING", "STARTING") ~ "running",
    aws_status %in% c("RUNNABLE", "SUBMITTED_UNPOLLED") ~ "queued",
    aws_status == "FAILED" ~ "archived_sampler_pathology",
    model_id == "m5_combined" ~ "queued",
    TRUE ~ "planned"
  )
}

reason_from_decision <- function(model_id, decision, comparison_status, aws_status) {
  case_when(
    decision == "promoted_baseline" ~
      "Only branch currently passing computational and data-fit gates with exact re-LOO caveat resolved.",
    model_id == "m5_combined" & decision == "archived_sampler_pathology" ~
      "Cloud run completed but saturated max treedepth and badly worsened positive-spawn and catch calibration.",
    model_id == "m5_stier_predation_pressure" ~
      "Sampler is usable, but positive-spawn RMSE and catch fit are effectively baseline-equivalent.",
    model_id == "m5_stier_predator_demand_total" & decision == "held_no_fit_gain" ~
      "Completed gated predator-demand screen; sampler is clean, but fit gain is too small and PSIS remains unresolved.",
    model_id == "m5_stier_doherty_proxy_removals" & decision == "held_no_fit_gain" ~
      "Completed Doherty-style proxy-removal screen; sampler/data-fit gates do not materially beat the promoted baseline.",
    model_id == "m5_stier_predator_demand_total" ~
      "Gated predator-demand screen; WCVI bridge supports demand over pressure ratio, but adjusted diagnostic signal is weak.",
    model_id == "m5_stier_doherty_proxy_removals" ~
      "Cloud smoke completed but the low-vulnerability fixed-removal formulation has poor energy geometry; useful as a negative AWS troubleshooting result, not a full catch-at-age predation-mortality model.",
    model_id == "m5_v5" ~
      "Archived because current cloud-promoted artifact has substantial divergences and treedepth hits.",
    model_id == "m5_combined" ~
      "Submitted in the latest spot round, but no synced job directory is present locally; AWS poll is required.",
    decision == "held_no_fit_gain" ~
      "Sampler/data checks are usable enough for context, but calibration does not materially beat m1_stier_11.",
    str_detect(coalesce(comparison_status, ""), "stale") ~
      "Artifact predates current source/data and is not a live promotion candidate.",
    aws_status == "FAILED" ~
      "Cloud job or artifact collection failed; inspect logs before reuse.",
    TRUE ~ "No current fit artifact or no current decision beyond planning."
  )
}

next_action_from_decision <- function(model_id, decision) {
  case_when(
    model_id == "m1_stier_11" ~
      "Use as reference baseline for reports and future branch comparisons.",
    model_id == "m5_combined" & decision == "archived_sampler_pathology" ~
      "Archive; do not spend exact re-LOO or combination-model time on this branch.",
    model_id == "m5_combined" ~
      "Refresh AWS SSO, poll Batch, sync S3 results, promote only if artifacts exist, then audit/PPC/compare.",
    model_id == "m5_stier_predation_pressure" ~
      "Hold; do exact re-LOO only if predator interpretation becomes central.",
    model_id == "m5_stier_predator_demand_total" & decision == "held_no_fit_gain" ~
      "Hold; use as context only and prioritize predator data-product refinement before any richer predator model.",
    model_id == "m5_stier_doherty_proxy_removals" & decision == "held_no_fit_gain" ~
      "Hold unless diagnostics clearly justify exact re-LOO; treat as proxy-removal context only.",
    model_id == "m5_stier_predator_demand_total" ~
      "Submit only as a deliberate single-covariate AWS screen after SSO refresh; longer local smoke had baseline-like heavy geometry.",
    model_id == "m5_stier_doherty_proxy_removals" ~
      "Do not submit the full fit yet; reparameterize or replace the fixed-removal formulation before another cloud smoke.",
    model_id == "m5_v5" ~
      "Archive; do not spend exact re-LOO time.",
    decision == "held_no_fit_gain" ~
      "Keep as context/sensitivity; do not promote without a new calibration or mechanistic reason.",
    decision == "queued" ~
      "Poll AWS state and sync artifacts before interpretation.",
    decision == "running" ~
      "Wait for terminal AWS status, then sync and audit.",
    decision == "planned" ~
      "Do not submit until a specific diagnostic question justifies this branch.",
    TRUE ~ "Review before further action."
  )
}

ledger <- model_ids %>%
  left_join(manifest, by = "model_id") %>%
  left_join(comparison_rows, by = "model_id") %>%
  left_join(batch_runs, by = "model_id") %>%
  left_join(cloud_summary, by = "model_id") %>%
  mutate(
    model_family = model_family_from_id(model_id, job_family),
    hypothesis = hypothesis_from_id(model_id),
    covariates = covariates_from_id(model_id),
    lag_structure = lag_from_id(model_id),
    observation_model = observation_from_id(model_id, likelihood_unit),
    aws_status = case_when(
      job_succeeded ~ "SUCCEEDED_SYNCED",
      !is.na(downloaded_job_dirs) & downloaded_job_dirs != "" ~ "SYNCED_FAILED_OR_INCOMPLETE",
      artifact_current & batch_status_stale & !is.na(comparison_status) & comparison_status != "" ~
        "LOCAL_CURRENT_STALE_AWS_ROW",
      batch_status_stale & !is.na(batch_status) & batch_status != "" ~ paste0("STALE_", batch_status),
      !is.na(batch_status) & batch_status != "" ~ batch_status,
      !is.na(aws_job_id) & aws_job_id != "" ~ "SUBMITTED_UNPOLLED",
      str_detect(coalesce(task_type, ""), "planned") ~ "PLANNED",
      TRUE ~ "NOT_SUBMITTED"
    ),
    artifact_current = coalesce(artifact_current, FALSE),
    looic_decision = as.character(looic_decision),
    decision = decision_from_status(model_id, comparison_status, aws_status, task_type),
    reason = reason_from_decision(model_id, decision, comparison_status, aws_status),
    next_action = next_action_from_decision(model_id, decision)
  ) %>%
  transmute(
    model_id,
    model_family,
    hypothesis,
    covariates,
    lag_structure,
    observation_model,
    aws_job_id = coalesce(aws_job_id, ""),
    aws_status,
    artifact_current,
    divergences,
    treedepth_hits,
    max_rhat,
    min_ebfmi,
    max_pareto_k,
    n_pareto_k_gt_0_7,
    looic_decision,
    positive_signal_log_rmse,
    positive_signal_log_bias,
    catch_log_rmse,
    catch_log_bias,
    decision,
    reason,
    next_action
  ) %>%
  arrange(
    factor(
      decision,
      levels = c(
        "promoted_baseline",
        "running",
        "queued",
        "held_needs_reloo",
        "held_no_fit_gain",
        "archived_sampler_pathology",
        "archived_bad_data_fit",
        "planned"
      )
    ),
    model_family,
    model_id
  )

write_csv(ledger, file.path(diag_dir, "model_decision_ledger.csv"))

md_tbl <- ledger %>%
  transmute(
    model_id,
    family = model_family,
    aws = aws_status,
    current = artifact_current,
    div_td = if_else(
      is.na(divergences),
      "",
      paste0(divergences, "/", treedepth_hits)
    ),
    rhat = fmt_num(max_rhat, 3),
    ebfmi = fmt_num(min_ebfmi, 3),
    max_k = fmt_num(max_pareto_k, 3),
    pos_rmse = fmt_num(positive_signal_log_rmse, 3),
    catch_rmse = fmt_num(catch_log_rmse, 3),
    decision,
    next_action
  )

md_lines <- c(
  "# Model Decision Ledger",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This ledger is the control sheet for iterative AWS model-farm decisions. It joins local diagnostic gates, cloud submission state, and the next action for each live or planned branch.",
  "",
  knitr::kable(md_tbl, format = "pipe"),
  "",
  "## Current Read",
  "",
  "- `m1_stier_11` remains the promoted baseline.",
  "- `m5_stier_predation_pressure` is held: sampler-usable, but no material data-fit gain over baseline.",
  "- `m5_stier_predator_demand_total` is held after the completed AWS screen: sampler-clean, but no material calibration gain and unresolved high Pareto-k points.",
  "- `m5_stier_doherty_proxy_removals` now has a cloud-smoke negative result: the low-vulnerability fixed-removal branch runs, but poor E-BFMI means no full fit yet.",
  "- `m5_v5` is archived because sampler pathologies override any apparent LOO improvement.",
  "- `m5_combined` is archived because the completed cloud run saturated max treedepth and badly worsened spawn/catch calibration.",
  "- The `m3_stier_distance_reloo` cloud array failed/incomplete; local exact re-LOO for `m3_stier_distance` is already available and the branch remains held.",
  "- Do not launch broader combination models until single-covariate branches clear both computational and data-fit gates.",
  "",
  "## Files",
  "",
  "- `Output/diagnostics/model_decision_ledger.csv`",
  "- `Output/diagnostics/model_decision_ledger.md`"
)

writeLines(md_lines, file.path(diag_dir, "model_decision_ledger.md"))

cat("Saved model decision ledger:\n")
cat("  Output/diagnostics/model_decision_ledger.csv\n")
cat("  Output/diagnostics/model_decision_ledger.md\n")
