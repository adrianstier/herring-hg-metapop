# Deck build pipeline — Royal Society herring talk

Three scripts produce `Herring_RoyalSociety_Stier_2026_clean.pptx`. Run them in
this order whenever the figures, content, or layout change.

## ⭐ Status & figure policy (READ FIRST — decided 2026-05-19, Adrian)

**This Python pipeline is the single canonical source for ALL talk figures —
current and future.** Every talk slide figure (existing or newly added,
including Q&A / backup slides) MUST be produced as a **matplotlib chart in
`redesign_figs.py`** and run through the **`preprocess_figures.py` chrome
bake**, matching the Design contract below. Do **not** introduce a different
charting style, a parallel exporter, or native-PowerPoint chart objects for
the talk. Aesthetic consistency across the deck is the goal.

**R / ggplot2 is the PAPER & ANALYSIS track — not the talk.**
`Code/07cz_deck_figure_reexport.R` and the R figures in `Output/figures/` are
**preserved and kept** for the manuscript / analysis worked on in parallel.
They are **not deleted** and **not** the talk figure source. The talk pulls
*numbers/data* from the analysis (via `Output/diagnostics/*.csv` etc.), never
R-rendered images. (This mirrors the repo `talk-usuk-forum-2026/` firewall:
talk ← data from analysis; never the reverse.)

If you (a future Claude/Codex/Adrian session) are asked to add or change a talk
slide figure: use this pipeline and the [Design contract](#design-contract-encoded-in-both-preprocess_figurespy-and-build_pptx_nativejs)
+ the [Adding a new slide / figure](#adding-a-new-slide--figure-match-these-aesthetics)
recipe below. Keep R for the paper.

## Pipeline

```
redesign_figs.py        → writes raw figures to deck_assets/_originals/
preprocess_figures.py   → bakes chrome (masthead + title + amber takeaway + provenance)
                          and writes the slide-ready PNGs to deck_assets/
build_pptx_native.js    → assembles the .pptx using those PNGs and a few native slides
```

Outputs land at `talk-usuk-forum-2026/Talk_Materials/Herring_RoyalSociety_Stier_2026_clean.pptx`.

## Run order

```sh
# 1. (optional) re-render the data figures
python3 redesign_figs.py

# 2. bake the deck chrome onto every figure PNG
python3 preprocess_figures.py

# 3. assemble the .pptx
node build_pptx_native.js
```

`node build_pptx_native.js` needs `pptxgenjs` (`npm install pptxgenjs` once).
`redesign_figs.py` / `preprocess_figures.py` need `matplotlib pandas pillow`.
**Fonts are portable (fixed 2026-05-19):** both scripts resolve fonts at
runtime — Liberation Serif + DejaVu Sans Mono on the Linux sandbox, falling
back to **Georgia + Courier New on macOS** (Georgia is also the deck's native
HEAD font, so the bake stays visually consistent on either platform). Paths
are derived from the script location (`__file__`), so the pipeline runs from
any checkout — no hardcoded absolute paths.

## What lives where

| File | Role |
|---|---|
| `redesign_figs.py` | Python/matplotlib data figures for S8, S9, S10, S12. Renders 3840×1500 unframed PNGs into `deck_assets/_originals/`. |
| `preprocess_figures.py` | Pillow chrome bake. Top band = rust mono kicker + serif title. Bottom band = amber left-rule + takeaway + mono provenance. Output 3840×2160 → `deck_assets/`. |
| `build_pptx_native.js` | `pptxgenjs` deck assembler. S1–S4, S11, S13–S14 are native pptx text. S5–S10, S12, S16 (DFO backup) are full-bleed images from the baked PNGs. |
| `deck_assets/` | Slide-ready PNGs the build script ingests. |
| `deck_assets/_originals/` | Untouched figure sources. Re-baking always starts from here. |
| `build_pptx.js` | Legacy builder, kept for provenance. Do not run. |

## Design contract (encoded in both `preprocess_figures.py` and `build_pptx_native.js`)

- Canvas 13.333 × 7.5 in @ 3840 × 2160 px, sRGB
- Dark `#0e0e0e` for narrative slides, light `#fbfaf7` only for S4
- Track colours: ecological = kelp `#8aa074`, cultural/people = plum `#b685a8`,
  economic = rust `#d9714f`, governance = marine `#6e9bc4`,
  management window/takeaway = amber `#cfa055`
- Masthead kicker: `COUPLED TIPPING POINTS | PACIFIC HERRING | HAIDA GWAII` in
  DejaVu Sans Mono / rust on every content slide
- Title: Liberation Serif Bold + optional Bold Italic rust accent
- Takeaway: amber left-rule + Liberation Serif italic
- Provenance footer: DejaVu Sans Mono in `--ink-soft`

The .pptx renders pixel-identical on any machine because figure slides are
baked images (no live font substitution). S1–S4, S11, S13–S15 are native text
boxes using venue-safe Georgia / Calibri / Consolas.

## Slide map

1. Title (native, photo + scrim)
2. Shore comes alive (native, video poster + amber tag)
3. People & fish (native, photo + scrim)
4. Baseline, measured (native, light background)
5. Two collapses — biomass time series (baked image)
6. Ocean productivity — PDO effect (baked image)
7. Fishing pressure — scale mismatch (baked image)
8. **Population growth collapsed — diverging bars** (baked image)
9. **The portfolio eroded — before/after** (baked image)
10. **The predators came back — stacked area** (baked image)
11. A system in a new state (native, 3-column)
12. **Four layers, four clocks — timeline** (baked image)
13. Three transferable lessons (native)
14. Close (native, photo + scrim)
15. Q&A backup divider (native)
16. DFO spawning biomass (baked image, backup)

Slides marked **bold** were redesigned with new visualizations.

## When you need to change something

- **Slide content / typography / titles** → edit `build_pptx_native.js`
- **Per-figure takeaway, provenance, or chrome** → edit the JOBS list at the
  bottom of `preprocess_figures.py`
- **Data figure itself** → edit the relevant `sX_*` function in
  `redesign_figs.py`, then re-run the full pipeline
- **Source data** → `redesign_figs.py` reads tidy CSVs directly from
  `Output/diagnostics/*.csv` and `Data/processed/predators/*.csv` (produced by
  the R / analysis pipeline). The R figure script
  `Code/07cz_deck_figure_reexport.R` is **paper/analysis track only** — kept
  for the manuscript, not run for the talk, not deleted. Do not wire it back
  into this pipeline.

## Adding a new slide / figure (match these aesthetics)

For any **new** talk figure — including the extra Q&A / backup slides — follow
this so the deck stays visually consistent. Never hand-make a one-off chart in
a different style.

1. **Chart** — add a `def sNN_<name>():` (or `sbN_<name>()` for backup) in
   `redesign_figs.py`. Reuse the module's palette constants (`BG`, `INK`,
   `RUST`, `MARINE`, `KELP`, `PLUM`, `AMBER`, `INK_SOFT`) and the resolved
   `SERIF*/MONO` fonts — do not introduce new colours or fonts. Honour the
   §3 track-colour contract (eco=kelp, cultural=plum, economic=rust,
   governance=marine, window=amber). Render at the content-zone size
   (`W_IN`×`H_IN` @ `DPI` → 3840×1500, **no baked title/takeaway** — the bake
   adds those). Save to `OUT / "NN_<name>.png"` (i.e. `deck_assets/_originals/`).
2. **Chrome** — add a `dict(src="NN_<name>.png", title_plain=…,
   title_italic=…, takeaway=…, provenance=…)` to the `JOBS` list in
   `preprocess_figures.py`. Takeaway = one-line italic; provenance = exact
   data source + claim-control guardrail wording.
3. **Slide** — add the slide in `build_pptx_native.js` as a full-bleed image
   of the baked `deck_assets/NN_<name>.png` (mirror an existing S5–S10 block).
4. **Build & verify** — run all three stages, then eyeball the baked PNG at
   100%: claim/number guardrails intact (`docs/talk-model-claim-control-sheet.md`,
   `numbers_provenance.md`), text legible from the back row, glyphs render
   (Georgia lacks `→`/some Unicode — use ASCII `->` or a covered glyph).
5. **Record** — update the Slide map in this README, `slide_asset_map.md`,
   and the Talk Build State in `docs/HERRING_TALK_ASSETS.md`.

## Edit history (high level)

- 2026-05-18 — original build, native-text overlay on figures (caused text/axis
  collisions on every figure slide)
- 2026-05-18 — chrome refactor: removed native overlays, baked chrome into PNGs
- 2026-05-19 — three design-critic rounds: title rebreak, takeaway strips,
  S9 plum→kelp, S11 chip parallelism, S14 split close
- 2026-05-19 — redesigned S8/S9/S10/S12 with matplotlib (replaced spaghetti
  slope chart, noisy time series, two-panel mismatch, and native table)
- 2026-05-19 — portability fix: removed hardcoded `/sessions/.../mnt/` sandbox
  paths (now derived from `__file__`); fonts resolve Liberation→Georgia/Courier
  so the pipeline runs on macOS as well as the Linux sandbox
- 2026-05-19 — **policy decided (Adrian):** this matplotlib + baked-chrome
  pipeline is canonical for ALL talk figures incl. future Q&A/backup slides;
  R/ggplot2 is the parallel paper/analysis track, preserved, not the talk
  source (see "Status & figure policy" at top)
