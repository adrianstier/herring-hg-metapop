# Repo Organization Migration Plan

**Date:** 2026-05-20
**Goal:** Reorganize the 44 GB repo so the four workstreams (core model, EWS, resilience, talks) each have a self-contained `analysis/<workstream>/` home, while preserving the talk-firewall rule and the shared modeling pipeline at the top level.

## Decisions locked

1. **Research compendium pattern.** One repo, `analysis/<workstream>/` for derivative analyses; shared infrastructure (`R/`, `Code/` core data pipeline, `Data/`, `Output/`, `inst/stan/`, `_targets.R`) stays top-level.
2. **Talk firewall preserved.** `analysis/04_talks/` is read-only on the core pipeline (per `CLAUDE.md`). The firewall rule moves with the directory.
3. **Heavy dirs (`Data/` 15 GB, `cloud/` 12 GB, `Output/` 13 GB) stay on disk, gitignored.** No data movement in this pass.
4. **Bioeconomics sub-package** moves wholesale into `analysis/03_bioeconomics/`.

## Target structure

```
herring-metapopulation/
├── R/                       shared function library (16 numbered scripts, 6,462 lines)
├── Code/                    core data pipeline + dossier scripts (00–06 + 07_*) — STAYS
│   └── archive/             Stier 2020 Ecosphere — read-only, stays
├── Data/                    raw + processed (gitignored; only manifests tracked)
├── Output/                  model fits, figures, diagnostics (gitignored)
├── inst/stan/               compiled Stan models (gitignored .hpp)
├── _targets.R               pipeline orchestrator
├── docs/                    specs, plans, talk control docs
├── Literature/              PDF library (gitignored)
├── tests/                   testthat
├── cloud/                   AWS batch (gitignored)
└── analysis/                NEW
    ├── 00_core_model/       paper-writing for the M1–M5 model (NOT the fits — those stay in Code/+Output/)
    ├── 01_ews/              early warning workstream
    │   └── scripts/         11 scripts moved from Code/11_ews_*.R
    ├── 02_resilience/       reversibility/hysteresis workstream
    │   └── scripts/         9 scripts moved from Code/12_reversibility_*.R + phase0 spike
    ├── 03_bioeconomics/     existing sub-package, moved wholesale
    │   └── (its own _targets.R, R/, Output/, renv/, tests/)
    ├── 04_talks/
    │   └── 2026-royalsociety/   POST-TALK move of talk-usuk-forum-2026/
    └── probes/              triage destination for Code/07_*.R dossier scripts (POST-TALK)
```

## Why the core model stays in `Code/` (not `analysis/00_core_model/`)

The compendium model in the user's first answer showed `00_core_model/` for "M1–M5 fits." But CLAUDE.md is explicit: **the modeling pipeline lives at the top level (`R/`, `Code/`, `Data/`, `Output/`, `inst/stan/`, `_targets.R`)** and is firewalled from the talk. Splitting the fitting scripts (`Code/03_fit_m*.R`) from the shared lib (`R/03_fit_model.R`) and the Stan models (`inst/stan/`) would either break that firewall or create three places to look for the same thing.

`analysis/00_core_model/` becomes the **paper-writing home for the core metapopulation manuscript** (drafts, figures specific to the paper, supplements, response-to-reviewers), parallel to how `analysis/01_ews/` holds EWS-specific scripts that consume core outputs.

## Path-coupling audit (executed 2026-05-20)

| Script set | Path style | Move-safe? |
|---|---|---|
| `Code/11_ews_*.R` (11 files) | `here::here("R", ...)` and `here::here("Output", ...)` | ✅ yes |
| `Code/12_reversibility_*.R` (9 files) | bare `source("R/12_reversibility.R")` (cwd-dependent) | ⚠️ yes if run from project root; **convert to `here::here()` during move** |
| `Code/12_reversibility_figs_render.R` | `here::here()` throughout | ✅ yes |
| `R/12_reversibility_figs.R` | `here::here("Output", ...)` | ✅ yes, doesn't move anyway |
| `bioeconomics/` | self-contained sub-package | ✅ yes (move whole tree) |
| `talk-usuk-forum-2026/Talk_Materials/deck_build/*.py,*.js` | references `Data/processed/`, `Output/diagnostics/` (relative from repo root) | ⚠️ post-talk — paths assume repo root cwd |

## Migration phases

### Phase A — Scaffold ✅ DONE
- `analysis/{00_core_model,01_ews,02_resilience,03_bioeconomics,04_talks/2026-royalsociety,probes}/` created
- `analysis/01_ews/{scripts,output,docs}/` and `analysis/02_resilience/{scripts,output,docs}/` populated

### Phase B — .gitignore updates (zero risk)
Add to `.gitignore`:
```
# Stale snapshots awaiting confirmed deletion
talk-usuk-forum-2026/Talk_Materials/_stale/

# Per-workstream analysis outputs (regenerable)
analysis/*/output/

# Bioeconomics sub-package internals once moved
analysis/03_bioeconomics/Output/
analysis/03_bioeconomics/renv/library/
```

### Phase C — Move EWS scripts (low risk, fully reversible)
```bash
git mv Code/11_ews_00_data_layers.R         analysis/01_ews/scripts/
git mv Code/11_ews_01_generic_aggregate.R   analysis/01_ews/scripts/
git mv Code/11_ews_02_spatial_synchrony.R   analysis/01_ews/scripts/
git mv Code/11_ews_03_covariance_eigen.R    analysis/01_ews/scripts/
git mv Code/11_ews_04_candidate_transitions.R analysis/01_ews/scripts/
git mv Code/11_ews_05_surrogate_significance.R analysis/01_ews/scripts/
git mv Code/11_ews_06_sensitivity_grid.R    analysis/01_ews/scripts/
git mv Code/11_ews_07_survey_artifact_audit.R analysis/01_ews/scripts/
git mv Code/11_ews_08_controls_power.R      analysis/01_ews/scripts/
git mv Code/11_ews_09_lead_time_matrix.R    analysis/01_ews/scripts/
git mv Code/11_ews_10_synthesis.R           analysis/01_ews/scripts/
```
Verify with `Rscript -e 'source("analysis/01_ews/scripts/11_ews_00_data_layers.R")'` from repo root.

Create `analysis/01_ews/docs/README.md` linking to `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md` and `docs/superpowers/plans/2026-05-19-herring-ews-analysis.md`.

### Phase D — Move resilience scripts (low risk, requires 1-line edits)
```bash
git mv Code/12_reversibility_01_driver_axis.R       analysis/02_resilience/scripts/
git mv Code/12_reversibility_02_effective_driver.R  analysis/02_resilience/scripts/
git mv Code/12_reversibility_03_edm.R               analysis/02_resilience/scripts/
git mv Code/12_reversibility_04_ccm.R               analysis/02_resilience/scripts/
git mv Code/12_reversibility_05_attractor_regime.R  analysis/02_resilience/scripts/
git mv Code/12_reversibility_06_driver_loop.R       analysis/02_resilience/scripts/
git mv Code/12_reversibility_07_controls.R          analysis/02_resilience/scripts/
git mv Code/12_reversibility_10_discrimination_synthesis.R analysis/02_resilience/scripts/
git mv Code/12_reversibility_figs_render.R          analysis/02_resilience/scripts/
git mv Code/phase0_reversibility_hysteresis_spike.R analysis/02_resilience/scripts/
```
**Then convert bare `source("R/12_reversibility.R")` → `source(here::here("R", "12_reversibility.R"))` in each script** (8 files affected). Sed pattern:
```bash
sed -i.bak 's|source("R/12_reversibility.R")|source(here::here("R", "12_reversibility.R"))|g' analysis/02_resilience/scripts/12_reversibility_*.R
```

Verify with `Rscript -e 'source("analysis/02_resilience/scripts/12_reversibility_figs_render.R")'`.

### Phase E — Move bioeconomics sub-package (medium risk)
```bash
git mv bioeconomics/ analysis/03_bioeconomics/
```
Update any cross-references in:
- `_targets.R` (if it references `bioeconomics/...`)
- `docs/superpowers/plans/2026-05-19-herring-bioeconomic-backbone.md`
- `docs/superpowers/specs/2026-05-19-herring-bioeconomic-analysis-design.md`

The sub-package's internal `_targets.R` and `renv/` should be unaffected (self-contained).

### Phase F — POST-TALK — Move talk-usuk-forum-2026 (HIGH risk pre-talk; safe after)
```bash
git mv talk-usuk-forum-2026/ analysis/04_talks/2026-royalsociety/
```
Update:
- `.gitignore` lines 70–86, 96–98 (replace `talk-usuk-forum-2026/` → `analysis/04_talks/2026-royalsociety/`)
- `CLAUDE.md` references (talk firewall rule still applies but with new path)
- `docs/HERRING_TALK_ASSETS.md` paths
- All deck_build Python/JS scripts that reference `talk-usuk-forum-2026/Talk_Materials/...` from outside

**Do not execute until talk delivered.**

### Phase G — POST-TALK — Triage Code/07_*.R dossier scripts (no risk if read-only triage)
26+ scripts spanning `07a` through `07bk`+. Initial classification (needs script-by-script inspection):
- `07ax_stier_signal_persistence_summary.R`, `07aw_promoted_baseline_evidence_package.R` → likely **core model**, leave in `Code/`
- `07ae_predator_data_feasibility_audit.R`, `07bb_predator_spatial_exposure_prototype.R`, `07bf_lead_spawn_location_predator_proximity.R` → likely **predator/core**, leave in `Code/`
- `07ai_fishing_closure_response.R`, `07aj_pdo_window_sensitivity.R` → could be EWS or resilience context
- Most `07a*` "section dossier" probes → `analysis/probes/section-dossiers/`

Workflow: read first 30 lines of each script's header, classify by what `R/` lib it sources and what `Output/` files it writes. Then move in batches.

### Phase H — POST-TALK — Cold-storage talk archive (3 GB reclaim)
`analysis/04_talks/2026-royalsociety/Talk_Materials/archive/presentation-versions/` is 57 pptx files × ~83 MB = 3 GB. After confirming the live deck is finalized:
```bash
mv analysis/04_talks/2026-royalsociety/Talk_Materials/archive/presentation-versions/ ~/Dropbox/cold-storage/herring-talk-2026-pptx-history/
```
Replace with a manifest file documenting the move.

### Phase I — POST-TALK — Update docs to new paths
- `CLAUDE.md` — top-level rule still names `R/`, `Code/`, `Data/`, `Output/`; add a line that derivative workstreams live in `analysis/`
- `README.md` — section diagram showing the new layout
- `docs/HERRING_TALK_ASSETS.md` — update talk paths
- `docs/superpowers/plans/*` — update path references where they cite `Code/11_ews_*` or `Code/12_reversibility_*`

## What we are NOT doing in this pass
- Splitting into multiple repos
- Moving `Data/` or `cloud/` off the working disk
- Restructuring `Output/` to be per-workstream
- Deleting any pptx files (only moved into `_stale/`)
- Deleting the 3 GB `archive/presentation-versions/` (Phase H, post-talk)
- Touching `Code/07_*.R` dossier scripts (Phase G, post-talk)
- Touching `R/` shared lib

## Rollback

Every `git mv` is reversible. Each phase commits independently; revert by `git revert <phase commit>` or `git mv` back.

## Sequencing recommendation

Execute Phase A (done), Phase B (gitignore), Phase C (EWS scripts), Phase D (resilience scripts), Phase E (bioeconomics) **today** — all are safe and don't touch the talk dir or live build path.

Hold Phases F–I **until after the talk delivers**.
