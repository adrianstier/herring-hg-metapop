# ============================================================================
# 03_fit_m2_v2.R — Fit Model M2 v2 (distance-decay, Student-t, censored zeros)
# stier-2027-herring-metapopulation
# ============================================================================

library(tidyverse)
library(here)
library(readxl)
library(rstan)
library(posterior)
library(bayesplot)
library(loo)

rstan_options(auto_write = TRUE)
options(mc.cores = 4)

source(here("R", "00_setup.R"))

cat("\n", strrep("=", 60), "\n")
cat(" MODEL M2 v2: Distance-decay + Student-t + Censored zeros\n")
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
# 2. LOAD DISTANCE MATRIX
# ============================================================================

xlsx_path <- file.path(proj_dir, "Data", "raw",
                       "Euclidean & effective distance matrices herring & Steller.xlsx")
dist_raw <- read_excel(xlsx_path, sheet = "Herring Effective")

section_ids <- as.integer(dist_raw[[1]][1:13])
id_cols <- paste0("Id", section_ids)
D_full <- as.matrix(dist_raw[1:13, id_cols])
D_full <- apply(D_full, 2, as.numeric)
rownames(D_full) <- section_ids
colnames(D_full) <- section_ids

# Match sections used in jags_data
keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
keep_str <- as.character(keep_sections)
D_sub <- D_full[keep_str, keep_str]

D_km <- D_sub / 1000
D_km <- (D_km + t(D_km)) / 2  # ensure symmetry
max_dist <- max(D_km)

# ============================================================================
# 3. PREPARE STAN DATA
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
  dist_mat = D_km,
  max_dist = max_dist,
  N_catch = jags_data$nIndex,
  catch_yr = jags_data$INDEX[,1],
  catch_site = jags_data$INDEX[,2],
  log_catch = jags_data$ctab[jags_data$INDEX],
  prior_only = 0
)

# Replace -99/-999 in Y with 0.0 for Stan (flag will mask them)
stan_data$Y[stan_data$Y < -50] <- 0.0

# ============================================================================
# 4. FIT MODEL
# ============================================================================

stan_file <- here("inst", "stan", "herring_metapop_m2_v2.stan")
fit <- stan(file = stan_file,
            data = stan_data,
            chains = 4,
            iter = 4500,
            warmup = 2000,
            cores = 4,
            refresh = 100,
            control = list(adapt_delta = 0.95, max_treedepth = 15),
            seed = 123)

# ============================================================================
# 5. SAVE RESULTS
# ============================================================================

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(fit, file.path(data_dir, "m2_v2_fit.rds"))
saveRDS(fit, file.path(out_dir, "fit_m2_v2.rds"))

# LOO
log_lik <- extract_log_lik(fit)
r_eff <- relative_eff(exp(log_lik))
loo_m2 <- loo(log_lik, r_eff = r_eff)
saveRDS(loo_m2, file.path(out_dir, "loo_m2_v2.rds"))

# Parameter summary
summ <- summarize_draws(fit)
write.csv(summ, file.path(proj_dir, "Output", "m2_v2_parameter_summary.csv"), row.names = FALSE)

cat("\n=== M2 v2 COMPLETE ===\n")
