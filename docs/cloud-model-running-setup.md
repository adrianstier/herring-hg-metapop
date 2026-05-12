# Cloud Model Running Setup

Generated: 2026-05-10

This is the practical setup for running the Haida Gwaii herring Stan model
branches on cloud machines.

## Bottom Line

Cloud will speed up model **throughput** more than single-chain speed.

Use cloud for:

- independent model branches;
- exact re-LOO holdouts;
- short parameterization smoke tests;
- sensitivity grids over priors, `adapt_delta`, and centered/non-centered
  choices.

Do not expect cloud to fix:

- divergences caused by bad posterior geometry;
- q / observation-error identifiability;
- predator/time confounding;
- weak section-level data support.

## Recommended Path

### Today / fastest path: EC2 plus S3

This is the least infrastructure:

1. Create an S3 prefix for bundles and results.
2. Upload a repo bundle with `cloud/upload_bundle_to_s3.sh`.
3. Launch one EC2 instance per model job.
4. Use `cloud/ec2_user_data_template.sh` as user-data.
5. Let each instance run one job, sync outputs to S3, then shut itself down.

This is enough for the current sprint because most jobs are independent.

### Robust path: AWS Batch

Use AWS Batch when we want to farm many independent model branches, exact
re-LOO refits, and sensitivity variants at once. Batch is the right shape for
this project because each model variant can be a separate job and exact re-LOO
can be an array job with one held-out point per child.

AWS advantages we should use deliberately:

- **Managed queues:** submit many jobs and let AWS place them on available
  compute.
- **Array jobs:** run high-Pareto re-LOO refits or prior-sensitivity grids as
  one logical job with many child jobs.
- **Spot compute:** use cheaper interruptible capacity for disposable smoke
  tests, re-LOO children, and exploratory branches.
- **On-Demand compute:** use non-interruptible capacity for the main inference
  models we cannot afford to lose late in sampling.
- **S3 artifact layer:** all jobs pull the same bundle and write independent
  outputs to `s3://.../jobs/<job_id>/`.
- **Container image:** install R/RStan dependencies once in an ECR image rather
  than rebuilding packages on every EC2 launch.

### HPC alternative

If university HPC is available, use the same job manifest and translate each
row into a SLURM job. The modeling problem is the same: one independent model
or exact re-LOO holdout per job.

## Instance Choice

Start CPU-only. GPUs are not useful for these RStan models.

Recommended first instances:

- `c7i.4xlarge` or similar compute-optimized instance for normal 4-chain fits.
- `c7i.8xlarge` if running multiple independent 2-chain exact re-LOO jobs on
  one host.
- `r7i.4xlarge` or similar memory-optimized instance if generated quantities or
  RStan fit objects cause memory pressure.

Use On-Demand for critical long fits. Use Spot for disposable short refits and
parallel exact re-LOO holdouts, but write outputs frequently because Spot
instances can be interrupted.

## Expected AWS Runtime

Treat these as planning ranges, not guarantees. They are based on the local Mac
runs already completed, then adjusted for AWS parallelism and the fact that
RStan still runs four CPU chains per model.

| Job family | Local reference | AWS planning range | Notes |
| --- | ---: | ---: | --- |
| Smoke fit | none | 20-60 min | Includes one optional RStan C++ compile preflight plus a short fit. |
| `m1_stier_11` / observation M1 branches | 3.0-3.6 h | 2-5 h | Good On-Demand first-pass candidates. |
| `m2_stier_site_growth` | 3.0 h | 2-5 h | Similar to M1 unless geometry worsens. |
| `m3_stier_distance` | 4.7 h | 3-8 h | Spatial covariance is heavier; keep on On-Demand for serious runs. |
| exact re-LOO array children | not directly comparable | 2-8 h per child | Wall time is close to the slowest child when submitted as an array. |
| predator / time-varying branches | older predator v3 was pathological | 6-24+ h | Use Spot for exploratory branches; promote only sampler-clean variants. |

The real speedup is throughput, not making one Stan chain magically fast. A
single four-chain model may only be modestly faster than the laptop, but AWS
lets us run M1, M2, M3, predator branches, and re-LOO children at the same time.
So a model round that would take several days serially on the laptop should be
possible as an overnight or same-day cloud batch if the container and smoke job
are clean.

## Repo Files

- `cloud/r-packages.txt`: R package list to install on an EC2 worker.
- `cloud/model-job-manifest.csv`: simple EC2-era model/job inventory.
- `cloud/model-farm-manifest.csv`: broader AWS Batch farming manifest covering
  baseline, observation, site-growth, spatial, density, predator, time-varying,
  exact re-LOO, and smoke-test jobs.
- `cloud/bootstrap_ec2_ubuntu.sh`: installs system libraries, R, AWS CLI, and R
  packages on Ubuntu.
- `cloud/Dockerfile.batch`: reusable AWS Batch image definition.
- `cloud/batch-job-definition-template.json`: Batch job definition template for
  the pushed ECR image and S3-capable job role.
- `cloud/make_cloud_bundle.sh`: creates a compact source/data bundle.
- `cloud/upload_bundle_to_s3.sh`: uploads the bundle and job manifest to S3.
- `cloud/run_cloud_job.sh`: runs one model job and syncs outputs.
- `cloud/batch_entrypoint.sh`: Batch entrypoint that downloads the bundle and
  runs a manifest-selected job.
- `cloud/build_and_push_batch_image.sh`: creates/pushes an ECR image for Batch.
- `cloud/setup_batch_infra.sh`: creates/updates IAM roles, log group, Batch
  compute environments, job queues, and job definition for the pushed image.
- `cloud/submit_batch_job.sh`: submits one explicit Batch job.
- `cloud/submit_model_farm.py`: submits selected rows from the model-farm
  manifest to AWS Batch.
- `cloud/sync_model_farm_results.sh`: downloads `jobs/` outputs from S3 and
  writes `Output/diagnostics/cloud_model_farm_status.csv`.
- `cloud/summarize_model_farm_results.py`: compares downloaded outputs against
  `cloud/model-farm-manifest.csv`.
- `cloud/promote_cloud_results.sh`: explicitly copies one downloaded successful
  cloud job into local artifact folders.
- `cloud/ec2_user_data_template.sh`: user-data template for one self-terminating
  EC2 job instance.
- `cloud/render_ec2_user_data.sh`: fills the user-data template for a specific
  job.

## First Setup On This Mac

Install/configure AWS CLI:

```sh
brew install awscli
aws configure sso
aws sts get-caller-identity
```

On this Mac, AWS CLI v2 is installed. Credentials still need to be configured;
newer AWS CLI versions may suggest `aws login`, while `aws configure sso` is
still the explicit SSO setup path.

Create an S3 bucket or prefix, for example:

```sh
export HERRING_S3=s3://YOUR-BUCKET/herring-hg-metapop/2026-05-10
cloud/upload_bundle_to_s3.sh "$HERRING_S3"
```

## Launch One EC2 Job

Render user-data:

```sh
cloud/render_ec2_user_data.sh \
  "$HERRING_S3" \
  m1_stier_obs_hier \
  Code/03_fit_m1_stier_obs_hier.R \
  /tmp/m1_stier_obs_hier-user-data.sh
```

Launch an Ubuntu 24.04 EC2 instance with:

   - IAM role that can read/write the S3 prefix,
   - enough EBS space, at least 200 GB for safety,
   - user-data from `/tmp/m1_stier_obs_hier-user-data.sh`.

The instance will:

1. download the bundle,
2. install dependencies,
3. run the model script,
4. sync `Output`, selected `Data/processed` artifacts, logs, and status files to
   S3,
5. shut itself down.

## Immediate Job Priorities

Use `cloud/model-job-manifest.csv`.

Current first jobs:

1. `m1_stier_obs_hier`
   - completed clean negative result;
   - do not rerun unchanged unless deliberately reproducing that result.
2. `m3_stier_distance_reloo_487`
   - exact re-LOO holdout for 2024 Englefield Bay.
3. `m3_stier_distance_reloo_82`
   - exact re-LOO holdout for 1965 Skidegate Inlet.

The local machine is already running the triage re-LOO jobs, so do not launch
duplicates unless deliberately abandoning or racing the local run.

## Batch Model-Farm Design

Use `cloud/model-farm-manifest.csv` as the source of truth for AWS farming.
Each row defines:

- `job_id`: unique model or array-job name;
- `job_family`: baseline, observation, spatial process, predator, etc.;
- `task_type`: full model fit, exact re-LOO array, sensitivity grid, smoke fit;
- `script`: R entrypoint;
- `array_size`: `1` for normal model jobs, `>1` for array jobs;
- `vcpus`, `memory_mib`, `timeout_hours`: per-job resource sizing;
- `queue_tier` and `spot_ok`: whether to use On-Demand or Spot;
- `env`: semicolon-separated environment overrides, for example
  `M3_DISTANCE_RELOO_CHAINS=2;USE_ARRAY_RANK_FOR_RELOO=1`.

Recommended queue split:

- `herring-ondemand`: main inference jobs such as `m1_stier_obs_hier`,
  `m2_stier_site_growth`, and revised final branches.
- `herring-spot`: smoke tests, exact re-LOO children, archived/debug branches,
  and sensitivity grids.

The current farm manifest includes all major families we are actively
considering:

- baseline: `m1_stier_11`;
- observation: `m1_stier_obs_hier`, `m1_stier_method_sensitivity`;
- site growth: `m2_stier_site_growth`;
- spatial process: `m3_stier_distance` plus `m3_stier_distance_reloo` array;
- density dependence: `m3_dd_global`, archived `m3_v5`;
- predators: `m5_v5`, `m5_combined`;
- time-varying productivity: `m6_timevarying`;
- smoke test: `smoke_m1_stier_obs_hier`.

### Batch Launch Flow

Build and push the reusable image:

```sh
AWS_PROFILE=herring cloud/build_and_push_batch_image.sh \
  us-east-1 herring-hg-metapop-batch latest
```

If Docker is not running locally, start Docker Desktop first. The Batch image
build is the slowest one-time setup step because it installs R/RStan packages.
The image uses portable R/Stan compile flags, not `-march=native`, because the
local build host and AWS Batch instance CPU types are not guaranteed to match.

Upload a fresh source/data bundle:

```sh
export HERRING_S3=s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-10
AWS_PROFILE=herring cloud/upload_bundle_to_s3.sh "$HERRING_S3"
```

After creating a Batch compute environment, job queue, and job definition for
the pushed image, submit only smoke tests first:

The job definition should use `cloud/batch-job-definition-template.json` as its
starting point. Replace:

- `__ECR_IMAGE_URI__` with the image URI printed by
  `cloud/build_and_push_batch_image.sh`;
- `__BATCH_JOB_ROLE_ARN__` with a role that can read/write the project S3
  prefix;
- `__BATCH_EXECUTION_ROLE_ARN__` with an ECS task execution role.

The helper script can create those AWS resources from the pushed image:

```sh
AWS_PROFILE=herring cloud/setup_batch_infra.sh \
  <ECR_IMAGE_URI_PRINTED_BY_BUILD_SCRIPT> \
  us-east-1 \
  herring-hg-metapop-107094296950
```

```sh
AWS_PROFILE=herring python3 cloud/submit_model_farm.py \
  --s3-prefix "$HERRING_S3" \
  --job-queue herring-hg-metapop-spot \
  --job-definition herring-hg-metapop \
  --task-type smoke_fit \
  --include-spot
```

The smoke row sets `HERRING_R_STAN_PREFLIGHT_COMPILE=1`, so it validates the
RStan syntax and C++ compile path before the short fit. For full jobs, leave
that off to avoid paying an extra compile before `rstan::stan(file = ...)`.

Then submit the main observation branch to the On-Demand queue:

```sh
AWS_PROFILE=herring python3 cloud/submit_model_farm.py \
  --s3-prefix "$HERRING_S3" \
  --job-queue herring-hg-metapop-ondemand \
  --job-definition herring-hg-metapop \
  --job-id m1_stier_obs_hier
```

Submit exact re-LOO children as an array job on Spot:

```sh
AWS_PROFILE=herring python3 cloud/submit_model_farm.py \
  --s3-prefix "$HERRING_S3" \
  --job-queue herring-hg-metapop-spot \
  --job-definition herring-hg-metapop \
  --job-id m3_stier_distance_reloo \
  --include-spot
```

Do not submit all families at once until the smoke job has proven that the
container, S3 permissions, and RStan compilation path work.

## Output Hygiene

Each cloud job should produce:

- `cloud/logs/<job_id>.log`;
- `cloud/job_status/<job_id>.status`;
- model `.rds` artifacts in `Data/processed`;
- LOO `.rds` artifacts in `Output/posteriors`;
- diagnostics/figures in `Output/diagnostics` and `Output/figures`.

After syncing results back locally, rerun:

```sh
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
```

If AWS credentials are stale and Batch cannot be polled, preserve the last known
status locally:

```sh
python3 cloud/summarize_aws_batch_status.py \
  --status-csv cloud/aws_batch_runs/2026-05-10-overnight-status.csv \
  --out-md Output/diagnostics/aws_batch_model_farm_status.md
```

This report is intentionally read-only with respect to AWS. It prevents stale
`RUNNING` or `STARTING` rows from being mistaken for live state when the local
SSO cache has expired.

## Cost Control

- Prefer one job per instance.
- Shut down automatically in user-data.
- Use a unique S3 prefix per sprint/day.
- Keep logs in S3 before shutdown.
- Use Spot only for jobs that can be lost and rerun.
- Start with one or two jobs before launching a grid.

## Sources

- AWS Batch documentation: <https://docs.aws.amazon.com/batch/>
- AWS Batch array jobs: <https://docs.aws.amazon.com/batch/latest/userguide/array_jobs.html>
- AWS Batch job dependencies: <https://docs.aws.amazon.com/batch/latest/userguide/job_dependencies.html>
- AWS Batch allocation strategies: <https://docs.aws.amazon.com/batch/latest/userguide/allocation-strategies.html>
- Amazon EC2 Spot interruption behavior: <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-instance-termination-notices.html>
- AWS CLI `s3 sync`: <https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html>
- AWS ParallelCluster documentation: <https://docs.aws.amazon.com/parallelcluster/>
