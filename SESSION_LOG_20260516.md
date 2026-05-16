# Session Log 2026-05-16

## Doherty proxy plan for Saturday talk

- Added `Code/07bo_doherty_proxy_parameter_plan.R` to generate the explicit
  proxy ledger for the Doherty-style HG bridge.
- The proxy rule is now documented in `README.md`, `AGENTS.md`,
  `docs/doherty-style-hg-replication-status.md`,
  `docs/doherty-style-hg-source-provenance.md`,
  `docs/doherty-style-hg-data-acquisition.md`, and
  `docs/saturday-talk-readiness-2026-05-16.md`.
- Talk-cycle policy:
  - HG public DFO sources anchor herring biology where available, including
    catch context, number/age composition, weight-at-age, maturity, and current
    public SCA summaries.
  - WCVI/Doherty values are provisional analogues only for missing
    length/size/selectivity or model-structure pieces.
  - WCVI catch-at-age, size-at-age, or predator-selectivity values must not be
    described as Haida Gwaii-estimated parameters.
  - The current output is a source-traceable bridge and acquisition plan, not a
    completed HG catch-at-age predator-removal model.
- New generated outputs:
  - `Output/diagnostics/doherty_proxy_parameter_plan.md`
  - `Output/diagnostics/doherty_proxy_parameter_plan.csv`
  - `Output/figures/doherty_proxy_parameter_plan.pdf`
  - `Output/figures/doherty_proxy_parameter_plan.png`
- The post-talk acquisition path remains:
  1. request exact machine-readable HG SCA/SISCAH catch, age, weight, length,
     maturity, and metadata inputs from DFO;
  2. convert public 1951-2017 HG age/weight extracts into a provisional
     regional catch-at-age bundle with explicit source/fleet, plus-group, and
     effective-sample-size flags;
  3. extract Doherty/WCVI predator selectivity assumptions into a sourced
     transferability registry;
  4. join exact HG biological inputs to versioned predator-repo demand/exposure
     products only after source and metadata QC;
  5. smoke-test a separate regional HG catch-at-age scaffold before considering
     any integration with the 11-section `m1_stier_11` biomass model.

## Predator repo integration handoff

- Added `docs/predator-repo-integration-guide.md` as the operational crosswalk
  between this herring modeling repo and the local predator source repo at
  `/Users/adrianstier/pacific-herring-predators`.
- Added `CLAUDE.md` so non-Codex/Claude agents have the same durable handoff:
  predator synthesis, source catalogs, audited demand/pressure products, and
  predator-only figures live in the sibling predator repo; this repo imports
  them for model covariates and integrated diagnostics.
- Updated `AGENTS.md`, `README.md`, `docs/predator-data-plan.md`,
  `docs/doherty-style-hg-source-provenance.md`,
  `docs/doherty-style-hg-data-acquisition.md`,
  `docs/full-analysis-model-farm-scope.md`,
  `docs/saturday-talk-readiness-2026-05-16.md`, and
  `docs/current-analysis-quickstart.md` to point to the integration guide.
- Updated `Code/02c_integrate_hg_predator_repo_products.R` to explicitly check
  `/Users/adrianstier/pacific-herring-predators` and to write the integration
  guide/Claude handoff into its diagnostic report.
- Updated `Code/09_check_document_references.R` so `CLAUDE.md` is scanned and
  `CLAUDE.md` references are checked like `AGENTS.md` and `README.md`.
- Operational import command:
  `PREDATOR_REPO_PATH=/Users/adrianstier/pacific-herring-predators Rscript --vanilla Code/02c_integrate_hg_predator_repo_products.R`.
- The next workstream after this wiring is to return to the HG Doherty-style
  regional model/AWS loop, using the predator repo products for demand,
  pressure, and spatial-site inputs while keeping WCVI selectivity and missing
  HG catch-at-age inputs explicitly labelled as proxies or blockers.

## HG Doherty proxy-removal AWS branch

- Added `inst/stan/herring_metapop_m5_stier_doherty_proxy_removals.stan` and
  `Code/03_fit_m5_stier_doherty_proxy_removals.R`.
- Scientific scope: this branch keeps the Stier-aligned observation model
  (ambiguous zeros skipped, two-era `q`, 11 sections) and treats audited annual
  HG predator consumption as a catch-like biomass removal-rate analogue. It is
  not a full age-structured catch-at-age model and does not estimate predator
  selectivity-at-age.
- Added `m5_stier_doherty_proxy_removals` and
  `smoke_m5_stier_doherty_proxy_removals_reduced` to
  `cloud/model-farm-manifest.csv`.
- Stabilization note: the unscaled and 0.25-scaled `Mp_mid`
  natural-mortality offsets were not local-smoke usable, so the registered
  first-pass screen is explicitly low-vulnerability:
  `DOHERTY_PROXY_MP_COLUMN=Mp_mid` and `DOHERTY_PROXY_PRED_SCALE=0.05`.
  A tiny 0.05 local smoke completed with no divergences or treedepth hits, but
  low E-BFMI and slow longer-warmup behavior mean the branch should start with
  a cloud smoke before any full fit.
- Updated `Code/03c_bayesian_fit_audit.R`,
  `Code/03d_posterior_predictive_checks_v3.R`,
  `Code/04_compare_models_v3.R`, and `Code/07bi_model_decision_ledger.R` so
  the branch participates in the normal audit/PPC/comparison/model-farm ledger
  after local or AWS artifacts exist.
- Updated `AGENTS.md`, `docs/full-analysis-model-farm-scope.md`,
  `docs/doherty-style-hg-replication-status.md`, and
  `docs/wcvi-predation-replication-bridge.md` to mark this as a constrained
  biomass-scale proxy-removal branch for AWS troubleshooting.
