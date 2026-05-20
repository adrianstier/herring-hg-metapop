# Doherty-Style HG Gap Table

Created: 2026-05-17

## Purpose

This table answers how close the repository is to a Haida Gwaii analogue of the
Doherty et al. WCVI predation analysis. The short answer is: the public
source-traced input layer is now substantial, but the repo still does not have
a complete HG catch-at-age predation-mortality model. Use this as the slide and
manuscript guardrail.

## Replication Status By Component

| Component needed for a Doherty-style analysis | HG material currently in repo | Source/provenance | Status | What is still missing | Talk use |
|---|---|---|---|---|---|
| Regional assessment model structure | Promoted `m1_stier_11` biomass model plus Doherty proxy/covariate Stan troubleshooting designs. | `inst/stan/herring_metapop_m1_stier_11.stan`; `docs/stan-model-map.md`; `Output/diagnostics/model_decision_ledger.md` | Biomass model promoted; Doherty branches planning/troubleshooting only. | A separate HG regional catch-at-age predation-mortality model design. | Say "bridge/plan", not "full replication". |
| Catch removals | Section-year catch in `Data/processed/herring_catch_local_1950_2024.csv`; public major-SAR catch summaries through 2024. | `Data/raw/dfo-catch/README_catch_data.txt`; DFO 2025/005 Table 2; `docs/doherty-style-hg-source-provenance.md` | Ready for biomass removals and public context. | Full catch-at-age input bundle by fleet/source/year. | Use as removals in `m1_stier_11`; not an age-structured catch likelihood. |
| Spawn index / adult observation stream | Maintained DFO spawn-index tonnes series and public Appendix B spawn cross-check. | DFO open data; CSAS 2018/028 Appendix B Table B.8; `Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv` | Ready for biomass model; public extract provisional. | Survey-effort/access metadata sufficient to convert ambiguous zeros to absences. | Use for adult spawn/biomass context; not independent recruitment. |
| Age composition / number-at-age | Public HG Appendix B number-at-age, 1951-2017; DFO 2025/005 confirms age-composition input windows through 2024. | CSAS 2018/028 Appendix B Table B.15; DFO 2025/005 Table 1; `Output/diagnostics/dfo_hg_public_extract/` | Provisional public extraction, schema/QC only. | Exact annual 2018-2024 input matrices, sample-source labels, plus-group rules, effective sample sizes. | Audit target and data-request justification only. |
| Weight-at-age | Public HG Appendix B weight-at-age, 1951-2017; DFO 2025/005 confirms weight-at-age input windows through 2024. | CSAS 2018/028 Appendix B Table B.22; DFO 2025/005 Table 1. | Provisional public extraction, schema/QC only. | Exact annual 2018-2024 matrices and preprocessing metadata. | Cross-check/source-tracing only. |
| Length/size-at-age | Rebuilding-plan biological captions and IFMP broad age/biology context. | HG rebuilding plan; 2024/2025 IFMP Appendix 3; `Output/diagnostics/dfo_newer_public_pdf_extract/`. | Caption/provenance context. | Machine-readable annual length-at-age or size-at-age tables. | Do not call any size/selectivity input HG-estimated. |
| Maturity-at-age | Public assumed maturity schedule encoded from CSAS 2018/028 text. | CSAS 2018/028 Section 2.1.4; `dfo_hg_maturity_schedule.csv`. | Provisional public parameter. | Current DFO confirmation and exact model-use metadata. | Schema planning only. |
| Biosample counts / effective sample sizes | Appendix B biosample counts by SAR. | CSAS 2018/028 Appendix B Table B.29. | Counts extracted; useful but incomplete. | Effective sample sizes and age-composition likelihood preprocessing rules. | Explain why the age-composition likelihood is not ready. |
| DFO SCA recruitment/biomass outputs | Public 2015-2024 age-2 recruitment, biomass/depletion, reference-point, and projection summaries. | DFO 2025/005 Tables 11, 15, 19. | Public assessment output context. | Not raw input data; not independent validation. | External context only; avoid circularity. |
| Predator annual demand / mortality proxy | Audited HG predator consumption, pressure, and `Mp_mid` proxy from sibling predator repo; imported into herring diagnostics. | `/Users/adrianstier/pacific-herring-predators`; `docs/predator-repo-integration-guide.md`; `Code/02c_integrate_hg_predator_repo_products.R` | Usable for demand-scale context and completed held screens. | Age-specific natural mortality by predator class. | Show ecological scale; no promoted coefficient. |
| Predator spatial exposure | Harbour seal and Steller sea lion section-year exposure prototypes; HG-wide humpback scaffold. | `Output/diagnostics/predator_spatial_exposure_prototype.md`; `Output/diagnostics/humpback_section_exposure_proxy.md`. | Prototype only. | Section-level humpback, fish, bird, effort/interpolation, and movement rules. | Data-product roadmap. |
| Predator selectivity by age/size | Doherty/WCVI provides model-structure analogue. | Doherty et al. 2025; `docs/wcvi-predation-replication-bridge.md`. | Not available as HG model-ready input. | Sourced selectivity table by predator class and herring age/size, with HG relevance flags. | WCVI analogue only; do not transfer as HG-estimated. |
| Future predator scenarios | Sibling predator repo has some future humpback projection scaffolding. | `docs/predator-repo-integration-guide.md`. | Not integrated for HG assessment. | Scenario definitions and uncertainty propagation for all relevant predator groups. | Omit from talk except as future work. |

## What We Can Honestly Say

- We have replicated the public-data acquisition path far enough to show that
  HG catch, spawn, age-composition, weight-at-age, biosample, maturity, and
  current DFO status streams exist and are source-traceable.
- We have not replicated the full Doherty WCVI catch-at-age analysis for HG.
- The missing pieces are specific and requestable: exact machine-readable
  age/weight/length/catch input matrices, effective sample sizes, preprocessing
  rules, and predator age/size selectivity.
- Current predator model branches answer a narrower question: whether annual
  HG predator demand/pressure improves the Stier biomass model. They do not.

## Acquisition Order

1. Use `docs/dfo-hg-biological-input-request-packet.md` to request exact
   machine-readable DFO HG input files and metadata.
2. Extract a sourced predator selectivity table from Doherty supplements and
   HG predator diet literature, with WCVI/HG transfer flags.
3. Build a regional HG catch-at-age input bundle separate from the 11-section
   biomass model.
4. Only after those three are audited, design a true Doherty-style HG model.

## Source Controls

- `docs/doherty-style-hg-source-provenance.md`
- `docs/doherty-style-hg-replication-status.md`
- `docs/doherty-style-hg-data-acquisition.md`
- `Output/diagnostics/doherty_hg_data_readiness.md`
- `Output/diagnostics/doherty_public_extract_qc.md`
- `Output/diagnostics/doherty_proxy_parameter_plan.md`
