# ============================================================================
# 03_fit_m1_v4.R — Fit Model M1 v4 (stable baseline + explicit detection layer)
# stier-2027-herring-metapopulation
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(posterior)
library(bayesplot)
library(loo)

rstan_options(auto_write = TRUE)
options(mc.cores = 4)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M1 v4: Stable baseline + threshold-aware detection layer\n")
cat(strrep("=", 60), "\n\n")

# ============================================================================
# 1. LOAD DATA
# ============================================================================

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")

v2_path <- file.path(data_dir, "jags_model_inputs_v2.RData")
if (file.exists(v2_path)) {
  load(v2_path)
} else {
  stop("v2 data not found. Run 02_data_merge.R first.")
}

# ============================================================================
# 2. PREPARE STAN DATA
# ============================================================================

stan_data <- list(
  N_years = jags_data$nYears,
  N_sites = jags_data$nSites,
  Y = jags_data$Y,
  Y_obs_flag = jags_data$Y_obs,
  Y_censored_flag = jags_data$Y_censored,
  pdo = jags_data$pdo,
  N_methods = 3,
  q_idx = jags_data$q_idx,
  N_catch = jags_data$nIndex,
  catch_yr = jags_data$INDEX[,1],
  catch_site = jags_data$INDEX[,2],
  log_catch = jags_data$ctab[jags_data$INDEX],
  prior_only = 0
)

# Replace -99/-999 in Y with 0.0 for Stan
stan_data$Y[stan_data$Y < -50] <- 0.0

surveyed_flag <- stan_data$Y_obs_flag + stan_data$Y_censored_flag
stopifnot(
  identical(dim(stan_data$Y), c(stan_data$N_years, stan_data$N_sites)),
  identical(dim(stan_data$Y_obs_flag), c(stan_data$N_years, stan_data$N_sites)),
  identical(dim(stan_data$Y_censored_flag), c(stan_data$N_years, stan_data$N_sites)),
  all(surveyed_flag <= 1L),
  sum(stan_data$Y_obs_flag) > 0,
  all(stan_data$q_idx %in% seq_len(stan_data$N_methods)),
  all(is.finite(stan_data$pdo)),
  all(is.finite(stan_data$log_catch)),
  all(is.finite(stan_data$Y[stan_data$Y_obs_flag == 1])),
  all(stan_data$Y[stan_data$Y_censored_flag == 1] == 0)
)

make_init_m1_v4 <- function() {
  list(
    Umu = 0,
    pdocoef = 0,
    sigma_proc = 0.7,
    mu_sigma_obs = 0.8,
    tau_sigma_obs = 0.1,
    sigma_obs = rep(0.8, stan_data$N_sites),
    nu_obs = 5,
    alpha_det = c(-0.5, -0.5, -0.5),
    beta_det = 1.0,
    log_q = c(-1.2, -0.2, 0.0),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    Z_init = rep(5, stan_data$N_sites),
    delta_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
  )
}

# ============================================================================
# 3. FIT MODEL
# ============================================================================

stan_file <- here("inst", "stan", "herring_metapop_m1_v4.stan")
fit <- stan(file = stan_file,
            data = stan_data,
            chains = 4,
            iter = 4500,
            warmup = 2000,
            cores = 4,
            refresh = 100,
            init = make_init_m1_v4,
            control = list(
              adapt_delta = 0.95,
              max_treedepth = 16,
              stepsize = 2.7e-4
            ),
            seed = 123)

# ============================================================================
# 4. SAVE RESULTS
# ============================================================================

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(fit, file.path(data_dir, "m1_v4_fit.rds"))
saveRDS(fit, file.path(out_dir, "fit_m1_v4.rds"))

# Save raw PSIS-LOO for auditability, then upgrade to moment matching while the
# compiled stanfit object is still live.
log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
r_eff <- relative_eff(exp(log_lik))
loo_m1_raw <- loo(log_lik, r_eff = r_eff)
saveRDS(loo_m1_raw, file.path(out_dir, "loo_m1_v4_raw_psis.rds"))

loo_m1 <- tryCatch(
  loo(fit, moment_match = TRUE, cores = 4),
  error = function(e) {
    warning("Moment matching failed; falling back to raw PSIS-LOO. ", conditionMessage(e))
    loo_m1_raw
  }
)
saveRDS(loo_m1, file.path(out_dir, "loo_m1_v4.rds"))

# Parameter summary
summ <- summarize_draws(fit)
write.csv(summ, file.path(proj_dir, "Output", "m1_v4_parameter_summary.csv"), row.names = FALSE)

cat("\n=== M1 v4 COMPLETE ===\n")
