#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

start_epoch="$(date +%s)"

echo "[$(date)] Waiting for m3_stier_distance fit artifacts..."

while true; do
  if [[ -f "Data/processed/m3_stier_distance_fit.rds" && -f "Output/posteriors/loo_m3_stier_distance.rds" ]] && \
     [[ "$(stat -f %m Data/processed/m3_stier_distance_fit.rds)" -ge "$start_epoch" ]] && \
     [[ "$(stat -f %m Output/posteriors/loo_m3_stier_distance.rds)" -ge "$start_epoch" ]]; then
    break
  fi
  sleep 120
done

echo "[$(date)] Fresh m3_stier_distance artifacts found. Running audit + PPC + comparison..."
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
Rscript Code/07s_m3_stier_distance_postfit.R
echo "[$(date)] m3_stier_distance refresh complete."
