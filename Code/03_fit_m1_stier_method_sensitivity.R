# ============================================================================
# 03_fit_m1_stier_method_sensitivity.R
# Fit Stier-aligned M1 sensitivity with three survey-method q terms.
#
# Builds directly from m1_stier_11:
#   - zero spawn records are treated as missing / ambiguous,
#   - positive spawn observations are the only spawn-index likelihood points,
#   - all 11 sections are fit,
#   - q_idx uses the maintained surface / mixed / dive era coding.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(posterior)
library(loo)

rstan_options(auto_write = TRUE)
options(mc.cores = 4)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M1_STIER_METHOD_SENSITIVITY: three-era q sensitivity\n")
cat(strrep("=", 60), "\n\n")

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")

v2_path <- file.path(data_dir, "jags_model_inputs_v2.RData")
if (file.exists(v2_path)) {
  load(v2_path)
} else {
  stop("v2 data not found. Run 02_data_merge.R first.")
}

q_idx_method <- jags_data$q_idx

stan_data <- list(
  N_years = jags_data$nYears,
  N_sites = jags_data$nSites,
  Y = jags_data$Y,
  Y_obs_flag = jags_data$Y_obs,
  pdo = jags_data$pdo,
  N_methods = 3L,
  q_idx = q_idx_method,
  N_catch = jags_data$nIndex,
  catch_yr = jags_data$INDEX[, 1],
  catch_site = jags_data$INDEX[, 2],
  log_catch = jags_data$ctab[jags_data$INDEX],
  prior_only = 0L
)

stan_data$Y[stan_data$Y_obs_flag == 0L] <- 0.0

stopifnot(
  identical(dim(stan_data$Y), c(stan_data$N_years, stan_data$N_sites)),
  identical(dim(stan_data$Y_obs_flag), c(stan_data$N_years, stan_data$N_sites)),
  sum(stan_data$Y_obs_flag) > 0,
  sum(jags_data$Y_censored) > 0,
  all(stan_data$q_idx %in% seq_len(stan_data$N_methods)),
  all(is.finite(stan_data$pdo)),
  all(is.finite(stan_data$log_catch)),
  all(is.finite(stan_data$Y[stan_data$Y_obs_flag == 1L]))
)

cat("Stier-aligned data choices:\n")
cat("  Positive spawn observations:", sum(stan_data$Y_obs_flag), "\n")
cat("  Ambiguous zero records skipped:", sum(jags_data$Y_censored), "\n")
cat("  Unsurveyed/missing cells skipped:", sum(jags_data$Y_missing), "\n")
cat("  q_idx = 1 surface years:", sum(stan_data$q_idx == 1L), "\n")
cat("  q_idx = 2 mixed transition years:", sum(stan_data$q_idx == 2L), "\n")
cat("  q_idx = 3 dive-dominant years:", sum(stan_data$q_idx == 3L), "\n")
cat("  Fitted sections:", stan_data$N_sites, "\n\n")

make_init_m1_stier_method_sensitivity <- function() {
  list(
    Umu = 0,
    pdocoef = 0,
    sigma_proc = 0.7,
    sigma_obs = 0.8,
    log_q = c(-1.2, -0.7, -0.2),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    Z_init = rep(5, stan_data$N_sites),
    delta_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
  )
}

stan_file <- here("inst", "stan", "herring_metapop_m1_stier_method_sensitivity.stan")
fit <- stan(
  file = stan_file,
  data = stan_data,
  chains = 4,
  iter = 4500,
  warmup = 2000,
  cores = 4,
  refresh = 100,
  init = make_init_m1_stier_method_sensitivity,
  control = list(adapt_delta = 0.95, max_treedepth = 15),
  seed = 126
)

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(fit, file.path(data_dir, "m1_stier_method_sensitivity_fit.rds"))
saveRDS(fit, file.path(out_dir, "fit_m1_stier_method_sensitivity.rds"))

log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
r_eff <- relative_eff(exp(log_lik))
loo_m1_method <- loo(log_lik, r_eff = r_eff)
saveRDS(loo_m1_method, file.path(out_dir, "loo_m1_stier_method_sensitivity.rds"))

summ <- summarize_draws(fit)
write.csv(
  summ,
  file.path(proj_dir, "Output", "m1_stier_method_sensitivity_parameter_summary.csv"),
  row.names = FALSE
)

cat("\n=== M1_STIER_METHOD_SENSITIVITY COMPLETE ===\n")
