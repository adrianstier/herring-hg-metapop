# Session Log 2026-05-15

## AWS refresh

- Refreshed AWS state with profile `herring`; `sts get-caller-identity`
  resolves to account `107094296950`.
- AWS Batch queues in `us-east-1` are valid/enabled:
  `herring-hg-metapop-ondemand` and `herring-hg-metapop-spot`.
- Direct Batch polling at 2026-05-15 06:19 local confirmed:
  - `m5_stier_predator_demand_total`: `SUCCEEDED`;
  - `m1_stier_11`, `m2_stier_site_growth`, `m3_stier_distance`, and
    `m5_stier_predation_pressure`: `SUCCEEDED`;
  - `m1_stier_method_sensitivity`, `m5_v5`, `m5_combined`,
    `smoke_cloud_pipeline`, and `smoke_m5_stier_predation_pressure_reduced`:
    `SUCCEEDED`;
  - `m3_stier_distance_reloo`: `FAILED`, matching the known incomplete cloud
    array state. Local exact re-LOO remains the source for that branch.
- No new AWS job was submitted. The decision ledger still supports holding
  predator branches and avoiding `m5_combined` exact re-LOO or combination-model
  spending.

## Doherty-style HG data acquisition

- Implemented `Code/07bk_doherty_hg_data_readiness.R` to audit whether the
  Haida Gwaii workspace can support a Doherty-style herring/predator assessment
  analogue.
- Implemented `Code/02d_fetch_dfo_herring_assessment_sources.R` to fetch public
  DFO herring PDFs and extract text into ignored diagnostics space before table
  extraction.
- Added `docs/doherty-style-hg-data-acquisition.md` as the source-backed
  acquisition plan.
- The important correction from the DFO stock-assessment page is that the
  herring biological streams are public/assessment-backed, not hypothetical:
  the public path is to extract DFO assessment appendices first, then request
  exact machine-readable SCA/SISCAH input files and metadata if extraction is
  incomplete.
- The readiness script writes:
  - `Output/diagnostics/doherty_hg_data_readiness.md`;
  - `Output/diagnostics/doherty_hg_data_readiness.csv`;
  - `Output/diagnostics/doherty_hg_source_registry.csv`;
  - `Output/diagnostics/doherty_hg_schema_templates.csv`;
  - `Output/diagnostics/doherty_hg_local_file_audit.csv`;
  - `Output/diagnostics/doherty_hg_dfo_data_request_template.md`;
  - `Output/figures/doherty_hg_data_readiness.pdf`.
- The public-source fetch script writes:
  - `Output/diagnostics/dfo_assessment_public_source_registry.csv`;
  - `Output/diagnostics/dfo_assessment_public_source_inventory.md`;
  - ignored downloaded PDF/text files under
    `Output/diagnostics/dfo_assessment_public_sources/`.
- Implemented `Code/02e_extract_dfo_hg_assessment_tables.R` and
  `Code/07bl_doherty_replication_execution_status.R` to execute the first
  public-data replication layer.
- Public DFO CSAS 2018/028 Appendix B extraction now produces provisional HG:
  catch rows (`67` wide / `201` gear-long), spawn rows (`67`),
  number-at-age rows (`72` source-year / `648` age-long), weight-at-age rows
  (`67` year / `603` age-long), biosample rows (`63`), and maturity rows
  (`9`).
- Added DFO CSAS Science Response 2025/005 to the public-source fetch registry
  and implemented `Code/02f_extract_newer_dfo_public_pdfs.R`.
- Newer public PDF extraction now mines DFO 2025/005, the 2024/2025 IFMP, and
  the Haida Gwaii rebuilding plan. Clean extracts include DFO 2025/005 input
  data windows (`12` rows), major SAR catch (`10`), HG spawn/sub-stock
  proportions (`10`), HG SCA key parameters (`11`), HG age-2 recruitment
  (`10`), HG biomass/depletion (`10`), HG reference points (`13`), 2024/2025
  IFMP projected biomass/age proportions (`4`), and rebuilding-plan biological
  captions (`92`).
- The 2025/2026 full IFMP catalogue confirms a PDF, but command-line direct
  access still returns an HTML archive page; record this as an access block,
  not a biological-data absence.
- Added `docs/doherty-style-hg-replication-status.md` as the tracked status
  note for what has been found versus what remains missing.
- Added `docs/doherty-style-hg-source-provenance.md` as the canonical source
  map for public DFO sources, local herring inputs, sibling predator-repo
  products, generated registries, and unresolved request items. The rule going
  forward is that every extracted table retains source document/table/URL,
  extraction method, and extraction notes; local/private sources must retain
  local path, upstream catalog, owner/custodian, and model-use status.
- Remaining missing/not machine-readable locally: exact annual 2018-2024
  age/weight matrices, exact SCA/SISCAH input files, effective sample-size/
  preprocessing metadata, length-at-age tables, predator age/size selectivity,
  future predator scenarios, and a regional HG catch-at-age design separate
  from the 11-section Stier biomass model.
- Model implication: do not fit a full 11-section catch-at-age model or another
  predator-removal Stan branch now. First acquire/extract HG age composition,
  weight-at-age, length-at-age, maturity, test-fishery biology, and predator
  age/size selectivity assumptions.
- Verification rerun completed for:
  `Code/02d_fetch_dfo_herring_assessment_sources.R`,
  `Code/02e_extract_dfo_hg_assessment_tables.R`,
  `Code/02f_extract_newer_dfo_public_pdfs.R`,
  `Code/07bk_doherty_hg_data_readiness.R`,
  `Code/07bl_doherty_replication_execution_status.R`,
  `Code/07bi_model_decision_ledger.R`, and
  `Code/09_check_document_references.R`; document references reported zero
  missing references and `git diff --check` was clean.

## Overnight talk-readiness follow-up

- Added `Code/07bm_doherty_public_extract_qc.R`, which checks public DFO
  extracts for expected row counts, year ranges, and complete source fields.
  Current result: all 15 tracked products pass structural QC. This is a
  traceability check only; it does not promote any table to catch-at-age model
  input status.
- Added `Code/07bn_hg_dfo_sca_external_comparison.R`, which builds the
  talk-facing comparison among `m1_stier_11`, public DFO HG SCA summaries from
  DFO 2025/005, and HG predator demand.
- New comparison outputs:
  `Output/diagnostics/hg_dfo_sca_external_comparison.md`,
  `Output/diagnostics/hg_dfo_sca_external_comparison_timeseries.csv`,
  `Output/diagnostics/hg_dfo_sca_external_comparison_summary.csv`, and
  `Output/figures/hg_dfo_sca_external_comparison.pdf`.
- Current 2015-2024 external-context read: mean `m1_stier_11` all-11 biomass is
  about 46.7 kt, mean public DFO HG SCA spawning biomass is about 7.9 kt, mean
  HG predator demand is about 15.5 kt/yr, and the median predator-consumption
  analogue is about 29% against `m1_stier_11` biomass or about 63% against the
  public DFO SCA spawning biomass. Use these only as scale/geography context.
- Added `docs/dfo-hg-biological-input-request-packet.md` as the tracked DFO
  request packet for exact machine-readable HG age, weight, length, catch,
  maturity, and SCA/SISCAH metadata.

## Current scientific status

- `m1_stier_11` remains the promoted baseline.
- `m5_stier_predator_demand_total` and `m5_stier_predation_pressure` remain
  held context: sampler-usable, no material calibration gain.
- `m5_v5` and `m5_combined` remain archived/excluded despite successful cloud
  completion.
- `m3_stier_distance` remains held; use local exact re-LOO, not the failed
  cloud array, for interpretation.
- Keep zeros ambiguous, two-era `q`, 11 fitted sections, and Stier-style
  reporting sensitivities.
