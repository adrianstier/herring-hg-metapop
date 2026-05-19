# Reversibility Discrimination Table

Generated: 2026-05-19 21:57:10.262615
Canonical seed: 20260519

## Observed Evidence (ACTUAL values — not the support template)

| Field | Observed value | Measurement status |
|-------|----------------|---------------------|
| nonlinear | FALSE | GENUINE (S-map theta test, n=75) |
| lambda_failed_to_relax | TRUE (post-closure Jacobian trend=0.0136) | GENUINE (post-closure Jacobian trend, n=20) |
| new_potential_well | NA (NOT ESTIMABLE at n=20) | NA: post-closure potential landscape NOT ESTIMABLE at n=20 (underpowered, degenerate contract) |
| loop_p | 0.0020 | GENUINE (500-replicate survey-artifact null, full series) |
| effective_driver_returned | TRUE (composite recent median=-0.155 vs roe-era median=0.149) | GENUINE (composite net pressure: recent>=2015 median=-0.155 vs roe-era 1972-2004 median=0.149; n_ref=33, n_recent=10) |
| artifact_reproduces | FALSE | GENUINE (loop_null_p=0.0020; >=0.05 would mean artifact reproduces) |

## Discrimination Verdicts

`support_criteria` below is the TEMPLATE of conditions that WOULD support
each verdict — it is NOT the observed evidence. Read a refuted row as
"would be supported IF <support_criteria>". The observed values are in the
table above.

| Explanation | Verdict | Support criteria (template, not findings) |
|-------------|---------|--------------------------------------------|
| hysteresis | indeterminate | nonlinear + |lambda| not relaxed + new well + sig. loop |
| unreturned_driver | refuted | fishing removed but effective driver did not return |
| long_transient | indeterminate | restoring but slow; no new well; n.s. loop |
| artifact | refuted | survey-artifact null reproduces the observed signal |

