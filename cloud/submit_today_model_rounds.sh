#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

AWS_PROFILE="${AWS_PROFILE:-herring}"
AWS_REGION="${AWS_REGION:-us-east-1}"
RUN_DATE="${RUN_DATE:-$(date +%Y-%m-%d)}"
S3_PREFIX="${HERRING_S3:-s3://herring-hg-metapop-107094296950/herring-hg-metapop/${RUN_DATE}}"
JOB_DEFINITION="${JOB_DEFINITION:-herring-hg-metapop}"
ONDEMAND_QUEUE="${ONDEMAND_QUEUE:-herring-hg-metapop-ondemand}"
SPOT_QUEUE="${SPOT_QUEUE:-herring-hg-metapop-spot}"
RUN_DIR="cloud/aws_batch_runs"

mkdir -p "$RUN_DIR"

echo "[$(date)] Checking AWS identity for profile ${AWS_PROFILE}..."
AWS_PROFILE="$AWS_PROFILE" aws sts get-caller-identity >/dev/null

echo "[$(date)] Integrating HG predator repo products if available..."
Rscript Code/02c_integrate_hg_predator_repo_products.R

echo "[$(date)] Uploading current analysis bundle to ${S3_PREFIX}..."
AWS_PROFILE="$AWS_PROFILE" HERRING_S3="$S3_PREFIX" cloud/upload_bundle_to_s3.sh "$S3_PREFIX"

echo "[$(date)] Submitting on-demand core model round..."
AWS_PROFILE="$AWS_PROFILE" python3 cloud/submit_model_farm.py \
  --s3-prefix "$S3_PREFIX" \
  --job-queue "$ONDEMAND_QUEUE" \
  --job-definition "$JOB_DEFINITION" \
  --job-id m1_stier_11 \
  --job-id m2_stier_site_growth \
  --job-id m3_stier_distance \
  --job-id m5_stier_predation_pressure \
  --out-csv "${RUN_DIR}/${RUN_DATE}-round1-ondemand.csv"

echo "[$(date)] Submitting spot smoke and exploratory round..."
AWS_PROFILE="$AWS_PROFILE" python3 cloud/submit_model_farm.py \
  --s3-prefix "$S3_PREFIX" \
  --job-queue "$SPOT_QUEUE" \
  --job-definition "$JOB_DEFINITION" \
  --job-id smoke_cloud_pipeline \
  --job-id smoke_m5_stier_predation_pressure_reduced \
  --job-id m1_stier_method_sensitivity \
  --job-id m3_stier_distance_reloo \
  --job-id m5_v5 \
  --job-id m5_combined \
  --include-spot \
  --out-csv "${RUN_DIR}/${RUN_DATE}-round1-spot.csv"

echo "[$(date)] Submitted model rounds."
echo "S3 prefix: ${S3_PREFIX}"
echo "Watch with:"
echo "  AWS_PROFILE=${AWS_PROFILE} python3 cloud/watch_aws_batch_run.py --jobs-csv ${RUN_DIR}/${RUN_DATE}-round1-ondemand.csv --sync-s3 --s3-prefix ${S3_PREFIX}"
echo "  AWS_PROFILE=${AWS_PROFILE} python3 cloud/watch_aws_batch_run.py --jobs-csv ${RUN_DIR}/${RUN_DATE}-round1-spot.csv --sync-s3 --s3-prefix ${S3_PREFIX}"
