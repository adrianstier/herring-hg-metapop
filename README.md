# stier-2027-herring-metapopulation

**Updated analysis of Pacific herring metapopulation dynamics at Haida Gwaii, extending Stier et al. (2020) with a decade of new data, Stan models, and new ecological questions.**

## Start Here

If you are reading this repository for the first time, use this order:

1. `README.md` for the project scope and the current model hierarchy.
2. `docs/collaborator-reading-guide.md` for the codebase reading order and file map.
3. `docs/theory-data-model-integration.md` for how ecological hypotheses become cleaned covariates, Stan data, parameters, and figures.
4. `docs/stan-model-map.md` for which Stan files are primary, archival, or generated artifacts.
5. `R/00_setup.R`, `R/01_data_cleaning.R`, `R/10_spatial_data.R`, and `R/02_prepare_model_data.R` for the data contract.
6. `inst/stan/*.stan` plus `R/03_fit_model.R` for the model contract.
7. `R/05_portfolio.R`, `R/08_occupancy_model.R`, `R/06_figures.R`, and `R/07_lecture_figures.R` for interpretation and communication.

The maintained workflow lives in `R/`, `_targets.R`, `inst/stan/`, and `tests/testthat/`.
The top-level `Code/` directory contains exploratory or one-off scripts that are useful context, but it is not the primary pipeline a collaborator should learn first.

## Motivation

Stier et al. (2020, *Ecosphere*) documented how fishing and environmental change eroded the spatial portfolio of herring subpopulations at Haida Gwaii, increasing synchrony and regional extinction risk. That analysis used spawn index and catch data through 2015 with a JAGS state-space model.

Since then:
- **The fishery has remained closed** (2005-present; DFO 2025 recommendation: 0 tonnes) — a 19-year natural experiment
- **The 2014-16 marine heatwave ("the blob")** hit during the study's final years — its aftermath is now visible
- **Predator recovery continued** — humpback whales, Steller sea lions, and harbor seals have further increased
- **Ono et al. (2025, *Nature*)** demonstrated collective memory loss in Norwegian herring — validating the mechanism hypothesized for Haida Gwaii
- **The 2024 Haida Gwaii Herring Rebuilding Plan** was finalized (CHN/DFO/Parks Canada)

## Core Questions

1. **Has the portfolio continued to erode?** With no fishing since 2005, has spatial diversity recovered — or has synchrony locked in?
2. **Does distance explain spatial correlation?** Can we replace 55 free correlations with a single distance-decay parameter?
3. **Is there density dependence?** The 19-year closure is a natural experiment — growth should decelerate if DD exists.
4. **Have predator effects intensified?** With continued marine mammal recovery, has natural mortality further increased?
5. **Can we detect collective memory loss?** Is there evidence of spawning site abandonment consistent with Ono et al. (2025)?

## Model Comparison Hierarchy

| Model | Spatial | Density Dep. | Predators | Key Question |
|-------|---------|-------------|-----------|-------------|
| M1 | Diagonal-equal | None | None | Baseline (reproduces Stier 2020) |
| M2 | Distance-decay (φ) | None | None | Does spatial structure matter? |
| M3 | Distance-decay | Global Gompertz | None | Is there density dependence? |
| M4 | Distance-decay | Site-specific Gompertz | None | Does DD vary by site? |
| M5 | Distance-decay | Best DD | SSL + seal + whale | Do predators suppress recovery? |
| M6 | Time-varying φ(t) | Best DD | Best predators | When did synchrony change? |
| Occupancy | — | — | — | Collective memory / site fidelity |

All models compared via LOO-CV. See `docs/analysis-plan.md` for details.

## What's New vs. 2019

| Dimension | Stier et al. 2020 | This Analysis |
|-----------|-------------------|---------------|
| Data | 1940-2015 | 1951-2025 maintained model window |
| Sampler | JAGS (Gibbs, 1M iterations) | Stan/cmdstanr (HMC, ~2000 iterations) |
| Spatial | Diagonal-equal (55 free correlations) | Distance-decay (1 parameter) + time-varying |
| Density dep. | None | Gompertz (global + site-specific) |
| Predators | None | SSL + seal + whale (spatially weighted) |
| Collective memory | Not tested | Formal occupancy sub-model |
| Models | 1 | 7 in a comparison hierarchy |
| Pipeline | Scripts with `setwd()` | `{targets}` + `here()` |
| Tests | None | 434 regression tests |

## Repository Structure

```
stier-2027-herring-metapopulation/
├── R/                              # 12 maintained R files
│   ├── 00_setup.R                  # Constants, themes, palettes
│   ├── 01_data_cleaning.R          # 7 data functions (tidyverse, named columns)
│   ├── 02_prepare_model_data.R     # Stan/JAGS dual-format data assembly
│   ├── 03_fit_model.R              # cmdstanr fitting, tidybayes extraction (M1-M6)
│   ├── 04_model_comparison.R       # LOO-CV comparison + visualization
│   ├── 05_portfolio.R              # Portfolio effect, synchrony, site occupancy
│   ├── 06_figures.R                # 6 publication figures (patchwork + theme_pub)
│   ├── 07_lecture_figures.R         # 4K dark-theme lecture figures
│   ├── 08_occupancy_model.R        # Collective memory Stan model interface
│   ├── 09_zero_inflated_obs.R      # Censored observation classification
│   ├── 10_spatial_data.R           # Distance matrices, spatial predator indices
│   └── process_oisst_monthly.R     # Utility to regenerate monthly SST inputs
├── inst/stan/                      # Primary Stan models + archival variants/cache artifacts
│   ├── herring_metapop_v1.stan     # M1: baseline (diagonal-equal)
│   ├── herring_metapop_v2.stan     # Legacy v2: free MVN (reference only)
│   ├── herring_metapop_m2_distance.stan    # M2: distance-decay
│   ├── herring_metapop_m3_dd_global.stan   # M3: + global Gompertz
│   ├── herring_metapop_m4_dd_site.stan     # M4: + site-specific Gompertz
│   ├── herring_metapop_m5_predators.stan   # M5: + predator covariates
│   ├── herring_metapop_m6_timevarying.stan # M6: + time-varying φ
│   └── site_occupancy.stan                 # Collective memory model
├── _targets.R                      # Maintained targets pipeline entrypoint
├── tests/testthat/                 # Regression tests for maintained R code
├── Code/legacy-2019/               # Original JAGS scripts (historical reference)
├── Code/                           # Exploratory / one-off scripts, not primary pipeline
├── Data/
│   ├── raw/                        # 62 files across 7 sources
│   │   ├── legacy-2019/            # Original CSVs (1940-2015)
│   │   ├── dfo-spawn/              # DFO spawn survey (through 2025)
│   │   ├── dfo-catch/              # DFO catch data
│   │   ├── environmental/          # PDO, SST, Chl-a
│   │   ├── predators/              # SSL, harbour seal, humpback
│   │   ├── steller-sea-lions/      # Breeding counts 1971-2013
│   │   └── harbour-seals/          # Haul-out surveys
│   └── processed/                  # Cleaned, merged analysis-ready data
├── Literature/                     # 71 PDFs (core + predators)
├── docs/
│   ├── analysis-plan.md            # 6-model hierarchy + expected results
│   ├── stan-model-map.md           # Which Stan files are primary vs archival
│   └── data-dictionary.md          # All variables documented
├── Output/
│   ├── figures/                    # Publication + lecture figures
│   ├── tables/                     # Model summaries
│   └── posteriors/                 # MCMC output
├── .gitignore
├── README.md
└── stier-2027-herring-metapopulation.Rproj
```

## Stan Directory Note

`inst/stan/` contains:

- primary maintained Stan models used by the current interfaces,
- archival or experimental `.stan` variants kept for provenance,
- generated `.hpp` and compiled `.rds` artifacts from Stan tooling.

For a first read-through, start with the primary files listed in `docs/stan-model-map.md` and ignore `.hpp` / `.rds`.

## Key Papers

| Paper | Relevance |
|-------|-----------|
| **Stier et al. 2020 *Ecosphere*** | The paper this project updates |
| **Ono et al. 2025 *Nature*** | Collective memory loss — the mechanism we test |
| **Samhouri, Stier et al. 2017 *Nat Ecol Evol*** | Predator recovery suppresses herring |
| **Shelton et al. 2014 *Sci Reports*** | Egg vs. adult harvest asymmetry |
| **Okamoto et al. 2020 *Ecol Apps*** | Aggregate management masks local collapse |
| **Frid et al. 2023 *Fish & Fisheries*** | Re-imagining precautionary approach with IKS |

## Getting Started

```r
# Install cmdstanr (requires CmdStan)
install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))
cmdstanr::install_cmdstan()

# Install project packages
# renv::restore()  # once renv is initialized

# Run the pipeline
targets::tar_make()

# Visualize the pipeline
targets::tar_visnetwork()
```

## Repository Conventions

- `YEARS`, `SECTIONS_KEEP`, and `SITE_NAMES` in `R/00_setup.R` define the canonical model dimensions. Most downstream objects are expected to align to those values exactly.
- Spawn survey zeros and missing data are intentionally treated differently. Positive spawn observations are logged, surveyed zeros are retained as left-censored cells, and unsurveyed cells are treated as true missing effort.
- Spatial models use the same site order as `SITE_NAMES`, with distance matrices and predator matrices aligned to that order.
- Model helpers return cleaned R objects first; `R/03_fit_model.R` then maps those objects onto version-specific Stan `data {}` contracts.

## Timeline

- **Spring 2026**: Repo setup, data acquisition, pipeline built
- **Summer 2026**: Run M1-M6 comparison, occupancy model
- **Fall 2026**: Draft manuscript, generate figures
- **Winter 2027**: Submit

## Contributors

- Adrian C. Stier (UCSB)
- [collaborators TBD]

## Citation

Stier AC, Shelton AO, Samhouri JF, Feist BE, & Levin PS (2020) Fishing, environment, and the erosion of a population portfolio. *Ecosphere* 11(11): e03283. doi:10.1002/ecs2.3283
