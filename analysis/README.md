# `analysis/` — derivative workstreams

Each subdirectory holds the scripts, outputs, and docs for one **derivative analysis** that consumes the core model + data pipeline (which lives at the repo top level: `R/`, `Code/`, `Data/`, `Output/`, `inst/stan/`).

| Workstream | Status | Outputs |
|---|---|---|
| [`00_core_model/`](00_core_model/) | scaffold (no manuscript yet) | future — paper drafts + supplements for the M1–M5 metapopulation paper |
| [`01_ews/`](01_ews/) | implemented | `Output/diagnostics/ews_*.{csv,md}` |
| [`02_resilience/`](02_resilience/) | implemented + figs rendered | `Output/figures/reversibility_*.{pdf,png}`, `Output/diagnostics/reversibility_*.md` |
| [`03_bioeconomics/`](03_bioeconomics/) | sub-package with own `_targets.R`/`renv/` | `analysis/03_bioeconomics/Output/` (gitignored) |
| [`04_talks/2026-royalsociety/`](04_talks/2026-royalsociety/) | active (talk workspace, firewalled) | `analysis/04_talks/2026-royalsociety/Talk_Materials/` |
| [`05_bc_coastwide/`](05_bc_coastwide/) | scaffold (data acquisition in progress) | future — BC-wide hierarchical M1/M3/M5 fits, comparative-areas figures |
| [`probes/`](probes/) | reserved scaffold | future — cross-workstream one-offs |

## Firewall rule

None of these workstreams write back into the core pipeline (`R/`, `Code/` outside `Code/probes/`, `Data/`, `Output/`, `inst/stan/`, `_targets.R`). They **read from** the core outputs and **write to** their own `output/` (or `Output/diagnostics/` with workstream-prefixed filenames). The talk workspace has an additional firewall: it pulls numbers from analyses but never feeds back into them. See `CLAUDE.md`.

## Path conventions

- All R scripts use `here::here()` from the repo root.
- Each workstream's scripts run from repo root via e.g. `Rscript analysis/01_ews/scripts/11_ews_00_data_layers.R`.
- Workstream-specific outputs go to the per-workstream `output/` or to `Output/diagnostics/<workstream>_*.csv`.

## See also

- [`../REPO_STRUCTURE.md`](../REPO_STRUCTURE.md) — top-level directory map
- [`../CLAUDE.md`](../CLAUDE.md) — project state + active sprint
- [`../docs/superpowers/plans/2026-05-20-repo-organization.md`](../docs/superpowers/plans/2026-05-20-repo-organization.md) — migration plan
