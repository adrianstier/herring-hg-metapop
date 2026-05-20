#!/usr/bin/env bash
set -euo pipefail

# Create/update the AWS Batch infrastructure for the herring model farm.
#
# This script is intentionally idempotent. It creates:
#   - IAM roles for Batch EC2 instances, task execution, and job S3 access
#   - an instance profile for Batch-managed EC2 workers
#   - CloudWatch log group
#   - On-Demand and Spot managed EC2 compute environments with minvCpus=0
#   - On-Demand and Spot job queues
#   - a job definition using cloud/batch-job-definition-template.json
#
# Usage:
#   AWS_PROFILE=herring cloud/setup_batch_infra.sh ECR_IMAGE_URI [region] [bucket]

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage: $0 ECR_IMAGE_URI [region] [bucket]" >&2
  exit 2
fi

image_uri="$1"
region="${2:-${AWS_REGION:-us-east-1}}"
bucket="${3:-herring-hg-metapop-107094296950}"

name_prefix="${HERRING_BATCH_PREFIX:-herring-hg-metapop}"
log_group="/aws/batch/${name_prefix}"
job_definition="${name_prefix}"
ondemand_ce="${name_prefix}-ondemand-ce"
spot_ce="${name_prefix}-spot-ce"
ondemand_queue="${name_prefix}-ondemand"
spot_queue="${name_prefix}-spot"

account_id="$(aws sts get-caller-identity --query Account --output text)"

job_role="${name_prefix}-job-role"
execution_role="${name_prefix}-execution-role"
instance_role="${name_prefix}-ecs-instance-role"
instance_profile="${name_prefix}-ecs-instance-profile"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "${tmp_dir}/ecs-task-trust.json" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

cat > "${tmp_dir}/ec2-trust.json" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

cat > "${tmp_dir}/job-s3-policy.json" <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::${bucket}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": "arn:aws:s3:::${bucket}/*"
    }
  ]
}
JSON

ensure_role() {
  local role_name="$1"
  local trust_file="$2"
  if ! aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
    aws iam create-role \
      --role-name "$role_name" \
      --assume-role-policy-document "file://${trust_file}" >/dev/null
  fi
}

ensure_role "$job_role" "${tmp_dir}/ecs-task-trust.json"
ensure_role "$execution_role" "${tmp_dir}/ecs-task-trust.json"
ensure_role "$instance_role" "${tmp_dir}/ec2-trust.json"

aws iam put-role-policy \
  --role-name "$job_role" \
  --policy-name "${name_prefix}-s3-access" \
  --policy-document "file://${tmp_dir}/job-s3-policy.json"

aws iam attach-role-policy \
  --role-name "$execution_role" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy >/dev/null 2>&1 || true

aws iam attach-role-policy \
  --role-name "$instance_role" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role >/dev/null 2>&1 || true

if ! aws iam get-instance-profile --instance-profile-name "$instance_profile" >/dev/null 2>&1; then
  aws iam create-instance-profile --instance-profile-name "$instance_profile" >/dev/null
fi
if ! aws iam get-instance-profile --instance-profile-name "$instance_profile" \
  --query "InstanceProfile.Roles[?RoleName=='${instance_role}'].RoleName" \
  --output text | grep -qx "$instance_role"; then
  aws iam add-role-to-instance-profile \
    --instance-profile-name "$instance_profile" \
    --role-name "$instance_role" >/dev/null
fi

aws logs create-log-group --log-group-name "$log_group" --region "$region" >/dev/null 2>&1 || true
aws logs put-retention-policy --log-group-name "$log_group" --retention-in-days 30 --region "$region"

vpc_id="$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region "$region")"
if [[ -z "$vpc_id" || "$vpc_id" == "None" ]]; then
  echo "No default VPC found in ${region}. Create a VPC/subnets first or extend this script." >&2
  exit 1
fi

subnet_ids="$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values="$vpc_id" Name=default-for-az,Values=true \
  --query 'Subnets[].SubnetId' \
  --output text \
  --region "$region")"
security_group_id="$(aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values="$vpc_id" Name=group-name,Values=default \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region "$region")"

subnet_json="$(printf '%s\n' $subnet_ids | python3 -c 'import json,sys; print(json.dumps([x.strip() for x in sys.stdin if x.strip()]))')"

job_role_arn="$(aws iam get-role --role-name "$job_role" --query Role.Arn --output text)"
execution_role_arn="$(aws iam get-role --role-name "$execution_role" --query Role.Arn --output text)"
instance_profile_arn="$(aws iam get-instance-profile --instance-profile-name "$instance_profile" --query InstanceProfile.Arn --output text)"

create_or_update_ce() {
  local ce_name="$1"
  local ce_type="$2"
  local allocation="$3"
  local max_vcpus="$4"

  local compute_resources
  compute_resources="$(
    cat <<JSON
{
  "type": "${ce_type}",
  "allocationStrategy": "${allocation}",
  "minvCpus": 0,
  "maxvCpus": ${max_vcpus},
  "desiredvCpus": 0,
  "instanceTypes": ["c7i", "c6i", "m7i", "m6i"],
  "subnets": ${subnet_json},
  "securityGroupIds": ["${security_group_id}"],
  "instanceRole": "${instance_profile_arn}",
  "tags": {
    "Project": "herring-hg-metapop",
    "ManagedBy": "codex"
  }
}
JSON
  )"

  if aws batch describe-compute-environments \
    --compute-environments "$ce_name" \
    --region "$region" \
    --query 'computeEnvironments[0].computeEnvironmentName' \
    --output text | grep -qx "$ce_name"; then
    aws batch update-compute-environment \
      --compute-environment "$ce_name" \
      --state ENABLED \
      --compute-resources "minvCpus=0,maxvCpus=${max_vcpus}" \
      --region "$region" >/dev/null
  else
    aws batch create-compute-environment \
      --compute-environment-name "$ce_name" \
      --type MANAGED \
      --state ENABLED \
      --compute-resources "$compute_resources" \
      --region "$region" >/dev/null
  fi
}

create_or_update_ce "$ondemand_ce" "EC2" "BEST_FIT_PROGRESSIVE" "${HERRING_BATCH_ONDEMAND_MAX_VCPUS:-64}"
create_or_update_ce "$spot_ce" "SPOT" "SPOT_CAPACITY_OPTIMIZED" "${HERRING_BATCH_SPOT_MAX_VCPUS:-64}"

wait_for_ce_valid() {
  local ce_name="$1"
  local status
  local reason

  echo "Waiting for compute environment ${ce_name} to become VALID..."
  for _ in $(seq 1 60); do
    status="$(aws batch describe-compute-environments \
      --compute-environments "$ce_name" \
      --region "$region" \
      --query 'computeEnvironments[0].status' \
      --output text)"
    reason="$(aws batch describe-compute-environments \
      --compute-environments "$ce_name" \
      --region "$region" \
      --query 'computeEnvironments[0].statusReason' \
      --output text)"

    if [[ "$status" == "VALID" ]]; then
      return 0
    fi
    if [[ "$status" == "INVALID" ]]; then
      echo "Compute environment ${ce_name} is INVALID: ${reason}" >&2
      return 1
    fi
    sleep 10
  done

  echo "Timed out waiting for compute environment ${ce_name} to become VALID." >&2
  aws batch describe-compute-environments \
    --compute-environments "$ce_name" \
    --region "$region" >&2
  return 1
}

wait_for_ce_valid "$ondemand_ce"
wait_for_ce_valid "$spot_ce"

create_or_update_queue() {
  local queue_name="$1"
  local ce_name="$2"

  local order
  order="[{\"order\":1,\"computeEnvironment\":\"${ce_name}\"}]"

  if aws batch describe-job-queues \
    --job-queues "$queue_name" \
    --region "$region" \
    --query 'jobQueues[0].jobQueueName' \
    --output text | grep -qx "$queue_name"; then
    aws batch update-job-queue \
      --job-queue "$queue_name" \
      --state ENABLED \
      --priority 10 \
      --compute-environment-order "$order" \
      --region "$region" >/dev/null
  else
    aws batch create-job-queue \
      --job-queue-name "$queue_name" \
      --state ENABLED \
      --priority 10 \
      --compute-environment-order "$order" \
      --region "$region" >/dev/null
  fi
}

create_or_update_queue "$ondemand_queue" "$ondemand_ce"
create_or_update_queue "$spot_queue" "$spot_ce"

job_def_file="${tmp_dir}/job-definition.json"
sed \
  -e "s|__ECR_IMAGE_URI__|${image_uri}|g" \
  -e "s|__BATCH_JOB_ROLE_ARN__|${job_role_arn}|g" \
  -e "s|__BATCH_EXECUTION_ROLE_ARN__|${execution_role_arn}|g" \
  -e "s|/aws/batch/herring-hg-metapop|${log_group}|g" \
  -e "s|\"awslogs-region\": \"us-east-1\"|\"awslogs-region\": \"${region}\"|g" \
  cloud/batch-job-definition-template.json > "$job_def_file"

aws batch register-job-definition \
  --cli-input-json "file://${job_def_file}" \
  --region "$region" >/dev/null

cat <<EOF
AWS Batch infrastructure ready.
  account: ${account_id}
  region: ${region}
  image: ${image_uri}
  bucket: ${bucket}
  on-demand queue: ${ondemand_queue}
  spot queue: ${spot_queue}
  job definition: ${job_definition}
  job role: ${job_role_arn}
EOF
