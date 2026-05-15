# Saturday Talk Readiness, May 16 2026

This is the current handoff for building the Saturday talk from the May 14 model-farm state.

## Bottom Line

- Use `m1_stier_11` as the promoted Stier-aligned baseline.
- Keep zeros and no-survey cells ambiguous/missing, use the two-era surface/SCUBA `q`, and report all 11 fitted sections with the focal-9 sensitivity.
- Do not submit another AWS model before the talk unless a new diagnostic creates a specific single-covariate question. The May 14 ledger does not justify one.
- Treat `m5_stier_predation_pressure`, `m2_stier_site_growth`, `m3_stier_distance`, `m1_stier_obs_hier`, and `m1_stier_method_sensitivity` as held context branches.
- For predators, use the WCVI bridge as context: predator demand is large, but
  the prepared `m5_stier_predator_demand_total` branch is gated because the
  adjusted diagnostic signal is weak and the model is computationally heavy.
- Archive `m5_combined` and `m5_v5`; do not spend exact re-LOO or combination-model time there.

## Talk Spine

1. The updated Stier-aligned baseline is now stable enough to report.
2. Total biomass is not the whole story: recent biomass is partly rebuilt, but section occupancy and portfolio diversity remain low.
3. Recent biomass is concentrated in a few sections, while Louscoone, Cumshewa, Skidegate, Laskeek, and Rennell carry the main depletion/portfolio warning.
4. Historical fishing pressure is the cleanest descriptive recovery axis, but it does not fully explain uneven recovery after closures.
5. Zeros and no-survey cells are a survey/access caveat, not automatic biological absences.
6. Predators, timing/substrate, density dependence, and spatial covariance are context or future data-product/model branches, not promoted causal claims for this talk.

## Numbers To Keep Handy

- `m1_stier_11`: 0 divergences, 0 treedepth hits, max R-hat about 1.001, min E-BFMI about 0.802.
- Exact re-LOO resolved the high Pareto-k baseline point; corrected LOOIC is about 1953.08.
- Positive-spawn log RMSE is about 0.565; catch log RMSE is about 0.010.
- 2025 all-11 post-fishing biomass median is about 82,214 t, but the upper tail is driven by sparse Tasu/Naden sensitivity sections.
- 2025 focal-9 post-fishing biomass median is about 47,640 t.
- Recent top-three biomass share is about 76% in the current-year summary and about 84% over the recent period portfolio read; use the period-specific figure when discussing portfolio erosion.
- Survey matrix: 495 positive site-years, 19 zero-record site-years, and 311 missing/unsurveyed site-years.
- Predator bridge: mean 2015-2024 HG predator consumption is about 15.5 kt/yr;
  the predator-removal analogue against `m1_stier_11` biomass is about 25%.
  Treat this as ecological scale, not a promoted predator coefficient.

## Use These First

- `Output/diagnostics/latest_model_status.md`
- `Output/diagnostics/model_decision_ledger.md`
- `Output/diagnostics/promoted_baseline_evidence_package.md`
- `Output/diagnostics/may10_integrated_evidence_matrix.md`
- `Output/diagnostics/covariate_readiness_registry.md`
- `Output/diagnostics/section_action_matrix.md`

## Figure Order

1. `Output/figures/stier2020_updated/fig1_spatiotemporal_spawn_updated.pdf`
2. `Output/figures/m1_stier_11_current_year_status.pdf`
3. `Output/figures/current_biomass_uncertainty_decomposition.pdf`
4. `Output/figures/portfolio_metrics_combined.pdf`
5. `Output/figures/section_action_matrix.pdf`
6. `Output/figures/fishing_closure_response.pdf`
7. `Output/figures/survey_coverage_zero_ambiguity.pdf`
8. `Output/figures/m1_stier_11_positive_spawn_fit_summary.pdf`
9. `Output/figures/positive_spawn_fit_caveat.pdf`
10. `Output/figures/lead_location_followup_targets.pdf`
11. `Output/figures/wcvi_predation_replication_bridge.pdf`
12. `Output/figures/predator_spatial_exposure_prototype.pdf`

## Model-Farm Decision

AWS was refreshed on May 14 with profile `herring`. The May 13 cloud round is terminal: core Stier branches succeeded, `m3_stier_distance_reloo` failed/incomplete in the cloud array, and local exact re-LOO already covers the distance branch. No S3-synced result changes the promoted baseline.

Do not run `m5_combined` exact re-LOO, do not relaunch the distance exact-reLOO array before the talk, and do not launch a timing/substrate, density-dependence, or predator combination branch just to have one more model. The talk is stronger with the current branch decisions cleanly separated from future mechanism work.
