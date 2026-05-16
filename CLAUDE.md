# Claude Handoff: Predator Repo Link

This herring metapopulation repo depends on the sibling predator-data repo for
predator data and predator-only visualizations.

## Repos

- Herring modeling repo: `/Users/adrianstier/stier-2027-herring-metapopulation`
- Predator source repo: `/Users/adrianstier/pacific-herring-predators`
- Predator GitHub repo: `stier-lab/pacific-herring-predators`

## Where To Get Predator Material

- Predator synthesis: `/Users/adrianstier/pacific-herring-predators/docs/HG_PREDATION_SYNTHESIS.md`
- Predator data dictionary/catalog:
  `/Users/adrianstier/pacific-herring-predators/docs/DATA_DICTIONARY.md`,
  `/Users/adrianstier/pacific-herring-predators/docs/data_catalog.csv`, and
  `/Users/adrianstier/pacific-herring-predators/docs/data_catalog_HG_only.csv`
- Audited HG predator demand/pressure:
  `/Users/adrianstier/pacific-herring-predators/data/processed/consumption_budget/HG_predation_pressure_index_AUDITED.csv`
- Herring-model predator covariates:
  `/Users/adrianstier/pacific-herring-predators/data/processed/consumption_budget/HG_pressure_climate_predator_covariates.csv`
- Audited group/species consumption:
  `/Users/adrianstier/pacific-herring-predators/data/processed/consumption_budget/HG_consumption_by_group_year_AUDITED.csv`
  and
  `/Users/adrianstier/pacific-herring-predators/data/processed/consumption_budget/HG_consumption_by_species_year_AUDITED.csv`
- Predator-only master figure:
  `/Users/adrianstier/pacific-herring-predators/Output/figures/MASTER_HG_predation_AUDITED.pdf`

## Import Into This Repo

Run from this herring repo:

```sh
PREDATOR_REPO_PATH=/Users/adrianstier/pacific-herring-predators \
  Rscript --vanilla Code/02c_integrate_hg_predator_repo_products.R
```

This writes ignored local products under `Data/processed/predators/` and the
diagnostic `Output/diagnostics/hg_predator_repo_integration.md`.

Use `docs/predator-repo-integration-guide.md` for the complete crosswalk from
predator repo files to herring repo diagnostics, figures, and model covariates.

## Modeling Caveat

Predator repo products currently support biomass-scale predator demand,
pressure, spatial-site prototypes, and talk figures. They are not
age-selective Doherty-style natural mortality. The promoted herring baseline
remains `m1_stier_11`, and predator model branches remain held unless the
model-decision ledger says otherwise.
