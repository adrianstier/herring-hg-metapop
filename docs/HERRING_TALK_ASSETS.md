# Haida Gwaii Herring Talk — Master Asset Index

**This file is the single source of truth for the Pacific herring / Haida Gwaii
talk.** It indexes every slide, photo, lecture, note, dataset, figure,
NotebookLM source, and Drive folder *in place* (nothing is copied or moved) and
tracks the cross-session build state.

> **Any new Claude or Codex session working on this talk MUST read this file
> first.** Claude enters via `CLAUDE.md`; Codex enters via `AGENTS.md`; both
> point here. When you finish a working session, update the
> **Talk Build State** section at the bottom so the next context window picks up
> cleanly.

Last updated: 2026-05-17 (talk blockers resolved/bounded; deck approach, S15, S19, S20, and portfolio-number provenance documented).

---

## 1. Talk Target

| Field | Value |
|---|---|
| Event | US–UK Scientific Forum on Shifts and Tipping Points in Ocean Systems |
| Host | The Royal Society (UK) + US National Academies partnership |
| Venue | The Royal Society, 6–9 Carlton House Terrace, St James's, London SW1Y 5AG |
| Forum dates | 19–20 May 2026 (welcome reception Mon 18 May, One Great George Street) |
| **Speaker slot** | **Wed 20 May 2026, 9:30 am** — Session 5: *Tipping Points in Ecosystem Services* |
| Slot length | ~25 min incl. Q&A (Cavan 9:05, **Stier 9:30**, White 9:55) |
| Session chair | **Ida Kubiszewski** (UCL, ida.kub@gmail.com); Forum co-chair Corinne Le Quéré |
| Chair's steer | Abstract reviewed, "fits the session well"; one explicit ask: **"focus on solutions as much as possible."** |
| Audience | ~40 leading ocean/climate/marine-ecology scientists (Pinsky, Will White, Dan Smale, Emma Cavan, Chris Costello, etc.) |
| Working title | Programme booklet has no separate talk-title line; use **"Coupled Tipping Points in Pacific Herring & Haida Gwaii"** unless Adrian supplies a shorter final title. |
| Recording | Forum recorded; video posted online 2–3 weeks after. Tell organizers if any unpublished result must not be public. |
| Slides | **Send final `.pptx` to `scientific.meetings@royalsociety.org`.** Stated deadline COB Mon 11 May 2026 → **OVERDUE; send ASAP.** Royal Society PC, PowerPoint. |
| Linked paper | The herring metapopulation paper (this repo). If the talk uses the portfolio-erosion result, keep numbers consistent with the current `m1_stier_11` analysis (not the early abstract's phrasing). |
| Source agenda | Gmail-shared Doc id `1zoEvxKL2G1oovUt9acsuPBvTdXgMQ-d2`; local `~/Downloads/Full Agenda_ 2026 US-UK Forum on Tipping Points in Ocean Systems.docx` |

### ⚠️ Submitted abstract — early concepts only, NOT the talk's guide

> **This is NOT a locked spine. Do not build the talk to it.** Adrian
> submitted these as loose early concepts for the program deadline; they do
> not bind the narrative. The correct outline for the tipping-points talk is
> **open and being developed with Adrian** (see Talk Build State / §"Outline
> options"). The text below is recorded only as historical context for what
> was loosely promised to the organizers, and as one possible source of raw
> material — nothing more.

> Pacific herring in Haida Gwaii, British Columbia, offer a diagnostic case of
> coupled social-ecological tipping points. A 65-year spatially explicit time
> series across 11 subpopulations reveals not biomass collapse but portfolio
> erosion — the synchronization of formerly asynchronous subpopulations, with
> realized growth rates depressed in seven of nine focal stocks since the 1994
> fishery closure. A parallel tipping point operates on the social side:
> cognitive-map elicitation from 27 regional experts reveals two structurally
> distinct mental models that predict opposite ecosystem responses to herring
> recovery, while archaeological and qualitative evidence indicate that the
> abundance required to sustain Haida k'aaw harvest practice has fallen below
> its threshold for the first time in approximately 10,000 years. The
> Archipelago Management Board — a co-governance arrangement between the Council
> of the Haida Nation, Parks Canada, and Fisheries and Oceans Canada — operates
> as a structural intervention on these coupled tipping points. I close with
> three transferable lessons for forage-fish management in the US and UK.

### Current talk outline — 20-slide production plan

The canonical talk sequence is now
`talk-usuk-forum-2026/Talk_Materials/talk_production_plan.md`: a 20-slide
working plan for the Royal Society ecosystem-services session, plus backup
slides for likely questions. Older `talk_outline_v1.md` and
`talk_outline_v2.md` remain useful for citation maps and rigor corrections,
but they no longer control slide order.

Constraints that still govern the deck:

- Audience = tipping-points/regime-shift experts (not undergrads, not a
  fisheries-management crowd) — Session 5 is *Tipping Points in Ecosystem
  Services*.
- Chair's only steer that still stands: **lead with / emphasize solutions.**
- Strong asset base exists (the 35-slide EEMB142C teaching lecture, 235
  organized assets, 60 papers — §3f) but it is undergrad pedagogy at 2× the
  length; it is raw material, not the structure.
- This repo's portfolio-erosion result is the most defensible *quantitative*
  tipping-points content available; the social/governance material is the
  differentiator for this audience.

No session should "build to the abstract." Build to the canonical production
plan and the claim-control sheet.

---

## 2. How to use this file

- **Read first**, before touching any talk slide, figure, or narrative work.
- Assets are referenced by **absolute path** or stable link. Do not copy assets
  into the repo (decision: index-in-place + pointers).
- The catalog table (section 3) is intentionally agent-parseable: stable
  columns `id | type | title | location | status | use-for`.
- `status` values: `ready` (use as-is), `draft`, `raw-material` (mine for
  content/narrative), `data`, `external` (lives outside repo), `pending`
  (needs an action to retrieve).
- When you add, retrieve, or finalize an asset, **update its row and the Talk
  Build State section** in the same session.
- NotebookLM is the citation-grounding source (see section 4). Do not cite a
  paper for the talk that you cannot ground in NotebookLM, Zotero, or the
  predator repo synthesis.

---

## 3. Asset catalog

### 3a. Talk-prep & evidence docs (this repo)

| id | type | title | location | status | use-for |
|---|---|---|---|---|---|
| TP-01 | doc | Saturday talk readiness (spine, numbers, 14-figure order) | `docs/saturday-talk-readiness-2026-05-16.md` | raw-material | headline numbers, figure order, caveats |
| TP-02 | doc | Monday talk sprint plan (claims, must-have figures, work order) | `docs/monday-talk-sprint-plan.md` | raw-material | talk-ready claims, figure shortlist |
| TP-03 | doc | Collaborator reading guide (repo orientation) | `docs/collaborator-reading-guide.md` | ready | onboarding a new session to the codebase |
| TP-04 | doc | Current population & driver findings | `docs/current-population-driver-findings.md` | raw-material | core scientific story |
| TP-05 | doc | May-9 analysis decision summary + output index | `docs/may-9-analysis-decision-summary.md`, `docs/may-9-analysis-output-index.md` | raw-material | what is decided vs held |
| TP-06 | doc | Integrated evidence matrix (claim/evidence/caveat) | `Output/diagnostics/may10_integrated_evidence_matrix.md` | ready | claim → evidence → caveat control sheet |
| TP-07 | doc | Promoted baseline evidence package | `Output/diagnostics/promoted_baseline_evidence_package.md` | ready | shortest defensible evidence for the baseline |
| TP-08 | doc | Covariate readiness registry | `Output/diagnostics/covariate_readiness_registry.md` | ready | what is in-model vs future vs held |
| TP-09 | doc | Section action matrix | `Output/diagnostics/section_action_matrix.md` | ready | section-level narrative roles |
| TP-10 | doc | Latest model status + decision ledger | `Output/diagnostics/latest_model_status.md`, `Output/diagnostics/model_decision_ledger.md` | ready | model provenance / what to claim |
| TP-11 | doc | **Herring non-recovery hypotheses & cross-system idea bank** | `docs/herring-non-recovery-hypotheses.md` | ready | mechanism menu (cod + herring lit), HG support ranking, contested-recovery nuance, governance-under-uncertainty solutions; **the place for talk hypotheses/ideas** |
| TP-12 | doc | **Talk model claim control sheet** | `docs/talk-model-claim-control-sheet.md` | ready | safe/unsafe language for every model, predator, recovery, DFO, and Doherty claim |
| TP-13 | doc | **Doherty-style HG gap table** | `docs/doherty-style-hg-gap-table.md` | ready | concise replication-gap table: present vs provisional vs missing vs proxy-only |
| TP-14 | doc | **20-slide talk production plan + backup/Q&A slides** | `talk-usuk-forum-2026/Talk_Materials/talk_production_plan.md` | ready | canonical slide order, treatment rhythm, asset wiring, likely-question backup slides |

### 3b. Figures (this repo)

| id | type | title | location | status | use-for |
|---|---|---|---|---|---|
| FIG-ORDER | doc | Curated 14-figure talk order | `docs/saturday-talk-readiness-2026-05-16.md` (Figure Order) | ready | authoritative figure list — do not re-list paths here, they drift |
| FIG-MUST | doc | Monday must-have figure shortlist | `docs/monday-talk-sprint-plan.md` (Must-Have Figures) | ready | minimal figure set |
| FIG-DIR | dir | All rendered figures (PDF + PNG) | `Output/figures/` | ready | pull specific panels by name from the curated lists |
| FIG-LEC | script | Lecture-figure generation script | `R/07_lecture_figures.R` | ready | regenerate talk/lecture figures |

### 3c. Lectures, teaching decks & narrative sources

| id | type | title | location | status | use-for |
|---|---|---|---|---|---|
| LEC-01 | pdf | Stier 2024 EEMB242 Metapopulation Herring lecture | `Literature/Stier_2024_EEMB242_Metapopulation_Herring_Lecture.pdf` | raw-material | existing metapop talk slides/structure |
| LEC-02 | pdf | L-Metapop-Herring EEMB242 2024 | `~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/L-Metapop-Herring-EEMB242-2024.pdf` | raw-material | metapop lecture (Drive copy) |
| LEC-03 | pdf | EEMB242 Tipping Points & Resilience 2024 | `~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/EEMB 242-Tipping Points and Resilience-2024.pdf` | raw-material | **tipping-points framing** lecture — directly on-theme |
| LEC-04 | docx | Herring in the Anthropocene — "Who gets the herring?" outline 2026 | `~/Downloads/herring-outline-2026.docx` | raw-material | **candidate narrative spine** (allocation + collapse arc) |
| LEC-05 | pdf | L2 Pacific Herring Case Study (Anthro Cons 142C, Apr 2026) | `~/Downloads/L2-Pacific_Herring_Case_Study_Anthro_Cons_142c_4_1_2026_updated.pdf` | raw-material | case-study slides, figures, framing |
| LEC-06 | html | Haida Gwaii herring timeline | `~/Downloads/herring_haida_gwaii_timeline.html` | raw-material | causal-timeline narrative device |
| LEC-07 | pptx | "We Fish Down the Food Web" deck | `~/Downloads/We-Fish-Down-the-Food-Web-Apex-Predators-First-Then-Everything-Below.pptx` | raw-material | predator/forage-web framing slides |
| LEC-08 | gdoc | Practice-talk notes (Hayden; Samhouri OSU) | `~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/Hayden practice talk.gdoc`, `Samhouri OSU practice talk.gdoc` | raw-material | prior talk framing/feedback (verify relevance) |

### 3d. Media, photos & datasets

| id | type | title | location | status | use-for |
|---|---|---|---|---|---|
| MED-01 | video | Predator footage `12dpb_predators.MOV` | `~/Downloads/12dpb_predators.MOV` | raw-material | spawn/predator visual |
| DAT-01 | csv | Gwaii Haanas seabird monitoring 1984–2014 | `~/Downloads/gwaii_haanas_npr_seabirds_1984-2014_data.csv` | data | seabird-predator context |
| DAT-02 | csv | Gwaii Haanas marine-mammal monitoring 2004–2010 | `~/Downloads/gwaii_haanas_npr_mamu_2004-2010_data.csv` | data | mammal-predator context |
| LIT-01 | pdf | Eisaguirre 2020 Ecology — trophic redundancy / predator size structure | `~/Downloads/Ecology - 2020 - Eisaguirre - Trophic redundancy and predator size class structure drive differences in kelp forest.pdf` | raw-material | predator-structure analogy |
| LIT-02 | pdf | PNAS 2108878119 supplementary | `~/Downloads/pnas.2108878119.sapp.pdf` | raw-material | verify which paper; likely rapid-recovery/forage-fish |

### 3e. Predator analysis repo (sibling: `/Users/adrianstier/pacific-herring-predators`)

| id | type | title | location | status | use-for |
|---|---|---|---|---|---|
| PRD-01 | doc | HG predation synthesis | `/Users/adrianstier/pacific-herring-predators/docs/HG_PREDATION_SYNTHESIS.md` | ready | predator demand/pressure narrative |
| PRD-02 | doc | Data dictionary + catalogs | `/Users/adrianstier/pacific-herring-predators/docs/DATA_DICTIONARY.md`, `docs/data_catalog.csv`, `docs/data_catalog_HG_only.csv` | ready | predator data provenance |
| PRD-03 | doc | HG share findings / coastwide viz proposals | `/Users/adrianstier/pacific-herring-predators/docs/HG_share_findings.md`, `docs/HG_vs_coastwide_visualization_proposals.md` | raw-material | predator figures & framing |
| PRD-04 | csv | Audited HG predation pressure + covariates | `/Users/adrianstier/pacific-herring-predators/data/processed/consumption_budget/HG_predation_pressure_index_AUDITED.csv` (+ `_climate_predator_covariates.csv`, `HG_consumption_by_group_year_AUDITED.csv`, `_by_species_year_AUDITED.csv`) | data | predator demand numbers |
| PRD-05 | pdf | Master HG predation figure (audited) | `/Users/adrianstier/pacific-herring-predators/Output/figures/MASTER_HG_predation_AUDITED.pdf` | ready | predator master figure |
| PRD-06 | doc | Predator-repo integration guide (crosswalk) | `docs/predator-repo-integration-guide.md` (this repo) + `CLAUDE.md` | ready | how predator products map into this repo |

### 3f. Google Drive talk-asset library

Shared folder **`1fboyHfQj_hYN9D79LnM2cWe21SywaEz0`** —
https://drive.google.com/drive/folders/1fboyHfQj_hYN9D79LnM2cWe21SywaEz0
(a complete, pre-organized talk-asset repository — it has its **own** master
index `DRV-IDX` and a 13-category photo/video library `DRV-ASSETS` with its own
inventory; treat those as the detailed sub-catalogs, don't re-list every photo
here). Fetch any item by id with
`gws drive files get --params '{"fileId":"<id>","alt":"media","supportsAllDrives":true}' -o <name>`
(write inside the repo dir, delete after) or `files export` for Google Docs.

| id | type | title | location (Drive id) | status | use-for |
|---|---|---|---|---|---|
| DRV-IDX | md/json | Folder's own master asset index | `1oaWz3wSsKLrHasc2Sev5yromdcRCGq22` (ASSET_INDEX.md), `11PAAC7n7D1b4owoGnCKVupdJW8gVAJk3` (ASSET_INDEX.json) | ready | **detailed catalog of the whole Drive folder — read this first for specifics** |
| DRV-DECK | pptx | EEMB142C Week1 Wednesday Spring2026 *modern* deck (53 MB) | `1RjVOJ8oe6ehG42hpOtGVi0dwzrmi1_4v` | raw-material | most-built existing deck; candidate base to adapt for London |
| DRV-SCRIPT | md | LECTURE_SCRIPT.md (35 KB) | `1iS0ykgyP4i1jNeSfiXjiNg17y_HEl867` | raw-material | spoken narrative / script source |
| DRV-OUTLINE | docx | Week1_Wednesday_Outline.docx (15 KB) | `1bXlxurhFkjhkHVSmkOgEDd19Yr_DFW1e` | raw-material | structured talk outline |
| DRV-LIT | md | HERRING_LITERATURE.md (22 KB) | `10pMvPHNiVHwtZYy7PIR2ngm5Z0YMsVFl` | raw-material | curated literature notes (check for k'aaw / cognitive-map / AMB refs) |
| DRV-README | md | Folder README | `1TjRqu2-o0pSa8KjwW0oie4JL0tCAOLtC` | ready | folder orientation |
| DRV-ASSETS | dir | Photo/video library, 13 categories: `01-biology 02-food-web 03-indigenous-cultural 04-overfishing 05-data-graphs 06-recovery-regime 07-maps-spatial 08-field-photos 09-collaborator-photos 10-research-figures 11-videos 12-publications from-242` | folder `1ubgQEK8xnpt2fyo9S1dSX1FeVGbojoCO`; `_INVENTORY.md`=`11zw3ojJ1EBuJIiKW4HJwpQf4l3dCF-Bd`; `_manifest.json`=`1LbP_hwjhvLnVWVBv0E4NmuPgBtZPlFfm` | ready | **all talk imagery/video** — read `_INVENTORY.md` to pick slides; `03-indigenous-cultural` + `12-publications` for the k'aaw/social slides |
| DRV-2019 | dir | `stier-2019-herring-metapop/` legacy repo snapshot (Code/Data/Output) | folder `1teV6jtggO8CwT-oZUfgLmuA2zNimBm7O` | raw-material | legacy analysis/figure provenance |
| DRV-ARCHIVE | dir | `archive/` (2026-iterations, intermediate-extractions, legacy-source) | folder `1Lybo8zo8N6_yFzl218mEXgXsKrv_Iyxk` | external | older iterations; provenance only |

### 3g. In-repo forum dossier — `talk-usuk-forum-2026/` (firewalled from core)

The Desktop `USUK_Forum_2026_Project` was moved into the repo on 2026-05-16 as
`talk-usuk-forum-2026/` — a **TALK-ONLY** workspace, firewalled from the core
analysis (see that folder's `README.md`). Heavy PDFs are gitignored (on
disk + Drive, same policy as `Literature/`); structure + working text/HTML are
tracked. **This is the home for the talk outline / drafts / deck.**

| id | type | title | location | status | use-for |
|---|---|---|---|---|---|
| FRM-README | doc | Workspace README + separation rule | `talk-usuk-forum-2026/README.md` | ready | read first; firewall + how it relates to this index |
| FRM-INDEX | doc | Original archive index (provenance) | `talk-usuk-forum-2026/INDEX.txt` | ready | dossier provenance (exported 2026-05-16 Tahiti) |
| FRM-AGENDA | pdf | Draft forum agenda (use `*_readable.pdf`) | `talk-usuk-forum-2026/Forum_Documents/` | data | confirm slot/session details |
| FRM-TIMELINE | html | Interactive HG herring timeline | `talk-usuk-forum-2026/Talk_Materials/herring_haida_gwaii_timeline.html` | raw-material | narrative/timeline device |
| FRM-TRIP | html | Trip dossier (flights, programme, forms, contacts) | `talk-usuk-forum-2026/Trip_Dossier/` | local-only | logistics — not talk content; gitignored because private |
| FRM-PAPERS | pdf/doc | Curated cited papers + acquisition log (PDFs gitignored) | `talk-usuk-forum-2026/Reference_Papers/` | raw-material | Doherty 2025, Ingeman 2019, Levin 2020, Okamoto 2020, Samhouri 2017, Selkoe 2015, Shelton 2014, Stier 2016, Stier 2020, plus newly acquired forum papers; source state in `ACQUISITION_LOG.md` |
| FRM-WORK | dir | **Talk outline / slide drafts / deck go here** | `talk-usuk-forum-2026/Talk_Materials/` | draft | working talk build location |
| FRM-PROD | doc | **Canonical 20-slide production plan** | `talk-usuk-forum-2026/Talk_Materials/talk_production_plan.md` | ready | current slide sequence, treatment rhythm, asset wiring, backup/Q&A slides |
| FRM-S8 | doc | **S8/S12 landed-value provenance** | `talk-usuk-forum-2026/Talk_Materials/S8_landed_value_provenance.md` | ready | source-corrected value-layer claim; Rebuilding Plan Figs 31/32; closes Gap A |
| FRM-VALUEFIGS | png/doc | **Rebuilding Plan value figure crops** | `talk-usuk-forum-2026/Talk_Materials/figs/` | ready | rendered Fig 31/32 landed-value crops plus provenance for S12 value-layer slide |
| FRM-BUILD1 | html | **Three-layer spine build** | `talk-usuk-forum-2026/Talk_Materials/build1_spine.html` | draft | recurring SPINE visual for slides 2, 12, and 20; structurally complete, still needs browser/render QA |
| FRM-NUMBERS | doc | **Portfolio-number provenance** | `talk-usuk-forum-2026/Talk_Materials/numbers_provenance.md` | ready | reconciles current `m1_stier_11` metrics versus Stier 2020 published annotations |
| FRM-DECKDEC | doc | **Deck build decision** | `talk-usuk-forum-2026/Talk_Materials/deck_build_decision.md` | ready | decision to build a fresh 20-slide expert deck, using Drive assets as source material |
| FRM-S15 | png/doc | **S15 cognitive-map figure crops and provenance** | `talk-usuk-forum-2026/Talk_Materials/S15_cognitive_map_provenance.md`, `talk-usuk-forum-2026/Talk_Materials/figs/cognitive_maps/` | ready | Stier 2016 cognitive-map proof object; preferred Figure 5 crop plus Figure 2 backup |
| FRM-S19 | doc | **S19 co-governance imagery provenance** | `talk-usuk-forum-2026/Talk_Materials/S19_cogovernance_imagery_provenance.md` | ready | official AMB image source, blockade/history source, signing-photo caveats |
| FRM-S20 | doc | **S20 solution payload** | `talk-usuk-forum-2026/Talk_Materials/S20_solution_payload.md` | ready | final three-part close: measure structure, manage exposure, build missing data spine |
| FRM-BLOCK | doc | **Talk blocker resolution log** | `talk-usuk-forum-2026/Talk_Materials/blocker_resolution_2026-05-17.md` | ready | compact handoff of resolved/bounded blockers and remaining production work |

---

## 4. NotebookLM (citation grounding)

- **Notebook:** "Herring Haida Gwaii"
- **ID:** `63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`
- **URL:** https://notebooklm.google.com/notebook/63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e
- **Sources:** 100+ (herring portfolio/governance/TEK + predator literature)
- **Full index, query patterns, gaps, update procedure:**
  `/Users/adrianstier/pacific-herring-predators/docs/notebooklm.md` (do not
  duplicate here — that file is the maintained index; log additions there).
- **Talk rule:** ground every cited paper via NotebookLM → Zotero → PubMed →
  bioRxiv before it goes on a slide. Flag anything unverifiable as
  `[CITATION NEEDED: topic]`.

---

## 5. External sources — RESOLVED (gws auth fixed durably)

`gws` now uses the **file** keyring backend
(`GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file`, exported in `~/.zshenv`; token at
`~/.config/gws/credentials.enc`). Every Claude/Codex shell can call Drive/Gmail
directly — no Keychain, no `!` prefix. If a future session ever sees 401, the
only fix is one re-login (browser OAuth; backend stays `file`):
`gws auth login -s drive,gmail,calendar,sheets,docs`.

**Refresh the Drive folder listing:**
```
gws drive files list --format table --params "{\"q\": \"'1fboyHfQj_hYN9D79LnM2cWe21SywaEz0' in parents and trashed=false\", \"fields\": \"files(id,name,mimeType,modifiedTime,size)\", \"pageSize\": 200, \"orderBy\": \"folder,name\", \"supportsAllDrives\": true, \"includeItemsFromAllDrives\": true}"
```

**Forum email of record:** Gmail msg `19e21e7b74b30c97` ("Meeting Booklet for
the US-UK Forum", 13 May 2026 — final booklet PDF with bios + abstracts).
Session-5 thread `19d538e24a40c585`. Shared agenda Doc id
`1zoEvxKL2G1oovUt9acsuPBvTdXgMQ-d2`. Read a message with
`gws gmail +read --id <messageId>`.

---

## 6. Talk Build State

> Update this section at the end of every working session. It is how multiple
> Claude/Codex context windows stay in sync.

- **2026-05-16 (setup):** Master asset index created. `CLAUDE.md` and
  `AGENTS.md` now point here. Talk Target confirmed from the agenda docx
  (US–UK Royal Society Tipping Points Forum, Wed 20 May 09:30, Session 5
  Ecosystem Services, ~25 min). **Open:** working title + abstract (pull from
  Gmail, §5b); Drive folder contents (§5a); decide whether the
  "Who gets the herring?" allocation/collapse arc (LEC-04) is the spine.
- **2026-05-16 (Doherty proxy):** Added a low-vulnerability HG
  Doherty-style predator-removal proxy branch to the model-farm registry:
  `m5_stier_doherty_proxy_removals`, using `Mp_mid` from the sibling predator
  repo with `DOHERTY_PROXY_PRED_SCALE=0.05`. This is talk-safe only as a
  biomass-scale proxy-removal sensitivity; it is not the completed HG
  catch-at-age predator model. AWS smoke completed, but E-BFMI was poor, so
  no full fit should be shown as a model result yet.
- **2026-05-16 (Mp fallback):** Added `m5_stier_doherty_mp_covariate` as a
  fallback screen, then stabilized it to use detrended
  `pred_mortality_mid_detrended_z` and baseline-anchored priors. Local smoke
  still did not clear practical geometry gates. The updated WCVI bridge screen
  is the talk-safe output: lag-1 detrended Mp has weak growth signal, so do not
  show the Mp Stan branch as a model result.
- **2026-05-16 (predator exposure gate):** Upgraded the seal/sea-lion spatial
  exposure work into a formal section-year data product with 25/50/100 km
  kernels, count sensitivities, and exposure-weighted extrapolation shares.
  The WCVI bridge now screens annual demand and section-year exposure together.
  No exposure row clears the lag-1 gate; the best row is harbour seal exposure
  but its rho is near zero and detrended direction is not a credible predator
  effect. Use this as a talk-safe explanation for why predation remains a
  plausible mechanism/data-product target, not a promoted model result.
- **2026-05-16 (assets + auth + abstract):**
  - **gws auth fixed durably** — UCSB account switched to the file keyring
    backend via `~/.zshenv`; Drive/Gmail now callable from any sandboxed
    Claude/Codex shell (§5).
  - **Drive folder indexed** as §3f (`DRV-*`): a pre-organized talk-asset
    library with its own `ASSET_INDEX.md`, a 53 MB built `modern.pptx`
    (`DRV-DECK`), `LECTURE_SCRIPT.md`, and a 13-category photo/video library.
  - **Abstract found and archived as historical context only** (§1, verbatim);
    later correction below de-locked it. Chair Ida Kubiszewski's explicit ask:
    **lead with solutions.**
- **2026-05-16 (talk outline v1 drafted):** Working slide-by-slide outline +
  speaker notes + per-slide asset map at
  **`talk-usuk-forum-2026/Talk_Materials/talk_outline_v1.md`** — 17 slides,
  Spine B, hysteresis-led, solutions-forward, cod↔herring grammar, HG-as-
  within-coast-exception; predator pit explicitly down-weighted. Includes a
  CREATE-NEW figure list (priority: S9 coupled-feedback diagram, S7 mechanism
  menu, S11 cod↔herring homology), PDF figures to source (McKechnie 2014;
  Stier 2016 *Sci Adv* cognitive maps), repo figures to regenerate from current
  `m1_stier_11`, and a numbers-to-verify list. Awaiting Adrian on: title,
  the 3 lessons (S16), deck mechanics, and go-ahead to build figures.
- **2026-05-16 (outline v2 + acquisition list):** **`talk_outline_v2.md`**
  superseded v1 and applied all 8 corrections + the Lenton/Scheffer/Rocha
  theory spine. It is now retained for its citation map and rigor corrections;
  the canonical slide order is the later 20-slide production plan. Papers
  Adrian must fetch listed in
  **`talk-usuk-forum-2026/Talk_Materials/papers_to_acquire.md`** (7 must-get).
- **Deck location:** build phase started. Canonical outline =
  `talk-usuk-forum-2026/Talk_Materials/talk_production_plan.md`. **First built
  artifact: `talk-usuk-forum-2026/Talk_Materials/build1_spine.html`** — the
  recurring three-layer SPINE (slides 2/12/20), event-driven, timeline visual
  language, on-slide provenance, schematic curves clearly labelled, reconciled
  numbers + correct Stier-2020 attribution. Built & structurally complete;
  **not yet browser-verified**. Remaining builds: #2 hysteresis, #3 portfolio,
  #4 predator-demand, + charts/photos.
- **2026-05-16 (content audit — gap analysis vs. locked spine):** Read
  `DRV-SCRIPT` (LECTURE_SCRIPT.md), `DRV-ASSETS` inventory (235 files), and
  `DRV-OUTLINE`. Finding: the Drive library is a fully-built **50-min,
  35-slide EEMB142C teaching lecture** ("Who gets the herring?", 4-pillar
  pedagogy) with a 53 MB `modern.pptx`, complete script, and 235 organized
  assets + 60 papers. London is a **different deliverable**: 25 min, ~40
  expert scientists, tipping-points + **solutions** spine. So the work is
  *adaptation/compression*, not gathering. Beat-by-beat:
  - **Beat 1 (coupled tipping setup):** new framing slide needed; not in the
    teaching deck's 4-pillar structure.
  - **Beat 2 (ecological tipping = portfolio erosion, 7/9 stocks since 1994):**
    evidence = THIS repo's current `m1_stier_11` analysis (see TP-01/§3b for
    current numbers). Teaching deck uses older Stier-2020 numbers
    (synchrony 0.17→0.28, 2.1×). **Must reconcile abstract's exact claims with
    current repo figures before slides.**
  - **Beat 3a (cognitive maps, 27 experts, two mental models):** evidence =
    **Stier et al. 2016 *Conservation Letters*** (cognitive-map elicitation).
    Only a speaker-note mention in the teaching deck; locate the paper/figure
    (check `DRV-ASSETS/12-publications` — 2016 ConsLett may be missing; the
    listed ConsLett is the 2018 portfolio one) and build a real slide.
  - **Beat 3b (k'aaw below threshold, ~10,000 yr):** strong assets exist —
    McKechnie 2014 PNAS, Haida Marine TEK Vols 1–3, k'aaw governance
    (script S13–14), `08-field-photos` Stier k'aaw photos.
  - **Beat 4 (Archipelago Management Board solution):** assets exist —
    script S26, Gwaii Haanas co-management PDFs, 2024 Rebuilding Plan. This is
    the solutions core the chair asked for; expand it.
  - **Beat 5 (3 transferable US/UK forage-fish lessons):** **does not exist
    anywhere — must be authored.** Highest-value new writing.
- **2026-05-16 (abstract de-locked + Spine B + in-repo dossier):**
  - **Correction:** the submitted abstract is **NOT** the talk guide — early
    concepts only. CLAUDE.md, AGENTS.md, and §1 updated; "locked spine"
    framing removed. No session should build to the abstract.
  - **Direction chosen: Spine B — coupled social–ecological tipping points.**
    Ecological hook reframed as **hysteresis / failed recovery** (collapse
    didn't rebound after fishing stopped) + wrong-state-variable, **not**
    "portfolio/asynchrony as an early-warning indicator" (Adrian rejected the
    EWS framing; portfolio = the *mechanism* explained, not the headline).
    Coupling (social↔ecological, bidirectional) is the novelty; close on a
    structural co-governance intervention; solutions-forward.
  - **In-repo dossier created:** `talk-usuk-forum-2026/` (moved from Desktop),
    firewalled from core analysis, registered as §3g. Talk outline/drafts/deck
    live in `talk-usuk-forum-2026/Talk_Materials/`.
  - **Still open (brainstorm):** (a) confirm hysteresis is the load-bearing
    ecological hook; (b) the close — the exact ask of the room. Then the deck.
- **2026-05-16 (NotebookLM cod+herring synthesis → idea bank):** Queried the
  cod notebook (`092f48e0…`) and herring notebook (`63dbc0f0…`). Built the
  canonical hypotheses/idea bank **`docs/herring-non-recovery-hypotheses.md`**
  (TP-11), referenced from CLAUDE.md + AGENTS.md. Key steers for the talk:
  cod↔herring share one tipping-point grammar; for **HG specifically**
  portfolio/spatial-erosion + PDO/bottom-up are best-supported while the
  charismatic **predator pit is weak for HG** (do not lead with predators);
  "never recovered" is contested (transient vs. permanent; Barents counterpoint;
  HG is the within-coast exception); cod supplies an evidence-based
  governance-under-uncertainty solutions set (refuges > TACs, precautionary
  HCRs, fix the baseline). Reframe candidate: "two systems, one tipping-point
  grammar; removing the stressor ≠ reversing the tip."
- **2026-05-16 (literature gap analysis):** Critical-reviewer NotebookLM
  queries (cod, herring, **Moorea Tipping Points Bible** `faecae81…`). Folded
  into the idea bank `docs/herring-non-recovery-hypotheses.md` §9–§12 and the
  outline's "v1 review — corrections" block. Headlines: (1) **citation fix** —
  cognitive maps = **Stier et al. 2016 *Conservation Letters* 10(1):67–76,
  N=27**, NOT the dossier *Science Advances* PDF; (2) **theory-canon gap** —
  herring/cod nbs lack Lenton/Rocha/Scheffer as primary sources; the Tipping
  Points Bible has them — frame to Lenton's positive-tipping keynote + Rocha
  2018 *Science* cascading-regime-shifts (Levin co-author) for the coupling
  slide; (3) **rigor refinements** — make mechanistic non-identifiability the
  point (PDO also confounded), social threshold is qualitative, co-governance
  not yet a proven ecological fix, add a forage-fish analogue, address the
  fine-scale-monitoring-cost counter (Benson 2015); (4) precise cites gained:
  Cleary 2024, Walters & Maguire 1996, Kjesbu 2014, Schijns 2021/Rose 2004,
  Frank 2011, Pedersen 2017, Jones-Rigg-Lee 2010, Gerrard 2014, Surma & Pitcher
  2015. Acquisition list in hypotheses-doc §12.
- **2026-05-16 (paper acquisition — partial + dossier repair):** Agent A got
  **6/12 clean** before stalling (Stier 2016 *Conservation Letters* — the
  corrected cognitive-map paper; Lenton 2008; Surma & Pitcher 2015; Benson
  2015; Gerrard 2014; Essington 2015). **Discovered + fixed:** the 9 original
  dossier "PDFs" were ZIP bundles of page JPEGs — repaired into valid
  (image-only, not text-searchable) PDFs; originals kept as `*.imgzip.bak`.
  Full state in `talk-usuk-forum-2026/Reference_Papers/ACQUISITION_LOG.md`.
  **This state is superseded by the acquisition updates below.** Ready
  `download-papers` TSV is in the ACQUISITION_LOG.
- **2026-05-16 (acquisition near-complete):** ✅ HG Herring **Rebuilding Plan
  2024** acquired (DFO WAVES `library-bibliotheque/41284161.pdf`; CHN:
  chnmarineplanning.ca/tabs-plans/haida-gwaii-iinaang-iingang-herring-rebuilding-plan).
  ✅ Pikitch 2014. **17 valid PDFs in dossier.** Outstanding: Rocha 2018,
  Chavez 2003, Möllmann 2009 (FAILED — stale UCSB SSO in `~/.chrome-debug-profile`)
  Cleary/DFO SR 2025/005 was later source-resolved through the core DFO public
  extraction workflow.
- **2026-05-17 (model-claim guardrails for the talk):** Added
  **`docs/talk-model-claim-control-sheet.md`** and
  **`docs/doherty-style-hg-gap-table.md`**; resolved the talk-plan predator
  rigor flag by changing S6/S7 from "predator recovery, not climate" to
  "large predator pressure, not a promoted HG coefficient"; corrected the
  timeline's 2020/2021 predator entries; marked Cleary/DFO 2025/005 as locally
  fetched via `Output/diagnostics/dfo_assessment_public_sources/`; and changed
  the talk workspace policy so private `Trip_Dossier/` files stay local and
  gitignored.
- **2026-05-17 (canonical production plan + asset wiring):** Adrian supplied a
  full **production plan** → canonical and later expanded to 20 slides:
  `talk-usuk-forum-2026/Talk_Materials/talk_production_plan.md` (separability /
  three-layer / management-window thesis; 20 slides; 4 dynamic builds; 5
  treatments). `talk_outline_v2.md` demoted to citation-map/rigor-constraints.
  Appended an **Asset wiring** section mapping every slide/build to concrete
  catalogued assets (repo figures, `DRV-ASSETS` photos/videos, predator-repo
  products, acquired papers, the `herring_haida_gwaii_timeline.html` design
  language). Gap A was later closed by the Rebuilding Plan value provenance;
  Gap B remains Athlii Gwaii / 2024 signing photos. The predator rigor flag is
  now resolved by the 2026-05-17 model-claim guardrail entry above.
- **Acquisition final:** 17 valid PDFs + Rebuilding Plan in the dossier. Rocha
  2018, Chavez 2003, Möllmann 2009 **persistently fail** the publisher route
  (UCSB SSO not carried by `~/.chrome-debug-profile`; re-run reproduced 536-B
  login pages) → deprioritized: reachable for grounding via the Moorea Tipping
  Points / cod notebooks; get PDFs later via UCSB library proxy or Zotero if a
  figure is needed. Cleary/DFO SR 2025/005 is source-resolved in the core
  extraction workflow.
- **2026-05-17 (Gap A resolved — S8 landed value sourced):** The S8 keystone
  value series is the **2024 HG Rebuilding Plan, Figures 31 (roe gillnet) & 32
  (roe seine) landed value, BC coastwide + Haida Gwaii, 2020$**, basis = DFO
  fish-slip records. Full verbatim provenance + quotes in
  `talk-usuk-forum-2026/Talk_Materials/S8_landed_value_provenance.md`. **⚠️
  Discrepancy corrected:** the older "1993 peak / ~$40M" language was **not**
  supported — the source says BC roe value **peaked in the 1980s**, high to
  mid-1990s, declined 1995–2005 & 2008–present. State it the sourced way
  unless raw DFO fish-slip data are pulled for an exact peak.
- **2026-05-17 (20-slide expansion + Q&A backups):** Expanded the canonical
  production plan to **20 content slides** with per-slide assets and 8
  likely-question backup slides. Corrected the S8/S12 value-layer claim using
  the Rebuilding Plan provenance and removed the unsupported "1993 / ~$40M /
  93%" language from the production plan and timeline events. Gap A is closed
  for sourcing; Gap B remains co-governance/direct-action/signing imagery.
- **2026-05-17 (🟡 portfolio numbers reconciled):** BUILD #1/#3 + asset-wiring
  in the production plan corrected. Current `m1_stier_11` numbers (synchrony
  0.63 all-11 / 0.70 focal-9; Simpson eff. sections 3.26/3.31; recent-period
  top-3 share 84%) now cite `Output/diagnostics/m1_stier_11_portfolio_metrics.md`.
  "2.1×" and "65% vs 4%" identified as **Stier et al. 2020 published results**
  (not m1_stier_11 outputs) and re-labelled accordingly — not blended into a
  current number. Durable mapping:
  `talk-usuk-forum-2026/Talk_Materials/numbers_provenance.md`. The last
  unsourced numbers are now out of the live plan.
- **2026-05-17 (blockers resolved/bounded for deck production):**
  - **Title:** final programme booklet contains the speaker slot, bio, and
    abstract, but no separate talk-title line. Use "Coupled Tipping Points in
    Pacific Herring & Haida Gwaii" unless Adrian supplies a shorter title.
  - **Deck approach:** resolved in
    `talk-usuk-forum-2026/Talk_Materials/deck_build_decision.md` — build a
    fresh 20-slide expert deck using `DRV-ASSETS` and the timeline visual
    language; do not cut the 35-slide EEMB142C deck into the final talk.
  - **S15:** Stier 2016 *Conservation Letters* cognitive-map figures rendered
    into `talk-usuk-forum-2026/Talk_Materials/figs/cognitive_maps/`; preferred
    proof object and caveats documented in `S15_cognitive_map_provenance.md`.
  - **S19 / Gap B:** source-bounded in
    `S19_cogovernance_imagery_provenance.md`. Use the official Parks Canada
    AMB/Gwaii Haanas image as the safe main slide image; blockade/history and
    2024 signing-news images are rights/label-sensitive backups. No clearly
    reusable herring-rebuilding-plan signing photo was found in bounded search.
  - **S20:** solution close authored in `S20_solution_payload.md`: measure
    structure, manage exposure, build the missing data spine.
  - **Blocker log:** see
    `talk-usuk-forum-2026/Talk_Materials/blocker_resolution_2026-05-17.md`.
- **2026-05-17 (Cleary PDF in dossier):** found in `~/Downloads/41290963.pdf`;
  clean 52-pp `Cleary_DFO_SR2025-005_PacificHerringStatus2024.pdf` now in the
  dossier (S17/S18 source fully in hand; dossier = 18 PDFs). ACQUISITION_LOG
  updated.
- **2026-05-17 (build1_spine.html structural smoke):** local HTTP smoke check
  serves `build1_spine.html` successfully; on-slide provenance carries the
  reconciled/attributed numbers. Browser/render QA and contact-sheet review
  are still required before final `.pptx` export.
- **2026-05-17 (Cleary plug-point map):** Read SR 2025/005 + extracted tables;
  wrote `talk-usuk-forum-2026/Talk_Materials/cleary_sr2025005_plug_points.md`
  - per-slide map with exact table provenance. Highlights: **S6** non-recovery
  thesis in DFO's own words; **S18 keystone** Table 19 confirms
  **P(SB2025<LRP)=0.378 (37.8%) no-catch** and adds
  **P(SB2025<0.75 x SB_Prod)=0.95**; **S7/S8** independent spatial
  concentration (Juan Perez-Skincuttle 85-98%, Louscoone about 0; Table 3);
  **S17** SoG fished 5-25 kt/yr vs HG 0 t (Table 2); **S9/S10** M about 0.45
  (Table 7). Caveat recorded: SR 2025/005 = aggregate SCA, NOT `m1_stier_11`
  metapop; keep separately attributed.
- **Open / next actions (priority order):**
  1. Render/QA `build1_spine.html`; then use it for S2/S12/S20.
  2. Build the remaining heavy proof objects: S7 portfolio, S10 predator
     demand, S14 hysteresis.
  3. Assemble/render the `.pptx` in
     `talk-usuk-forum-2026/Talk_Materials/`.
  4. **Slides OVERDUE to `scientific.meetings@royalsociety.org`** (.pptx) —
     send as soon as the draft deck passes contact-sheet QA.
