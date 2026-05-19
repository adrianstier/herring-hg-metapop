# Reversibility Controls — Power Calibration

Generated: 2026-05-19 21:57:10.114796
Canonical seed: 20260519
Seeds tested: 12

## Summary

- Positive control PRIMARY criterion (lambda_trend > 0): 9/12 seeds pass
- Canonical seed PRIMARY pass: TRUE

- Canonical seed pos_lambda_trend  = 0.0020
- Canonical seed pos_nl_p          = 1.000 (SECONDARY — not a gate)
- Canonical seed neg_nonlinear_sig = FALSE
- Canonical seed neg_lambda_trend  = -0.0011

## Design Notes

PRIMARY criterion: positive control lambda_trend > 0 (pre-transition Jacobian
eigenvalue rising as fold is approached — critical slowing down signature).

SECONDARY criterion: S-map nonlinearity (nl_p < 0.05). Reported only; underpowered
at n=70 (slow-passage slow-transition regime). Never used as a hard pass/fail gate.

Negative control target: nonlinearity_detected = FALSE AND lambda_trend ~ 0
(linear-stochastic OU/AR(1); no directional eigenvalue trend).

Non-zero exit (status=1) fires if PRIMARY fails at canonical seed 20260519.

## Per-Seed Results

| seed | canonical | pos_lam_trend | pos_primary | neg_nonlin | neg_lam_trend |
|------|-----------|--------------|-------------|------------|--------------|
| 20260519 | TRUE | 0.0020 | TRUE | FALSE | -0.0011 |
| 1 | FALSE | 0.0015 | TRUE | FALSE | -0.0010 |
| 2 | FALSE | -0.0003 | FALSE | FALSE | -0.0004 |
| 3 | FALSE | 0.0004 | TRUE | FALSE | 0.0001 |
| 4 | FALSE | 0.0033 | TRUE | TRUE | 0.0029 |
| 5 | FALSE | 0.0033 | TRUE | FALSE | 0.0003 |
| 7 | FALSE | NA | FALSE | FALSE | -0.0047 |
| 11 | FALSE | 0.0016 | TRUE | FALSE | 0.0043 |
| 21 | FALSE | 0.0009 | TRUE | FALSE | 0.0005 |
| 42 | FALSE | 0.0005 | TRUE | FALSE | -0.0007 |
| 99 | FALSE | -0.0118 | FALSE | FALSE | 0.0009 |
| 123 | FALSE | 0.0020 | TRUE | FALSE | 0.0007 |

