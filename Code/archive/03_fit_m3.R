# ============================================================================
# 03_fit_m3.R — Fit Model M3: Global Gompertz density dependence
# stier-2027-herring-metapopulation
#
# M3 extends M2 (distance-decay spatial correlation) with a global Gompertz
# density-dependence parameter b, shared across all 11 spawning sections.
#
# Process model:
#   Z[t,j] = (1 + b) * X[t-1,j] + U[j] + pdocoef * pdo[t-1] + eps[t-1,j]
#
# When b = 0, this reduces to M2 (density-independent).
# When b < 0, growth decelerates at higher biomass (Gompertz regulation).
#
# This script:
#   1. Loads the model inputs from jags_model_inputs.RData
#   2. Computes the distance matrix from site coordinates (or loads from Excel)
#   3. Prepares the Stan data list
#   4. Compiles the Stan model via rstan
#   5. Fits the model via rstan::sampling
#   6. Runs MCMC diagnostics
#   7. Extracts and summarizes posteriors
#   8. Computes LOO-CV for model comparison
#
# USAGE:
#   source("Code/03_fit_m3.R")
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(posterior)
library(bayesplot)
library(loo)
library(tidybayes)
library(readxl)

# rstan settings
options(mc.cores = 4)
rstan_options(auto_write = TRUE)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M3: Global Gompertz Density Dependence\n")
cat(strrep("=", 60), "\n\n")

# ============================================================================
# 1. LOAD MODEL INPUTS
# ============================================================================

load(here("Data", "processed", "jags_model_inputs.RData"))

# Extract components from jags_data
logSHI    <- jags_data$Y
nYears    <- jags_data$nYears
nSites    <- jags_data$nSites
pdo_vec   <- jags_data$pdo
logcatch  <- jags_data$ctab
q_idx     <- jags_data$q_idx
years     <- jags_data$years
site_names <- jags_data$site_names

cat("Data loaded:", nYears, "years x", nSites, "sites\n")
cat("Years:", min(years), "-", max(years), "\n")
cat("Sites:", paste(site_names, collapse = ", "), "\n\n")

# ============================================================================
# 2. DISTANCE MATRIX
# ============================================================================

# Try loading from the pre-computed Excel file first
xlsx_path <- here("Data", "raw",
                  "Euclidean & effective distance matrices herring & Steller.xlsx")

if (file.exists(xlsx_path)) {
  cat("Loading effective distance matrix from Excel...\n")

  dist_raw <- read_xlsx(xlsx_path, sheet = "Herring Effective")

  # Extract section IDs from column names (strip "Id" prefix)
  col_ids <- as.integer(gsub("^Id", "", names(dist_raw)[-1]))
  row_ids <- as.integer(dist_raw[[1]])
  valid_rows <- !is.na(row_ids)
  row_ids <- row_ids[valid_rows]

  dist_full <- as.matrix(dist_raw[valid_rows, -1])
  rownames(dist_full) <- row_ids
  colnames(dist_full) <- col_ids

  # Subset to the 11 retained sections
  keep_str <- as.character(SECTIONS_KEEP)
  dist_sub <- dist_full[keep_str, keep_str]
  dist_sub <- apply(dist_sub, 2, as.numeric)

  # Convert metres to km
  dist_km <- dist_sub / 1000

  cat("  Distance matrix loaded: range [",
      round(min(dist_km[dist_km > 0]), 1), ",",
      round(max(dist_km), 1), "] km\n")

} else {
  cat("Excel distance file not found. Computing Euclidean distances from coordinates...\n")

  # Site coordinates (latitude, longitude) for the 11 retained sections
  # Order matches SECTIONS_KEEP: 1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25
  site_coords <- tibble(
    section = SECTIONS_KEEP,
    lat = c(52.406, 52.82, 53.35, 53.04, 52.16,
            53.98, 52.45, 53.24, 53.04, 52.80, 52.31),
    lon = c(-131.52, -132.05, -132.55, -132.43, -131.23,
            -132.17, -131.26, -131.98, -131.78, -131.74, -131.32)
  )

  # Haversine distance (km) between all pairs
  haversine_km <- function(lat1, lon1, lat2, lon2) {
    R <- 6371  # Earth radius in km
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

  # Ensure symmetry
  dist_km <- (dist_km + t(dist_km)) / 2
  rownames(dist_km) <- site_coords$section
  colnames(dist_km) <- site_coords$section

  cat("  Computed Haversine distances: range [",
      round(min(dist_km[dist_km > 0]), 1), ",",
      round(max(dist_km), 1), "] km\n")
}

# ============================================================================
# 3. PREPARE STAN DATA
# ============================================================================

# Observation indicator: 1 = observed, 0 = missing/NA
Y_obs <- matrix(as.integer(!is.na(logSHI)), nrow = nYears, ncol = nSites)

# Replace NAs with 0 for Stan (not used when Y_obs == 0)
Y_clean <- logSHI
Y_clean[is.na(Y_clean)] <- 0.0

# Catch indexing: (year, site) pairs where log(catch + 1) > 0
catch_positive <- which(logcatch > 0, arr.ind = TRUE)

stan_data <- list(
  N_years   = nYears,
  N_sites   = nSites,
  Y         = Y_clean,
  Y_obs     = Y_obs,
  pdo       = as.numeric(pdo_vec),
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
cat("  Distance range: [", round(min(dist_km[dist_km > 0]), 1), ",",
    round(max(dist_km), 1), "] km\n")

# ============================================================================
# 4. COMPILE AND FIT STAN MODEL
# ============================================================================

stan_file <- here("inst", "stan", "herring_metapop_m3_dd_global.stan")

cat("\nCompiling Stan model:", basename(stan_file), "\n")
cat("This may take a few minutes on first compile...\n")

cat("\n", strrep("-", 40), "\n")
cat("Fitting M3 with 4 chains, 1500 warmup + 2500 sampling...\n")
cat("  adapt_delta = 0.95, max_treedepth = 14\n")
cat(strrep("-", 40), "\n\n")

fit_m3 <- stan(
  file            = stan_file,
  data            = stan_data,
  chains          = 4L,
  warmup          = 1500L,
  iter            = 4000L,  # total = warmup + sampling
  cores           = 4L,
  seed            = 2027L,
  control         = list(adapt_delta = 0.95, max_treedepth = 14),
  refresh         = 500
)

# ============================================================================
# 5. MCMC DIAGNOSTICS
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" MCMC DIAGNOSTICS — M3 (Global Gompertz DD)\n")
cat(strrep("=", 60), "\n\n")

# Check for divergent transitions and other warnings
sp <- get_sampler_params(fit_m3, inc_warmup = FALSE)
n_divergent <- sum(sapply(sp, function(x) sum(x[, "divergent__"])))
n_treedepth <- sum(sapply(sp, function(x) sum(x[, "treedepth__"] >= 14)))

cat("Divergent transitions:", n_divergent, "\n")
cat("Max treedepth exceeded:", n_treedepth, "\n")

# Key parameter summary
cat("\n--- Key parameter estimates ---\n")
key_params <- c("b", "U_mu", "sigma_U", "pdocoef", "phi",
                "sigma_obs", "log_q[1]", "log_q[2]")
print(summary(fit_m3, pars = key_params)$summary)

# Rhat and ESS check across all parameters
all_summ <- summary(fit_m3)$summary
rhat_vals <- all_summ[, "Rhat"]
rhat_vals <- rhat_vals[!is.na(rhat_vals)]
ess_vals <- all_summ[, "n_eff"]
ess_vals <- ess_vals[!is.na(ess_vals)]

n_rhat_bad <- sum(rhat_vals > 1.01, na.rm = TRUE)
n_ess_bad  <- sum(ess_vals < 400, na.rm = TRUE)

cat("\nParameters with Rhat > 1.01:", n_rhat_bad, "of", length(rhat_vals), "\n")
cat("Parameters with n_eff < 400:", n_ess_bad, "of", length(ess_vals), "\n")
cat("Rhat range: [", round(min(rhat_vals, na.rm = TRUE), 4), ",",
    round(max(rhat_vals, na.rm = TRUE), 4), "]\n")

if (n_divergent == 0 && n_rhat_bad == 0 && n_ess_bad == 0) {
  cat("\nDiagnostics PASSED.\n")
} else {
  cat("\nDiagnostics NEED ATTENTION.\n")
  if (n_divergent > 0)   cat("  -> Consider increasing adapt_delta\n")
  if (n_rhat_bad > 0) cat("  -> Run longer chains\n")
  if (n_ess_bad > 0)  cat("  -> Increase iterations\n")
}

# ============================================================================
# 6. POSTERIOR SUMMARIES — DENSITY DEPENDENCE
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" DENSITY DEPENDENCE RESULTS\n")
cat(strrep("=", 60), "\n\n")

b_draws <- as.numeric(extract(fit_m3, "b")$b)
cat("Global Gompertz parameter b:\n")
cat("  Median:", round(median(b_draws), 4), "\n")
cat("  Mean:  ", round(mean(b_draws), 4), "\n")
cat("  SD:    ", round(sd(b_draws), 4), "\n")
cat("  90% CI: [", round(quantile(b_draws, 0.05), 4), ",",
    round(quantile(b_draws, 0.95), 4), "]\n")
cat("  95% CI: [", round(quantile(b_draws, 0.025), 4), ",",
    round(quantile(b_draws, 0.975), 4), "]\n")
cat("  Pr(b < 0):", round(mean(b_draws < 0), 4), "\n")

# Interpretation
cat("\nInterpretation:\n")
if (median(b_draws) < -0.05 && quantile(b_draws, 0.95) < 0) {
  cat("  Strong evidence for density dependence.\n")
  cat("  The 90% CI excludes zero.\n")
  cat("  Return rate:", round(-median(b_draws) * 100, 1),
      "% of deviation from equilibrium per year.\n")
} else if (median(b_draws) < 0) {
  cat("  Suggestive evidence for density dependence.\n")
  cat("  The posterior leans negative but the 90% CI includes zero.\n")
} else {
  cat("  No evidence for density dependence.\n")
  cat("  The posterior is centered near zero (density-independent).\n")
}

# Equilibrium biomass per site (if b < 0)
cat("\nImplied equilibrium log-biomass per site (X* = -U[j] / b):\n")
equil_draws <- extract(fit_m3, "X_equilibrium")$X_equilibrium

for (j in 1:nSites) {
  equil_j <- equil_draws[, j]
  equil_j <- equil_j[is.finite(equil_j)]  # drop Inf (when b ~ 0)
  if (length(equil_j) > 100) {
    cat(sprintf("  %-30s  X*: %6.2f  (biomass: %8.0f t)\n",
                site_names[j],
                median(equil_j),
                median(exp(equil_j))))
  } else {
    cat(sprintf("  %-30s  not estimable (b ~ 0)\n", site_names[j]))
  }
}

# ============================================================================
# 7. LOO-CV FOR MODEL COMPARISON
# ============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" LOO-CV — M3\n")
cat(strrep("=", 60), "\n\n")

log_lik <- extract_log_lik(fit_m3, parameter_name = "log_lik", merge_chains = FALSE)

# Compute relative effective sample sizes
r_eff <- relative_eff(exp(log_lik))

# Remove columns that are always 0 (unobserved Y)
# First merge chains for filtering
log_lik_merged <- extract_log_lik(fit_m3, parameter_name = "log_lik")
nonzero_cols <- which(colSums(abs(log_lik_merged)) > 0)

log_lik_obs <- log_lik_merged[, nonzero_cols]
r_eff_obs <- relative_eff(exp(log_lik[, , nonzero_cols]))

loo_m3 <- loo(log_lik_obs, r_eff = r_eff_obs)
print(loo_m3)

looic_m3 <- loo_m3$estimates["looic", "Estimate"]
cat("\nLOOIC:", round(looic_m3, 1), "\n")
cat("p_loo:", round(loo_m3$estimates["p_loo", "Estimate"], 1), "\n")

# Pareto k diagnostics
n_bad_k <- sum(loo_m3$diagnostics$pareto_k > 0.7)
cat("Pareto k > 0.7:", n_bad_k, "of", length(loo_m3$diagnostics$pareto_k), "\n")

# Compare with M1
looic_m1 <- 1949.7
delta_looic <- looic_m3 - looic_m1
cat("\n--- Model Comparison ---\n")
cat("M1 LOOIC:", looic_m1, "\n")
cat("M3 LOOIC:", round(looic_m3, 1), "\n")
cat("Delta LOOIC (M3 - M1):", round(delta_looic, 1), "\n")
if (delta_looic < -2) {
  cat("M3 fits better than M1 (density dependence improves fit).\n")
} else if (delta_looic > 2) {
  cat("M1 fits better than M3 (no benefit from density dependence).\n")
} else {
  cat("Models are comparable (within 2 LOOIC units).\n")
}

# ============================================================================
# 8. SAVE OUTPUTS
# ============================================================================

out_dir <- here("Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Save the fit object
saveRDS(fit_m3, here("Data", "processed", "m3_fit.rds"))
cat("\nFit saved to:", here("Data", "processed", "m3_fit.rds"), "\n")

# Also save to posteriors dir
saveRDS(fit_m3, file.path(out_dir, "fit_m3.rds"))
cat("Fit also saved to:", file.path(out_dir, "fit_m3.rds"), "\n")

# Save LOO result
saveRDS(loo_m3, file.path(out_dir, "loo_m3.rds"))
cat("LOO saved to:", file.path(out_dir, "loo_m3.rds"), "\n")

# Save key parameter summary to CSV
key_summ <- summary(fit_m3, pars = key_params)$summary
key_summ_df <- as.data.frame(key_summ)
key_summ_df$parameter <- rownames(key_summ)
key_summ_df <- key_summ_df |> select(parameter, everything())
write_csv(key_summ_df, here("Output", "m3_parameter_summary.csv"))
cat("Parameter summary saved to:", here("Output", "m3_parameter_summary.csv"), "\n")

cat("\n", strrep("=", 60), "\n")
cat(" M3 FITTING COMPLETE\n")
cat(strrep("=", 60), "\n")
