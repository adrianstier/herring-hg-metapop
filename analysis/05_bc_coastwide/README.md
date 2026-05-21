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
