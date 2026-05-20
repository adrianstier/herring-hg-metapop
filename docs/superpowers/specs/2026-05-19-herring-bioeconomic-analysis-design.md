# Design Spec — Bioeconomic Analysis of the Pacific Herring Fishery (Coastwide BC & Haida Gwaii)

- **Date:** 2026-05-19
- **Author:** Adrian Stier (analysis voiced through a fisheries-economist lens — "Costello hat")
- **Status:** Approved design, ready for implementation planning
- **Deliverable type:** Standalone companion economics paper + reusable bioeconomic compendium, informed by (never feeding back into) the herring metapopulation biology
- **Sibling biology repo:** `/Users/adrianstier/stier-2027-herring-metapopulation` (model `m1_stier_11`)

---

## 1. Motivation & the gap

The Pacific herring fishery — coastwide British Columbia and especially Haida Gwaii (HG) — has a well-told *qualitative* economic history but **no formal economic analysis**. A targeted NotebookLM synthesis of the 151-source "Herring Haida Gwaii" library establishes three things:

1. **The narrative and several value series already exist** (Powell 2012 *Western Historical Quarterly*; DFO Pacific Region IFMP; Jones 2000/2007; Hourston 1980; Stocker 1993; Stier et al. 2020 *Ecosphere*). Numbers in hand: coastwide catch peak >200 kt/yr early 1960s (240 kt in 1963); HG record 77,500 t in 1956; roe fishery born 1972 on the collapse of Japan's domestic herring fishery; coastwide roe value ≈ $50M/yr 1993–2002 → ≈ $12M (2004) → $2.78M (2006); SOK 1977 = 111 t/$1.2M → 1996 = 256 t/$22.4M; SOK price $40/lb (1995) → <$6/lb (2004); DFO IFMP "Figure 9" is a digitizable coastwide roe-seine value series 1992–2004.
2. **The economics has never been done.** The sources are explicitly silent on: an estimated demand curve, supply/demand identification, stock-vs-demand decomposition, rent dissipation, MEY/optimal-control counterfactuals, and *any* quantitative accounting of post-2002 losses (rents, jobs, GDP, buybacks).
3. **The identification problem is solved by history**, not econometric contortion: roe demand appeared in 1972 for reasons exogenous to the BC stock (Japan's domestic collapse) and decayed through the 1990s while the resource was still present.

**Contribution:** the first bioeconomic accounting of a coastal forage-fish collapse and its non-recovery, complementary to the metapopulation/portfolio biology.

## 2. Goal & scope

**Goal.** Reconstruct the full bioeconomic time series of the BC/HG herring fishery and analyze, in parallel, four economic questions about its collapse and non-recovery.

**In scope.** 1950–present backbone; 1972–2006 roe era as the quantitative core; coastwide (5 BC SARs) + HG focus; commercial roe, SOK/k'aaw, food-and-bait, reduction-era; First Nations (Haida; Heiltsuk as comparative) economy.

**Out of scope.** Re-estimating biology (imported from `m1_stier_11`); a full coastwide ecosystem-services valuation beyond herring; predator-economics (lives in the predator repo).

## 3. Core architecture — shared backbone + four lenses

A/B/C/D are **not four studies**; they are four lenses on one reconstructed bioeconomic object. Build the backbone once, query it four ways.

**Unifying comparative spine:** HG = the engine that *stopped* (series effectively ends ~2002, FSC-only after) vs. coastwide BC = the engine that *kept running* (long, price-rich, still active). This asymmetry is the experimental contrast that lets every lens make causal — not merely descriptive — claims; coastwide is the control group and the demand-side identification source.

### 3.1 Shared backbone (built once), four layers
- **L0 · Institutions / regime timeline** — reduction era; 1967/68 moratorium; 1972 roe birth; 1983 fixed harvest rate; open access → 1998 IVQ "pool" system (seine pools ≥8, gillnet ≥4); HG closures 1999–2001 and 2003–present; 2013 reopening conflict; Davis Plan; *R. v. Gladstone* 1996; co-governance (AMB, CHN Haida Fisheries, PNCIMA).
- **L1 · Biology (imported, not re-estimated)** — biomass, recruitment, section-level exploitation from `m1_stier_11`.
- **L2 · Harvest** — catch by area / gear / end-use (reduction → food&bait → roe → SOK/k'aaw → FSC), effort, fleet, regime.
- **L3 · Market** — ex-vessel & roe price, Japanese *kazunoko* import quantity & value, CAD–JPY FX, competitor (Alaska/Russia) supply, substitute prices, deflators. Real terms, both CAD and JPY.
- **First Nations / SOK / k'aaw economy is an elevated component, not a Harvest row** — non-market, food-security, and constitutional-right value with separate governance.

### 3.2 Firewall (one-directional coupling)
Economics **imports** biological outputs (biomass, recruitment, section exploitation) from `m1_stier_11` and **never feeds back** into the biological model. Same convention as the predator-repo integration. Imported series are provenance-tagged with model branch and decision-ledger status.

## 4. The four lenses

| Lens | Question | Method | The documented silence it fills |
|---|---|---|---|
| **C · Market structure** (critical path) | Was the fishery stock-driven or demand-driven? How did price/demand/supply co-evolve? | Structural simultaneous system: inverse roe demand (Japan income, CAD–JPY FX, competitor supply, substitutes) + landings/supply (price, imported stock, regime dummy). Identify off the 1972 demand birth & 1990s demand decay. Variance decomposition stock-vs-demand; cointegration + error-correction if series are I(1); SVAR with regime breaks as robustness. | No estimated demand curve; no supply/demand identification; no stock-vs-demand decomposition. |
| **A · Cause** | Did the economics drive the collapse and lock in non-recovery? | Open-access entry / derby-effort model coupled to imported stock dynamics; test whether profit-targeting alone reproduces spatial homogenization & portfolio erosion (Stier 2020: 15–20% aggregate vs 65% local); economic hysteresis (stranded capital, market death, license collapse) as a human lock-in beside ecological hypotheses. | Mechanisms described, never modeled bioeconomically. |
| **B · Consequence** | What was lost, and by whom? | Producer + consumer surplus from C; discounted foregone-rent stream 2002→present (counterfactual landings × price); distributional split (industrial fleet vs Haida vs Heiltsuk); co-developed non-market k'aaw/FSC + food-security value. | Zero quantitative post-2002 loss accounting. |
| **D · Counterfactual** | What would economically rational management have done? | Deterministic optimal control / dynamic programming on the fitted metapopulation model: realized path vs MEY vs MSY vs spatial-portfolio-optimal; rent dissipated open-access/derby vs IVQ; value of the place-based scale-matched governance Stier 2020 recommends. | No MEY, no optimal-control counterfactual, no rent-dissipation estimate. |

A, B, D are extensions of C's estimated system + imported biology, and can be drafted in parallel once C exists.

## 5. Data acquisition plan — tier 3 (full fidelity), sequenced so analysis never blocks

**Critical path (fast, desk-acquirable):**
- Digitize Powell 2012 value/price figures and the DFO IFMP "Figure 9" coastwide roe-seine value series 1992–2004.
- Sea Around Us / Melnychuk et al. 2021 global ex-vessel price database (already in the user's NotebookLM library) for Pacific herring by country-year.
- Japan Customs *kazunoko* import quantity & value; FAO trade as cross-check.
- Bank of Canada CAD–JPY FX and Canadian/Japanese deflators.
- Import `m1_stier_11` biological outputs.
→ produces **backbone v1** in days, with no gatekeepers.

**Upgrade track (parallel, slow, never blocks the analysis):**
- DFO Pacific Region landed-value series and fleet cost-and-earnings history (data request; needs DFO economics contact).
- IFMP economic series beyond the digitized figures.
- **Co-developed Haida / CHN Haida Fisheries Program valuation of k'aaw & FSC value**, governed by First Nations data sovereignty (OCAP / CARE principles). This is an ethical requirement *and* a credibility requirement: the equity finding must be co-owned. Heiltsuk treated as comparative (the 40%-of-gross community-reinvestment model; *Gladstone* right).

As upgrade-track series land, the corresponding backbone series move from approximate to high-fidelity and **B and D are re-run** at higher resolution. C and A run to completion on backbone v1 regardless.

## 6. Deliverable

1. **Standalone companion economics paper** — working frame: *"the first bioeconomic accounting of a forage-fish collapse that didn't come back."* Four lenses = four results sections. Shares the biological backbone with the 2027 metapopulation paper but is a separate, self-contained manuscript and (eventually) its own reproducible repo.
2. **Reusable reconstructed bioeconomic dataset** as a research compendium (documented, provenance-tagged, deflated; the first such object for this fishery).
3. **Co-governance / solutions section** landing the B (equity) and D (optimal-management) findings into the project's existing governance-under-uncertainty payload, co-owned with CHN where it concerns Haida value.

## 7. Phased work plan (for the implementation plan to expand into milestones)

- **Phase 0 — Desk backbone (days).** Reconstruct backbone v1 (L0–L3 + imported biology); document units, deflation, provenance; HG + 5 coastwide SARs.
- **Phase 1 — Lens C (critical path).** Estimate the structural demand/supply system on backbone v1; stock-vs-demand decomposition; identification diagnostics.
- **Phase 2 — Lenses A, B, D in parallel.** Each extends C's estimated system + imported biology.
- **Upgrade track (parallel throughout).** DFO requests + Haida co-development; series upgrades; re-run B & D.
- **Synthesis.** Companion paper draft + compendium release + co-governance section.

## 8. Risks & mitigations

- **Upgrade-track data never arrives / is slow.** Mitigation: the desk backbone is a complete working spine; B/D ship at approximate fidelity with explicit uncertainty, sharpen later. Project is never blocked.
- **First Nations data sovereignty.** Mitigation: k'aaw/FSC valuation is co-developed and co-owned (OCAP/CARE); no extraction of Haida data without CHN partnership; Heiltsuk material used only from published sources unless co-developed.
- **Identification weakness.** Mitigation: the historical demand shocks (1972 birth, 1990s decay) are strong structural instruments; triangulate with SVAR + cointegration; report robustness.
- **Biology coupling drift.** Mitigation: pin imported series to a specific `m1_stier_11` branch via the model-decision ledger; one-directional firewall enforced and documented.
- **Scope sprawl across four lenses.** Mitigation: shared backbone enforces one consistent dataset; phasing makes C the gate; A/B/D are bounded extensions, not new studies.

## 9. Key sources (provenance for the design claims)

Powell 2012 (*Western Historical Quarterly*, BC herring reduction→roe economic history, SOK value series, open-access/overcapitalization, Heiltsuk Band Council reinvestment); Jones 2000 (*Just Fish*) & Jones 2007 (Haida oral history & herring management); Hourston 1980 (decline & recovery of Canada's Pacific herring); Stocker 1993 (management policy evolution); Stier et al. 2020 *Ecosphere* (portfolio erosion; 15–20% aggregate vs 65% local exploitation); *R. v. Gladstone* [1996] 2 S.C.R. 723 (Heiltsuk right to sell roe); Jones, Rigg & Lee 2010 *Ecology & Society* (Haida marine planning / co-governance); Melnychuk et al. 2021 (global ex-vessel price database); DFO Pacific Region Herring IFMP (value figures, IVQ-pool regime). Citation grounding rule applies to any manuscript text downstream: verify each via NotebookLM → Zotero → PubMed/bioRxiv before drafting.

## 10. Decisions deferred to the implementation plan

- Standalone repo location/name and its relationship to the metapopulation repo (companion vs. submodule).
- Exact econometric package/stack (R: `systemfit`/`AER`/`vars`/`urca` vs. a Bayesian structural variant) — to follow repo conventions.
- Discount-rate and deflator conventions; choice of MEY objective for D.
- Sequencing of DFO contact and CHN co-development outreach.
