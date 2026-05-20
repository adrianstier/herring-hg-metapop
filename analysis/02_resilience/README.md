# `analysis/02_resilience/` — Reversibility / Hysteresis

Empirical dynamic modeling and driver-loop analysis testing whether the Haida Gwaii herring system shows hysteresis vs simply slow recovery.

## Layout

```
02_resilience/
├── scripts/         9 reversibility scripts + phase0 spike + figs_render
├── output/          intermediate (gitignored — figures go to Output/figures/reversibility_*)
└── docs/            (this README — cross-refs below)
```

## Pipeline (`scripts/12_reversibility_*.R`)

| Stage | Script | Purpose |
|---|---|---|
| spike | `phase0_reversibility_hysteresis_spike.R` | Phase 0 sanity check (descriptive only) |
| 01 | `12_reversibility_01_driver_axis.R` | Exploitation-rate driver axis |
| 02 | `12_reversibility_02_effective_driver.R` | Effective driver construction |
| 03 | `12_reversibility_03_edm.R` | S-map / EDM for state dependence |
| 04 | `12_reversibility_04_ccm.R` | CCM for driver-state causality |
| 05 | `12_reversibility_05_attractor_regime.R` | Drift–diffusion potential `U(x)` + regime-shift detection |
| 06 | `12_reversibility_06_driver_loop.R` | Driver-state loop via shoelace-area hysteresis test |
| 07 | `12_reversibility_07_controls.R` | Positive (cusp fold) + negative (AR1) power controls |
| 10 | `12_reversibility_10_discrimination_synthesis.R` | Cross-test discrimination table |
| fig | `12_reversibility_figs_render.R` | Render the 7 publication figures |

All scripts use `here::here()`; converted from bare `source("R/...")` during the 2026-05-20 reorganization.

## Shared library

`R/12_reversibility.R` (681 lines, 15 functions) + `R/12_reversibility_figs.R` (figure helpers). The render driver is in `scripts/12_reversibility_figs_render.R`.

## Methods rigor (audited 2026-05-20)

- **Hysteresis test** is computed via **shoelace area on driver-state loops** (`driver_state_loop()` lines 440–491 of `R/12_reversibility.R`), with null testing via `loop_null_pvalue()` — not just xy-plotting.
- **λ_max trajectory** is computed via **S-map Jacobian companion-matrix eigenvalue** (`smap_jacobian_eigen()` lines 188–242), not naive AR1 coefficient.
- **Surrogates** use Ebisuzaki phase-randomization (spec §5).
- **Positive control** is a ramped cusp fold, not a flat equilibrium.

## Figures

7 publication figures in `Output/figures/reversibility_*.{pdf,png}`:
- `reversibility_lambda_trajectory`, `reversibility_state_df`, `reversibility_potential`
- `reversibility_driver_loop`, `reversibility_controls`
- `reversibility_phase0_hysteresis_loop`, `reversibility_phase0_synchrony_loop` (phase0 spike outputs)

Companion legends in `Output/figures/legends/`.

## Specs and plans

- **Design spec:** [`docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md`](../../docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md)
- **Implementation plan:** [`docs/superpowers/plans/2026-05-19-herring-reversibility-hysteresis.md`](../../docs/superpowers/plans/2026-05-19-herring-reversibility-hysteresis.md)
- **Shared utilities with EWS:** [`docs/reversibility-ews-shared-utils.md`](../../docs/reversibility-ews-shared-utils.md)

## Open items

- The `phase0_reversibility_hysteresis_spike.R` produces two `reversibility_phase0_*` figures whose canonical-vs-deprecated status is undocumented. Decide whether the phase0 outputs are kept as sanity checks, integrated into 01–07, or archived.
- Two utility functions (`detect_candidate_transitions`, `survey_artifact_null`) are self-contained copies of EWS functions — see [`docs/reversibility-ews-shared-utils.md`](../../docs/reversibility-ews-shared-utils.md) for the dedupe obligation when EWS lands.
