# ============================================================================
# 07br_predator_talk_brief.R
# Talk-ready predator claim brief from current gated diagnostics.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_csv_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(tibble())
  }
  read_csv(path, show_col_types = FALSE)
}

fmt <- function(x, accuracy = 0.01) {
  number(as.numeric(x), accuracy = accuracy)
}

bridge_ts <- read_csv_if_exists(file.path(diag_dir, "wcvi_predation_replication_bridge_timeseries.csv"))
screen <- read_csv_if_exists(file.path(diag_dir, "wcvi_predator_demand_residual_screen.csv"))
exposure_recent <- read_csv_if_exists(file.path(diag_dir, "predator_spatial_exposure_recent_by_section.csv"))
humpback_proxy <- read_csv_if_exists(file.path(diag_dir, "humpback_section_exposure_proxy.csv"))
salmon_context <- read_csv_if_exists(file.path(diag_dir, "salmon_recruitment_context_screen.csv"))

if (nrow(bridge_ts) == 0 || nrow(screen) == 0) {
  stop("Bridge diagnostics missing. Rerun Code/07bj_wcvi_predation_replication_bridge.R first.")
}

recent_scale <- bridge_ts %>%
  filter(year >= 2015, year <= 2024) %>%
  summarise(
    mean_predator_consumption_kt = mean(C_total_kt, na.rm = TRUE),
    mean_biomass_kt = mean(total_biomass_kt, na.rm = TRUE),
    median_predator_removal_rate = median(predator_removal_rate, na.rm = TRUE),
    mean_pressure_pct = mean(pressure_pct, na.rm = TRUE),
    .groups = "drop"
  )

gate_summary <- screen %>%
  filter(lag_label == "lag_1", class %in% c("demand", "spatial_exposure", "mortality_proxy")) %>%
  count(class, gate, name = "n_predictors") %>%
  arrange(class, gate)

best_exposure <- screen %>%
  filter(lag_label == "lag_1", class == "spatial_exposure") %>%
  arrange(desc(robust_score)) %>%
  slice(1)

salmon_row <- screen %>%
  filter(label == "Salmon predator demand", lag_label == "lag_1") %>%
  slice(1)

humpback_recent <- if (nrow(humpback_proxy) > 0) {
  humpback_proxy %>%
    distinct(year, C_year_tonnes, N_indiv, model_readiness) %>%
    filter(year >= 2015, year <= 2024) %>%
    summarise(
      mean_consumption_kt = mean(C_year_tonnes, na.rm = TRUE) / 1000,
      mean_N = mean(N_indiv, na.rm = TRUE),
      readiness = first(model_readiness),
      .groups = "drop"
    )
} else {
  tibble(mean_consumption_kt = NA_real_, mean_N = NA_real_, readiness = "not_generated")
}

exposure_top_lines <- if (nrow(exposure_recent) > 0) {
  exposure_recent %>%
    filter(predator_species_or_source %in% c("Harbour seal", "Steller sea lion filled total")) %>%
    group_by(predator_species_or_source) %>%
    arrange(exposure_rank, .by_group = TRUE) %>%
    slice_head(n = 3) %>%
    summarise(
      line = paste0("- ", first(predator_species_or_source), ": ", paste(section_name, collapse = ", ")),
      .groups = "drop"
    ) %>%
    pull(line)
} else {
  "- Exposure top sections unavailable; rerun `Code/07bb_predator_spatial_exposure_prototype.R`."
}

best_exposure_line <- if (nrow(best_exposure) > 0) {
  paste0(
    "- Best current section-exposure row is `",
    best_exposure$label,
    "`: n `",
    best_exposure$n,
    "`, rho `",
    fmt(best_exposure$spearman_rho, 0.01),
    "`, detrended r `",
    fmt(best_exposure$detrended_r, 0.01),
    "`, gate `",
    best_exposure$gate,
    "`."
  )
} else {
  "- No section-exposure row is available in the current bridge gate; rerun the exposure and bridge scripts."
}

salmon_line <- if (nrow(salmon_row) > 0) {
  paste0(
    "- Salmon demand is `",
    salmon_row$gate,
    "` in the bridge, but it is recruitment/juvenile context rather than adult SSB mortality."
  )
} else {
  "- Salmon demand bridge gate is unavailable; rerun `Code/07bj_wcvi_predation_replication_bridge.R`."
}

gate_lines <- gate_summary %>%
  mutate(line = paste0("- ", class, " / ", gate, ": ", n_predictors)) %>%
  pull(line)

lines <- c(
  "# Predator Talk Brief",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## One-Slide Message",
  "",
  "Predation is quantitatively large and mechanistically plausible in Haida Gwaii, but the current integrated HG model does not support a promoted predator-effect coefficient. The defensible next step is better spatial exposure, especially humpbacks, not a bigger combined Stan model.",
  "",
  "## Talk-Safe Claims",
  "",
  paste0(
    "- 2015-2024 mean total predator consumption is `",
    fmt(recent_scale$mean_predator_consumption_kt, 0.01),
    "` kt/yr against `m1_stier_11` mean biomass of `",
    fmt(recent_scale$mean_biomass_kt, 0.01),
    "` kt."
  ),
  paste0(
    "- Median predator-removal analogue against `m1_stier_11` biomass is `",
    percent(recent_scale$median_predator_removal_rate, accuracy = 0.1),
    "`; pressure ratio against observed spawn is `",
    percent(recent_scale$mean_pressure_pct / 100, accuracy = 1),
    "`."
  ),
  best_exposure_line,
  paste0(
    "- Humpback section exposure is still `",
    humpback_recent$readiness,
    "`; current HG-wide humpback proxy averages `",
    fmt(humpback_recent$mean_consumption_kt, 0.01),
    "` kt/yr and `",
    fmt(humpback_recent$mean_N, 1),
    "` feeding-substantive individuals over 2015-2024."
  ),
  salmon_line,
  "",
  "## Source Diagnostics",
  "",
  "- Predator-demand bridge: `Output/diagnostics/wcvi_predation_replication_bridge_timeseries.csv` and `Output/diagnostics/wcvi_predator_demand_residual_screen.csv`.",
  "- Seal/sea-lion section exposure: `Output/diagnostics/predator_spatial_exposure_recent_by_section.csv`.",
  "- Humpback scaffold: `Output/diagnostics/humpback_section_exposure_proxy.csv`.",
  "- Salmon context: `Output/diagnostics/salmon_recruitment_context_screen.csv`.",
  "",
  "## What Not To Claim",
  "",
  "- Do not claim a promoted predator coefficient.",
  "- Do not call the humpback scaffold section-level exposure.",
  "- Do not treat salmon demand as adult biomass mortality.",
  "- Do not treat DFO 2025 age-2 recruitment rows as independent juvenile-survey validation; they are SCA model-output context.",
  "- Do not revive `m5_combined` or launch `m6_stier_predator_exposure_mammals` from the current gates.",
  "",
  "## Gate Summary",
  "",
  gate_lines,
  "",
  "## Spatial Exposure Talking Points",
  "",
  exposure_top_lines,
  "",
  "## Slide Assets",
  "",
  "- `Output/figures/wcvi_predation_replication_bridge.pdf`: predator-demand/removal bridge and gate plot.",
  "- `Output/figures/predator_spatial_exposure_prototype.pdf`: section exposure product figure.",
  "- `Output/figures/humpback_section_exposure_proxy.pdf`: HG-wide humpback scaffold figure.",
  "- `Output/figures/salmon_recruitment_context_screen.pdf`: salmon context figure.",
  "",
  "## Post-Talk Action Gate",
  "",
  "Rerun `m6_stier_predator_exposure_mammals` only after a refreshed section-year exposure row has expected negative sign, survives detrending and section controls, beats the future-lag negative control, and clears a local Stan smoke."
)

writeLines(lines, file.path(diag_dir, "predator_talk_brief.md"))

claim_table <- tibble(
  claim = c(
    "predator_scale_large",
    "predator_effect_not_promoted",
    "humpback_section_exposure_missing",
    "salmon_is_recruitment_context",
    "sca_recruitment_is_context",
    "post_talk_gate_before_stan"
  ),
  talk_safe_text = c(
    "HG predator demand is large relative to recent herring biomass/spawn.",
    "Current predator branches and exposure screens do not promote a predator coefficient.",
    "Humpback demand exists at HG-wide scale, but section exposure still needs spatial sightings/density.",
    "Salmon demand should be framed as juvenile/recruitment context, not adult SSB mortality.",
    "Public DFO age-2 recruitment rows are SCA model output, not independent validation data.",
    "Only build an exposure Stan branch after a section-year exposure row clears residual-screen and smoke gates."
  )
)

write_csv(claim_table, file.path(diag_dir, "predator_talk_claims.csv"))

cat("Saved predator talk brief:\n")
cat("  Output/diagnostics/predator_talk_brief.md\n")
cat("  Output/diagnostics/predator_talk_claims.csv\n")
