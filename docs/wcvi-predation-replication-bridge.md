# WCVI Predation Replication Bridge

Updated: 2026-05-16

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
- screens 50 km harbour seal and Steller sea lion section-year exposure rows
  against section-level promoted-baseline growth, with section controls and
  exposure-weighted extrapolation flags;
- writes the control diagnostic:
  `Output/diagnostics/wcvi_predation_replication_bridge.md`.

Current read from that bridge:

- recent predator consumption is large relative to observed spawn deposition;
- mean 2015-2024 HG predator consumption is about 15.5 kt/yr;
- mean 2015-2024 predator-removal analogue against `m1_stier_11` biomass is
  about 25%;
- total predator demand is a cleaner model covariate than pressure ratio, but
  the lag-1 total-demand signal is weak after detrending and adjustment.
- no current section-year exposure candidate clears the gate; the best row is
  harbour seal exposure, but lag-1 Spearman rho is near zero and the detrended
  direction is not a credible predator effect.

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

## May 16 HG Proxy-Removal Branch

The next AWS troubleshooting branch is `m5_stier_doherty_proxy_removals`. It is
the closest current analogue to Doherty's removal logic that does not pretend we
have final HG catch-at-age inputs:

- the observation layer remains `m1_stier_11` style: ambiguous zeros skipped,
  two-era `q`, and 11 sections;
- audited HG predator mortality proxy values from
  `/Users/adrianstier/pacific-herring-predators` enter as a scaled catch-like
  biomass mortality analogue;
- the registered first-pass screen uses `Mp_mid` with
  `DOHERTY_PROXY_PRED_SCALE=0.05`, after unscaled and 0.25-scaled `Mp_mid`
  smokes were too slow/pathological for AWS full-fit submission;
- predator removal is shared across sections in proportion to latent
  post-fishery biomass;
- no age composition, weight-at-age, length-at-age, or predator selectivity is
  fitted.

Use this branch to troubleshoot geometry and sensitivity to catch-like predator
removals on AWS. Do not describe it as the completed HG Doherty catch-at-age
model.

Cloud smoke outcome: the low-vulnerability smoke (`Mp_mid * 0.05`) completed on
AWS Batch on 2026-05-16, but it is not full-fit ready. The smoke had 0
divergences and 0 treedepth hits, yet E-BFMI was about 0.003 and `sigma_proc`
inflated, showing that the fixed-removal offset is being absorbed by process
variance. Treat this as a negative geometry result and reparameterize or replace
the fixed-removal formulation before submitting a full run.

## May 16 Mp-Covariate Fallback

The fallback branch is `m5_stier_doherty_mp_covariate`. It keeps the same
Stier-aligned observation layer and uses `pred_mortality_mid_z = z(log1p(Mp_mid))`
as an estimated annual process covariate. This is less mechanistically strict
than fixed catch-like removals, but it answers a useful diagnostic question:
does the Doherty-style HG Mp proxy carry a model signal when it is estimated as
a normal single covariate rather than imposed as fixed mortality?

Interpretation guardrail: this branch is still not a catch-at-age model. It has
no age composition, weight-at-age, length-at-age, predator selectivity, or
future predator scenarios.

Troubleshooting outcome: the initial `pred_mortality_mid_z` branch was not
AWS-ready. It had 0 divergences, but 29/100 post-warmup transitions hit max
treedepth and E-BFMI was about 0.008. A detrended,
baseline-anchored version also failed the practical local-smoke gate because it
remained too slow. The bridge screen now includes raw and detrended `Mp_mid`.
The detrended lag-1 Mp proxy has weak signal against promoted-baseline growth:
Spearman rho about 0.09, detrended r about 0.00, and adjusted beta about -0.01.
Do not submit the Mp Stan branch to AWS until there is a stronger spatial or
age-selective predator data product.

## May 16 Section-Exposure Gate

`Code/07bb_predator_spatial_exposure_prototype.R` now writes a formal
section-year exposure product at
`Output/diagnostics/predator_spatial_exposure_section_year.csv`. The table
includes source spans, count sensitivities, observed/interpolated/extrapolated
flags, exposure-weighted extrapolation shares, nearest predator-site distance,
and 25/50/100 km kernels.

`Code/07bj_wcvi_predation_replication_bridge.R` now consumes that table and
screens harbour seal, Steller sea lion raw non-pup, Steller sea lion filled
total, and combined mammal exposure at the section-year grain. The current
lag-1 gate fails for all exposure rows:

- harbour seal exposure: n 196 section-years, 11 sections, rho about -0.02,
  detrended r about 0.05, adjusted beta about -0.12;
- Steller sea lion filled-total exposure: n 473 section-years, 11 sections,
  rho about 0.06, detrended r about 0.04;
- Steller sea lion raw non-pup exposure: n 473 section-years, 11 sections,
  rho about 0.05, detrended r about 0.00;
- combined mammal exposure: n 517 section-years, 11 sections, rho about 0.08,
  detrended r about 0.07.

Do not submit `m6_stier_predator_exposure_mammals` from the current screen. The
implemented output is a better talk-safe explanation of why predation remains a
plausible mechanism and a data-product target, while the promoted model stays
`m1_stier_11`.

## May 16 Talk-Ready Predator Package

The predator branch now has three small supporting products for the Saturday
talk and post-talk data plan:

- `Output/diagnostics/predator_talk_brief.md`: one-slide predator message and
  claim guardrails.
- `Output/diagnostics/humpback_section_exposure_proxy.md`: HG-wide humpback
  demand scaffold. Recent mean demand is about `5.12 kt/yr` and about `307`
  feeding-substantive individuals, but the section weights are uniform, so this
  is not model-ready section exposure.
- `Output/diagnostics/salmon_recruitment_context_screen.md`: salmon demand is
  follow-up-only context for juvenile/recruitment hypotheses, not adult biomass
  mortality. The public 2015-2024 recruitment checks are descriptive only.

Use these as the bridge between the Doherty-style predator narrative and the
current HG model result: predation is plausible and large, but the current
integrated model does not promote a predator coefficient. The next step is
better spatial exposure, especially humpbacks, plus age/recruitment data if the
salmon pathway is pursued.

## May 16 Integrated Predator-Mechanism Gate

`Code/07bs_predator_mechanism_integration_screen.R` now tests whether predator
demand or section exposure becomes stronger when integrated with historical
fishing pressure, PDO, annual fishing, section controls, and year controls.
The strict lag-1 gate returns no candidate rows:

- harbour seal exposure has a negative adjusted coefficient (`beta = -0.10`,
  `p = 0.02`), but fails because raw and post-2005 correlations are positive;
- combined mammal exposure x historical fishing is the strongest interaction,
  but its effect is small (`beta = -0.02`, `p = 0.16`);
- salmon and fish annual demand remain weak follow-up context rather than Stan
  branch candidates.

Use `Output/diagnostics/predator_mechanism_integration_screen.md` as the
current decision note. It strengthens the rationale for not launching a broad
predator or predator x fishing model before better exposure data are available.
