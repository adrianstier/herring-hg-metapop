#!/usr/bin/env bash
set -euo pipefail

# Build and push the AWS Batch container image.
# Usage:
#   AWS_PROFILE=herring cloud/build_and_push_batch_image.sh [region] [repo_name] [tag]

region="${1:-${AWS_REGION:-us-east-1}}"
repo_name="${2:-herring-hg-metapop-batch}"
tag="${3:-$(date +%Y%m%d-%H%M%S)}"
platform="${HERRING_BATCH_DOCKER_PLATFORM:-linux/amd64}"

account_id="$(aws sts get-caller-identity --query Account --output text)"
repo_uri="${account_id}.dkr.ecr.${region}.amazonaws.com/${repo_name}"

aws ecr describe-repositories --repository-names "$repo_name" --region "$region" >/dev/null 2>&1 ||
  aws ecr create-repository --repository-name "$repo_name" --region "$region" >/dev/null

aws ecr get-login-password --region "$region" |
  docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${region}.amazonaws.com"

docker build \
  --platform "$platform" \
  -f cloud/Dockerfile.batch \
  -t "${repo_uri}:${tag}" \
  cloud

docker push "${repo_uri}:${tag}"

echo "${repo_uri}:${tag}"
