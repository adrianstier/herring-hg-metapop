#!/usr/bin/env Rscript
# Code/12_reversibility_03_edm.R
# Task 18: EDM nonlinearity, Jacobian eigen-trajectory, and CCM driver causality.
# For each state variable {biomass_all11, biomass_focal9}:
#   edm_embed -> smap_nonlinearity -> smap_jacobian_eigen
# CCM split: see Code/12_reversibility_04_ccm.R (driver causality)
# Outputs:
#   Output/diagnostics/reversibility_edm_nonlinearity.csv
#   Output/diagnostics/reversibility_edm_jacobian_eigen.csv
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source("R/12_reversibility.R")
seed <- 20260519L

## --- inputs -----------------------------------------------------------------
bio <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")
drv <- read.csv("Output/diagnostics/reversibility_driver_axis.csv")

## State series (median posterior)
states <- list(
  biomass_all11 = bio[bio$report_set == "all_11", c("year", "median")],
  biomass_focal9 = bio[bio$report_set == "focal_9", c("year", "median")]
)

## Coarse posterior envelope: lo80 and hi80 treated as additional state candidates
bio11 <- bio[bio$report_set == "all_11", ]
states$biomass_all11_lo80 <- bio11[, c("year", "lo80")]
states$biomass_all11_hi80 <- bio11[, c("year", "hi80")]
names(states$biomass_all11_lo80)[2] <- "median"
names(states$biomass_all11_hi80)[2] <- "median"

## --- EDM nonlinearity table -------------------------------------------------
nl_rows <- lapply(names(states), function(nm) {
  s <- states[[nm]]
  v <- s$median
  em <- edm_embed(v)
  E_use <- if (is.na(em$E_best)) 2L else em$E_best
  nl <- smap_nonlinearity(v, E = E_use, n_surr = 500, seed = seed)
  data.frame(
    state         = nm,
    n_obs         = sum(!is.na(v)),
    E             = E_use,
    rho_simplex   = if (is.na(em$rho_best)) NA_real_ else em$rho_best,
    rho_theta0    = nl$rho_theta0,
    rho_theta_best = nl$rho_theta_best,
    nl_delta      = nl$delta,
    nl_p          = nl$p_value,
    nonlinear_sig = isTRUE(nl$p_value < 0.05),
    seed          = seed,
    stringsAsFactors = FALSE
  )
})
nl <- do.call(rbind, nl_rows)

## --- Jacobian eigen-trajectory ----------------------------------------------
je_rows <- lapply(names(states), function(nm) {
  s <- states[[nm]]
  v <- s$median
  em <- edm_embed(v)
  E_use <- if (is.na(em$E_best)) 2L else em$E_best
  je <- smap_jacobian_eigen(v, E = E_use, theta = 2)
  ## align back to year
  yr <- s$year
  if (length(yr) == nrow(je)) {
    je$year <- yr
  } else {
    je$year <- NA_integer_
  }
  je$state <- nm
  je[, c("state", "year", "t", "lambda_max")]
})
je <- do.call(rbind, je_rows)

## --- outputs ----------------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write.csv(nl, "Output/diagnostics/reversibility_edm_nonlinearity.csv",
          row.names = FALSE)
write.csv(je, "Output/diagnostics/reversibility_edm_jacobian_eigen.csv",
          row.names = FALSE)

## --- sanity print -----------------------------------------------------------
med_p <- nl$nl_p[nl$state == "biomass_all11"]
n_fin_lam <- sum(!is.na(je$lambda_max[je$state == "biomass_all11"]))
cat(sprintf(
  "[reversibility] EDM: %d states | all11 nl_p=%.3f (sig=%s) | lambda_max n_finite=%d\n",
  nrow(nl), if (length(med_p)) med_p else NA,
  if (length(med_p)) as.character(isTRUE(med_p < 0.05)) else "?",
  n_fin_lam
))
