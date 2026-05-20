# ============================================================================
# 03_fit_m5_combined.R — Fit M5 with combined predator index (fallback)
#
# The 3-coefficient M5 had severe convergence issues (3997/4000 max treedepth
# exceedances, Rhat up to 1.67, ESS as low as 4) due to SSL-whale collinearity
# (r = 0.97). This script uses the pre-computed combined predator index
# (pred_combined from predator_indices.csv) for a single predator coefficient.
#
# Settings: 4 chains, 1000 warmup, 1000 sampling, adapt_delta=0.99,
#           max_treedepth=14
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(loo)
library(readxl)

rstan_options(auto_write = TRUE)
options(mc.cores = 4L)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M5-combined: Gompertz DD + Combined Predator Index\n")
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

# ============================================================================
# 2. LOAD PREDATOR INDICES (combined)
# ============================================================================

pred <- read_csv(here("Data", "processed", "predator_indices.csv"),
                 show_col_types = FALSE)

pred_aligned <- pred %>%
  filter(year %in% years) %>%
  arrange(year)

stopifnot(all(pred_aligned$year == years))

pred_combined_vec <- pred_aligned$pred_combined

cat("Combined predator index: mean =", round(mean(pred_combined_vec), 3),
    ", SD =", round(sd(pred_combined_vec), 3), "\n")

# ============================================================================
# 3. DISTANCE MATRIX
# ============================================================================

xlsx_path <- here("Data", "raw",
                  "Euclidean & effective distance matrices herring & Steller.xlsx")

if (file.exists(xlsx_path)) {
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
} else {
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
}

cat("Distance range: [", round(min(dist_km[dist_km > 0]), 1), ",",
    round(max(dist_km), 1), "] km\n")

# ============================================================================
# 4. PREPARE STAN DATA
# ============================================================================

Y_obs   <- matrix(as.integer(!is.na(logSHI)), nrow = nYears, ncol = nSites)
Y_clean <- logSHI
Y_clean[is.na(Y_clean)] <- 0.0

catch_positive <- which(logcatch > 0, arr.ind = TRUE)

stan_data <- list(
  N_years       = nYears,
  N_sites       = nSites,
  Y             = Y_clean,
  Y_obs         = Y_obs,
  pdo           = as.numeric(pdo_vec),
  pred_combined = as.numeric(pred_combined_vec),
  q_idx         = as.array(q_idx),
  dist_mat      = dist_km,
  N_catch       = nrow(catch_positive),
  catch_row     = as.array(catch_positive[, 1]),
  catch_col     = as.array(catch_positive[, 2]),
  log_catch     = logcatch[catch_positive],
  prior_only    = 0L
)

cat("Stan data prepared: N_years =", nYears, ", N_sites =", nSites, "\n")

# ============================================================================
# 5. FIT THE MODEL
# ============================================================================

stan_file <- here("inst", "stan", "herring_metapop_m5_combined.stan")

cat("\n", strrep("-", 40), "\n")
cat("Fitting M5-combined: 4 chains x 1000 samples\n")
cat("  adapt_delta = 0.99, max_treedepth = 14\n")
cat(strrep("-", 40), "\n\n")

fit_m5c <- stan(
  file    = stan_file,
  data    = stan_data,
  chains  = 4L,
  cores   = 4L,
  iter    = 2000L,
  warmup  = 1000L,
  seed    = 2027L,
  control = list(adapt_delta = 0.99, max_treedepth = 14),
  refresh = 200
)

# ============================================================================
# 6. DIAGNOSTICS
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" MCMC DIAGNOSTICS — M5-combined\n")
cat(strrep("=", 60), "\n\n")

sampler_params <- get_sampler_params(fit_m5c, inc_warmup = FALSE)
n_divergent  <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
n_treedepth  <- sum(sapply(sampler_params, function(x) sum(x[, "treedepth__"] >= 14)))

cat("Divergent transitions:", n_divergent, "\n")
cat("Max treedepth exceeded:", n_treedepth, "\n")

key_params <- c("U_mu", "sigma_U", "pdocoef", "beta", "K_log",
                "pred_coef", "phi", "sigma_obs", "log_q[1]", "log_q[2]")
summ <- summary(fit_m5c, pars = key_params)$summary
print(round(summ, 4))

all_summ <- summary(fit_m5c)$summary
rhat_vals <- all_summ[, "Rhat"]
ess_vals  <- all_summ[, "n_eff"]

rhat_bad_n <- sum(rhat_vals > 1.01, na.rm = TRUE)
ess_bad_n  <- sum(ess_vals < 400, na.rm = TRUE)

cat("\nParameters with Rhat > 1.01:", rhat_bad_n, "\n")
cat("Parameters with n_eff < 400:", ess_bad_n, "\n")

if (n_divergent == 0 && rhat_bad_n == 0 && ess_bad_n == 0) {
  cat("\nDiagnostics PASSED.\n")
} else {
  cat("\nDiagnostics NEED ATTENTION.\n")
  if (n_divergent > 0)    cat("  -> Divergent transitions present\n")
  if (n_treedepth > 0)    cat("  -> Max treedepth exceeded:", n_treedepth, "\n")
  if (rhat_bad_n > 0)     cat("  -> Rhat > 1.01 for", rhat_bad_n, "params\n")
  if (ess_bad_n > 0)      cat("  -> Low ESS for", ess_bad_n, "params\n")
}

# ============================================================================
# 7. PREDATOR EFFECT
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" COMBINED PREDATOR EFFECT\n")
cat(strrep("=", 60), "\n\n")

pred_coef_draws <- rstan::extract(fit_m5c, pars = "pred_coef")$pred_coef

cat(sprintf("pred_coef: median = %6.3f, 90%% CI [%6.3f, %6.3f], Pr(<0) = %.3f\n",
            median(pred_coef_draws),
            quantile(pred_coef_draws, 0.05),
            quantile(pred_coef_draws, 0.95),
            mean(pred_coef_draws < 0)))

# Period effects
pred_effect_mat <- rstan::extract(fit_m5c, pars = "pred_effect_total")$pred_effect_total

early_idx <- which(years <= 1980)
mid_idx   <- which(years >= 1990 & years <= 2005)
late_idx  <- which(years >= 2010)

early_effect <- rowMeans(pred_effect_mat[, early_idx, drop = FALSE])
mid_effect   <- rowMeans(pred_effect_mat[, mid_idx, drop = FALSE])
late_effect  <- rowMeans(pred_effect_mat[, late_idx, drop = FALSE])

cat(sprintf("\n  Pre-1980 (low predators):    median = %6.3f [%6.3f, %6.3f]\n",
            median(early_effect), quantile(early_effect, 0.05), quantile(early_effect, 0.95)))
cat(sprintf("  1990-2005 (recovering):      median = %6.3f [%6.3f, %6.3f]\n",
            median(mid_effect), quantile(mid_effect, 0.05), quantile(mid_effect, 0.95)))
cat(sprintf("  2010-2025 (high predators):  median = %6.3f [%6.3f, %6.3f]\n",
            median(late_effect), quantile(late_effect, 0.05), quantile(late_effect, 0.95)))

if (mean(pred_coef_draws < 0) > 0.9) {
  cat("\n  Strong evidence: combined predator recovery suppresses herring growth.\n")
} else if (mean(pred_coef_draws < 0) > 0.75) {
  cat("\n  Moderate evidence for predator suppression.\n")
} else {
  cat("\n  Weak or no evidence for predator suppression.\n")
}

# ============================================================================
# 8. LOO-CV
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" LOO-CV — M5-combined\n")
cat(strrep("=", 60), "\n\n")

log_lik_array <- rstan::extract(fit_m5c, pars = "log_lik", permuted = FALSE)
log_lik_mat <- as.matrix(rstan::extract(fit_m5c, pars = "log_lik")$log_lik)
nonzero_cols <- which(colSums(abs(log_lik_mat)) > 0)
log_lik_obs  <- log_lik_mat[, nonzero_cols]

n_iter_per_chain <- dim(log_lik_array)[1]
n_chains <- dim(log_lik_array)[2]
chain_id <- rep(1:n_chains, each = n_iter_per_chain)

r_eff <- relative_eff(log_lik_obs, chain_id = chain_id)
loo_m5c <- loo(log_lik_obs, r_eff = r_eff)
print(loo_m5c)

looic_m5c <- loo_m5c$estimates["looic", "Estimate"]
cat("\nLOOIC:", round(looic_m5c, 1), "\n")
cat("p_loo:", round(loo_m5c$estimates["p_loo", "Estimate"], 1), "\n")

n_bad_k <- sum(loo_m5c$diagnostics$pareto_k > 0.7)
cat("Pareto k > 0.7:", n_bad_k, "of", length(loo_m5c$diagnostics$pareto_k), "\n")

# Compare
cat("\n--- Model Comparison ---\n")
cat("M1 LOOIC:         1949.7\n")
cat("M5 (3-pred) LOOIC: 2075.1 (convergence issues)\n")
cat("M5-combined LOOIC:", round(looic_m5c, 1), "\n")

delta <- looic_m5c - 1949.7
cat("Delta (M5c - M1):", round(delta, 1), "\n")
if (delta < -4) {
  cat("M5-combined is BETTER than M1.\n")
} else if (delta > 4) {
  cat("M5-combined is WORSE than M1.\n")
} else {
  cat("M5-combined and M1 are equivalent.\n")
}

# ============================================================================
# 9. SAVE OUTPUTS
# ============================================================================

# Keep the historical alias, but also save an explicit model-id artifact so
# cloud manifest checks can distinguish this branch from other M5 fits.
saveRDS(fit_m5c, here("Data", "processed", "m5_fit.rds"))
saveRDS(fit_m5c, here("Data", "processed", "m5_combined_fit.rds"))
cat("\nFit saved to: Data/processed/m5_fit.rds\n")
cat("Fit saved to: Data/processed/m5_combined_fit.rds\n")

out_dir <- here("Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
saveRDS(fit_m5c, file.path(out_dir, "fit_m5_combined.rds"))
saveRDS(loo_m5c, file.path(out_dir, "loo_m5_combined.rds"))

# Parameter summary
param_summ_df <- as.data.frame(summ)
param_summ_df$parameter <- rownames(summ)
param_summ_df <- param_summ_df[, c("parameter", setdiff(names(param_summ_df), "parameter"))]
write_csv(param_summ_df, here("Output", "m5_parameter_summary.csv"))
cat("Parameter summary saved to: Output/m5_parameter_summary.csv\n")

# Predator effects
pred_effect_summary <- tibble(
  year = years,
  pred_effect_median = apply(pred_effect_mat, 2, median),
  pred_effect_lo = apply(pred_effect_mat, 2, quantile, 0.05),
  pred_effect_hi = apply(pred_effect_mat, 2, quantile, 0.95)
)
write_csv(pred_effect_summary, file.path(out_dir, "m5_predator_effects.csv"))

cat("\n", strrep("=", 60), "\n")
cat(" M5-COMBINED FITTING COMPLETE\n")
cat(strrep("=", 60), "\n")
