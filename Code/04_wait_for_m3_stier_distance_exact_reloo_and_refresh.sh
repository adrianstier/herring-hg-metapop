#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

reloo_label="${M3_DISTANCE_RELOO_LABEL:-exact}"
if [[ "$reloo_label" == "exact" ]]; then
  out_stem="m3_stier_distance_exact_reloo"
else
  out_stem="m3_stier_distance_${reloo_label}_reloo"
fi

csv_file="Output/diagnostics/${out_stem}.csv"
export M3_DISTANCE_RELOO_WATCH_CSV="$csv_file"

echo "[$(date)] Waiting for m3_stier_distance ${reloo_label} re-LOO to finish..."

while true; do
  if [[ -f "$csv_file" ]]; then
    progress="$(
      Rscript --vanilla -e '
        x <- read.csv(Sys.getenv("M3_DISTANCE_RELOO_WATCH_CSV"))
        completed <- suppressWarnings(max(x$n_exact_refit_completed, na.rm = TRUE))
        total <- suppressWarnings(max(x$n_high_pareto_total, na.rm = TRUE))
        if (!is.finite(completed)) completed <- 0
        if (!is.finite(total)) total <- NA
        cat(completed, total, sep = "/")
      '
    )"
    echo "[$(date)] ${reloo_label} re-LOO progress: $progress"
    completed="${progress%%/*}"
    total="${progress##*/}"
    if [[ "$total" != "NA" && "$completed" -ge "$total" ]]; then
      break
    fi
  fi
  sleep 300
done

echo "[$(date)] m3_stier_distance ${reloo_label} re-LOO complete. Refreshing model comparison and synthesis..."

Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
Rscript Code/07s_m3_stier_distance_postfit.R
Rscript Code/07x_driver_model_triage.R
Rscript Code/07q_may9_headline_findings_table.R
Rscript Code/07ag_integrated_evidence_matrix.R

echo "[$(date)] m3_stier_distance ${reloo_label} re-LOO refresh complete."
