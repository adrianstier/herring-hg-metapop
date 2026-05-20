# v3.6 REVISED Deck Build Log

Talk: Royal Society US-UK Forum, Session 5 (Tipping Points in Ecosystem Services)
When: Wed 20 May 2026, 09:30 London (TODAY, T-~2h)
Output: `Talk_Materials/Herring_RoyalSociety_Stier_2026_v3.6_REVISED.pptx`
Fallback (do NOT touch): `Herring_RoyalSociety_Stier_2026_claude-code_20260519-152552_A-minus-4_SHIPPABLE.pptx`

## Hard Rules (every agent honors)

1. Universal fonts on native text only — Calibri (body) / Georgia (headers, take-home) / Consolas (kicker, mono). NO Crimson Pro / IBM Plex in native text.
2. EMBED all media. `add_picture()` for images. `add_movie(mime_type='video/mp4', poster_frame_image=...)` for videos. Verify external refs == 0.
3. Claim-control: synchrony **0.17 → 0.28 (>60%)** (NOT 0.31→0.40). Predator demand **≈⅓ standing stock** (NOT 239%). SOK **$62.88/lb (1995) → $11–14/lb (2004)**. Last HG roe: **2002**. P(SB<LRP) = 0.38 at zero catch. **No "wolves" attributed to HG corpus** (S6 white-wolf is Pacific Wild visual texture only).
4. "Recovery is a moving target." appears ONLY at S1 and S30. Bookend, nowhere else.
5. "Tipping point" only at S1 kicker (session title) and S28 (reframe).
6. `Footage: Pacific Wild` credit on every video slide (S4, S6, others using clips).
7. Haida = present-tense sovereign nation. NEVER "stakeholders" / "human dimensions."
8. kʼaaw = "the right and the ritual persisted; access did not." NEVER "kʼaaw economy persisted intact."

## Phases

- A: Asset prep
- B: 5 parallel slide builders (S1–S6, S7–S12, S13–S18, S19–S24, S25–S30 + X1-4 + B1-5)
- C: Assembly + PDF
- D: 3 parallel QA agents (typography, claim-control, narrative/portability)
- E: Patch + final QA

## Log

| Time | Agent | Slide/Phase | Status |
|------|-------|-------------|--------|
| 2026-05-20T06:46:24Z | phase-A | manifest+placeholders | DONE — 5 placeholders generated, 21 spine slides + 2 extras have confirmed assets, 7 spine + 2 extras + 5 backups text-only |
| 2026-05-20T06:55:32Z | builder-B1 | s01 | done |
| 2026-05-20T06:55:32Z | builder-B1 | s02 | done |
| 2026-05-20T06:55:32Z | builder-B1 | s03 | done |
| 2026-05-20T06:55:32Z | builder-B1 | s04 | done |
| 2026-05-20T06:55:32Z | builder-B1 | s05 | done |
| 2026-05-20T06:55:32Z | builder-B1 | s06 | done |
| 2026-05-20T06:57:14Z | builder-B3 | s13 | done |
| 2026-05-20T06:57:14Z | builder-B3 | s14 | done |
| 2026-05-20T06:57:14Z | builder-B3 | s15 | done |
| 2026-05-20T06:57:14Z | builder-B3 | s16 | done |
| 2026-05-20T06:57:14Z | builder-B3 | s17 | done — video embedded (sim_anim_v2.mp4), φ 0.17→0.28 (>60%) callout |
| 2026-05-20T06:57:14Z | builder-B3 | s18 | done — 8-fold productivity drain (δ²σ 0.08→0.01) |
| 2026-05-20T06:57:14Z | builder-B3 | smoke-test | PASS — all 6 build, /tmp/b3_smoke.pptx 3.5 MB, 6 slides |
| 2026-05-20T07:57:00Z | builder-B2 | s07 | done — sea lion poster_frame hero LEFT 60%, 3 stacked predator callouts RIGHT 40% (humpback / harbour seal / Steller sea lion), amber-rule punch line, Pacific Wild credit. NO 239% callout, NO retired 10_predators.png. |
| 2026-05-20T07:57:00Z | builder-B2 | s08 | done — spare layout, 03_people.png (confirmed Haida kʼaaw harvest, contemporary), Salomon/CHN credit only, present-tense framing, NO data callouts. |
| 2026-05-20T07:57:00Z | builder-B2 | s09 | done — 04_baseline.png LEFT 60% (McKechnie 2014 PNAS), 6 stacked callouts RIGHT 40% (49% / 171 sites / <±10% / ~10,700 yr / kʼaaw middens / iinang), source footer. |
| 2026-05-20T07:57:00Z | builder-B2 | s10 | done — v1_04_aerial_seine_net.mp4 embedded LEFT 60%, text-only schematic card RIGHT 40% with unicode arrows (ship → cove1 → ship → cove2), Pacific Wild credit. |
| 2026-05-20T07:57:00Z | builder-B2 | s11 | done — RebuildingPlan2024_Fig32 LEFT 70%, regime sidebar RIGHT 30% (4 regimes + amber rule + audited $62.88/lb 1995 → $11–14/lb 2004 + last HG roe 2002), source footer. |
| 2026-05-20T07:57:00Z | builder-B2 | s12 | done — 3-column keystones (ECOLOGICAL/CULTURAL/ECONOMIC) with subtitles "The channel" / "10,000 years" / "150 years", amber-rule bottom strip "And in one lifetime, the fish changed twice.", §5.2.3 source. No "Recovery is a moving target." |
| 2026-05-20T07:57:00Z | builder-B2 | smoke-test | PASS — all 6 builders import, 6 slides construct, /tmp/b2_smoketest.pptx 18.8 MB, 1 video (S10) + 4 images embedded |
| 2026-05-20T06:58:31Z | builder-B4 | s19 | done — 06_climate_pdo.png full-width chart (12.0" x 4.4"), amber-rule punch line "Climate is necessary — but it is not the barrier." overrides original take-home, "Blob 2014-2016 · no detectable signal" mono callout. SUSPECT 1: OCEAN. Necessary-not-sufficient framing only. |
| 2026-05-20T06:58:31Z | builder-B4 | s20 | done — 07_two_scales.png LEFT 58%, RIGHT 40% callouts (4% archipelago-wide / 50–70% in coves / 91% in some subpops), amber-rule italic "The coastwide number looked safe — that was the problem." Stier 2020 · Okamoto 2020 footer. |
| 2026-05-20T06:58:31Z | builder-B4 | s21 | done — text-only title card, two 5.5"×4.0" cards centered (1 · RECOVERED PREDATOR PIT and 2 · LOST ELDERS / GWOF), thin amber rules on top, mono rust headers, Georgia italic bodies. |
| 2026-05-20T06:58:31Z | builder-B4 | s22 | done — sea-lion poster LEFT 52%, RIGHT callout sequence: Measured (φ: 0.17 → 0.28) + amber rule + Hypothesis (leading explanation) + amber rule + BIG Georgia "Predator demand ≈ ⅓ of standing stock" (rust) + "(~29% removal analogue)" + claim-control footnote. Pacific Wild credit. NO 239%. NO 10_predators.png. NO 0.31→0.40. Frame = leading hypothesis only. |
| 2026-05-20T06:58:31Z | builder-B4 | s23 | done — Guujaaw quote large center-left (Georgia italic 28pt), "— Chief Gidansta (Guujaaw)" attribution, 12_decoupling.png top-right 3"×3", convergence panel (MacCall 2019 · Corten 2002 · Huse 2002/2010 · Ono 2025 · Jesmer 2018), regional result strip (ρ_firstdiff = +0.37, p ≈ 0.035, n=32 ; mean-age → spawn 7-yr lag ρ = +0.43, p ≈ 0.015), consistent-with disclaimer per claim-control sheet. |
| 2026-05-20T06:58:31Z | builder-B4 | s24 | done — five-bullet results summary LEFT 65%, optional 13_takeaways.png RIGHT 35%. Bullets: aggregate biomass + spatial collapse / synchrony ~60% / productivity ~8-fold / ocean necessary-not-barrier / predators+elders both consistent neither proven causally. NO "moving target" (reserved S1/S30). NO "tipping point" (reserved S28). |
| 2026-05-20T06:58:31Z | builder-B4 | smoke-test | PASS — all 6 builders import, 6 slides construct end-to-end into /tmp/B4_sanity.pptx |
| 2026-05-20T07:30:00Z | builder-B5 | s25 | done |
| 2026-05-20T07:30:00Z | builder-B5 | s26 | done |
| 2026-05-20T07:30:00Z | builder-B5 | s27 | done |
| 2026-05-20T07:30:00Z | builder-B5 | s28 | done |
| 2026-05-20T07:30:00Z | builder-B5 | s29 | done |
| 2026-05-20T07:30:00Z | builder-B5 | s30 | done |
| 2026-05-20T07:30:00Z | builder-B5 | x1 | done |
| 2026-05-20T07:30:00Z | builder-B5 | x2 | done |
| 2026-05-20T07:30:00Z | builder-B5 | x3 | done |
| 2026-05-20T07:30:00Z | builder-B5 | x4 | done |
| 2026-05-20T07:30:00Z | builder-B5 | b1 | done |
| 2026-05-20T07:30:00Z | builder-B5 | b2 | done |
| 2026-05-20T07:30:00Z | builder-B5 | b3 | done |
| 2026-05-20T07:30:00Z | builder-B5 | b4 | done |
| 2026-05-20T07:30:00Z | builder-B5 | b5 | done — smoke test PASS 15/15 |
| 2026-05-20T08:04:00Z | phase-C | assembly | DONE — 39 slides, 92 MB pptx, 56 MB pdf, 35 embedded media files, 0 external refs. assemble_v36.py shipped; all 39 builders imported and constructed clean (no BROKEN placeholders, no patches required). PDF via soffice 26.2.0.3 (impress_pdf_Export), 39 pages. Outputs: Herring_RoyalSociety_Stier_2026_v3.6_REVISED.pptx + .pdf in Talk_Materials/. |
| 2026-05-20T08:08:00Z | qa-narrative-portability | audit | DONE — P0=0, P1=0 |
| 2026-05-20T08:12:00Z | qa-claim-control | audit | DONE — P0=0, P1=1 |
| 2026-05-20T08:08:00Z | qa-typography | audit | DONE — P0=2, P1=1, P2=0 |
| 2026-05-20T07:14:31Z | phase-E | patch+re-render | DONE — ship ready |
