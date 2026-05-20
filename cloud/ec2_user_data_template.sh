#!/usr/bin/env bash
set -euo pipefail

# EC2 user-data template.
# Replace the three placeholders before launching an instance:
#   __S3_PREFIX__  e.g. s3://my-bucket/herring/cloud
#   __JOB_ID__     e.g. m1_stier_obs_hier
#   __JOB_SCRIPT__ e.g. Code/03_fit_m1_stier_obs_hier.R

S3_PREFIX="__S3_PREFIX__"
JOB_ID="__JOB_ID__"
JOB_SCRIPT="__JOB_SCRIPT__"

cd /home/ubuntu

aws s3 cp "${S3_PREFIX%/}/herring-cloud-bundle.tar.gz" ./herring-cloud-bundle.tar.gz
tar -xzf herring-cloud-bundle.tar.gz
cd herring-cloud-bundle

bash cloud/bootstrap_ec2_ubuntu.sh

export JOB_ID
export JOB_SCRIPT
export S3_OUT="${S3_PREFIX%/}/jobs/${JOB_ID}"

bash cloud/run_cloud_job.sh

sudo shutdown -h now
