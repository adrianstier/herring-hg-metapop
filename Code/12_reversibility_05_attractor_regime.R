#!/usr/bin/env Rscript
# Code/12_reversibility_05_attractor_regime.R
# Task 19: Potential landscape, regime model selection, state modality.
# Split latent biomass at PIVOT (2005 closure) for pre/post comparison.
# Outputs:
#   Output/diagnostics/reversibility_potential_landscape_pre_post.csv
#   Output/diagnostics/reversibility_regime_model_selection.csv
#   Output/diagnostics/reversibility_state_modality.csv
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source("R/12_reversibility.R")
PIVOT <- 2005L

## --- inputs -----------------------------------------------------------------
bio <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")

bio11 <- bio[bio$report_set == "all_11", ]
bio11 <- bio11[order(bio11$year), ]

## Pre- and post-closure latent biomass (median)
pre  <- bio11[bio11$year <= PIVOT, ]
post <- bio11[bio11$year >  PIVOT, ]

## --- potential landscape (pre vs post) --------------------------------------
pl_era <- function(dat, era_label) {
  pl <- potential_landscape(dat$median, n_bin = 25, min_count = 3)
  if (length(pl$x) == 0) {
    return(data.frame(era = era_label, x = NA_real_, U = NA_real_,
                      drift = NA_real_, is_minimum = NA,
                      stringsAsFactors = FALSE))
  }
  is_min <- rep(FALSE, length(pl$x))
  if (length(pl$minima) > 0) {
    for (mn in pl$minima) is_min[which.min(abs(pl$x - mn))] <- TRUE
  }
  data.frame(era = era_label, x = pl$x, U = pl$U, drift = pl$drift,
             is_minimum = is_min, stringsAsFactors = FALSE)
}
pl_pre  <- pl_era(pre,  "pre_closure_<=2005")
pl_post <- pl_era(post, "post_closure_>2005")
pl_all  <- rbind(pl_pre, pl_post)

## Count minima (potential wells) in each era
n_min_pre  <- sum(pl_pre$is_minimum, na.rm = TRUE)
n_min_post <- sum(pl_post$is_minimum, na.rm = TRUE)

## --- regime model selection (stock-recruit structure) -----------------------
## Use lag-1 biomass as a proxy for "stock" when no recruit series is available.
## Lag-1 biomass (year t-1) as stock -> biomass (year t) as recruit-proxy.
bio_ord <- bio11$median
n <- length(bio_ord)
stock_proxy   <- bio_ord[-n]        # B(t-1)
recruit_proxy <- bio_ord[-1]        # B(t) — next-year latent biomass

rm_res <- regime_models(stock_proxy, recruit_proxy)

## per-report-set sensitivity
bio9 <- bio[bio$report_set == "focal_9", ]
bio9 <- bio9[order(bio9$year), ]
b9 <- bio9$median
rm_f9 <- regime_models(b9[-length(b9)], b9[-1])

regime_tab <- data.frame(
  report_set = c("all_11", "all_11", "focal_9", "focal_9"),
  model      = c(rm_res$table$model, rm_f9$table$model),
  aic        = c(rm_res$table$aic,   rm_f9$table$aic),
  best       = c(rep(rm_res$best, 2), rep(rm_f9$best, 2)),
  stringsAsFactors = FALSE
)

## --- state modality ---------------------------------------------------------
## Test whether residuals (biomass minus era-mean) are multimodal post-closure.
resid_pre  <- pre$median  - mean(pre$median, na.rm = TRUE)
resid_post <- post$median - mean(post$median, na.rm = TRUE)
md_pre  <- state_modality(resid_pre)
md_post <- state_modality(resid_post)
md_full <- state_modality(bio11$median)  # full series

modality_tab <- data.frame(
  era       = c("pre_closure_<=2005", "post_closure_>2005", "full_series"),
  dip       = c(md_pre$dip,  md_post$dip,  md_full$dip),
  dip_p     = c(md_pre$dip_p, md_post$dip_p, md_full$dip_p),
  n_obs     = c(nrow(pre), nrow(post), nrow(bio11)),
  multimodal_sig = c(isTRUE(md_pre$dip_p < 0.05),
                     isTRUE(md_post$dip_p < 0.05),
                     isTRUE(md_full$dip_p < 0.05)),
  stringsAsFactors = FALSE
)

## --- outputs ----------------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write.csv(pl_all,      "Output/diagnostics/reversibility_potential_landscape_pre_post.csv",
          row.names = FALSE)
write.csv(regime_tab,  "Output/diagnostics/reversibility_regime_model_selection.csv",
          row.names = FALSE)
write.csv(modality_tab, "Output/diagnostics/reversibility_state_modality.csv",
          row.names = FALSE)

## --- sanity print -----------------------------------------------------------
cat(sprintf(
  "[reversibility] potential minima pre=%d post=%d | regime best=%s | dip_p post=%.3f\n",
  n_min_pre, n_min_post,
  if (!is.na(rm_res$best)) rm_res$best else "NA",
  if (!is.na(md_post$dip_p)) md_post$dip_p else NA
))
