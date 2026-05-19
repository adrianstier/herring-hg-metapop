#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

start_epoch="$(date +%s)"

echo "[$(date)] Waiting for m3_v3 and m5_v3 fit artifacts..."

while true; do
  if [[ -f "Data/processed/m3_v3_fit.rds" && -f "Data/processed/m5_v3_fit.rds" ]] && \
     [[ "$(stat -f %m Data/processed/m3_v3_fit.rds)" -ge "$start_epoch" ]] && \
     [[ "$(stat -f %m Data/processed/m5_v3_fit.rds)" -ge "$start_epoch" ]]; then
    break
  fi
  sleep 120
done

echo "[$(date)] Fits found. Running audit + PPC + comparison..."
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
echo "[$(date)] Comparison complete."
