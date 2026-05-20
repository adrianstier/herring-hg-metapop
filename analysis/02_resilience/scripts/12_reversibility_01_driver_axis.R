#!/usr/bin/env Rscript
# Code/12_reversibility_01_driver_axis.R
# Task 16: Driver-axis diagnostic script
# Computes exploitation rate u = catch / latent biomass for HG herring 1951-2024.
# Outputs: Output/diagnostics/reversibility_driver_axis.csv
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source(here::here("R", "12_reversibility.R"))

## --- inputs -----------------------------------------------------------------
catch <- read.csv("Data/processed/herring_catch_local_1950_2024.csv")
bio   <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")

## Annual catch (aggregate across sections)
ac <- aggregate(TotalCatch ~ Year, data = catch, FUN = sum)
names(ac) <- c("year", "total_catch")

## all_11 latent biomass (median posterior)
b11 <- bio[bio$report_set == "all_11", c("year", "median", "period")]
names(b11)[2] <- "biomass"

## focal_9 latent biomass (median posterior) — sensitivity series
b9  <- bio[bio$report_set == "focal_9", c("year", "median")]
names(b9)[2] <- "biomass_focal9"

## --- compute exploitation rate ---------------------------------------------
d <- exploitation_rate(ac, b11)  # exploitation_rate inner-joins on year
d <- merge(d, b9, by = "year", all.x = TRUE)

## Also add the era bounds for downstream use
d <- merge(d, b11[, c("year", "period")], by = "year", all.x = TRUE)
d <- d[order(d$year), ]

## Compute focal-9 u as well (sensitivity check)
b_f9 <- d$biomass_focal9
d$u9 <- ifelse(is.na(b_f9) | b_f9 <= 0, NA_real_, d$total_catch / b_f9)

## Canonical pivot: fishing closure year
PIVOT <- 2005
d$limb <- ifelse(d$year <= PIVOT, "down_limb", "up_limb")

## --- output -----------------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write.csv(d[, c("year", "period", "limb", "total_catch", "biomass",
                "biomass_focal9", "u", "u9")],
          "Output/diagnostics/reversibility_driver_axis.csv",
          row.names = FALSE)

## --- sanity print -----------------------------------------------------------
n_yr   <- sum(!is.na(d$u))
u_min  <- min(d$u, na.rm = TRUE)
u_max  <- max(d$u, na.rm = TRUE)
u_med  <- median(d$u, na.rm = TRUE)
n_down <- sum(d$limb == "down_limb" & !is.na(d$u))
n_up   <- sum(d$limb == "up_limb"   & !is.na(d$u))
cat(sprintf(
  "[reversibility] driver axis: %d yr (down=%d, up=%d), u in [%.3f, %.3f], median=%.3f\n",
  n_yr, n_down, n_up, u_min, u_max, u_med
))
