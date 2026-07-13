# ============================================================================
# 07av_may11_status_snapshot.R
# One-page current status for autonomous analysis continuation.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
out_path <- file.path(diag_dir, "may11_autonomous_status.md")

read_diag <- function(file) {
  path <- file.path(diag_dir, file)
  if (!file.exists(path)) {
    return(tibble())
  }
  read_csv(path, show_col_types = FALSE)
}

model_tbl <- read_diag("model_branch_status_table.csv")
biomass_tbl <- read_diag("current_biomass_estimate_total.csv")
biomass_tail <- read_diag("current_biomass_uncertainty_tail_contributions.csv")
aws_tbl <- read_csv(
  file.path(proj_dir, "cloud", "aws_batch_runs", "2026-05-10-overnight-status.csv"),
  show_col_types = FALSE
)

best_models <- model_tbl %>%
  filter(model %in% c(
    "m1_stier_11",
    "m1_stier_obs_hier",
    "m1_stier_method_sensitivity",
    "m2_stier_site_growth",
    "m3_stier_distance",
    "m5_v3"
  )) %>%
  transmute(
    model,
    status = use_for_monday,
    fit_ok,
    div_td = paste0(divergences, "/", treedepth_hits),
    max_k = max_pareto_k,
    pos_rmse = positive_signal_log_rmse,
    read = short_read
  )

biomass_line <- biomass_tbl %>%
  filter(state == "post-fishing", section_set == "all 11 sections") %>%
  slice(1)
focal_line <- biomass_tbl %>%
  filter(state == "post-fishing", section_set == "Stier focal 9") %>%
  slice(1)

sensitivity_tail_share <- biomass_tail %>%
  filter(section_set == "fit-only sensitivity") %>%
  summarise(value = sum(mean_share_top5_tail, na.rm = TRUE), .groups = "drop") %>%
  pull(value)

fmt <- function(x, accuracy = 1) number(x, accuracy = accuracy, big.mark = ",")

aws_counts <- aws_tbl %>%
  count(status, name = "n") %>%
  arrange(status)

lines <- c(
  "# May 11 Autonomous Status Snapshot",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Current Decision",
  "",
  "- Keep `m1_stier_11` as the promoted analysis baseline.",
  "- Treat `m1_stier_obs_hier` as a clean negative result: extra observation variance did not improve positive-spawn calibration.",
  "- Treat `m3_stier_distance` as ecological context, not promoted inference, unless a later branch delivers clearer calibration gain.",
  "- Do not use current predator fit artifacts as predator evidence.",
  "",
  "## Model Status",
  "",
  knitr::kable(best_models, format = "pipe"),
  "",
  "## Biomass Estimate",
  "",
  paste0(
    "- 2025 all-11 post-fishing biomass median: `", fmt(biomass_line$median),
    " t` (80% `", fmt(biomass_line$lo80), "`-`", fmt(biomass_line$hi80),
    " t`; 90% `", fmt(biomass_line$lo90), "`-`", fmt(biomass_line$hi90), " t`)."
  ),
  paste0(
    "- 2025 focal-9 post-fishing biomass median: `", fmt(focal_line$median),
    " t` (80% `", fmt(focal_line$lo80), "`-`", fmt(focal_line$hi80),
    " t`; 90% `", fmt(focal_line$lo90), "`-`", fmt(focal_line$hi90), " t`)."
  ),
  paste0(
    "- Upper-tail warning: fit-only sensitivity sections account for `",
    percent(sensitivity_tail_share, accuracy = 1),
    "` of biomass in the top 5% of all-11 posterior draws."
  ),
  "- These are model-scale latent biomass estimates, not official DFO assessment biomass.",
  "",
  "## Figure State",
  "",
  "- Compact evidence package: `Output/diagnostics/promoted_baseline_evidence_package.md`.",
  "- Stier signal persistence summary: `Output/diagnostics/stier_signal_persistence_summary.md`.",
  "- Updated Stier main figures are regenerated from `m1_stier_11`: `Output/diagnostics/stier2020_updated_figure_index.md`.",
  "- Companion and supplement figures are regenerated from `m1_stier_11`: `Output/diagnostics/stier2020_updated_companion_supplement_index.md`.",
"- Positive-spawn fit caveat figure is regenerated from `m1_stier_11`: `Output/figures/positive_spawn_fit_caveat.pdf`.",
"- Biomass uncertainty decomposition is regenerated from `m1_stier_11`: `Output/figures/current_biomass_uncertainty_decomposition.pdf`.",
"- Section action matrix is regenerated from `m1_stier_11`: `Output/figures/section_action_matrix.pdf`.",
"- Lead section local audit is regenerated for Cumshewa/Louscoone/Laskeek/Skidegate: `Output/figures/lead_section_local_audit.pdf`.",
"- Lead section raw location transition audit is regenerated for Louscoone/Cumshewa/Laskeek: `Output/figures/lead_section_location_transition.pdf`.",
"- Lead section geocoded raw location map is regenerated for Louscoone/Cumshewa/Laskeek: `Output/figures/lead_section_location_map.pdf`.",
"- Lead spawn-location predator proximity screen is regenerated from geocoded spawn locations and post-2005 seal/SSL sites: `Output/figures/lead_spawn_location_predator_proximity.pdf`.",
"- Named local follow-up targets are regenerated from location transitions, substrate/method metadata, coordinates, and predator proximity: `Output/diagnostics/lead_location_followup_targets.md` and `Output/figures/lead_location_followup_targets.pdf`.",
"- Predator spatial exposure prototype is regenerated from raw HG seal/SSL locations: `Output/figures/predator_spatial_exposure_prototype.pdf`.",
"- Section recovery covariate screen combines fishing, observation caveats, timing/substrate, and predator exposure: `Output/figures/section_recovery_covariate_screen.pdf`.",
"- Covariate readiness registry separates baseline covariates, descriptive screens, prototype products, and held model ideas: `Output/diagnostics/covariate_readiness_registry.md`.",
"- Positive-spawn caveat memo is in `Output/diagnostics/positive_spawn_fit_caveat.md`.",
"- Biomass estimate tables are in `Output/diagnostics/current_biomass_estimate*.csv`.",
  "",
  "## AWS State",
  "",
  "- Local AWS polling is blocked until the `herring` SSO token is refreshed.",
  paste0(
    "- Last local AWS status CSV counts: ",
    paste0("`", aws_counts$status, "`=", aws_counts$n, collapse = ", "),
    "."
  ),
  "- Read `Output/diagnostics/aws_batch_model_farm_status.md` before assuming cloud jobs are still running.",
  "",
  "## Next Work Without New Permissions",
  "",
"1. Polish figures and tables around the promoted baseline, not held branches.",
"2. Use `section_action_matrix.md` to keep section-level interpretation disciplined: mechanism cases, portfolio erosion cases, concentration cases, recovery contrasts, and uncertainty sensitivities.",
"3. Use `lead_location_followup_targets.md` plus the underlying local audit/map/proximity files to focus the next mechanism work on named places, survey access, habitat/substrate, exposure, and location persistence for Cumshewa/Louscoone/Laskeek rather than another regional coefficient.",
"4. Use `predator_spatial_exposure_prototype.md` as a data-product roadmap only; it supports future section exposure work, not a promoted predator coefficient.",
"5. Use `section_recovery_covariate_screen.md` to keep covariate interpretation descriptive: fishing is the strongest section-level axis, while predator/timing/substrate need cleaner data products.",
"6. Once AWS SSO is refreshed, poll Batch, sync successful jobs from S3, and rerun audit/PPC/comparison before promoting anything."
)

writeLines(lines, out_path)
cat(paste(lines, collapse = "\n"))
