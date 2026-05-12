# ============================================================================
# 03_fit_m1_stier_obs_hier.R
# Fit Stier-aligned M1 with hierarchical observation calibration.
#
# Key choices:
#   - zero spawn records are treated as missing / ambiguous,
#   - positive spawn observations are the only spawn-index likelihood points,
#   - survey method uses the original Stier two-era surface/SCUBA split,
#   - section-specific observation error and surface-era extra variance are
#     tested before adding biological-driver process complexity.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(posterior)
library(loo)

rstan_options(auto_write = TRUE)

source(here("R", "00_setup.R"))
source(here("R", "cloud_fit_control.R"))

fit_control <- cloud_fit_control()
options(mc.cores = fit_control$cores)

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M1_STIER_OBS_HIER: section + surface observation calibration\n")
cat(strrep("=", 60), "\n\n")

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")

v2_path <- file.path(data_dir, "jags_model_inputs_v2.RData")
if (file.exists(v2_path)) {
  load(v2_path)
} else {
  stop("v2 data not found. Run 02_data_merge.R first.")
}

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)

stan_data <- list(
  N_years = jags_data$nYears,
  N_sites = jags_data$nSites,
  Y = jags_data$Y,
  Y_obs_flag = jags_data$Y_obs,
  pdo = jags_data$pdo,
  N_methods = 2L,
  q_idx = q_idx_stier,
  N_catch = jags_data$nIndex,
  catch_yr = jags_data$INDEX[, 1],
  catch_site = jags_data$INDEX[, 2],
  log_catch = jags_data$ctab[jags_data$INDEX],
  prior_only = 0L
)

# Replace all non-positive-observation sentinels with a harmless value. These
# cells are skipped by Y_obs_flag in the Stier-aligned likelihood.
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

cat("Stier-aligned observation-calibration data choices:\n")
cat("  Positive spawn observations:", sum(stan_data$Y_obs_flag), "\n")
cat("  Ambiguous zero records skipped:", sum(jags_data$Y_censored), "\n")
cat("  Unsurveyed/missing cells skipped:", sum(jags_data$Y_missing), "\n")
cat("  q_idx = 1 surface years:", sum(stan_data$q_idx == 1L), "\n")
cat("  q_idx = 2 SCUBA/dive years:", sum(stan_data$q_idx == 2L), "\n")
cat("  Fitted sections:", stan_data$N_sites, "\n\n")
print_fit_control(fit_control)

make_init_m1_stier_obs_hier <- function() {
  list(
    Umu = 0,
    pdocoef = 0,
    sigma_proc = 0.7,
    log_sigma_obs_mu = log(0.8),
    tau_log_sigma_obs = 0.15,
    log_sigma_obs_raw = rep(0, stan_data$N_sites),
    log_sigma_surface_extra = log(1.25),
    log_q = c(-1.2, -0.2),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    Z_init = rep(5, stan_data$N_sites),
    delta_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
  )
}

stan_file <- here("inst", "stan", "herring_metapop_m1_stier_obs_hier.stan")
fit <- stan(
  file = stan_file,
  data = stan_data,
  chains = fit_control$chains,
  iter = fit_control$iter,
  warmup = fit_control$warmup,
  cores = fit_control$cores,
  refresh = 100,
  init = make_init_m1_stier_obs_hier,
  control = list(adapt_delta = 0.96, max_treedepth = 15),
  seed = 129
)

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(fit, file.path(data_dir, "m1_stier_obs_hier_fit.rds"))
saveRDS(fit, file.path(out_dir, "fit_m1_stier_obs_hier.rds"))

if (!fit_control$skip_postfit) {
  log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
  r_eff <- relative_eff(exp(log_lik))
  loo_m1 <- loo(log_lik, r_eff = r_eff)
  saveRDS(loo_m1, file.path(out_dir, "loo_m1_stier_obs_hier.rds"))
} else {
  cat("Skipping LOO because HERRING_SKIP_POSTFIT/HERRING_SMOKE is active.\n")
}

summ <- summarize_draws(fit)
write.csv(
  summ,
  file.path(proj_dir, "Output", "m1_stier_obs_hier_parameter_summary.csv"),
  row.names = FALSE
)

cat("\n=== M1_STIER_OBS_HIER COMPLETE ===\n")
