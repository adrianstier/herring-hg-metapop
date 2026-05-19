# Reversibility Discrimination Table

Generated: 2026-05-19 21:08:07.19488
Canonical seed: 20260519

## Evidence Bundle

| Evidence field              | Value |
|----------------------------|-------|
| nonlinear (S-map, all_11)   | FALSE    |
| lambda_failed_to_relax      | TRUE (post-closure trend=0.0136) |
| new_potential_well          | FALSE (0 post-closure minima) |
| loop_p (u x biomass_all11)  | 0.0020 |
| effective_driver_returned   | TRUE (post-closure median u=0.0000) |
| artifact_reproduces         | FALSE |

## Discrimination Verdicts

| Explanation          | Verdict        | Signatures |
|---------------------|----------------|-----------|
| hysteresis           | refuted        | nonlinear + |lambda| not relaxed + new well + sig. loop |
| unreturned_driver    | refuted        | fishing removed but effective driver did not return |
| long_transient       | weak           | restoring but slow; no new well; n.s. loop |
| artifact             | refuted        | survey-artifact null reproduces the observed signal |

