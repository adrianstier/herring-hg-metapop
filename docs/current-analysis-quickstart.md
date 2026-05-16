# Current Analysis Quickstart

Updated: 2026-05-14

This is the short path for collaborators who need the current answer without
reading every historical model branch.

## Read These First

1. `Output/diagnostics/latest_model_status.md`
2. `Output/diagnostics/promoted_baseline_evidence_package.md`
3. `Output/diagnostics/model_decision_ledger.md`
4. `Output/diagnostics/covariate_readiness_registry.md`
5. `docs/wcvi-predation-replication-bridge.md`
6. `docs/doherty-style-hg-source-provenance.md`
7. `docs/saturday-talk-readiness-2026-05-16.md`
8. `AGENTS.md`

## Current Baseline

Use `m1_stier_11` as the practical analysis baseline.

| Item | Path |
|---|---|
| Stan model | `inst/stan/herring_metapop_m1_stier_11.stan` |
| Fit script | `Code/03_fit_m1_stier_11.R` |
| Fit artifact | `Data/processed/m1_stier_11_fit.rds` |
| LOO artifact | `Output/posteriors/loo_m1_stier_11.rds` |
| Exact re-LOO note | `Output/diagnostics/m1_stier_11_exact_reloo.md` |

Baseline interpretation:

- zero and no-survey cells are ambiguous/missing, not informative
  nondetections;
- all 11 Haida Gwaii sections are fit;
- surface and SCUBA survey-era catchability terms are explicit;
- catch removals and lag-1 PDO are already in the model;
- age/size structure, predators, and density dependence are not promoted
  baseline components.

## Current Model Decisions

| Branch | Decision | Why |
|---|---|---|
| `m1_stier_11` | Promoted baseline | Sampler-clean; exact re-LOO resolved the only high Pareto-k point; best practical positive-spawn calibration. |
| `m1_stier_obs_hier` | Held | Sampler-clean, but positive-spawn calibration worsened. |
| `m1_stier_method_sensitivity` | Held | Useful q sensitivity; no calibration gain and unstable PSIS points remain. |
| `m2_stier_site_growth` | Held | Sampler-clean; section-growth heterogeneity did not improve calibration. |
| `m3_stier_distance` | Spatial context only | Sampler-clean and estimates a plausible distance range, but exact re-LOO had treedepth pressure and calibration gain is small. |
| `m5_stier_predation_pressure` | Held | First Stier-aligned predator-pressure branch is sampler-usable, but positive-spawn and catch calibration are effectively baseline-equivalent. |
| `m5_stier_predator_demand_total` | Held | Completed on AWS as the WCVI-bridge total-demand screen; sampler-clean, but calibration gain is too small and PSIS still has two Pareto-k points above 0.7. |
| `m5_v5` / `m5_combined` / older predator branches | Archived or no inference use | `m5_v5` has sampler pathologies; `m5_combined` saturated max treedepth and badly worsened calibration; older predator branches are stale/pathological or exploratory. |
| `m3_stier_distance_reloo` cloud array | Failed/incomplete, no rerun now | Local exact re-LOO already exists and the distance branch remains held. |

## Headline Numbers To Check Before Reporting

Use the generated diagnostics rather than hand-copying these values:

- `Output/diagnostics/current_biomass_estimate.md`
- `Output/diagnostics/current_biomass_uncertainty_decomposition.md`
- `Output/diagnostics/stier_signal_persistence_summary.md`
- `Output/diagnostics/positive_spawn_fit_caveat.md`
- `Output/diagnostics/section_action_matrix.md`

Current read from the May 14 refresh:

- all-11 2025 post-fishing biomass median is useful but has a wide upper tail;
- focal-9 biomass is the cleaner talk number because sparse Tasu/Naden sections
  drive most of the all-11 upper-tail uncertainty;
- historical fishing pressure is the strongest descriptive recovery axis;
- Cumshewa and Louscoone remain the clearest mechanism cases;
- predator, timing, substrate, and local spawn-location screens are data-product
  and targeting work before they are promoted model covariates.

## Figure Entry Points

| Question | Figure |
|---|---|
| Portfolio / synchrony | `Output/figures/m1_stier_11_portfolio_metrics_combined.pdf` |
| Current biomass uncertainty | `Output/figures/current_biomass_uncertainty_decomposition.pdf` |
| Section action priorities | `Output/figures/section_action_matrix.pdf` |
| Spawn/catch fit caveat | `Output/figures/positive_spawn_fit_caveat.pdf` |
| Local follow-up targets | `Output/figures/lead_location_followup_targets.pdf` |
| Covariate readiness | `Output/diagnostics/covariate_readiness_registry.md` |

## Safe Next Analysis Steps

1. Do not submit another AWS model branch unless the model-decision ledger
   identifies a targeted Stier-aligned single-covariate question that can finish
   and be explained before the talk.
2. Current May 14 predator decision: `m5_stier_predator_demand_total` is
   completed and held. Use `Output/diagnostics/hg_dfo_sca_external_comparison.md`
   and `Output/figures/hg_dfo_sca_external_comparison.pdf` for DFO/predator
   scale context, not as evidence for a promoted predator coefficient.
3. Refresh local diagnostics with `Code/08_refresh_may9_analysis_suite.sh` after
   any model artifact changes. The wrapper now ends with
   `Code/09_check_document_references.R`, so stale local file references are
   caught as part of the full refresh.
4. If AWS credentials are active, submit only smoke jobs first, then write the
   submission CSV with `cloud/submit_model_farm.py --out-csv ...`.
5. Use `cloud/watch_aws_batch_run.py` on the submission CSVs to poll and sync cloud results.
6. Promote no model branch unless it improves calibration, stays sampler-clean,
   and preserves the ambiguous-zero interpretation unless explicitly labeled as
   a sensitivity.

## Known Documentation Risk

Some older docs still begin with the historical M1-M6 model hierarchy. Treat
that as provenance. For current inference and reporting, use the promoted
`m1_stier_11` path described here.
