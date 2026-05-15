# Doherty-Style HG Replication Status

Updated: 2026-05-15

## What Is Now Executed

The public-data replication path has moved from planning to provisional
extraction.

Run order:

```sh
Rscript --vanilla Code/02d_fetch_dfo_herring_assessment_sources.R
Rscript --vanilla Code/02e_extract_dfo_hg_assessment_tables.R
Rscript --vanilla Code/07bk_doherty_hg_data_readiness.R
Rscript --vanilla Code/07bl_doherty_replication_execution_status.R
Rscript --vanilla Code/07bi_model_decision_ledger.R
```

Current generated outputs are under ignored diagnostics directories:

- `Output/diagnostics/dfo_assessment_public_sources/`
- `Output/diagnostics/dfo_hg_public_extract/`
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

- current 2018-2024 HG age/weight biological input tables;
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
provisional form and can compute predator-demand context. It still lacks the
age-selective predator-removal machinery and current machine-readable
assessment inputs needed for a defensible Doherty analogue.

The promoted baseline remains `m1_stier_11`: ambiguous zeros, two-era `q`, 11
sections, and biomass-based section states.
