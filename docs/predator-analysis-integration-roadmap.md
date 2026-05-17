# Predator Analysis Integration Roadmap

Updated: 2026-05-16

This note records what the current predator analyses actually show, what is
weak in the current integration, and how to improve predator data products
before another Stan branch.

Companion note: `docs/wcvi-predation-replication-bridge.md`. It records the
Doherty et al. WCVI predator-paper crosswalk and the HG demand/removal analogue
implemented in `Code/07bj_wcvi_predation_replication_bridge.R`.

## Current Read

The promoted herring baseline remains `m1_stier_11`. Predator results are
context only. The Stier-aligned predator branch,
`m5_stier_predation_pressure`, is sampler-usable and estimates a negative
predator coefficient, but it does not improve positive-spawn or catch
calibration enough to promote. The WCVI-aligned demand branch,
`m5_stier_predator_demand_total`, also completed on AWS and remains held.

Key current numbers:

- `m5_stier_predation_pressure` positive-spawn RMSE is about `0.564`, versus
  `0.565` for `m1_stier_11`.
- `m5_stier_predation_pressure` catch RMSE is about `0.010`, effectively the
  same as the baseline.
- The fitted predator coefficient on the current standardized pressure ratio is
  negative: median about `-0.079`, 90% interval about `-0.136` to `-0.020`.
- The branch still remains held because the fit gain is negligible and the
  covariate is not cleanly exogenous.
- `m5_stier_predator_demand_total` is sampler-clean (`0` divergences, `0`
  treedepth hits, max R-hat about `1.001`, min E-BFMI about `0.816`) and
  estimates a negative demand coefficient: median about `-0.057`, 90% interval
  about `-0.110` to `-0.003`.
- The demand branch is still held because positive-spawn RMSE only moves from
  about `0.565` to `0.560`, catch RMSE stays about `0.010`, and PSIS is not
  clean (`2` Pareto-k points above `0.7`, maximum about `0.906`).

## Main Integration Problem

The current Stan predator branch uses `pred_pressure_log_z`, which is derived
from `log(pressure_pct + 1)`. In the predator repo, `pressure_pct` is:

```text
100 * predator_consumption_kt / HG_spawn_kt
```

That is a good descriptive pressure metric, but it is not the right first
process covariate because the denominator is observed herring spawn. In other
words, the covariate is partly built from the response system. It will tend to
be high when spawn is low, even if predator demand is unchanged.

The fix is conceptual and practical:

- use predator **demand** as the exogenous covariate, for example
  `log1p(C_total_kt)` or group-specific `log1p(C_group_kt)`;
- keep predator **pressure ratio** as a descriptive risk metric and figure
  layer, not as the first state-process predictor;
- only compute pressure ratios inside interpretation or inside a model that
  explicitly treats latent herring biomass as part of predation mortality.

Current simple screens make the distinction clear:

|covariate|rho with next growth|rho with year|rho with log biomass|
|---|---:|---:|---:|
|`log1p(C_total_kt)`|`-0.334`|`0.860`|`-0.481`|
|lagged `log1p(C_total_kt)`|`-0.299`|`0.912`|`-0.421`|
|`log1p(pressure_pct)`|`-0.474`|`0.735`|`-0.650`|
|lagged `log1p(pressure_pct)`|`-0.285`|`0.794`|`-0.585`|
|lag-1 PDO|`-0.488`|`0.027`|`-0.275`|

The pressure ratio is more strongly tied to biomass because it contains spawn
in the denominator. PDO remains the cleaner simple regional covariate because
it is not a monotonic time trend.

The WCVI bridge diagnostic reaches the same conclusion with stronger controls:
lag-1 total predator demand has Spearman rho about `-0.30` with next-year
latent growth, but detrended r is only about `-0.05` and the adjusted beta is
near zero after accounting for PDO, fishing fraction, and year. That supports
preparing a demand branch, but not treating it as strong evidence before a
fit-and-compare gate.

## Spatial Exposure Fix

The predator spatial exposure product is now a formal section-year data product
rather than only a plotted prototype. An earlier version had a join mismatch in
its growth-correlation screen. Predator exposure used raw DFO section codes:

```text
1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25
```

The model biomass table uses model site indices:

```text
1, 2, ..., 11
```

So the prototype's exposure-growth join only matched the first three sections.
`Code/07bb_predator_spatial_exposure_prototype.R` now joins to model biomass by
`section_name`, while preserving raw section codes as metadata.

After the first fix, the 50 km kernel screen used all 11 sections. The May 16
implementation adds source spans, count sensitivities, exposure-weighted
interpolation/extrapolation shares, and 25/50/100 km kernels. Growth screens
exclude section-years where edge-held counts dominate exposure.

|predator|section-years|years|sections|rho exposure-growth|rho exposure-year|
|---|---:|---:|---:|---:|---:|
|Harbour seal|`196`|`26`|`11`|`0.02`|`-0.59`|
|Steller sea lion filled total|`473`|`43`|`11`|`0.04`|`0.57`|
|Steller sea lion raw non-pup|`473`|`43`|`11`|`0.03`|`0.63`|

This does not promote a predator effect. It makes the exposure product a better
input for future screens and reinforces the current conclusion: section-level
predator exposure is feasible, but the current seal/sea-lion signals are weak
or time-confounded, and humpback exposure is still not section-level.

The WCVI bridge now includes the exposure rows in the same lag-1 gate as annual
demand. The best 50 km section-exposure row is harbour seal exposure
(`n = 196`, `11` sections), but it fails because the raw rho is near zero,
the detrended signal is positive rather than negative, and the future-lag
negative control is not beaten. Do not submit `m6_stier_predator_exposure`
from this screen.

## Humpback And Salmon Additions

`Code/07bp_humpback_section_exposure_proxy.R` now turns the sibling predator
repo's HG-wide humpback demand products into a traceable 11-section scaffold:
`Output/diagnostics/humpback_section_exposure_proxy.md`,
`Output/diagnostics/humpback_section_exposure_proxy.csv`, and
`Output/figures/humpback_section_exposure_proxy.pdf`.

The main read is deliberately conservative:

- the source products are HG-wide abundance/consumption, not section-level
  sightings or density;
- the current scaffold distributes demand uniformly across the 11 modeled
  sections;
- recent humpback demand averages about `5.12 kt/yr` and about `307`
  feeding-substantive individuals over 2015-2024;
- the file is `not_model_ready_no_section_exposure` until PRISMM/BCCSN or
  comparable effort-corrected humpback sightings/density are mapped to
  Haida Gwaii sections and season.

`Code/07bq_salmon_recruitment_context_screen.R` now separates salmon from adult
biomass mortality. Salmon demand is the only annual-demand bridge row that gets
a follow-up-only label, but it is a juvenile/recruitment pathway, not a clean
adult SSB removal covariate. The lag-1 adult-growth bridge has `n = 73`,
Spearman rho about `-0.32`, detrended r about `-0.05`, and adjusted beta about
`-0.05`. Public 2015-2024 DFO HG age-2 recruitment checks are SCA-output
context only, not independent juvenile-survey validation (same-year rho about
`0.15`, lag-1 rho about `0.09`, lag-2 rho about `0.28`).
Do not submit a salmon adult-biomass Stan branch without age/recruitment
structure.

`Code/07br_predator_talk_brief.R` writes the compact talk package:
`Output/diagnostics/predator_talk_brief.md`,
`Output/diagnostics/predator_talk_claims.csv`, and the slide-asset list.
Use that note for the one-slide predator message.

## Integrated Mechanism Screen

`Code/07bs_predator_mechanism_integration_screen.R` now implements the
pre-Stan integration screen requested after the predator roadmap discussion. It
tests `m1_stier_11` section-year growth against annual predator demand,
section-year seal/sea-lion exposure, historical fishing pressure, PDO, annual
fishing, section controls, and year controls. It also checks section endpoint
context for historical fishing, recent predator exposure, and timing/substrate
change.

Current output:

- `Output/diagnostics/predator_mechanism_integration_screen.md`
- `Output/diagnostics/predator_mechanism_integration_screen.csv`
- `Output/diagnostics/predator_mechanism_section_endpoint_screen.csv`
- `Output/figures/predator_mechanism_integration_screen.pdf`

Current read:

- No integrated predator row clears the strict lag-1 candidate gate.
- The strongest adjusted exposure row is harbour seal exposure
  (`beta = -0.10`, `p = 0.02`), but it fails because the raw and post-2005
  directions are positive rather than negative.
- The strongest predator x historical-fishing row is combined mammal exposure
  x historical fishing (`beta = -0.02`, `p = 0.16`), but it fails the effect
  size gate.
- Section endpoint context still ranks historical fishing as the clearest
  recovery axis (`beta = -0.91`, rho about `-0.66`). Recent Steller sea lion
  exposure is negative descriptively (`beta = -0.73`, rho about `-0.42`), but
  this is n = 11 endpoint context, not a model-ready effect.

Decision: do not launch a combined predator Stan model or a predator x fishing
Stan branch from the current evidence. The next predator work should improve
the exposure data product, especially humpback section exposure and
effort/interpolation rules, before another AWS fit.

## Post-Closure Recovery Screen

`Code/07bt_postclosure_recovery_mechanism_screen.R` now widens the predator
question to the full "why no complete recovery after no fishing?" hypothesis
set. It uses the promoted `m1_stier_11` state series and separates:

- legacy fishing and recovery residuals;
- raw spawn-location persistence/recolonization in the lead local-audit
  sections;
- post-2005 predator demand, seal/sea-lion exposure, PDO, and marine-heatwave
  timing;
- timing/substrate endpoint context;
- survey coverage and positive-spawn fit caveats.

Current output:

- `Output/diagnostics/postclosure_recovery_mechanism_screen.md`
- `Output/diagnostics/postclosure_recovery_mechanism_screen.csv`
- `Output/diagnostics/postclosure_recovery_section_scorecard.csv`
- `Output/figures/postclosure_recovery_mechanism_screen.pdf`

Current read:

- No post-closure section-year predator/climate row clears the strict candidate
  gate.
- The strongest lag-1 row is combined mammal exposure x historical fishing
  (`beta = -0.26`, `p < 0.01`), but it fails the future-lag negative-control
  gate.
- Fish and total predator demand have the expected negative sign, but the lag-1
  effects are weak and do not justify another Stan branch.
- Endpoint context ranks worse-than-fishing residual depletion and historical
  fishing highest. That is useful diagnosis, not causal identification.
- Section scorecard priorities are now explicit: Skidegate and Louscoone are
  legacy/portfolio cases, Cumshewa is the clearest site-persistence audit case,
  and Laskeek/Rennell remain recovery-contrast context.

Decision: for the talk, say that closure was necessary but not sufficient. The
analysis does not support a single promoted predator coefficient yet; the next
practical work is section-level humpback exposure, effort/access-aware local
persistence, and age/recruitment context.

## Future-Lag And Age-3 Audit

`Code/07bu_future_lag_negative_control_audit.R` now separates immediate adult
mortality tests from delayed recruitment-return tests. This matters because an
adult predation effect should appear quickly, while egg/juvenile or recruitment
effects could plausibly show up when age-3 fish return to spawn.

Current output:

- `Output/diagnostics/future_lag_negative_control_audit.md`
- `Output/diagnostics/future_lag_negative_control_audit.csv`
- `Output/diagnostics/future_lag_negative_control_summary.csv`
- `Output/diagnostics/age3_recruitment_lag_screen.csv`
- `Output/diagnostics/public_age_recruitment_lag_proxy_screen.csv`
- `Output/figures/future_lag_negative_control_audit.pdf`

Current read:

- Adult lag-1 biomass-growth rows: zero follow-up rows.
- Biomass-growth age-3 proxy rows: zero follow-up rows. The strongest is
  combined mammal exposure (`beta = -0.04`, rho about `-0.12`), and it fails
  the weak-effect gate.
- The DFO 2025 age-2 recruitment table is short because it is a recent
  2015-2024 SCA output summary, not the full biological input matrix.
- Longer public age data do exist in CSAS 2018/028 Appendix B Table B.15
  (`1951-2017` number-at-age) and Table B.22 (`1951-2017` weight-at-age), but
  these are provisional PDF extracts and schema checks, not final model inputs.
- Appendix B Table B.8 spawn is raw assessment input and not q-scaled, but it
  is the same adult spawn observation stream used by `m1_stier_11`; any
  spawn-normalized age proxy is shared-input context rather than independent
  recruitment evidence.
- DFO 2025 Table 11 age-2 recruitment is estimated inside the SCA model from
  catch, spawn, age composition, and weight-at-age, so it is model-output
  context only.
- Spawn habitat index / spawn index is spawning output or egg deposition. It
  can be used as brood-year parent-output context or a coarse return proxy, but
  it is not pure recruitment because it mixes survival, age composition, repeat
  spawning, observation scale, and survey method.

Decision: the age-3 lag hypothesis is biologically credible and worth keeping,
but the next step is exact age-composition/recruitment input integration, not a
new predator Stan branch.

## What The Predator Data Say Now

The sibling predator repo gives a much richer predator field than the original
three-mammal regional index. For 2015-2024, the current audited Haida Gwaii
product estimates:

- mean predator consumption: about `15.5 kt/yr`;
- mean HG spawn deposition: about `9.65 kt/yr`;
- mean pressure ratio: about `239%` of spawn deposition;
- median pressure ratio: about `202%`.

Recent consumption is not just mammals:

- fish predators: about `8.66 kt/yr`;
- marine mammals: about `5.44 kt/yr`;
- salmon: about `2.26 kt/yr`;
- birds / egg predators: about `0.28 kt/yr`.

Top recent species in the current HG product include humpback whale, Pacific
cod, Steller sea lion, Pacific hake, sablefish, lingcod, arrowtooth flounder,
spiny dogfish, chum, and coho. This matters because a "predator model" that
only uses harbour seal, Steller sea lion, and humpback abundance is no longer
aligned with the best predator data product.

## Recommended Data Architecture

Keep four predator layers separate:

1. **Annual predator demand**
   - Grain: year.
   - Fields: `C_total_kt`, `C_fish_kt`, `C_mammals_kt`, `C_salmon_kt`,
     `C_birds_kt`, plus species-level columns where defensible.
   - Model role: candidate regional process covariates after residual screens.

2. **Predator pressure ratio**
   - Grain: year.
   - Fields: `pressure_pct`, `C_total_kt`, `HG_spawn_kt`.
   - Model role: descriptive risk metric; do not use as a simple exogenous
     process covariate because it includes herring spawn in the denominator.

3. **Section-year spatial exposure**
   - Grain: year x model section x predator group/species.
   - Fields: exposure kernel value, nearest site distance, raw/fill flags,
     observed-year flags, kernel radius, source predator site count.
   - Model role: future `m6_stier_predator_exposure`, after effort/interpolation
     and biological kernel decisions.
   - Current caveat: seal/sea-lion kernels are working defaults; humpbacks still
     lack section-level exposure.

4. **Spawn-location local audit**
   - Grain: raw spawn location.
   - Fields: transition status, survey/access notes, substrate/method metadata,
     coordinates, nearest predator site, recent exposure.
   - Model role: follow-up targeting and interpretation, not direct Stan input.

## Next Analyses Before Another Predator Stan Branch

Do these before spending AWS time on another predator model:

1. Add predator-demand columns to the herring integration output.
   - Keep `pred_pressure_log_z` for backward compatibility.
   - Add `pred_demand_log_z = z(log1p(C_total_kt))`.
   - Add group-specific demand columns for fish, mammals, salmon, and birds.
   - Add clear metadata that pressure ratios are descriptive.

2. Run residual screens against the promoted baseline.
   - Response should be posterior median growth residual or one-step process
     residual, not raw biomass alone.
   - Predictors should include lagged total demand, group demand, pressure
     ratio, PDO, fishing fraction, and year.
   - Report raw, detrended, and era-restricted correlations.
   - Current status: implemented as
     `Code/07bs_predator_mechanism_integration_screen.R`; no predator
     integration row clears the strict gate.

3. Split observed versus filled predator exposure.
   - Harbour seal: preserve complex-year collapsing; do not sum repeated
     subsite `complex_count`.
   - Steller sea lion: separate raw non-pup counts from interpolated /
     extrapolated count fields.
   - Report how many model years are observed, interpolated, and extrapolated
     for each section.

4. Treat predator groups differently.
   - Mammals: best for spatial exposure and recovery-regime context.
   - Fish predators: largest recent HG consumption group, but spatially coarse.
   - Birds / egg predators: should connect to spawn timing/substrate and egg
     loss, not adult biomass mortality.
   - Salmon: juvenile-herring predation context, not adult SSB removal.
   - Humpbacks: large HG-wide demand, but no section-level exposure yet.

5. Use negative controls before model fitting.
   - Compare lag `-1`, `0`, `1`, and `2`.
   - Include future predator demand as a negative control.
   - Check whether the signal survives removing a linear year trend.
   - Check whether the signal survives within the post-2005 closure period.

## Model Roadmap

Only after the above diagnostics are clean and a single-covariate branch shows
material calibration gain:

1. `m5_stier_predator_demand_total`
   - Same Stier observation layer as `m1_stier_11`.
   - Zeros ambiguous, two-era q, 11 sections.
   - Replace pressure-ratio covariate with lagged total predator demand:
     `z(log1p(C_total_kt))`.
   - Current status: completed on AWS Batch as a deliberate single-covariate
     screen after AWS SSO refresh; local audit/PPC/comparison gates classify it
     as held for no material fit gain. Use it as context, not promoted
     evidence.

2. Single-group screens, one at a time.
   - `m5_stier_predator_demand_mammals`.
   - `m5_stier_predator_demand_fish`.
   - Do not combine groups until one group passes calibration and geometry
     gates.

3. `m6_stier_predator_exposure`
   - Section-year exposure for one predator group/species only.
   - Start with harbour seal or Steller sea lion only if a refreshed
     section-year exposure product passes the lag-1 screen.
   - Include raw/fill flags and exposure-weighted extrapolation shares in the
     Stan data prep and diagnostics.
   - Do not add humpback exposure until there is a Haida Gwaii or section-level
     spatial product; the current basin-wide abundance is not enough.

4. Process-form branch, later.
   - If predator demand is compelling, consider a predation mortality term
     rather than another unconstrained growth covariate.
   - That branch should avoid using observed spawn in the covariate and should
     distinguish predator demand from realized consumption.

## Talk / Manuscript Use Right Now

For the current talk, say:

- predator recovery is ecologically plausible and quantitatively large;
- the best current HG predator product estimates recent consumption around
  `15.5 kt/yr`, larger than recent spawn deposition;
- HG-wide humpback demand alone is about `5.12 kt/yr` recently, but we do not
  yet have a model-ready section exposure surface;
- salmon demand belongs in the juvenile/recruitment story, not adult SSB
  mortality, until age/recruitment structure is added;
- the first Stier-aligned predator branch did not materially improve the
  herring model;
- the WCVI-aligned total-demand branch also did not materially improve
  calibration after a full AWS fit;
- the wider post-closure screen still returns no strict predator/climate
  candidate, so no-fishing should be framed as necessary but not sufficient
  rather than as proof of one missing covariate;
- an age-3 recruitment-return lag is plausible, but current biomass-growth and
  public age-composition proxy screens are audit targets, while shared-spawn
  and SCA-output rows are context only;
- the next scientific step is a better predator data-product integration, not
  a richer combined Stan model.

Do not claim a promoted predator effect from the current Stan models.
