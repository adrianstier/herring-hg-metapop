#!/usr/bin/env bash
set -euo pipefail

# Render EC2 user-data for one self-terminating cloud model job.
# Usage:
#   cloud/render_ec2_user_data.sh s3://bucket/prefix job_id Code/script.R [/tmp/user-data.sh]

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 s3://bucket/prefix job_id Code/script.R [/tmp/user-data.sh]" >&2
  exit 2
fi

s3_prefix="${1%/}"
job_id="$2"
job_script="$3"
out_file="${4:-/tmp/herring-${job_id}-user-data.sh}"

sed \
  -e "s|__S3_PREFIX__|${s3_prefix}|g" \
  -e "s|__JOB_ID__|${job_id}|g" \
  -e "s|__JOB_SCRIPT__|${job_script}|g" \
  cloud/ec2_user_data_template.sh > "$out_file"

chmod 600 "$out_file"
echo "$out_file"
