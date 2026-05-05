# ============================================================================
# 03_fit_m5_v3.R — Fit Model M5 v3 (DD + Predators + Okamoto priors)
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
cat(" MODEL M5 v3: DD + Predators + Okamoto Priors\n")
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

# Predator index
pred_df <- read_csv(file.path(data_dir, "predator_indices.csv"), show_col_types = FALSE)
pred_combined <- pred_df$pred_combined
stopifnot(length(pred_combined) == jags_data$nYears)

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

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
keep_str <- as.character(keep_sections)
D_sub <- D_full[keep_str, keep_str]

D_km <- D_sub / 1000
D_km <- (D_km + t(D_km)) / 2
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
  pred_combined = pred_combined,
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

stan_data$Y[stan_data$Y < -50] <- 0.0

surveyed_flag <- stan_data$Y_obs_flag + stan_data$Y_censored_flag
stopifnot(
  identical(dim(stan_data$Y), c(stan_data$N_years, stan_data$N_sites)),
  identical(dim(stan_data$Y_obs_flag), c(stan_data$N_years, stan_data$N_sites)),
  identical(dim(stan_data$Y_censored_flag), c(stan_data$N_years, stan_data$N_sites)),
  identical(dim(stan_data$dist_mat), c(stan_data$N_sites, stan_data$N_sites)),
  all(surveyed_flag <= 1L),
  sum(stan_data$Y_obs_flag) > 0,
  all(stan_data$q_idx %in% seq_len(stan_data$N_methods)),
  all(is.finite(stan_data$pdo)),
  all(is.finite(stan_data$pred_combined)),
  all(is.finite(stan_data$log_catch)),
  all(is.finite(stan_data$Y[stan_data$Y_obs_flag == 1])),
  all(stan_data$Y[stan_data$Y_censored_flag == 1] == 0),
  all(diag(stan_data$dist_mat) == 0),
  max(abs(stan_data$dist_mat - t(stan_data$dist_mat))) < 1e-8
)

make_init_m5_v3 <- function() {
  list(
    U_mu = 0,
    sigma_U = 0.2,
    U_raw = rep(0, stan_data$N_sites),
    pdocoef = 0,
    pred_coef = 0,
    mu_b = -0.2,
    sigma_b = 0.15,
    b_raw = rep(0, stan_data$N_sites),
    sigma_proc = 0.7,
    phi = max(stan_data$max_dist / 4, 1),
    mu_sigma_obs = 0.8,
    tau_sigma_obs = 0.1,
    sigma_obs = rep(0.8, stan_data$N_sites),
    nu_obs = 5,
    log_q = c(-1.2, -0.2, 0.0),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    epsilon_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites),
    Z_init = rep(5, stan_data$N_sites)
  )
}

# ============================================================================
# 4. FIT MODEL
# ============================================================================

stan_file <- here("inst", "stan", "herring_metapop_m5_v3.stan")
fit <- stan(file = stan_file,
            data = stan_data,
            chains = 4,
            iter = 4500,
            warmup = 2000,
            cores = 4,
            refresh = 100,
            init = make_init_m5_v3,
            control = list(adapt_delta = 0.95, max_treedepth = 15),
            seed = 123)

# ============================================================================
# 5. SAVE RESULTS
# ============================================================================

out_dir <- file.path(proj_dir, "Output", "posteriors")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(fit, file.path(data_dir, "m5_v3_fit.rds"))
saveRDS(fit, file.path(out_dir, "fit_m5_v3.rds"))

# LOO
log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
r_eff <- relative_eff(exp(log_lik))
loo_m5 <- loo(log_lik, r_eff = r_eff)
saveRDS(loo_m5, file.path(out_dir, "loo_m5_v3.rds"))

# Parameter summary
summ <- summarize_draws(fit)
write.csv(summ, file.path(proj_dir, "Output", "m5_v3_parameter_summary.csv"), row.names = FALSE)

cat("\n=== M5 v3 COMPLETE ===\n")
