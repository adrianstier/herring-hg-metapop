# SOK vs Sac-Roe Quota Accounting — and whether it is "fair" under Shelton et al. 2014

**Purpose.** Answers a recurring talk/manuscript question: *outside Haida
Gwaii, where commercial spawn-on-kelp (SOK) still operates, is SOK "fairly"
quota'd given Shelton et al. 2014's egg-vs-adult harvest asymmetry?* It
documents (a) what the DFO rules **actually** do, (b) the Shelton-fair
benchmark, (c) the conservatism/equity gap, (d) the caveats that forbid a naive
"loosen SOK" conclusion, and (e) the bioeconomic Lens D hook.

**Status: interpretive governance analysis, not a model input.** Like
`herring-non-recovery-hypotheses.md`, this informs how we *read* and *talk
about* results. It does not change `m1_stier_11` or any data product, and it is
firewalled from the modeling pipeline. Keep consistent with `AGENTS.md`,
`docs/talk-model-claim-control-sheet.md`, and the citation-grounding rule.

**Primary sources (in repo, page numbers verified by text extraction):**
- DFO 2024/2025 Pacific Herring **IFMP**, 242 pp —
  `Output/diagnostics/dfo_assessment_public_sources/dfo_herring_ifmp_2024_2025.pdf`
- **2024 Haida Gwaii Herring Rebuilding Plan** (CHN / DFO / Parks Canada) —
  `analysis/04_talks/2026-royalsociety/Reference_Papers/HG_Herring_Rebuilding_Plan_2024_CHN_DFO_ParksCanada.pdf`
  (mirror: `Output/diagnostics/dfo_assessment_public_sources/dfo_hg_rebuilding_plan_2024.pdf`)
- Shelton, Samhouri, **Stier** & Levin 2014, *Sci. Rep.* 4:7110 —
  `Literature/Shelton_et_al_2014_SciReports_Herring_Egg_Limitation.pdf`
  (the `Stier_et_al_2014_SciReports_Egg_vs_Adult_Harvest_Tradeoffs.pdf` file is
  byte-identical — same paper, alias filename).
- Newell 1999, *Spawn-on-Kelp Fishery, Northern BC* —
  `Literature/Newell_1999_Spawn_on_Kelp_Fishery_Northern_BC.pdf`
  **(image-only scan; not yet OCR'd — cited as a known source, not quoted).**

---

## (a) What the rules actually do

**One biomass-based TAC, split across four commercial fisheries.** Science
advice is set as spawning biomass in metric tonnes (CSAS process), converted to
short tons for planning; **after FSC needs are met**, "commercial fishery
quotas are set and allocations are distributed across the four commercial
herring fisheries" — seine roe, gillnet roe, **SOK**, food-and-bait/special use
(IFMP §6.3, p77; §1.5, p23). FSC priority-after-conservation flows from
*Sparrow* 1990; the **Heiltsuk hold the only Aboriginal right to fish SOK
*commercially*** (*R. v. Gladstone* 1996; IFMP p156–157).

**SOK is landed and quota'd in pounds of *product*, not whole fish.** The
roe fishery quota is short tons of whole herring; SOK quota is pounds of
spawn-on-kelp product (e.g., Heiltsuk 304,000 lb across 19 equivalent licences;
coastwide SOK landings reported e.g. 77 short tons = 153,000 lb in 2013, 310
short tons = 619,000 lb in 2017; IFMP p157, p30).

**The bridge is an explicit whole-herring ↔ SOK conversion rate.** Treaty
allocations are stated as "*X* short tons of whole herring **or a corresponding
amount of herring spawn on kelp … in accordance with the conversion rates for
whole herring to herring spawn on kelp** … as described in the [Maa-nulth /
Tla'amin] Fisheries Operational Guidelines" (IFMP p120). So DFO debits SOK
product against the single biomass TAC through a documented conversion.

> ⚠️ **Not verified in repo:** the *numeric* conversion coefficient lives in
> the **Maa-nulth / Tla'amin Fisheries Operational Guidelines** (treaty
> operational annexes), which are *referenced* by the IFMP but not reproduced
> in it and are not in this repo. Do not put a specific lb-SOK-per-tonne-herring
> ratio on a slide or in the manuscript until that document is obtained and
> grounded (NotebookLM → Zotero → DFO). Newell 1999 likely carries the
> historical basis but is an un-OCR'd image scan.

**The only life-stage differentiation DFO makes** is in the 2024 HG Rebuilding
Plan, which models allocation scenarios separately for **open-pond SOK (oSOK)**,
**closed-pond SOK (cSOK)**, and **seine-roe (SR)**, and charges explicit
**ponding-induced mortality** to cSOK (closed-pond impounds fish, then "post-
season release of ponded herring"; oSOK takes no adults) (Rebuilding Plan
Tables 7, 24; IFMP §5.4.1 p41). All rebuilding procedures share **one harvest
control rule**: HS30-100 — target HR = 0 below LCP = 0.30·B₀, rising linearly
to a **maximum reference harvest rate of 10%** at UCP = 1.00·B₀; LRP = 0.30·SB₀,
USR = 0.75·SB₀ (Rebuilding Plan Table 7). Note this 10% cap is well below the
legacy ~20% rate and the 0.25·B₀ cut-off that Shelton et al. used.

**HG-specific:** Major SAR last commercial roe fishery 2002, last SOK 2004;
persistent low biomass since the 1990s with rising natural mortality; no
commercial fishery since; FSC k'aaw only (Rebuilding Plan §; DFO SR 2025/005).
The live commercial SOK question is therefore **coastwide** — Central Coast
(Heiltsuk, *Gladstone*), Prince Rupert District (10 SOK licences, 5% HR), etc.

## (b) The Shelton-fair benchmark

Shelton et al. 2014 show an **asymmetry**: stocks tolerate egg-harvest rates of
roughly `h_egg` ≈ 0.7–0.9 before depletion vs. `h_adult` ≈ 0.5 for the lethal
fishery. The paper attributes this to **(1) harvest order** — the sac-roe
fishery kills mature fish *immediately before they spawn*, forfeiting that
year's entire egg contribution — and **(2) density-dependent (Beverton–Holt)
recruitment**: "relatively low numbers of eggs can still produce a substantial
number of recruits two years later." Iteroparity (repeat spawning) is the
life-history backdrop that makes adult removal especially costly, but it is
*not* the headline mechanism the paper credits. A *Shelton-fair* system would
let the egg fishery operate at a materially **higher** allowable rate than the
lethal adult fishery, because a unit of herring "spent" as SOK eggs is far
cheaper to the stock than a unit spent as killed pre-spawn adults.

## (c) The conservatism / equity gap

The DFO conversion is a **product↔whole-fish mass-and-mortality bridge, not a
population-impact discount.** The single biomass TAC and the shared HS30-100
harvest rate are applied to spawning biomass *regardless of whether the take is
lethal roe or non-lethal SOK*. The closest DFO comes to life-stage accounting
is the cSOK ponding-mortality charge and the oSOK/cSOK/SR scenario split — that
captures "closed-pond kills some fish," but **not** the Shelton recruitment-
compensation asymmetry (egg removal buffered by density-dependent recruitment).
Consequences:

- SOK is debited as if its biomass cost equalled the lethal fishery's. By
  Shelton's logic that is **conservative against SOK** — it under-rewards the
  lower-impact, culturally central fishery.
- Within a shared TAC, structurally the higher-impact lethal roe fishery draws
  on a currency that **ignores the asymmetry**, effectively cross-subsidised by
  the egg fishery's unrecognised lower footprint.

So, strictly on the asymmetry: **no, it is not "fairly" quota'd — it is quota'd
conservatively relative to SOK's true population impact.**

## (d) Why this does NOT license "give SOK more quota"

Shelton et al. is explicitly **strategic, not tactical**, and three of its own
findings — plus the current DFO precaution — block a naive liberalisation:

1. **The safe zone collapses under recruitment variability.** At high
   recruitment CV almost no harvest combination avoids closures. Depressed,
   low-productivity stocks (HG: rising M, persistent low state) are exactly
   where egg-removal compensation is weakest.
2. **Single well-mixed stock, perfect knowledge.** Shelton's model has no
   spatial portfolio (cf. Stier 2020 / Okamoto 2020). A coastwide "egg harvest
   is safe" inference can still locally over-harvest a structured stock — the
   central HG lesson.
3. **Eggs are also an ecosystem subsidy.** Shelton's own `B_ecosystem`
   ("one-third for the birds") analysis flags spawn-on-substrate as predator
   food; SOK removes some of it independent of adult survival.
4. **DFO already applies strong precaution** that partially closes the gap: a
   10% max HR (half the legacy rate, and far below `h_egg` ≈ 0.7), LRP =
   0.30·B₀, oSOK/cSOK/SR separation, and explicit ponding-mortality.

**Defensible statement:** Shelton supports the *principle* that commercial SOK
can sustainably bear a higher rate than an equivalent lethal fishery, making a
flat shared-biomass conversion biologically conservative and arguably
inequitable to SOK; but Shelton provides **no conversion factor**, and its own
caveats forbid loosening SOK quotas for depressed or spatially structured
stocks without recruitment-variability and spatial-portfolio accounting —
especially at HG.

## (e) Bioeconomic Lens D hook

This is precisely the question the companion bioeconomic analysis's **Lens D
(rational-management counterfactual)** is built to interrogate
(`docs/superpowers/specs/2026-05-19-herring-bioeconomic-analysis-design.md` §4):
a rational manager who priced the Shelton asymmetry would shift allocation
toward the low-impact, non-lethal egg fishery and away from the lethal
pre-spawn roe fishery — and would *not* run both off one undifferentiated
biomass currency. Quantifying that reallocation (rent, equity, and the value of
the *Gladstone*/k'aaw-aligned low-impact fishery) is a Lens D / Lens B
deliverable, firewalled from `m1_stier_11`.

## Claim-control quick reference

| Safe to say | Do not say | Source |
|---|---|---|
| SOK and roe are separate fisheries sharing one biomass TAC, bridged by a documented whole-herring↔SOK conversion rate. | "A pound of SOK eggs counts the same as a pound of roe from killed adults" (false — different units, bridged by a conversion). | IFMP §6.3 p77; p120 |
| DFO differentiates oSOK/cSOK/SR and charges cSOK ponding mortality, but applies one shared HCR (max 10% HR). | "DFO discounts SOK for the egg-vs-adult population asymmetry." (It does not — only mass/mortality.) | Rebuilding Plan Tables 7, 24 |
| By Shelton's asymmetry, SOK is quota'd conservatively relative to its true population impact. | "Therefore SOK quotas should be raised." (Shelton is strategic; caveats forbid this, esp. at HG.) | Shelton 2014; this doc §d |
| The exact SOK↔herring conversion coefficient is in treaty Operational Guidelines, not yet grounded in repo. | Any specific lb-per-tonne ratio. | IFMP p120 (referenced, not stated) |

## Open grounding actions

1. Obtain the **Maa-nulth / Tla'amin Fisheries Operational Guidelines** (and/or
   the IFMP SOK Appendix 8 conversion table) for the numeric coefficient;
   ground via the "Herring Haida Gwaii" NotebookLM library
   (`63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`) → Zotero → DFO.
2. OCR `Literature/Newell_1999_Spawn_on_Kelp_Fishery_Northern_BC.pdf` for the
   historical conversion basis (open- vs closed-pond accounting origin).
3. If used on a slide, route through `docs/talk-model-claim-control-sheet.md`.
