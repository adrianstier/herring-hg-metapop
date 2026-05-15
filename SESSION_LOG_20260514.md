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

## Predator integration deep dive

- Reviewed the existing predator stack:
  - legacy regional indices in `Data/processed/predator_indices.csv`;
  - audited HG predator-repo products imported by
    `Code/02c_integrate_hg_predator_repo_products.R`;
  - the held Stier-aligned branch `m5_stier_predation_pressure`;
  - section-level exposure and lead-location proximity diagnostics.
- Pulled the full-fit `m5_stier_predation_pressure` coefficient summary:
  `predcoef` median about `-0.079`, 90% interval about `-0.136` to `-0.020`;
  the branch stays held because calibration is effectively unchanged from
  `m1_stier_11`.
- Identified the main predator-integration issue: the current Stan covariate
  `pred_pressure_log_z` is standardized `log(pressure_pct + 1)`, where
  `pressure_pct = predator consumption / HG spawn`. That is a useful
  descriptive pressure metric but is partly endogenous as a simple process
  covariate because the denominator is observed herring spawn.
- Fixed `Code/07bb_predator_spatial_exposure_prototype.R` so
  predator-exposure growth correlations join exposure to model biomass by
  `section_name`, not by raw DFO section code. The previous join only matched
  the first three model sites; the refreshed 50 km screen now uses all 11
  sections (`77` harbour seal section-years and `143` Steller sea lion
  section-years).
- Reran:
  - `Rscript --vanilla Code/07bb_predator_spatial_exposure_prototype.R`;
  - `Rscript --vanilla Code/07bc_section_recovery_covariate_screen.R`.
- Added `docs/predator-analysis-integration-roadmap.md`, which recommends
  separating predator demand (`C_total_kt` and group-specific consumption) from
  predator pressure ratios before any next predator Stan branch.

## WCVI predation-replication bridge

- Identified the relevant WCVI paper as Doherty et al. 2025, *Predation by
  marine mammals explains recent trends in natural mortality of Pacific
  Herring and changes expectations for future biomass*, ICES Journal of Marine
  Science, doi:10.1093/icesjms/fsae183.
- Added `docs/wcvi-predation-replication-bridge.md` and
  `Code/07bj_wcvi_predation_replication_bridge.R` to translate the WCVI
  approach into the HG/Stier model scale without adding unsupported
  age-structured machinery.
- The bridge uses audited HG predator consumption as annual demand, computes
  WCVI-style removal-rate analogues against `m1_stier_11` biomass, and scores
  predator demand with future-demand negative controls.
- Current bridge read:
  - mean 2015-2024 HG predator consumption is about `15.5` kt/yr;
  - mean 2015-2024 predator-removal analogue is about `25%` against
    `m1_stier_11` biomass;
  - lag-1 total predator demand has Spearman rho about `-0.30` with next-year
    latent growth, but detrended r is only about `-0.05` and adjusted beta is
    near zero after PDO, fishing fraction, and year.
- Updated `Code/02c_integrate_hg_predator_repo_products.R` to export
  `pred_demand_total_log_z` alongside `pred_pressure_log_z`. Total demand is
  model-ready; group-specific demand remains partially observed and should be
  screened with explicit missingness rather than silently carried forward.
- Prepared the gated next model branch:
  - `inst/stan/herring_metapop_m5_stier_predator_demand_total.stan`;
  - `Code/03_fit_m5_stier_predator_demand_total.R`;
  - manifest row `m5_stier_predator_demand_total` as `planned_model_fit`;
  - smoke row `smoke_m5_stier_predator_demand_total_reduced`.
- Local reduced smoke completed, confirming the Stan/data contract, but the
  short smoke had `80` post-warmup max-treedepth hits and low E-BFMI. Treat
  this as another reason not to submit a heavy AWS run automatically.
- Updated the demand-branch initialization to start near the promoted
  Stier-layer posterior scale (`sigma_obs`, `log_q`, `Umu`, `pdocoef`) rather
  than the older low-observation-error smoke values.
- A longer-warmup local smoke (`HERRING_SMOKE=1`, `STAN_ITER=650`,
  `STAN_WARMUP=550`, one chain) completed with `0` divergences, `0`
  max-treedepth hits at max treedepth `15`, E-BFMI about `1.03`, and all `100`
  saved draws at treedepth `14`. This is expensive but matches the baseline
  model family's heavy geometry better than the short smoke.
- This branch keeps ambiguous zeros, the Stier two-era q split, all 11
  sections, and `m1_stier_11` as baseline. It is technically ready for a
  deliberate full AWS single-covariate screen, but should not be submitted
  automatically because the adjusted diagnostic signal is weak.
- Refreshed AWS identity/queue state after preparing the branch:
  - profile `herring` still resolves to account `107094296950`;
  - on-demand and spot queues had no `SUBMITTED`, `PENDING`, `RUNNABLE`,
    `STARTING`, or `RUNNING` jobs;
  - no new AWS job was submitted.
- A later AWS refresh attempt failed because the `herring` SSO token expired
  and the browser login could not be completed from this runtime. No AWS
  submission record was created.

## Predator-demand AWS submission

- Refreshed AWS SSO using the device-code flow for profile `herring`;
  `sts get-caller-identity` again resolved to account `107094296950`.
- Initial upload attempt for the predator-demand run exposed a packaging bug:
  `cloud/make_cloud_bundle.sh` copied `cloud/aws_results/` into the next
  bundle, producing a `10.7` GiB tarball full of old fit artifacts.
- Fixed `cloud/make_cloud_bundle.sh` so generated cloud staging directories
  and `.rds` files are excluded globally. The clean bundle is about `38` MiB.
- Uploaded the clean bundle to:
  `s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-14-predator-demand-total`.
- Submitted only `m5_stier_predator_demand_total` through the model-farm
  manifest with `--include-planned`; no combination branch was submitted.
- AWS Batch job:
  `da5908a1-e3f3-4add-be86-b8db55530640`.
- Started `cloud/watch_aws_batch_run.py`; first observed state was `RUNNABLE`.
