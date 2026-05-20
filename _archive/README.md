# `_archive/` — cold storage for obsolete work products

This directory holds files that are **no longer part of the active project** but are retained for provenance / reference / future re-use. Nothing in here is read by the modeling pipeline, the talk build, or any active script.

## Layout

Each cleanup batch is dated:

```
_archive/
└── YYYY-MM-DD/
    ├── README.md              what was archived and why
    └── <category>/            files moved this batch
```

## How to use this directory

- **Read-only by convention.** If you need a file again, copy it back out — don't edit it in place.
- **Tracked vs gitignored:** small text files (`.md`, `.R`, `.csv` < ~1 MB) are tracked. Heavy binaries (`.pptx`, `.png.bak`, `.pdf.bak`, videos) are gitignored — they live on disk only. See `.gitignore` for the patterns.
- **Don't delete from here.** Anything not worth keeping should go to your trash, not into `_archive/`. This directory is the "kept but inactive" tier.
- **If a file is reactivated** (you start using it again), `git mv` it back to its working location.

## What is NOT here

- `Code/archive/stier-2020-ecosphere-herring/` — the 2020 Ecosphere paper code lives there separately, per the project CLAUDE.md (read-only provenance, never part of live pipeline).
- `analysis/04_talks/.../archive/presentation-versions/` — talk pptx version history; will be promoted into `_archive/` after the Royal Society talk delivers (Phase H of the repo organization plan).

## Index of batches

| Batch | Description | Notes |
|---|---|---|
| `2026-05-20/` | Reorganization sweep: stale planning docs from the May 8–12 sprint, top-level morning reports, talk image `.bak` files, and stale top-level pptx | Companion to `docs/superpowers/plans/2026-05-20-repo-organization.md` |
| `2026-05-21/` | Final cleanup: 10 Reference_Papers PDF `.bak` files, prior `deck_assets_v36/` snapshot, repo-wide `.DS_Store` purge, scaffold `.gitkeep` files | Closes the 2026-05-20 reorganization plan |
