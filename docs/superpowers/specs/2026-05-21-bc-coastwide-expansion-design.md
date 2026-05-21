# BC-Coastwide Expansion — Design Spec

**Date:** 2026-05-21
**Workstream:** `analysis/05_bc_coastwide/` (new)
**Status:** brainstorming → design approved → awaiting written-spec review → implementation plan

## Goal

Expand the Haida Gwaii (HG) section-level herring metapopulation analysis to all 8 DFO stock-area codes covering British Columbia (HG, Prince Rupert District, Central Coast, Strait of Georgia, West Coast Vancouver Island, Area 27, Area 2W, NA), at section-level spatial resolution, fitting hierarchical versions of the promoted M1 baseline plus M3 (density-dependence) and M5 (predator-mediated) model branches.

The expansion is **multi-purpose** by design — a single hierarchical BC-wide model whose outputs serve three concurrent goals:

1. **Comparative-areas natural experiment** — stock areas have different fishery histories (HG closed 2002–present, SoG never closed, WCVI partial), different predator regimes (sibling repo coastwide synthesis), different recovery dynamics. Use this variation to separate fishing-driver from environment-driver from intrinsic-dynamics.
2. **Statistical power for EWS / resilience** — HG's hysteresis verdict was `indeterminate` at n=20 post-closure (Output/diagnostics/reversibility_discrimination_table.md). Scaling section count ~10× gives leverage to revisit those underpowered nulls in a follow-on analysis.
3. **Coastwide management application** — section-level risk portfolio, sections at-risk before collapse, alternative framing to current PA-rule management for DFO audiences.

## Decisions locked during 2026-05-21 brainstorm

| Decision | Choice | Rationale |
|---|---|---|
| Primary goal | All three (comparative + EWS power + management) | One BC-wide hierarchical model serves all three with shared data wrangling and modeling |
| Stock-area scope | All 8 codes (HG, PRD, CC, SoG, WCVI, A27, A2W, NA) | Already present in `Pacific_herring_spawn_index_data_2025_EN.csv`; complete dataset inventory |
| Catch acquisition | Open Data Portal as primary + CSAS appendix scrape as cross-check | Open Data canonical for the model; CSAS for validation in years where Open Data is incomplete |
| Model architecture | Hierarchical M1 — sections nested in stock areas | Tractable; standard metapop pattern; matches DFO's own hierarchy |
| Model variants | M1, M3, M5 — full ladder including predators | Tests intrinsic regulation (M3) and predator effects (M5) at the larger spatial scale |
| Repo placement | New workstream `analysis/05_bc_coastwide/` | Cleanest separation; HG-only M1_stier_11 stays as the manuscript baseline |
| Downstream scope | Stop at fitted models + comparative-areas figures (no EWS/resilience re-run in this spec) | Lean scope, single manuscript; EWS/resilience re-run is a follow-on spec |
| Stan file location | `analysis/05_bc_coastwide/stan/` (not `inst/stan/`) | Hierarchical extensions are different enough from core HG models to live separately |
| Cross-stock-area covariance | Zero (block-diagonal Σ) | Reduces free covariance parameters from ~5,000 to ~250 (sum of within-area pairs); cross-area synchrony estimated post-hoc, not via Σ |
| Compute strategy | Sequential by model, parallel by chain, cloud (AWS Batch); ~2–3 weeks wall-clock per round | Existing `cloud/` infrastructure handles this; M3 and M5 build on M1's compilation cache |

## Architecture

```
analysis/05_bc_coastwide/
├── README.md
├── scripts/
│   ├── 00_data_acquisition.R          download/refresh Open Data + CSAS catch
│   ├── 01_assemble_bc_spawn.R         filter 31,168-row CSV → tidy section-year panel
│   ├── 02_assemble_bc_catch.R         Open Data + CSAS appendix merge
│   ├── 03_assemble_bc_predator_covs.R pull from sibling repo, BC-section join
│   ├── 04_assemble_distance_matrix.R  within-stock-area distance matrices
│   ├── 05_prepare_stan_data.R         to Stan data list (hierarchical)
│   ├── 06_fit_m1_bc.R                 baseline (hierarchical) — cloud
│   ├── 07_fit_m3_bc.R                 + Gompertz density-dependence — cloud
│   ├── 08_fit_m5_bc.R                 + predator covariates — cloud
│   ├── 09_diagnostics.R               MCMC + posterior predictive
│   ├── 10_comparative_areas.R         HG vs SoG vs WCVI etc.
│   ├── 11_bc_portfolio.R              coastwide synchrony / CV-ratio / occupancy
│   └── 12_manuscript_figures.R        5 manuscript figures + tables
├── output/                            gitignored; large posterior artifacts
├── docs/
│   ├── README.md
│   └── manuscript-skeleton.md
└── stan/
    ├── herring_metapop_bc_m1.stan     hierarchical M1 extension
    ├── herring_metapop_bc_m3.stan     + Gompertz DD
    └── herring_metapop_bc_m5.stan     + predator covariates
```

Each script uses `here::here()` and runs from repo root. `scripts/00–05` and `09–12` run locally; `06`, `07`, `08` run on AWS Batch via existing `cloud_fit_control.R` pattern.

## Data acquisition + processing

| Source | Current state | Output |
|---|---|---|
| BC-wide spawn index | ✅ `Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv` (31,168 rows, 1951–2025, 8 stock-area codes) | `Data/processed/bc_spawn_by_section_year.csv` |
| Commercial catch (Open Data Portal) | ❌ download in scripts/00 | `Data/processed/bc_catch_by_section_year_gear.csv` |
| CSAS appendix catch | ❌ scrape CSAS SAR PDFs per stock area per year | `Data/processed/bc_catch_csas_appendix.csv` |
| Section-level distance matrices | ❌ compute from spawn-event lat/long (already in spawn file) | `Data/processed/bc_distance_within_stock_area.rds` |
| Predator covariates | partial — sibling repo `~/pacific-herring-predators` has BC-wide species totals; not all section-resolved | `Data/processed/bc_predator_covariates.csv` |
| Environmental covariates (PDO, SST, Chl-a) | ✅ already coastwide in repo | reuse existing |

Catch acquisition has two phases. **Phase 1 (canonical):** DFO Open Data Portal — single download via `httr` or `wget`, parse to the `(year, statistical_area, section, gear, catch_tonnes)` schema. **Phase 2 (cross-check):** CSAS SAR appendix PDFs per stock area per year, reusing the OCR pipeline at `Code/02f_extract_newer_dfo_public_pdfs.R`. Cross-check passes if BC-wide catch sums per stock-area-year agree within tolerance (e.g., ±2%).

Predator covariate assembly is the most uncertain data step. The sibling repo's `HG_vs_coastwide_visualization_proposals.md` documents BC-wide species totals (harbour seal interpolated curve, Steller sea lion, California sea lion, humpback, synoptic-trawl 7-spp, seabirds, salmon escapement). Section-level resolution exists for HG but not all BC sections. Strategy: use section-resolved data where available; aggregate to stock-area-level otherwise; document the resolution per species in `bc_predator_covariates_provenance.md`.

## Hierarchical M1 model specification

State variable: log-biomass per section $s$ per year $y$, denoted $z_{s,y}$.

```
z_{s,y+1} = z_{s,y} + r_{a(s)} - F_{s,y} - P_{s,y} + ε_{s,y}     [process]
y_{s,y}   = q_{e(y)} * exp(z_{s,y}) + obs_error                  [observation]
```

where:
- $a(s)$ is the stock-area of section $s$
- $r_{a}$ is **stock-area-level intrinsic growth** (varies across 5 major + 2 minor + NA = 8 areas; NA pooled with weakly informative prior)
- $F_{s,y}$ is section-year fishing mortality from Open Data catch / posterior biomass (or fixed at zero for closed sections)
- $P_{s,y}$ is predator pressure (M5 only; M1 sets $P=0$, M3 keeps $P=0$ and adds $-β z_{s,y-1}$ density-dependence)
- $ε_{s,y} \sim \text{MVN}(0, Σ)$ with **Σ block-diagonal by stock area** — within-area blocks use the existing distance-decay kernel ($Σ_{ij} = σ_{a}^2 \exp(-d_{ij} / λ_a)$), between-area entries zero
- $q_{e(y)}$ is the two-era catchability split (pre-/post-1988) inherited from HG M1_stier_11

The block-diagonal Σ is the key tractability assumption. Without it the 100×100 covariance has ~5,000 free parameters; with it the parameter count is the sum of within-area pairs across 8 areas, ~250 free. Cross-stock-area synchrony, where present, is estimated post-hoc from posterior latent states (script 11), not via Σ.

**M3 extension:** add a section-level Gompertz density-dependence term $-β_{a(s)} z_{s,y}$ with stock-area-level carrying capacity hyperparameters. Tests intrinsic regulation at coastwide scale.

**M5 extension:** add predator covariates as additive terms in the process equation: $-\sum_p γ_{p,a(s)} X_{p,s,y}$ where $X_{p,s,y}$ is predator-$p$ pressure on section $s$ year $y$ and $γ_{p,a}$ is a stock-area-level effect. Tests whether the HG predator effect generalizes to coastwide variation.

## Output products

Five manuscript figures, plus tables and a section-by-section results page.

- **Fig 1** BC stock-area map with section-level coloring by latest-5-yr trend (decline / flat / increase) — sets the geographic stage
- **Fig 2** Section-level posterior state trajectories faceted by stock area (5 panels for the major areas; minor + NA in supplement) — shows the within-area dynamics
- **Fig 3** Comparative-areas summary — recovery curves anchored to fishery-history events (HG 2002 closure, WCVI partial closures, SoG never closed) — the natural-experiment story
- **Fig 4** BC portfolio metrics — synchrony, CV-ratio, occupancy ratchet — per stock area — tests whether the Stier 2020 portfolio-erosion finding generalizes
- **Fig 5** Driver decomposition — fraction of section-level state variance attributable to fishing, environment, predators, intrinsic dynamics — the main quantitative output

Tables: stock-area parameter estimates (r, σ, distance-decay range, observation error per era, density-dependence β, predator γ); LOO-CV / WAIC across M1, M3, M5.

## Compute strategy

- **Local** (Mac/laptop): data acquisition (00), processing (01–05), all post-fit analysis (09–12). I/O-bound, no heavy compute.
- **Cloud (AWS Batch)**: the three model fits (06, 07, 08). Existing `cloud/` setup handles this — `run_cloud_job.sh`, `cloud_fit_control.R`, `model-farm-manifest.csv`.
- **Estimated wall-clock**: each BC fit ~30–50× the HG M1 fit time. Single-instance estimate: M1 ~5–8 days, M3 ~6–10 days, M5 ~8–14 days. Total ~3–4 weeks cloud time per round.
- **Sequencing**: fit M1 first (baseline); use M1 compilation artifacts and warm-start values for M3 and M5. M3 and M5 can run in parallel after M1 completes.

## Testing

- **Unit tests** (`tests/testthat/test-bc-coastwide.R`): assembly-function tests — panel completeness, year coverage, stock-area code consistency, distance-matrix block-diagonal structure, catch-data join coverage.
- **Integration test**: fit M1 BC-wide on a **2-stock-area subset** (HG + WCVI, ~30 sections). Validate that the HG-section posteriors in this subset fit overlap the existing HG-only M1_stier_11 posteriors at the 80% credible-interval level. Failing this gate means the hierarchical structure is shifting estimates in a way that breaks comparability with the existing baseline.
- **Cross-check**: BC-wide catch sums per stock-area-year must match CSAS SAR totals within ±2% tolerance, in `Output/diagnostics/bc_catch_csas_concordance.md`.
- **Diagnostics**: standard MCMC diagnostics (R̂, ESS, divergent transitions, Pareto-k LOO) per stock area per parameter block.

## Cross-workstream relationships

- **Reads from** `Data/raw/dfo-spawn/`, `Data/raw/dfo-catch/`, sibling repo `~/pacific-herring-predators/data/processed/`, existing `Data/processed/` environmental covariates
- **Writes to** `Data/processed/bc_*` (force-tracked manifests) and `analysis/05_bc_coastwide/output/` (gitignored posterior artifacts)
- **Does not modify** the core M1_stier_11 baseline or any existing HG-only analysis. The talk-firewall rule from `CLAUDE.md` extends symmetrically: this workstream pulls from core, never writes back.
- **Future spec** (out of scope here): BC-wide EWS and resilience re-runs at coastwide n, expected to convert HG's `indeterminate` hysteresis verdict to a determinate one. Documented as follow-on in `analysis/05_bc_coastwide/docs/README.md` after this spec lands.

## Out of scope for this spec

- BC-wide EWS pipeline rerun
- BC-wide resilience / hysteresis rerun
- Bioeconomic extension to BC scale (separate spec for `analysis/03_bioeconomics/`)
- Section-level FSC catch reconstruction (separate provenance question)
- Doherty-style age-structured predator-removal model (covered in `Code/probes/07bj_wcvi_predation_replication_bridge.R` as data-readiness audit)

## Open implementation details (resolved during planning)

These do not change the design but need decisions during the implementation-plan phase:

1. **NA stock-area treatment**: pool with weakly informative prior, or exclude rows entirely? Default: pool, document the count of NA rows in `bc_spawn_provenance.md`.
2. **Era-break year for catchability**: HG M1_stier_11 uses 1988. BC areas may have different survey-method changeover years. Default: per-area era-break parameter, prior centred on 1988.
3. **Predator covariate Mahalanobis-vs-Section join strategy**: which predator-data products at which spatial resolution. Default: documented per species in `bc_predator_covariates_provenance.md` during script 03.
4. **Recovery-event anchor years per stock area**: HG 2002 closure, WCVI 1968/2006 closures, SoG never closed. Default: assemble explicit table in `data-prep/bc_fishery_events.csv` during script 02.

## Success criteria

- All 8 stock areas processed into the model
- All three BC fits (M1, M3, M5) complete with R̂ < 1.01 across major parameters and ESS > 400
- HG-subset M1 posteriors overlap existing M1_stier_11 at 80% CI level (integration-test gate)
- BC catch concordance with CSAS within ±2% per stock-area-year
- 5 manuscript figures rendered at publication quality (pub-figure-pipeline `theme_pub`)
- LOO-CV ranking of M1 / M3 / M5 produced, reported with standard errors

## Implementation plan

To be written next via the `superpowers:writing-plans` skill, decomposing the 13 scripts into TDD-ordered tasks with explicit acceptance criteria and dependencies.
