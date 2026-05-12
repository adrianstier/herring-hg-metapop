#!/usr/bin/env bash
set -euo pipefail

# Bootstrap an Ubuntu EC2 instance for the herring Stan model jobs.
# Run once on a fresh instance, then sync the repo bundle and call
# cloud/run_cloud_job.sh.

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  gfortran \
  git \
  libcurl4-openssl-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libfribidi-dev \
  libharfbuzz-dev \
  libjpeg-dev \
  libpng-dev \
  libssl-dev \
  libtiff5-dev \
  libxml2-dev \
  make \
  pandoc \
  r-base \
  r-base-dev \
  unzip

mkdir -p ~/.R
cat > ~/.R/Makevars <<'EOF'
CXX14FLAGS += -O3 -march=native -mtune=native
CXX17FLAGS += -O3 -march=native -mtune=native
EOF

if ! command -v aws >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${tmp_dir}/awscliv2.zip"
  unzip -q "${tmp_dir}/awscliv2.zip" -d "${tmp_dir}"
  sudo "${tmp_dir}/aws/install"
  rm -rf "${tmp_dir}"
fi

sudo Rscript --vanilla -e '
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  pkgs <- readLines("cloud/r-packages.txt")
  pkgs <- pkgs[nzchar(pkgs)]
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) install.packages(missing, Ncpus = parallel::detectCores())
'

echo "EC2 bootstrap complete."
