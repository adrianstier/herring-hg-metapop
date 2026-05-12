# Current Population And Driver Findings

Generated after the May 9, 2026 analysis sprint. These findings are based on
the promoted `m1_stier_11` baseline unless noted otherwise.

## Baseline Interpretation

`m1_stier_11` is currently the practical baseline because it matches the key
Stier et al. data interpretation:

- ambiguous zero spawn records are skipped rather than treated as confirmed
  absences,
- positive spawn observations use a two-era surface vs SCUBA/dive q structure,
- all 11 sections are fitted,
- Stier-style 9-section reporting is handled as a sensitivity layer, and
- age/size structure, predators, and density dependence are held out of the
  baseline.

The model is sampler-clean and the exact re-LOO correction for the high-k 1970
Naden Harbour point did not materially change LOOIC.

The current compact control sheet is
`Output/diagnostics/may10_integrated_evidence_matrix.md`. It separates:

- trusted baseline and population claims;
- high-confidence observation and fishing-pressure evidence;
- moderate-confidence PDO and spatial-process candidates; and
- contextual or held mechanisms, especially predators, density dependence, and
  age/size structure.

## Model Completion Status

Finished and usable:

- `m1_stier_11`: promoted baseline. Sampler clean (`0` divergences, `0`
  treedepth hits, max R-hat about `1.001`), exact re-LOO resolved the single
  high-k point, and positive-spawn RMSE is about `0.565`.
- `m1_stier_method_sensitivity`: sampler clean and useful as survey-method
  context, but held because it does not improve positive-spawn calibration.
- `m2_stier_site_growth`: sampler clean, but held because site-productivity
  offsets did not improve calibration and were strongly pooled.
- `m3_stier_distance`: sampler clean and biologically interpretable, with
  practical process-correlation range near `144` km and slight positive-spawn
  RMSE improvement (`0.556` versus `0.565`). Exact re-LOO completed for the
  three high Pareto-k points, but the branch remains held because the fit gain
  is small and one exact refit had treedepth pressure.

Finished but not usable for current inference:

- `m5_v3` predator branch: stale relative to the current Stier-aligned model
  path and not sampler-clean (`94` divergences, `9,692` treedepth hits, bad
  R-hat/E-BFMI, max Pareto k about `2.60`). Do not use this as predator
  evidence.
- Older `v3`/`v5` process branches: stale or sampler-pathological. They should
  not be promoted directly.

Interpretation: the spatial model has a real but unresolved candidate result.
The predator model does not yet have a defensible fitted result; predator
recovery remains ecological context until a cleaner exposure product and a
stable Stier-aligned branch exist.

## Survey Coverage And Method Interpretation

From `Output/diagnostics/survey_method_coverage_audit.md`:

- The fitted matrix contains `495` positive section-years, `19` zero-record
  section-years, and `311` missing or unsurveyed section-years.
- The lowest-coverage sections are Naden Harbour (`12 / 75` years surveyed),
  Tasu Sound & Gowgaia Bay (`16 / 75`), Cumshewa Inlet (`31 / 75`),
  Skidegate Inlet (`44 / 75`), and Englefield Bay (`46 / 75`).
- Median coverage is low in the early industrial period (`5` surveyed sections)
  and recent closure period (`5` surveyed sections), so apparent archipelago
  totals from raw observations are often partial-coverage summaries.
- The Stier-style two-era q split remains useful, but the raw DFO `Method`
  labels show that post-1988 survey records are mixed rather than a clean
  dive-only era.

Interpretation: zeros and blanks should remain ambiguous in the baseline. The
main observation-model sensitivity is not "absence vs presence"; it is how much
survey method, era, and uneven section coverage distort positive spawn
magnitudes.

The focused zero-ambiguity diagnostic
(`Output/diagnostics/survey_coverage_zero_ambiguity.md`) makes the same point
more directly:

- There are `514` surveyed site-years, `311` missing/unsurveyed site-years, and
  only `19` zero-record site-years.
- Naden Harbour (`12 / 75` years), Tasu Sound & Gowgaia Bay (`16 / 75`), and
  Cumshewa Inlet (`31 / 75`) are the lowest-coverage fitted sections.
- The weakest median survey coverage occurs during the marine-heatwave period
  (`4` surveyed sections) and the early-industrial period (`5` surveyed
  sections).
- There are `23` years with five or fewer surveyed sections.

Interpretation: the current baseline should continue to treat zero records and
missing cells cautiously. Some no-survey years can reflect governance/access
context, including Haida preferences, rather than low expected biomass.

The spawn-index scale audit adds a second observation caution:

- Across `469` positive overlapping section-years, the median legacy SHI / DFO
  tonnes ratio is `111.8`.
- The ratio is not constant: the 10th-90th percentile range is `48.0` to
  `327.9`, and section medians range from about `67.9` at Skincuttle to `379.9`
  at Tasu.
- A section-intercept log-linear calibration fits better than a single global
  conversion, with adjusted R2 `0.882` versus `0.831`.

Interpretation: `spawn_index_tonnes` is internally consistent, but it is not a
simple continuation of Stier's legacy SHI scale. Numerical q values from the
legacy SHI model should not be copied into the DFO-tonnes model. If a
legacy-scale sensitivity is needed, reconstruct it from legacy SHI through 2015
or use a section-aware calibration.

The legacy-SHI overlap sensitivity then asks whether that scale difference
obviously changes the observed story through 2015:

- annual total positive-signal log correlation between legacy SHI and DFO
  tonnes is `0.942`;
- annual occupied-section correlation is `0.993`;
- section recent/early Spearman correlation is `0.952`.

Interpretation: the two scales are not numerically interchangeable, but the
broad observed annual and section-direction patterns through 2015 are similar.
The current conclusions are therefore not obviously an artifact of using DFO
tonnes, although this does not replace a posterior legacy-SHI refit.

## Fit Quality

From `Output/diagnostics/m1_stier_11_fit_quality_summary.md`:

- Surface-era positive-spawn fit is the weak point:
  RMSE `1.65`, 90% interval coverage `57%`.
- SCUBA/dive positive-spawn fit is better:
  RMSE `1.02`, 90% interval coverage `82%`.
- Worst section fits are Skidegate Inlet, Naden Harbour, Juan Perez Sound, and
  Englefield Bay.
- Catch fit is essentially exact by construction:
  catch log RMSE `0.00022`.

Interpretation: the current model is not failing because catch is poorly fit.
The meaningful remaining calibration problem is positive spawn magnitude,
especially early surface-era observations and a few influential sections.

The focused positive-spawn caveat
(`Output/diagnostics/positive_spawn_fit_caveat.md`) sharpens that limitation:

- Early-industrial positive-spawn RMSE is `2.06`, versus `0.96` in the recent
  closure period.
- Surface-era RMSE is `1.65`, versus `1.02` for SCUBA/dive observations.
- The largest residual clusters are early Skidegate observations with
  observed < fitted, and roe-fishery-era Juan Perez/Naden observations with
  observed > fitted.

Interpretation: the promoted baseline is most reliable for modern status,
period summaries, occupancy/portfolio structure, and section contrasts. Do not
over-read individual early surface-era magnitudes.

## Population State

From `Output/diagnostics/m1_stier_11_population_driver_summary.md`:

- Median all-section biomass in the recent closure period is about `49,489`,
  compared with `63,553` in 1951-1965 and `32,572` during the roe-fishery
  period.
- Median observed occupied sections in 2017-2025 is `5` out of `11`.
- Recent fishing fraction is effectively zero, compared with about `0.106`
  during the roe-fishery period.
- The baseline PDO coefficient is weakly negative:
  mean `-0.053`, 90% interval `-0.126` to `0.020`.

Interpretation: recent archipelago biomass is not simply at a historic low, but
the spatial portfolio is not healthy. Recovery is incomplete and uneven across
sections.

The 11-section and 9-focal summaries differ most in recent uncertainty:

- 2017-2025 median all-11 biomass is about `49,489`, but the median upper 90%
  interval is extremely wide because sparse sections such as Naden can carry
  large posterior uncertainty.
- 2017-2025 median 9-focal biomass is about `31,632`, with a much tighter
  median upper 90% interval near `98,375`.

Interpretation: all-11 fitting is still important, but focal-9 reporting is
more stable for the talk/manuscript unless the sensitivity role of Tasu and
Naden is explicitly shown.

The 2025 current-year snapshot is useful for communication but should be read
with survey coverage:

- 2025 all-11 posterior median biomass is about `29,851`.
- The top 3 sections carry `76%` of 2025 posterior biomass.
- `3 / 11` sections, all focal sections, are below 20% of their early baseline.
- Only `5 / 11` sections were surveyed in 2025; `4` were positive and `1` had a
  zero record.
- Largest 2025 shares: Juan Perez Sound (`38%`), Skincuttle Inlet (`24%`), Port
  Louis (`14%`), Naden Harbour (`7%`, unsurveyed), and Laskeek Bay (`6%`).

Interpretation: the current-year picture is concentrated and coverage-limited.
Use it as a "where things stand now" panel, but base inference on period
summaries.

## Section Winners And Losers

The strongest recent-to-early declines are:

- Skidegate Inlet: recent / early ratio `0.08`
- Louscoone Inlet: `0.13`
- Cumshewa Inlet: `0.14`
- Laskeek Bay: `0.23`

The strongest increases are:

- Naden Harbour: `14.36`
- Port Louis: `3.32`
- Englefield Bay: `2.67`
- Tasu Sound & Gowgaia Bay: `0.99`

Important caveat: Naden and Tasu are retained in the 11-section model but are
excluded from Stier-style 9-focal reporting because they are sparse or
uncertain. Treat them as sensitivity points rather than headline recovery
evidence.

The uncertainty audit supports that caveat:

- Tasu and Naden have extreme recent relative uncertainty because of low survey
  coverage (`21%` and `16%`).
- Recent depletion conclusions are strongest for Cumshewa and Louscoone, where
  low recent/early biomass is not just a sparse-section artifact.
- Skidegate is clearly depleted by posterior median, but recent uncertainty is
  wider than for the better-covered southeast sections.

The cryptic-collapse screen gives the same pattern in threshold language:

- In 2017-2025, the median number of sections below 20% of their 1951-1965
  baseline is `3 / 11` for all sections and `3 / 9` for focal sections.
- Skidegate Inlet and Louscoone Inlet are below 20% in all `9 / 9` recent
  years.
- Cumshewa Inlet is below 20% in `6 / 9` recent years.
- Laskeek Bay is near the threshold and below it in `2 / 9` recent years.

Interpretation: the cleanest population message is not "the whole archipelago
is collapsed." It is that total biomass can look partly recovered while several
historically important sections remain persistently depleted.

The observed occupancy-transition screen adds a cautious site-retention
diagnostic:

- Among `435` adjacent year-section pairs with survey records in both years,
  positive-detection persistence is `99.1%`.
- Zero-record to positive-detection transitions are `54.5%`, but this is based
  on only `11` zero-record starts.
- Closure-era positive-detection persistence is still high at `98.9%`.

Interpretation: the observed data are consistent with strong site retention
where consecutive surveys exist, but zero records are too sparse and too
context-dependent to estimate true recolonization. This supports using
occupancy as descriptive context, not as a promoted true-absence model.

The post-closure recovery screen adds a trajectory view:

- Clear post-closure rebounds: Englefield Bay, Tasu Sound & Gowgaia Bay, Naden
  Harbour, and Port Louis.
- Weak positive trends: Skidegate Inlet, Juan Perez Sound, and Skincuttle Inlet.
- Flat or declining after closure: Louscoone Inlet, Rennell Sound, Laskeek Bay,
  and Cumshewa Inlet.
- Fast positive trend does not imply full recovery: Skidegate is increasing
  post-closure but still remains below 20% of its early baseline in every
  recent year.

Interpretation: closure-era recovery is real in some sections, but the response
is not spatially even. This strengthens the case for section-specific
productivity before regional predator effects.

The integrated section scorecard compresses the section story:

- Persistently depleted: Skidegate Inlet, Louscoone Inlet, and Cumshewa Inlet.
- Flat or declining: Laskeek Bay and Rennell Sound.
- Rebounding but below early: Tasu Sound & Gowgaia Bay.
- Intermediate: Skincuttle Inlet and Juan Perez Sound.
- Rebounded above early: Englefield Bay, Port Louis, and Naden Harbour.

Interpretation: no single axis explains the current section pattern. Historical
catch, survey coverage, post-closure trend, and recent/early biomass all matter,
which is exactly why the section-productivity branch was worth testing.

The section mechanism typology makes the section story more operational:

- persistent depletion beyond fishing: Louscoone Inlet and Cumshewa Inlet;
- depleted or stagnant: Skidegate Inlet, Laskeek Bay, and Rennell Sound;
- sparse/uncertain sensitivity sections: Tasu Sound & Gowgaia Bay and Naden
  Harbour;
- rebounded sections: Englefield Bay and Port Louis.

Interpretation: the clearest sections for mechanistic scrutiny are Cumshewa,
Louscoone, and Laskeek. The clearest sections for sensitivity/coverage caveats
are Tasu and Naden. This is a better structure for analysis than simply ranking
sections by current biomass.

The section narrative synthesis
(`Output/diagnostics/section_narrative_synthesis.md`) combines those diagnostics
into a one-row-per-section triage table:

- mechanism scrutiny: Louscoone Inlet and Cumshewa Inlet;
- portfolio concern: Skidegate Inlet, Laskeek Bay, and Rennell Sound;
- recovery contrast: Englefield Bay and Port Louis;
- sensitivity caveat: Tasu Sound & Gowgaia Bay and Naden Harbour.

Interpretation: this table is the fastest way to keep section narratives
consistent across figures. It is analysis triage, not a final talk outline.

The section driver dossiers
(`Output/diagnostics/section_driver_dossiers.md`) extend that table into a
section-by-section driver read:

- Louscoone and Cumshewa remain the clearest mechanism-scrutiny sections;
- Skidegate, Laskeek, and Rennell are portfolio-concern sections;
- Englefield and Port Louis are recovery contrasts; and
- Tasu and Naden are sensitivity caveats because of sparse survey coverage.

Interpretation: the section-level driver story should not be framed as
"predators versus fishing" yet. The current evidence is more specific:
historical fishing is a strong axis, but local depletion beyond fishing is most
visible in Cumshewa, Louscoone, and Laskeek, while the two sparse western/sparse
sections should be used mainly to show uncertainty.

The section action matrix
(`Output/diagnostics/section_action_matrix.md` and
`Output/figures/section_action_matrix.pdf`) turns that synthesis into the
current section-level work plan:

- lead mechanism cases: Cumshewa and Louscoone;
- portfolio erosion cases: Skidegate, Laskeek, and Rennell;
- current biomass concentration cases: Juan Perez and Skincuttle;
- positive recovery contrasts: Port Louis and Englefield; and
- uncertainty sensitivity only: Tasu and Naden.

Interpretation: this is the safest way to discuss section-specific mechanisms.
It keeps current biomass concentration separate from portfolio recovery and
keeps sparse western/sparse sections out of headline driver inference.

The lead section local audit
(`Output/diagnostics/lead_section_local_audit.md` and
`Output/figures/lead_section_local_audit.pdf`) checks the sections that matter
most for mechanism and portfolio interpretation against the processed annual
survey record and raw HG location records:

- Cumshewa and Louscoone remain priority mechanism cases, but Cumshewa has
  materially weaker survey coverage than Louscoone.
- Laskeek is a well-covered portfolio-erosion case, so its depletion signal is
  harder to dismiss as a sparse-data artifact.
- Skidegate is important but observation-limited because its positive-spawn fit
  caveat is severe in the early surface era.
- Raw HG location records are available for Louscoone, Cumshewa, and Laskeek;
  Skidegate is represented in the processed section series but not in that raw
  HG section extract.

Interpretation: the next high-value mechanistic work is a local survey access,
habitat/substrate, and exposure audit for Cumshewa/Louscoone/Laskeek, not
another regional predator coefficient.

The raw location-transition audit
(`Output/diagnostics/lead_section_location_transition.md` and
`Output/figures/lead_section_location_transition.pdf`) sharpens that local
read:

- Cumshewa has 14 raw locations; only 3 have recent signal, 11 are classified
  as lost after the roe fishery, and recent raw signal is about `1.1%` of
  roe-fishery raw signal.
- Louscoone has 7 raw locations; only 2 have recent signal, 5 are classified
  as lost after the roe fishery, and recent raw signal is about `0.9%` of
  roe-fishery raw signal.
- Laskeek has 24 raw locations; 12 have recent signal and 10 are classified as
  lost after the roe fishery, with recent raw signal about `13.0%` of
  roe-fishery raw signal.

Interpretation: Cumshewa and Louscoone look like strong local persistence/loss
cases, while Laskeek looks more like a reduced and spatially reconfigured
portfolio. This screen is not effort-adjusted, so it identifies audit targets
rather than proving biological absence at unsurveyed locations.

The geocoded companion map
(`Output/diagnostics/lead_section_location_map.md` and
`Output/figures/lead_section_location_map.pdf`) shows the mappable subset of
those raw locations. It should be used to target local habitat/substrate,
survey-access, and predator-exposure follow-up; one Laskeek raw location lacks
usable coordinates, so the map is not identical to the full transition table.

The lead spawn-location predator proximity screen
(`Output/diagnostics/lead_spawn_location_predator_proximity.md` and
`Output/figures/lead_spawn_location_predator_proximity.pdf`) links those
geocoded spawn locations to post-2005 harbour seal and Steller sea lion sites:

- harbour seal sites are near most lead-section spawn locations; median nearest
  distance is about `2.5`-`4.5 km` by section;
- Louscoone has the highest Steller sea lion proximity/exposure among the lead
  sections, with median nearest distance about `10.3 km` and exposure z about
  `2.17`;
- lost-after-roe locations are not clearly more predator-exposed than persisted
  locations in this post-2005 screen.

Interpretation: this is useful for local follow-up and for designing a better
spatial predator covariate, but it still does not establish predator causation
because post-2005 predator sites do not reconstruct historical exposure during
the loss period.

The named local follow-up target table and figure
(`Output/diagnostics/lead_location_followup_targets.md` and
`Output/figures/lead_location_followup_targets.pdf`) combine the transition
screen, raw spawn-method/substrate metadata, coordinates, and predator
proximity. Highest-priority named locations currently include Traynor Creek,
Louscoone Inlet East, Kilmington Point, Skindaskun Island, Atli Inlet,
Cumshewa Inlet, Conglomerate Point, Selwyn Inlet, Cecil Cove, and Beattie
Anchorage. Use this table to focus local survey-access, habitat/substrate, and
exposure review. The `lost after roe fishery` label remains a raw-data screen:
it is not proof of absence without effort/access confirmation.

## M2 Section-Productivity Result

`m2_stier_site_growth` finished on May 9, 2026. It kept the `m1_stier_11`
observation layer and added hierarchical section-specific productivity `U[j]`.

Result:

- sampler health was clean: `0` divergences, `0` treedepth hits, max R-hat
  `1.001`, minimum E-BFMI `0.836`;
- PSIS-LOO was unstable: max Pareto k `0.842`, with `5` points above `0.7`;
- positive-spawn calibration did not improve relative to `m1_stier_11`:
  aggregate log10 RMSE `0.566` versus `0.565`, and bias `0.234` versus
  `0.233`;
- section productivity estimates were strongly pooled, with all median `U[j]`
  values between `0.027` and `0.037` and all 90% intervals overlapping zero.

Interpretation: persistent section winners and losers are not well explained by
a simple constant productivity offset. Do not promote this branch or spend
exact-reLOO time on it without a new reason.

## Method-Sensitivity Result

`m1_stier_method_sensitivity` finished on May 9, 2026. It kept the
`m1_stier_11` process and ambiguous-zero likelihood but split q into surface,
mixed-transition, and dive-dominant eras.

Result:

- sampler health was clean: `0` divergences, `0` treedepth hits, max R-hat
  `1.002`, minimum E-BFMI `0.763`;
- PSIS-LOO was unstable: max Pareto k `0.866`, with `7` points above `0.7`;
- positive-spawn calibration did not improve relative to `m1_stier_11`:
  aggregate log10 RMSE `0.569` versus `0.565`, and bias `0.229` versus
  `0.233`;
- q medians were surface `0.187`, mixed transition `0.623`, and
  dive-dominant `0.278`, with the mixed-transition estimate highly uncertain.

Interpretation: survey-era differences are real and worth reporting, but the
three-era q split is not a better baseline. Use it as descriptive context for
method sensitivity, and keep `m1_stier_11` as the promoted practical model.

## M3 Distance-Covariance Result

`m3_stier_distance` finished on May 9, 2026. It kept the `m1_stier_11`
observation layer and added a one-parameter distance-decay covariance for
annual process shocks.

Result:

- sampler health was clean: `0` divergences, `0` treedepth hits, max R-hat
  `1.001`, minimum E-BFMI `0.803`;
- the distance-decay estimate is biologically interpretable: median practical
  range `144` km, with a 90% interval from about `100` to `222` km;
- exact re-LOO completed for the three high Pareto-k points, yielding corrected
  LOOIC about `1,949.27`, but one exact refit had repeated treedepth hits;
- positive-spawn calibration improved only slightly relative to `m1_stier_11`:
  aggregate log10 RMSE `0.556` versus `0.565`, and bias `0.218` versus `0.233`.

Correct high-k points, using the year-major Stan `log_lik` order, are:

- 1970 Naden Harbour, observed spawn `3.2`, Pareto k `0.813`;
- 2024 Englefield Bay, observed spawn `253.3`, Pareto k `0.728`;
- 1965 Skidegate Inlet, observed spawn `0.3`, Pareto k `0.709`.

Interpretation: there is some evidence for spatially correlated process shocks,
but the branch remains held because exact re-LOO did not produce a clean enough
gain for promotion. The estimated distance range is useful ecological context
for the talk; it is not yet a reason to move beyond the `m1_stier_11` baseline.

## Density-Dependence Screen

The descriptive density-dependence screen uses `m1_stier_11` posterior median
biomass and asks whether next-year latent growth is lower after high biomass.

Result:

- archipelago growth versus lagged archipelago biomass has Spearman rho
  `0.213`, not a negative density signal;
- the archipelago linear slope is `0.083` with p `0.076`;
- pooled section growth versus lagged section biomass is weakly negative:
  Spearman rho `-0.103`;
- strongest negative section screens are Laskeek Bay (`-0.285`), Skincuttle
  Inlet (`-0.210`), Naden Harbour (`-0.176`), Juan Perez Sound (`-0.164`),
  and Skidegate Inlet (`-0.161`).

Interpretation: the current posterior medians do not justify an aggressive
complex density-dependent Stan branch. If density dependence is tested, start
with one global Gompertz term and keep the Stier observation layer unchanged.
Do not add section-specific density dependence, predators, or size/age
structure on top of this baseline until a simpler branch provides a clear gain.

## Fishing Pressure

The section-pressure screen shows that historical fishing pressure matters, but
does not fully explain the spatial pattern.

Cross-section associations with recent / early biomass:

- mean fishing fraction, 1951-2004: Spearman rho `-0.66`
- observed catch through 2004: Spearman rho `-0.62`
- cumulative posterior removed biomass: Spearman rho `-0.62`
- number of catch years: Spearman rho `-0.54`
- early biomass: Spearman rho `-0.50`

Interpretation: more heavily fished sections tended to decline more, but the
relationship is noisy with only 11 sections and is entangled with section size,
historical abundance, and reporting coverage. It motivates section-specific
process structure before adding regional predator effects.

The fishing-pressure decomposition sharpens this:

- recent/early biomass versus mean fishing fraction has Spearman rho `-0.66`;
- recent/early biomass versus observed catch has Spearman rho `-0.62`;
- a simple mean-fishing-fraction regression has adjusted R2 `0.26`;
- adding early biomass does not improve the cross-section regression
  materially, with adjusted R2 `0.25`;
- Juan Perez, Skincuttle, and Skidegate account for about `34%`, `30%`, and
  `15%` of observed 1951-2004 catch;
- Cumshewa, Louscoone, and Laskeek are more depleted than expected from mean
  fishing pressure alone.

Interpretation: historical fishing pressure belongs in the central story, but
it is not a sufficient explanation for the present spatial pattern. The
sections that are worse than fishing alone predicts are where observation
quality, local productivity, habitat/substrate, and governance/access history
need the most scrutiny.

The fishing-closure response diagnostic adds the time-series read:

- median recent biomass is about `49,489`, or `1.52x` the roe-fishery median
  and `0.78x` the early-industrial median;
- median fishing fraction dropped from `10.6%` during the roe fishery to `0%`
  in the recent closure period;
- median occupied sections declined from `8` during the roe fishery to `5`
  recently; and
- recent biomass remains concentrated, with top-three share `84%` and Simpson
  effective sections `3.26`.

Interpretation: closure removed direct fishing mortality, so persistent
depletion is not explained by ongoing catch. The important next question is why
some sections did not recover after closure, not whether fishing is still
directly suppressing biomass.

## Portfolio Structure

Posterior-state portfolio metrics from the 11-vs-9 reporting sensitivity show:

- Early 1951-1960 synchrony was about `0.29`.
- Recent 2016-2025 synchrony is about `0.49` for all 11 and `0.51` for the
  9-focal set.
- The mid-record windows have lower median synchrony near `0.20`, while
  post-2005 windows are higher near `0.61`.
- Recent portfolio CV ratios are around `1.8`, but this is partly because the
  archipelago total has low variation while some sections remain persistently
  low.

Interpretation: the portfolio has not simply recovered with biomass. Spatial
structure remains concentrated and synchronized enough that section-level
heterogeneity is a central part of the ecological story.

The annual concentration diagnostic sharpens that point:

- In 2017-2025, the top 3 sections carry about `84%` of all-11 posterior
  biomass and `85%` of focal-9 posterior biomass.
- Simpson effective section count is only about `3.26` for all 11 and `3.31`
  for the 9-focal set.
- The regenerated `m1_stier_11` portfolio figure gives recent 10-year-window
  synchrony of `0.63` for all 11 and `0.70` for the 9-focal set.
- The largest recent section shares are Juan Perez Sound (`33%`), Skincuttle
  Inlet (`31%`), and Port Louis (`17%`).
- The biomass-weighted centroid shifts from roughly `52.596, -131.536` in the
  early industrial period to `52.743, -131.738` in the recent closure period.

Interpretation: the recent population is effectively a 3-section biomass
portfolio, not an evenly recovered 11-section metapopulation. The concentration
also has a geographic component, but this is currently a context screen rather
than a mechanistic spatial model.

The section contribution analysis shows why the recovery message is
metric-sensitive:

- using additive period means of annual section posterior medians, recent minus
  early change is about `-32,886`;
- recent minus roe-fishery change is about `-5,804` on the same additive
  section-mean scale;
- largest recent-minus-early gains are Port Louis, Naden, and Englefield;
- largest recent-minus-early losses are Skincuttle, Juan Perez, and Skidegate;
- largest recent-minus-roe gains are Juan Perez, Port Louis, and Naden, while
  Cumshewa, Louscoone, and Skincuttle remain major losses.

Interpretation: the statement "recent biomass is higher than the roe-fishery
period" is true for the period-summary median archipelago total, but it is not
a broad section-level recovery. Gains are concentrated and metric-sensitive.

The marine-heatwave screen adds temporal context:

- total biomass median is about `30,757` during 2005-2013 closure, `46,798`
  during 2014-2016, and `49,489` during 2017-2025;
- occupied sections are `7.0` pre-MHW, `4.0` during the MHW window, and `5.0`
  in the recent closure period;
- largest recent-minus-pre-MHW gains are Juan Perez, Port Louis, and Naden;
- largest recent-minus-pre-MHW losses are Laskeek, Rennell, and Cumshewa.

Interpretation: the 2014-2016 heatwave is a useful period marker, but it does
not explain the section typology by itself. The post-MHW pattern is still a
spatially uneven recovery story.

## Residual Spatial Structure

From `Output/diagnostics/m1_stier_11_residual_spatial_correlation.md`:

- Positive-spawn residuals have modest positive section-pair correlation:
  median `0.20` across all positive observations.
- Residual correlations weakly decline with effective distance:
  Spearman rho `-0.28` across all positive observations.
- The pattern is similar but weaker for SCUBA/dive positives:
  median pair correlation `0.12`, distance rho `-0.22`.
- Several nearby east/southeast pairs retain positive residual correlations,
  including Juan Perez / Laskeek and Laskeek / Skincuttle.

Interpretation: there is enough residual spatial structure to justify a
distance-correlated process branch, and `m3_stier_distance` has now tested that
idea directly. The distance estimate is useful context, but the branch remains
held because its calibration gain is small. Exact re-LOO has completed for the
three high-k points, with corrected LOOIC about `1,949.27`, but one exact refit
had repeated treedepth hits, so this is spatial context rather than promoted
model evidence.

## Spawn Timing And Substrate Context

From `Output/diagnostics/spawn_timing_substrate_screen.md`:

- Median regional spawn start is fairly stable across broad periods, around
  day-of-year `88-92` except for the late-reduction period (`104`).
- The substrate record changes strongly: median subtidal share is `0%` in
  1951-1971, `52%` during the roe fishery, `76%` during 2005-2013 closure,
  and `73%` in 2017-2025.
- Median substrate effective number rises from `1.00` early to `1.69-2.27`
  in closure-era periods.
- Section-level correlations between recent/early biomass change and substrate
  changes are weak:
  delta spawn timing rho `0.31`, delta subtidal share rho `-0.21`, delta
  substrate effective n rho `-0.21`.

Interpretation: timing and substrate are real changes in the DFO observation
record. They matter for how spawn index is measured and interpreted, but they
are not yet strong standalone population-driver evidence.

## Driver Screening

The simple lag-1 screen found negative associations between next-year latent
growth and:

- PDO: Spearman rho `-0.49`
- Steller sea lion index: `-0.32`
- subtidal spawn share: `-0.31`
- humpback whale index: `-0.30`
- combined predator index: `-0.29`
- harbour seal index: `-0.27`

The trend-robust screen changes the interpretation:

- PDO remains the most stable climate signal, especially lag 0-1, and it is
  already included in the promoted baseline.
- Predator signals are plausible but strongly time-confounded.
- Substrate and method-era covariates are important for observation/reporting
  interpretation and should not be automatically read as population-process
  drivers.
- Chlorophyll and SST screens have short time series and should be treated as
  low-confidence.

The driver-confounding audit clarifies why predator effects should not be the
next model branch:

- Steller sea lion, humpback whale, and combined predator indices are almost
  monotonic time trends: Spearman rho with year is `0.99`, `0.98`, and `0.96`.
- Predator indices are highly correlated with each other:
  combined predators / humpback rho `0.97`, Steller sea lion / humpback rho
  `0.96`, and combined predators / Steller sea lion rho `0.95`.
- Observed catch and fishing fraction are nearly redundant (rho `0.98`) and
  strongly structured by closure-era management.
- PDO is the least time-confounded major climate signal: rho with year is about
  `0.00`, while rho with growth is `-0.46`.

Interpretation: predator hypotheses remain ecologically plausible, but the
current regional predator indices are too time-confounded to interpret before
the section-productivity and spatial-structure branches are evaluated. The
existing lagged-PDO term is the cleanest regional climate signal to report and
stress-test.

The predator data feasibility audit
(`Output/diagnostics/predator_data_feasibility_audit.md`) adds the data
provenance reason for that decision:

- Harbour seal raw data are Haida Gwaii haulout records from `1986-2017`, but
  only `7` directly observed source years feed the current processed index.
- Steller sea lion raw data are Haida Gwaii haulout / rookery records from
  `1971-2013`, with `13` observed years.
- Humpback whale abundance is a `2002-2021` North Pacific basin-wide series,
  not a Haida Gwaii-specific exposure series.
- The combined predator index has Spearman rho `0.96` with year and only
  `-0.29` with next-year growth.

Interpretation: predator recovery belongs in the ecological context, but a
section-level predator model needs a separate exposure data product before it
is defensible.

The predator spatial exposure prototype
(`Output/diagnostics/predator_spatial_exposure_prototype.md`) is the first step
toward that data product:

- Harbour seal exposure can be derived from `1986-2017` Haida Gwaii haulout
  locations/counts: 7 observed years, 247 named predator sites, and 582
  site-years after collapsing repeated complex counts.
- Steller sea lion exposure can be derived from `1971-2013` Haida Gwaii
  haulout/rookery locations/counts: 13 observed years, 16 sites, and 208
  site-years.
- The 50 km prototype remains confounded: harbour seal exposure has rho `0.10`
  with next-year section growth and rho `0.25` with year, while Steller sea
  lion exposure has rho `-0.02` with next-year growth and rho `0.70` with year.
- Highest recent prototype exposures are biologically plausible enough to
  prioritize local review: harbour seal exposure is highest near Naden, Laskeek,
  and Cumshewa; Steller sea lion exposure is highest near Louscoone,
  Skincuttle, and Juan Perez.

Interpretation: the prototype supports building a better section-level predator
exposure covariate, not promoting a predator effect. Before any predator Stan
branch, refine effort correction, interpolation rules, species-specific
distance kernels, and the unresolved humpback section-exposure problem.

The combined section recovery covariate screen
(`Output/diagnostics/section_recovery_covariate_screen.md`) keeps those driver
claims disciplined across all 11 sections:

- Mean historical fishing fraction has the strongest section-level association
  with log recent/early biomass, Spearman rho `-0.66`.
- Catch per early biomass is also negative, rho `-0.40`.
- Prototype predator exposure is weaker and not directionally decisive:
  harbour seal exposure rho `0.36`, Steller sea lion exposure rho `-0.26`.
- Timing/substrate shifts are only available for 6 sections in the current
  early-versus-recent comparison, so they are not ready for a promoted
  section-level covariate.

Interpretation: use this as a triage result. The present data support a strong
descriptive fishing-history axis plus section-specific local audits, while
predator, timing, and substrate work should first improve covariate data
products.

The focused PDO screen gives the cleanest climate statement:

- the baseline Stan PDO coefficient has mean `-0.053` and 90% interval
  `-0.126` to `0.020`;
- lag-1 PDO versus next-year posterior median growth has Spearman rho `-0.49`;
- the detrended lag-1 relationship remains negative, r `-0.42`;
- the cheap window-sensitivity screen finds the strongest nearby window is PDO
  mean lag 0-1, with Spearman rho `-0.52`, detrended r `-0.45`, and adjusted
  beta `-0.08`;
- the original lag-1 PDO term remains competitive, with adjusted beta `-0.09`;
- PDO has near-zero monotonic association with year, unlike predator indices.

Interpretation: PDO is worth carrying forward as climate context, but it is
already in `m1_stier_11`. The window screen supports the qualitative signal but
does not justify a redundant PDO-only branch before Monday. It is not yet a
promoted causal result because the baseline coefficient interval overlaps zero.

The driver/model triage table turns these screens into a working priority
order:

- report now: observation-scale caveats and historical fishing pressure;
- baseline climate context: lagged PDO, because it is associated with growth
  without being a monotonic time trend, but its Stan coefficient remains
  uncertain;
- context only after exact re-LOO: spatially correlated process shocks;
- completed negative branch: observation calibration (`m1_stier_obs_hier`),
  because it was sampler-clean but worsened positive-spawn calibration;
- context only for now: predators, substrate/timing, age/size, and complex
  density dependence.

Interpretation: the Saturday analysis should focus on sharpening the baseline
story and section-level mechanism read. If another Stan branch is run, it
should start from the promoted observation layer and have a clear calibration
target before adding biological-driver terms. Predator, substrate, age/size,
and density dependence belong in the talk as plausible mechanisms or caveats,
not as promoted causal model results.

## Current Model Direction

The current model decision is to keep `m1_stier_11` as the promoted practical
baseline. Four obvious May 9 extensions/screens have now been tested:

- `m2_stier_site_growth`: section-specific productivity did not improve fit.
- `m1_stier_method_sensitivity`: three-era q did not improve fit.
- `m3_stier_distance`: spatial process covariance is interpretable; exact
  re-LOO completed, but the positive-spawn fit gain is small and one exact
  refit showed treedepth pressure, so it remains held.
- `density_dependence_screen`: descriptive evidence for global density
  dependence is weak, so do not rush to a complex DD branch.

The next useful work is therefore not a predator or age/size branch. It should
be one of:

- using `m1_stier_obs_hier` as a completed clean negative result, not a
  promotion candidate;
- observation/data-scale cleanup, especially checking whether a legacy SHI-scale
  reconstruction changes q and positive-spawn calibration;
- deciding how to report the `m3_stier_distance` range as ecological context
  without promoting the branch;
- stronger reporting diagnostics around spatial concentration, survey coverage,
  and section-specific recovery.

## Outputs To Use

- `Output/diagnostics/may9_headline_findings.md`
- `Output/diagnostics/may9_headline_findings.csv`
- `Output/figures/m1_stier_11_population_driver_dashboard.pdf`
- `Output/figures/m1_stier_11_section_period_heatmap.pdf`
- `Output/figures/m1_stier_11_driver_robustness.pdf`
- `Output/figures/m1_stier_11_section_pressure_screen.pdf`
- `Output/figures/m1_stier_11_fit_quality_summary.pdf`
- `Output/figures/m1_stier_11_spatial_concentration.pdf`
- `Output/figures/m1_stier_11_residual_spatial_correlation.pdf`
- `Output/figures/m1_stier_11_cryptic_collapse_screen.pdf`
- `Output/figures/spawn_timing_substrate_screen.pdf`
- `Output/figures/density_dependence_screen.pdf`
- `Output/figures/driver_model_triage.pdf`
- `Output/figures/fishing_pressure_decomposition.pdf`
- `Output/figures/fishing_closure_response.pdf`
- `Output/figures/pdo_climate_signal_screen.pdf`
- `Output/figures/pdo_window_sensitivity.pdf`
- `Output/figures/section_mechanism_typology.pdf`
- `Output/figures/section_change_contribution.pdf`
- `Output/figures/mhw_recovery_screen.pdf`
- `Output/figures/section_action_matrix.pdf`
- `Output/figures/lead_section_local_audit.pdf`
- `Output/figures/m1_stier_11_driver_confounding_audit.pdf`
- `Output/figures/m1_stier_11_postclosure_recovery.pdf`
- `Output/figures/m1_stier_11_section_scorecard.pdf`
- `Output/figures/m1_stier_11_spatial_shift.pdf`
- `Output/figures/m1_stier_11_current_year_status.pdf`
- `Output/figures/m1_stier_11_uncertainty_audit.pdf`
- `Output/figures/survey_method_coverage_audit.pdf`
- `Output/diagnostics/m1_stier_11_population_driver_summary.md`
- `Output/diagnostics/m1_stier_11_driver_robustness.md`
- `Output/diagnostics/m1_stier_11_section_pressure_screen.md`
- `Output/diagnostics/m1_stier_11_fit_quality_summary.md`
- `Output/diagnostics/m1_stier_11_spatial_concentration.md`
- `Output/diagnostics/m1_stier_11_residual_spatial_correlation.md`
- `Output/diagnostics/m1_stier_11_cryptic_collapse_screen.md`
- `Output/diagnostics/spawn_timing_substrate_screen.md`
- `Output/diagnostics/density_dependence_screen.md`
- `Output/diagnostics/driver_model_triage.md`
- `Output/diagnostics/fishing_pressure_decomposition.md`
- `Output/diagnostics/fishing_closure_response.md`
- `Output/diagnostics/pdo_climate_signal_screen.md`
- `Output/diagnostics/pdo_window_sensitivity.md`
- `Output/diagnostics/section_mechanism_typology.md`
- `Output/diagnostics/section_change_contribution.md`
- `Output/diagnostics/mhw_recovery_screen.md`
- `Output/diagnostics/section_action_matrix.md`
- `Output/diagnostics/lead_section_local_audit.md`
- `Output/diagnostics/m1_stier_11_driver_confounding_audit.md`
- `Output/diagnostics/m1_stier_11_postclosure_recovery.md`
- `Output/diagnostics/m1_stier_11_section_scorecard.md`
- `Output/diagnostics/m1_stier_11_spatial_shift.md`
- `Output/diagnostics/m1_stier_11_current_year_status.md`
- `Output/diagnostics/m1_stier_11_uncertainty_audit.md`
- `Output/diagnostics/survey_method_coverage_audit.md`
