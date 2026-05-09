# Parameter Comparison: Stier et al. 2020 vs Current Analysis

## Legacy JAGS estimates (from Posteriors/Parameter Estimates.csv)

| Parameter | Mean | SD | 2.5% | 97.5% | Rhat |
|-----------|------|-----|------|-------|------|
| Umu (growth rate) | 0.062 | 0.029 | 0.005 | 0.120 | 1.00 |
| pdocoef (PDO) | -0.041 | 0.040 | -0.120 | 0.036 | 1.00 |
| sigma2 (process var) | 0.391 | 0.065 | 0.282 | 0.532 | 1.01 |
| tauR2 (obs precision) | 1.783 | 0.165 | 1.484 | 2.126 | 1.01 |
| log.q[1] (surface) | 2.602 | 0.113 | 2.379 | 2.816 | 1.02 |
| log.q[2] (dive) | 2.930 | 0.163 | 2.611 | 3.247 | 1.01 |

Derived: sigma_proc = sqrt(0.391) = 0.625, sigma_obs = 1/sqrt(1.783) = 0.749

## Current Stan M1 estimates

| Parameter | Mean | SD | 2.5% | 97.5% | Rhat |
|-----------|------|-----|------|-------|------|
| Umu | 0.031 | 0.035 | -0.031 | 0.106 | 1.018 |
| pdocoef | -0.056 | 0.041 | -0.133 | 0.027 | 1.025 |
| sigma_proc | 0.687 | 0.055 | 0.582 | 0.802 | 1.014 |
| sigma_obs | 1.583 | 0.062 | 1.463 | 1.711 | 1.005 |
| log_q[1] (surface) | -1.753 | 0.138 | -2.019 | -1.478 | 1.011 |
| log_q[2] (dive) | -0.731 | 0.204 | -1.130 | -0.336 | 1.012 |

## Key Differences

### 1. sigma_obs: 0.749 vs 1.583 (2.1x inflation)
- Legacy JAGS prior: tauR2 ~ dgamma(2,2) — moderately informative, concentrates sigma_obs near 1.0
- Current Stan prior: half-Student-t(3,0,2.5) — vague, allows huge values
- ROOT CAUSE of the sigma_obs/sigma_proc identifiability problem
- Fix: Use normal(0.5, 0.3) or match the legacy dgamma(2,2) prior

### 2. Umu: 0.062 vs 0.031 (halved)
- Downstream of sigma_obs inflation: higher observation noise → smoother states → lower apparent growth
- Legacy estimate (6%/yr) is more ecologically plausible for herring

### 3. log_q: opposite signs
- Legacy uses SHI (Spawn Habitat Index, spatial volume in eggs·layers·m²) — very large numbers
- Current uses DFO spawn index in tonnes — smaller numbers
- Legacy: Y = X + log.q with log.q > 0 (SHI > biomass in model units)
- Current: Y = X + log_q with log_q < 0 (observed spawn < true biomass)
- The sign flip is EXPECTED and correct for the different measurement scales

### 4. Section framing
- The archived Stier JAGS code drops Cartwright Sound (4) and Masset Inlet (11) from the raw section set, leaving 11 modeled sections.
- The paper then focuses figures and interpretation on 9 data-rich focal subpopulations, effectively de-emphasizing Tasu Sound (1) and Naden Harbour (12) because of sparse or uncertain data.
- Current analysis should preserve this distinction: fit 11 sections where defensible, but report a 9-focal-section sensitivity aligned with the paper.

## From Okamoto et al. 2020

Key methodological features relevant to our analysis:
1. Site-specific Gompertz (α_l, β_l, λ_l) — more flexible than our global b
2. Site-specific observation error — not single sigma_obs
3. ln q ~ Normal(0, 0.05) from Martell et al. 2012 — very informative q prior
4. Spatially correlated process error (MVN with correlation Ω)
5. Stan, 3 chains, 1K iterations

Key finding: "risk of collapse at subpopulation scale can be 10x greater than at metapopulation scale" — directly relevant to our portfolio erosion story.

Important caveat from the DFO 2025 data summary:
the DFO spawn index is explicitly reported as unscaled by q and should be treated as minimum observed spawning biomass, not as a direct estimate of true biomass. So the q prior is still essential, but the source-backed mean checked locally is `ln q ~ Normal(0, 0.05)`, not an arbitrary alternative center.

## Implications for v2 models

1. sigma_obs prior should be informative (~0.5-0.75 based on legacy + Martell et al.)
2. Consider site-specific observation error (Okamoto approach)
3. The q prior from Martell et al. 2012 (`Normal(0, 0.05)` on `ln q`) would further constrain the model, but any different mean needs direct source support
4. Site-specific DD (Okamoto's α, β per site) may be needed — global b is restrictive
5. Zero-spawn treatment should be dataset-specific. Re-reading Stier et al. and the Haida Gwaii survey context supports treating zero spawn records as ambiguous/missing in the promoted `m1_stier_11` baseline, with detection-aware zeros retained as a sensitivity analysis rather than the default.
6. Match the Stier section framing carefully: the original model fit 11 subpopulations after dropping Cartwright and Masset from the raw section set, but figures and interpretation focused on 9 data-rich focal subpopulations.
