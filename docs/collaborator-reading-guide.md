# Collaborator Reading Guide

This document is for a collaborator reading the repository for the first time and trying to understand it line by line without already knowing the codebase.

## What Is Maintained vs. Historical

The maintained analysis stack is:

- `_targets.R`
- `R/*.R`
- primary Stan source files in `inst/stan/`
- `tests/testthat/*.R`
- `docs/`

The `Code/` directory is still useful, but mostly as:

- exploratory analyses,
- one-off fitting scripts,
- historical comparisons to older model versions,
- provenance for outputs that may not yet be folded into the targets pipeline.

If you want the shortest correct mental model, learn `R/` and `_targets.R` first and treat `Code/` as supplementary.

For Stan specifically, use [`docs/stan-model-map.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/stan-model-map.md) before reading `inst/stan/`. That folder contains both current models and archival/generated files.

## The Core Question

The repository asks how a Haida Gwaii herring metapopulation changed through time as fishing pressure, environment, predator recovery, and possible collective-memory loss interacted.

At a high level the code tries to answer four linked questions:

1. How do raw observations become analysis-ready data with fixed dimensions?
2. How do those cleaned data map into the Stan variables used by each model?
3. How do model outputs become ecological summaries such as synchrony, occupancy, and portfolio effect?
4. How do those summaries connect back to the biological hypotheses?

## Read in This Order

### 1. Global constants and invariants

Read [`R/00_setup.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/00_setup.R).

Focus on:

- `YEARS`, `N_YEARS`
- `SECTIONS_ALL`, `SECTIONS_KEEP`, `SITE_NAMES`, `N_SITES`
- `SURVEY_TRANSITION_YEAR`
- project paths and theme helpers

This file tells you what dimensions almost every matrix and vector in the project must obey.

### 2. Data cleaning and semantic decisions

Read [`R/01_data_cleaning.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/01_data_cleaning.R).

Focus on the semantic choices, not just the syntax:

- spawn zeros become `NA` on the log scale for continuous biomass models,
- catch missing values are zero-filled but tracked through observation logic,
- PDO is reduced to a spring average,
- predator data are aggregated to annual indices,
- survey-method history becomes `q_idx`.

This file explains what the code means by "observation," "missing," and "zero."

### 3. Spatial covariates

Read [`R/10_spatial_data.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/10_spatial_data.R).

This file is where geography enters the model:

- the effective distance matrix,
- section centroids,
- spatially weighted predator pressure,
- validation checks that enforce site alignment.

### 4. Data-to-model contract

Read [`R/02_prepare_model_data.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/02_prepare_model_data.R).

This is the most important integration file for understanding the codebase.

It turns cleaned tibbles and matrices into:

- canonical Stan inputs,
- canonical JAGS inputs for legacy comparisons,
- spatial covariates,
- predator covariates,
- fixed shape and alignment checks.

If you understand this file, you can usually infer what a Stan model is expecting before you open it.

### 5. Stan models and the version-specific bridge

Read:

- [`inst/stan/herring_metapop_v1.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_v1.stan)
- [`inst/stan/herring_metapop_m2_distance.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m2_distance.stan)
- [`inst/stan/herring_metapop_m3_dd_global.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m3_dd_global.stan)
- [`inst/stan/herring_metapop_m4_dd_site.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m4_dd_site.stan)
- [`inst/stan/herring_metapop_m5_predators.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m5_predators.stan)
- [`inst/stan/herring_metapop_m6_timevarying.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m6_timevarying.stan)

Then read [`R/03_fit_model.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/03_fit_model.R).

The key thing to notice is that the cleaned data layer is slightly richer than any single Stan model needs. `R/03_fit_model.R` is the translation layer that chooses the right subset and shape for each model version.

Ignore `.hpp` and `.rds` files in `inst/stan/` on a first pass. They are generated artifacts, not handwritten model code.

### 6. Ecological summaries

Read [`R/05_portfolio.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/05_portfolio.R) and [`R/08_occupancy_model.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/08_occupancy_model.R).

These files answer:

- how regional stability is summarized from section-level biomass,
- how site fidelity and recolonization are summarized from occupancy data.

### 7. Communication layer

Read:

- [`R/06_figures.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/06_figures.R)
- [`R/07_lecture_figures.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/07_lecture_figures.R)
- [`R/04_model_comparison.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/04_model_comparison.R)

These files show what the codebase considers the key scientific outputs.

### 8. Pipeline orchestration

Read [`_targets.R`](/Users/adrianstier/stier-2027-herring-metapopulation/_targets.R) last.

By then, the target graph will read like a compact summary rather than a wall of names.

## Core Invariants to Keep in Mind

These invariants are repeated throughout the code and are worth memorizing early:

- Rows usually mean years.
- Columns usually mean retained spawning sections in `SITE_NAMES` order.
- `N_YEARS` and `N_SITES` are treated as hard contracts, not suggestions.
- Continuous biomass models use `log(SHI)` and therefore cannot directly represent SHI = 0.
- Occupancy and censored-data helpers recover survey effort so zeros can be interpreted biologically.
- Catch is observed on a sparse grid of year-site cells and is indexed separately from spawn observations.
- Predator covariates appear in two forms:
  region-level time series and site-level spatially weighted matrices.

## Files a New Collaborator Can Safely Ignore on Day One

- `Code/legacy-2019/`
- one-off `Code/03_fit_*` scripts
- generated `Output/` files
- raw temporary outputs in the project root such as `m*_output.txt`

They may be useful later, but they are not needed to understand the maintained pipeline.

## Questions Worth Asking While Reading

If you want to check whether you really understand the repository, ask yourself these questions while reading:

1. What exact distinction does the code make between a zero observation and a missing observation?
2. Which hypotheses are represented by process error, density dependence, predator covariates, and occupancy persistence?
3. Which raw data source feeds each Stan covariate?
4. Which dimensions and names must match for the models to work?
5. Which outputs are intended for scientific interpretation versus diagnostics?

If you can answer those five questions from the code and docs, you have the right mental model.
