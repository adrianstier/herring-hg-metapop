# ============================================================================
# 07j_spawn_timing_substrate_screen.R
# Spawn timing and substrate covariate screen for population interpretation.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

period_for_year <- function(year) {
  case_when(
    year <= 1965 ~ "1951-1965 early industrial",
    year <= 1971 ~ "1966-1971 late reduction",
    year <= 2004 ~ "1972-2004 roe fishery",
    year <= 2013 ~ "2005-2013 closure",
    year <= 2016 ~ "2014-2016 marine heatwave",
    TRUE ~ "2017-2025 recent closure"
  )
}

period_levels <- c(
  "1951-1965 early industrial",
  "1966-1971 late reduction",
  "1972-2004 roe fishery",
  "2005-2013 closure",
  "2014-2016 marine heatwave",
  "2017-2025 recent closure"
)

region_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_region_1951_2025.csv"),
  show_col_types = FALSE
) %>%
  mutate(period = factor(period_for_year(year), levels = period_levels))

section_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_section_1951_2025.csv"),
  show_col_types = FALSE
) %>%
  filter(in_model) %>%
  mutate(period = factor(period_for_year(year), levels = period_levels))

recent_change <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_recent_change.csv"),
  show_col_types = FALSE
)

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
site_lookup <- tibble(
  site = seq_along(keep_sections),
  section = keep_sections
) %>%
  left_join(
    recent_change %>%
      distinct(site, model_site_name = site_name, focal_status),
    by = "site"
  )

annual_cov <- region_cov %>%
  transmute(
    year,
    period,
    surveyed_sections,
    occupied_sections,
    total_spawn_index_tonnes,
    weighted_spawn_start_doy,
    subtidal_share,
    substrate_effective_n,
    timing_window_days
  )

period_cov <- annual_cov %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    median_spawn_start_doy = median(weighted_spawn_start_doy, na.rm = TRUE),
    median_subtidal_share = median(subtidal_share, na.rm = TRUE),
    median_substrate_effective_n = median(substrate_effective_n, na.rm = TRUE),
    median_timing_window_days = median(timing_window_days, na.rm = TRUE),
    median_surveyed_sections = median(surveyed_sections, na.rm = TRUE),
    .groups = "drop"
  )

section_period_cov <- section_cov %>%
  filter(total_records > 0) %>%
  group_by(section, section_name, period) %>%
  summarise(
    n_surveyed_years = n(),
    median_spawn_start_doy = median(spawn_start_doy_weighted, na.rm = TRUE),
    median_subtidal_share = median(subtidal_share, na.rm = TRUE),
    median_substrate_effective_n = median(substrate_effective_n, na.rm = TRUE),
    median_spawn_index_tonnes = median(spawn_index_tonnes, na.rm = TRUE),
    .groups = "drop"
  )

section_change_cov <- section_period_cov %>%
  filter(period %in% c("1951-1965 early industrial", "2017-2025 recent closure")) %>%
  select(section, section_name, period, median_spawn_start_doy, median_subtidal_share, median_substrate_effective_n) %>%
  pivot_wider(
    names_from = period,
    values_from = c(median_spawn_start_doy, median_subtidal_share, median_substrate_effective_n)
  ) %>%
  mutate(
    delta_spawn_start_doy =
      `median_spawn_start_doy_2017-2025 recent closure` -
      `median_spawn_start_doy_1951-1965 early industrial`,
    delta_subtidal_share =
      `median_subtidal_share_2017-2025 recent closure` -
      `median_subtidal_share_1951-1965 early industrial`,
    delta_substrate_effective_n =
      `median_substrate_effective_n_2017-2025 recent closure` -
      `median_substrate_effective_n_1951-1965 early industrial`
  ) %>%
  left_join(site_lookup, by = "section") %>%
  left_join(
    recent_change %>%
      select(site, recent_to_early_ratio, log_recent_to_early),
    by = "site"
  )

safe_spearman <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 5 || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  cor(x[ok], y[ok], method = "spearman")
}

cov_correlations <- section_change_cov %>%
  summarise(
    n_sections = sum(is.finite(log_recent_to_early)),
    rho_delta_spawn_start = safe_spearman(delta_spawn_start_doy, log_recent_to_early),
    rho_delta_subtidal = safe_spearman(delta_subtidal_share, log_recent_to_early),
    rho_delta_substrate_effective_n = safe_spearman(delta_substrate_effective_n, log_recent_to_early)
  )

p_timing <- ggplot(annual_cov, aes(x = year, y = weighted_spawn_start_doy)) +
  geom_point(aes(size = surveyed_sections), colour = "#176B87", alpha = 0.75) +
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE, colour = "#C47F2C", linewidth = 0.7) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  labs(
    x = NULL,
    y = "Weighted spawn start DOY",
    size = "Surveyed\nsections",
    title = "Spawn timing"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_subtidal <- ggplot(annual_cov, aes(x = year, y = subtidal_share)) +
  geom_point(aes(size = surveyed_sections), colour = "#2166AC", alpha = 0.75) +
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE, colour = "#C47F2C", linewidth = 0.7) +
  scale_y_continuous(labels = percent) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  labs(
    x = NULL,
    y = "Subtidal share",
    size = "Surveyed\nsections",
    title = "Subtidal spawn share"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_section <- section_change_cov %>%
  filter(is.finite(delta_subtidal_share), is.finite(log_recent_to_early)) %>%
  ggplot(aes(x = delta_subtidal_share, y = log_recent_to_early, label = model_site_name)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(aes(colour = focal_status), size = 2.4, alpha = 0.9) +
  scale_x_continuous(labels = percent) +
  scale_colour_manual(values = c(focal_9 = "#176B87", dropped_from_focal = "#C47F2C")) +
  labs(
    x = "Recent - early subtidal share",
    y = "log(recent / early biomass)",
    colour = NULL,
    title = "Subtidal-shift screen by section"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_period <- period_cov %>%
  pivot_longer(
    cols = c(median_spawn_start_doy, median_subtidal_share, median_substrate_effective_n),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(metric = recode(
    metric,
    median_spawn_start_doy = "Spawn start DOY",
    median_subtidal_share = "Subtidal share",
    median_substrate_effective_n = "Substrate effective n"
  )) %>%
  ggplot(aes(x = period, y = value, group = metric)) +
  geom_col(fill = "#176B87", alpha = 0.8) +
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  labs(
    x = NULL,
    y = NULL,
    title = "Median covariates by period"
  ) +
  theme_minimal(base_size = 8) +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid.minor = element_blank()
  )

p <- (p_timing | p_subtidal | p_section) / p_period +
  plot_annotation(
    title = "Spawn timing and substrate screen",
    subtitle = "DFO spawn covariates are useful for observation/context sensitivity before they are promoted to process drivers."
  )

ggsave(
  file.path(fig_dir, "spawn_timing_substrate_screen.pdf"),
  p,
  width = 280,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "spawn_timing_substrate_screen.png"),
  p,
  width = 280,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(annual_cov, file.path(diag_dir, "spawn_timing_substrate_annual.csv"))
write_csv(period_cov, file.path(diag_dir, "spawn_timing_substrate_period.csv"))
write_csv(section_period_cov, file.path(diag_dir, "spawn_timing_substrate_section_period.csv"))
write_csv(section_change_cov, file.path(diag_dir, "spawn_timing_substrate_section_change.csv"))
write_csv(cov_correlations, file.path(diag_dir, "spawn_timing_substrate_correlations.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# Spawn Timing And Substrate Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Period Medians",
  "",
  paste0(
    "- ",
    period_cov$period,
    ": spawn start DOY = ",
    fmt(period_cov$median_spawn_start_doy, 1),
    ", subtidal share = ",
    percent(period_cov$median_subtidal_share, accuracy = 1),
    ", substrate effective n = ",
    fmt(period_cov$median_substrate_effective_n, 2),
    ", surveyed sections = ",
    fmt(period_cov$median_surveyed_sections, 1)
  ),
  "",
  "## Section-Level Correlations With Recent / Early Biomass",
  "",
  paste0("- Delta spawn start DOY: Spearman rho = ", fmt(cov_correlations$rho_delta_spawn_start, 2)),
  paste0("- Delta subtidal share: Spearman rho = ", fmt(cov_correlations$rho_delta_subtidal, 2)),
  paste0("- Delta substrate effective n: Spearman rho = ", fmt(cov_correlations$rho_delta_substrate_effective_n, 2)),
  "",
  "## Interpretation",
  "",
  "- Spawn timing and substrate covariates are real changes in the observation record, but they are also entangled with survey coverage and method.",
  "- Treat them first as reporting/observation-context variables and sensitivity covariates.",
  "- Promote them to population-process covariates only after the section-productivity branch is evaluated.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/spawn_timing_substrate_screen.pdf`",
  "- `Output/diagnostics/spawn_timing_substrate_period.csv`",
  "- `Output/diagnostics/spawn_timing_substrate_section_change.csv`",
  "- `Output/diagnostics/spawn_timing_substrate_correlations.csv`"
)

writeLines(lines, file.path(diag_dir, "spawn_timing_substrate_screen.md"))

cat("Saved spawn timing/substrate diagnostics:\n")
cat("  Output/diagnostics/spawn_timing_substrate_screen.md\n")
cat("  Output/figures/spawn_timing_substrate_screen.pdf\n")
