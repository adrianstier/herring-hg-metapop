# Analysis Plan: Herring Metapopulation Dynamics at Haida Gwaii

> Note
> This file mixes early planning notes with implementation details.
> For the current maintained map from theory to cleaned data to Stan inputs, read [`docs/theory-data-model-integration.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/theory-data-model-integration.md).
> For a first-pass walkthrough of the codebase, read [`docs/collaborator-reading-guide.md`](/Users/adrianstier/stier-2027-herring-metapopulation/docs/collaborator-reading-guide.md).

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

## Model Hierarchy: Six Candidate Models (M1--M6)

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
**Status:** Data preparation implemented; threshold-aware Stan variants are now part of the active model comparison.

Modifies the observation model to properly handle surveyed-zero spawn-index values. Positive observations are logged, surveyed-zeros are left-censored observations telling us biomass is below the detection threshold, and unsurveyed cells are skipped.

```
if (Y_status[t,j] == 1)    # observed positive SHI
  Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
else if (Y_status[t,j] == -1)  # surveyed-zero (left-censored)
  target += normal_lcdf(log_threshold | X[t,j] + log_q[q_idx[t]], sigma_obs)
# Y_status == 0: not surveyed, skip
```

**What it reveals:** Whether the current treatment of zeros biases latent biomass estimates upward. Surveyed-zeros carry information (biomass < threshold) that the model currently discards.

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
