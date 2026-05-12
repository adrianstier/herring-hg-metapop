# ============================================================================
# 07aw_promoted_baseline_evidence_package.R
# Compact evidence package for the promoted m1_stier_11 baseline.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
out_path <- file.path(diag_dir, "promoted_baseline_evidence_package.md")

read_diag <- function(filename) {
  path <- file.path(diag_dir, filename)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

model_tbl <- read_diag("model_branch_status_table.csv")
biomass_tbl <- read_diag("current_biomass_estimate_total.csv")
current_tbl <- read_diag("m1_stier_11_current_year_summary.csv")
catch_fit <- read_diag("m1_stier_11_catch_fit_summary.csv")
method_fit <- read_diag("m1_stier_11_spawn_fit_by_method.csv")
period_fit <- read_diag("m1_stier_11_spawn_fit_by_period.csv")
section_tbl <- read_diag("section_narrative_synthesis.csv")
action_tbl <- read_diag("section_action_matrix.csv")
lead_local <- read_diag("lead_section_local_audit_annual_summary.csv")
lead_location <- read_diag("lead_section_location_transition_summary.csv")
lead_targets <- read_diag("lead_location_followup_targets.csv")
predator_availability <- read_diag("predator_spatial_exposure_availability.csv")
predator_exposure_cor <- read_diag("predator_spatial_exposure_growth_correlations.csv")
predator_recent <- read_diag("predator_spatial_exposure_recent_by_section.csv")
caveat_summary <- read_diag("positive_spawn_fit_caveat_summary.csv")
biomass_tail <- read_diag("current_biomass_uncertainty_tail_contributions.csv")

baseline <- model_tbl %>%
  filter(model == "m1_stier_11") %>%
  slice(1)

obs_hier <- model_tbl %>%
  filter(model == "m1_stier_obs_hier") %>%
  slice(1)

distance <- model_tbl %>%
  filter(model == "m3_stier_distance") %>%
  slice(1)

sensitivity_tail_share <- biomass_tail %>%
  filter(section_set == "fit-only sensitivity") %>%
  summarise(value = sum(mean_share_top5_tail, na.rm = TRUE), .groups = "drop") %>%
  pull(value)

biomass_all <- biomass_tbl %>%
  filter(state == "post-fishing", section_set == "all 11 sections") %>%
  slice(1)

biomass_focal <- biomass_tbl %>%
  filter(state == "post-fishing", section_set == "Stier focal 9") %>%
  slice(1)

current <- current_tbl %>% slice(1)

fmt <- function(x, accuracy = 1) number(x, accuracy = accuracy, big.mark = ",")
fmt3 <- function(x) number(x, accuracy = 0.001)

section_md <- section_tbl %>%
  transmute(
    section = site_name,
    role = talk_role,
    `recent/early` = number(recent_to_early_ratio, accuracy = 0.01),
    `current share` = percent(current_share, accuracy = 1),
    caveat = main_caveat
  )

action_group_md <- action_tbl %>%
  group_by(talk_use) %>%
  summarise(
    n = n(),
    sections = paste(site_name, collapse = "; "),
    `2025 share` = percent(sum(current_share, na.rm = TRUE), accuracy = 1),
    `median recent/early` = number(median(recent_to_early_ratio, na.rm = TRUE), accuracy = 0.01),
    .groups = "drop"
  ) %>%
  arrange(match(talk_use, unique(action_tbl$talk_use)))

lead_local_md <- lead_local %>%
  transmute(
    section = section_name,
    `survey coverage` = percent(survey_coverage, accuracy = 1),
    `positive years` = positive_years,
    `recent positives/surveys` = paste0(recent_positive_years, "/", recent_surveyed_years),
    `median positive spawn` = number(median_positive_spawn_t, accuracy = 1),
    `talk use` = talk_use
  )

lead_location_md <- lead_location %>%
  transmute(
    section = section_name,
    `raw locations` = raw_locations,
    `recent locations` = recent_locations,
    `lost after roe` = lost_after_roe_locations,
    `recent/roe signal` = percent(recent_to_roe_signal, accuracy = 0.1),
    `top lost location` = top_lost_location,
    `top recent location` = top_recent_location
  )

lead_targets_md <- lead_targets %>%
  slice_head(n = 12) %>%
  transmute(
    rank = priority_rank,
    section = section_name,
    location = LocationName,
    class = priority_class,
    `roe signal` = number(signal_roe, accuracy = 1),
    `recent signal` = number(signal_recent, accuracy = 1),
    `seal km` = number(seal_nearest_distance_km, accuracy = 0.1),
    `SSL km` = number(ssl_nearest_distance_km, accuracy = 0.1)
  )

predator_availability_md <- predator_availability %>%
  transmute(
    predator,
    `years` = paste0(first_year, "-", last_year),
    `observed years` = observed_years,
    sites = predator_sites,
    `site-years` = site_years
  )

predator_cor_md <- predator_exposure_cor %>%
  filter(range_km == 50) %>%
  transmute(
    predator,
    years,
    `rho exposure-growth` = number(rho_growth, accuracy = 0.01),
    `rho exposure-year` = number(rho_year, accuracy = 0.01)
  )

predator_recent_md <- predator_recent %>%
  group_by(predator) %>%
  slice_min(exposure_rank, n = 3, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    predator,
    section = section_name,
    rank = exposure_rank,
    `recent exposure z` = number(recent_median_exposure_z, accuracy = 0.01)
  )

method_md <- method_fit %>%
  transmute(
    method,
    n,
    rmse = number(rmse, accuracy = 0.01),
    bias = number(bias, accuracy = 0.01),
    `90% coverage` = percent(coverage_90, accuracy = 1)
  )

period_md <- period_fit %>%
  transmute(
    period,
    n,
    rmse = number(rmse, accuracy = 0.01),
    bias = number(bias, accuracy = 0.01),
    `90% coverage` = percent(coverage_90, accuracy = 1)
  )

lines <- c(
  "# Promoted Baseline Evidence Package",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Decision",
  "",
  "- Promoted baseline: `m1_stier_11`.",
  "- It is the Stier-aligned 11-section model: ambiguous zeros are not treated as biological nondetections, and survey catchability uses the surface/SCUBA split.",
  paste0(
    "- Sampler health: divergences=", baseline$divergences,
    ", treedepth hits=", baseline$treedepth_hits,
    ", max R-hat=", fmt3(baseline$max_rhat),
    ", min E-BFMI=", fmt3(baseline$min_ebfmi), "."
  ),
  paste0(
    "- Positive-spawn calibration: log RMSE=", fmt3(baseline$positive_signal_log_rmse),
    ", bias=", fmt3(baseline$positive_signal_log_bias), "."
  ),
  "- Exact re-LOO has resolved the main high-k point for the promoted baseline.",
  "",
  "## Branch Reads",
  "",
  paste0(
    "- `m1_stier_obs_hier`: sampler-clean but held; positive-spawn RMSE worsened to ",
    fmt3(obs_hier$positive_signal_log_rmse), " and max Pareto k is ",
    fmt3(obs_hier$max_pareto_k), "."
  ),
  paste0(
    "- `m3_stier_distance`: sampler-clean spatial context; positive-spawn RMSE is ",
    fmt3(distance$positive_signal_log_rmse), ", exact re-LOO completed, and the branch is held because fit gain is small and exact refits had treedepth pressure."
  ),
  "- Current predator artifacts are stale/pathological and should not be used as predator evidence.",
  "- New predator spatial exposure prototype is a data-product result only: seal/SSL section exposure can be built, but time confounding remains and humpback exposure is still basin-scale.",
  "",
  "## Biomass",
  "",
  paste0(
    "- 2025 all-11 post-fishing biomass median: `", fmt(biomass_all$median),
    " t` (80% `", fmt(biomass_all$lo80), "`-`", fmt(biomass_all$hi80),
    " t`; 90% `", fmt(biomass_all$lo90), "`-`", fmt(biomass_all$hi90), " t`)."
  ),
  paste0(
    "- 2025 focal-9 post-fishing biomass median: `", fmt(biomass_focal$median),
    " t` (80% `", fmt(biomass_focal$lo80), "`-`", fmt(biomass_focal$hi80),
    " t`; 90% `", fmt(biomass_focal$lo90), "`-`", fmt(biomass_focal$hi90), " t`)."
  ),
  paste0(
    "- 2025 top-three section share: ", percent(current$top3_share, accuracy = 1),
    "; sections below 20% early baseline: ", current$n_below_20pct, " / 11."
  ),
  paste0(
    "- Upper-tail warning: fit-only sensitivity sections account for ",
    percent(sensitivity_tail_share, accuracy = 1),
    " of biomass in the top 5% of all-11 posterior draws."
  ),
  "- Biomass is model-scale latent biomass, not an official DFO assessment estimate.",
  "",
  "## Fit To Data",
  "",
  paste0(
    "- Catch fit is essentially exact (log RMSE ",
    scientific(catch_fit$rmse, digits = 3), "), so it should be read as catch accounting/removal consistency rather than independent predictive validation."
  ),
  "- Positive-spawn fit is the real observation-calibration test.",
  "",
  "### Positive Spawn By Survey Method",
  "",
  knitr::kable(method_md, format = "pipe"),
  "",
  "### Positive Spawn By Period",
  "",
  knitr::kable(period_md, format = "pipe"),
  "",
  "## Section Story",
  "",
  knitr::kable(section_md, format = "pipe"),
  "",
  "## Section Action Matrix",
  "",
  "- Use `Output/diagnostics/section_action_matrix.md` and `Output/figures/section_action_matrix.pdf` as the current section-level work plan.",
  "- Cumshewa and Louscoone are the lead mechanism cases; Juan Perez and Skincuttle are current biomass concentration cases; Tasu and Naden are uncertainty sensitivity only.",
  "",
  knitr::kable(action_group_md, format = "pipe"),
  "",
  "### Lead Local Audit",
  "",
  "- `Output/diagnostics/lead_section_local_audit.md` checks Cumshewa, Louscoone, Laskeek, and Skidegate against survey coverage, period records, and raw HG location concentration.",
  "- `Output/diagnostics/lead_section_location_transition.md` checks raw location persistence/loss for Louscoone, Cumshewa, and Laskeek; Skidegate remains model-only in this raw HG section extract.",
  "- `Output/diagnostics/lead_section_location_map.md` maps the geocoded subset of those raw locations to guide local access, habitat/substrate, and exposure follow-up.",
  "- `Output/diagnostics/lead_spawn_location_predator_proximity.md` links geocoded spawn locations to post-2005 seal/sea-lion sites; it is a local audit screen, not predator-effect evidence.",
  "- `Output/diagnostics/lead_location_followup_targets.md` combines location loss/persistence, substrate/method metadata, coordinates, and predator proximity into a named target list for local follow-up.",
  "- This strengthens the next action: local data audits for Cumshewa/Louscoone and a fit-caveated portfolio read for Skidegate.",
  "",
  knitr::kable(lead_local_md, format = "pipe"),
  "",
  "### Raw Location Transition Summary",
  "",
  knitr::kable(lead_location_md, format = "pipe"),
  "",
  "### Top Local Follow-up Targets",
  "",
  knitr::kable(lead_targets_md, format = "pipe"),
  "",
  "## Predator Exposure Prototype",
  "",
  "- `Output/diagnostics/predator_spatial_exposure_prototype.md` builds rough section exposure from raw Haida Gwaii harbour seal and Steller sea lion locations.",
  "- Treat it as a feasibility roadmap, not causal evidence; regional predator indices remain too time-confounded for a promoted Stan coefficient.",
  "- `Output/diagnostics/section_recovery_covariate_screen.md` combines recovery with fishing pressure, survey coverage, timing/substrate, and prototype predator exposure; it keeps historical fishing as the cleanest section-level axis.",
  "- `Output/diagnostics/covariate_readiness_registry.md` separates baseline covariates, descriptive screens, prototype data products, and held model ideas.",
  "",
  "### Raw Predator Location Availability",
  "",
  knitr::kable(predator_availability_md, format = "pipe"),
  "",
  "### 50 km Kernel Correlation Screen",
  "",
  knitr::kable(predator_cor_md, format = "pipe"),
  "",
  "### Highest Recent Prototype Exposures",
  "",
  knitr::kable(predator_recent_md, format = "pipe"),
  "",
  "## Original Stier Signal Persistence",
  "",
  "- The updated signal-persistence memo is `Output/diagnostics/stier_signal_persistence_summary.md`.",
  "- Realized-growth decline persists in most focal sections, but process-deviation spread is lower in recent closure years; discuss this as uneven section dynamics and reduced portfolio buffering rather than a single causal process-error story.",
  "",
  "## Caveats",
  "",
  paste0("- ", caveat_summary$claim, ": ", caveat_summary$evidence),
  "",
  "## Priority Figure Files",
  "",
  "- `Output/figures/stier2020_updated/fig1_spatiotemporal_spawn_updated.pdf`",
  "- `Output/figures/stier2020_updated/fig6_process_portfolio_updated.pdf`",
  "- `Output/figures/m1_stier_11_current_year_status.pdf`",
  "- `Output/figures/current_biomass_uncertainty_decomposition.pdf`",
  "- `Output/figures/section_action_matrix.pdf`",
  "- `Output/figures/lead_section_local_audit.pdf`",
  "- `Output/figures/lead_section_location_transition.pdf`",
  "- `Output/figures/lead_section_location_map.pdf`",
  "- `Output/figures/lead_spawn_location_predator_proximity.pdf`",
  "- `Output/figures/lead_location_followup_targets.pdf`",
  "- `Output/figures/predator_spatial_exposure_prototype.pdf`",
  "- `Output/figures/section_recovery_covariate_screen.pdf`",
  "- `Output/figures/section_narrative_synthesis.pdf`",
  "- `Output/figures/positive_spawn_fit_caveat.pdf`",
  "- `Output/figures/m1_stier_11_positive_spawn_fit_summary.pdf`",
  "- `Output/figures/m1_stier_11_catch_fit_by_section.pdf`"
)

writeLines(lines, out_path)
cat("Saved promoted baseline evidence package:\n")
cat("  Output/diagnostics/promoted_baseline_evidence_package.md\n")
