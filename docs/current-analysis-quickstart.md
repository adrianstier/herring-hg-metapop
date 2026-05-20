# Current Analysis Quickstart

Updated: 2026-05-16

This is the short path for collaborators who need the current answer without
reading every historical model branch.

## Read These First

1. `Output/diagnostics/latest_model_status.md`
2. `Output/diagnostics/promoted_baseline_evidence_package.md`
3. `Output/diagnostics/model_decision_ledger.md`
4. `Output/diagnostics/covariate_readiness_registry.md`
5. `docs/wcvi-predation-replication-bridge.md`
6. `docs/doherty-style-hg-source-provenance.md`
7. `docs/predator-repo-integration-guide.md`
8. `Output/diagnostics/predator_talk_brief.md`
9. `docs/saturday-talk-readiness-2026-05-16.md`
10. `Output/diagnostics/doherty_proxy_parameter_plan.md`
11. `Output/diagnostics/postclosure_recovery_mechanism_screen.md`
12. `Output/diagnostics/future_lag_negative_control_audit.md`
13. `AGENTS.md`

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
- the direct post-closure screen returns no strict predator/climate
  section-year candidate, so no-fishing should be framed as necessary but not
  sufficient rather than as proof of one unmodeled predator coefficient;
- the future-lag audit keeps immediate adult mortality separate from delayed
  age-3 recruitment-return mechanisms; the delayed hypothesis is plausible, but
  current Appendix B age-composition rows are provisional audit targets, while
  shared-spawn and SCA-output rows are context rather than model-ready
  covariates;
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
| Predator talk brief | `Output/diagnostics/predator_talk_brief.md` |
| Humpback missing-data scaffold | `Output/figures/humpback_section_exposure_proxy.pdf` |
| Salmon recruitment context | `Output/figures/salmon_recruitment_context_screen.pdf` |
| Predator mechanism integration | `Output/figures/predator_mechanism_integration_screen.pdf` |
| Post-closure mechanism screen | `Output/figures/postclosure_recovery_mechanism_screen.pdf` |
| Future-lag / age-3 audit | `Output/figures/future_lag_negative_control_audit.pdf` |

## Safe Next Analysis Steps

1. Do not submit another AWS model branch unless the model-decision ledger
   identifies a targeted Stier-aligned single-covariate question that can finish
   and be explained before the talk.
2. Current May 16 predator decision: `m5_stier_predator_demand_total` is
   completed and held, and no seal/sea-lion exposure row clears the lag-1 gate.
   Use `Output/diagnostics/predator_talk_brief.md`,
   `Output/diagnostics/hg_dfo_sca_external_comparison.md`, and
   `Output/figures/hg_dfo_sca_external_comparison.pdf` for DFO/predator scale
   context, not as evidence for a promoted predator coefficient.
3. Treat `Output/diagnostics/humpback_section_exposure_proxy.md` as a
   missing-data scaffold, not model-ready section exposure. Treat
   `Output/diagnostics/salmon_recruitment_context_screen.md` as
   juvenile/recruitment context, not adult biomass mortality.
4. Use `Output/diagnostics/predator_mechanism_integration_screen.md` as the
   current answer to predator integration with fishing/PDO/timing ideas. It
   returns zero strict candidates, so do not launch a predator x fishing or
   combined predator Stan branch from the current evidence.
5. Use `Output/diagnostics/postclosure_recovery_mechanism_screen.md` as the
   current answer to "why not recovered after closure." It returns zero strict
   post-closure section-year predator/climate candidates; endpoint context
   points to legacy depletion and unresolved local persistence/recolonization.
6. Use `Output/diagnostics/future_lag_negative_control_audit.md` for the
   timing caveat. Adult lag-1 and biomass-growth age-3 rows do not clear gates;
   public Appendix B age-composition rows are provisional audit targets only.
   Spawn-normalized rows share the adult-spawn input stream, and DFO 2025
   age-2 recruitment is SCA model-output context until exact DFO
   age-composition/recruitment inputs are available.
7. Use `docs/dfo-hg-biological-input-request-packet.md` for the exact DFO
   follow-up ask on machine-readable HG biological inputs and SCA/SISCAH
   metadata.
8. Refresh local diagnostics with `Code/08_refresh_may9_analysis_suite.sh` after
   any model artifact changes. The wrapper now ends with
   `Code/09_check_document_references.R`, so stale local file references are
   caught as part of the full refresh.
9. If AWS credentials are active, submit only smoke jobs first, then write the
   submission CSV with `cloud/submit_model_farm.py --out-csv ...`.
10. Use `cloud/watch_aws_batch_run.py` on the submission CSVs to poll and sync cloud results.
11. Promote no model branch unless it improves calibration, stays sampler-clean,
   and preserves the ambiguous-zero interpretation unless explicitly labeled as
   a sensitivity.

## Known Documentation Risk

Some older docs still begin with the historical M1-M6 model hierarchy. Treat
that as provenance. For current inference and reporting, use the promoted
`m1_stier_11` path described here.
