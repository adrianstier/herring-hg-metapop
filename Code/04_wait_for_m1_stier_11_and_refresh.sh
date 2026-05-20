#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

start_epoch="$(date +%s)"

echo "[$(date)] Waiting for m1_stier_11 fit artifacts..."

while true; do
  if [[ -f "Data/processed/m1_stier_11_fit.rds" && -f "Output/posteriors/loo_m1_stier_11.rds" ]] && \
     [[ "$(stat -f %m Data/processed/m1_stier_11_fit.rds)" -ge "$start_epoch" ]] && \
     [[ "$(stat -f %m Output/posteriors/loo_m1_stier_11.rds)" -ge "$start_epoch" ]]; then
    break
  fi
  sleep 120
done

echo "[$(date)] Fresh m1_stier_11 artifacts found. Running audit + PPC + comparison..."
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
echo "[$(date)] m1_stier_11 refresh complete."
