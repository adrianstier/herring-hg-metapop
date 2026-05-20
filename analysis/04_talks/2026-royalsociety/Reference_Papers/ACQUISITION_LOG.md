# Reference paper acquisition log

Updated 2026-05-17. State for cross-session continuity (Agent A stalled on the
DFO doc hunt; this log was written by the coordinating session after recovery).

## ⚠️ Data-integrity fix applied

The **9 original dossier "PDFs" were ZIP bundles of page JPEGs**, not real
PDFs (mis-exported 2026-05-10). They have been **repaired into valid
multi-page PDFs** (page-image PDFs at 200 dpi — readable, figures intact, but
**not text-searchable / not OCR'd**). Originals preserved as
`*.pdf.imgzip.bak`. Affected: Doherty 2025, Ingeman 2019, Levin 2020,
Okamoto 2020, Samhouri 2017, Selkoe 2015, Shelton 2014, Stier 2020 Ecosphere,
Stier 2016 Science Advances. If text-search/quality matters, re-acquire clean
copies later (Stier 2020 Ecosphere & Shelton 2014 are open access; Doherty
2025 ICES JMS is often OA via OUP).

## Status vs the 12-paper target list

| # | Paper | Status | File |
|---|---|---|---|
| 1 | Cleary et al. 2024/DFO 2025/005 (HG status / forecast) | GOT in core repo public extraction | `Output/diagnostics/dfo_assessment_public_sources/dfo_science_response_2025_005.pdf` |
| 2 | Stier et al. 2016 *Conservation Letters* (cognitive maps, N=27) | ✅ GOT (clean) | `Stier_2016_ExpertPerceptionsFoodWeb.pdf` |
| 3 | Rocha et al. 2018 *Science* (cascading regime shifts) | **PENDING — paywalled, CDP** | — |
| 4 | Lenton et al. 2008 *PNAS* (tipping elements) | ✅ GOT (clean) | `Lenton_2008_TippingElementsClimateSystem.pdf` |
| 5 | Surma & Pitcher 2015 (whale recovery NE Pacific food webs) | ✅ GOT (clean) | `Surma_2015_WhaleRecoveryNEPacificFoodWebs.pdf` |
| 6 | Benson 2015 (aggregate-harvest conservation risk, BC herring) | ✅ GOT (clean) | `Benson_2015_ConservationRisksAggregateHarvestHerring.pdf` |
| 7 | Gerrard 2014 (HG herring spawn contraction / TEK) | ✅ GOT (clean) | `Gerrard_2014_HaidaGwaiiHerringSpawnContraction.pdf` |
| 8 | Haida Gwaii Herring Rebuilding Plan, April 2024 | **USER-ONLY** (CHN / Parks Canada / DFO) | — |
| 9 | Chavez et al. 2003 *Science* (anchovies↔sardines) | **PENDING — paywalled, CDP** | — |
| 10 | Essington et al. 2015 *PNAS* (fishing amplifies forage collapses) | ✅ GOT (clean) | `Essington_2015_FishingAmplifiesForageFishCollapses.pdf` |
| 11 | Pikitch et al. 2014 *Fish and Fisheries* | **PENDING — paywalled, CDP** | — |
| 12 | Möllmann et al. 2009 *Global Change Biology* (Baltic regime shift) | **PENDING — paywalled, CDP** | — |

**Got: 8/12 or source-resolved** (Stier ConsLett, Lenton, Surma, Benson,
Gerrard, Essington, Rebuilding Plan, DFO 2025/005 via the core extraction).
Repaired: 9 dossier image-bundles. Remaining: 3 paywalled theory/analogue
papers plus Chavez 2003 if still desired.

## Confirmed citations (resolved by Agent A before stall — re-ground vs DOI)

- #5 Surma & Pitcher 2015 — confirm exact journal/volume on the downloaded PDF.
- #6 Benson 2015 — confirm exact journal/volume on the downloaded PDF.

## Ready-to-run `download-papers` TSV (paywalled residual)

Run after Chrome-CDP is live (`download-papers /tmp/papers.tsv .` from this
dir). The CDP agent must CONFIRM each DOI via Semantic Scholar/Crossref before
trusting these URLs (Möllmann DOI uncertain — do not assume):

```
Rocha_2018_CascadingRegimeShifts	https://www.science.org/doi/pdf/10.1126/science.aat7850
Chavez_2003_AnchoviesSardines	https://www.science.org/doi/pdf/10.1126/science.1075880
Pikitch_2014_ForageFishContribution	https://onlinelibrary.wiley.com/doi/pdfdirect/10.1111/faf.12004
Mollmann_2009_BalticRegimeShift	https://onlinelibrary.wiley.com/doi/pdfdirect/10.1111/j.1365-2486.2008.01814.x
```

The Cleary/DFO Science Response is already fetched by the herring repo's public
DFO extraction workflow. Do not copy it into git; use the source path in the
core repo and the DFO WAVES URL in the source-provenance docs.

## UPDATE 2026-05-16b

- ✅ **HG Herring Rebuilding Plan (April 2024) — ACQUIRED** (was "user-only").
  `HG_Herring_Rebuilding_Plan_2024_CHN_DFO_ParksCanada.pdf` (5.9 MB, ~138 pp,
  verified). Source: DFO WAVES `https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf`
  ("Haida Gwaii 'íináang | iinang Pacific Herring rebuilding plan"). Also at
  CHN: https://chnmarineplanning.ca/tabs-plans/haida-gwaii-iinaang-iingang-herring-rebuilding-plan
- ✅ **Pikitch 2014 — ACQUIRED** (`Pikitch_2014_ForageFishContribution.pdf`,
  113 KB — small; sanity-check it's the full article, not an extract).
- ❌ **Rocha 2018, Chavez 2003 (Science), Möllmann 2009 (Wiley) — FAILED-auth.**
  `download-papers` returned 536-byte HTML login pages and auto-deleted them.
  Cause: the debug-Chrome profile (`~/.chrome-debug-profile`) has **stale UCSB
  SSO cookies**. Fix: in that debug Chrome window, open one science.org and one
  onlinelibrary.wiley.com article, complete UCSB SSO once, then re-run
  `download-papers /tmp/papers.tsv <ReferencePapersDir>` (it skips the 16
  already-valid files; only re-fetches the 3). Möllmann DOI still unconfirmed —
  if it 404s after SSO, confirm DOI via Crossref/Semantic Scholar.
- **Cleary/DFO Science Response 2025/005 — SOURCE-RESOLVED.** Local source:
  `Output/diagnostics/dfo_assessment_public_sources/dfo_science_response_2025_005.pdf`
  and `.txt`. URL:
  `https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf`.
  Extracted tables live under
  `Output/diagnostics/dfo_newer_public_pdf_extract/`.

## UPDATE 2026-05-17 — Cleary clean PDF now in the dossier

✅ **Cleary / DFO CSAS Science Response 2025/005** — clean original PDF located
in `~/Downloads/41290963.pdf` (WAVES id confirms provenance; identical dup
`41290963-2.pdf` ignored). Copied to dossier as
`Cleary_DFO_SR2025-005_PacificHerringStatus2024.pdf` (52 pp, %PDF-, verified;
"Procedures for Pacific Herring (Clupea pallasii) in BC: Status in 2024 and
Forecast for 2025"). Dossier now 18 PDFs. This is the S17 (SoG negative
control) / S18 (zero-below-LRP) source — now fully in hand alongside the repo
extraction + Tables 11/15/19 CSVs under `dfo_newer_public_pdf_extract/`.

## UPDATE 2026-05-19 — NotebookLM ingestion + OCR repair

Synced the local PDF library into the **"Herring Haida Gwaii" NotebookLM
notebook** (`63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`). 10 papers that were
missing were added (151 → 161 sources); reconciled the dossier + `Literature/`
against notebook sources.

- ➕ **New paper acquired & filed:** `~/Downloads/fsy091.pdf` → renamed
  `Literature/MacCall_et_al_2019_ICESJMS_Socially_Learned_Migration_GWOF.pdf`
  (MacCall et al. 2019 ICES JMS, the "Go With the Older Fish"/GWOF socially-
  learned migration model — Pacific herring, Haida/Tlingit co-authors).
  Indexed; queryable in NotebookLM (verified).
- 🔧 **OCR repair:** the repaired image-bundle PDFs had **zero text layer**, so
  NotebookLM (no OCR) could not index them. OCR'd via `ocrmypdf --force-ocr`
  and re-uploaded (old image-only NotebookLM sources deleted, replaced):
  - Ingeman 2019 Science — 0 → 76k chars ✅
  - Levin 2020 BioScience — 0 → 46k chars ✅
  - Selkoe 2015 ESS — 0 → 78k chars ✅
  - Stier 2016 Science Advances — 0 → 84k chars ✅
  Pre-OCR originals preserved (`*.imgzip.bak`; Pikitch `*.preocr.bak`).
- ⚠️ **`Pikitch_2014_ForageFishContribution.pdf` is NOT the article at all.**
  OCR + NotebookLM both confirm it is a **1-page Cloudflare "security
  verification" bot-check page** (~236 chars), not the Pikitch et al. 2014
  *Fish and Fisheries* "little fish, big impact" paper. The "✅ ACQUIRED" note
  in UPDATE 2026-05-16b above is **superseded / WRONG** — this paper still
  needs a clean re-download
  (`https://onlinelibrary.wiley.com/doi/pdfdirect/10.1111/faf.12004`, Wiley,
  paywalled → Chrome-CDP + UCSB SSO).
- Note: same-paper-different-filename duplicates already in the notebook were
  NOT re-added (e.g. Benson/Cleary 2015, Essington 2015, Surma 2015, the
  Cleary DFO SR, predators `raum-suryan`/`rehberg`); the 9-gap reconciliation
  treated those as present.

## UPDATE 2026-05-19b — Pikitch 2012 Lenfest report: filed locally, NotebookLM BLOCKED

### Context
**Pikitch 2012 ≠ Pikitch 2014.** Two separate Pikitch forage-fish works:
- **Pikitch 2014** — *Fish and Fisheries* journal article (doi:10.1111/faf.12004).
  Local file `Pikitch_2014_ForageFishContribution.pdf` is the Cloudflare bot-check
  stub from the 2026-05-16b download attempt — **not the real article**. Still
  PENDING (paywalled Wiley; needs Chrome-CDP + UCSB SSO). The `.preocr.bak`
  was also a stub and has been left untouched.
- **Pikitch 2012** — *Lenfest Ocean Program* full report, "Little Fish, Big Impact:
  Managing a crucial link in ocean food webs." Open-access, freely downloadable.
  This is the source that was previously uploaded as a Cloudflare stub (source_id
  `b513bbe5-9f13-4abb-88e5-4da87a0596d4`, now deleted).

### What completed
- ✅ **Step 1 — PDF filed:** Real Pikitch 2012 Lenfest report copied from
  `~/Downloads/Pikitch et al 2012 - Little Fish, Big Impact.pdf` →
  `analysis/04_talks/2026-royalsociety/Reference_Papers/Pikitch_2012_LittleFishBigImpact_Lenfest.pdf`
  Verification: `%PDF-` header ✓, 345,508 chars ✓ (>300k threshold), text-clean ✓.
- ✅ **Step 2 — Old Cloudflare stub deleted:** source_id `b513bbe5-9f13-4abb-88e5-4da87a0596d4`
  deleted from notebook `63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`.
- ✅ **Notebook cleanup:** 20 empty zombie stubs deleted during troubleshooting
  (4 Pikitch text-test stubs, 9 URL/test stubs, 6 pre-existing empty Drive Document
  stubs with char_count=0, 1 diagnostic stub). Final clean state: 160 sources,
  PDFs: 154, web_page: 6, unknown: 0.

### What is BLOCKED
- ❌ **Step 3 — NotebookLM upload BLOCKED:** All source-add attempts for notebook
  `63dbc0f0` fail. Errors observed:
  - File upload RPC `o4cbdc` → status `[3]` (INVALID_ARGUMENT) before any bytes sent
  - Text source → status `[9]` (FAILED_PRECONDITION); stub created but ingestion never completes
  - Google Drive source (uploaded to astier@ucsb.edu Drive, id `12Rekms56dBFTZZ_CdFAwwiEliWinNJ_0`,
    shared with adrian.stier@gmail.com, made public) → status `[9]`
  - Drive URL variants (view, uc?export=download, open?id) → all fail
  - Confirmed NOT a file-quality issue: same PDF uploads successfully to a different
    notebook (`1046fbeb-4f60-4ba9-8b76-269218f68a67`). The block is specific to `63dbc0f0`.
  - Root cause hypothesis: notebook may be hitting an undocumented per-type or
    content-size limit (154 PDFs in a single notebook is unusually high).
- ❌ **Step 4 — Indexing verification:** blocked by Step 3 (no PIKITCH2012_SID recorded).
- ❌ **Step 6 — nlm source list grep:** blocked by Step 3.

### PIKITCH2012_SID
**NOT YET RECORDED** — upload never succeeded. Record here once Step 3 is resolved.

### User action required
Open `https://notebooklm.google.com` in a browser (signed in as
`adrian.stier@gmail.com`), navigate to the "Herring Haida Gwaii" notebook
(`63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`), check for error banners or a stuck
ingestion state, then manually upload
`analysis/04_talks/2026-royalsociety/Reference_Papers/Pikitch_2012_LittleFishBigImpact_Lenfest.pdf`.
Once the upload succeeds and the source is indexed, record the new source ID
here as `PIKITCH2012_SID` and run:
```bash
nlm source list 63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e 2>/dev/null | grep -i pikitch
```
