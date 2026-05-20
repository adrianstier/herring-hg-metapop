# Repo structure — `stier-2027-herring-metapopulation`

Navigation map for the herring metapopulation repo. **For project context, scientific goals, and active sprint state, read `CLAUDE.md` first** — this file is the *where things live* map, not the *what we're doing* map.

## Top-level layout

```
stier-2027-herring-metapopulation/
│
├── README.md                  scientific overview + setup
├── CLAUDE.md                  ⭐ ACTIVE PROJECT STATE — read first
├── REPO_STRUCTURE.md          this file (directory map)
├── AGENTS.md                  agent operational instructions
├── _targets.R                 pipeline orchestrator (drake/targets)
├── DESCRIPTION-equivalents    (.gitignore, .Rprofile, .Rproj, etc.)
│
├── R/                         📚 SHARED LIBRARY — 16 numbered scripts
│   ├── 00_setup.R             theme_pub(), Okabe-Ito, common utilities
│   ├── 01_data_cleaning.R … 12_reversibility_figs.R
│   └── (cloud_fit_control.R, process_oisst_monthly.R)
│
├── Code/                      🔧 CORE DATA PIPELINE + DOSSIERS
│   ├── 00_data_audit.R … 06_*.R       data prep + model fitting pipeline
│   ├── 03_fit_m{1..5}_*.R              individual M1–M5 fit variants
│   ├── 07_*.R                          (~30 dossier/probe scripts — to be triaged
│   │                                    into analysis/probes/ post-talk)
│   └── archive/                        Stier 2020 Ecosphere read-only provenance
│
├── inst/stan/                 Stan model source (.stan compiled to .hpp)
│
├── Data/                      🗄️ raw + processed (gitignored — 15 GB)
│   ├── raw/                   BCO-DMO-bound raw data
│   └── processed/             pipeline outputs consumed by analyses
│
├── Output/                    🗄️ model fits, figures, diagnostics (gitignored — 13 GB)
│   ├── diagnostics/           every analysis writes diagnostics here
│   ├── figures/               manuscript figures (some force-tracked)
│   └── posteriors/            Stan posterior samples
│
├── cloud/                     ☁️ AWS Batch artifacts (gitignored — 12 GB)
│
├── Literature/                📖 PDF library (gitignored — 174 MB)
│
├── docs/                      📝 specs, plans, integration guides
│   ├── superpowers/
│   │   ├── plans/             current sprint plans (May 19+)
│   │   └── specs/             analysis design specs (May 19+)
│   ├── session-logs/          dated session logs (small, tracked)
│   ├── HERRING_TALK_ASSETS.md ⭐ talk single source of truth
│   ├── talk-model-claim-control-sheet.md  language contract for talk
│   ├── herring-non-recovery-hypotheses.md hypothesis bank
│   └── (predator integration, Doherty replication, Stan map, etc.)
│
├── tests/testthat/            unit + integration tests
│
├── analysis/                  🧪 DERIVATIVE WORKSTREAMS (see below)
│
├── talk-usuk-forum-2026/      🎤 Royal Society talk workspace (FIREWALLED)
│
├── logs/                      build/job logs (gitignored)
│
└── _archive/                  🗃️ cold storage — see _archive/README.md
```

## `analysis/<workstream>/` — derivative analyses

Each workstream is **self-contained for its own analysis scripts**, but reads from the shared top-level `R/`, `Data/`, `Output/`. None of them write back into the core pipeline (talk firewall principle applied per workstream).

```
analysis/
├── 00_core_model/             paper-writing home for the M1–M5 manuscript
│   ├── scripts/               (manuscript-specific scripts, e.g., supplementary figures)
│   ├── output/                paper-specific outputs
│   └── docs/                  draft, response-to-reviewers, supplement
│
├── 01_ews/                    Early Warning Signals
│   ├── scripts/               11_ews_*.R (11 scripts, 5,257 lines)
│   ├── output/                EWS-specific diagnostics
│   └── docs/                  (cross-refs to docs/superpowers/specs/.../ews-analysis-design.md)
│
├── 02_resilience/             Reversibility / Hysteresis
│   ├── scripts/               12_reversibility_*.R + phase0 spike (10 scripts)
│   ├── output/                reversibility-specific outputs
│   └── docs/                  (cross-refs to docs/superpowers/specs/.../reversibility-hysteresis-analysis-design.md)
│
├── 03_bioeconomics/           self-contained sub-package
│   ├── _targets.R             sub-package's own pipeline
│   ├── R/                     L0–L3c data layer functions
│   ├── data-raw/, data/       (gitignored CSVs)
│   ├── Output/                (gitignored)
│   ├── renv/                  isolated package environment
│   └── tests/testthat/
│
├── 04_talks/                  POST-TALK: talk-usuk-forum-2026/ will move here
│   └── 2026-royalsociety/     (currently still at top level)
│
└── probes/                    POST-TALK: triage destination for Code/07_*.R
```

## `talk-usuk-forum-2026/` — talk workspace

**FIREWALL RULE (from `CLAUDE.md`):** never import anything from the talk dir back into the modeling pipeline (`R/`, `Code/`, `Data/`, `Output/`). Talk numbers are pulled *from* core analysis, never the reverse. This rule continues after the talk dir moves to `analysis/04_talks/2026-royalsociety/`.

```
talk-usuk-forum-2026/
├── README.md                          firewall + provenance
├── Reference_Papers/                  ~100 source PDFs (10 .pdf.bak kept for OCR tooling)
├── Talk_Materials/
│   ├── Herring_RoyalSociety_..._slide14updated.pptx   🎯 LIVE DECK
│   ├── deck_assets/                   final slide images, videos
│   ├── deck_assets_v36/               prior snapshot
│   ├── deck_build/                    build pipeline (JS+TS+Py, slides_html, photos)
│   ├── archive/presentation-versions/ 57 pptx version snapshots, 3 GB (POST-TALK cold-storage)
│   ├── figs/                          working figure scratch
│   ├── NARRATIVE_*.md                 narrative drafts
│   ├── slide_asset_map.md             slide → asset crosswalk
│   └── (various .md status/build docs)
├── Trip_Dossier/                      private logistics (gitignored)
└── Attendee_Dossier/                  confidential — gitignored
```

## Where to find common things

| Looking for | Path |
|---|---|
| **Talk live deck** | `talk-usuk-forum-2026/Talk_Materials/Herring_RoyalSociety_Stier_2026_v3.6_REVISED_slide14updated.pptx` |
| **Active model status** | `Output/diagnostics/model_decision_ledger.md`, `model_branch_status_table.md` |
| **Talk language contract** | `docs/talk-model-claim-control-sheet.md` |
| **Talk asset index** | `docs/HERRING_TALK_ASSETS.md` |
| **EWS scripts** | `analysis/01_ews/scripts/11_ews_*.R` |
| **EWS spec** | `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md` |
| **Resilience scripts** | `analysis/02_resilience/scripts/12_reversibility_*.R` |
| **Resilience figures** | `Output/figures/reversibility_*.{pdf,png}` |
| **Bioeconomics sub-package** | `analysis/03_bioeconomics/` |
| **2020 Ecosphere paper code** | `Code/archive/stier-2020-ecosphere-herring/INDEX.md` |
| **Predator integration** | `docs/predator-repo-integration-guide.md` (sibling repo: `~/pacific-herring-predators`) |
| **Sprint plans** | `docs/superpowers/plans/` |
| **Repo organization plan** | `docs/superpowers/plans/2026-05-20-repo-organization.md` |
| **What got archived and when** | `_archive/README.md` |

## Path conventions

- All R scripts use `here::here()` for paths. Project root is detected via `_targets.R` or `.here` marker.
- Shell scripts assume `pwd == <repo root>`.
- Python scripts in `talk-usuk-forum-2026/Talk_Materials/deck_build/` reference `Data/`, `Output/` as relative paths — they must be run from the repo root.
- `_targets.R` is the canonical pipeline driver. `tar_visnetwork()` shows the live DAG.

## Sibling repo

The herring modeling repo depends on the predator-data repo:

- **`~/pacific-herring-predators/`** (GitHub: `stier-lab/pacific-herring-predators`)
- Imported via `Code/02c_integrate_hg_predator_repo_products.R`
- See `docs/predator-repo-integration-guide.md` for the full crosswalk

## Recent reorganization

The 2026-05-20 reorg moved derivative workstreams into `analysis/<workstream>/`. See `docs/superpowers/plans/2026-05-20-repo-organization.md` for the migration plan and which phases are pending (Phase F–I: post-talk talk-dir move, `Code/07_*.R` triage, cold-storage of talk pptx history, doc path updates).
