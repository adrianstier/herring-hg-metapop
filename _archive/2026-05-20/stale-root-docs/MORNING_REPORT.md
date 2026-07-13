# Morning Report

Date: 2026-05-11

## Branches Created

- `chore/overnight-review-docs-20260511-2138`: initial session log, review notes, and AWS submitter guard against planned/missing-script jobs.
- `chore/overnight-cloud-result-checks-20260511-2153`: added `--out-csv` to model-farm submissions so submitted AWS job ids can feed the watcher.
- `chore/overnight-current-analysis-quickstart-20260511-2203`: added a standalone current-analysis quickstart that points to the promoted `m1_stier_11` baseline.
- `chore/overnight-doc-reference-checker-20260511-2210`: added a markdown local-file reference checker.
- `chore/overnight-cloud-runtime-review-20260511-2240`: made cloud result sync summarize against the downloaded run manifest.
- `chore/overnight-cloud-dryrun-ids-20260511-2254`: made dry-run submission CSV ids unique and recorded the maintained test result.

Current branch: `chore/overnight-cloud-dryrun-ids-20260511-2254`.

## Files Archived

- 0.

No files were moved or archived. I avoided P3 because the repo is in an active modeling sprint and many untracked `Code/`/`cloud/` files are current work, not old superseded work.

## Bugs Found And Fixed

- `68238de` - Guarded `cloud/submit_model_farm.py` so `planned_*` manifest rows are skipped unless `--include-planned` is explicit, and missing scripts fail locally before AWS submission.
- `c387fe2` - Added `--out-csv` to `cloud/submit_model_farm.py` so submitted job ids are captured for `cloud/watch_aws_batch_run.py`.
- `c175122` - Changed `cloud/sync_model_farm_results.sh` to summarize artifacts against the downloaded run manifest when available, not whatever manifest happens to be current locally.
- `807cdf8` - Made dry-run job ids unique as `DRY_RUN_<job_id>` so multi-row dry-run CSVs do not collapse when keyed by job id.

## Bugs / Risks Flagged

See `REVIEW_NOTES.md`.

Highest-priority flagged items:

- `README.md:39` still opens with the old M1-M6 hierarchy before the current promoted-baseline guidance.
- `docs/stan-model-map.md:5` has competing "read first" sections: older maintained model infrastructure before the promoted `m1_stier_11` branch.
- `docs/full-analysis-model-farm-scope.md:123` calls exploratory density/predator rows "current jobs", which can encourage stale AWS submissions.
- `Output/diagnostics/latest_model_status.md:76` mentions historical surveyed-cell `m1_v5` before the promoted baseline in the next-decision section.

## Tests Run

- `python3 -m py_compile cloud/submit_model_farm.py` - passed.
- `python3 cloud/submit_model_farm.py --dry-run ... --job-id smoke_cloud_pipeline --include-spot --out-csv /private/tmp/herring-submit-dryrun.csv` - passed.
- `python3 cloud/submit_model_farm.py --dry-run ... --include-spot` - passed and skipped `m6_timevarying`.
- `bash -n cloud/sync_model_farm_results.sh` - passed.
- `bash -n cloud/batch_entrypoint.sh` - passed.
- `bash -n cloud/run_cloud_job.sh` - passed.
- `bash -n cloud/promote_cloud_results.sh` - passed.
- `Rscript Code/09_check_document_references.R` - passed; 65 markdown files scanned, 372 local references checked, 0 missing references, 1 known planned-missing reference.
- `Rscript tests/testthat.R` - passed; 439 passed, 0 failed, 0 warnings, 0 skipped.

## Anything Surprising

- The worktree was already very dirty before this overnight pass. I avoided staging unrelated modified files and committed only files changed in each cycle.
- The AWS submission/watcher loop had a missing handoff: submission did not write the job-id CSV that the watcher expects.
- The documentation now contains the correct `m1_stier_11` direction, but several older entry points still present historical model hierarchies first.

## Three Things To Look At First

1. Review `docs/current-analysis-quickstart.md`. It is the cleanest current-model entry point I added without touching dirty README/docs files.
2. Review `cloud/submit_model_farm.py` and `cloud/sync_model_farm_results.sh`. These are the main AWS model-farm safety fixes.
3. Decide whether to consolidate the large existing dirty worktree into coherent commits before more modeling. The current analysis outputs are valuable, but review will stay hard until the untracked `Code/07*`, `cloud/`, docs, and Stan branches are grouped.

