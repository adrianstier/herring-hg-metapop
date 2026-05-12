#!/usr/bin/env bash
set -euo pipefail

# AWS Batch entrypoint for herring model jobs.
#
# Required environment variables:
#   S3_PREFIX   s3://bucket/prefix containing herring-cloud-bundle.tar.gz
#   JOB_ID      base job id from cloud/model-job-manifest.csv
#   JOB_SCRIPT  R script to run inside the repo bundle
#
# Optional:
#   JOB_ENV                   semicolon-separated KEY=VALUE assignments
#   USE_ARRAY_RANK_FOR_RELOO=1  map AWS_BATCH_JOB_ARRAY_INDEX to
#                               M3_DISTANCE_RELOO_HOLDOUT_RANK

: "${S3_PREFIX:?Set S3_PREFIX}"
: "${JOB_ID:?Set JOB_ID}"
: "${JOB_SCRIPT:?Set JOB_SCRIPT}"

base_job_id="$JOB_ID"
work_root="${HERRING_WORK_ROOT:-/work}"
bundle_name="herring-cloud-bundle.tar.gz"
mkdir -p "$work_root"
cd "$work_root"

aws s3 cp "${S3_PREFIX%/}/${bundle_name}" "./${bundle_name}"
tar -xzf "$bundle_name"
cd herring-cloud-bundle

if [[ -n "${JOB_ENV:-}" ]]; then
  IFS=';' read -r -a job_env_pairs <<< "$JOB_ENV"
  for pair in "${job_env_pairs[@]}"; do
    [[ -z "$pair" ]] && continue
    if [[ "$pair" != *=* ]]; then
      echo "Invalid JOB_ENV entry: $pair" >&2
      exit 2
    fi
    export "$pair"
  done
fi

if [[ -n "${AWS_BATCH_JOB_ARRAY_INDEX:-}" ]]; then
  array_index="$AWS_BATCH_JOB_ARRAY_INDEX"
  array_rank="$((array_index + 1))"
  export HERRING_ARRAY_INDEX="$array_index"
  export HERRING_ARRAY_RANK="$array_rank"
  export JOB_ID="${base_job_id}_rank$(printf '%03d' "$array_rank")"

  if [[ "${USE_ARRAY_RANK_FOR_RELOO:-0}" == "1" ]]; then
    export M3_DISTANCE_RELOO_HOLDOUT_RANK="$array_rank"
  fi
fi

export S3_OUT="${S3_PREFIX%/}/jobs/${JOB_ID}"

bash cloud/run_cloud_job.sh
