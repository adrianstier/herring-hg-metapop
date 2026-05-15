# WCVI Predation Replication Bridge

Updated: 2026-05-15

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

## May 15 Data-Execution Update

The herring assessment input side is no longer just a request plan. Public DFO
Appendix B tables have been provisionally extracted by
`Code/02e_extract_dfo_hg_assessment_tables.R`:

- HG catch by gear, 1951-2017;
- HG aggregate spawn index, 1951-2017;
- HG number-at-age by gear/source, 72 source-year rows;
- HG weight-at-age, 1951-2017;
- HG biosample counts;
- fixed maturity-at-age schedule.

The current blocker is not whether those streams exist. The blocker is that the
repo still lacks current 2018-2024 machine-readable biological inputs,
effective sample-size/preprocessing metadata, length-at-age tables, and predator
age/size selectivity. Since that first pass, `Code/02f_extract_newer_dfo_public_pdfs.R`
also extracts DFO 2025/005 public summaries through 2024 for HG catch, spawn,
SCA parameters, recruitment, biomass/depletion, reference points, and projected
broad age composition. Those are status/reporting extracts, not exact raw
age/weight input matrices. See `docs/doherty-style-hg-replication-status.md`.
The source map for these herring and predator streams is
`docs/doherty-style-hg-source-provenance.md`; new assessment or predator data
products should not enter this bridge unless their source registry row and
table-level source fields are present.

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

`m5_stier_predator_demand_total` completed on AWS on May 15 after being
submitted on May 14 as a deliberate single-covariate screen. The diagnostic
reason remains narrow: the WCVI bridge supports demand over pressure ratio
conceptually, but the completed fit does not justify predator combinations or
promotion.

Local geometry check:

- a short 200-iteration smoke compiled but adapted poorly and hit max
  treedepth;
- a longer-warmup smoke (`650` iterations, `550` warmup, one chain) had
  `0` divergences, `0` treedepth hits at max treedepth `15`, and E-BFMI about
  `1.03`;
- all saved draws were at treedepth `14`, which is expensive but consistent
  with the promoted baseline and full `m5_stier_predation_pressure` fit.

Full-run result:

- sampler-clean: `0` divergences, `0` treedepth hits, max R-hat about `1.001`,
  min E-BFMI about `0.816`;
- predator-demand coefficient median about `-0.057`, 90% interval about
  `-0.110` to `-0.003`;
- positive-spawn log RMSE about `0.560`, versus about `0.565` for
  `m1_stier_11`;
- catch log RMSE about `0.010`, effectively unchanged;
- PSIS is not clean: `2` Pareto-k points above `0.7`, maximum about `0.906`.

Interpret this as a completed-but-held screen. Do not add predator combinations
or spend exact re-LOO time before the talk unless predator inference becomes
the central claim.
