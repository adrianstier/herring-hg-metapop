# ============================================================================
# 07ae_predator_data_feasibility_audit.R
# Predator data feasibility and confounding audit.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
raw_pred_dir <- file.path(proj_dir, "Data", "raw", "predators")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

safe_spearman <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 5 || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  cor(x[ok], y[ok], method = "spearman")
}

driver_ts <- read_csv(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  show_col_types = FALSE
)

pred <- read_csv(
  file.path(data_dir, "predator_indices.csv"),
  show_col_types = FALSE
)

seal_raw <- read_csv(
  file.path(raw_pred_dir, "Harbour_seal_counts_haulout_locs_BCcoast.csv"),
  show_col_types = FALSE
)

ssl_raw <- read_csv(
  file.path(raw_pred_dir, "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv"),
  show_col_types = FALSE
)

whale_raw <- read_csv(
  file.path(raw_pred_dir, "humpback_whale_NorthPacific_abundance_Cheeseman2024.csv"),
  show_col_types = FALSE
)

seal_hg <- seal_raw %>%
  filter(Region == "Haida Gwaii")

ssl_hg <- ssl_raw %>%
  filter(REGION == "Haida Gwaii")

availability_tbl <- tibble(
  predator = c("Harbour seal", "Steller sea lion", "Humpback whale"),
  raw_scope = c("Haida Gwaii haulout complexes", "Haida Gwaii haulouts / rookeries", "North Pacific basin-wide"),
  raw_year_min = c(min(seal_hg$Year, na.rm = TRUE), min(ssl_hg$`SURVEY YEAR`, na.rm = TRUE), min(whale_raw$Year, na.rm = TRUE)),
  raw_year_max = c(max(seal_hg$Year, na.rm = TRUE), max(ssl_hg$`SURVEY YEAR`, na.rm = TRUE), max(whale_raw$Year, na.rm = TRUE)),
  raw_unique_years = c(n_distinct(seal_hg$Year), n_distinct(ssl_hg$`SURVEY YEAR`), n_distinct(whale_raw$Year)),
  raw_site_or_series_units = c(n_distinct(seal_hg$Complex), n_distinct(ssl_hg$SITE), 1L),
  processed_observed_years = c(sum(pred$seal_obs), sum(pred$ssl_obs), sum(pred$whale_obs)),
  current_model_use = c(
    "regional annual index; spatial exposure possible from haulout coordinates",
    "regional annual index; spatial exposure possible through 2013 / 2017 only",
    "regional proxy only; not Haida Gwaii-specific"
  )
)

pred_long <- pred %>%
  transmute(
    year,
    `Harbour seal` = seal_std,
    `Steller sea lion` = ssl_std,
    `Humpback whale` = whale_std,
    `Combined predator` = pred_combined
  ) %>%
  pivot_longer(-year, names_to = "predator", values_to = "standardized_index")

obs_long <- pred %>%
  transmute(
    year,
    `Harbour seal` = seal_obs == 1L,
    `Steller sea lion` = ssl_obs == 1L,
    `Humpback whale` = whale_obs == 1L
  ) %>%
  pivot_longer(-year, names_to = "predator", values_to = "observed")

confounding_tbl <- tibble(
  predator = c("Harbour seal", "Steller sea lion", "Humpback whale", "Combined predator", "PDO"),
  variable = c("seal_std", "ssl_std", "whale_std", "pred_combined", "pdo")
) %>%
  rowwise() %>%
  mutate(
    rho_year = safe_spearman(driver_ts[[variable]], driver_ts$year),
    rho_total_biomass = safe_spearman(driver_ts[[variable]], driver_ts$total_biomass_median),
    rho_next_year_growth = safe_spearman(driver_ts[[paste0(variable, "_lag1")]] %||% driver_ts[[variable]], driver_ts$growth_median),
    rho_fishing_fraction = safe_spearman(driver_ts[[variable]], driver_ts$fishing_fraction_median),
    rho_pdo = if_else(variable == "pdo", NA_real_, safe_spearman(driver_ts[[variable]], driver_ts$pdo)),
    rho_combined_predator = if_else(variable == "pred_combined", NA_real_, safe_spearman(driver_ts[[variable]], driver_ts$pred_combined))
  ) %>%
  ungroup() %>%
  select(-variable)

pred_pair_cor <- pred %>%
  select(seal_std, ssl_std, whale_std, pred_combined) %>%
  cor(use = "complete.obs", method = "spearman") %>%
  as.data.frame() %>%
  rownames_to_column("index_a") %>%
  pivot_longer(-index_a, names_to = "index_b", values_to = "spearman_rho") %>%
  filter(index_a < index_b)

recommendation_tbl <- tibble(
  candidate = c(
    "Combined regional predator index",
    "Separate harbour seal / SSL / humpback regional effects",
    "Spatial harbour seal and SSL exposure",
    "Humpback spatial exposure",
    "Predator branch in Stan"
  ),
  current_status = c(
    "available but strongly time-confounded",
    "available but collinear",
    "partly feasible from raw haulout data",
    "not currently available as a time series",
    "not recommended yet"
  ),
  main_blocker = c(
    "monotonic recovery and closure-era trend are hard to separate",
    "indices are highly correlated with each other",
    "raw counts are sparse and need correction/interpolation choices",
    "current whale series is basin-wide; PRISMM is a one-year spatial snapshot",
    "observation/process calibration should settle first"
  ),
  next_action = c(
    "report descriptively; do not interpret causally",
    "avoid in one model until more data or stronger priors exist",
    "build a separate exposure data product before model fitting",
    "obtain feeding-area or sighting-effort corrected data",
    "revisit only after `m3_stier_distance` exact re-LOO and a simple PDO branch"
  )
)

pred_cols <- c(
  "Harbour seal" = "#009E73",
  "Steller sea lion" = "#D55E00",
  "Humpback whale" = "#0072B2",
  "Combined predator" = "#6A3D9A",
  "PDO" = "grey35"
)

p_ts <- ggplot(pred_long, aes(x = year, y = standardized_index, colour = predator)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey65", linewidth = 0.25) +
  geom_line(linewidth = 0.7) +
  geom_point(
    data = obs_long %>% filter(observed),
    aes(x = year, y = -2.3, colour = predator),
    inherit.aes = FALSE,
    size = 1.3,
    alpha = 0.85
  ) +
  scale_colour_manual(values = pred_cols[names(pred_cols) != "PDO"]) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  labs(
    x = NULL,
    y = "Standardized index",
    title = "Current predator indices are mostly regional time trends",
    subtitle = "Dots along the bottom mark years with directly observed source data before interpolation/extrapolation."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

scatter_df <- driver_ts %>%
  transmute(
    year,
    pred_combined,
    pdo,
    growth_median,
    total_biomass_median,
    fishing_fraction_median
  )

p_year <- ggplot(scatter_df, aes(x = year, y = pred_combined)) +
  geom_point(colour = "#6A3D9A", alpha = 0.75, size = 1.6) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey35", linewidth = 0.6) +
  labs(
    x = "Year",
    y = "Combined predator index",
    title = "Time confounding"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_growth <- ggplot(scatter_df, aes(x = pred_combined, y = growth_median)) +
  geom_blank(data = scatter_df %>% filter(is.finite(pred_combined), is.finite(growth_median))) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey65", linewidth = 0.25) +
  geom_point(
    data = scatter_df %>% filter(is.finite(pred_combined), is.finite(growth_median)),
    aes(colour = year),
    alpha = 0.75,
    size = 1.6
  ) +
  geom_smooth(
    data = scatter_df %>% filter(is.finite(pred_combined), is.finite(growth_median)),
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = "grey35",
    linewidth = 0.6
  ) +
  scale_colour_viridis_c(option = "C", guide = "none") +
  labs(
    x = "Combined predator index",
    y = "Next-year latent growth",
    title = "Weak growth screen"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_fishing <- ggplot(scatter_df, aes(x = pred_combined, y = fishing_fraction_median)) +
  geom_point(aes(colour = year), alpha = 0.75, size = 1.6) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey35", linewidth = 0.6) +
  scale_colour_viridis_c(option = "C", guide = "none") +
  scale_y_continuous(labels = percent) +
  labs(
    x = "Combined predator index",
    y = "Fishing fraction",
    title = "Closure confounding"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p <- p_ts / (p_year | p_growth | p_fishing) +
  plot_layout(heights = c(1.15, 1)) +
  plot_annotation(
    title = "Predator data feasibility audit",
    subtitle = "Predator recovery is ecologically plausible, but the current covariates are too time-confounded for a clean causal branch."
  )

ggsave(
  file.path(fig_dir, "predator_data_feasibility_audit.pdf"),
  p,
  width = 230, height = 175, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "predator_data_feasibility_audit.png"),
  p,
  width = 230, height = 175, units = "mm", dpi = 300
)

write_csv(availability_tbl, file.path(diag_dir, "predator_data_availability.csv"))
write_csv(confounding_tbl, file.path(diag_dir, "predator_data_confounding.csv"))
write_csv(pred_pair_cor, file.path(diag_dir, "predator_index_pair_correlations.csv"))
write_csv(recommendation_tbl, file.path(diag_dir, "predator_model_recommendations.csv"))

fmt <- function(x, accuracy = 0.01) number(x, accuracy = accuracy)

combined_row <- confounding_tbl %>% filter(predator == "Combined predator")
pdo_row <- confounding_tbl %>% filter(predator == "PDO")
high_pairs <- pred_pair_cor %>%
  arrange(desc(abs(spearman_rho))) %>%
  slice_head(n = 3)

lines <- c(
  "# Predator Data Feasibility Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Bottom Line",
  "",
  "Predator recovery remains a plausible ecological hypothesis, but the current predator covariates should stay descriptive for now. They are regional, highly collinear, and strongly confounded with year / closure era.",
  "",
  "## Data Availability",
  "",
  paste0("- Harbour seal raw data: Haida Gwaii haulout records, `", availability_tbl$raw_year_min[1], "-", availability_tbl$raw_year_max[1], "`, `", availability_tbl$raw_unique_years[1], "` observed years, `", availability_tbl$raw_site_or_series_units[1], "` complexes."),
  paste0("- Steller sea lion raw data: Haida Gwaii haulout / rookery records, `", availability_tbl$raw_year_min[2], "-", availability_tbl$raw_year_max[2], "`, `", availability_tbl$raw_unique_years[2], "` observed years, `", availability_tbl$raw_site_or_series_units[2], "` sites."),
  paste0("- Humpback whale raw data: North Pacific basin-wide abundance, `", availability_tbl$raw_year_min[3], "-", availability_tbl$raw_year_max[3], "`, not a Haida Gwaii-specific series."),
  "",
  "## Confounding",
  "",
  paste0("- Combined predator index versus year Spearman rho: `", fmt(combined_row$rho_year), "`."),
  paste0("- Combined predator index versus next-year growth Spearman rho: `", fmt(combined_row$rho_next_year_growth), "`."),
  paste0("- PDO versus year Spearman rho: `", fmt(pdo_row$rho_year), "`, which is why PDO remains a cleaner simple regional covariate candidate."),
  paste0(
    "- Strongest predator index correlations: ",
    paste0(high_pairs$index_a, " / ", high_pairs$index_b, " `", fmt(high_pairs$spearman_rho), "`", collapse = "; "),
    "."
  ),
  "",
  "## Recommendation",
  "",
  "- Do not launch a predator Stan branch from the current regional index yet.",
  "- If predator work proceeds, first build a separate exposure data product for harbour seals and Steller sea lions from haulout coordinates and document interpolation/correction choices.",
  "- Humpback exposure needs either feeding-area estimates, effort-corrected sightings, or spatial density snapshots linked to time; the current basin-wide series is not enough for section-level inference.",
  "- In the near term, report predator recovery as ecological context and prioritize exact re-LOO for the distance model plus any simple PDO branch.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/predator_data_feasibility_audit.pdf`",
  "- `Output/diagnostics/predator_data_availability.csv`",
  "- `Output/diagnostics/predator_data_confounding.csv`",
  "- `Output/diagnostics/predator_model_recommendations.csv`"
)

writeLines(lines, file.path(diag_dir, "predator_data_feasibility_audit.md"))

cat("Saved predator data feasibility audit:\n")
cat("  Output/figures/predator_data_feasibility_audit.pdf\n")
cat("  Output/diagnostics/predator_data_feasibility_audit.md\n")
