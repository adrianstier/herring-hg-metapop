# High-Quality Analysis Scope

This note separates what is ready now from what would materially improve the final Haida Gwaii herring analysis.

## Ready Now

These are implemented or source-backed in the current workspace:

1. `m1_v3` is complete and improves on `m1_v2`.
2. `m3_v3` and `m5_v3` are the source-backed next candidate models.
3. Surveyed zeros are retained rather than silently dropped.
4. Source-backed `q` guidance is documented:
   local Okamoto support is for a tight `ln q ~ Normal(0, 0.05)`-style prior, not an unverified alternative center.
5. Additional DFO covariates can now be built directly from the raw spawn survey file:
   - spawn timing,
   - substrate composition,
   - method composition.

## Current Bayesian Checks

The workflow is now producing explicit audit and posterior-predictive outputs:

- [bayesian_fit_audit_v3.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Output/diagnostics/bayesian_fit_audit_v3.csv)
- [posterior_predictive_summary_v3.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Output/diagnostics/posterior_predictive_summary_v3.csv)
- [posterior_predictive_by_year_v3.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Output/diagnostics/posterior_predictive_by_year_v3.csv)

Current read after the full `v3` comparison:

1. sampler health is good:
   - `0` divergences,
   - `0` treedepth hits,
   - max Pareto `k < 0.5`,
   - E-BFMI comfortably above the usual warning threshold.
2. predictive calibration is not yet good enough:
   - the model predicts too many positive survey detections, and
   - it materially underpredicts surveyed zeros / below-detection years.

That comparison is now complete and documented in
[v3-model-comparison-results.md](/Users/adrianstier/stier-2027-herring-metapopulation/docs/v3-model-comparison-results.md).

Current conclusion:

1. `m1_v3` is the only sampler-clean fit.
2. `m3_v3` and `m5_v3` both fail convergence / geometry checks.
3. all `v3` models underpredict surveyed zeros.

So the next serious model should target the observation process first, not add more process complexity on top of unstable fits.

## Built For The Next Round

The following tables are intended to feed the next model iteration:

- [dfo_spawn_covariates_section_1951_2025.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Data/processed/dfo_spawn_covariates_section_1951_2025.csv)
- [dfo_spawn_covariates_region_1951_2025.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Data/processed/dfo_spawn_covariates_region_1951_2025.csv)
- [dfo_data_stream_inventory.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Data/processed/dfo_data_stream_inventory.csv)

Highest-value covariates to test first:

1. `weighted_spawn_start_doy`
2. `subtidal_share`
3. `substrate_effective_n`
4. `occupied_sections` as a posterior predictive target, not a first-pass process covariate

The first `v5` process candidates should use lagged, standardized timing / habitat covariates only.
`occupied_sections` should stay in posterior predictive checking unless a stronger identification strategy is introduced.

## What Would Make The Analysis Much Stronger

### Model evaluation

1. Use time-blocked or rolling-origin validation, not only PSIS-LOO.
   State-space time series can look better under LOO while still forecasting poorly.
2. Add posterior predictive checks for:
   - section occupancy,
   - total spawn index,
   - section share composition,
   - years with many surveyed zeros.
3. Report model-selection uncertainty, not only the single best model.

### Structural sensitivity

1. Sensitivity to zero treatment:
   compare left-censored zeros against at least one alternative detection specification.
2. Sensitivity to section inclusion:
   compare the current 11-section analysis against the earlier 9-subpopulation framing.
3. Sensitivity to the `q` prior:
   especially the dive-era scaling term.

### Additional DFO data that would materially improve the analysis

These are high-value, but they are not packaged locally in usable form:

1. annual age composition from commercial plus test-fishery samples,
2. annual weight-at-age,
3. raw test-fishery biological series.

Best use once obtained:

- regional covariates on cohort strength and body condition,
- informative priors on productivity or biomass scaling,
- possibly a stock-area age-structured cross-check.

They do not, by themselves, justify a full 11-section age-structured model at this stage.

## Recommended Next Sequence

1. Treat `m1_v3` as the current reference model.
2. Build a next-round model that improves the surveyed-zero / detection formulation on the stable baseline.
3. Re-run audit plus posterior predictive checks and confirm the zero-process calibration improves.
4. Only after that, test the `v5` timing / habitat covariates.
5. Revisit richer predator / site-specific process structure only if the simpler observation-model revision stays sampler-clean.
