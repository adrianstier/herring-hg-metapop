# Session Log 2026-05-13

## AWS model farm restart and dependency cleanup

- Verified AWS SSO profile `herring` after user re-login.
- Submitted May 13 model-farm round to
  `s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-13`.
- Confirmed current AWS Batch state:
  - `smoke_cloud_pipeline`: succeeded;
  - `smoke_m5_stier_predation_pressure_reduced`: succeeded;
  - `m1_stier_11`, `m2_stier_site_growth`, `m1_stier_method_sensitivity`,
    and `m5_v5`: running;
  - `m3_stier_distance`, `m5_stier_predation_pressure`, and `m5_combined`:
    runnable / waiting for capacity.
- Diagnosed the immediate `m3_stier_distance_reloo` array failure: it launched
  before `m3_stier_distance` had produced
  `Output/posteriors/loo_m3_stier_distance.rds`.
- Patched `cloud/submit_today_model_rounds.sh` so first-round submissions no
  longer include `m3_stier_distance_reloo`.
- Patched `Code/04g_m3_stier_distance_exact_reloo.R` so follow-up cloud re-LOO
  jobs can fetch the source LOO artifact from
  `S3_PREFIX/jobs/m3_stier_distance/Output/posteriors/` when missing locally.
- Added `cloud/submit_m3_reloo_after_distance.sh`, a follow-up launcher that
  refuses to submit the array until the required source LOO artifact exists in
  S3.
- Added `cloud/aws_results/` to `.gitignore`; synced Batch result downloads are
  staging artifacts, not maintained source files.
- Updated model-farm docs to record the dependency-ordering failure and the
  future rule: do not submit exact re-LOO arrays until source model artifacts
  exist.

## Fit-and-diagnostics gates

- Added catch-fit metrics to the generic posterior predictive check script:
  `catch_log_rmse` and `catch_log_bias`.
- Updated model comparison so promotion requires sampler health, resolved LOO,
  positive-spawn magnitude fit, and catch accounting consistency.
- Fixed `cloud/summarize_model_farm_results.py` so array-child output folders
  such as `m3_stier_distance_reloo_rank001` are no longer incorrectly matched
  to the parent `m3_stier_distance` manifest row.
- Reran `Code/03d_posterior_predictive_checks_v3.R` and
  `Code/04_compare_models_v3.R`.
- Current local decision after the regenerated comparison:
  - `m1_stier_11` remains the promoted baseline;
  - sampler diagnostics are clean (`0` divergences, `0` treedepth hits, max
    R-hat about `1.001`);
  - positive-spawn log RMSE is about `0.565`;
  - catch log RMSE is about `0.010`;
  - process/sensitivity branches are held unless they improve data fit without
    creating diagnostics problems.
