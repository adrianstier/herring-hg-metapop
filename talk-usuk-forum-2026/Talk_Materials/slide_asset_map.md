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
| 4 | The baseline, measured | `Literature/McKechnie_et_al_2014_PNAS_Archaeological_Herring.pdf` (crop site map / NISP) | `DRV-ASSETS 12-publications/McKechnie_…pdf` | 🟡 | Crop figure; **verify callouts** (171 sites, 435,777 bones, 49%, 99%, <±10%) against PDF text |

## Act II — Story & results (slides 5–10)

| # | Slide | Primary asset | Backup | Status | Action / guardrail |
|---|---|---|---|---|---|
| 5 | Two collapses, two outcomes | 🔨 build annotated catch/biomass timeline | base data: `Output/figures/m1_total_biomass_trajectory.pdf`; `DRV-ASSETS 05-data-graphs/dfo_biomass_timeseries_with_threshold.png` | 🔨 | The talk's "engine." Build a clean ~1900–present timeline with the two on-figure annotations (1960s→recovered ~5 yr; 1990s→25 yr no recovery). Verify peak numbers vs Cleary/Rebuilding Plan |
| 6 | The investigation | `Output/figures/stier2020_updated/fig3_growth_pdo_updated.pdf` (climate/PDO) | `Output/figures/stier2020_updated/companions/companion_07_driver_dashboard.pdf` | 🟡⚠️ | Frame as "climate necessary, not sufficient." Confirm chosen panel does **not** show a promoted predator coefficient |
| 7 | The two scales (4% vs 65%) | 🟡 `DRV-ASSETS 05-data-graphs/slide_herring_fishing_rate_subpop_vs_archipelago.png` (teaching version exists) | `DRV-ASSETS 10-research-figures/proportion_sites_fished_biomass_caught.png` | 🟡🔨⚠️ | NOT a from-scratch build — adapt the teaching figure. **Label "4% / 65%" as Stier et al. 2020** (not m1_stier_11). The conceptual hinge |
| 8 | Growth collapsed, cove by cove | `Output/figures/stier2020_updated/fig5_realized_growth_updated.pdf` (current refit) | `DRV-ASSETS 10-research-figures/Pop_Growth_Pc_DD_July14.pdf` | ✅ | Drop in; theme-match deck |
| 9 | The portfolio eroded | `Output/figures/synchrony.pdf` | `Output/figures/stier2020_updated/fig6_process_portfolio_updated.pdf`; current numbers from `Output/figures/portfolio_metrics_combined.pdf` | ✅⚠️ | Current synchrony = 0.63/0.70 (m1_stier_11). ">60% rise" = Stier 2020 (label). **⚡ EWS framing = hypothesis only — leading-indicator analysis NOT done; present as proposal, not result** |
| 10 | The predators came back | fig: `/Users/adrianstier/pacific-herring-predators/Output/figures/century_scale_predator_field.pdf` (or `HG_humpback_trajectory_1910-2022.pdf`) | photo: ⚠️ none in 142C/242 libraries | 🟡📷⚠️ | Pull recovery fig from predator repo by reference (firewall-safe). **GAP: no humpback-feeding photo exists in lecture libraries — Adrian must source.** Frame predators as large pressure, NOT a promoted causal coefficient |

## Act III — Synthesis (slides 11–14)

| # | Slide | Primary asset | Backup | Status | Action / guardrail |
|---|---|---|---|---|---|
| 11 | A system in a new state | text-led 3 columns (ecosystem / people / economy) | `figs/RebuildingPlan2024_Fig31_…png`, `…Fig32_…png` (value layer) | 🟡⚠️ | **Do NOT assert "$40M→$2.78M" (unsourced).** Use sourced wording: BC roe value peaked 1980s, high to mid-90s, declined 1995–2005 & post-2008 (Rebuilding Plan Figs 31/32, DFO fish slips). See `S8_landed_value_provenance.md` |
| 12 | The decoupling — mgmt window | `build1_spine.html` (currently **3-layer**: eco/value/culture) | — | 🔨 | **Biggest build gap.** Spec names a non-existent `herring_decoupling_figure.html`. S12 speaker notes need **4 layers/clocks** (service ~1990, ecological 1993, economic 2005, governance later). Extend build1_spine to 4-layer, render/QA, export slide image |
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
2. **S12 figure missing** — the named built artifact does not exist; 3-layer vs
   4-layer mismatch. Highest-priority build.
3. **S10 humpback-feeding photo** — not in any 142C/242 asset library (only SSL
   video + a humpback silhouette). Adrian must source.
4. **No new analysis required.** Spine rests on `m1_stier_11` + Stier 2020
   published + sibling predator-repo audited products. Claim-control sheet bars
   new AWS jobs.

## Build order (Claude can do 1–6; Adrian owns photos)

1. S12 four-layer decoupling figure (extend `build1_spine.html`).
2. S7 two-scale figure (adapt the 142C teaching version; Stier 2020 attribution).
3. S5 annotated two-collapse timeline.
4. S4 McKechnie crop + callout verification.
5. S6 figure pick + S9/S11 number corrections.
6. S13 typographic layout.
7. Adrian: pull/choose photos for S1, S2, S3, S10, S14 from `DRV-ASSETS`.
