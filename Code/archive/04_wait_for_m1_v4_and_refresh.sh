#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

start_epoch="$(date +%s)"

echo "[$(date)] Waiting for m1_v4 fit artifacts..."

while true; do
  if [[ -f "Data/processed/m1_v4_fit.rds" && -f "Output/posteriors/loo_m1_v4.rds" ]] && \
     [[ "$(stat -f %m Data/processed/m1_v4_fit.rds)" -ge "$start_epoch" ]] && \
     [[ "$(stat -f %m Output/posteriors/loo_m1_v4.rds)" -ge "$start_epoch" ]]; then
    break
  fi
  sleep 120
done

echo "[$(date)] Fresh m1_v4 artifacts found. Running audit + PPC + comparison..."
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
Rscript Code/04d_decide_next_after_m1_v4.R

if [[ -f "Output/diagnostics/m1_v4_next_action.txt" ]] && \
   grep -qx 'promote_m1_v4_hold_complexity' "Output/diagnostics/m1_v4_next_action.txt"; then
  echo "[$(date)] m1_v4 promoted. Holding richer process branches by default."
else
  echo "[$(date)] m1_v4 not clean enough. Holding process-complexity branches."
fi

echo "[$(date)] m1_v4 refresh complete."
