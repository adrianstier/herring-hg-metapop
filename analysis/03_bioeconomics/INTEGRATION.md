# Integration note

This directory was the standalone `~/herring-bioeconomics` sibling repo
through 2026-05-19, when it was integrated as a nested project inside
`stier-2027-herring-metapopulation/` at the user's direction (consolidation
over the sibling-repo design).

## Separation rule (mirrors `analysis/04_talks/2026-royalsociety/README.md`)

The modelling pipeline (`R/`, `Code/`, `inst/stan/`, `Data/`, `Output/`,
`_targets.R` at the **repo root**) stays the canonical metapopulation analysis
and is unaffected by anything in this folder. Bioeconomics work lives entirely
inside `bioeconomics/` — its own `R/`, `tests/`, `data-raw/`, `_targets.R`,
DESCRIPTION, renv. Biology is imported by `bioeconomics/data-raw/biology/
export_biology_from_metapop.R` as a **read-only, one-directional, provenance-
tagged snapshot** of the promoted `m1_stier_11` baseline.

## Status at integration (2026-05-19)

Tasks 1–5, 7, 8, 9 complete under strict TDD with two-stage review (see
`bioeconomics/docs/` and the repo-root `docs/superpowers/plans/2026-05-19-
herring-bioeconomic-backbone.md`). Tasks 6, 10, 11, 12 remain. Last suite
state: FAIL 0 / SKIP 2 (Comtrade key, FRED key) / PASS 55.

## Canonical research docs (this folder)

- `bioeconomics/docs/2026-05-19-herring-economics-detailed-brief.md`
- `bioeconomics/docs/2026-05-19-kazunoko-demand-context-brief.md`
- `bioeconomics/docs/herring-economics-three-acts.html`

These were briefly mirrored into the repo-root `docs/` and
`analysis/04_talks/2026-royalsociety/Talk_Materials/` during the standalone-repo phase;
those mirrors are removed by the integration commit.
