# Session Log 2026-05-14

## AWS Batch completion sweep

- User refreshed AWS SSO for profile `herring`; verified identity as account
  `107094296950` with the `AdministratorAccess` SSO role in `us-east-1`.
- Polled the May 13 Batch manifests:
  - `cloud/aws_batch_runs/2026-05-13-round1-ondemand.csv`;
  - `cloud/aws_batch_runs/2026-05-13-round1-spot.csv`.
- Final May 13 status:
  - succeeded: `m1_stier_11`, `m2_stier_site_growth`,
    `m3_stier_distance`, `m5_stier_predation_pressure`,
    `m1_stier_method_sensitivity`, `m5_combined`, `m5_v5`,
    `smoke_cloud_pipeline`, and
    `smoke_m5_stier_predation_pressure_reduced`;
  - failed/incomplete: `m3_stier_distance_reloo` array.
- Synced the May 13 S3 prefix from
  `s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-13`
  into local cloud staging.
- Promoted the completed `m5_combined` job artifacts into the local analysis
  paths, then reran the audit/PPC/comparison/interpretation stack.

## Diagnostics and decisions

- `m1_stier_11` remains the promoted baseline.
- `m5_stier_predation_pressure` remains held: sampler-usable and
  baseline-equivalent on positive-spawn and catch fit.
- `m5_v5` remains archived: substantial divergences and treedepth hits.
- `m5_combined` is now archived:
  - `0` divergences;
  - `4000` max-treedepth hits out of `4000` post-warmup transitions;
  - max R-hat about `1.037`;
  - max Pareto k about `0.826`;
  - positive-spawn log RMSE about `2.37`;
  - catch log RMSE about `0.28`.
- Do not spend exact re-LOO or combination-model time on `m5_combined`.
- The `m3_stier_distance_reloo` cloud array failed/incomplete, but local exact
  re-LOO for `m3_stier_distance` already exists and the branch remains held.

## Implementation fixes

- Fixed the `m5_combined` fit script to save an explicit
  `Data/processed/m5_combined_fit.rds` in addition to the historical
  `Data/processed/m5_fit.rds` alias.
- Fixed `cloud/model-farm-manifest.csv` so the `m5_combined` expected artifact
  list uses the explicit model-specific fit path and its notes field remains a
  valid quoted CSV field.
- Fixed the Bayesian audit registry so `m5_combined` is checked against the
  actual fit control `max_treedepth = 14`; the previous registry value of `15`
  missed the treedepth saturation.
- Updated comparison/status scripts so `m5_combined` is archived by the same
  sampler, positive-spawn, and catch-fit gates as the other branches.
- Added `Code/07bi_model_decision_ledger.R`, which writes:
  - `Output/diagnostics/model_decision_ledger.csv`;
  - `Output/diagnostics/model_decision_ledger.md`.

## AWS notes for next cycle

- Do not run multiple `cloud/watch_aws_batch_run.py --sync-s3-prefix` commands
  against the same prefix at the same time. Poll all manifests first, then run
  one S3 sync, or sync from one watcher only.
- The old cloud `m5_combined` run produced `Data/processed/m5_fit.rds` but did
  not stage `Data/processed/m5_combined_fit.rds`; a local alias was created
  after promotion, and the source/manifest are fixed for future runs.
- Treat manifest artifact names and audit `max_treedepth` settings as part of
  the model contract: mismatches can make cloud summaries or diagnostics look
  healthier than they are.

## May 14 continuation / Saturday talk handoff

- Refreshed AWS state with profile `herring`; `sts get-caller-identity`
  confirmed account `107094296950` and the `AdministratorAccess` SSO role.
- Re-polled the May 13 Batch manifests:
  - on-demand core jobs all remain `SUCCEEDED`;
  - spot jobs all remain `SUCCEEDED` except `m3_stier_distance_reloo`, which is
    `FAILED`;
  - S3 prefix `s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-13`
    was synced once to local cloud staging.
- Rebuilt `Output/diagnostics/cloud_model_farm_status.csv` from the synced May
  13 results, then regenerated the model-decision ledger.
- No next targeted single-covariate AWS screen is justified before the Saturday
  May 16 talk:
  - `m1_stier_11` remains the promoted baseline;
  - `m5_stier_predation_pressure` is held after the completed cloud result;
  - timing/substrate remains screen-only because missingness and survey-method
    confounding are still strong;
  - density dependence remains weak in descriptive screens;
  - the failed cloud `m3_stier_distance_reloo` array should not be relaunched
    now because local exact re-LOO already exists and the branch remains held;
  - do not spend exact re-LOO or combination-model time on `m5_combined`.
- Updated the collaborator quickstart to remove stale "run next" language for
  `m5_stier_predation_pressure`.
- Added `docs/saturday-talk-readiness-2026-05-16.md` as the current talk
  handoff: talk spine, model-farm decision, numbers to keep handy, and figure
  order.
