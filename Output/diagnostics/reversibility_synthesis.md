# Reversibility / Hysteresis Analysis — Synthesis

Generated: 2026-05-19 21:25:50.53957

## Overview

This document synthesises the Phase 7 reversibility diagnostics for Haida
Gwaii Pacific herring latent biomass (model m1_stier_11, all_11 report set)
relative to the 2005 moratorium (closure) pivot year.

All language is claim-control-safe: consistent with, not supported by, or
indeterminate. No claim of a completed tipping point, proven bifurcation,
or causal attribution to predators is made.

## CRITICAL CAVEAT — composite-reconstruction dependence

The hysteresis vs unreturned-driver distinction (spec §2.4) is gated on
whether the NET control parameter returned. We operationalise the net
driver as the **composite** `effective_driver` built in Script 02: a
z-scored average of three components —

  1. `u` — fishing exploitation rate (m1_stier_11-derived);
  2. predation pressure index (predator-repo, CONTEXT-ONLY provenance);
  3. PDO (Pacific Decadal Oscillation, climate).

Predation and PDO enter as context-only covariates (see
reversibility_effective_driver_provenance.md). **Every conclusion about the
net-driver return therefore depends on this composite reconstruction.** A
different component set or weighting could change the gate. This is the
make-or-break caveat for the headline.

## Net-driver return rule and the actual numbers

Rule: the net control parameter has *returned* iff the recent post-closure
composite median is no higher than the pre-collapse reference composite
median (higher composite z = more net pressure).

- Pre-collapse reference window = roe-fishery era 1972-2004 (last productive, actively-fished pre-collapse era; n=33)
- Recent window = post-closure year >= 2015 (n=10)

- Reference (1972-2004) composite: median = 0.149, mean = 0.146
- Recent (>=2015) composite: median = -0.155, mean = -0.111
- All post-closure (>2005) composite: median = -0.145, mean = -0.103, range = [-1.002, 0.634]

Result: recent composite median (-0.155) is at/below the pre-collapse reference median (0.149) -> effective_driver_returned = TRUE.

Note the post-closure composite is NOT a flat low-pressure plateau: it
ranges [-1.002, 0.634] (includes a 2014-2016 marine-heatwave excursion). The central
tendency, not the excursions, drives the gate; this is reported transparently.

Secondary CONTEXT (NOT the gate): fishing-only exploitation u post-2005 median = 0.0000 (u < 0.05: TRUE). Fishing trivially collapses to ~0
post-moratorium; using u alone would conflate the two explanations the
analysis exists to separate, so it is reported only as context.

## Key Evidence (genuine vs underpowered)

**S-map nonlinearity (biomass_all11):** nl_p = 0.261 at n=75 — not significant. GENUINE measurement; the latent biomass
series is not detectably nonlinear by the S-map theta test at this n.

**Jacobian eigenvalue trend (post-closure):** |lambda_max| trends upward post-closure (slope = 0.0136, n=20). A positive slope is consistent with the
state not yet relaxing toward a low-biomass attractor, and is equally
consistent with a slow, incomplete transient return.

**Potential landscape (post-closure):** NOT ESTIMABLE at n=20 (underpowered). potential_landscape() returned its
degenerate contract — the estimator did not run. This is **indeterminate,
NOT a confirmed absence** of an alternative attractor. Treating it as a
false FALSE would manufacture evidence against hysteresis.

**Driver-state loop geometry (u x biomass_all11):** loop null p-value = 0.0020 — distinguishable from the survey-artifact null (q=[0.6, 1.0]).
The driver-state path does not retrace, consistent with hysteresis-like
geometry. This does NOT prove a fold bifurcation.

**Net (composite) driver returned:** TRUE — see the rule and numbers above. Composite-dependent.

## Discrimination Summary (verdict + observed evidence)

- **hysteresis**: indeterminate — observed: nonlinear=FALSE, lambda_failed_to_relax=TRUE, new_well=NA(not estimable), loop_p=0.0020, eff_driver_returned=TRUE
- **unreturned_driver**: refuted — observed: effective_driver_returned=TRUE (composite recent median=-0.155 vs roe-era median=0.149)
- **long_transient**: indeterminate — observed: lambda_failed_to_relax=TRUE, loop_p=0.0020, new_well=NA(not estimable)
- **artifact**: refuted — observed: artifact_reproduces=FALSE (loop_p=0.0020)

(The discrimination_table `support_criteria` column is the support TEMPLATE,
not findings; the observed values above are the evidence-accurate record.)

## Interpretation Notes

These verdicts follow mechanically from discrimination_table() applied to
the corrected evidence bundle. They are reported as-derived; no steering.

- **hysteresis**: indeterminate. The hysteresis support template requires nonlinear + |lambda| not relaxed + a new potential well + a significant loop; it is refuted
  when the net (composite) driver returned. With new_potential_well
  indeterminate (n~19 not estimable) and the composite net driver at/below
  its pre-collapse reference, this row is governed by the returned-driver
  refutation criterion. Refutation here does not exclude slow transients.

- **unreturned_driver**: refuted. Gated solely on the composite net-pressure return. Composite-dependent (see CRITICAL CAVEAT).

- **long_transient**: indeterminate. Consistent-with where the driver returned but recovery is slow and
  no estimable new well exists; the post-closure landscape being not
  estimable limits how strongly this can be asserted.

- **artifact**: refuted. The loop signal is distinguishable from the survey-artifact null at p=0.0020.

All conclusions are conditional on model m1_stier_11, the latent biomass
time series as the state variable, and the composite effective-driver
reconstruction. Model-estimated biomass uncertainty propagates downstream.

