# ============================================================================
# 05_mcmc_diagnostics.R — Comprehensive MCMC diagnostics for all fitted models
#
# Runs ruthless diagnostics on M1, M2, M3, M5 herring metapopulation models:
#   1. Trace plots and mixing assessment
#   2. Rhat distributions and flagging
#   3. Effective sample size (bulk + tail ESS)
#   4. Divergent transitions analysis
#   5. Energy diagnostics (E-BFMI)
#   6. Posterior predictive checks
#   7. Residual analysis
#   8. LOO diagnostics deep-dive (Pareto k, WAIC vs LOO)
#
# Outputs:
#   - PDF diagnostic plots  -> Output/diagnostics/
#   - Text diagnostic report -> Output/diagnostics/diagnostic_report.txt
# ============================================================================

library(rstan)
library(loo)
library(bayesplot)
library(posterior)
library(ggplot2)
library(patchwork)
library(here)

# Source shared setup
source(here("R", "00_setup.R"))

# ============================================================================
# SETUP
# ============================================================================

data_dir <- here("Data", "processed")
diag_dir <- here("Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

# Load model data
load(file.path(data_dir, "jags_model_inputs.RData"))

Y_raw      <- jags_data$Y
nYears     <- jags_data$nYears
nSites     <- jags_data$nSites
years      <- jags_data$years
site_names <- jags_data$site_names
q_idx      <- jags_data$q_idx
y_obs      <- ifelse(is.na(Y_raw), 0L, 1L)

cat("Data loaded:", nYears, "years x", nSites, "sites\n")
cat("Observed cells:", sum(y_obs), "of", prod(dim(y_obs)), "\n\n")

# Open report file
report_file <- file.path(diag_dir, "diagnostic_report.txt")
report_con <- file(report_file, open = "wt")

write_report <- function(...) {
  msg <- paste0(...)
  cat(msg, "\n")
  writeLines(msg, report_con)
}

write_report("================================================================")
write_report("  MCMC DIAGNOSTICS REPORT — Herring Metapopulation Models")
write_report("  Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
write_report("================================================================")
write_report("")

# ============================================================================
# LOAD ALL MODELS
# ============================================================================

model_files <- list(
  M1 = file.path(data_dir, "m1_fit.rds"),
  M2 = file.path(data_dir, "m2_fit.rds"),
  M3 = file.path(data_dir, "m3_fit.rds"),
  M5 = file.path(data_dir, "m5_fit.rds")
)

# Key parameters per model (for trace plots)
key_params <- list(
  M1 = c("Umu", "pdocoef", "sigma_proc", "sigma_obs", "log_q[1]", "log_q[2]"),
  M2 = c("U_mu", "sigma_U", "pdocoef", "sigma", "phi", "sigma_obs",
          "log_q[1]", "log_q[2]"),
  M3 = c("U_mu", "sigma_U", "pdocoef", "b", "phi", "sigma_obs",
          "log_q[1]", "log_q[2]"),
  M5 = c("U_mu", "sigma_U", "pdocoef", "beta", "K_log", "pred_coef",
          "phi", "sigma_obs", "log_q[1]", "log_q[2]")
)

# Model descriptions
model_desc <- c(
  M1 = "M1: Diagonal-Equal (baseline)",
  M2 = "M2: Distance-Decay Spatial",
  M3 = "M3: Gompertz DD + Spatial",
  M5 = "M5: DD + Spatial + Predators"
)

# Load all fits
fits <- list()
for (m in names(model_files)) {
  cat("Loading", m, "...\n")
  fits[[m]] <- readRDS(model_files[[m]])
}
cat("All models loaded.\n\n")


# ============================================================================
# HELPER: Extract obs-only indices for log_lik (Stan order: t-fast-j or j-fast-t?)
# Stan code iterates: for(t in 1:T) for(j in 1:J) idx++
# So index = (t-1)*J + j, i.e., j is the fast index
# ============================================================================

get_obs_indices <- function() {
  idx <- 0
  obs_idx <- c()
  for (t in 1:nYears) {
    for (j in 1:nSites) {
      idx <- idx + 1
      if (y_obs[t, j] == 1) {
        obs_idx <- c(obs_idx, idx)
      }
    }
  }
  obs_idx
}

obs_indices <- get_obs_indices()
cat("Observation indices:", length(obs_indices), "of", nYears * nSites, "\n\n")

# Map obs_indices back to (year, site) pairs
obs_year <- ((obs_indices - 1) %/% nSites) + 1
obs_site <- ((obs_indices - 1) %% nSites) + 1


# ############################################################################
# 1. TRACE PLOTS AND MIXING
# ############################################################################

write_report("============================================================")
write_report("  1. TRACE PLOTS AND MIXING")
write_report("============================================================")

for (m in names(fits)) {
  fit <- fits[[m]]
  kp <- key_params[[m]]

  write_report("")
  write_report("--- ", model_desc[m], " ---")

  pdf(file.path(diag_dir, paste0("trace_", m, ".pdf")),
      width = 10, height = 2.5 * length(kp))

  # Extract draws as array for bayesplot
  draws_arr <- as.array(fit, pars = kp)

  p <- mcmc_trace(draws_arr, facet_args = list(ncol = 1)) +
    ggtitle(paste("Trace plots:", model_desc[m])) +
    theme_pub(base_size = 8) +
    theme(strip.text = element_text(size = 7))
  print(p)

  dev.off()

  # Quick mixing assessment via n_eff / total samples
  summ <- summary(fit, pars = kp)$summary
  for (p_name in kp) {
    neff <- summ[p_name, "n_eff"]
    rhat <- summ[p_name, "Rhat"]
    total <- fit@sim$iter * fit@sim$chains - fit@sim$warmup * fit@sim$chains
    ratio <- neff / total
    status <- if (!is.na(rhat) && rhat > 1.01) "POOR" else if (ratio < 0.1) "LOW-ESS" else "OK"
    write_report(sprintf("  %-15s  n_eff=%6.0f  Rhat=%.4f  ESS/N=%.2f  [%s]",
                         p_name, neff, rhat, ratio, status))
  }
}


# ############################################################################
# 2. RHAT DISTRIBUTION
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  2. RHAT DISTRIBUTION")
write_report("============================================================")

pdf(file.path(diag_dir, "rhat_histograms.pdf"), width = 10, height = 8)
par(mfrow = c(2, 2))

for (m in names(fits)) {
  fit <- fits[[m]]
  all_summ <- summary(fit)$summary
  rhat_vals <- all_summ[, "Rhat"]
  rhat_vals <- rhat_vals[!is.na(rhat_vals)]

  # Histogram
  hist(rhat_vals, breaks = 50, main = paste("Rhat:", model_desc[m]),
       xlab = "Rhat", col = "steelblue", border = "white")
  abline(v = 1.01, col = "orange", lwd = 2, lty = 2)
  abline(v = 1.05, col = "red", lwd = 2, lty = 2)
  abline(v = 1.10, col = "darkred", lwd = 2, lty = 2)
  legend("topright", legend = c("1.01", "1.05", "1.10"),
         col = c("orange", "red", "darkred"), lty = 2, lwd = 2, cex = 0.8)

  # Report
  write_report("")
  write_report("--- ", model_desc[m], " ---")
  write_report(sprintf("  Total parameters: %d", length(rhat_vals)))
  write_report(sprintf("  Rhat range: [%.4f, %.4f]", min(rhat_vals), max(rhat_vals)))
  write_report(sprintf("  Rhat > 1.01: %d (%.1f%%)", sum(rhat_vals > 1.01),
                        100 * mean(rhat_vals > 1.01)))
  write_report(sprintf("  Rhat > 1.05: %d (%.1f%%)", sum(rhat_vals > 1.05),
                        100 * mean(rhat_vals > 1.05)))
  write_report(sprintf("  Rhat > 1.10: %d (%.1f%%)", sum(rhat_vals > 1.10),
                        100 * mean(rhat_vals > 1.10)))

  # Flag specific problematic parameters
  if (any(rhat_vals > 1.05)) {
    bad <- names(rhat_vals[rhat_vals > 1.05 & !is.na(rhat_vals)])
    bad <- bad[!grepl("^(Z\\[|X\\[|Pc_mat\\[|epsilon\\[|delta_raw\\[|Pc_logit\\[|epsilon_raw\\[|log_lik\\[|Y_rep\\[|biomass_pred\\[|fishing_rate\\[|Omega\\[)", bad)]
    if (length(bad) > 0) {
      write_report("  FLAGGED (non-derived) with Rhat > 1.05:")
      for (b in bad[1:min(20, length(bad))]) {
        write_report(sprintf("    %-25s  Rhat=%.4f  n_eff=%.0f",
                             b, all_summ[b, "Rhat"], all_summ[b, "n_eff"]))
      }
    }
  }
}

dev.off()


# ############################################################################
# 3. EFFECTIVE SAMPLE SIZE (BULK + TAIL ESS)
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  3. EFFECTIVE SAMPLE SIZE (ESS)")
write_report("============================================================")

pdf(file.path(diag_dir, "ess_distributions.pdf"), width = 12, height = 8)
par(mfrow = c(2, 2))

for (m in names(fits)) {
  fit <- fits[[m]]
  all_summ <- summary(fit)$summary
  ess_vals <- all_summ[, "n_eff"]
  ess_vals <- ess_vals[!is.na(ess_vals) & is.finite(ess_vals)]

  hist(pmin(ess_vals, 5000), breaks = 50,
       main = paste("Bulk ESS:", model_desc[m]),
       xlab = "n_eff (capped at 5000)", col = "darkolivegreen3", border = "white")
  abline(v = 400, col = "red", lwd = 2, lty = 2)
  abline(v = 100, col = "darkred", lwd = 2, lty = 2)

  write_report("")
  write_report("--- ", model_desc[m], " ---")
  write_report(sprintf("  Min ESS: %.0f", min(ess_vals)))
  write_report(sprintf("  Median ESS: %.0f", median(ess_vals)))
  write_report(sprintf("  Mean ESS: %.0f", mean(ess_vals)))
  write_report(sprintf("  ESS < 100: %d (%.1f%%)", sum(ess_vals < 100),
                        100 * mean(ess_vals < 100)))
  write_report(sprintf("  ESS < 400: %d (%.1f%%)", sum(ess_vals < 400),
                        100 * mean(ess_vals < 400)))

  # Flag the worst offenders
  worst <- sort(ess_vals)[1:min(10, length(ess_vals))]
  worst_names <- names(sort(ess_vals))[1:min(10, length(ess_vals))]
  # Filter to non-derived params
  keep <- !grepl("^(Z\\[|X\\[|Pc_mat\\[|epsilon\\[|epsilon_raw\\[|log_lik\\[|Y_rep\\[|biomass_pred\\[|fishing_rate\\[|Omega\\[|Pc\\[|delta_raw\\[)", worst_names)
  if (any(keep)) {
    write_report("  Lowest ESS (key params):")
    for (i in which(keep)[1:min(5, sum(keep))]) {
      write_report(sprintf("    %-25s  n_eff=%.0f  Rhat=%.4f",
                           worst_names[i], worst[i],
                           all_summ[worst_names[i], "Rhat"]))
    }
  }
}

dev.off()


# ############################################################################
# 4. DIVERGENT TRANSITIONS
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  4. DIVERGENT TRANSITIONS")
write_report("============================================================")

pdf(file.path(diag_dir, "divergences.pdf"), width = 12, height = 10)
par(mfrow = c(2, 2))

for (m in names(fits)) {
  fit <- fits[[m]]
  sp <- get_sampler_params(fit, inc_warmup = FALSE)

  n_div <- sum(sapply(sp, function(x) sum(x[, "divergent__"])))
  n_tree <- sum(sapply(sp, function(x) sum(x[, "treedepth__"] >= fit@stan_args[[1]]$control$max_treedepth)))
  total_iter <- sum(sapply(sp, nrow))

  write_report("")
  write_report("--- ", model_desc[m], " ---")
  write_report(sprintf("  Divergent transitions: %d / %d (%.2f%%)",
                        n_div, total_iter, 100 * n_div / total_iter))
  write_report(sprintf("  Max treedepth hits: %d / %d (%.2f%%)",
                        n_tree, total_iter, 100 * n_tree / total_iter))

  if (n_div > 0) {
    write_report("  ** WARNING: Divergences detected — posterior may be biased **")

    # Plot divergent vs non-divergent in parameter space
    # Use lp__ vs first key param
    kp1 <- key_params[[m]][1]
    draws <- as.array(fit, pars = c(kp1, "lp__"))
    np <- nuts_params(fit)

    p <- mcmc_scatter(draws, pars = c(kp1, "lp__"), np = np,
                      np_style = scatter_style_np(div_color = "red", div_size = 1.5)) +
      ggtitle(paste(m, ": divergent vs non-divergent"))
    print(p)

  } else {
    write_report("  No divergences — CLEAN")
    plot.new()
    title(main = paste(m, ": No divergences"), col.main = "darkgreen")
  }
}

dev.off()


# ############################################################################
# 5. ENERGY DIAGNOSTICS (E-BFMI)
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  5. ENERGY DIAGNOSTICS (E-BFMI)")
write_report("============================================================")

for (m in names(fits)) {
  fit <- fits[[m]]
  sp <- get_sampler_params(fit, inc_warmup = FALSE)

  write_report("")
  write_report("--- ", model_desc[m], " ---")

  for (ch in seq_along(sp)) {
    energy <- sp[[ch]][, "energy__"]
    # E-BFMI = var(diff(energy)) / var(energy)
    de <- diff(energy)
    ebfmi <- var(de) / var(energy)

    status <- if (ebfmi < 0.2) "** CRITICAL **" else if (ebfmi < 0.3) "* WARNING *" else "OK"
    write_report(sprintf("  Chain %d: E-BFMI = %.4f  [%s]", ch, ebfmi, status))
  }
}


# ############################################################################
# 6. POSTERIOR PREDICTIVE CHECKS
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  6. POSTERIOR PREDICTIVE CHECKS")
write_report("============================================================")

# Key sites for detailed PPC
key_site_names <- c("Juan Perez Sound", "Skincuttle Inlet", "Laskeek Bay")
key_site_idx <- match(key_site_names, site_names)

cat("Key sites for PPC:\n")
for (i in seq_along(key_site_names)) {
  cat(sprintf("  %s -> index %d\n", key_site_names[i], key_site_idx[i]))
}

for (m in names(fits)) {
  fit <- fits[[m]]
  write_report("")
  write_report("--- ", model_desc[m], " ---")

  # Extract Y_rep (posterior predictive)
  Y_rep <- rstan::extract(fit, "Y_rep")$Y_rep  # [n_draws, nYears, nSites]
  n_draws <- dim(Y_rep)[1]

  # Extract predicted X + log_q for each obs
  X_draws <- rstan::extract(fit, "X")$X  # [n_draws, nYears, nSites]

  if (m == "M1") {
    log_q_draws <- rstan::extract(fit, "log_q")$log_q  # [n_draws, 2]
  } else {
    log_q_draws <- rstan::extract(fit, "log_q")$log_q  # [n_draws, 2]
  }

  # ---- 6a. Overlay histograms: observed vs Y_rep ----
  pdf(file.path(diag_dir, paste0("ppc_overlay_", m, ".pdf")), width = 10, height = 6)

  # Collect observed Y values
  y_observed <- Y_raw[y_obs == 1]

  # Sample 100 posterior draws for overlay
  draw_idx <- sample(n_draws, min(100, n_draws))
  y_rep_samples <- matrix(NA, nrow = length(draw_idx), ncol = length(y_observed))

  obs_count <- 0
  for (t in 1:nYears) {
    for (j in 1:nSites) {
      if (y_obs[t, j] == 1) {
        obs_count <- obs_count + 1
        y_rep_samples[, obs_count] <- Y_rep[draw_idx, t, j]
      }
    }
  }

  # bayesplot ppc_dens_overlay
  p <- ppc_dens_overlay(y_observed, y_rep_samples[1:min(50, nrow(y_rep_samples)), ]) +
    ggtitle(paste("PPC density overlay:", model_desc[m])) +
    theme_pub(base_size = 10)
  print(p)

  dev.off()

  # ---- 6b. Site-specific time series: observed vs predicted ----
  pdf(file.path(diag_dir, paste0("ppc_timeseries_", m, ".pdf")), width = 12, height = 10)

  par(mfrow = c(3, 1), mar = c(4, 4, 3, 1))

  for (s in seq_along(key_site_idx)) {
    j <- key_site_idx[s]
    sname <- key_site_names[s]

    # Posterior mean and 90% CI of predicted Y
    y_pred_mean <- apply(Y_rep[, , j], 2, mean)
    y_pred_lo   <- apply(Y_rep[, , j], 2, quantile, 0.05)
    y_pred_hi   <- apply(Y_rep[, , j], 2, quantile, 0.95)

    y_range <- range(c(Y_raw[, j], y_pred_lo, y_pred_hi), na.rm = TRUE)

    plot(years, y_pred_mean, type = "l", col = "steelblue", lwd = 2,
         ylim = y_range, xlab = "Year", ylab = "log(Spawn Index)",
         main = paste(m, ":", sname))
    polygon(c(years, rev(years)),
            c(y_pred_lo, rev(y_pred_hi)),
            col = adjustcolor("steelblue", alpha.f = 0.2), border = NA)
    points(years, Y_raw[, j], pch = 16, col = "black", cex = 0.8)
    legend("topright", legend = c("Observed", "Predicted (90% CI)"),
           col = c("black", "steelblue"), pch = c(16, NA), lwd = c(NA, 2),
           fill = c(NA, adjustcolor("steelblue", 0.2)),
           border = c(NA, NA), cex = 0.8, bty = "n")
  }

  dev.off()

  # ---- 6c. Observed vs predicted scatter ----
  pdf(file.path(diag_dir, paste0("ppc_scatter_", m, ".pdf")), width = 8, height = 8)

  # Posterior mean of Y_rep for each obs
  y_pred_obs <- numeric(sum(y_obs))
  y_obs_vals <- numeric(sum(y_obs))
  site_labels <- character(sum(y_obs))
  year_labels <- numeric(sum(y_obs))
  idx <- 0
  for (t in 1:nYears) {
    for (j in 1:nSites) {
      if (y_obs[t, j] == 1) {
        idx <- idx + 1
        y_pred_obs[idx] <- mean(Y_rep[, t, j])
        y_obs_vals[idx] <- Y_raw[t, j]
        site_labels[idx] <- site_names[j]
        year_labels[idx] <- years[t]
      }
    }
  }

  scatter_df <- data.frame(
    observed = y_obs_vals,
    predicted = y_pred_obs,
    site = site_labels,
    year = year_labels
  )

  p <- ggplot(scatter_df, aes(x = observed, y = predicted)) +
    geom_abline(slope = 1, intercept = 0, lty = 2, color = "grey50") +
    geom_point(aes(color = site), alpha = 0.6, size = 1.5) +
    labs(title = paste("Observed vs Predicted:", model_desc[m]),
         x = "Observed log(Spawn Index)",
         y = "Predicted log(Spawn Index) [posterior mean]") +
    theme_pub(base_size = 10) +
    theme(legend.text = element_text(size = 6))
  print(p)

  dev.off()

  # Summary stats
  rmse <- sqrt(mean((y_pred_obs - y_obs_vals)^2))
  cor_val <- cor(y_pred_obs, y_obs_vals)
  bias <- mean(y_pred_obs - y_obs_vals)

  write_report(sprintf("  RMSE: %.4f", rmse))
  write_report(sprintf("  Correlation: %.4f", cor_val))
  write_report(sprintf("  Bias: %.4f", bias))
}


# ############################################################################
# 7. RESIDUAL ANALYSIS
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  7. RESIDUAL ANALYSIS")
write_report("============================================================")

for (m in names(fits)) {
  fit <- fits[[m]]
  Y_rep <- rstan::extract(fit, "Y_rep")$Y_rep

  write_report("")
  write_report("--- ", model_desc[m], " ---")

  # Compute posterior mean predicted Y
  Y_pred_mean <- apply(Y_rep, c(2, 3), mean)

  # Residuals: observed - predicted (only where observed)
  resid_mat <- matrix(NA, nrow = nYears, ncol = nSites)
  for (t in 1:nYears) {
    for (j in 1:nSites) {
      if (y_obs[t, j] == 1) {
        resid_mat[t, j] <- Y_raw[t, j] - Y_pred_mean[t, j]
      }
    }
  }

  pdf(file.path(diag_dir, paste0("residuals_", m, ".pdf")), width = 12, height = 10)
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))

  # 7a. Residuals vs time
  resid_by_year <- data.frame(
    year = rep(years, nSites),
    residual = as.vector(resid_mat),
    site = rep(site_names, each = nYears)
  )
  resid_by_year <- resid_by_year[!is.na(resid_by_year$residual), ]

  year_mean_resid <- aggregate(residual ~ year, data = resid_by_year, mean)

  plot(year_mean_resid$year, year_mean_resid$residual, type = "b",
       pch = 16, col = "steelblue",
       xlab = "Year", ylab = "Mean residual",
       main = paste(m, ": Residuals vs Time"))
  abline(h = 0, lty = 2, col = "grey50")
  # Add loess smoother
  if (nrow(year_mean_resid) > 10) {
    lo <- loess(residual ~ year, data = year_mean_resid, span = 0.3)
    lines(year_mean_resid$year, predict(lo), col = "red", lwd = 2)
  }

  # 7b. Residuals by site (boxplot)
  site_resids <- list()
  for (j in 1:nSites) {
    r <- resid_mat[, j]
    site_resids[[site_names[j]]] <- r[!is.na(r)]
  }
  boxplot(site_resids, las = 2, cex.axis = 0.6,
          main = paste(m, ": Residuals by Site"),
          ylab = "Residual", col = "lightyellow")
  abline(h = 0, lty = 2, col = "grey50")

  # 7c. Residuals vs predicted (heteroscedasticity)
  pred_vals <- Y_pred_mean[y_obs == 1]
  res_vals <- resid_mat[y_obs == 1]

  plot(pred_vals, res_vals, pch = 16, cex = 0.6, col = adjustcolor("black", 0.4),
       xlab = "Predicted log(Spawn Index)",
       ylab = "Residual",
       main = paste(m, ": Residuals vs Predicted"))
  abline(h = 0, lty = 2, col = "grey50")
  if (length(pred_vals) > 10) {
    lo <- loess(res_vals ~ pred_vals, span = 0.5)
    ord <- order(pred_vals)
    lines(pred_vals[ord], predict(lo)[ord], col = "red", lwd = 2)
  }

  # 7d. QQ plot
  qqnorm(res_vals, main = paste(m, ": QQ plot of residuals"),
         pch = 16, cex = 0.6, col = adjustcolor("steelblue", 0.6))
  qqline(res_vals, col = "red", lwd = 2)

  dev.off()

  # Summary stats
  write_report(sprintf("  Mean residual: %.4f", mean(res_vals)))
  write_report(sprintf("  SD residual: %.4f", sd(res_vals)))
  write_report(sprintf("  Skewness: %.4f", mean(((res_vals - mean(res_vals)) / sd(res_vals))^3)))
  write_report(sprintf("  Kurtosis: %.4f", mean(((res_vals - mean(res_vals)) / sd(res_vals))^4)))

  # Check for temporal trend
  year_cors <- cor(year_mean_resid$year, year_mean_resid$residual)
  write_report(sprintf("  Temporal trend (cor with year): %.4f", year_cors))

  # Check for site-specific bias
  site_means <- sapply(site_resids, mean)
  worst_bias_site <- names(which.max(abs(site_means)))
  write_report(sprintf("  Worst site bias: %s (mean resid = %.4f)",
                        worst_bias_site, site_means[worst_bias_site]))
}


# ############################################################################
# 8. LOO DIAGNOSTICS DEEP-DIVE
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  8. LOO DIAGNOSTICS DEEP-DIVE")
write_report("============================================================")

loo_results <- list()
waic_results <- list()

for (m in names(fits)) {
  fit <- fits[[m]]
  write_report("")
  write_report("--- ", model_desc[m], " ---")

  # Extract log_lik
  log_lik_all <- rstan::extract(fit, "log_lik")$log_lik  # [n_draws, N_years*N_sites]

  # Keep only observed
  log_lik_obs <- log_lik_all[, obs_indices]

  # Compute LOO
  tryCatch({
    loo_result <- loo(log_lik_obs)
    loo_results[[m]] <- loo_result

    write_report(sprintf("  LOOIC: %.1f (SE: %.1f)",
                          loo_result$estimates["looic", "Estimate"],
                          loo_result$estimates["looic", "SE"]))
    write_report(sprintf("  p_loo: %.1f",
                          loo_result$estimates["p_loo", "Estimate"]))
    write_report(sprintf("  elpd_loo: %.1f",
                          loo_result$estimates["elpd_loo", "Estimate"]))

    # Pareto k diagnostics
    pk <- loo_result$diagnostics$pareto_k
    write_report(sprintf("  Pareto k: min=%.3f, median=%.3f, max=%.3f",
                          min(pk), median(pk), max(pk)))
    write_report(sprintf("  Pareto k > 0.5: %d (%.1f%%)",
                          sum(pk > 0.5), 100 * mean(pk > 0.5)))
    write_report(sprintf("  Pareto k > 0.7: %d (%.1f%%)",
                          sum(pk > 0.7), 100 * mean(pk > 0.7)))
    write_report(sprintf("  Pareto k > 1.0: %d (%.1f%%)",
                          sum(pk > 1.0), 100 * mean(pk > 1.0)))

    # Identify problematic observations
    if (any(pk > 0.7)) {
      bad_k_idx <- which(pk > 0.7)
      write_report("  Observations with Pareto k > 0.7:")
      for (bi in bad_k_idx[1:min(15, length(bad_k_idx))]) {
        yr <- years[obs_year[bi]]
        st <- site_names[obs_site[bi]]
        yval <- Y_raw[obs_year[bi], obs_site[bi]]
        write_report(sprintf("    obs %d: year=%d, site=%s, Y=%.2f, k=%.3f",
                             bi, yr, st, yval, pk[bi]))
      }

      # Cluster analysis: are problematic obs in certain sites/years?
      bad_sites <- table(site_names[obs_site[bad_k_idx]])
      bad_years <- table(years[obs_year[bad_k_idx]])

      write_report("  Site clustering of high-k obs:")
      for (s in names(sort(bad_sites, decreasing = TRUE))) {
        write_report(sprintf("    %-30s: %d obs", s, bad_sites[s]))
      }

      write_report("  Year clustering (top 5):")
      top_years <- sort(bad_years, decreasing = TRUE)[1:min(5, length(bad_years))]
      for (y in names(top_years)) {
        write_report(sprintf("    %s: %d obs", y, top_years[y]))
      }
    }
  }, error = function(e) {
    write_report(sprintf("  LOO computation failed: %s", conditionMessage(e)))
  })

  # Compute WAIC
  tryCatch({
    waic_result <- waic(log_lik_obs)
    waic_results[[m]] <- waic_result

    write_report(sprintf("  WAIC: %.1f (SE: %.1f)",
                          waic_result$estimates["waic", "Estimate"],
                          waic_result$estimates["waic", "SE"]))
    write_report(sprintf("  p_waic: %.1f",
                          waic_result$estimates["p_waic", "Estimate"]))
  }, error = function(e) {
    write_report(sprintf("  WAIC computation failed: %s", conditionMessage(e)))
  })

  # Compare WAIC and LOO
  if (m %in% names(loo_results) && m %in% names(waic_results)) {
    loo_val <- loo_results[[m]]$estimates["looic", "Estimate"]
    waic_val <- waic_results[[m]]$estimates["waic", "Estimate"]
    diff_val <- abs(loo_val - waic_val)
    write_report(sprintf("  |LOOIC - WAIC| = %.1f %s",
                          diff_val,
                          if (diff_val > 10) "** DISAGREEMENT **" else "(agreement)"))
  }
}

# Pareto k plot for all models
pdf(file.path(diag_dir, "pareto_k_all_models.pdf"), width = 12, height = 10)
par(mfrow = c(2, 2))

for (m in names(loo_results)) {
  pk <- loo_results[[m]]$diagnostics$pareto_k
  plot(seq_along(pk), pk, pch = 16, cex = 0.5,
       col = ifelse(pk > 0.7, "red", ifelse(pk > 0.5, "orange", "steelblue")),
       xlab = "Observation index", ylab = "Pareto k",
       main = paste("Pareto k:", model_desc[m]),
       ylim = c(min(pk) - 0.1, max(pk) + 0.1))
  abline(h = 0.5, lty = 2, col = "orange")
  abline(h = 0.7, lty = 2, col = "red")
  abline(h = 1.0, lty = 2, col = "darkred")
  legend("topright", legend = c("OK (k<0.5)", "Marginal (0.5-0.7)", "Bad (k>0.7)"),
         col = c("steelblue", "orange", "red"), pch = 16, cex = 0.7)
}

dev.off()

# Pareto k by site for each model
pdf(file.path(diag_dir, "pareto_k_by_site.pdf"), width = 12, height = 10)
par(mfrow = c(2, 2))

for (m in names(loo_results)) {
  pk <- loo_results[[m]]$diagnostics$pareto_k
  pk_by_site <- split(pk, site_names[obs_site])

  boxplot(pk_by_site, las = 2, cex.axis = 0.55,
          main = paste("Pareto k by site:", m),
          ylab = "Pareto k", col = "lightyellow")
  abline(h = 0.7, lty = 2, col = "red")
  abline(h = 0.5, lty = 2, col = "orange")
}

dev.off()


# ############################################################################
# MODEL COMPARISON TABLE
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  MODEL COMPARISON")
write_report("============================================================")
write_report("")

if (length(loo_results) > 1) {
  # Build comparison
  write_report(sprintf("  %-10s  %10s  %10s  %10s  %10s  %6s",
                        "Model", "LOOIC", "SE", "WAIC", "p_loo", "k>0.7"))

  for (m in names(loo_results)) {
    looic <- loo_results[[m]]$estimates["looic", "Estimate"]
    se    <- loo_results[[m]]$estimates["looic", "SE"]
    ploo  <- loo_results[[m]]$estimates["p_loo", "Estimate"]
    waic_val <- if (m %in% names(waic_results)) {
      waic_results[[m]]$estimates["waic", "Estimate"]
    } else NA
    pk_bad <- sum(loo_results[[m]]$diagnostics$pareto_k > 0.7)

    write_report(sprintf("  %-10s  %10.1f  %10.1f  %10.1f  %10.1f  %6d",
                          m, looic, se, waic_val, ploo, pk_bad))
  }

  # Formal loo_compare
  write_report("")
  write_report("  loo_compare (elpd_diff):")

  tryCatch({
    comp <- loo_compare(loo_results)
    comp_txt <- capture.output(print(comp))
    for (line in comp_txt) write_report(paste("   ", line))
  }, error = function(e) {
    write_report(paste("  Could not run loo_compare:", conditionMessage(e)))
  })
}


# ############################################################################
# OVERALL VERDICT
# ############################################################################

write_report("")
write_report("============================================================")
write_report("  OVERALL DIAGNOSTIC VERDICT")
write_report("============================================================")
write_report("")

for (m in names(fits)) {
  fit <- fits[[m]]
  sp <- get_sampler_params(fit, inc_warmup = FALSE)
  all_summ <- summary(fit)$summary

  n_div <- sum(sapply(sp, function(x) sum(x[, "divergent__"])))
  rhat_vals <- all_summ[, "Rhat"]
  rhat_vals <- rhat_vals[!is.na(rhat_vals)]
  ess_vals <- all_summ[, "n_eff"]
  ess_vals <- ess_vals[!is.na(ess_vals) & is.finite(ess_vals)]
  max_rhat <- max(rhat_vals, na.rm = TRUE)
  min_ess <- min(ess_vals, na.rm = TRUE)

  issues <- character(0)
  if (n_div > 0) issues <- c(issues, sprintf("DIVERGENCES (%d)", n_div))
  if (max_rhat > 1.05) issues <- c(issues, sprintf("HIGH Rhat (max=%.3f)", max_rhat))
  if (max_rhat > 1.01 && max_rhat <= 1.05) issues <- c(issues, sprintf("MARGINAL Rhat (max=%.3f)", max_rhat))
  if (min_ess < 100) issues <- c(issues, sprintf("VERY LOW ESS (min=%.0f)", min_ess))
  if (min_ess < 400 && min_ess >= 100) issues <- c(issues, sprintf("LOW ESS (min=%.0f)", min_ess))

  n_tree <- sum(sapply(sp, function(x) sum(x[, "treedepth__"] >= fit@stan_args[[1]]$control$max_treedepth)))
  total_iter <- sum(sapply(sp, nrow))
  if (n_tree / total_iter > 0.1) issues <- c(issues, sprintf("HIGH TREEDEPTH (%.0f%%)", 100*n_tree/total_iter))

  if (m %in% names(loo_results)) {
    pk_bad <- sum(loo_results[[m]]$diagnostics$pareto_k > 0.7)
    if (pk_bad > 0) issues <- c(issues, sprintf("PARETO k>0.7 (%d obs)", pk_bad))
  }

  if (length(issues) == 0) {
    verdict <- "PASS"
  } else {
    verdict <- paste("ISSUES:", paste(issues, collapse = "; "))
  }

  write_report(sprintf("  %-45s  %s", model_desc[m], verdict))
}

write_report("")
write_report("============================================================")
write_report("  END OF DIAGNOSTIC REPORT")
write_report("============================================================")

close(report_con)
cat("\n\nDiagnostic report written to:", report_file, "\n")
cat("Diagnostic plots saved to:", diag_dir, "\n")
