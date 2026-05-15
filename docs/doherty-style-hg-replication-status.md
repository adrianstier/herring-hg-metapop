# Doherty-Style HG Replication Status

Updated: 2026-05-15

## What Is Now Executed

The public-data replication path has moved from planning to provisional
extraction.

Run order:

```sh
Rscript --vanilla Code/02d_fetch_dfo_herring_assessment_sources.R
Rscript --vanilla Code/02e_extract_dfo_hg_assessment_tables.R
Rscript --vanilla Code/02f_extract_newer_dfo_public_pdfs.R
Rscript --vanilla Code/07bk_doherty_hg_data_readiness.R
Rscript --vanilla Code/07bl_doherty_replication_execution_status.R
Rscript --vanilla Code/07bi_model_decision_ledger.R
```

Current generated outputs are under ignored diagnostics directories:

- `Output/diagnostics/dfo_assessment_public_sources/`
- `Output/diagnostics/dfo_hg_public_extract/`
- `Output/diagnostics/dfo_newer_public_pdf_extract/`
- `Output/diagnostics/doherty_hg_replication_execution_status.md`
- `Output/diagnostics/doherty_hg_predator_class_crosswalk.csv`
- `Output/diagnostics/doherty_hg_model_gate_ledger.csv`

## Herring Tables Extracted From Public DFO Sources

From DFO CSAS Research Document 2018/028 Appendix B, the extractor now creates
provisional HG tables:

| Product | Source | Rows extracted | Status |
|---|---|---:|---|
| catch by gear | Appendix B Table B.1 | 67 wide / 201 long | provisional public extraction |
| spawn index | Appendix B Table B.8 | 67 | provisional public extraction |
| number-at-age | Appendix B Table B.15 | 72 source-year / 648 age rows | provisional public extraction |
| weight-at-age | Appendix B Table B.22 | 67 year / 603 age rows | provisional public extraction |
| biosample counts | Appendix B Table B.29 | 63 | provisional public extraction |
| maturity-at-age | Section 2.1.4 | 9 | manually encoded from published text |

These are good enough for schema review and source-PDF spot checks. They are
not final model inputs.

## Newer Public PDF Extraction

`Code/02f_extract_newer_dfo_public_pdfs.R` now mines post-2018 public DFO PDFs.

Valid local PDF/text extraction succeeded for:

- DFO CSAS Science Response 2025/005;
- the 2024/2025 Pacific Herring IFMP;
- the Haida Gwaii Herring Rebuilding Plan.

The 2025/2026 IFMP catalogue confirms a public PDF, but command-line requests
to the direct PDF still return an HTML archive page. Treat that as an access
block, not an indication that the document or data do not exist.

Clean newer public extracts now include:

| Product | Source | Rows extracted | Status |
|---|---|---:|---|
| SCA input data windows | DFO 2025/005 Table 1 | 12 | public summary |
| major SAR catch | DFO 2025/005 Table 2 | 10 | public summary |
| HG spawn index / sub-stock proportions | DFO 2025/005 Table 3 | 10 | public summary |
| HG SCA key parameters | DFO 2025/005 Table 7 | 11 | public summary |
| HG age-2 recruitment | DFO 2025/005 Table 11 | 10 | public summary |
| HG spawning biomass and depletion | DFO 2025/005 Table 15 | 10 | public summary |
| HG reference points / 2025 projection | DFO 2025/005 Table 19 | 13 | public summary |
| projected 2025 biomass / broad age proportions | 2024/2025 IFMP Table 3.1 | 4 | public summary |
| rebuilding-plan biological captions | HG rebuilding plan | 92 | caption/provenance audit |

The Science Response confirms that major-stock SCA input windows run through
2024 for catch, spawn index, age composition, and weight-at-age. It does not
publish the exact annual age/weight matrices or effective sample sizes.

## Predator Crosswalk Status

The HG predator product can support annual demand/removal-rate context, but not
yet Doherty-style age-specific predation mortality.

| HG predator class | Current status | Blocking issue |
|---|---|---|
| humpback whale | annual demand available | section exposure and age/size selectivity missing |
| Steller sea lion | demand and HG spatial sites available | raw/fill flags and age/size selectivity missing |
| harbour seal | demand and HG spatial sites available | complex-year handling and age/size selectivity missing |
| California sea lion | broad Northern BC allocation available | clean HG-only allocation missing |
| fish predators | important HG demand layer available | coarse regional scale and no age selectivity |
| salmon predators | juvenile context available | not adult SSB predation mortality |
| bird egg predators | spawn-stage context available | not adult catch-at-age removals |

## Not Found Yet

These remain explicitly missing or not machine-readable locally:

- exact annual 2018-2024 HG number/proportion-at-age and weight-at-age input
  matrices;
- exact SCA/SISCAH input files;
- effective sample sizes and preprocessing rules for age-composition
  likelihoods;
- machine-readable length-at-age tables;
- predator selectivity-at-age or selectivity-at-size by predator class;
- future predator scenario tables;
- a regional HG catch-at-age model design that is separate from the 11-section
  Stier biomass model.

## Model Decision

Do not fit a Doherty-style predator-removal catch-at-age model yet.

The repo can now reproduce the public-data input layer through 2017 in
provisional form, add current public SCA/status summaries through 2024, and
compute predator-demand context. It still lacks the age-selective
predator-removal machinery and exact current machine-readable assessment inputs
needed for a defensible Doherty analogue.

The promoted baseline remains `m1_stier_11`: ambiguous zeros, two-era `q`, 11
sections, and biomass-based section states.
