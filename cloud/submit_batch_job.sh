#!/usr/bin/env bash
set -euo pipefail

# Submit one AWS Batch job or array job from explicit arguments.
# Usage:
#   cloud/submit_batch_job.sh JOB_ID JOB_SCRIPT S3_PREFIX JOB_QUEUE JOB_DEFINITION \
#     [ARRAY_SIZE] [VCPUS] [MEMORY_MIB] [TIMEOUT_HOURS] [JOB_ENV]

if [[ $# -lt 5 || $# -gt 10 ]]; then
  echo "Usage: $0 JOB_ID JOB_SCRIPT S3_PREFIX JOB_QUEUE JOB_DEFINITION [ARRAY_SIZE] [VCPUS] [MEMORY_MIB] [TIMEOUT_HOURS] [JOB_ENV]" >&2
  exit 2
fi

job_id="$1"
job_script="$2"
s3_prefix="${3%/}"
job_queue="$4"
job_definition="$5"
array_size="${6:-1}"
vcpus="${7:-4}"
memory_mib="${8:-32000}"
timeout_hours="${9:-24}"
job_env="${10:-}"

container_overrides="$(
  cat <<JSON
{
  "vcpus": ${vcpus},
  "memory": ${memory_mib},
  "environment": [
    {"name": "S3_PREFIX", "value": "${s3_prefix}"},
    {"name": "JOB_ID", "value": "${job_id}"},
    {"name": "JOB_SCRIPT", "value": "${job_script}"},
    {"name": "JOB_ENV", "value": "${job_env}"}
  ]
}
JSON
)"

args=(
  --job-name "$job_id"
  --job-queue "$job_queue"
  --job-definition "$job_definition"
  --container-overrides "$container_overrides"
  --retry-strategy attempts=1
  --timeout "attemptDurationSeconds=$((timeout_hours * 3600))"
)

if [[ "$array_size" -gt 1 ]]; then
  args+=(--array-properties "size=${array_size}")
fi

aws batch submit-job "${args[@]}"
