# ============================================================================
# 07d_m1_stier_11_fit_quality_summary.R
# Positive-spawn and catch fit quality summary for the promoted baseline.
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

spawn_fit <- read_csv(
  file.path(diag_dir, "m1_stier_11_positive_spawn_fit.csv"),
  show_col_types = FALSE
) %>%
  mutate(
    period = factor(period_for_year(year), levels = period_levels),
    abs_log_residual = abs(log_residual),
    covered_90 = observed_log_spawn >= fitted_log_lo90 &
      observed_log_spawn <= fitted_log_hi90,
    residual_direction = case_when(
      log_residual > 0 ~ "observed > fitted",
      log_residual < 0 ~ "observed < fitted",
      TRUE ~ "exact"
    )
  )

catch_fit <- read_csv(
  file.path(diag_dir, "m1_stier_11_catch_fit.csv"),
  show_col_types = FALSE
) %>%
  mutate(
    period = factor(period_for_year(year), levels = period_levels),
    abs_log_residual = abs(log_residual),
    covered_90 = observed_log_catch >= fitted_log_lo90 &
      observed_log_catch <= fitted_log_hi90
  )

spawn_method_summary <- spawn_fit %>%
  group_by(method) %>%
  summarise(
    n = n(),
    rmse = sqrt(mean(log_residual^2, na.rm = TRUE)),
    bias = mean(log_residual, na.rm = TRUE),
    mae = mean(abs_log_residual, na.rm = TRUE),
    coverage_90 = mean(covered_90, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(rmse))

spawn_period_summary <- spawn_fit %>%
  group_by(period) %>%
  summarise(
    n = n(),
    rmse = sqrt(mean(log_residual^2, na.rm = TRUE)),
    bias = mean(log_residual, na.rm = TRUE),
    mae = mean(abs_log_residual, na.rm = TRUE),
    coverage_90 = mean(covered_90, na.rm = TRUE),
    .groups = "drop"
  )

spawn_site_summary <- spawn_fit %>%
  group_by(site, site_name) %>%
  summarise(
    n = n(),
    rmse = sqrt(mean(log_residual^2, na.rm = TRUE)),
    bias = mean(log_residual, na.rm = TRUE),
    mae = mean(abs_log_residual, na.rm = TRUE),
    coverage_90 = mean(covered_90, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(rmse))

spawn_site_period_summary <- spawn_fit %>%
  group_by(site, site_name, period) %>%
  summarise(
    n = n(),
    rmse = sqrt(mean(log_residual^2, na.rm = TRUE)),
    bias = mean(log_residual, na.rm = TRUE),
    coverage_90 = mean(covered_90, na.rm = TRUE),
    .groups = "drop"
  )

catch_summary <- catch_fit %>%
  summarise(
    n = n(),
    rmse = sqrt(mean(log_residual^2, na.rm = TRUE)),
    bias = mean(log_residual, na.rm = TRUE),
    mae = mean(abs_log_residual, na.rm = TRUE),
    coverage_90 = mean(covered_90, na.rm = TRUE)
  )

worst_spawn <- spawn_fit %>%
  arrange(desc(abs_log_residual)) %>%
  slice_head(n = 25)

p_method <- spawn_method_summary %>%
  mutate(method = fct_reorder(method, rmse)) %>%
  ggplot(aes(x = rmse, y = method, fill = bias > 0)) +
  geom_col(width = 0.72) +
  scale_fill_manual(values = c(`TRUE` = "#176B87", `FALSE` = "#C47F2C"), guide = "none") +
  labs(
    x = "Positive-spawn log RMSE",
    y = NULL,
    title = "Fit quality by survey method",
    subtitle = "Blue means observed values are higher than fitted on average; orange means lower."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_period <- spawn_period_summary %>%
  ggplot(aes(x = period, y = rmse, fill = bias > 0)) +
  geom_col(width = 0.72) +
  scale_fill_manual(values = c(`TRUE` = "#176B87", `FALSE` = "#C47F2C"), guide = "none") +
  labs(
    x = NULL,
    y = "Positive-spawn log RMSE",
    title = "Fit quality by period"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 35, hjust = 1)
  )

p_heat <- spawn_site_period_summary %>%
  ggplot(aes(x = period, y = fct_reorder(site_name, rmse, .fun = max), fill = rmse)) +
  geom_tile(colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(labels = label_number(accuracy = 0.1)) +
  labs(
    x = NULL,
    y = NULL,
    fill = "RMSE",
    title = "Where positive-spawn misfit is concentrated"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 35, hjust = 1)
  )

p <- (p_method | p_period) / p_heat +
  plot_annotation(
    title = "M1 Stier 11 fit-quality summary",
    subtitle = "Catch is matched almost exactly by construction; remaining misfit is in positive spawn magnitudes."
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_fit_quality_summary.pdf"),
  p,
  width = 240,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_fit_quality_summary.png"),
  p,
  width = 240,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(spawn_method_summary, file.path(diag_dir, "m1_stier_11_spawn_fit_by_method.csv"))
write_csv(spawn_period_summary, file.path(diag_dir, "m1_stier_11_spawn_fit_by_period.csv"))
write_csv(spawn_site_summary, file.path(diag_dir, "m1_stier_11_spawn_fit_by_section.csv"))
write_csv(spawn_site_period_summary, file.path(diag_dir, "m1_stier_11_spawn_fit_by_section_period.csv"))
write_csv(catch_summary, file.path(diag_dir, "m1_stier_11_catch_fit_summary.csv"))
write_csv(worst_spawn, file.path(diag_dir, "m1_stier_11_worst_positive_spawn_residuals.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier 11 Fit-Quality Summary",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Positive Spawn Fit By Method",
  "",
  paste0(
    "- ",
    spawn_method_summary$method,
    ": RMSE = ",
    fmt(spawn_method_summary$rmse, 2),
    ", bias = ",
    fmt(spawn_method_summary$bias, 2),
    ", 90% coverage = ",
    percent(spawn_method_summary$coverage_90, accuracy = 1)
  ),
  "",
  "## Worst Sections",
  "",
  paste0(
    "- ",
    head(spawn_site_summary$site_name, 6),
    ": RMSE = ",
    fmt(head(spawn_site_summary$rmse, 6), 2),
    ", bias = ",
    fmt(head(spawn_site_summary$bias, 6), 2)
  ),
  "",
  "## Catch Fit",
  "",
  paste0(
    "- Catch log RMSE = ",
    fmt(catch_summary$rmse, 5),
    "; this is near-zero because the current catch likelihood treats reported catch as an almost exact removal constraint."
  ),
  "",
  "## Interpretation",
  "",
  "- The model is not catch-limited; catch is essentially pinned by the likelihood.",
  "- Positive-spawn magnitude fit is the meaningful calibration target.",
  "- Method and period differences should remain visible in every reporting figure.",
  "- Persistent section-level residual structure is another reason to test `m2_stier_site_growth` before adding predators.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_fit_quality_summary.pdf`",
  "- `Output/diagnostics/m1_stier_11_spawn_fit_by_method.csv`",
  "- `Output/diagnostics/m1_stier_11_spawn_fit_by_section.csv`",
  "- `Output/diagnostics/m1_stier_11_worst_positive_spawn_residuals.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_fit_quality_summary.md"))

cat("Saved fit-quality diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_fit_quality_summary.md\n")
cat("  Output/figures/m1_stier_11_fit_quality_summary.pdf\n")
