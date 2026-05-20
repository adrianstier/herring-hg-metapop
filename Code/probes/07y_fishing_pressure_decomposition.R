# ============================================================================
# 07y_fishing_pressure_decomposition.R
# Decompose historical fishing pressure and section outcomes for m1_stier_11.
# ============================================================================

library(tidyverse)
library(here)
library(scales)
library(patchwork)

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

scorecard <- read_diag("m1_stier_11_section_scorecard.csv")
pressure_corr <- read_diag("m1_stier_11_section_pressure_correlations.csv")
section_year_pressure <- read_diag("m1_stier_11_section_year_fishing_pressure.csv")

section_pressure <- scorecard %>%
  mutate(
    log_recent_to_early = log(recent_to_early_ratio),
    catch_share = observed_catch_1951_2004 / sum(observed_catch_1951_2004, na.rm = TRUE),
    depletion_index = -log_recent_to_early,
    catch_per_early_biomass = observed_catch_1951_2004 / pmax(early_biomass, 1e-6),
    status = fct_relevel(
      status,
      "persistently depleted",
      "flat or declining",
      "rebounding but below early",
      "intermediate",
      "rebounded above early"
    )
  )

fishing_lm <- lm(log_recent_to_early ~ mean_fishing_fraction_1951_2004, data = section_pressure)
early_lm <- lm(log_recent_to_early ~ mean_fishing_fraction_1951_2004 + log(early_biomass), data = section_pressure)

section_pressure <- section_pressure %>%
  mutate(
    fishing_only_expected = predict(fishing_lm, newdata = section_pressure),
    fishing_only_resid = log_recent_to_early - fishing_only_expected,
    pressure_size_expected = predict(early_lm, newdata = section_pressure),
    pressure_size_resid = log_recent_to_early - pressure_size_expected
  ) %>%
  arrange(recent_to_early_ratio)

period_pressure <- section_year_pressure %>%
  group_by(period) %>%
  summarise(
    removed_median = sum(removed_median, na.rm = TRUE),
    mean_fishing_fraction = mean(fishing_fraction_median, na.rm = TRUE),
    max_section_fishing_fraction = max(fishing_fraction_median, na.rm = TRUE),
    .groups = "drop"
  )

pressure_summary <- tibble(
  metric = c(
    "rho_recent_early_vs_mean_fishing_fraction",
    "rho_recent_early_vs_observed_catch",
    "lm_slope_mean_fishing_fraction",
    "lm_p_mean_fishing_fraction",
    "lm_adj_r2_mean_fishing_fraction",
    "lm_adj_r2_plus_log_early_biomass",
    "top_3_catch_share",
    "n_persistently_depleted"
  ),
  value = c(
    pressure_corr %>%
      filter(predictor == "mean_fishing_fraction_1951_2004") %>%
      pull(spearman_rho) %>%
      first(),
    pressure_corr %>%
      filter(predictor == "observed_catch_1951_2004") %>%
      pull(spearman_rho) %>%
      first(),
    coef(summary(fishing_lm))["mean_fishing_fraction_1951_2004", "Estimate"],
    coef(summary(fishing_lm))["mean_fishing_fraction_1951_2004", "Pr(>|t|)"],
    summary(fishing_lm)$adj.r.squared,
    summary(early_lm)$adj.r.squared,
    section_pressure %>%
      arrange(desc(observed_catch_1951_2004)) %>%
      slice_head(n = 3) %>%
      summarise(value = sum(catch_share)) %>%
      pull(value),
    sum(section_pressure$status == "persistently depleted")
  )
)

write_csv(section_pressure, file.path(diag_dir, "fishing_pressure_decomposition_by_section.csv"))
write_csv(period_pressure, file.path(diag_dir, "fishing_pressure_decomposition_by_period.csv"))
write_csv(pressure_summary, file.path(diag_dir, "fishing_pressure_decomposition_summary.csv"))

top_catch <- section_pressure %>%
  arrange(desc(catch_share)) %>%
  slice_head(n = 5) %>%
  mutate(site_name = fct_reorder(site_name, catch_share))

p_scatter <- ggplot(
  section_pressure,
  aes(x = mean_fishing_fraction_1951_2004, y = recent_to_early_ratio, colour = status)
) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey55") +
  geom_hline(yintercept = 0.2, linetype = "dotted", colour = "firebrick") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey35", linewidth = 0.6) +
  geom_point(aes(size = observed_catch_1951_2004), alpha = 0.85) +
  geom_text(
    aes(label = site_name),
    check_overlap = TRUE,
    nudge_y = 0.04,
    size = 2.5,
    show.legend = FALSE
  ) +
  scale_y_log10(labels = label_number(accuracy = 0.01)) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_size_continuous(labels = label_comma(), range = c(2, 7)) +
  labs(
    x = "Mean fishing fraction, 1951-2004",
    y = "Recent / early biomass ratio",
    colour = NULL,
    size = "Observed catch",
    title = "Historical fishing pressure and current section status",
    subtitle = "Higher historical fishing pressure is associated with lower recent/early biomass, but not deterministically."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_catch <- ggplot(top_catch, aes(x = catch_share, y = site_name, fill = status)) +
  geom_col(width = 0.7) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Share of observed catch, 1951-2004",
    y = NULL,
    fill = NULL,
    title = "Catch was concentrated in a few sections"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

p_resid <- ggplot(
  section_pressure,
  aes(x = fishing_only_resid, y = fct_reorder(site_name, fishing_only_resid), colour = status)
) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(size = 2.5) +
  labs(
    x = "Outcome residual after mean fishing pressure",
    y = NULL,
    colour = NULL,
    title = "Sections worse or better than fishing alone predicts",
    subtitle = "Negative residuals are more depleted than expected from mean fishing fraction alone."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

p <- p_scatter / (p_catch | p_resid) +
  plot_layout(heights = c(1.2, 1)) +
  plot_annotation(
    title = "Fishing-pressure decomposition",
    subtitle = "Fishing pressure is a strong descriptive axis, but section outcomes still require spatial/ecological context."
  )

ggsave(
  file.path(fig_dir, "fishing_pressure_decomposition.pdf"),
  p,
  width = 220, height = 185, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "fishing_pressure_decomposition.png"),
  p,
  width = 220, height = 185, units = "mm", dpi = 300
)

top_catch_labels <- section_pressure %>%
  arrange(desc(catch_share)) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " ", percent(catch_share, accuracy = 1))) %>%
  pull(label)

worse_than_fishing <- section_pressure %>%
  arrange(fishing_only_resid) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " residual=", number(fishing_only_resid, accuracy = 0.01))) %>%
  pull(label)

better_than_fishing <- section_pressure %>%
  arrange(desc(fishing_only_resid)) %>%
  slice_head(n = 3) %>%
  transmute(label = paste0(site_name, " residual=", number(fishing_only_resid, accuracy = 0.01))) %>%
  pull(label)

md_lines <- c(
  "# Fishing-Pressure Decomposition",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Recent/early biomass versus mean fishing fraction Spearman rho: `",
    number(pressure_summary$value[pressure_summary$metric == "rho_recent_early_vs_mean_fishing_fraction"], accuracy = 0.01),
    "`."
  ),
  paste0(
    "- Recent/early biomass versus observed catch Spearman rho: `",
    number(pressure_summary$value[pressure_summary$metric == "rho_recent_early_vs_observed_catch"], accuracy = 0.01),
    "`."
  ),
  paste0(
    "- A simple mean-fishing-fraction regression has adjusted R2 `",
    number(pressure_summary$value[pressure_summary$metric == "lm_adj_r2_mean_fishing_fraction"], accuracy = 0.01),
    "`; adding early biomass gives adjusted R2 `",
    number(pressure_summary$value[pressure_summary$metric == "lm_adj_r2_plus_log_early_biomass"], accuracy = 0.01),
    "`."
  ),
  paste0("- Top catch-share sections: ", paste(top_catch_labels, collapse = "; "), "."),
  "",
  "## Interpretation",
  "",
  "- Historical fishing pressure is a strong descriptive axis for current section status.",
  "- It is not deterministic: several sections are worse or better than expected from mean fishing fraction alone.",
  "- This supports using fishing as a central context/driver in the talk, while still retaining spatial and survey-coverage caveats.",
  "",
  "## Residuals After Mean Fishing Fraction",
  "",
  paste0("- More depleted than fishing alone predicts: ", paste(worse_than_fishing, collapse = "; "), "."),
  paste0("- Less depleted than fishing alone predicts: ", paste(better_than_fishing, collapse = "; "), "."),
  "",
  "## Files",
  "",
  "- `Output/figures/fishing_pressure_decomposition.pdf`",
  "- `Output/diagnostics/fishing_pressure_decomposition_by_section.csv`",
  "- `Output/diagnostics/fishing_pressure_decomposition_summary.csv`"
)

writeLines(md_lines, file.path(diag_dir, "fishing_pressure_decomposition.md"))

cat("Saved fishing-pressure decomposition outputs:\n")
cat("  Output/figures/fishing_pressure_decomposition.pdf\n")
cat("  Output/diagnostics/fishing_pressure_decomposition.md\n")
