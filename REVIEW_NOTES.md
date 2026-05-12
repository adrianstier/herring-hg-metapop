# Review Notes

## 2026-05-11 Overnight Pass

### Fixed: AWS model-farm submitter could submit planned rows with missing scripts

- **File:** `cloud/submit_model_farm.py`
- **Related manifest row:** `cloud/model-farm-manifest.csv:12`
- **Issue:** `m6_timevarying` is marked `planned_model_fit` and references `Code/03_fit_m6_timevarying.R`, which is intentionally not implemented. The submitter filtered by family/task/spot only, so a broad selection could submit this planned row and fail in AWS after spending queue/runtime.
- **Fix:** Added a default guard that skips `planned_*` task types unless `--include-planned` is explicitly passed. Added a local script-existence check before submit/dry-run output.
- **Verification:** Dry-run checks listed below in `SESSION_LOG_20260511.md`.

### Fixed: AWS model-farm submitter did not create watcher-compatible job records

- **File:** `cloud/submit_model_farm.py`
- **Related watcher:** `cloud/watch_aws_batch_run.py:105`
- **Issue:** The watcher expects a CSV with `aws_job_id`, but the submitter only printed commands / AWS output. That forced manual job-id capture between submission and monitoring.
- **Fix:** Added `--out-csv`; successful submissions now write `model`, `aws_job_id`, `queue`, `priority`, and `notes`. Dry runs write unique `DRY_RUN_<job_id>` values for schema checks.
- **Verification:** Dry-run output was written to `/private/tmp/herring-submit-dryrun.csv` and contained the expected columns.

### Fixed: cloud result sync could summarize against the wrong manifest

- **File:** `cloud/sync_model_farm_results.sh`
- **Issue:** The script downloaded the run manifest from S3 but summarized artifacts against the current local `cloud/model-farm-manifest.csv`. If the manifest changed after submission, the status table could report incorrect expected artifacts.
- **Fix:** Prefer `${local_dir}/model-farm-manifest.csv` when present, with the local manifest as fallback.
- **Verification:** `bash -n` passed for the sync, entrypoint, run, and promote scripts.

### Flagged: README still opens with an old M1-M6 hierarchy before the promoted baseline

- **File:** `README.md:39`
- **Issue:** The "Model Comparison Hierarchy" table still presents M1-M6 as the main model structure before the current `m1_stier_11` promoted-baseline section. The current direction below it is correct, but a first-time collaborator can still read the old hierarchy as the active plan.
- **Options considered:** move the old hierarchy to an archival section; relabel it as historical; replace it with the current `m1_stier_11` branch sequence.
- **Recommendation:** Replace this top-level table with the current promoted/held branch status and move the historical M1-M6 table below the current baseline section as provenance.

### Flagged: Stan model map has two competing "read first" entry points

- **File:** `docs/stan-model-map.md:5`
- **Issue:** The opening "Read These First" section lists the maintained `R/03_fit_model.R` model family first, while the immediately following Stier-aligned section says `m1_stier_11` is the promoted practical baseline. Both are true historically, but the ordering makes the older model family look primary.
- **Options considered:** leave as is; add a warning; reorder the document to put `m1_stier_11` first.
- **Recommendation:** Reorder `docs/stan-model-map.md` so the `m1_stier_11` branch appears before the legacy maintained-family map. Keep the older `R/`/`_targets` interface as maintained infrastructure, not the current inference baseline.

### Flagged: Cloud scope names exploratory predator/DD jobs as "current jobs"

- **File:** `docs/full-analysis-model-farm-scope.md:123`
- **Issue:** The density-dependence and predator sections list `m3_dd_global`, `m5_v5`, and `m5_combined` as current jobs. The manifest correctly marks some of these as legacy/exploratory, and current diagnostics say predators are data-product work before coefficient fitting.
- **Options considered:** leave the scope doc untouched; rename "Current jobs" to "Available exploratory rows"; split active, held, and planned rows.
- **Recommendation:** Change those headings to distinguish active/promoted, held, exploratory, and planned jobs so future AWS submissions do not spend time on stale branches by default.

### Flagged: Generated status mentions historical surveyed-cell models before the promoted baseline decision

- **File:** `Output/diagnostics/latest_model_status.md:76`
- **Issue:** "Best historical surveyed-cell model by current gates: `m1_v5`" appears in the next-decision section before the more important promoted-baseline line. This can overemphasize stale detection-aware models even though `m1_stier_11` is the practical baseline and zeros are ambiguous.
- **Options considered:** change only prose; change the generating script; leave generated output and rely on README/AGENTS.
- **Recommendation:** Patch the generator (`Code/04b_interpret_model_outputs.R`) so promoted-baseline guidance is first and surveyed-cell stale models are explicitly labeled as archival sensitivity.
