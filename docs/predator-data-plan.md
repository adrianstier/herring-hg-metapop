# Pacific Herring Predator-Data Plan

This note plans the predator-time-series database that supports the herring
metapopulation manuscript. Detailed data ingestion, schemas, and processed time
series live in a sibling repo:

- **Repo**: [`stier-lab/pacific-herring-predators`](https://github.com/stier-lab/pacific-herring-predators) (local at `/Users/adrianstier/pacific-herring-predators/`)
- **Scope**: BC coast, with explicit Haida Gwaii / Hecate Strait subsetting where the data support it.
- **Companion NotebookLM**: `Herring Haida Gwaii` notebook, `63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e` ([open](https://notebooklm.google.com/notebook/63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e)). The original 59 herring-only sources were expanded with ~40 predator papers from the legacy Drive archive on 2026-05-09. See [`docs/notebooklm.md`](https://github.com/stier-lab/pacific-herring-predators) and [`docs/zotero-seed-papers.md`](https://github.com/stier-lab/pacific-herring-predators) in the predators repo.
- **Legacy archive**: extensive predator material (Steller telemetry, harbour seal counts, predator literature, predator-analysis scripts behind Samhouri/Stier 2017 *Nat Ecol Evol*) lives at `~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/Stier Lab/People/Adrian Stier/Projects/Completed/Herring_Haida_Gwaii/`, especially the `PDF Library/{Steller pdfs,Harbour Seals,Seals,From Libby Loggerwell}/` subfolders and `Data/Steller Sea Lions/Tracks ADFG/`. Treat as read-only provenance.

> 2026-05-09. Started as part of moving beyond `m1_stier_11`. The current
> herring repo only contains time series for harbour seal, Steller sea lion,
> and humpback whale (`Data/raw/predators/`). That is a small slice of the
> herring predator field. This plan defines the broader predator suite, the
> spatial / temporal / taxonomic coverage we need, and how the new repo will
> grow into the source of truth.

> 2026-05-11 update. This repo now has a first section-level exposure
> prototype in `Output/diagnostics/predator_spatial_exposure_prototype.md` and
> `Output/figures/predator_spatial_exposure_prototype.pdf`. It uses raw Haida
> Gwaii harbour seal and Steller sea lion locations/counts to compute rough
> distance-kernel exposure by herring section. Treat it as a data-product proof
> of concept, not a predator-effect result: the screen remains time-confounded
> and humpback exposure is still basin-scale.

> 2026-05-12 update. The private predator repo now provides an audited HG
> predation-pressure product that is useful enough for a first Stier-aligned
> Stan branch. Run
> `Rscript Code/02c_integrate_hg_predator_repo_products.R` with
> `PREDATOR_REPO_PATH` pointing to the predator checkout. The script writes
> `Data/processed/predators/hg_predation_pressure_covariates.csv` and a short
> report at `Output/diagnostics/hg_predator_repo_integration.md`. The first
> model branch using this product is `m5_stier_predation_pressure`: annual
> regional HG predation pressure, lagged one year in the biomass process, while
> retaining ambiguous zeros, two-era q, and no age/size structure.

> 2026-05-14 update. The first Stier-aligned predator branch is now held, not
> promoted: it is sampler-usable but gives no material calibration gain over
> `m1_stier_11`. The deeper integration read is in
> `docs/predator-analysis-integration-roadmap.md`. The key change is to
> separate predator demand (`C_total_kt` and group-specific consumption) from
> predator pressure ratios (`consumption / HG spawn`). Pressure ratios are
> useful descriptive metrics but should not be the first exogenous process
> covariate because they include observed herring spawn in the denominator. The
> section exposure prototype also now joins predator exposure to model biomass
> by `section_name`, fixing a raw-section-code versus model-site-index mismatch
> in the exposure-growth screen.

## Headline finding from the literature (revision 2026-05-09)

Three BC-coast-wide reviews now anchor the predator scope:

1. **Doherty, Johnson, Benson, Cox & Cleary 2025 *ICES JMS*** —
   Marine-mammal predation explains the recent rise in herring natural mortality.
   This is THE 2020s review the user remembered.
2. **Surma & Pitcher 2017 *ICES JMS*** — Spatial and temporal predator-prey
   dynamics off western Canada. Confirms predator-prey overlap is regionally
   specific (WCVI vs. Haida Gwaii vs. SoG).
3. **Schweigert, Trites, Pearsall et al. 2010 *ICES JMS*** — Provides a
   verbatim, quantitative predator consumption budget for BC herring SSB
   1973-2008. **Total = 53.8% of SSB consumed/yr by 12 predator species.**

That budget reorders the priority list significantly versus an intuition-only
plan. See the predator-database repo's
`docs/predator-consumption-budget.md` for the full table; the top species are:

| Rank | Species | % of BC herring SSB consumed/yr |
|---:|---|---:|
| 1 | Northern fur seal | 15.7% |
| 2 | Lingcod | 7.1% |
| 3 | Pacific cod | 6.8% |
| 4 | Spiny dogfish | 6.7% |
| 5 | Pacific hake (piscivorous) | 5.1% |
| 6 | Steller sea lion | 3.0% |
| 7 | Humpback whale | 2.6% |
| 8 | Arrowtooth flounder | 2.5% |
| 9 | California sea lion | 2.3% |
| 10-12 | Halibut, sablefish, harbour seal | 0.4-0.8% |

**Implications**:

- **Northern fur seal** is the single largest herring consumer in this budget — and is missing from this repo's current predator data. Promote to Priority 1.
- **Walleye pollock** is planktivorous in the Gulf of Alaska (Logerwell 2007). Drop from herring-predator scope.
- **Hake at-spawn is misleading**: hake migrates into BC June-October and misses the spring spawn. Hake is Priority 1 for **year-round adult mortality**, Priority 2 for **at-spawn pressure**.
- **Arrowtooth flounder** and **California sea lion** were missing from the original Tier 1 list; both quantified at >2% SSB.
- **Cetacean recovery** (Surma & Pitcher 2015) gives 6-12% top-down biomass reduction at full recovery — meaningful but not the dominant term. The dominant term is the **fish predator suite** (lingcod + cod + dogfish + hake + flounder ≈ 28% of SSB combined).
- Doherty 2025 attributes recent natural-mortality trend mostly to humpback recovery, but on top of the 50%+ baseline predator consumption — so it's a **trend on top of a heavy baseline**, not the dominant term in absolute consumption.

These insights are now reflected in
`pacific-herring-predators/docs/predator-coverage-matrix.md` and
`pacific-herring-predators/docs/predator-consumption-budget.md`.

## Why a separate repo

Predator abundance time series at BC-coast scale are reusable beyond the
current herring manuscript: they touch the predator-pit work, the
collective-memory occupancy model, future salmon/forage-fish projects, and
lab teaching. A shared repo keeps:

- raw downloads + provenance separate from manuscript-specific cleaning,
- a single curated NotebookLM for predator literature,
- citation lists in one Zotero-anchored place,
- predator schemas portable across projects.

The herring repo `Data/raw/predators/` becomes a thin pointer to the curated
files in the predators repo once they are stable.

## Herring predator suite (BC coast)

Predators of *Clupea pallasii* in the Northeast Pacific span four functional
groups. Each row notes the herring life stage targeted, the spatial scale at
which abundance is most credible, and whether we already have a time series.

### Marine mammals

| Predator | Latin name | Stage targeted | Best spatial scale | Key BC time series | Status |
|---|---|---|---|---|---|
| Harbour seal | *Phoca vitulina richardii* | adult, juvenile | regional (BC) and Haida Gwaii sites | DFO haul-out counts 1966-2019; SAR 2022/034 | ✓ in repo |
| Steller sea lion | *Eumetopias jubatus* | adult, juvenile | Haida Gwaii rookeries + BC | DFO breeding counts 1971-2013, 2016-17; CSAS 2024/047 | ✓ in repo |
| Humpback whale | *Megaptera novaeangliae* | juvenile, adult | basin-wide; BC density grid | Cheeseman et al. 2024 (basin); PRISMM 2018; BCCSN sightings | ✓ basin-wide; need BC subset |
| Fin whale | *Balaenoptera physalus* | juvenile, adult | regional, BC | PRISMM 2018; COSEWIC 2019 | gap |
| Minke whale | *Balaenoptera acutorostrata* | juvenile, adult | regional, BC | PRISMM 2018 | gap |
| Bigg's (transient) killer whale | *Orcinus orca* | indirect (eats pinnipeds) | regional NE Pacific | NMFS / DFO mark-resight | gap (indirect predator) |
| Northern resident killer whale | *Orcinus orca* | indirect (eats salmon) | regional | DFO photo-ID census | gap (indirect) |
| Sea otter | *Enhydra lutris kenyoni* | not a herring predator | local (range expansion) | DFO range surveys | gap (ecosystem context) |
| Northern fur seal | *Callorhinus ursinus* | adult | migratory, NE Pacific | NOAA Pribilofs counts | gap |
| Harbour porpoise, Dall's porpoise | *Phocoena phocoena*, *Phocoenoides dalli* | adult, juvenile | regional | PRISMM 2018; BCCSN | gap |

### Fish

| Predator | Latin name | Stage targeted | Best spatial scale | Key BC time series | Status |
|---|---|---|---|---|---|
| Pacific hake | *Merluccius productus* | juvenile, adult | coast-wide (CA-BC) | PFMC/JTC stock assessment 1966-present | gap |
| Pacific halibut | *Hippoglossus stenolepis* | adult | IPHC Area 2B (BC) | IPHC stock assessment 1888-present (Setline / FISS) | gap |
| Lingcod | *Ophiodon elongatus* | adult | BC areas | DFO CSAS lingcod assessments | gap |
| Pacific cod | *Gadus macrocephalus* | adult | BC outer coast / Hecate Strait | DFO synoptic trawl survey | gap |
| Sablefish | *Anoplopoma fimbria* | adult | NE Pacific shelf-slope | DFO sablefish stock assessment | gap (deep-water; secondary) |
| Spiny dogfish | *Squalus suckleyi* | adult | regional | DFO trawl + IPHC; declining | gap |
| Walleye pollock | *Gadus chalcogrammus* | juvenile, adult | NE Pacific (mainly AK; BC fringe) | NMFS AFSC | optional |
| Coho salmon | *Oncorhynchus kisutch* | juvenile, larvae | BC areas; smolt-to-adult | DFO Pacific Salmon Explorer | gap |
| Chinook salmon | *O. tshawytscha* | juvenile, larvae | BC regions | DFO Pacific Salmon Explorer | gap |
| Adult Pacific herring (cannibal) | *Clupea pallasii* | eggs, larvae | section-level | DFO spawn index (already in this repo) | already in herring repo |

### Birds

| Predator | Latin name | Stage targeted | Best spatial scale | Key BC time series | Status |
|---|---|---|---|---|---|
| Common murre | *Uria aalge* | juvenile, adult | colony-based, BC + WA | Triangle Island monitoring (UBC); BC seabird colony database | gap |
| Marbled murrelet | *Brachyramphus marmoratus* | juvenile, adult | BC coast | COSEWIC 2012 / 2024; at-sea surveys | gap |
| Rhinoceros auklet | *Cerorhinca monocerata* | juvenile | colony-based (Triangle, Pine, Lucy) | UBC / SFU Triangle Island time series 1975-present | gap |
| Cassin's auklet | *Ptychoramphus aleuticus* | larvae (forage shifted) | Triangle Island | UBC monitoring | optional |
| Glaucous-winged gull | *Larus glaucescens* | EGGS at spawn | BC colonies | Audubon CBC; BCCWS; colony surveys | gap |
| Bald eagle | *Haliaeetus leucocephalus* | EGGS at spawn | BC | Audubon CBC; BBA; BC raptor surveys | gap |
| Surf scoter | *Melanitta perspicillata* | EGGS at spawn | herring spawn aggregations | Audubon CBC; Lok/Rodway/Lok et al. studies; BCCWS | gap (major egg consumer) |
| Long-tailed duck | *Clangula hyemalis* | EGGS at spawn | wintering, BC | Audubon CBC; BCCWS | gap |
| Pelagic cormorant | *Urile pelagicus* | adult, juvenile | colony-based | colony surveys | gap |
| Pacific loon | *Gavia pacifica* | adult, juvenile | wintering | BCCWS | gap |

### Invertebrate egg predators

These rarely have explicit time series but are important to mention as part of
the predation field at spawn:

- *Pisaster ochraceus* (ochre sea star) — sea-star wasting collapse 2013-2015 likely altered intertidal egg loss budgets.
- *Strongylocentrotus* spp. (urchins) — relevant for substrate cover at subtidal spawn.
- Snails (e.g., *Nucella*) — opportunistic egg consumers.

## Coverage matrix: spatial × temporal × taxonomic

This drives prioritization in the new repo. Each cell is "what is realistic
to populate well given existing public data."

### Spatial axes

1. **Haida Gwaii** (DFO Section A2W, A2E, plus offshore Hecate Strait).
2. **BC coast** — North coast (PFMA 1-10), Central coast (11-13), West Coast Vancouver Island (20-27), Strait of Georgia / Salish Sea (28-29).
3. **Northeast Pacific** — California Current + Gulf of Alaska context.

### Temporal axes

1. Pre-1900: whaling, sealing, eagle bounty (qualitative or single-decade points).
2. 1900-1971: industrial whaling era; sea otters near extinction; pinniped bounties.
3. 1971-2005: closures, recovery curves begin; modern surveys initiate.
4. 2005-present: Haida Gwaii fishery closure era; predator recovery continues; 2014-16 marine heatwave; humpback decline post-2014.

### Taxonomic axes

Mammals, fish, birds, invertebrates as listed above. Lifestage matters:
egg-predators are different from adult-fish predators and the figures should
keep them separate.

### High-value gaps (priority-ranked)

1. Pacific hake biomass time series (BC-relevant, 1966-present, single most abundant herring predator at coast scale).
2. Bald eagle + glaucous-winged gull abundance (CBC; eats roe at spawn — directly within section).
3. Surf scoter wintering counts (BCCWS) — the dominant duck egg predator.
4. Common murre + rhinoceros auklet time series (Triangle Island; long high-quality series; informs juvenile herring predation).
5. Pacific halibut Area 2B SPR / biomass (IPHC; long series, eats juvenile-adult herring).
6. Coho + Chinook salmon abundance for North coast (DFO; juvenile-herring predation).
7. Marbled murrelet COSEWIC trends.
8. Killer whale (Bigg's) abundance — indirect, but explains pinniped pressure.
9. Fin whale recovery trajectory — partial herring/krill predator.

## How this connects back to the herring manuscript

The modeling roadmap in `docs/analysis-plan.md` and `AGENTS.md` now separates
two predator uses:

1. `m5_stier_predation_pressure`: a direct annual HG predation-pressure process
   branch that should be run on AWS and judged by the same sampler/PPC/LOO gates
   as other branches.
2. Section-level predator exposure: still a data-product roadmap, because seal
   and Steller spatial products are available but humpback exposure and
   time/effort confounding remain unresolved.

So the predator database is:

1. The provenance of the annual HG pressure covariate used by
   `m5_stier_predation_pressure`.
2. The provenance of any section-level predator covariate that eventually re-enters the
   model after `m6_stier_predators`.
3. A descriptive figure that shows how the predator field surrounding herring
   has changed across the same 1951-2025 window the spawn data cover. That
   figure can sit in the manuscript Introduction independently of whether
   predator covariates are in the final fit.
4. A literature/citation backbone (NotebookLM + Zotero) that any agent doing
   manuscript work can query.

The May 11 herring-repo prototype narrows the near-term predator task:

1. Preserve harbour seal complex-year collapsing; `complex_count` is repeated
   across subsites and should not be summed naively.
2. For Steller sea lions, record whether interpolated/extrapolated count fields
   are being used and keep sensitivity toggles for raw-only versus filled
   counts.
3. Decide biologically defensible kernels before modeling: 25, 50, and 100 km
   are only placeholders.
4. Build or obtain Haida Gwaii/section-level humpback exposure; the Cheeseman
   basin-wide series is not enough for a section predator coefficient.
5. Keep exposure diagnostics separate from effect inference until time trends
   and effort differences are handled.

## Visualization plan

Multi-panel figure, common 1900-2025 x-axis, four taxon-grouped panels:

1. **Mammals**: harbour seal, Steller sea lion, humpback whale, fin whale, sea otter range index. Direct counts or relative indices, normalized to peak.
2. **Fish**: Pacific hake spawning biomass, Pacific halibut Area 2B, lingcod biomass, coho/Chinook total returns. Each on its own scale, normalized.
3. **Birds**: common murre + rhinoceros auklet (Triangle Island), surf scoter (BCCWS), bald eagle + glaucous-winged gull (CBC). Counts or per-effort.
4. **Egg-predator pressure at spawn**: combined surf scoter + bald eagle + gull index at North coast scale.

Overlay vertical guides for: 1965 BC industrial whaling closure, 1970 Marine Mammal Protection Act, 1972 BC sea otter reintroduction, 2002 Haida Gwaii roe fishery closure (de facto), 2005 formal closure, 2014-2016 marine heatwave.

Use `theme_pub(base_size = 9)` and Okabe-Ito palette, exported via the
`pub-figure-pipeline` quality gate.

## Next-step checklist

- [x] Plan doc (this file).
- [ ] Scaffold `pacific-herring-predators` repo — directory layout, README, .gitignore, renv stub.
- [ ] `docs/predator-coverage-matrix.md` with the table above as the canonical machine-readable form (CSV mirror).
- [ ] `R/` skeletons for ingest helpers per source (DFO, IPHC, PFMC/JTC, BBS/CBC, BCCWS, Triangle Island, BCCSN).
- [ ] Pull seed Zotero items from herring library, group by taxon, write `docs/zotero-seed-papers.md`.
- [ ] Create NotebookLM notebook seeded with PDF + URL sources by taxon; record short_code in predator repo README.
- [ ] First two illustrative time series ingested (suggest: Pacific hake JTC + BC harbour seal SAR) to prove schema.
- [ ] Cross-link from `Data/raw/predators/DATA_SOURCES_README.txt` to predator repo location.

## Related files

- `Data/raw/predators/DATA_SOURCES_README.txt` — current raw data provenance for the three mammals already ingested.
- `R/01_data_cleaning.R` `clean_predators()` — current annual aggregation logic.
- `R/10_spatial_data.R` `build_predator_spatial_index()` — site-level spatial weighting.
- `docs/theory-data-model-integration.md` — predator covariates in the Stan data contract.
