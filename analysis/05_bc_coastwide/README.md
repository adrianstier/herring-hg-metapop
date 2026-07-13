# `analysis/05_bc_coastwide/` — BC-coastwide hierarchical metapopulation

Extension of the section-level M1 herring metapopulation analysis from Haida Gwaii (11 sections) to all 8 DFO stock-area codes across British Columbia (~100 sections). Fits hierarchical M1 (baseline), M3 (Gompertz density-dependence), and M5 (predator-mediated).

## Layout

```
05_bc_coastwide/
├── scripts/
│   ├── 00_data_acquisition.R         download Open Data catch + refresh spawn
│   ├── 01_assemble_bc_spawn.R        filter 31k-row CSV → tidy panel
│   ├── 02_assemble_bc_catch.R        Open Data + CSAS appendix merge
│   ├── 03_assemble_bc_predator_covs.R pull from sibling repo
│   ├── 04_assemble_distance_matrix.R within-stock-area distance matrices
│   ├── 05_prepare_stan_data.R        Stan data list
│   ├── 06_fit_m1_bc.R                cloud — M1 baseline
│   ├── 07_fit_m3_bc.R                cloud — M3
│   ├── 08_fit_m5_bc.R                cloud — M5
│   ├── 09_diagnostics.R              MCMC + PPC
│   ├── 10_comparative_areas.R        HG vs SoG vs WCVI
│   ├── 11_bc_portfolio.R             coastwide portfolio metrics
│   └── 12_manuscript_figures.R       5 figures + tables
├── stan/                             3 Stan models (separate from inst/stan/)
├── output/                           gitignored posterior artifacts
└── docs/                             cross-refs to spec + plan
```

## Specs and plans

- Design spec: [`docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md`](../../docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md)
- Implementation plan: [`docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md`](../../docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md)

## Talk firewall

This workstream reads from the core pipeline (`R/`, `Data/`, `Output/`, sibling predator repo) and writes only to `Data/processed/bc_*` (force-tracked manifests) and `analysis/05_bc_coastwide/output/` (gitignored). Does not modify the core M1_stier_11 baseline.

## Outputs (populated as pipeline runs)

| File | Description | Produced by |
|---|---|---|
| `Data/processed/bc_spawn_by_section_year.csv` | Section-year spawn panel (8 stock areas, 1951–2025) | `scripts/01` |
| `Data/raw/dfo-catch/bc_commercial_catch_OPEN_DATA.csv` | Raw DFO Open Data Portal catch | `scripts/00` |
| `Data/processed/bc_catch_by_section_year_gear.csv` | Tidy section-year-gear catch panel | `scripts/02` |
| `Data/processed/bc_catch_csas_appendix.csv` | CSAS SAR appendix catch (cross-check) | `scripts/02b` |
| `Output/diagnostics/bc_catch_csas_concordance.md` | Open Data ↔ CSAS concordance report | `scripts/02b` |
| `Data/processed/bc_predator_covariates.csv` | Year-by-stock-area predator covariates | `scripts/03` |
| `Data/processed/bc_predator_covariates_provenance.md` | Per-species spatial-resolution notes | `scripts/03` |
| `Data/processed/bc_distance_within_stock_area.rds` | Within-area distance matrices | `scripts/04` |
| `Data/processed/bc_fishery_events.csv` | Anchor years for closures per stock area | committed seed |
| `Data/processed/bc_stan_data.rds` | Stan data list for M1/M3/M5 | `scripts/05` |
| `analysis/05_bc_coastwide/output/m{1,3,5}_bc_fit.rds` | Production fits (cloud) | `scripts/06`–`08` |
| `analysis/05_bc_coastwide/output/m1_bc_subset_HG_WCVI_fit.rds` | Integration-test subset fit | `scripts/06` |
| `Output/diagnostics/bc_coastwide_mcmc_diagnostics.md` | R̂ / ESS / divergent transitions | `scripts/09` |
| `Output/diagnostics/bc_coastwide_loo_table.csv` | LOO-CV across M1/M3/M5 | `scripts/09` |
| `Output/diagnostics/bc_comparative_areas.{csv,md}` | Recovery curves per stock area | `scripts/10` |
| `Output/diagnostics/bc_portfolio_metrics.{csv,md}` | Synchrony / CV-ratio / occupancy | `scripts/11` |
| `Output/figures/bc_coastwide_fig{1..5}.{pdf,png}` | 5 manuscript figures | `scripts/12` |
| `Output/figures/legends/bc_coastwide_fig{1..5}_legend.md` | Companion legends | `scripts/12` |

## Running the pipeline

```bash
# Phase 1: data acquisition (local)
Rscript analysis/05_bc_coastwide/scripts/00_data_acquisition.R
Rscript analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R
Rscript analysis/05_bc_coastwide/scripts/02_assemble_bc_catch.R
Rscript analysis/05_bc_coastwide/scripts/02b_csas_appendix_crosscheck.R

# Phase 2: covariates + distance + Stan data (local)
Rscript analysis/05_bc_coastwide/scripts/03_assemble_bc_predator_covs.R
Rscript analysis/05_bc_coastwide/scripts/04_assemble_distance_matrix.R
Rscript analysis/05_bc_coastwide/scripts/05_prepare_stan_data.R

# Phase 3: integration-test subset locally (smoke)
HERRING_SMOKE=1 SUBSET=HG_WCVI Rscript analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'

# Phase 4: full BC cloud fits (AWS Batch — see cloud/run_cloud_job.sh)
SUBSET=ALL bash cloud/run_cloud_job.sh analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R --name m1_bc_all
SUBSET=ALL bash cloud/run_cloud_job.sh analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R --name m3_bc_all
SUBSET=ALL bash cloud/run_cloud_job.sh analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R --name m5_bc_all

# Phase 5: pull fits + post-fit analysis (local, after cloud completes)
bash cloud/promote_cloud_results.sh m1_bc_all
bash cloud/promote_cloud_results.sh m3_bc_all
bash cloud/promote_cloud_results.sh m5_bc_all
Rscript analysis/05_bc_coastwide/scripts/09_diagnostics.R
Rscript analysis/05_bc_coastwide/scripts/10_comparative_areas.R
Rscript analysis/05_bc_coastwide/scripts/11_bc_portfolio.R
Rscript analysis/05_bc_coastwide/scripts/12_manuscript_figures.R
```
