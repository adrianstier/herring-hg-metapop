# Literature-Grounded Model Parameter Roadmap

Generated: 2026-05-10
Execution update: `m1_stier_obs_hier` has now finished. It was sampler-clean,
but is held rather than promoted because positive-spawn calibration worsened
relative to `m1_stier_11`.
May 11 update: a follow-up NotebookLM query and local raw-location screens
reinforce the same ordering. Keep `m1_stier_11` promoted, treat zero/no-survey
records as ambiguous, hold age/size as regional context, and improve local
covariate data products before fitting predator or habitat coefficients.

This note synthesizes the NotebookLM paper query, the local Stier/Okamoto/DFO
PDFs, and the current May 9-10 diagnostics. It is a parameter roadmap, not a
commitment to add every term to Stan.

## Current Baseline

The promoted model, `m1_stier_11`, already includes:

- lagged spring PDO on population growth,
- explicit section-year catch removal through estimated fishing fraction,
- two Stier-style survey-era catchability terms: surface and SCUBA/dive,
- positive spawn observations only, with zero/no-survey cells treated as
  ambiguous.

It does not include predators, age/size, density dependence, explicit movement,
spawn timing/substrate covariates, site-specific observation error, or spatially
correlated process error in the promoted baseline.

## Source Read

Stier et al. 2020 supports:

- surface versus SCUBA catchability,
- ambiguous zeros as missing rather than confirmed absences,
- catch/fishing removal,
- PDO as a regional climate covariate,
- density-independent dynamics as a defensible first approximation,
- predators, habitat, and other unknown mechanisms as process variation when
  section-level exposure data are unavailable.

Okamoto et al. 2020 supports:

- location-specific observation error,
- spatially correlated process error,
- site-specific demographic structure,
- Gompertz-style compensation in a different empirical setting,
- spatial scale mismatch as central to cryptic collapse risk.

DFO assessment/data-summary materials support:

- stock-area age composition and weight-at-age as important regional
  biological context,
- two broad survey eras and explicit q scaling in DFO assessment logic,
- spawn timing and substrate composition as available observation-context
  variables,
- recruitment and natural mortality as important but not section-resolved
  processes.

Schweigert/Ware materials support:

- bottom-up and top-down controls as plausible recovery constraints,
- density- and distance-dependent dispersal as biologically plausible,
- climate regime effects on recruitment/productivity and movement,
- caution that predator and ecosystem indices are difficult to synthesize even
  where data are relatively strong.

## Ranked Candidate Parameters

|rank|candidate|model role|near-term value|feasibility|decision|
|---:|---|---|---|---|---|
|1|hierarchical section-specific observation error `sigma_obs[j]`|observation|high|high|tested in `m1_stier_obs_hier`; held because calibration worsened|
|2|method-specific positive-observation variance or surface-era extra error|observation|high|high|tested in `m1_stier_obs_hier`; useful negative result, not promotion path|
|3|spatial process covariance / effective-distance range `phi`|process|medium-high|already fit|exact re-LOO completed; hold as spatial context because gain is small and one exact refit had treedepth pressure|
|4|PDO lag/window sensitivity: lag 0-1 vs lag 1|climate process|medium|high|diagnostic says no separate branch needed before Monday|
|5|section-specific process variance `sigma_proc[j]`|process heterogeneity|medium|medium|possible after observation branch, if geometry stays clean|
|6|global Gompertz density dependence `b`|process|medium|medium|only after spatial re-LOO; current screen is weak|
|7|spawn timing and substrate terms|observation/context or process sensitivity|medium|medium|treat first as observation/reporting sensitivity, not causal driver|
|8|legacy SHI-scale refit or section-aware scale calibration|data scale|medium-high|medium|valuable sensitivity; avoid global multiplier|
|9|predator exposure/mortality coefficient|mortality/process|high scientific interest|low current feasibility|build spatial exposure product first|
|10|regional age/weight-at-age covariates|recruitment/productivity context|high scientific interest|low-medium|future regional covariate/check, not full section age model|
|11|explicit dispersal/movement matrix|movement process|high scientific interest|low|scenario/simulation later; not a near-term fit|

## Completed Observation Branch

The literature and fit diagnostics correctly pointed to an observation-
calibration branch, implemented as:

`m1_stier_obs_hier`

Files:

- `inst/stan/herring_metapop_m1_stier_obs_hier.stan`
- `Code/03_fit_m1_stier_obs_hier.R`
- `Code/07am_m1_stier_obs_hier_postfit.R`
- `Code/04_wait_for_m3_then_fit_m1_stier_obs_hier.sh`

Keep:

- `m1_stier_11` process,
- ambiguous-zero likelihood,
- 11 fitted sections,
- two-era Stier survey q,
- lagged PDO,
- catch removal.

It added:

- hierarchical section-specific observation error `sigma_obs[j]`,
- method-specific positive-observation scale multiplier, especially allowing
  larger surface-era variance,
- optionally a weakly regularized surface-era bias term only if the variance
  term does not address the residual pattern.

Result:

- sampler-clean;
- positive-spawn RMSE worsened from `0.565` in `m1_stier_11` to about `0.637`;
- max Pareto k increased to about `1.29`;
- therefore, extra section-specific observation error and surface-era variance
  alone are not the fix.

Reason it remains useful:

- Current fit caveat says surface-era positive-spawn RMSE is `1.65`, while
  SCUBA/dive RMSE is `1.02`.
- Okamoto directly supports location-specific observation error.
- The branch shows that the surface-era caveat should be communicated and
  handled as a data-scale limitation before adding more process complexity.

Any future observation branch must clear a stricter gate:

- 0 divergences and no severe treedepth / E-BFMI issues,
- positive-spawn RMSE improves materially, especially surface-era RMSE,
- catch fit remains intact,
- no new unresolved high Pareto-k points after exact re-LOO where needed,
- section status/portfolio conclusions do not flip because of an unidentifiable
  q/sigma tradeoff.

## Spatial Branch Decision

`m3_stier_distance` is already the best process upgrade candidate:

- sampler-clean,
- effective distance range is biologically interpretable,
- positive-spawn RMSE improved slightly from `0.565` to `0.556`,
- exact re-LOO completed, with corrected LOOIC about `1,949.27`, but one exact
  refit had treedepth pressure.

Do not stack new process covariates on top of it. The spatial covariance can be
described as ecological context for shared shocks among nearby sections, but it
is not promoted above `m1_stier_11`.

## Parameters To Hold For Now

Predators:

- Stier explicitly identified predators as desirable but unavailable at section
  scale.
- Current regional predator indices are strongly time-confounded and highly
  collinear.
- A defensible predator branch needs a separate spatial exposure product, at
  minimum for harbour seals and Steller sea lions using haulout/rookery
  locations and interpolation choices.

Age/size:

- DFO and Okamoto-related papers make age truncation and weight-at-age
  scientifically important.
- The section-level model should not become a full 11-section age-structured
  model now.
- Use age composition, age-3 share, mean age, or weight-at-age later as regional
  productivity/recruitment covariates or external checks.

Explicit dispersal:

- Ware/Schweigert support density- and distance-dependent dispersal.
- Stier reported convergence problems with more complicated spatial/movement
  dynamics.
- Current distance covariance is the pragmatic first approximation.

Complex density dependence:

- Okamoto supports compensation in principle.
- Stier justified density-independent dynamics for depleted herring, and the
  current density-dependence screen is weak.
- If tested, use one global Gompertz term before any section-specific density
  dependence.

## Practical Ordering

1. Keep `m1_stier_11` promoted unless a branch improves positive-spawn
   calibration without worsening sampler/PSIS diagnostics.
2. Use `m3_stier_distance` as completed spatial context, not as the promoted
   baseline.
3. Use `m1_stier_obs_hier` as a clean negative result: do not rerun it
   unchanged.
4. Use existing PDO lag/window diagnostics rather than a redundant PDO-only
   branch.
5. Treat timing/substrate as observation/reporting sensitivity until a stronger
   causal design is available.
6. Build predator exposure data before fitting predators.
7. Keep age/size as future regional covariates, not a Monday model.

## May 11 Local Covariate Update

The latest NotebookLM scan prioritized predator exposure, local fishing
history, observation calibration, spatial covariance, spawn timing, and local
habitat/substrate. The local diagnostics now put those ideas in a safer order:

- local spawn-location persistence/loss is now directly measurable for
  Louscoone, Cumshewa, and Laskeek:
  `Output/diagnostics/lead_section_location_transition.md`;
- the geocoded companion map is available at
  `Output/diagnostics/lead_section_location_map.md`;
- post-2005 harbour seal and Steller sea lion proximity can be linked to those
  geocoded spawn locations:
  `Output/diagnostics/lead_spawn_location_predator_proximity.md`;
- Louscoone and Cumshewa recent raw location signal is near 1% of roe-fishery
  raw signal, while Laskeek is about 13%;
- Louscoone has high Steller sea lion proximity/exposure in the post-2005
  screen, but lost-after-roe locations are not clearly more predator-exposed
  than locations that persisted into recent closure.

Decision from this update:

- Do not add a predator coefficient yet.
- Do use the local location and predator-proximity products to design a better
  exposure covariate: species-specific kernels, effort/interpolation choices,
  period-specific exposure, and unresolved humpback spatial allocation.
- Treat habitat/substrate and spawn timing first as local audit covariates
  because survey effort and method can mimic biological changes.
- Keep fishing history as the strongest current descriptive axis, but use the
  location diagnostics to identify places where fishing alone is unlikely to be
  the whole story.

## Source Anchors

- `Literature/Stier_et_al_2020_Ecosphere_Portfolio_Erosion.pdf`
- `Literature/Okamoto et al. (Ecological Applicaitons) 2020.pdf`
- `Literature/Daniel_2014_DFO_BC_Herring_Stock_Assessment_2013.pdf`
- `Data/raw/dfo-spawn/DataSummary.HG.2025.pdf`
- `Literature/Schweigert_et_al_2010_ICESJMS_Factors_Limiting_Recovery.pdf`
- `Literature/Ware_Schweigert_DFO_Metapopulation_Dynamics_Climate.pdf`
- NotebookLM notebook `Herring Haida Gwaii`
