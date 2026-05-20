# ============================================================================
# 07w_density_dependence_screen.R
# Descriptive density-dependence screen from m1_stier_11 posterior medians.
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

year_tbl <- read_csv(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  show_col_types = FALSE
) %>%
  arrange(year) %>%
  mutate(
    log_lag_total_biomass = lag(log(total_biomass_median)),
    lag_total_biomass = lag(total_biomass_median)
  )

section_tbl <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  arrange(site, year) %>%
  group_by(site, site_name, focal_status) %>%
  mutate(
    log_lag_section_biomass = lag(log(median)),
    section_growth = log(median) - lag(log(median)),
    lag_section_biomass = lag(median)
  ) %>%
  ungroup()

total_dd_summary <- year_tbl %>%
  filter(is.finite(growth_median), is.finite(log_lag_total_biomass)) %>%
  summarise(
    n = n(),
    spearman_rho = cor(growth_median, log_lag_total_biomass, method = "spearman"),
    pearson_r = cor(growth_median, log_lag_total_biomass),
    lm_slope = coef(lm(growth_median ~ log_lag_total_biomass))[["log_lag_total_biomass"]],
    lm_p = summary(lm(growth_median ~ log_lag_total_biomass))$coefficients["log_lag_total_biomass", "Pr(>|t|)"],
    .groups = "drop"
  )

period_dd_summary <- year_tbl %>%
  filter(is.finite(growth_median), is.finite(log_lag_total_biomass)) %>%
  group_by(period) %>%
  summarise(
    n = n(),
    spearman_rho = if_else(n >= 4, cor(growth_median, log_lag_total_biomass, method = "spearman"), NA_real_),
    pearson_r = if_else(n >= 4, cor(growth_median, log_lag_total_biomass), NA_real_),
    .groups = "drop"
  )

section_dd_summary <- section_tbl %>%
  filter(is.finite(section_growth), is.finite(log_lag_section_biomass)) %>%
  group_by(site, site_name, focal_status) %>%
  summarise(
    n = n(),
    spearman_rho = cor(section_growth, log_lag_section_biomass, method = "spearman"),
    pearson_r = cor(section_growth, log_lag_section_biomass),
    lm_slope = coef(lm(section_growth ~ log_lag_section_biomass))[["log_lag_section_biomass"]],
    .groups = "drop"
  ) %>%
  arrange(spearman_rho)

section_pooled_summary <- section_tbl %>%
  filter(is.finite(section_growth), is.finite(log_lag_section_biomass)) %>%
  summarise(
    n = n(),
    spearman_rho = cor(section_growth, log_lag_section_biomass, method = "spearman"),
    pearson_r = cor(section_growth, log_lag_section_biomass),
    lm_slope = coef(lm(section_growth ~ log_lag_section_biomass))[["log_lag_section_biomass"]],
    .groups = "drop"
  )

p_total <- year_tbl %>%
  filter(is.finite(growth_median), is.finite(lag_total_biomass)) %>%
  ggplot(aes(x = lag_total_biomass, y = growth_median, colour = period)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(size = 2, alpha = 0.85) +
  geom_smooth(aes(group = 1), method = "lm", formula = y ~ x, se = TRUE, colour = "grey25", linewidth = 0.65) +
  scale_x_log10(labels = label_comma()) +
  labs(
    x = "Lagged archipelago biomass",
    y = "Posterior median log growth",
    colour = NULL,
    title = "Archipelago-level density signal is weak",
    subtitle = "A strong negative slope would support global Gompertz density dependence."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_section <- section_dd_summary %>%
  mutate(site_name = fct_reorder(site_name, spearman_rho)) %>%
  ggplot(aes(x = spearman_rho, y = site_name, colour = focal_status)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(size = 2.2) +
  scale_x_continuous(limits = c(-1, 1)) +
  labs(
    x = "Spearman rho: section growth vs lagged section biomass",
    y = NULL,
    colour = NULL,
    title = "Section-level density signals are mostly weakly negative"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_period <- period_dd_summary %>%
  mutate(
    spearman_plot = replace_na(spearman_rho, 0),
    period = fct_reorder(period, spearman_plot)
  ) %>%
  ggplot(aes(x = spearman_plot, y = period)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_col(fill = "#0072B2", alpha = 0.8, width = 0.7) +
  scale_x_continuous(limits = c(-1, 1)) +
  labs(
    x = "Spearman rho",
    y = NULL,
    title = "Period-specific total-biomass screen is sample-size limited"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- p_total / (p_section | p_period) +
  plot_annotation(
    title = "Descriptive Density-Dependence Screen",
    subtitle = "Uses m1_stier_11 posterior medians; this is not a replacement for a fitted DD model."
  )

ggsave(
  file.path(fig_dir, "density_dependence_screen.pdf"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "density_dependence_screen.png"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(total_dd_summary, file.path(diag_dir, "density_dependence_total_summary.csv"))
write_csv(period_dd_summary, file.path(diag_dir, "density_dependence_by_period.csv"))
write_csv(section_dd_summary, file.path(diag_dir, "density_dependence_by_section.csv"))
write_csv(section_pooled_summary, file.path(diag_dir, "density_dependence_pooled_section_summary.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

section_lines <- section_dd_summary %>%
  slice_head(n = 5) %>%
  transmute(
    line = paste0(
      "- ",
      site_name,
      ": rho=",
      fmt(spearman_rho, 3),
      ", slope=",
      fmt(lm_slope, 3),
      "."
    )
  ) %>%
  pull(line)

lines <- c(
  "# Density-Dependence Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Archipelago growth vs lagged archipelago biomass Spearman rho: ",
    fmt(total_dd_summary$spearman_rho, 3),
    "."
  ),
  paste0(
    "- Archipelago linear slope: ",
    fmt(total_dd_summary$lm_slope, 3),
    " (p=",
    fmt(total_dd_summary$lm_p, 3),
    ")."
  ),
  paste0(
    "- Pooled section growth vs lagged section biomass Spearman rho: ",
    fmt(section_pooled_summary$spearman_rho, 3),
    "."
  ),
  "",
  "Interpretation: there is not a strong descriptive archipelago-level negative density signal in the `m1_stier_11` posterior medians. Section-level signals are mostly weakly negative, which argues for caution before spending a long Stan run on density dependence.",
  "",
  "## Strongest Negative Section Screens",
  "",
  section_lines,
  "",
  "## Decision",
  "",
  "- Do not jump directly to a complex density-dependent model.",
  "- If density dependence is tested, start with one global Gompertz term and keep the Stier observation layer unchanged.",
  "- Treat timing/substrate and observation-scale diagnostics as equally important near-term alternatives.",
  "",
  "## Files",
  "",
  "- `Output/figures/density_dependence_screen.pdf`",
  "- `Output/diagnostics/density_dependence_total_summary.csv`",
  "- `Output/diagnostics/density_dependence_by_section.csv`",
  "- `Output/diagnostics/density_dependence_by_period.csv`"
)

writeLines(lines, file.path(diag_dir, "density_dependence_screen.md"))
cat(paste(lines, collapse = "\n"))
cat("\n")
