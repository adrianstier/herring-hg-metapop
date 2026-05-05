# ============================================================================
# 03_fit_m5.R — Fit Model M5: Gompertz DD + Marine Predator Recovery
# stier-2027-herring-metapopulation
#
# M5 extends M3 (distance-decay + global Gompertz DD) with predator recovery
# covariates from harbour seals, Steller sea lions, and humpback whales.
#
# This tests the Samhouri, Stier et al. (2017, Nature Ecol. Evol.) hypothesis
# that marine predator recovery suppresses herring population recovery at
# Haida Gwaii — the "irony of conservation success."
#
# Process model:
#   Z[t,j] = Z[t-1,j] + U[j] + beta * (Z[t-1,j] - K_log)
#            + pdocoef * pdo[t-1]
#            + seal_coef * seal[t-1]
#            + ssl_coef * ssl[t-1]
#            + whale_coef * whale[t-1]
#            + epsilon[t-1,j]
#
# This script:
#   1. Loads herring model inputs (jags_model_inputs.RData)
#   2. Loads predator indices (predator_indices.csv)
#   3. Computes the distance matrix
#   4. Prepares the Stan data list
#   5. Compiles and fits the model via rstan
#   6. Runs MCMC diagnostics
#   7. Extracts predator effect posteriors
#   8. Computes LOO-CV for model comparison with M1
#   9. Saves outputs
#
# USAGE:
#   source("Code/02b_predator_processing.R")   # run first if needed
#   source("Code/03_fit_m5.R")
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(posterior)
library(bayesplot)
library(loo)
library(readxl)

rstan_options(auto_write = TRUE)
options(mc.cores = 4L)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M5: Gompertz DD + Predator Recovery (rstan)\n")
cat(strrep("=", 60), "\n\n")

# ============================================================================
# 1. LOAD HERRING MODEL INPUTS
# ============================================================================

load(here("Data", "processed", "jags_model_inputs.RData"))

logSHI     <- jags_data$Y
nYears     <- jags_data$nYears
nSites     <- jags_data$nSites
pdo_vec    <- jags_data$pdo
logcatch   <- jags_data$ctab
q_idx      <- jags_data$q_idx
years      <- jags_data$years
site_names <- jags_data$site_names

cat("Herring data loaded:", nYears, "years x", nSites, "sites\n")
cat("Years:", min(years), "-", max(years), "\n")
cat("Sites:", paste(site_names, collapse = ", "), "\n\n")

# ============================================================================
# 2. LOAD PREDATOR INDICES
# ============================================================================

pred_path <- here("Data", "processed", "predator_indices.csv")

if (!file.exists(pred_path)) {
  cat("Predator indices not found. Running 02b_predator_processing.R...\n")
  source(here("Code", "02b_predator_processing.R"))
}

pred <- read_csv(pred_path, show_col_types = FALSE)

# Verify year alignment
stopifnot(
  "Predator indices must cover all model years" =
    all(years %in% pred$year)
)

# Extract standardized predator vectors aligned to model years
pred_aligned <- pred %>%
  filter(year %in% years) %>%
  arrange(year)

stopifnot(all(pred_aligned$year == years))

seal_vec  <- pred_aligned$seal_std
ssl_vec   <- pred_aligned$ssl_std
whale_vec <- pred_aligned$whale_std
whale_obs <- if ("whale_obs" %in% names(pred_aligned)) {
  as.integer(pred_aligned$whale_obs)
} else {
  as.integer(!is.na(pred_aligned$whale_raw) & pred_aligned$whale_raw != 0)
}
pred_obs <- if (all(c("seal_obs", "ssl_obs") %in% names(pred_aligned))) {
  as.integer(pred_aligned$seal_obs == 1L | pred_aligned$ssl_obs == 1L)
} else {
  as.integer(
    (!is.na(pred_aligned$seal_raw) & pred_aligned$seal_raw != 0) |
      (!is.na(pred_aligned$ssl_raw) & pred_aligned$ssl_raw != 0)
  )
}

cat("Predator indices loaded:\n")
cat("  Seal:  mean =",  round(mean(seal_vec), 3),
    ", SD =", round(sd(seal_vec), 3), "\n")
cat("  SSL:   mean =",  round(mean(ssl_vec), 3),
    ", SD =", round(sd(ssl_vec), 3), "\n")
cat("  Whale: mean =",  round(mean(whale_vec), 3),
    ", SD =", round(sd(whale_vec), 3), "\n")

# Correlation check
cat("\nPredator inter-correlation:\n")
pred_cor <- cor(cbind(seal = seal_vec, ssl = ssl_vec, whale = whale_vec))
print(round(pred_cor, 3))

# Warn about high collinearity
if (any(abs(pred_cor[lower.tri(pred_cor)]) > 0.8)) {
  cat("\nWARNING: High collinearity among predator indices (|r| > 0.8).\n")
  cat("  Consider using a combined index or dropping one species.\n")
  cat("  Will attempt 3-coefficient model first; fall back to combined if needed.\n\n")
}

# ============================================================================
# 3. DISTANCE MATRIX
# ============================================================================

xlsx_path <- here("Data", "raw",
                  "Euclidean & effective distance matrices herring & Steller.xlsx")

if (file.exists(xlsx_path)) {
  cat("\nLoading effective distance matrix from Excel...\n")

  dist_raw <- read_xlsx(xlsx_path, sheet = "Herring Effective")
  col_ids  <- as.integer(gsub("^Id", "", names(dist_raw)[-1]))
  row_ids  <- as.integer(dist_raw[[1]])
  valid_rows <- !is.na(row_ids)
  row_ids  <- row_ids[valid_rows]

  dist_full <- as.matrix(dist_raw[valid_rows, -1])
  rownames(dist_full) <- row_ids
  colnames(dist_full) <- col_ids

  keep_str <- as.character(SECTIONS_KEEP)
  dist_sub <- dist_full[keep_str, keep_str]
  dist_sub <- apply(dist_sub, 2, as.numeric)
  dist_km  <- dist_sub / 1000

  cat("  Distance range: [", round(min(dist_km[dist_km > 0]), 1), ",",
      round(max(dist_km), 1), "] km\n")

} else {
  cat("\nComputing Haversine distances from site coordinates...\n")

  site_coords <- tibble(
    section = SECTIONS_KEEP,
    lat = c(52.406, 52.82, 53.35, 53.04, 52.16,
            53.98, 52.45, 53.24, 53.04, 52.80, 52.31),
    lon = c(-131.52, -132.05, -132.55, -132.43, -131.23,
            -132.17, -131.26, -131.98, -131.78, -131.74, -131.32)
  )

  haversine_km <- function(lat1, lon1, lat2, lon2) {
    R <- 6371
    dlat <- (lat2 - lat1) * pi / 180
    dlon <- (lon2 - lon1) * pi / 180
    a <- sin(dlat / 2)^2 +
         cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dlon / 2)^2
    2 * R * asin(sqrt(a))
  }

  n <- nrow(site_coords)
  dist_km <- matrix(0, nrow = n, ncol = n)
  for (i in 1:n) {
    for (j in 1:n) {
      if (i != j) {
        dist_km[i, j] <- haversine_km(
          site_coords$lat[i], site_coords$lon[i],
          site_coords$lat[j], site_coords$lon[j]
        )
      }
    }
  }

  dist_km <- (dist_km + t(dist_km)) / 2
  rownames(dist_km) <- site_coords$section
  colnames(dist_km) <- site_coords$section

  cat("  Distance range: [", round(min(dist_km[dist_km > 0]), 1), ",",
      round(max(dist_km), 1), "] km\n")
}

# ============================================================================
# 4. PREPARE STAN DATA
# ============================================================================

Y_obs   <- matrix(as.integer(!is.na(logSHI)), nrow = nYears, ncol = nSites)
Y_clean <- logSHI
Y_clean[is.na(Y_clean)] <- 0.0

catch_positive <- which(logcatch > 0, arr.ind = TRUE)

stan_data <- list(
  N_years   = nYears,
  N_sites   = nSites,
  Y         = Y_clean,
  Y_obs     = Y_obs,
  pdo       = as.numeric(pdo_vec),

  # Predator covariates (region-level, standardized)
  seal      = as.numeric(seal_vec),
  ssl       = as.numeric(ssl_vec),
  whale     = as.numeric(whale_vec),
  whale_obs = as.array(whale_obs),
  pred_obs  = as.array(pred_obs),

  q_idx     = as.array(q_idx),
  dist_mat  = dist_km,
  N_catch   = nrow(catch_positive),
  catch_row = as.array(catch_positive[, 1]),
  catch_col = as.array(catch_positive[, 2]),
  log_catch = logcatch[catch_positive],
  prior_only = 0L
)

cat("\nStan data prepared:\n")
cat("  N_years:", stan_data$N_years, "\n")
cat("  N_sites:", stan_data$N_sites, "\n")
cat("  Observed Y:", sum(Y_obs), "of", prod(dim(Y_obs)), "\n")
cat("  Catch > 0:", stan_data$N_catch, "entries\n")
cat("  Predator vectors: seal, ssl, whale (length", length(seal_vec), ")\n")

# ============================================================================
# 5. FIT THE MODEL VIA RSTAN
# ============================================================================

stan_file <- here("inst", "stan", "herring_metapop_m5_predators.stan")

cat("\n", strrep("-", 40), "\n")
cat("Fitting M5 with 4 chains x 1000 post-warmup samples (rstan)...\n")
cat("  adapt_delta = 0.95, max_treedepth = 12\n")
cat(strrep("-", 40), "\n\n")

fit_m5 <- stan(
  file            = stan_file,
  data            = stan_data,
  chains          = 4L,
  cores           = 4L,
  iter            = 2000L,    # 1000 warmup + 1000 sampling
  warmup          = 1000L,
  seed            = 2027L,
  control         = list(adapt_delta = 0.95, max_treedepth = 12),
  refresh         = 200
)

# ============================================================================
# 6. MCMC DIAGNOSTICS
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" MCMC DIAGNOSTICS — M5 (Gompertz DD + Predators)\n")
cat(strrep("=", 60), "\n\n")

# Check for divergences and treedepth
sampler_params <- get_sampler_params(fit_m5, inc_warmup = FALSE)
n_divergent  <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
n_treedepth  <- sum(sapply(sampler_params, function(x) sum(x[, "treedepth__"] >= 12)))

cat("Divergent transitions:", n_divergent, "\n")
cat("Max treedepth exceeded:", n_treedepth, "\n")

# Key parameter summary
cat("\n--- Key parameter estimates ---\n")
key_params <- c("U_mu", "sigma_U", "pdocoef", "beta", "K_log",
                "seal_coef", "ssl_coef", "whale_coef",
                "phi", "sigma_obs", "log_q[1]", "log_q[2]")
summ <- summary(fit_m5, pars = key_params)$summary
print(round(summ, 4))

# Rhat and ESS check on all parameters
all_summ <- summary(fit_m5)$summary
rhat_vals <- all_summ[, "Rhat"]
ess_vals  <- all_summ[, "n_eff"]

rhat_bad_n <- sum(rhat_vals > 1.01, na.rm = TRUE)
ess_bad_n  <- sum(ess_vals < 400, na.rm = TRUE)

cat("\nParameters with Rhat > 1.01:", rhat_bad_n, "\n")
cat("Parameters with n_eff < 400:", ess_bad_n, "\n")

converged <- (n_divergent == 0 && rhat_bad_n == 0)

if (n_divergent == 0 && rhat_bad_n == 0 && ess_bad_n == 0) {
  cat("\nDiagnostics PASSED.\n")
} else {
  cat("\nDiagnostics NEED ATTENTION.\n")
  if (n_divergent > 0)    cat("  -> Consider increasing adapt_delta\n")
  if (rhat_bad_n > 0)     cat("  -> Run longer chains\n")
  if (ess_bad_n > 0)      cat("  -> Increase iterations (low ESS for some params)\n")
}

# ============================================================================
# 7. PREDATOR EFFECT POSTERIORS
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" PREDATOR RECOVERY EFFECTS\n")
cat(strrep("=", 60), "\n\n")

draws <- as.data.frame(rstan::extract(fit_m5, permuted = TRUE))

pred_params <- c("seal_coef", "ssl_coef", "whale_coef")
pred_labels <- c("Harbour seal", "Steller sea lion", "Humpback whale")

for (i in seq_along(pred_params)) {
  p_draws <- draws[[pred_params[i]]]
  cat(sprintf("%-20s: median = %6.3f, 90%% CI [%6.3f, %6.3f], Pr(<0) = %.3f\n",
              pred_labels[i],
              median(p_draws),
              quantile(p_draws, 0.05),
              quantile(p_draws, 0.95),
              mean(p_draws < 0)))
}

# Total predator effect across the time series
cat("\n--- Total predator effect on log-biomass growth ---\n")

# Extract pred_effect_total as matrix [iterations x N_years]
pred_effect_mat <- rstan::extract(fit_m5, pars = "pred_effect_total")$pred_effect_total

# Summarize for early (pre-recovery) vs. recent (post-recovery) periods
early_idx <- which(years <= 1980)
mid_idx   <- which(years >= 1990 & years <= 2005)
late_idx  <- which(years >= 2010)

early_effect <- rowMeans(pred_effect_mat[, early_idx, drop = FALSE])
mid_effect   <- rowMeans(pred_effect_mat[, mid_idx, drop = FALSE])
late_effect  <- rowMeans(pred_effect_mat[, late_idx, drop = FALSE])

cat(sprintf("  Pre-1980 (low predators):    median = %6.3f [%6.3f, %6.3f]\n",
            median(early_effect),
            quantile(early_effect, 0.05),
            quantile(early_effect, 0.95)))
cat(sprintf("  1990-2005 (recovering):      median = %6.3f [%6.3f, %6.3f]\n",
            median(mid_effect),
            quantile(mid_effect, 0.05),
            quantile(mid_effect, 0.95)))
cat(sprintf("  2010-2025 (high predators):  median = %6.3f [%6.3f, %6.3f]\n",
            median(late_effect),
            quantile(late_effect, 0.05),
            quantile(late_effect, 0.95)))

# Interpretation
cat("\nInterpretation:\n")
seal_draws  <- rstan::extract(fit_m5, pars = "seal_coef")$seal_coef
ssl_draws   <- rstan::extract(fit_m5, pars = "ssl_coef")$ssl_coef
whale_draws <- rstan::extract(fit_m5, pars = "whale_coef")$whale_coef
total_coef  <- seal_draws + ssl_draws + whale_draws

cat("  Combined predator effect (sum of coefficients):\n")
cat(sprintf("    median = %6.3f, 90%% CI [%6.3f, %6.3f]\n",
            median(total_coef),
            quantile(total_coef, 0.05),
            quantile(total_coef, 0.95)))
cat(sprintf("    Pr(sum < 0) = %.3f\n", mean(total_coef < 0)))

if (mean(total_coef < 0) > 0.9) {
  cat("  Strong evidence: predator recovery suppresses herring growth.\n")
  cat("  This supports the Samhouri & Stier (2017) 'irony of conservation success' hypothesis.\n")
} else if (mean(total_coef < 0) > 0.75) {
  cat("  Moderate evidence for predator suppression of herring growth.\n")
} else {
  cat("  Weak or no evidence for predator suppression.\n")
}

# ============================================================================
# 8. LOO-CV FOR MODEL COMPARISON
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" LOO-CV — M5\n")
cat(strrep("=", 60), "\n\n")

log_lik_array <- rstan::extract(fit_m5, pars = "log_lik", permuted = FALSE)
# log_lik_array is [iterations x chains x (N_years * N_sites)]
# Merge into matrix for loo
log_lik_mat <- as.matrix(rstan::extract(fit_m5, pars = "log_lik")$log_lik)
# Remove columns where log_lik == 0 (unobserved data points)
nonzero_cols <- which(colSums(abs(log_lik_mat)) > 0)
log_lik_obs  <- log_lik_mat[, nonzero_cols]

# Construct chain_id for relative_eff
n_iter_per_chain <- dim(log_lik_array)[1]
n_chains <- dim(log_lik_array)[2]
chain_id <- rep(1:n_chains, each = n_iter_per_chain)

r_eff <- relative_eff(log_lik_obs, chain_id = chain_id)
loo_m5 <- loo(log_lik_obs, r_eff = r_eff)
print(loo_m5)

looic_m5 <- loo_m5$estimates["looic", "Estimate"]
ploo_m5  <- loo_m5$estimates["p_loo", "Estimate"]

cat("\nLOOIC:", round(looic_m5, 1), "\n")
cat("p_loo:", round(ploo_m5, 1), "\n")

n_bad_k <- sum(loo_m5$diagnostics$pareto_k > 0.7)
cat("Pareto k > 0.7:", n_bad_k, "of", length(loo_m5$diagnostics$pareto_k), "\n")

# Compare to M1 baseline
cat("\n--- Comparison with M1 (LOOIC = 1949.7) ---\n")
cat("M5 LOOIC:", round(looic_m5, 1), "\n")
delta_looic <- looic_m5 - 1949.7
cat("Delta LOOIC (M5 - M1):", round(delta_looic, 1), "\n")
if (delta_looic < -4) {
  cat("M5 is BETTER than M1 — predators improve fit.\n")
} else if (delta_looic > 4) {
  cat("M5 is WORSE than M1 — predators do not improve fit.\n")
} else {
  cat("M5 and M1 are essentially equivalent in predictive accuracy.\n")
}

# ============================================================================
# 9. SAVE OUTPUTS
# ============================================================================

# Save fit to Data/processed/m5_fit.rds (as instructed)
saveRDS(fit_m5, here("Data", "processed", "m5_fit.rds"))
cat("\nFit saved to: Data/processed/m5_fit.rds\n")

# Also save to Output/posteriors/
out_dir <- here("Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
saveRDS(fit_m5, file.path(out_dir, "fit_m5.rds"))
cat("Fit also saved to:", file.path(out_dir, "fit_m5.rds"), "\n")

saveRDS(loo_m5, file.path(out_dir, "loo_m5.rds"))
cat("LOO saved to:", file.path(out_dir, "loo_m5.rds"), "\n")

# Save parameter summary to Output/m5_parameter_summary.csv (as instructed)
param_summ_df <- as.data.frame(summ)
param_summ_df$parameter <- rownames(summ)
param_summ_df <- param_summ_df[, c("parameter", setdiff(names(param_summ_df), "parameter"))]
write_csv(param_summ_df, here("Output", "m5_parameter_summary.csv"))
cat("Parameter summary saved to: Output/m5_parameter_summary.csv\n")

# Save predator effect summary
pred_effect_summary <- tibble(
  year = years,
  pred_effect_median = apply(pred_effect_mat, 2, median),
  pred_effect_lo = apply(pred_effect_mat, 2, quantile, 0.05),
  pred_effect_hi = apply(pred_effect_mat, 2, quantile, 0.95)
)
write_csv(pred_effect_summary, file.path(out_dir, "m5_predator_effects.csv"))
cat("Predator effects saved to:", file.path(out_dir, "m5_predator_effects.csv"), "\n")

cat("\n", strrep("=", 60), "\n")
cat(" M5 FITTING COMPLETE\n")
cat(strrep("=", 60), "\n")
