# Agent Notes For This Repository

This file captures project-specific modeling decisions that future coding agents should read before editing model code or interpretation docs.

## Current Scientific Direction

The promoted baseline is now Stier-aligned before adding more biological complexity.

As of 2026-05-08, use `m1_stier_11` as the practical analysis baseline:

- Stan file: `inst/stan/herring_metapop_m1_stier_11.stan`
- Fit script: `Code/03_fit_m1_stier_11.R`
- Fit artifact: `Data/processed/m1_stier_11_fit.rds`
- LOO artifact: `Output/posteriors/loo_m1_stier_11.rds`
- Status file: `Output/diagnostics/latest_model_status.md`
- Exact re-LOO note: `Output/diagnostics/m1_stier_11_exact_reloo.md`

The original PSIS-LOO had one high Pareto-k point, but exact re-LOO resolved it:
held-out 1970 Naden Harbour changed total LOOIC from 1953.02 to 1953.08, with
a clean refit. Treat that LOO warning as resolved unless the model/data change.

1. Treat zero spawn records as ambiguous unless there is explicit evidence that a complete survey was designed to establish absence.
   - Some site-years are not surveyed for governance/access reasons, including Haida preferences, not because biomass is low.
   - Therefore no survey effort, and ambiguous zero records, should not push biomass downward.
   - The current detection-aware / informative-zero models are useful sensitivity analyses, not the default biological interpretation.
2. Keep survey-method differences explicit.
   - Stier et al. separated surface and SCUBA survey catchability.
   - This repo has evidence for a transition/mixed period, so a three-era sensitivity is reasonable, but a Stier-replication branch should use the original two-era split.
3. Do not transfer numerical `log.q` values across data scales without checking units.
   - Stier used the spawn habitat index scale.
   - The current maintained data use DFO `spawn_index_tonnes`.
   - The proportional observation equation transfers; the absolute posterior scale of `log.q` does not.
4. Separate model fitting from figure/reporting focus for section count.
   - Stier fit the model to 11 Haida Gwaii subpopulations but focused interpretation on 9 data-rich focal subpopulations.
   - Preserve both 11-section and 9-focal reporting sensitivities.
5. Hold off on full size/age structure for now.
   - Stier and Okamoto support biomass-based section-level modeling here.
   - Age composition and weight-at-age are future regional covariates or stock-area cross-checks, not a full 11-section age-structured model in the current branch.

## Source Anchors

- `Literature/Stier_et_al_2020_Ecosphere_Portfolio_Erosion.pdf`
- `Code/legacy-2019/Model1_diagonal_equal.R`
- `docs/parameter-comparison-stier2020.md`
- `docs/high-quality-analysis-scope.md`
- `docs/analysis-issues-and-fixes.md`

## Implementation Caution

Do not silently overwrite `Data/processed/jags_model_inputs_v2.RData` to change zero treatment or section selection. Create explicit sensitivity inputs or fit scripts with clear names, for example:

- `m1_stier_11`: zeros ambiguous/missing, Stier-like survey q, 11 fitted sections.
- `m1_stier_9_report`: same fit summarized over the 9 focal sections.
- `m1_detection_zero_sensitivity`: surveyed zeros treated as informative nondetections.

When reporting fits, state whether zeros are ambiguous/missing or informative nondetections. That choice changes the biological interpretation.

Also state the likelihood unit. Raw LOOIC is not directly comparable between
positive-only models like `m1_stier_11` and surveyed-cell/detection-aware models
like `m1_v4` or `m1_v5`.
