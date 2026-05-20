library(tidyverse)
library(here)
library(glue)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(file) {
  readr::read_csv(file.path(diag_dir, file), show_col_types = FALSE)
}

fmt_num <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
}

fmt_int <- function(x) {
  format(round(as.numeric(x)), big.mark = ",", trim = TRUE)
}

period_tbl <- read_diag("m1_stier_11_period_summary.csv")
current_tbl <- read_diag("m1_stier_11_current_year_summary.csv")
scorecard_tbl <- read_diag("m1_stier_11_section_scorecard.csv")
concentration_tbl <- read_diag("m1_stier_11_spatial_concentration.csv")
survey_tbl <- read_diag("survey_coverage_zero_ambiguity_overall.csv")
scale_tbl <- read_diag("spawn_index_scale_global_summary.csv")
fishing_summary <- read_diag("fishing_pressure_decomposition_summary.csv")
closure_summary <- read_diag("fishing_closure_response_summary.csv")
pdo_tbl <- read_diag("pdo_climate_lag_screen.csv")
pdo_window_tbl <- read_diag("pdo_window_sensitivity.csv")
predator_tbl <- read_diag("predator_data_confounding.csv")
predator_exposure_availability <- read_diag("predator_spatial_exposure_availability.csv")
predator_exposure_cor <- read_diag("predator_spatial_exposure_growth_correlations.csv")
local_transition <- read_diag("lead_section_location_transition_summary.csv")
local_targets <- read_diag("lead_location_followup_targets.csv")
local_predator_section <- read_diag("lead_spawn_location_predator_proximity_by_section.csv")
local_predator_status <- read_diag("lead_spawn_location_predator_proximity_by_status.csv")
density_tbl <- read_diag("density_dependence_pooled_section_summary.csv")
distance_tbl <- read_diag("m3_stier_distance_global_parameters.csv")
distance_context <- read_diag("m3_stier_distance_comparison_context.csv")
mhw_tbl <- read_diag("mhw_recovery_period_summary.csv")
section_roles <- read_diag("section_narrative_synthesis.csv")
section_action <- read_diag("section_action_matrix.csv")

period_lookup <- period_tbl %>%
  select(period, total_biomass_median, occupied_sections, fishing_fraction)

early_biomass <- period_lookup %>%
  filter(str_detect(period, "early")) %>%
  pull(total_biomass_median)

roe_biomass <- period_lookup %>%
  filter(str_detect(period, "roe")) %>%
  pull(total_biomass_median)

recent_row <- period_lookup %>%
  filter(str_detect(period, "recent")) %>%
  slice(1)

recent_concentration <- concentration_tbl %>%
  filter(report_set == "all_11", year >= 2017, year <= 2025) %>%
  summarise(
    top3_share = median(top3_share_median, na.rm = TRUE),
    simpson_n = median(simpson_effective_sections_median, na.rm = TRUE),
    .groups = "drop"
  )

status_counts <- scorecard_tbl %>%
  count(status, sort = TRUE) %>%
  mutate(label = paste0(status, "=", n)) %>%
  pull(label) %>%
  paste(collapse = "; ")

role_counts <- section_roles %>%
  count(talk_role, sort = TRUE) %>%
  mutate(label = paste0(talk_role, "=", n)) %>%
  pull(label) %>%
  paste(collapse = "; ")

action_counts <- section_action %>%
  group_by(talk_use) %>%
  summarise(sections = paste(site_name, collapse = ", "), .groups = "drop") %>%
  mutate(label = paste0(talk_use, ": ", sections)) %>%
  pull(label) %>%
  paste(collapse = "; ")

fishing_rho <- fishing_summary %>%
  filter(metric == "rho_recent_early_vs_mean_fishing_fraction") %>%
  pull(value)

fishing_r2 <- fishing_summary %>%
  filter(metric == "lm_adj_r2_mean_fishing_fraction") %>%
  pull(value)

if (length(fishing_r2) == 0) {
  fishing_r2 <- NA_real_
}

closure_value <- function(metric_name) {
  closure_summary %>%
    filter(metric == metric_name) %>%
    pull(value) %>%
    first()
}

recent_vs_roe <- closure_value("recent_vs_roe_biomass_ratio")
roe_fishing_fraction <- closure_value("roe_fishing_fraction_median")
recent_fishing_fraction <- closure_value("recent_fishing_fraction_median")
roe_occupied_sections <- closure_value("roe_occupied_sections_median")
recent_occupied_sections <- closure_value("recent_occupied_sections_median")

pdo_lag1 <- pdo_tbl %>%
  filter(lag == 1) %>%
  slice(1)

pdo_window_best <- pdo_window_tbl %>%
  slice_max(robust_score, n = 1, with_ties = FALSE)

combined_predator <- predator_tbl %>%
  filter(predator == "Combined predator") %>%
  slice(1)

if (nrow(combined_predator) == 0) {
  combined_predator <- predator_tbl %>%
    summarise(
      predator = "Combined predator",
      rho_year = max(abs(rho_year), na.rm = TRUE),
      rho_next_year_growth = min(rho_next_year_growth, na.rm = TRUE),
      .groups = "drop"
    )
}

predator_exposure_50 <- predator_exposure_cor %>%
  filter(range_km == 50) %>%
  mutate(label = paste0(
    predator,
    " exposure-growth rho ",
    fmt_num(rho_growth, 2),
    "; exposure-year rho ",
    fmt_num(rho_year, 2)
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

predator_availability_label <- predator_exposure_availability %>%
  mutate(label = paste0(
    predator,
    " ",
    first_year,
    "-",
    last_year,
    " (",
    observed_years,
    " observed years, ",
    predator_sites,
    " sites)"
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

local_transition_label <- local_transition %>%
  transmute(label = paste0(
    section_name,
    " recent/roe signal ",
    fmt_num(100 * recent_to_roe_signal, 1),
    "% (lost after roe ",
    lost_after_roe_locations,
    "/",
    raw_locations,
    " locations)"
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

local_targets_label <- local_targets %>%
  slice_head(n = 7) %>%
  transmute(label = paste0(
    priority_rank,
    ". ",
    LocationName,
    " (",
    section_name,
    "; ",
    priority_class,
    ")"
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

local_predator_label <- local_predator_section %>%
  filter(
    (predator == "Steller sea lion" & section_name == "Louscoone Inlet") |
      (predator == "Harbour seal" & section_name %in% c("Cumshewa Inlet", "Laskeek Bay"))
  ) %>%
  transmute(label = paste0(
    section_name,
    " ",
    predator,
    " median exposure z ",
    fmt_num(median_exposure_50_z, 2),
    ", nearest ",
    fmt_num(median_nearest_distance_km, 1),
    " km"
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

lost_vs_persisted_predator_label <- local_predator_status %>%
  filter(transition_status %in% c("lost after roe fishery", "persisted into recent closure")) %>%
  select(predator, transition_status, median_exposure_50_z) %>%
  pivot_wider(names_from = transition_status, values_from = median_exposure_50_z) %>%
  transmute(label = paste0(
    predator,
    " lost z ",
    fmt_num(`lost after roe fishery`, 2),
    " vs persisted z ",
    fmt_num(`persisted into recent closure`, 2)
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

distance_range <- distance_tbl %>%
  filter(parameter == "practical_range_km") %>%
  slice(1)

distance_fit <- distance_context %>%
  select(
    model,
    positive_signal_log_rmse,
    positive_signal_log_bias,
    max_pareto_k,
    loo_resolved,
    any_of(c("exact_reloo_looic_total", "exact_reloo_treedepth_hits"))
  )

m1_fit <- distance_fit %>%
  filter(model == "m1_stier_11") %>%
  slice(1)

m3_fit <- distance_fit %>%
  filter(model == "m3_stier_distance") %>%
  slice(1)

m3_reloo_evidence <- if (
  "exact_reloo_looic_total" %in% names(m3_fit) &&
    "exact_reloo_treedepth_hits" %in% names(m3_fit) &&
    is.finite(m3_fit$exact_reloo_looic_total)
) {
  glue(
    "exact re-LOO corrected LOOIC {fmt_num(m3_fit$exact_reloo_looic_total, 2)}; exact-refit treedepth hits {fmt_int(m3_fit$exact_reloo_treedepth_hits)}"
  )
} else {
  glue("max k {fmt_num(m3_fit$max_pareto_k, 3)}")
}

mhw_summary <- mhw_tbl %>%
  mutate(period_key = case_when(
    str_detect(period, "2005") ~ "pre",
    str_detect(period, "2014") ~ "mhw",
    str_detect(period, "2017") ~ "recent",
    TRUE ~ period
  )) %>%
  select(period_key, total_biomass_median, occupied_sections) %>%
  pivot_wider(
    names_from = period_key,
    values_from = c(total_biomass_median, occupied_sections)
  )

matrix_tbl <- tribble(
  ~priority, ~domain, ~claim, ~key_evidence, ~main_caveat, ~next_action, ~confidence,
  1, "Baseline model",
  "`m1_stier_11` is the practical baseline for current inference.",
  "Sampler-clean Stier-aligned 11-section model; zeros/no-surveys are ambiguous; two-era q is retained.",
  "Positive-spawn magnitudes remain weaker in the early surface-survey era.",
  "Use this as the analysis baseline unless a simpler branch clearly improves calibration and diagnostics.",
  "high",
  2, "Population state",
  "The system is not simply collapsed or recovered; recent biomass is moderate but spatially uneven.",
  glue("Recent median biomass {fmt_int(recent_row$total_biomass_median)} versus early {fmt_int(early_biomass)} and roe-fishery {fmt_int(roe_biomass)}; recent occupied sections {fmt_num(recent_row$occupied_sections, 1)} / 11."),
  "Archipelago totals are sensitive to aggregation and sparse-section uncertainty.",
  "Lead with period totals plus section/portfolio diagnostics, not total biomass alone.",
  "high",
  3, "Portfolio structure",
  "Recent biomass is concentrated in only a few sections.",
  glue("2017-2025 median top-3 share {fmt_num(100 * recent_concentration$top3_share, 0)}%; Simpson effective sections {fmt_num(recent_concentration$simpson_n, 2)}."),
  "Top-section identities vary with posterior uncertainty and reporting set.",
  "Use concentration/effective-section metrics as the main portfolio result.",
  "high",
  4, "Section status",
  "The strongest warning signal is persistent section-level depletion.",
  glue("{status_counts}; section roles: {role_counts}."),
  "Tasu and Naden are useful sensitivity sections but too sparse for headline evidence.",
  "Use the section narrative table to separate mechanism scrutiny, portfolio concern, recovery contrast, and sensitivity caveats.",
  "high",
  5, "Section action",
  "The safest section-level mechanism read separates depletion, concentration, recovery, and uncertainty roles.",
  action_counts,
  "This is analysis triage, not a causal attribution model.",
  "Use the section action matrix; prioritize Cumshewa/Louscoone local data audits before adding another regional driver branch.",
  "high",
  5.5, "Local spawn locations",
  "Lead-section depletion is visible within sections as location persistence/loss, not only section totals.",
  local_transition_label,
  "Raw location signal is not effort-adjusted and Skidegate is not available in this raw HG section extract.",
  "Use raw location transition and map diagnostics to target local access, habitat/substrate, and exposure follow-up.",
  "moderate-high",
  5.7, "Named local follow-up",
  "The local evidence is now specific enough to name places for targeted review.",
  local_targets_label,
  "A named lost-location target is not proof of biological absence; survey access, naming/code changes, and effort must be checked.",
  "Use the follow-up target table to organize local survey-access, habitat/substrate, and exposure questions before fitting another regional coefficient.",
  "moderate-high",
  6, "Observation process",
  "Zero records and missing cells should remain ambiguous in the baseline.",
  glue("{survey_tbl$positive_site_years} positive site-years; {survey_tbl$zero_record_site_years} zero-record site-years; {survey_tbl$missing_site_years} missing/unsurveyed site-years."),
  "The current data do not reliably distinguish true biological absence from no survey/access constraints.",
  "Do not promote an informative-nondetection model without survey-effort metadata.",
  "high",
  7, "Observation scale",
  "DFO tonnes and Stier legacy SHI agree directionally but are not interchangeable by one multiplier.",
  glue("Median legacy SHI / DFO tonnes ratio {fmt_num(scale_tbl$median_ratio, 1)}; 10-90% range {fmt_num(scale_tbl$lo10_ratio, 1)}-{fmt_num(scale_tbl$hi90_ratio, 1)}; log correlation {fmt_num(scale_tbl$cor_log, 2)}."),
  "Legacy q values should not be copied directly to the DFO-tonnes likelihood.",
  "If needed, run a legacy-SHI posterior sensitivity through 2015 rather than using a global rescale.",
  "high",
  8, "Historical fishing",
  "Fishing pressure is a central descriptive driver but not a full explanation.",
  glue("Recent/early biomass vs mean fishing fraction rho {fmt_num(fishing_rho, 2)}; recent biomass is {fmt_num(recent_vs_roe, 2)}x the roe-fishery median after fishing fraction fell from {fmt_num(100 * roe_fishing_fraction, 1)}% to {fmt_num(100 * recent_fishing_fraction, 1)}%, but occupied sections fell {fmt_num(roe_occupied_sections, 1)} to {fmt_num(recent_occupied_sections, 1)}."),
  "Only 11 sections; fishing is entangled with historic biomass, section size, management era, and survey coverage.",
  "Report fishing as a major axis, then separate aggregate biomass rebound from incomplete section/portfolio recovery.",
  "high",
  9, "PDO / climate",
  "PDO is already in the baseline and is the cleanest regional climate signal.",
  glue("Lag-1 PDO vs next-year growth Spearman rho {fmt_num(pdo_lag1$spearman_rho, 2)}; best cheap window {pdo_window_best$label} rho {fmt_num(pdo_window_best$spearman_rho, 2)} and adjusted beta {fmt_num(pdo_window_best$adjusted_beta, 2)}."),
  "The baseline Stan PDO coefficient interval still overlaps zero, so this is climate context rather than a strong promoted effect.",
  "Do not launch a redundant PDO-only branch; if needed, test PDO window/lag sensitivity on the existing baseline structure.",
  "moderate",
  10, "Predators",
  "Predator recovery is plausible ecological context, not current causal model evidence.",
  glue("Combined predator index vs year rho {fmt_num(combined_predator$rho_year, 2)}; vs next-year growth rho {fmt_num(combined_predator$rho_next_year_growth, 2)}."),
  "Predator indices are strongly time-confounded and collinear; humpbacks are basin-scale rather than section exposure.",
  "Hold predator Stan branches until a spatial exposure data product exists.",
  "moderate",
  11, "Predator exposure data product",
  "Raw HG harbour seal and Steller sea lion records can support a future section-level exposure covariate, but not yet a promoted predator effect.",
  glue("{predator_availability_label}; 50 km screen: {predator_exposure_50}."),
  "Prototype exposure still mixes count trends, effort choices, distance kernels, and predator movement; humpback exposure remains unresolved.",
  "Refine the exposure data product before adding predator coefficients: effort correction, interpolation rules, range kernels, and species-specific exposure hypotheses.",
  "moderate",
  11.5, "Local predator proximity",
  "Predator proximity can now be computed for geocoded lead-section spawn locations, but it does not yet explain location loss.",
  glue("{local_predator_label}; {lost_vs_persisted_predator_label}."),
  "Post-2005 predator observations do not reconstruct historical exposure during roe-era loss years.",
  "Use this as local audit targeting and as design input for a better predator exposure product, not as predator-effect evidence.",
  "moderate",
  12, "Spatial process",
  "Distance-correlated process shocks are plausible but not yet promoted.",
  glue("M3 distance practical range median {fmt_num(distance_range$median, 0)} km; positive-spawn RMSE {fmt_num(m3_fit$positive_signal_log_rmse, 3)} vs baseline {fmt_num(m1_fit$positive_signal_log_rmse, 3)}; {m3_reloo_evidence}."),
  "Exact re-LOO completed, but calibration gain is small and one exact refit showed treedepth pressure.",
  "Use as spatial-process context, not promoted inference; revisit only if a new process branch improves calibration materially.",
  "moderate",
  13, "Density dependence",
  "Current posterior medians do not justify complex density dependence.",
  glue("Pooled section growth vs lagged biomass rho {fmt_num(density_tbl$spearman_rho, 2)}; slope {fmt_num(density_tbl$lm_slope, 3)}."),
  "This is descriptive, not a full dynamic model test.",
  "If tested, start with one global Gompertz term only, after the current branches are settled.",
  "low to moderate",
  14, "Marine heatwave context",
  "The marine heatwave is a useful period marker but does not explain the section pattern by itself.",
  glue("Occupied sections: pre-MHW {fmt_num(mhw_summary$occupied_sections_pre, 1)}, MHW {fmt_num(mhw_summary$occupied_sections_mhw, 1)}, recent {fmt_num(mhw_summary$occupied_sections_recent, 1)}."),
  "Period windows are short and survey coverage is uneven.",
  "Use MHW as temporal context, not as the main causal claim.",
  "moderate"
) %>%
  arrange(priority)

readr::write_csv(matrix_tbl, file.path(diag_dir, "may10_integrated_evidence_matrix.csv"))

md_lines <- c(
  "# Integrated Evidence Matrix",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This matrix condenses the current May 9-10 diagnostics into actionable claims. It is not a slide deck; it is an analysis control sheet for deciding what to trust, what to hold, and what to run next.",
  "",
  "|priority|domain|claim|key evidence|main caveat|next action|confidence|",
  "|---:|:---|:---|:---|:---|:---|:---|",
  pmap_chr(
    matrix_tbl,
    function(priority, domain, claim, key_evidence, main_caveat, next_action, confidence) {
      cells <- c(priority, domain, claim, key_evidence, main_caveat, next_action, confidence)
      cells <- str_replace_all(as.character(cells), "\\|", "/")
      paste0("|", paste(cells, collapse = "|"), "|")
    }
  ),
  "",
  "## Operating Decision",
  "",
  "- Keep `m1_stier_11` as the promoted baseline.",
"- Treat zeros/no-surveys as ambiguous unless survey-effort metadata can distinguish true nondetection from no survey/access constraints.",
"- Use historical fishing, spatial concentration, and section-role diagnostics as the strongest current population story.",
"- Use PDO as baseline climate context and the distance-covariance branch as spatial-process context, not promoted inference.",
"- Keep predators, complex density dependence, and age/size structure out of the promoted model path before Monday."
)

writeLines(md_lines, file.path(diag_dir, "may10_integrated_evidence_matrix.md"))

cat("Saved:\n")
cat("  Output/diagnostics/may10_integrated_evidence_matrix.csv\n")
cat("  Output/diagnostics/may10_integrated_evidence_matrix.md\n")
