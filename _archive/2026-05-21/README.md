# Archive batch: 2026-05-21 — final reorganization cleanup

Second batch in the reorganization sequence; companion to `docs/superpowers/plans/2026-05-20-repo-organization.md`. Covers items that were intentionally deferred from the 2026-05-20 batch or surfaced during final cleanup.

## Categories

### `reference-paper-bak/` — 10 files, ~35 MB, **gitignored**
PDF processing backups in `analysis/04_talks/2026-royalsociety/Reference_Papers/`. Two flavors:
- `.pdf.imgzip.bak` — pre-image-extraction PDF backups (9 files)
- `.pdf.preocr.bak` — pre-OCR PDF backup (1 file: Pikitch_2014)

Originally retained "may be needed by PDF tooling" but the corresponding processed PDFs are intact and these are reproducible from source. Kept here as cold storage in case re-OCR or re-extraction is wanted.

### `deck-assets-v36/` — 12 files, ~3.4 MB, **gitignored**
Prior snapshot of the talk's slide assets directory. The active `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_assets/` supersedes it. `deck_assets_v35/` was empty and was deleted outright.

## Cleanup actions also taken in this batch (not file moves, recorded for traceability)

- Removed all `.DS_Store` files repo-wide (macOS metadata, was already gitignored)
- Removed empty `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_assets_v35/`
- Added `.gitkeep` to empty `analysis/<workstream>/{output,docs,scripts}/` scaffold dirs
- Cleaned up lingering historical text references in active READMEs

## Restoring a file

```bash
mv _archive/2026-05-21/reference-paper-bak/<file>.pdf.bak analysis/04_talks/2026-royalsociety/Reference_Papers/
```
