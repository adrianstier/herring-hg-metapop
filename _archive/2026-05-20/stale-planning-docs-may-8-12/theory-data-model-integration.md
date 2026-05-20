# Theory, Data, and Model Integration

This document is the current source of truth for how ecological ideas in the project are represented in data engineering, Stan inputs, and output products.

> Current baseline, 2026-05-08
> The promoted practical baseline is `m1_stier_11`, which follows Stier et al. (2020) by treating zero spawn records as ambiguous/missing. The data contract still preserves zero and survey-effort information so detection-aware / left-censored models can be run as sensitivity analyses.

## One-Sentence Summary

The repository converts section-level spawn surveys, catch, environment, and predator data into a set of aligned matrices and vectors that let competing state-space and occupancy models ask whether herring resilience is limited by synchrony, density dependence, predator recovery, and collective-memory loss.

## The Integration Stack

The project has five layers:

1. Ecological theory and hypotheses
2. Raw observations from DFO, NOAA, and published predator datasets
3. Engineered covariates and observation masks
4. Model-specific Stan data contracts
5. Scientific outputs and figures

The code is easiest to understand if you keep those five layers separate.

## Hypothesis-to-Code Map

| Hypothesis | Ecological meaning | Raw data | Cleaning / engineering step | Stan variables | Primary model files | Downstream outputs |
|---|---|---|---|---|---|---|
| Portfolio erosion / synchrony | Sections rise and fall together more than before | Spawn index by section | `clean_spawn()`, `extract_posteriors()` | `Y`, `Y_obs`, latent `Z`, `X` | `herring_metapop_v1.stan`, `herring_metapop_m2_distance.stan`, `herring_metapop_m3_dd_global.stan`, `herring_metapop_m4_dd_site.stan`, `herring_metapop_m5_predators.stan`, `herring_metapop_m6_timevarying.stan` | `compute_portfolio()`, `compute_synchrony()`, `fig_portfolio()`, `fig_synchrony()` |
| Fishing pressure as biomass removal | Catch lowers post-fishing biomass relative to pre-fishing biomass | Section-level spring catch | `clean_catch()`, `build_catch_index()` | `N_catch`, `catch_row`, `catch_col`, `log_catch`, latent `Pc` | all continuous biomass models | `extract_posteriors()` fishing summaries, `fig_fishing_rates()` |
| Environmental forcing | Productivity shifts with broad-scale climate | Monthly PDO | `clean_pdo()` | `pdo` | all continuous biomass models | posterior `pdocoef`, model comparisons |
| Spatial process correlation | Nearby sections share process shocks | Effective distance matrix | `load_distance_matrix()`, `compute_distance_matrix()` | `dist_mat`, `max_dist` | `herring_metapop_m2_distance.stan`, `m3`, `m4`, `m5`, `m6` | spatial model comparison, synchrony interpretation |
| Density dependence | Growth slows as biomass approaches carrying capacity | Spawn-derived latent biomass | model-internal use of previous `Z` or `X` | `beta`, `K_log` or site-level variants | `m3`, `m4`, `m5`, `m6` | model comparison, parameter summaries |
| Predator recovery suppresses rebuilding | Marine mammal recovery increases natural mortality or suppresses growth | SSL counts, seal counts, whale abundance | `clean_predators()`, `build_predator_spatial_index()` | region-level `ssl`, `seal`, `whale`; site-level spatial `ssl`, `seal`; masks `pred_obs`, `whale_obs` | `herring_metapop_m5_predators.stan`, `herring_metapop_m6_timevarying.stan`, `herring_metapop_v2.stan` | predator parameter summaries, `fig_predator_effects()` |
| Collective memory / site fidelity | Previous occupancy changes current occupancy beyond biomass alone | Spawn survey effort and detected spawning | `prepare_occupancy_data()`, `compute_site_occupancy()` | `occupied`, `surveyed`, `log_N_total`, optional `age_index` | `site_occupancy.stan` | `fig_occupancy_heatmap()`, `fig_recolonization()` |
| Surveyed zero vs not surveyed | A reported zero is not automatically biological absence | Legacy + DFO spawn survey effort | `clean_spawn()`, `prepare_model_data()`, `prepare_censored_data()`, and occupancy prep | `Y_obs`, `Y_censored`, `Y_missing`; `occupied` / `surveyed` in occupancy model | `m1_stier_11` baseline treats zeros as ambiguous; threshold-aware models are sensitivities | occupancy and censored-observation diagnostics |

## Data Semantics That Matter

### 1. Spawn zeros are not all the same

This is the single most important semantic detail in the repository.

- In the data contract, positive spawn values are logged, while zero records can be carried as separate censored cells for sensitivity models.
- In the promoted `m1_stier_11` baseline, zero spawn records are treated as ambiguous/missing following Stier et al. (2020).
- A log-scale `NA` for a zero does not mean the site-year is missing in a scientific sense.
- The maintained cleaning path uses survey-effort columns to classify whether the site was:
  - surveyed and no spawning was found,
  - or not surveyed at all.

If a collaborator misses this distinction, they will misunderstand half of the model design.

### 2. Catch is sparse and indexed

Spawn observations exist on a full year-by-site grid after completion. Catch does not.

Instead of storing a dense likelihood over all cells, the code stores:

- the positions where catch was positive,
- the positions where catch was zero,
- the corresponding log-catch values.

That is why `build_catch_index()` and the `catch_row` / `catch_col` arrays exist.

### 3. Spatial covariates come in two forms

Predator pressure is represented in two distinct ways:

- region-level annual series for models where predators are assumed to affect all sections similarly,
- site-level spatially weighted matrices where predator effect depends on proximity to predator locations.

Those are both valid, but they answer different biological questions.

### 4. Site order is a hard contract

Almost every matrix in the project assumes that columns follow `SITE_NAMES` in exactly the order defined in `R/00_setup.R`.

Distance matrices, spawn matrices, catch matrices, posterior summaries, and spatial predator indices all depend on this alignment.

## Cleaned Data Objects and Their Meaning

| Object | Produced by | Shape | Meaning |
|---|---|---|---|
| `spawn$wide` | `clean_spawn()` | `N_YEARS x N_SITES` matrix | log positive spawn index; zeros and missing cells are `NA` only because the log transform is undefined |
| `spawn$long` | `clean_spawn()` | long tibble | section-year observations plus `survey_status` (`positive`, `censored_zero`, `missing`) |
| `catch$wide` | `clean_catch()` | `N_YEARS x N_SITES` matrix | raw spring catch with missing filled as zero |
| `catch$log_catch` | `clean_catch()` | `N_YEARS x N_SITES` matrix | `log(catch + 1)` |
| `pdo` | `clean_pdo()` | length `N_YEARS` vector | spring PDO anomaly |
| `predators` | `clean_predators()` | one row per year | annual predator indices |
| `distance_matrix` | `load_distance_matrix()` | `N_SITES x N_SITES` matrix | inter-section effective distance |
| `predator_spatial$ssl_spatial` | `build_predator_spatial_index()` | `N_YEARS x N_SITES` matrix | spatially weighted SSL exposure |
| `predator_spatial$seal_spatial` | `build_predator_spatial_index()` | `N_YEARS x N_SITES` matrix | spatially weighted seal exposure |
| `occupancy_data$occupied` | `prepare_occupancy_data()` | `N_YEARS x N_SITES` integer matrix | binary spawning occupancy |
| `occupancy_data$surveyed` | `prepare_occupancy_data()` | `N_YEARS x N_SITES` integer matrix | binary survey effort mask |

## How `prepare_model_data()` Bridges Theory and Stan

`prepare_model_data()` is the main integration hinge in the project.

It does three jobs:

1. enforce dimensions and alignment,
2. add observation masks and sparse catch indexing,
3. attach optional predator and spatial covariates in a version-agnostic way.

The output is deliberately a little richer than any one Stan model needs. `R/03_fit_model.R` then reduces that richer object to the exact contract required by `v1`, `m2`, `m5`, `m6`, or `v2`.

That separation is intentional:

- `prepare_model_data()` says what the scientific dataset is,
- `.build_stan_input()` says what a specific Stan file needs.

## Model Families and What Changes Across Them

### Baseline biomass model

File: [`inst/stan/herring_metapop_v1.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_v1.stan)

Adds:

- latent biomass states,
- catch adjustment,
- PDO effect,
- two survey catchabilities,
- independent process error.

### Spatial biomass models

Files: `m2`, `m3`, `m4`, `m5`, `m6`

Add progressively:

- distance-decay spatial covariance,
- density dependence,
- predator effects,
- time-varying spatial range.

### Occupancy model

File: [`inst/stan/site_occupancy.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/site_occupancy.stan)

Uses a different response entirely:

- binary occupancy,
- survey-effort mask,
- persistence and recolonization structure.

It is not just "the biomass model with fewer variables." It encodes a different theory.

## What a Collaborator Should Check Before Editing Models

Before changing any Stan file, check:

1. Which cleaned object supplies each variable?
2. Whether that variable is region-level or section-level.
3. Whether zeros carry biological meaning or are only placeholders for missingness.
4. Whether the column order is still `SITE_NAMES`.
5. Whether tests should be added in `tests/testthat/` to lock in the new contract.

## Recommended Extensions

The most natural future extensions are:

- integrating censored spawn observations into the continuous biomass model,
- adding age-structure data to the occupancy model,
- making the theory-to-figure mapping more explicit in manuscript-ready tables,
- migrating exploratory `Code/` scripts into maintained `R/` functions when they stabilize.

Those are easier once a collaborator understands the current theory-data-model split above.
