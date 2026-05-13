# AWS + Codex Model-Farm Lessons

Generated: 2026-05-10

This is a practical implementation log for connecting Codex to AWS so future
projects can reuse the working pattern. Keep this updated with what actually
worked, what failed, and why.

## Goal

Use Codex on the local Mac to:

1. package a modeling repo;
2. upload source/data bundles to S3;
3. create AWS Batch infrastructure;
4. submit many model variants as independent jobs;
5. collect results back into the repo;
6. rerun diagnostics and generate the next model-farm round.

## What Worked

### AWS IAM Identity Center / SSO

The correct approach was AWS CLI v2 SSO, not long-lived access keys pasted into
chat.

Working profile:

```sh
aws sso login --profile herring
AWS_PROFILE=herring aws sts get-caller-identity
```

Successful identity:

```text
Account: 107094296950
Role: AWSReservedSSO_AdministratorAccess...
User: adrian_stier
Region: us-east-1
```

The local `~/.aws/config` needs this shape:

```ini
[profile herring]
sso_session = herring
sso_account_id = 107094296950
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[sso-session herring]
sso_start_url = https://d-90660c8d70.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

### SSO Assignment

The AWS access portal showed `AWS accounts (0)` until the IAM Identity Center
user `adrian_stier` was assigned to account `107094296950` with the
`AdministratorAccess` permission set.

The fix was:

1. IAM Identity Center;
2. AWS accounts;
3. select account `Adrian_Stier / 107094296950`;
4. assign user `adrian_stier`;
5. assign permission set `AdministratorAccess`;
6. wait briefly;
7. rerun `aws sso login --profile herring`.

### S3 Artifact Layer

Created private bucket:

```text
herring-hg-metapop-107094296950
```

Applied:

- block all public access;
- default AES256 server-side encryption.

Uploaded bundle/manifests to:

```text
s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-10/
```

This worked:

```sh
AWS_PROFILE=herring cloud/upload_bundle_to_s3.sh \
  s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-10
```

### Repo Bundle

`cloud/make_cloud_bundle.sh` creates a compact bundle around 352 MB.

It now excludes:

- `.git`;
- compiled Stan/C++ artifacts;
- saved fit `.rds` files;
- posterior `.rds` files;
- logs;
- Python `__pycache__` and `.pyc`.

The bundle includes the important shared inputs:

- `Data/processed/jags_model_inputs_v2.RData`;
- Stan files;
- R fit scripts;
- cloud scripts;
- model-farm manifests.

### Sandbox / Escalation Pattern

Codex sandboxing blocked some network/local socket operations. The working
pattern was to retry important commands with explicit escalation when they
failed for sandbox reasons.

Examples:

- AWS SSO/ST​​​​S credential calls may need escalation.
- Docker daemon access needs escalation.
- Existing Chrome remote debugging / desktop automation may be blocked by macOS
  privacy permissions, so screenshots from the user were more reliable.

### Docker Desktop

Docker was installed but the daemon was initially stopped:

```text
Cannot connect to the Docker daemon
```

The fix was:

```sh
open -a Docker
docker info
```

After Docker Desktop started, Docker reported:

```text
29.3.1
```

## What Failed / What To Watch

### AWS Access Portal Had No Accounts

Symptom:

```text
aws: [ERROR]: No AWS accounts are available to you.
```

Cause:

The user existed in IAM Identity Center, but no permission set was assigned to
the AWS account.

Fix:

Assign the user to the account with a permission set, then rerun SSO.

### Expired SSO Cache After Browser Says Login Worked

Symptom:

```text
aws: [ERROR]: Error when retrieving token from sso: Token has expired and refresh failed
```

This can happen even after the browser says:

```text
Your credentials have been shared successfully and can be used until your session expires.
```

In the May 11 run, the local `~/.aws/sso/cache` files were still dated May 10,
so the `herring` profile had not actually received a fresh CLI token in the
shell that Codex was using.

Checks:

```sh
AWS_PROFILE=herring aws sts get-caller-identity
ls -lt ~/.aws/sso/cache | sed -n '1,20p'
sed -n '1,120p' ~/.aws/config
```

Fix:

```sh
aws sso login --profile herring
AWS_PROFILE=herring aws sts get-caller-identity
```

If the browser handoff is unreliable, use the device-code flow:

```sh
aws sso login --profile herring --use-device-code
```

Rule for future projects: when Batch polling fails with an SSO cache error,
write a local stale-status report rather than losing the last known job table.
For this repo:

```sh
python3 cloud/summarize_aws_batch_status.py
```

May 12, 2026 repeat symptom:

```text
aws: [ERROR]: Error when retrieving token from sso: Token has expired and refresh failed
```

This blocked live Batch submission even though the repo/cloud scripts were ready.
Do not keep debugging Batch when this appears. Refresh the local shell session:

```sh
aws sso login --profile herring
AWS_PROFILE=herring aws sts get-caller-identity
```

Then run the prepared round launcher:

```sh
zsh cloud/submit_today_model_rounds.sh
```

### Wrong SSO Config Section

Using:

```ini
[profile sso-session.herring]
```

is wrong for the new SSO-session format.

Correct:

```ini
[sso-session herring]
```

### Inline Shell Assignment Bug

This failed:

```sh
AWS_PROFILE=herring HERRING_S3=s3://... cloud/upload_bundle_to_s3.sh "$HERRING_S3"
```

because the shell expands `"$HERRING_S3"` before applying the inline assignment.

Use either:

```sh
export HERRING_S3=s3://...
AWS_PROFILE=herring cloud/upload_bundle_to_s3.sh "$HERRING_S3"
```

or pass the S3 URI directly:

```sh
AWS_PROFILE=herring cloud/upload_bundle_to_s3.sh s3://...
```

### Dockerfile `apt-get install awscli` Failed

The first Batch Dockerfile attempted:

```dockerfile
apt-get install awscli
```

On the `rocker/r-ver:4.4.2` Ubuntu Noble base, `awscli` had no installation
candidate.

Fix:

Install AWS CLI v2 from Amazon's zip installer in the Dockerfile:

```dockerfile
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install \
  && rm -rf /tmp/aws /tmp/awscliv2.zip
```

### Platform Matters

The local Mac is Apple Silicon, but the AWS Batch EC2 queues use x86 instance
families such as `c7i`, `c6i`, `m7i`, and `m6i`.

The Docker build script now forces:

```sh
--platform linux/amd64
```

Without this, it is easy to accidentally build an ARM image that will not run
on the selected EC2 instance families.

### R / Stan Interface Hardening

The Dockerfile originally used:

```make
CXX14FLAGS += -O3 -march=native -mtune=native
CXX17FLAGS += -O3 -march=native -mtune=native
```

That is unsafe for this workflow. The image is built on an Apple Silicon Mac
using `linux/amd64` emulation, then run later on AWS x86 instance families.
`-march=native` can bake build-host-specific CPU assumptions into compiled R
package shared libraries.

Fix:

```make
CXX14FLAGS += -O2 -pipe
CXX17FLAGS += -O2 -pipe
```

This is less aggressively optimized, but much more portable across Batch
instance types. Runtime Stan compilation can still use the same generic flags.

Every cloud job now appends the R/Stan interface state to its status file using
`cloud/log_rstan_interface.R`:

- R version and platform;
- `rstan`, `StanHeaders`, `Rcpp`, and `RcppEigen` versions;
- active `R_MAKEVARS_USER` and Makevars contents;
- detected Stan file;
- `rstan::stanc()` syntax result before the expensive fit starts.

Full C++ preflight compilation is available by setting:

```sh
HERRING_R_STAN_PREFLIGHT_COMPILE=1
```

Use that for smoke jobs or debugging image/toolchain problems. Do not enable it
by default for all long jobs, because it can duplicate the compile cost that
`rstan::stan(file = ...)` will already pay.

### R Package Install Must Fail Hard

One image build pushed successfully even though `install.packages()` reported
failed installs:

```text
package 'qs' is not available for this version of R
installation of 10 packages failed:
  'fs', 'sass', 'bslib', 'gargle', 'rmarkdown', 'googledrive',
  'reprex', 'googlesheets4', 'tarchetypes', 'tidyverse'
```

The Docker build still exited zero because `install.packages()` emitted warnings
rather than stopping. That image was not trustworthy because the model scripts
call `library(tidyverse)`.

Fixes:

- switch the base image from `rocker/r-ver:4.4.2` to
  `rocker/tidyverse:4.4.2`;
- remove nonessential `qs` and `tarchetypes` from the Batch package install
  list;
- add `cloud/required-r-packages.txt`;
- make the Docker build run `requireNamespace()` checks and `stop()` if any
  required package is missing.

Future projects should always add an explicit package verification step to the
container build. Do not trust `install.packages()` warnings inside Docker.

### Smoke Tests Must Be Smaller Than Real Models

The first AWS Batch smoke job used `Code/03_fit_m1_stier_obs_hier.R` with:

```text
HERRING_SMOKE=1;STAN_CHAINS=1;STAN_ITER=200;STAN_WARMUP=100;STAN_CORES=1
```

but the R script ignored those environment variables and hardcoded:

```r
chains = 4
iter = 4500
warmup = 2000
cores = 4
```

Result:

```text
job_id: 9924721a-01b9-4211-b948-93b90360ea96
status: FAILED
reason: Job attempt duration exceeded timeout
exitCode: 137
```

The CloudWatch tail showed the job was not a smoke test at all: it reached
roughly 55% of a full 4500-iteration fit before AWS killed it at the two-hour
timeout.

Fix:

- add `inst/stan/cloud_pipeline_smoke.stan`;
- add `cloud/smoke_stan_pipeline.R`;
- make the manifest `smoke_fit` row run this tiny model first;
- use the real herring scripts only after the R/Stan/S3/Batch path is proven;
- retrofit real model scripts or wrappers so `STAN_CHAINS`, `STAN_ITER`,
  `STAN_WARMUP`, and `STAN_CORES` are honored before using them as smoke tests.

Rule for future projects: the first cloud smoke test should be a toy model that
finishes in minutes and verifies infrastructure. The second smoke test can be a
reduced version of the real model.

The tiny smoke passed on Spot:

```text
job_id: b8b76e00-c2c1-4551-a96d-99a72b11c59a
job_name: smoke_cloud_pipeline
status: SUCCEEDED
runtime: about 100 seconds
```

Verified:

- AWS Batch pulled the image and bundle;
- R 4.4.2 ran on `x86_64-pc-linux-gnu`;
- `rstan`, `StanHeaders`, `Rcpp`, and `RcppEigen` loaded;
- Makevars used portable `-O2 -pipe` flags;
- `rstan::stanc()` passed;
- `rstan::stan_model()` C++ compilation passed;
- the toy model sampled;
- status/log/result artifacts uploaded to S3.

One follow-up issue surfaced: `cloud/run_cloud_job.sh` originally synced the
entire bundled `Output/` tree back to S3, which uploaded stale local figures and
diagnostics from the source bundle. The fix was to sync only files newer than
an immutable artifact marker created immediately before `Rscript "$JOB_SCRIPT"`
runs. Use `HERRING_SYNC_ALL_OUTPUT=1` only for a deliberate full-output archival
job.

A first attempt used the job status file as that marker, but the status file is
updated after the model exits. That made the generated fit artifacts older than
the marker, so nothing came back except logs/status. Use a separate
`*.artifact_marker` file that is touched once and never modified.

The bundle was also tightened after this:

- copy only code, Stan files, cloud scripts, docs, and processed input data;
- exclude local `Output/`;
- exclude saved fit `.rds` files from `Data/processed`;
- include only the distance-matrix raw Excel file needed by spatial models;
- delete `.DS_Store` and `._*` files before tar creation.

This reduced the bundle from about 353 MB to about 69 MB.

## Current Implementation State

Working:

- AWS SSO profile `herring`;
- private encrypted S3 bucket;
- source/data bundle upload;
- model-farm manifest;
- result sync/promote scripts;
- Batch Dockerfile and build script after the `awscli` fix;
- Batch setup script written and syntax-checked.

Still in progress / not fully proven:

- result sync from a completed AWS job;
- automatic next-round rerun decision from cloud results.

Proven on 2026-05-10:

- ECR image build and push;
- AWS Batch IAM roles, compute environments, queues, and job definition;
- Batch job submission;
- CloudWatch log retrieval;
- tiny RStan Batch smoke job;
- S3 artifact upload from a completed job.

## Recommended Future-Project Pattern

For future Codex-managed scientific model farms:

1. Set up AWS SSO first.
2. Create one private encrypted S3 bucket per project or lab.
3. Keep a compact bundle script that excludes generated/heavy artifacts.
4. Build a reusable Docker image with dependencies installed once.
5. Use a CSV manifest as the source of truth for jobs.
6. Use AWS Batch array jobs for embarrassingly parallel refits/sensitivities.
7. Keep cloud outputs staged until explicitly promoted locally.
8. Always run local audit/PPC/comparison scripts after promotion.
9. Document every AWS failure mode as soon as it happens.

## Commands To Remember

Verify identity:

```sh
AWS_PROFILE=herring aws sts get-caller-identity
```

Upload bundle:

```sh
AWS_PROFILE=herring cloud/upload_bundle_to_s3.sh \
  s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-10
```

Build/push Batch image:

```sh
AWS_PROFILE=herring cloud/build_and_push_batch_image.sh \
  us-east-1 herring-hg-metapop-batch latest
```

Set up Batch infra after image push:

```sh
AWS_PROFILE=herring cloud/setup_batch_infra.sh \
  <ECR_IMAGE_URI> \
  us-east-1 \
  herring-hg-metapop-107094296950
```

Submit smoke job:

```sh
AWS_PROFILE=herring python3 cloud/submit_model_farm.py \
  --s3-prefix s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-10 \
  --job-queue herring-hg-metapop-spot \
  --job-definition herring-hg-metapop \
  --task-type smoke_fit \
  --include-spot
```

Sync results:

```sh
AWS_PROFILE=herring cloud/sync_model_farm_results.sh \
  s3://herring-hg-metapop-107094296950/herring-hg-metapop/2026-05-10
```
