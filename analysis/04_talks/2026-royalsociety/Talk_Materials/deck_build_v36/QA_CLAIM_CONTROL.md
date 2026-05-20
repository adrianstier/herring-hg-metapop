# QA Claim-Control Report — v3.6 REVISED

**Auditor:** QA-CLAIM-CONTROL (automated sweep)
**Date:** 2026-05-20
**Deck:** `Herring_RoyalSociety_Stier_2026_v3.6_REVISED.pptx` (39 slides: 30 spine + X1–X4 + B1–B5)
**Sources audited:** PPTX (python-pptx shape text + notes_text_frame) + `slides_v36/s*.py`, `x*.py`, `b*.py` literal strings
**Cross-checked against:** `docs/talk-model-claim-control-sheet.md`, `/tmp/v36_revised.md`

---

## Status: **PASS_WITH_WARNINGS**

No P0 ship-blockers. One P1 (citation footer drift on S19), three P2 cosmetic / scope-clarification notes. Deck is safe to ship.

---

## P0 Issues (BLOCK SHIP — must fix before talk)

**NONE.** Every hard-rule check on the most scientifically-auditable claims passed:

- Synchrony φ correctly stated as **0.17 → 0.28 (>60% increase)** on every appearance; the retired pair `0.31 / 0.40` does **not** appear in any rendered text — only in the docstring comments of `s17.py` / `s22.py` as a self-policing reminder ("NOT 0.31 → 0.40 — that was an old/incorrect pair"). Those comments are not rendered to slides.
- Retired predator-demand figure **`239%`** has **0 hits** anywhere in the rendered deck (slides + notes). Replaced everywhere by the safe `≈⅓ of standing stock` / `~29% removal analogue` pair on S22, with the source-comment in `s22.py` again policing against `239%`.
- SOK $ markers on S11/S12: **$62.88/lb (1995) → $11–14/lb (2004)** — exact match to the claim-control sheet. X4 (backup) uses the alternate audited pair `$40/lb (1995) → <$6/lb (2004)` per RP2024, which the outline explicitly allows for X4 only.
- **Last HG roe = 2002**, SOK closed 2004, 0 t harvest 2025: present on S11, S12, S26, X3, X4, B5. No `2003` drift anywhere.
- **P(SB<LRP) = 0.38** at zero catch on X3 (slide 33). Exact value, no `0.4`/`0.35` rounding drift.
- **"Recovery is a moving target."** appears on exactly **S1 + S30** as visible slide type (slide bodies), and is echoed in the matching notes of those same two slides — no third slide carries it. Bookend intact.
- **No forbidden framing terms:** `stakeholders`, `human dimensions`, `Indigenous communities` (collective-noun framing of the Haida specifically), `economy persisted intact`, `demonstrated cause`, `proved/proves` — **all 0 hits** across slide bodies and speaker notes.
- **Haida framing on S8:** present-tense "are an Indigenous nation," "Council of the Haida Nation is their government," "co-governed" — matches outline contract.
- **Predator-mechanism caveats:** S22 carries `"Leading hypothesis — NOT a fitted HG coefficient (claim-control)."` as a visible italic line on the slide. S23 carries `"Consistent-with, modest, regional, descriptive — not demonstrated as cause at subpopulation scale (per claim-control sheet)."` as a visible italic line.
- **`m1_stier_11`** appears on S15 (methods grid card) and as the source attribution on S16. Spelling `m1_stier_11` exact in both visible slide text (the speaker note on S15 uses the hyphenated `m1-stier-11` for spoken cadence, which is fine — visible attribution is exact).

## P1 Issues (high priority — should fix if there is time, but not ship-blockers)

1. **S19 citation footer says `Analysis: Stier et al. 2020 / 2027 in prep`.** "2027 in prep" is a forward citation to the herring-metapopulation manuscript not yet submitted. Two options:
   - (a) Trim to `Analysis: Stier et al. 2020` and reserve the 2027 self-citation for the Discussion section.
   - (b) Leave as-is but be prepared to defend in Q&A if an attendee asks for the in-prep reference.
   - Outline does not require the `2027 in prep` callout; this is the only forward-citation drift in the deck.
   *Risk:* low — but technically a citation that cannot yet be verified at NotebookLM / Zotero / PubMed scale.

## P2 Issues (cosmetic / non-blocking / scope clarification)

1. **"Tipping point" appears on X4, B3, B5 in addition to S1 + S28.** The QA hard-rule said "tipping point" should appear ONLY on S1 + S28. However:
   - **X4** is explicitly titled `BACKUP · ACCESS TIPPING POINT` per the outline (Extras section, §X4). Outline-sanctioned use.
   - **B3** (slide 37) restates the audience question verbatim: *"How would you operationalise an EWS for an ES tipping point?"* — paraphrasing the reviewer's pushback, not an authorial claim.
   - **B5** (slide 39) closes the calibrated answer with *"...IS the access tipping point"* — outline-sanctioned framing of the social-economic strand.
   - All three uses are in the backup pool, only pulled if the room asks for them. **Recommendation: accept** — the QA hard-rule was overscoped; spine-only restriction (S1 + S28) holds for the running order and is satisfied.

2. **Pacific Wild credit not present on S17, X1 (slide 31), X2 (slide 32).** The QA hard-rule listed these as video slides requiring Pacific Wild credit. However, these three slides embed **`sim_anim_v2.mp4`** — the async→sync **simulation animation** generated from HG spawn-thickness data, which is **not Pacific Wild footage**. Pacific Wild attribution would be incorrect. **Recommendation: leave as-is** — Pacific Wild credits present on every slide that actually carries Pacific Wild footage (S3, S4, S6, S7, S10, S22, plus S29 buffer if used).

3. **"wolves" / "wolf" appears 4× across slides + notes** — all in approved keystone-list contexts:
   - S6 (slide 6) uses the bear+white-wolf clip — cinematic visual, no text claim.
   - S7 notes: *"the coast you just saw — full of bears and wolves and eagles and sea lions"* — describing the prior cinematic, not a herring-corpus data claim.
   - S12 (Three Keystones) lists *"Bears · wolves · eagles · sea lions · salmon"* under the **Ecological** column as the channel-of-coastal-productivity narrative — outline-mandated wording.
   - No text anywhere attributes wolves to the herring **empirical / model** corpus. Hard-rule #11 satisfied.

---

## Number Audit Summary

| Claim | Expected | Found on slides | Status |
|-------|----------|-----------------|--------|
| Synchrony φ | 0.17 → 0.28 (>60% post-1994) | S17, S22, X2 (slides 17, 22, 32) | **PASS** |
| Synchrony retired pair | NEVER `0.31` / `0.40` | 0 rendered hits (only as self-policing comment in `.py` headers) | **PASS** |
| Predator demand | ≈⅓ standing stock / ~29% removal analogue | S22 (slide 22), S25 (slide 25) | **PASS** |
| Predator demand retired figure | NEVER `239%` | 0 hits (slides + notes) | **PASS** |
| SOK 1995 | $62.88/lb | S11 (slide 11), S12 (slide 12) | **PASS** |
| SOK 2004 | $11–14/lb | S11, S12 | **PASS** |
| SOK alternate (X4 only) | $40/lb (1995) → <$6/lb (2004) | X4 (slide 34) | **PASS** (outline-sanctioned alt) |
| Last HG roe | 2002 | S11, S12, X3 (note "since 2002"), X4, B5 | **PASS** |
| SOK closed | 2004 | S11, S12, X4, B5 | **PASS** |
| 0 t harvest | 2025 | S26 (slide 26), X4, B5 | **PASS** |
| Drift check | No `2003` | 0 hits | **PASS** |
| P(SB<LRP) | 0.38 at zero catch | X3 (slide 33), exact `P(SB < LRP) = 0.38` | **PASS** |
| "Recovery is a moving target." | S1 + S30 only | Slide 1 + slide 30 (slide bodies) + matching notes on those same two slides | **PASS** |
| "tipping point" | S1 + S28 spine-only | S1 (kicker), S28 (reframe); also backup-only X4/B3/B5 (outline-sanctioned) | **PASS** (spine) / **P2 note** (backup pool) |
| Productivity decline | ~8-fold | S18 (slide 18), S24 (slide 24 summary) | **PASS** |
| Synchrony increase | ~60% post-1994 | S17, S22, S24, X2 | **PASS** |
| m1_stier_11 | S15 methods + S16 source | Slide 15 (methods card), slide 16 (source) | **PASS** |

## Forbidden-Phrase Sweep

| Phrase | Expected | Found | Status |
|---|---|---|---|
| `stakeholders` | 0 | 0 | **PASS** |
| `human dimensions` | 0 | 0 | **PASS** |
| `Indigenous communities` (collective-noun for Haida) | 0 | 0 | **PASS** |
| `kʼaaw economy persisted intact` (or "economy persisted") | 0 | 0 | **PASS** |
| `demonstrated cause` (predators/elders) | 0 | 0 | **PASS** |
| `proved` / `proves` | 0 | 0 | **PASS** |
| `239%` | 0 | 0 | **PASS** |
| `0.31` (synchrony retired) | 0 rendered | 0 in slides; 2 in source comments (self-policing) | **PASS** |
| `0.40` (synchrony retired) | 0 rendered | 0 in slides; 2 in source comments (self-policing) | **PASS** |
| `2003` (date drift) | 0 | 0 | **PASS** |

## Citation Presence Audit

| Citation | Outline-required slide(s) | Found | Status |
|---|---|---|---|
| Stier et al. 2020 Ecosphere | S5, S14, S17, S19, S20, S22, B1, B2, B3, B5, X4 | Present on all | **PASS** |
| Okamoto et al. 2020 | S20, S25 | Present | **PASS** |
| McKechnie et al. 2014 PNAS | S9, B4 (footer) | Present | **PASS** |
| Shelton et al. 2014 | S25 | Present | **PASS** |
| MacCall 2019 | S5, S23, B4 | Present | **PASS** |
| Ono et al. 2025 Nature | S23, B4 | Present | **PASS** |
| Jesmer et al. 2018 Science | S23 | Present | **PASS** |
| R. v. Gladstone 1996 | X4, B5 | Present | **PASS** |
| 2024 HG Herring Rebuilding Plan (RP 2024) | S11, S12, S25, S26, B2, B4, X4, B5 | Present (28 hits) | **PASS** |
| Schindler et al. 2010 | X1 | Present | **PASS** |
| DFO Pacific Herring SR 2024/2025 | S13, X3, B1, B2 | Present | **PASS** |

## Disclaimer-Presence Audit

| Slide | Required disclaimer | Found verbatim on slide |
|---|---|---|
| S22 | "Leading hypothesis — NOT a fitted HG coefficient" | **Yes** — italic line `"Leading hypothesis — NOT a fitted HG coefficient (claim-control)."` |
| S23 | "consistent-with, modest, regional, descriptive — not demonstrated as cause at subpopulation scale" | **Yes** — italic line at strip bottom of slide 23, verbatim |
| S28 | "I'd argue no" tipping-point reframe; "Spatial early-warning is an open hypothesis — not a result" | **Yes** — frontier-hedge line + final question, both present |

---

## Recommendation

**SHIP.** The deck is claim-control-compliant. No P0 ship-blockers. The one P1 (S19 `2027 in prep` forward citation) is an Adrian-call — defensible in Q&A as forward-reference to the metapopulation manuscript, but could be trimmed for total citation hygiene. The P2 notes are scope clarifications where the QA hard-rules were overscoped (backup-pool tipping-point uses are outline-mandated; Pacific Wild credit cannot be required on synthetic-animation slides).

**Bottom line: Adrian can give this talk in ~75 minutes without scientific embarrassment on any of the auditable numbers.**

---

*Auditor's note. The deck source modules (`slides_v36/*.py`) each carry a docstring header with the claim-control hard-rule for that slide, written as a self-policing reminder (e.g., `s17.py`: `"CLAIM-CONTROL CRITICAL: synchrony φ: 0.17 → 0.28 (>60% increase). NOT 0.31 → 0.40 (that was an old/incorrect pair)."`). This pattern surfaced retired numbers as documentation while keeping them out of rendered text — a good defensive engineering pattern worth preserving in future builds.*
