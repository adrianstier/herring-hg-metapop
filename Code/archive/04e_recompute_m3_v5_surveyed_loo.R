# ============================================================================
# 04e_recompute_m3_v5_surveyed_loo.R
# Recompute m3_v5 LOO over all surveyed cells from saved posterior draws.
#
# The original m3_v5 generated quantities only stored positive-observation
# log_lik values even though the model target included censored surveyed zeros.
# This script repairs the current artifact without refitting. Future m3_v5 fits
# use the corrected Stan generated quantities directly.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(loo)

proj_dir <- here::here()
proc_dir <- file.path(proj_dir, "Data", "processed")
post_dir <- file.path(proj_dir, "Output", "posteriors")

load(file.path(proc_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(file.path(proc_dir, "m3_v5_fit.rds"))

post <- rstan::extract(
  fit,
  pars = c("X", "log_q", "sigma_obs", "nu_obs"),
  permuted = TRUE
)

surveyed_idx <- which(
  (jags_data$Y_obs + jags_data$Y_censored) == 1L,
  arr.ind = TRUE
)

n_draws <- length(post$nu_obs)
log_lik <- matrix(NA_real_, nrow = n_draws, ncol = nrow(surveyed_idx))
log_detection_threshold <- log(0.1)

for (i in seq_len(nrow(surveyed_idx))) {
  t <- surveyed_idx[i, "row"]
  j <- surveyed_idx[i, "col"]
  method <- jags_data$q_idx[t]

  mu <- post$X[, t, j] + post$log_q[, method]
  sigma <- post$sigma_obs[, j]
  nu <- post$nu_obs

  if (jags_data$Y_obs[t, j] == 1L) {
    y <- jags_data$Y[t, j]
    log_lik[, i] <- stats::dt((y - mu) / sigma, df = nu, log = TRUE) - log(sigma)
  } else {
    z <- (log_detection_threshold - mu) / sigma
    log_lik[, i] <- stats::pt(z, df = nu, log.p = TRUE)
  }
}

n_chains <- length(fit@sim$samples)
draws_per_chain <- n_draws / n_chains
if (draws_per_chain == floor(draws_per_chain)) {
  chain_id <- rep(seq_len(n_chains), each = draws_per_chain)
} else {
  chain_id <- rep(1L, n_draws)
}

r_eff <- relative_eff(exp(log_lik), chain_id = chain_id, cores = 1)
loo_m3_v5 <- loo(log_lik, r_eff = r_eff)

saveRDS(log_lik, file.path(post_dir, "log_lik_m3_v5_surveyed_cells.rds"))
saveRDS(loo_m3_v5, file.path(post_dir, "loo_m3_v5.rds"))

cat("Saved repaired m3_v5 surveyed-cell LOO:\n")
cat("  Output/posteriors/log_lik_m3_v5_surveyed_cells.rds\n")
cat("  Output/posteriors/loo_m3_v5.rds\n")
print(loo_m3_v5)
