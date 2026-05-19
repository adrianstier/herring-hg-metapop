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

## --- single cached embedding per state -> nonlinearity + Jacobian -----------
## I-3 fix: compute edm_embed(v) ONCE per state series and use that single
## E_use for BOTH smap_nonlinearity() and smap_jacobian_eigen(). Avoids a
## redundant rEDM cross-validation AND the latent risk that the nonlinearity
## test and the |lambda| Jacobian could use divergent E_best if rEDM is not
## perfectly stateless. Outputs are then split into the nl-CSV and je-CSV.
embed_out <- lapply(names(states), function(nm) {
  s <- states[[nm]]
  v <- s$median
  em <- edm_embed(v)
  E_use <- if (is.na(em$E_best)) 2L else em$E_best

  nlx <- smap_nonlinearity(v, E = E_use, n_surr = 500, seed = seed)
  jex <- smap_jacobian_eigen(v, E = E_use, theta = 2)

  ## align Jacobian rows back to year
  yr <- s$year
  jex$year  <- if (length(yr) == nrow(jex)) yr else NA_integer_
  jex$state <- nm
  jex <- jex[, c("state", "year", "t", "lambda_max")]

  nl_row <- data.frame(
    state          = nm,
    n_obs          = sum(!is.na(v)),
    E              = E_use,
    rho_simplex    = if (is.na(em$rho_best)) NA_real_ else em$rho_best,
    rho_theta0     = nlx$rho_theta0,
    rho_theta_best = nlx$rho_theta_best,
    nl_delta       = nlx$delta,
    nl_p           = nlx$p_value,
    nonlinear_sig  = isTRUE(nlx$p_value < 0.05),
    seed           = seed,
    stringsAsFactors = FALSE
  )
  list(nl = nl_row, je = jex, E_best = em$E_best, E_use = E_use)
})

nl <- do.call(rbind, lapply(embed_out, `[[`, "nl"))
je <- do.call(rbind, lapply(embed_out, `[[`, "je"))

## Report the per-state E_best from the single embed (I-3 verification aid).
for (k in seq_along(embed_out)) {
  cat(sprintf("[reversibility] single-embed: %-22s E_best=%s -> E_use=%d\n",
              names(states)[k],
              ifelse(is.na(embed_out[[k]]$E_best), "NA",
                     as.character(embed_out[[k]]$E_best)),
              embed_out[[k]]$E_use))
}

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
