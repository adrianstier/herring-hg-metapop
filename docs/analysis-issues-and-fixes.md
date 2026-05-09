# Analysis Issues and Fixes — Prioritized Action Plan

Compiled from 5 diagnostic agents (MCMC diagnostics, data audit, model critique, state estimate plots, prior sensitivity). Issues are ranked by priority.

> Note
> This is a historical diagnostic memo that references legacy `Code/` scripts and experimental Stan variants.
> It is useful for scientific context and unresolved ideas, but it is not the current source of truth for the maintained `R/` + `_targets.R` workflow.

## CRITICAL (must fix before any results are trustworthy)

### C1. LOOIC computation is broken across models
- **Source:** Model critique agent
- **Problem:** M2 never filters out log_lik = 0.0 for missing observations; M5 passes log-likelihood instead of likelihood to `relative_eff()`. Model comparisons are invalid.
- **Fix:** Standardize log_lik filtering in all R fitting scripts. Better: fix Stan generated quantities to only output log_lik for observed data points using N_obs computed in transformed data block.
- **Files:** All `03_fit_m*.R` scripts + all `.stan` files (generated quantities block)

### C2. M1 has not converged
- **Source:** MCMC diagnostics agent
- **Problem:** 5 parameters with Rhat > 1.10, 23 > 1.05. Umu has only 135 effective samples. 100% max_treedepth saturation at treedepth=12.
- **Fix:** Re-run M1 with max_treedepth=15 and 2500+ post-warmup samples (matching M3's budget).
- **Files:** `Code/03_fit_m1.R`

### C3. M5 uses pre-fishing Z instead of post-fishing X
- **Source:** Model critique agent
- **Problem:** M5's state equation uses Z[t-1,j] (pre-fishing) as the DD input. Harvested fish can't contribute to next year's recruitment. M1-M3 correctly use X[t-1,j].
- **Fix:** Change M5 Stan code to use X[t-1,j]. Also unify Gompertz parameterization with M3.
- **Files:** `inst/stan/herring_metapop_m5_predators.stan`, `inst/stan/herring_metapop_m5_combined.stan`

### C4. Informative zeros discarded
- **Source:** Data audit + model critique agents
- **Status update, 2026-05-06:** The data contract can carry 19 zero records separately as `Y_censored` / `Y_censored_flag`, but these should not automatically be promoted as informative nondetections.
- **Status update, 2026-05-08:** `m1_stier_11` is now the promoted Stier-aligned baseline. It treats zero spawn records as ambiguous/missing, fits the 11-section model, and keeps detection-aware zeros as sensitivity analyses.
- **Stier alignment:** Stier et al. (2020) treated reported zero spawn as ambiguous and classified those records as missing. The archived model code does the same with `w[w==0] <- NA`.
- **Haida Gwaii survey context:** Some site-years may be unsurveyed for governance/access reasons, including Haida preferences, rather than because biomass is low. That makes "no survey" and many zero records part of the observation/governance process, not direct biological evidence of absence.
- **Current modeling decision:** The promoted baseline treats zero spawn records as ambiguous/missing unless explicit survey metadata justify true nondetection. Detection-aware / left-censored zero models should be retained as sensitivity analyses, not the default.
- **Files:** `Code/02_data_merge.R`, `R/02_prepare_model_data.R`, detection-aware `.stan` files.

## MAJOR (should fix for publication quality)

### M1. sigma_obs is implausibly large (1.58)
- **Source:** Model critique agent
- **Problem:** Implies observed spawn can be 23x above/below true value. Typical survey CV is ~30% (sigma_obs ~0.3 on log scale). sigma_obs and sigma_proc are likely not identifiable.
- **Fix:** Use informative prior on sigma_obs based on survey methodology (~Normal(0.3, 0.15)). Or fix sigma_obs and estimate sigma_proc freely.
- **Impact:** Would fundamentally change the signal-to-noise partition.

### M2. Residuals are non-normal (kurtosis ~7.5)
- **Source:** MCMC diagnostics agent
- **Problem:** Heavy left tails. Normal observation model generates too many extreme lows.
- **Fix:** Use Student-t observation likelihood with estimated degrees of freedom (nu ~ gamma(2, 0.1)).
- **Files:** All `.stan` files (observation model)

### M3. Temporal trend in residuals (r = +0.35)
- **Source:** MCMC diagnostics agent
- **Problem:** Systematic under-prediction in 1950s-60s, over-prediction in 1970s-80s. Missing time-varying process.
- **Fix options:** (a) Time-varying growth rate; (b) regime shift indicator; (c) fishery closure structural break covariate.

### M4. Inconsistent Gompertz parameterization (M3 vs M5)
- **Source:** Model critique agent
- **Problem:** M3 uses `(1+b)*X`, M5 uses explicit K_log. U_mu is +1.97 in M3 but -0.43 in M5.
- **Fix:** Use identical `(1+b)*X` parameterization in M5 (drop K_log).

### M5. q_idx transition needs mixed-era handling
- **Source:** Data audit agent
- **Problem:** In 1988, only 11% of records used dive methods. Transition was gradual.
- **Resolved baseline:** The maintained model inputs now use three method eras: surface, mixed transition, and dive.
- **Stier-aligned sensitivity:** The original paper and archived JAGS code used two eras: surface through 1987 and SCUBA from 1988 onward. Compare this two-era split against the maintained three-era split rather than assuming one is universally correct.
- **Remaining option:** Use section-year specific method covariates if both era approximations are still too coarse.

### M6. Post-closure SOK catch treated as roe harvest
- **Source:** Data audit agent
- **Problem:** 1,274 tonnes of SOK in Port Louis (2007-2013). SOK removes eggs, not adults. The Pc parameter assumes adult biomass removal.
- **Fix:** Either remove SOK from the catch matrix (it doesn't remove spawning adults) or model SOK as egg removal with different population-level impact.

### M7. Portfolio analysis uses noisy raw data
- **Source:** Model critique agent
- **Problem:** With sigma_obs = 1.6, synchrony/PE calculations are dominated by observation noise.
- **Fix:** Compute portfolio metrics on posterior mean X[t,j] (estimated true states) rather than raw Y[t,j].

### M8. Naden Harbour outlier
- **Source:** MCMC diagnostics + plotting agents
- **Problem:** Mean residual +1.2 to +1.4 across all models. 22-year data gap (1983-2005). Dominates high Pareto-k values.
- **Fix:** Investigate data quality. Consider site-specific intercept or exclusion sensitivity test.

### M9. Inconsistent phi priors between M2 and M3/M5
- **Source:** Model critique agent
- **Problem:** M2 uses half-normal scaled to study area. M3/M5 use inv_gamma(5,5) implying ~1 km range.
- **Fix:** Use consistent priors. The M2 approach (scaled to max_dist) is more principled.

## MINOR (nice to have)

### m1. Legacy "SHI" column name ambiguity
- Resolved in the maintained processed CSV: the DFO tonnes column is now `spawn_index_tonnes`.

### m2. PDO window may be wrong
- Spring PDO (Mar-Jun) consistently near zero. Try winter PDO (Nov-Mar) or SST directly.

### m3. No structural break test for 2005 fishery closure
- Add binary covariate or allow growth rate to differ pre/post closure.

### m4. LOO fundamentally unreliable for state-space models
- Supplement with leave-future-out CV, temporal k-fold, or Bayes factors.

### m5. Consider Ricker DD alternative
- Gompertz and Ricker often give similar fits. Worth testing but not critical.
