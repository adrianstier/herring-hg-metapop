# =============================================================================
# 03_fit_m1.R — Fit M1 (Diagonal-Equal) herring metapopulation model in Stan
#
# Reproduces the baseline model from Stier et al. (2020), ported from JAGS.
# Uses non-centered parameterization for process errors to improve sampling.
#
# State-space model with:
#   - Process: Z[t,j] = X[t-1,j] + Umu + pdocoef*pdo[t-1] + sigma_proc*delta_raw[t-1,j]
#   - Fishing: X[t,j] = Z[t,j] + log(1 - Pc[t,j])
#   - Observation: Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
#   - Process noise: delta_raw ~ Normal(0, 1) (non-centered)
# =============================================================================

library(rstan)

# Parallel chains
options(mc.cores = 4)

# Stan settings for reproducibility
rstan_options(auto_write = TRUE)

# =============================================================================
# 1. Load data
# =============================================================================

cat("Loading data...\n")
load("Data/processed/jags_model_inputs.RData")

# Extract components
Y_raw    <- jags_data$Y          # 75 x 11, with NAs
nYears   <- jags_data$nYears     # 75
nSites   <- jags_data$nSites     # 11
pdo      <- jags_data$pdo        # length 75
ctab     <- jags_data$ctab       # 75 x 11, log(catch+1), 0 where no catch
INDEX    <- jags_data$INDEX      # 156 x 2 (row, col) where catch > 0
INDEX_z  <- jags_data$INDEX.zero # 669 x 2 (row, col) where catch == 0
nIndex   <- jags_data$nIndex     # 156
nIndex_z <- jags_data$nIndex.zero # 669
q_idx    <- jags_data$q_idx      # length 75 (1=surface, 2=dive)
years    <- jags_data$years
sites    <- jags_data$site_names

cat("Data dimensions: nYears =", nYears, ", nSites =", nSites, "\n")
cat("Observed Y cells:", sum(!is.na(Y_raw)), "/ Missing:", sum(is.na(Y_raw)), "\n")
cat("Catch > 0 pairs:", nIndex, "/ Catch == 0 pairs:", nIndex_z, "\n")

# =============================================================================
# 2. Prepare data for Stan
# =============================================================================

# Create observation indicator matrix (1 = observed, 0 = missing)
y_obs <- ifelse(is.na(Y_raw), 0L, 1L)

# Replace NAs in Y with 0.0 (Stan cannot handle NAs)
Y_stan <- Y_raw
Y_stan[is.na(Y_stan)] <- 0.0

# Extract catch > 0 data as vectors
catch_yr   <- as.integer(INDEX[, 1])
catch_site <- as.integer(INDEX[, 2])
log_catch  <- numeric(nIndex)
for (k in seq_len(nIndex)) {
  log_catch[k] <- ctab[catch_yr[k], catch_site[k]]
}

# Extract catch == 0 positions
zero_yr   <- as.integer(INDEX_z[, 1])
zero_site <- as.integer(INDEX_z[, 2])

# Assemble Stan data list
stan_data <- list(
  N_years    = nYears,
  N_sites    = nSites,
  Y          = Y_stan,
  y_obs      = y_obs,
  pdo        = as.numeric(pdo),
  q_idx      = as.integer(q_idx),
  N_catch    = nIndex,
  catch_yr   = catch_yr,
  catch_site = catch_site,
  log_catch  = log_catch,
  N_zero     = nIndex_z,
  zero_yr    = zero_yr,
  zero_site  = zero_site
)

# Verify dimensions
cat("\nStan data check:\n")
cat("  Y:", dim(stan_data$Y), "\n")
cat("  y_obs:", dim(stan_data$y_obs), "\n")
cat("  pdo:", length(stan_data$pdo), "\n")
cat("  q_idx:", length(stan_data$q_idx), "\n")
cat("  N_catch:", stan_data$N_catch, "\n")
cat("  N_zero:", stan_data$N_zero, "\n")

# =============================================================================
# 3. Compile Stan model
# =============================================================================

cat("\n--- Compiling Stan model ---\n")
stan_file <- "inst/stan/herring_metapop_m1.stan"
model <- stan_model(file = stan_file, verbose = TRUE)
cat("Compilation successful!\n")

# =============================================================================
# 4. SHORT test run (4 chains, 300 warmup, 300 sampling)
# =============================================================================

cat("\n--- SHORT test run (300 warmup, 300 sampling, 4 chains) ---\n")
fit_test <- sampling(
  model,
  data    = stan_data,
  chains  = 4,
  warmup  = 300,
  iter    = 600,
  thin    = 1,
  seed    = 42,
  control = list(
    adapt_delta   = 0.95,
    max_treedepth = 12
  )
)

# Check for basic issues
cat("\n--- Test run diagnostics ---\n")
test_summary <- summary(fit_test)$summary

# Check Rhat
rhat_vals <- test_summary[, "Rhat"]
rhat_vals <- rhat_vals[!is.na(rhat_vals)]
n_bad_rhat <- sum(rhat_vals > 1.05, na.rm = TRUE)
cat("Parameters with Rhat > 1.05:", n_bad_rhat, "/", length(rhat_vals), "\n")

# Check divergent transitions
sampler_params <- get_sampler_params(fit_test, inc_warmup = FALSE)
n_divergent <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
cat("Divergent transitions:", n_divergent, "\n")

# Check max treedepth
n_maxtree <- sum(sapply(sampler_params, function(x) sum(x[, "treedepth__"] >= 12)))
cat("Max treedepth hits:", n_maxtree, "\n")

# Print key parameters from test run
key_params <- c("Umu", "pdocoef", "sigma_proc", "sigma_obs", "log_q[1]", "log_q[2]")
cat("\nKey parameter estimates (test run):\n")
print(test_summary[key_params, c("mean", "sd", "2.5%", "97.5%", "n_eff", "Rhat")])

cat("\nTest run completed. Proceeding to medium run...\n")

# =============================================================================
# 5. MEDIUM run (4 chains, 1000 warmup, 1000 sampling)
#    Note: max_treedepth = 12 produces treedepth warnings but converges well
#    for key parameters. Increasing to 14 is much slower (~4x) without
#    materially improving posterior estimates.
# =============================================================================

cat("\n--- MEDIUM run (1000 warmup, 1000 sampling, 4 chains) ---\n")
fit_m1 <- sampling(
  model,
  data    = stan_data,
  chains  = 4,
  warmup  = 1000,
  iter    = 2000,
  thin    = 1,
  seed    = 42,
  control = list(
    adapt_delta   = 0.95,
    max_treedepth = 12
  )
)

# =============================================================================
# 6. Diagnostics
# =============================================================================

cat("\n======================================================\n")
cat("  M1 MEDIUM RUN DIAGNOSTICS\n")
cat("======================================================\n\n")

m1_summary <- summary(fit_m1)$summary

# Divergent transitions
sampler_params_m1 <- get_sampler_params(fit_m1, inc_warmup = FALSE)
n_divergent_m1 <- sum(sapply(sampler_params_m1, function(x) sum(x[, "divergent__"])))
cat("Divergent transitions:", n_divergent_m1, "\n")

# Max treedepth
n_maxtree_m1 <- sum(sapply(sampler_params_m1, function(x) sum(x[, "treedepth__"] >= 12)))
cat("Max treedepth hits:", n_maxtree_m1, "\n")

# Rhat summary
rhat_m1 <- m1_summary[, "Rhat"]
rhat_m1 <- rhat_m1[!is.na(rhat_m1)]
cat("\nRhat summary:\n")
cat("  Min:", min(rhat_m1, na.rm = TRUE), "\n")
cat("  Max:", max(rhat_m1, na.rm = TRUE), "\n")
cat("  Median:", median(rhat_m1, na.rm = TRUE), "\n")
cat("  Params with Rhat > 1.05:", sum(rhat_m1 > 1.05, na.rm = TRUE), "/", length(rhat_m1), "\n")
cat("  Params with Rhat > 1.10:", sum(rhat_m1 > 1.10, na.rm = TRUE), "/", length(rhat_m1), "\n")

# Flag problematic parameters
if (any(rhat_m1 > 1.05, na.rm = TRUE)) {
  bad_params <- names(rhat_m1)[rhat_m1 > 1.05 & !is.na(rhat_m1)]
  cat("\nParameters with Rhat > 1.05 (first 20):\n")
  print(m1_summary[bad_params[1:min(20, length(bad_params))],
                   c("mean", "sd", "n_eff", "Rhat")])
}

# Key parameter estimates
cat("\n--- Key Parameter Estimates ---\n")
print(m1_summary[key_params, c("mean", "sd", "2.5%", "97.5%", "n_eff", "Rhat")])

# Effective sample size summary
neff_m1 <- m1_summary[, "n_eff"]
neff_m1 <- neff_m1[!is.na(neff_m1)]
cat("\nEffective sample size summary:\n")
cat("  Min:", min(neff_m1, na.rm = TRUE), "\n")
cat("  Median:", median(neff_m1, na.rm = TRUE), "\n")
cat("  Params with n_eff < 100:", sum(neff_m1 < 100, na.rm = TRUE), "\n")

# WAIC and LOO-CV computation
cat("\n--- Model comparison metrics ---\n")
tryCatch({
  library(loo)

  # Extract log_lik
  log_lik <- extract_log_lik(fit_m1, parameter_name = "log_lik")

  # Identify which columns correspond to observed Y
  # Stan iterates (t,j) with j fastest, matching R's column-major for t(y_obs)
  obs_indices <- which(as.vector(t(y_obs)) == 1)
  log_lik_obs <- log_lik[, obs_indices]

  # WAIC
  waic_m1 <- waic(log_lik_obs)
  cat("\nWAIC:\n")
  print(waic_m1)

  # LOO-CV
  loo_m1 <- loo(log_lik_obs)
  cat("\nLOO-CV:\n")
  print(loo_m1)
}, error = function(e) {
  cat("Could not compute WAIC/LOO:", conditionMessage(e), "\n")
})

# =============================================================================
# 7. Save results
# =============================================================================

cat("\n--- Saving results ---\n")
dir.create("Data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(fit_m1, "Data/processed/m1_fit.rds")
cat("Stanfit object saved to Data/processed/m1_fit.rds\n")

# Save summary table
m1_summary_df <- as.data.frame(m1_summary)
dir.create("Output", recursive = TRUE, showWarnings = FALSE)
write.csv(m1_summary_df, "Output/m1_parameter_summary.csv")
cat("Parameter summary saved to Output/m1_parameter_summary.csv\n")

cat("\n======================================================\n")
cat("  M1 MODEL FITTING COMPLETE\n")
cat("======================================================\n")
