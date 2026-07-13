# ============================================================================
# 07k_m1_stier_11_driver_confounding_audit.R
# Driver collinearity/time-confounding audit for m1_stier_11 driver screens.
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

driver_ts <- read_csv(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  show_col_types = FALSE
)

driver_vars <- c(
  "pdo",
  "pred_combined",
  "seal_std",
  "ssl_std",
  "whale_std",
  "fishing_fraction_median",
  "observed_catch_tonnes",
  "weighted_spawn_start_doy",
  "subtidal_share",
  "substrate_effective_n",
  "sst_spring_anom",
  "chla_spring_mean"
)

label_lookup <- c(
  pdo = "PDO",
  pred_combined = "Combined predators",
  seal_std = "Harbour seal",
  ssl_std = "Steller sea lion",
  whale_std = "Humpback whale",
  fishing_fraction_median = "Fishing fraction",
  observed_catch_tonnes = "Observed catch",
  weighted_spawn_start_doy = "Spawn start DOY",
  subtidal_share = "Subtidal share",
  substrate_effective_n = "Substrate effective n",
  sst_spring_anom = "Spring SST anomaly",
  chla_spring_mean = "Spring chlorophyll"
)

driver_long <- driver_ts %>%
  select(year, all_of(driver_vars)) %>%
  pivot_longer(-year, names_to = "driver", values_to = "value") %>%
  mutate(
    driver_label = recode(driver, !!!label_lookup),
    z_value = as.numeric(scale(value))
  )

safe_spearman <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 5 || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  cor(x[ok], y[ok], method = "spearman")
}

pair_cor <- crossing(driver_x = driver_vars, driver_y = driver_vars) %>%
  mutate(
    rho = map2_dbl(driver_x, driver_y, function(x, y) {
      safe_spearman(driver_ts[[x]], driver_ts[[y]])
    }),
    driver_x_label = recode(driver_x, !!!label_lookup),
    driver_y_label = recode(driver_y, !!!label_lookup)
  )

time_confounding <- tibble(driver = driver_vars) %>%
  mutate(
    driver_label = recode(driver, !!!label_lookup),
    n = map_int(driver, ~ sum(is.finite(driver_ts[[.x]]))),
    rho_year = map_dbl(driver, ~ safe_spearman(driver_ts$year, driver_ts[[.x]])),
    rho_post_closure = map_dbl(driver, ~ {
      post_closure <- as.integer(driver_ts$year >= 2005)
      safe_spearman(post_closure, driver_ts[[.x]])
    }),
    rho_growth = map_dbl(driver, ~ safe_spearman(driver_ts$growth_median, driver_ts[[.x]]))
  ) %>%
  arrange(desc(abs(rho_year)))

high_pair_cor <- pair_cor %>%
  filter(driver_x < driver_y, is.finite(rho), abs(rho) >= 0.7) %>%
  arrange(desc(abs(rho)))

p_heat <- pair_cor %>%
  mutate(
    driver_x_label = factor(driver_x_label, levels = label_lookup[driver_vars]),
    driver_y_label = factor(driver_y_label, levels = rev(label_lookup[driver_vars]))
  ) %>%
  ggplot(aes(x = driver_x_label, y = driver_y_label, fill = rho)) +
  geom_tile(colour = "white", linewidth = 0.1) +
  scale_fill_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1, 1)
  ) +
  labs(
    x = NULL,
    y = NULL,
    fill = "rho",
    title = "Driver correlation matrix",
    subtitle = "Spearman correlations using all available overlapping years."
  ) +
  theme_minimal(base_size = 8) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    legend.position = "bottom"
  )

p_time <- time_confounding %>%
  mutate(driver_label = fct_reorder(driver_label, abs(rho_year))) %>%
  ggplot(aes(x = rho_year, y = driver_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_col(fill = "#176B87", alpha = 0.85) +
  labs(
    x = "Spearman rho with year",
    y = NULL,
    title = "Time confounding",
    subtitle = "Large absolute values are hard to separate from long-term trend."
  ) +
  theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank())

p_series <- driver_long %>%
  filter(driver %in% c("pdo", "pred_combined", "fishing_fraction_median", "subtidal_share", "weighted_spawn_start_doy")) %>%
  ggplot(aes(x = year, y = z_value, colour = driver_label)) +
  geom_hline(yintercept = 0, colour = "grey80") +
  geom_line(linewidth = 0.7, alpha = 0.9) +
  facet_wrap(~driver_label, scales = "free_y", ncol = 1) +
  labs(
    x = "Year",
    y = "Standardized value",
    colour = NULL,
    title = "Selected driver trajectories"
  ) +
  theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(), legend.position = "none")

p <- p_heat | (p_time / p_series)

ggsave(
  file.path(fig_dir, "m1_stier_11_driver_confounding_audit.pdf"),
  p,
  width = 270,
  height = 220,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_driver_confounding_audit.png"),
  p,
  width = 270,
  height = 220,
  units = "mm",
  dpi = 300
)

write_csv(pair_cor, file.path(diag_dir, "m1_stier_11_driver_pair_correlations.csv"))
write_csv(time_confounding, file.path(diag_dir, "m1_stier_11_driver_time_confounding.csv"))
write_csv(high_pair_cor, file.path(diag_dir, "m1_stier_11_driver_high_pair_correlations.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE)
}

lines <- c(
  "# M1 Stier 11 Driver Confounding Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Strongest Time-Confounded Predictors",
  "",
  paste0(
    "- ",
    head(time_confounding$driver_label, 8),
    ": rho with year = ",
    fmt(head(time_confounding$rho_year, 8), 2),
    "; rho with growth = ",
    fmt(head(time_confounding$rho_growth, 8), 2),
    "; n = ",
    head(time_confounding$n, 8)
  ),
  "",
  "## Strong Pairwise Driver Correlations",
  "",
  if (nrow(high_pair_cor) == 0) {
    "- No driver pairs had |Spearman rho| >= 0.70."
  } else {
    paste0(
      "- ",
      recode(high_pair_cor$driver_x, !!!label_lookup),
      " / ",
      recode(high_pair_cor$driver_y, !!!label_lookup),
      ": rho = ",
      fmt(high_pair_cor$rho, 2)
    )
  },
  "",
  "## Interpretation",
  "",
  "- Predator indices are useful ecological hypotheses, but they are heavily time-trended and correlated with each other.",
  "- Fishing and catch covariates are also time-structured because the fishery closes after 2005.",
  "- PDO is still worth carrying forward because it is less mechanically tied to the closure-era management shift.",
  "- Do not read a one-covariate predator correlation as predator causation without a section/process model that can separate time, fishing history, and spatial heterogeneity.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_driver_confounding_audit.pdf`",
  "- `Output/diagnostics/m1_stier_11_driver_pair_correlations.csv`",
  "- `Output/diagnostics/m1_stier_11_driver_time_confounding.csv`",
  "- `Output/diagnostics/m1_stier_11_driver_high_pair_correlations.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_driver_confounding_audit.md"))

cat("Saved driver-confounding diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_driver_confounding_audit.md\n")
cat("  Output/figures/m1_stier_11_driver_confounding_audit.pdf\n")
