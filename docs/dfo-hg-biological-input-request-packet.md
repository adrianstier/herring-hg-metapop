# DFO HG Biological Input Request Packet

Created: 2026-05-15

## Purpose

This packet turns the Doherty-style HG data gap ledger into a concrete request
for machine-readable Haida Gwaii Pacific Herring assessment inputs. The request
is for copies and metadata for already-published or assessment-used data
streams, not for a new DFO analysis.

The modeling baseline remains `m1_stier_11`: ambiguous zeros, two-era `q`, 11
fitted sections, and biomass-based section states. These inputs are needed
before any defensible Doherty-style catch-at-age predator-removal analogue can
be fit.

## Recipient Targets

- DFO Pacific herring stock assessment team.
- DFO Pacific Biological Station / Fish Ageing Lab for ageing, length, weight,
  and biological-sample metadata.

## Public Source Evidence

| Source | URL / path | What it establishes |
|---|---|---|
| DFO Pacific herring stock assessment page | <https://www.pac.dfo-mpo.gc.ca/science/species-especes/herring-hareng/stock-assessments-evaluations-stocks-eng.html> | Biological sampling surveys collect pre-spawning age/growth data; spawn surveys support the spawn index; current advice uses integrated statistical catch-age models. |
| DFO spawn-index open data | <https://open.canada.ca/data/en/dataset/d892511c-d851-4f85-a0ec-708bc05d2810> | Public maintained spawn-index data source; local tonnes-scale product is already used in the Stier-aligned biomass model. |
| DFO CSAS Research Document 2018/028 | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40944670.pdf> | Appendix B publishes HG catch, spawn, number-at-age, weight-at-age, biosample counts, and maturity schedule through 2017. |
| DFO CSAS Science Response 2025/005 | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf> | Table 1 confirms current major-stock SCA input windows through 2024 for catch, spawn index, age composition, and weight-at-age. Tables 3 and 15 provide public HG spawn and biomass/depletion summaries. |
| 2024/2025 Pacific Herring IFMP | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf> | Public IFMP Appendix 3 context and broad projected biomass/age-proportion summaries. |
| 2025/2026 Pacific Herring IFMP catalogue | <https://publications.gc.ca/site/eng/9.958396/publication.html> | Catalogue confirms the current full IFMP; command-line direct PDF access is blocked by archive HTML in this environment. |
| HG Pacific Herring Rebuilding Plan | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf> | Confirms sub-stock biological figure context, length/weight/proportion-at-age summaries, and imputation rules, but not machine-readable annual length-at-age tables. |

## Local Evidence Already Extracted

| Product | Local output | Status |
|---|---|---|
| Public source inventory | `Output/diagnostics/dfo_assessment_public_source_registry.csv` | Source registry and fetch/text-extraction status. |
| CSAS 2018/028 Appendix B extract | `Output/diagnostics/dfo_hg_public_extract/` | Provisional public extraction through 2017; schema/source audit only. |
| Newer public PDF extract | `Output/diagnostics/dfo_newer_public_pdf_extract/` | Current public summaries through 2024; reporting/request scoping only. |
| Public extract QC | `Output/diagnostics/doherty_public_extract_qc.md` | All 15 tracked public products pass structural/source-field QC. |
| Data readiness registry | `Output/diagnostics/doherty_hg_data_readiness.md` | Readiness status, source registry, schema templates, and missing-data ledger. |
| External DFO SCA comparison | `Output/diagnostics/hg_dfo_sca_external_comparison.md` | Talk-facing scale context among `m1_stier_11`, DFO HG SCA summaries, and predator demand. |

## Specific Data Request

Please share, or point us to the public repository/input archive for, the exact
Haida Gwaii Pacific Herring SCA/SISCAH input data used in recent assessments:

1. Annual number-at-age or proportion-at-age by sample source/fleet.
   - Include roe seine, roe gillnet, test fishery, other fisheries, and any
     source/fishery labels used in the model input files.
   - Include raw sample sizes and effective sample sizes used in the
     age-composition likelihood.

2. Annual weight-at-age matrices.
   - Include stock assessment region, source/fleet where relevant, sample size,
     units, plus-group convention, and imputation/preprocessing flags.

3. Length-at-age or biological sample summaries tied to ageing records.
   - Include year, source/fleet, length units, sample size, and any privacy or
     suppression rules.

4. Fleet/source-specific catch tables in SCA/SISCAH input form.
   - Include roe seine, roe gillnet, other fisheries, SOK/open-pond records
     where applicable, test-fishery removals if modeled, and units.

5. Maturity-at-age schedule and biological assumptions used in current HG SCA.
   - Include source citation and any deviations from the fixed maturity
     schedule published in CSAS 2018/028.

6. SCA/SISCAH model input bundle and metadata.
   - Preferred: exact CSV/RDS/input files used by recent HG assessment runs.
   - Include model year definitions, ageing method notes, plus-group treatment,
     fishery/source coding, preprocessing scripts or notes, and any effective
     sample-size adjustment rules.

7. Table-definition guidance for public appendices.
   - If public appendices are the authoritative source for any input stream,
     please confirm table definitions, units, and any transformations not
     recoverable from PDFs.

## Not Requested Yet

These are deliberately held out of the first DFO request:

- a new custom DFO analysis;
- a full HG catch-at-age model refit;
- unpublished predator selectivity assumptions not already part of assessment
  or public predator literature;
- future predator scenario construction.

Predator age/size selectivity should be handled as a separate literature and
author/supplement request after the herring biological inputs are in hand.

## Email Draft

Subject: Request for machine-readable Haida Gwaii Pacific Herring assessment inputs

Dear DFO Pacific herring assessment team,

We are compiling a transparent Haida Gwaii Pacific Herring data bundle to
evaluate a Doherty et al.-style predator-removal analogue alongside an existing
section-level biomass model. Public DFO sources already establish that the
needed streams exist in the assessment workflow: the DFO stock-assessment page
describes biological and spawn surveys, CSAS 2018/028 Appendix B publishes HG
catch/spawn/age/weight/biosample tables through 2017, and CSAS Science Response
2025/005 Table 1 confirms that current major-stock SCA inputs include catch,
spawn index, age composition, and weight-at-age through 2024.

Could you please share the machine-readable Haida Gwaii SCA/SISCAH input data,
or point us to the public repository/input archive, for the following streams:

- annual number-at-age or proportion-at-age by sample source/fleet, with raw
  and effective sample sizes;
- annual weight-at-age matrices and sample sizes;
- length-at-age or biological sample summaries tied to ageing records;
- fleet/source-specific catch tables in the same form used by SCA/SISCAH;
- maturity-at-age schedule and current biological-assumption notes;
- metadata for model year definitions, plus-group treatment, fishery/source
  coding, ageing/sample preprocessing, and effective sample-size adjustments.

Preferred format is CSV, RDS, or the exact SCA/SISCAH input files used for
recent Haida Gwaii assessments. We will retain DFO source metadata and cite data
provenance explicitly in all outputs. We are not requesting a new analysis; this
is a request for machine-readable copies and interpretation metadata for
assessment inputs already documented in public DFO sources.

Thank you,

[name]

## Use Guardrail

Even if this request is fulfilled, the first use should be a regional
cross-check or carefully scoped data product. Do not move to a full
Doherty-style predator-removal catch-at-age model until the herring inputs,
predator age/size selectivity, and model design are all reviewed and
documented.
