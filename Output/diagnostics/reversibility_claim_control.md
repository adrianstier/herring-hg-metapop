# Reversibility Claim-Control Audit

Generated: 2026-05-19 21:25:50.542681

This file records the claim-safety pass for reversibility synthesis outputs.

## Prohibited phrasing (documented here as a checklist, never asserted)

The synthesis must not state a completed tipping point, a proven
bifurcation/fold, a causal attribution to predators, or that hysteresis is
confirmed. All verdicts are 'supported / weak / refuted / indeterminate'
from discrimination_table(), and predator inputs are context-only.

## Scientific-integrity fixes applied (spec review)

- effective_driver_returned uses the COMPOSITE net pressure (u + predation
  + PDO), gated against the 1972-2004 roe-fishery pre-collapse reference —
  NOT fishing-only u (which trivially -> 0 post-moratorium).
- new_potential_well = NA (-> indeterminate) when the post-closure potential
  landscape is not estimable at n~19 — never coerced to a false FALSE.
- discrimination_table column relabelled support_criteria (support TEMPLATE,
  not findings); an observed-evidence block is emitted so the record is
  internally consistent on loop significance.

## Evidence provenance

| Field | Source | Status |
|-------|--------|--------|
| nonlinear | reversibility_edm_nonlinearity.csv | GENUINE (S-map theta test, n=75) |
| lambda_failed_to_relax | reversibility_edm_jacobian_eigen.csv | GENUINE (post-closure Jacobian trend, n=20) |
| new_potential_well | reversibility_potential_landscape_pre_post.csv | NA: post-closure potential landscape NOT ESTIMABLE at n=20 (underpowered, degenerate contract) |
| loop_p | reversibility_driver_state_hysteresis_loop.csv | GENUINE (500-replicate survey-artifact null, full series) |
| effective_driver_returned | reversibility_effective_driver.csv (COMPOSITE) | GENUINE (composite net pressure: recent>=2015 median=-0.155 vs roe-era 1972-2004 median=0.149; n_ref=33, n_recent=10) |
| artifact_reproduces | derived from loop_null_p | GENUINE (loop_null_p=0.0020; >=0.05 would mean artifact reproduces) |

