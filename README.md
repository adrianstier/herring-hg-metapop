# stier-2027-herring-metapopulation

**Updated analysis of Pacific herring metapopulation dynamics at Haida Gwaii, extending Stier et al. (2020) with a decade of new data.**

## Motivation

Stier et al. (2020, *Ecosphere*) documented how fishing and environmental change eroded the spatial portfolio of herring subpopulations at Haida Gwaii, increasing synchrony and regional extinction risk. That analysis used spawn index and catch data through 2015.

Since then:
- **The fishery has remained closed** (2005-present; DFO 2025 recommendation: 0 tonnes)
- **The 2014-16 marine heatwave ("the blob")** hit during the study's final years — its aftermath is now visible
- **Predator recovery continued** — humpback whales, Steller sea lions, and harbor seals have further increased
- **DFO released updated spawn survey data** through 2024 (Science Response 2022/046 and subsequent updates)
- **The 2024 Haida Gwaii Herring Rebuilding Plan** was finalized (CHN/DFO/Parks Canada)
- **Ono et al. (2025, *Nature*)** demonstrated collective memory loss in Norwegian herring — validating the mechanism hypothesized for Haida Gwaii
- **CJFAS (2025)** identified 22 significant pressure-response relationships for HG herring, primarily predators and PDO

## Core Questions

Building on Stier et al. 2020, the updated analysis asks:

1. **Has the portfolio continued to erode?** With no fishing since 2005, has spatial diversity recovered — or has synchrony locked in?
2. **What drove the 2014-16 heatwave response?** The blob hit during the original study's endpoint. Now we have a decade of post-blob data to assess recovery trajectory.
3. **Have predator effects intensified?** Samhouri et al. (2017) showed predator recovery suppressed herring. With continued marine mammal recovery, has natural mortality further increased?
4. **Does the rebuilding plan's spatial framework match the metapopulation structure?** The 2024 plan uses DFO's 5 major stock areas. Our subpopulation data may reveal finer-scale structure that the plan doesn't capture.
5. **Can we detect collective memory loss?** Ono et al. (2025) showed Norwegian herring shifted spawning grounds 800 km after age truncation. Is there evidence of similar site abandonment at Haida Gwaii?

## What's New vs. 2019

| Dimension | Stier et al. 2020 | This Analysis |
|-----------|-------------------|---------------|
| Spawn data | 1940-2015 | 1940-2024 (+9 years) |
| Catch data | 1950-2015 | 1950-2024 (fishery closed 2005-2024) |
| PDO data | Through 2015 | Through 2024 (includes blob + recovery) |
| Model | Hierarchical time series with spatial correlation | Same + extensions for predator covariates and regime detection |
| Key additions | — | Marine heatwave analysis, predator recovery covariates (whale/seal survey data), spawning site occupancy analysis (collective memory), rebuilding plan spatial evaluation |

## Data Sources to Acquire

### Priority 1: Spawn & Catch (DFO)
- [ ] **DFO Herring Spawn Survey data 2016-2024** — Contact DFO Pacific Science or check open data portal (open.canada.ca). Request Haida Gwaii sub-section level data matching the 9 sub-stocks in the original analysis.
- [ ] **DFO catch data 2016-2024** — Should show zero commercial catch since 2005 closure. Confirm any FSC (food, social, ceremonial) harvest levels.
- [ ] **DFO Science Advisory Secretariat reports 2016-2025** — Annual status updates and forecasts. The 2025 Science Response (2025/005) is the most recent.

### Priority 2: Environmental Covariates
- [ ] **PDO index 2016-2024** — NOAA JISAO (research.jisao.washington.edu/pdo/). Monthly values, update `pdo.csv`.
- [ ] **SST data for Haida Gwaii** — NOAA OISST or MEDS buoy data. Captures the 2014-16 blob and subsequent conditions.
- [ ] **Chlorophyll-a / productivity** — MODIS or Copernicus satellite data for the Hecate Strait / HG region.

### Priority 3: Predator Recovery Data
- [ ] **Humpback whale survey data** — DFO Pacific or BC Cetacean Sightings Network. Need abundance estimates or indices for the HG/Hecate Strait area.
- [ ] **Steller sea lion counts** — DFO or NOAA (for cross-border populations). Breeding colony counts at HG rookeries.
- [ ] **Harbor seal counts** — DFO Pacific haul-out surveys.

### Priority 4: Governance & Policy
- [ ] **Haida Gwaii Herring Rebuilding Plan (2024)** — Full text from DFO/CHN. Already referenced in lecture materials.
- [ ] **CJFAS 2025 paper** — doi:10.1139/cjfas-2024-0150. Pressure-response relationships for HG herring.

## Repository Structure

```
stier-2027-herring-metapopulation/
├── README.md                   ← This file
├── stier-2027-herring-metapopulation.Rproj
├── Code/
│   ├── [legacy 2019 scripts]   ← Original analysis code (reference)
│   ├── Posteriors/              ← Original MCMC posteriors
│   ├── 00_setup.R              ← TODO: packages, paths, theme
│   ├── 01_data_acquisition.R   ← TODO: download/clean new DFO data
│   ├── 02_data_merge.R         ← TODO: merge legacy + new data
│   ├── 03_model_updated.R      ← TODO: updated hierarchical model
│   ├── 04_portfolio_analysis.R ← TODO: synchrony, portfolio metrics
│   ├── 05_predator_analysis.R  ← TODO: predator covariate models
│   ├── 06_memory_analysis.R    ← TODO: spawning site occupancy
│   ├── 07_figures.R            ← TODO: publication figures
│   └── 08_lecture_figures.R    ← TODO: 4K lecture slides
├── Data/
│   ├── raw/
│   │   ├── legacy-2019/        ← Original CSVs (1940-2015)
│   │   ├── dfo-spawn/          ← TODO: new DFO spawn survey data
│   │   ├── dfo-catch/          ← TODO: new catch/FSC data
│   │   ├── environmental/      ← TODO: PDO, SST, Chl-a
│   │   └── predators/          ← TODO: whale, seal, sea lion data
│   └── processed/              ← Cleaned, merged analysis-ready data
├── Output/
│   ├── figures/                ← Publication and lecture figures
│   ├── tables/                 ← Model summaries, comparison tables
│   └── posteriors/             ← MCMC output
├── Literature/                 ← 20 core PDFs (Stier lab + collaborators)
└── docs/
    ├── data-dictionary.md      ← TODO: variable definitions
    └── analysis-plan.md        ← TODO: detailed methods plan
```

## Legacy Code Reference

The `Code/` directory contains the original 2019 R scripts:

| Script | Purpose |
|--------|---------|
| `Model1_diagonal_equal.R` | Hierarchical time series model (JAGS/Stan) with spatial correlation |
| `error_prop_3_25_19.R` | Error propagation for spawn index estimates |
| `error_prop_3_25_19+AOS.R` | Error propagation with age-at-spawning correction |
| `figures.R` | Publication figures for Stier et al. 2020 |
| `lecture_figures.R` | 4K lecture figures (dark theme) for EEMB 142C |
| `theme_acs.R` / `theme_publication.R` | ggplot2 themes |
| `multiplot.R` | Multi-panel layout utility |

## Key Papers

| Paper | Relevance |
|-------|-----------|
| **Stier et al. 2020 *Ecosphere*** | The paper this project updates. Portfolio erosion, spatial fishing pressure, synchrony increase. |
| **Samhouri, Stier et al. 2017 *Nat Ecol Evol*** | Predator recovery suppresses herring — the irony of conservation success. |
| **Ono et al. 2025 *Nature*** | Collective memory loss in Norwegian herring. The mechanism we hypothesized is now proven. |
| **CJFAS 2025** | 22 pressure-response relationships for HG herring. Predators and PDO dominate. |
| **DFO 2025 Science Response** | Current status: 0 tonnes recommended. 7,930 t forecast, 43% below LRP. |
| **Shelton et al. 2014 *Sci Reports*** | Egg vs. adult harvest asymmetry. K'aaw in the safe zone. |
| **Okamoto et al. 2020 *Ecol Apps*** | Aggregate management masks local collapse risk. |
| **Frid et al. 2023 *Fish & Fisheries*** | Re-imagining precautionary approach with Indigenous Knowledge Systems. |

## Timeline

- **Spring 2026**: Set up repo, acquire data, clean and merge datasets
- **Summer 2026**: Run updated models, compare 2015 vs 2024 parameter estimates
- **Fall 2026**: Draft manuscript sections, generate figures
- **Winter 2027**: Submit manuscript

## Contributors

- Adrian C. Stier (UCSB)
- [collaborators TBD — reach out to Samhouri, Shelton, Okamoto]

## Citation for Original Work

Stier AC, Shelton AO, Samhouri JF, Feist BE, & Levin PS (2020) Fishing, environment, and the erosion of a population portfolio. *Ecosphere* 11(11): e03283. doi:10.1002/ecs2.3283
