# stier-2027-herring-metapopulation

**Updated analysis of Pacific herring metapopulation dynamics at Haida Gwaii, extending Stier et al. (2020) with a decade of new data, Stan models, and new ecological questions.**

## Start Here

If you are reading this repository for the first time, use this order:

1. `README.md` for the project scope and the current model hierarchy.
2. `docs/collaborator-reading-guide.md` for the codebase reading order and file map.
3. `docs/theory-data-model-integration.md` for how ecological hypotheses become cleaned covariates, Stan data, parameters, and figures.
4. `docs/stan-model-map.md` for which Stan files are primary, archival, or generated artifacts.
5. `R/00_setup.R`, `R/01_data_cleaning.R`, `R/10_spatial_data.R`, and `R/02_prepare_model_data.R` for the data contract.
6. `inst/stan/*.stan` plus `R/03_fit_model.R` for the model contract.
7. `R/05_portfolio.R`, `R/08_occupancy_model.R`, `R/06_figures.R`, and `R/07_lecture_figures.R` for interpretation and communication.

The maintained workflow lives in `R/`, `_targets.R`, `inst/stan/`, and `tests/testthat/`.
The top-level `Code/` directory contains exploratory or one-off scripts that are useful context, but it is not the primary pipeline a collaborator should learn first.

## Motivation

Stier et al. (2020, *Ecosphere*) documented how fishing and environmental change eroded the spatial portfolio of herring subpopulations at Haida Gwaii, increasing synchrony and regional extinction risk. That analysis used spawn index and catch data through 2015 with a JAGS state-space model.

Since then:
- **The fishery has remained closed** (2005-present; DFO 2025 recommendation: 0 tonnes) — a 19-year natural experiment
- **The 2014-16 marine heatwave ("the blob")** hit during the study's final years — its aftermath is now visible
- **Predator recovery continued** — humpback whales, Steller sea lions, and harbor seals have further increased
- **Ono et al. (2025, *Nature*)** demonstrated collective memory loss in Norwegian herring — validating the mechanism hypothesized for Haida Gwaii
- **The 2024 Haida Gwaii Herring Rebuilding Plan** was finalized (CHN/DFO/Parks Canada)

## Core Questions

1. **Has the portfolio continued to erode?** With no fishing since 2005, has spatial diversity recovered — or has synchrony locked in?
2. **Does distance explain spatial correlation?** Can we replace 55 free correlations with a single distance-decay parameter?
3. **Is there density dependence?** The 19-year closure is a natural experiment — growth should decelerate if DD exists.
4. **Have predator effects intensified?** With continued marine mammal recovery, has natural mortality further increased?
5. **Can we detect collective memory loss?** Is there evidence of spawning site abandonment consistent with Ono et al. (2025)?

## Model Comparison Hierarchy

| Model | Spatial | Density Dep. | Predators | Key Question |
|-------|---------|-------------|-----------|-------------|
| M1 | Diagonal-equal | None | None | Baseline (reproduces Stier 2020) |
| M2 | Distance-decay (φ) | None | None | Does spatial structure matter? |
| M3 | Distance-decay | Global Gompertz | None | Is there density dependence? |
| M4 | Distance-decay | Site-specific Gompertz | None | Does DD vary by site? |
| M5 | Distance-decay | Best DD | SSL + seal + whale | Do predators suppress recovery? |
| M6 | Time-varying φ(t) | Best DD | Best predators | When did synchrony change? |
| Occupancy | — | — | — | Collective memory / site fidelity |

All models compared via LOO-CV. See `docs/analysis-plan.md` for details.

## What's New vs. 2019

| Dimension | Stier et al. 2020 | This Analysis |
|-----------|-------------------|---------------|
| Data | 1940-2015 | 1951-2025 maintained model window |
| Sampler | JAGS (Gibbs, 1M iterations) | Stan/cmdstanr (HMC, ~2000 iterations) |
| Spatial | Diagonal-equal (55 free correlations) | Distance-decay (1 parameter) + time-varying |
| Density dep. | None | Gompertz (global + site-specific) |
| Predators | None | SSL + seal + whale (spatially weighted) |
| Collective memory | Not tested | Formal occupancy sub-model |
| Models | 1 | 7 in a comparison hierarchy |
| Pipeline | Scripts with `setwd()` | `{targets}` + `here()` |
| Tests | None | 235 `testthat` expectations across 4 test files |

## Current Modeling Direction

Recent review of Stier et al. (2020), the archived JAGS code, and the Haida Gwaii survey context changed the preferred baseline direction:

- **Zero spawn records are ambiguous by default.** Stier et al. treated reported zero spawn as missing because zeros can reflect missing or unreliable survey information rather than true biological absence. In the current Haida Gwaii context, some site-years may also be unsurveyed for governance/access reasons, including Haida preferences, so absence of survey effort must not be interpreted as low biomass.
- **Informative-zero / detection models are sensitivity analyses.** Detection-aware models that treat surveyed zeros as evidence of below-threshold biomass remain useful, but they should not be promoted without explicit survey metadata justifying that interpretation.
- **Survey method effects are essential.** Stier estimated separate surface and SCUBA survey catchability terms. This repository may also test a mixed-transition era, but Stier-aligned replication should preserve the original two-era logic.
- **The `q` scale is unit dependent.** Stier used the spawn habitat index scale, while current maintained data use `spawn_index_tonnes`. The proportional observation equation transfers, but numerical `log.q` values should not be copied across scales without a unit-specific sensitivity.
- **Fit 11, report 9 as a sensitivity.** Stier fit the state-space model to 11 Haida Gwaii subpopulations but focused figures and interpretation on 9 data-rich focal subpopulations. This repo should preserve both 11-section and 9-focal reporting paths.
- **Hold size/age structure for now.** Age composition and weight-at-age are future covariates or stock-area cross-checks, not part of the current section-level baseline.
- **Label Doherty-style proxies explicitly.** For the May 16 talk cycle, public HG DFO tables are the first source for catch, age composition, weight-at-age, maturity, and current assessment context. WCVI/Doherty values can be shown only as provisional analogues for missing length/size/selectivity or model-structure pieces. They are not Haida Gwaii-estimated catch-at-age, size-at-age, or predator-selectivity parameters. The proxy ledger is `Output/diagnostics/doherty_proxy_parameter_plan.md`, regenerated by `Code/07bo_doherty_proxy_parameter_plan.R`.

### Current promoted baseline

As of 2026-05-11, the promoted practical baseline is still `m1_stier_11`:

- zeros are treated as ambiguous/missing, following Stier et al. (2020) and the archived JAGS model;
- all 11 Haida Gwaii sections are fit;
- surface and SCUBA survey-era catchability terms are explicit;
- size/age structure, predators, and density dependence are held out of this baseline.

The fit is sampler-clean and the only high PSIS-LOO point was resolved by exact re-LOO. The held-out 1970 Naden Harbour refit changed total LOOIC only from 1953.02 to 1953.08, so the LOO warning is negligible for current model selection. Detection-aware models such as `m1_v4`/`m1_v5` remain sensitivity analyses because they use a different surveyed-cell likelihood unit and treat zeros as informative nondetections.

The main May 11 challenger, `m1_stier_obs_hier`, is also sampler-clean but is held rather than promoted. It kept the Stier-aligned ambiguous-zero likelihood and added section-specific observation error plus surface-era extra variance, but positive-spawn calibration worsened relative to `m1_stier_11` (aggregate log10 RMSE 0.64 versus 0.56) and PSIS was less stable (max Pareto k 1.29).

### Current model sequence

The next models should be rebuilt from the `m1_stier_11` observation layer rather than promoted from older stale `v3`/`v5` branches. The current working order is:

1. finish the 9-focal reporting sensitivity from the existing 11-section fit;
2. screen population state, section winners/losers, fishing pressure, and candidate drivers from `m1_stier_11`;
3. hold `m2_stier_site_growth`: it was sampler-clean but did not improve positive-spawn calibration and had unresolved Pareto-k instability;
4. hold `m1_stier_method_sensitivity`: it was sampler-clean but did not improve positive-spawn calibration, had unresolved Pareto-k instability, and estimated a highly uncertain mixed-transition q;
5. hold `m1_stier_obs_hier`: it was sampler-clean but worsened positive-spawn calibration, so extra observation variance alone is not the answer;
6. hold `m3_stier_distance`: it was sampler-clean and estimated a plausible distance-decay range; exact re-LOO completed for the three high-k points, but one exact refit had treedepth pressure and the positive-spawn calibration gain remains too small for promotion;
7. hold complex density dependence for now: the posterior-median density screen has no strong archipelago-wide negative signal;
8. do not launch a redundant PDO-only branch: `m1_stier_11` already includes lagged PDO, so further climate work should focus on PDO window/lag sensitivity or clearer interpretation of the existing coefficient;
9. use `m5_stier_predation_pressure` as the first AWS predator branch: it keeps
   the Stier-aligned observation layer and adds lagged HG predation pressure
   from `stier-lab/pacific-herring-predators`;
10. add timing/substrate covariates and finer section-level predator exposure
    only after the annual predator-pressure branch remains sampler-clean and
    materially improves diagnostics.

As of 2026-05-11, the promoted branch remains `m1_stier_11`. The three-era method-sensitivity readout is `Output/diagnostics/m1_stier_method_sensitivity_postfit.md` and `Output/figures/m1_stier_method_sensitivity_postfit.pdf`. The distance-covariance readout is `Output/diagnostics/m3_stier_distance_postfit.md` and `Output/figures/m3_stier_distance_postfit.pdf`; exact re-LOO completed for its three high-k points, but the branch remains spatial context because fit gain is small and one exact refit had treedepth pressure. See `docs/current-population-driver-findings.md` for the current population/driver synthesis, `docs/may-9-analysis-decision-summary.md` for the compact model-decision checkpoint, `docs/may-9-analysis-output-index.md` for a map of the diagnostics generated during the May 9 sprint, and `Output/diagnostics/may9_headline_findings.md` for the shortest table of headline numbers. Three additional context audits now support the model-ordering decision: `Output/diagnostics/survey_coverage_zero_ambiguity.md` documents why zero/no-survey cells remain ambiguous, `Output/diagnostics/predator_data_feasibility_audit.md` documents why regional predator covariates remain descriptive, and `Output/diagnostics/predator_spatial_exposure_prototype.md` shows that a section-level seal/sea-lion exposure product is feasible but still not causal evidence.

As of 2026-05-10, use `Output/diagnostics/may10_integrated_evidence_matrix.md`
as the compact analysis control sheet. It translates the diagnostic suite into
claim, evidence, caveat, next-action, and confidence rows, and is regenerated by
`Code/07ag_integrated_evidence_matrix.R`.
For model-parameter choices from the NotebookLM/paper scan, use
`docs/literature-parameter-roadmap.md`. The observation-calibration branch with
section-specific observation error and surface-era extra variance has now been
tested as `m1_stier_obs_hier`; it is clean but held because it does not improve
fit. Predators and age/size remain future/context work.
The main portfolio figure has also been regenerated from the promoted baseline:
`Output/figures/m1_stier_11_portfolio_metrics_combined.pdf` now overwrites the
legacy `Output/figures/portfolio_metrics_combined.pdf` path.
For fit caveats, use `Output/diagnostics/positive_spawn_fit_caveat.md`: the
modern/recent fit is much better than the early surface-era fit, so individual
early surface magnitudes should not carry the headline story.
For the shortest single current evidence package, use
`Output/diagnostics/promoted_baseline_evidence_package.md`; it combines model
status, biomass, spawn/catch fit, section roles, caveats, and priority figure
paths for the promoted `m1_stier_11` baseline.
For the current section-level work plan, use
`Output/diagnostics/section_action_matrix.md` and
`Output/figures/section_action_matrix.pdf`: Cumshewa/Louscoone are the lead
mechanism cases, Juan Perez/Skincuttle are current biomass concentration cases,
and Tasu/Naden are uncertainty sensitivity only.
For the lead mechanism/portfolio local data audit, use
`Output/diagnostics/lead_section_local_audit.md` and
`Output/figures/lead_section_local_audit.pdf`: it focuses Cumshewa,
Louscoone, Laskeek, and Skidegate on survey coverage, period records, and raw
HG location concentration.
For within-section raw spawn-location persistence, use
`Output/diagnostics/lead_section_location_transition.md` and
`Output/figures/lead_section_location_transition.pdf`: Louscoone and Cumshewa
have recent raw signal near 1% of roe-fishery signal, while Laskeek has a
larger but still depleted recent raw signal across more locations. Skidegate is
not available in that raw HG section extract, so keep it as model/processed
series evidence only for this specific local-location screen.
The geocoded companion is `Output/diagnostics/lead_section_location_map.md` and
`Output/figures/lead_section_location_map.pdf`; use it to target local
access/habitat/exposure follow-up rather than to infer absence.
`Output/diagnostics/lead_spawn_location_predator_proximity.md` and
`Output/figures/lead_spawn_location_predator_proximity.pdf` link those
geocoded raw spawn locations to post-2005 harbour seal and Steller sea lion
sites. Current read: predator proximity is computable at the local scale, but
lost locations are not clearly more predator-exposed than persistent locations,
so this remains audit targeting rather than predator-effect evidence.
The practical named follow-up list is
`Output/diagnostics/lead_location_followup_targets.md` with figure
`Output/figures/lead_location_followup_targets.pdf`: it combines
location-transition status, spawn-method/substrate metadata, coordinates, and
seal/sea-lion proximity. Use it for targeted local review; a lost-location
label still means "no recent positive raw record in this extract", not proven
absence.
For predator work, first run
`Rscript Code/02c_integrate_hg_predator_repo_products.R` with
`PREDATOR_REPO_PATH` pointing to a checkout of the private
`stier-lab/pacific-herring-predators` repo. That creates
`Data/processed/predators/hg_predation_pressure_covariates.csv`, which feeds the
new `m5_stier_predation_pressure` AWS/model-farm branch. This is the current
predator branch to test before returning to older `m5_v5` or `m5_combined`
scripts.

The local predator source repo is
`/Users/adrianstier/pacific-herring-predators`. For predator data,
predator-only figures, and source catalogs, use
`docs/predator-repo-integration-guide.md` and `CLAUDE.md`. The short import is:

```sh
PREDATOR_REPO_PATH=/Users/adrianstier/pacific-herring-predators \
  Rscript --vanilla Code/02c_integrate_hg_predator_repo_products.R
```

The predator repo's canonical outputs include
`data/processed/consumption_budget/HG_predation_pressure_index_AUDITED.csv`,
`data/processed/consumption_budget/HG_pressure_climate_predator_covariates.csv`,
`data/processed/consumption_budget/HG_consumption_by_group_year_AUDITED.csv`,
and `Output/figures/MASTER_HG_predation_AUDITED.pdf`. After import, this
herring repo uses local ignored products in `Data/processed/predators/` for
model covariates and integrated diagnostics.

For spatial predator context, use `Output/diagnostics/predator_spatial_exposure_prototype.md`
and `Output/figures/predator_spatial_exposure_prototype.pdf`: raw Haida Gwaii
harbour seal and Steller sea lion records can be converted into rough
section-level exposure covariates, but the current screen is still weak or
time-confounded and should be treated as a data-product roadmap, not a
predator-effect result. The talk-ready predator summary is
`Output/diagnostics/predator_talk_brief.md`. For missing predator-data pieces,
use `Output/diagnostics/humpback_section_exposure_proxy.md` for the HG-wide
humpback scaffold and `Output/diagnostics/salmon_recruitment_context_screen.md`
for salmon as juvenile/recruitment context. The integrated predator mechanism
gate is `Output/diagnostics/predator_mechanism_integration_screen.md`; it
tests predator demand/exposure with historical fishing, PDO, section controls,
and timing/substrate context and currently returns no strict Stan candidate.
For the most compact combined covariate read, use
`Output/diagnostics/section_recovery_covariate_screen.md` and
`Output/figures/section_recovery_covariate_screen.pdf`: historical fishing
is the strongest section-level recovery axis. For model-scope decisions, use
`Output/diagnostics/covariate_readiness_registry.md`; it separates covariates
already in the promoted model from descriptive screens, prototype data products,
and held ideas such as age/size. Predator exposure, timing/substrate, and
survey coverage remain descriptive/context variables.
For the current biomass number, also use
`Output/diagnostics/current_biomass_uncertainty_decomposition.md` and
`Output/figures/current_biomass_uncertainty_decomposition.pdf`: the 2025
all-11 median is useful, but sparse fit-only sections account for about 92% of
the upper 5% biomass tail, so the focal-9 estimate is the cleaner talk number.
For the specific question of whether the original Stier et al. signal persists
with the 2025 update, use
`Output/diagnostics/stier_signal_persistence_summary.md`.
For cloud execution, use `docs/cloud-model-running-setup.md` and the scripts in
`cloud/`. The setup supports simple EC2+S3 jobs and an AWS Batch model farm
driven by `cloud/model-farm-manifest.csv`, so observation, spatial, density,
predator, time-varying, exact re-LOO, and smoke-test branches can run as
independent cloud jobs.
The latest local AWS status report is
`Output/diagnostics/aws_batch_model_farm_status.md`; if it is stale, refresh the
CLI token with `aws sso login --profile herring` before polling or syncing
Batch results.
The full run/collect/audit/rerun scope is in
`docs/full-analysis-model-farm-scope.md`.
Implementation notes for reusing this Codex-to-AWS pattern in future projects
are in `docs/aws-codex-model-farm-lessons.md`.

Key May 9 diagnostics so far: recent biomass is concentrated in a few sections, three focal sections remain below 20% of their 1951-1965 section baseline in the recent closure period, historical fishing pressure is a strong but incomplete section-level driver, and the closure-response diagnostic shows why fishing history and recovery must be separated: recent biomass is about 1.52x the roe-fishery median after fishing ended, but median occupied sections fall from 8 during the roe fishery to 5 recently. Cumshewa and Louscoone are the clearest depletion-beyond-fishing cases. The existing lagged-PDO baseline effect is negative but uncertain; a cheap PDO window screen finds lag 0-1 slightly stronger while lag 1 remains competitive, so do not launch a redundant PDO-only branch. Predator indices are strongly time-confounded, density-dependence evidence is weak, and residual spawn-fit correlations show only weak distance decay. The new predator spatial exposure prototype makes the next predator step clearer: refine section-level exposure from raw seal/sea-lion locations before fitting a predator coefficient. Those results keep the near-term priority on section heterogeneity, local exposure data products, and observation calibration before predator or age/size model branches.

The May 9 spawn-index scale audit also shows that maintained DFO `spawn_index_tonnes` is not a simple numerical continuation of Stier's legacy SHI scale. The median SHI / tonnes ratio is about 112, but it varies strongly by section, so legacy `q` values should not be copied into the current DFO-tonnes model.

Full age/size structure is not part of the next section-level model branch. Age composition and weight-at-age should be treated as future regional covariates, priors, or cross-checks.

For the Saturday talk, the Doherty-style material should be framed as a
source-traceable bridge, not as a completed HG catch-at-age predator-removal
analysis. Use `Output/figures/hg_dfo_sca_external_comparison.pdf`,
`Output/figures/wcvi_predation_replication_bridge.pdf`, and
`Output/figures/doherty_proxy_parameter_plan.pdf` together: the first two show
predator-demand scale and DFO context, while the proxy plan shows which
age/size/catch inputs are HG public extracts, which are WCVI/Doherty analogues,
and which still require exact DFO inputs.

## Repository Structure

```
stier-2027-herring-metapopulation/
├── R/                              # 12 maintained R files
│   ├── 00_setup.R                  # Constants, themes, palettes
│   ├── 01_data_cleaning.R          # 7 data functions (tidyverse, named columns)
│   ├── 02_prepare_model_data.R     # Stan/JAGS dual-format data assembly
│   ├── 03_fit_model.R              # cmdstanr fitting, tidybayes extraction (M1-M6)
│   ├── 04_model_comparison.R       # LOO-CV comparison + visualization
│   ├── 05_portfolio.R              # Portfolio effect, synchrony, site occupancy
│   ├── 06_figures.R                # 6 publication figures (patchwork + theme_pub)
│   ├── 07_lecture_figures.R         # 4K dark-theme lecture figures
│   ├── 08_occupancy_model.R        # Collective memory Stan model interface
│   ├── 09_zero_inflated_obs.R      # Censored observation classification
│   ├── 10_spatial_data.R           # Distance matrices, spatial predator indices
│   └── process_oisst_monthly.R     # Utility to regenerate monthly SST inputs
├── inst/stan/                      # Primary Stan models + archival variants/cache artifacts
│   ├── herring_metapop_m1_stier_11.stan    # Promoted Stier-aligned baseline (zeros ambiguous, 11 sections)
│   ├── herring_metapop_v1.stan             # Earlier diagonal-equal baseline (archival)
│   ├── herring_metapop_v2.stan             # Legacy v2: free MVN (reference only)
│   ├── herring_metapop_m2_distance.stan    # Distance-decay process covariance
│   ├── herring_metapop_m3_dd_global.stan   # + global Gompertz
│   ├── herring_metapop_m4_dd_site.stan     # + site-specific Gompertz
│   ├── herring_metapop_m5_predators.stan   # + predator covariates
│   ├── herring_metapop_m6_timevarying.stan # + time-varying φ
│   ├── site_occupancy.stan                 # Collective memory model
│   ├── herring_metapop_m1_v{2,3,4,5}.stan  # Detection-aware / informative-zero sensitivities (archival)
│   └── herring_metapop_m{3,5}_v{2,3,5}.stan # Earlier process-branch experiments (archival)
├── _targets.R                      # Maintained targets pipeline entrypoint
├── tests/testthat/                 # Regression tests for maintained R code
├── Code/legacy-2019/               # Original JAGS scripts (historical reference)
├── Code/                           # Exploratory / one-off scripts, not primary pipeline
├── Data/
│   ├── raw/                        # 62 files across 7 sources
│   │   ├── legacy-2019/            # Original CSVs (1940-2015)
│   │   ├── dfo-spawn/              # DFO spawn survey (through 2025)
│   │   ├── dfo-catch/              # DFO catch data
│   │   ├── environmental/          # PDO, SST, Chl-a
│   │   ├── predators/              # SSL, harbour seal, humpback
│   │   ├── steller-sea-lions/      # Breeding counts 1971-2013
│   │   └── harbour-seals/          # Haul-out surveys
│   └── processed/                  # Cleaned, merged analysis-ready data
├── Literature/                     # 71 PDFs (core + predators)
├── docs/
│   ├── analysis-plan.md                  # Forward plan after `m1_stier_11`; historical M1-M6 reference
│   ├── analysis-issues-and-fixes.md      # Historical diagnostic memo
│   ├── collaborator-reading-guide.md     # First-pass codebase reading order
│   ├── current-population-driver-findings.md # Current state, driver, and next-model synthesis
│   ├── data-dictionary.md                # All variables documented
│   ├── high-quality-analysis-scope.md    # What is ready vs what would strengthen the analysis
│   ├── okamoto-deep-dive.md              # Okamoto et al. 2020 model deep-dive
│   ├── parameter-comparison-stier2020.md # JAGS vs Stan parameter comparison
│   ├── stan-model-map.md                 # Which Stan files are primary vs archival
│   ├── theory-data-model-integration.md  # Hypotheses → cleaned data → Stan inputs → outputs
│   ├── v3-model-comparison-results.md    # Historical `v3` comparison record
│   └── v5-covariate-rationale.md         # `v5` covariate selection rationale
├── Output/
│   ├── figures/                    # Publication + lecture figures
│   ├── diagnostics/                # Sampler audits, PPCs, LOO/Pareto-k summaries, `latest_model_status.md`
│   ├── tables/                     # Model summaries
│   └── posteriors/                 # MCMC output / LOO artifacts
├── .gitignore
├── README.md
└── stier-2027-herring-metapopulation.Rproj
```

## Stan Directory Note

`inst/stan/` contains:

- primary maintained Stan models used by the current interfaces,
- archival or experimental `.stan` variants kept for provenance,
- generated `.hpp` and compiled `.rds` artifacts from Stan tooling.

For a first read-through, start with the primary files listed in `docs/stan-model-map.md` and ignore `.hpp` / `.rds`.

## Key Papers

| Paper | Relevance |
|-------|-----------|
| **Stier et al. 2020 *Ecosphere*** | The paper this project updates |
| **Ono et al. 2025 *Nature*** | Collective memory loss — the mechanism we test |
| **Samhouri, Stier et al. 2017 *Nat Ecol Evol*** | Predator recovery suppresses herring |
| **Shelton et al. 2014 *Sci Reports*** | Egg vs. adult harvest asymmetry |
| **Okamoto et al. 2020 *Ecol Apps*** | Aggregate management masks local collapse |
| **Frid et al. 2023 *Fish & Fisheries*** | Re-imagining precautionary approach with IKS |

## Getting Started

```r
# Install cmdstanr (requires CmdStan)
install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))
cmdstanr::install_cmdstan()

# Install project packages
# renv::restore()  # once renv is initialized

# Run the pipeline
targets::tar_make()

# Visualize the pipeline
targets::tar_visnetwork()
```

## Repository Conventions

- `YEARS`, `SECTIONS_KEEP`, and `SITE_NAMES` in `R/00_setup.R` define the canonical model dimensions. Most downstream objects are expected to align to those values exactly.
- Zero-spawn handling must be explicit in every model/report. The Stier-aligned default treats zero spawn records as ambiguous/missing unless survey metadata justify true nondetection. Detection-aware / left-censored zero models are sensitivity analyses.
- Spatial models use the same site order as `SITE_NAMES`, with distance matrices and predator matrices aligned to that order.
- Model helpers return cleaned R objects first; `R/03_fit_model.R` then maps those objects onto version-specific Stan `data {}` contracts.
- Future agents should read `AGENTS.md` before changing model code or result interpretation.

## Timeline

- **Spring 2026**: Repo setup, data acquisition, pipeline built
- **Summer 2026**: Run M1-M6 comparison, occupancy model
- **Fall 2026**: Draft manuscript, generate figures
- **Winter 2027**: Submit

## Contributors

- Adrian C. Stier (UCSB)
- [collaborators TBD]

## Citation

Stier AC, Shelton AO, Samhouri JF, Feist BE, & Levin PS (2020) Fishing, environment, and the erosion of a population portfolio. *Ecosphere* 11(11): e03283. doi:10.1002/ecs2.3283
