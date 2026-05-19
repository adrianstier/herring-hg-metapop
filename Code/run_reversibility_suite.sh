#!/bin/zsh
# run_reversibility_suite.sh
# Reversibility / hysteresis analysis suite runner.
# Runs all Phase 7 diagnostic scripts in dependency order, then renders
# the 5 publication figures.
#
# CRITICAL: Scripts are ENUMERATED EXPLICITLY -- do NOT glob.
# The numbering has a gap (no 08/09); globbing 12_reversibility_0*.R
# would silently SKIP 12_reversibility_10_discrimination_synthesis.R
# (the headline script).  Dependency order below is authoritative.
#
# Script 07 (controls) may quit(status=1L) on canonical-seed PRIMARY
# failure -- set -e correctly propagates that as a suite failure (intended
# gate; do not add || true here).
#
# Usage:
#   cd <repo-root>
#   zsh Code/run_reversibility_suite.sh
#
# Exit 0 = all scripts completed, controls gate passed, figures rendered.
# Exit non-0 = a script failed (check log for which one).

set -euo pipefail

cd "$(dirname "$0")/.."

log_file="reversibility_suite.log"

{
  echo "[$(date)] Starting reversibility / hysteresis suite"

  # ------------------------------------------------------------------
  # Phase 7: diagnostic scripts (explicit dependency order)
  # ------------------------------------------------------------------

  echo "[$(date)] 01 driver_axis"
  Rscript Code/12_reversibility_01_driver_axis.R

  echo "[$(date)] 02 effective_driver"
  Rscript Code/12_reversibility_02_effective_driver.R

  echo "[$(date)] 03 edm"
  Rscript Code/12_reversibility_03_edm.R

  echo "[$(date)] 04 ccm"
  Rscript Code/12_reversibility_04_ccm.R

  echo "[$(date)] 05 attractor_regime"
  Rscript Code/12_reversibility_05_attractor_regime.R

  echo "[$(date)] 06 driver_loop"
  Rscript Code/12_reversibility_06_driver_loop.R

  echo "[$(date)] 07 controls  [PRIMARY gate -- suite fails if canonical seed fails]"
  Rscript Code/12_reversibility_07_controls.R

  echo "[$(date)] 10 discrimination_synthesis  [headline; gap in numbering is intentional]"
  Rscript Code/12_reversibility_10_discrimination_synthesis.R

  # ------------------------------------------------------------------
  # Phase 8: publication figures
  # ------------------------------------------------------------------

  echo "[$(date)] Figure render"
  Rscript Code/12_reversibility_figs_render.R

  echo "[$(date)] Reversibility suite complete -- exit 0"
} 2>&1 | tee "$log_file"
