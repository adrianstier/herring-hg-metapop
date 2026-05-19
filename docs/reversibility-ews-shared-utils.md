# Reversibility / EWS Shared-Utility Reconciliation Note

Date: 2026-05-20
Branch: feat/reversibility-hysteresis-analysis
Spec refs: §6.1 (EWS-shared utility reuse pattern), §9 (Relationship to the EWS spec)

---

## Context

Two functions exist in `R/12_reversibility.R` that are **also specced** for
`R/11_early_warning.R` (the EWS plan, as of this writing **not yet executed**):

- `detect_candidate_transitions()`
- `survey_artifact_null()`

The reversibility plan implements its own copies in the `R/12_reversibility.R`
namespace. Phase 9 (Task 24 Step 1) records the dedupe obligation here so a
future EWS implementation matches them byte-for-byte and the migration is clean.

---

## Authoritative function signatures and return contracts

### `detect_candidate_transitions(x, years, penalty = "MBIC")`

```r
detect_candidate_transitions(x, years, penalty = "MBIC")
```

**Arguments:**
- `x` — numeric vector (time series, may contain `NA`/`Inf`).
- `years` — integer or numeric vector, same length as `x`.
- `penalty` — string passed to `changepoint::cpt.meanvar()` (default `"MBIC"`).

**Return contract:**  `data.frame` with columns `year` (integer), `index`
(integer), `kind` (character).

- **NA-safe:** filters to `ok <- is.finite(x)` then maps detected change-point
  positions back to original indices via `which(ok)[idx]` — the `index` column
  is always a position in the *original* `x`/`years` vectors.
- **Short-series guard:** returns a **0-row** `data.frame` (columns present,
  0 rows) when `sum(is.finite(x)) < 4L`. Never crashes, never a silent number.
- **Implementation:** `changepoint::cpt.meanvar(..., method = "PELT")`.

### `survey_artifact_null(truth, era_break, q, cv = 0.2, seed)`

```r
survey_artifact_null(truth, era_break, q, cv = 0.2, seed)
```

**Arguments:**
- `truth` — numeric vector, the "true" underlying series (before obs error).
- `era_break` — integer, index of the era boundary (rows `<= era_break` get
  catchability `q[1]`; rows `> era_break` get `q[2]`).
- `q` — length-2 numeric vector of catchability multipliers (pre/post).
- `cv` — lognormal coefficient of variation (default `0.2`).
- `seed` — integer; passed directly to `set.seed(seed)` for determinism.

**Return contract:**  numeric vector of length `length(truth)` (the simulated
observed series under the two-era catchability shift + lognormal obs error).

- **Assertion:** `stopifnot(length(q) == 2L)` — must be length 2; hard error
  otherwise.
- **Determinism:** `set.seed(seed)` is called inside the function, advancing
  the global RNG state. Result is byte-identical across runs at a given seed.
- **Formula:** `q[era] * truth * rlnorm(n, -0.5 * cv^2, cv)`.

---

## Current location (authoritative until EWS plan executes)

Both functions live in `R/12_reversibility.R` (lines ~56–70 and ~427–434
as of HEAD `2eaa580`). Their docstrings note "Self-contained copy of the
EWS-shared util; Phase 9 records the dedupe obligation."

---

## Migration rule (when the EWS plan executes)

1. The EWS implementation (`R/11_early_warning.R`) becomes the **canonical
   home** for both functions.
2. `R/12_reversibility.R` replaces its copies with `source(here::here("R/11_early_warning.R"))` at
   the top (or a targeted `source()` of a shared utility file if the EWS plan
   extracts them to a separate file).
3. Both test files (`tests/testthat/test-reversibility.R` and
   `tests/testthat/test-early-warning.R`) retain their analytic-case tests —
   the reversibility tests verify the shared function from the new canonical
   location; the EWS tests verify the same.
4. The signatures and return contracts above are the binding contract: the EWS
   implementation must match them exactly so no reversibility callers break.

---

## Sibling spec relationship

This note operationalises the cross-spec link documented in:
- Reversibility spec §9 (Relationship to the EWS spec), Table row "Shared infra"
- EWS spec: `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md`
- Plan note (line ~12): "Phase 9 Task 24 records the dedupe obligation."
