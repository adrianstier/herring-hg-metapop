# Doherty-Style HG Source Provenance

Created: 2026-05-15

## Purpose

This is the canonical source map for the Doherty-style Haida Gwaii herring and
predator data workflow. It covers public DFO assessment sources, local processed
herring files, sibling predator-repo products, and unresolved request items.

The promoted model baseline remains `m1_stier_11`: ambiguous zeros, two-era
`q`, 11 fitted sections, and biomass-based section states. The sources below
support data acquisition and model-readiness checks. They do not authorize a
new catch-at-age or predator-removal model branch until the model gates are
cleared.

## Provenance Rule

Every extracted or derived table used in this workflow must retain enough
provenance to recover the original source and extraction decision:

- `source_document`
- `source_table` or source section/figure when no table exists
- `source_url` or local catalog path
- `extraction_method`
- `extraction_notes`
- `source_id` when the table is part of a multi-source registry

If a source is local/private rather than public, the documentation must name the
local path, upstream repository/catalog, owner or data custodian, and model-use
status. Missing machine-readable data should be recorded as missing, not treated
as evidence that the biological stream does not exist.

## Canonical Registries

- `Output/diagnostics/doherty_hg_source_registry.csv` is the generated source
  registry for the Doherty HG readiness workflow.
- `Output/diagnostics/dfo_assessment_public_source_registry.csv` records the
  public DFO source fetch inventory.
- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_public_extract_audit.csv`
  audits the CSAS 2018/028 Appendix B extraction.
- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_status.csv`
  audits the newer public PDF extraction.
- `Output/diagnostics/doherty_public_extract_qc.csv` checks public extract row
  counts, year ranges, and source-field completeness.
- `Output/diagnostics/hg_dfo_sca_external_comparison_timeseries.csv` is the
  talk-facing external comparison among `m1_stier_11`, public DFO HG SCA
  summaries, and predator demand.
- `Output/diagnostics/doherty_proxy_parameter_plan.csv` is the talk-cycle proxy
  ledger separating HG public biological extracts, sibling predator products,
  WCVI/Doherty analogues, and unresolved acquisition items.
- `docs/doherty-style-hg-gap-table.md` is the concise talk/manuscript gap table
  for what is present, provisional, missing, and proxy-only relative to a full
  Doherty-style HG replication.
- `docs/predator-repo-integration-guide.md` is the operational crosswalk from
  the local predator source repo at `/Users/adrianstier/pacific-herring-predators`
  to this herring repo's imported predator covariates, diagnostics, and figures.
- `docs/dfo-hg-biological-input-request-packet.md` is the tracked request
  packet for exact machine-readable DFO HG biological inputs and metadata.
- `../pacific-herring-predators/docs/data_catalog.csv`,
  `../pacific-herring-predators/docs/data_catalog_HG_only.csv`, and
  `../pacific-herring-predators/docs/predator-coverage-matrix.csv` are the
  upstream predator source catalogs.

## Source Map

| Data stream | Source and URL/path | Local script/product | Current model-use status |
|---|---|---|---|
| Public assessment entry point | DFO Pacific herring stock assessment landing page: <https://www.pac.dfo-mpo.gc.ca/science/species-especes/herring-hareng/stock-assessments-evaluations-stocks-eng.html> | `Code/07bk_doherty_hg_data_readiness.R`; `Output/diagnostics/doherty_hg_source_registry.csv` | Source discovery and provenance. Confirms biological sampling, spawn surveys, assessment regions, model history, and public spawn-index links. |
| Public spawn-index source | DFO Pacific herring spawn-index open data: <https://open.canada.ca/data/en/dataset/d892511c-d851-4f85-a0ec-708bc05d2810>, linked from the assessment landing page. Local files: `Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv`, `Data/raw/dfo-spawn/HG_spawn_index_by_section_1951_2025.csv`, `Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv` | Existing processed inputs used by `m1_stier_11`; audited by `Code/07bk_doherty_hg_data_readiness.R` | Model-ready for the biomass model, with zero/no-survey ambiguity preserved. Do not transfer Stier SHI-scale `q` values onto this tonnes-scale product. |
| HG catch removals | Local DFO catch products: `Data/processed/herring_catch_local_1950_2024.csv`; provenance pointer `Data/raw/dfo-catch/README_catch_data.txt` | Existing processed inputs used by `m1_stier_11`; audited by `Code/07bk_doherty_hg_data_readiness.R` | Usable for biomass-model removals. Not a complete SCA catch-at-age input bundle. |
| CSAS 2018 public assessment | DFO CSAS Research Document 2018/028 page: <https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ResDocs-DocRech/2018/2018_028-eng.html>; PDF: <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40944670.pdf> | `Code/02d_fetch_dfo_herring_assessment_sources.R`; `Code/02e_extract_dfo_hg_assessment_tables.R`; `Output/diagnostics/dfo_hg_public_extract/` | Provisional public extraction for schema audit and source spot checks. Not final model input. |
| HG catch by gear, 1951-2017 | CSAS 2018/028 Appendix B Table B.1 | `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b1_catch_wide.csv`; `dfo_hg_appendix_b1_catch_long.csv` | Provisional public extraction. Contains source fields. |
| HG aggregate spawn, 1951-2017 | CSAS 2018/028 Appendix B Table B.8 | `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b8_spawn.csv` | Provisional public extraction of raw, not-q-scaled spawn input. Public aggregate cross-check, not replacement for maintained spawn-index input; shared with the adult-spawn observation stream behind `m1_stier_11`, so not an independent response. |
| HG number-at-age, 1951-2017 | CSAS 2018/028 Appendix B Table B.15 | `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b15_number_at_age_wide.csv`; `dfo_hg_appendix_b15_number_at_age_long.csv` | Provisional public extraction of assessment input data derived from biological samples. Supports schema design and age-composition screens only until current machine-readable inputs and sample-size metadata are obtained. |
| HG weight-at-age, 1951-2017 | CSAS 2018/028 Appendix B Table B.22 | `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b22_weight_at_age_wide.csv`; `dfo_hg_appendix_b22_weight_at_age_long.csv` | Provisional public extraction. Supports schema design only. |
| HG biosample counts | CSAS 2018/028 Appendix B Table B.29 | `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b29_biosamples_all_sar.csv`; `dfo_hg_appendix_b29_biosamples_hg.csv` | Provisional public extraction. Does not replace effective sample sizes for age-composition likelihoods. |
| Maturity-at-age schedule | CSAS 2018/028 Section 2.1.4 assumed biological parameters | `Output/diagnostics/dfo_hg_public_extract/dfo_hg_maturity_schedule.csv` | Encoded public provisional input. Needs current DFO input confirmation before model use. |
| Current public status and SCA summaries | DFO CSAS Science Response 2025/005 page: <https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ScR-RS/2025/2025_005-eng.html>; PDF: <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf> | `Code/02f_extract_newer_dfo_public_pdfs.R`; `Output/diagnostics/dfo_newer_public_pdf_extract/` | Public summary and request-scoping source through 2024. Not raw SCA/SISCAH input. |
| SCA input data windows | DFO 2025/005 Table 1 | `dfo_sr_2025_005_table_1_input_data_windows.csv` | Confirms catch, spawn, age composition, and weight-at-age coverage windows through 2024. Does not contain raw input values. |
| Major SAR catch, 2015-2024 | DFO 2025/005 Table 2 | `dfo_sr_2025_005_table_2_major_catch_2015_2024.csv` | Public summary. Use for reporting/request scoping only. |
| HG spawn and sub-stock proportions, 2015-2024 | DFO 2025/005 Table 3 | `dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv` | Public summary. Use for reporting/request scoping only. |
| HG SCA key parameters | DFO 2025/005 Table 7 | `dfo_sr_2025_005_table_7_hg_key_parameters.csv` | Public summary. Use as DFO assessment context, not a model input. |
| HG age-2 recruitment, 2015-2024 | DFO 2025/005 Table 11 | `dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv` | Public SCA model-output summary. Use as assessment context only because recruitment is estimated from the catch-age model fitted to catch, spawn, age composition, and weight-at-age. |
| HG spawning biomass/depletion, 2015-2024 | DFO 2025/005 Table 15 | `dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv` | Public DFO assessment output. Use as external comparison only. |
| HG reference points and 2025 projection | DFO 2025/005 Table 19 | `dfo_sr_2025_005_table_19_hg_reference_points.csv` | Public DFO assessment output. Use as external comparison only. |
| 2024/2025 IFMP projected biomass and broad age proportions | 2024/2025 Pacific Herring IFMP PDF: <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf>, Appendix 3 Table 3.1 | `dfo_ifmp_2024_2025_table_3_1_projected_biomass_age_props.csv` | Public status summary. Not raw age-composition input. |
| 2025/2026 IFMP catalogue | Government Publications catalogue: <https://publications.gc.ca/site/eng/9.958396/publication.html>; direct PDF path: <https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs143-3-23-2600-eng.pdf> | `Code/02d_fetch_dfo_herring_assessment_sources.R`; `Code/02f_extract_newer_dfo_public_pdfs.R` | Catalogue confirms the public PDF. Command-line direct PDF fetch currently returns archive HTML, so record as access-blocked, not absent. |
| HG rebuilding-plan biological figures/captions | Haida Gwaii Pacific Herring Rebuilding Plan PDF: <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf> | `dfo_hg_rebuilding_plan_biology_caption_catalog.csv` | Caption/provenance audit. Confirms age/length/weight figure context and imputation rules but no machine-readable annual length-at-age table. |
| DFO input manifest | `Data/raw/dfo-spawn/input-data.csv` | Audited by `Code/07bk_doherty_hg_data_readiness.R` | Manifest only. Names biological streams; not actual raw matrices. |
| Local biological-sample placeholders | `Data/raw/HG_biological_samples.csv`; `Data/raw/HG_biological_samples_v2.csv` | `Output/diagnostics/doherty_hg_local_file_audit.csv` | Not model-ready. First file is a catch summary without usable age/length/weight columns; second is empty. |
| SISCAH/SCA method reference | DFO CSAS SAR 2023/040: <https://www.dfo-mpo.gc.ca/csas-sccs/Publications/SAR-AS/2023/2023_040-eng.html> | `Code/07bk_doherty_hg_data_readiness.R` source registry row | Method reference only. Does not provide raw HG input matrices. |
| Fish ageing/sample data custodian | DFO Pacific Fish Ageing Lab: <https://www.pac.dfo-mpo.gc.ca/science/species-especes/agelab-scalimetrie/index-eng.html> | `Output/diagnostics/doherty_hg_dfo_data_request_template.md` | Data-request lead for ageing, length, weight, and sample metadata. |
| Doherty WCVI model analogue | Doherty et al. 2025, ICES Journal of Marine Science, fsae183: <https://doi.org/10.1093/icesjms/fsae183> | `docs/wcvi-predation-replication-bridge.md`; `Code/07bj_wcvi_predation_replication_bridge.R` | Model-structure and selectivity reference. Do not copy WCVI parameters directly to HG. |
| Annual HG predator demand and pressure | Sibling repo `../pacific-herring-predators`; local products `Data/processed/predators/hg_predation_pressure_covariates.csv`, `hg_predator_consumption_by_group_year.csv`, `hg_predator_consumption_by_species_recent.csv` | `Code/02c_integrate_hg_predator_repo_products.R`; `Code/07bj_wcvi_predation_replication_bridge.R` | Usable for biomass-scale predator-demand context and completed held single-covariate screens. Not age-selective predation mortality. |
| Predator repo integration crosswalk | Local checkout `/Users/adrianstier/pacific-herring-predators`; GitHub `stier-lab/pacific-herring-predators` | `docs/predator-repo-integration-guide.md`; `CLAUDE.md`; `AGENTS.md` | Operational handoff. Use this before looking for predator data or visualizations. |
| Predator spatial sites/exposure prototype | Sibling repo catalogs plus local `Data/processed/predators/hg_spatial_predator_sites.csv` | `Code/07bb_predator_spatial_exposure_prototype.R`; `Output/diagnostics/predator_spatial_exposure_prototype.md` | Data-product roadmap. Seal and sea-lion exposure is feasible; humpback/fish/bird section exposure and interpolation rules remain incomplete. |
| Predator age/size selectivity | Doherty supplement, HG diet literature, and predator-repo future selectivity table | Not found locally as a machine-readable table | Blocks Doherty-style predation mortality fitting. Must be extracted into a sourced table before any predator-removal branch. |
| Future predator scenarios | Future predator abundance/scenario source not found locally | Not implemented | Blocks Doherty-style projection work. |
| Public extract QC | All public DFO extracts listed above | `Code/07bm_doherty_public_extract_qc.R`; `Output/diagnostics/doherty_public_extract_qc.md` | Structural/source QC only. Passing QC means traceable and internally consistent, not model-ready. |
| DFO SCA external comparison | `m1_stier_11` diagnostics, DFO 2025/005 Tables 3 and 15, and HG predator demand | `Code/07bn_hg_dfo_sca_external_comparison.R`; `Output/diagnostics/hg_dfo_sca_external_comparison.md`; `Output/figures/hg_dfo_sca_external_comparison.pdf` | Talk-facing scale context. Do not treat as a likelihood comparison or direct validation residual. |
| Doherty proxy parameter plan | HG public DFO extracts, DFO public summaries, sibling predator-repo products, and Doherty/WCVI model-structure analogues | `Code/07bo_doherty_proxy_parameter_plan.R`; `Output/diagnostics/doherty_proxy_parameter_plan.md`; `Output/figures/doherty_proxy_parameter_plan.pdf` | Talk-facing proxy ledger. HG public sources anchor herring biology where available; WCVI/Doherty values are provisional analogues only and must not be described as HG-estimated catch-at-age, size-at-age, or selectivity parameters. |
| DFO biological input request | Public source evidence and missing input ledger | `docs/dfo-hg-biological-input-request-packet.md` | Acquisition packet for exact HG SCA/SISCAH age, weight, length, catch, maturity, and metadata files. |

## Documentation Touch Points

These tracked documents should link back here whenever they discuss Doherty-style
data acquisition or predator integration:

- `docs/doherty-style-hg-data-acquisition.md`
- `docs/doherty-style-hg-replication-status.md`
- `docs/dfo-hg-biological-input-request-packet.md`
- `docs/wcvi-predation-replication-bridge.md`
- `docs/predator-data-plan.md`
- `docs/predator-repo-integration-guide.md`
- `docs/data-dictionary.md`
- `docs/current-analysis-quickstart.md`
- `docs/collaborator-reading-guide.md`
- `docs/saturday-talk-readiness-2026-05-16.md`
- `AGENTS.md`
- `CLAUDE.md`
- `SESSION_LOG_20260515.md`
- `SESSION_LOG_20260516.md`

When a new public PDF, DFO request result, predator source, or local data
product is added, update this file and regenerate
`Output/diagnostics/doherty_hg_source_registry.csv` with
`Code/07bk_doherty_hg_data_readiness.R`.
