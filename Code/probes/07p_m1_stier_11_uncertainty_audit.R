# ============================================================================
# 07p_m1_stier_11_uncertainty_audit.R
# Posterior uncertainty audit for m1_stier_11 section conclusions.
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

section_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
)

scorecard <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_scorecard.csv"),
  show_col_types = FALSE
)

survey <- read_csv(
  file.path(diag_dir, "survey_status_by_section.csv"),
  show_col_types = FALSE
)

section_uncertainty <- section_year %>%
  mutate(
    rel_width_90 = (hi90 - lo90) / pmax(median, 1e-9),
    log_width_90 = log(hi90) - log(lo90)
  ) %>%
  group_by(site, site_name, focal_status, period) %>%
  summarise(
    median_rel_width_90 = median(rel_width_90, na.rm = TRUE),
    median_log_width_90 = median(log_width_90, na.rm = TRUE),
    median_biomass = median(median, na.rm = TRUE),
    .groups = "drop"
  )

section_uncertainty_summary <- section_uncertainty %>%
  group_by(site, site_name, focal_status) %>%
  summarise(
    median_rel_width_90_all_periods = median(median_rel_width_90, na.rm = TRUE),
    recent_rel_width_90 = median(
      median_rel_width_90[period == "2017-2025 recent closure"],
      na.rm = TRUE
    ),
    median_log_width_90_all_periods = median(median_log_width_90, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    scorecard %>%
      select(site, status, recent_to_early_ratio, closure_pct_per_year),
    by = "site"
  ) %>%
  left_join(
    survey %>%
      select(site, surveyed_years, survey_coverage, missing_years),
    by = "site"
  ) %>%
  arrange(desc(recent_rel_width_90))

period_uncertainty <- section_uncertainty %>%
  group_by(period, focal_status) %>%
  summarise(
    median_rel_width_90 = median(median_rel_width_90, na.rm = TRUE),
    median_log_width_90 = median(median_log_width_90, na.rm = TRUE),
    .groups = "drop"
  )

p_section <- section_uncertainty_summary %>%
  mutate(site_name = fct_reorder(site_name, recent_rel_width_90)) %>%
  ggplot(aes(x = recent_rel_width_90, y = site_name, fill = survey_coverage)) +
  geom_col(alpha = 0.9) +
  scale_x_log10(labels = label_number(accuracy = 0.1)) +
  scale_fill_gradient(low = "#F7F7F7", high = "#2166AC", labels = percent) +
  labs(
    x = "Recent 90% interval width / median",
    y = NULL,
    fill = "Survey\ncoverage",
    title = "Recent section uncertainty"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_period <- section_uncertainty %>%
  ggplot(aes(x = period, y = median_rel_width_90, fill = focal_status)) +
  geom_boxplot(outlier.alpha = 0.5) +
  scale_y_log10(labels = label_number(accuracy = 0.1)) +
  scale_fill_manual(values = c(focal_9 = "#176B87", dropped_from_focal = "#C47F2C")) +
  labs(
    x = NULL,
    y = "90% interval width / median",
    fill = NULL,
    title = "Uncertainty by period"
  ) +
  theme_minimal(base_size = 9) +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_status <- section_uncertainty_summary %>%
  ggplot(aes(x = survey_coverage, y = recent_rel_width_90, colour = status)) +
  geom_point(size = 2.5, alpha = 0.9) +
  scale_x_continuous(labels = percent) +
  scale_y_log10(labels = label_number(accuracy = 0.1)) +
  labs(
    x = "Survey coverage",
    y = "Recent relative uncertainty",
    colour = NULL,
    title = "Coverage explains much of section uncertainty"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_section | (p_period / p_status)

ggsave(
  file.path(fig_dir, "m1_stier_11_uncertainty_audit.pdf"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_uncertainty_audit.png"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(section_uncertainty, file.path(diag_dir, "m1_stier_11_uncertainty_by_section_period.csv"))
write_csv(section_uncertainty_summary, file.path(diag_dir, "m1_stier_11_uncertainty_by_section.csv"))
write_csv(period_uncertainty, file.path(diag_dir, "m1_stier_11_uncertainty_by_period.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier 11 Uncertainty Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Highest Recent Section Uncertainty",
  "",
  paste0(
    "- ",
    head(section_uncertainty_summary$site_name, 6),
    ": recent 90% width / median = ",
    fmt(head(section_uncertainty_summary$recent_rel_width_90, 6), 1),
    "; survey coverage = ",
    percent(head(section_uncertainty_summary$survey_coverage, 6), accuracy = 1),
    "; status = ",
    head(section_uncertainty_summary$status, 6)
  ),
  "",
  "## Lowest Recent Section Uncertainty",
  "",
  paste0(
    "- ",
    tail(section_uncertainty_summary$site_name, 6),
    ": recent 90% width / median = ",
    fmt(tail(section_uncertainty_summary$recent_rel_width_90, 6), 1),
    "; survey coverage = ",
    percent(tail(section_uncertainty_summary$survey_coverage, 6), accuracy = 1),
    "; status = ",
    tail(section_uncertainty_summary$status, 6)
  ),
  "",
  "## Interpretation",
  "",
  "- Sparse sections should be carried in the 11-section fit but not overused as headline evidence.",
  "- Naden and Tasu are especially important sensitivity sections because they can influence total biomass but have low survey coverage.",
  "- Persistent depletion conclusions are strongest where low biomass, repeated recent years below threshold, and moderate survey coverage agree.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_uncertainty_audit.pdf`",
  "- `Output/diagnostics/m1_stier_11_uncertainty_by_section.csv`",
  "- `Output/diagnostics/m1_stier_11_uncertainty_by_section_period.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_uncertainty_audit.md"))

cat("Saved uncertainty audit:\n")
cat("  Output/diagnostics/m1_stier_11_uncertainty_audit.md\n")
cat("  Output/figures/m1_stier_11_uncertainty_audit.pdf\n")
