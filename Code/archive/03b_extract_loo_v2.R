# ============================================================================
# 03b_extract_loo_v2.R — Extract and save LOO objects from v2 fits
# stier-2027-herring-metapopulation
# ============================================================================

library(rstan)
library(loo)
library(here)

cat("\nExtracting LOO objects from v2 fits...\n")

# M1 v2
m1_fit_path <- here("Data/processed/m1_v2_fit.rds")
if (file.exists(m1_fit_path)) {
  cat("Loading M1 v2 fit...\n")
  fit <- readRDS(m1_fit_path)
  # Extract as array to preserve chain info
  log_lik <- rstan::extract(fit, "log_lik", permuted = FALSE)
  r_eff <- relative_eff(exp(log_lik))
  loo_m1 <- loo(log_lik, r_eff = r_eff)
  saveRDS(loo_m1, here("Output/posteriors/loo_m1_v2.rds"))
  cat("Saved Output/posteriors/loo_m1_v2.rds\n")
  rm(fit, log_lik, loo_m1)
  gc()
}

# Add more as they finish
# M2, M3, M5 will save their own LOO in Output/posteriors/ as per my new scripts
