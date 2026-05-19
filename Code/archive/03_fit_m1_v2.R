# =============================================================================
# 03_fit_m1_v2.R — Fit M1v2 herring metapopulation model in Stan
#
# Updated baseline model with fixes:
#   C1: LOO computed on N_obs log_lik values only (no 0.0 contamination)
#   C2: max_treedepth=15, 2500 post-warmup samples for convergence
#   C4: Left-censored observation model for surveyed zeros
#   M1: Informative sigma_obs prior: normal(0.5, 0.3) T[0,]
#   M2: Student-t observation model (estimated nu_obs)
#
# Tries v2 data first (from data fix agent), falls back to original data
# with ALL zeros treated as censored.
# =============================================================================

library(rstan)
library(loo)

# Parallel chains
options(mc.cores = 4)
rstan_options(auto_write = TRUE)

# =============================================================================
# 1. Load data — try v2 first, fall back to original
# =============================================================================

cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("  Loading data\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n\n")

v2_path <- "Data/processed/jags_model_inputs_v2.RData"
v1_path <- "Data/processed/jags_model_inputs.RData"

if (file.exists(v2_path)) {
  cat("Loading v2 data (from data fix agent)...\n")
  load(v2_path)
  data_version <- "v2"
} else {
  cat("v2 data not available. Loading original data and constructing censored arrays...\n")
  load(v1_path)
  data_version <- "v1 (with censored zeros derived from raw survey data)"
}

# Extract common components from jags_data
nYears   <- jags_data$nYears     # 75
nSites   <- jags_data$nSites     # 11
pdo      <- jags_data$pdo        # length 75
ctab     <- jags_data$ctab       # 75 x 11, log(catch+1), 0 where no catch
INDEX    <- jags_data$INDEX       # N_catch x 2 (row, col) where catch > 0
INDEX_z  <- jags_data$INDEX.zero  # N_zero x 2 (row, col) where catch == 0
nIndex   <- jags_data$nIndex
nIndex_z <- jags_data$nIndex.zero
q_idx    <- jags_data$q_idx      # length 75 (1=surface, 2=dive)
years    <- jags_data$years
sites    <- jags_data$site_names

cat("Data dimensions: nYears =", nYears, ", nSites =", nSites, "\n")
cat("Data version:", data_version, "\n")

# =============================================================================
# 2. Build observation and censored indicator matrices
# =============================================================================

if (data_version == "v2") {
  # v2 data already provides Y_obs, Y_censored, Y_missing, N_obs, N_censored
  cat("\nUsing pre-computed observation/censored flags from v2 data...\n")

  Y_obs_flag     <- jags_data$Y_obs        # 75 x 11, 1 = positive obs
  Y_censored_flag <- jags_data$Y_censored  # 75 x 11, 1 = surveyed zero

  # Use logSHI for the Y matrix (has proper NAs, not -999)
  # logSHI has NAs for both censored zeros and truly missing
  Y_raw <- jags_data$logSHI

  N_obs      <- as.integer(jags_data$N_obs)
  N_censored <- as.integer(jags_data$N_censored)
  N_missing  <- nYears * nSites - N_obs - N_censored

} else {
  # Fall back: build from original data + raw survey
  cat("\nBuilding observation/censored flags from original data + raw survey...\n")

  Y_raw <- jags_data$Y  # 75 x 11, NAs for missing

  # Y_obs_flag: 1 = positive observation (non-NA, all non-NA values are positive)
  Y_obs_flag <- ifelse(is.na(Y_raw), 0L, 1L)

  # Create censored indicator from raw survey data
  raw_survey <- read.csv("Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv")
  if ("spawn_index_tonnes" %in% names(raw_survey) && !"SHI" %in% names(raw_survey)) {
    raw_survey$SHI <- raw_survey$spawn_index_tonnes
  }

  # Map model site indices to raw survey section numbers (drops sections 4 and 11)
  section_to_site <- c(
    "1"  = 1,   # Tasu Sound & Gowgaia Bay
    "2"  = 2,   # Port Louis
    "3"  = 3,   # Rennell Sound
    "5"  = 4,   # Englefield Bay
    "6"  = 5,   # Louscoone Inlet
    "12" = 6,   # Naden Harbour
    "21" = 7,   # Juan Perez Sound
    "22" = 8,   # Skidegate Inlet
    "23" = 9,   # Cumshewa Inlet
    "24" = 10,  # Laskeek Bay
    "25" = 11   # Skincuttle Inlet
  )

  Y_censored_flag <- matrix(0L, nrow = nYears, ncol = nSites)
  year_offset <- min(years) - 1  # 1950, so year 1951 -> row 1

  for (i in seq_len(nrow(raw_survey))) {
    sec_str <- as.character(raw_survey$section[i])
    if (sec_str %in% names(section_to_site)) {
      site_idx <- section_to_site[sec_str]
      yr <- raw_survey$year[i]
      yr_idx <- yr - year_offset

      if (yr_idx >= 1 && yr_idx <= nYears) {
        if (!is.na(raw_survey$SHI[i]) && raw_survey$SHI[i] == 0) {
          Y_censored_flag[yr_idx, site_idx] <- 1L
        }
      }
    }
  }

  # No cell should be both observed and censored
  overlap <- sum(Y_obs_flag == 1 & Y_censored_flag == 1)
  if (overlap > 0) {
    warning("Found ", overlap, " cells flagged as both observed AND censored! Fixing...")
    Y_censored_flag[Y_obs_flag == 1 & Y_censored_flag == 1] <- 0L
  }

  N_obs <- sum(Y_obs_flag)
  N_censored <- sum(Y_censored_flag)
  N_missing <- nYears * nSites - N_obs - N_censored
}

cat("\nObservation breakdown:\n")
cat("  Positive observations (Y_obs_flag = 1):", N_obs, "\n")
cat("  Censored zeros (Y_censored_flag = 1):", N_censored, "\n")
cat("  Truly missing (neither):", N_missing, "\n")
cat("  Total cells:", nYears * nSites, "\n")

# =============================================================================
# 3. Prepare Stan data list
# =============================================================================

# Replace NAs in Y with 0.0 (Stan cannot handle NAs)
Y_stan <- Y_raw
Y_stan[is.na(Y_stan)] <- 0.0
# Also replace -999 sentinel values (from v2 JAGS format) with 0.0
Y_stan[Y_stan < -900] <- 0.0

# Extract catch > 0 data
catch_yr   <- as.integer(INDEX[, 1])
catch_site <- as.integer(INDEX[, 2])
log_catch  <- numeric(nIndex)
for (k in seq_len(nIndex)) {
  log_catch[k] <- ctab[catch_yr[k], catch_site[k]]
}

# Extract catch == 0 positions
zero_yr   <- as.integer(INDEX_z[, 1])
zero_site <- as.integer(INDEX_z[, 2])

# Determine number of survey methods from q_idx
N_methods <- as.integer(max(q_idx))
cat("  N_methods (survey types):", N_methods, "\n")

stan_data <- list(
  N_years        = nYears,
  N_sites        = nSites,
  Y              = Y_stan,
  Y_obs_flag     = Y_obs_flag,
  Y_censored_flag = Y_censored_flag,
  pdo            = as.numeric(pdo),
  N_methods      = N_methods,
  q_idx          = as.integer(q_idx),
  N_catch        = nIndex,
  catch_yr       = catch_yr,
  catch_site     = catch_site,
  log_catch      = log_catch,
  N_zero         = nIndex_z,
  zero_yr        = zero_yr,
  zero_site      = zero_site
)

# Verify dimensions
cat("\nStan data check:\n")
cat("  Y:", dim(stan_data$Y), "\n")
cat("  Y_obs_flag:", dim(stan_data$Y_obs_flag), "\n")
cat("  Y_censored_flag:", dim(stan_data$Y_censored_flag), "\n")
cat("  pdo:", length(stan_data$pdo), "\n")
cat("  q_idx:", length(stan_data$q_idx), "\n")
cat("  N_catch:", stan_data$N_catch, "\n")
cat("  N_zero:", stan_data$N_zero, "\n")

# =============================================================================
# 4. Compile Stan model
# =============================================================================

cat("\n--- Compiling Stan model (M1 v2) ---\n")
stan_file <- "inst/stan/herring_metapop_m1_v2.stan"
model <- stan_model(file = stan_file, verbose = TRUE)
cat("Compilation successful!\n")

# =============================================================================
# 5. SHORT test run (300 warmup, 300 sampling)
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
    max_treedepth = 15
  )
)

# Quick diagnostics on test run
cat("\n--- Test run diagnostics ---\n")
test_summary <- summary(fit_test)$summary

log_q_params <- paste0("log_q[", seq_len(N_methods), "]")
key_params <- c("Umu", "pdocoef", "sigma_proc", "sigma_obs", "nu_obs",
                log_q_params)

rhat_vals <- test_summary[, "Rhat"]
rhat_vals <- rhat_vals[!is.na(rhat_vals)]
n_bad_rhat <- sum(rhat_vals > 1.05, na.rm = TRUE)
cat("Parameters with Rhat > 1.05:", n_bad_rhat, "/", length(rhat_vals), "\n")

sampler_params <- get_sampler_params(fit_test, inc_warmup = FALSE)
n_divergent <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
cat("Divergent transitions:", n_divergent, "\n")

n_maxtree <- sum(sapply(sampler_params, function(x) sum(x[, "treedepth__"] >= 15)))
cat("Max treedepth hits:", n_maxtree, "\n")

cat("\nKey parameter estimates (test run):\n")
print(test_summary[key_params, c("mean", "sd", "2.5%", "97.5%", "n_eff", "Rhat")])

cat("\nTest run completed. Proceeding to production run...\n")

# =============================================================================
# 6. PRODUCTION run (2000 warmup, 2500 sampling, 4 chains)
# =============================================================================

cat("\n--- PRODUCTION run (2000 warmup, 2500 sampling, 4 chains) ---\n")
cat("    max_treedepth = 15, adapt_delta = 0.95\n")
cat("    Total post-warmup samples: 4 x 2500 = 10000\n\n")

fit_m1_v2 <- sampling(
  model,
  data    = stan_data,
  chains  = 4,
  warmup  = 2000,
  iter    = 4500,  # 2000 warmup + 2500 sampling
  thin    = 1,
  seed    = 42,
  control = list(
    adapt_delta   = 0.95,
    max_treedepth = 15
  )
)

# =============================================================================
# 7. Full diagnostics
# =============================================================================

cat("\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("  M1v2 PRODUCTION RUN DIAGNOSTICS\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n\n")

m1v2_summary <- summary(fit_m1_v2)$summary

# --- Divergent transitions ---
sampler_params_v2 <- get_sampler_params(fit_m1_v2, inc_warmup = FALSE)
n_divergent_v2 <- sum(sapply(sampler_params_v2, function(x) sum(x[, "divergent__"])))
cat("Divergent transitions:", n_divergent_v2, "\n")

# --- Max treedepth ---
n_maxtree_v2 <- sum(sapply(sampler_params_v2, function(x) sum(x[, "treedepth__"] >= 15)))
cat("Max treedepth hits:", n_maxtree_v2, "\n")

# --- Rhat summary ---
rhat_v2 <- m1v2_summary[, "Rhat"]
rhat_v2 <- rhat_v2[!is.na(rhat_v2)]
cat("\nRhat summary:\n")
cat("  Min:", min(rhat_v2, na.rm = TRUE), "\n")
cat("  Max:", max(rhat_v2, na.rm = TRUE), "\n")
cat("  Median:", median(rhat_v2, na.rm = TRUE), "\n")
cat("  Params with Rhat > 1.01:", sum(rhat_v2 > 1.01, na.rm = TRUE), "/", length(rhat_v2), "\n")
cat("  Params with Rhat > 1.05:", sum(rhat_v2 > 1.05, na.rm = TRUE), "/", length(rhat_v2), "\n")
cat("  Params with Rhat > 1.10:", sum(rhat_v2 > 1.10, na.rm = TRUE), "/", length(rhat_v2), "\n")

# Flag problematic parameters
if (any(rhat_v2 > 1.05, na.rm = TRUE)) {
  bad_params <- names(rhat_v2)[rhat_v2 > 1.05 & !is.na(rhat_v2)]
  cat("\nParameters with Rhat > 1.05 (first 20):\n")
  print(m1v2_summary[bad_params[1:min(20, length(bad_params))],
                     c("mean", "sd", "n_eff", "Rhat")])
}

# --- Key parameter estimates ---
cat("\n--- Key Parameter Estimates ---\n")
print(m1v2_summary[key_params, c("mean", "sd", "2.5%", "97.5%", "n_eff", "Rhat")])

# --- nu_obs estimate ---
cat("\n--- Student-t degrees of freedom (nu_obs) ---\n")
cat("  Posterior mean:", m1v2_summary["nu_obs", "mean"], "\n")
cat("  Posterior SD:", m1v2_summary["nu_obs", "sd"], "\n")
cat("  95% CI: [", m1v2_summary["nu_obs", "2.5%"], ",",
    m1v2_summary["nu_obs", "97.5%"], "]\n")
cat("  ESS:", m1v2_summary["nu_obs", "n_eff"], "\n")
if (m1v2_summary["nu_obs", "mean"] < 10) {
  cat("  -> Heavy tails confirmed (nu < 10 suggests outliers in data)\n")
} else if (m1v2_summary["nu_obs", "mean"] < 30) {
  cat("  -> Moderate tails (nu 10-30)\n")
} else {
  cat("  -> Near-normal tails (nu > 30, Student-t approximates Normal)\n")
}

# --- sigma_obs comparison note ---
cat("\n--- sigma_obs under informative prior ---\n")
cat("  Prior: normal(0.5, 0.3) T[0,]\n")
cat("  Posterior mean:", m1v2_summary["sigma_obs", "mean"], "\n")
cat("  Posterior SD:", m1v2_summary["sigma_obs", "sd"], "\n")
cat("  95% CI: [", m1v2_summary["sigma_obs", "2.5%"], ",",
    m1v2_summary["sigma_obs", "97.5%"], "]\n")
cat("  (Compare to v1 which used half-t(3,0,2.5) vague prior)\n")

# --- Effective sample size summary ---
neff_v2 <- m1v2_summary[, "n_eff"]
neff_v2 <- neff_v2[!is.na(neff_v2)]
cat("\nEffective sample size summary:\n")
cat("  Min:", min(neff_v2, na.rm = TRUE), "\n")
cat("  Median:", median(neff_v2, na.rm = TRUE), "\n")
cat("  Params with n_eff < 100:", sum(neff_v2 < 100, na.rm = TRUE), "\n")
cat("  Params with n_eff < 400:", sum(neff_v2 < 400, na.rm = TRUE), "\n")

# Report the parameter with lowest ESS
min_ess_idx <- which.min(neff_v2)
cat("  Lowest ESS parameter:", names(neff_v2)[min_ess_idx],
    "=", round(neff_v2[min_ess_idx], 0), "\n")

# =============================================================================
# 8. LOO-CV (computed correctly on observed-only log_lik)
# =============================================================================

cat("\n--- LOO-CV and WAIC (observed data only, N_obs =", N_obs, ") ---\n")
tryCatch({
  # log_lik is already sized N_obs (no 0.0 contamination)
  log_lik <- extract_log_lik(fit_m1_v2, parameter_name = "log_lik")

  cat("  log_lik dimensions:", dim(log_lik), "\n")
  cat("  (Should be [n_samples x N_obs] = [10000 x", N_obs, "])\n")

  # Compute relative effective sample sizes for PSIS
  r_eff <- relative_eff(exp(log_lik), cores = 4)

  # LOO-CV
  loo_v2 <- loo(log_lik, r_eff = r_eff, cores = 4)
  cat("\nLOO-CV:\n")
  print(loo_v2)

  # WAIC
  waic_v2 <- waic(log_lik)
  cat("\nWAIC:\n")
  print(waic_v2)

  # Pareto k diagnostics
  cat("\nPareto k diagnostic:\n")
  k_vals <- loo_v2$diagnostics$pareto_k
  cat("  k > 0.5:", sum(k_vals > 0.5), "\n")
  cat("  k > 0.7:", sum(k_vals > 0.7), "\n")
  cat("  k > 1.0:", sum(k_vals > 1.0), "\n")

}, error = function(e) {
  cat("Could not compute LOO/WAIC:", conditionMessage(e), "\n")
})

# =============================================================================
# 9. Save results
# =============================================================================

cat("\n--- Saving results ---\n")
dir.create("Data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(fit_m1_v2, "Data/processed/m1_v2_fit.rds")
cat("Stanfit object saved to Data/processed/m1_v2_fit.rds\n")

# Save summary table
m1v2_summary_df <- as.data.frame(m1v2_summary)
dir.create("Output", recursive = TRUE, showWarnings = FALSE)
write.csv(m1v2_summary_df, "Output/m1v2_parameter_summary.csv")
cat("Parameter summary saved to Output/m1v2_parameter_summary.csv\n")

# Save diagnostic summary
diag_summary <- list(
  data_version    = data_version,
  N_obs           = N_obs,
  N_censored      = N_censored,
  N_missing       = N_missing,
  n_divergent     = n_divergent_v2,
  n_maxtree       = n_maxtree_v2,
  max_rhat        = max(rhat_v2, na.rm = TRUE),
  n_rhat_gt_1.05  = sum(rhat_v2 > 1.05, na.rm = TRUE),
  n_rhat_gt_1.10  = sum(rhat_v2 > 1.10, na.rm = TRUE),
  min_ess         = min(neff_v2, na.rm = TRUE),
  median_ess      = median(neff_v2, na.rm = TRUE),
  nu_obs_mean     = m1v2_summary["nu_obs", "mean"],
  nu_obs_sd       = m1v2_summary["nu_obs", "sd"],
  sigma_obs_mean  = m1v2_summary["sigma_obs", "mean"],
  sigma_obs_sd    = m1v2_summary["sigma_obs", "sd"]
)
saveRDS(diag_summary, "Output/m1v2_diagnostic_summary.rds")
cat("Diagnostic summary saved to Output/m1v2_diagnostic_summary.rds\n")

cat("\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("  M1v2 MODEL FITTING COMPLETE\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n")
