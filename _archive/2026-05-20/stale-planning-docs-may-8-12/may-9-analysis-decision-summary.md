# May 9 Analysis Decision Summary

Generated during the May 9, 2026 analysis sprint. This note summarizes the
state of evidence after the `m2_stier_site_growth`,
`m1_stier_method_sensitivity`, and `m3_stier_distance` fits finished.

Updated May 10, 2026 to integrate the literature/NotebookLM parameter roadmap
in `docs/literature-parameter-roadmap.md`.

## Practical Baseline

Use `m1_stier_11` as the current practical baseline:

- zeros are ambiguous/missing, not informative absences;
- all 11 sections are fitted;
- Stier-style surface and SCUBA/dive q terms are explicit;
- 9-focal reporting remains a sensitivity/reporting layer;
- age/size, predators, and density dependence are held out for now.

The exact re-LOO check for the high-k 1970 Naden Harbour point did not change
model ranking or interpretation.

## Finished Model Branches

- `m1_stier_11`: finished, sampler-clean, promoted baseline.
- `m1_stier_method_sensitivity`: finished and sampler-clean, but held as an
  observation sensitivity because the three-era q split did not improve
  positive-spawn calibration.
- `m2_stier_site_growth`: finished and sampler-clean, but held because simple
  section-productivity offsets did not improve calibration.
- `m3_stier_distance`: finished and sampler-clean. It estimated a plausible
  distance-decay process range near `144` km and slightly improved
  positive-spawn RMSE. Exact re-LOO completed for three influential
  observations, but the branch remains held because the fit gain is small and
  one exact refit had treedepth pressure.
- Predator model status: no current predator branch is usable. The old
  `m5_v3` artifact exists but is stale and sampler-pathological, so predators
  remain ecological context rather than fitted model evidence.

## Main Population Finding

The current story is not a simple archipelago-wide collapse or recovery.

The strongest pattern is spatial reorganization:

- recent biomass is concentrated in a few sections;
- the top 3 sections carry about 84% of recent all-11 posterior biomass;
- Simpson effective section count is only about 3.3;
- three focal sections remain below 20% of their early section baseline:
  Skidegate, Louscoone, and Cumshewa;
- 2025 is also concentrated: top 3 sections carry about 76% of posterior
  biomass.
- section contribution accounting shows that recent gains are concentrated and
  metric-sensitive; additive section means remain below both early-industrial
  and roe-fishery period levels even though the period-summary median total is
  higher than the roe-fishery period.
- the marine-heatwave period is an important temporal marker, but occupied
  sections remain low after it (`4.0` during MHW, `5.0` recently), so it does
  not replace the spatial recovery/depletion story.

## Section-Level Interpretation

Current scorecard:

- Persistently depleted: Skidegate, Louscoone, Cumshewa.
- Flat or declining: Laskeek, Rennell.
- Rebounding but below early: Tasu.
- Intermediate: Skincuttle, Juan Perez.
- Rebounded above early: Englefield, Port Louis, Naden.

Important uncertainty caveat:

- Tasu and Naden have very low survey coverage and very wide recent posterior
  intervals; they belong in the 11-section fit but should not be headline
  evidence.
- Persistent depletion is most defensible where low biomass, repeated years
  below threshold, and reasonable survey coverage agree.

The section-mechanism typology is now the cleanest operational split:

- Cumshewa and Louscoone are persistent depletion beyond fishing;
- Skidegate, Laskeek, and Rennell are depleted or stagnant;
- Tasu and Naden are sparse/uncertain sensitivity sections;
- Englefield and Port Louis are rebounded.

## Driver Interpretation

Current evidence supports these priorities:

1. Historical fishing pressure is associated with worse section outcomes.
   Cross-section Spearman correlations with recent/early biomass are about
   `-0.66` for mean fishing fraction and `-0.62` for observed catch through
   2004. The new fishing decomposition gives adjusted R2 `0.26` for a simple
   mean-fishing-fraction regression, so fishing is important but incomplete.
2. Lagged PDO is the cleanest regional climate signal and is already included
   in `m1_stier_11`. It is not strongly time-trended and has a negative growth
   association, but the Stan coefficient is still uncertain.
3. Predator indices remain ecological hypotheses, not current causal evidence.
   They are extremely time-confounded and highly correlated with each other.
4. Spawn timing and substrate are important observation/context variables, but
   their section-level links to recovery are weak in the current screen.
5. Residual spatial correlations weakly decline with effective distance, so a
   spatial-correlation branch is justified later, after the simpler
   section-productivity branch.
6. Descriptive density-dependence evidence is weak at the archipelago scale
   and only modestly negative at the section scale, so a complex DD branch is
   not the next aggressive analysis priority.

The driver/model triage output converts that into operational guidance:

- lead with observation-scale/survey-method caveats and historical fishing
  pressure;
- interpret lagged PDO as baseline climate context, not as a new branch to add;
- use spatial process covariance as ecological context, not promoted model
  evidence, because exact re-LOO completed but the gain remains small;
- treat observation calibration (`m1_stier_obs_hier`) as a completed clean
  negative result before new biological-driver terms;
- hold predators, substrate/timing, and complex density dependence as context
  rather than promoted model branches.

The focused PDO diagnostic supports that ordering: baseline `pdocoef` is
negative but uncertain, lag-1 PDO versus growth has Spearman rho `-0.49`, and
the detrended relationship remains negative at about `-0.42`.

The predator data feasibility audit makes the predator decision more concrete:

- the combined predator index is strongly time-confounded with year
  (Spearman rho about `0.96`);
- the three mammal indices are highly collinear with each other;
- harbour seal and Steller sea lion raw data are Haida Gwaii-specific but
  sparse in direct observation years;
- the current humpback series is North Pacific basin-wide, not section-level
  Haida Gwaii exposure.

Decision: keep predators as ecological context for Monday. Do not launch a
predator Stan branch until a separate spatial exposure data product exists.

The new survey coverage / zero-ambiguity audit also strengthens the baseline
observation decision:

- `495` positive section-years;
- `19` zero-record section-years;
- `311` missing or unsurveyed section-years;
- `23` years with five or fewer surveyed sections.

Decision: keep zero records ambiguous in the baseline. Some no-survey years can
reflect access/governance context, including Haida preferences, rather than
low biomass.

## Observation-Scale Interpretation

The new spawn-index scale audit confirms that the maintained DFO tonnes series
is not numerically interchangeable with Stier's legacy SHI scale:

- median legacy SHI / DFO tonnes ratio is `111.8`;
- the 10th-90th percentile ratio spans `48.0` to `327.9`;
- section medians range from about `67.9` to `379.9`;
- section-aware calibration improves the log-scale fit over a single global
  conversion.

Decision:

- keep the current `spawn_index_tonnes` analysis as internally consistent;
- do not transfer numerical q values from the legacy SHI model;
- if legacy scale matters for the talk/manuscript, use a separate legacy-SHI
  sensitivity through 2015 rather than a global multiplier.

The observed-data overlap sensitivity through 2015 reduces the concern that the
main story is purely a scale artifact:

- annual total positive-signal log correlation is `0.942`;
- annual occupied-section correlation is `0.993`;
- section recent/early Spearman correlation is `0.952`.

This is not a posterior refit, but it supports keeping the DFO-tonnes analysis
as the practical current baseline while treating legacy-SHI as a sensitivity.

## Completed Model Branches

`m2_stier_site_growth` finished on May 9, 2026.

Purpose:

- keep the `m1_stier_11` observation layer;
- add hierarchical section-specific productivity;
- test whether persistent section winners/losers are supported as process
  heterogeneity before adding predators or density dependence.

Decision:

- hold, do not promote.

Reason:

- sampler health was clean, but PSIS-LOO remained unstable
  (max Pareto k `0.842`, `5` points above `0.7`);
- positive-spawn calibration was effectively unchanged from `m1_stier_11`
  (aggregate log10 RMSE `0.566` versus `0.565`);
- section productivity estimates were strongly pooled and did not explain the
  recovery/depletion scorecard.

`m1_stier_method_sensitivity` also finished on May 9, 2026.

Purpose:

- keep the `m1_stier_11` process and ambiguous-zero likelihood;
- compare the Stier two-era surface/SCUBA q split against a three-era
  surface/mixed/dive-dominant q split;
- isolate survey-method calibration before adding process complexity.

Decision:

- hold, do not promote.

Reason:

- sampler health was clean, but PSIS-LOO remained unstable
  (max Pareto k `0.866`, `7` points above `0.7`);
- positive-spawn calibration did not improve over `m1_stier_11`
  (aggregate log10 RMSE `0.569` versus `0.565`);
- the mixed-transition q was highly uncertain, so the extra split is useful
  as a descriptive sensitivity but not a stronger baseline.

`m3_stier_distance` also finished on May 9, 2026.

Purpose:

- keep the `m1_stier_11` observation layer;
- add one distance-decay process-correlation parameter;
- test whether spatially correlated process shocks are supported before adding
  density dependence, predators, or timing/substrate covariates.

Decision:

- hold for now; exact re-LOO completed, but the fit gain remains too small for
  promotion and one exact refit had treedepth pressure.

Reason:

- sampler health was clean;
- the distance-decay estimate is interpretable, with median practical range
  about `144` km;
- corrected exact-reLOO LOOIC was about `1,949.27`;
- positive-spawn calibration improved only slightly over `m1_stier_11`
  (aggregate log10 RMSE `0.556` versus `0.565`).

The descriptive density-dependence screen also finished on May 9, 2026.

Purpose:

- check whether current `m1_stier_11` posterior medians show a strong
  biomass-dependent growth pattern before spending time on a DD Stan branch.

Decision:

- hold complex density dependence for now.

Reason:

- archipelago growth versus lagged archipelago biomass is not negative
  (Spearman rho `0.213`);
- pooled section growth versus lagged section biomass is only weakly negative
  (Spearman rho `-0.103`);
- strongest negative section screens are modest and do not justify adding
  section-specific density dependence.

Next branch:

- keep `m1_stier_11` as the promoted practical baseline;
- let the `m3_stier_distance` exact re-LOO finish before using its LOO ranking;
- treat `m1_stier_obs_hier` as a completed clean negative result: hierarchical
  section-specific observation error and extra surface-era variance did not
  improve positive-spawn calibration;
- prioritize observation/data-scale cleanup such as legacy SHI-scale
  reconstruction if feasible;
- do not add predators, complex density dependence, explicit movement, or
  age/size structure before a simpler branch materially improves fit or
  interpretation.

## Useful Outputs

Read these first:

- `docs/current-population-driver-findings.md`
- `docs/m2-site-growth-decision-guide.md`
- `Output/diagnostics/m3_stier_distance_postfit.md`
- `Output/diagnostics/m3_stier_distance_pareto_k_points.csv`
- `Output/diagnostics/spawn_index_scale_audit.md`
- `Output/figures/spawn_index_scale_audit.pdf`
- `Output/diagnostics/legacy_shi_overlap_sensitivity.md`
- `Output/figures/legacy_shi_overlap_sensitivity.pdf`
- `Output/diagnostics/density_dependence_screen.md`
- `Output/figures/density_dependence_screen.pdf`
- `Output/diagnostics/driver_model_triage.md`
- `Output/figures/driver_model_triage.pdf`
- `Output/diagnostics/fishing_pressure_decomposition.md`
- `Output/figures/fishing_pressure_decomposition.pdf`
- `Output/diagnostics/pdo_climate_signal_screen.md`
- `Output/figures/pdo_climate_signal_screen.pdf`
- `Output/diagnostics/section_mechanism_typology.md`
- `Output/figures/section_mechanism_typology.pdf`
- `Output/diagnostics/section_change_contribution.md`
- `Output/figures/section_change_contribution.pdf`
- `Output/diagnostics/mhw_recovery_screen.md`
- `Output/figures/mhw_recovery_screen.pdf`
- `Output/diagnostics/may9_headline_findings.md`
- `Output/diagnostics/m1_stier_11_section_scorecard.md`
- `Output/diagnostics/m1_stier_11_uncertainty_audit.md`
- `Output/diagnostics/m1_stier_11_driver_confounding_audit.md`
- `Output/diagnostics/m1_stier_11_postclosure_recovery.md`
- `Output/diagnostics/m1_stier_11_cryptic_collapse_screen.md`
- `Output/diagnostics/m1_stier_11_spatial_shift.md`
