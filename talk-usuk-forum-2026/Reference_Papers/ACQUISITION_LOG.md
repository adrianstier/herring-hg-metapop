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
