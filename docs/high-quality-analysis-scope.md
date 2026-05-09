# High-Quality Analysis Scope

This note separates what is ready now from what would materially improve the final Haida Gwaii herring analysis.

> Update, 2026-05-06
> Re-reading Stier et al. (2020) and the archived JAGS model changed the preferred baseline direction for zero-spawn records. Stier treated reported zero spawn as ambiguous/missing. Given the Haida Gwaii context, including years where survey absence may reflect governance/access decisions rather than low biomass, baseline models should treat zeros as ambiguous unless survey metadata explicitly justify a true nondetection interpretation.

> Update, 2026-05-08
> `m1_stier_11` has now been fit and promoted as the Stier-aligned practical baseline. Exact re-LOO resolved its single high Pareto-k point: the held-out 1970 Naden Harbour refit changed total LOOIC from 1953.02 to 1953.08 with no sampler pathologies.

## Ready Now

These are implemented or source-backed in the current workspace:

1. `m1_stier_11` is the promoted Stier-aligned baseline.
2. The data pipeline can distinguish positive observations, zero records, and unsurveyed/missing cells, but the preferred biological interpretation has changed: Stier-aligned baseline models should treat zero spawn as ambiguous/missing.
3. Source-backed `q` guidance is documented:
   local Okamoto support is for a tight `ln q ~ Normal(0, 0.05)`-style prior, not an unverified alternative center.
4. Additional DFO covariates can now be built directly from the raw spawn survey file:
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

Historical `v3` conclusion:

1. `m1_v3` is the only sampler-clean fit.
2. `m3_v3` and `m5_v3` both fail convergence / geometry checks.
3. all `v3` models underpredict surveyed zeros.

That comparison remains useful as a diagnostic of observation-model sensitivity, but it should not be read as a mandate to promote informative-zero models. Stier's zero-as-ambiguous decision and the Haida Gwaii survey governance context are now represented by `m1_stier_11`, with detection-aware zeros retained as a sensitivity.

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
   compare a Stier-aligned ambiguous-zero baseline against a detection-aware / left-censored zero sensitivity.
2. Sensitivity to section inclusion:
   fit or summarize the current 11-section analysis alongside the Stier 9-focal-subpopulation framing.
3. Sensitivity to the `q` prior:
   especially the survey-era split and the unit-dependent scale of `log.q`.
4. Sensitivity to survey method:
   compare the Stier two-era surface/SCUBA split with the current three-era surface/mixed/dive split if the transition years are influential.

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

1. Use `m1_stier_11` as the baseline for practical reporting.
2. Add the Stier 9-focal-subpopulation reporting sensitivity from the 11-section fit.
3. Run detection-aware / informative-zero models only as sensitivity analyses.
4. Compare current `spawn_index_tonnes` results against a legacy-SHI-scale sensitivity if the old SHI scale can be restored cleanly.
5. Only after the observation/data-scale branch is stable, test timing / habitat covariates and revisit richer predator or site-specific process structure.
