# ============================================================================
# 07f_m2_stier_site_growth_postfit.R
# Interpret the m2_stier_site_growth branch after it finishes.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

fit_path <- file.path(data_dir, "m2_stier_site_growth_fit.rds")
if (!file.exists(fit_path)) {
  stop("m2_stier_site_growth_fit.rds not found. Run Code/03_fit_m2_stier_site_growth.R first.")
}

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(fit_path)
post <- rstan::extract(fit, pars = c("U", "U_mu", "sigma_U", "pdocoef", "sigma_proc", "sigma_obs", "log_q"))

site_names <- jags_data$site_names

summarise_draws <- function(x) {
  tibble(
    mean = mean(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE),
    p_gt_0 = mean(x > 0, na.rm = TRUE)
  )
}

ensure_columns <- function(tbl, numeric_cols = character(), character_cols = character()) {
  for (col in numeric_cols) {
    if (!col %in% names(tbl)) {
      tbl[[col]] <- NA_real_
    }
  }
  for (col in character_cols) {
    if (!col %in% names(tbl)) {
      tbl[[col]] <- NA_character_
    }
  }
  tbl
}

u_summary <- map_dfr(seq_along(site_names), function(j) {
  summarise_draws(post$U[, j]) %>%
    mutate(site = j, site_name = site_names[j], .before = 1)
}) %>%
  arrange(median)

global_summary <- bind_rows(
  summarise_draws(post$U_mu) %>% mutate(parameter = "U_mu"),
  summarise_draws(post$sigma_U) %>% mutate(parameter = "sigma_U"),
  summarise_draws(post$pdocoef) %>% mutate(parameter = "pdocoef"),
  summarise_draws(post$sigma_proc) %>% mutate(parameter = "sigma_proc"),
  summarise_draws(post$sigma_obs) %>% mutate(parameter = "sigma_obs"),
  map_dfr(seq_len(ncol(post$log_q)), function(i) {
    summarise_draws(post$log_q[, i]) %>%
      mutate(parameter = paste0("log_q[", i, "]"))
  })
) %>%
  select(parameter, everything())

section_screen_path <- file.path(diag_dir, "m1_stier_11_section_pressure_screen.csv")
section_screen <- if (file.exists(section_screen_path)) {
  read_csv(section_screen_path, show_col_types = FALSE)
} else {
  tibble(site = seq_along(site_names), site_name = site_names)
} %>%
  ensure_columns(
    numeric_cols = c(
      "recent_to_early_ratio",
      "observed_catch_1951_2004",
      "mean_fishing_fraction_1951_2004"
    )
  )

scorecard_path <- file.path(diag_dir, "m1_stier_11_section_scorecard.csv")
scorecard <- if (file.exists(scorecard_path)) {
  read_csv(scorecard_path, show_col_types = FALSE) %>%
    select(site, status, closure_pct_per_year, recovery_class, survey_coverage)
} else {
  tibble(site = seq_along(site_names))
} %>%
  ensure_columns(
    numeric_cols = c("closure_pct_per_year", "survey_coverage"),
    character_cols = c("status", "recovery_class")
  )

uncertainty_path <- file.path(diag_dir, "m1_stier_11_uncertainty_by_section.csv")
uncertainty <- if (file.exists(uncertainty_path)) {
  read_csv(uncertainty_path, show_col_types = FALSE) %>%
    select(site, recent_rel_width_90)
} else {
  tibble(site = seq_along(site_names))
} %>%
  ensure_columns(numeric_cols = "recent_rel_width_90")

u_joined <- u_summary %>%
  left_join(section_screen, by = c("site", "site_name")) %>%
  left_join(scorecard, by = "site") %>%
  left_join(uncertainty, by = "site")

u_cor <- u_joined %>%
  select(site_name, median, recent_to_early_ratio, observed_catch_1951_2004, mean_fishing_fraction_1951_2004) %>%
  pivot_longer(
    c(recent_to_early_ratio, observed_catch_1951_2004, mean_fishing_fraction_1951_2004),
    names_to = "predictor",
    values_to = "value"
  ) %>%
  group_by(predictor) %>%
  summarise(
    n = sum(is.finite(median) & is.finite(value)),
    spearman_rho = suppressWarnings(cor(median, value, method = "spearman", use = "complete.obs")),
    pearson_r = suppressWarnings(cor(median, value, method = "pearson", use = "complete.obs")),
    .groups = "drop"
  ) %>%
  arrange(desc(abs(spearman_rho)))

comparison_path <- file.path(diag_dir, "model_comparison.csv")
comparison_context <- if (file.exists(comparison_path)) {
  read_csv(comparison_path, show_col_types = FALSE) %>%
    filter(model %in% c("m1_stier_11", "m2_stier_site_growth")) %>%
    select(
      model,
      comparison_status,
      sampler_clean,
      loo_resolved,
      looic_decision,
      max_pareto_k,
      divergences,
      treedepth_hits,
      max_rhat,
      min_ebfmi,
      positive_signal_log_rmse,
      positive_signal_log_bias
    )
} else {
  tibble()
}

p_u <- u_summary %>%
  mutate(site_name = fct_reorder(site_name, median)) %>%
  ggplot(aes(x = median, y = site_name)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_errorbar(
    aes(xmin = lo90, xmax = hi90),
    orientation = "y",
    width = 0.18,
    colour = "grey40"
  ) +
  geom_point(aes(colour = p_gt_0), size = 2.2) +
  scale_colour_viridis_c(labels = percent, limits = c(0, 1)) +
  labs(
    x = "Section productivity U[j]",
    y = NULL,
    colour = "P(U[j] > 0)",
    title = "Estimated section-specific productivity",
    subtitle = "Positive values indicate higher latent productivity after accounting for PDO and catch."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_recovery <- u_joined %>%
  filter(is.finite(recent_to_early_ratio)) %>%
  ggplot(aes(x = median, y = recent_to_early_ratio)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey45") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_point(aes(size = observed_catch_1951_2004, colour = status), alpha = 0.86) +
  geom_text(aes(label = site_name), size = 2.5, check_overlap = TRUE, nudge_y = 0.05) +
  scale_y_log10(labels = label_number(accuracy = 0.01)) +
  scale_size_continuous(labels = label_comma(), range = c(2, 7)) +
  labs(
    x = "Section productivity U[j]",
    y = "Recent / early biomass",
    size = "Observed catch through 2004",
    colour = NULL,
    title = "Does productivity explain section recovery?"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_u / p_recovery +
  plot_annotation(
    title = "M2 Stier site-growth post-fit diagnostic",
    subtitle = "Use this to decide whether section heterogeneity should be promoted before richer process branches."
  )

ggsave(
  file.path(fig_dir, "m2_stier_site_growth_productivity_diagnostic.pdf"),
  p,
  width = 220,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m2_stier_site_growth_productivity_diagnostic.png"),
  p,
  width = 220,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(u_summary, file.path(diag_dir, "m2_stier_site_growth_u_by_section.csv"))
write_csv(u_joined, file.path(diag_dir, "m2_stier_site_growth_u_section_context.csv"))
write_csv(global_summary, file.path(diag_dir, "m2_stier_site_growth_global_parameters.csv"))
write_csv(u_cor, file.path(diag_dir, "m2_stier_site_growth_u_correlations.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M2 Stier Site-Growth Post-Fit Diagnostic",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Section Productivity Ranking",
  "",
  paste0(
    "- ",
    u_summary$site_name,
    ": median U = ",
    fmt(u_summary$median, 3),
    ", 90% interval ",
    fmt(u_summary$lo90, 3),
    " to ",
    fmt(u_summary$hi90, 3),
    ", P(U > 0) = ",
    percent(u_summary$p_gt_0, accuracy = 1)
  ),
  "",
  "## Scorecard Context",
  "",
  paste0(
    "- ",
    u_joined$site_name,
    ": status = ",
    if_else(is.na(u_joined$status), "unknown", u_joined$status),
    ", recent/early = ",
    fmt(u_joined$recent_to_early_ratio, 2),
    ", closure trend = ",
    fmt(u_joined$closure_pct_per_year, 1),
    "%/yr, recent uncertainty width/median = ",
    fmt(u_joined$recent_rel_width_90, 1)
  ),
  "",
  "## Cross-Section Associations",
  "",
  paste0(
    "- ",
    u_cor$predictor,
    ": Spearman rho with U = ",
    fmt(u_cor$spearman_rho, 2),
    " (n=",
    u_cor$n,
    ")"
  ),
  "",
  "## Model Comparison Context",
  "",
  if (nrow(comparison_context) > 0) {
    paste0(
      "- ",
      comparison_context$model,
      ": status = ",
      comparison_context$comparison_status,
      ", sampler clean = ",
      comparison_context$sampler_clean,
      ", LOO resolved = ",
      comparison_context$loo_resolved,
      ", LOOIC decision = ",
      fmt(comparison_context$looic_decision, 2),
      ", max Pareto k = ",
      fmt(comparison_context$max_pareto_k, 3),
      ", divergences = ",
      comparison_context$divergences,
      ", treedepth hits = ",
      comparison_context$treedepth_hits,
      ", positive RMSE = ",
      fmt(comparison_context$positive_signal_log_rmse, 2),
      ", positive bias = ",
      fmt(comparison_context$positive_signal_log_bias, 2)
    )
  } else {
    "- Model-comparison context not available. Run `Code/03c_bayesian_fit_audit.R`, `Code/03d_posterior_predictive_checks_v3.R`, `Code/04_compare_models_v3.R`, and `Code/04b_interpret_model_outputs.R` first."
  },
  "",
  "## Outputs",
  "",
  "- `Output/figures/m2_stier_site_growth_productivity_diagnostic.pdf`",
  "- `Output/diagnostics/m2_stier_site_growth_u_by_section.csv`",
  "- `Output/diagnostics/m2_stier_site_growth_u_section_context.csv`",
  "- `Output/diagnostics/m2_stier_site_growth_global_parameters.csv`",
  "- `Output/diagnostics/m2_stier_site_growth_u_correlations.csv`"
)

writeLines(lines, file.path(diag_dir, "m2_stier_site_growth_postfit.md"))

cat("Saved m2 site-growth post-fit diagnostics:\n")
cat("  Output/diagnostics/m2_stier_site_growth_postfit.md\n")
cat("  Output/figures/m2_stier_site_growth_productivity_diagnostic.pdf\n")
