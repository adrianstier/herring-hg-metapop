# Talk Model Claim Control Sheet

Created: 2026-05-17

## Purpose

This is the talk-facing contract between the model farm, predator/Doherty work,
and the US-UK Forum slide plan. Use it before drafting or presenting any model
claim. It is intentionally stricter than the narrative outline: if a phrase
conflicts with this sheet, revise the phrase.

## Bottom Line

- The promoted quantitative baseline is `m1_stier_11`.
- All other fitted model branches are held context, sensitivities, diagnostics,
  or archived exclusions.
- Predator demand is ecologically large and worth showing, but no predator
  coefficient is promoted for Haida Gwaii.
- The Doherty work is a source-traceable HG bridge and gap table, not a
  completed HG catch-at-age predation-mortality replication.
- Closure removed direct fishing pressure, but the post-closure screen does not
  identify a single promoted mechanism for incomplete recovery.

## Claim Boundaries

| Topic | Safe claim | Do not say | Primary source |
|---|---|---|---|
| Baseline model | `m1_stier_11` is the promoted Stier-aligned baseline: ambiguous zeros, two-era `q`, 11 fitted sections, focal-9 reporting sensitivity. | Do not call zero records proven absences; do not replace the baseline with a held branch. | `Output/diagnostics/latest_model_status.md`; `Output/diagnostics/model_decision_ledger.md` |
| Portfolio/recovery | Recent biomass partly rebounds but remains concentrated; local section recovery is uneven and portfolio diversity remains low. | Do not equate total biomass with recovered ecosystem-service function. | `Output/diagnostics/promoted_baseline_evidence_package.md`; `Output/diagnostics/m1_stier_11_portfolio_metrics.md`; `docs/saturday-talk-readiness-2026-05-16.md` |
| No-fishing period | No-fishing is necessary but not sufficient; direct fishing removals are near zero recently, yet some sections remain depleted. | Do not imply that post-closure non-recovery proves predator control. | `Output/diagnostics/fishing_closure_response.md`; `Output/diagnostics/postclosure_recovery_mechanism_screen.md` |
| Predator demand | Recent predator consumption is large relative to public spawn/biomass context, and the predator field is a serious ecological pressure. | Do not say the current HG model proves predator recovery caused non-recovery. | `Output/diagnostics/predator_talk_brief.md`; `Output/diagnostics/hg_dfo_sca_external_comparison.md`; `docs/predator-analysis-integration-roadmap.md` |
| Predator Stan branches | `m5_stier_predation_pressure` and `m5_stier_predator_demand_total` are sampler-usable held screens with no material calibration gain. | Do not promote `predcoef`, run combinations, or spend exact re-LOO time without a new gate-clearing reason. | `Output/diagnostics/model_decision_ledger.md`; `Output/diagnostics/latest_model_status.md` |
| Doherty/WCVI | Doherty et al. is the WCVI model-structure reference; our HG work replicates the data-readiness logic and a biomass-scale proxy bridge. | Do not describe WCVI catch-at-age, size-at-age, or selectivity assumptions as HG-estimated parameters. | `docs/doherty-style-hg-gap-table.md`; `docs/doherty-style-hg-replication-status.md`; `docs/doherty-style-hg-source-provenance.md` |
| DFO SCA summaries | DFO 2025/005 tables provide public HG assessment context through 2024 and confirm age/weight input windows. | Do not treat DFO SCA recruitment/biomass outputs as independent observations or likelihood validation of `m1_stier_11`. | `docs/doherty-style-hg-source-provenance.md`; `Output/diagnostics/hg_dfo_sca_external_comparison.md` |
| Age/recruitment lag | A 3-year recruitment-return lag is biologically plausible, but current public/proxy screens are audit targets only. | Do not treat spawn-normalized age proxies or DFO SCA age-2 recruitment as independent juvenile-survey evidence. | `Output/diagnostics/future_lag_negative_control_audit.md`; `docs/predator-analysis-integration-roadmap.md` |
| Legacy models | Legacy `v3`/`v4`/`v5` and surveyed-cell branches are context/sensitivity only because likelihood units and zero treatment differ. | Do not compare raw LOOIC across `positive_only` and surveyed-cell likelihoods. | `Output/diagnostics/model_decision_ledger.md`; `Output/diagnostics/latest_model_status.md` |

## Slide-Level Translation

| Slide/beats | Approved framing |
|---|---|
| Portfolio / structure | "The state variable that tips is spatial structure and service delivery, not just coastwide biomass." |
| Predator beat | "Predator demand is now large enough to be a serious pressure, and WCVI shows the mechanism can matter; in HG, our model screens keep it as context until section exposure and age-selective data improve." |
| Hysteresis beat | "The driver can be reduced without the service trajectory retracing the collapse path." |
| DFO / LRP beat | "Public DFO outputs show HG remains below reference-point context even after closures; compare scale and status, not model likelihood." |
| Closing solution | "Manage exposure and monitoring scale under uncertainty; do not wait for a single solved mechanism." |

## Current Model Classes

| Model class | Models | Talk use |
|---|---|---|
| Promoted baseline | `m1_stier_11` | Headline biomass, recovery, portfolio, branch comparisons. |
| Held observation sensitivities | `m1_stier_method_sensitivity`, `m1_stier_obs_hier` | Robustness/negative calibration results only. |
| Held process context | `m2_stier_site_growth`, `m3_stier_distance`, `m5_stier_predation_pressure`, `m5_stier_predator_demand_total` | "Tested and held"; do not interpret coefficients as mechanisms. |
| Archived exclusions | `m5_v5`, `m5_combined` | Do not use for inference. |
| Planning/troubleshooting only | `m5_stier_doherty_mp_covariate`, `m5_stier_doherty_proxy_removals`, `m6_timevarying`, density branches | Data-product or geometry notes only; no talk inference. |

## Pre-AWS Gate

Before any new AWS job after the talk package:

1. The model-decision ledger must identify one specific branch and one specific
   diagnostic question.
2. The covariate must be source-traceable, exogenous enough for the claim, and
   pass lag/sign/effect-size/detrending/future-lag controls.
3. The expected output must change a decision, not merely add another model.

As of 2026-05-17, no new predator or Doherty branch clears that gate.
