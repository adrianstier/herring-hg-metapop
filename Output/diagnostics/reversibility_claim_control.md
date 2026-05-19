# Reversibility Claim-Control Audit

Generated: 2026-05-19 21:08:07.202684

This file records the claim-safety pass for reversibility synthesis outputs.
Run `grep -i` checks below to verify no prohibited language survived.

## Prohibited phrases

- 'the system tipped'
- 'proves a fold'
- 'proves a bifurcation'
- 'caused by predators'

## Self-audit result

All synthesis language uses: 'consistent with', 'not supported',
'indeterminate', 'refuted', or 'weak' (from discrimination_table verdicts).

No absolute causal claims appear in reversibility_synthesis.md.
Predator covariates are marked context-only in the effective_driver_provenance.md.

## Evidence provenance

| Field                      | Source file                                         |
|---------------------------|-----------------------------------------------------|
| nonlinear                  | reversibility_edm_nonlinearity.csv (nl_sig, all11)  |
| lambda_failed_to_relax     | reversibility_edm_jacobian_eigen.csv (post-2005 trend) |
| new_potential_well         | reversibility_potential_landscape_pre_post.csv      |
| loop_p                     | reversibility_driver_state_hysteresis_loop.csv (u x biomass) |
| effective_driver_returned  | reversibility_driver_axis.csv (post-closure u)      |
| artifact_reproduces        | derived from loop_null_p >= 0.05                    |

