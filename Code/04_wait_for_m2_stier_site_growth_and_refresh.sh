#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

start_epoch="$(date +%s)"

echo "[$(date)] Waiting for m2_stier_site_growth fit artifacts..."

while true; do
  if [[ -f "Data/processed/m2_stier_site_growth_fit.rds" && -f "Output/posteriors/loo_m2_stier_site_growth.rds" ]] && \
     [[ "$(stat -f %m Data/processed/m2_stier_site_growth_fit.rds)" -ge "$start_epoch" ]] && \
     [[ "$(stat -f %m Output/posteriors/loo_m2_stier_site_growth.rds)" -ge "$start_epoch" ]]; then
    break
  fi
  sleep 120
done

echo "[$(date)] Fresh m2_stier_site_growth artifacts found. Running audit + PPC + comparison..."
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
Rscript Code/07f_m2_stier_site_growth_postfit.R
echo "[$(date)] m2_stier_site_growth refresh complete."
