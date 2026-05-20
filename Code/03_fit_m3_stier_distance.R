# ============================================================================
# 03_fit_m3_stier_distance.R
# Fit Stier-aligned M3 branch with distance-decay process covariance.
#
# Builds directly from m1_stier_11:
#   - zero spawn records are treated as missing / ambiguous,
#   - positive spawn observations are the only spawn-index likelihood points,
#   - survey method uses the original Stier two-era split,
#   - annual process shocks are spatially correlated by effective distance.
# ============================================================================

library(tidyverse)
library(here)
library(readxl)
library(rstan)
library(posterior)
library(loo)

rstan_options(auto_write = TRUE)
options(mc.cores = 4)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M3_STIER_DISTANCE: distance-decay process covariance\n")
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

xlsx_path <- file.path(
  proj_dir,
  "Data",
  "raw",
  "Euclidean & effective distance matrices herring & Steller.xlsx"
)
dist_raw <- read_excel(xlsx_path, sheet = "Herring Effective")

section_ids <- as.integer(dist_raw[[1]][1:13])
id_cols <- paste0("Id", section_ids)
D_full <- as.matrix(dist_raw[1:13, id_cols])
D_full <- apply(D_full, 2, as.numeric)
rownames(D_full) <- section_ids
colnames(D_full) <- section_ids

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
keep_str <- as.character(keep_sections)
D_sub <- D_full[keep_str, keep_str]

D_km <- D_sub / 1000
D_km <- (D_km + t(D_km)) / 2
diag(D_km) <- 0
max_dist <- max(D_km)

stan_data <- list(
  N_years = jags_data$nYears,
  N_sites = jags_data$nSites,
  Y = jags_data$Y,
  Y_obs_flag = jags_data$Y_obs,
  pdo = jags_data$pdo,
  N_methods = 2L,
  q_idx = q_idx_stier,
  dist_mat = D_km,
  max_dist = max_dist,
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
  identical(dim(stan_data$dist_mat), c(stan_data$N_sites, stan_data$N_sites)),
  isTRUE(all.equal(stan_data$dist_mat, t(stan_data$dist_mat))),
  all(diag(stan_data$dist_mat) == 0),
  sum(stan_data$Y_obs_flag) > 0,
  sum(jags_data$Y_censored) > 0,
  all(stan_data$q_idx %in% seq_len(stan_data$N_methods)),
  all(is.finite(stan_data$pdo)),
  all(is.finite(stan_data$log_catch)),
  all(is.finite(stan_data$Y[stan_data$Y_obs_flag == 1L])),
  is.finite(stan_data$max_dist),
  stan_data$max_dist > 0
)

cat("Stier-aligned data choices:\n")
cat("  Positive spawn observations:", sum(stan_data$Y_obs_flag), "\n")
cat("  Ambiguous zero records skipped:", sum(jags_data$Y_censored), "\n")
cat("  Unsurveyed/missing cells skipped:", sum(jags_data$Y_missing), "\n")
cat("  q_idx = 1 surface years:", sum(stan_data$q_idx == 1L), "\n")
cat("  q_idx = 2 SCUBA/dive years:", sum(stan_data$q_idx == 2L), "\n")
cat("  Fitted sections:", stan_data$N_sites, "\n")
cat("  Max effective distance (km):", round(stan_data$max_dist, 1), "\n\n")

make_init_m3_stier_distance <- function() {
  list(
    Umu = 0,
    pdocoef = 0,
    sigma_proc = 0.7,
    phi = 3 / stan_data$max_dist,
    sigma_obs = 0.8,
    log_q = c(-1.2, -0.2),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    Z_init = rep(5, stan_data$N_sites),
    epsilon_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
  )
}

stan_file <- here("inst", "stan", "herring_metapop_m3_stier_distance.stan")
fit <- stan(
  file = stan_file,
  data = stan_data,
  chains = 4,
  iter = 4500,
  warmup = 2000,
  cores = 4,
  refresh = 100,
  init = make_init_m3_stier_distance,
  control = list(adapt_delta = 0.97, max_treedepth = 15),
  seed = 125
)

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(fit, file.path(data_dir, "m3_stier_distance_fit.rds"))
saveRDS(fit, file.path(out_dir, "fit_m3_stier_distance.rds"))

log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
r_eff <- relative_eff(exp(log_lik))
loo_m3 <- loo(log_lik, r_eff = r_eff)
saveRDS(loo_m3, file.path(out_dir, "loo_m3_stier_distance.rds"))

summ <- summarize_draws(fit)
write.csv(
  summ,
  file.path(proj_dir, "Output", "m3_stier_distance_parameter_summary.csv"),
  row.names = FALSE
)

cat("\n=== M3_STIER_DISTANCE COMPLETE ===\n")
