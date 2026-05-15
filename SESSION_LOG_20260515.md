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
- Model implication: do not fit a full 11-section catch-at-age model or another
  predator-removal Stan branch now. First acquire/extract HG age composition,
  weight-at-age, length-at-age, maturity, test-fishery biology, and predator
  age/size selectivity assumptions.

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
