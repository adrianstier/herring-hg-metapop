# ============================================================================
# 03_fit_m2.R — Fit Model M2 (distance-decay spatial correlation)
# stier-2027-herring-metapopulation
#
# Self-contained script that:
#   1. Loads jags_model_inputs.RData (produced by 02_data_merge.R)
#   2. Loads the effective distance matrix from the Excel file
#   3. Prepares the Stan data list
#   4. Compiles and fits herring_metapop_m2_distance.stan
#   5. Runs MCMC diagnostics
#   6. Saves results
#
# Model M2 replaces the diagonal-equal process variance (M1) with a
# distance-decay spatial correlation:
#   M1: delta[t,j] ~ Normal(0, sigma^2)  independently
#   M2: delta[t, ] ~ MVN(0, Sigma)
#        where Sigma[i,j] = sigma^2 * exp(-phi * d[i,j])
#
# This encodes exponentially-decaying spatial correlation between spawning
# sites, reducing 55 free correlation parameters to a single decay rate phi.
#
# Requirements:
#   - cmdstanr (or rstan as fallback)
#   - readxl (for distance matrix)
#   - posterior, bayesplot, loo (for diagnostics)
# ============================================================================

library(tidyverse)
library(here)
library(readxl)

# ── Check for cmdstanr, fall back to rstan ──
use_cmdstanr <- requireNamespace("cmdstanr", quietly = TRUE)
if (use_cmdstanr) {
  library(cmdstanr)
  cat("Using cmdstanr backend\n")
} else {
  library(rstan)
  rstan_options(auto_write = TRUE)
  options(mc.cores = parallel::detectCores())
  cat("Using rstan backend (cmdstanr not available)\n")
}

library(posterior)
library(bayesplot)
library(loo)


# ============================================================================
# 1. LOAD DATA
# ============================================================================

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")

# Load the JAGS-format model inputs
load(file.path(data_dir, "jags_model_inputs.RData"))

cat("\n=== Data loaded ===\n")
cat("  Years:", jags_data$nYears, "(", min(jags_data$years), "-",
    max(jags_data$years), ")\n")
cat("  Sites:", jags_data$nSites, "\n")
cat("  Non-NA spawn obs:", sum(!is.na(jags_data$Y)), "of",
    prod(dim(jags_data$Y)), "\n")
cat("  Catch > 0 entries:", jags_data$nIndex, "\n")


# ============================================================================
# 2. LOAD DISTANCE MATRIX
# ============================================================================

xlsx_path <- file.path(proj_dir, "Data", "raw",
                       "Euclidean & effective distance matrices herring & Steller.xlsx")

stopifnot("Distance matrix Excel file not found" = file.exists(xlsx_path))

# Read the "Herring Effective" sheet (shortest water path, not straight-line)
dist_raw <- read_excel(xlsx_path, sheet = "Herring Effective")

# The Excel has 13 sections (rows 1:13): 1,2,3,4,5,6,11,12,21,22,23,24,25
# Columns: first column = row labels, then Id1, Id2, ..., Id25
# We need only the 11 retained sections (drop 4 and 11)

# Extract section IDs from first column
section_ids <- as.integer(dist_raw[[1]][1:13])

# Extract numeric distance matrix
id_cols <- paste0("Id", section_ids)
D_full <- as.matrix(dist_raw[1:13, id_cols])
D_full <- apply(D_full, 2, as.numeric)
rownames(D_full) <- section_ids
colnames(D_full) <- section_ids

# Subset to 11 retained sections
keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
keep_str <- as.character(keep_sections)
D_sub <- D_full[keep_str, keep_str]

# Convert from metres to km
D_km <- D_sub / 1000

# Enforce perfect symmetry (guard against floating-point issues)
D_km <- (D_km + t(D_km)) / 2

# Validation
stopifnot(
  "Distance matrix not square"       = nrow(D_km) == ncol(D_km),
  "Distance matrix wrong dimensions" = nrow(D_km) == jags_data$nSites,
  "Diagonal not zero"                = all(diag(D_km) == 0),
  "Matrix not symmetric"             = max(abs(D_km - t(D_km))) < 1e-6,
  "Negative distances"               = all(D_km >= 0)
)

max_dist <- max(D_km)

cat("\n=== Distance matrix (km) ===\n")
cat("  Dimensions:", nrow(D_km), "x", ncol(D_km), "\n")
cat("  Range: [", round(min(D_km[D_km > 0]), 1), ",",
    round(max_dist, 1), "] km\n")
cat("  Mean inter-site distance:", round(mean(D_km[upper.tri(D_km)]), 1), "km\n")
cat("  Max distance (for phi prior scaling):", round(max_dist, 1), "km\n")


# ============================================================================
# 3. PREPARE STAN DATA
# ============================================================================

# Observation indicator: 1 = observed, 0 = missing/NA
Y_obs <- matrix(as.integer(!is.na(jags_data$Y)),
                nrow = jags_data$nYears, ncol = jags_data$nSites)

# Replace NAs with 0 in Y for Stan (not used in likelihood when Y_obs == 0)
Y_clean <- jags_data$Y
Y_clean[is.na(Y_clean)] <- 0.0

# Catch indexing: (year, site) pairs where catch > 0
# jags_data$INDEX has 2 columns: row (year index), col (site index)
# jags_data$ctab has log(catch+1) values

stan_data <- list(
  N_years   = jags_data$nYears,
  N_sites   = jags_data$nSites,
  Y         = Y_clean,
  Y_obs     = Y_obs,
  pdo       = as.numeric(jags_data$pdo),
  q_idx     = as.array(jags_data$q_idx),

  # Distance matrix (km)
  dist_mat  = D_km,
  max_dist  = max_dist,

  # Catch indexing
  N_catch   = jags_data$nIndex,
  catch_row = as.array(jags_data$INDEX[, 1]),
  catch_col = as.array(jags_data$INDEX[, 2]),
  log_catch = as.numeric(jags_data$ctab[jags_data$INDEX]),

  # Prior predictive mode (0 = fit data, 1 = prior only)
  prior_only = 0L
)

# Verify the data list
cat("\n=== Stan data summary ===\n")
cat("  N_years:", stan_data$N_years, "\n")
cat("  N_sites:", stan_data$N_sites, "\n")
cat("  N_catch:", stan_data$N_catch, "\n")
cat("  Y non-zero obs:", sum(stan_data$Y_obs), "\n")
cat("  max_dist:", round(stan_data$max_dist, 1), "km\n")
cat("  phi prior SD (3/max_dist):", round(3 / stan_data$max_dist, 5), "\n")
cat("  Practical range at prior median phi:",
    round(3 / (0.6745 * 3 / stan_data$max_dist), 1), "km\n")


# ============================================================================
# 4. COMPILE AND FIT
# ============================================================================

stan_file <- file.path(proj_dir, "inst", "stan",
                       "herring_metapop_m2_distance.stan")
stopifnot("Stan file not found" = file.exists(stan_file))

cat("\n=== Compiling Stan model ===\n")
cat("  File:", basename(stan_file), "\n")

# ── Sampling settings ──
# State-space models need high adapt_delta to avoid divergences.
# max_treedepth = 12 allows deeper exploration of the posterior.
n_chains       <- 4L
n_warmup       <- 1000L
n_sampling     <- 1000L
adapt_delta    <- 0.95
max_treedepth  <- 13L
seed           <- 2027L

if (use_cmdstanr) {
  # ---- cmdstanr path ----
  mod <- cmdstan_model(
    stan_file = stan_file,
    dir       = dirname(stan_file)
  )

  cat("\n=== Sampling ===\n")
  cat("  Chains:", n_chains, "\n")
  cat("  Warmup:", n_warmup, "  Sampling:", n_sampling, "\n")
  cat("  adapt_delta:", adapt_delta, "  max_treedepth:", max_treedepth, "\n")

  fit <- mod$sample(
    data            = stan_data,
    chains          = n_chains,
    parallel_chains = min(n_chains, parallel::detectCores()),
    iter_warmup     = n_warmup,
    iter_sampling   = n_sampling,
    adapt_delta     = adapt_delta,
    max_treedepth   = max_treedepth,
    seed            = seed,
    refresh         = 200
  )

  cat("\n=== Sampling complete ===\n")

} else {
  # ---- rstan path ----
  fit <- stan(
    file    = stan_file,
    data    = stan_data,
    chains  = n_chains,
    warmup  = n_warmup,
    iter    = n_warmup + n_sampling,
    control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth),
    seed    = seed,
    refresh = 200
  )

  cat("\n=== Sampling complete ===\n")
}


# ============================================================================
# 5. MCMC DIAGNOSTICS
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" MCMC DIAGNOSTICS — Model M2 (distance-decay)\n")
cat(strrep("=", 60), "\n\n")

if (use_cmdstanr) {
  # cmdstanr diagnostics
  diag_summary <- fit$diagnostic_summary()
  n_divergent  <- sum(diag_summary$num_divergent)
  n_treedepth  <- sum(diag_summary$num_max_treedepth)
  ebfmi        <- diag_summary$ebfmi

  cat("Divergent transitions:", n_divergent, "\n")
  cat("Max treedepth exceeded:", n_treedepth, "\n")
  cat("E-BFMI per chain:", paste(round(ebfmi, 3), collapse = ", "), "\n")

  # Parameter summaries
  summ <- fit$summary()
  rhat_bad <- summ |> filter(rhat > 1.01)
  ess_bad  <- summ |> filter(ess_bulk < 400 | ess_tail < 400)

  cat("\nParameters with Rhat > 1.01:", nrow(rhat_bad), "\n")
  if (nrow(rhat_bad) > 0 && nrow(rhat_bad) <= 20) {
    print(rhat_bad |> select(variable, rhat, ess_bulk, ess_tail))
  }

  cat("Parameters with ESS < 400:", nrow(ess_bad), "\n")

  # Key parameter summaries
  cat("\n--- Key parameters ---\n")
  key_params <- c("sigma", "phi", "U_mu", "sigma_U", "pdocoef",
                  "sigma_obs", "log_q[1]", "log_q[2]")
  key_summ <- summ |> filter(variable %in% key_params)
  print(key_summ |> select(variable, mean, median, sd, q5, q95, rhat, ess_bulk))

  # Derived: practical range = 3/phi (distance at which correlation ~ 5%)
  phi_draws <- fit$draws("phi", format = "draws_matrix")
  practical_range <- 3 / phi_draws
  cat("\nPractical range (3/phi): median =",
      round(median(practical_range), 1), "km, 90% CI = [",
      round(quantile(practical_range, 0.05), 1), ",",
      round(quantile(practical_range, 0.95), 1), "] km\n")

} else {
  # rstan diagnostics
  key_pars <- c("sigma", "phi", "U_mu", "sigma_U", "pdocoef", "sigma_obs", "log_q")
  key_summ <- summary(fit, pars = key_pars)$summary
  cat("\n--- Key parameters ---\n")
  print(round(key_summ, 4))

  # Check for divergences and treedepth
  sampler_params <- get_sampler_params(fit, inc_warmup = FALSE)
  n_divergent <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
  n_treedepth <- sum(sapply(sampler_params, function(x) sum(x[, "treedepth__"] >= max_treedepth)))
  cat("\nDivergent transitions:", n_divergent, "\n")
  cat("Max treedepth exceeded:", n_treedepth, "\n")

  # Rhat summary across all parameters
  all_summ <- summary(fit)$summary
  rhat_vals <- all_summ[, "Rhat"]
  rhat_vals <- rhat_vals[!is.na(rhat_vals)]
  cat("\nRhat summary (all parameters):\n")
  cat("  Max Rhat:", round(max(rhat_vals), 4), "\n")
  cat("  Parameters with Rhat > 1.01:", sum(rhat_vals > 1.01), "\n")
  cat("  Parameters with Rhat > 1.05:", sum(rhat_vals > 1.05), "\n")
  cat("  Parameters with Rhat > 1.10:", sum(rhat_vals > 1.10), "\n")

  # n_eff summary
  neff_vals <- all_summ[, "n_eff"]
  neff_vals <- neff_vals[!is.na(neff_vals)]
  cat("\nn_eff summary:\n")
  cat("  Min n_eff:", round(min(neff_vals)), "\n")
  cat("  Median n_eff:", round(median(neff_vals)), "\n")
  cat("  Parameters with n_eff < 100:", sum(neff_vals < 100), "\n")
  cat("  Parameters with n_eff < 400:", sum(neff_vals < 400), "\n")

  # Practical range from phi
  phi_draws <- rstan::extract(fit, "phi")$phi
  practical_range <- 3 / phi_draws
  cat("\nPractical range (3/phi): median =",
      round(median(practical_range), 1), "km, 90% CI = [",
      round(quantile(practical_range, 0.05), 1), ",",
      round(quantile(practical_range, 0.95), 1), "] km\n")
}


# ============================================================================
# 6. LOO-CV (for model comparison with M1)
# ============================================================================

cat("\n=== LOO-CV ===\n")

if (use_cmdstanr) {
  log_lik <- fit$draws("log_lik", format = "draws_matrix")
} else {
  log_lik <- extract_log_lik(fit, parameter_name = "log_lik")
}

loo_m2 <- loo(log_lik)
print(loo_m2)

# ---- Compare with M1 ----
cat("\n=== M1 vs M2 comparison ===\n")
m1_fit_path <- file.path(data_dir, "m1_fit.rds")
if (file.exists(m1_fit_path)) {
  m1_fit <- readRDS(m1_fit_path)

  # Try to extract LOO from M1
  tryCatch({
    m1_log_lik <- extract_log_lik(m1_fit, parameter_name = "log_lik")
    loo_m1 <- loo(m1_log_lik)
    cat("\nM1 LOOIC:", round(loo_m1$estimates["looic", "Estimate"], 1), "\n")
    cat("M2 LOOIC:", round(loo_m2$estimates["looic", "Estimate"], 1), "\n")
    delta_looic <- loo_m2$estimates["looic", "Estimate"] - loo_m1$estimates["looic", "Estimate"]
    cat("Delta LOOIC (M2 - M1):", round(delta_looic, 1), "\n")
    if (delta_looic < 0) {
      cat("  => M2 (distance-decay) fits BETTER than M1 (independent)\n")
    } else {
      cat("  => M1 (independent) fits better or similar to M2\n")
    }

    # Formal comparison
    comp <- loo_compare(loo_m1, loo_m2)
    cat("\nloo_compare:\n")
    print(comp)
  }, error = function(e) {
    cat("Could not extract LOO from M1 fit:", conditionMessage(e), "\n")
    cat("M1 LOOIC (reported):", 1949.7, "\n")
    cat("M2 LOOIC:", round(loo_m2$estimates["looic", "Estimate"], 1), "\n")
    delta_looic <- loo_m2$estimates["looic", "Estimate"] - 1949.7
    cat("Delta LOOIC (M2 - M1):", round(delta_looic, 1), "\n")
  })
} else {
  cat("M1 fit not found at:", m1_fit_path, "\n")
  cat("M1 LOOIC (reported):", 1949.7, "\n")
  cat("M2 LOOIC:", round(loo_m2$estimates["looic", "Estimate"], 1), "\n")
}


# ============================================================================
# 7. SAVE RESULTS
# ============================================================================

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Save fit to Output/posteriors/
if (use_cmdstanr) {
  fit$save_object(file.path(out_dir, "fit_m2_distance.rds"))
} else {
  saveRDS(fit, file.path(out_dir, "fit_m2_distance.rds"))
}

# Also save to Data/processed/m2_fit.rds (per instructions)
saveRDS(fit, file.path(data_dir, "m2_fit.rds"))

# Save LOO result
saveRDS(loo_m2, file.path(out_dir, "loo_m2_distance.rds"))

# Save parameter summary to Output/m2_parameter_summary.csv
if (use_cmdstanr) {
  summ_all <- fit$summary()
  write_csv(summ_all, file.path(proj_dir, "Output", "m2_parameter_summary.csv"))
  write_csv(summ_all, file.path(out_dir, "summary_m2_distance.csv"))
} else {
  all_summ <- as.data.frame(summary(fit)$summary)
  all_summ$parameter <- rownames(all_summ)
  all_summ <- all_summ[, c("parameter", setdiff(names(all_summ), "parameter"))]
  write.csv(all_summ, file.path(proj_dir, "Output", "m2_parameter_summary.csv"),
            row.names = FALSE)
}

cat("\n=== Results saved ===\n")
cat("  ", file.path(out_dir, "fit_m2_distance.rds"), "\n")
cat("  ", file.path(data_dir, "m2_fit.rds"), "\n")
cat("  ", file.path(out_dir, "loo_m2_distance.rds"), "\n")
cat("  ", file.path(proj_dir, "Output", "m2_parameter_summary.csv"), "\n")


# ============================================================================
# 8. QUICK POSTERIOR VISUALIZATION
# ============================================================================

cat("\n=== Posterior summaries ===\n")

if (use_cmdstanr) {
  # Reconstructed correlation matrix (posterior mean)
  Omega_draws <- fit$draws("Omega", format = "draws_matrix")
  Omega_mean <- matrix(colMeans(Omega_draws), nrow = stan_data$N_sites)
  rownames(Omega_mean) <- jags_data$site_names
  colnames(Omega_mean) <- jags_data$site_names

  cat("\nPosterior mean correlation matrix (Omega):\n")
  print(round(Omega_mean, 3))
} else {
  # rstan: extract Omega posterior mean
  Omega_draws <- rstan::extract(fit, "Omega")$Omega
  Omega_mean <- apply(Omega_draws, c(2, 3), mean)
  if (exists("jags_data") && !is.null(jags_data$site_names)) {
    rownames(Omega_mean) <- jags_data$site_names
    colnames(Omega_mean) <- jags_data$site_names
  }
  cat("\nPosterior mean correlation matrix (Omega):\n")
  print(round(Omega_mean, 3))
}

cat("\n=== Done. ===\n")
