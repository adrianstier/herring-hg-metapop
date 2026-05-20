# Monday Talk Sprint Plan

This is the short-horizon plan for turning the current repo into a defensible
talk by Monday. The Saturday priority is still analysis, not slide production:
keep extracting population and driver insight, then use Sunday to package the
best-supported results.

May 11 update: the current analysis package is now in Monday-ready triage mode.
Do not change the promoted baseline unless new fit artifacts are synced and
diagnostic-clean. The highest-value remaining work is polishing interpretation
and local mechanism targeting around the existing `m1_stier_11` result.

## Talk-Ready Claims

Use `Output/diagnostics/may10_integrated_evidence_matrix.md` as the compact
claim/evidence/caveat/action control sheet while refining these claims.
Use `Output/diagnostics/covariate_readiness_registry.md` when deciding whether
a covariate belongs in the current story, a future data product, or a held model
idea.

1. The Stier-aligned baseline is now fit and promoted.
   - Model: `m1_stier_11`.
   - Zeros are ambiguous/missing, matching Stier et al. (2020) and the archived
     JAGS model.
   - All 11 Haida Gwaii sections are fit.
   - Surface and SCUBA/dive survey catchability are estimated separately.
   - Size/age structure, predators, and density dependence are intentionally
     held out of this baseline.

2. The baseline passes core diagnostics.
   - 0 divergences.
   - 0 treedepth hits.
   - max R-hat about 1.001.
   - min E-BFMI about 0.802.
   - The one high Pareto-k point was resolved by exact re-LOO.
   - Exact re-LOO changed total LOOIC only from 1953.02 to 1953.08.

3. The main data story is now cleaner.
   - Positive spawn fit is reasonable under the Stier-aligned likelihood.
   - Catch is fit through the fishing-rate component.
   - Zero-spawn records are not treated as biological absences without survey
     metadata.
   - The focused survey-coverage audit shows 495 positive site-years, 19
     zero-record site-years, and 311 missing/unsurveyed site-years.
   - 9 focal sections are a reporting sensitivity from the same 11-section fit,
     not a different biological model.

4. The next process and scale checks are informative but not promoted.
   - `m2_stier_site_growth` was sampler-clean but did not improve
     positive-spawn calibration.
   - `m1_stier_method_sensitivity` was sampler-clean but did not improve
     positive-spawn calibration; its q estimates are descriptive context.
   - `m3_stier_distance` was sampler-clean and estimated a practical
     process-correlation range near 144 km; exact re-LOO completed, but one
     exact refit had treedepth pressure and the positive-spawn calibration gain
     remains too small for promotion.
   - Legacy SHI and DFO tonnes are strongly related but not linked by one
     constant multiplier; the broad observed overlap story through 2015 is
     similar across scales.
   - Predator recovery is ecological context, not a promoted covariate result:
     the combined predator index has rho about 0.96 with year and needs a
     spatial exposure data product before section-level inference.

5. The literature/NotebookLM parameter roadmap now points to observation
   calibration before new biological-driver branches.
   - See `docs/literature-parameter-roadmap.md`.
   - Completed/held Stan branch: `m1_stier_obs_hier`.
   - Result: same `m1_stier_11` process and ambiguous-zero likelihood,
     with hierarchical section-specific observation error and surface-era
     extra variance, fit cleanly but worsened positive-spawn calibration.
   - Do not jump to predators, full age/size structure, explicit movement, or
     complex density dependence before the observation-scale problem is tested.

6. The strongest new mechanism follow-up is local and named, not another
   regional coefficient.
   - Use `Output/diagnostics/lead_location_followup_targets.md` and
     `Output/figures/lead_location_followup_targets.pdf`.
   - Highest-priority locations include Traynor Creek, Louscoone Inlet East,
     Kilmington Point, Skindaskun Island, Atli Inlet, Cumshewa Inlet, and
     Conglomerate Point.
   - Treat lost-location labels as audit targets only; they are not
     effort-adjusted absence evidence without survey-access confirmation.

## Must-Have Figures For Monday

Use these before adding new model results:

1. `Output/figures/spawn_timeseries_by_section.pdf`
   - Shows the raw survey-history problem.
2. `Output/figures/m1_stier_11_positive_spawn_fit_summary.pdf`
   - Shows observed vs fitted positive spawn signal and residuals.
3. `Output/figures/m1_stier_11_positive_spawn_fit_by_section.pdf`
   - Shows section-level fit.
4. `Output/figures/m1_stier_11_catch_fit_by_section.pdf`
   - Shows catch fit.
5. `Output/figures/m1_stier_9_focal_reporting_summary.pdf`
   - Shows 11-section fit versus Stier 9-focal reporting sensitivity.
6. `Output/figures/section_narrative_synthesis.pdf`
   - Shows the current section roles: mechanism scrutiny, portfolio concern,
     recovery contrast, and sensitivity caveat.
7. `Output/figures/fishing_closure_response.pdf`
   - Shows the key driver nuance: direct fishing pressure ended, biomass partly
     rebounded, but occupied sections and portfolio diversity stayed low.
8. `Output/figures/survey_coverage_zero_ambiguity.pdf`
   - Shows why zeros/no-survey cells are not simple biological absences.
9. `Output/figures/predator_data_feasibility_audit.pdf`
   - Use as a context/limitations figure if predators come up.
10. `Output/figures/portfolio_metrics_combined.pdf`
   - Regenerated from `m1_stier_11`; use for portfolio buffering, synchrony,
     top-three share, and effective-section count.
11. `Output/figures/lead_location_followup_targets.pdf`
   - Shows named locations for local access/substrate/exposure follow-up.

## Weekend Work Order

### Saturday

1. Finish and inspect the 9-focal reporting figures.
2. Keep running analysis that improves interpretation:
   - exact re-LOO for `m3_stier_distance`;
   - observation scale and legacy SHI sensitivity;
   - section transition / occupancy screens;
   - driver confounding and robustness checks;
   - PDO lag/window sensitivity on the existing baseline;
   - survey coverage / zero ambiguity synthesis;
   - predator data feasibility audit;
   - section narrative synthesis;
   - stale figure cleanup only where it affects interpretation.
3. Do not spend Saturday building the deck unless the analysis queue is idle.

### Sunday

1. Build the actual slide deck.
2. Add one compact model-roadmap slide.
3. Add one limitations slide:
   - raw LOOIC only comparable within likelihood unit,
   - zeros ambiguous without survey-effort metadata,
   - no age/size structure yet,
   - predator effects not yet in promoted baseline.
4. Rehearse the 2-minute version of the conclusion.

### Monday / Final Analysis Packaging

1. Open all PDFs in the deck and verify they render.
2. Keep backup figures in `Output/figures/`.
3. Do not launch a new long Stan fit unless a result is already finished and
   diagnostic-clean.
4. If AWS SSO is refreshed, poll/sync cloud jobs first, then rerun
   audit/PPC/comparison before changing any promoted status.
5. If AWS remains blocked, stay local: polish the evidence package, section
   action matrix, local follow-up targets, and figure order.

## Next Models After The Talk

Start from the `m1_stier_11` observation layer. Do not promote stale `v3`/`v5`
branches directly.

The current literature-grounded branch order is maintained in
`docs/literature-parameter-roadmap.md`. The practical rule is: finish the
`m3_stier_distance` exact re-LOO triage, then test observation calibration
before adding new biological-driver terms.

1. `m1_stier_method_sensitivity`
   - Same process as `m1_stier_11`.
   - Compare Stier two-era `q` with three-era surface/mixed/dive `q`.
   - Purpose: isolate survey-method sensitivity before process complexity.
   - Status: finished May 9 and held.
   - Readout: `Output/diagnostics/m1_stier_method_sensitivity_postfit.md`
     and `Output/figures/m1_stier_method_sensitivity_postfit.pdf`.
   - Decision: sampler-clean but no positive-spawn fit gain; use its q
     estimates as descriptive survey-era context, not as the promoted model.

2. `m2_stier_site_heterogeneity`
   - Site-specific growth and/or process variance.
   - No spatial covariance yet.
   - Purpose: identify whether persistent section differences are driving fit.
   - Status: simple site-growth version `m2_stier_site_growth` finished and is
     held; it was sampler-clean but did not improve positive-spawn calibration.

3. `m3_stier_distance`
   - Distance-decay process covariance.
   - Same observation layer.
   - Purpose: test whether nearby sections share process shocks.
   - Status: finished May 9 and held. It is sampler-clean and estimates a
     practical range near 144 km, but positive-spawn calibration gain is small
     and exact re-LOO showed one exact refit with treedepth pressure.

4. `m1_stier_obs_hier`
   - Same process as `m1_stier_11`.
   - Same ambiguous-zero likelihood and Stier two-era survey `q`.
   - Add hierarchical section-specific observation error `sigma_obs[j]`.
   - Add method-specific positive-observation scale, especially extra
     surface-era variance.
   - Optional weak surface-era bias only if extra variance does not improve the
     residual pattern.
   - Purpose: address the remaining positive-spawn magnitude misfit directly
     before changing the biological process model.
   - Status: finished cleanly, but held as a negative result because
     positive-spawn calibration worsened relative to `m1_stier_11`.

5. `m2_stier_process_variance`
   - Section-specific process variance, with strong pooling.
   - Purpose: test whether uneven section recovery reflects different
     unobserved process volatility after observation calibration.

6. `m4_stier_dd`
   - Global density dependence.
   - Purpose: test closure-era recovery expectations.
   - Only test one global Gompertz term before any site-specific DD.

7. `m5_stier_timing_habitat`
   - Lagged spawn timing and substrate covariates.
   - Purpose: observation/reporting or phenology/habitat sensitivity before
     predators.

8. `m6_stier_predator_exposure`
   - Predator covariates only after a spatial exposure data product exists.
   - Purpose: avoid confounding predator trends with post-closure time trends
     and regional time trends.

9. Regional age/weight covariate checks.
   - Age composition, age-3 share, mean age, and weight-at-age are future
     regional productivity/recruitment context.
   - Do not build a full 11-section age-structured model for this talk cycle.

## Do Not Attempt Before Monday

- Full section-level age-structured model.
- Predator model as the next immediate step.
- Site-specific density dependence.
- Explicit dispersal or movement matrix.
- More complex zero-detection model as the main baseline.
- Any unchanged `m1_stier_obs_hier` rerun; it is already a clean negative
  result and should be cited as held.
- Any new model that cannot finish, diagnose, and be explained before the talk.
