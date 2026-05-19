# Slide → Asset Map — 14-slide Royal Society spine

Created: 2026-05-18. Wires every slide in the **confirmed 14-slide architecture**
(`talk_architecture_1_outline.html` / `_2_speaker_notes.html` /
`_3_figures_layout.html`) to concrete asset files, with status, the
claim/number guardrail that governs it, and the remaining action.

**Provenance rules (do not violate):**
- Numbers: `numbers_provenance.md` — current portfolio metrics are `m1_stier_11`
  (synchrony 0.63 all-11 / 0.70 focal-9; Simpson 3.26/3.31; top-3 share 84%).
  "2.1×", "65% vs 4%", ">60% synchrony rise" are **Stier et al. 2020 published**
  — label as such, never as current output.
- Claims: `../../docs/talk-model-claim-control-sheet.md` — `m1_stier_11` is the
  only promoted baseline; predators = large ecological pressure, **not** a
  promoted HG coefficient; no completed Doherty catch-at-age replication.
- DRV-ASSETS files live on Drive folder `1ubgQEK8xnpt2fyo9S1dSX1FeVGbojoCO`
  (inventory `11zw3ojJ1EBuJIiKW4HJwpQf4l3dCF-Bd`). Fetch with
  `gws drive files get --params '{"fileId":"<id>","alt":"media","supportsAllDrives":true}' -o <name>`
  (write inside the repo dir, delete after). Listed by category/filename.

Status legend: ✅ ready to drop in · 🟡 adapt/confirm · 🔨 build · 📷 source photo (Adrian) · ⚠️ claim/number guardrail.

---

## Act I — Cold open (slides 1–4)

| # | Slide | Primary asset | Backup | Status | Action / guardrail |
|---|---|---|---|---|---|
| 1 | Title | `DRV-ASSETS 01-biology/herring_bait_ball_underwater_spiral.jpg` | `01-biology/herring_school_underwater_natgeo.jpeg` | 📷 | Pull from Drive; dark scrim under title block. Title: "Coupled Tipping Points in Pacific Herring & Haida Gwaii" |
| 2 | The shore comes alive | `DRV-ASSETS 01-biology/aerial_herring_spawn_turquoise_water.jpeg` | `01-biology/herring_bait_ball_dramatic_underwater.jpeg` | 📷 | Full-bleed, image carries it |
| 3 | The people and the fish | `DRV-ASSETS 09-collaborator-photos/salomon_roe_on_branch_harvest_from_boat.JPG` (k'aaw practice, Salomon-credited) | `08-field-photos/stier_herring_roe_on_kelp_closeup.jpeg` (Adrian's own — no consent issue) | 📷 | Credit photographer + Nation on slide. Stier field photo is the rights-safe fallback |
| 4 | The baseline, measured | `Literature/McKechnie_et_al_2014_PNAS_Archaeological_Herring.pdf` (crop site map / NISP) | `DRV-ASSETS 12-publications/McKechnie_…pdf`; accessible-image candidate: [Mongabay 2014 "By the bones"](https://news.mongabay.com/2014/06/by-the-bones-herring-populations-were-superabundant-before-commercial-fisheries/) | 🟡 | Crop figure; **verify callouts** (171 sites, 435,777 bones, 49%, 99%, <±10%) against PDF text. ⚠️ Mongabay photo usable **only with explicit on-slide photo credit** — verify rights per the named photographer before embedding in the public deck |

## Act II — Story & results (slides 5–10)

| # | Slide | Primary asset | Backup | Status | Action / guardrail |
|---|---|---|---|---|---|
| 5 | Two collapses, two outcomes | 🔨 build annotated catch/biomass timeline | base data: `Output/figures/m1_total_biomass_trajectory.pdf`; `DRV-ASSETS 05-data-graphs/dfo_biomass_timeseries_with_threshold.png` | 🔨 | The talk's "engine." Build a clean ~1900–present timeline with the two on-figure annotations (1960s→recovered ~5 yr; 1990s→25 yr no recovery). Verify peak numbers vs Cleary/Rebuilding Plan |
| 6 | The investigation | `Output/figures/stier2020_updated/fig3_growth_pdo_updated.pdf` (climate/PDO) | `Output/figures/stier2020_updated/companions/companion_07_driver_dashboard.pdf` | 🟡⚠️ | Frame as "climate necessary, not sufficient." Confirm chosen panel does **not** show a promoted predator coefficient |
| 7 | The two scales (archipelago vs fished sections) | ✅ `Output/figures/lecture/deck/s07_two_scales.png` → staged `deck_assets/07_two_scales.png` (real-data R figure; `Code/07cz_deck_figure_reexport.R` S7 block) | data: `Output/diagnostics/stier2020_updated_fig4_fishing.csv` | ✅⚠️ | BUILT — real-data archipelago-wide vs fished-sections F, 1951–2025, CI bands, shaded mismatch gap. DFO HCR drawn only over years in force (F=0.20 1983–2017 → F=0.10). **Updated Stier et al. 2020 method (catch matrix to 2025) — scale-mismatch result, NOT m1_stier_11.** Cut-off (0.25·SB0 ≈ 5.4 kt) is a biomass floor → speaker note, not this F axis. Embedded via `build_pptx_native.js` (full-bleed image, replaces old schematic). The conceptual hinge |
| 8 | Growth collapsed, cove by cove | ✅ **REBUILT 2026-05-18** `Output/figures/lecture/deck/s08_realized_growth.png` → staged `deck_assets/08_realized_growth.png` (deck-styled slopegraph; `Code/07cz_deck_figure_reexport.R` S8 block) | `Output/figures/stier2020_updated/fig5_realized_growth_updated.pdf` (focal-9 Stier-2020 view) | ✅⚠️ | **ALL-11 (Adrian's call 2026-05-18, switched from focal-9):** data = `Output/diagnostics/stier2020_updated_companion_growth_change.csv` — per-section mean realized growth, m1_stier_11, all 11 sections, hist (1952–94) → post (1995–2025). Headline = data-exact **"9 of 11 sections declined"** (post-era median < historical). Tasu Sound & Naden Harbour = sparse-sensitivity (retained in m1_stier_11, excluded from Stier-2020 focal panels) → grey/dashed + "(sparse)" label, never hidden. Port Louis = lone focal hold (ink). λ=1 replacement line is meaningful here (a couple post-era sections dip <1). Track colour = kelp (ecological); top ~1.85 in reserved for native title; medians only, no per-section significance (claim-control sheet). Native title/notes updated in `deck_build/build_pptx_native.js`; pptx rebuilt + composite-QA'd |
| 9 | The portfolio eroded | `Output/figures/synchrony.pdf` | `Output/figures/stier2020_updated/fig6_process_portfolio_updated.pdf`; current numbers from `Output/figures/portfolio_metrics_combined.pdf` | ✅⚠️ | Current synchrony = 0.63/0.70 (m1_stier_11). ">60% rise" = Stier 2020 (label). **⚡ EWS framing = hypothesis only — leading-indicator analysis NOT done; present as proposal, not result** |
| 10 | The predators came back | **✅ BUILT** `Output/figures/lecture/deck/s10_predators_returned.png` (deck-styled 2-panel: A HG herring eaten by predator group 1910–2024, mammals the hero band; B predator demand as % of HG spawn, 2015–24 ≈239%) | `/Users/adrianstier/pacific-herring-predators/Output/figures/HG_humpback_trajectory_1910-2022.pdf` (recovery-shape alternative) | ✅📷⚠️ | Figure done — re-rendered firewall-safe from `Data/processed/predators/` via `Code/07cz_deck_figure_reexport.R` S10 block; claim guardrail baked into caption ("large ecological pressure, NOT a fitted m1_stier_11 coefficient"). **GAP REMAINS: no humpback-feeding photo in 142C/242 libraries — Adrian sources the P-zone photo this figure insets into.** |

## Act III — Synthesis (slides 11–14)

| # | Slide | Primary asset | Backup | Status | Action / guardrail |
|---|---|---|---|---|---|
| 11 | A system in a new state | text-led 3 columns (ecosystem / people / economy) | `figs/RebuildingPlan2024_Fig31_…png`, `…Fig32_…png` (value layer) | 🟡⚠️ | **Do NOT assert "$40M→$2.78M" (unsourced).** Use sourced wording: BC roe value peaked 1980s, high to mid-90s, declined 1995–2005 & post-2008 (Rebuilding Plan Figs 31/32, DFO fish slips). See `S8_landed_value_provenance.md` |
| 12 | The decoupling — mgmt window | `herring_decoupling_figure.html` (**built 2026-05-18**; static, 4 layers/clocks) | `build1_spine.html` (animated 3-layer spine — S1/S2/S14 use) | ✅ | Built in the build1_spine visual language, rendered + decluttered. Governance track schematic (not an outcome metric; HG still below LRP). Remaining: export to slide image, choose light/dark to match deck |
| 13 | What this case teaches | text-led; content from `S20_solution_payload.md` (measure structure / manage exposure / build data spine) | three take-homes in `talk_architecture_1_outline.html` slide 13 | ✅ | Typographic layout. Keep the spatial-EWS thread proposal-strength (ties to S9) |
| 14 | Close | reuse slide 1/2 herring photo (reprise) | `DRV-ASSETS 01-biology/*` | 📷 | Closing line large + alone: "The herring is the example. The lesson is about thresholds." |

---

## Open decisions / genuine gaps (carry forward)

1. **Canonical-plan conflict (needs Adrian).** This map follows the 14-slide
   architecture. `HERRING_TALK_ASSETS.md` still calls the 20-slide
   `talk_production_plan.md` canonical. The 14-slide spine **drops the social
   cognitive-map beat** (Stier 2016, 27 experts) and AMB co-governance imagery
   that S15/S19 provenance work targeted — the master index calls that "the
   differentiator for this audience." Confirm 14-slide is final, or fold the
   social beat back in.
2. ~~S12 figure missing~~ **RESOLVED 2026-05-18** — `herring_decoupling_figure.html`
   built (static, 4 layers/clocks, build1_spine visual language). Remaining:
   export to slide image + light/dark theme choice.
3. **S10 figure ✅ BUILT** (`s10_predators_returned.png`, deck-styled, claim-safe,
   chosen by Adrian = consumption + pressure over the humpback-trajectory
   alternative). **Remaining S10 gap: the humpback-feeding photo** the figure
   insets into — not in any 142C/242 asset library (only SSL video + a humpback
   silhouette). Adrian must source the P-zone photo.
4. **No new analysis required.** Spine rests on `m1_stier_11` + Stier 2020
   published + sibling predator-repo audited products. Claim-control sheet bars
   new AWS jobs.

## Build order (Claude can do 1–6; Adrian owns photos)

1. ✅ S12 four-layer decoupling figure — **done** (`herring_decoupling_figure.html`).
2. ✅ S7 two-scale figure — **done** (real-data `s07_two_scales.png`, updated Stier 2020 attribution; replaces the schematic).
3. S5 annotated two-collapse timeline.
4. S4 McKechnie crop + callout verification.
5. S6 figure pick + S9/S11 number corrections.
6. S13 typographic layout.
7. ✅ S10 predator figure — **done** (`s10_predators_returned.png`).
8. Adrian: pull/choose photos for S1, S2, S3, S10 (humpback feeding), S14 from `DRV-ASSETS`.
