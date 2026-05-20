# ============================================================================
# 07m_m1_stier_11_section_scorecard.R
# Integrated section scorecard for m1_stier_11 interpretation.
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

pressure <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_pressure_screen.csv"),
  show_col_types = FALSE
)

recovery <- read_csv(
  file.path(diag_dir, "m1_stier_11_postclosure_recovery_by_section.csv"),
  show_col_types = FALSE
)

collapse <- read_csv(
  file.path(diag_dir, "m1_stier_11_recent_cryptic_collapse_status.csv"),
  show_col_types = FALSE
)

fit_quality <- read_csv(
  file.path(diag_dir, "m1_stier_11_spawn_fit_by_section.csv"),
  show_col_types = FALSE
) %>%
  rename(spawn_fit_rmse = rmse, spawn_fit_bias = bias, spawn_fit_coverage_90 = coverage_90)

survey <- read_csv(
  file.path(diag_dir, "survey_status_by_section.csv"),
  show_col_types = FALSE
)

spatial_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
)

recent_share <- spatial_year %>%
  filter(period == "2017-2025 recent closure") %>%
  group_by(site, site_name) %>%
  summarise(recent_median_biomass = median(median, na.rm = TRUE), .groups = "drop") %>%
  mutate(recent_biomass_share = recent_median_biomass / sum(recent_median_biomass, na.rm = TRUE))

scorecard <- pressure %>%
  select(
    site,
    site_name,
    focal_status,
    early_biomass,
    recent_biomass,
    recent_to_early_ratio,
    observed_catch_1951_2004,
    mean_fishing_fraction_1951_2004,
    n_catch_years
  ) %>%
  left_join(
    recovery %>%
      select(site, closure_pct_per_year, recent_pct_per_year, rebound_from_postclosure_min, recovery_class),
    by = "site"
  ) %>%
  left_join(
    collapse %>%
      select(site, recent_years_below_20pct, recent_years_below_10pct),
    by = "site"
  ) %>%
  left_join(
    fit_quality %>%
      select(site, spawn_fit_rmse, spawn_fit_bias, spawn_fit_coverage_90),
    by = "site"
  ) %>%
  left_join(
    survey %>%
      select(site, surveyed_years, zero_record_years, missing_years, survey_coverage),
    by = "site"
  ) %>%
  left_join(
    recent_share %>%
      select(site, recent_biomass_share),
    by = "site"
  ) %>%
  mutate(
    status = case_when(
      recent_years_below_20pct >= 6 ~ "persistently depleted",
      recovery_class == "clear rebound" & recent_to_early_ratio >= 1 ~ "rebounded above early",
      recovery_class == "clear rebound" ~ "rebounding but below early",
      recovery_class == "flat/declining" ~ "flat or declining",
      TRUE ~ "intermediate"
    ),
    status = factor(
      status,
      levels = c(
        "persistently depleted",
        "flat or declining",
        "rebounding but below early",
        "intermediate",
        "rebounded above early"
      )
    )
  ) %>%
  arrange(status, recent_to_early_ratio)

status_summary <- scorecard %>%
  count(status, name = "n_sections") %>%
  arrange(status)

p_recovery <- scorecard %>%
  mutate(site_name = fct_reorder(site_name, recent_to_early_ratio)) %>%
  ggplot(aes(x = recent_to_early_ratio, y = site_name, fill = status)) +
  geom_vline(xintercept = 0.2, linetype = "dashed", colour = "grey45") +
  geom_vline(xintercept = 1.0, linetype = "dashed", colour = "grey65") +
  geom_col(alpha = 0.9) +
  scale_x_log10(labels = label_number(accuracy = 0.1)) +
  scale_fill_manual(values = c(
    "persistently depleted" = "#8B1A1A",
    "flat or declining" = "#D55E00",
    "rebounding but below early" = "#F0E442",
    "intermediate" = "grey55",
    "rebounded above early" = "#2166AC"
  )) +
  labs(
    x = "Recent / early biomass",
    y = NULL,
    fill = NULL,
    title = "Section status scorecard"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_pressure <- ggplot(
  scorecard,
  aes(x = observed_catch_1951_2004, y = recent_to_early_ratio, colour = status)
) +
  geom_hline(yintercept = 0.2, linetype = "dashed", colour = "grey45") +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey65") +
  geom_point(aes(size = recent_biomass_share), alpha = 0.9) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_number(accuracy = 0.1)) +
  scale_colour_manual(values = c(
    "persistently depleted" = "#8B1A1A",
    "flat or declining" = "#D55E00",
    "rebounding but below early" = "#F0E442",
    "intermediate" = "grey55",
    "rebounded above early" = "#2166AC"
  )) +
  scale_size_continuous(labels = percent, range = c(2, 8)) +
  labs(
    x = "Observed catch, 1951-2004",
    y = "Recent / early biomass",
    colour = NULL,
    size = "Recent share",
    title = "Historical catch vs recent section status"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_quality <- scorecard %>%
  mutate(site_name = fct_reorder(site_name, spawn_fit_rmse)) %>%
  ggplot(aes(x = spawn_fit_rmse, y = site_name, fill = survey_coverage)) +
  geom_col(alpha = 0.9) +
  scale_fill_gradient(low = "#F7F7F7", high = "#2166AC", labels = percent) +
  labs(
    x = "Positive-spawn fit RMSE",
    y = NULL,
    fill = "Survey\ncoverage",
    title = "Fit quality and data coverage"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_recovery | (p_pressure / p_quality)

ggsave(
  file.path(fig_dir, "m1_stier_11_section_scorecard.pdf"),
  p,
  width = 270,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_section_scorecard.png"),
  p,
  width = 270,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(scorecard, file.path(diag_dir, "m1_stier_11_section_scorecard.csv"))
write_csv(status_summary, file.path(diag_dir, "m1_stier_11_section_scorecard_status_summary.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier 11 Section Scorecard",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Status Counts",
  "",
  paste0("- ", status_summary$status, ": ", status_summary$n_sections, " sections"),
  "",
  "## Section Scorecard",
  "",
  paste0(
    "- ",
    scorecard$site_name,
    ": status = ",
    scorecard$status,
    ", recent/early = ",
    fmt(scorecard$recent_to_early_ratio, 2),
    ", post-closure trend = ",
    fmt(scorecard$closure_pct_per_year, 1),
    "%/yr, catch 1951-2004 = ",
    fmt(scorecard$observed_catch_1951_2004, 0),
    ", survey coverage = ",
    percent(scorecard$survey_coverage, accuracy = 1)
  ),
  "",
  "## Interpretation",
  "",
  "- This scorecard is the current compact section-level synthesis for talk planning.",
  "- Persistent depletion, post-closure trend, historical catch, and survey coverage do not collapse to one axis.",
  "- The scorecard reinforces the need for section-specific productivity before regional predator attribution.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_section_scorecard.pdf`",
  "- `Output/diagnostics/m1_stier_11_section_scorecard.csv`",
  "- `Output/diagnostics/m1_stier_11_section_scorecard_status_summary.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_section_scorecard.md"))

cat("Saved section scorecard:\n")
cat("  Output/diagnostics/m1_stier_11_section_scorecard.md\n")
cat("  Output/figures/m1_stier_11_section_scorecard.pdf\n")
