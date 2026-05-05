# v3 Model Comparison Results

Date finalized: April 4, 2026

This note records the first full `v3` comparison after `m1_v3`, `m3_v3`, and `m5_v3` all finished and the audit/PPC scripts were rerun.

## Bottom Line

`m1_v3` is the only fit that is currently trustworthy enough to use for inference.

`m3_v3` and `m5_v3` are not credible analysis endpoints because they fail basic sampler-health thresholds before model-selection questions even matter.

## Audit Summary

From [bayesian_fit_audit_v3.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Output/diagnostics/bayesian_fit_audit_v3.csv):

### m1_v3

- divergences: `0`
- treedepth hits: `0`
- max R-hat: `1.001`
- min E-BFMI: `0.677`
- max Pareto `k`: `0.471`
- `LOOIC`: `1885.56`

Interpretation:

- sampler-clean,
- PSIS-LOO usable,
- currently the only model that passes a basic Bayesian quality gate.

### m3_v3

- divergences: `155`
- treedepth hits: `7433`
- max R-hat: `1.191`
- min bulk ESS: `11.1`
- max Pareto `k`: `0.703`
- `LOOIC`: `1893.43`

Interpretation:

- not converged,
- geometry still problematic,
- and predictive fit is worse than `m1_v3` anyway.

### m5_v3

- divergences: `94`
- treedepth hits: `9692`
- max R-hat: `17.18`
- min bulk ESS: `2.01`
- min E-BFMI: `0.0168`
- max Pareto `k`: `2.60`
- `LOOIC`: `2932.72`

Interpretation:

- unusable for inference,
- severe pathologies,
- and much worse predictive fit than both other models.

## Posterior Predictive Check Summary

From [posterior_predictive_summary_v3.csv](/Users/adrianstier/stier-2027-herring-metapopulation/Output/diagnostics/posterior_predictive_summary_v3.csv):

Observed surveyed-below-detection zeros: `19`

Predicted median surveyed-below-detection zeros:

- `m1_v3`: `6`
- `m3_v3`: `4`
- `m5_v3`: `3`

Interpretation:

- all three models underpredict surveyed zeros,
- and the richer models actually make that calibration problem worse.

## Decision

Do not move directly from `m3_v3` / `m5_v3` into `m3_v5` / `m5_v5`.

That would add process complexity on top of models that are already failing the posterior geometry checks.

## Recommended Next Step

The next model should be a stable-baseline observation-model revision, not a more complex process model.

Priority order:

1. keep `m1_v3` as the current reference model,
2. build an `m1_v4` or similar model focused on the zero process,
3. only revisit richer spatial/predator structure after that model is sampler-clean.

Most defensible target for the next round:

- a stronger detection / censored-observation formulation for surveyed zeros,
- while keeping the simpler `m1` process structure that already samples well.
