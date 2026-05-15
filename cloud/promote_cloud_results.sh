#!/usr/bin/env bash
set -euo pipefail

# Copy selected downloaded cloud artifacts into the working repo.
# This is intentionally explicit: pass one downloaded job directory at a time.
# Usage:
#   cloud/promote_cloud_results.sh cloud/aws_results/2026-05-10/jobs/m1_stier_obs_hier

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 cloud/aws_results/<prefix>/jobs/<job_id>" >&2
  exit 2
fi

job_dir="$1"
if [[ ! -d "$job_dir" ]]; then
  echo "Job directory not found: $job_dir" >&2
  exit 1
fi

mkdir -p Data/processed Output/posteriors Output/diagnostics Output/figures cloud/logs cloud/job_status

if [[ -d "${job_dir}/Data/processed" ]]; then
  rsync -av "${job_dir}/Data/processed/" Data/processed/
fi
if [[ -d "${job_dir}/Output/posteriors" ]]; then
  rsync -av "${job_dir}/Output/posteriors/" Output/posteriors/
fi
if [[ -d "${job_dir}/Output" ]]; then
  find "${job_dir}/Output" -maxdepth 1 -type f -print0 |
    while IFS= read -r -d '' output_file; do
      rsync -av "${output_file}" Output/
    done
fi
if [[ -d "${job_dir}/Output/diagnostics" ]]; then
  rsync -av "${job_dir}/Output/diagnostics/" Output/diagnostics/
fi
if [[ -d "${job_dir}/Output/figures" ]]; then
  rsync -av "${job_dir}/Output/figures/" Output/figures/
fi
if [[ -d "${job_dir}/logs" ]]; then
  rsync -av "${job_dir}/logs/" cloud/logs/
fi
if [[ -d "${job_dir}/job_status" ]]; then
  rsync -av "${job_dir}/job_status/" cloud/job_status/
fi

echo "Promoted cloud artifacts from ${job_dir}"
