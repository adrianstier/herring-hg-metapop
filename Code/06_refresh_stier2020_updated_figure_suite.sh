#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "[$(date)] Rebuilding updated Stier et al. 2020 main figures..."
Rscript Code/06g_reproduce_stier2020_figures_updated.R

echo "[$(date)] Rebuilding updated companion and supplement figures..."
Rscript Code/06h_companion_and_supplement_figures_updated.R

echo "[$(date)] Updated Stier figure suite complete."
echo "Main index: Output/diagnostics/stier2020_updated_figure_index.md"
echo "Companion/supplement index: Output/diagnostics/stier2020_updated_companion_supplement_index.md"
