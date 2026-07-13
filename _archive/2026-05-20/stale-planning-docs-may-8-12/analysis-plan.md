# Analysis Plan: Herring Metapopulation Dynamics at Haida Gwaii

> Note
> This file mixes early planning notes with implementation details.
> For the current maintained map from theory to cleaned data to Stan inputs, read [`docs/theory-data-model-integration.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/theory-data-model-integration.md).
> For a first-pass walkthrough of the codebase, read [`docs/collaborator-reading-guide.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/collaborator-reading-guide.md).
> For the current literature/NotebookLM parameter roadmap, read [`docs/literature-parameter-roadmap.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/literature-parameter-roadmap.md).
> As of 2026-05-11, the promoted practical baseline is still `m1_stier_11`, which treats zero spawn records as ambiguous/missing following Stier et al. (2020). The observation-hierarchy branch `m1_stier_obs_hier` finished and is sampler-clean, but it is held because positive-spawn calibration worsened relative to `m1_stier_11`. The left-censored / detection-aware zero model described below remains a sensitivity analysis, not the default baseline.

## Overview

This project estimates spatiotemporal dynamics of Pacific herring (*Clupea pallasii*) spawning biomass across 11 sections at Haida Gwaii, British Columbia (1951--2025). The analysis tests how portfolio effects, spatial synchrony, and collective memory interact to shape metapopulation resilience under fishing pressure and environmental change.

The central question: **Did age-selective fishing erode the collective memory that maintained spawning site fidelity, contributing to site abandonment and reduced metapopulation stability?**

---

## The Collective Memory Hypothesis

Ono et al. (2025, *Nature*) demonstrated that Norwegian spring-spawning herring (*Clupea harengus*) shifted spawning grounds ~800 km after decades of age-selective fishing destroyed the collective memory held by experienced older cohort members. Key mechanisms:

1. **Social transmission of migration routes.** Naive young fish follow experienced adults to spawning grounds. When older fish are selectively removed by fishing, the knowledge of traditional spawning sites is lost.

2. **Age-truncation as a memory bottleneck.** Intense fishing reduces population age structure, leaving fewer older individuals to guide spawning migrations. Below a critical threshold, the navigational "library" is depleted.

3. **Hysteresis in site recolonization.** Once a site is abandoned, recolonization requires either (a) density-dependent spillover from occupied sites or (b) random exploration by naive spawners. Both are slow and probabilistic, creating persistent site abandonment even after population recovery.

At Haida Gwaii, herring experienced intense reduction fishery (1950s--1960s), a roe fishery (1970s--2002), and closure since 2005. If collective memory operated here, we predict:
- Sites abandoned during peak fishing would show low recolonization probability
- Recolonization probability would decline with population size (fewer scouts)
- The number of occupied sites would show a ratchet effect: declining faster during population crashes than recovering during rebuilding phases

---

## Current Forward Plan After `m1_stier_11`

The active baseline has shifted from the early six-model hierarchy to a
Stier-aligned branch:

- `m1_stier_11` is the promoted baseline.
- zeros are ambiguous/missing,
- survey catchability uses the Stier two-era surface/SCUBA split,
- all 11 sections are fit,
- the 9 focal sections are a reporting sensitivity, not a separate model fit.

The next models should be rebuilt from this observation layer. Do not promote
older `v3`/`v5` process branches without refitting them under the same
zero/method assumptions.

Recommended model sequence:

1. `m1_stier_11`: promoted baseline.
2. `m1_stier_9_report`: reporting sensitivity from the same posterior.
3. `m2_stier_site_growth`: completed May 9 and held; sampler-clean but no
   positive-spawn fit gain and unresolved Pareto-k instability.
4. `m1_stier_method_sensitivity`: completed May 9 and held; sampler-clean, but
   no positive-spawn fit gain and unresolved Pareto-k instability. The three-era
   q estimates are useful for interpretation, not model promotion.
5. `m3_stier_distance`: completed May 9 and held; distance-decay process
   covariance was sampler-clean and biologically interpretable, but did not
   materially improve positive-spawn calibration. Exact re-LOO completed for
   its three high-k PSIS points, but one exact refit had treedepth pressure, so
   the branch remains spatial context rather than promoted inference.
6. `m1_stier_obs_hier`: completed May 11 and held. It kept the `m1_stier_11`
   process, ambiguous-zero likelihood, 11 sections, Stier two-era `q`, lagged
   PDO, and catch removal, then added hierarchical section-specific observation
   error and extra surface-era positive-observation variance. The sampler was
   clean, but positive-spawn calibration worsened (`RMSE 0.64` vs `0.56` for
   `m1_stier_11`) and PSIS was less stable (`max Pareto k 1.29`). Treat this
   as evidence that extra observation variance alone is not the fix.
7. Hold complex density dependence for now. The posterior-median density screen
   found no strong archipelago-wide negative density signal and only weak pooled
   section evidence. If tested later, start with one global Gompertz term only.
8. Do not launch a redundant PDO-only branch: `m1_stier_11` already includes
   lagged PDO. If climate needs more work, test PDO window/lag sensitivity on
   the existing baseline structure.
9. `m5_stier_timing_habitat`: lagged spawn timing and substrate covariates only
   as observation/context branches after simpler calibration checks.
10. `m6_stier_predator_exposure`: predator covariates only after a separate
    spatial exposure data product exists and the simpler process/observation
    branches are stable.
11. Age composition and weight-at-age: future regional productivity/recruitment
    covariates or external checks, not a full 11-section age-structured model.

Every branch should be evaluated with sampler diagnostics, positive-spawn fit,
catch fit, and PSIS/exact re-LOO. Raw LOOIC should only be compared within the
same likelihood unit.

The May 9 population/driver screen is summarized in
[`current-population-driver-findings.md`](current-population-driver-findings.md).
The short version is that recent archipelago biomass is partly rebounding, but
occupied sections remain low and recovery is highly uneven. Historical fishing
pressure is negatively associated with section recovery, but fishing alone
explains only part of section outcomes. Cumshewa and Louscoone are the cleanest
persistent-depletion-beyond-fishing sections, while Tasu and Naden are
sparse-data sensitivities. The existing lagged-PDO term is the most stable
regional climate signal, but its coefficient remains uncertain.
Predator indices remain descriptive context for now because they are strongly
time-confounded with closure-era trends.

For rapid synthesis, use `Output/diagnostics/may9_headline_findings.md`. To
regenerate the current diagnostic suite in dependency order, run
`Code/08_refresh_may9_analysis_suite.sh`.

The May 9-11 `m2_stier_site_growth`, `m1_stier_method_sensitivity`,
`m1_stier_obs_hier`, and `m3_stier_distance` results are useful negative or
partial results. Simple constant section-productivity offsets did not explain
the spatial recovery pattern, splitting the positive-observation q term into
surface/mixed/dive eras did not improve positive-spawn calibration, adding
section-specific observation error plus surface-era extra variance worsened the
aggregate positive-spawn calibration, and distance-decay process covariance
estimated a plausible correlation range without enough calibration gain to
promote it. Keep `m1_stier_11` as the working baseline. Do not jump to
predators, density dependence, or age/size structure as a promoted path before
Monday. The parallel non-Stan priority remains observation/data scale
diagnostics, legacy SHI reconstruction if feasible, section-mechanism typology,
and sharper fishing/PDO interpretation.

As of May 11, the most important fit caveat is no longer zeros. It is
positive-spawn magnitude calibration in the early surface-survey era. The
promoted `m1_stier_11` baseline fits recent SCUBA/dive-era positive spawn much
better than early surface observations; the caveat memo and figure are written
to `Output/diagnostics/positive_spawn_fit_caveat.md` and
`Output/figures/positive_spawn_fit_caveat.pdf`. Treat this as a communication
and data-scale caveat for Monday, not a reason to promote the observation-
hierarchy branch, because that branch worsened positive-spawn RMSE despite clean
sampler diagnostics.

The current biomass estimate also needs a specific uncertainty caveat. The
2025 all-11 median is useful, but the all-11 upper interval is dominated by
Tasu and Naden, which are retained as sparse fit-only sensitivity sections.
Use `Output/diagnostics/current_biomass_uncertainty_decomposition.md` and
`Output/figures/current_biomass_uncertainty_decomposition.pdf`; sparse fit-only
sections account for about 92% of biomass in the top 5% of all-11 posterior
draws.

## Historical Model Hierarchy: Six Candidate Models (M1--M6)

We use a structured model comparison to disentangle process error structure, covariate effects, and the collective memory signal.

### M1: Diagonal and Equal (Baseline)

**Stan file:** `inst/stan/herring_metapop_v1.stan`  
**Status:** Implemented and validated.

The simplest state-space model. All sites share one process error variance (sigma). No spatial correlation in process errors.

```
Z[t,j] = X[t-1,j] + U + pdocoef * pdo[t-1] + delta[t,j]
delta[t,j] ~ Normal(0, sigma)        # iid across sites and years
```

**What it reveals:** Baseline fit. If this model fits well, spatial heterogeneity in dynamics is limited.

### M2: Diagonal and Unequal

**Stan file:** `inst/stan/herring_metapop_v2.stan`  
**Status:** Implemented.

Each site gets its own process error variance (sigma_j) and growth rate (U_j). Still no spatial correlation.

```
Z[t,j] = X[t-1,j] + U[j] + pdocoef * pdo[t-1] + delta[t,j]
delta[t,j] ~ Normal(0, sigma[j])     # site-specific variance
```

**What it reveals:** Whether sites differ fundamentally in environmental variability and growth potential. Large sigma_j differences point to site-specific drivers not captured by PDO alone.

### M3: Multivariate Normal (Full Correlation)

**Stan file:** planned  
**Status:** Not yet implemented.

Process errors follow a multivariate normal distribution with a full covariance matrix.

```
delta[t,] ~ MVN(0, Sigma)
Sigma = diag(sigma) * Omega * diag(sigma)
Omega ~ LKJ(2)                       # correlation matrix prior
```

**What it reveals:** Which sites co-vary in process error (shared unmeasured drivers). The Omega matrix directly estimates spatial correlation in population dynamics. Compare to the empirical synchrony from the portfolio analysis (05_portfolio.R).

### M4: Predator Covariates

**Stan file:** planned  
**Status:** Predator data cleaned (`clean_predators()`), model not yet written.

Extends M2 (or M3) with time-varying predator abundance covariates.

```
Z[t,j] = X[t-1,j] + U[j] + pdocoef * pdo[t-1]
        + beta_ssl * ssl[t] + beta_seal * seal[t] + beta_whale * whale[t]
        + delta[t,j]
```

**What it reveals:** Whether predator recovery (humpback whales, Steller sea lions, harbour seals) suppresses herring biomass after the fishery closure. The "predator pit" hypothesis: herring cannot recover because predators increased to fill the niche vacated by fishers.

### M5: Left-Censored Observation Model

**Stan file:** planned  
**R helper:** `R/09_zero_inflated_obs.R` (`prepare_censored_data()`)  
**Status:** Data preparation implemented; threshold-aware Stan variants are sensitivity analyses, not the promoted baseline.

Modifies the observation model to treat selected surveyed-zero spawn-index values as informative nondetections. Positive observations are logged, surveyed-zeros are left-censored observations telling us biomass is below the detection threshold, and unsurveyed cells are skipped. This interpretation requires survey metadata or a stated sensitivity-analysis framing; it is not the current Stier-aligned default.

```
if (Y_status[t,j] == 1)    # observed positive SHI
  Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
else if (Y_status[t,j] == -1)  # surveyed-zero (left-censored)
  target += normal_lcdf(log_threshold | X[t,j] + log_q[q_idx[t]], sigma_obs)
# Y_status == 0: not surveyed, skip
```

**What it reveals:** How much inference changes if selected zero records are treated as biological evidence of below-threshold biomass rather than ambiguous/missing survey outcomes.

### M6: Site Occupancy Sub-Model (Collective Memory)

**Stan file:** `inst/stan/site_occupancy.stan`  
**R functions:** `R/08_occupancy_model.R`  
**Status:** Implemented.

A standalone Bayesian occupancy model testing the collective memory hypothesis. Operates on binary occupancy data (spawning detected / not detected) rather than continuous SHI.

```
occupied[t,j] ~ Bernoulli(p[t,j])
logit(p[t,j]) = alpha[j] + gamma * occupied[t-1,j]
              + delta_pop * log_N_total[t]
              + delta_age * age_index[t]
```

**Key parameters:**

| Parameter | Interpretation | Collective memory prediction |
|-----------|---------------|------------------------------|
| `gamma` (persistence) | If spawning last year, how much more likely this year? | Positive and large — site fidelity is strong |
| `delta_pop` (population effect) | Larger populations occupy more sites? | Positive — more fish can explore/remember more sites |
| `delta_age` (age effect) | More old fish = more sites remembered? | Positive — this is the direct collective memory test |
| `alpha[j]` (site intercept) | Baseline attractiveness of each site | Varies — some sites are intrinsically better |
| `sigma_alpha` (site heterogeneity) | How much do sites differ? | Large — sites are not interchangeable |

**Survey mask:** Only site-years where `totalrecords > 0` (site was actually surveyed) enter the likelihood. Unsurveyed site-years are treated as missing data, with their occupancy state imputed by the autoregressive structure.

**Generated quantities:**
- `p_recol[t,j]`: Recolonization probability = P(occupied | was unoccupied). This is `inv_logit(alpha[j] + delta_pop * log_N + delta_age * age)` with `gamma * 0` (no persistence contribution).
- `p_persist[t,j]`: Persistence probability = P(occupied | was occupied). Same but with `gamma * 1`.
- The difference `p_persist - p_recol` on the probability scale = the "memory premium" — how much site fidelity exceeds random (re)colonization.

**What it reveals:**
- Whether spawning site occupancy is history-dependent (gamma > 0)
- Whether population size predicts site range (delta_pop > 0)
- Whether age structure predicts site range (delta_age > 0, if data available)
- How recolonization probability has changed over time (declining = memory erosion)
- Which sites were permanently abandoned vs. temporarily vacated

---

## Model Comparison Strategy

| Comparison | Models | Question answered |
|-----------|--------|-------------------|
| Process error heterogeneity | M1 vs M2 | Do sites differ in intrinsic variability? |
| Spatial correlation | M2 vs M3 | Are process errors correlated across sites? |
| Predator regulation | M2 vs M4 | Do recovering predators suppress herring? |
| Zero-handling bias | M1 vs M5 | Does ignoring surveyed-zeros bias estimates? |
| Collective memory | M6 (standalone) | Does site fidelity depend on population history? |
| Full integration | M3+M5+M6 components | Combined best model with occupancy dynamics |

Comparison uses PSIS-LOO-CV (Vehtari et al. 2017) via the `loo` package. M1--M5 are compared on the same observation likelihood (log SHI predictions). M6 operates on a different response variable (binary occupancy) and is compared separately.

---

## Expected Results and Interpretations

### Scenario A: Strong collective memory signal

- **gamma >> 0:** Site fidelity is strong; spawning at a site last year dramatically increases probability this year
- **delta_pop > 0:** Larger populations occupy more sites (scouts explore more)
- **Recolonization probability declining over time:** As population crashed (1960s--1980s), ability to recolonize abandoned sites decreased
- **Ratchet pattern in site count:** Number of occupied sites declined faster during crashes than it recovered during rebuilding
- **Implication:** Conservation requires protecting age structure, not just total biomass. Ono et al.'s finding generalizes to Northeast Pacific herring.

### Scenario B: Density-dependent occupancy without memory

- **gamma ~ 0:** No site fidelity beyond what population size predicts
- **delta_pop >> 0:** Population size is the dominant predictor
- **Recolonization probability tracks population size 1:1**
- **Implication:** Herring are not site-faithful; they go wherever there is suitable habitat. Recovery of biomass automatically means recovery of spatial extent. This would contrast with Ono et al. and suggest that site fidelity mechanisms differ between Atlantic and Pacific herring.

### Scenario C: Habitat-driven occupancy

- **alpha[j] variation >> gamma, delta_pop:** Site identity matters most
- **sigma_alpha large**
- **Implication:** Some sites are simply better spawning habitat, and fish select them based on environmental cues rather than social memory. Occupancy reflects habitat quality, not cultural transmission.

---

## Data Requirements

### Currently available

| Data | Source | Coverage | Status |
|------|--------|----------|--------|
| Spawn index (SHI) by section | DFO | 1951--2025 | Cleaned |
| Spawn survey effort (totalrecords) | DFO legacy | 1940--2015 | Available in raw CSV |
| Commercial catch by section | DFO | 1950--2024 | Cleaned |
| PDO index | NOAA JISAO | 1854--2025 | Cleaned |
| SST (OISST) | NOAA | 2014--2025 | Cleaned |
| Steller sea lion counts | DFO | 1971--2013 | Cleaned |
| Harbour seal counts | DFO | 1966--2019 | Cleaned |
| Humpback whale abundance | Cheeseman 2024 | 2002--2021 | Cleaned |

### Needed but not yet available

| Data | Why needed | Potential source |
|------|-----------|-----------------|
| Age composition by section | Direct test of delta_age (collective memory) | DFO biological sampling |
| Spawn timing (phenology) | Alternative memory metric | Available in raw data (spawn_date_xbar) |
| Substrate/habitat quality by section | Control for habitat-driven occupancy | DFO habitat surveys |
| Acoustic survey biomass | Independent biomass estimate | DFO acoustic surveys |

---

## Pipeline Integration

The occupancy sub-model is integrated into the `targets` pipeline as Stage 7b:

```
spawn_clean (Stage 2)
  └── occupancy_data (prepare_occupancy_data)
        └── fit_occupancy_model (fit_occupancy, deployment = "main")
              └── occupancy_posteriors (extract_occupancy_posteriors)
                    ├── fig_occupancy_heatmap
                    └── fig_recolonization
```

The censored data helper (`prepare_censored_data` in `R/09_zero_inflated_obs.R`) is ready for integration into a future M5 model but is not yet wired into the pipeline.

---

## Key References

- Ono K, Langangen O, Myrvoll-Nilsen E, et al. 2025. Collective memory loss in Atlantic herring after decades of overfishing. *Nature*.
- Stier AC, Samhouri JF, et al. 2020. Fishing, environment, and the erosion of a population complex. *Ecosphere* 11:e03246.
- Schindler DE, Hilborn R, Chasco B, et al. 2010. Population diversity and the portfolio effect in an exploited species. *Nature* 465:609--612.
- Secor DH. 2015. *Migration Ecology of Marine Fishes*. Johns Hopkins University Press. (natal homing and social learning)
- Corten A. 2002. The role of "conservatism" in herring migrations. *Rev Fish Biol Fish* 12:235--249.
- McQuinn IH. 1997. Metapopulations and the Atlantic herring. *Rev Fish Biol Fish* 7:297--329.
- Vehtari A, Gelman A, Gabry J. 2017. Practical Bayesian model evaluation using leave-one-out cross-validation and WAIC. *Stat Comput* 27:1413--1432.
