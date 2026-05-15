# ============================================================================
# 03_fit_m5_stier_predator_demand_total.R
# Fit Stier-aligned M5 with total HG predator-demand covariate.
#
# Key choices:
#   - zero spawn records remain ambiguous / skipped,
#   - survey method uses the original Stier two-era split,
#   - predator effect enters as lagged annual total HG predator demand,
#   - demand is z(log1p(C_total_kt)), not consumption / observed spawn,
#   - age/size structure is held out of this branch.
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
cat(" MODEL M5_STIER_PREDATOR_DEMAND_TOTAL: Stier obs + HG predator demand\n")
cat(strrep("=", 60), "\n\n")

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
pred_dir <- file.path(data_dir, "predators")

v2_path <- file.path(data_dir, "jags_model_inputs_v2.RData")
if (file.exists(v2_path)) {
  load(v2_path)
} else {
  stop("v2 data not found. Run 02_data_merge.R first.")
}

pred_path <- file.path(pred_dir, "hg_predation_pressure_covariates.csv")
if (!file.exists(pred_path)) {
  stop(
    "Predator covariates not found at ", pred_path, ". ",
    "Run Code/02c_integrate_hg_predator_repo_products.R with PREDATOR_REPO_PATH ",
    "set to the pacific-herring-predators checkout."
  )
}

pred_covariates <- read_csv(pred_path, show_col_types = FALSE)

if (!"pred_demand_total_log_z" %in% names(pred_covariates)) {
  stop(
    "Predator covariates do not include pred_demand_total_log_z. ",
    "Rerun Code/02c_integrate_hg_predator_repo_products.R."
  )
}

pred_demand <- pred_covariates %>%
  select(year, pred_demand_total_log_z) %>%
  right_join(tibble(year = jags_data$years), by = "year") %>%
  arrange(year) %>%
  pull(pred_demand_total_log_z)

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)

stan_data <- list(
  N_years = jags_data$nYears,
  N_sites = jags_data$nSites,
  Y = jags_data$Y,
  Y_obs_flag = jags_data$Y_obs,
  pdo = jags_data$pdo,
  pred_demand = pred_demand,
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
  all(is.finite(stan_data$pred_demand)),
  all(is.finite(stan_data$log_catch)),
  all(is.finite(stan_data$Y[stan_data$Y_obs_flag == 1L]))
)

cat("Stier-aligned predator-demand data choices:\n")
cat("  Positive spawn observations:", sum(stan_data$Y_obs_flag), "\n")
cat("  Ambiguous zero records skipped:", sum(jags_data$Y_censored), "\n")
cat("  Unsurveyed/missing cells skipped:", sum(jags_data$Y_missing), "\n")
cat("  q_idx = 1 surface years:", sum(stan_data$q_idx == 1L), "\n")
cat("  q_idx = 2 SCUBA/dive years:", sum(stan_data$q_idx == 2L), "\n")
cat("  Predator-demand covariate range:", paste(round(range(stan_data$pred_demand), 3), collapse = " to "), "\n")
cat("  Fitted sections:", stan_data$N_sites, "\n\n")
print_fit_control(fit_control)

make_init_m5_stier_predator_demand_total <- function() {
  list(
    Umu = 0,
    pdocoef = 0,
    predcoef = 0,
    sigma_proc = 0.7,
    sigma_obs = 0.8,
    log_q = c(-1.2, -0.2),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    Z_init = rep(5, stan_data$N_sites),
    delta_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
  )
}

stan_file <- here("inst", "stan", "herring_metapop_m5_stier_predator_demand_total.stan")
fit <- stan(
  file = stan_file,
  data = stan_data,
  chains = fit_control$chains,
  iter = fit_control$iter,
  warmup = fit_control$warmup,
  cores = fit_control$cores,
  refresh = 100,
  init = make_init_m5_stier_predator_demand_total,
  control = list(adapt_delta = 0.96, max_treedepth = 15),
  seed = 152
)

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

artifact_suffix <- if (fit_control$smoke) "_smoke" else ""
saveRDS(fit, file.path(data_dir, paste0("m5_stier_predator_demand_total", artifact_suffix, "_fit.rds")))
saveRDS(fit, file.path(out_dir, paste0("fit_m5_stier_predator_demand_total", artifact_suffix, ".rds")))

if (!fit_control$skip_postfit) {
  log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
  r_eff <- relative_eff(exp(log_lik))
  loo_m5 <- loo(log_lik, r_eff = r_eff)
  saveRDS(loo_m5, file.path(out_dir, "loo_m5_stier_predator_demand_total.rds"))
} else {
  cat("Skipping LOO because HERRING_SKIP_POSTFIT/HERRING_SMOKE is active.\n")
}

summ <- summarize_draws(fit)
write.csv(
  summ,
  file.path(
    proj_dir,
    "Output",
    paste0("m5_stier_predator_demand_total", artifact_suffix, "_parameter_summary.csv")
  ),
  row.names = FALSE
)

cat("\n=== M5_STIER_PREDATOR_DEMAND_TOTAL COMPLETE ===\n")
