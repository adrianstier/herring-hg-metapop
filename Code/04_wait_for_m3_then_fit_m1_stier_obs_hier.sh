#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

cat <<'MSG'
m1_stier_obs_hier has already completed and is held as a clean negative result.

This archived launcher used to wait for m3_stier_distance re-LOO and then start
m1_stier_obs_hier automatically. That behavior is now disabled so an unchanged
observation-hierarchy branch is not rerun by accident.

Current promoted baseline: m1_stier_11.
Current evidence package: Output/diagnostics/promoted_baseline_evidence_package.md
MSG
