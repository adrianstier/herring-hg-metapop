## ==========================================================================
##  06_state_estimate_plots_v2.R
##  Diagnostic and publication-quality plots for v2 state-space models
## ==========================================================================

library(rstan)
library(tidyverse)
library(patchwork)
library(here)

proj_dir <- here()
data_dir <- file.path(proj_dir, "Data", "processed")
fig_dir  <- file.path(proj_dir, "Output", "figures", "v2")
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

add_events <- function() {
  list(
    geom_vline(xintercept = 2005, linetype = "dashed",
               colour = "grey40", linewidth = 0.35),
    annotate("rect", xmin = 2014, xmax = 2016,
             ymin = -Inf, ymax = Inf,
             fill = "firebrick", alpha = 0.06)
  )
}

## =========================================================================
##  1. FUNCTION TO PLOT A MODEL
## =========================================================================

plot_model_v2 <- function(model_name = "m1") {
  cat("\nProcessing plots for model:", model_name, "v2\n")

  fit_path <- file.path(data_dir, paste0(model_name, "_v2_fit.rds"))
  if (!file.exists(fit_path)) {
    cat("  Fit file not found:", fit_path, "\n")
    return(NULL)
  }

  fit <- readRDS(fit_path)
  load(file.path(data_dir, "jags_model_inputs_v2.RData"))

  Y_raw   <- jags_data$logSHI  # Has NAs for both censored and missing
  nYears  <- jags_data$nYears
  nSites  <- jags_data$nSites
  years   <- jags_data$years
  sites   <- jags_data$site_names
  q_idx   <- jags_data$q_idx
  Y_obs_flag <- jags_data$Y_obs
  Y_cens_flag <- jags_data$Y_censored

  post <- rstan::extract(fit)
  nIter <- dim(post$X)[1]

  # 2. Posterior summary for X
  cat("  Summarising posterior states...\n")
  X_summary <- expand.grid(year_idx = 1:nYears, site_idx = 1:nSites) %>%
    as_tibble() %>%
    mutate(
      year      = years[year_idx],
      site_name = factor(sites[site_idx], levels = sites),
      X_median  = NA_real_,
      X_lo95    = NA_real_,
      X_hi95    = NA_real_,
      X_mean    = NA_real_
    )

  for (i in seq_len(nrow(X_summary))) {
    t_i <- X_summary$year_idx[i]
    j_i <- X_summary$site_idx[i]
    samps <- post$X[, t_i, j_i]
    qs <- quantile(samps, probs = c(0.025, 0.50, 0.975))
    X_summary$X_lo95[i]  <- qs[1]
    X_summary$X_median[i] <- qs[2]
    X_summary$X_hi95[i]  <- qs[3]
    X_summary$X_mean[i]  <- mean(samps)
  }

  # Add observed data
  Y_flat <- as.vector(Y_raw)
  X_summary$Y_obs <- Y_flat
  X_summary$is_obs <- as.vector(Y_obs_flag) == 1
  X_summary$is_cens <- as.vector(Y_cens_flag) == 1

  # log_q mean
  log_q_mean <- colMeans(post$log_q)
  X_summary$q_idx <- q_idx[X_summary$year_idx]

  # 3. Plot 1: Biomass time series
  cat("  Generating biomass plots...\n")
  p1 <- ggplot(X_summary, aes(x = year)) +
    geom_ribbon(aes(ymin = X_lo95, ymax = X_hi95), fill = "#0072B2", alpha = 0.2) +
    geom_line(aes(y = X_median), colour = "#0072B2") +
    # Observed
    geom_point(data = filter(X_summary, is_obs),
               aes(y = Y_obs - log_q_mean[q_idx]),
               size = 0.7, colour = "#D55E00") +
    # Censored zeros (as triangles at bottom)
    geom_point(data = filter(X_summary, is_cens),
               aes(y = X_lo95 - 0.5), shape = 2,
               size = 0.7, colour = "red") +
    facet_wrap(~ site_name, scales = "free_y") +
    add_events() +
    labs(x = "Year", y = "Log-biomass (X scale)",
         title = paste("v2", model_name, "state estimates"),
         subtitle = "Red triangles = surveyed zeros (left-censored)")

  ggsave(file.path(fig_dir, paste0(model_name, "_v2_biomass.png")), p1, width = 12, height = 8)

  # 4. Total biomass
  cat("  Generating total biomass plot...\n")
  total_X_samps <- apply(exp(post$X), c(1, 2), sum)
  total_X_summary <- tibble(
    year = years,
    median = apply(total_X_samps, 2, median),
    lo95 = apply(total_X_samps, 2, quantile, 0.025),
    hi95 = apply(total_X_samps, 2, quantile, 0.975)
  )

  p2 <- ggplot(total_X_summary, aes(x = year, y = median)) +
    geom_ribbon(aes(ymin = lo95, ymax = hi95), fill = "grey70", alpha = 0.3) +
    geom_line() +
    add_events() +
    scale_y_log10() +
    labs(x = "Year", y = "Total Archipelago Biomass (tonnes, log-scale)",
         title = paste("v2", model_name, "total metapopulation biomass"))

  ggsave(file.path(fig_dir, paste0(model_name, "_v2_total_biomass.png")), p2, width = 8, height = 5)

  cat("  Plots saved to", fig_dir, "\n")
}

# Run for M1 v2
plot_model_v2("m1")
