# ============================================================================
# 07bh_covariate_readiness_registry.R
# Current and candidate covariate readiness registry.
# ============================================================================

library(tidyverse)
library(here)
library(glue)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(file) {
  path <- file.path(diag_dir, file)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

read_diag_optional <- function(file) {
  path <- file.path(diag_dir, file)
  if (!file.exists(path)) {
    return(tibble())
  }
  read_csv(path, show_col_types = FALSE)
}

fmt <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
}

model_tbl <- read_diag("model_branch_status_table.csv")
survey_tbl <- read_diag("survey_coverage_zero_ambiguity_overall.csv")
fishing_tbl <- read_diag("fishing_pressure_decomposition_summary.csv")
pdo_tbl <- read_diag("pdo_climate_lag_screen.csv")
pdo_window_tbl <- read_diag("pdo_window_sensitivity.csv")
density_tbl <- read_diag("density_dependence_pooled_section_summary.csv")
distance_tbl <- read_diag("m3_stier_distance_global_parameters.csv")
predator_tbl <- read_diag("predator_data_confounding.csv")
predator_availability <- read_diag("predator_spatial_exposure_availability.csv")
predator_cor <- read_diag("predator_spatial_exposure_growth_correlations.csv")
predator_demand_screen <- read_diag_optional("wcvi_predator_demand_residual_screen.csv")
recovery_cov <- read_diag("section_recovery_covariate_correlations.csv")
local_targets <- read_diag("lead_location_followup_targets.csv")
location_transition <- read_diag("lead_section_location_transition_summary.csv")
timing_substrate_period <- read_diag("spawn_timing_substrate_period.csv")

m1 <- model_tbl %>%
  filter(model == "m1_stier_11") %>%
  slice(1)

m3 <- model_tbl %>%
  filter(model == "m3_stier_distance") %>%
  slice(1)

fishing_rho <- fishing_tbl %>%
  filter(metric == "rho_recent_early_vs_mean_fishing_fraction") %>%
  pull(value) %>%
  first()

pdo_lag1 <- pdo_tbl %>%
  filter(lag == 1) %>%
  slice(1)

pdo_best <- pdo_window_tbl %>%
  slice_max(robust_score, n = 1, with_ties = FALSE)

density <- density_tbl %>%
  slice(1)

distance_range <- distance_tbl %>%
  filter(parameter == "practical_range_km") %>%
  slice(1)

pred_combined <- predator_tbl %>%
  filter(predator == "Combined predator") %>%
  slice(1)

if (nrow(pred_combined) == 0) {
  pred_combined <- tibble(
    rho_year = NA_real_,
    rho_next_year_growth = NA_real_
  )
}

pred_demand_lag1 <- predator_demand_screen %>%
  filter(predictor == "demand_total_log_z", lag_label == "lag_1") %>%
  slice(1)

pred_demand_label <- if (nrow(pred_demand_lag1) == 0) {
  "Run Code/07bj_wcvi_predation_replication_bridge.R to score total predator demand."
} else {
  glue(
    "WCVI bridge total-demand lag-1 rho {fmt(pred_demand_lag1$spearman_rho, 2)}, detrended r {fmt(pred_demand_lag1$detrended_r, 2)}, adjusted beta {fmt(pred_demand_lag1$adjusted_beta, 2)}."
  )
}

pred_exposure_label <- predator_cor %>%
  filter(range_km == 50) %>%
  transmute(label = paste0(
    predator,
    " growth rho ",
    fmt(rho_growth, 2),
    ", year rho ",
    fmt(rho_year, 2)
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

pred_availability_label <- predator_availability %>%
  transmute(label = paste0(
    predator,
    " ",
    first_year,
    "-",
    last_year,
    " (",
    observed_years,
    " years)"
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

local_target_label <- local_targets %>%
  slice_head(n = 5) %>%
  transmute(label = paste0(LocationName, " / ", section_name)) %>%
  pull(label) %>%
  paste(collapse = "; ")

location_loss_label <- location_transition %>%
  transmute(label = paste0(
    section_name,
    " recent/roe ",
    percent(recent_to_roe_signal, accuracy = 0.1),
    ", lost ",
    lost_after_roe_locations,
    "/",
    raw_locations
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

timing_substrate_label <- timing_substrate_period %>%
  summarise(
    surveyed_sections_recent = median_surveyed_sections[str_detect(period, "recent")][1],
    surveyed_sections_roe = median_surveyed_sections[str_detect(period, "roe")][1],
    median_recent_start = median_spawn_start_doy[str_detect(period, "recent")][1],
    median_roe_start = median_spawn_start_doy[str_detect(period, "roe")][1],
    recent_subtidal = median_subtidal_share[str_detect(period, "recent")][1],
    roe_subtidal = median_subtidal_share[str_detect(period, "roe")][1],
    .groups = "drop"
  )

covariate_registry <- tribble(
  ~covariate_or_feature, ~current_role, ~grain, ~evidence_summary, ~main_blocker, ~recommended_action, ~readiness,
  "Catch removals / fishing fraction",
  "in promoted model as removals; descriptive recovery axis",
  "section-year catch plus section-period summaries",
  glue("Catch is accounted for in the state process; section recovery vs mean fishing fraction rho {fmt(fishing_rho, 2)}."),
  "Fishing pressure is confounded with historical biomass, section size, and management era.",
  "Report as a central descriptive driver; do not add another redundant fishing covariate without a clear mechanistic contrast.",
  "ready for interpretation",
  "Lag-1 PDO",
  "in promoted model",
  "annual regional covariate",
  glue("Baseline includes lag-1 PDO; cheap screen lag-1 rho {fmt(pdo_lag1$spearman_rho, 2)}, best window {pdo_best$label} rho {fmt(pdo_best$spearman_rho, 2)}."),
  "Regional climate signal is not section-specific and posterior coefficient remains uncertain.",
  "Keep as baseline climate context; defer new climate branches unless using residual diagnostics.",
  "ready as context",
  "Survey catchability q",
  "in promoted observation model",
  "survey-era observation calibration",
  "Stier two-era surface/SCUBA q retained; method-sensitivity branch was clean but did not improve positive-spawn calibration.",
  "DFO tonnes and legacy SHI are not interchangeable by one constant multiplier.",
  "Keep Stier two-era q for promoted baseline; cite three-era q branch as sensitivity only.",
  "ready for baseline",
  "Ambiguous zeros / no-survey cells",
  "in promoted likelihood as missing/ambiguous",
  "section-year observation status",
  glue("{survey_tbl$positive_site_years} positive site-years, {survey_tbl$zero_record_site_years} zero-record site-years, {survey_tbl$missing_site_years} missing/unsurveyed site-years."),
  "No complete survey-effort/access metadata; some no-surveys may reflect governance/access decisions rather than low biomass.",
  "Do not promote informative nondetection without survey-effort metadata.",
  "ready as caveat",
  "11-section spatial reporting",
  "in promoted model",
  "section-level state series",
  glue("Promoted model is clean: divergences {m1$divergences}, treedepth hits {m1$treedepth_hits}, positive-spawn RMSE {fmt(m1$positive_signal_log_rmse, 3)}."),
  "Tasu/Naden create upper-tail biomass sensitivity.",
  "Report all-11 and focal-9 biomass together; use uncertainty decomposition.",
  "ready for reporting",
  "Distance-correlated process shocks",
  "held spatial context branch",
  "section process covariance",
  glue("M3 practical range median {fmt(distance_range$median, 0)} km; RMSE {fmt(m3$positive_signal_log_rmse, 3)}; exact re-LOO completed but treedepth pressure remains."),
  "Small calibration gain and exact-refit geometry pressure.",
  "Use as ecological context only; do not promote before a cleaner branch improves calibration.",
  "context only",
  "Density dependence",
  "descriptive screen only",
  "pooled section-year growth vs lagged biomass",
  glue("Pooled screen rho {fmt(density$spearman_rho, 2)}, slope {fmt(density$lm_slope, 3)}."),
  "Weak signal and high risk of geometry/pathology if made site-specific.",
  "If tested, start with one global Gompertz term only after reporting is stable.",
  "not ready for promotion",
  "Predator regional indices",
  "descriptive context only",
  "annual regional abundance/index",
  glue("Combined predator index vs year rho {fmt(pred_combined$rho_year, 2)}; vs next-year growth rho {fmt(pred_combined$rho_next_year_growth, 2)}."),
  "Strong calendar-time confounding; humpbacks not section-specific.",
  "Do not promote predator coefficient from regional index.",
  "not ready",
  "Predator annual demand",
  "WCVI-style removals analogue and gated model covariate",
  "annual regional consumption budget",
  pred_demand_label,
  "Total demand is more exogenous than pressure ratio, but still time-confounded and weak after adjustment.",
  "Use `m5_stier_predator_demand_total` only as a deliberate single-covariate screen; do not submit combinations.",
  "screen only",
  "Predator spatial exposure",
  "prototype data product",
  "section-year / local-distance exposure",
  glue("{pred_availability_label}; 50 km screen: {pred_exposure_label}."),
  "Effort, movement, interpolation, and historical exposure assumptions are unresolved.",
  "Refine data product before Stan predator branch; use local proximity only as targeting.",
  "prototype",
  "Local spawn-location persistence",
  "descriptive local mechanism target",
  "raw spawn location within lead sections",
  glue("{location_loss_label}. Top targets: {local_target_label}."),
  "Raw location screen is not effort-adjusted; no recent positive record is not proof of absence.",
  "Use named target list for local survey-access, habitat/substrate, and exposure review.",
  "ready for local follow-up",
  "Spawn timing and substrate",
  "screened descriptive covariates",
  "section-period raw spawn records",
  glue("Current timing/substrate screen has median surveyed sections {fmt(timing_substrate_label$surveyed_sections_recent, 0)} recent vs {fmt(timing_substrate_label$surveyed_sections_roe, 0)} roe; median recent start DOY {fmt(timing_substrate_label$median_recent_start, 1)} vs roe DOY {fmt(timing_substrate_label$median_roe_start, 1)}; subtidal share {percent(timing_substrate_label$recent_subtidal, accuracy = 1)} recent vs {percent(timing_substrate_label$roe_subtidal, accuracy = 1)} roe."),
  "Missingness and survey method confounding remain strong; section coverage is incomplete.",
  "Use for interpretation and local follow-up before Stan branch.",
  "screen only",
  "Age/size structure",
  "held out",
  "regional biosample / assessment context",
  "NotebookLM and DFO materials indicate age and weight-at-age are relevant, but local raw age data are not currently available in a section-level form.",
  "Full 11-section age-structured model is data hungry and would likely force aggregation.",
  "Hold off; use age/weight only as future regional context if data are pulled cleanly.",
  "held"
) %>%
  mutate(
    readiness = factor(
      readiness,
      levels = c(
        "ready for baseline",
        "ready for interpretation",
        "ready for reporting",
        "ready as context",
        "ready as caveat",
        "ready for local follow-up",
        "context only",
        "prototype",
        "screen only",
        "not ready for promotion",
        "not ready",
        "held"
      )
    )
  ) %>%
  arrange(readiness, covariate_or_feature)

write_csv(covariate_registry, file.path(diag_dir, "covariate_readiness_registry.csv"))

md_tbl <- covariate_registry %>%
  mutate(readiness = as.character(readiness))

lines <- c(
  "# Covariate Readiness Registry",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This registry separates covariates already used by the promoted model from descriptive screens, prototype data products, and held model ideas.",
  "",
  knitr::kable(md_tbl, format = "pipe"),
  "",
  "## Operating Read",
  "",
  "- The promoted model already includes catch removals, lag-1 PDO, surface/SCUBA q, ambiguous zeros, and all 11 sections.",
  "- Historical fishing is the strongest descriptive recovery axis, but the model should not double-count it as a new covariate without a specific contrast.",
  "- Predator, timing, substrate, and local location signals are better treated as data products and local follow-up targets before Stan coefficients.",
  "- Age/size structure remains held for this talk cycle."
)

writeLines(lines, file.path(diag_dir, "covariate_readiness_registry.md"))

cat("Saved:\n")
cat("  Output/diagnostics/covariate_readiness_registry.csv\n")
cat("  Output/diagnostics/covariate_readiness_registry.md\n")
