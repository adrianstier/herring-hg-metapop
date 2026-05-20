# `analysis/00_core_model/` — Core metapopulation manuscript workspace

**Status:** scaffold (no manuscript work in this directory yet).

This directory is the **paper-writing home for the M1–M5 core metapopulation manuscript**. It is intentionally separate from the model-fitting code, which stays at the repo top level per the talk-firewall principle in `CLAUDE.md`.

## Where the actual model lives

- **Fitting scripts:** `Code/03_fit_m*.R` (10 variants of M1–M5)
- **Shared lib:** `R/03_fit_model.R`
- **Stan source:** `inst/stan/`
- **Posteriors + diagnostics:** `Output/posteriors/`, `Output/diagnostics/`
- **Post-fit dossiers:** `Code/probes/07_*.R` (71 diagnostic scripts)
- **Model decision ledger:** `Output/diagnostics/model_decision_ledger.md`
- **Model branch status:** `Output/diagnostics/model_branch_status_table.md`

## What goes here (when manuscript work begins)

```
00_core_model/
├── scripts/        manuscript-specific figure/table scripts (consume Output/diagnostics/)
├── output/         paper-specific figures + supplementary tables (gitignored if large)
└── docs/
    ├── manuscript.qmd       or .tex / .md
    ├── supplement.qmd
    └── response-to-reviewers.md
```

## Conventions

- All paths use `here::here()` — scripts in `scripts/` run from repo root.
- Figures should consume from `Output/figures/` and `Output/diagnostics/` only — never re-run fits here.
- Cross-references to `analysis/01_ews/` and `analysis/02_resilience/` for derivative-section results.
