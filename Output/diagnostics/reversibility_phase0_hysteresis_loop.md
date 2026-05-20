# Phase 0 spike — driver-state hysteresis loop (PRELIMINARY, descriptive)

Generated: 2026-05-19
Spec: `docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md`

## What this is / is NOT

- IS: the fastest descriptive read on whether a driver-state **loop** exists
  worth the full battery. HG-internal, reuses on-disk CSVs, no new deps.
- IS NOT: evidence of a fold/bifurcation. No surrogates, no controls, no EDM,
  no significance, no discrimination among the four explanations yet.

## Descriptive contrast (latent biomass, all-11)

**No in-series unfished anchor:** the 1951-2024 record begins mid-reduction-
fishery, so there is no low-driver point before exploitation. The pristine
baseline is the 10,000-yr archaeological one (out of series). This is a
*driver-removal* contrast, not a matched-low-driver loop gap.

- Empirical exploitation collapse: last year u>0.02 = **2002**.
- Early industrial (1951-1957), driver HIGH: mean u=0.289, mean biomass=**74181 t**.
- Post-closure (2015-2025), driver ~0: mean u=0.000, mean biomass=**46664 t**.
- Fishing driver removed (u 0.29 -> ~0) yet state is **27517 t lower** —
  recent biomass is **63%** of the 1950s *heavily-fished* level.
- Focal-9 sensitivity: same ratio = 44%.

## Descriptive contrast (structure: synchrony phi)

- Early windows (mid <=1960): mean phi = **0.26**.
- Recent windows (mid >=2015): mean phi = **0.53**.
- Driver removed yet phi ROSE (portfolio structure eroded further, did not
  retrace) — structure tracks the driver-removal even less than biomass.

## Reading (control-sheet-safe)

The fishing driver was reduced to ~zero at the closure, yet neither biomass
nor portfolio structure retraced upward — biomass sits below its 1950s
heavily-fished level and synchrony rose. Consistent with the control-sheet
hysteresis sentence ("the driver can be reduced without the service
trajectory retracing the collapse path"). **Descriptive only** — does NOT
distinguish:

  (i) true hysteresis / new attractor;
  (ii) **the effective driver never returned** — only *fishing* was removed;
       predation may have risen and carrying capacity fallen, so the net
       control parameter need not have returned. THIS is the leading honest
       alternative; the effective-driver reconstruction (full spec) is
       required before any hysteresis claim.
  (iii) a long transient (slow, not blocked);
  (iv) a measurement-scale artifact.

Discriminating (i)-(iv) is the full spec (EDM Jacobian, potential landscape,
effective-driver, surrogates, positive/negative/survey-artifact controls).

## Outputs

- `Output/figures/reversibility_phase0_hysteresis_loop.{pdf,png}`
- `Output/figures/reversibility_phase0_synchrony_loop.{pdf,png}`
- `Output/diagnostics/reversibility_phase0_driver_state.csv`
