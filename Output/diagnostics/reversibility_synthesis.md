# Reversibility / Hysteresis Analysis — Synthesis

Generated: 2026-05-19 21:08:07.198595

## Overview

This document synthesises the Phase 7 reversibility diagnostics for Haida Gwaii
Pacific herring latent biomass (model m1_stier_11, all_11 report set) relative
to the 2005 moratorium (closure) pivot year.

All language below is claim-control-safe: consistent with, not supported by,
or indeterminate. No claim of a completed tipping point, proven bifurcation,
or causal attribution to predators is made.

## Key Evidence

**S-map nonlinearity (biomass_all11):** nl_p = 0.261 — not significant at
n=75. The latent biomass time series is not detectably nonlinear by the
S-map theta test at this sample size.

**Jacobian eigenvalue trend (post-closure):** The dominant local Jacobian
eigenvalue (|lambda_max|) trends upward in the post-closure window
(slope > 0), consistent with the state not yet relaxing toward a low-biomass
attractor. This pattern is also consistent with a slow transient return to
the pre-collapse equilibrium that has not yet completed within the available
time window.

**Potential landscape:** Zero potential minima detected in the post-closure
era. This does not support an alternative attractor (new potential well)
distinct from the pre-closure state.

**Driver-state loop geometry (u x biomass_all11):** The loop null p-value is
0.002, distinguishable from the survey-artifact null (q=[0.6, 1.0]). The
driver-state path does not retrace — consistent with hysteresis-like geometry.
This does not prove a fold bifurcation.

**Exploitation driver returned:** Post-2005 median exploitation rate u ~ 0,
consistent with the moratorium effectively removing fishing pressure. The
effective control driver has returned to low levels.

## Discrimination Summary

- **hysteresis**: refuted — nonlinear + |lambda| not relaxed + new well + sig. loop
- **unreturned_driver**: refuted — fishing removed but effective driver did not return
- **long_transient**: weak — restoring but slow; no new well; n.s. loop
- **artifact**: refuted — survey-artifact null reproduces the observed signal

## Interpretation Notes

The hysteresis explanation is refuted here because the effective driver
(exploitation) returned to near-zero post-moratorium, yet biomass has not
recovered. Refutation of hysteresis under the current evidence framework does
not exclude the possibility of slow transients or unresolved drivers.

The long-transient explanation is consistent with the data: the driver returned,
the loop geometry is significant (non-retracing path), but no new potential
well was detected, and the eigenvalue trend does not indicate recovery is
complete. Recovery may be ongoing but slower than the post-closure observation
window.

The unreturned-driver explanation is refuted because exploitation (u) did
return to near-zero after the moratorium. Other drivers (climate, predation)
were included as context-only covariates and are not the authoritative gate.

The artifact explanation is not supported: the loop signal is distinguishable
from the survey-artifact null at p=0.002.

These conclusions are conditional on model m1_stier_11 and the latent biomass
time series as the state variable. Uncertainty in model-estimated biomass
propagates to all downstream diagnostics.

