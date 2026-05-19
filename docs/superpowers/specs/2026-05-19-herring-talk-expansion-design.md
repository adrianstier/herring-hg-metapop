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
Tight honest m1_stier_11 description (Bayesian state-space metapopulation;
spawn-index data; 11 sections; spatially-correlated process error;
survey-scaling; ambiguous zeros = missing) explicitly framed as the
published, peer-reviewed **Okamoto et al. 2020 (Ecol Appl)** approach,
extended. ~40 s. Claim-control safe (no fitted predator coefficient claim).

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

## Deadline note

Talk is tomorrow. Per explicit user go-ahead ("ok do that"), the brainstorming
pipeline is compressed: this design doc stands as the spec; implementation
proceeds via an ordered task checklist rather than a separate
writing-plans/executing-plans cycle (user-instruction precedence + same-day
deadline). Spec committed for the record.
