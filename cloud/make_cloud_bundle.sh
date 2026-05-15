#!/usr/bin/env bash
set -euo pipefail

# Create a compact source/data bundle for cloud model jobs.
# Usage:
#   cloud/make_cloud_bundle.sh

bundle_dir="${1:-/tmp/herring-cloud-bundle}"
bundle_file="${2:-/tmp/herring-cloud-bundle.tar.gz}"

export COPYFILE_DISABLE=1

rm -rf "$bundle_dir" "$bundle_file"
mkdir -p "$bundle_dir"

rsync_common=(
  --exclude ".git" \
  --exclude ".DS_Store" \
  --exclude "._*" \
  --exclude "*.rds" \
  --exclude "*.hpp" \
  --exclude "*.o" \
  --exclude "*.so" \
  --exclude "*.dSYM" \
  --exclude "__pycache__" \
  --exclude "*.pyc" \
  --exclude "aws_results" \
  --exclude "aws_batch_runs" \
  --exclude "job_status" \
  --exclude "logs" \
  --exclude "m*_output.txt" \
  --exclude "*.log"
)

for path in Code R inst cloud docs README.md AGENTS.md DESCRIPTION NAMESPACE \
  stier-2027-herring-metapopulation.Rproj; do
  if [[ -e "$path" ]]; then
    rsync -a "${rsync_common[@]}" "$path" "$bundle_dir"/
  fi
done

mkdir -p "$bundle_dir/Data/processed" "$bundle_dir/Data/raw"

rsync -a \
  "${rsync_common[@]}" \
  --exclude "*.rds" \
  Data/processed/ "$bundle_dir/Data/processed"/

rsync -a \
  "${rsync_common[@]}" \
  "Data/raw/Euclidean & effective distance matrices herring & Steller.xlsx" \
  "$bundle_dir/Data/raw"/

mkdir -p "$bundle_dir/Output"

find "$bundle_dir" -name ".DS_Store" -delete
find "$bundle_dir" -name "._*" -delete

tar --disable-copyfile -C "$(dirname "$bundle_dir")" -czf "$bundle_file" "$(basename "$bundle_dir")"

echo "$bundle_file"
