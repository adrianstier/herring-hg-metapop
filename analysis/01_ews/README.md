# `analysis/01_ews/` — Early Warning Signals

Phase 1–10 EWS analysis on the Haida Gwaii herring metapopulation.

## Layout

```
01_ews/
├── scripts/         11 dependency-ordered scripts (11_ews_00 through 11_ews_10)
├── output/          EWS-specific intermediate artifacts (gitignored)
└── docs/            (this README — cross-refs below)
```

## Pipeline (`scripts/11_ews_*.R`)

| Stage | Script | Purpose |
|---|---|---|
| 00 | `11_ews_00_data_layers.R` | Build the two co-equal data layers (observed; `m1_stier_11` latent draws) |
| 01 | `11_ews_01_generic_aggregate.R` | Tier-1 generic temporal battery on aggregate biomass |
| 02 | `11_ews_02_spatial_synchrony.R` | Tier-2 spatial/synchrony (φ, η, var/skew, Moran's I, portfolio CV-ratio) |
| 03 | `11_ews_03_covariance_eigen.R` | Covariance leading-EOF / λ_max + MAR(1) eigenvalue |
| 04 | `11_ews_04_candidate_transitions.R` | STARS + breakpoint candidate-transition detection |
| 05 | `11_ews_05_surrogate_significance.R` | Kendall τ + AR(1)/phase-randomized surrogate p-values |
| 06 | `11_ews_06_sensitivity_grid.R` | window × detrend × unit × estimator τ sign/significance grid |
| 07 | `11_ews_07_survey_artifact_audit.R` | Survey-method false-positive audit + disqualification flags |
| 08 | `11_ews_08_controls_power.R` | Power calibration (fold + stationary scenarios) |
| 09 | `11_ews_09_lead_time_matrix.R` | Joins transitions + significance into the lead-time matrix |
| 10 | `11_ews_10_synthesis.R` | Narrative + claim-control summary |

All scripts use `here::here()` for paths. Run order is sequential; later scripts depend on earlier CSV outputs in `Output/diagnostics/ews_*.csv`.

## Shared library

`R/11_early_warning.R` — pure-function library (629 lines, 13 indicators). All script-level orchestration lives in `scripts/`; all math lives in the shared lib.

## Tests

`tests/testthat/test-early-warning.R` covers the shared lib's analytic invariants.

## Specs and plans

- **Design spec:** [`docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md`](../../docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md)
- **Implementation plan:** [`docs/superpowers/plans/2026-05-19-herring-ews-analysis.md`](../../docs/superpowers/plans/2026-05-19-herring-ews-analysis.md)
- **Shared utilities with resilience workstream:** [`docs/reversibility-ews-shared-utils.md`](../../docs/reversibility-ews-shared-utils.md)

## Talk firewall

EWS scripts must not import from the talk workspace at `analysis/04_talks/2026-royalsociety/`. Talk numbers are pulled *from* EWS outputs (`Output/diagnostics/ews_*.{csv,md}`), never the reverse. See `CLAUDE.md`.
