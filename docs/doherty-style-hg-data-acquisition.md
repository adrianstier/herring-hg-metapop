# Doherty-Style HG Data Acquisition Plan

Created: 2026-05-15

## Purpose

This note turns the WCVI Doherty-style predator-removal idea into a concrete
Haida Gwaii data acquisition workflow. It is deliberately a data-readiness plan,
not approval to fit a new age-structured model. The promoted modeling baseline
remains `m1_stier_11`: ambiguous zeros, two-era `q`, 11 fitted sections, and no
age/size state dimension.

## Current Read

The DFO Pacific herring stock-assessment page is the correct public entry point.
It confirms:

- biological sampling surveys collect pre-spawning samples and track herring age
  and growth;
- spawn surveys measure egg deposition and support the spawn index;
- Haida Gwaii and Area 2 West include DFO herring sections 001-006, 011-012,
  and 021-025;
- major-area assessment advice now comes from integrated statistical catch-age
  models;
- open spawn-index data are publicly linked.

The public DFO assessment reports and appendices go further. They document that
Pacific herring stock assessments use commercial catch, spawn survey indices,
age composition, and weight-at-age. They also publish or summarize Haida Gwaii
biological streams such as number/proportion-at-age, number aged, weight-at-age,
length-at-age, and test-fishery/commercial seine biology. Therefore the next
step is public extraction first, followed by a narrow DFO request for exact
machine-readable inputs and metadata if the PDFs cannot be extracted cleanly.

## Execution Update

As of 2026-05-15, the first public extraction pass is implemented:

- `Code/02d_fetch_dfo_herring_assessment_sources.R` fetches and text-extracts
  public DFO assessment sources into ignored diagnostics space.
- `Code/02e_extract_dfo_hg_assessment_tables.R` extracts provisional HG
  Appendix B catch, spawn, number-at-age, weight-at-age, biosample count, and
  maturity tables from DFO CSAS Research Document 2018/028.
- `Code/07bl_doherty_replication_execution_status.R` writes the replication
  status, predator crosswalk, and model-gate ledger.
- `docs/doherty-style-hg-replication-status.md` is the tracked status note.

The extracted public tables cover 1951-2017. Current 2018-2024 machine-readable
biology, effective sample-size metadata, length-at-age tables, and predator
age/size selectivity remain unresolved.

## Acquisition Order

1. Public DFO landing page and open data:
   - download or refresh the spawn-index open-data package and metadata;
   - retain the DFO section map crosswalk for HG/A2W sections;
   - cross-check local `spawn_index_tonnes` products against the public package.

2. Public assessment appendices:
   - extract HG catch, spawn, number-at-age, proportion-at-age, weight-at-age,
     number-aged/sample-size, and maturity schedule tables from DFO assessment
     documents;
   - keep source document, page/table number, extraction method, units, and
     plus-group conventions in every extracted table;
   - distinguish public plotted/summarized sub-stock products from exact model
     input tables.

3. Public Haida Gwaii rebuilding plan:
   - extract sub-stock age/length/weight summaries where available for
     Cumshewa/Selwyn, Juan Perez/Skincuttle, Louscoone, Masset, Naden,
     Skidegate, and A2W;
   - use these as regional/sub-stock covariates or cross-checks, not as a new
     11-section age-structured state model.

4. DFO targeted request:
   - request exact HG SCA/SISCAH input CSV/RDS files if public extraction cannot
     recover model-ready tables;
   - request effective sample sizes, fishery/source labels, length/weight/age
     preprocessing rules, plus-group treatment, ageing lab metadata, and privacy
     suppression rules;
   - ask for machine-readable copies of already-published inputs, not for a new
     custom analysis.

5. Predator integration:
   - keep the sibling predator repo as the source of truth for predator
     abundance, consumption, and spatial exposure products;
   - map Doherty predator classes to HG classes with explicit flags:
     `direct_HG`, `BC_allocated_to_HG`, `literature_scaled`, or `gap`;
   - encode predator age/size selectivity only after the herring age/weight
     tables are locally extractable and audited.

## Model Gates

Do not launch another predator or catch-at-age Stan branch until the readiness
registry marks these products at least extractable and internally checked:

- HG age composition by year/source/age;
- HG weight-at-age by year/age;
- catch by year/fleet/source with units aligned to the assessment;
- maturity schedule with source citation;
- predator class mapping and age/size selectivity assumptions.

Even after those are ready, the first model use should be a regional covariate
or external cross-check against `m1_stier_11`, not a full 11-section
age-structured metapopulation model.

## Implemented Control Sheet

Run:

```sh
Rscript Code/07bk_doherty_hg_data_readiness.R
```

Outputs:

- `Output/diagnostics/doherty_hg_data_readiness.md`
- `Output/diagnostics/doherty_hg_data_readiness.csv`
- `Output/diagnostics/doherty_hg_source_registry.csv`
- `Output/diagnostics/doherty_hg_schema_templates.csv`
- `Output/diagnostics/doherty_hg_local_file_audit.csv`
- `Output/diagnostics/doherty_hg_dfo_data_request_template.md`
- `Output/figures/doherty_hg_data_readiness.pdf`

## Primary Public Sources

- DFO Pacific herring stock assessment landing page:
  <https://www.pac.dfo-mpo.gc.ca/science/species-especes/herring-hareng/stock-assessments-evaluations-stocks-eng.html>
- DFO Pacific herring IFMP summary:
  <https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/herring-hareng-ifmp-pgip-sm-eng.html>
- DFO Pacific herring 2025/2026 full IFMP catalogue record:
  <https://publications.gc.ca/site/eng/9.958396/publication.html>
- DFO Pacific herring 2025/2026 full IFMP direct PDF:
  <https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs143-3-23-2600-eng.pdf>
- DFO CSAS Research Document 2018/028:
  <https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ResDocs-DocRech/2018/2018_028-eng.html>
- Haida Gwaii Pacific Herring Rebuilding Plan:
  <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf>
