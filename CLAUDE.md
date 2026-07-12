# ⭐ Haida Gwaii Herring Talk — READ FIRST

## Related herring repositories (cross-walk)

> **You are here: `stier-2027-herring-metapopulation`**

Part of a **three-repo Pacific herring / Haida Gwaii set**. Keep this map in sync across all three (each repo's CLAUDE.md carries it):

- **`pacific-herring-predators`** — GitHub `stier-lab/pacific-herring-predators` · `~/pacific-herring-predators`. Predator-data backbone: audited HG/BC predator time series, pressure/consumption products, harbour-seal & Steller sea-lion spatial products, curated literature. **Not** the modeling repo.
- **`stier-2027-herring-metapopulation`** — GitHub `adrianstier/herring-hg-metapop` · `~/stier-2027-herring-metapopulation`. Herring state-space / metapopulation modeling (extends Stier et al. 2020 *Ecosphere*); consumes predator covariates from the predator repo; houses the 2026 Royal Society talk workspace.
- **`herring-bioeconomics`** — `~/herring-bioeconomics`. Bioeconomic backbone + four-lens economic analysis of the BC / Haida Gwaii fishery (kazunoko demand, ecosystem-service & value tipping points).

**Presentations & large media (Google Drive):** `Stier Lab/People/Adrian Stier/Projects/In Progress/Herring-Predator-Dynamics/` — talk decks, video clips, talk-prep. Its `README.md` is the canonical cross-repo map.

**Shared NotebookLM:** "Herring Haida Gwaii" — https://notebooklm.google.com/notebook/63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e

If this session involves the **Pacific herring / Haida Gwaii talk** (US–UK
Royal Society *Tipping Points in Ocean Systems* Forum, London, Wed 20 May 2026
[delivered], 09:30, Session 5 — Ecosystem Services; ~25 min; tied to the herring
metapopulation paper):

**⚠️ The submitted abstract is NOT the talk's guide.** It was just some early
concepts sent in for the program — do not treat it as a locked spine or
narrative. The right outline for this tipping-points talk is still open and is
being worked out with Adrian.

**Read `docs/HERRING_TALK_ASSETS.md` before doing anything.** It is the single
source of truth — it indexes every slide, photo, lecture, note, dataset,
figure, NotebookLM source, and Drive folder for the talk (in place, nothing
copied), and tracks the cross-session build state. Update its **Talk Build
State** section at the end of each working session so the next context window
(Claude or Codex) continues cleanly.

Before turning a model result into slide language, read
`docs/talk-model-claim-control-sheet.md`. It is the safe-language contract for
baseline, held branches, predators, DFO summaries, and the Doherty-style bridge.

**Talk work lives in `analysis/04_talks/2026-royalsociety/`** — a TALK-ONLY workspace
firewalled from the core metapopulation analysis. Never import anything from
it into the modeling pipeline (`R/`, `inst/stan/`, `Data/`, `Output/`,
`Code/`, `_targets.R`); talk numbers are pulled *from* the core analysis,
never the reverse. See `analysis/04_talks/2026-royalsociety/README.md`. Current direction:
Spine B (coupled social–ecological tipping points, hysteresis-led, NOT
portfolio-as-early-warning, solutions-forward).

**For hypotheses / ideas about why HG herring have not recovered** — borrowing
from other systems (cod, etc.) and the herring literature — the canonical,
expandable idea bank is **`docs/herring-non-recovery-hypotheses.md`** (mechanism
menu with HG support ranking, contested-recovery nuance, governance-under-
uncertainty solutions, and how to expand it via NotebookLM). Consult/extend it
before reasoning about non-recovery mechanisms or drafting talk narrative.

---

# Archived: Stier et al. 2020 *Ecosphere* paper code

The original **2020 Ecosphere** Haida Gwaii herring metapopulation /
portfolio paper codebase is archived (copied, original on Drive untouched) at:

**`Code/archive/stier-2020-ecosphere-herring/`** — start with its
**`INDEX.md`**.

Contains: the 2020 simulator + figure code (`Code/Recent Figs/`), legacy MARSS/
JAGS lineage (`Code/old/`), the **async→sync portfolio animation**
(`_animation/sim_anim.mp4`, the talk restyle target), the published Ecosphere
Fig 5, and the scianimator interactive version. ~16 MB (code + animation only;
the 4.6 GB of model-output binaries were left on Drive — path in `INDEX.md`).
Read-only provenance — not part of the live pipeline; port with intent.

---

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

## Herring-Side Predator Outputs

- Talk brief: `Output/diagnostics/predator_talk_brief.md`.
- Seal/sea-lion exposure: `Output/diagnostics/predator_spatial_exposure_prototype.md`
  and `Output/diagnostics/predator_spatial_exposure_section_year.csv`.
- Humpback scaffold: `Output/diagnostics/humpback_section_exposure_proxy.md`.
  This is HG-wide demand distributed uniformly across sections, not
  model-ready section exposure.
- Salmon context: `Output/diagnostics/salmon_recruitment_context_screen.md`.
  Treat salmon as juvenile/recruitment context unless the model gains age or
  recruitment structure.
- Future-lag / age screens:
  `Output/diagnostics/future_lag_negative_control_audit.md`.
  Appendix B number-at-age is provisional assessment-input context from
  biological samples; Appendix B spawn shares the adult-spawn observation stream
  used by `m1_stier_11`; DFO 2025 age-2 recruitment is SCA model output. Do not
  treat shared-spawn-normalized or SCA-output rows as independent predator
  validation.

## Modeling Caveat

Predator repo products currently support biomass-scale predator demand,
pressure, spatial-site prototypes, and talk figures. They are not
age-selective Doherty-style natural mortality. The promoted herring baseline
remains `m1_stier_11`, and predator model branches remain held unless the
model-decision ledger says otherwise.
For all model interpretation, check `Output/diagnostics/model_decision_ledger.md`
and `Output/diagnostics/model_branch_status_table.md` first. They classify
branches as promoted, held/context, archived/do-not-use, zero-treatment
sensitivity, or planning-only so old or gated predator branches are not
accidentally upgraded into evidence.
