# ============================================================================
# 07_m1_stier_11_population_driver_analysis.R
# Population-state and driver diagnostics from the promoted Stier baseline.
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

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(file.path(data_dir, "m1_stier_11_fit.rds"))

post <- rstan::extract(fit, pars = c("X", "Z", "Pc_logit", "Umu", "pdocoef"))

years <- jags_data$years
site_names <- jags_data$site_names
focal_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_idx <- which(!site_names %in% focal_drop)

summarise_draws <- function(x) {
  tibble(
    median = median(x, na.rm = TRUE),
    lo80 = quantile(x, 0.10, na.rm = TRUE),
    hi80 = quantile(x, 0.90, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE)
  )
}

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

# ---------------------------------------------------------------------------
# Posterior state summaries
# ---------------------------------------------------------------------------

total_x_all <- apply(exp(post$X), c(1, 2), sum)
total_z_all <- apply(exp(post$Z), c(1, 2), sum)
total_x_focal <- apply(exp(post$X[, , focal_idx, drop = FALSE]), c(1, 2), sum)
total_z_focal <- apply(exp(post$Z[, , focal_idx, drop = FALSE]), c(1, 2), sum)

total_biomass_df <- bind_rows(
  map_dfr(seq_along(years), function(t) {
    summarise_draws(total_x_all[, t]) %>%
      mutate(year = years[t], report_set = "all_11")
  }),
  map_dfr(seq_along(years), function(t) {
    summarise_draws(total_x_focal[, t]) %>%
      mutate(year = years[t], report_set = "focal_9")
  })
) %>%
  mutate(
    period = factor(period_for_year(year), levels = period_levels),
    report_set = factor(report_set, levels = c("all_11", "focal_9"))
  )

section_biomass_df <- map_dfr(seq_along(years), function(t) {
  map_dfr(seq_along(site_names), function(j) {
    summarise_draws(exp(post$X[, t, j])) %>%
      mutate(
        year = years[t],
        site = j,
        site_name = site_names[j],
        focal_status = if_else(j %in% focal_idx, "focal_9", "dropped_from_focal")
      )
  })
}) %>%
  mutate(period = factor(period_for_year(year), levels = period_levels))

section_period_df <- section_biomass_df %>%
  group_by(site, site_name, focal_status, period) %>%
  summarise(
    median_biomass = median(median, na.rm = TRUE),
    lo90_biomass = median(lo90, na.rm = TRUE),
    hi90_biomass = median(hi90, na.rm = TRUE),
    .groups = "drop"
  )

section_recent_change_df <- section_period_df %>%
  filter(period %in% c(
    "1951-1965 early industrial",
    "2017-2025 recent closure"
  )) %>%
  select(site, site_name, focal_status, period, median_biomass) %>%
  pivot_wider(names_from = period, values_from = median_biomass) %>%
  mutate(
    recent_to_early_ratio = `2017-2025 recent closure` / `1951-1965 early industrial`,
    log_recent_to_early = log(recent_to_early_ratio)
  ) %>%
  arrange(log_recent_to_early)

# ---------------------------------------------------------------------------
# Fishing summaries
# ---------------------------------------------------------------------------

n_draws <- dim(post$X)[1]
removed_draws <- matrix(0, nrow = n_draws, ncol = length(years))

for (k in seq_len(jags_data$nIndex)) {
  t <- jags_data$INDEX[k, 1]
  j <- jags_data$INDEX[k, 2]
  pc <- plogis(post$Pc_logit[, k])
  removed_draws[, t] <- removed_draws[, t] + exp(post$Z[, t, j]) * pc
}

fishing_fraction_draws <- removed_draws / pmax(total_z_all, 1e-12)

catch_by_year <- tibble(
  year = years,
  observed_catch_tonnes = map_dbl(seq_along(years), function(t) {
    idx <- which(jags_data$INDEX[, 1] == t)
    if (length(idx) == 0) {
      return(0)
    }
    sum(exp(jags_data$ctab[jags_data$INDEX][idx]), na.rm = TRUE)
  })
)

fishing_df <- map_dfr(seq_along(years), function(t) {
  summarise_draws(fishing_fraction_draws[, t]) %>%
    mutate(year = years[t])
}) %>%
  left_join(catch_by_year, by = "year") %>%
  mutate(period = factor(period_for_year(year), levels = period_levels))

# ---------------------------------------------------------------------------
# Growth and driver data
# ---------------------------------------------------------------------------

growth_draws <- matrix(NA_real_, nrow = n_draws, ncol = length(years))
growth_draws[, -1] <- log(total_z_all[, -1]) - log(total_x_all[, -length(years)])

growth_df <- map_dfr(seq_along(years), function(t) {
  summarise_draws(growth_draws[, t]) %>%
    mutate(year = years[t])
})

region_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_region_1951_2025.csv"),
  show_col_types = FALSE
)
env_cov <- read_csv(file.path(data_dir, "environmental_covariates.csv"), show_col_types = FALSE)
pred_cov <- read_csv(file.path(data_dir, "predator_indices.csv"), show_col_types = FALSE)

driver_df <- total_biomass_df %>%
  filter(report_set == "all_11") %>%
  select(
    year,
    total_biomass_median = median,
    total_biomass_lo90 = lo90,
    total_biomass_hi90 = hi90,
    period
  ) %>%
  left_join(growth_df %>% select(year, growth_median = median, growth_lo90 = lo90, growth_hi90 = hi90), by = "year") %>%
  left_join(fishing_df %>% select(year, fishing_fraction_median = median, fishing_lo90 = lo90, fishing_hi90 = hi90, observed_catch_tonnes), by = "year") %>%
  left_join(
    region_cov %>%
      select(
        year,
        surveyed_sections,
        occupied_sections,
        surveyed_zero_sections,
        total_spawn_index_tonnes,
        weighted_spawn_start_doy,
        subtidal_share,
        substrate_effective_n,
        dive_record_pct,
        surface_record_pct
      ),
    by = "year"
  ) %>%
  left_join(env_cov, by = "year") %>%
  left_join(pred_cov, by = "year") %>%
  arrange(year) %>%
  mutate(
    across(
      c(
        pdo, pred_combined, seal_std, ssl_std, whale_std,
        weighted_spawn_start_doy, subtidal_share, substrate_effective_n,
        sst_spring_anom, chla_spring_mean, observed_catch_tonnes,
        fishing_fraction_median
      ),
      list(lag1 = ~ lag(.x)),
      .names = "{.col}_lag1"
    )
  )

driver_vars <- c(
  "pdo_lag1",
  "sst_spring_anom_lag1",
  "chla_spring_mean_lag1",
  "pred_combined_lag1",
  "seal_std_lag1",
  "ssl_std_lag1",
  "whale_std_lag1",
  "weighted_spawn_start_doy_lag1",
  "subtidal_share_lag1",
  "substrate_effective_n_lag1",
  "observed_catch_tonnes_lag1",
  "fishing_fraction_median_lag1"
)

cor_one <- function(response, predictor) {
  dat <- driver_df %>%
    select(response = all_of(response), predictor = all_of(predictor)) %>%
    filter(is.finite(response), is.finite(predictor))

  if (nrow(dat) < 10 || sd(dat$response) == 0 || sd(dat$predictor) == 0) {
    return(tibble(
      response = response,
      predictor = predictor,
      n = nrow(dat),
      spearman_rho = NA_real_,
      pearson_r = NA_real_,
      p_spearman = NA_real_
    ))
  }

  spearman <- suppressWarnings(cor.test(dat$response, dat$predictor, method = "spearman"))
  pearson <- suppressWarnings(cor(dat$response, dat$predictor, method = "pearson"))
  tibble(
    response = response,
    predictor = predictor,
    n = nrow(dat),
    spearman_rho = unname(spearman$estimate),
    pearson_r = pearson,
    p_spearman = spearman$p.value
  )
}

driver_cor_df <- bind_rows(
  map_dfr(driver_vars, ~ cor_one("growth_median", .x)),
  map_dfr(driver_vars, ~ cor_one("total_biomass_median", .x)),
  map_dfr(driver_vars, ~ cor_one("occupied_sections", .x))
) %>%
  arrange(response, desc(abs(spearman_rho)))

period_summary_df <- driver_df %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    total_biomass_median = median(total_biomass_median, na.rm = TRUE),
    total_biomass_lo90 = median(total_biomass_lo90, na.rm = TRUE),
    total_biomass_hi90 = median(total_biomass_hi90, na.rm = TRUE),
    growth_median = median(growth_median, na.rm = TRUE),
    occupied_sections = median(occupied_sections, na.rm = TRUE),
    catch_tonnes = median(observed_catch_tonnes, na.rm = TRUE),
    fishing_fraction = median(fishing_fraction_median, na.rm = TRUE),
    pdo = median(pdo, na.rm = TRUE),
    pred_combined = median(pred_combined, na.rm = TRUE),
    weighted_spawn_start_doy = median(weighted_spawn_start_doy, na.rm = TRUE),
    subtidal_share = median(subtidal_share, na.rm = TRUE),
    .groups = "drop"
  )

# ---------------------------------------------------------------------------
# Figures
# ---------------------------------------------------------------------------

report_cols <- c(all_11 = "#176B87", focal_9 = "#4F7F52")
biomass_y_min <- min(total_biomass_df$lo90[total_biomass_df$lo90 > 0], na.rm = TRUE)
biomass_y_max <- max(total_biomass_df$hi90, na.rm = TRUE)

biomass_scaled_df <- driver_df %>%
  transmute(
    year,
    biomass_index = as.numeric(scale(log10(total_biomass_median)))
  )

p_total <- ggplot(total_biomass_df, aes(x = year, colour = report_set, fill = report_set)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), alpha = 0.13, colour = NA) +
  geom_line(aes(y = median), linewidth = 0.7) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  annotate(
    "rect",
    xmin = 2014, xmax = 2016,
    ymin = biomass_y_min * 0.85, ymax = biomass_y_max * 1.15,
    alpha = 0.06, fill = "#B44A3C"
  ) +
  scale_colour_manual(values = report_cols, labels = c(all_11 = "All 11", focal_9 = "9 focal")) +
  scale_fill_manual(values = report_cols, labels = c(all_11 = "All 11", focal_9 = "9 focal")) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = NULL,
    y = "Post-fishing biomass",
    title = "Posterior biomass trajectory",
    subtitle = "Vertical dashed line marks fishery closure; red band marks 2014-2016 MHW."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom", legend.title = element_blank())

p_fishing <- ggplot(fishing_df, aes(x = year)) +
  geom_col(aes(y = observed_catch_tonnes), fill = "#C47F2C", alpha = 0.45) +
  geom_line(aes(y = median * max(observed_catch_tonnes, na.rm = TRUE)), colour = "#101827", linewidth = 0.55) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_y_continuous(
    labels = label_comma(),
    sec.axis = sec_axis(
      ~ .x / max(fishing_df$observed_catch_tonnes, na.rm = TRUE),
      name = "Posterior fishing fraction"
    )
  ) +
  labs(x = NULL, y = "Observed catch", title = "Fishing pressure collapsed after closure") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_growth <- driver_df %>%
  select(year, growth_median, growth_lo90, growth_hi90, pdo_lag1) %>%
  filter(is.finite(growth_median)) %>%
  ggplot(aes(x = year)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_ribbon(aes(ymin = growth_lo90, ymax = growth_hi90), fill = "#176B87", alpha = 0.16) +
  geom_line(aes(y = growth_median), colour = "#176B87", linewidth = 0.65) +
  geom_line(aes(y = pdo_lag1 / 8), colour = "#C47F2C", linewidth = 0.45, alpha = 0.9) +
  labs(
    x = NULL,
    y = "Latent log growth",
    title = "Growth is variable; PDO signal is weak in the baseline",
    subtitle = "Orange shows lagged PDO rescaled for visual comparison."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_pred <- driver_df %>%
  select(year, total_biomass_median, pred_combined, ssl_std, seal_std, whale_std) %>%
  pivot_longer(c(pred_combined, ssl_std, seal_std, whale_std), names_to = "predator", values_to = "index") %>%
  ggplot(aes(x = year)) +
  geom_line(
    data = biomass_scaled_df,
    aes(x = year, y = biomass_index),
    colour = "#176B87",
    linewidth = 0.7,
    inherit.aes = FALSE
  ) +
  geom_line(aes(y = index, colour = predator), linewidth = 0.45, alpha = 0.8) +
  scale_colour_manual(values = c(
    pred_combined = "#101827",
    ssl_std = "#C47F2C",
    seal_std = "#4F7F52",
    whale_std = "#B44A3C"
  )) +
  labs(
    x = NULL,
    y = "Standardized index",
    title = "Predator trends are descriptive here, not yet causal",
    subtitle = "Blue biomass line is standardized log biomass; predator covariates are not in m1_stier_11."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom", legend.title = element_blank())

p_cor <- driver_cor_df %>%
  filter(response == "growth_median", is.finite(spearman_rho)) %>%
  mutate(
    predictor = str_remove(predictor, "_lag1$"),
    predictor = fct_reorder(predictor, spearman_rho)
  ) %>%
  ggplot(aes(x = spearman_rho, y = predictor, fill = spearman_rho > 0)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = "grey45") +
  scale_fill_manual(values = c(`TRUE` = "#176B87", `FALSE` = "#C47F2C"), guide = "none") +
  labs(
    x = "Spearman rho with next-year latent growth",
    y = NULL,
    title = "Descriptive driver screening",
    subtitle = "Correlations are not causal; they identify candidates for the next Stan branch."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_dashboard <- (p_total | p_fishing) / (p_growth | p_pred) / p_cor +
  plot_annotation(
    title = "M1 Stier 11 population and driver diagnostic",
    subtitle = "Promoted baseline states plus descriptive covariate screening for the next model branches."
  )

p_section <- section_period_df %>%
  ggplot(aes(x = period, y = fct_rev(factor(site_name)), fill = log10(median_biomass))) +
  geom_tile(colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "C", labels = label_number(accuracy = 0.1)) +
  labs(
    x = NULL,
    y = NULL,
    fill = "log10 biomass",
    title = "Section biomass by period",
    subtitle = "Posterior median post-fishing biomass from m1_stier_11."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 35, hjust = 1)
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_population_driver_dashboard.pdf"),
  p_dashboard,
  width = 240,
  height = 300,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_population_driver_dashboard.png"),
  p_dashboard,
  width = 240,
  height = 300,
  units = "mm",
  dpi = 300
)
ggsave(
  file.path(fig_dir, "m1_stier_11_section_period_heatmap.pdf"),
  p_section,
  width = 240,
  height = 160,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_section_period_heatmap.png"),
  p_section,
  width = 240,
  height = 160,
  units = "mm",
  dpi = 300
)

# ---------------------------------------------------------------------------
# Write outputs and memo
# ---------------------------------------------------------------------------

write_csv(total_biomass_df, file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"))
write_csv(section_biomass_df, file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"))
write_csv(section_period_df, file.path(diag_dir, "m1_stier_11_section_biomass_by_period.csv"))
write_csv(section_recent_change_df, file.path(diag_dir, "m1_stier_11_section_recent_change.csv"))
write_csv(fishing_df, file.path(diag_dir, "m1_stier_11_fishing_by_year.csv"))
write_csv(driver_df, file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"))
write_csv(driver_cor_df, file.path(diag_dir, "m1_stier_11_driver_correlations.csv"))
write_csv(period_summary_df, file.path(diag_dir, "m1_stier_11_period_summary.csv"))

pdo_summary <- tibble(
  variable = c("Umu", "pdocoef"),
  mean = c(mean(post$Umu), mean(post$pdocoef)),
  q05 = c(quantile(post$Umu, 0.05), quantile(post$pdocoef, 0.05)),
  q50 = c(quantile(post$Umu, 0.50), quantile(post$pdocoef, 0.50)),
  q95 = c(quantile(post$Umu, 0.95), quantile(post$pdocoef, 0.95))
)
write_csv(pdo_summary, file.path(diag_dir, "m1_stier_11_core_parameter_summary.csv"))

top_growth_cor <- driver_cor_df %>%
  filter(response == "growth_median", is.finite(spearman_rho)) %>%
  arrange(desc(abs(spearman_rho))) %>%
  slice_head(n = 6)

recent <- period_summary_df %>% filter(period == "2017-2025 recent closure")
early <- period_summary_df %>% filter(period == "1951-1965 early industrial")
roe <- period_summary_df %>% filter(period == "1972-2004 roe fishery")

decliners <- section_recent_change_df %>%
  slice_head(n = 4)
increasers <- section_recent_change_df %>%
  arrange(desc(log_recent_to_early)) %>%
  slice_head(n = 4)

fmt <- function(x, digits = 2) {
  format(round(x, digits), big.mark = ",", trim = TRUE)
}

lines <- c(
  "# M1 Stier 11 Population And Driver Diagnostic",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## What This Is",
  "",
  "This memo screens population state and driver signals from the promoted `m1_stier_11` baseline. It is descriptive, not a causal predator or density-dependence model.",
  "",
  "## Headline Read",
  "",
  paste0(
    "- Median all-section biomass in the recent closure period is ",
    fmt(recent$total_biomass_median, 0),
    " versus ",
    fmt(early$total_biomass_median, 0),
    " in the early industrial period and ",
    fmt(roe$total_biomass_median, 0),
    " during the roe-fishery period."
  ),
  paste0(
    "- Median observed occupied sections in the recent closure period is ",
    fmt(recent$occupied_sections, 1),
    " out of 11."
  ),
  paste0(
    "- Median fishing fraction in the recent closure period is ",
    fmt(recent$fishing_fraction, 4),
    ", compared with ",
    fmt(roe$fishing_fraction, 4),
    " during the roe-fishery period."
  ),
  paste0(
    "- Baseline PDO effect posterior: mean ",
    fmt(pdo_summary$mean[pdo_summary$variable == "pdocoef"], 3),
    ", 90% interval ",
    fmt(pdo_summary$q05[pdo_summary$variable == "pdocoef"], 3),
    " to ",
    fmt(pdo_summary$q95[pdo_summary$variable == "pdocoef"], 3),
    "."
  ),
  "",
  "## Driver Screening",
  "",
  "Strong correlations below are candidates for new Stan branches, not evidence of causality.",
  "",
  paste0(
    "- ",
    top_growth_cor$predictor,
    ": Spearman rho with next-year latent growth = ",
    fmt(top_growth_cor$spearman_rho, 2),
    " (n=",
    top_growth_cor$n,
    ")"
  ),
  "",
  "## Section Patterns",
  "",
  "Largest recent-to-early declines:",
  "",
  paste0(
    "- ",
    decliners$site_name,
    ": recent / early ratio = ",
    fmt(decliners$recent_to_early_ratio, 2)
  ),
  "",
  "Largest recent-to-early increases:",
  "",
  paste0(
    "- ",
    increasers$site_name,
    ": recent / early ratio = ",
    fmt(increasers$recent_to_early_ratio, 2)
  ),
  "",
  "## Interpretation For Next Models",
  "",
  "1. Fishing removal is no longer the direct pressure after closure, so the next model should not just add more catch structure.",
  "2. Section differences are large enough to justify a site-heterogeneity branch before predator covariates.",
  "3. Predator indices are useful descriptive context, but they are confounded with closure-era time trends in this baseline screen.",
  "4. Timing and substrate covariates are reasonable near-term candidates because they come directly from the DFO spawn survey process.",
  "5. Full age/size structure remains a later cross-check, not the next section-level model.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_population_driver_dashboard.pdf`",
  "- `Output/figures/m1_stier_11_section_period_heatmap.pdf`",
  "- `Output/diagnostics/m1_stier_11_driver_correlations.csv`",
  "- `Output/diagnostics/m1_stier_11_period_summary.csv`",
  "- `Output/diagnostics/m1_stier_11_section_recent_change.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_population_driver_summary.md"))

cat("Saved population/driver diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_population_driver_summary.md\n")
cat("  Output/figures/m1_stier_11_population_driver_dashboard.pdf\n")
cat("  Output/figures/m1_stier_11_section_period_heatmap.pdf\n")
