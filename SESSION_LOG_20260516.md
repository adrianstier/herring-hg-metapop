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
