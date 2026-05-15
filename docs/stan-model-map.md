# Stan Model Map

This document tells a first-time collaborator which files in `inst/stan/` are part of the current maintained workflow and which ones are older variants or generated artifacts.

## Read These First

These are the primary Stan source files that match the maintained R interfaces:

- [`inst/stan/herring_metapop_v1.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_v1.stan)
- [`inst/stan/herring_metapop_m2_distance.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m2_distance.stan)
- [`inst/stan/herring_metapop_m3_dd_global.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m3_dd_global.stan)
- [`inst/stan/herring_metapop_m4_dd_site.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m4_dd_site.stan)
- [`inst/stan/herring_metapop_m5_predators.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m5_predators.stan)
- [`inst/stan/herring_metapop_m6_timevarying.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m6_timevarying.stan)
- [`inst/stan/site_occupancy.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/site_occupancy.stan)

These are the files whose `data {}` contracts are explicitly supported by [`R/03_fit_model.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/03_fit_model.R) and described in [`docs/theory-data-model-integration.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/theory-data-model-integration.md).

## Important Special Case

- [`inst/stan/herring_metapop_v2.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_v2.stan) is still supported by `fit_model(version = "v2")`, but it is best treated as a reference or transitional model rather than the main path in `_targets.R`.

## Stier-Aligned Baseline Direction

The current promoted Stier-aligned branch is:

- [`inst/stan/herring_metapop_m1_stier_11.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m1_stier_11.stan)
- [`Code/03_fit_m1_stier_11.R`](/Users/adrianstier/stier-2027-herring-metapopulation/Code/03_fit_m1_stier_11.R)

As of 2026-05-08, `m1_stier_11` is the promoted practical baseline. It treats
zero spawn records as ambiguous/missing, fits all 11 Haida Gwaii sections, uses
the Stier-style two-era surface/SCUBA survey `q` split, and holds size/age
structure, predators, and density dependence out of the baseline. Its one high
Pareto-k point was resolved by exact re-LOO: the held-out 1970 Naden Harbour
refit changed total LOOIC from 1953.02 to 1953.08 with no sampler pathologies.

The completed May 9 process branch is:

- [`inst/stan/herring_metapop_m2_stier_site_growth.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m2_stier_site_growth.stan)
- [`Code/03_fit_m2_stier_site_growth.R`](/Users/adrianstier/stier-2027-herring-metapopulation/Code/03_fit_m2_stier_site_growth.R)

`m2_stier_site_growth` keeps the `m1_stier_11` observation layer unchanged and
adds hierarchical section-specific productivity `U[j]`. It finished
sampler-clean, but it is held rather than promoted: PSIS-LOO was unstable
(max Pareto k `0.842`, five points above `0.7`), positive-spawn calibration did
not improve, and the section-productivity estimates were strongly pooled.

The completed May 9 observation-sensitivity branch is:

- [`inst/stan/herring_metapop_m1_stier_method_sensitivity.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m1_stier_method_sensitivity.stan)
- [`Code/03_fit_m1_stier_method_sensitivity.R`](/Users/adrianstier/stier-2027-herring-metapopulation/Code/03_fit_m1_stier_method_sensitivity.R)

`m1_stier_method_sensitivity` keeps the `m1_stier_11` process and
ambiguous-zero likelihood but estimates three q terms for surface,
mixed-transition, and dive-dominant years. It finished sampler-clean, but it is
held rather than promoted: PSIS-LOO was unstable (max Pareto k `0.866`, seven
points above `0.7`) and aggregate positive-spawn RMSE was worse than
`m1_stier_11` (`0.569` versus `0.565`). Its q medians are useful descriptive
checks: surface `0.187`, mixed transition `0.623`, and dive-dominant `0.278`.

The completed May 9 distance-covariance branch is:

- [`inst/stan/herring_metapop_m3_stier_distance.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m3_stier_distance.stan)
- [`Code/03_fit_m3_stier_distance.R`](/Users/adrianstier/stier-2027-herring-metapopulation/Code/03_fit_m3_stier_distance.R)

`m3_stier_distance` keeps the `m1_stier_11` observation layer unchanged and
adds a one-parameter distance-decay covariance for annual process shocks. It
finished sampler-clean and estimated a median practical process-correlation
range of about `144` km, but it is held rather than promoted: positive-spawn
calibration improved only slightly (`0.556` aggregate log10 RMSE versus `0.565`
for `m1_stier_11`). Exact re-LOO completed for the three high-k points, but one
exact refit had treedepth pressure, so the branch remains spatial context
rather than a promoted inference model.

The prepared May 14 predator-demand branch is:

- [`inst/stan/herring_metapop_m5_stier_predator_demand_total.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/herring_metapop_m5_stier_predator_demand_total.stan)
- [`Code/03_fit_m5_stier_predator_demand_total.R`](/Users/adrianstier/stier-2027-herring-metapopulation/Code/03_fit_m5_stier_predator_demand_total.R)

`m5_stier_predator_demand_total` keeps the `m1_stier_11` observation layer and
uses total HG predator demand, `z(log1p(C_total_kt))`, rather than the
observed-spawn pressure ratio. It is manifest-gated as `planned_model_fit`;
the WCVI bridge diagnostic supports demand as the cleaner covariate, but the
adjusted demand signal is weak enough that cloud submission should be a
deliberate single-covariate screen, not an automatic next run. A longer local
smoke had baseline-like heavy geometry: no divergences, no max-treedepth hits,
but all draws at treedepth `14`.

Future model branches should preserve the following distinction:

- A **Stier-aligned baseline** should treat zero spawn records as ambiguous/missing, use explicit survey-era `q` terms, and avoid size/age structure.
- A **detection-aware sensitivity** may treat selected zero records as informative nondetections, but only if the report states that interpretation clearly.

This distinction matters because the current Haida Gwaii survey process includes non-biological causes of missing effort, including governance/access decisions. Do not let missing survey effort imply low biomass.

Also keep the section-count distinction explicit:

- Stier fit the state-space model to 11 subpopulations.
- Stier focused interpretation and figures on 9 data-rich focal subpopulations.
- New Stan/data branches should make 11-section fitting and 9-focal reporting choices explicit in names and outputs.

## Forward Stan Branches To Build Next

The next Stan files should be new `*_stier_*` branches that inherit the
`m1_stier_11` observation model. Do not revive older `v3`/`v5` variants as
promotion candidates unless they are refit under the same zero and survey-method
assumptions.

The literature/NotebookLM roadmap is summarized in
[`docs/literature-parameter-roadmap.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/literature-parameter-roadmap.md).
It points to observation calibration before new biological-driver branches.

Recommended branch order:

1. `herring_metapop_m2_stier_site_growth.stan`
   - completed May 9 and held,
   - section-specific productivity did not explain the scorecard.
2. `herring_metapop_m1_stier_method_sensitivity.stan`
   - completed May 9 and held,
   - same process as `m1_stier_11`,
   - compared two-era `q` with three-era surface/mixed/dive `q`.
3. `herring_metapop_m3_stier_distance.stan`
   - completed May 9 and held after exact re-LOO,
   - distance-decay process covariance,
   - same Stier observation layer,
   - exact re-LOO completed for 3 high-k points, but one exact refit had
     treedepth pressure and the positive-spawn fit gain is too small for
     promotion.
4. `herring_metapop_m1_stier_obs_hier.stan`
   - completed May 11 and held,
   - same `m1_stier_11` process, ambiguous-zero likelihood, 11 sections,
     Stier two-era `q`, lagged PDO, and catch removal,
   - added hierarchical section-specific observation error `sigma_obs[j]`,
   - added method-specific positive-observation scale, especially extra
     surface-era variance,
   - sampler-clean but not promoted because positive-spawn RMSE worsened and
     PSIS became less stable.
5. `herring_metapop_m2_stier_site_growth_regularized.stan`
   - fallback only if section productivity becomes necessary again,
   - tighter pooling or simpler section grouping.
6. `herring_metapop_m2_stier_process_variance.stan`
   - section-specific process variance with strong pooling,
   - only after the observation-calibration branch stays sampler-clean.
7. `herring_metapop_m4_stier_dd.stan`
   - global density dependence,
   - only after spatial re-LOO and observation calibration justify moving past
     the baseline.
8. `herring_metapop_m5_stier_timing_habitat.stan`
   - lagged spawn timing and substrate covariates,
   - first as observation/reporting or phenology/habitat sensitivity.
9. `herring_metapop_m5_stier_predator_demand_total.stan`
    - prepared May 14 as a gated predator-demand screen,
    - use only as a single-covariate test against `m1_stier_11`,
    - do not combine predator groups or pressure ratios in this branch.
10. `herring_metapop_m6_stier_predator_exposure.stan`
    - predator covariates only after a spatial exposure data product exists and
      process/observation calibration remain stable.

Keep full section-level age/size structure out of this sequence. Age composition
and weight-at-age can later inform priors, regional covariates, or external
checks.

## Archival or Experimental Variants

Files such as these are useful provenance, but they are not the first files a collaborator should learn:

- `herring_metapop_m1.stan`
- `herring_metapop_m1_v2.stan`
- `herring_metapop_m1_v3.stan`
- `herring_metapop_m1_priortest.stan`
- `herring_metapop_m2_v2.stan`
- `herring_metapop_m3_v2.stan`
- `herring_metapop_m3_v3.stan`
- `herring_metapop_m3_v4.stan`
- `herring_metapop_m5_combined.stan`
- `herring_metapop_m5_v2.stan`
- `herring_metapop_m5_v3.stan`

They are retained because they document prior model experiments, prior-sensitivity work, or alternate parameterizations that may still be scientifically interesting.

## Generated Artifacts

These files are not source-of-truth model code:

- `*.hpp`
- `*.rds`

They are generated by Stan or CmdStan tooling and are useful for compilation/runtime workflows, but collaborators should not start by reading or editing them.

## Practical Reading Order

1. Read [`R/02_prepare_model_data.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/02_prepare_model_data.R).
2. Read [`R/03_fit_model.R`](/Users/adrianstier/stier-2027-herring-metapopulation/R/03_fit_model.R), especially `.build_stan_input()`.
3. Read `v1`, then `m2`, then `m3`, `m4`, `m5`, `m6`.
4. Read [`inst/stan/site_occupancy.stan`](/Users/adrianstier/stier-2027-herring-metapopulation/inst/stan/site_occupancy.stan) as a separate theory branch.
5. Ignore archival `.stan`, `.hpp`, and `.rds` files until you need provenance or model-history context.
