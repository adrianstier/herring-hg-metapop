# ============================================================================
# 07z_pdo_climate_signal_screen.R
# Focused PDO/climate screen for the m1_stier_11 baseline.
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

ts_tbl <- read_diag("m1_stier_11_driver_screening_timeseries.csv")
robust_tbl <- read_diag("m1_stier_11_driver_robustness.csv")
param_tbl <- read_csv(file.path(proj_dir, "Output", "m1_stier_11_parameter_summary.csv"), show_col_types = FALSE)

pdo_param <- param_tbl %>%
  filter(variable == "pdocoef") %>%
  slice(1)

pdo_lag_tbl <- robust_tbl %>%
  filter(
    response == "growth_median",
    predictor == "pdo",
    subset == "all_years"
  ) %>%
  arrange(lag) %>%
  select(lag, n, spearman_rho, pearson_r, detrended_r, p_spearman, p_detrended, robust_score)

pdo_period_tbl <- ts_tbl %>%
  filter(!is.na(growth_median), !is.na(pdo_lag1)) %>%
  group_by(period) %>%
  summarise(
    n = n(),
    median_pdo_lag1 = median(pdo_lag1, na.rm = TRUE),
    median_growth = median(growth_median, na.rm = TRUE),
    spearman_rho = if_else(n >= 4, cor(growth_median, pdo_lag1, method = "spearman"), NA_real_),
    .groups = "drop"
  )

pdo_state_tbl <- ts_tbl %>%
  filter(!is.na(growth_median), !is.na(pdo_lag1)) %>%
  mutate(
    pdo_state = case_when(
      pdo_lag1 <= quantile(pdo_lag1, 1 / 3, na.rm = TRUE) ~ "cool PDO tercile",
      pdo_lag1 >= quantile(pdo_lag1, 2 / 3, na.rm = TRUE) ~ "warm PDO tercile",
      TRUE ~ "middle PDO tercile"
    ),
    pdo_state = factor(pdo_state, levels = c("cool PDO tercile", "middle PDO tercile", "warm PDO tercile"))
  ) %>%
  group_by(pdo_state) %>%
  summarise(
    n = n(),
    median_pdo_lag1 = median(pdo_lag1, na.rm = TRUE),
    median_growth = median(growth_median, na.rm = TRUE),
    median_fishing_fraction = median(fishing_fraction_median, na.rm = TRUE),
    median_total_biomass = median(total_biomass_median, na.rm = TRUE),
    .groups = "drop"
  )

pdo_year_tbl <- ts_tbl %>%
  select(
    year, period, growth_median, growth_lo90, growth_hi90,
    total_biomass_median, pdo, pdo_lag1, fishing_fraction_median,
    pred_combined_lag1, subtidal_share_lag1
  )

write_csv(pdo_lag_tbl, file.path(diag_dir, "pdo_climate_lag_screen.csv"))
write_csv(pdo_period_tbl, file.path(diag_dir, "pdo_climate_by_period.csv"))
write_csv(pdo_state_tbl, file.path(diag_dir, "pdo_climate_by_state.csv"))
write_csv(pdo_year_tbl, file.path(diag_dir, "pdo_climate_yearly.csv"))

p_ts <- ggplot(ts_tbl, aes(x = year)) +
  geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
  geom_col(aes(y = pdo), fill = "#0072B2", alpha = 0.55) +
  geom_line(
    data = ts_tbl %>% filter(!is.na(growth_median)),
    aes(y = growth_median),
    colour = "#D55E00",
    linewidth = 0.65
  ) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "PDO and latent growth",
    title = "PDO and posterior median growth",
    subtitle = "Blue bars are PDO; orange line is next-year latent growth from m1_stier_11."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_scatter <- ts_tbl %>%
  filter(!is.na(growth_median), !is.na(pdo_lag1)) %>%
  ggplot(aes(x = pdo_lag1, y = growth_median, colour = period)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(size = 2, alpha = 0.85) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey30", linewidth = 0.6) +
  labs(
    x = "PDO lag 1",
    y = "Next-year latent growth",
    colour = NULL,
    title = "Lag-1 PDO is the cleanest regional covariate screen",
    subtitle = paste0(
      "Spearman rho=",
      number(pdo_lag_tbl$spearman_rho[pdo_lag_tbl$lag == 1], accuracy = 0.01),
      "; detrended r=",
      number(pdo_lag_tbl$detrended_r[pdo_lag_tbl$lag == 1], accuracy = 0.01),
      "."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_lags <- pdo_lag_tbl %>%
  mutate(lag = factor(paste0("lag ", lag), levels = paste0("lag ", sort(lag)))) %>%
  pivot_longer(
    cols = c(spearman_rho, detrended_r),
    names_to = "metric",
    values_to = "r"
  ) %>%
  mutate(metric = recode(metric, spearman_rho = "Spearman", detrended_r = "Detrended Pearson")) %>%
  ggplot(aes(x = lag, y = r, fill = metric)) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.3) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(values = c("Spearman" = "#0072B2", "Detrended Pearson" = "#009E73")) +
  labs(
    x = NULL,
    y = "Correlation with growth",
    fill = NULL,
    title = "PDO lag sensitivity"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_state <- ggplot(pdo_state_tbl, aes(x = pdo_state, y = median_growth, fill = pdo_state)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_col(width = 0.65) +
  scale_fill_manual(values = c("#56B4E9", "#999999", "#E69F00")) +
  labs(
    x = NULL,
    y = "Median latent growth",
    title = "Growth by lagged PDO tercile"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none",
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

p <- (p_ts / (p_scatter | p_lags | p_state)) +
  plot_layout(heights = c(1.1, 1)) +
  plot_annotation(
    title = "PDO climate signal screen",
    subtitle = "PDO is more model-ready than predator indices because it is associated with growth but not a monotonic time trend."
  )

ggsave(
  file.path(fig_dir, "pdo_climate_signal_screen.pdf"),
  p,
  width = 230, height = 185, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "pdo_climate_signal_screen.png"),
  p,
  width = 230, height = 185, units = "mm", dpi = 300
)

md_lines <- c(
  "# PDO Climate Signal Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Baseline Stan PDO coefficient mean `",
    number(pdo_param$mean, accuracy = 0.001),
    "`, 90% interval `",
    number(pdo_param$q5, accuracy = 0.001),
    "` to `",
    number(pdo_param$q95, accuracy = 0.001),
    "`."
  ),
  paste0(
    "- Lag-1 PDO versus next-year posterior median growth: Spearman rho `",
    number(pdo_lag_tbl$spearman_rho[pdo_lag_tbl$lag == 1], accuracy = 0.01),
    "`, detrended r `",
    number(pdo_lag_tbl$detrended_r[pdo_lag_tbl$lag == 1], accuracy = 0.01),
    "`."
  ),
  paste0(
    "- PDO versus year Spearman rho is near zero (`",
    number(read_diag("m1_stier_11_driver_time_confounding.csv") %>%
      filter(driver == "pdo") %>%
      pull(rho_year) %>%
      first(), accuracy = 0.01),
    "`), unlike predator indices."
  ),
  "",
  "## Interpretation",
  "",
  "- PDO is the cleanest regional climate signal, and it is already included in the promoted baseline.",
  "- The promoted baseline includes a weak negative lagged-PDO effect, but its interval overlaps zero.",
  "- Treat this as evidence for climate context, not a fully promoted causal model.",
  "- Do not launch a redundant PDO-only branch; if climate needs more work, test PDO window/lag sensitivity on the existing baseline structure.",
  "",
  "## Files",
  "",
  "- `Output/figures/pdo_climate_signal_screen.pdf`",
  "- `Output/diagnostics/pdo_climate_lag_screen.csv`",
  "- `Output/diagnostics/pdo_climate_by_period.csv`",
  "- `Output/diagnostics/pdo_climate_by_state.csv`"
)

writeLines(md_lines, file.path(diag_dir, "pdo_climate_signal_screen.md"))

cat("Saved PDO climate screen outputs:\n")
cat("  Output/figures/pdo_climate_signal_screen.pdf\n")
cat("  Output/diagnostics/pdo_climate_signal_screen.md\n")
