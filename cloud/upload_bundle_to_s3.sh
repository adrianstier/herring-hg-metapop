#!/usr/bin/env bash
set -euo pipefail

# Upload a cloud bundle to S3.
# Usage:
#   cloud/upload_bundle_to_s3.sh s3://bucket/prefix

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 s3://bucket/prefix" >&2
  exit 2
fi

s3_prefix="${1%/}"
bundle_file="$(cloud/make_cloud_bundle.sh)"

aws s3 cp "$bundle_file" "${s3_prefix}/herring-cloud-bundle.tar.gz"
aws s3 cp cloud/model-job-manifest.csv "${s3_prefix}/model-job-manifest.csv"
aws s3 cp cloud/model-farm-manifest.csv "${s3_prefix}/model-farm-manifest.csv"

echo "Uploaded bundle to ${s3_prefix}/herring-cloud-bundle.tar.gz"
