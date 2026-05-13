#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

AWS_PROFILE="${AWS_PROFILE:-herring}"
AWS_REGION="${AWS_REGION:-us-east-1}"
RUN_DATE="${RUN_DATE:-$(date +%Y-%m-%d)}"
S3_PREFIX="${HERRING_S3:-s3://herring-hg-metapop-107094296950/herring-hg-metapop/${RUN_DATE}}"
JOB_DEFINITION="${JOB_DEFINITION:-herring-hg-metapop}"
SPOT_QUEUE="${SPOT_QUEUE:-herring-hg-metapop-spot}"
RUN_DIR="cloud/aws_batch_runs"

mkdir -p "$RUN_DIR"

loo_uri="${S3_PREFIX%/}/jobs/m3_stier_distance/Output/posteriors/loo_m3_stier_distance.rds"

echo "[$(date)] Checking for completed m3_stier_distance LOO artifact..."
if ! AWS_PROFILE="$AWS_PROFILE" aws s3 ls "$loo_uri" >/dev/null; then
  echo "Missing required source artifact:" >&2
  echo "  $loo_uri" >&2
  echo "Wait for m3_stier_distance to finish and upload artifacts, then rerun this script." >&2
  exit 1
fi

echo "[$(date)] Submitting m3_stier_distance_reloo follow-up array..."
AWS_PROFILE="$AWS_PROFILE" python3 cloud/submit_model_farm.py \
  --s3-prefix "$S3_PREFIX" \
  --job-queue "$SPOT_QUEUE" \
  --job-definition "$JOB_DEFINITION" \
  --job-id m3_stier_distance_reloo \
  --include-spot \
  --out-csv "${RUN_DIR}/${RUN_DATE}-m3-distance-reloo.csv"

echo "[$(date)] Submitted m3_stier_distance_reloo."
echo "Watch with:"
echo "  AWS_PROFILE=${AWS_PROFILE} python3 cloud/watch_aws_batch_run.py --jobs-csv ${RUN_DIR}/${RUN_DATE}-m3-distance-reloo.csv --out-csv Output/diagnostics/aws_batch_${RUN_DATE}_m3_distance_reloo.csv --out-json Output/diagnostics/aws_batch_${RUN_DATE}_m3_distance_reloo.json --sync-s3-prefix ${S3_PREFIX} --sync-local-dir cloud/aws_results/${RUN_DATE}"

