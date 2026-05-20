# The Economics of Pacific Herring at Haida Gwaii — A Detailed Brief

- **Date:** 2026-05-19
- **Prepared for:** `herring-bioeconomics` (Stier Lab) — backbone for Lens A (cause), Lens B (consequence), Lens C (market structure), Lens D (optimal-management counterfactual)
- **Status:** Working research brief. Every number is sourced or explicitly labeled as schematic/derived/chart-read.
- **Companion artifacts (this repo, `docs/`):**
  - `2026-05-19-kazunoko-demand-context-brief.md` — forward-looking demand context (the "why the market won't return" piece)
  - `herring-economics-three-acts.html` — visual narrative of the documented historical price arc
  - The `talk-usuk-forum-2026/Talk_Materials/s8_value_lag_infographic.html` candidate slide (sibling repo) — talk-format version of the same story under the deck's stricter claim-control
- **One-line thesis:** The Pacific-herring fishery at Haida Gwaii has lived three economic lives — bulk industrial input, luxury kazunoko commodity, and post-closure absence — and the demand engine that made the second life valuable has **structurally faded on both blades** (Japanese hatchery recovery + demographic demand decline), so the **economic non-recovery is likely more permanent than the ecological one.**

---

## 1. The fishery before the fishery (pre-1930s) — k'aaw as currency

Pacific herring is a cultural keystone species for coastal First Nations [1, 2]. At Haida Gwaii, **k'aaw** (spawn-on-kelp) was an artisanal good and a trade currency long before any commercial commercial fishery — Skidegate Haidas traded buckets of dried k'aaw to mainland Tsimshian and Tlingit for eulachon grease, soapberries, and other goods [3, 4]. Oral history places dried k'aaw at **≈$0.22/lb in the 1930s** (Ernie Wilson, Jedway), the earliest documented per-unit price in our record [3]. There is no commercial-fishery price signal in this period; the economy was barter-and-craft.

## 2. Act I — The reduction era (≈1930s–1967): industrial input, no price record (yet)

**The harvest.** The industrial reduction fishery began in BC in the 1930s; by the 1950s exploitation rates in Haida Gwaii reached 50–90% [5]. Coastwide catch crossed **200 kt/yr in the early 1960s, peaking at 240 kt in 1963** [6, 7]. Haida Gwaii's all-time record was **77,500 t in 1956**, supported by the exceptional 1951 year-class [8] — and was taken by **just 2–3 seine boats** working January–March [5]. The product was fishmeal and fish oil, sent to poultry feed, paint, and other low-value industrial uses [9]. By 1965 most older fish had been removed, and the federal government closed the reduction fishery in 1967/68 [6, 7, 8].

**Why "no $/lb" is misleading.** The Herring Haida Gwaii NotebookLM library (151 sources) and the 2024 Rebuilding Plan are explicit that no per-unit reduction-era price appears in their texts [I-1]. But the *historical record* is not silent. The data live in:

- **DFO / Statistics Canada annual fisheries statistics** (BC herring landings + landed value by year, ≈1935+) — imputed ex-vessel $/lb = landed value ÷ landings, the mainstream method.
- **Tester (1945)** *Catch statistics of the British Columbia herring fishery to 1943-44*, Fisheries Research Board Bulletin 67 [10].
- **Stocker (1993)** *Recent management of the British Columbia herring fishery*, CBFAS [11].
- **Sea Around Us / Melnychuk-Tai global ex-vessel price database** (Melnychuk et al. 2021) — purpose-built reconstruction of real ex-vessel prices, BC Pacific herring ≈1950+ [12]. Already in this lab's NotebookLM library; the fastest desk-tier acquisition path and what `herring-bioeconomics` Task 7/L3 is designed to consume.

**What it would likely show.** In real 2020 CAD, reduction-era ex-vessel herring was almost certainly in the **≈$0.10–0.50/lb** band — *orders of magnitude* below the kazunoko-era figures below. Pulling it would convert the slide's dashed "no data" segment into a sourced floor, and would make the 1972 demand shock register visibly as a **2–3 order-of-magnitude repricing of the same fish.**

## 3. Act II — The kazunoko boom (1972–≈1996): a demand shock that rewrote the price

**The shock was exogenous to BC.** In the early 1970s **Japan's domestic herring fishery collapsed** [9, 13]. East Asian demand for *kazunoko* (herring roe) and *kazunoko konbu* (spawn-on-kelp) spiked. DFO reopened the BC fishery in 1972 in a completely new mode: high-value sac-roe (gillnet/seine the females, strip roe, reduce carcasses) plus a commercial spawn-on-kelp (SOK) fishery [5, 9, 13, 14]. Same fish, repriced in Tokyo.

**The new price regime — every figure source-stated:**

| Year(s) | Series | Figure | Status | Source |
|---|---|---|---|---|
| ~1972 | Processed roe, fisher → Vancouver middleman | **$0.85/lb** (nom) | source-stated | Roy Jones Sr. oral history [3] |
| ~1972+ | Dried k'aaw, direct to Japanese buyers | **up to $24/lb** (nom) | source-stated, undated | Harvey Williams oral history [3] |
| **1979** | **Gillnet roe herring, ex-vessel** | **$5,500/ton** (nom) | **source-stated — the cleanest per-ton anchor** | Haida Marine TEK Vol. 3 p.204 [3] |
| 1977 | SOK fishery total value | $1.2M (nom), 111 t product | source-stated | Powell/Harris 2012 *WHQ* [9] |
| 1996 | SOK fishery total value | $22.4M (nom), 256 t product | source-stated | Powell/Harris 2012 [9] |
| 1980s | BC roe-herring landed + wholesale value | **peaked** (no exact $) | source-stated (qualitative) | HG Rebuilding Plan 2024 §5.2.3.5.2 [15] |
| 1995 | SOK price (real, 2020$) — **peak** | **$62.88/lb** | **source-stated, primary, inflation-adjusted** | HG Rebuilding Plan 2024 §5.2.3.4.3 [15] |
| 1970s | SOK price (real, 2020$) | $16–31/lb | source-stated | HG Rebuilding Plan 2024 [15] |
| 1993–2002 | Coastwide commercial **roe** fishery (total, all gear) | ≈32,000 t/yr, ≈$50M/yr (nom) | source-stated (period average) | DFO Pacific Herring IFMP [16] |
| 1992–2004 | Coastwide commercial roe **seine** fishery, value | 1992 ≈$24.5M; **1993 ≈$40M (seine peak)**; 1994 ≈$34.5M; 1995 ≈$37M; 1996 ≈$36.5M; 1997 ≈$9.2M; 1998 ≈$7.8M; 1999 ≈$6.3M; 2000 ≈$21.8M; 2001 ≈$14.9M; 2002 ≈$16.8M; 2003 ≈$13.4M; 2004 ≈$12M (nom) | **chart-read ±10%** from IFMP "Figure 9" — pre-digitization (Task 6) | DFO Pacific Herring IFMP Fig. 9 [16] |
| 1993–2002 | **Implied** all-gear roe $/tonne whole herring | ≈$1,560/t nom ≈ **$2,300/t real (2020$)** | derived (value ÷ landings, midpoint deflated) | this brief, from [15, 16] |
| 1979 → 2020$ | Implied real value of 1979 anchor | **≈ $17,300 / t** (2020$) | derived (CPI deflated, approx StatCan all-items) | this brief |

**Reconciling the two roe-value statements.** The IFMP text says the *total* roe fishery averaged ≈$50M/yr 1993–2002 [16]; the same IFMP figure shows the *seine subset* peaking at ≈$40M in 1993 and crashing through 1997–99 [16, chart-read]. The 2024 Rebuilding Plan, which uses the longer DFO fish-slip series for *all* roe gear, says total roe value **peaked in the 1980s** (not 1993) and was relatively high to the mid-1990s [15]. These are consistent: the Rebuilding Plan covers a wider window and gear set; the IFMP Figure 9 captures the seine subset for a narrower span. The talk's claim-control sheet treats the Rebuilding Plan as the authoritative source; the project's analytical record (this brief) carries both with their attribution.

**The political economy of the boom.** DFO's postwar removal of district quotas turned the fishery effectively open-access [9]. The roe fishery operated as an extreme derby — openings as short as **15 minutes to 2 hours**, described as chaotic and dangerous [13]. Fleet investment escalated ("technological brinkmanship" [9]); Indigenous fishers were structurally squeezed out by capital barriers [9]. In **1998 DFO introduced an Individual Vessel Quota (IVQ) "pool" system** to curb the derby — seine pools of ≥8, gillnet pools of ≥4 [16]. By the 2006 coastwide structure: **≈440 vessels** licensed for BC herring [17], **1,520** roe-herring licences (Category HS+HG), **21** SOK licences (Category J+FJ) [16].

**Serial depletion in space — the bioeconomic mechanism.** Mobile commercial fleets targeted the most profitable, densest local spawning aggregations. DFO managed for a **15–20% aggregate harvest rate**, but local exploitation rates reached **65%** in productive bays [18 — Stier et al. 2020 *Ecosphere*]. Cumshewa Inlet earned the nickname "Million Dollar Bay" for its lucrative SOK and roe fisheries [3]. Profit-driven spatial homogenization **eroded the metapopulation portfolio effect**, a finding load-bearing for Lens A.

**The Haida economy — agency built in the one seat available.** Haida fishers Dempsey Collinson and Roy Jones Sr. pioneered the closed-pond SOK technique in the 1970s [3, 14]. Early commercial SOK licences were partly issued as compensation for lost salmon/halibut licences under the **Davis Plan** [3, 14]. By 1978 Haidas held **8 of 12 island SOK licences**; recent counts: **6 of 10 on-island** (or, per a separate report, **5 of 9 J-licences**) [3, 17]. The 1996 Supreme Court decision **R. v. Gladstone** affirmed the Heiltsuk's unextinguished Aboriginal right to harvest and commercially sell herring roe [19] — a right that became economically worthless once the stocks collapsed and the fisheries closed. In Heiltsuk territory the Band Council collectively managed licences and **took 40% of gross revenues** for community reinvestment, building a Friendship Centre and a community-owned airport on Campbell Island [9].

## 4. Act III — The demand collapse (≈1996–2006): three exogenous forces, none in Hecate Strait

The decline was a **demand-side** event, slow and structural, driven entirely by forces outside BC:

1. **Japan's prolonged post-bubble stagnation** cut discretionary spending on a luxury New Year delicacy [16].
2. **Generational consumer shift** — younger Japanese eating substantially less kazunoko [20].
3. **New low-cost competing supply from Alaska and Russia**, pricing BC as a competing exporter into a contracting market [16].

The price signature is unambiguous:

- **SOK price (nominal): $40/lb (1995) → < $6/lb (2004)** [16]. In real 2020 CAD: **$62.88/lb (1995, peak) → $11–14/lb (recent)** [15].
- **Coastwide roe value collapse:** the IFMP states "poor economic conditions in Japan have resulted in a reduction in the price paid for herring roe" [16]; the seine-only Figure 9 series shows the slide from ~$40M (1993) through ~$9M (1997) and ~$12M (2004); a modest 2016–18 uptick of ~$16M landed value plus >$29M in processing value [15].
- **SOK annual fishery average**: ≈ **$3.6M/yr 1982–2008** [15].
- **At Haida Gwaii**: significant roe fisheries through 1994; HG roe shut 1999–2001; **last HG roe fishery 2002** [15].

**Why this is hard to attribute cleanly.** 2003 is where two collapses meet on the same date: the multi-year demand decline (market) **and** the precautionary regulatory closure on a stock below the cutoff (regulation). Disentangling them is the central problem Lens C/D exist to solve.

## 5. Present state (2007–2026): closure persists; the coast is now SoG-only

**Haida Gwaii: zero, every year, for nearly a decade.** Cleary et al. 2024 (DFO Pacific Herring Status) confirms HG commercial catch = **0 t every year 2015–2022** [17]; the stock remains below the **Haida Gwaii Limit Reference Point of 6,452 t (0.3·SB₀)** [17]. Prince Rupert District, Central Coast, and West Coast Vancouver Island roe fisheries are likewise closed or negligible. The 2024 HG Herring Rebuilding Plan (CHN/DFO/Parks Canada) is the governing instrument [15].

**Strait of Georgia is the lone remnant — and contested.** DFO's 2025/26 IFMP keeps SoG open at a **14% harvest rate, ≈14,390 t TAC** (a 1,603 t increase over the prior year; up from the 10% rate imposed in 2022 after overharvesting) [W-1, W-2]. The Pacific Marine Conservation Caucus has declined to endorse DFO's options for a second straight year; conservation groups, First Nations, and recreational organizations are campaigning to halt the fishery [W-2, W-3, W-4].

**Canada's export footprint into Japan.** Industry/trade sources put **80–90% of internationally-traded kazunoko sushi from Alaska or Canada** [W-10]; Vancouver processors (e.g., Lions Gate Fisheries) still ship WCVI roe to Japan [W-11]. But Canada's production *base* is now SoG-only and a fraction of boom-era volume. Tellingly, **Japan out-caught Canada's Pacific herring in 2020 and 2021** [W-5] — the historical importer now out-fishes the historical exporter. (No public 2024–25 Canada→Japan herring-roe export $ figure surfaced in search; this is the data gap the project's Task 7 Comtrade loader is built to close once an API key is available.)

**Japan rebuilt its own supply — both blades of the scissors moved.** Japan launched a government Hokkaido herring stock-enhancement programme in the early 1980s, scaled through the 1990s; millions of hatchery-raised fry are released yearly, with fishers reinvesting ≈2% of sales [W-5, W-6]. **Japan's 2023 domestic catch ≈ 20,000 t — a "21st-century record,"** roughly double Sitka's that year, reversing a ~50-year decline [W-5]. Nuance: the Sea-of-Japan side of Hokkaido is in clear decline even as the overall rebound holds — the recovery is real but spatially uneven [W-7, W-8]. Simultaneously, **Japanese kazunoko demand has structurally weakened**: a New-Year-only ritual product, aging and low-birth-rate demographics, declining younger-consumer interest, with manufacturers pushing novelty products like kazunoko-cheese ("Kazuchee") to defend sales [W-6, W-9]. Domestic Hokkaido kazunoko is now visibly displacing Canadian/Alaskan product on Japanese retail shelves [W-5, W-9].

## 6. The lag thesis — value lagged structure (Spine B, Prediction 1)

The most important analytical statement in this brief: the **economic signal lagged the ecological one and masked the collapse**.

The 2024 Rebuilding Plan and the IFMP both place the BC roe-fishery value plateau in the **1980s through mid-1990s** [15, 16]. Our backbone biology (m1_stier_11) and Stier et al. 2020 [18] show the **spatial portfolio of HG herring eroding through the 1980s** as the mobile commercial fleet homogenized the most-profitable bays. Total value held high while the structure that produced it was already failing; the value signal turned down only after the ecological signal had been deteriorating for a decade. Per the talk's S8 provenance doc, this lag — *not* portfolio-as-early-warning — is the canonical framing for the Royal Society narrative [I-2].

The lag has two consequences:

1. **For management:** an aggregate value indicator (the kind regulators traditionally track) is a *lagging* indicator of forage-fish health; it told the right story too late.
2. **For recovery:** the structure that produced the rents in the 1980s–90s — a dense, asynchronous spatial portfolio of spawning aggregations — is the thing that has not come back. Biomass can recover without portfolio recovering; rents will not recover without portfolio (Lens D).

## 7. Distribution & equity — the human ledger

Quantitative First Nations economic figures are sparse in the literature (an acknowledged data gap; Lens B's central acquisition task). What is documented:

- **Cultural keystone** — herring and k'aaw are central to Haida and Heiltsuk social, ceremonial, and trade life [1, 2, 3].
- **Davis Plan compensation** — SOK licences partly issued to Haida fishers as compensation for lost salmon/halibut access [3].
- **Closed-pond SOK invention** by Haida pioneers — Dempsey Collinson and Roy Jones Sr. [3, 14].
- **Licence holdings on Haida Gwaii** — 8 of 12 (1978) → 6 of 10 / 5 of 9 (mid-2000s) [3, 17].
- **Heiltsuk Band Council model** — 40% of gross revenues to community reinvestment; Friendship Centre and airport [9].
- **R. v. Gladstone (1996)** — affirmed constitutional right to harvest and sell herring roe [19].
- **Co-governance** — Council of the Haida Nation Marine Plans; Archipelago Management Board; PNCIMA; the precedent of the razor-clam co-management (1994 onward) [21, 22].

What is *not* documented in this literature: dollar values of licences (a famously large rent signal in BC roe herring), per-vessel revenue, employment numbers, PICFI program dollars, an HG-specific landed value (DFO records by PFMA, not by Gwaii Haanas — landed values are not separable [15]), post-2002 macro accounting (regional GDP, jobs lost, buybacks). The Lens B agenda is to **co-develop** the missing Haida valuation series with the Council of the Haida Nation under First Nations data sovereignty (OCAP/CARE), not extract.

## 8. The economic non-recovery thesis

This is the brief's load-bearing finding (see companion `2026-05-19-kazunoko-demand-context-brief.md`):

> The foreign demand engine that *created* the BC roe-herring fishery in 1972 has weakened on **both sides**: Japan **rebuilt domestic supply** via hatcheries, **and** Japanese **demand structurally declined**. So the 1980s–90s rent environment is unrecoverable on current trends.

Implication for the project: **Lens D (the recovery counterfactual) must not assume the historical price regime.** A biological rebuild of Haida Gwaii herring would now meet a self-supplied, demographically-shrinking, competitor-flooded market. The "value of recovery" must be computed against a *post-2000s* demand structure. The economic non-recovery may be more permanent than the ecological one.

This sharpens the project's central claim. "Non-recovery" is usually framed ecologically; this evidence supports a stronger, coupled social-ecological framing: even conditional on ecological recovery, the **economic** basis for the Haida Gwaii fishery may not return — a coupled lock-in, not merely a depleted stock.

## 9. Analytical methods & data architecture — how the four lenses map onto this story

The `herring-bioeconomics` repo (sibling to `stier-2027-herring-metapopulation`) implements the four-lens design from the May 19 spec:

| Lens | Question | What this brief gives it | Status |
|---|---|---|---|
| **C — Market structure** (critical path) | Was the fishery stock-driven or demand-driven? | The 1972 demand birth and 1990s decay as exogenous instruments; the SOK $/lb anchor series; the Rebuilding-Plan qualitative roe-value trajectory; the present-day demand collapse | Identification story documented; structural estimation gated on Task 6 + Sea Around Us pull |
| **A — Cause** | Did economics drive collapse + lock in non-recovery? | Open-access / derby / IVQ regime timeline; 15–20% aggregate vs 65% local exploitation (Stier 2020); 2–3 boats → 440 vessels capital story | Mechanism documented; bioeconomic modelling pending |
| **B — Consequence** | What was lost, by whom? | Distributional structure (Haida licences, Heiltsuk model, Gladstone, Davis Plan); post-2002 zero; the data-gap inventory | Quant accounting requires CHN co-development (deferred to upgrade track) |
| **D — Counterfactual** | What would economically rational management have done? | The LRP (6,452 t HG); 2013 DFO TAC menu (2,000–9,000 t); the recovery counterfactual must use the *new* demand regime, not the boom | DP / optimal control pending; non-recovery demand framing now in hand |

**Shared backbone status (this repo):** Tasks 1–5, 7, 8, 9 completed under strict TDD with two-stage review; Task 4 (biology import) corrected from a section-sum bias to the HG-total posterior (+31% real correction); Task 5 (harvest) corrected SOK source provenance (product vs impound biomass); Task 7 (Comtrade kazunoko) and Task 8 (FX/CPI) have working loaders with graceful skips pending API keys. Tasks 6 (figure digitization — human gate), 10 (assemble), 11 (QA), 12 (targets pipeline + `backbone-v1` tag) remain.

**Comparative spine:** Haida Gwaii (engine that stopped) vs coastwide BC, now SoG-only (engine still running, contested) — this asymmetry is the experimental contrast that lets every lens make causal, not merely descriptive, claims.

## 10. Data gaps & acquisitions — what to pull next

| Need | Source | Path |
|---|---|---|
| Continuous BC Pacific-herring ex-vessel $/tonne, 1950+, real | **Sea Around Us / Melnychuk-Tai database** [12] | Desk-tier; in this lab's NotebookLM library; closes the reduction-era and 1980s gaps |
| Roe landed value series, BC + HG, 2020$, full record | **HG Rebuilding Plan Fig. 31/32** (digitize) or **DFO fish-slip raw** | Task 6 (human gate) for figures; data request for raw |
| Japan kazunoko import volume + value, annual | **UN Comtrade HS 030520** (Japan as reporter, imports) | Task 7 loader exists; needs `COMTRADE_PRIMARY_KEY` |
| CAD–JPY FX, full historical | **FRED DEXJPUS × DEXCAUS** (derivation, pre-2017) + **BoC Valet** (2017+) | Task 8 loader (BoC) live; pre-2017 derivation is a small upgrade |
| Canada CPI deflator, audited | **FRED `CPALCY01CAA661N`** | Task 8 loader; needs `FRED_API_KEY` |
| Japan domestic Pacific herring catch, annual | **Japan Fisheries Agency / FAO FishStat** | New L3 sub-series (Lens C demand shifter) |
| First Nations / Haida economic accounts | **CHN Haida Fisheries Program, co-developed** | Lens B equity work; OCAP/CARE governed |
| BC SoG roe value/volume 2007→ | **DFO Pacific IFMP annual** | Task 6 extension |

## 11. Provenance & references

### Primary literature & DFO

- **[1]** McKechnie et al. 2014. Long-term patterns of Pacific herring abundance based on archaeological data. *PNAS* (cited via talk reference set). Establishes the long pre-industrial baseline and forage-fish keystone framing.
- **[2]** Pikitch et al. 2012/2014 (Lenfest / forage-fish synthesis). Global value of forage fish, including their indirect contribution to other fisheries.
- **[3]** Council of the Haida Nation, *Haida Marine Traditional Knowledge Study* (HMTK), Vols 1–3. Oral histories (Roy Jones Sr., Ernie Wilson, Harvey Williams, Dempsey Collinson). Source for k'aaw prices (1930s $0.22/lb; up to $24/lb to Japanese buyers); 1979 gillnet roe $5,500/ton; closed-pond SOK invention; Haida licence counts (8/12 by 1978, 6/10 mid-2000s); trade with Tsimshian and Tlingit.
- **[4]** Powell 2012 / Harris 2012, *Western Historical Quarterly* — *Divided Waters: Heiltsuk Spatial Management of Herring Fisheries*. Source for SOK fishery value 1977 ($1.2M, 111 t) → 1996 ($22.4M, 256 t); the post-WWII removal of district quotas; "technological brinkmanship" overcapitalization; Heiltsuk Band Council 40%-reinvestment model; Friendship Centre and airport on Campbell Island.
- **[5]** Hourston 1980, *The Decline and Recovery of Canada's Pacific Herring Stocks*. Rapp. P-v. Réun. CIEM 177. Source for 50–90% HG exploitation rates in the 1950s; 1968 moratorium narrative; 2–3 seine boats taking the bulk of the reduction-era HG catch.
- **[6]** Misty MacDuffee 2018 (Raincoast Conservation Foundation), *Pacific Herring: Underpinning the coastal foodweb*. Source for >200 kt/yr coastwide early 1960s and the 1967 closure.
- **[7]** Stocker 1993, *Recent management of the British Columbia herring fishery*, Canadian Bulletin of Fisheries and Aquatic Sciences. Source for the 240 kt 1963 figure; management policy evolution; fixed harvest rate / cutoff regime.
- **[8]** Schweigert et al., DFO QCI/Haida Gwaii stock assessments (multiple years). Source for HG 77,500 t 1956 (1951 year-class); fixed 20% target harvest rate with cutoff.
- **[9]** Powell 2012 *WHQ* (full): the reduction era's industrial outputs (fishmeal → poultry feed; oil → paint, fertilizer, industrial); transformation 1972 from reduction to roe; Davis Plan licence-compensation context; SOK fishery growth 1977–1996.
- **[10]** Tester 1945, *Catch statistics of the British Columbia herring fishery to 1943-44*, Fisheries Research Board of Canada Bulletin 67. Reduction-era landings and value records (cited via Jones 2000 in the HMTK; pull for primary reduction-era $/lb).
- **[11]** Stocker 1993 (same as [7]). Includes management-period value series for the 1970s–1980s.
- **[12]** Melnychuk et al. 2021, Sea Around Us / Tai et al. 2017 — Global ex-vessel price database. Purpose-built reconstruction; BC Pacific herring back to ≈1950. **Already in this lab's NotebookLM library** (notebook "Melynchuck et al 2021").
- **[13]** Jones 2000, *The herring fishery of Haida Gwaii: An ethical analysis*, in Coward, Ommer & Pitcher (eds.) *Just Fish*. Source for the early-1970s roe-fishery birth narrative; derby openings 15 min – 2 hr; chaotic / dangerous operating conditions; Vancouver middleman markups ("change the address and ship it to Japan").
- **[14]** Jones 2007, *Application of Haida oral history to Pacific herring management*, in *Fisher's Knowledge in Fisheries Science and Management* (UNESCO).
- **[15]** Council of the Haida Nation / DFO / Parks Canada 2024, **Haida Gwaii ʹíináang | iinang Pacific Herring Rebuilding Plan**. On disk at `talk-usuk-forum-2026/Reference_Papers/HG_Herring_Rebuilding_Plan_2024_CHN_DFO_ParksCanada.pdf`. The authoritative current-source. SOK real price (2020$): $16–31/lb (1970s), $62.88/lb (1995 peak), $11–14/lb (recent). Roe value peaked 1980s, high to mid-1990s, declined 1995–2005 and 2008–present, modest 2016–18 uptick (~$16M landed + >$29M processing). SOK average $3.6M/yr 1982–2008. Last HG roe fishery 2002.
- **[16]** DFO Pacific Region, *Pacific Herring Integrated Fisheries Management Plan* (multiple years). Source for the IFMP 1998 IVQ pool regime; 1993–2002 coastwide roe ≈32,000 t/yr ≈$50M/yr; Figure 9 chart-read series 1992–2004; 2006 expected-use table (Commercial Roe $2.78M; Commercial SOK $2.7M; Food & Bait $0.15/lb; Special Use $0.62/lb); 1,520 roe licences and 21 SOK licences (2006); "poor economic conditions in Japan have resulted in a reduction in the price paid for herring roe."
- **[17]** Cleary et al. 2015/2024 (DFO Pacific Herring science). Coastwide landings by SAR 2015–2022 (HG 0 t every year); HG LRP 6,452 t; ~440 BC herring vessels; standard SOK pond ≈100 t of mature herring (Shields & Kingston 1982 lineage); 2013 DFO Daniel TAC menu (2,000–9,000 t).
- **[18]** Stier, Shelton, Samhouri, Feist & Levin 2020, *Fishing, environment, and the erosion of a population portfolio*, *Ecosphere* 11(11): e03283. Source for 15–20% aggregate vs 65% local exploitation; portfolio erosion; place-based scale-matched governance recommendation.
- **[19]** **R. v. Gladstone**, [1996] 2 S.C.R. 723. Supreme Court of Canada affirmation of Heiltsuk Aboriginal right to harvest and commercially sell herring roe.
- **[20]** Multiple KCAW 2024 reporting (see [W-5] – [W-9]) on kazunoko demand structure.
- **[21]** Jones, Rigg & Lee 2010, *Haida marine planning: First Nations as a partner in marine conservation*, *Ecology & Society* 15(1):12.
- **[22]** Council of the Haida Nation Marine Planning Program; Archipelago Management Board; PNCIMA — co-governance institutional context.

### Web sources — current market context (accessed 2026-05-19)

- **[W-1]** DFO, *Pacific Herring 2025–2026 IFMP*. https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/herring-hareng-ifmp-pgip-sm-eng.html
- **[W-2]** Pacific Wild, *2025/26 Herring Management Plan Released*. https://pacificwild.org/2025-26-herring-management-plan-released/
- **[W-3]** The Tyee, *"We Are Going to Fight to Save the Herring"* (2025-11-14). https://thetyee.ca/News/2025/11/14/Fight-Save-Herring/
- **[W-4]** Victoria News, *Victoria fishing club calls to halt commercial herring fishery* (2026-02-17). https://vicnews.com/2026/02/17/victoria-fishing-club-calls-to-halt-commercial-herring-fishery/
- **[W-5]** KCAW, *Hatcheries are helping Japan's herring industry rebound — what does that mean for Alaska?* (2024-10-01). https://www.kcaw.org/2024/10/01/hatcheries-are-helping-japans-herring-industry-rebound-what-does-that-mean-for-alaska/
- **[W-6]** KCAW, *As Japan's consumer tastes change, marketers hope to create the next hot herring product* (2024-10-03). https://www.kcaw.org/2024/10/03/as-japans-consumer-tastes-change-marketers-hope-to-create-the-next-hot-herring-product/
- **[W-7]** SeafoodNews, *Hokkaido's Herring Production in the Sea of Japan Shows Clear Decline*. https://www.seafoodnews.com/Story/1341879/Hokkaidos-Herring-Production-in-the-Sea-of-Japan-Shows-Clear-Decline
- **[W-8]** KCAW, *Can Japan sustain the rebound of its 'phantom fish'?* (2024-10-04). https://www.kcaw.org/2024/10/04/can-japan-sustain-the-rebound-of-its-phantom-fish/
- **[W-9]** KCAW, *While local herring are more affordable and accessible in Japan, some still look to Alaska for eggs* (2024-10-02). https://www.kcaw.org/2024/10/02/while-local-herring-are-more-affordable-and-accessible-in-japan-some-still-look-to-alaska-for-eggs/
- **[W-10]** BCBusiness, *The Down-Low on Herring Roe*. https://www.bcbusiness.ca/the-down-low-on-herring-roe
- **[W-11]** Lions Gate Fisheries Ltd., *Herring Roe* (Vancouver processor/exporter). https://www.lionsgatefisheries.com/herring-roe

### Internal artifacts (this repo)

- **[I-1]** Herring Haida Gwaii NotebookLM library (151 sources); curated reference set governing all citations above.
- **[I-2]** `talk-usuk-forum-2026/Talk_Materials/S8_landed_value_provenance.md` (sibling repo) — claim-control / S8 provenance doc; defines the talk's "value lagged the ecology" framing and excludes "1993/$40M" as unsourced teaching shorthand for talk use.
- **[I-3]** `docs/superpowers/specs/2026-05-19-herring-bioeconomic-analysis-design.md` — approved design spec for the four-lens analysis.
- **[I-4]** `docs/superpowers/plans/2026-05-19-herring-bioeconomic-backbone.md` — Phase-0 implementation plan; 9 of 12 tasks complete.
- **[I-5]** `docs/herring-economics-three-acts.html` — visual narrative of the price arc, real 2020 CAD/t (log-scale schematic).
- **[I-6]** `docs/2026-05-19-kazunoko-demand-context-brief.md` — forward-looking demand brief.
- **[I-7]** `talk-usuk-forum-2026/Talk_Materials/s8_value_lag_infographic.html` — candidate Royal Society talk slide (under stricter claim-control).

## 12. Rigor caveats

1. **Source provenance is uneven across periods.** Reduction-era prices are *acquirable* (StatCan / Sea Around Us / Tester 1945) but not yet pulled; we labeled them "no $/lb on record" in the talk slide, which is cautious-but-overstated. The brief flags the path.
2. **Roe-value narrative has two coherent but distinct framings** depending on source and window: the IFMP shows a seine subset with a 1993 peak; the Rebuilding Plan covers the full roe gear / longer window and places the peak in the 1980s. The talk uses the Rebuilding Plan framing per its claim-control sheet; this brief retains both.
3. **HG-specific landed values are not separable** in DFO records (PFMA-level reporting). All HG-specific dollar figures here are share-of-coastwide approximations unless otherwise noted.
4. **Schematic/derived/chart-read labels are load-bearing** — the three-acts graphic is explicitly "not a fitted series"; the IFMP Figure 9 numbers are chart-reads pre-Task-6-digitization; the implied $/tonne anchors are value÷tonnage derivations with the 1979-vs-1990s "different baskets" caveat.
5. **KCAW 2024 reporting is journalism.** Tonnage and percentage claims about the Japanese rebound are pending primary confirmation from the Japan Fisheries Agency or FAO before use in a manuscript.
6. **First Nations data sovereignty** governs any economic figure that touches Haida or Heiltsuk community accounts (OCAP / CARE). The Lens B equity series will be co-developed, not extracted.
7. **The talk and this brief are firewalled.** The `stier-2027-herring-metapopulation` modelling pipeline is read-only from this brief's perspective; biology is imported by the `herring-bioeconomics` backbone via a one-directional provenance-tagged snapshot of `m1_stier_11`.

---

*Brief compiled from the Herring Haida Gwaii NotebookLM library (151 sources), the 2024 Haida Gwaii Pacific Herring Rebuilding Plan, the DFO Pacific Herring IFMP, Haida Marine TEK Vol. 3, Powell/Harris 2012 (Western Historical Quarterly), Stier et al. 2020 (Ecosphere), Cleary et al. 2015/2024, and the 2024 KCAW reporting series, with internal cross-reference to the project's design spec, backbone implementation, three-acts graphic, kazunoko-demand brief, and the candidate Royal Society slide.*
