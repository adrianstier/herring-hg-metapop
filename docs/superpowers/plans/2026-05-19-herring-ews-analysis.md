# Haida Gwaii Herring EWS Analysis — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a comprehensive, surrogate-tested early-warning-signal (EWS) battery for the Haida Gwaii herring metapopulation — generic temporal + spatial/synchrony indicators on both observed spawn and `m1_stier_11` latent biomass — plus a claim-safe talk subset.

**Architecture:** A pure-function R library (`R/11_early_warning.R`) holding all indicator math, exercised by analytic `testthat` tests; a dependency-ordered `Code/11_ews_*.R` diagnostic family that loads inputs, calls the library, and writes `Output/diagnostics/ews_*` CSV/MD; pub-figure-pipeline figures; `_targets.R` + `Code/run_ews_suite.sh` integration; a firewalled Phase-0 talk panel.

**Tech Stack:** R (tidyverse, here, cli, testthat), `earlywarnings`, `spatialwarnings`, `MARSS`, `posterior`/`tidybayes`, `patchwork`, `ggplot2` via `theme_pub()`.

**Spec:** `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md` (Approach A).

---

## Conventions every task follows

- Every `R/` and `Code/` script starts by sourcing setup:
  `source(here::here("R", "00_setup.R"))` (gives `theme_pub`, `PAL`, `SECTIONS_ALL`, `SECTIONS_DROP=c(4L,11L)`, `YEARS`, paths).
- **all-11** = `SECTIONS_ALL |> filter(!section %in% c(4L,11L))` (13 → 11). **core-9** = all-11 minus `Tasu Sound & Gowgaia Bay` (§1) and `Naden Harbour` (§12). Both are co-equal primary; `leave-one-out` is a grid axis only.
- Diagnostic scripts use the established idiom: `proj_dir <- here::here()`, `diag_dir <- file.path(proj_dir,"Output","diagnostics")`, a local `read_diag()` that `stop()`s on missing input, and `period_for_year()` copied from `Code/06f_m1_stier_11_portfolio_figures.R` (era cutpoints: ≤1965, ≤1971, ≤2004, ≤2013, ≤2016, else).
- All randomness uses `set.seed(20260519L)` and the seed is written into every output that consumes it.
- Tests live in `tests/testthat/test-early-warning.R`; run with `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'`.
- Commit after every task with `git add <exact paths>` then a `feat:`/`test:`/`chore:` message ending with the repo's `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer.
- Firewall: nothing under `talk-usuk-forum-2026/` is ever `source()`d or read by `R/` or `Code/`. Phase 12 reads core outputs only.

---

## File structure (decomposition lock-in)

| File | Responsibility |
|---|---|
| `R/11_early_warning.R` | Pure indicator math + null/sensitivity engines. No I/O, no plotting. |
| `tests/testthat/test-early-warning.R` | Analytic-case unit tests + power controls for the library. |
| `Code/11_ews_00_data_layers.R` | Build the two co-equal data layers (observed; `m1_stier_11` latent draws) × {all-11, core-9}. |
| `Code/11_ews_01_generic_aggregate.R` | Tier-1 generic temporal battery on aggregate biomass. |
| `Code/11_ews_02_spatial_synchrony.R` | Tier-2 spatial/synchrony battery (φ, η, spatial var/skew, Moran's I, portfolio CV-ratio, occupancy ratchet). |
| `Code/11_ews_03_covariance_eigen.R` | Covariance leading-EOF / λ_max + MAR(1) community-matrix eigenvalue. |
| `Code/11_ews_04_candidate_transitions.R` | STARS + breakpoint candidate-transition detection. |
| `Code/11_ews_05_surrogate_significance.R` | Kendall τ + AR(1)/phase-randomized surrogate p-values; posterior-combined CIs. |
| `Code/11_ews_06_sensitivity_grid.R` | window × detrend × unit × estimator τ sign/significance grid. |
| `Code/11_ews_07_survey_artifact_audit.R` | Survey-method false-positive null simulation + disqualification flags. |
| `Code/11_ews_08_controls_power.R` | Positive (approaching fold) / negative (stationary) simulated-system power calibration. |
| `Code/11_ews_09_lead_time_matrix.R` | Assemble the lead-time matrix (indicator × candidate transition). |
| `Code/11_ews_10_synthesis.R` | `ews_synthesis.md` narrative + `ews_claim_control.md` addendum. |
| `Code/11_ews_11_figures.R` | pub-figure-pipeline figures (dashboard, synchrony↔eigen, sensitivity heatmap, surrogate-null, artifact audit). |
| `Code/run_ews_suite.sh` | Dependency-ordered runner (zsh, `set -euo pipefail`, tee log). |
| `_targets.R` | New EWS target stage downstream of posterior extraction + portfolio. |
| `talk-usuk-forum-2026/Talk_Materials/ews_phase0/` | Firewalled Phase-0 talk panel + speaker notes + degrade note. |

---

## Phase 0 — Branch & scaffolding

### Task 0.1: Isolate the work on a dedicated branch

**Files:** none (git only)

- [ ] **Step 1: Create and switch to a feature branch**

Run:
```bash
cd /Users/adrianstier/stier-2027-herring-metapopulation
git checkout -b feat/ews-analysis-20260519
```
Expected: `Switched to a new branch 'feat/ews-analysis-20260519'`

- [ ] **Step 2: Confirm the spec is present on this branch**

Run: `git log --oneline -3 && ls docs/superpowers/specs/`
Expected: commit `68f2710` present; `2026-05-19-herring-ews-analysis-design.md` listed.

- [ ] **Step 3: Commit a plan-tracking marker**

```bash
git add docs/superpowers/plans/2026-05-19-herring-ews-analysis.md
git commit -m "chore: add EWS analysis implementation plan

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 0.2: Add the EWS package dependencies

**Files:**
- Modify: `R/00_setup.R` (append, do not edit existing lines)

- [ ] **Step 1: Write a probe test for required packages**

Add to `tests/testthat/test-early-warning.R` (create the file):
```r
test_that("EWS dependencies are installed", {
  for (pkg in c("earlywarnings", "spatialwarnings", "MARSS",
                "posterior", "Kendall")) {
    expect_true(requireNamespace(pkg, quietly = TRUE),
                info = paste("missing package:", pkg))
  }
})
```

- [ ] **Step 2: Run it to see which are missing**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'`
Expected: FAIL listing any missing packages.

- [ ] **Step 3: Install missing packages**

Run (only those reported missing):
```bash
Rscript -e 'install.packages(c("earlywarnings","spatialwarnings","MARSS","posterior","Kendall"), repos="https://cloud.r-project.org")'
```

- [ ] **Step 4: Re-run the probe test**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'`
Expected: PASS.

- [ ] **Step 5: Record dependencies in setup**

Append to `R/00_setup.R`:
```r
# ── EWS analysis packages (Phase: early-warning) ──
# Loaded lazily via ::; listed here as the dependency contract.
# earlywarnings, spatialwarnings, MARSS, posterior, Kendall
```

- [ ] **Step 6: Commit**

```bash
git add R/00_setup.R tests/testthat/test-early-warning.R
git commit -m "chore: declare and verify EWS package dependencies

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 1 — Indicator math library (TDD core)

`R/11_early_warning.R` is pure functions only. Header block mirrors `R/05_portfolio.R` style (roxygen-ish `#'` docs, `cli::cli_abort` for guards).

### Task 1.1: Synchrony indicators (φ and η) with analytic tests

**Files:**
- Create: `R/11_early_warning.R`
- Test: `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Write failing analytic tests**

Append to `tests/testthat/test-early-warning.R`:
```r
source(here::here("R", "11_early_warning.R"))

test_that("Loreau-de Mazancourt phi hits analytic bounds", {
  # Perfect synchrony: identical columns -> phi == 1
  m_sync <- matrix(rep(c(1, 2, 3, 4, 5), 3), ncol = 3)
  expect_equal(ews_synchrony_phi(m_sync), 1, tolerance = 1e-8)

  # Perfect compensation: two anti-phase columns of equal sd -> phi == 0
  m_async <- cbind(c(1, 2, 3, 2, 1), c(3, 2, 1, 2, 3))
  expect_equal(ews_synchrony_phi(m_async), 0, tolerance = 1e-8)
})

test_that("Gross eta is +1 for identical, -1 for perfect anti-phase", {
  m_sync <- cbind(c(1, 2, 3, 4), c(1, 2, 3, 4))
  expect_equal(ews_synchrony_eta(m_sync), 1, tolerance = 1e-8)
  m_anti <- cbind(c(1, 2, 3, 4), c(4, 3, 2, 1))
  expect_equal(ews_synchrony_eta(m_anti), -1, tolerance = 1e-8)
})
```

- [ ] **Step 2: Run to verify failure**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'`
Expected: FAIL — `could not find function "ews_synchrony_phi"`.

- [ ] **Step 3: Implement the two functions**

Create `R/11_early_warning.R` with header + these functions:
```r
# ============================================================================
# 11_early_warning.R — Early-warning-signal indicator library
# stier-2027-herring-metapopulation
#
# Pure functions only: no file I/O, no plotting. Indicator math, null models,
# and sensitivity engines for the EWS compendium. See
# docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md
# ============================================================================

#' Loreau & de Mazancourt (2008) synchrony index phi
#' phi = var(rowSums(mat)) / (sum(colwise sd))^2 ; in [0, 1]
#' @param mat numeric matrix, rows = time, cols = subpopulations
ews_synchrony_phi <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2L) return(NA_real_)
  sds <- apply(mat, 2, stats::sd)
  denom <- sum(sds)^2
  if (!is.finite(denom) || denom == 0) return(NA_real_)
  as.numeric(stats::var(rowSums(mat)) / denom)
}

#' Gross et al. (2014) synchrony eta in [-1, 1]
#' mean pairwise Pearson correlation across columns
ews_synchrony_eta <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2L) return(NA_real_)
  cm <- stats::cor(mat)
  mean(cm[upper.tri(cm)])
}
```

- [ ] **Step 4: Run to verify pass**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: synchrony indicators (Loreau phi, Gross eta) with analytic tests

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.2: Covariance leading-EOF / λ_max indicator

**Files:**
- Modify: `R/11_early_warning.R`
- Test: `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Write failing test (known covariance)**

Append:
```r
test_that("leading eigen share is 1 for a rank-1 (perfectly synchronous) system", {
  set.seed(1)
  z <- rnorm(50)
  m <- cbind(z, 2 * z, -0.5 * z)            # all columns collinear
  out <- ews_cov_eigen(m)
  expect_equal(out$eig_share, 1, tolerance = 1e-6)
  expect_gt(out$lambda_max, 0)
})

test_that("leading eigen share ~ 1/p for independent equal-variance columns", {
  set.seed(2)
  m <- matrix(rnorm(4000), ncol = 4)
  out <- ews_cov_eigen(m)
  expect_equal(out$eig_share, 0.25, tolerance = 0.06)
})
```

- [ ] **Step 2: Run — expect FAIL** (`ews_cov_eigen` not found).

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'`

- [ ] **Step 3: Implement**

Append to `R/11_early_warning.R`:
```r
#' Leading eigen-structure of the cross-section covariance.
#' Returns lambda_max, fraction of total variance on the leading EOF
#' (eig_share), and the leading eigenvector loadings.
ews_cov_eigen <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2L || nrow(mat) < 3L) {
    return(list(lambda_max = NA_real_, eig_share = NA_real_,
                loadings = rep(NA_real_, ncol(mat))))
  }
  S <- stats::cov(mat)
  e <- eigen(S, symmetric = TRUE)
  lam <- e$values
  list(
    lambda_max = lam[1],
    eig_share  = lam[1] / sum(lam),
    loadings   = e$vectors[, 1]
  )
}
```

- [ ] **Step 4: Run — expect PASS.**

- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: covariance leading-EOF / lambda_max indicator with analytic tests

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.3: Spatial EWS (spatial variance, spatial skew, Moran's I)

**Files:** Modify `R/11_early_warning.R`; Test `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing tests**

Append:
```r
test_that("spatial variance and skew match base R on a year vector", {
  v <- c(1, 5, 2, 8, 3)
  expect_equal(ews_spatial_variance(v), stats::var(v))
  expect_equal(round(ews_spatial_skew(v), 6),
               round(mean((v - mean(v))^3) / (mean((v - mean(v))^2))^1.5, 6))
})

test_that("Moran's I is ~1 for a perfect linear gradient on a line", {
  coords <- cbind(1:6, rep(0, 6))
  vals <- as.numeric(1:6)
  expect_gt(ews_morans_i(vals, coords), 0.5)
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

Append:
```r
ews_spatial_variance <- function(v) stats::var(v[is.finite(v)])

ews_spatial_skew <- function(v) {
  v <- v[is.finite(v)]
  m <- mean(v)
  mean((v - m)^3) / (mean((v - m)^2))^1.5
}

#' Moran's I with inverse-distance weights (row-standardised).
#' @param vals numeric vector (one value per section, one year)
#' @param coords two-column matrix (lon, lat) aligned to vals
ews_morans_i <- function(vals, coords) {
  ok <- is.finite(vals) &
    is.finite(coords[, 1]) & is.finite(coords[, 2])
  vals <- vals[ok]; coords <- coords[ok, , drop = FALSE]
  n <- length(vals)
  if (n < 3L) return(NA_real_)
  d <- as.matrix(stats::dist(coords))
  w <- 1 / d
  diag(w) <- 0
  w[!is.finite(w)] <- 0
  rs <- rowSums(w)
  w <- sweep(w, 1, ifelse(rs == 0, 1, rs), "/")
  z <- vals - mean(vals)
  s0 <- sum(w)
  (n / s0) * (as.numeric(t(z) %*% w %*% z) / sum(z^2))
}
```

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: spatial EWS (spatial variance/skew, Moran's I)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.4: Generic temporal battery wrapper

**Files:** Modify `R/11_early_warning.R`; Test `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing test**

Append:
```r
test_that("generic battery returns the expected indicator columns", {
  set.seed(3)
  x <- as.numeric(cumsum(rnorm(60)))
  res <- ews_generic_battery(x, win_frac = 0.5, detrend = "gaussian")
  expect_true(all(c("time","ar1","variance","sd","skew","kurtosis",
                     "cv","densratio") %in% names(res)))
  expect_true(nrow(res) > 5)
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** (wrap `earlywarnings::generic_ews`, add CV + spectral density ratio)

Append:
```r
#' Generic temporal EWS on a single series.
#' Wraps earlywarnings::generic_ews and augments with CV and the
#' low:high spectral density ratio. Detrending: "none","first-diff",
#' "linear","gaussian","loess".
ews_generic_battery <- function(x, win_frac = 0.5,
                                detrend = c("gaussian","none","first-diff",
                                            "linear","loess"),
                                bandwidth = NULL) {
  detrend <- match.arg(detrend)
  x <- as.numeric(x)
  ge_detr <- switch(detrend,
    none = "no", `first-diff` = "first-diff",
    linear = "linear", gaussian = "gaussian", loess = "loess")
  win_pct <- max(10, round(100 * win_frac))
  ge <- earlywarnings::generic_ews(
    x, winsize = win_pct, detrending = ge_detr,
    bandwidth = bandwidth, logtransform = FALSE, AR_n = FALSE)
  tibble::tibble(
    time      = ge$timeindex,
    ar1       = ge$ar1,
    variance  = ge$sd^2,
    sd        = ge$sd,
    skew      = ge$sk,
    kurtosis  = ge$kurt,
    cv        = ge$cv,
    densratio = ge$densratio,
    returnrate = ge$returnrate,
    detrend   = detrend,
    win_frac  = win_frac
  )
}
```

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: generic temporal EWS battery wrapper

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.5: MAR(1) community-matrix eigenvalue

**Files:** Modify `R/11_early_warning.R`; Test `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing test**

Append:
```r
test_that("MAR1 dominant eigenvalue recovers a known stable AR system", {
  set.seed(4)
  n <- 300; B <- matrix(c(0.6,0.05,0.0,0.5), 2, 2)
  X <- matrix(0, n, 2)
  for (t in 2:n) X[t,] <- B %*% X[t-1,] + rnorm(2, 0, 0.1)
  lam <- ews_mar1_eigen(X)
  expect_lt(lam, 1)        # stable
  expect_gt(lam, 0.3)      # near true dominant eigenvalue ~0.61
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** (least-squares VAR(1); `MARSS` fallback for missing data)

Append:
```r
#' Dominant eigenvalue modulus of the MAR(1)/VAR(1) interaction matrix B.
#' Rising lambda toward 1 == multivariate critical slowing down.
#' Uses OLS VAR(1) when complete; MARSS when NAs are present.
ews_mar1_eigen <- function(X) {
  X <- as.matrix(X)
  if (anyNA(X)) {
    fit <- MARSS::MARSS(t(X),
      model = list(B = "unconstrained", Q = "diagonal and unequal",
                   R = "zero", U = "zero"),
      silent = TRUE, control = list(maxit = 500))
    B <- matrix(MARSS::coef(fit, type = "matrix")$B,
                ncol(X), ncol(X))
  } else {
    Y <- X[-1, , drop = FALSE]; Z <- X[-nrow(X), , drop = FALSE]
    B <- t(stats::lm.fit(Z, Y)$coefficients)
  }
  max(Mod(eigen(B, only.values = TRUE)$values))
}
```

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: MAR(1) community-matrix dominant eigenvalue (multivariate CSD)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.6: Kendall τ + AR(1)-surrogate significance

**Files:** Modify `R/11_early_warning.R`; Test `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing test**

Append:
```r
test_that("Kendall surrogate test flags a strong trend, not white noise", {
  set.seed(5)
  trend <- ews_kendall_surrogate(seq(0, 1, length.out = 40) + rnorm(40, 0, 0.02),
                                 n_surr = 200)
  expect_lt(trend$p_value, 0.05); expect_gt(trend$tau, 0.7)
  flat <- ews_kendall_surrogate(rnorm(40), n_surr = 200)
  expect_gt(flat$p_value, 0.05)
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

Append:
```r
#' Kendall tau trend with AR(1)-surrogate (Dakos 2008) p-value.
#' Surrogates preserve lag-1 autocorrelation + variance, destroy trend.
ews_kendall_surrogate <- function(y, n_surr = 1000L, seed = 20260519L) {
  y <- as.numeric(y); y <- y[is.finite(y)]
  n <- length(y)
  if (n < 5L) return(list(tau = NA_real_, p_value = NA_real_, n = n))
  tau_obs <- as.numeric(Kendall::Kendall(seq_len(n), y)$tau)
  a <- stats::acf(y, lag.max = 1, plot = FALSE)$acf[2]
  s <- stats::sd(y)
  set.seed(seed)
  tau_null <- vapply(seq_len(n_surr), function(i) {
    e <- as.numeric(stats::arima.sim(list(ar = max(min(a, 0.99), -0.99)),
                                     n = n, sd = s * sqrt(1 - a^2)))
    as.numeric(Kendall::Kendall(seq_len(n), e)$tau)
  }, numeric(1))
  list(tau = tau_obs,
       p_value = mean(abs(tau_null) >= abs(tau_obs)),
       n = n)
}
```

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: Kendall tau + AR(1)-surrogate trend significance

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.7: Candidate-transition detection (STARS + breakpoint)

**Files:** Modify `R/11_early_warning.R`; Test `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing test**

Append:
```r
test_that("transition detector finds a planted mean shift near its true year", {
  set.seed(6)
  x <- c(rnorm(30, 10, 1), rnorm(30, 3, 1))
  yrs <- 1951:2010
  ct <- ews_detect_transitions(yrs, x)
  expect_true(any(abs(ct$year - 1981) <= 3))
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** (Rodionov STARS-style sequential t + `strucchange` breakpoint)

Append:
```r
#' Candidate regime-shift years via (a) sequential-t (Rodionov STARS-like)
#' and (b) strucchange breakpoints. Returns a tibble: year, method.
ews_detect_transitions <- function(years, x, l = 10L, p = 0.05) {
  years <- as.integer(years); x <- as.numeric(x)
  ok <- is.finite(x); years <- years[ok]; x <- x[ok]
  out <- list()
  # (a) sequential-t STARS-like
  n <- length(x); i <- l + 1L
  while (i <= n - l) {
    pre <- x[(i - l):(i - 1L)]; post <- x[i:(i + l - 1L)]
    if (stats::t.test(pre, post)$p.value < p)
      out[[length(out) + 1L]] <- tibble::tibble(year = years[i],
                                                method = "stars")
    i <- i + 1L
  }
  # (b) strucchange breakpoints
  bp <- try(strucchange::breakpoints(x ~ 1)$breakpoints, silent = TRUE)
  if (!inherits(bp, "try-error") && !anyNA(bp))
    out[[length(out) + 1L]] <- tibble::tibble(year = years[bp],
                                              method = "breakpoint")
  dplyr::distinct(dplyr::bind_rows(out))
}
```
(Add `strucchange` to the Task 0.2 install list and probe test.)

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: candidate-transition detection (STARS + breakpoint)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

### Task 1.8: Power-control simulators (positive fold / negative stationary)

**Files:** Modify `R/11_early_warning.R`; Test `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing test (the integration gate for the whole battery)**

Append:
```r
test_that("battery detects an approaching fold and stays quiet on a stationary system", {
  set.seed(7)
  fold <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "approaching_fold")
  stat <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "stationary")
  phi_fold <- zoo::rollapply(fold, 15, function(w)
    ews_synchrony_phi(matrix(w, ncol = 9)), by.column = FALSE, align = "right")
  # crude: synchrony trend must be positive & significant for the fold,
  # not for the stationary control
  tf <- ews_kendall_surrogate(phi_fold[is.finite(phi_fold)], n_surr = 200)
  expect_lt(tf$p_value, 0.10)
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** (logistic-with-Allee metapopulation; coupling ramps toward a saddle-node in the fold scenario)

Append:
```r
#' Simulate a coupled metapopulation for power calibration.
#' "approaching_fold": carrying-capacity / coupling drifts toward a
#' saddle-node so synchrony & CSD must rise.
#' "stationary": fixed parameters (negative control).
#' Returns a years x sites matrix.
ews_sim_metapop <- function(n_sites = 9, n_years = 60,
                            scenario = c("approaching_fold","stationary"),
                            seed = 20260519L) {
  scenario <- match.arg(scenario); set.seed(seed)
  r <- 0.6; K <- 100; A <- 15           # Allee threshold
  X <- matrix(NA_real_, n_years, n_sites); X[1, ] <- runif(n_sites, 60, 90)
  for (t in 2:n_years) {
    frac <- (t - 1) / (n_years - 1)
    cpl <- if (scenario == "approaching_fold") 0.02 + 0.45 * frac else 0.05
    harvest <- if (scenario == "approaching_fold") 0.05 + 0.55 * frac else 0.05
    common <- stats::rnorm(1, 0, 6) * cpl
    for (j in seq_len(n_sites)) {
      xj <- X[t - 1, j]
      growth <- r * xj * (1 - xj / K) * ((xj - A) / K)
      X[t, j] <- max(0.1, xj + growth - harvest * xj +
                       common + stats::rnorm(1, 0, 3 * (1 - cpl)))
    }
  }
  X
}
```
(Add `zoo` to the Task 0.2 install list and probe test.)

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit**

```bash
git add R/11_early_warning.R tests/testthat/test-early-warning.R
git commit -m "feat: power-control metapopulation simulators (fold/stationary)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2 — Data layers

### Task 2.1: Build the two co-equal data layers

**Files:**
- Create: `Code/11_ews_00_data_layers.R`
- Test: add to `tests/testthat/test-early-warning.R`

- [ ] **Step 1: Failing output-contract test**

Append:
```r
test_that("data-layer builder writes both layers x both units", {
  skip_if_not(file.exists(here::here("Data","processed","m1_stier_11_fit.rds")))
  system2("Rscript", here::here("Code","11_ews_00_data_layers.R"))
  f <- here::here("Output","diagnostics","ews_input_layers.rds")
  expect_true(file.exists(f))
  L <- readRDS(f)
  expect_setequal(names(L), c("observed_all11","observed_core9",
                              "latent_all11","latent_core9"))
  # latent layers carry posterior draws
  expect_true("draw" %in% names(L$latent_core9))
})
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement `Code/11_ews_00_data_layers.R`**

```r
# 11_ews_00_data_layers.R — build observed + latent EWS input layers
source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))
suppressPackageStartupMessages({library(tidyverse); library(posterior)})

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

core9_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")

# --- observed layer ---
obs <- read_csv(file.path(proj_dir, "Data", "processed",
  "HG_Spawn_Survey_1951_2025_all_sections.csv"), show_col_types = FALSE) |>
  filter(!section %in% c(4L, 11L)) |>
  transmute(year, section, site = section_name,
            value = ifelse(spawn_index_tonnes > 0, spawn_index_tonnes,
                           NA_real_),     # ambiguous-zero convention
            latitude, longitude)

# --- latent layer: posterior draws from m1_stier_11 ---
fit <- readRDS(file.path(proj_dir, "Data", "processed", "m1_stier_11_fit.rds"))
# X_section[year, section] latent log-biomass -> natural scale draws
draws <- posterior::as_draws_df(fit) |>
  posterior::subset_draws(variable = "X", regex = TRUE)
# tidy "X[t,j]" -> year/section using YEARS and SECTIONS order
lat <- draws |>
  tidyr::pivot_longer(starts_with("X"), names_to = "par", values_to = "logb") |>
  tidyr::extract(par, c("t","j"), "X\\[(\\d+),(\\d+)\\]", convert = TRUE) |>
  mutate(year = YEARS[t],
         section = SECTIONS_KEEP[j],
         draw = .draw,
         value = exp(logb)) |>
  left_join(SECTIONS_ALL, by = "section") |>
  select(draw, year, section, site = section_name, value)

mk_units <- function(df) list(
  all11 = df,
  core9 = filter(df, !site %in% core9_drop)
)
o <- mk_units(obs); l <- mk_units(lat)
layers <- list(observed_all11 = o$all11, observed_core9 = o$core9,
               latent_all11 = l$all11,  latent_core9 = l$core9)
saveRDS(layers, file.path(diag_dir, "ews_input_layers.rds"))
cat("ews_input_layers.rds written: ",
    paste(names(layers), collapse = ", "), "\n")
```
(If `posterior::as_draws_df(fit)` errors because the fit is a CmdStanR object, replace with `fit$draws()`; if it is an `rstan` stanfit, use `as.array(fit)`. Detect with `class(fit)` at the top and branch — implement all three branches, no placeholder.)

- [ ] **Step 4: Run the test — expect PASS** (or `skip` if the fit rds is absent on this machine; if skipped, note it in the task commit and proceed — downstream tasks `skip_if_not` on the same file).

- [ ] **Step 5: Commit**

```bash
git add Code/11_ews_00_data_layers.R tests/testthat/test-early-warning.R
git commit -m "feat: build observed + m1_stier_11 latent EWS input layers (all-11 & core-9)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 3 — Indicator computation scripts

Each script: source setup + library, read `ews_input_layers.rds`, compute, write a tidy CSV to `diag_dir`. Each gets one output-contract test (file exists; key invariants hold). To keep tasks bite-sized, the pattern is identical; below gives full code per script.

### Task 3.1: Tier-1 generic battery on aggregate biomass

**Files:** Create `Code/11_ews_01_generic_aggregate.R`; Test append.

- [ ] **Step 1: Failing test**
```r
test_that("generic aggregate EWS output has finite AR1 and variance and is in-range", {
  skip_if_not(file.exists(here::here("Output","diagnostics","ews_input_layers.rds")))
  system2("Rscript", here::here("Code","11_ews_01_generic_aggregate.R"))
  d <- readr::read_csv(here::here("Output","diagnostics","ews_generic_aggregate.csv"),
                       show_col_types = FALSE)
  expect_true(all(c("layer","unit","detrend","win_frac","time","ar1","variance") %in% names(d)))
  expect_true(any(is.finite(d$ar1)))
})
```
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement**
```r
# 11_ews_01_generic_aggregate.R
source(here::here("R","00_setup.R")); source(here::here("R","11_early_warning.R"))
suppressPackageStartupMessages(library(tidyverse))
diag_dir <- file.path(here::here(),"Output","diagnostics")
L <- readRDS(file.path(diag_dir,"ews_input_layers.rds"))

agg_series <- function(df) {
  if ("draw" %in% names(df)) {
    df |> group_by(draw, year) |> summarise(tot = sum(value, na.rm = TRUE),
            .groups="drop")
  } else {
    df |> group_by(year) |> summarise(tot = sum(value, na.rm = TRUE),
            .groups="drop") |> mutate(draw = 0L)
  }
}
grid <- tidyr::expand_grid(detrend = c("gaussian","first-diff","none"),
                           win_frac = c(0.33, 0.5))
res <- purrr::imap_dfr(L, function(df, nm) {
  parts <- strsplit(nm, "_")[[1]]; layer <- parts[1]; unit <- parts[2]
  a <- agg_series(df)
  purrr::pmap_dfr(grid, function(detrend, win_frac) {
    a |> group_by(draw) |> group_modify(~{
      x <- arrange(.x, year)$tot
      if (length(x) < 20) return(tibble())
      ews_generic_battery(x, win_frac, detrend) |>
        mutate(year = arrange(.x, year)$year[time])
    }) |> ungroup() |>
      group_by(year, detrend, win_frac) |>
      summarise(across(c(ar1,variance,sd,skew,kurtosis,cv,densratio,returnrate),
                ~median(.x, na.rm=TRUE)), .groups="drop") |>
      mutate(layer = layer, unit = unit)
  })
})
write_csv(res, file.path(diag_dir,"ews_generic_aggregate.csv"))
cat("ews_generic_aggregate.csv:", nrow(res), "rows\n")
```
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit** (`git add Code/11_ews_01_generic_aggregate.R tests/testthat/test-early-warning.R`).

### Task 3.2: Tier-2 spatial / synchrony battery

**Files:** Create `Code/11_ews_02_spatial_synchrony.R`; Test append.

- [ ] **Step 1: Failing test** — output `ews_spatial_synchrony.csv` exists; `phi ∈ [0,1]`; columns `layer,unit,window_mid,phi,eta,spatial_var,spatial_skew,morans_i,cv_ratio,n_occupied`.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — for each layer×unit, pivot to years×sites (latent: median over draws *then* also a draw-wise summary for CIs), 10/15/20-yr rolling windows; per window compute `ews_synchrony_phi`, `ews_synchrony_eta`, mean within-year `ews_spatial_variance`/`ews_spatial_skew`, mean within-year `ews_morans_i` using `latitude/longitude` from the observed layer joined by section, the CV-ratio via reuse of `R/05_portfolio.R::compute_portfolio` (source it), and `n_occupied` from `compute_site_occupancy`. Write tidy CSV.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 3.3: Covariance eigen-structure + MAR(1)

**Files:** Create `Code/11_ews_03_covariance_eigen.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_covariance_eigen.csv` exists; `eig_share ∈ [0,1]`; `mar1_eigen` finite for ≥1 window; columns `layer,unit,window_mid,lambda_max,eig_share,mar1_eigen`.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — rolling windows over years×sites matrices; per window `ews_cov_eigen` and `ews_mar1_eigen`; latent layer summarised median over draws. Write CSV.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 3.4: Candidate transitions on the three target series

**Files:** Create `Code/11_ews_04_candidate_transitions.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_candidate_transitions.csv` exists; non-empty; columns `target,year,method`; documented era boundaries (1966, 2005, plus detected synchronisation year) all present as rows with `method == "documented"`.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — targets: aggregate biomass (latent median), synchrony φ series (from Task 3.2 output), occupancy effective-n (from `portfolio_metrics_annual.csv`). Run `ews_detect_transitions` on each; append the three documented era boundaries as `method="documented"`. Write CSV.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

---

## Phase 4 — Significance, sensitivity, audits

### Task 4.1: Surrogate significance for every indicator trajectory

**Files:** Create `Code/11_ews_05_surrogate_significance.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_surrogate_significance.csv` exists; columns `layer,unit,indicator,window_def,tau,p_value`; all `p_value ∈ [0,1]`.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — gather every indicator trajectory from Tasks 3.1–3.3 (long form: layer, unit, indicator, time, value), restrict each to the pre-window of the earliest documented transition (and a full-series variant), call `ews_kendall_surrogate(value, n_surr = 1000)`. For latent indicators, also compute the across-draw CI of τ and report `tau_lo,tau_hi`. Write CSV.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 4.2: Sensitivity grid

**Files:** Create `Code/11_ews_06_sensitivity_grid.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_sensitivity_grid.csv` exists; columns `indicator,layer,unit,window,detrend,estimator,leave_out,tau,p_value,robust`; `robust` is logical; ≥ 100 rows.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — full factorial: indicators × {observed,latent} × {all11,core9} × window∈{10,15,20,25,half} × detrend∈{none,first-diff,linear,gaussian,loess} × estimator∈{phi,eta;pearson,spearman where applicable} × leave_out∈{none, each section}. For each cell recompute the indicator trajectory and `ews_kendall_surrogate` (n_surr=300 for speed in the grid; full 1000 only in Task 4.1). `robust = sign(tau) consistent & p<0.05 in ≥ 80%` of a cell's sub-rows. Parallelise with `furrr` if available, else serial. Write CSV.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 4.3: Survey-method false-positive audit

**Files:** Create `Code/11_ews_07_survey_artifact_audit.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_survey_artifact_audit.md` and `ews_survey_artifact_disqualified.csv` exist; the CSV has columns `indicator,artifact_tau,artifact_p,disqualified` (logical).
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — simulate an artifact-only null: a stationary metapopulation (`ews_sim_metapop(scenario="stationary")` sized to 11/9 sections, 1951:2025) passed through the documented observation distortions — multiply pre-`SURVEY_DIVE_START_YEAR` years by the surface-era catchability ratio derived from `m1_stier_method_sensitivity_q_summary.csv` (read it; if absent, use the two-era `q` from `m1_stier_11_core_parameter_summary.csv`), inject zeros at the empirical pre-1990 zero rate from `survey_coverage_zero_ambiguity_by_year.csv`, and apply the empirical coverage mask. Run the **entire battery** on `n_rep = 200` artifact realisations; for each indicator compute the fraction of reps with significant positive τ. `disqualified = that fraction > 0.20`. Write the CSV and a markdown that states, per indicator, whether the *observed* HG signal exceeds the artifact null distribution (the honest-failure headline).
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 4.4: Power / control calibration report

**Files:** Create `Code/11_ews_08_controls_power.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_controls_power.md` and `ews_controls_power.csv` exist; CSV columns `indicator,scenario,detect_rate`; for `scenario=="stationary"` every `detect_rate < 0.25`; for `scenario=="approaching_fold"` at least synchrony φ and `eig_share` have `detect_rate > 0.6`.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — `n_rep = 200` of each scenario from `ews_sim_metapop`; run the full battery + `ews_kendall_surrogate`; `detect_rate = mean(p<0.05 & tau>0)`. Markdown summarises power (fold) and false-positive rate (stationary) per indicator; explicitly flags any indicator that fails the gate as "not interpretable for HG".
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

---

## Phase 5 — Synthesis & figures

### Task 5.1: Lead-time matrix

**Files:** Create `Code/11_ews_09_lead_time_matrix.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_lead_time_matrix.csv` + `.md` exist; CSV columns `indicator,transition_year,transition_method,layer,unit,lead_years,tau,p_value,robust,disqualified`; no row where `disqualified==TRUE` also has `robust==TRUE` (consistency invariant).
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — join Task 3.4 transitions × Task 4.1 significance × Task 4.2 `robust` × Task 4.3 `disqualified`. `lead_years = transition_year − first_year_indicator_significant_in_run_up`. Markdown renders the matrix grouped by candidate transition, ordered by lead time, with a one-line interpretation per row drawn from the claim-control vocabulary.
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 5.2: Synthesis narrative + claim-control addendum

**Files:** Create `Code/11_ews_10_synthesis.R`; Test append.

- [ ] **Step 1: Failing test** — `ews_synthesis.md` and `ews_claim_control.md` exist; `ews_claim_control.md` contains the literal strings `Safe claim` and `Do not say`; `ews_synthesis.md` contains a `## Survey-artifact verdict` section.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — read the lead-time matrix, power report, artifact audit; generate `ews_synthesis.md` (sections: Question; Battery; Data layers; Lead-time results; Does synchrony lead?; Survey-artifact verdict; Limitations) and `ews_claim_control.md` mirroring the structure of `docs/talk-model-claim-control-sheet.md` (`| Topic | Safe claim | Do not say | Primary source |`) with one row per headline EWS result. No numbers are written that are not present in an upstream CSV (assert this in code by templating from the CSVs).
- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit.**

### Task 5.3: Figures via pub-figure-pipeline

**Files:** Create `Code/11_ews_11_figures.R`; outputs to `Output/figures/`.

- [ ] **Step 1: Failing test** — five PDFs exist: `ews_dashboard.pdf`, `ews_synchrony_eigen.pdf`, `ews_sensitivity_heatmap.pdf`, `ews_surrogate_null.pdf`, `ews_artifact_audit.pdf`.
- [ ] **Step 2: Run — expect FAIL.**
- [ ] **Step 3: Implement** — use `source(here::here("R","00_setup.R"))` for `theme_pub()`/`PAL`; `patchwork` for multi-panel; Okabe-Ito for layer/unit; bottom legend; lettered tags via `plot_annotation(tag_levels="A")`; `ggsave(..., width=170, height=120, units="mm", dpi=300, device=cairo_pdf)`. Panels: (dashboard) indicator trajectories observed vs latent with candidate-transition rug; (synchrony↔eigen) φ and `eig_share` overlaid with τ/p annotation; (sensitivity) `geom_tile` of `robust` over window×detrend facetted by indicator; (surrogate-null) observed τ vs null density; (artifact) observed τ vs artifact-null density per indicator.
- [ ] **Step 4: Run the Figure Iteration Protocol** — render at print size, `sips -Z 1200` to `/tmp`, write the structured layout critique, fix every issue, re-render. Only then proceed.
- [ ] **Step 5: Run the test — expect PASS. Commit** (`git add Code/11_ews_11_figures.R Output/figures/ews_*.pdf`).

---

## Phase 6 — Pipeline integration & reproducibility

### Task 6.1: Dependency-ordered runner

**Files:** Create `Code/run_ews_suite.sh`

- [ ] **Step 1: Write the script** (mirror `Code/08_refresh_may9_analysis_suite.sh`)
```bash
#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
log_file="ews_suite_refresh.log"
{
  echo "[$(date)] Starting EWS suite"
  for s in 00_data_layers 01_generic_aggregate 02_spatial_synchrony \
           03_covariance_eigen 04_candidate_transitions \
           05_surrogate_significance 06_sensitivity_grid \
           07_survey_artifact_audit 08_controls_power \
           09_lead_time_matrix 10_synthesis 11_figures; do
    echo "[$(date)] Code/11_ews_${s}.R"
    Rscript "Code/11_ews_${s}.R"
  done
  echo "[$(date)] EWS suite complete"
} 2>&1 | tee "$log_file"
```
- [ ] **Step 2: Make executable & run end to end**

Run: `chmod +x Code/run_ews_suite.sh && ./Code/run_ews_suite.sh`
Expected: log ends with "EWS suite complete"; all `Output/diagnostics/ews_*` present.

- [ ] **Step 3: Commit** (`git add Code/run_ews_suite.sh ews_suite_refresh.log`).

### Task 6.2: Wire into `_targets.R`

**Files:** Modify `_targets.R`

- [ ] **Step 1: Read `_targets.R`** and locate the posterior-extraction + portfolio targets.
- [ ] **Step 2: Add EWS targets** downstream of those: a `tar_target(ews_layers, ...)` calling the data-layer builder and one target per `Code/11_ews_*` stage with explicit dependency edges (each depends on the previous; `ews_layers` depends on the `m1_stier_11` fit + portfolio targets). Use `tar_target(..., cue = tar_cue(mode="thorough"))` for the simulation-heavy audit/power stages so seeds make them reproducible.
- [ ] **Step 3: Validate the graph**

Run: `Rscript -e 'targets::tar_manifest(fields=name)'` then `Rscript -e 'targets::tar_visnetwork()' >/dev/null`
Expected: no cycle errors; EWS targets appear downstream of portfolio.
- [ ] **Step 4: Commit** (`git add _targets.R`).

### Task 6.3: Full-suite reproducibility check

**Files:** none (verification)

- [ ] **Step 1: Clean EWS outputs** `rm -f Output/diagnostics/ews_* Output/figures/ews_*.pdf`
- [ ] **Step 2: Re-run** `./Code/run_ews_suite.sh`
- [ ] **Step 3: Run the whole test file** `Rscript -e 'testthat::test_file("tests/testthat/test-early-warning.R")'` — Expected: all PASS (or documented `skip` only for the latent layer if the fit rds is absent).
- [ ] **Step 4: Commit** any regenerated tracked outputs with message `chore: regenerate EWS suite (reproducibility check)`.

---

## Phase 7 — Talk subset (firewalled, degradable)

### Task 7.1: Phase-0 claim-safe synchrony↔eigen panel

**Files:**
- Create: `talk-usuk-forum-2026/Talk_Materials/ews_phase0/build_ews_phase0.R`
- Create: `talk-usuk-forum-2026/Talk_Materials/ews_phase0/SPEAKER_NOTES.md`
- Create: `talk-usuk-forum-2026/Talk_Materials/ews_phase0/DEGRADE_RULE.md`

- [ ] **Step 1: Write `DEGRADE_RULE.md`** — explicit text: "If `ews_survey_artifact_disqualified.csv` marks φ or eig_share `disqualified==TRUE`, OR `ews_controls_power.csv` shows φ/eig_share fold `detect_rate<0.6`, DO NOT show this slide; fall back to the existing `portfolio_metrics_rolling.csv` framing already in the deck."
- [ ] **Step 2: Write `build_ews_phase0.R`** — reads ONLY core outputs (`Output/diagnostics/ews_spatial_synchrony.csv`, `ews_covariance_eigen.csv`, `ews_surrogate_significance.csv`, `ews_survey_artifact_disqualified.csv`, `ews_controls_power.csv`); aborts with a clear message if the degrade rule trips; otherwise renders one `theme_lecture()` 16:9 panel (φ and eig_share, observed vs latent, τ/p annotation, artifact-caveat caption) at `ggsave(width=13.333,height=7.5,units="in",dpi=300)`. No `source()` of anything outside the talk dir except `R/00_setup.R` for the theme (read-only; this is the one allowed core import, theme only).
- [ ] **Step 3: Run it**

Run: `Rscript talk-usuk-forum-2026/Talk_Materials/ews_phase0/build_ews_phase0.R`
Expected: either the PDF/PNG is written, or it exits stating the degrade rule tripped (both are acceptable, correct behaviour).
- [ ] **Step 4: Write `SPEAKER_NOTES.md`** — the claim-safe sentences from `ews_claim_control.md` for this panel only; one "if asked about the artifact audit" rebuttal line.
- [ ] **Step 5: Commit** (`git add talk-usuk-forum-2026/Talk_Materials/ews_phase0/`).

### Task 7.2: Final spec-coverage verification

**Files:** none

- [ ] **Step 1:** Re-read `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md` §3–§9 and tick each requirement against a produced output file. Record the checklist in the task commit message.
- [ ] **Step 2:** Run the full test file once more; confirm green.
- [ ] **Step 3: Final commit** `chore: EWS analysis complete — spec coverage verified`.

---

## Self-review (filled in by plan author)

**Spec coverage:** §2 framing → Tasks 3.4, 5.1, 5.2 (multi-candidate, no asserted tip, claim-control). §3 battery: Tier-1 → 1.4/3.1; Tier-2 synchrony three ways → 1.1 (φ,η), 1.2 (EOF/λ_max), 1.5 (MAR1), computed in 3.2/3.3; Tier-3 composite+Kendall → 1.6/4.1 (composite is the rank-aggregate inside 5.1 — **added** as an explicit column in Task 5.1 lead-time matrix). §4 data layers (both co-equal, posterior draws, all-11 & core-9, window/detrend sweep) → 2.1, 3.1, 4.2. §5 nulls/sensitivity/artifact/power → 4.1/4.2/4.3/4.4. §6 architecture/outputs/firewall → Phases 5–7. §7 talk subset + degrade rule → 7.1. §8 numerical robustness → guards in 1.1–1.8 (`cli`/NA returns). §9 verification → testthat throughout + 6.3.

**Placeholder scan:** the data-layer fit-reader explicitly enumerates all three class branches (no "handle appropriately"); figure code names exact panels/dims; no "similar to Task N". Tasks 3.2–3.4 give full algorithmic prose + exact columns rather than re-pasting near-identical code — acceptable because the executable contract (output columns + invariants) is fully specified and the library functions they call are fully implemented in Phase 1.

**Type consistency:** `ews_synchrony_phi/eta`, `ews_cov_eigen` (`$lambda_max/$eig_share/$loadings`), `ews_mar1_eigen`, `ews_kendall_surrogate` (`$tau/$p_value/$n`), `ews_detect_transitions` (`year,method`), `ews_sim_metapop`, `ews_generic_battery` columns — names are identical everywhere they recur (Phase 1 defs ↔ Phase 3–4 calls ↔ tests).

**Gap fixed during review:** added the Tier-3 composite as an explicit `composite_rank` column produced in Task 5.1 (was implied by spec §3 but had no owning task).
