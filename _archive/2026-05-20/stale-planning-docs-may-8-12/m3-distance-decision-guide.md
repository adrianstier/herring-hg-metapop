# M3 Distance-Covariance Decision Guide

Generated during the May 9, 2026 sprint after `m3_stier_distance` finished.

## Branch Purpose

`m3_stier_distance` keeps the promoted `m1_stier_11` observation layer:

- ambiguous zeros are skipped,
- positive spawn uses the Stier-style two-era surface/SCUBA q split,
- all 11 sections are fitted,
- age/size, predator, and density-dependence terms are held out.

The only process change is a distance-decay covariance for annual process
shocks. This tests whether nearby sections share unmeasured process variation
before adding more biological covariates.

## Current Result

Status: hold, do not promote yet.

Reasons:

- sampler health is clean: `0` divergences, `0` treedepth hits, max R-hat
  about `1.001`, minimum E-BFMI about `0.803`;
- the distance estimate is biologically interpretable: median practical range
  about `144` km, 90% interval about `100` to `222` km;
- positive-spawn calibration improves only slightly over `m1_stier_11`:
  aggregate log10 RMSE `0.556` versus `0.565`;
- PSIS-LOO still needs exact checking: max Pareto k `0.813`, with `3` points
  above `0.7`.

## Correct High-K Points

Use the year-major Stan `log_lik` order. The high-k points are:

| log_lik_index | year | site | observed spawn | Pareto k |
|---:|---:|---|---:|---:|
| 117 | 1970 | Naden Harbour | 3.2 | 0.813 |
| 487 | 2024 | Englefield Bay | 253.3 | 0.728 |
| 82 | 1965 | Skidegate Inlet | 0.3 | 0.709 |

Earlier scratch output mislabeled these points by using the wrong observation
order. The corrected table is
`Output/diagnostics/m3_stier_distance_pareto_k_points.csv`.

## Exact Re-LOO

The exact re-LOO script is:

- `Code/04g_m3_stier_distance_exact_reloo.R`

By default, it runs full exact refits with 4 chains, 4500 iterations, 2000
warmup, `adapt_delta = 0.97`, and `max_treedepth = 15`. The script now also
accepts environment variables for clearly labeled triage runs without changing
the exact default:

```sh
M3_DISTANCE_RELOO_LABEL=triage \
M3_DISTANCE_RELOO_CHAINS=2 \
M3_DISTANCE_RELOO_ITER=1500 \
M3_DISTANCE_RELOO_WARMUP=750 \
M3_DISTANCE_RELOO_CORES=2 \
Rscript Code/04g_m3_stier_distance_exact_reloo.R
```

A triage run should be treated as a decision aid only. Use the default exact
run for final model-comparison claims.

It writes incremental results to:

- `Output/diagnostics/m3_stier_distance_exact_reloo.csv`

and each held-out refit to:

- `Data/processed/m3_stier_distance_exact_reloo_idx*_fit.rds`

If `M3_DISTANCE_RELOO_LABEL` is not `exact`, outputs use that label, for
example:

- `Output/diagnostics/m3_stier_distance_triage_reloo.csv`
- `Data/processed/m3_stier_distance_triage_reloo_idx*_fit.rds`

After exact re-LOO or a labeled triage re-LOO completes, rerun:

```sh
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
Rscript Code/07s_m3_stier_distance_postfit.R
```

Or launch the lightweight watcher:

```sh
zsh Code/04_wait_for_m3_stier_distance_exact_reloo_and_refresh.sh
```

The watcher is label-aware. For a triage run, use:

```sh
M3_DISTANCE_RELOO_LABEL=triage \
zsh Code/04_wait_for_m3_stier_distance_exact_reloo_and_refresh.sh
```

It sleeps until all high-k rows are present, then refreshes the model
comparison, interpretation, distance postfit, driver triage, headline findings,
and integrated evidence matrix.

## Promotion Gate

Promote `m3_stier_distance` only if all are true:

1. exact re-LOO leaves it clearly competitive within the positive-only
   likelihood unit;
2. exact refits are sampler-clean;
3. positive-spawn calibration is not worse than `m1_stier_11`;
4. the distance parameter remains interpretable and not prior-dominated;
5. the branch clarifies the ecological story enough to justify added process
   complexity.

If it fails any of those gates, keep `m1_stier_11` as the practical baseline and
use the distance-range posterior only as descriptive ecological context.
