# Deck Design System — Royal Society Herring Talk

Created: 2026-05-18. **The build contract for the .pptx.** Everything that goes
on a slide obeys this file: canvas, type scale, palette, figure-placement
zones, the no-stretch rule, the R-figure re-export spec, and the per-slide
figure→zone→source map. Pairs with the 14-slide architecture
(`talk_architecture_{1,2,3}.html`), `slide_asset_map.md`, and the
claim-control sheet. If a slide conflicts with this file, fix the slide.

---

## 0. Architecture decision — image-rendered deck (read first)

**The .pptx is a sequence of full-bleed 16:9 images, one per slide. No live
text boxes, no live fonts.** Speaker notes go in the PowerPoint notes field
(plain text — that's the only live text, and notes don't render on screen).

Why (from `~/.claude/CLAUDE.md` failure modes):

1. **Font substitution is the #1 deck risk.** The deck's typefaces (Crimson
   Pro, IBM Plex Sans/Mono) are **not** installed on the Royal Society
   presentation PC. Live text boxes would silently re-flow into a substitute
   font and break every layout. Baking each slide to an image makes the deck
   pixel-identical on any machine.
2. **Zero stretch by construction.** Every slide image is authored at exactly
   the canvas aspect ratio, so PowerPoint places it edge-to-edge with no
   distortion. Figures never touch a PowerPoint resize handle.
3. **Pixel-faithful to the established design** (build1_spine.html and the
   built slide artifacts) — no re-creation drift.

Tradeoff accepted: slides are not editable in PowerPoint. Mitigation: the
HTML/R sources are the editable masters and are version-controlled; re-render
to regenerate. (Same tradeoff `~/.claude/CLAUDE.md` documents for Marp.)

A `.key`/editable variant is out of scope for the 20 May deadline.

---

## 1. Canvas

| Property | Value |
|---|---|
| Aspect | 16:9, **13.333 × 7.5 in** (true widescreen — matches `~/templates`) |
| Slide image | **3840 × 2160 px** (= 13.333×7.5 in @ 288 dpi; the `save_lecture_figure()` native size) |
| Safe margin | 5% inset (≈ 0.67 in / 192 px) — nothing critical outside it; venue projector may overscan |
| Background | light `#fbfaf7` (warm white) for content; **dark `#0e0e0e` for title (S1), close (S14), and the decoupling payoff (S12)** — the dark/light "sandwich" |
| Color profile | sRGB on export (`--force-color-profile=srgb`) |

---

## 2. Type scale (authored in source; baked to image)

Fonts: **Crimson Pro** (serif, headers/quotes), **IBM Plex Sans** (body),
**IBM Plex Mono** (masthead, labels, provenance). Loaded via Google Fonts in
the HTML sources; baked into the rendered image so the venue PC never needs
them.

Sizes are specified at the 13.333-in canvas (px @ 288 dpi in parentheses):

| Element | Size | Font | Notes |
|---|---|---|---|
| Slide title (h1) | 38–44 pt (152–176 px) | Crimson Pro 600 | one line preferred; italic rust accent clause allowed |
| Thesis / deck line | 22–26 pt (88–104 px) | Crimson Pro 400 | ≤ 70 ch, `--ink-soft` |
| Section / column head | 20–24 pt (80–96 px) | Crimson Pro 600 | |
| Body / column text | 16–18 pt (64–72 px) | IBM Plex Sans 400 | left-aligned, never centered |
| Big stat callout | 60–96 pt (240–384 px) | Crimson Pro 700 | for S7 (4% / 65%) and similar |
| Masthead kicker | 11–13 pt (44–52 px) | IBM Plex Mono 500 | uppercase, .18em tracking, rust |
| Takeaway strip | 22–26 pt (88–104 px) | Crimson Pro 400 | amber left-rule, no underline |
| Provenance footer | 10–12 pt (40–48 px) | IBM Plex Mono 400 | rust left-rule; the only place < 14 pt |

**Hard floor:** nothing a viewer must read is below **16 pt** at 13.333-in
canvas (provenance footer is the documented exception — it is an audit anchor,
not read from the back of the room). This is the projection-legibility rule.

---

## 3. Palette (content-informed — herring / ocean / Haida earth)

Do not substitute a generic palette. One dominant ink, ocean-and-earth
supports, single rust accent.

| Token | Light | Dark | Use |
|---|---|---|---|
| `--bg` | `#fbfaf7` | `#0e0e0e` | slide background |
| `--ink` | `#111111` | `#f0eee9` | primary text |
| `--ink-soft` | `#4a4a4a` | `#a8a59f` | secondary text |
| `--accent-rust` | `#8b3a23` / `#d9714f` | accent, masthead, economic track, "value" |
| `--accent-marine` | `#1c3a52` / `#6e9bc4` | management scale, governance track |
| `--accent-kelp` | `#4a5d3a` / `#8aa074` | ecological structure |
| `--accent-plum` | `#5d3d52` / `#b685a8` | cultural service / "people" |
| `--accent-amber` | `#a07028` / `#cfa055` | management window, takeaway rule |

**Track-color contract (must be identical on every slide):** ecological =
kelp, cultural/service/people = plum, economic/value = rust, governance =
marine, management-window = amber. S5, S11, S12 all use these — never recolor.

Motif: the IBM Plex Mono masthead kicker `Coupled tipping points | Pacific
herring | Haida Gwaii` top-left on every content slide; rust left-rule on
provenance, amber left-rule on takeaways. Carry it across all slides.

---

## 4. Slide zone templates (what goes where)

Seven zone templates. Each slide's wireframe in `talk_architecture_3` maps to
one. Content lives inside the 5% safe margin.

| Zone | Used by | Layout | Figure/photo rule |
|---|---|---|---|
| **T — Title** | S1 | dark; full-bleed photo, title block lower-third on a scrim | photo authored 16:9, cover-cropped centered, scrim ≥ 45% opacity behind text |
| **P — Full-bleed photo** | S2, S3, S14 | dark; image edge-to-edge, optional kicker | photo 16:9; if native ≠ 16:9, center-crop the **photo**, never letterbox a photo |
| **F — Figure + takeaway** | S4, S6, S8, S9 | light; title (top), figure (center ~70% h), takeaway strip (bottom) | figure exported at the **content-zone aspect** and placed `contain` — letterbox in the branded zone, never crop a data figure |
| **2 — Two-panel** | S7 | light; title, two equal panels, takeaway | each panel authored together as one 16:9 image (no PPT-side layout) |
| **C — Column text** | S11, S13 | light; title, 3 columns or numbered rows, takeaway | no figure; pure type |
| **D — Built figure full** | S12 | dark; the decoupling figure carries its own title/legend/footer | full-bleed; authored 16:9 |
| **R — Reprise/close** | S14 | dark; full-bleed photo + one closing line | as P |

**The one inviolable figure rule (no stretch):**
- A **data figure** (R/PDF/SVG) is placed `sizing:{type:'contain'}` inside its
  zone — scaled to fit, aspect preserved, letterboxed on the branded
  background. **Never** set independent width+height. **Never** crop a data
  figure to fill.
- A **photograph** may be cover-cropped (center) to fill a P/T/R slide
  (cropping a photo is fine; distorting it is not).
- Decision test before placing any image: "is the rendered aspect ratio equal
  to the source's native aspect ratio?" If no → wrong; re-export at the zone
  aspect or letterbox.

---

## 5. R-figure re-export spec (SUPERSEDED for the talk — paper/analysis track)

> **⚠️ Policy (decided 2026-05-19, Adrian).** Talk figures are **no longer
> R-rendered**. The canonical talk-figure pipeline is the **matplotlib +
> baked-chrome** pipeline in `deck_build/` (`redesign_figs.py` →
> `preprocess_figures.py` → `build_pptx_native.js`) — see §7 and
> `deck_build/README.md` ("Status & figure policy"). ALL talk figures, current
> and future (incl. Q&A/backup slides), use that pipeline and aesthetics.
> R/ggplot2 (`Code/07cz_deck_figure_reexport.R`, `Output/figures/`) is the
> **parallel paper/analysis track**: preserved, **not deleted**, **not** the
> talk source. The spec below is retained for the manuscript figure work and
> as historical context for how the deck figures originated — do not apply it
> to the talk deck.

R figures currently in `Output/figures/` are **manuscript** exports
(`theme_pub(base_size≈10)`, often non-16:9, axis text sized for print). They
**must be re-exported for the deck** so axis labels are readable from the back
of a lecture theatre and the aspect ratio matches the slide zone.

**Use the repo's existing lecture tooling** — `R/07_lecture_figures.R` →
`save_lecture_figure()` with `theme_lecture(base_size = 18)` from
`R/00_setup.R`. Do **not** invent a parallel exporter.

Per-figure rules:

1. **Theme:** `theme_lecture(base_size = 18)` minimum; bump to 20–22 for dense
   panels. Never `theme_pub()` for a slide.
2. **Aspect = the target zone, not 16:9 by default.**
   - Zone **D / full-bleed figure** (S12-style): 13.333 × 7.5 in (3840×2160 @ 288).
   - Zone **F / figure + takeaway** (S6, S8, S9): the figure occupies a
     **11.0 × 4.6 in** content box → export at **that** ratio (≈ 2.39:1),
     3300×1380 px @ 300 dpi. Title and takeaway are drawn by the slide frame,
     not inside the figure.
3. **DPI:** 300 (`dpi = 300`, or 288 to match `save_lecture_figure`'s 4K
   convention — either gives ≥ 250 px/in at projected size).
4. **On-figure text floor:** smallest axis tick label ≥ **18 pt-equivalent**
   at final placed size. After export, eyeball at 100% — if a tick label is
   unreadable, increase `base_size` or reduce tick count (`scale_*(n.breaks=)`),
   never shrink the figure.
5. **Background:** `theme_lecture` is dark (`#0e0e0e`-family). Two routes —
   (a) place dark figures on **dark zone** slides (S12), or (b) for **light**
   content slides (S6/S8/S9) add a light `theme_lecture(dark=FALSE)` variant
   (add to `R/00_setup.R` if absent) so the figure background matches the
   slide. **Never** put a dark figure on a light slide or vice-versa.
6. **No PowerPoint scaling:** export at the exact pixel size of the zone box so
   PowerPoint places at 100% (no up/down-sampling, no resize handle).
7. **Colour:** the figure's series colours must use the §3 track contract
   (kelp/plum/rust/marine), not ggplot defaults, so figures match the deck.
8. **Legend:** bottom or direct-label (per `~/.claude/CLAUDE.md` figure
   standards); never inside the panel.

Re-export targets (R figures only — the rest are HTML/photo/PDF):

| Slide | Source figure | Re-export as | Zone / aspect |
|---|---|---|---|
| S6 | `stier2020_updated/fig3_growth_pdo_updated` | `lecture/s06_climate_pdo.png` | F · 11.0×4.6 |
| S8 | `stier2020_updated/fig5_realized_growth_updated` | `lecture/s08_realized_growth.png` | F · 11.0×4.6 |
| S9 | `synchrony` (+ `portfolio_metrics_combined` for numbers) | `lecture/s09_synchrony.png` | F · 11.0×4.6 |
| S10 | `Data/processed/predators/` (firewall-safe import) | `lecture/deck/s10_predators_returned.png` | inset · authored 16:9 |
| (B-cards) | as needed from `qa_backup_slides.md` proof objects | `lecture/bNN_*.png` | F |

---

## 6. Per-slide figure → zone → source (the build map)

Builds on `slide_asset_map.md`; adds the zone + the exact image the deck
assembler places. "Render" = HTML→PNG at 3840×2160. "Re-export" = R per §5.
"Photo" = Adrian supplies from `DRV-ASSETS` (or the S10 humpback video frame).

| # | Slide | Zone | Deck image (3840×2160 unless noted) | State |
|---|---|---|---|---|
| 1 | Title | T | photo (DRV 01-biology) + title overlay (composited) | 📷 Adrian |
| 1b | **Sense of place — Haida Gwaii** | P | render `s01b_haida_gwaii_place.html` → `deck_assets/01b_sense_of_place.png` (full-bleed, ESRI/Maxar satellite + deck-styled annotations & place dots) | ✅ built 2026-05-20 |
| 2 | The shore comes alive | P | photo (DRV 01-biology) | 📷 Adrian |
| 3 | The people & the fish | P | photo (DRV 09-collab salomon / 08-field stier) | 📷 Adrian |
| 4 | The baseline, measured | F | McKechnie crop + stat callouts (compose to slide) | 🔨 build §7 |
| 5 | Two collapses | D-light | render `s5_two_collapses.html` | ✅ built |
| 6 | The investigation | F | re-export `s06_climate_pdo.png` + slide frame | 🔁 re-export |
| 7 | The two scales | F | re-export `s07_two_scales.png` + slide frame | ✅ real-data figure (replaces schematic) |
| 8 | Growth collapsed | F | re-export `s08_realized_growth.png` + slide frame | 🔁 re-export |
| 9 | Portfolio eroded | F | re-export `s09_synchrony.png` + slide frame | 🔁 re-export |
| 10 | Predators came back | P+inset | humpback video frame (Adrian) + `s10_predators_returned.png` inset (✅ re-exported §5) | 📷 Adrian + ✅ fig |
| 11 | New state | C | render `s11_triple_bottom_line.html` | ✅ built |
| 12 | The decoupling | D | render `herring_decoupling_figure.html` | ✅ built |
| 13 | What this teaches | C | render `s13_takeaways.html` | ✅ built |
| 14 | Close | R | reprise S1/S2 photo + closing line (composite) | 📷 Adrian |

Q&A backup cards (`qa_backup_slides.md`, B1–B20): rendered as **C/F** zone
images, kept in a hidden section after slide 14, pulled on demand.

---

## 7. Build pipeline (deterministic)

1. **Render HTML slides** (S5, S7, S11, S12, S13 + any built B-cards):
   headless Chrome `--window-size=1920,1080 --screenshot`, then upscale-export
   at 3840×2160 (author CSS already targets 16:9; render at 2× for crispness).
2. **Re-export R figures** (S6, S8, S9): `Rscript` driving
   `R/07_lecture_figures.R` helpers per §5; output to `Output/figures/lecture/`.
3. **Compose framed figure slides** (S4, S6, S8, S9): place the `contain`
   figure on a branded 3840×2160 background (light `#fbfaf7`, masthead kicker,
   title, takeaway, provenance) — a small HTML frame template
   (`_slide_frame.html`) takes a figure path + strings and renders the
   composite, so framing is identical to the built slides and the figure is
   never stretched.
4. **Composite photo slides** (S1, S2, S3, S10, S14): once Adrian supplies the
   DRV-ASSETS images / humpback frame — center-cover crop to 16:9, scrim +
   title via the frame template.
5. **Assemble .pptx** with pptxgenjs: 13.333×7.5 in; for each slide
   `addImage({path, x:0, y:0, w:13.333, h:7.5})` (image is already exactly
   16:9 → zero distortion); speaker notes from `talk_architecture_2` into
   `slide.addNotes()`; backup cards appended after S14.
6. **QA (required, per pptx skill):** export pptx→pdf→jpg, subagent visual
   inspection for overflow/contrast/stretch/placeholder; fix-and-reverify loop.
7. **Deliver:** send final `.pptx` to `scientific.meetings@royalsociety.org`
   (overdue).

---

## 8. Rules digest (pin this)

- 16:9, 13.333×7.5 in, 3840×2160 px, sRGB.
- Image-rendered deck — no live fonts (venue PC lacks Crimson Pro/IBM Plex).
- Data figures: `contain`, aspect preserved, letterboxed on brand bg — **never
  stretched, never cropped**. Photos: center-crop ok, never distort.
- Re-export every R figure with `theme_lecture(base_size ≥ 18)` at the zone
  aspect, 300 dpi; smallest tick label ≥ 18 pt-equivalent; series colours =
  the track contract.
- Type floor 16 pt (provenance footer the only exception).
- Track colours fixed: eco=kelp, cultural/people=plum, economic=rust,
  governance=marine, window=amber. Dark = S1/S12/S14; light = the rest.
- Every claim/number obeys the claim-control sheet & `numbers_provenance.md`.
- QA with fresh-eyes subagent before declaring done.
