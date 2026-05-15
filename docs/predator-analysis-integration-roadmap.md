# Predator Analysis Integration Roadmap

Updated: 2026-05-14

This note records what the current predator analyses actually show, what is
weak in the current integration, and how to improve predator data products
before another Stan branch.

## Current Read

The promoted herring baseline remains `m1_stier_11`. Predator results are
context only. The Stier-aligned predator branch,
`m5_stier_predation_pressure`, is sampler-usable and estimates a negative
predator coefficient, but it does not improve positive-spawn or catch
calibration enough to promote.

Key current numbers:

- `m5_stier_predation_pressure` positive-spawn RMSE is about `0.564`, versus
  `0.565` for `m1_stier_11`.
- `m5_stier_predation_pressure` catch RMSE is about `0.010`, effectively the
  same as the baseline.
- The fitted predator coefficient on the current standardized pressure ratio is
  negative: median about `-0.079`, 90% interval about `-0.136` to `-0.020`.
- The branch still remains held because the fit gain is negligible and the
  covariate is not cleanly exogenous.

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

## Spatial Exposure Fix

The first predator spatial exposure prototype had a join mismatch in its
growth-correlation screen. Predator exposure used raw DFO section codes:

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

After the fix, the 50 km kernel screen uses all 11 sections:

|predator|section-years|years|sections|rho exposure-growth|rho exposure-year|
|---|---:|---:|---:|---:|---:|
|Harbour seal|`77`|`7`|`11`|`0.20`|`0.14`|
|Steller sea lion|`143`|`13`|`11`|`-0.05`|`0.59`|

This does not promote a predator effect. It makes the exposure prototype a
better data product and reinforces the current conclusion: section-level
predator exposure is feasible, but still weak and time/effort-confounded.

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

5. Use negative controls before model fitting.
   - Compare lag `-1`, `0`, `1`, and `2`.
   - Include future predator demand as a negative control.
   - Check whether the signal survives removing a linear year trend.
   - Check whether the signal survives within the post-2005 closure period.

## Model Roadmap

Only after the above diagnostics are clean:

1. `m5_stier_predator_demand_total`
   - Same Stier observation layer as `m1_stier_11`.
   - Zeros ambiguous, two-era q, 11 sections.
   - Replace pressure-ratio covariate with lagged total predator demand:
     `z(log1p(C_total_kt))`.

2. Single-group screens, one at a time.
   - `m5_stier_predator_demand_mammals`.
   - `m5_stier_predator_demand_fish`.
   - Do not combine groups until one group passes calibration and geometry
     gates.

3. `m6_stier_predator_exposure`
   - Section-year exposure for one predator group/species only.
   - Start with Steller sea lion or harbour seal because spatial locations
     exist, but include raw/fill flags.
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
- the first Stier-aligned predator branch did not materially improve the
  herring model;
- the next scientific step is a better predator data-product integration, not
  a richer combined Stan model.

Do not claim a promoted predator effect from the current Stan models.
