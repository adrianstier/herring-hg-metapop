# Demand-Side Context Brief: The Kazunoko Market, Japanese Stock Recovery, and the Current State of the BC/Haida Gwaii Herring Fishery

- **Date:** 2026-05-19
- **Prepared for:** herring-bioeconomics (Lens C — market structure; Lens D — recovery counterfactual)
- **Status:** Working brief. External web sources (current-market) clearly separated from internally grounded data (HG fishery status).
- **One-line finding:** The foreign demand engine that *created* the BC roe-herring fishery in 1972 has weakened on **both** sides — Japan rebuilt its own supply via hatcheries **and** Japanese kazunoko demand structurally declined — so the **economic** non-recovery of Haida Gwaii herring is likely **more permanent than the ecological** one.
- **Companion artifact:** [`docs/herring-economics-three-acts.html`](./herring-economics-three-acts.html) — the visual narrative of the documented historical price arc (Acts I–III: 1930 → ~2006/2022, real 2020 CAD per tonne, the kazunoko boom-and-collapse round-trip). This brief is its analytical continuation — **Act IV: why the market does not return** — and the two are intended to be read together as the demand-side spine for Lens C / Lens D.

---

## 1. Why this brief exists

The Herring Haida Gwaii NotebookLM library (151 sources) is explicit that it contains **no** post-2006 prices, **no** export/market volumes, and **nothing** on Japanese domestic stock status [I-1, I-2]. The bioeconomic backbone we have built is therefore blind on the demand side after 2006. Lens C (structural demand/supply) and Lens D (the optimal-management / recovery counterfactual) cannot be specified correctly without knowing whether the historical price regime could ever return. This brief assembles the current evidence and states the implication.

---

## 2. Current status of the BC / Haida Gwaii fishery

**Most of the coast — including all of Haida Gwaii — has been closed for ~two decades.**

- Haida Gwaii commercial roe/SOK herring: closed since ~2002–2003; **0 t landed every year 2015–2022**; the stock remains below the Haida Gwaii Limit Reference Point of **6,452 t (0.3·SB₀)** [I-3]. Prince Rupert District, Central Coast, and West Coast Vancouver Island roe fisheries are likewise closed or negligible in recent years [I-3].
- **Strait of Georgia (SoG) is the lone exception and is actively contested.** DFO's 2025/26 Integrated Fisheries Management Plan keeps SoG open at a **14% harvest rate, ~14,390 t TAC**, an increase of ~1,603 t over the prior year, and up from the 10% rate imposed in 2022 after a period of overharvesting [W-1, W-2]. The Pacific Marine Conservation Caucus declined to endorse DFO's SoG options for a second consecutive year; conservation groups, First Nations, and recreational organisations (including a Victoria fishing club, Feb 2026) are campaigning to halt the fishery [W-2, W-3, W-4].

**Implication:** "the fishery" is not a single object. Haida Gwaii is a ~20-year closure on a sub-LRP stock; SoG is a single shrinking, politically embattled remnant whose quota DFO nudged *up* for 2025/26. Any coastwide series must treat these as different regimes (consistent with the backbone's L0 layer).

---

## 3. Did Japanese domestic herring recover? — Yes, materially

Japan's domestic Hokkaido (Pacific) herring has rebounded through a long-running government hatchery / stock-enhancement programme:

- Enhancement effort began in Hokkaido in the early 1980s and scaled through the 1990s; Japan now releases **millions of hatchery-raised herring fry per year**, with fishers reinvesting **~2% of sales** into the programme [W-5, W-6].
- **2023 domestic catch ≈ 20,000 t — described as a "21st-century record,"** roughly **double Sitka's catch** that year, reversing an approximately 50-year decline [W-5].
- **Japan exceeded Canada's Pacific herring catch in 2020 and 2021** — an inversion of the historical importer/exporter relationship; **Russia catches more than either** [W-5].
- **Nuance / fragility:** the Sea-of-Japan side of Hokkaido is reported to be in clear decline even as the overall rebound narrative holds [W-7]. The recovery is real but spatially uneven and not guaranteed to persist [W-8].

---

## 4. Kazunoko demand has declined structurally

- Kazunoko consumption is now essentially a **New-Year-only ritual**; aging and low-birth-rate demographics and changing younger-consumer tastes have shrunk the base [W-6, W-9].
- Manufacturers are resorting to **product innovation to defend sales** (e.g., kazunoko–cheese "Kazuchee"), an indicator of a contracting core market [W-6].
- On Japanese retail shelves, **domestic Hokkaido kazunoko is increasingly displacing Canadian/Alaskan product** ("in the past… product of Canada or Alaska; nowadays… domestic… more and more") [W-5, W-9].

---

## 5. Current BC/Canada exports to Japan

- Canada + Alaska still supply most internationally-traded kazunoko (industry/trade sources put it around **80–90% of kazunoko sushi from Alaska or Canada**), and Vancouver processors (e.g., Lions Gate Fisheries) still ship West Coast Vancouver Island roe to Japan [W-10, W-11].
- But Canada's *production base* is now essentially SoG-only — a small fraction of the boom-era fishery — and faces domestic-Japanese, Alaskan, and Russian competition into a shrinking market.
- **Data gap:** no public 2024–2025 Canada→Japan herring-roe export value/volume figure was located. This is precisely the series the project's **Task 7 (UN Comtrade HS 030520, Japan imports)** loader is built to retrieve; it currently skips for lack of a Comtrade API key (see repo Task 7). Acquiring that key closes this gap.

---

## 6. Implication for the bioeconomic analysis

This is the analytically load-bearing conclusion:

1. **The demand engine moved permanently, on both blades.** Supply: Japan rebuilt domestic production via hatcheries. Demand: Japanese kazunoko consumption structurally declined. Either alone would soften the BC export market; together they make the 1980s–90s rent environment effectively unrecoverable.
2. **Lens D (recovery counterfactual) must not assume the historical price regime.** A biological rebuild of Haida Gwaii herring would today meet a self-supplied, demographically-shrinking, competitor-flooded market. The "value of recovery" must be computed against a *post-2000s* demand structure, not the boom.
3. **Lens C (structural demand/supply) gains a cleaner identification story.** The 1972 demand birth (Japanese domestic collapse) and the post-1990s demand decay (Japanese recovery + demographic demand fall) are both exogenous to the BC stock — strong instruments — and the Japanese-recovery timeline is now datable from these sources.
4. **It sharpens the project's central thesis.** "Non-recovery" is usually framed ecologically. This brief supports a stronger, complementary claim: even conditional on ecological recovery, the **economic** basis for the Haida Gwaii fishery may not return — a coupled social–ecological lock-in, not merely a depleted stock.

**Read with the companion graphic [I-4].** `herring-economics-three-acts.html` plots the documented arc through Act III (real ex-vessel value ≈ $17,300/t in 1979 → ≈ $150/t by 2006, HG 0 t through 2022). This brief supplies the missing **Act IV**: the post-closure demand structure that determines whether the curve in that graphic could ever turn back up. The visual ends at the floor; this brief explains why the floor is, for now, structural rather than cyclical.

---

## 7. Open data needs (to convert this brief into series)

| Need | Source to pursue | Project hook |
|---|---|---|
| Canada→Japan herring-roe export value/volume, annual | UN Comtrade HS 030520; Statistics Canada trade | **Task 7** loader (needs `COMTRADE_PRIMARY_KEY`) |
| Japan domestic herring catch series, annual | Japan Fisheries Agency / FAO FishStat | New L3 sub-series (Lens C demand shifter) |
| Japanese kazunoko consumption / per-capita | Japan MAFF household surveys | Lens C demand shifter |
| BC SoG roe value/volume 2007→ | DFO Pacific IFMP annual; Task 6 extension | Extends the post-2006 value series |

---

## References

### Internal / grounded sources (project data, NotebookLM library)

- **[I-1]** Herring Haida Gwaii NotebookLM library (151 sources); query 2026-05-19 confirming no post-2006 price, export-volume, or Japanese-stock data.
- **[I-2]** This repo, `docs/2026-05-19-…` price-ledger synthesis (prior session output).
- **[I-3]** Cleary, J.S. et al. — DFO Pacific Herring stock status / IFMP science (2015; 2024), via the Herring Haida Gwaii NotebookLM library: Haida Gwaii post-closure landings 0 t 2015–2022; HG Limit Reference Point 6,452 t (0.3·SB₀); ~440 BC herring vessels; coast-wide landings by SAR 2015–2022.
- **[I-4]** Companion visual artifact — `herring-economics-three-acts.html` (this repo, `docs/`). Three-act real-terms ex-vessel value narrative, constant 2020 CAD per tonne (log scale): Act I reduction era (no $/t on record); Act II kazunoko boom (1979 ≈ $17,300/t source-stated; 1993–2002 fleet-avg ≈ $2,300/t implied); Act III collapse (2006 ≈ $150/t implied; HG 0 t through 2022; LRP 6,452 t). Built from Powell/Harris 2012, DFO IFMP Fig. 9 & 2006 Table 9, Haida Marine TEK Vol. 3, Cleary et al. 2015/2024, and Haida oral histories, synthesized via the NotebookLM library; schematic/anchored, not a fitted series. Open in a browser: `file:///Users/adrianstier/herring-bioeconomics/docs/herring-economics-three-acts.html`.

### External / web sources (current-market; accessed 2026-05-19)

- **[W-1]** Fisheries and Oceans Canada, *Pacific Herring 2025–2026 Integrated Fisheries Management Plan*. https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/herring-hareng-ifmp-pgip-sm-eng.html
- **[W-2]** Pacific Wild, *2025/26 Herring Management Plan Released*. https://pacificwild.org/2025-26-herring-management-plan-released/
- **[W-3]** The Tyee, *"We Are Going to Fight to Save the Herring"* (2025-11-14). https://thetyee.ca/News/2025/11/14/Fight-Save-Herring/
- **[W-4]** Victoria News, *Victoria fishing club calls to halt commercial herring fishery* (2026-02-17). https://vicnews.com/2026/02/17/victoria-fishing-club-calls-to-halt-commercial-herring-fishery/
- **[W-5]** KCAW (Sitka), *Hatcheries are helping Japan's herring industry rebound — what does that mean for Alaska?* (2024-10-01). https://www.kcaw.org/2024/10/01/hatcheries-are-helping-japans-herring-industry-rebound-what-does-that-mean-for-alaska/
- **[W-6]** KCAW, *As Japan's consumer tastes change, marketers hope to create the next hot herring product* (2024-10-03). https://www.kcaw.org/2024/10/03/as-japans-consumer-tastes-change-marketers-hope-to-create-the-next-hot-herring-product/
- **[W-7]** SeafoodNews, *Hokkaido's Herring Production in the Sea of Japan Shows Clear Decline*. https://www.seafoodnews.com/Story/1341879/Hokkaidos-Herring-Production-in-the-Sea-of-Japan-Shows-Clear-Decline
- **[W-8]** KCAW, *Can Japan sustain the rebound of its 'phantom fish'?* (2024-10-04). https://www.kcaw.org/2024/10/04/can-japan-sustain-the-rebound-of-its-phantom-fish/
- **[W-9]** KCAW, *While local herring are more affordable and accessible in Japan, some still look to Alaska for eggs* (2024-10-02). https://www.kcaw.org/2024/10/02/while-local-herring-are-more-affordable-and-accessible-in-japan-some-still-look-to-alaska-for-eggs/
- **[W-10]** BCBusiness, *The Down-Low on Herring Roe*. https://www.bcbusiness.ca/the-down-low-on-herring-roe
- **[W-11]** Lions Gate Fisheries Ltd., *Herring Roe* (processor/exporter, West Coast Vancouver Island → Japan). https://www.lionsgatefisheries.com/herring-roe

### Source-quality note

W-5/6/8/9 are a 2024 KCAW (public radio, Sitka) reported series — strong, current, but journalistic; treat tonnage/quantitative claims as approximate pending primary confirmation from the Japan Fisheries Agency / FAO. W-1 (DFO IFMP) is primary. Per the project citation-grounding rule, any of these figures used in a manuscript must be re-verified against a primary fisheries-statistics source and, where possible, cross-checked via the NotebookLM/literature pipeline before publication.
