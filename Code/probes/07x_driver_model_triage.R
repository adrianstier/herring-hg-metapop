# ============================================================================
# 07x_driver_model_triage.R
# Rank candidate population drivers and model extensions using the May 9 outputs.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(filename) {
  path <- file.path(diag_dir, filename)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

driver_corr <- read_diag("m1_stier_11_driver_correlations.csv")
driver_time <- read_diag("m1_stier_11_driver_time_confounding.csv")
pressure_tbl <- read_diag("m1_stier_11_section_pressure_correlations.csv")
scale_global <- read_diag("spawn_index_scale_global_summary.csv") %>% slice(1)
scale_section <- read_diag("spawn_index_scale_by_section.csv")
legacy_scale <- read_diag("legacy_shi_overlap_scale_agreement.csv")
timing_corr <- read_diag("spawn_timing_substrate_correlations.csv") %>% slice(1)
density_total <- read_diag("density_dependence_total_summary.csv") %>% slice(1)
density_pooled <- read_diag("density_dependence_pooled_section_summary.csv") %>% slice(1)
m3_context <- read_diag("m3_stier_distance_comparison_context.csv") %>%
  filter(model == "m3_stier_distance") %>%
  slice(1)
m3_global <- read_diag("m3_stier_distance_global_parameters.csv")
m3_reloo_path <- file.path(diag_dir, "m3_stier_distance_triage_reloo.csv")
m3_reloo <- if (file.exists(m3_reloo_path)) {
  read_csv(m3_reloo_path, show_col_types = FALSE)
} else {
  tibble()
}

get_growth_rho <- function(predictor) {
  driver_corr %>%
    filter(response == "growth_median", .data$predictor == !!predictor) %>%
    pull(spearman_rho) %>%
    first()
}

get_time_rho <- function(driver) {
  driver_time %>%
    filter(.data$driver == !!driver) %>%
    pull(rho_year) %>%
    first()
}

get_pressure_rho <- function(metric) {
  pressure_tbl %>%
    filter(.data$predictor == !!metric) %>%
    pull(spearman_rho) %>%
    first()
}

fmt_rho <- function(x) {
  number(x, accuracy = 0.01)
}

fmt_num <- function(x, accuracy = 0.1) {
  number(x, accuracy = accuracy, big.mark = ",")
}

scale_section_range <- range(scale_section$median_ratio, na.rm = TRUE)
legacy_annual_cor <- legacy_scale %>%
  filter(metric == "annual_total_log_correlation") %>%
  pull(value) %>%
  first()
m3_range <- m3_global %>%
  filter(parameter == "practical_range_km") %>%
  pull(median) %>%
  first()
m3_reloo_completed <- nrow(m3_reloo) > 0 &&
  max(m3_reloo$n_exact_refit_completed, na.rm = TRUE) >=
    max(m3_reloo$n_high_pareto_total, na.rm = TRUE)
m3_reloo_looic <- if (m3_reloo_completed) {
  first(m3_reloo$looic_total_exact_corrected)
} else {
  NA_real_
}
m3_reloo_treedepth_hits <- if (nrow(m3_reloo) > 0) {
  sum(m3_reloo$treedepth_hits, na.rm = TRUE)
} else {
  NA_real_
}
m3_model_readiness <- if (m3_reloo_completed) {
  "hold after exact re-LOO"
} else {
  "hold until re-LOO diagnostics available"
}
m3_headline <- if (m3_reloo_completed) {
  paste0(
    "m3 distance practical range about ", fmt_num(m3_range),
    " km; positive-spawn RMSE ", fmt_num(m3_context$positive_signal_log_rmse, 0.001),
    "; exact re-LOO corrected LOOIC ", fmt_num(m3_reloo_looic, 0.01),
    "; exact-refit treedepth hits ", fmt_num(m3_reloo_treedepth_hits, 1), "."
  )
} else {
  paste0(
    "m3 distance practical range about ", fmt_num(m3_range),
    " km; positive-spawn RMSE ", fmt_num(m3_context$positive_signal_log_rmse, 0.001),
    "; max Pareto k ", fmt_num(m3_context$max_pareto_k, 0.001), "."
  )
}
m3_decision <- if (m3_reloo_completed) {
  "Plausible and interpretable spatial process context, but the fit gain is small and exact refits showed treedepth pressure."
} else {
  "Plausible and interpretable, but current fit gain is small and exact re-LOO diagnostics are not available."
}
m3_next_action <- if (m3_reloo_completed) {
  "Use as spatial-process context, not promoted inference; revisit only if a new process branch improves calibration materially."
} else {
  "Regenerate exact re-LOO diagnostics before treating this as model evidence."
}

triage_tbl <- tribble(
  ~mechanism, ~evidence_strength, ~confounding_risk, ~model_readiness, ~headline_evidence, ~decision, ~next_action,
  "Observation scale / survey method", "high", "moderate", "ready for sensitivity, not promoted branch",
  paste0(
    "Legacy SHI / DFO tonnes median ratio ",
    fmt_num(scale_global$median_ratio),
    "; section medians ",
    fmt_num(scale_section_range[1]), "-",
    fmt_num(scale_section_range[2]),
    "; legacy-vs-DFO annual r=", fmt_rho(legacy_annual_cor), "."
  ),
  "Keep m1_stier_11; report scale caveat; avoid copying legacy q values.",
  "If time allows, build a legacy-SHI posterior sensitivity through 2015 rather than a global multiplier.",

  "Historical fishing pressure", "high", "moderate", "report now",
  paste0(
    "Recent/early biomass vs mean fishing fraction rho=",
    fmt_rho(get_pressure_rho("mean_fishing_fraction_1951_2004")),
    "; vs observed catch rho=",
    fmt_rho(get_pressure_rho("observed_catch_1951_2004")),
    "."
  ),
  "Use as a central descriptive driver; do not overclaim causality with 11 sections.",
  "Make a talk figure that links section scorecard, historical catch, and recent depletion.",

  "PDO / regional climate", "moderate", "low", "baseline climate context",
  paste0(
    "Growth vs PDO lag-1 rho=", fmt_rho(get_growth_rho("pdo_lag1")),
    "; PDO vs year rho=", fmt_rho(get_time_rho("pdo")), "."
  ),
  "Already included in m1_stier_11; useful because it is not just a time trend, but the Stan coefficient remains uncertain.",
  "Do not launch a redundant PDO-only branch; if needed, test PDO window/lag sensitivity on the existing baseline structure.",

  "Predators", "ecologically plausible but statistically weak", "very high", "hold",
  paste0(
    "Growth vs combined predator lag-1 rho=", fmt_rho(get_growth_rho("pred_combined_lag1")),
    "; combined predators vs year rho=", fmt_rho(get_time_rho("pred_combined")), "."
  ),
  "Do not promote a predator effect from the current regional indices.",
  "Use predator results as hypothesis/context; improve spatial or age-specific predator data before Stan modeling.",

  "Spawn timing / substrate", "moderate observation context", "high", "hold as covariate",
  paste0(
    "Growth vs subtidal share lag-1 rho=", fmt_rho(get_growth_rho("subtidal_share_lag1")),
    "; section recovery vs timing change rho=", fmt_rho(timing_corr$rho_delta_spawn_start),
    "; vs subtidal change rho=", fmt_rho(timing_corr$rho_delta_subtidal), "."
  ),
  "Important for interpreting the survey record; not a strong standalone population driver yet.",
  "Use as observation/context material in the talk; defer mechanistic modeling.",

  "Spatially correlated process shocks", "moderate", "low to moderate", m3_model_readiness,
  m3_headline,
  m3_decision,
  m3_next_action,

  "Density dependence", "weak", "low", "hold complex DD",
  paste0(
    "Archipelago rho=", fmt_rho(density_total$spearman_rho),
    "; pooled section rho=", fmt_rho(density_pooled$spearman_rho), "."
  ),
  "No strong global negative density-dependence signal in posterior medians.",
  "If tested, start with one global Gompertz term only; do not add section-specific DD now."
)

score_levels <- c(
  "high" = 3,
  "moderate" = 2,
  "moderate observation context" = 2,
  "ecologically plausible but statistically weak" = 1,
  "weak" = 1
)

triage_tbl <- triage_tbl %>%
  mutate(
    evidence_score = unname(score_levels[evidence_strength]),
    promoted_for_monday = case_when(
      mechanism %in% c("Observation scale / survey method", "Historical fishing pressure", "PDO / regional climate") ~ "yes/context",
      mechanism %in% c("Spatially correlated process shocks") & !m3_reloo_completed ~ "maybe after re-LOO refresh",
      mechanism %in% c("Spatially correlated process shocks") ~ "context only",
      TRUE ~ "context only"
    )
  )

write_csv(triage_tbl, file.path(diag_dir, "driver_model_triage.csv"))

md_lines <- c(
  "# Driver And Model Triage",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This table ranks candidate drivers and model extensions using the current `m1_stier_11` diagnostics.",
  "",
  knitr::kable(
    triage_tbl %>%
      select(
        mechanism, evidence_strength, confounding_risk, model_readiness,
        promoted_for_monday, headline_evidence, decision, next_action
      ),
    format = "pipe"
  )
)

writeLines(md_lines, file.path(diag_dir, "driver_model_triage.md"))

plot_tbl <- triage_tbl %>%
  mutate(
    mechanism = fct_reorder(mechanism, evidence_score),
    readiness_label = case_when(
      str_detect(model_readiness, "report") ~ "Report now",
      str_detect(model_readiness, "candidate|baseline") ~ "Candidate",
      str_detect(model_readiness, "after exact") ~ "Hold",
      str_detect(model_readiness, "exact") ~ "Pending",
      TRUE ~ "Hold"
    ),
    readiness_label = factor(readiness_label, levels = c("Report now", "Candidate", "Pending", "Hold"))
  )

p <- ggplot(plot_tbl, aes(x = evidence_score, y = mechanism, colour = readiness_label)) +
  geom_segment(aes(x = 0, xend = evidence_score, yend = mechanism), linewidth = 0.7, alpha = 0.45) +
  geom_point(size = 3) +
  scale_x_continuous(
    breaks = c(1, 2, 3),
    labels = c("weak", "moderate", "high"),
    limits = c(0, 3.2)
  ) +
  scale_colour_manual(
    values = c(
      "Report now" = "#009E73",
      "Candidate" = "#0072B2",
      "Pending" = "#E69F00",
      "Hold" = "#999999"
    )
  ) +
  labs(
    x = "Current evidence strength",
    y = NULL,
    colour = NULL,
    title = "Driver and model-extension triage",
    subtitle = "Ranking reflects current evidence, confounding, and whether the branch is ready for Monday's narrative."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave(
  file.path(fig_dir, "driver_model_triage.pdf"),
  p,
  width = 190, height = 115, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "driver_model_triage.png"),
  p,
  width = 190, height = 115, units = "mm", dpi = 300
)

cat("Saved driver/model triage outputs:\n")
cat("  Output/diagnostics/driver_model_triage.csv\n")
cat("  Output/diagnostics/driver_model_triage.md\n")
cat("  Output/figures/driver_model_triage.pdf\n")
