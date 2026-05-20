# May 9 Analysis Output Index

This index maps the May 9 diagnostics to the question each one answers. It is
for rapid navigation, not a slide outline.

## Baseline Status

- `docs/current-population-driver-findings.md`
  Current full synthesis.
- `docs/may-9-analysis-decision-summary.md`
  Compact checkpoint after `m2_stier_site_growth` finished and was held.
- `docs/m2-site-growth-decision-guide.md`
  May 9 result plus mechanical promotion/failure gates for future `m2` reruns.
- `docs/m3-distance-decision-guide.md`
  Distance-covariance result, exact re-LOO instructions, and promotion gates.
- `docs/literature-parameter-roadmap.md`
  NotebookLM/local-paper synthesis of candidate parameters. Key result: the
  best next optional Stan branch is observation calibration
  (`sigma_obs[j]` plus surface-era extra positive-observation variance), not
  predators or full age/size structure.
- `Output/diagnostics/latest_model_status.md`
  Last regenerated model comparison status, including the held
  `m2_stier_site_growth`, `m1_stier_method_sensitivity`, and
  `m3_stier_distance` branches.
- `Output/diagnostics/may9_headline_findings.md`
  Compact table of headline numbers and interpretations for rapid synthesis.
- `Output/diagnostics/may9_headline_findings.csv`
  Machine-readable version of the same headline table.
- `Output/diagnostics/may10_integrated_evidence_matrix.md`
  Compact claim/evidence/caveat/action matrix for deciding what is trusted,
  what is contextual, and what should be held before the Monday talk.
- `Output/diagnostics/may10_integrated_evidence_matrix.csv`
  Machine-readable version of the same evidence matrix.
- `Output/diagnostics/model_branch_status_table.md`
  Compact answer to which model branches have finished, fit acceptably, and are
  usable for Monday. Key result: `m1_stier_11` is promoted, `m3_stier_distance`
  is the only clean spatial candidate but remains held after exact re-LOO, and
  no predator model is currently usable.
- `Output/diagnostics/model_branch_status_table.csv`
  Machine-readable version of the model branch status table.
- `Output/diagnostics/section_action_matrix.md`
  Current section-level work plan separating lead mechanism cases, portfolio
  erosion cases, current biomass concentration cases, recovery contrasts, and
  uncertainty sensitivities.
- `Output/figures/section_action_matrix.pdf`
  Visual version of that section action matrix.
- `Output/diagnostics/lead_section_local_audit.md`
  Local survey/context audit for Cumshewa, Louscoone, Laskeek, and Skidegate.
- `Output/figures/lead_section_local_audit.pdf`
  Visual local audit of annual records, period coverage, and raw HG location
  concentration.

## Data And Observation Context

- `Output/figures/survey_method_coverage_audit.pdf`
  Shows section-year survey coverage, zero records, missing cells, and raw DFO
  method mix.
- `Output/diagnostics/survey_method_coverage_audit.md`
  Text summary: 495 positive section-years, 19 zero-record section-years, 311
  missing/unsurveyed section-years.
- `Output/figures/survey_coverage_zero_ambiguity.pdf`
  Focused figure for the talk/manuscript caveat that zero records and
  missing/unsurveyed cells are not simple biological absences.
- `Output/diagnostics/survey_coverage_zero_ambiguity.md`
  Key result: 514 surveyed site-years, 311 missing/unsurveyed site-years, and
  only 19 zero-record site-years; weakest median coverage occurs in the
  marine-heatwave and early-industrial periods.
- `Output/figures/m1_stier_11_fit_quality_summary.pdf`
  Where the baseline fits spawn and catch well or poorly.
- `Output/diagnostics/m1_stier_11_fit_quality_summary.md`
  Key result: surface-era positive-spawn magnitudes remain the weak point.
- `Output/diagnostics/positive_spawn_fit_caveat.md`
  Focused caveat for what not to over-interpret: early-industrial and
  surface-era positive-spawn magnitudes fit worst; modern status and
  period/portfolio summaries are safer.
- `Output/figures/m1_stier_11_uncertainty_audit.pdf`
  Identifies sections where posterior uncertainty dominates interpretation.
- `Output/figures/spawn_index_scale_audit.pdf`
  Compares Stier legacy SHI against maintained DFO spawn-index tonnes.
- `Output/diagnostics/spawn_index_scale_audit.md`
  Key result: median SHI / tonnes ratio is about `112`, but the ratio varies
  strongly by section, so a legacy-scale sensitivity should not use a single
  global multiplier.
- `Output/figures/legacy_shi_overlap_sensitivity.pdf`
  Checks whether broad observed patterns through 2015 change between legacy SHI
  and DFO tonnes.
- `Output/diagnostics/legacy_shi_overlap_sensitivity.md`
  Key result: annual positive-signal log correlation `0.942`, occupied-section
  correlation `0.993`, section recent/early Spearman correlation `0.952`.

## Population State

- `Output/figures/m1_stier_11_population_driver_dashboard.pdf`
  Broad population and driver dashboard.
- `Output/figures/m1_stier_11_current_year_status.pdf`
  2025 current-year status: biomass concentration and survey status.
- `Output/figures/mhw_recovery_screen.pdf`
  Closure-era and marine-heatwave period context for total biomass, growth, and
  section changes.
- `Output/diagnostics/mhw_recovery_screen.md`
  Key result: the MHW window is useful context, but it does not explain the
  section-level recovery/depletion typology by itself.
- `Output/figures/m1_stier_11_cryptic_collapse_screen.pdf`
  Section-level low-biomass threshold screen relative to 1951-1965 baselines.
- `Output/figures/m1_stier_11_postclosure_recovery.pdf`
  Post-closure section trends.
- `Output/figures/m1_stier_11_section_scorecard.pdf`
  Integrated section status: recovery, depletion, catch, coverage, fit quality.
- `Output/figures/section_mechanism_typology.pdf`
  Section-level synthesis of recent/early biomass, fishing pressure,
  after-fishing residuals, survey coverage, uncertainty, and current share.
- `Output/diagnostics/section_mechanism_typology.md`
  Key result: Cumshewa and Louscoone are persistent depletion beyond fishing;
  Tasu and Naden are sparse/uncertain sensitivity sections.
- `Output/figures/section_narrative_synthesis.pdf`
  One-row-per-section interpretation synthesis translated into a compact
  diagnostic matrix and role plot.
- `Output/diagnostics/section_narrative_synthesis.md`
  Analysis triage table grouping sections into mechanism scrutiny, portfolio
  concern, recovery contrast, and sensitivity caveats.
- `Output/diagnostics/section_driver_dossiers.md`
  One section-by-section driver read that combines role, recent/early biomass,
  fishing residuals, survey coverage, post-closure trend, and density-screen
  context.
- `Output/figures/observed_occupancy_transition_screen.pdf`
  Positive-detection persistence and zero-record transition screen using only
  adjacent surveyed year-section pairs.
- `Output/diagnostics/observed_occupancy_transition_screen.md`
  Key result: positive detections persist in `99.1%` of adjacent surveyed
  pairs, but zero-record starts are too sparse for true recolonization
  inference.

## Portfolio And Spatial Structure

- `Output/figures/m1_stier_11_spatial_concentration.pdf`
  Recent top-3 share and effective section count.
- `Output/figures/m1_stier_11_portfolio_metrics_combined.pdf`
  Regenerated main portfolio figure from the promoted `m1_stier_11` baseline.
- `Output/diagnostics/m1_stier_11_portfolio_metrics.md`
  Key result: recent top-three share is about `84%`, Simpson effective sections
  about `3.26`, and all-11 recent synchrony about `0.63`.
- `Output/figures/m1_stier_11_spatial_shift.pdf`
  Coarse geographic redistribution of posterior biomass.
- `Output/figures/section_change_contribution.pdf`
  Additive section contribution to recent-minus-early and recent-minus-roe
  biomass change.
- `Output/diagnostics/section_change_contribution.md`
  Key result: apparent recovery is metric-sensitive and concentrated; additive
  section means remain below both early-industrial and roe-fishery levels.
- `Output/figures/m1_stier_11_residual_spatial_correlation.pdf`
  Whether residuals suggest distance-correlated process structure.

## Fishing And Driver Evidence

- `Output/figures/m1_stier_11_section_pressure_screen.pdf`
  Section-level historical fishing pressure versus recent/early biomass.
- `Output/figures/fishing_pressure_decomposition.pdf`
  Fishing-pressure decomposition with section residuals after mean fishing
  fraction.
- `Output/diagnostics/fishing_pressure_decomposition.md`
  Key result: fishing pressure is a strong descriptive axis, but Cumshewa,
  Louscoone, and Laskeek are more depleted than mean fishing pressure alone
  predicts.
- `Output/figures/fishing_closure_response.pdf`
  Closure-response synthesis: catch pressure drops to zero after 2005, biomass
  partly rebounds, but occupied sections and effective sections remain low.
- `Output/diagnostics/fishing_closure_response.md`
  Key result: recent biomass is about `1.52x` the roe-fishery median while
  median occupied sections fall from `8` during the roe fishery to `5`
  recently.
- `Output/figures/m1_stier_11_driver_robustness.pdf`
  Lagged/trend-robust driver screening.
- `Output/figures/pdo_climate_signal_screen.pdf`
  Focused PDO/climate diagnostic: time series, lag-1 growth relation, lag
  sensitivity, and PDO-state summaries.
- `Output/diagnostics/pdo_climate_signal_screen.md`
  Key result: baseline lagged-PDO effect is negative but uncertain; lag-1 PDO
  has rho `-0.49` with next-year growth and detrended r about `-0.42`.
- `Output/figures/pdo_window_sensitivity.pdf`
  Cheap lag/window sensitivity for PDO using posterior growth from
  `m1_stier_11`.
- `Output/diagnostics/pdo_window_sensitivity.md`
  Key result: PDO mean lag 0-1 is the strongest nearby window, but lag-1 PDO
  remains competitive, so the promoted baseline does not need a redundant
  PDO-only branch.
- `Output/figures/m1_stier_11_driver_confounding_audit.pdf`
  Driver collinearity and time confounding.
- `Output/figures/spawn_timing_substrate_screen.pdf`
  Spawn timing and substrate context; useful mainly for observation/context
  sensitivity.
- `Output/figures/density_dependence_screen.pdf`
  Descriptive test of whether next-year posterior median growth declines after
  high biomass.
- `Output/diagnostics/density_dependence_screen.md`
  Key result: no strong archipelago-wide negative density signal; pooled
  section signal is only weakly negative, so complex DD is held.
- `Output/figures/driver_model_triage.pdf`
  Compact evidence/readiness ranking for candidate drivers and model branches.
- `Output/diagnostics/driver_model_triage.md`
  Recommended operating order: report observation-scale caveats and fishing
  pressure now, interpret existing lagged PDO as climate context, hold
  predators/substrate/DD as context, and use spatial covariance only as
  ecological context after completed exact re-LOO.
- `Output/figures/predator_data_feasibility_audit.pdf`
  Current predator time series, source-observation years, and confounding
  screens.
- `Output/diagnostics/predator_data_feasibility_audit.md`
  Key result: the combined predator index is highly time-confounded
  (Spearman rho about `0.96` with year), while PDO is near-zero with year, so
  predators remain ecological context rather than the next Stan branch.
- `Output/figures/predator_spatial_exposure_prototype.pdf`
  Prototype map/exposure/correlation figure from raw Haida Gwaii harbour seal
  and Steller sea lion locations. This is a data-product feasibility figure,
  not predator-effect evidence.
- `Output/diagnostics/predator_spatial_exposure_prototype.md`
  Key result: rough section-level seal/sea-lion exposure is feasible, but the
  prototype remains time-confounded and lacks a section-level humpback exposure
  series. Refine exposure before adding predator coefficients.
- `Output/figures/section_recovery_covariate_screen.pdf`
  Combined n=11 descriptive screen for recovery ratio versus fishing pressure,
  observation caveats, timing/substrate shifts, and prototype predator exposure.
- `Output/diagnostics/section_recovery_covariate_screen.md`
  Key result: historical fishing pressure remains the cleanest section-level
  recovery axis; predator exposure, timing, and substrate are data-product
  targets rather than promoted causal covariates.
- `Output/figures/lead_section_location_transition.pdf`
  Raw HG spawn-location persistence/loss figure for Louscoone, Cumshewa, and
  Laskeek.
- `Output/diagnostics/lead_section_location_transition.md`
  Key result: Louscoone and Cumshewa recent raw signal is near 1% of roe-fishery
  raw signal, while Laskeek is about 13% with more persistent recent locations.
  This is local audit targeting, not effort-adjusted absence evidence.
- `Output/figures/lead_section_location_map.pdf`
  Geocoded companion map for the mappable raw locations in Louscoone, Cumshewa,
  and Laskeek.
- `Output/diagnostics/lead_section_location_map.md`
  Key result: use mapped lost/persistent locations to target local
  habitat/substrate, access, and exposure follow-up; do not interpret the map as
  effort-adjusted absence evidence.
- `Output/figures/lead_spawn_location_predator_proximity.pdf`
  Local proximity/exposure screen linking geocoded lead-section spawn locations
  to post-2005 harbour seal and Steller sea lion sites.
- `Output/diagnostics/lead_spawn_location_predator_proximity.md`
  Key result: predator proximity can be calculated locally, but lost locations
  are not clearly more predator-exposed than persistent locations; keep this as
  audit targeting, not predator-effect evidence.
- `Output/diagnostics/lead_location_followup_targets.md`
  Named local follow-up target list combining raw location persistence/loss,
  spawn-method/substrate metadata, coordinates, and predator proximity. Top
  targets include Traynor Creek, Louscoone Inlet East, Kilmington Point,
  Skindaskun Island, Atli Inlet, Cumshewa Inlet, and Conglomerate Point. This is
  the fastest table to use for local mechanism follow-up.
- `Output/figures/lead_location_followup_targets.pdf`
  Ranked visual version of the named local follow-up target list.
- `Output/diagnostics/covariate_readiness_registry.md`
  Current covariate readiness control sheet. It separates baseline covariates,
  descriptive screens, prototype data products, and held ideas such as
  age/size structure.

## Completed Model Branch

- `inst/stan/herring_metapop_m2_stier_site_growth.stan`
  Adds hierarchical section-specific productivity to the `m1_stier_11`
  observation layer.
- `Code/03_fit_m2_stier_site_growth.R`
  Completed fit script.
- `Code/04_wait_for_m2_stier_site_growth_and_refresh.sh`
  Watcher that refreshes audit/PPC/model-comparison outputs when the fit and
  LOO artifacts are written, then runs the `m2` post-fit diagnostic.
- `Code/04_wait_for_m2_stier_site_growth_postfit.sh`
  Companion watcher for the already-running May 9 fit; it waits for fresh
  artifacts and runs only the `m2` post-fit diagnostic.
- `Code/07f_m2_stier_site_growth_postfit.R`
  Post-fit interpretation script to run after artifacts exist.
- `Code/07q_may9_headline_findings_table.R`
  Regenerates the compact headline findings table from diagnostic CSV outputs.
- `Code/07ag_integrated_evidence_matrix.R`
  Regenerates the compact claim/evidence/caveat/action control sheet from the
  current diagnostic CSV outputs.
- `Code/07ah_section_driver_dossiers.R`
  Regenerates the section-by-section driver dossiers from the current section
  diagnostics.
- `Code/08_refresh_may9_analysis_suite.sh`
  Re-runs the current May 9 diagnostic suite in dependency order and refreshes
  the headline table plus model status files.

## Completed Observation-Sensitivity Branch

- `inst/stan/herring_metapop_m1_stier_method_sensitivity.stan`
  Keeps the `m1_stier_11` process and ambiguous-zero likelihood but uses
  three survey-method q terms.
- `Code/03_fit_m1_stier_method_sensitivity.R`
  Completed fit script for the three-era q sensitivity.
- `Code/04_wait_for_m1_stier_method_sensitivity_and_refresh.sh`
  Watcher that refreshes audit/PPC/model-comparison outputs after the fit and
  LOO artifacts are written.
- `Code/07r_m1_stier_method_sensitivity_postfit.R`
  Post-fit q and positive-signal diagnostic for the three-era survey-method
  sensitivity. Outputs are
  `Output/figures/m1_stier_method_sensitivity_postfit.pdf` and
  `Output/diagnostics/m1_stier_method_sensitivity_postfit.md`.

## Completed Distance-Covariance Branch

- `inst/stan/herring_metapop_m3_stier_distance.stan`
  Keeps the `m1_stier_11` observation layer but replaces independent annual
  process shocks with distance-decay spatial covariance.
- `Code/03_fit_m3_stier_distance.R`
  Completed fit script for the distance-covariance branch.
- `Code/04_wait_for_m3_stier_distance_and_refresh.sh`
  Watcher that refreshes audit/PPC/model-comparison outputs after the fit and
  LOO artifacts are written.
- `Code/07s_m3_stier_distance_postfit.R`
  Post-fit diagnostic for the distance-decay parameter, practical range, and
  implied correlation curve.
- `Code/04g_m3_stier_distance_exact_reloo.R`
  Exact re-LOO script for the three high-k points. This writes incremental
  results to `Output/diagnostics/m3_stier_distance_exact_reloo.csv`.
- `Code/04_wait_for_m3_stier_distance_exact_reloo_and_refresh.sh`
  Lightweight watcher that waits for all exact re-LOO rows, then refreshes
  model comparison, interpretation, distance postfit, driver triage, headline
  findings, and the integrated evidence matrix.
- `Output/figures/m3_stier_distance_postfit.pdf`
  Distance-decay practical range and implied process-correlation curve.
- `Output/diagnostics/m3_stier_distance_postfit.md`
  Short interpretation: sampler-clean, median practical range about `144` km,
  positive-spawn RMSE only slightly better than `m1_stier_11`, exact re-LOO
  still pending.
- `Output/diagnostics/m3_stier_distance_pareto_k_points.csv`
  Correct high-k point map using the year-major Stan `log_lik` order.

## Immediate Model Decision Rule

The May 9 `m2_stier_site_growth`, `m1_stier_method_sensitivity`, and
`m3_stier_distance` decisions are already made at the current diagnostic level:
hold, do not promote. For future reruns:

1. Check sampler health first: divergences, treedepth, E-BFMI, R-hat.
2. Check whether positive-spawn and catch fit degrade relative to
   `m1_stier_11`.
3. Compare section-specific productivity estimates with:
   - `m1_stier_11_section_scorecard.csv`,
   - `m1_stier_11_section_pressure_screen.csv`,
   - `m1_stier_11_uncertainty_by_section.csv`.
4. If clean, interpretable, and improved, use it as the base for the next
   process branch.
5. If not clean or not improved, hold it. Do not add predators, density
   dependence, or age/size structure until a simpler observation or process
   branch materially improves fit or interpretation.
