# v5 Covariate Rationale

This note records which DFO-derived covariates are appropriate for the next model layer and which are not.

## Included In v5 Process Candidates

The current `v5` model candidates use two lagged, standardized regional covariates:

1. `weighted_spawn_start_doy`
2. `subtidal_share`

Reason:

- both are interpretable as year-level phenology / habitat-structure descriptors,
- both vary over time,
- neither is just a rescaled version of total spawn biomass,
- and using them lagged in the process equation is more defensible than using same-year summaries.

## Excluded From The v5 Process Equation

These are intentionally not entering the first `v5` process model:

1. `occupied_sections`
2. `surveyed_zero_sections`
3. `total_spawn_index_tonnes`
4. survey-method composition summaries

Reason:

- they are too close to the observation stream already used in `Y`,
- they risk double-using survey information,
- or they belong more naturally in posterior predictive checks or observation-model refinement.

## Prior Strategy

The `v5` models use regularizing priors on covariate effects after z-scoring:

- `beta_cov ~ normal(0, 0.3)`

Interpretation:

- a 1 SD shift in timing or substrate share is assumed a priori to have a modest effect on log-scale biomass dynamics,
- and the model has to earn larger effects from the data.
