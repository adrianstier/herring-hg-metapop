#!/usr/bin/env Rscript
# Code/12_reversibility_06_driver_loop.R
# Task 20: Driver-state hysteresis loop geometry and null p-values.
# Runs driver_state_loop() and loop_null_pvalue() for:
#   state   = {biomass (all_11 median), synchrony (rolling-window midpoint)}
#   driver  = {u (exploitation rate), effective_driver}
# -> 4 combinations (2 states x 2 drivers)
# Output:
#   Output/diagnostics/reversibility_driver_state_hysteresis_loop.csv
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source("R/12_reversibility.R")
seed  <- 20260519L
PIVOT <- 2005L

## --- inputs -----------------------------------------------------------------
bio <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")
drv <- read.csv("Output/diagnostics/reversibility_driver_axis.csv")
ed  <- read.csv("Output/diagnostics/reversibility_effective_driver.csv")

## biomass state (all_11 median, year-aligned)
bio11 <- bio[bio$report_set == "all_11", c("year", "median")]
names(bio11)[2] <- "biomass"
bio11 <- bio11[order(bio11$year), ]

## synchrony state (rolling window; use window_mid as time axis)
pm_path <- "Data/processed/portfolio_metrics_rolling.csv"
pm <- read.csv(pm_path)
pm <- pm[order(pm$window_mid), ]
## Use floor(window_mid) to get an integer-year proxy for alignment
pm$year_proxy <- floor(pm$window_mid)

## driver: exploitation rate u (year-aligned)
drv <- drv[order(drv$year), ]

## driver: effective_driver (year-aligned)
ed <- ed[order(ed$year), ]

## --- helper: run one (driver, state, year) combo ----------------------------
run_loop <- function(driver_vec, state_vec, year_vec,
                     driver_name, state_name,
                     pivot     = PIVOT,
                     era_break = PIVOT,
                     q_vals    = c(0.6, 1.0),
                     n_null    = 500,
                     rng_seed  = seed) {
  res <- driver_state_loop(driver_vec, state_vec, year_vec, pivot = pivot)
  p_null <- loop_null_pvalue(
    driver    = driver_vec,
    state     = state_vec,
    year      = year_vec,
    pivot     = pivot,
    era_break = era_break,
    q         = q_vals,
    n_null    = n_null,
    seed      = rng_seed
  )
  ## Safely extract matched_gap — may be NA (use is.finite() per spec contract)
  mg <- res$matched_gap
  if (!is.finite(mg)) mg <- NA_real_

  data.frame(
    driver          = driver_name,
    state           = state_name,
    signed_area     = res$signed_area,
    matched_gap     = mg,
    loop_null_p     = p_null,
    loop_sig        = isTRUE(!is.na(p_null) && p_null < 0.05),
    era_break_used  = era_break,
    q_pre           = q_vals[1],
    q_post          = q_vals[2],
    n_null          = n_null,
    seed            = rng_seed,
    stringsAsFactors = FALSE
  )
}

## --- 4 combinations ---------------------------------------------------------
## 1. biomass x u
m_bio_u <- merge(bio11, drv[, c("year", "u")], by = "year")
m_bio_u <- m_bio_u[order(m_bio_u$year), ]

## 2. biomass x effective_driver
m_bio_ed <- merge(bio11, ed[, c("year", "effective_driver")], by = "year")
m_bio_ed <- m_bio_ed[order(m_bio_ed$year), ]

## 3. synchrony x u
##    Synchrony uses year_proxy; merge on nearest integer year.
##    Keep only years present in both series.
m_sync_u <- merge(pm[, c("year_proxy", "synchrony")],
                  drv[, c("year", "u")],
                  by.x = "year_proxy", by.y = "year")
m_sync_u <- m_sync_u[order(m_sync_u$year_proxy), ]

## 4. synchrony x effective_driver
m_sync_ed <- merge(pm[, c("year_proxy", "synchrony")],
                   ed[, c("year", "effective_driver")],
                   by.x = "year_proxy", by.y = "year")
m_sync_ed <- m_sync_ed[order(m_sync_ed$year_proxy), ]

cat(sprintf("[reversibility] loop: biomass-u n=%d | biomass-ed n=%d | sync-u n=%d | sync-ed n=%d\n",
            nrow(m_bio_u), nrow(m_bio_ed), nrow(m_sync_u), nrow(m_sync_ed)))

## Run all 4
r1 <- run_loop(m_bio_u$u,              m_bio_u$biomass,
               m_bio_u$year,           "u",                "biomass_all11")
r2 <- run_loop(m_bio_ed$effective_driver, m_bio_ed$biomass,
               m_bio_ed$year,          "effective_driver",  "biomass_all11")
r3 <- run_loop(m_sync_u$u,             m_sync_u$synchrony,
               m_sync_u$year_proxy,    "u",                "synchrony")
r4 <- run_loop(m_sync_ed$effective_driver, m_sync_ed$synchrony,
               m_sync_ed$year_proxy,   "effective_driver",  "synchrony")

loop_tab <- rbind(r1, r2, r3, r4)
rownames(loop_tab) <- NULL

## --- output -----------------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write.csv(loop_tab,
          "Output/diagnostics/reversibility_driver_state_hysteresis_loop.csv",
          row.names = FALSE)

## --- sanity print -----------------------------------------------------------
cat("[reversibility] driver-state hysteresis loop results:\n")
for (i in seq_len(nrow(loop_tab))) {
  cat(sprintf("  %-20s x %-18s  signed_area=%8.3f  matched_gap=%s  loop_p=%s\n",
              loop_tab$driver[i], loop_tab$state[i],
              loop_tab$signed_area[i],
              if (is.finite(loop_tab$matched_gap[i])) sprintf("%.3f", loop_tab$matched_gap[i]) else "NA",
              if (!is.na(loop_tab$loop_null_p[i])) sprintf("%.3f", loop_tab$loop_null_p[i]) else "NA"))
}
