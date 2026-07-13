# ============================================================================
# 07q_may9_headline_findings_table.R
# Compile a compact table of headline findings from the May 9 analysis outputs.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(filename) {
  path <- file.path(diag_dir, filename)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

period_tbl <- read_diag("m1_stier_11_period_summary.csv")
current_tbl <- read_diag("m1_stier_11_current_year_summary.csv")
current_section_tbl <- read_diag("m1_stier_11_current_year_status.csv")
scorecard_tbl <- read_diag("m1_stier_11_section_scorecard.csv")
concentration_tbl <- read_diag("m1_stier_11_recent_spatial_concentration.csv")
driver_conf_tbl <- read_diag("m1_stier_11_driver_time_confounding.csv")
driver_pair_tbl <- read_diag("m1_stier_11_driver_high_pair_correlations.csv")
driver_corr_tbl <- read_diag("m1_stier_11_driver_correlations.csv")
uncertainty_tbl <- read_diag("m1_stier_11_uncertainty_by_section.csv")
scale_global_tbl <- read_diag("spawn_index_scale_global_summary.csv")
scale_section_tbl <- read_diag("spawn_index_scale_by_section.csv")
m3_global_tbl <- read_diag("m3_stier_distance_global_parameters.csv")
m3_context_tbl <- read_diag("m3_stier_distance_comparison_context.csv")
legacy_scale_agreement_tbl <- read_diag("legacy_shi_overlap_scale_agreement.csv")
occupancy_transition_tbl <- read_diag("observed_occupancy_transition_summary.csv")
density_total_tbl <- read_diag("density_dependence_total_summary.csv")
density_pooled_tbl <- read_diag("density_dependence_pooled_section_summary.csv")
density_section_tbl <- read_diag("density_dependence_by_section.csv")
fishing_pressure_summary_tbl <- read_diag("fishing_pressure_decomposition_summary.csv")
fishing_pressure_section_tbl <- read_diag("fishing_pressure_decomposition_by_section.csv")
pdo_lag_tbl <- read_diag("pdo_climate_lag_screen.csv")
typology_tbl <- read_diag("section_mechanism_typology.csv")
section_change_tbl <- read_diag("section_change_contribution_summary.csv")
mhw_period_tbl <- read_diag("mhw_recovery_period_summary.csv")
survey_ambiguity_overall_tbl <- read_diag("survey_coverage_zero_ambiguity_overall.csv")
survey_ambiguity_period_tbl <- read_diag("survey_coverage_zero_ambiguity_by_period.csv")
predator_feasibility_tbl <- read_diag("predator_data_confounding.csv")

fmt_num <- function(x, accuracy = 1) {
  number(x, accuracy = accuracy, big.mark = ",")
}

fmt_pct <- function(x, accuracy = 1) {
  percent(x, accuracy = accuracy)
}

period_value <- function(period, col) {
  period_tbl %>%
    filter(.data$period == !!period) %>%
    pull({{ col }}) %>%
    first()
}

recent_biomass <- period_value("2017-2025 recent closure", total_biomass_median)
early_biomass <- period_value("1951-1965 early industrial", total_biomass_median)
roe_biomass <- period_value("1972-2004 roe fishery", total_biomass_median)
recent_occupied <- period_value("2017-2025 recent closure", occupied_sections)
roe_fishing <- period_value("1972-2004 roe fishery", fishing_fraction)
recent_fishing <- period_value("2017-2025 recent closure", fishing_fraction)

current <- current_tbl %>% slice(1)
all11_concentration <- concentration_tbl %>%
  filter(report_set == "all_11") %>%
  slice(1)

status_counts <- scorecard_tbl %>%
  count(status, name = "n") %>%
  arrange(desc(n), status)

persistently_depleted <- scorecard_tbl %>%
  filter(status == "persistently depleted") %>%
  arrange(recent_to_early_ratio) %>%
  pull(site_name)

flat_declining <- scorecard_tbl %>%
  filter(status == "flat or declining") %>%
  arrange(recent_to_early_ratio) %>%
  pull(site_name)

top_current_sections <- current_section_tbl %>%
  arrange(desc(current_share)) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " ", fmt_pct(current_share, accuracy = 1))) %>%
  pull(label)

top_driver_confounds <- driver_conf_tbl %>%
  arrange(desc(abs(rho_year))) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(driver_label, " rho(year)=", round(rho_year, 2))) %>%
  pull(label)

top_pair_confounds <- driver_pair_tbl %>%
  arrange(desc(abs(rho))) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(driver_x_label, " / ", driver_y_label, " rho=", round(rho, 2))) %>%
  pull(label)

top_growth_correlations <- driver_corr_tbl %>%
  filter(response == "growth_median") %>%
  arrange(desc(abs(spearman_rho))) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(predictor, " rho=", round(spearman_rho, 2))) %>%
  pull(label)

highest_uncertainty <- uncertainty_tbl %>%
  arrange(desc(recent_rel_width_90)) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " width/median=", fmt_num(recent_rel_width_90, 0.1))) %>%
  pull(label)

scale_global <- scale_global_tbl %>% slice(1)
scale_section_range <- range(scale_section_tbl$median_ratio, na.rm = TRUE)
legacy_annual_cor <- legacy_scale_agreement_tbl %>%
  filter(metric == "annual_total_log_correlation") %>%
  pull(value) %>%
  first()

legacy_section_cor <- legacy_scale_agreement_tbl %>%
  filter(metric == "section_recent_early_spearman") %>%
  pull(value) %>%
  first()

m3_range <- m3_global_tbl %>%
  filter(parameter == "practical_range_km") %>%
  slice(1)

m3_context <- m3_context_tbl %>%
  filter(model == "m3_stier_distance") %>%
  slice(1)

m3_reloo_evidence <- if (
  "exact_reloo_looic_total" %in% names(m3_context) &&
    "exact_reloo_treedepth_hits" %in% names(m3_context) &&
    is.finite(m3_context$exact_reloo_looic_total)
) {
  paste0(
    "; exact re-LOO LOOIC ",
    fmt_num(m3_context$exact_reloo_looic_total, 0.01),
    "; exact-refit treedepth hits ",
    fmt_num(m3_context$exact_reloo_treedepth_hits, 1)
  )
} else {
  paste0("; max k ", fmt_num(m3_context$max_pareto_k, 0.001))
}

occupancy_transition <- occupancy_transition_tbl %>% slice(1)
density_total <- density_total_tbl %>% slice(1)
density_pooled <- density_pooled_tbl %>% slice(1)

top_density_sections <- density_section_tbl %>%
  arrange(spearman_rho) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " rho=", round(spearman_rho, 2))) %>%
  pull(label)

fishing_summary_value <- function(metric) {
  fishing_pressure_summary_tbl %>%
    filter(.data$metric == !!metric) %>%
    pull(value) %>%
    first()
}

top_fishing_residual_sections <- fishing_pressure_section_tbl %>%
  arrange(fishing_only_resid) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " resid=", fmt_num(fishing_only_resid, 0.01))) %>%
  pull(label)

pdo_lag1 <- pdo_lag_tbl %>%
  filter(lag == 1) %>%
  slice(1)

persistent_beyond_fishing <- typology_tbl %>%
  filter(typology == "persistent depletion beyond fishing") %>%
  pull(site_name)

sparse_uncertain_sections <- typology_tbl %>%
  filter(typology == "sparse/uncertain sensitivity") %>%
  pull(site_name)

section_change_value <- function(comparison) {
  section_change_tbl %>%
    filter(.data$comparison == !!comparison) %>%
    pull(total_change) %>%
    first()
}

mhw_period_value <- function(period, col) {
  mhw_period_tbl %>%
    filter(.data$period == !!period) %>%
    pull({{ col }}) %>%
    first()
}

survey_ambiguity_overall <- survey_ambiguity_overall_tbl %>% slice(1)
weakest_survey_periods <- survey_ambiguity_period_tbl %>%
  arrange(median_surveyed_sections) %>%
  slice_head(n = 2) %>%
  transmute(label = paste0(period, " median surveyed=", median_surveyed_sections)) %>%
  pull(label)

pred_combined_feasibility <- predator_feasibility_tbl %>%
  filter(predator == "Combined predator") %>%
  slice(1)

pdo_feasibility <- predator_feasibility_tbl %>%
  filter(predator == "PDO") %>%
  slice(1)

headline_tbl <- tribble(
  ~category, ~finding, ~value, ~interpretation, ~source,
  "Population state", "Recent closure biomass versus early baseline",
  paste0(fmt_num(recent_biomass), " vs ", fmt_num(early_biomass), " tonnes-equivalent"),
  "Recent median biomass is below the early industrial median, despite fishery closure.",
  "m1_stier_11_period_summary.csv",
  "Population state", "Recent closure biomass versus roe-fishery period",
  paste0(fmt_num(recent_biomass), " vs ", fmt_num(roe_biomass), " tonnes-equivalent"),
  "Recent total biomass is higher than the roe-fishery period, but spatial composition is not recovered.",
  "m1_stier_11_period_summary.csv",
  "Occupancy", "Recent occupied sections",
  paste0(fmt_num(recent_occupied, 0.1), " of 11"),
  "The closure-era population is not evenly reoccupying the archipelago.",
  "m1_stier_11_period_summary.csv",
  "Occupancy", "Observed positive-detection persistence",
  paste0(
    percent(occupancy_transition$persistence, accuracy = 0.1),
    " across ",
    occupancy_transition$n_adjacent_surveyed_pairs,
    " adjacent surveyed pairs"
  ),
  "Positive detections are highly persistent where consecutive surveys exist, but this is not a true-absence occupancy model.",
  "observed_occupancy_transition_screen.md",
  "Observation scale", "Zero and no-survey ambiguity",
  paste0(
    survey_ambiguity_overall$positive_site_years,
    " positive; ",
    survey_ambiguity_overall$zero_record_site_years,
    " zero-record; ",
    survey_ambiguity_overall$missing_site_years,
    " missing"
  ),
  paste0(
    "Zero/no-survey cells should stay ambiguous in the baseline; weakest coverage periods are ",
    paste(weakest_survey_periods, collapse = "; "),
    "."
  ),
  "survey_coverage_zero_ambiguity.md",
  "Fishing", "Recent fishing fraction",
  paste0(fmt_num(recent_fishing, 0.001), " recent vs ", fmt_num(roe_fishing, 0.001), " roe-fishery"),
  "Ongoing direct fishing removal is not the proximate recent driver in the baseline.",
  "m1_stier_11_period_summary.csv",
  "Fishing", "Historical fishing pressure decomposition",
  paste0(
    "rho=",
    fmt_num(fishing_summary_value("rho_recent_early_vs_mean_fishing_fraction"), 0.01),
    "; adj R2=",
    fmt_num(fishing_summary_value("lm_adj_r2_mean_fishing_fraction"), 0.01)
  ),
  paste0(
    "Fishing pressure is a strong descriptive axis, but worse-than-fishing residuals remain for ",
    paste(top_fishing_residual_sections, collapse = "; "),
    "."
  ),
  "fishing_pressure_decomposition.md",
  "Portfolio", "Recent top-3 biomass share",
  fmt_pct(all11_concentration$top3_share, accuracy = 1),
  "Recent biomass is concentrated in a few sections, so total biomass alone is misleading.",
  "m1_stier_11_recent_spatial_concentration.csv",
  "Portfolio", "Recent Simpson effective sections",
  fmt_num(all11_concentration$simpson_effective_sections, 0.01),
  "The recent portfolio behaves like roughly three effective biomass-bearing sections.",
  "m1_stier_11_recent_spatial_concentration.csv",
  "Portfolio", "Section contribution to biomass change",
  paste0(
    "recent-early ",
    fmt_num(section_change_value("recent_minus_early"), 1),
    "; recent-roe ",
    fmt_num(section_change_value("recent_minus_roe"), 1)
  ),
  "Recovery depends on aggregation metric; recent gains are concentrated and do not restore broad section-level biomass.",
  "section_change_contribution.md",
  "Population state", "Marine heatwave window",
  paste0(
    "occupied sections ",
    fmt_num(mhw_period_value("2005-2013 closure", occupied_sections), 0.1),
    " pre-MHW; ",
    fmt_num(mhw_period_value("2014-2016 marine heatwave", occupied_sections), 0.1),
    " MHW; ",
    fmt_num(mhw_period_value("2017-2025 recent closure", occupied_sections), 0.1),
    " recent"
  ),
  "The MHW window is useful context, but it does not alone explain the spatial recovery/depletion typology.",
  "mhw_recovery_screen.md",
  "Current year", "2025 total biomass and concentration",
  paste0(fmt_num(current$total_biomass_median), "; top-3 share ", fmt_pct(current$top3_share, accuracy = 1)),
  "The current-year state is concentrated and should be read with survey coverage caveats.",
  "m1_stier_11_current_year_summary.csv",
  "Current year", "Largest 2025 sections",
  paste(top_current_sections, collapse = "; "),
  "Juan Perez and Skincuttle dominate current estimated biomass.",
  "m1_stier_11_current_year_status.csv",
  "Section status", "Persistently depleted sections",
  paste(persistently_depleted, collapse = "; "),
  "Persistent depletion is the strongest spatial warning signal.",
  "m1_stier_11_section_scorecard.csv",
  "Section status", "Flat or declining sections",
  paste(flat_declining, collapse = "; "),
  "These sections are not showing convincing closure-era recovery.",
  "m1_stier_11_section_scorecard.csv",
  "Section status", "Status counts",
  paste(paste0(status_counts$status, "=", status_counts$n), collapse = "; "),
  "Section-level outcomes are heterogeneous, but the simple site-growth branch did not improve fit.",
  "m1_stier_11_section_scorecard.csv",
  "Section status", "Mechanism typology",
  paste0("beyond-fishing depletion: ", paste(persistent_beyond_fishing, collapse = "; ")),
  paste0(
    "Cumshewa/Louscoone are clearest depletion-beyond-fishing cases; sparse sensitivity sections are ",
    paste(sparse_uncertain_sections, collapse = "; "),
    "."
  ),
  "section_mechanism_typology.md",
  "Observation scale", "Legacy SHI versus DFO tonnes",
  paste0(
    "median ratio ",
    fmt_num(scale_global$median_ratio, 0.1),
    "; section medians ",
    fmt_num(scale_section_range[1], 0.1),
    "-",
    fmt_num(scale_section_range[2], 0.1)
  ),
  "The current DFO-tonnes model is internally consistent, but legacy q values are not transferable by one multiplier.",
  "spawn_index_scale_audit.md",
  "Observation scale", "Legacy-SHI overlap sensitivity",
  paste0("annual r=", fmt_num(legacy_annual_cor, 0.001), "; section rho=", fmt_num(legacy_section_cor, 0.001)),
  "Through 2015, the broad observed annual and section-direction patterns are similar across scales.",
  "legacy_shi_overlap_sensitivity.md",
  "Process model", "Distance-covariance branch",
  paste0(
    "range ",
    fmt_num(m3_range$median, 0.1),
    " km; RMSE ",
    fmt_num(m3_context$positive_signal_log_rmse, 0.001),
    m3_reloo_evidence
  ),
  "Spatially correlated process noise is plausible, but m3_stier_distance is held because fit gain is small and exact refits showed treedepth pressure.",
  "m3_stier_distance_postfit.md",
  "Process model", "Density-dependence screen",
  paste0(
    "archipelago rho ",
    fmt_num(density_total$spearman_rho, 0.001),
    "; pooled section rho ",
    fmt_num(density_pooled$spearman_rho, 0.001)
  ),
  paste0(
    "No strong descriptive global density-dependence signal; strongest negative section screens are ",
    paste(top_density_sections, collapse = "; "),
    "."
  ),
  "density_dependence_screen.md",
  "Driver screen", "Strongest simple growth correlations",
  paste(top_growth_correlations, collapse = "; "),
  "PDO is the cleanest near-term regional covariate; predator signals are descriptive for now.",
  "m1_stier_11_driver_correlations.csv",
  "Driver screen", "PDO climate signal",
  paste0(
    "lag-1 rho ",
    fmt_num(pdo_lag1$spearman_rho, 0.01),
    "; detrended r ",
    fmt_num(pdo_lag1$detrended_r, 0.01)
  ),
  "PDO is growth-associated without being a monotonic time trend, but the baseline Stan PDO interval still overlaps zero.",
  "pdo_climate_signal_screen.md",
  "Driver screen", "Predator data feasibility",
  paste0(
    "combined predator rho(year)=",
    fmt_num(pred_combined_feasibility$rho_year, 0.01),
    "; rho(growth)=",
    fmt_num(pred_combined_feasibility$rho_next_year_growth, 0.01),
    "; PDO rho(year)=",
    fmt_num(pdo_feasibility$rho_year, 0.01)
  ),
  "Predator recovery is plausible context, but current predator covariates are too time-confounded for the next Stan branch.",
  "predator_data_feasibility_audit.md",
  "Driver confounding", "Most time-confounded predictors",
  paste(top_driver_confounds, collapse = "; "),
  "Predator indices are strongly time-trended, making one-covariate predator causality unsafe.",
  "m1_stier_11_driver_time_confounding.csv",
  "Driver confounding", "Strong pairwise driver correlations",
  paste(top_pair_confounds, collapse = "; "),
  "Predator, catch, and time signals are entangled; richer driver models need strong priors and careful comparisons.",
  "m1_stier_11_driver_high_pair_correlations.csv",
  "Uncertainty", "Highest recent section uncertainty",
  paste(highest_uncertainty, collapse = "; "),
  "Sparse sections remain useful in the 11-section model but should not carry headline inference alone.",
  "m1_stier_11_uncertainty_by_section.csv"
)

write_csv(headline_tbl, file.path(diag_dir, "may9_headline_findings.csv"))

md_lines <- c(
  "# May 9 Headline Findings",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This table compiles the main population and driver findings from the current `m1_stier_11` analysis outputs.",
  "",
  knitr::kable(headline_tbl, format = "pipe")
)

writeLines(md_lines, file.path(diag_dir, "may9_headline_findings.md"))

cat("Saved headline findings table:\n")
cat("  Output/diagnostics/may9_headline_findings.csv\n")
cat("  Output/diagnostics/may9_headline_findings.md\n")
