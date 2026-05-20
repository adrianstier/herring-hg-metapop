# Stier et al. 2020 *Ecosphere* — Haida Gwaii herring metapopulation: archived code

**What this is.** The code from the original **Stier et al. 2020 (Ecosphere)**
Haida Gwaii Pacific herring metapopulation / portfolio-effect paper
("Synchrony after a major event can increase metapopulation risk of
collapse"). Imported here as a **read-only archive / provenance reference**
for the Royal Society talk and the current `stier-2027-herring-metapopulation`
analysis.

**Provenance.** Copied 2026-05-19 from (NOT deleted — original intact):
`~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/Stier Lab/People/Adrian Stier/Projects/Completed/Herring_Haida_Gwaii/`
(`Code/`, `Communications/gif/`, `Data/Herring/Nathan Stuff/`).

**Scope of the copy.** Code only (235 files, 3.1 MB) + animation assets
(2.9 MB) + the scianimator interactive animation (9.5 MB) ≈ **16 MB**. The
project's **4.6 GB of model-output binaries** (`*.RData`, `*.rds`), big PDFs,
and raw data dumps were **deliberately left on Drive** (not code; would bloat
this 41 GB repo). Retrieve them from the Drive path above if a fit object is
ever needed.

**Firewall note.** This is archived 2020 provenance, NOT part of the live
`stier-2027` pipeline (it sits under `Code/archive/`, which the orchestrators
do not scan). Do not wire it into `_targets.R` / `08_refresh*`. Talk pulls
*concepts/data*, never re-runs this directly without intent.

---

## ⭐ The async→sync animation (talk target)

`_animation/sim_anim.mp4` — 12.5 s, 8 fps, 500×400. Six subpopulation biomass
series wander **asynchronously**, then a vertical "Major Event" bar, after
which they move **synchronously** (tight band); a thick grey line = the
metapopulation aggregate. Title: *"Synchrony after a major event can increase
metapopulation risk of collapse."* This is the illustration to **restyle into
the canonical dark v3 deck pipeline** and place near **S9 (portfolio
eroded)**.

| `_animation/` file | what |
|---|---|
| `sim_anim.mp4` | **the async→sync portfolio animation** (restyle target) |
| `herring_portfolio.mp4`, `herring_portfoliov2.mp4` | sibling portfolio animations (variants) |
| `ezgif.com-gif-maker.gif` | gif version |
| `herring CCF.mp4` | cross-correlation animation |
| `ecs23283-fig-0005-m.jpg` | **published Ecosphere Fig 5** = realized-growth slopegraph 1950–94 → 1995–2015 (same concept as canonical deck **S8**) |
| `okamoto.png` | Okamoto reference figure |

`scianimator/` — an interactive R **`animation`-package** (scianimator
HTML/JS) version: `PlotMap.r` + `index.html` + `js/css/` + input data
(`ALLSPAWN.csv`, `VPARec.dat`, `KILOMETR.TXT`, …). Frame-based spatial spawn
animation; useful reference for how the original was rendered (no single
script string-matches `sim_anim`; the mp4 was rendered from frames/ffmpeg).

---

## Code map

### `Code/Recent Figs/` — the paper's final/current code (start here)
| file | role |
|---|---|
| `Simulator_catch__2q_v3.R` | metapopulation simulator (two-q catch model) — the async→sync simulation engine |
| `Figures_Main_Text_v4_nospace.R`, `…-2q.R`, `Figures_Main_Text_v3_v3.R` | main-text figure generation (incl. the portfolio/synchrony figures) |
| `Supplement_v4.R`, `Supplement_v3_twoq.R`, `Supplement_v2.R`, `Posterior_Supplement.R` | supplement figures + posterior summaries |
| `model_output_summary_maps2015.R` | spatial/map summaries of model output |
| `theme_publication.R` | ggplot publication theme (2020 paper) |

### `Code/old/` — legacy lineage (historical; mine for method details only)
- `Herring_Substock/` (6) — 11-site CAR substock MARSS models
  (`Herring_Model_11_Sites_CAR_diag_{equal,unequal}_v1.R`)
- `12 Sites/` — 12-site MARSS variants (DD / CAR / noFishing)
- `MARSS 1st Pass/`, `old models/` — earliest `Simulator_v1/v2`,
  spatial-autocorrelation + fishing simulator drafts
- `txtfiles/` (24) — JAGS/BUGS model definitions
  (`normal_spatialRW_11sites_CAR_*.txt`)
- `Code_SSL/` (15), `Imac_Herring_4_14/` (15), `Code/` (19) — analysis-toolkit,
  dispersion, multiplot, publication_figures, map code
- `management_sections/`, `mapcodeandfiles/` — section/map helpers

---

## For future Claude/Codex sessions
- **Restyling the animation** → read `Code/Recent Figs/Simulator_catch__2q_v3.R`
  for the simulation logic; `_animation/sim_anim.mp4` is the visual target;
  reimplement in `talk-usuk-forum-2026/Talk_Materials/deck_build/redesign_figs.py`
  per the canonical pipeline (see `deck_build/README.md`).
- **Method/provenance questions** about the 2020 paper → `Recent Figs/` first,
  then `old/` lineage.
- This tree is **archived/reference** — do not modify in place to drive the
  current pipeline; port what you need into the live code with intent.
