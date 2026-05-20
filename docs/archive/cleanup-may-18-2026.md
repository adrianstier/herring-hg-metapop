# Repo Cleanup Plan — stier-2027-herring-metapopulation

**Generated:** 2026-05-18 · **Repo:** `/Users/adrianstier/stier-2027-herring-metapopulation` (41 GB, git-tracked)

> **Scope:** This is an audit + prioritized cleanup *plan*, produced by a swarm of
> read-only domain agents. No files were moved, deleted, or modified to create it.
> ⚠️ Live constraints: Royal Society talk **Wed 20 May 2026** (2 days out); the
> Bayesian modeling pipeline is active; the talk-workspace firewall rule applies
> (`analysis/04_talks/2026-royalsociety/` never feeds the core pipeline). Nothing tagged
> **Risk: H** or **talk/pipeline-live** should be actioned without explicit sign-off.

## How to read this
Each domain section: inventory → categorized issues → a prioritized action table
(Priority · Action · Path(s) · Risk L/M/H · Reversible? · Rationale) → open questions.
The final **Synthesis** section reconciles cross-cutting items (esp. `.gitignore`
and the 41 GB bloat) into one dependency-ordered, risk-tagged action plan.

---


## 1. Root-level hygiene & repo structure

_Audit date: 2026-05-18. Repo: `/Users/adrianstier/stier-2027-herring-metapopulation` (git-tracked, ~41 GB). READ-ONLY audit — nothing modified. Talk Wed 2026-05-20._

### Inventory snapshot

| Metric | Value |
|---|---|
| Root `.log` files | 20 |
| Root `*_output.txt` files | 13 |
| Root `SESSION_LOG_*.md` | 7 (20260511–20260517) |
| Other root meta `.md` | `MORNING_REPORT.md`, `REVIEW_NOTES.md`, `README.md`, `CLAUDE.md`, `AGENTS.md` |
| Total root loose `.log` + `*_output.txt` size | ~370 KB (largest: `may9_analysis_suite_refresh.log` 100 KB) |
| Total all root regular files | ~656 KB |
| Root `.log`/`*_output.txt` git-tracked? | **0 tracked** — all untracked local junk, **never entered git history** (verified `git log --all` on samples = empty) |
| Root `.md` git-tracked? | **9 tracked & committed clean** (7 SESSION_LOG + MORNING_REPORT + REVIEW_NOTES); last commit `d2c6d3d` 2026-05-17 |
| `git ls-files` total | 426 |
| `git status --porcelain` | 22 (none are root logs/txt — all in Code/, docs/, analysis/04_talks/2026-royalsociety/) |
| `.git` dir size | 182 MB (NOT a 41 GB contributor) |
| 41 GB location | `Data/` 15 GB, `Output/` 13 GB, `cloud/` 12 GB — **all outside this agent's domain**; root contributes ~0 |

**Key finding: the root log/output clutter is a *tidiness* problem, not a *bloat* problem.** `.gitignore` lines 20–22 (`*_output.txt`, `*_watch.log`, `*.log`) already correctly exclude every stray root log/txt. None are committed; none are in history. They cost ~370 KB on local disk only.

### Issues

**Redundant / duplicate**
- Multiple log "families" for the same model run, e.g. `m1_stier_11_output.txt` + `m1_stier_11_refresh.log` + `m1_stier_11_exact_reloo.log`; `m3_stier_distance_*` has 7 variants incl. `..._full_aborted_20260510_050404.log` (87-byte `..._exact_reloo_refresh.log` is an empty stub). These are point-in-time console captures, not pipeline inputs — duplicative once their info is in SESSION_LOGs.

**Stale / superseded**
- Versioned April outputs `m1_v3/v4/v5_output.txt`, `m2_v2`, `m3_v2/v3/v4/v5`, `m5_v3_output.txt` (dated Apr 2–24) belong to an older `_vN` model-naming scheme superseded by the May `*_stier_*` named-model scheme. They are stale console logs, not analysis artifacts. (No root logs predate May 1 by mtime in the live window, but these `_vN` files are content-stale.)
- `MORNING_REPORT.md` (2026-05-12) and `REVIEW_NOTES.md` (2026-05-12) are committed point-in-time snapshots now ~6 days old, likely superseded by later SESSION_LOGs (20260514–17). Staleness note only — do not rewrite.

**Misplaced (belongs elsewhere)**
- All 33 root `.log`/`*_output.txt` files are model-run console captures that conceptually belong under a `logs/` or `Output/diagnostics/`-style location, not the repo root. No `logs/` dir exists at root; `.gitignore` only ignores `cloud/logs/`, not a root `logs/`.
- `excalidraw.log` (255 B) is a diagram-tool artifact unrelated to the analysis pipeline — orphaned tool noise.

**Should be git-ignored / not tracked**
- Already handled correctly. `.gitignore` 20–22 covers all root logs/txt; verified untracked and absent from history. **No committed bloat at root.** No action required for git hygiene here.
- Minor: a root `logs/` directory is NOT yet gitignored — if logs are relocated there, add `logs/` to `.gitignore` (currently only `cloud/logs/` line 59).

**Dead / orphaned**
- `m3_stier_distance_exact_reloo_refresh.log` — 87 bytes, effectively empty stub.
- `m3_stier_distance_exact_reloo_full_aborted_20260510_050404.log` — name explicitly says "aborted"; dead run output.
- `v3_compare_watch.log` (Apr 4), `excalidraw.log` — orphaned.

**Risk items (LIVE talk / active models — flag, do NOT propose deleting)**
- `may9_analysis_suite_refresh.log` (100 KB, mtime 2026-05-12) and `m1_stier_obs_hier_*`, `m2_stier_site_growth_*`, `m3_stier_distance_*` (May 6–13) may be the **most recent diagnostic captures from the active Bayesian pipeline** feeding the Wed 2026-05-20 Royal Society talk. Treat all May-dated `*_stier_*` logs as potentially live reference. Do not relocate/delete before the talk.
- The 7 committed `SESSION_LOG_*.md` + `MORNING_REPORT.md` + `REVIEW_NOTES.md` are part of the working narrative/provenance trail for the talk. They are tracked & clean — leave entirely untouched until after 2026-05-20.
- `README.md`, `AGENTS.md`, `CLAUDE.md`, `_targets.R`, `.Rproj` — all recently updated (README/AGENTS/CLAUDE 2026-05-17). Quality looks current; staleness not a concern. No rewrite proposed.

### Prioritized recommendations

_All deferred until AFTER the 2026-05-20 talk. Nothing here is required for git/bloat reasons — root junk is already gitignored, ~370 KB, zero history impact. This is post-talk tidiness only._

| Priority | Action | Exact path(s) / glob | Risk (L/M/H) | Reversible? | Rationale |
|---|---|---|---|---|---|
| P3 (post-talk) | Create `logs/` (or `Output/logs/`), `git mv`-free **plain move** of stale April version logs into it | `m1_v3_output.txt`, `m1_v4_output.txt`, `m1_v5_output.txt`, `m2_v2_output.txt`, `m3_v2_output.txt`, `m3_v3_output.txt`, `m3_v4_output.txt`, `m3_v5_output.txt`, `m5_v3_output.txt` | L | Yes (move-back) | Superseded `_vN` scheme; declutters root; untracked so no git impact |
| P3 (post-talk) | Move remaining root model logs into `logs/` once talk done | `m1_stier_*`, `m2_stier_*`, `m3_stier_*`, `may9_analysis_suite_refresh.log`, `v3_compare_watch.log` | L | Yes | Console captures, not pipeline inputs; keep accessible but off root |
| P3 (post-talk) | Add `logs/` to `.gitignore` after relocating | `.gitignore` (owner: not this agent — flag only) | L | Yes | Keeps relocated logs untracked, consistent with current intent |
| P4 (post-talk) | Delete clearly-dead stubs ONLY after Adrian confirms | `m3_stier_distance_exact_reloo_refresh.log` (87 B), `m3_stier_distance_exact_reloo_full_aborted_20260510_050404.log`, `excalidraw.log` | M | **No (deletion)** | Empty/aborted/orphaned; but irreversible — require explicit sign-off |
| P4 (post-talk) | Confirm `MORNING_REPORT.md` / `REVIEW_NOTES.md` superseded; if so, consider folding into a `notes/` dir (tracked move) | `MORNING_REPORT.md`, `REVIEW_NOTES.md` | M | Yes (tracked move) | They are committed provenance — only reorganize, never delete |

### Open questions for Adrian

1. **Are any May-dated root logs (esp. `may9_analysis_suite_refresh.log`, `m1_stier_obs_hier_after_m3.log`, `m3_stier_distance_*`) still being read/appended by the live pipeline or referenced for the Wed talk?** If yes, nothing moves until after 2026-05-20.
2. Do you want a permanent root **`logs/` convention** (gitignored) so future model runs stop landing at repo root? This is the single highest-value structural fix.
3. Are the April `m*_vN_output.txt` files safe to archive/delete, or do you need them as a provenance trail for the `_vN`→`_stier_` model-rename history?
4. `MORNING_REPORT.md` and `REVIEW_NOTES.md` are committed but ~6 days stale — keep as historical record, fold into a `notes/` dir, or are they still active scratchpads?
5. Should the 7 `SESSION_LOG_*.md` files stay at root long-term, or move to a tracked `docs/session-logs/` after the talk? (No action now — they're live talk provenance.)


---

## 2. R/ pipeline, inst/, tests/, _targets.R

_Audit date: 2026-05-18. READ-ONLY. No R/Stan/targets executed. LIVE pipeline +
Royal Society talk Wed 20 May 2026 — recommendations are conservative._

### Inventory snapshot

**`R/` (13 files, all git-tracked):**

| File | Last commit | In `_targets.R`? | In `tests/`? | In `Code/`? | Notes |
|---|---|---|---|---|---|
| `00_setup.R` | 2026-05-03 | sourced via `tar_source("R")` | yes (all) | — | constants, `theme_pub`, `theme_lecture` |
| `01_data_cleaning.R` | 2026-05-03 | yes (clean_*) | yes | — | 7 fns |
| `02_prepare_model_data.R` | 2026-05-03 | yes | yes | — | `prepare_model_data` |
| `03_fit_model.R` | 2026-05-05 | yes (`fit_model`, `check_diagnostics`, `extract_posteriors`) | partial | — | also defines `compile_model`, `prepare_stan_data_spatial`; holds `.model_file_map` (8 versions) |
| `04_model_comparison.R` | 2026-05-05 | **no** | no | yes (`Code/04_*`) | `compare_models`, `plot_loo_comparison` |
| `05_portfolio.R` | 2026-05-05 | yes | yes | — | portfolio/synchrony |
| `06_figures.R` | 2026-05-05 | yes (7 figs) | yes | — | publication figs |
| `07_lecture_figures.R` | 2026-05-05 | **no** | yes (test-figures) | — | dark-theme lecture figs |
| `08_occupancy_model.R` | 2026-05-03 | yes | partial | — | occupancy sub-model |
| `09_zero_inflated_obs.R` | 2026-05-03 | **no** | yes (test-data-cleaning) | — | `prepare_censored_data` only |
| `10_spatial_data.R` | 2026-05-05 | yes | yes | — | distance matrix + predator spatial |
| `cloud_fit_control.R` | 2026-05-12 | **no** | no | yes (5 `Code/03_*`) | env-driven Stan runtime control |
| `process_oisst_monthly.R` | 2026-05-05 | **no** | no | no | standalone script (no fns); self-documents as optional, off-pipeline |

**`inst/stan/` (33 `.stan`, 7 `.hpp`, 26 `.rds`):**
- `.rds` (26): gitignored (`*.rds` in `.gitignore`) — untracked local compile cache, not in scope for git cleanup.
- `.hpp` (7): **git-tracked**, all committed 2026-04-01.
- `.stan` (33): 8 mapped by `R/03_fit_model.R` `.model_file_map` + `site_occupancy.stan` (occupancy). Remaining ~24 `m1_stier_*`/`m2_*`/`m3_*`/`m5_*`/`*_v2..v5` are referenced by **`Code/`** (sibling-owned), NOT by `R/`. `cloud_pipeline_smoke.stan` used by `cloud/smoke_stan_pipeline.R`.

**`tests/` (1 runner + 4 suites, 83 `test_that` blocks):** test-data-cleaning (32), test-spatial (30), test-portfolio (17), test-figures (4). All last touched 2026-05-05.

**`_targets.R`** (427 lines): coherent DAG, `tar_source("R")`, fits `version = "v1"` baseline + occupancy; `m2`-`m6`/`v2` documented but not wired.

### Issues

**Redundant / duplicate**
- None within `R/` itself — each script has a distinct role; no duplicate function definitions found.
- `inst/stan/` shows heavy *versioned naming sprawl* (`m1`, `m1_v2..v5`, `m1_stier_11`, `m1_stier_obs_hier`, `m1_stier_method_sensitivity`, `m1_priortest`; same for m3/m5). This is iteration history, not strict duplication, and the live `m1_stier_11` baseline + sensitivity branches are referenced by `Code/` — **out of safe-removal scope** (and `Code/` is owned by a sibling agent; do not act on it here).

**Stale / superseded**
- **7 tracked `.hpp` files in `inst/stan/` are stale build artifacts.** Committed 2026-04-01; their parent `.stan` sources were all modified 2026-05-05 (`herring_metapop_v1.stan`, `v2`, `m2_distance`, `m3_dd_global`, `m4_dd_site`, `m5_predators`, `m6_timevarying`). cmdstanr regenerates `.hpp` on compile, so the committed copies are out-of-date C++ transpilations that should never have been tracked (cf. `.rds` which *is* correctly gitignored). Low-value noise; safe to untrack but NOT pipeline-load-bearing either way.
- `m1_v2..v5`, `m3_v2..v5`, `m5_v2..v5` Stan files represent superseded model iterations, but they are still referenced from `Code/` and from the `model_decision_ledger`/`branch_status_table` governance docs — superseded ≠ deletable while the talk/paper review is live.

**Orphaned (not sourced/targeted anywhere)**
- **Provably orphaned from the maintained pipeline (no `_targets.R`, no `tests/`, no `R/` `source()` reference):** `R/04_model_comparison.R`, `R/07_lecture_figures.R`, `R/09_zero_inflated_obs.R`, `R/cloud_fit_control.R`, `R/process_oisst_monthly.R`.
  - **BUT** `tar_source("R")` sources the *entire* `R/` directory unconditionally, so every `.R` file there is loaded into the targets session regardless of whether a target calls it. None is dead from R's perspective.
  - `04_model_comparison.R` and `cloud_fit_control.R` are actively called by `Code/` scripts → **NOT orphaned**, just not wired into the default DAG.
  - `07_lecture_figures.R` is exercised by `tests/testthat/test-figures.R` → **NOT orphaned**.
  - `09_zero_inflated_obs.R` (`prepare_censored_data`) is exercised by `tests/testthat/test-data-cleaning.R` → **NOT orphaned**; it is not called by `02`/`03` or `_targets.R`, suggesting the censored-zero path is a tested-but-not-yet-wired capability.
  - `process_oisst_monthly.R`: **the only genuinely standalone file** — no function defs, sourced nowhere (`R/`, `tests/`, `Code/`, `cloud/`, `_targets.R`), self-labeled "optional preprocessing utility, not part of `tar_make()`". This is by design (regenerates a raw SST CSV), not accidental orphaning.
- `cloud_pipeline_smoke.stan`: only Stan file referenced by neither `R/` nor `Code/`, but it IS used by `cloud/smoke_stan_pipeline.R` and documented in `docs/aws-codex-model-farm-lessons.md` → intentional, not orphaned.

**Naming / numbering inconsistencies**
- `R/` numbering 00–10 is contiguous and clean, but three numbered files (`04`, `07`, `09`) are not in the default DAG, so the numeric sequence implies a linear pipeline that `_targets.R` does not actually follow end-to-end. Mildly misleading but not a defect.
- `cloud_fit_control.R` and `process_oisst_monthly.R` are unnumbered while everything else is numbered — correct (they are utilities), but worth a one-line header note for the next reader.
- `inst/stan/` mixes three naming schemes: canonical (`herring_metapop_v1`), numbered-model (`m1`..`m6`), and author-tagged (`m1_stier_11`, `m5_stier_doherty_*`). The `.model_file_map` only knows the first two; the `m*_stier_*` family is driven entirely from `Code/`. Sprawl is real but governed by the ledger docs — flag only.

**Dead code / commented-out blocks / TODO debt**
- **Zero** `TODO`/`FIXME`/`HACK`/`XXX` markers in `R/*.R`. No `deprecated`/`obsolete`/`do not use` markers either. Unusually clean.
- One intentional commented-out target block in `_targets.R` (lines 259–270, the `fit_v2` predator-covariate placeholder) — clearly labeled "v2 placeholder", harmless documentation-as-code.
- No large commented-out code blocks detected in any `R/` file.

**Risk items (pipeline-live — flag, do not propose removing if load-bearing)**
- `_targets.R` fits `version = "v1"`, but per `README.md` / `CLAUDE.md` the *promoted* baseline is `m1_stier_11` (run via `Code/`, not the default DAG). This is a known architectural split (maintained `R/`+targets API vs. active `Code/` model farm), **not** a bug to "fix" — do not rewire `_targets.R` to chase the talk baseline. Flag for Adrian's awareness only.
- `R/03_fit_model.R` `.model_file_map`, `.spatial_models`, predator-model classifiers are the contract every fit depends on. Do not touch before the talk.
- The 24 non-canonical Stan files look unused from `R/` but are load-bearing for the live `Code/` model farm and governance ledger. **Do not remove any `inst/stan/*.stan`.**

### Prioritized recommendations

| Priority | Action | Exact path(s) | Risk (L/M/H) | Reversible? | Rationale |
|---|---|---|---|---|---|
| P3 (post-talk, optional) | `git rm --cached` the 7 tracked `.hpp` files and add `inst/stan/*.hpp` to `.gitignore` (mirrors existing `*.rds` handling) | `inst/stan/herring_metapop_{v1,v2,m2_distance,m3_dd_global,m4_dd_site,m5_predators,m6_timevarying}.hpp` | L | Yes (git) | Stale cmdstanr C++ artifacts (2026-04-01) older than their `.stan` sources (2026-05-05); regenerated on compile; should be gitignored like `.rds`. Untracking does not affect runtime. **Defer until after 20 May.** |
| P3 (doc only) | Add a one-line header to `R/04_model_comparison.R`, `R/07_lecture_figures.R`, `R/09_zero_inflated_obs.R` noting they are loaded by `tar_source("R")` / `Code/` / `tests/` but not in the default DAG | those 3 files | L | Yes | Removes the "is this orphaned?" question for future cleanup passes. Comment-only, no behavior change. Owner decision — do not edit unilaterally. |
| P4 (no action) | Leave all `inst/stan/*.stan`, all `R/*.R`, all `tests/*` as-is | `inst/stan/`, `R/`, `tests/` | — | — | Nothing in this domain is provably dead; `Code/`-driven and ledger-governed files must be preserved through the live talk + paper review. |

### Open questions for Adrian

1. **`.hpp` tracking:** Was committing `inst/stan/*.hpp` (2026-04-01) intentional, or should they be gitignored alongside `*.rds`? They are stale vs. the 2026-05-05 `.stan` edits. (Cleanup is trivial and reversible but I will not touch it before the talk.)
2. **`09_zero_inflated_obs.R` (`prepare_censored_data`):** Tested but not wired into `02`/`03`/`_targets.R`. Is the censored-zero path a deliberately-held capability (consistent with README "informative-zero models are sensitivity analyses"), or a pipeline gap where `_targets.R` should be feeding censored data into `fit_model`?
3. **`_targets.R` baseline = `v1` vs. promoted `m1_stier_11`:** Confirm the intended division of labor — maintained `R/`+targets pipeline stays on `v1`, while `m1_stier_11` and branches live only in the sibling-owned `Code/` farm? If so, no action; just confirming this is by design before any future consolidation.
4. **`process_oisst_monthly.R`:** Confirm it should stay in `R/` (it has no functions and is never sourced) vs. moving to a `scripts/`/`data-raw/` location post-talk — purely organizational, no urgency.
5. **Test coverage gaps (informational):** `fit_model`, `compile_model`, `check_diagnostics`, `fit_occupancy`, `extract_occupancy_posteriors`, and most `fig_*`/occupancy figures have no `test_that` coverage (Stan-fitting fns are reasonably untested for speed). Worth a lightweight smoke test for `fit_model` post-talk? Not a cleanup item.


---

## 3. Code/ analysis scripts

_Audit date: 2026-05-18. READ-ONLY. Repo HEAD `900d7c5`, branch `chore/overnight-cloud-dryrun-ids-20260511-2254`. Scope: `Code/` only (R/, Output/, docs/, talk/, Data/ owned by others)._

### Inventory snapshot

- **132** `.R` scripts directly in `Code/` + **13** `.sh` orchestrators + **8** `.R` in `Code/legacy-2019/` (plus a `Posteriors/` subdir of 2019 PDFs/CSV).
- Numeric pipeline stages: `00_` data audit → `01*` acquisition/SST/chl-a → `02*` merge + predator/DFO covariates → `03*` model fits (**26** `03_fit_*` variants) → `03b–03d` LOO/PPC audits → `04*` model comparison + portfolio + 11 `wait_for_*.sh` glue → `05_` MCMC diagnostics → `06*` figure suites → **70** `07*` analysis/section/screen scripts → `08_refresh_may9_analysis_suite.sh` (master orchestrator, calls ~55 of the `07*`) → `09_check_document_references.R`.
- **Talk-critical (LIVE, Royal Society Wed 20 May):** `Code/07cz_deck_figure_reexport.R` (modified today, uncommitted `M`). It sources only `R/00_setup.R` and reads CSVs from `Output/diagnostics/` + `Data/processed/`. Its upstream CSV producers in `Code/`: `06g_reproduce_stier2020_figures_updated.R` (fig3/fig4 CSVs), `02c_integrate_hg_predator_repo_products.R` (predator consumption + pressure index), and the `07_*`/`07i`/`07l` family writing `m1_stier_11_total_biomass_by_year.csv`.
- Model lineage is explicit in `03c_bayesian_fit_audit.R`: the **promoted baseline is `m1_stier_11`**; `m1_v3/v4/v5`, `m3_v3/v5`, `m5_v3/v5` are carried but flagged `stale_models`. `m2`/`m3`/`m5` Stier-named branches are the current secondary models.

### Issues

**- Redundant / duplicate / superseded variants**
- `03_fit_m1*` ladder: `03_fit_m1.R`, `_v2`, `_v3`, `_v4`, `_v5` are all superseded by the Stier-named branch (`03_fit_m1_stier_11.R` = promoted baseline, `_stier_method_sensitivity`, `_stier_obs_hier`). `03c_bayesian_fit_audit.R` itself classifies the `v*` rows as `stale_models`.
- Same pattern for `03_fit_m2.R`/`_v2` (→ `03_fit_m2_stier_site_growth.R`), `03_fit_m3.R`/`_v2`/`_v3`/`_v4`/`_v5` (→ `03_fit_m3_stier_distance.R`), `03_fit_m5.R`/`_v2`/`_v3`/`_v5` (→ `03_fit_m5_stier_*` + `03_fit_m5_combined.R`). `_v2`/`_v4` rows have **zero callers** anywhere; `v3`/`v5` are referenced only by the two audit scripts that explicitly tag them stale.
- `06_state_estimate_plots.R` (current, 2026-05-12) vs `06_state_estimate_plots_v2.R` (older, 2026-05-05, header says "v2 state-space models" — a superseded model generation, 0 callers).
- `04_model_comparison_v2.R` (1.3 KB stub, 0 callers) superseded by `04_compare_models_v3.R` (used by `08_` orchestrator + `04_wait_for_v3_and_compare.sh`).
- `03b_extract_loo_v2.R` (948 B, 0 callers) — superseded by the `03c/03d` audit pair.
- `06b_m1_v4_total_biomass_trajectory.R`, `06c_m1_v4_aggregate_fit_diagnostic.R`, `04c_inspect_m1_v4_diagnostics.R`, `04d_decide_next_after_m1_v4.R`, `04e_recompute_m3_v5_surveyed_loo.R` — all operate on the stale `m1_v4`/`m3_v5` objects; superseded by the `06d/06e/06f` + `07*_stier_11_*` family.

**- Stale one-offs**
- `wait_for_*.sh` glue scripts are dated babysitter loops, all with **0 external references**: `04_wait_for_m1_v4_and_refresh.sh`, `04_wait_for_m1_v5_and_refresh.sh`, `04_wait_for_v3_and_compare.sh` (point at stale `v3/v4/v5` fits); `04_wait_for_m1_stier_11_and_refresh.sh`, `_m1_stier_method_sensitivity_`, `_m1_stier_obs_hier_`, `_m2_stier_site_growth_` (×2), `_m3_stier_distance_` (×2), `04_wait_for_m3_then_fit_m1_stier_obs_hier.sh` — single-fit-run scaffolds, not reusable pipeline. The `v3/v4/v5` ones are unambiguously stale; the `stier_*` ones are recent but still throwaway.
- ~15 `07*` "status snapshot / dossier / ledger / brief" scripts that read like dated working memos rather than reusable analysis: `07av_may11_status_snapshot.R`, `07q_may9_headline_findings_table.R`, `07ax_stier_signal_persistence_summary.R`, `07aw_promoted_baseline_evidence_package.R`, `07bi_model_decision_ledger.R`, `07br_predator_talk_brief.R`, `07bl_doherty_replication_execution_status.R`, etc. Many are NOT in the `08_` orchestrator (see Orphaned).
- `Code/legacy-2019/` (8 scripts + `Posteriors/` outputs): last touched 2026-04-01, **no current script sources `legacy-2019/`** (the grep hits for "legacy" are scripts with "legacy" in their *name*, e.g. `07u_legacy_shi_overlap_sensitivity.R`, not path references). Fully orphaned 2019 codebase.

**- Naming inconsistencies**
- Three coexisting conventions for the same `03` stage: numeric `_v2..v5`, descriptive `_stier_11` / `_stier_site_growth`, and bare names. `_v2` means "model generation 2", `_stier_11` means "Stier-aligned spec #11" — opaque without the `03c` tribble.
- `07*` suffix space exhausted into `07aa…07az`, `07ba…07bw`, then a jump to `07cz` (talk deck) — alphabetic ordering no longer reflects run order or dependency; `07cz` sorts after `07c` but is the newest/most important file.
- Mixed stage-04 naming: `04_compare_models_v3.R` vs `04_model_comparison_v2.R` (verb-noun vs noun) for the same job.
- `01c_chla_erddap_download.R` and `01c_chla_processing.R` share the `01c` prefix (two scripts, one number); likewise `02c_integrate_hg_predator_repo_products.R` and `02c_prepare_dfo_covariates.R`; `04e_m1_stier_11_loo_diagnostic.R` and `04e_recompute_m3_v5_surveyed_loo.R`.

**- Orphaned (no caller, outputs unused)**
- `03_fit_m1_v2.R`, `03_fit_m2_v2.R`, `03_fit_m3_v2.R`, `03_fit_m3_v4.R`, `03_fit_m5_v2.R`, `03_fit_m2.R`, `03_fit_m3.R`, `03_fit_m5.R`, `03_fit_m1.R` — **0 callers** in any `.R/.sh/.md` across the repo.
- `06_state_estimate_plots_v2.R`, `04_model_comparison_v2.R`, `03b_extract_loo_v2.R` — 0 callers.
- `07*` scripts NOT invoked by `08_refresh_may9_analysis_suite.sh` and not referenced elsewhere: `07_prior_sensitivity.R`, `07bi`, `07bj`, `07bk`, `07bl`, `07bm`, `07bn`, `07bo`, `07bp`, `07bq`, `07br`, `07bs`, `07bv`, `07bw` (the last two are untracked `??`). Some feed `07cz` indirectly (`07bn` reads `m1_stier_11_total_biomass`), others appear to be standalone screens — needs Adrian's confirmation before any are archived.
- `Code/legacy-2019/` entire directory + `Posteriors/` outputs — orphaned.

**- Dead code / TODO debt**
- **No** `TODO`/`FIXME`/`XXX`/`HACK` markers found in `Code/` (clean on that axis).
- Large commented regions in the older big scripts: `05_mcmc_diagnostics.R` (109/853 comment lines), `07_prior_sensitivity.R` (91/636), `04_portfolio_analysis.R` (90/558), `00_data_audit.R` (84/799). Mostly header/section banners and prose, not commented-out dead code — low concern, do not touch pre-talk.

**- Risk items — DO NOT TOUCH (talk-live, Royal Society Wed 20 May 2026)**
The following are load-bearing for the live deck. Exclude from ALL cleanup actions:
- `Code/07cz_deck_figure_reexport.R` (the deck builder; uncommitted modifications present)
- `Code/06g_reproduce_stier2020_figures_updated.R` (writes `stier2020_updated_fig3_pdo_effect.csv`, `stier2020_updated_fig4_fishing.csv` consumed by 07cz)
- `Code/06h_companion_and_supplement_figures_updated.R` (run together with 06g via `06_refresh_stier2020_updated_figure_suite.sh`)
- `Code/06_refresh_stier2020_updated_figure_suite.sh` (orchestrates 06g/06h)
- `Code/02c_integrate_hg_predator_repo_products.R` (writes predator consumption + pressure CSVs consumed by 07cz)
- `Code/03_fit_m1_stier_11.R` + `Code/03_fit_m1_stier_obs_hier.R` (produce `m1_stier_11_fit.rds` / `m1_stier_obs_hier_fit.rds` that 06g loads)
- `Code/07_m1_stier_11_population_driver_analysis.R`, `Code/07i_m1_stier_11_cryptic_collapse_screen.R`, `Code/07l_m1_stier_11_postclosure_recovery.R` (write `m1_stier_11_total_biomass_by_year.csv` consumed by 07cz)
- `Code/02f_extract_newer_dfo_public_pdfs.R` (feeds `dfo_newer_public_pdf_extract/` that 07cz reads)
- `Code/R/00_setup.R` is sourced by 07cz but lives in sibling-owned `R/` — flag only, do not act.

### Prioritized recommendations

All recommendations are **post-talk** (after Wed 20 May). Recommended action is a reversible move to `Code/archive/` (git `mv`, preserves history) — never deletion. Nothing below should be executed before the talk.

| Priority | Action | Exact path(s) | Risk (L/M/H) | Reversible? | Rationale |
|---|---|---|---|---|---|
| P1 | Archive superseded model-fit variants with 0 callers | `Code/03_fit_m1.R`, `Code/03_fit_m1_v2.R`, `Code/03_fit_m2.R`, `Code/03_fit_m2_v2.R`, `Code/03_fit_m3.R`, `Code/03_fit_m3_v2.R`, `Code/03_fit_m3_v4.R`, `Code/03_fit_m5.R`, `Code/03_fit_m5_v2.R` | L | Yes (git mv) | Zero callers anywhere; superseded by `*_stier_*` branch which is the promoted baseline per `03c` |
| P1 | Archive stale-tagged fit variants (referenced only by audit scripts that label them `stale_models`) | `Code/03_fit_m1_v3.R`, `Code/03_fit_m1_v4.R`, `Code/03_fit_m1_v5.R`, `Code/03_fit_m3_v3.R`, `Code/03_fit_m3_v5.R`, `Code/03_fit_m5_v3.R`, `Code/03_fit_m5_v5.R` | M | Yes (git mv) | Only `03c`/`03d` reference them, and those tag the rows stale; confirm Adrian wants the stale rows dropped from the audit tribble first |
| P1 | Archive superseded utility/version stubs | `Code/06_state_estimate_plots_v2.R`, `Code/04_model_comparison_v2.R`, `Code/03b_extract_loo_v2.R` | L | Yes (git mv) | 0 callers; superseded by `06_state_estimate_plots.R`, `04_compare_models_v3.R`, `03c/03d` |
| P1 | Archive stale v4/m3_v5-bound diagnostics | `Code/06b_m1_v4_total_biomass_trajectory.R`, `Code/06c_m1_v4_aggregate_fit_diagnostic.R`, `Code/04c_inspect_m1_v4_diagnostics.R`, `Code/04d_decide_next_after_m1_v4.R`, `Code/04e_recompute_m3_v5_surveyed_loo.R` | L | Yes (git mv) | Operate only on stale `m1_v4`/`m3_v5` objects; superseded by `*_stier_11_*` family |
| P2 | Archive stale `wait_for` glue tied to v3/v4/v5 | `Code/04_wait_for_m1_v4_and_refresh.sh`, `Code/04_wait_for_m1_v5_and_refresh.sh`, `Code/04_wait_for_v3_and_compare.sh` | L | Yes (git mv) | 0 references; point at stale fits no longer in the pipeline |
| P2 | Move 2019 legacy dir wholesale to archive | `Code/legacy-2019/` (8 `.R` + `Posteriors/`) | L | Yes (git mv) | No current script sources `legacy-2019/`; last touched 2026-04-01; self-contained 2019 codebase |
| P3 | Triage dated "status/snapshot/ledger/brief" memos with Adrian, then archive non-reusable ones | `Code/07av_may11_status_snapshot.R`, `Code/07q_may9_headline_findings_table.R`, `Code/07ax_stier_signal_persistence_summary.R`, `Code/07bi_model_decision_ledger.R`, `Code/07br_predator_talk_brief.R`, `Code/07bl_doherty_replication_execution_status.R`, `Code/07bm_doherty_public_extract_qc.R` | M | Yes (git mv) | Read as dated working memos, not pipeline; but several may be referenced by talk/docs (sibling-owned) — DO NOT archive without Adrian confirming each |
| P3 | Resolve naming-convention drift (documentation, not file moves) | stage `03_fit_*` family; `07aa…07cz` suffix space; duplicate-number prefixes (`01c`, `02c`, `04e`) | L | Yes | Add a `Code/README.md` mapping prefixes→stages + model lineage; rename only post-talk with Adrian to avoid breaking the `08_` orchestrator |
| P4 | Optionally relocate the 11 single-run `wait_for_*stier_*.sh` scaffolds after fits are final | `Code/04_wait_for_m1_stier_11_and_refresh.sh`, `_m1_stier_method_sensitivity_`, `_m1_stier_obs_hier_`, `_m2_stier_site_growth_*` (×2), `_m3_stier_distance_*` (×2), `04_wait_for_m3_then_fit_m1_stier_obs_hier.sh` | M | Yes (git mv) | Recent but throwaway one-shot scaffolds; keep until model fits are frozen for the paper |

### Open questions for Adrian

1. **Stale-model audit rows:** `03c_bayesian_fit_audit.R` / `03d` / `04_compare_models_v3.R` still enumerate `m1_v3/v4/v5`, `m3_v3/v5`, `m5_v3/v5` (tagged `stale_models`). If those `03_fit_m*_v*.R` scripts are archived, do you want the corresponding rows pruned from the audit tribbles, or kept as historical record? (Archiving the scripts without editing the audit is safe — the audit just won't find the `.rds`; it already filters stale.)
2. **`07*` non-orchestrated screens:** ~14 `07b*`/`07_prior_sensitivity.R` are not called by `08_refresh_may9_analysis_suite.sh`. Are these (a) deliberately standalone manuscript/talk screens to keep, (b) feeding `talk/`/`docs/` (sibling-owned, can't verify here), or (c) abandoned? Per-file confirmation needed before archiving any.
3. **Dated memo scripts (`*_may9_*`, `*_may11_*`, `*_status_snapshot`, `*_ledger`, `*_brief`):** keep as a dated decision log, or archive once their content is captured in the manuscript/docs?
4. **`legacy-2019/Posteriors/` outputs:** archive alongside the legacy scripts, or are those PDFs/CSV cited anywhere in the paper?
5. **Naming overhaul:** willing to adopt one convention for stage `03` (drop `_v*` once `_stier_*` is canonical) and add a `Code/README.md` stage map? Renames must be coordinated with `08_*.sh` and any sibling-owned `talk/`/`docs/` references.
6. **Uncommitted/untracked:** `07cz_deck_figure_reexport.R` is modified-uncommitted (talk-critical, do not touch); `07bv_heatwave_bottomup_scope.R` and `07bw_bloom_phenology_link_screen.R` are untracked `??` — intended to commit, or scratch?


---

## 4. docs/ documentation

### Inventory snapshot

- **36 `.md` files** in `docs/` (flat; no subdirectories — no `docs/archive/` exists yet). Plus 1 non-md: `aws-runtime-estimates.html` (4.8 KB, out of md scope, noted only).
- **Total size (md):** ~473 KB / **9,182 lines** across the 36 files.
- **Largest:** `HERRING_TALK_ASSETS.md` (54 KB — active SSOT), `current-population-driver-findings.md` (42 KB), `predator-analysis-integration-roadmap.md` (21 KB), `predator-data-plan.md` (21 KB), `aws-codex-model-farm-lessons.md` (21 KB), `analysis-plan.md` (20 KB).
- **Git status:** all tracked except `bottom-up-plankton-data-scope.md` (untracked, new 2026-05-18) and `HERRING_TALK_ASSETS.md` (modified, uncommitted).
- **Date span:** 2026-04-03 (`v5-covariate-rationale.md`, oldest) → 2026-05-18 (`HERRING_TALK_ASSETS.md`, `bottom-up-plankton-data-scope.md`).
- **Referenced by repo CLAUDE.md:** `HERRING_TALK_ASSETS.md`, `talk-model-claim-control-sheet.md`, `herring-non-recovery-hypotheses.md`, `predator-repo-integration-guide.md`, plus two **broken refs**: `docs/HG_PREDATION_SYNTHESIS.md` (does not exist) and `docs/DATA_DICTIONARY.md` (case mismatch — actual file is `data-dictionary.md`).
- **Referenced by README.md:** `collaborator-reading-guide`, `theory-data-model-integration`, `stan-model-map`, `talk-model-claim-control-sheet`, `analysis-plan`, `current-population-driver-findings`, `may-9-analysis-decision-summary`, `may-9-analysis-output-index`, `literature-parameter-roadmap`, `predator-repo-integration-guide`, `cloud-model-running-setup`, `full-analysis-model-farm-scope`, `aws-codex-model-farm-lessons`, `doherty-style-hg-gap-table`.

### Issues

**Redundant / overlapping (grouped):**

- **G1 — Talk-readiness / sprint-plan stack:** `saturday-talk-readiness-2026-05-16.md`, `monday-talk-sprint-plan.md`, `current-analysis-quickstart.md`. All three are "here is the current state, read these first, build the talk" handoffs at successive dates (May 11 → May 16 → May 16). `current-analysis-quickstart.md` (May 16) is the newest and most general; the other two are dated checkpoints. **Caveat:** `HERRING_TALK_ASSETS.md` cites `saturday-talk-readiness` as the *authoritative 14-figure order* (FIG-ORDER) and `monday-talk-sprint-plan` as the *must-have figure shortlist* (FIG-MUST) — they are live upstream inputs, not free to archive.
- **G2 — May-9 analysis decision/index pair + scope notes:** `may-9-analysis-decision-summary.md`, `may-9-analysis-output-index.md`, `high-quality-analysis-scope.md`, `analysis-issues-and-fixes.md`. All describe the May 8–12 baseline-decision state. `current-population-driver-findings.md` is explicitly the "current full synthesis" that supersedes the decision summary's findings, but the may-9 pair is still cited by `HERRING_TALK_ASSETS.md` (TP-05) and README. `analysis-issues-and-fixes.md` self-labels as "historical diagnostic memo … not the current source of truth."
- **G3 — Model-version comparison notes (clearly stale):** `v3-model-comparison-results.md` (Apr 4; self-states "now superseded for practical reporting by `m1_stier_11`"), `v5-covariate-rationale.md` (Apr 3, oldest file, pre-`m1_stier_11`), `parameter-comparison-stier2020.md` (May 8). These describe abandoned `v3`/`v5` lineages; the promoted baseline is `m1_stier_11`.
- **G4 — Decision guides for held branches:** `m2-site-growth-decision-guide.md`, `m3-distance-decision-guide.md`, `okamoto-deep-dive.md`. Single-branch May-9 decision memos; both m2/m3 are "held, not promoted." Useful as promotion-gate records, but historical.
- **G5 — Predator integration trio:** `predator-data-plan.md`, `predator-analysis-integration-roadmap.md`, `predator-repo-integration-guide.md`. Overlapping scope (all point at the sibling `pacific-herring-predators` repo). `predator-repo-integration-guide.md` (May 16) is the cleanest "source of truth" framing and is the CLAUDE.md-referenced one; `predator-data-plan.md` is the older (May 9) planning doc.
- **G6 — Doherty-style HG quartet:** `doherty-style-hg-data-acquisition.md`, `doherty-style-hg-gap-table.md`, `doherty-style-hg-replication-status.md`, `doherty-style-hg-source-provenance.md` + `dfo-hg-biological-input-request-packet.md` + `wcvi-predation-replication-bridge.md`. Six docs on the same Doherty WCVI-replication thread. `doherty-style-hg-source-provenance.md` self-declares "canonical source map"; `-data-acquisition` is the older plan now executed by `-replication-status`. Strong consolidation candidate but tightly cross-linked and recent (all May 15–17).
- **G7 — Cloud/AWS model-farm trio:** `cloud-model-running-setup.md`, `full-analysis-model-farm-scope.md`, `aws-codex-model-farm-lessons.md`. Overlapping infra/runtime guidance; all README-referenced. `aws-codex-model-farm-lessons.md` is the maintained implementation log ("keep this updated"); the other two are setup/scope notes.

**Stale / superseded / historical:**

- `v5-covariate-rationale.md` (Apr 3) — pre-dates `m1_stier_11` baseline; describes `v5` candidates never promoted.
- `v3-model-comparison-results.md` (Apr 4) — self-states superseded by `m1_stier_11`.
- `analysis-issues-and-fixes.md` (May 8) — self-labeled "historical diagnostic memo … references legacy `Code/` scripts … not the current source of truth."
- `parameter-comparison-stier2020.md` (May 8) — point-in-time legacy-vs-Stan parameter table.
- `analysis-plan.md` (May 12) — self-states "mixes early planning notes with implementation"; redirects readers to `theory-data-model-integration.md` (the live SSOT).
- `may-9-*` pair, `monday-talk-sprint-plan.md`, `saturday-talk-readiness-2026-05-16.md` — dated checkpoints now historical *but still actively cited by HERRING_TALK_ASSETS.md* (see Risk).

**Contradictions:**

- No hard scientific contradictions found — every analysis/talk doc consistently affirms `m1_stier_11` as the promoted baseline with ambiguous zeros / two-era q / 11 sections. The control-sheet discipline ("if a phrase conflicts with this sheet, revise the phrase") has kept them aligned.
- **Reference-integrity contradiction:** repo `CLAUDE.md` points to `docs/HG_PREDATION_SYNTHESIS.md` and `docs/DATA_DICTIONARY.md`, neither of which exists at those paths (the second is a filename-case mismatch with `docs/data-dictionary.md`). This is a navigation defect, not a content conflict — flag for fix, not consolidation.

**Naming inconsistencies:**

- Case style is mixed: 34 kebab-case lowercase files vs `HERRING_TALK_ASSETS.md` (SCREAMING_SNAKE). CLAUDE.md assumes a non-existent `DATA_DICTIONARY.md` — suggests the screaming-snake convention was once intended for "canonical" docs but not applied to `data-dictionary.md`.
- Only one doc carries a date in its filename (`saturday-talk-readiness-2026-05-16.md`); the parallel `monday-talk-sprint-plan.md` and `may-9-analysis-*` encode the date in prose only — inconsistent dating convention for what are all dated checkpoints.
- `doherty-style-hg-*` (4 files) vs `dfo-hg-biological-input-request-packet.md` vs `wcvi-predation-replication-bridge.md` — same workstream, three different prefixes.

**Risk items (active sources of truth — DO NOT consolidate/delete):**

- `HERRING_TALK_ASSETS.md` — explicit single-source-of-truth for the live Royal Society talk (Wed 20 May 2026); CLAUDE.md entry point. **DO NOT TOUCH.**
- `talk-model-claim-control-sheet.md` — active talk-facing model-claim contract; CLAUDE.md + README referenced. **DO NOT TOUCH.**
- `saturday-talk-readiness-2026-05-16.md` — *looks* archivable but is cited by `HERRING_TALK_ASSETS.md` as the authoritative 14-figure order (FIG-ORDER). **DO NOT archive before the talk.**
- `monday-talk-sprint-plan.md` — cited by `HERRING_TALK_ASSETS.md` as the must-have figure shortlist (FIG-MUST). **DO NOT archive before the talk.**
- `may-9-analysis-decision-summary.md`, `may-9-analysis-output-index.md` — cited by `HERRING_TALK_ASSETS.md` (TP-05) and README. **DO NOT archive before the talk.**
- `herring-non-recovery-hypotheses.md`, `predator-repo-integration-guide.md` — CLAUDE.md referenced (active).
- `theory-data-model-integration.md`, `data-dictionary.md`, `stan-model-map.md`, `collaborator-reading-guide.md`, `current-population-driver-findings.md`, `literature-parameter-roadmap.md` — README-referenced live reading-path / SSOT docs.

### Proposed consolidation map

> All actions deferred to **after the talk (post-20 May 2026)**. Archive = move into a new `docs/archive/` (reversible), never delete. No consolidation that touches a HERRING_TALK_ASSETS.md-cited or CLAUDE/README-cited file before the talk.

| Keep (canonical) | Merge in | Archive | Notes |
|---|---|---|---|
| `theory-data-model-integration.md` (live SSOT) | — | `analysis-plan.md` (post-talk) | analysis-plan self-redirects here; archive once nothing links it. README link must be repointed first. |
| `current-population-driver-findings.md` (current synthesis) | — | `may-9-analysis-decision-summary.md`, `may-9-analysis-output-index.md`, `high-quality-analysis-scope.md`, `analysis-issues-and-fixes.md` (all post-talk) | Findings superseded by current synthesis; but may-9 pair cited by talk assets — archive only after talk + repoint README. |
| `current-analysis-quickstart.md` (newest read-first) | — | `saturday-talk-readiness-2026-05-16.md`, `monday-talk-sprint-plan.md` (post-talk only) | Both are live talk inputs NOW. Post-talk, fold any durable content into quickstart, archive the dated checkpoints. |
| `predator-repo-integration-guide.md` (CLAUDE-ref'd SoT) | key planning content from `predator-data-plan.md`, `predator-analysis-integration-roadmap.md` | `predator-data-plan.md`, `predator-analysis-integration-roadmap.md` (post-talk) | Guide is the cleanest SoT framing; other two are older planning layers. |
| `doherty-style-hg-source-provenance.md` (self-declared canonical) | `doherty-style-hg-data-acquisition.md`, `doherty-style-hg-replication-status.md`, `doherty-style-hg-gap-table.md` | the three merged-in files (post-talk) | gap-table is README-ref'd — repoint README before archiving. Keep `dfo-hg-biological-input-request-packet.md` separate (it is an outbound request artifact). |
| `aws-codex-model-farm-lessons.md` (maintained log) | — | `cloud-model-running-setup.md`, `full-analysis-model-farm-scope.md` (optional, low value) | All README-ref'd; low churn — lowest-priority consolidation, arguably leave as-is. |
| — | — | `v5-covariate-rationale.md`, `v3-model-comparison-results.md`, `parameter-comparison-stier2020.md` | Stale `v3/v5` lineage; **safest, highest-value archive** — not referenced by CLAUDE.md or HERRING_TALK_ASSETS.md, self-declared superseded. |
| `m2-site-growth-decision-guide.md`, `m3-distance-decision-guide.md`, `okamoto-deep-dive.md` (keep) | — | — | Keep as promotion-gate / scientific records; do not merge — they encode reusable rerun gates. |
| `HERRING_TALK_ASSETS.md`, `talk-model-claim-control-sheet.md`, `herring-non-recovery-hypotheses.md`, `data-dictionary.md`, `stan-model-map.md`, `collaborator-reading-guide.md`, `literature-parameter-roadmap.md`, `bottom-up-plankton-data-scope.md` | — | — | Active / referenced — do not consolidate. |

### Prioritized recommendations

| Priority | Action | Exact path(s) | Risk (L/M/H) | Reversible? | Rationale |
|---|---|---|---|---|---|
| P0 | Fix broken CLAUDE.md doc refs (point to existing files / create stub) — **content-author decision, not an auto-fix** | `CLAUDE.md` → `docs/HG_PREDATION_SYNTHESIS.md` (missing), `docs/DATA_DICTIONARY.md` (→ `docs/data-dictionary.md`) | L | Yes | Navigation defect: CLAUDE.md sends sessions to non-existent docs during a live talk window. Flag to Adrian; do not edit (read-only audit). |
| P0 | Freeze all docs/ consolidation until after talk (Wed 20 May 2026) | entire `docs/` | — | — | Talk is live; HERRING_TALK_ASSETS.md depends on dated checkpoints. |
| P1 | Post-talk: create `docs/archive/`, move stale `v3/v5` lineage | `docs/v5-covariate-rationale.md`, `docs/v3-model-comparison-results.md`, `docs/parameter-comparison-stier2020.md` | L | Yes (git mv) | Self-declared superseded; not referenced by CLAUDE.md/README/HERRING_TALK_ASSETS.md. Highest value / lowest risk. |
| P2 | Post-talk: archive may-9 + dated talk checkpoints **after** repointing README and HERRING_TALK_ASSETS.md links | `docs/may-9-analysis-decision-summary.md`, `docs/may-9-analysis-output-index.md`, `docs/high-quality-analysis-scope.md`, `docs/analysis-issues-and-fixes.md`, `docs/saturday-talk-readiness-2026-05-16.md`, `docs/monday-talk-sprint-plan.md` | M | Yes (git mv) | Cited by README + HERRING_TALK_ASSETS.md — links must be updated first or navigation breaks. |
| P2 | Post-talk: consolidate Doherty-style quartet into `doherty-style-hg-source-provenance.md`; repoint README's `doherty-style-hg-gap-table.md` link | `docs/doherty-style-hg-data-acquisition.md`, `docs/doherty-style-hg-replication-status.md`, `docs/doherty-style-hg-gap-table.md` | M | Yes | Six near-overlapping docs on one thread; canonical doc self-declared. Recent + cross-linked → moderate risk. |
| P3 | Post-talk: fold predator-data-plan / -integration-roadmap into `predator-repo-integration-guide.md`, archive originals | `docs/predator-data-plan.md`, `docs/predator-analysis-integration-roadmap.md` | M | Yes | Reduces 3→1 SoT for predator integration; guide is CLAUDE.md-ref'd. |
| P3 | Adopt one naming convention (kebab-case) for non-canonical docs; reserve SCREAMING_SNAKE for SSOT only; date-stamp all checkpoint docs consistently | `docs/*` | L | Yes | Removes the convention ambiguity that caused the `DATA_DICTIONARY.md` broken ref. |
| P4 | Decide fate of `bottom-up-plankton-data-scope.md` (untracked) — commit or leave | `docs/bottom-up-plankton-data-scope.md` | L | Yes | New 2026-05-18, untracked; not yet linked anywhere. Owner decision. |

### Open questions for Adrian

1. **Broken CLAUDE.md links:** Does `HG_PREDATION_SYNTHESIS.md` exist elsewhere (sibling repo / Drive) and should be created here, or should the CLAUDE.md reference be removed? And should `DATA_DICTIONARY.md` ref be repointed to `data-dictionary.md`, or do you want the file renamed to the screaming-snake convention?
2. **Talk-input dated checkpoints:** After the talk, are `saturday-talk-readiness-2026-05-16.md` and `monday-talk-sprint-plan.md` worth keeping as historical record, or fully foldable into `current-analysis-quickstart.md`? (HERRING_TALK_ASSETS.md will need its FIG-ORDER/FIG-MUST pointers updated either way.)
3. **`bottom-up-plankton-data-scope.md`** is untracked — intentional WIP, or should it be committed and linked from the analysis reading path?
4. **Doherty-style quartet:** Is `doherty-style-hg-source-provenance.md` truly the survivor, or do you want `-gap-table` kept standalone as the slide/manuscript guardrail it claims to be (README links it directly)?
5. **Naming convention:** Confirm you want SCREAMING_SNAKE reserved only for `HERRING_TALK_ASSETS.md`-class SSOT docs and everything else kebab-case, so future broken refs are avoided.
6. **Cloud/AWS trio (G7):** Low churn, all README-linked — leave as three, or consolidate into the maintained `aws-codex-model-farm-lessons.md`? (Lowest-value action; default recommendation is leave as-is.)


---

## 5. Output/, Literature/, cloud/ — heavy & generated artifacts

### Inventory snapshot (sizes!)

Repo total: **41 GB**. My domain holds **~25.2 GB (61%)** of it.

| Domain | Size | Tracked files | Tracked size | Untracked bulk |
|---|---|---|---|---|
| `Output/` | **13 GB** | 6 files | ~1.0 MB | `posteriors/` 13 GB |
| `cloud/` | **12 GB** | 26 files | ~75 KB (scripts) | `aws_results/` 12 GB |
| `Literature/` | **174 MB** | 20 PDFs | **45 MB** | 52 untracked PDFs (~129 MB) |

Critical context: **`.git` is only 182 MB and history is clean** — none of the multi-GB `.rds` files are or ever were committed (`git rev-list --disk-usage` = 182 MiB, in-pack 0). **No history rewrite needed anywhere in my domain.** The 25 GB is entirely untracked working-tree bloat already covered by `.gitignore`. The real disk problem is local-only; the real *git* problem is the 45 MB of tracked Literature PDFs that contradict the repo's own ignore policy.

Breakdown of the 25 GB:
- `Output/posteriors/` — 13 GB, 44 `.rds` brms/Stan fit objects (17 files >340 MB; largest `fit_m5_v5.rds` 918 MB). **Already gitignored** (`Output/posteriors/*.rds`).
- `cloud/aws_results/` — 12 GB, 103 files. **Already gitignored** (`cloud/aws_results/`). This is a near-total **duplicate** of `Output/posteriors/`: each AWS Batch job dir holds the *same* fit twice — `<job>/Output/posteriors/fit_X.rds` AND `<job>/Data/processed/X_fit.rds` — and those mirror the canonical copies in `Output/posteriors/`. Verified byte-identical size: `fit_m5_v5.rds` = 962,160,997 bytes in both `cloud/aws_results/.../m5_v5/Output/posteriors/` and `Output/posteriors/`. ~21 fit RDS files stored 2–3× over.
- `Output/diagnostics/` — 52 MB, 400 files (262 CSV, 83 MD, 40 PDF). Gitignored. `dfo_assessment_public_sources/` (38 MB of downloaded DFO PDFs) dominates.
- `Output/figures/` — 40 MB, ~208 PNG/PDF. Mostly gitignored; 3 deck PNGs force-tracked.

### Biggest space offenders

| Path | Size | Git-tracked? | Regenerable? |
|---|---|---|---|
| `Output/posteriors/` (44 .rds) | **13 GB** | No (gitignored) | Yes — re-run Stan/brms (slow/$, but reproducible) |
| `cloud/aws_results/` (esp. `2026-05-13/jobs/`) | **12 GB** | No (gitignored) | Yes — **redundant**, duplicates `Output/posteriors/` |
| `cloud/aws_results/2026-05-13/jobs/` | 11 GB | No | Yes — staged AWS pull, already promoted |
| `cloud/aws_results/2026-05-14-predator-demand-total/` | 1.7 GB | No | Yes |
| `Output/diagnostics/dfo_assessment_public_sources/` | 38 MB | No (gitignored) | Yes — re-downloadable public DFO PDFs |
| Tracked Literature PDFs (20) | **45 MB in git** | **Yes (force-added)** | No — but stored on Google Drive |
| `Literature/predators/` (35 files) | 65 MB | No | No — external lit |

### Issues

**Redundant / duplicate**
- `cloud/aws_results/` (12 GB) is ~95% redundant with `Output/posteriors/` (13 GB). Within each job, the fit is stored **twice** (`Output/posteriors/` + `Data/processed/`). Once results are promoted to canonical `Output/posteriors/` (a `cloud/promote_cloud_results.sh` exists for this), the entire `cloud/aws_results/` tree is a stale download cache. **This is the single biggest reclaimable chunk: ~12 GB of pure duplication.**
- `Output/diagnostics/posterior_predictive_by_year.csv` vs `..._by_year_v3.csv`; `posterior_predictive_summary_v3.csv`, `model_comparison_v3.csv`, `bayesian_fit_audit_v3.csv` — `_v3` suffixes alongside unversioned originals (superseded copies kept in place).
- Figure PNG+PDF pairs duplicated for ~150 figures (intentional dual-format export, but doubles `Output/figures/` footprint).

**Stale / superseded**
- `Output/figures/v2/` (2 files, `m1_v2_*`) and `Output/figures/m1_v4_*` — old model-version renders superseded by current `m1_stier_*` / `m5_*` outputs.
- `Output/diagnostics/` dated AWS status artifacts: `aws_batch_2026-05-13_round1_ondemand.{json,csv}`, `..._round1_spot.{json,csv}`, `aws_batch_2026-05-14_predator_demand_total.{json,csv}`, `aws_batch_2026-05-16_doherty_proxy_lowvuln_smoke.{json,csv}` — point-in-time run logs, superseded after promotion.
- `Output/diagnostics/m1_v4_next_action.txt`, `m1_v4_next_step_decision.md` — stale planning notes for an old model version.
- `cloud/aws_results/2026-05-13/` — oldest staged pull; if promoted, fully stale.

**Should be git-ignored / externalized (with size)**
- `Output/posteriors/` (13 GB) — **already gitignored**, never in history. Good. No git action; disk-only.
- `cloud/aws_results/` (12 GB) — **already gitignored**, never in history. Good.
- `Output/diagnostics/` (52 MB), `Output/figures/` (40 MB), `Output/*.csv/*.pdf/*.png` — **already gitignored**. Good.
- **`Literature/` tracked PDFs (45 MB / 20 files)** — the root `.gitignore` explicitly says `Literature/` with `!Literature/.gitkeep` and the comment "too large for git, stored on Google Drive", yet 20 PDFs were **force-added** and ARE tracked (e.g. `Stier_et_al_2014_SciReports...pdf` 5.9 MB, `Shelton_et_al_2014...pdf` 5.9 MB, `Ware_Schweigert_DFO...pdf` 4.4 MB). This is a policy contradiction and the only meaningful git-history concern in my domain (45 MB in pack, recoverable only via history rewrite — **flag, defer**). Going forward they should be untracked; the 52 untracked PDFs (incl. all 35 in `Literature/predators/`) correctly follow policy.

**Naming / organization**
- `Output/figures/` mixes manuscript figures, exploratory "screen"/"triage"/"audit"/"plan" figures (`*_screen.pdf`, `driver_model_triage`, `doherty_proxy_parameter_plan`), and model-version renders all in one flat 156-file top level — no `exploratory/` vs `manuscript/` separation. `lecture/deck/` is well-isolated. `stier2020_updated/{companions,supplement}/` is clean.
- `Output/tables/` and `Output/presentations/` are empty (0 B) — dead directory stubs.
- `Output/diagnostics/` is a 400-file flat dump mixing CSV data products, MD decision notes, run logs, and downloaded DFO PDF corpora — no subfolder discipline except `dfo_*` extract dirs.
- `cloud/aws_results/` inconsistent date-dir naming: bare `2026-05-13` vs descriptive `2026-05-14-predator-demand-total`, `2026-05-16-doherty-proxy-lowvuln`.

**Risk items — DO NOT remove**
- `Output/figures/lecture/deck/` (3.1 MB, 8 PNGs) — **TALK-CRITICAL for Royal Society talk Wed 20 May 2026**. 3 are git-tracked (`s06_climate_pdo.png`, `s08_realized_growth.png`, `s09_synchrony.png`); 5 untracked but regenerated 2026-05-18 (today). **Do not remove, do not gitignore the tracked three.**
- `Output/posteriors/*.rds` — regenerable in principle but represent days of compute / AWS cost. "Regenerable" ≠ "cheap." Treat as precious working artifacts; safe to keep gitignored, do NOT delete from working tree without Adrian's sign-off.
- Tracked Literature PDFs — precious (source lit) and non-regenerable from scripts; on Google Drive but verify before any history action.

### Prioritized recommendations

| Priority | Action | Exact path(s) | Risk (L/M/H) | Reversible? | Rationale |
|---|---|---|---|---|---|
| P1 | Reclaim ~12 GB: delete the duplicate AWS staging cache **after confirming promotion to `Output/posteriors/`** | `cloud/aws_results/2026-05-13/jobs/`, `cloud/aws_results/2026-05-14-predator-demand-total/` | M | Yes (re-pull from S3 via `cloud/sync_model_farm_results.sh`) | Byte-identical duplicate of `Output/posteriors/`; not in git; largest single reclaim. **Adrian confirms promotion first.** |
| P1 | Keep `.gitignore` rules for `Output/posteriors/`, `cloud/aws_results/`, `Output/diagnostics/`, `Output/figures/` — already correct, **no change needed** | (gitignore) | L | Yes | Bloat is already untracked & not in history; do not "fix" what works |
| P2 | Resolve Literature tracking contradiction: either (a) keep 20 PDFs intentionally tracked and **remove the blanket `Literature/` ignore**, or (b) untrack them (`git rm --cached`) to honor stated Drive-only policy | `Literature/*.pdf` (20 tracked) | M | Yes (cached rm is reversible; files stay on disk) | Policy says Drive-only but 20 are force-added — pick one. Synthesizer should reconcile globally. |
| P2 | Defer/flag: 45 MB of Literature PDFs already in git **pack history** — full removal needs `git filter-repo` history rewrite | `Literature/*.pdf` history | **H** | Hard | Only if repo size on clone matters; coordinate with all collaborators. **Do not auto-do.** |
| P3 | Remove empty dead stub dirs | `Output/tables/`, `Output/presentations/` | L | Yes | 0 B, no purpose |
| P3 | Archive/clear stale dated run logs after they're synthesized into canonical diagnostics | `Output/diagnostics/aws_batch_2026-05-1*.{json,csv}`, `Output/diagnostics/m1_v4_next_*.{txt,md}`, `Output/diagnostics/*_v3.csv` | L | Yes (regenerable / git-ignored anyway) | Point-in-time superseded artifacts cluttering 400-file dir |
| P3 | Reorganize `Output/figures/` into `manuscript/`, `exploratory/`, keep `lecture/deck/` as-is | `Output/figures/*` (flat 156 files) | M | Yes | Discoverability; do AFTER Royal Society talk (don't disturb deck path now) |
| P4 | Add `cloud/aws_results/**/Data/processed/*.rds` note — even within cloud results the fit is stored twice per job | `cloud/aws_results/**/Data/processed/` | L | Yes | Documents the 2× intra-job duplication if cloud cache is ever kept |

### Open questions for Adrian
1. Has `cloud/aws_results/2026-05-13/` (and `-14`, `-16`) been **promoted** into canonical `Output/posteriors/` via `promote_cloud_results.sh`? If yes → ~12 GB safe to delete locally (re-pullable from S3).
2. Are the 20 tracked `Literature/*.pdf` files **intentionally** in git (so the repo is self-contained per your "projects must be self-contained" memory note), or an accident that should be untracked to honor the Drive-only `.gitignore` comment? This decides P2(a) vs P2(b).
3. Do you want the 45 MB of Literature PDFs scrubbed from git **history** (filter-repo, High risk, breaks collaborator clones), or is leaving them in history acceptable since `.git` is only 182 MB?
4. Of the 44 `Output/posteriors/*.rds`, are old-version fits (`fit_m1_v3.rds`, `fit_m1_v4.rds`, `fit_m1v2_*`, `fit_m5_v3.rds`) superseded by `*_stier_*` runs and deletable, or kept for model-comparison/reproducibility?
5. Post-talk, OK to flatten/reorganize `Output/figures/` into manuscript vs exploratory subfolders?


---

## 6. analysis/04_talks/2026-royalsociety/ talk workspace

### Inventory snapshot

Workspace root `analysis/04_talks/2026-royalsociety/` = 390M total. Audit domain `Talk_Materials/` = 293M (the bulk). Royal Society talk is Wed 20 May 2026 — this workspace builds the in-flight deck. Audited READ-ONLY.

Top-level `Talk_Materials/` (38 entries):
- **Deliverables (large, current):** `Herring_RoyalSociety_Stier_2026_clean.pptx` (56.9M, 05-18 16:28 — newest), `Herring_RoyalSociety_Stier_2026.pptx` (55.8M, 05-18 16:20 — older sibling), `Herring_RoyalSociety_Stier_2026_clean.pdf` (16.7M, 05-18 16:29 — newest export). Two single-slide test exports: `S5_only.pptx` (339K), `DFO_SpawningBiomass_only.pptx` (351K).
- `deck_build/` = 121M (incl. `node_modules/` 7.6M, `slides_html/` 50M, `photos/` 55M, `dfo_src/` 1.2M, `Herring_RoyalSociety_Stier_2026.pdf` 6.1M stale intermediate, 18 QA screenshot JPGs ~1.1M total).
- `deck_assets/` = 45M (15 staged PNGs + `_originals/` holding 4 pre-restage copies).
- `figs/` = 1.7M (provenance source figures — git-tracked, in scope only as reference).
- Two empty dirs: `deck_source/`, `blocker_resolution/`.
- 10 root-level HTML files (4 schematic slide sources still consumed by `render_deck.sh`; 3 talk_architecture_*.html; build1_spine.html; herring_haida_gwaii_timeline.html; herring_decoupling_figure.html).
- Outline/plan triplet: `talk_outline_v1.md` (20.8K, 05-17 07:55), `talk_outline_v2.md` (9.2K, 05-17 11:21), `talk_production_plan.md` (29.5K, 05-17 17:42, 20-slide), plus `deck_build_decision.md`.
- Sync docs: `slide_asset_map.md`, `deck_design_system.md`, and (referenced) repo-root `docs/HERRING_TALK_ASSETS.md` (54K, 05-18 16:22).

Builder situation: `deck_build/build_pptx_native.js` (18K, 05-18 16:28 — newest file in deck_build; the **current/authoritative** native-PowerPoint builder, embeds R-figure PNGs + photos, "Cleaned 2026-05-18"). `deck_build/build_pptx.js` (8.7K, 05-18 15:08 — **legacy** "one full-bleed image per slide" builder). Both read `../deck_assets`. `slide_asset_map.md` explicitly names `build_pptx_native.js` as the embed path (S7/S8 rows). Firewall: builders + `render_deck.sh` only copy **from** `Output/figures/lecture/deck/` **into** `deck_assets/` — no writes back into Output/Data/Code. **No firewall violation found.**

### Issues

- **Redundant / duplicate (legacy vs current builders; staged-asset duplication)**
  - `deck_build/build_pptx.js` (legacy full-bleed builder) is superseded by `build_pptx_native.js` (current). Both live side-by-side; only the native one is referenced by `slide_asset_map.md`. Legacy is a divergence/foot-gun risk if invoked by mistake, but harmless while untouched. DEFER (do not delete pre-talk — it is the documented fallback render path in `deck_build_decision.md`).
  - Staged-copy duplication: `Output/figures/lecture/deck/*.png` (canonical R exports, 3.1M) are copied into `deck_assets/*.png` (45M) by `render_deck.sh`. This is intended pipeline staging (firewall-safe direction), not accidental duplication — but it is the source of disk bloat and a staleness vector. DEFER.
  - `deck_assets/_originals/` holds 4 pre-restage PNG copies (06/08/09/10, 05-18 16:23) — a manual safety backup made hours before the talk. Keep until after talk (it is a rollback aid, not clutter to remove now).
  - `slides_html/photos/` (50M) duplicates large source images already in `deck_build/photos/` (55M) — e.g. `s01_title.png` 18.5M appears in both. Redundant copy, but consumed by `render_deck.sh` `overlay()` calls. DEFER.
  - Two near-identical big decks: `Herring_RoyalSociety_Stier_2026.pptx` (55.8M, older) vs `Herring_RoyalSociety_Stier_2026_clean.pptx` (56.9M, newer). The `_clean` pair (pptx+pdf, 05-18 16:28/16:29) is the latest. The non-`_clean` 55.8M pptx is an earlier render — almost certainly stale, but DO NOT remove until Adrian confirms which is the final submission file.

- **Superseded (HTML schematics replaced by R figures)**
  - `s5_two_collapses.html`, `s7_two_scales.html`: per `slide_asset_map.md`, S7 is now the real-data R figure (`s07_two_scales.png` → `deck_assets/07_two_scales.png`), "replaces old schematic." S5 similarly moved to a built timeline. **However `render_deck.sh` still `schem`-renders `s5_two_collapses.html` → `05_two_collapses.png` and `s7_two_scales.html` → `07_two_scales.png`.** This is a live inconsistency: the script regenerates the superseded schematic over the staged R figure. Note only — do NOT edit `render_deck.sh` or delete these HTML files before the talk; the deck currently builds against this script and the .pptx already exists.
  - `s11_triple_bottom_line.html`, `s13_takeaways.html`, `herring_decoupling_figure.html` (S12): still actively consumed by `render_deck.sh` as schematic slide sources — NOT superseded. Keep.
  - `build1_spine.html` (12.4K): early shared visual artifact referenced by `deck_build_decision.md` for slides 2/12/20. Possibly superseded by `herring_decoupling_figure.html` per `slide_asset_map.md` note 2. Ambiguous — DEFER, ask Adrian.

- **Stale renders / screenshot clutter**
  - `deck_build/Herring_RoyalSociety_Stier_2026.pdf` (6.1M, 05-18 13:57): an old intermediate PDF render inside the build dir, predating the current root-level `_clean.pdf` (05-18 16:29). Stale build artifact. Low-value but DEFER (zero risk to leave; removing pre-talk has no upside and nonzero distraction risk).
  - 18 QA screenshot JPGs in `deck_build/` (`qa-01..15.jpg`, `q-04/05.jpg`, `qx-04.jpg`, ~1.1M total, all 05-18 13:13–13:57): visual-QA scratch images from earlier deck iterations — classic `/tmp`-like clutter, not consumed by any build script (grep of builders/render_deck.sh shows no reference). This is the one genuinely safe-now candidate, but see Risk items — recommend still deferring given 2-day proximity unless Adrian wants the tidy.
  - `deck_build/dfo_src/` (1.2M): digitization working set (page scan, crop, overlay, CSV) for the DFO Fig8d figure. One-time provenance artifact; the digitized CSV may still be referenced by provenance docs. DEFER.

- **Doc-sync inconsistencies (note only — do NOT edit mid-talk)**
  - **Canonical-plan conflict (already self-flagged in `slide_asset_map.md` "Open decisions" #1):** the asset map follows a **14-slide** architecture; repo-root `docs/HERRING_TALK_ASSETS.md` still calls the **20-slide** `talk_production_plan.md` canonical; `deck_build_decision.md` (05-17) also says "fresh 20-slide deck." Three documents disagree on slide count / canonical plan. The 14-slide spine drops the social cognitive-map beat (Stier 2016) that S15/S19 provenance work targeted.
  - `talk_outline_v1.md` (20K), `talk_outline_v2.md` (9K), `talk_production_plan.md` (29K) overlap heavily; v2 is newer than v1 but `talk_architecture_1/2/3_*.html` (05-18, newest) appear to be the operative artifacts the .pptx was built from. No file states "canonical/superseded" cleanly across the set.
  - `slide_asset_map.md` rows still carry `🔨 build` / `🟡⚠️` status for S5/S6 while the .pptx and `deck_assets/` already contain finished S5/S6 PNGs — map status lags the actual built deck.
  - Note only. These are intentionally left for post-talk reconciliation; editing sync docs now risks confusing the in-flight build.

- **Naming / organization**
  - Empty dirs `deck_source/` and `blocker_resolution/` (note: a sibling file `blocker_resolution_2026-05-17.md` exists — the empty dir is a naming collision/leftover).
  - `deck_build/` mixes builders, node_modules, HTML sources, photos, QA screenshots, a stale PDF, and a digitization sandbox in one flat directory — hard to reason about but functionally fine; reorganizing now is out of scope and risky.
  - Single-slide test exports (`S5_only.pptx`, `DFO_SpawningBiomass_only.pptx`) sit beside the 56M deliverables with no `_test`/`scratch` prefix.

### Risk items — DO NOT TOUCH until after 20 May 2026

Explicitly hands-off for the next 2 days (talk is Wed 20 May):

- `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/build_pptx_native.js` — current/authoritative builder. Do not change, move, or "clean."
- `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/build_pptx.js` — legacy, but the documented fallback render path; leave in place.
- `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_assets/` (all 15 PNGs **and** `_originals/`) — live deck inputs + rollback backup.
- `analysis/04_talks/2026-royalsociety/Talk_Materials/Herring_RoyalSociety_Stier_2026_clean.pptx` (56.9M), `Herring_RoyalSociety_Stier_2026_clean.pdf` (16.7M), and `Herring_RoyalSociety_Stier_2026.pptx` (55.8M) — final + sibling deliverables; do not delete/dedupe until Adrian confirms the submission file.
- Sync docs: `slide_asset_map.md`, `deck_design_system.md`, repo-root `docs/HERRING_TALK_ASSETS.md` — do not edit mid-talk (inconsistencies noted only).
- `render_deck.sh` and all HTML schematic sources it consumes (`s5_two_collapses.html`, `s7_two_scales.html`, `s11_triple_bottom_line.html`, `s13_takeaways.html`, `herring_decoupling_figure.html`, `slides_html/*.html`, `slides_html/photos/`, `deck_build/photos/`) — the deck currently builds against this exact chain.
- Do NOT run any deck build.

### Prioritized recommendations

**Safe now (pre-talk):** essentially nothing should be modified. The only defensible safe-now action is reviewing (not removing) the obviously stale QA screenshots; even that is recommended as Defer given the 2-day window and zero upside to touching this workspace now.

**Defer until after 20 May 2026:** all dedup, deletion, doc reconciliation, and reorganization.

| Priority | Window | Action | Exact path(s) | Risk (L/M/H) | Reversible? | Rationale |
|---|---|---|---|---|---|---|
| P3 | Safe now (pre-talk) — optional, low value | Visually confirm these are unreferenced QA scratch JPGs; recommend STILL deferring removal | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/qa-01.jpg`…`qa-15.jpg`, `q-04.jpg`, `q-05.jpg`, `qx-04.jpg` (18 files, ~1.1M) | L | Yes (would be in trash; regenerable by re-screenshotting) | Not referenced by any builder/`render_deck.sh`; pure scratch. But 2 days out, no disk pressure → no reason to act now. |
| P2 | Defer until after 20 May | Delete stale intermediate PDF render inside build dir | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/Herring_RoyalSociety_Stier_2026.pdf` (6.1M, 05-18 13:57) | L | Yes (regenerable from builder) | Superseded by root `_clean.pdf` (05-18 16:29); 6.1M dead weight. Defer — confirm it is not the file someone hands off. |
| P1 | Defer until after 20 May | Confirm which big deck is the submission file, then archive/remove the other | `Herring_RoyalSociety_Stier_2026.pptx` (55.8M) vs `_clean.pptx` (56.9M) + `S5_only.pptx`, `DFO_SpawningBiomass_only.pptx` | M | Yes if archived not deleted | ~112M of near-duplicate decks + 2 test exports. Identifying canonical is an Adrian decision; never dedupe deliverables mid-talk. |
| P2 | Defer until after 20 May | Decide fate of legacy builder (delete, or move to `legacy/` with a header note) | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/build_pptx.js` | M | Yes | Divergence risk vs `build_pptx_native.js`. Currently the documented fallback per `deck_build_decision.md` — needs Adrian's call, not a unilateral cleanup. |
| P2 | Defer until after 20 May | Resolve superseded HTML schematics + fix `render_deck.sh` regenerating S5/S7 over R figures | `analysis/04_talks/2026-royalsociety/Talk_Materials/s5_two_collapses.html`, `s7_two_scales.html`, `render_deck.sh` `schem` lines for 05/07 | M | Yes | `slide_asset_map.md` says S7 R figure "replaces old schematic" but `render_deck.sh` still overwrites it from HTML. Real inconsistency — fix only when deck is no longer in flight. |
| P3 | Defer until after 20 May | Dedupe duplicated large photos between the two photo dirs | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/photos/` vs `deck_build/slides_html/photos/` (~105M combined, overlapping s01/s02/s14) | M | Yes | ~50M recoverable, but both are consumed by `render_deck.sh`; consolidating requires editing the render script → post-talk only. |
| P3 | Defer until after 20 May | Remove empty leftover dirs | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_source/`, `analysis/04_talks/2026-royalsociety/Talk_Materials/blocker_resolution/` | L | Yes | Empty; `blocker_resolution/` collides with `blocker_resolution_2026-05-17.md`. Trivial, but no reason to touch the workspace before the talk. |
| P1 | Defer until after 20 May | Reconcile canonical-plan conflict (14- vs 20-slide) across sync docs | `slide_asset_map.md`, repo-root `docs/HERRING_TALK_ASSETS.md`, `talk_production_plan.md`, `deck_build_decision.md` | M | Yes (docs) | Three docs disagree on slide count/canonical. Already self-flagged in `slide_asset_map.md` "Open decisions #1". Editing mid-talk would confuse the build — explicitly post-talk. |
| P3 | Defer until after 20 May | Consolidate / version outline triplet | `talk_outline_v1.md`, `talk_outline_v2.md`, `talk_production_plan.md` | L | Yes | Heavy overlap, no clear canonical marker; `talk_architecture_*.html` appear operative. Reorganize post-talk with Adrian. |
| P3 | Defer until after 20 May | Decide if `deck_build/dfo_src/` digitization sandbox can be archived | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/dfo_src/` (1.2M) | L | Yes | One-time Fig8d digitization working set; CSV may be cited by provenance. Verify before archiving — post-talk. |
| P3 | Defer until after 20 May | Remove pre-restage backup once final deck confirmed | `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_assets/_originals/` (4 PNGs, ~1.3M) | L | Yes | Manual rollback safety net made 05-18 16:23. Keep through the talk; clear only after the deck is delivered. |

### Open questions for Adrian

1. **Which big .pptx is the Royal Society submission file** — `Herring_RoyalSociety_Stier_2026_clean.pptx` (56.9M, newest) or `Herring_RoyalSociety_Stier_2026.pptx` (55.8M)? Can the non-final one (and the `S5_only` / `DFO_SpawningBiomass_only` test exports) be archived after the talk?
2. **Canonical slide plan: 14 or 20?** `slide_asset_map.md` follows 14-slide; `docs/HERRING_TALK_ASSETS.md` + `talk_production_plan.md` + `deck_build_decision.md` say 20-slide. Which is final, and does the dropped social cognitive-map beat (Stier 2016, S15/S19 provenance) fold back in?
3. **`render_deck.sh` regenerates S5/S7 from HTML schematics, but `slide_asset_map.md` says the R figures replaced those schematics.** Is the live deck built from the R-figure staged PNGs or from the HTML-rendered schematics? (Affects whether `s5_two_collapses.html`/`s7_two_scales.html` are truly superseded.)
4. **Is `build_pptx.js` (legacy) still a needed fallback**, or can it be retired now that `build_pptx_native.js` is authoritative? `deck_build_decision.md` implies a render-fallback role.
5. **`build1_spine.html`** — superseded by `herring_decoupling_figure.html` (per `slide_asset_map.md` note 2), or still the shared visual artifact for slides 2/12/20 (per `deck_build_decision.md`)?
6. After the talk, OK to consolidate the duplicated photo dirs (`deck_build/photos/` vs `deck_build/slides_html/photos/`, ~50M recoverable) and delete the empty `deck_source/`/`blocker_resolution/` dirs?


---

<!-- SYNTHESIS -->
## Synthesis — cross-cutting reconciliation & priority action plan

_Reconciliation pass over sections 1–6. Numbers spot-verified read-only on 2026-05-18: `.git` = 182 MB, `Data/` = 15 GB, `Output/posteriors/` = 13 GB, `cloud/aws_results/` = 12 GB; branch `chore/overnight-cloud-dryrun-ids-20260511-2254`. Live constraints honored: Royal Society talk **Wed 20 May 2026** (2 days out), Bayesian pipeline active, talk-workspace firewall intact._

### A. The 41 GB question — settled

The 41 GB is **not a git problem**. `.git` is 182 MB with clean history — none of the multi-GB `.rds` fit objects or the AWS cache are or ever were committed (`git rev-list --disk-usage` = 182 MiB, in-pack 0). The bulk is entirely untracked working-tree data already covered by `.gitignore`. **This is a disk-hygiene + tidiness cleanup, NOT a git-history rewrite.** The single biggest *disk* reclaim is the ~12 GB `cloud/aws_results/` tree, which is a byte-identical duplicate of `Output/posteriors/` (verified: `fit_m5_v5.rds` = 962,160,997 bytes in both locations; each AWS job additionally stores its fit twice, in `Output/posteriors/` and `Data/processed/`). The only genuine *git* concern anywhere is small and policy-level: 45 MB of Literature PDFs were force-added against the repo's own `Literature/` ignore rule (section 5) — a contradiction to resolve, not a history emergency (history removal is High-risk and optional given `.git` is only 182 MB).

| Location | Size | Git-tracked? | In history? | Regenerable? | Disposition |
|---|---|---|---|---|---|
| `Data/` | ~15 GB | No (gitignored) | No | Partly (raw inputs) | Out of all 6 audit domains; not a cleanup target — leave |
| `Output/posteriors/` (44 `.rds`) | ~13 GB | No (gitignored) | No | Yes, but days of compute / AWS $ | Precious working artifacts — keep, do not delete without sign-off |
| `cloud/aws_results/` (103 files) | ~12 GB | No (gitignored) | No | Yes — **redundant duplicate** of posteriors | **Biggest single reclaim (~12 GB)** — delete locally after promotion confirmed |
| `Output/diagnostics/` + `Output/figures/` | ~92 MB | No (gitignored) | No | Yes | Tidy/reorganize post-talk |
| Tracked `Literature/*.pdf` (20) | 45 MB | **Yes (force-added)** | **Yes (in pack)** | No (on Drive) | **Only git contradiction** — untrack going forward; history rewrite optional/deferred |
| `.git` | 182 MB | — | clean | — | Healthy — **no history rewrite needed** |

Root logs/output (section 1, ~370 KB) and docs (section 4, ~473 KB) are rounding error on disk — pure tidiness, zero bloat impact.

### B. Cross-cutting conflicts & dependencies

**B1 — `.gitignore` (sections 1, 2, 5): one unified recommendation.** Three sections touch `.gitignore`; the conclusions are complementary, not contradictory. Section 5 confirms the existing rules (`Output/posteriors/*.rds`, `cloud/aws_results/`, `Output/diagnostics/`, `Output/figures/`) are **already correct — do not "fix" what works.** The only additive changes, all post-talk:
- Add `logs/` (section 1) — only *after* root logs are relocated there, so future model runs stop landing at repo root.
- Add `inst/stan/*.hpp` and `git rm --cached` the 7 tracked `.hpp` (section 2) — mirrors the existing correct `*.rds` handling; stale C++ transpilations (2026-04-01) older than their `.stan` sources (2026-05-05), regenerated on compile, runtime-irrelevant.
- Resolve the `Literature/` contradiction (section 5) — see B4. This is the only `.gitignore`-adjacent item that needs an Adrian decision before any edit.
There is no conflict between the three sections; the unified action is "leave the heavy-data rules alone, add three narrow post-talk rules."

**B2 — Doc-sync 14-vs-20-slide conflict (sections 4 & 6): stated once.** `slide_asset_map.md` follows a **14-slide** architecture; `docs/HERRING_TALK_ASSETS.md` + `talk_production_plan.md` + `deck_build_decision.md` say **20-slide**. The 14-slide spine drops the social cognitive-map beat (Stier 2016, S15/S19 provenance). This is already self-flagged in `slide_asset_map.md` "Open decisions #1." **Resolution: note only, do NOT edit any sync doc before the talk** — these docs feed the in-flight build and `HERRING_TALK_ASSETS.md` is the CLAUDE.md entry point. It is a single decision for Adrian (E2), reconciled post-talk.

**B3 — Broken `CLAUDE.md` doc references (section 4).** Repo `CLAUDE.md` points to `docs/HG_PREDATION_SYNTHESIS.md` (does not exist) and `docs/DATA_DICTIONARY.md` (case mismatch — actual file is `docs/data-dictionary.md`). This is a navigation defect, not a content conflict. It is technically a tiny, safe, talk-irrelevant edit — **but** `CLAUDE.md` is itself a live talk-window control file and the fix is a content-author judgment (create stub vs. remove ref vs. rename file). **Safer resolution: surface as a decision (E3), do not auto-edit.** Read-only audit discipline applies.

**B4 — Literature PDF policy contradiction (section 5): the only real cross-domain git conflict.** `.gitignore` says `Literature/` is Drive-only ("too large for git"), yet 20 PDFs are force-added and tracked (45 MB in pack). Section 5 offers (a) keep them tracked + remove the blanket ignore, or (b) `git rm --cached` to honor the policy. The user's own memory note ("projects must be self-contained, download PDFs into the project directory") *favors keeping literature local* — so the safer reconciliation is **(a): formalize the 20 as intentionally tracked, narrow the ignore rule** rather than untrack. History scrubbing (filter-repo) is High-risk, breaks collaborator clones, and is unjustified at 182 MB `.git` — **defer indefinitely unless clone size becomes a problem.** Single decision for Adrian (E2).

**B5 — Stale-model lineage spans sections 1, 2, 3, 5 (no conflict, shared dependency).** The `_vN` → `_stier_*` model rename shows up as: root `_vN` console logs (§1), `inst/stan/*_v2..v5.stan` (§2), `Code/03_fit_m*_v*.R` + audit-ledger rows (§3), and `Output/posteriors/fit_m*_v*.rds` + `Output/figures/v2/` (§5). All four agree these are *superseded but not deletable while the talk/paper review is live*, and all defer. The only dependency to honor: archiving `Code/03_fit_m*_v*.R` (§3 P1) interacts with the audit tribbles in `03c/03d/04_compare_models_v3.R` that still enumerate the stale rows — §3 confirms archiving the scripts without editing the audit is **safe** (audit already filters stale; it just won't find the `.rds`). Decide tribble pruning separately (E-list), don't block the archive on it.

**B6 — Empty/dead stub directories (sections 5 & 6).** `Output/tables/`, `Output/presentations/` (§5, 0 B) and `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_source/`, `blocker_resolution/` (§6, empty, name-collides with `blocker_resolution_2026-05-17.md`). Trivial, reversible, but the talk-workspace pair sits inside the firewalled in-flight build — **all four deferred to Phase 2** to keep one clean rule ("no structural touches to talk-adjacent trees pre-talk"). The `Output/` pair is technically safe-now but has zero payoff and is bundled with Phase 2 for consistency.

**No contradictory recommendations survive reconciliation.** Where sections differed in tone (e.g. §5 P2 offering a/b on Literature; §6 flagging the legacy builder as both foot-gun and documented fallback), the safer option is taken: preserve-and-formalize over delete, defer over act, decision-surface over auto-edit.

### C. Unified priority action plan

Dependency-ordered. Duplicate recommendations across sections merged into single rows. `Window`: **SAFE NOW** = talk-irrelevant, zero pipeline/deck risk, reversible; **AFTER 20-MAY** = anything talk- or pipeline-adjacent; **NEEDS ADRIAN** = requires an explicit decision before action. Ruthlessly: almost everything is AFTER 20-MAY.

| # | Action | Domain(s) | Window | Risk | Reversible? | Est. payoff (disk / clarity) |
|---|---|---|---|---|---|---|
| 1 | Capture Adrian's decisions (Section E) — gates almost everything below | all | NEEDS ADRIAN | L | n/a | Unblocks Phases 1–2 |
| 2 | Visually confirm (do **not** remove) the 18 unreferenced QA-screenshot JPGs in `deck_build/` are scratch | §6 | SAFE NOW | L | Yes | ~0 disk / minor clarity — inventory only, no removal pre-talk |
| 3 | Spot-confirm `cloud/aws_results/` byte-duplication vs `Output/posteriors/` (read-only `du`/cmp on 1–2 files) | §5 | SAFE NOW | L | Yes | 0 disk / de-risks the #5 reclaim |
| 4 | Confirm AWS results promoted to canonical `Output/posteriors/` via `promote_cloud_results.sh` | §5 | NEEDS ADRIAN | L | Yes | Gate for #5 (~12 GB) |
| 5 | Delete duplicate AWS staging cache (re-pullable from S3) | §5 | AFTER 20-MAY | M | Yes (re-pull `sync_model_farm_results.sh`) | **~12 GB / high** |
| 6 | Decide + delete superseded old-version `Output/posteriors/fit_m*_v*.rds` if not needed for model-comparison | §5 | AFTER 20-MAY · NEEDS ADRIAN | M | No (delete) — keep gitignored copies elsewhere | up to ~3–13 GB / medium |
| 7 | Resolve Literature tracking contradiction: formalize 20 PDFs as tracked, narrow `Literature/` ignore (recommended (a)) | §5 | NEEDS ADRIAN | M | Yes (`rm --cached` reversible) | 0 disk / removes policy conflict |
| 8 | Create `Code/archive/`; `git mv` 0-caller superseded fit variants + stubs + v4/m3_v5 diagnostics | §3 | AFTER 20-MAY | L | Yes (git mv) | 0 disk / **high clarity** (~22 files off active tree) |
| 9 | `git mv` stale-tagged `Code/03_fit_m{1,3,5}_v{3,5}.R` to archive (audit tribbles auto-filter) | §3 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes (git mv) | 0 disk / medium |
| 10 | `git mv Code/legacy-2019/` (8 `.R` + `Posteriors/`) wholesale to `Code/archive/` | §3 | AFTER 20-MAY · NEEDS ADRIAN (cited in paper?) | L | Yes (git mv) | 0 disk / medium |
| 11 | `git mv` stale `Code/04_wait_for_{m1_v4,m1_v5,v3}*.sh` glue to archive | §3 | AFTER 20-MAY | L | Yes (git mv) | 0 disk / low–med |
| 12 | Create root `logs/`, plain-move stale April `_vN` root logs + remaining root model logs into it | §1 | AFTER 20-MAY | L | Yes (move-back) | ~370 KB / **high clarity** (declutters root) |
| 13 | Add `logs/` to `.gitignore` (only after #12) | §1, §5 | AFTER 20-MAY | L | Yes | 0 / prevents future root junk |
| 14 | `git rm --cached` 7 `inst/stan/*.hpp`; add `inst/stan/*.hpp` to `.gitignore` | §2 | AFTER 20-MAY | L | Yes (git) | trivial / med (mirrors `.rds` policy) |
| 15 | Create `docs/archive/`; `git mv` stale `v3/v5` lineage docs (not CLAUDE/README/talk-cited) | §4 | AFTER 20-MAY | L | Yes (git mv) | ~tiny / **high clarity** (safest doc archive) |
| 16 | Repoint README + `HERRING_TALK_ASSETS.md` links, then archive may-9 + dated talk-checkpoint docs | §4 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes (git mv) | tiny / medium — links must update first |
| 17 | Consolidate Doherty-style quartet → `doherty-style-hg-source-provenance.md`; repoint README | §4 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes | tiny / medium |
| 18 | Fold predator-data-plan/-roadmap into `predator-repo-integration-guide.md`, archive originals | §4 | AFTER 20-MAY | M | Yes | tiny / medium |
| 19 | Fix broken `CLAUDE.md` refs (`HG_PREDATION_SYNTHESIS.md`, `DATA_DICTIONARY.md` case) | §4 | NEEDS ADRIAN | L | Yes | 0 / fixes live navigation defect |
| 20 | Confirm submission `.pptx`; archive the non-final deck + `S5_only`/`DFO_*` test exports | §6 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes (archive, not delete) | ~112 MB / medium |
| 21 | Delete stale intermediate `deck_build/Herring_..._2026.pdf` (6.1 MB) | §6 | AFTER 20-MAY | L | Yes (regenerable) | ~6 MB / low |
| 22 | Decide fate of legacy `build_pptx.js` (retire vs. move to `legacy/` with header) | §6 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes | 0 / removes foot-gun |
| 23 | Fix `render_deck.sh` regenerating S5/S7 schematics over R figures; resolve superseded HTML | §6 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes | 0 / fixes real build inconsistency |
| 24 | Dedupe duplicated photo dirs (`deck_build/photos/` vs `slides_html/photos/`) | §6 | AFTER 20-MAY | M | Yes | ~50 MB / low |
| 25 | Remove empty stub dirs: `Output/tables`, `Output/presentations`, `deck_source`, `blocker_resolution` | §5, §6 | AFTER 20-MAY | L | Yes | 0 / low tidiness |
| 26 | Triage dated `07*` memo/status/ledger/brief scripts per-file with Adrian, archive non-reusable | §3 | AFTER 20-MAY · NEEDS ADRIAN | M | Yes (git mv) | 0 / medium |
| 27 | Reorganize `Output/figures/` into `manuscript/` vs `exploratory/` (keep `lecture/deck/` as-is) | §5 | AFTER 20-MAY | M | Yes | 0 / medium |
| 28 | Add `Code/README.md` stage/prefix map + model lineage; resolve naming drift (no renames yet) | §3 | AFTER 20-MAY | L | Yes | 0 / **high clarity** |
| 29 | Add one-line headers to `R/04`, `R/07`, `R/09` noting load-path (not in default DAG) | §2 | AFTER 20-MAY | L | Yes | 0 / low–med |

### D. DO-NOT-TOUCH until after the talk (consolidated)

Aggregated from every section's risk list. Hands-off through **Wed 20 May 2026**:

**Talk-critical code & build chain (§3, §6):**
- `Code/07cz_deck_figure_reexport.R` (deck builder, uncommitted `M`) and its upstream CSV producers: `Code/06g_reproduce_stier2020_figures_updated.R`, `Code/06h_companion_and_supplement_figures_updated.R`, `Code/06_refresh_stier2020_updated_figure_suite.sh`, `Code/02c_integrate_hg_predator_repo_products.R`, `Code/02f_extract_newer_dfo_public_pdfs.R`, `Code/03_fit_m1_stier_11.R`, `Code/03_fit_m1_stier_obs_hier.R`, `Code/07_m1_stier_11_population_driver_analysis.R`, `Code/07i_m1_stier_11_cryptic_collapse_screen.R`, `Code/07l_m1_stier_11_postclosure_recovery.R`.
- `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/build_pptx_native.js` (current builder) **and** `build_pptx.js` (documented fallback).
- `analysis/04_talks/2026-royalsociety/Talk_Materials/deck_assets/` — all 15 staged PNGs **and** `_originals/` rollback backup.
- `Herring_RoyalSociety_Stier_2026_clean.pptx` (56.9 MB), `_clean.pdf` (16.7 MB), `Herring_RoyalSociety_Stier_2026.pptx` (55.8 MB), `S5_only.pptx`, `DFO_SpawningBiomass_only.pptx`.
- `render_deck.sh` and every HTML schematic it consumes (`s5_two_collapses.html`, `s7_two_scales.html`, `s11_triple_bottom_line.html`, `s13_takeaways.html`, `herring_decoupling_figure.html`, `slides_html/*.html`, `slides_html/photos/`, `deck_build/photos/`). **Do NOT run any deck build.**

**Sync/SSOT docs (§4, §6) — note only, no edits mid-talk:**
- `docs/HERRING_TALK_ASSETS.md`, `docs/talk-model-claim-control-sheet.md`, `docs/saturday-talk-readiness-2026-05-16.md`, `docs/monday-talk-sprint-plan.md`, `docs/may-9-analysis-decision-summary.md`, `docs/may-9-analysis-output-index.md`, `docs/herring-non-recovery-hypotheses.md`, `docs/predator-repo-integration-guide.md`, plus README-cited live reading-path docs (`theory-data-model-integration.md`, `data-dictionary.md`, `stan-model-map.md`, `collaborator-reading-guide.md`, `current-population-driver-findings.md`, `literature-parameter-roadmap.md`).
- `analysis/04_talks/2026-royalsociety/Talk_Materials/slide_asset_map.md`, `deck_design_system.md` (the 14-vs-20 conflict stays unresolved until after the talk).
- Repo `CLAUDE.md` (live control file — broken-ref fix surfaced as a decision, not an edit).

**Pipeline-live model assets (§1, §2, §3, §5):**
- All `inst/stan/*.stan` (33 files — `Code/`-driven + ledger-governed; none provably dead).
- `R/03_fit_model.R` (`.model_file_map`, `.spatial_models`, predator classifiers — the fit contract), all `R/*.R`, all `tests/*`.
- All `Output/posteriors/*.rds` (44 fits — regenerable ≠ cheap; no working-tree deletion without sign-off).
- `Output/figures/lecture/deck/` (8 PNGs incl. 3 git-tracked `s06/s08/s09`) — talk-critical, regenerated today.
- All May-dated `*_stier_*` root logs and live diagnostics (`may9_analysis_suite_refresh.log`, `m1_stier_obs_hier_*`, `m2_stier_site_growth_*`, `m3_stier_distance_*`) — potential live pipeline reference.
- The 7 committed `SESSION_LOG_*.md` + `MORNING_REPORT.md` + `REVIEW_NOTES.md` (talk provenance trail).

### E. Decisions needed from Adrian

1. **AWS promotion confirmed?** Has `cloud/aws_results/2026-05-13/` (and `-14`, `-16`) been promoted into canonical `Output/posteriors/` via `promote_cloud_results.sh`? **Yes → ~12 GB safe to delete locally** (re-pullable from S3). [gates action #5]
2. **Literature tracking policy — A or B?** (A) Keep the 20 PDFs intentionally tracked and narrow the `Literature/` ignore rule (matches your "self-contained projects" memory note — **recommended**); or (B) `git rm --cached` them to honor the Drive-only `.gitignore` comment. Separately: scrub the 45 MB from git *history* (filter-repo)? **Recommend NO** — `.git` is only 182 MB and it breaks collaborator clones.
3. **Broken `CLAUDE.md` refs — fix how?** `docs/HG_PREDATION_SYNTHESIS.md` (missing): create a stub, or remove the reference? `docs/DATA_DICTIONARY.md`: repoint to `docs/data-dictionary.md`, or rename the file to SCREAMING_SNAKE? (A/B each.)
4. **Canonical slide plan: 14 or 20?** `slide_asset_map.md` = 14-slide; `HERRING_TALK_ASSETS.md` + `talk_production_plan.md` + `deck_build_decision.md` = 20-slide. Which is final, and does the dropped social cognitive-map beat (Stier 2016, S15/S19) fold back in? (Post-talk reconciliation; needed to close §4/§6.)
5. **Which `.pptx` is the submission file** — `Herring_RoyalSociety_Stier_2026_clean.pptx` (56.9 MB, newest) or `Herring_RoyalSociety_Stier_2026.pptx` (55.8 MB)? May the other + `S5_only`/`DFO_SpawningBiomass_only` test exports be archived after the talk?
6. **Docs consolidation — confirm canonical survivors:** `theory-data-model-integration.md`, `current-population-driver-findings.md`, `current-analysis-quickstart.md`, `predator-repo-integration-guide.md`, `doherty-style-hg-source-provenance.md`, `aws-codex-model-farm-lessons.md`? Keep `doherty-style-hg-gap-table.md` standalone (README links it) or fold it in?
7. **Stale-model cleanup scope:** archive `Code/03_fit_m*_v*.R` + `legacy-2019/` + delete old `Output/posteriors/fit_m*_v*.rds`? And prune the matching stale rows from the `03c/03d/04_compare_models_v3.R` audit tribbles, or keep as historical record? (Archiving scripts without editing the audit is safe.)
8. **Proceed with the post-talk archive sweep (Phases 1 & 2) as sequenced below?** Single yes/no to authorize the whole plan once decisions 1–7 are in.

### F. Recommended sequence

Reversible `git mv` (history-preserving) over `rm` everywhere a file is tracked. Plain `mv` for untracked junk (root logs). Never `rm` deliverables or `.rds` — archive or move.

**Phase 0 — safe now (pre-talk, ≤15 min, zero talk risk).** Inventory/verification only; nothing moved, deleted, or edited:
1. Read-only spot-confirm the `cloud/aws_results/` ↔ `Output/posteriors/` byte-duplication on 1–2 files (`cmp`, `du`) so the ~12 GB reclaim is de-risked and ready (#3).
2. Visually confirm the 18 `deck_build/qa-*.jpg` / `q-*.jpg` / `qx-*.jpg` are unreferenced scratch — **confirm only, do not remove** (#2).
3. Collect Adrian's answers to Section E (#1). **Stop here until after the talk.**

**Phase 1 — post-talk disk reclaim (the ~12–25 GB).** Run only after the talk is delivered and decisions 1, 7 are in:
1. Re-verify promotion (decision 1). If confirmed: `rm -rf cloud/aws_results/2026-05-13/jobs/ cloud/aws_results/2026-05-14-predator-demand-total/` (re-pullable via `cloud/sync_model_farm_results.sh`) — **~12 GB** (#5).
2. If decision 7 says superseded old-version fits are droppable: remove the specific `Output/posteriors/fit_m{1,5}_v{2,3,4,5}.rds` named by Adrian — up to a further ~3–13 GB (#6).
3. Resolve Literature tracking per decision 2: if (A), narrow the `Literature/` rule and keep tracked; if (B), `git rm --cached Literature/*.pdf` (files stay on disk) (#7). No history rewrite unless explicitly chosen.

**Phase 2 — post-talk structural tidy (Code/archive, docs consolidation, logs/ convention, .gitignore hardening).** After Phase 1, dependency-ordered:
1. **Code archive:** `mkdir Code/archive`; `git mv` the 0-caller superseded fit variants, stubs, v4/m3_v5 diagnostics, stale `wait_for_*.sh`, and (per decision 7) `Code/03_fit_m*_v{3,5}.R` + `Code/legacy-2019/` into it (#8–11). Add `Code/README.md` stage/prefix map (#28). Per-file triage the dated `07*` memos with Adrian, archive non-reusable (#26). No renames yet (would break `08_*.sh`).
2. **Root logs convention:** `mkdir logs`; plain-`mv` stale April `_vN` logs + remaining root model logs into `logs/` (#12); then add `logs/` to `.gitignore` (#13).
3. **inst/stan hygiene:** `git rm --cached inst/stan/*.hpp`; add `inst/stan/*.hpp` to `.gitignore` (#14). Add load-path header comments to `R/04/07/09` (#29).
4. **Docs consolidation:** `mkdir docs/archive`; `git mv` stale `v3/v5` lineage docs first (safest, no inbound links — #15). Then repoint README + `HERRING_TALK_ASSETS.md` links **before** archiving may-9/dated-checkpoint docs (#16). Consolidate Doherty quartet and predator trio per decisions 6 (#17–18). Fix broken `CLAUDE.md` refs per decision 3 (#19).
5. **Talk workspace tidy** (deck no longer in flight): per decision 5, archive non-final `.pptx` + test exports (#20); delete stale intermediate PDF (#21); resolve legacy builder + `render_deck.sh` S5/S7 inconsistency per decisions 4–5 (#22–23); dedupe photo dirs (#24); remove the 4 empty stub dirs (#25). Reorganize `Output/figures/` into `manuscript/`/`exploratory/` last (#27).

End state: ~12–25 GB reclaimed, `.git` untouched (clean), root/Code/docs decluttered, future runs land in gitignored `logs/`, zero history rewrite.

---

## EXECUTED — 2026-05-18 (Adrian: "address all issues", risk accepted)

Done now (all **reversible**: `git mv` / `git rm --cached` / moving untracked files; talk pipeline re-verified intact afterward — `07cz` re-ran clean, deck rebuilt 16:20):

| Action | Result |
|---|---|
| `Code/archive/` created; superseded fit variants + stubs + v4/m3_v5 diagnostics + stale `wait_for_v*.sh` `git mv`'d | **27 scripts** archived |
| `Code/legacy-2019/` → `Code/archive/legacy-2019/` | moved |
| `docs/archive/` created; stale v3/v5 lineage docs `git mv`'d | `v5-covariate-rationale.md`, `v3-model-comparison-results.md`, `parameter-comparison-stier2020.md` |
| `inst/stan/*.hpp` untracked (`git rm --cached`, files kept) + `.gitignore` hardened (`inst/stan/*.hpp`, `logs/`) | **7** .hpp untracked |
| Root `logs/` (gitignored) created; untracked stale root logs/outputs moved (today's left in place) | **29 files** → `logs/` |
| `SESSION_LOG_*.md` → `docs/session-logs/` (`git mv`; no inbound refs) | **7 files** |

**Deferred (NOT done — would endanger the Wed 20 May talk / need your decision / irreversible):**
- ❌ `cloud/aws_results/` 12 GB delete — **NOT a confirmed byte-identical duplicate** on inspection (it holds AWS *job* trees incl. predator/m5 fits); `promote_cloud_results.sh` exists but no evidence it ran. Needs your confirmation. Irreversible — left untouched.
- ❌ Literature-PDF git-history rewrite — deferred (only real git wart; `.git` is 182 MB, not worth `filter-repo`).
- ❌ may-9 / dated talk-checkpoint docs, Doherty quartet, predator-trio consolidation — cited by the live `HERRING_TALK_ASSETS.md`; defer until after the talk + README repoint.
- ❌ Dated `07*` memo scripts, `wait_for_*stier_*.sh` — per-file decision needed (pipeline still live).

**Corrections to the audit (verified false / unsafe):**
1. **"Broken CLAUDE.md refs" = FALSE POSITIVE.** `CLAUDE.md:54,56` point to `/Users/adrianstier/pacific-herring-predators/docs/...` — absolute paths into the **sibling predator repo**, which exist. Nothing broken; no edit made (a "fix" would have introduced an error).
2. **"cloud/aws_results byte-identical duplicate" = UNVERIFIED.** Structure differs (per-job trees, predator/m5 models). Not safe to delete on the audit's assumption.

_Status: archived to `docs/archive/cleanup-may-18-2026.md`. Open items above carry forward to post-talk._
