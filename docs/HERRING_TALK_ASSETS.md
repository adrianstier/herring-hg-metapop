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

Last updated: 2026-05-16.

---

## 1. Talk Target

| Field | Value |
|---|---|
| Event | US–UK Scientific Forum on Shifts and Tipping Points in Ocean Systems |
| Host | The Royal Society (UK) + US National Academies partnership |
| Venue | The Royal Society, 6–9 Carlton House Terrace, St James's, London SW1Y 5AG |
| Forum dates | 19–20 May 2026 (welcome reception Mon 18 May, One Great George Street) |
| **Speaker slot** | **Wed 20 May 2026, 9:30 am** — Session 5: *Tipping Points in Ecosystem Services* |
| Slot length | ~25 min incl. Q&A (slots: Cavan 9:05, **Stier 9:30**, White 9:55) — CONFIRM in Gmail invite |
| Session chair | Ida Kubiszewski (UCL); Forum co-chair Corinne Le Quéré |
| Audience | ~40 leading ocean/climate/marine-ecology scientists (Pinsky, Will White, Dan Smale, Emma Cavan, Chris Costello, etc.) |
| Working title | **TBD — confirm from Gmail invite** (agenda lists the slot with no title yet) |
| Abstract | **TBD — confirm from Gmail invite** |
| Framing | "Related but new" — *not* the repo's old `m1_stier_11` portfolio-talk spine. The herring metapopulation analysis + Haida Gwaii predator/portfolio/governance story is **raw material** for an ecosystem-services tipping-points talk. Spine to be developed across sessions. |
| Linked paper | The herring metapopulation paper (this repo, `stier-2027-herring-metapopulation`). Talk and paper share evidence; keep claims consistent. |
| Source agenda | `~/Downloads/Full Agenda_ 2026 US-UK Forum on Tipping Points in Ocean Systems.docx` |

**Framing guardrail:** index assets neutrally. The strongest narrative
candidate currently on disk is the "Who gets the herring? / Herring in the
Anthropocene" allocation-and-collapse arc (`~/Downloads/herring-outline-2026.docx`),
which maps cleanly onto "Tipping Points in Ecosystem Services." Treat it as a
candidate spine, not a decision, until confirmed with Adrian.

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

## 5. Pending external sources (action required)

The `gws` CLI token lives in the macOS login Keychain and is **not readable
from Claude's sandboxed shell** (401). Two sources are therefore pending.
Populate them by running these in **your** Terminal, or in this chat with a
leading `!` (runs in your session so output lands in the conversation):

### 5a. Shared Google Drive folder ("a lot of stuff is here")

Folder id `1fboyHfQj_hYN9D79LnM2cWe21SywaEz0`
(link: https://drive.google.com/open?id=1fboyHfQj_hYN9D79LnM2cWe21SywaEz0).

```
! gws drive files list --format table --params "{\"q\": \"'1fboyHfQj_hYN9D79LnM2cWe21SywaEz0' in parents and trashed=false\", \"fields\": \"files(id,name,mimeType,modifiedTime,size)\", \"pageSize\": 200, \"orderBy\": \"folder,name\", \"supportsAllDrives\": true, \"includeItemsFromAllDrives\": true}"
```

When the listing appears, the next session will add each file as a `DRV-*` row
in section 3. The folder is also likely mirrored locally under
`~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/` — once the name
is known it can be indexed from the filesystem with no auth.

### 5b. Gmail — official invite (title, abstract, slot length, logistics)

```
! gws gmail users messages list --params "{\"userId\": \"me\", \"q\": \"tipping points ocean OR Royal Society forum OR US-UK forum OR Le Quere herring\", \"maxResults\": 20}"
```

(If the resource path errors, check it with `! gws gmail users --help`.) Then
`! gws gmail +read <messageId>` on the relevant hit to extract the confirmed
**working title, abstract, exact talk length, and travel/logistics**, and fill
the TBD rows in section 1.

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
- **Deck location:** none yet (`Output/presentations/` is empty). Record the
  working deck path here once it exists.
- **Next actions:** (1) run §5a/§5b to close the pending sources; (2) confirm
  framing/spine with Adrian; (3) draft slide outline mapping LEC-04/LEC-03 +
  TP/FIG/PRD evidence onto the ecosystem-services tipping-points theme.
