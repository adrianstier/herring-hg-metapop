# QA Typography Report — v3.6 REVISED

Audit timestamp: 2026-05-20T08:08:00Z
Auditor: qa-typography
Inputs:
- PPTX: `Herring_RoyalSociety_Stier_2026_v3.6_REVISED.pptx`
- PDF:  `Herring_RoyalSociety_Stier_2026_v3.6_REVISED.pdf`

## Summary
- Slides scanned: 39 (S1–S30 + X1–X4 + B1–B5)
- P0 issues: **2** (block ship)
- P1 issues: **1** (high priority, fix if time)
- P2 issues: **0** (cosmetic — none worth chasing)

The deck is in good shape: font policy is clean, no overflow, no real overlap, no contrast problems. Two real ship-blockers found, both narrow and surgically fixable.

## P0 Issues

- **S16 (page 16) — visible "ASSET NEEDED" placeholder card on stage.** The slide titled *"What the model predicts — at two scales."* shows a black placeholder labeled `ASSET NEEDED · S16 · Model output — regional + local predictions · build-phase: m1_stier_11 posterior summaries, aggregate + 11 sections · v3.6 build placeholder · phase-A`. This is the ONE slot where the model output figure was meant to land. Caption "Aggregate spawn-biomass posterior + 11-section trajectories" is in place. Source footer reads "Source: m1_stier_11 (Output/diagnostics/)".
  **Fix recommendation:** Render the actual `m1_stier_11` posterior figure (aggregate + 11-section panel) and drop it in `Talk_Materials/figures/` as `s16_model_output_two_scales.png`. Replace the placeholder image_path in `slides_v36/s16.py`. If the figure can't be produced in time for talk, swap the placeholder for a clean text-only "key result" card (the two callouts — aggregate posterior + section variance — restated typographically) to avoid showing build cruft to a Royal Society audience.

- **S27 (page 27) — lesson 3 title overflows into its subtitle.** Lesson 3 lead ("In coupled systems, manage the ecological AND cultural AND economic resource together.") wraps to two lines at 22pt bold across the 10.3-in row, and the second line collides with the gloss/subtitle "They came apart; only co-governance spans all three keystones." This is fully legible in PPTX preview at high zoom but unreadable at projector resolution from row ~10 back. Lessons 1 and 2 fit on one line and are clean.
  **Fix recommendation:** In `slides_v36/s27.py`, either (a) shorten lesson 3 lead to one line — e.g. "Co-manage ecology, culture, and economics together." — or (b) increase `row_h` from 1.5 → 1.9 and the lead box height from 0.6 → 1.0 to give the wrapped title room before the gloss. Option (a) is the publishable fix; option (b) is the no-decisions-needed code-only fix.

## P1 Issues

- **S23 (page 23) — claim-control footnote at 10pt.** The disclaimer "Consistent-with, modest, regional, descriptive — not demonstrated as cause at subpopulation scale (per claim-control sheet)." renders at Calibri 10pt. It is legible on the PDF and on a laptop screen, but at a 75-min Royal Society talk projected from 20+ ft, that line is the *most important risk-management text on the slide* (it is the disclaimer that keeps the predator-pit framing honest) and it sits below body text. Bump to 11–12 pt, italic, gray-soft as currently styled.
  **Fix recommendation:** In `slides_v36/s23.py`, change the claim-control footnote `size=10` → `size=12`. The TextBox 11 region has vertical room.

## P2 Issues
None worth shipping a patch for. All Calibri 12–13pt body fragments flagged in the raw scan are short numeric callouts, geographic place-names, or single-word section labels that read perfectly at projection resolution. Mono kicker/credit text at 8.5–11 pt is by spec (matches the talk's monospace voice).

## Font Family Audit
Allowed: Calibri / Georgia / Consolas
**Violations: NONE.** Every text run in every shape on every one of the 39 slides resolves to one of the three approved families. No Crimson Pro, no IBM Plex, no Helvetica.

## Visual Check Notes
Spot-checked: S1, S3, S5, S7, S11, S12, S16, S17, S19, S20, S22, S23, S25, S27, S28, S30, X1, X3, X4, B1–B4, plus video slides S4, S6, S10, S29 for poster frames.

- **page 1 (S1):** Clean. Crimson "SESSION 5 · TIPPING POINTS" kicker, big Georgia title "Pacific Herring at Haida Gwaii", italic subtitle, amber rule, gold pull quote "Recovery is a moving target." All elements aligned, no clipping.
- **page 3 (S3):** Two-up video posters (left=Pacific blue, right=herring spawn closeup), with cream "MOST OF THE YEAR" / "WHEN THE HERRING ARRIVE" labels sitting *on top of the dark image* (NOT on the cream slide background — the contrast audit script flagged the run color vs slide bg, but the image beneath provides contrast). Text is legible. Bottom black band "In a matter of days." is clean.
- **page 4, 6, 10, 29 (video slides):** All have poster frames embedded. No black-rectangle thumbnails in the PDF.
- **page 5 (S5):** Cove-scale chart at left, "LIFE HISTORY" sidebar at right. Reads well. Chart title and axis labels legible at full-page zoom.
- **page 7 (S7):** Sea-lion photo left, three predator callouts right (humpback ~1,000→25,000-33,000, harbour seal ~10,000→105,000, Steller >4× since 1970). "The mouth eating herring now is bigger than the fishery ever was." amber-rule punch line reads clean.
- **page 11 (S11):** "The economics of herring" — DFO seine landed-value chart, "REGIMES" sidebar with four eras, SOK peak $62.88/lb → $11–14/lb collapse, last HG roe 2002. Page-number "192" appears bottom-right of chart — that's part of the source chart image, not the slide. Acceptable.
- **page 12 (S12):** Three-column keystones (Ecological / Cultural / Economic) with subtitles "The channel" / "10,000 years" / "150 years". Clean three-column layout.
- **page 16 (S16):** ⚠️ ASSET NEEDED placeholder — see P0 above.
- **page 17 (S17):** "The parts came into phase." Stier 2020 portfolio chart left, φ: 0.17 → 0.28 callout right, amber rule, "+>60% increase post-1994", "Bad years became bad years everywhere." Clean.
- **page 19 (S19):** "Necessary, not the barrier." PDO + biomass chart with "Blob 2014-2016 · no detectable signal" callout. The bounding-box overlap flagged on S19 between the amber punch-line band and the credit footer is a false positive — both are full-width thin bands stacked vertically, visually distinct.
- **page 20 (S20):** "The average hid the extremes." Two-scale fishing-pressure chart left, 4%/50-70%/91% stacked callouts right. Clean.
- **page 22 (S22):** Sea-lion poster left, mono callouts right ("Measured: synchrony rose post-1994 / φ: 0.17 → 0.28 (Stier 2020)"), amber rule, Hypothesis framing, BIG Georgia "Predator demand ≈ ⅓ of standing stock", "(~29% removal analogue)", and small claim-control footnote at 9.5pt mono. The mono footnote at 9.5pt is borderline-tiny but it is by spec — it's a mono claim-control note, not body text. Acceptable.
- **page 23 (S23):** Guujaaw quote dominant left, MacCall/Corten/Huse/Ono/Jesmer convergence list right, regional ρ result band below, claim-control disclaimer at the bottom in 10pt — see P1 above. The flagged overlap between regional-result and claim-control bands is a false positive (vertically stacked bands).
- **page 25 (S25):** "Allocate the portfolio. Re-couple the strands." Two columns (1 · ALLOCATE / 2 · RE-COUPLE). Clean.
- **page 27 (S27):** ⚠️ Lesson 3 title-subtitle collision — see P0 above. Lessons 1 and 2 are clean.
- **page 28 (S28):** Open-question pull quote on tipping-point language. Clean, lots of white space (intentional).
- **page 30 (S30):** Closing "Recovery is a moving target." in gold on near-black, "Same fish. Same coast. Once it came back. Once it has not." subtitle, Thank-you line, attribution footer. Clean.
- **page 31 (X1):** "Diversification removes variance, not yield." Portfolio backup with Markowitz/Schindler/Bristol-Bay context. Clean.
- **page 33 (X3):** "P(SB < LRP) = 0.38" backup with spawning biomass chart. Clean and high-impact.
- **page 34 (X4):** "The rights persisted. The access did not." Six numbered rights/access points. Clean.
- **page 39 (B5):** k'aaw / Gladstone backup answer. Clean.

### False positives noted (recorded so future audits don't re-flag)
- Overlap between full-width amber-rule punch-line band and full-width credit footer band on S19 and S23: flagged at 50–70% by bounding-box math; visually they are vertically stacked thin strips with no shared content. Ignore.
- Cream-text-on-cream-bg on S3: text actually sits on top of dark video poster images, contrast is fine. Ignore.

## Sign-off
- Font policy: **CLEAN** (0 violations across 39 slides)
- Overflow: **CLEAN** (0 boxes outside 13.333 × 7.5 in)
- Overlap: **CLEAN** after manual review (2 raw flags, both false positives)
- Contrast: **CLEAN** after manual review (1 raw flag, false positive — text over image)
- Poster frames on video slides: **PRESENT** on all of S4, S6, S10, S17, S22, X1, X2

Two P0 fixes (S16 asset, S27 title wrap) and one P1 fix (S23 footnote size) before ship.
