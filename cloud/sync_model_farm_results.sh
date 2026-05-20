#!/usr/bin/env bash
set -euo pipefail

# Download AWS model-farm job outputs from S3 and summarize status.
# Usage:
#   AWS_PROFILE=herring cloud/sync_model_farm_results.sh s3://bucket/prefix [local_dir]

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 s3://bucket/prefix [local_dir]" >&2
  exit 2
fi

s3_prefix="${1%/}"
default_name="$(basename "$s3_prefix")"
local_dir="${2:-cloud/aws_results/${default_name}}"

mkdir -p "$local_dir"
aws s3 sync "${s3_prefix}/jobs" "${local_dir}/jobs"
aws s3 cp "${s3_prefix}/model-farm-manifest.csv" "${local_dir}/model-farm-manifest.csv" || true
aws s3 cp "${s3_prefix}/model-job-manifest.csv" "${local_dir}/model-job-manifest.csv" || true

manifest_path="${local_dir}/model-farm-manifest.csv"
if [[ ! -f "$manifest_path" ]]; then
  manifest_path="cloud/model-farm-manifest.csv"
fi

python3 cloud/summarize_model_farm_results.py \
  "$local_dir" \
  --manifest "$manifest_path" \
  --out Output/diagnostics/cloud_model_farm_status.csv

echo "Downloaded model-farm results to ${local_dir}"
