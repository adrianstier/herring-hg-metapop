## ==========================================================================
##  06_state_estimate_plots.R
##  Diagnostic and publication-quality plots for M1 state-space model
##  (herring metapopulation, Haida Gwaii).
##
##  Generates:
##    1. Estimated biomass time series by site (posterior X with CIs + obs Y)
##    2. Observed vs fitted scatter with R² and RMSE
##    3. Residuals over time by site
##    4. Total biomass trajectory (summed across sites)
##    5. Realized growth rate over time
##    6. Site-level parameter comparison (caterpillar plot of Z_init + growth)
##
##  Requires: m1_fit.rds, jags_model_inputs.RData
## ==========================================================================

library(rstan)
library(tidyverse)
library(patchwork)

proj_dir <- here::here()
proc_dir <- file.path(proj_dir, "Data", "processed")
fig_dir  <- file.path(proj_dir, "Output", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

## =========================================================================
##  0. PALETTE AND THEME
## =========================================================================

okabe_ito <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
  "#D55E00", "#CC79A7", "#000000", "#999999", "#882255", "#44AA99"
)

theme_diag <- function(base_size = 10) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor  = element_blank(),
      strip.text        = element_text(size = base_size - 1, face = "bold"),
      axis.text         = element_text(size = base_size - 2),
      axis.title        = element_text(size = base_size - 1),
      plot.title        = element_text(size = base_size + 1, face = "bold"),
      plot.subtitle     = element_text(size = base_size - 1, colour = "grey40"),
      legend.text       = element_text(size = base_size - 2),
      legend.title      = element_text(size = base_size - 1),
      plot.margin       = margin(8, 8, 8, 8, "mm")
    )
}

theme_set(theme_diag())

# Helper: add key event markers (fishery closure + marine heatwave)
add_events <- function(p) {
  p +
    geom_vline(xintercept = 2005, linetype = "dashed",
               colour = "grey40", linewidth = 0.35) +
    annotate("rect", xmin = 2014, xmax = 2016,
             ymin = -Inf, ymax = Inf,
             fill = "firebrick", alpha = 0.06)
}


## =========================================================================
##  1. LOAD DATA AND MODEL FIT
## =========================================================================

cat("Loading data and model fit...\n")

load(file.path(proc_dir, "jags_model_inputs.RData"))

Y_raw   <- jags_data$Y              # 75 x 11
nYears  <- jags_data$nYears
nSites  <- jags_data$nSites
years   <- jags_data$years           # 1951:2025
sites   <- jags_data$site_names      # character[11]
q_idx   <- jags_data$q_idx           # 1=surface, 2=dive

fit_m1 <- readRDS(file.path(proc_dir, "m1_fit.rds"))

cat("Extracting posterior samples (this may take a moment)...\n")
post <- rstan::extract(fit_m1)

# Key arrays:
# post$X      — 4000 x 75 x 11 (post-fishing log biomass)
# post$Z      — 4000 x 75 x 11 (pre-fishing log biomass)
# post$Y_rep  — 4000 x 75 x 11 (posterior predictive)
# post$log_q  — 4000 x 2

nIter <- dim(post$X)[1]
cat("Posterior samples:", nIter, "\n")
cat("Years:", min(years), "-", max(years), " (", nYears, ")\n")
cat("Sites:", nSites, "\n\n")


## =========================================================================
##  2. BUILD TIDY POSTERIOR SUMMARY FOR X (POST-FISHING LOG-BIOMASS)
## =========================================================================

# Compute quantiles of X[t,j] across posterior samples
X_summary <- expand.grid(year_idx = 1:nYears, site_idx = 1:nSites) %>%
  as_tibble() %>%
  mutate(
    year      = years[year_idx],
    site_name = factor(sites[site_idx], levels = sites),
    X_median  = NA_real_,
    X_lo95    = NA_real_,
    X_hi95    = NA_real_,
    X_lo80    = NA_real_,
    X_hi80    = NA_real_,
    X_mean    = NA_real_
  )

cat("Computing posterior summaries for X...\n")
for (i in seq_len(nrow(X_summary))) {
  t_i <- X_summary$year_idx[i]
  j_i <- X_summary$site_idx[i]
  samps <- post$X[, t_i, j_i]
  qs <- quantile(samps, probs = c(0.025, 0.10, 0.50, 0.90, 0.975))
  X_summary$X_lo95[i]  <- qs[1]
  X_summary$X_lo80[i]  <- qs[2]
  X_summary$X_median[i] <- qs[3]
  X_summary$X_hi80[i]  <- qs[4]
  X_summary$X_hi95[i]  <- qs[5]
  X_summary$X_mean[i]  <- mean(samps)
}

# Add observed Y values
Y_df <- expand.grid(year_idx = 1:nYears, site_idx = 1:nSites) %>%
  as_tibble() %>%
  mutate(
    year      = years[year_idx],
    site_name = factor(sites[site_idx], levels = sites),
    Y_obs     = as.vector(Y_raw)
  )

X_summary <- X_summary %>%
  left_join(Y_df %>% select(year, site_name, Y_obs),
            by = c("year", "site_name"))

# Compute fitted Y (predicted observation) = X + log_q[q_idx[t]]
# Use posterior mean of log_q
log_q_mean <- colMeans(post$log_q)  # [surface, dive]

X_summary <- X_summary %>%
  mutate(
    q_index  = q_idx[year_idx],
    Y_fitted = X_mean + log_q_mean[q_index]
  )

cat("Posterior summaries computed.\n\n")


## =========================================================================
##  3. PLOT 1: ESTIMATED BIOMASS TIME SERIES BY SITE
## =========================================================================

cat("Generating Plot 1: Biomass time series by site...\n")

p1 <- ggplot(X_summary, aes(x = year)) +
  # 95% CI ribbon
  geom_ribbon(aes(ymin = X_lo95, ymax = X_hi95),
              fill = "#0072B2", alpha = 0.15) +
  # 80% CI ribbon
  geom_ribbon(aes(ymin = X_lo80, ymax = X_hi80),
              fill = "#0072B2", alpha = 0.25) +
  # Posterior median line
  geom_line(aes(y = X_median), colour = "#0072B2", linewidth = 0.5) +
  # Observed Y as points (adjusted for log_q so they're on the X scale)
  geom_point(
    aes(y = Y_obs - log_q_mean[q_index]),
    size = 0.8, colour = "#D55E00", alpha = 0.8,
    na.rm = TRUE
  ) +
  # Event markers
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.25) +
  annotate("rect", xmin = 2014, xmax = 2016,
           ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.04) +
  facet_wrap(~ site_name, ncol = 3, scales = "free_y") +
  scale_x_continuous(breaks = seq(1950, 2025, by = 20)) +
  labs(
    x = "Year",
    y = "Estimated log-biomass (post-fishing)",
    title = "M1 state estimates: posterior median and credible intervals",
    subtitle = "Blue ribbon = 80%/95% CI of X[t,j]; orange points = observed Y adjusted to X scale"
  ) +
  theme(
    strip.text = element_text(size = 7),
    axis.text  = element_text(size = 6)
  )

ggsave(file.path(fig_dir, "m1_biomass_timeseries_by_site.pdf"),
       p1, width = 250, height = 200, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_biomass_timeseries_by_site.png"),
       p1, width = 250, height = 200, units = "mm", dpi = 300)

cat("  Saved: m1_biomass_timeseries_by_site\n")


## =========================================================================
##  4. PLOT 2: OBSERVED VS FITTED
## =========================================================================

cat("Generating Plot 2: Observed vs fitted...\n")

obs_fit <- X_summary %>%
  filter(!is.na(Y_obs)) %>%
  select(year, site_name, Y_obs, Y_fitted)

# Compute R² and RMSE
r2   <- cor(obs_fit$Y_obs, obs_fit$Y_fitted)^2
rmse <- sqrt(mean((obs_fit$Y_obs - obs_fit$Y_fitted)^2))

# Axis limits
lims <- range(c(obs_fit$Y_obs, obs_fit$Y_fitted), na.rm = TRUE)
lims <- lims + c(-0.5, 0.5)

p2 <- ggplot(obs_fit, aes(x = Y_fitted, y = Y_obs, colour = site_name)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed",
              colour = "grey50", linewidth = 0.4) +
  geom_point(size = 1.2, alpha = 0.6) +
  scale_colour_manual(values = okabe_ito, name = "Site") +
  coord_equal(xlim = lims, ylim = lims) +
  annotate("text",
           x = lims[1] + 0.3, y = lims[2] - 0.3,
           label = paste0("R\u00B2 = ", round(r2, 3),
                          "\nRMSE = ", round(rmse, 3)),
           hjust = 0, vjust = 1, size = 3.5, colour = "grey20") +
  labs(
    x = "Fitted Y (posterior mean)",
    y = "Observed Y (log spawn index)",
    title = "M1 model fit: observed vs predicted log-spawn index"
  ) +
  guides(colour = guide_legend(ncol = 3, override.aes = list(size = 2.5))) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "m1_observed_vs_fitted.pdf"),
       p2, width = 170, height = 180, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_observed_vs_fitted.png"),
       p2, width = 170, height = 180, units = "mm", dpi = 300)

cat("  Saved: m1_observed_vs_fitted\n")
cat("  R² =", round(r2, 4), " | RMSE =", round(rmse, 4), "\n")


## =========================================================================
##  5. PLOT 3: RESIDUALS OVER TIME
## =========================================================================

cat("Generating Plot 3: Residuals over time...\n")

resid_df <- obs_fit %>%
  mutate(residual = Y_obs - Y_fitted)

p3 <- ggplot(resid_df, aes(x = year, y = residual)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_point(size = 0.6, colour = "#0072B2", alpha = 0.7) +
  geom_smooth(method = "loess", se = TRUE, span = 0.5,
              colour = "#D55E00", fill = "#D55E00",
              alpha = 0.15, linewidth = 0.5) +
  # Event markers
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.25) +
  annotate("rect", xmin = 2014, xmax = 2016,
           ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.04) +
  facet_wrap(~ site_name, ncol = 3, scales = "free_y") +
  scale_x_continuous(breaks = seq(1950, 2025, by = 20)) +
  labs(
    x = "Year",
    y = "Residual (observed - fitted)",
    title = "M1 residuals by site over time",
    subtitle = "Loess smoother (orange) reveals temporal bias; grey line = zero"
  ) +
  theme(
    strip.text = element_text(size = 7),
    axis.text  = element_text(size = 6)
  )

ggsave(file.path(fig_dir, "m1_residuals_by_site.pdf"),
       p3, width = 250, height = 200, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_residuals_by_site.png"),
       p3, width = 250, height = 200, units = "mm", dpi = 300)

cat("  Saved: m1_residuals_by_site\n")


## =========================================================================
##  6. PLOT 4: TOTAL BIOMASS TRAJECTORY
## =========================================================================

cat("Generating Plot 4: Total biomass trajectory...\n")

# Sum X[t,j] across sites for each posterior sample, then summarise
# post$X is 4000 x 75 x 11
total_X <- apply(post$X, c(1, 2), sum)  # 4000 x 75

total_summary <- tibble(
  year      = years,
  median    = apply(total_X, 2, median),
  lo95      = apply(total_X, 2, quantile, 0.025),
  hi95      = apply(total_X, 2, quantile, 0.975),
  lo80      = apply(total_X, 2, quantile, 0.10),
  hi80      = apply(total_X, 2, quantile, 0.90),
  mean_val  = apply(total_X, 2, mean)
)

# Observed total: sum of Y_raw across sites (only where observed)
# Since Y is log(SHI), we can't just sum logs. Instead, sum the observed
# log-values adjusted to X scale (Y - log_q) for visual comparison.
obs_total_df <- X_summary %>%
  filter(!is.na(Y_obs)) %>%
  mutate(Y_adj = Y_obs - log_q_mean[q_index]) %>%
  group_by(year) %>%
  summarise(
    obs_sum_adj = sum(Y_adj, na.rm = TRUE),
    n_obs       = n(),
    .groups     = "drop"
  )

p4 <- ggplot(total_summary, aes(x = year)) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95),
              fill = "#009E73", alpha = 0.15) +
  geom_ribbon(aes(ymin = lo80, ymax = hi80),
              fill = "#009E73", alpha = 0.25) +
  geom_line(aes(y = median), colour = "#009E73", linewidth = 0.7) +
  # Observed total as points
  geom_point(data = obs_total_df,
             aes(x = year, y = obs_sum_adj),
             size = 0.8, colour = "#D55E00", alpha = 0.7) +
  # Fishery closure and MHW markers
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.35) +
  annotate("rect", xmin = 2014, xmax = 2016,
           ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.06) +
  annotate("text", x = 2005, y = Inf, label = "Fishery\nclosure",
           vjust = 1.5, hjust = 1.1, size = 2.8, colour = "grey40") +
  annotate("text", x = 2015, y = Inf, label = "MHW",
           vjust = 1.5, hjust = 0.5, size = 2.8, colour = "firebrick") +
  # Pre vs post closure shading
  annotate("rect", xmin = 1951, xmax = 2005,
           ymin = -Inf, ymax = Inf,
           fill = "grey70", alpha = 0.04) +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(
    x = "Year",
    y = "Total estimated log-biomass (sum across 11 sites)",
    title = "Archipelago-wide estimated log-biomass (M1)",
    subtitle = "Green ribbon = posterior 80%/95% CI; orange = sum of observed log-Y (adj. for catchability)"
  )

ggsave(file.path(fig_dir, "m1_total_biomass_trajectory.pdf"),
       p4, width = 200, height = 120, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_total_biomass_trajectory.png"),
       p4, width = 200, height = 120, units = "mm", dpi = 300)

cat("  Saved: m1_total_biomass_trajectory\n")


## =========================================================================
##  7. PLOT 5: REALIZED GROWTH RATE OVER TIME
## =========================================================================

cat("Generating Plot 5: Growth rate over time...\n")

# Realized growth rate: r[t,j] = X[t,j] - X[t-1,j]
# Compute for each posterior sample, then summarise per year

# Mean growth rate across sites for each posterior sample and year
# post$X is 4000 x 75 x 11
growth_raw <- post$X[, 2:nYears, , drop = FALSE] -
              post$X[, 1:(nYears - 1), , drop = FALSE]
# growth_raw: 4000 x 74 x 11

# Mean across sites per iteration per year
growth_mean_sites <- apply(growth_raw, c(1, 2), mean)  # 4000 x 74

growth_summary <- tibble(
  year   = years[2:nYears],
  median = apply(growth_mean_sites, 2, median),
  lo95   = apply(growth_mean_sites, 2, quantile, 0.025),
  hi95   = apply(growth_mean_sites, 2, quantile, 0.975),
  lo80   = apply(growth_mean_sites, 2, quantile, 0.10),
  hi80   = apply(growth_mean_sites, 2, quantile, 0.90),
  mean_r = apply(growth_mean_sites, 2, mean)
)

# Also compute site-specific growth for a spaghetti view
growth_site_summary <- expand.grid(
  year_idx = 2:nYears,
  site_idx = 1:nSites
) %>%
  as_tibble() %>%
  mutate(
    year      = years[year_idx],
    site_name = factor(sites[site_idx], levels = sites)
  )

growth_site_summary$r_median <- NA_real_
growth_site_summary$r_mean   <- NA_real_

for (i in seq_len(nrow(growth_site_summary))) {
  t_i <- growth_site_summary$year_idx[i] - 1  # index into growth_raw
  j_i <- growth_site_summary$site_idx[i]
  samps <- growth_raw[, t_i, j_i]
  growth_site_summary$r_median[i] <- median(samps)
  growth_site_summary$r_mean[i]   <- mean(samps)
}

# Panel A: mean growth rate across sites
p5a <- ggplot(growth_summary, aes(x = year)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95),
              fill = "#CC79A7", alpha = 0.15) +
  geom_ribbon(aes(ymin = lo80, ymax = hi80),
              fill = "#CC79A7", alpha = 0.25) +
  geom_line(aes(y = median), colour = "#CC79A7", linewidth = 0.5) +
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.35) +
  annotate("rect", xmin = 2014, xmax = 2016,
           ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.06) +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(
    x = "Year",
    y = "Mean realized growth rate\n(across 11 sites)",
    title = "Realized per-capita growth rate over time (M1)",
    subtitle = "r[t] = X[t,j] - X[t-1,j], averaged across sites; ribbon = 80%/95% CI"
  )

# Panel B: by site
p5b <- ggplot(growth_site_summary,
              aes(x = year, y = r_median, colour = site_name)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_line(linewidth = 0.3, alpha = 0.7) +
  scale_colour_manual(values = okabe_ito, name = "Site") +
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.35) +
  annotate("rect", xmin = 2014, xmax = 2016,
           ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.06) +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(
    x = "Year",
    y = "Realized growth rate (site-level)",
    subtitle = "Posterior median growth rate by site"
  ) +
  guides(colour = guide_legend(ncol = 3, override.aes = list(linewidth = 1))) +
  theme(legend.position = "bottom")

p5_combined <- p5a / p5b +
  plot_layout(heights = c(1, 1.2)) +
  plot_annotation(tag_levels = "A")

ggsave(file.path(fig_dir, "m1_growth_rate_over_time.pdf"),
       p5_combined, width = 200, height = 200, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_growth_rate_over_time.png"),
       p5_combined, width = 200, height = 200, units = "mm", dpi = 300)

cat("  Saved: m1_growth_rate_over_time\n")

# Compare pre- vs post-closure mean growth rates
pre_closure  <- growth_summary %>% filter(year <= 2005) %>% pull(mean_r)
post_closure <- growth_summary %>% filter(year > 2005)  %>% pull(mean_r)
cat("  Mean growth rate (posterior mean, averaged across sites):\n")
cat("    Pre-closure (1952-2005):", round(mean(pre_closure), 4), "\n")
cat("    Post-closure (2006-2025):", round(mean(post_closure), 4), "\n")


## =========================================================================
##  8. PLOT 6: SITE-LEVEL PARAMETER COMPARISON (CATERPILLAR PLOTS)
## =========================================================================

cat("Generating Plot 6: Site-level parameter caterpillar plots...\n")

# M1 has global Umu (no site-varying growth rate). We can instead show:
#   A) Initial state estimates Z_init[j] (caterpillar)
#   B) Mean realized growth rate per site across all years (from posteriors)

# A: Z_init caterpillar
Z_init_summary <- tibble(
  site_name = factor(sites, levels = sites),
  median    = apply(post$Z_init, 2, median),
  lo95      = apply(post$Z_init, 2, quantile, 0.025),
  hi95      = apply(post$Z_init, 2, quantile, 0.975),
  lo80      = apply(post$Z_init, 2, quantile, 0.10),
  hi80      = apply(post$Z_init, 2, quantile, 0.90)
)

p6a <- ggplot(Z_init_summary,
              aes(x = fct_reorder(site_name, median), y = median)) +
  geom_linerange(aes(ymin = lo95, ymax = hi95),
                 linewidth = 0.4, colour = "grey60") +
  geom_linerange(aes(ymin = lo80, ymax = hi80),
                 linewidth = 1.0, colour = "#0072B2") +
  geom_point(size = 2, colour = "#0072B2") +
  coord_flip() +
  labs(
    x = NULL,
    y = "Initial log-biomass Z[1,j]",
    title = "Initial state estimates by site (1951)"
  )

# B: Mean realized growth rate per site (posterior distribution)
# For each site j, compute mean( X[t,j] - X[t-1,j] ) over all t for each
# posterior iteration, giving a posterior distribution of mean growth per site.
site_growth_post <- matrix(NA_real_, nrow = nIter, ncol = nSites)
for (j in 1:nSites) {
  r_jt <- post$X[, 2:nYears, j] - post$X[, 1:(nYears - 1), j]  # nIter x 74
  site_growth_post[, j] <- rowMeans(r_jt)
}

site_growth_summary <- tibble(
  site_name = factor(sites, levels = sites),
  median    = apply(site_growth_post, 2, median),
  lo95      = apply(site_growth_post, 2, quantile, 0.025),
  hi95      = apply(site_growth_post, 2, quantile, 0.975),
  lo80      = apply(site_growth_post, 2, quantile, 0.10),
  hi80      = apply(site_growth_post, 2, quantile, 0.90),
  mean_val  = apply(site_growth_post, 2, mean)
)

p6b <- ggplot(site_growth_summary,
              aes(x = fct_reorder(site_name, median), y = median)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50",
             linewidth = 0.3) +
  geom_linerange(aes(ymin = lo95, ymax = hi95),
                 linewidth = 0.4, colour = "grey60") +
  geom_linerange(aes(ymin = lo80, ymax = hi80),
                 linewidth = 1.0, colour = "#009E73") +
  geom_point(size = 2, colour = "#009E73") +
  coord_flip() +
  labs(
    x = NULL,
    y = "Mean realized growth rate (1952-2025)",
    title = "Mean realized growth rate by site"
  )

p6_combined <- p6a + p6b +
  plot_annotation(tag_levels = "A")

ggsave(file.path(fig_dir, "m1_site_parameter_caterpillar.pdf"),
       p6_combined, width = 250, height = 120, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_site_parameter_caterpillar.png"),
       p6_combined, width = 250, height = 120, units = "mm", dpi = 300)

cat("  Saved: m1_site_parameter_caterpillar\n")


## =========================================================================
##  9. SUPPLEMENTARY: POSTERIOR PREDICTIVE CHECK HISTOGRAM
## =========================================================================

cat("Generating supplementary: posterior predictive check...\n")

# Compare distribution of observed Y with Y_rep samples
# Pick 50 random posterior draws of Y_rep for overlay
set.seed(42)
draw_idx <- sample(nIter, 50)

# Flatten observed Y (non-NA only)
Y_obs_vec <- as.vector(Y_raw)
Y_obs_vec <- Y_obs_vec[!is.na(Y_obs_vec)]

# Flatten Y_rep for each draw (all cells, but only those observed)
y_obs_mask <- !is.na(as.vector(Y_raw))
ppc_draws <- map_dfr(draw_idx, function(d) {
  y_rep_d <- as.vector(post$Y_rep[d, , ])
  tibble(
    value = y_rep_d[y_obs_mask],
    draw  = as.character(d),
    type  = "Y_rep"
  )
})

ppc_obs <- tibble(
  value = Y_obs_vec,
  draw  = "observed",
  type  = "Observed"
)

p_ppc <- ggplot() +
  geom_density(data = ppc_draws, aes(x = value, group = draw),
               colour = "#0072B2", alpha = 0.1, linewidth = 0.2) +
  geom_density(data = ppc_obs, aes(x = value),
               colour = "#D55E00", linewidth = 0.8) +
  labs(
    x = "Log spawn index",
    y = "Density",
    title = "Posterior predictive check (M1)",
    subtitle = "Orange = observed Y; blue = 50 posterior predictive draws"
  )

ggsave(file.path(fig_dir, "m1_posterior_predictive_check.pdf"),
       p_ppc, width = 170, height = 100, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_posterior_predictive_check.png"),
       p_ppc, width = 170, height = 100, units = "mm", dpi = 300)

cat("  Saved: m1_posterior_predictive_check\n")


## =========================================================================
##  10. SUPPLEMENTARY: KEY PARAMETER POSTERIOR DENSITIES
## =========================================================================

cat("Generating supplementary: parameter posteriors...\n")

param_df <- tibble(
  Umu        = post$Umu,
  pdocoef    = post$pdocoef,
  sigma_proc = post$sigma_proc,
  sigma_obs  = post$sigma_obs,
  log_q_surf = post$log_q[, 1],
  log_q_dive = post$log_q[, 2]
) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "value") %>%
  mutate(parameter = factor(parameter,
    levels = c("Umu", "pdocoef", "sigma_proc", "sigma_obs",
               "log_q_surf", "log_q_dive"),
    labels = c("U (growth rate)", "PDO coefficient",
               "sigma[proc]", "sigma[obs]",
               "log(q) surface", "log(q) dive")
  ))

p_params <- ggplot(param_df, aes(x = value)) +
  geom_density(fill = "#0072B2", alpha = 0.3, colour = "#0072B2") +
  facet_wrap(~ parameter, scales = "free", ncol = 3) +
  labs(
    x = "Parameter value",
    y = "Posterior density",
    title = "M1 key parameter posteriors"
  )

ggsave(file.path(fig_dir, "m1_parameter_posteriors.pdf"),
       p_params, width = 220, height = 130, units = "mm", dpi = 300,
       device = cairo_pdf)
ggsave(file.path(fig_dir, "m1_parameter_posteriors.png"),
       p_params, width = 220, height = 130, units = "mm", dpi = 300)

cat("  Saved: m1_parameter_posteriors\n")


## =========================================================================
##  11. SUMMARY STATISTICS
## =========================================================================

cat("\n")
cat("======================================================\n")
cat("  M1 DIAGNOSTIC PLOT SUMMARY\n")
cat("======================================================\n\n")

cat("Plots generated:\n")
cat("  1. m1_biomass_timeseries_by_site  — State estimates with CIs by site\n")
cat("  2. m1_observed_vs_fitted          — Scatter of Y_obs vs Y_fitted\n")
cat("  3. m1_residuals_by_site           — Residuals over time by site\n")
cat("  4. m1_total_biomass_trajectory    — Summed log-biomass with CIs\n")
cat("  5. m1_growth_rate_over_time       — Realized per-capita growth\n")
cat("  6. m1_site_parameter_caterpillar  — Initial states + mean growth by site\n")
cat("  7. m1_posterior_predictive_check  — PPC density overlay\n")
cat("  8. m1_parameter_posteriors        — Key parameter densities\n\n")

cat("Model fit statistics:\n")
cat("  R² (observed vs fitted):", round(r2, 4), "\n")
cat("  RMSE:", round(rmse, 4), "\n\n")

cat("Key parameter estimates (posterior mean [95% CI]):\n")
cat("  Umu (growth rate):",
    round(mean(post$Umu), 4), "[",
    round(quantile(post$Umu, 0.025), 4), ",",
    round(quantile(post$Umu, 0.975), 4), "]\n")
cat("  PDO coefficient:",
    round(mean(post$pdocoef), 4), "[",
    round(quantile(post$pdocoef, 0.025), 4), ",",
    round(quantile(post$pdocoef, 0.975), 4), "]\n")
cat("  sigma_proc:",
    round(mean(post$sigma_proc), 4), "[",
    round(quantile(post$sigma_proc, 0.025), 4), ",",
    round(quantile(post$sigma_proc, 0.975), 4), "]\n")
cat("  sigma_obs:",
    round(mean(post$sigma_obs), 4), "[",
    round(quantile(post$sigma_obs, 0.025), 4), ",",
    round(quantile(post$sigma_obs, 0.975), 4), "]\n")

cat("\n======================================================\n")
cat("  DONE\n")
cat("======================================================\n")
