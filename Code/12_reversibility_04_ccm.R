#!/usr/bin/env Rscript
# Code/12_reversibility_04_ccm.R
# Task 18 (CCM split): Convergent Cross-Mapping — driver causality.
# Tests whether candidate drivers (u, effective_driver, pdo, predation_pressure_index)
# causally predict the biomass state via CCM convergence.
# GATE: converges_strict only (Kendall rho-vs-libSize p<0.05 AND rho_max>0.2).
# converges_heuristic is carried as a non-authoritative supporting flag only.
# Output:
#   Output/diagnostics/reversibility_ccm_driver_causality.csv
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source("R/12_reversibility.R")
seed <- 20260519L

## --- inputs -----------------------------------------------------------------
bio <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")
drv <- read.csv("Output/diagnostics/reversibility_driver_axis.csv")
ed  <- read.csv("Output/diagnostics/reversibility_effective_driver.csv")
nl  <- read.csv("Output/diagnostics/reversibility_edm_nonlinearity.csv")

## PDO for CCM — optional input; mirror Script 02's file.exists() guard so a
## clean env missing the covariate degrades (PDO excluded) instead of crashing.
pdo_path <- "Data/processed/pdo_combined_1854_2025.csv"
if (file.exists(pdo_path)) {
  pdo_raw <- read.csv(pdo_path)
  pdo_ann <- aggregate(Value ~ year, data = pdo_raw, FUN = mean)
  names(pdo_ann) <- c("year", "pdo")
} else {
  warning("[ccm] PDO file not found — PDO excluded from driver set: ", pdo_path)
  pdo_ann <- data.frame(year = integer(), pdo = numeric())
}

## predation context covariate
pred_path <- "Data/processed/predators/hg_predation_pressure_covariates.csv"
pred_cov <- if (file.exists(pred_path)) {
  cov <- read.csv(pred_path)
  if ("pred_pressure_log_z" %in% names(cov)) {
    p <- cov[, c("year", "pred_pressure_log_z")]
    names(p)[2] <- "predation_pressure_index"
    p
  } else NULL
} else NULL

## Build a merged driver frame aligned on year
bio11 <- bio[bio$report_set == "all_11", c("year", "median")]
names(bio11)[2] <- "biomass"
m <- merge(bio11, drv[, c("year", "u")], by = "year")
m <- merge(m, ed[, c("year", "effective_driver")], by = "year", all.x = TRUE)
m <- merge(m, pdo_ann, by = "year", all.x = TRUE)
if (!is.null(pred_cov)) m <- merge(m, pred_cov, by = "year", all.x = TRUE)
m <- m[order(m$year), ]

## Embedding dimension from nonlinearity table
E_all11 <- nl$E[nl$state == "biomass_all11"][1]
if (is.na(E_all11) || !is.finite(E_all11)) E_all11 <- 2L
E_all11 <- as.integer(E_all11)

## --- CCM --------------------------------------------------------------------
target <- m$biomass

## Build candidate driver list (only include if >=10 non-NA overlap with target)
drv_candidates <- list(u = m$u, effective_driver = m$effective_driver)
if ("pdo" %in% names(m)) drv_candidates$pdo <- m$pdo
if ("predation_pressure_index" %in% names(m)) {
  drv_candidates$predation_pressure_index <- m$predation_pressure_index
}
## filter to series with enough overlap
drv_use <- drv_candidates[sapply(drv_candidates, function(v) {
  sum(!is.na(v) & !is.na(target)) >= 10
})]

ccm_res <- if (length(drv_use) > 0) {
  ccm_drivers(target, drv_use, E = E_all11, seed = seed)
} else {
  data.frame(driver = character(), rho_min = numeric(), rho_max = numeric(),
             converges_strict = logical(), converges_heuristic = logical())
}
ccm_res$state  <- "biomass_all11"
ccm_res$E_used <- E_all11
ccm_res$seed   <- seed

## --- output -----------------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write.csv(ccm_res,
          "Output/diagnostics/reversibility_ccm_driver_causality.csv",
          row.names = FALSE)

## --- sanity print -----------------------------------------------------------
## GATE must be converges_strict, NEVER converges_heuristic
n_strict <- if (nrow(ccm_res) > 0) sum(ccm_res$converges_strict, na.rm = TRUE) else 0L
cat(sprintf(
  "[reversibility] CCM: %d drivers tested | %d converge_strict (authoritative gate) | E=%d\n",
  nrow(ccm_res), n_strict, E_all11
))
if (nrow(ccm_res) > 0) {
  for (i in seq_len(nrow(ccm_res))) {
    cat(sprintf("  %-35s rho_max=%.3f  strict=%s  heuristic=%s\n",
                ccm_res$driver[i],
                ccm_res$rho_max[i],
                ccm_res$converges_strict[i],
                ccm_res$converges_heuristic[i]))
  }
}
