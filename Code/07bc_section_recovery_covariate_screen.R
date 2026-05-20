# ============================================================================
# 07bc_section_recovery_covariate_screen.R
# Descriptive section-level screen for recovery covariates.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(filename) {
  read_csv(file.path(diag_dir, filename), show_col_types = FALSE)
}

section_action <- read_diag("section_action_matrix.csv") %>%
  select(
    site_name,
    focal_status,
    talk_use,
    evidence_score,
    recent_to_early_ratio,
    current_share,
    recent_rel_width_90,
    main_caveat
  ) %>%
  mutate(
    log_recent_to_early = log(recent_to_early_ratio)
  )

fishing <- read_diag("fishing_pressure_decomposition_by_section.csv") %>%
  select(
    site_name,
    mean_fishing_fraction_1951_2004,
    catch_per_early_biomass,
    fishing_only_resid,
    survey_coverage,
    spawn_fit_rmse,
    spawn_fit_coverage_90
  )

predator <- read_diag("predator_spatial_exposure_recent_by_section.csv") %>%
  mutate(
    predator_key = case_when(
      predator == "Harbour seal" ~ "harbour_seal",
      predator == "Steller sea lion" ~ "steller_sea_lion",
      TRUE ~ str_replace_all(str_to_lower(predator), "[^a-z0-9]+", "_")
    )
  ) %>%
  select(section_name, predator_key, recent_median_exposure_z, nearest_predator_site_km) %>%
  pivot_wider(
    names_from = predator_key,
    values_from = c(recent_median_exposure_z, nearest_predator_site_km),
    names_glue = "{predator_key}_{.value}"
  ) %>%
  rename(site_name = section_name)

timing <- read_diag("spawn_timing_substrate_section_change.csv") %>%
  transmute(
    site_name = section_name,
    delta_spawn_start_doy,
    delta_subtidal_share,
    delta_substrate_effective_n
  )

screen_df <- section_action %>%
  left_join(fishing, by = "site_name") %>%
  left_join(predator, by = "site_name") %>%
  left_join(timing, by = "site_name") %>%
  mutate(
    current_share_pct = 100 * current_share,
    mean_fishing_fraction_pct = 100 * mean_fishing_fraction_1951_2004,
    survey_coverage_pct = 100 * survey_coverage,
    spawn_fit_coverage_90_pct = 100 * spawn_fit_coverage_90
  )

covariate_defs <- tribble(
  ~covariate, ~label, ~family, ~interpretation,
  "mean_fishing_fraction_1951_2004", "Mean historical fishing fraction", "historical fishing", "higher fishing pressure should predict lower recovery if fishing legacy matters",
  "catch_per_early_biomass", "Catch per early biomass", "historical fishing", "higher cumulative catch relative to early biomass should predict lower recovery",
  "survey_coverage", "Survey coverage", "observation caveat", "coverage should be read as confidence/context, not a biological driver",
  "spawn_fit_rmse", "Positive-spawn fit RMSE", "observation caveat", "large fit error flags sections where magnitude inference is weaker",
  "harbour_seal_recent_median_exposure_z", "Recent harbour seal exposure", "predator exposure prototype", "prototype only; time and effort confounding remain",
  "steller_sea_lion_recent_median_exposure_z", "Recent Steller sea lion exposure", "predator exposure prototype", "prototype only; time and effort confounding remain",
  "harbour_seal_nearest_predator_site_km", "Nearest harbour seal site distance", "predator exposure prototype", "shorter distance may indicate higher local exposure",
  "steller_sea_lion_nearest_predator_site_km", "Nearest Steller sea lion site distance", "predator exposure prototype", "shorter distance may indicate higher local exposure",
  "delta_spawn_start_doy", "Recent minus early spawn timing", "phenology/substrate", "positive values mean later recent spawn timing",
  "delta_subtidal_share", "Recent minus early subtidal share", "phenology/substrate", "positive values mean more recent subtidal spawn",
  "delta_substrate_effective_n", "Recent minus early substrate diversity", "phenology/substrate", "positive values mean broader recent substrate use",
  "current_share", "2025 biomass share", "state descriptor", "concentration outcome, not an independent driver"
)

safe_cor <- function(x, y, method = "spearman") {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 4 || length(unique(x[ok])) < 2 || length(unique(y[ok])) < 2) {
    return(NA_real_)
  }
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

safe_slope <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 4 || length(unique(x[ok])) < 2) {
    return(NA_real_)
  }
  coef(lm(y[ok] ~ scale(x[ok])))[2]
}

cor_tbl <- covariate_defs %>%
  mutate(
    n = map_int(covariate, ~ sum(is.finite(screen_df[[.x]]) & is.finite(screen_df$log_recent_to_early))),
    spearman_rho = map_dbl(covariate, ~ safe_cor(screen_df[[.x]], screen_df$log_recent_to_early, "spearman")),
    pearson_r = map_dbl(covariate, ~ safe_cor(screen_df[[.x]], screen_df$log_recent_to_early, "pearson")),
    scaled_lm_slope = map_dbl(covariate, ~ safe_slope(screen_df[[.x]], screen_df$log_recent_to_early))
  ) %>%
  arrange(desc(abs(spearman_rho)))

top_covariates <- cor_tbl %>%
  filter(is.finite(spearman_rho), family != "state descriptor") %>%
  slice_max(abs(spearman_rho), n = 4, with_ties = FALSE)

section_screen <- screen_df %>%
  transmute(
    section = site_name,
    focal_status,
    talk_use,
    recent_to_early_ratio,
    log_recent_to_early,
    current_share,
    mean_fishing_fraction_1951_2004,
    catch_per_early_biomass,
    survey_coverage,
    spawn_fit_rmse,
    harbour_seal_exposure_z = harbour_seal_recent_median_exposure_z,
    steller_sea_lion_exposure_z = steller_sea_lion_recent_median_exposure_z,
    delta_spawn_start_doy,
    delta_subtidal_share,
    delta_substrate_effective_n,
    main_caveat
  )

write_csv(section_screen, file.path(diag_dir, "section_recovery_covariate_screen.csv"))
write_csv(cor_tbl, file.path(diag_dir, "section_recovery_covariate_correlations.csv"))

p_corr <- cor_tbl %>%
  filter(is.finite(spearman_rho), family != "state descriptor") %>%
  mutate(label = fct_reorder(label, spearman_rho)) %>%
  ggplot(aes(x = spearman_rho, y = label, fill = family)) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(width = 0.7) +
  scale_x_continuous(limits = c(-1, 1)) +
  labs(
    x = "Spearman rho with log(recent / early biomass)",
    y = NULL,
    fill = NULL,
    title = "Section-level recovery covariate screen",
    subtitle = "n = 11 sections; descriptive only, not causal identification."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

scatter_df <- top_covariates %>%
  select(covariate, label, family, spearman_rho) %>%
  left_join(
    screen_df %>%
      select(site_name, talk_use, log_recent_to_early, all_of(top_covariates$covariate)) %>%
      pivot_longer(
        cols = all_of(top_covariates$covariate),
        names_to = "covariate",
        values_to = "value"
      ),
    by = "covariate"
  )

p_scatter <- scatter_df %>%
  ggplot(aes(x = value, y = log_recent_to_early, colour = talk_use)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.3) +
  geom_point(size = 2.2, alpha = 0.9) +
  geom_smooth(method = "lm", se = FALSE, colour = "grey20", linewidth = 0.45) +
  facet_wrap(~ label, scales = "free_x", ncol = 2) +
  labs(
    x = NULL,
    y = "log(recent / early biomass)",
    colour = NULL,
    title = "Top descriptive covariate contrasts",
    subtitle = "Use as triage for local audits and future model design."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_corr / p_scatter +
  plot_layout(heights = c(1, 1.35)) +
  plot_annotation(
    title = "Section recovery and candidate covariates",
    subtitle = "Fishing history remains the clearest axis; predator exposure is a data-product target, not a fitted effect."
  )

ggsave(
  file.path(fig_dir, "section_recovery_covariate_screen.pdf"),
  p,
  width = 240, height = 220, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "section_recovery_covariate_screen.png"),
  p,
  width = 240, height = 220, units = "mm", dpi = 300
)

cor_md <- cor_tbl %>%
  transmute(
    family,
    covariate = label,
    n,
    `Spearman rho` = number(spearman_rho, accuracy = 0.01),
    `scaled LM slope` = number(scaled_lm_slope, accuracy = 0.01),
    interpretation
  )

section_md <- section_screen %>%
  transmute(
    section,
    `talk use` = talk_use,
    `recent/early` = number(recent_to_early_ratio, accuracy = 0.01),
    `fishing fraction` = percent(mean_fishing_fraction_1951_2004, accuracy = 0.1),
    `survey coverage` = percent(survey_coverage, accuracy = 1),
    `harbour exposure z` = number(harbour_seal_exposure_z, accuracy = 0.01),
    `SSL exposure z` = number(steller_sea_lion_exposure_z, accuracy = 0.01),
    caveat = main_caveat
  )

lines <- c(
  "# Section Recovery Covariate Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This is a descriptive n=11 section screen. It is meant to prioritize local audits and future model branches, not to identify causal effects.",
  "",
  "## Main Read",
  "",
  "- Historical fishing pressure remains the cleanest section-level recovery axis.",
  "- Predator exposure is now spatially prototype-able for harbour seals and Steller sea lions, but the section-growth correlations are weak and still time/effort confounded.",
  "- Survey coverage and positive-spawn fit RMSE should be treated as evidence-quality modifiers, not biological drivers.",
  "- Timing/substrate shifts are missing for several sections, so they are not ready for a section-level Stan covariate without more preprocessing.",
  "",
  "## Covariate Correlations",
  "",
  knitr::kable(cor_md, format = "pipe"),
  "",
  "## Section Screen",
  "",
  knitr::kable(section_md, format = "pipe"),
  "",
  "## Decision",
  "",
  "- Keep the next interpretation centered on section heterogeneity and historical fishing pressure.",
  "- Use predator exposure as a data-product branch, especially around Louscoone/Skincuttle/Juan Perez for Steller sea lions and Naden/Laskeek/Cumshewa for harbour seals.",
  "- Do not promote a predator, timing, or substrate coefficient until the covariate products are less missing/confounded and the observation layer remains calibrated.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/section_recovery_covariate_screen.pdf`",
  "- `Output/diagnostics/section_recovery_covariate_screen.csv`",
  "- `Output/diagnostics/section_recovery_covariate_correlations.csv`"
)

writeLines(lines, file.path(diag_dir, "section_recovery_covariate_screen.md"))

cat("Saved section recovery covariate screen:\n")
cat("  Output/diagnostics/section_recovery_covariate_screen.md\n")
cat("  Output/figures/section_recovery_covariate_screen.pdf\n")
