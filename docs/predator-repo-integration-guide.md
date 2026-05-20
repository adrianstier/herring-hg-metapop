# Predator Repo Integration Guide

Created: 2026-05-16

## Source Of Truth

Predator data and predator-only visualizations live in the sibling repo:

- Local checkout: `/Users/adrianstier/pacific-herring-predators`
- GitHub repo: `stier-lab/pacific-herring-predators`
- Herring modeling repo: `/Users/adrianstier/stier-2027-herring-metapopulation`

Use the predator repo as the source of truth for predator abundance,
consumption, pressure, spatial sites, source catalogs, and predator-only
figures. Use this herring metapopulation repo for model integration,
Stier-aligned biomass fits, predator-covariate screens, and talk figures that
compare predator demand with `m1_stier_11` or public DFO SCA outputs.

## Import Command

From the herring metapopulation repo:

```sh
PREDATOR_REPO_PATH=/Users/adrianstier/pacific-herring-predators \
  Rscript --vanilla Code/02c_integrate_hg_predator_repo_products.R
```

If `PREDATOR_REPO_PATH` is unset, the integration script also checks the
standard sibling path `../pacific-herring-predators`.

The import writes local, ignored herring products under
`Data/processed/predators/` and a diagnostic at
`Output/diagnostics/hg_predator_repo_integration.md`.

## Predator Repo Files To Use

| Need | Predator repo source |
|---|---|
| Canonical predator synthesis | `docs/HG_PREDATION_SYNTHESIS.md` |
| Data dictionary and source catalog | `docs/DATA_DICTIONARY.md`, `docs/data_catalog.csv`, `docs/data_catalog_HG_only.csv` |
| Species/region coverage | `docs/predator-coverage-matrix.md`, `docs/predator-coverage-matrix.csv` |
| Consumption budget index | `data/processed/consumption_budget/INDEX.md` |
| Audited HG predation pressure | `data/processed/consumption_budget/HG_predation_pressure_index_AUDITED.csv` |
| Herring-model predator covariates | `data/processed/consumption_budget/HG_pressure_climate_predator_covariates.csv` |
| Audited group consumption | `data/processed/consumption_budget/HG_consumption_by_group_year_AUDITED.csv` |
| Audited species consumption | `data/processed/consumption_budget/HG_consumption_by_species_year_AUDITED.csv` |
| HG humpback feeding-substantive demand | `data/processed/consumption_budget/HG_humpback_consumption_feeding_substantive_1910-2022.csv` |
| Predator share provenance | `data/processed/consumption_budget/HG_share_factors_audited.csv` |
| Doherty-style Mp sensitivity | `data/processed/consumption_budget/HG_Mp_sensitivity_AUDITED.csv` |
| Predator attribution model selection | `data/processed/consumption_budget/HG_attribution_model_selection.csv` |
| Functional-response selection | `data/processed/consumption_budget/HG_FR_model_selection.csv` |
| Future humpback projection | `data/processed/consumption_budget/HG_humpback_projection_2022-2050.csv` |
| Humpback HG photo-ID trajectory | `data/processed/haida_gwaii/cheeseman_2024_humpback_HG_photo_id_2001-2022.csv`, `data/processed/haida_gwaii/HG_humpback_trajectory_1910-2022.csv` |
| HG harbour seal sites | `data/processed/haida_gwaii/harbour_seal_HG_haulouts_1986-2019.csv` |
| HG Steller sea lion sites | `data/processed/haida_gwaii/steller_sea_lion_HG_breeding_1971-2021.csv`, `data/processed/haida_gwaii/steller_sea_lion_HG_non_breeding_1971-2021.csv` |
| Predator-only master figure | `Output/figures/MASTER_HG_predation_AUDITED.pdf`, `Output/figures/MASTER_HG_predation_AUDITED.png` |
| Predator pressure figure | `Output/figures/HG_total_consumption_with_pressure_index.pdf`, `Output/figures/HG_total_consumption_with_pressure_index.png` |
| Doherty-style Mp figure | `Output/figures/HG_Mp_AUDITED.pdf`, `Output/figures/HG_Mp_AUDITED.png` |
| Predator attribution figure | `Output/figures/HG_attribution_analysis.pdf`, `Output/figures/HG_attribution_analysis.png` |
| Pre-whaling / 2050 projection figure | `Output/figures/HG_prewhaling_counterfactual.pdf`, `Output/figures/HG_prewhaling_counterfactual.png` |

## Herring Repo Products Created From The Import

| Local herring product | Source in predator repo | Use in herring repo |
|---|---|---|
| `Data/processed/predators/hg_predation_pressure_index_audited.csv` | `HG_predation_pressure_index_AUDITED.csv` | Descriptive predator pressure and reporting. |
| `Data/processed/predators/hg_predation_pressure_covariates.csv` | `HG_pressure_climate_predator_covariates.csv` plus audited consumption tables | Stan predator covariates, including `pred_demand_total_log_z` and `pred_pressure_log_z`. |
| `Data/processed/predators/hg_predator_consumption_by_group_year.csv` | `HG_consumption_by_group_year_AUDITED.csv` | WCVI bridge, DFO SCA external comparison, group-demand summaries. |
| `Data/processed/predators/hg_predator_consumption_by_species_recent.csv` | `HG_consumption_by_species_year_AUDITED.csv` | Recent species ranking for interpretation. |
| `Data/processed/predators/hg_spatial_predator_sites.csv` | HG harbour seal and Steller sea lion site files | Section-level exposure prototypes and local proximity screens. |

## Herring Repo Figures And Diagnostics To Use After Import

| Herring output | Purpose |
|---|---|
| `Output/diagnostics/hg_predator_repo_integration.md` | Confirms import source path, local outputs, recent pressure, group demand, and top recent species. |
| `Output/diagnostics/wcvi_predation_replication_bridge.md` and `Output/figures/wcvi_predation_replication_bridge.pdf` | WCVI/Doherty-style predator-demand bridge against `m1_stier_11` biomass. |
| `Output/diagnostics/hg_dfo_sca_external_comparison.md` and `Output/figures/hg_dfo_sca_external_comparison.pdf` | Talk-facing scale context among `m1_stier_11`, public DFO HG SCA biomass, and predator demand. |
| `Output/diagnostics/predator_spatial_exposure_prototype.md`, `Output/diagnostics/predator_spatial_exposure_section_year.csv`, and `Output/figures/predator_spatial_exposure_prototype.pdf` | Section-year seal/sea-lion exposure product with kernels, count sensitivities, and extrapolation flags. |
| `Output/diagnostics/humpback_section_exposure_proxy.md`, `Output/diagnostics/humpback_section_exposure_proxy.csv`, and `Output/figures/humpback_section_exposure_proxy.pdf` | HG-wide humpback demand scaffold. Explicitly not model-ready section exposure because the current weights are uniform across sections. |
| `Output/diagnostics/salmon_recruitment_context_screen.md`, `Output/diagnostics/salmon_recruitment_context_screen.csv`, and `Output/figures/salmon_recruitment_context_screen.pdf` | Salmon demand screen framed as recruitment/juvenile context rather than adult SSB mortality. |
| `Output/diagnostics/predator_talk_brief.md` and `Output/diagnostics/predator_talk_claims.csv` | Talk-ready predator claims and guardrails from the current bridge, exposure, humpback, and salmon diagnostics. |
| `Output/diagnostics/predator_mechanism_integration_screen.md`, `Output/diagnostics/predator_mechanism_integration_screen.csv`, and `Output/figures/predator_mechanism_integration_screen.pdf` | Pre-Stan gate for predator demand/exposure integrated with historical fishing, PDO, section controls, and timing/substrate endpoint context. |
| `Output/diagnostics/lead_spawn_location_predator_proximity.md` and `Output/figures/lead_spawn_location_predator_proximity.pdf` | Lead-location proximity to predator sites. |
| `Output/diagnostics/doherty_proxy_parameter_plan.md` and `Output/figures/doherty_proxy_parameter_plan.pdf` | Explicit proxy/caveat slide support for the current talk cycle. |

## Interpretation Rules

- `HG_predation_pressure_index_AUDITED.csv` and
  `hg_predation_pressure_index_audited.csv` are pressure indices:
  predator consumption divided by observed HG spawn deposition. They are useful
  for ecological scale and figures, but they are not a direct mortality rate.
- `pred_demand_total_log_z` is the cleaner exogenous predator covariate for
  Stier-aligned biomass-process screens because it depends on predator demand,
  not observed herring spawn in the denominator.
- Predator repo outputs are not age-specific natural mortality. Do not describe
  them as Doherty-style age-selective predation mortality until predator
  selectivity and HG catch-at-age inputs are acquired and audited.
- Humpback products currently support HG-wide demand and trajectory context,
  not section-level exposure. The herring-side proxy scaffold is a missing-data
  placeholder until spatial sightings/density surfaces are sectionized.
- Salmon consumption should be interpreted as juvenile/recruitment context
  unless the herring model gains age or recruitment structure.
- The promoted herring baseline remains `m1_stier_11`. Predator branches are
  held context unless they clear the model-decision ledger gates.

## Refresh Protocol

1. In `/Users/adrianstier/pacific-herring-predators`, regenerate predator
   products if upstream predator data or code changed. The canonical audited
   master figure is produced by `R/28_master_figure_AUDITED.R`.
2. In `/Users/adrianstier/stier-2027-herring-metapopulation`, run the import
   command above.
3. Regenerate affected herring diagnostics:

```sh
Rscript --vanilla Code/07bb_predator_spatial_exposure_prototype.R
Rscript --vanilla Code/07bj_wcvi_predation_replication_bridge.R
Rscript --vanilla Code/07bp_humpback_section_exposure_proxy.R
Rscript --vanilla Code/07bq_salmon_recruitment_context_screen.R
Rscript --vanilla Code/07br_predator_talk_brief.R
Rscript --vanilla Code/07bs_predator_mechanism_integration_screen.R
Rscript --vanilla Code/07bn_hg_dfo_sca_external_comparison.R
Rscript --vanilla Code/07bo_doherty_proxy_parameter_plan.R
Rscript --vanilla Code/07bh_covariate_readiness_registry.R
Rscript --vanilla Code/07bi_model_decision_ledger.R
Rscript --vanilla Code/09_check_document_references.R
```

4. Commit only source/docs/registry changes in the herring repo. Do not commit
   imported predator CSVs, fit artifacts, or generated figures unless the repo
   policy changes.
