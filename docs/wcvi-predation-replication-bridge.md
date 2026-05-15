# WCVI Predation Replication Bridge

Updated: 2026-05-14

The WCVI predator paper to mirror is Doherty et al. 2025, *Predation by
marine mammals explains recent trends in natural mortality of Pacific Herring
and changes expectations for future biomass*, ICES Journal of Marine Science
82(5), fsae183, https://doi.org/10.1093/icesjms/fsae183.

## What The WCVI Paper Does

The paper combines three pieces:

- predator abundance and bioenergetic models to estimate annual herring
  consumption;
- a Bayesian catch-at-age herring assessment where predator consumption is
  treated like catch-like removals or predation mortality with predator-specific
  selectivity;
- future predator and herring projections to compare reference points and
  expected biomass under alternative natural-mortality assumptions.

That full approach is not a drop-in replacement for the current Haida Gwaii
analysis because this repo is intentionally a biomass-based, section-level,
Stier-aligned model. We do not currently have a defensible 11-section
age-structured HG assessment with predator selectivity-at-age.

## What We Can Replicate Now

`Code/07bj_wcvi_predation_replication_bridge.R` implements the defensible
near-term replication:

- uses the sibling HG predator consumption budget as the bioenergetic-style
  annual demand product;
- computes WCVI-style removal-rate analogues,
  `predator consumption / (m1_stier_11 biomass + predator consumption)`;
- keeps observed-spawn pressure ratios as descriptive only;
- screens total and group-specific predator demand against promoted-baseline
  latent growth, including future-demand negative controls;
- writes the control diagnostic:
  `Output/diagnostics/wcvi_predation_replication_bridge.md`.

Current read from that bridge:

- recent predator consumption is large relative to observed spawn deposition;
- mean 2015-2024 HG predator consumption is about 15.5 kt/yr;
- mean 2015-2024 predator-removal analogue against `m1_stier_11` biomass is
  about 25%;
- total predator demand is a cleaner model covariate than pressure ratio, but
  the lag-1 total-demand signal is weak after detrending and adjustment.

## How This Integrates With Our Model

The current held branch, `m5_stier_predation_pressure`, used a pressure ratio:

```text
100 * predator_consumption_kt / observed_HG_spawn_kt
```

That is useful for ecological interpretation, but it is partly response-derived
because observed spawn is in the denominator. The next model-ready branch is
therefore `m5_stier_predator_demand_total`, which uses:

```text
z(log1p(C_total_kt))
```

This branch preserves the project constraints:

- ambiguous zeros stay skipped;
- surface/SCUBA catchability remains a two-era split;
- all 11 sections are fitted;
- `m1_stier_11` remains the baseline;
- predator groups are not combined in a richer model until a single-covariate
  branch passes sampler and calibration gates.

## Cloud Decision

`m5_stier_predator_demand_total` is now in the model-farm manifest as
`planned_model_fit`, not as an automatic run. The diagnostic reason is simple:
the WCVI bridge supports demand over pressure ratio conceptually, but the
adjusted demand signal is not strong enough to spend cloud time without an
explicit decision. A local reduced smoke fit compiled and ran, but showed
treedepth pressure, so geometry should be reviewed before any full AWS run.

Submit it only as a deliberate single-covariate screen, after the reduced smoke
and geometry warnings are judged acceptable or fixed.
