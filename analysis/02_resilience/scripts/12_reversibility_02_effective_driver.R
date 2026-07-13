#!/usr/bin/env Rscript
# Code/12_reversibility_02_effective_driver.R
# Task 17: Effective-driver reconstruction
# Combines exploitation rate (primary) with context-only predation-pressure and
# PDO covariates into a composite effective driver.
# Outputs:
#   Output/diagnostics/reversibility_effective_driver.csv
#   Output/diagnostics/reversibility_effective_driver_provenance.md
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source(here::here("R", "12_reversibility.R"))

## --- inputs -----------------------------------------------------------------
d <- read.csv("Output/diagnostics/reversibility_driver_axis.csv")

## PDO: annual mean from monthly series
pdo_path <- "Data/processed/pdo_combined_1854_2025.csv"
if (file.exists(pdo_path)) {
  pdo_raw <- read.csv(pdo_path)
  pdo_ann <- aggregate(Value ~ year, data = pdo_raw, FUN = mean)
  names(pdo_ann) <- c("year", "pdo")
  ## z-score to make comparable to u
  pdo_ann$pdo <- as.numeric(scale(pdo_ann$pdo))
  d <- merge(d, pdo_ann, by = "year", all.x = TRUE)
} else {
  warning("[effective_driver] PDO file not found; pdo excluded from composite")
  d$pdo <- NA_real_
}

## Predation-pressure context covariate (context-only, NOT a promoted model branch)
pred_path <- "Data/processed/predators/hg_predation_pressure_covariates.csv"
if (file.exists(pred_path)) {
  cov <- read.csv(pred_path)
  ## use pred_pressure_log_z as the context series (already z-scored in predator repo)
  if ("pred_pressure_log_z" %in% names(cov)) {
    pred_cov <- cov[, c("year", "pred_pressure_log_z")]
    names(pred_cov)[2] <- "predation_pressure_index"
    d <- merge(d, pred_cov, by = "year", all.x = TRUE)
  } else {
    warning("[effective_driver] pred_pressure_log_z column absent; predation excluded")
    d$predation_pressure_index <- NA_real_
  }
} else {
  warning("[effective_driver] predator covariate file not found; predation excluded")
  d$predation_pressure_index <- NA_real_
}

## --- assemble component list ------------------------------------------------
## Only include series with >=10 non-NA overlapping years with u
all_candidates <- c("u", "predation_pressure_index", "pdo")
comp <- all_candidates[sapply(all_candidates, function(cn) {
  if (!cn %in% names(d)) return(FALSE)
  sum(!is.na(d[[cn]]) & !is.na(d$u)) >= 10
})]

prov_labels <- c(
  u                        = "m1_stier_11:all_11_median",
  predation_pressure_index = "predator-repo:hg_predation_pressure_covariates:context-only",
  pdo                      = "Data/processed/pdo_combined_1854_2025.csv:annual-mean-z"
)
prov <- prov_labels[comp]

## --- compute composite ------------------------------------------------------
ed <- effective_driver(d, components = comp, provenance = prov)

## --- output -----------------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)

write.csv(ed[, c("year", "u", "effective_driver")],
          "Output/diagnostics/reversibility_effective_driver.csv",
          row.names = FALSE)

prov_lines <- c(
  "# Effective-driver provenance (context-only)",
  "",
  sprintf("Generated: %s", Sys.Date()),
  sprintf("Seed: 20260519 (no stochastic ops in this script)"),
  "",
  "## Components included in composite",
  "",
  paste0("- ", names(prov), ": ", prov),
  "",
  "## Modeling caveat",
  "",
  paste(
    "Predation-pressure and PDO components are context covariates tagged",
    "context-only. No promoted coefficient; predator model branches remain held.",
    "The promoted baseline is m1_stier_11. The effective driver is a descriptive",
    "z-score composite — not a structural model parameter.",
    sep = " "
  ),
  "",
  "## Components available",
  paste0("comp = c(", paste0('"', comp, '"', collapse = ", "), ")"),
  "",
  "## Components excluded (absent or <10 overlap years)",
  paste0("excluded = c(",
         paste0('"', setdiff(all_candidates, comp), '"', collapse = ", "), ")")
)
writeLines(prov_lines,
           "Output/diagnostics/reversibility_effective_driver_provenance.md")

## --- sanity print -----------------------------------------------------------
n_yr <- sum(!is.na(ed$effective_driver))
ed_min <- min(ed$effective_driver, na.rm = TRUE)
ed_max <- max(ed$effective_driver, na.rm = TRUE)
cat(sprintf(
  "[reversibility] effective driver: components = %s | %d yr | range [%.3f, %.3f]\n",
  paste(comp, collapse = ", "), n_yr, ed_min, ed_max
))
