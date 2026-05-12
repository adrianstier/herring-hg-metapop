#!/usr/bin/env bash
set -euo pipefail

# Run one model job on an EC2 instance.
#
# Required environment variables:
#   JOB_ID        short job name, e.g. m1_stier_obs_hier
#   JOB_SCRIPT    R script path, e.g. Code/03_fit_m1_stier_obs_hier.R
# Optional:
#   S3_OUT        s3://bucket/prefix/jobs/JOB_ID for output sync
#   JOB_ENV       semicolon-separated KEY=VALUE assignments for this job
#
# Example:
#   JOB_ID=m1_stier_obs_hier \
#   JOB_SCRIPT=Code/03_fit_m1_stier_obs_hier.R \
#   S3_OUT=s3://my-bucket/herring/jobs/m1_stier_obs_hier \
#   cloud/run_cloud_job.sh

: "${JOB_ID:?Set JOB_ID}"
: "${JOB_SCRIPT:?Set JOB_SCRIPT}"

mkdir -p "cloud/logs" "cloud/job_status"

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

start_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log_file="cloud/logs/${JOB_ID}.log"
status_file="cloud/job_status/${JOB_ID}.status"
artifact_marker="cloud/job_status/${JOB_ID}.artifact_marker"

{
  echo "job_id=${JOB_ID}"
  echo "job_script=${JOB_SCRIPT}"
  echo "start_time_utc=${start_time}"
  echo "hostname=$(hostname)"
  echo "nproc=$(getconf _NPROCESSORS_ONLN)"
  echo "working_dir=$(pwd)"
  echo "job_env=${JOB_ENV:-}"
  echo "array_index=${AWS_BATCH_JOB_ARRAY_INDEX:-}"
} > "$status_file"

{
  Rscript --version
  Rscript --vanilla cloud/log_rstan_interface.R
} >> "$status_file" 2>&1

touch "$artifact_marker"

set +e
Rscript "$JOB_SCRIPT" 2>&1 | tee "$log_file"
exit_code="${PIPESTATUS[0]}"
set -e

end_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "end_time_utc=${end_time}"
  echo "exit_code=${exit_code}"
} >> "$status_file"

if [[ -n "${S3_OUT:-}" ]]; then
  artifact_file="cloud/job_status/${JOB_ID}.artifacts"

  if [[ "${HERRING_SYNC_ALL_OUTPUT:-0}" == "1" ]]; then
    aws s3 sync Output "${S3_OUT%/}/Output"
    aws s3 sync Data/processed "${S3_OUT%/}/Data/processed" \
      --exclude "*" \
      --include "*.rds" \
      --include "*.csv" \
      --include "*.md"
  else
    find Output Data/processed \
      -type f \
      -newer "$artifact_marker" \
      ! -name ".DS_Store" \
      ! -name "._*" \
      \( -name "*.rds" -o -name "*.csv" -o -name "*.md" -o -name "*.pdf" -o -name "*.png" -o -name "*.txt" -o -name "*.json" \) \
      -print | sort > "$artifact_file"

    while IFS= read -r artifact; do
      [[ -z "$artifact" ]] && continue
      aws s3 cp "$artifact" "${S3_OUT%/}/${artifact}"
    done < "$artifact_file"
  fi

  aws s3 sync cloud/logs "${S3_OUT%/}/logs"
  aws s3 sync cloud/job_status "${S3_OUT%/}/job_status"
fi

exit "$exit_code"
