# Royal Society herring talk — 10 → 15-20 min expansion (design)

Date: 2026-05-19 · Talk: Wed 2026-05-20, US–UK Forum Session 5 (Ecosystem
Services), ~40 tipping-points/regime-shift experts, chair wants
solutions-forward. Approved approach: **A — "Predator pit → moving target"**,
balanced (deepen one evidence beat + a layered concept→fix→general finish),
plus an opening **sense-of-place locator** and early-arc retune.

## Narrative spine (ABT)

Herring fed Haida Gwaii for ~10,000 years **and** we can measure it precisely,
**but** one collapse never recovered because the *system itself changed*
(predation regime flip + spatial-portfolio erosion), **therefore** recovery is
a moving target and historical reference points are the wrong yardstick —
reset the reference points and the expectations.

## Slide changes (3 new slides + light retunes)

### 1. NEW S1b — "Sense of place" (locator), right after S1 Title
- Full-bleed `deck_build/photos/s_locator_l2.png` = globe → North America →
  Haida Gwaii archipelago inset, on black (matches deck dark bg). Borrowed
  from EEMB142C L2 deck slide 10 (Adrian's own teaching asset; treat like
  the other L2 imports).
- Masthead + a place title + a one-line roadmap of where the talk goes:
  every spring the shore comes alive → predators and people show up → then
  it changed → what that means for "recovery".
- Notes: orient a non-local expert audience geographically; preview the arc.

### 2. Early-arc retune (S2, S3, S3.5) — no new slides
Opening reads: **place (S1b) → "every spring, herring spawn — the shore comes
alive" (S2) → "and the whole system shows up: predators and people" (S3
people + S3.5 wasp-waist)**. Copy/speaker-note tweaks only; S2 keeps the
spawn video, S3.5 keeps the wasp-waist diagram. Deep-time (10,000-yr) framing
stays at S4 (baseline measured).

### 3. NEW S10b — "The predator pit" (baked figure, after S10 two-oceans)
> ⚠️ **CORRECTED 2026-05-19 (Adrian caught it):** the "≈239% of spawn"
> framing below is **RETIRED — do NOT reintroduce it.** `HG_spawn_kt` is the
> DFO spawn *index* (a survey index, not the standing stock), so "239% of
> spawn" reads as biologically impossible. S10b ships with the talk-safe
> `predator_talk_brief.md` framing instead: predators take ≈15.5 kt/yr ≈ a
> third of the ≈47 kt m1_stier_11 stock (≈29% removal analogue). Built.
- Reuse SB2 species data + pressure index: predator demand ≈239% of HG annual
  spawn (2015–24); humpback ~5.0 kt + Steller sea lion ~2.4 kt dominate.
- Argument: a *different process now sets the ceiling* — closure removed
  fishing (≈0-t HG catch since 2002) but a recovered predator field holds
  herring at the low state (consumptive lock-in / alternative stable state);
  removing the original stressor cannot reverse the tip.
- **Guardrail (loud on-slide + notes): audited predator demand/pressure,
  NOT a fitted m1_stier_11 mortality coefficient; the lock-in is presented
  hypothesis-strength on causality.**

### 4. NEW S12b — "The reference-point problem" (native, after S12)
- Mirrors S12 chrome. Argument: DFO's LRP is anchored to a historical
  unfished-biomass baseline the regime-shifted system cannot return to, so
  the stock is "below LRP" almost by construction.
- Killer stat (promoted from the B-DFO backup): DFO SR 2025/005 — even at
  **zero catch since 2002, P(SB2025 < LRP) = 0.38**; not fishing is not
  enough.
- Prescription: dynamic / ecosystem-conditioned reference points; judge
  recovery against the achievable new equilibrium; reset management +
  stakeholder expectations; co-governance to negotiate what "recovery" means
  across ecology / culture / economy.
- Claim-safe caption: m1_stier_11 + DFO SR 2025/005; co-governance is an
  institutional milestone, not an outcome metric.

### 5. S13 retune + S14 tweak — no new slide, no 4th lesson
- Re-point lesson 3 + amber footer to generalize: *"Reference points and
  recovery targets must be conditioned on the current system state, not a
  historical baseline — wherever a system has crossed a hysteretic
  threshold."*
- S14: one tweak so it explicitly lands the reference-point/expectations
  punchline; keep "A century of change — recalibrate what herring is" + the
  S3.5 tie-back.

## Timing (target ~18 min)

Setup (S1, S1b, S2, S3, S3.5, S4) ~4 min · Mechanism (S5–S9b) ~6 min ·
Predator regime (S9c, S10, S10b) ~3 min · Finish (S11, S12, S12b, S13, S14)
~5.5 min. Compressible-on-the-day (skip-safe per speaker notes): S6, S9b.

## Constraints / guardrails (must hold)

- Predator demand = a large ecological pressure, NOT a fitted m1_stier_11
  coefficient (claim-control sheet).
- "~10% of historic / alternative stable state" cites m1_stier_11 + DFO SR
  2025/005; DFO SCA summaries are public context, not likelihood validation.
- Co-governance = institutional milestone, not an outcome metric.
- Reference-point critique is a scientific argument, not a DFO-bashing claim.
- No new analysis; reuse existing audited data/assets only.

## Build footprint

+3 slides (S1b full-bleed image; S10b baked via `redesign_figs.py` +
`preprocess_figures.py` JOBS; S12b native in `build_pptx_native.js`) + light
retunes (S2/S3/S3.5 notes, S13/S14 text). Deck → ~30 slides incl. backups.
Pipeline: redesign → preprocess → node build → PDF QA → dated checkpoint →
board log → quit+reopen PowerPoint (cache).

## ADDENDUM (2026-05-19, post-approval) — 3 more elements + timing

Okamoto et al. 2020 *Ecol Appl* ("Spatial variation in exploited
metapopulations obscures risk of collapse"; Okamoto, Hessing-Lewis,
Samhouri, Shelton, **Stier**, Levin, Salomon) is Adrian's own co-authored
paper — it is the published basis for the scale-mismatch analysis AND
states the solution explicitly: dynamically optimizing harvest minimizes
local risk without sacrificing yield; multiple nested scales of management;
ecological, social, economic consequences. It legitimizes the methods and
supplies the solution.

### §5 — Methods/legitimacy slide (NEW native, after S4)
**CORRECTION (Adrian 2026-05-19): methods ≠ Okamoto. Do NOT frame the
methods slide as "the Okamoto approach."** Okamoto et al. 2020 is the
SOLUTION slide (§7), not the methods citation. The methods slide legitimizes
OUR analysis on its own merits: a tight, honest m1_stier_11 description —
Bayesian state-space metapopulation model; DFO spawn-index data; 11 sections
(focal-9 reporting); spatially-correlated process error; survey-scaling
prior; ambiguous zeros treated as missing; updated/extended from Stier et
al. 2020 (Ecosphere) metapopulation lineage. Purpose: a non-fisheries
tipping-points audience trusts the inference. ~40 s. Claim-control safe (no
fitted predator coefficient claim). Okamoto-2020 is referenced ONLY on §7.

### §6 — Economics↔ecology slide (NEW native, feeding S11)
Resolved framing: **coupled supply + demand**, not either/or. The BC
sac-roe fishery existed only via a narrow foreign-demand niche — Japanese
*kazunoko* demand created by Japan's own (Hokkaido) Pacific-herring
collapse. Then BOTH failed: Japanese demand fell (post-1990s consumption
change) AND ecological supply collapsed (HG stock + closures). Herring's
*market* value evaporated while its *ecological + cultural* value (forage;
kʼaaw) did not — the economics were only ever legible as extracted export,
decoupled from ecological role. On-slide = sourced trajectory only (roe
value peaked 1980s→declined; SOK $62.88/lb 1995→$11–14/lb, Rebuilding Plan
§5.2.3); Japan-collapse driver flagged as documented context. Feeds S11
"value moved, didn't vanish."

### §7 — Okamoto solution slide (NEW native, immediately before S13)
Visualize the Okamoto et al. 2020 strategy as THE solution: nested-scale +
dynamically-optimized harvest allocating herring across the triple bottom
line — industry (commercial) · Haida (kʼaaw/FSC) · ecosystem (predators:
marine mammals + commercial fishes like salmon) — managed at the cove
scale, not just archipelago-wide. Attributed Okamoto et al. 2020. S13
tightened so it does not duplicate (Okamoto = the "how"; S13 = transferable
lessons).

### Timing decision (user, 2026-05-19)
**Target ~20 min, build all 6 additions, fast visual beats.** Locator
~20 s, whale ~15 s, S9b animation ~20 s; S6 (climate) + S9b explicitly
marked drop-on-the-day in speaker notes. Nothing cut from the deck.

Total new spine slides: **6** (S1b locator, methods, economics,
Okamoto-solution, S10b, S12b) + retunes (S2/S3/S3.5, S13/S14) + S6/S9b
drop-on-day notes. Deck → ~33 slides incl. backups.

## 🟢 ADRIAN'S ECONOMIC STORY — three price regimes (use to build out S10c)

Adrian supplied this directly (2026-05-19) — build the S10c economics slide
into a **three-act "price regime" diagram/concept** (price/value on y vs
time; same fish, three regimes):

- **Act 1 — Industrial input (1930s–1967):** no real price signal. Reduction
  fishery — herring → fishmeal/oil, lowest-value use; harvested for volume
  (coastwide >200 kt/yr early 1960s, 240 kt in 1963; HG record 77,500 t in
  1956 off the 1951 year-class). No ex-vessel price/t for this era in
  sources. Only high-value product = Haida kʼaaw (SOK), largely a trade
  good (bartered Tsimshian/Tlingit for eulachon grease, soapberries) or
  artisanal (Ernie Wilson: dried kʼaaw $0.22/lb, 1930s, Jedway).
  Overfishing + poor recruitment → fishery shut 1967/68.
- **Act 2 — Kazunoko price explosion (1972–~1996):** resource didn't change,
  the MARKET did. Exogenous demand shock — Japan's own domestic herring
  fishery collapsed early 1970s → fishmeal fish → luxury roe overnight
  (only female roe = kazunoko, near-price-inelastic Japanese New Year
  delicacy). Roy Jones Sr.: early-1970s roe $0.85/lb from a Vancouver
  middleman ("change the address, ship to Japan"). SOK $1.2M (111 t, 1977)
  → $22.4M (256 t, 1996); coastwide roe ~$50M/yr on ~32,000 t (1993–2002),
  seine peak ≈$40M (1993). Premium dried kʼaaw direct to Japanese buyers
  up to $24/lb.
- **Act 3 — Demand collapse (~1996–2006):** DEMAND-side, not stock-side —
  three forces all in Japan/competitors: (1) Japan post-bubble stagnation,
  (2) generational shift away from kazunoko, (3) low-cost Alaska/Russia
  supply into the same single market. SOK $40/lb (1995) → <$6/lb (2004),
  ~85% in <a decade. Coastwide roe $50M → ~$12M (2004) → $2.78M (2006).
  By 2006 near-worthless (Food&Bait $0.15/lb, Special Use $0.62/lb). HG
  fishery closed (1999–2001, then 2003–present). Full round trip —
  industrial → luxury → near-worthless — in ~35 yr; stock collapse roughly
  concurrent; **disentangling the two is the central unanswered question**
  (this is the slide's payoff line; ties to S11 "value moved, didn't
  vanish" + the reference-point problem).

**⚠️ CLAIM-CONTROL RECONCILIATION REQUIRED before these specific $ go on a
Royal Society slide.** `S8_landed_value_provenance.md` found the
*authoritative primary source* (2024 HG Herring Rebuilding Plan §5.2.3, DFO
fish slips) supports: roe value "peaked in the 1980s, high to mid-1990s,
declined 1995–2005 & post-2008"; SOK real price "$62.88/lb (1995) →
$11–14/lb recently." Adrian's numbers here ($40/lb→<$6/lb; $50M→$12M→$2.78M;
seine ≈$40M 1993) are richer/teaching-deck-sourced and **differ** from that
primary source. The three-act CONCEPT is the design; the fresh session must
have Adrian confirm which number set is citable on-slide (or present the
trajectory qualitatively + footnote the source) — do NOT silently put the
unreconciled figures on the slide. The Roy Jones Sr. / Ernie Wilson quotes
are strong colour for speaker notes.

## ▶️ RESUME HERE (continuation checklist)

> **✅ COMPLETE — 2026-05-19 ~13:55 (Session-B continuation).** ALL 6
> expansion additions + retunes are built and QA-passed. Deck final &
> shippable at **33 slides** (`Herring_RoyalSociety_Stier_2026_clean.pptx`,
> final checkpoint `..._claude-code_20260519-135454.*`). Spine: S1·S1b·S2·
> S3·S3.5·S4·**S4b**·S5·S6·S7·S8·S8b·S9·S9b·S9c·S10·**S10b**·**S10c**·S11·
> S12·**S12b**·**S12c**·S13·S14 + Q&A divider + B-DFO + SB1–SB7. The build
> order below is DONE: S4b methods (our m1_stier_11, not Okamoto); S10c
> economics rebuilt as the **3-act price-regime diagram** (on-slide $ =
> primary-source only per Adrian's 2026-05-19 AskUserQuestion call —
> Rebuilding Plan §5.2.3; richer per-era $ + Roy Jones Sr./Ernie Wilson
> quotes in speaker notes only); S10b predator-pit baked figure (audited
> pressure, loud guardrail in provenance — NOT a fitted m1 coefficient);
> S12b reference-point problem; S12c Okamoto-2020 solution; S13 lesson 3
> re-pointed to the reference-point/hysteresis generalization (no longer
> duplicating S12c) + footer tightened; S14 sub-line lands the reference-
> point/expectations punchline; S6 + S9b drop-on-the-day notes added.
> Running log: `analysis/04_talks/2026-royalsociety/Talk_Materials/SLIDE_REVISION_TODO_
> 2026-05-19.md` (newest at bottom). Only non-blocking follow-ups left:
> doc-sync of HERRING_TALK_ASSETS Talk-Build-State / deck README slide
> map / slide_asset_map (still 15-slide spine), and the backup-only SB4
> title-clip / SB5 label-collision (Q&A figs, not ship-blockers). The
> original checklist below is kept for provenance.

**State (historical):** deck known-good at **28 slides** (`Herring_RoyalSociety_Stier_2026_clean.pptx`),
builds clean. DONE: S1b "Haida Gwaii" locator (slide 2); S8b annotation
collision fixed. Talk Wed 2026-05-20.

**Pipeline (run from `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/`):**
`python3 redesign_figs.py && python3 preprocess_figures.py && node build_pptx_native.js`
→ output `../Herring_RoyalSociety_Stier_2026_clean.pptx`. QA via LibreOffice
→ PDF (`soffice --headless --convert-to pdf -env:UserInstallation=file:///tmp/loX`).
**PowerPoint caches an open file** — must `osascript quit` + `pkill` + reopen
to see changes. After each item: dated checkpoint
`Herring_RoyalSociety_Stier_2026_claude-code_YYYYMMDD-HHMMSS.pptx/.pdf`,
log in `analysis/04_talks/2026-royalsociety/Talk_Materials/SLIDE_REVISION_TODO_2026-05-19.md`.

**Build order (each = 1 native block in `build_pptx_native.js` unless noted):**
1. **Methods/legitimacy** native slide after S4 — m1_stier_11 itself (NOT
   Okamoto): Bayesian state-space metapopulation, DFO spawn index, 11
   sections (focal-9), spatial process error, survey-q prior, zeros=missing,
   extended from Stier 2020 Ecosphere. Legitimizes the inference. ~40s.
2. **Economics↔ecology** native slide feeding S11 — coupled supply+demand:
   Japan's Hokkaido herring collapse created the kazunoko import niche →
   BC sac-roe fishery built → Japanese demand fell post-1990s AND HG
   ecological supply collapsed → market value gone, ecological+cultural
   value not. On-slide numbers ONLY from `S8_landed_value_provenance.md`
   (roe value peaked 1980s→declined; SOK $62.88/lb 1995→$11–14/lb).
   Japan-collapse driver = documented context, flag if unsourced. Kazunoko
   photo in `deck_build/photos/l2_imports/` (image6.jpeg ~1440x907).
3. **S10b predator-pit** baked figure — new `redesign_figs.py` fn (content
   zone 19.2×7.5 @200dpi, NO baked title) + `preprocess_figures.py` JOBS
   entry + native fullbleed block after S10. Data: SB2 species means
   (humpback ~4.96 kt, Steller ~2.41 kt) + pressure index ≈239% of spawn
   2015–24. Message: consumptive lock-in / alternative stable state —
   closure removed fishing but recovered predator field caps recovery.
   GUARDRAIL loud: audited demand/pressure, NOT a fitted m1 coefficient;
   causal lock-in hypothesis-strength.
4. **Okamoto-2020 solution** native slide before S13 — triple-bottom-line
   allocation: industry (commercial) · Haida (kʼaaw/FSC) · ecosystem
   (predators: marine mammals + commercial fishes like salmon); nested-scale
   + dynamically-optimized harvest. Attributed Okamoto et al. 2020 Ecol
   Appl (Adrian co-author). Then tighten S13 so it doesn't duplicate.
5. **S12b reference-point problem** native slide after S12 (mirror S12
   chrome): DFO LRP anchored to historical baseline unreachable post-regime-
   shift; killer stat from B-DFO backup — even at zero catch since 2002,
   P(SB2025<LRP)=0.38; prescribe dynamic/ecosystem-conditioned reference
   points + reset expectations. Caption: m1_stier_11 + DFO SR 2025/005;
   co-governance = institutional milestone not outcome metric.
6. **S13 retune + S14 tweak** (no 4th lesson); add "drop-on-the-day" lines
   to S6 + S9b speaker notes. Final pipeline rebuild + QA + checkpoint +
   board + quit/reopen PowerPoint.

**Hard constraints:** predator demand = pressure not fitted coefficient;
"~10%/alt stable state" cites m1_stier_11 + DFO SR 2025/005; co-governance ≠
outcome metric; no new analysis; reuse existing audited data/assets only;
target ~20 min, S6+S9b drop-on-day. Coordination board has the running log.

## Deadline note

Talk is tomorrow. Per explicit user go-ahead ("ok do that"), the brainstorming
pipeline is compressed: this design doc stands as the spec; implementation
proceeds via an ordered task checklist rather than a separate
writing-plans/executing-plans cycle (user-instruction precedence + same-day
deadline). Spec committed for the record.
