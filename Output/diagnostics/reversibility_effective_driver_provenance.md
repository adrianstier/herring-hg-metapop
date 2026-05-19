# Effective-driver provenance (context-only)

Generated: 2026-05-19
Seed: 20260519 (no stochastic ops in this script)

## Components included in composite

- u: m1_stier_11:all_11_median
- predation_pressure_index: predator-repo:hg_predation_pressure_covariates:context-only
- pdo: Data/processed/pdo_combined_1854_2025.csv:annual-mean-z

## Modeling caveat

Predation-pressure and PDO components are context covariates tagged context-only. No promoted coefficient; predator model branches remain held. The promoted baseline is m1_stier_11. The effective driver is a descriptive z-score composite — not a structural model parameter.

## Components available
comp = c("u", "predation_pressure_index", "pdo")

## Components excluded (absent or <10 overlap years)
excluded = c("")
