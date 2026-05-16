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
Rscript --vanilla Code/07bm_doherty_public_extract_qc.R
Rscript --vanilla Code/07bn_hg_dfo_sca_external_comparison.R
Rscript --vanilla Code/07bi_model_decision_ledger.R
```

Current generated outputs are under ignored diagnostics directories:

- `Output/diagnostics/dfo_assessment_public_sources/`
- `Output/diagnostics/dfo_hg_public_extract/`
- `Output/diagnostics/dfo_newer_public_pdf_extract/`
- `Output/diagnostics/doherty_hg_replication_execution_status.md`
- `Output/diagnostics/doherty_hg_predator_class_crosswalk.csv`
- `Output/diagnostics/doherty_hg_model_gate_ledger.csv`
- `Output/diagnostics/doherty_public_extract_qc.md`
- `Output/diagnostics/hg_dfo_sca_external_comparison.md`
- `Output/diagnostics/doherty_proxy_parameter_plan.md`
- `Output/figures/hg_dfo_sca_external_comparison.pdf`
- `Output/figures/doherty_proxy_parameter_plan.pdf`

Tracked request packet:

- `docs/dfo-hg-biological-input-request-packet.md`

## Source Provenance

The canonical source map is `docs/doherty-style-hg-source-provenance.md`.
It records the public DFO URLs, local data paths, sibling predator-repo catalogs,
generated source registries, and unresolved request items for every data stream
in this workflow.

All clean public extracts retain `source_document`, `source_table`,
`source_url`, `extraction_method`, and `extraction_notes`. The main generated
source controls are:

- `Output/diagnostics/dfo_assessment_public_source_registry.csv`
- `Output/diagnostics/doherty_hg_source_registry.csv`
- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_public_extract_audit.csv`
- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_status.csv`

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

`Code/07bm_doherty_public_extract_qc.R` now checks the public extracts for row
counts, year ranges, and complete source fields. All 15 tracked products pass
structural QC. Passing structural QC means the tables are traceable and
internally consistent; it does not make them final catch-at-age model inputs.

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

## Talk-Cycle Proxy Policy

`Code/07bo_doherty_proxy_parameter_plan.R` creates the explicit proxy ledger
for the May 16 talk. The rule is:

- HG public DFO sources are the first anchor for herring biology: catch context,
  number/age composition, weight-at-age, maturity, and current public SCA
  summaries.
- WCVI/Doherty assumptions can be shown only as provisional analogues for
  missing length/size/selectivity or model-structure pieces.
- WCVI catch-at-age, size-at-age, and predator selectivity must not be described
  as Haida Gwaii-estimated parameters.
- The output is suitable for a progress/replication-plan slide, not for a claim
  that a full HG catch-at-age predator-removal analysis has been fitted.

Current proxy output:

- `Output/diagnostics/doherty_proxy_parameter_plan.md`
- `Output/diagnostics/doherty_proxy_parameter_plan.csv`
- `Output/figures/doherty_proxy_parameter_plan.pdf`
- `Output/figures/doherty_proxy_parameter_plan.png`

## External DFO SCA Comparison

`Code/07bn_hg_dfo_sca_external_comparison.R` compares the promoted
`m1_stier_11` all-11 trajectory with public DFO HG SCA biomass/depletion,
public DFO HG spawn/sub-stock proportions, and the current HG predator-demand
product. Treat this as talk-facing scale context, not as a model-likelihood
comparison.

Current 2015-2024 read:

- mean `m1_stier_11` all-11 biomass: about 46.7 kt;
- mean public DFO HG SCA spawning biomass: about 7.9 kt;
- mean HG predator demand: about 15.5 kt/yr;
- median predator-consumption analogue: about 29% against `m1_stier_11` biomass
  and about 63% against public DFO SCA biomass;
- public DFO Table 3 shows Juan Perez/Skincuttle reaches up to about 98% of
  HG spawn-index share, while Louscoone reaches 0% in the public summary.

Use those numbers only with the caveat that the DFO SCA and `m1_stier_11` do
not have identical geography or state definitions.

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

The request packet for these missing herring biological inputs is
`docs/dfo-hg-biological-input-request-packet.md`.

## Model Decision

Do not fit a Doherty-style predator-removal catch-at-age model yet.

The repo can now reproduce the public-data input layer through 2017 in
provisional form, add current public SCA/status summaries through 2024, and
compute predator-demand context. It still lacks the age-selective
predator-removal machinery and exact current machine-readable assessment inputs
needed for a defensible Doherty analogue.

The promoted baseline remains `m1_stier_11`: ambiguous zeros, two-era `q`, 11
sections, and biomass-based section states.

For AWS troubleshooting on May 16, the constrained branch is
`m5_stier_doherty_proxy_removals`. It is deliberately weaker than the full
Doherty model: audited annual HG predator mortality proxy values enter the
Stier biomass model as a scaled catch-like mortality/removal analogue, shared
across sections by latent biomass. The first registered screen uses `Mp_mid`
with `DOHERTY_PROXY_PRED_SCALE=0.05`; unscaled and 0.25-scaled `Mp_mid`
offsets were not local-smoke usable.
It does not use age composition, weight-at-age, length-at-age, predator
selectivity-at-age, or future predator scenarios. Treat any output as
proxy-removal context only until the exact HG biological inputs and selectivity
registry are complete.

AWS status: the low-vulnerability cloud smoke for this branch succeeded at the
container level on 2026-05-16, but sampler geometry was poor (E-BFMI about
0.003 with inflated process variance). Do not submit the full
`m5_stier_doherty_proxy_removals` fit until the fixed-removal formulation is
reparameterized or replaced.
