# Herring Reversibility / Hysteresis / Alternative-State Analysis — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the HG-internal dynamical-systems analysis that tests whether the post-collapse herring metapopulation occupies a different attractor and whether non-recovery is path-dependent, delivering a hysteresis-vs-alternatives discrimination table — not an asserted transition.

**Architecture:** A pure-function R library (`R/12_reversibility.R`) holding all dynamical math (driver axis, effective-driver, EDM/S-map/CCM, potential landscape, regime models, driver-space loop, controls, discrimination), exercised by analytic `testthat` tests; a dependency-ordered `Code/12_reversibility_*.R` diagnostic family that loads inputs, calls the library, and writes `Output/diagnostics/reversibility_*`; pub-figure-pipeline figures; `_targets.R` + `Code/run_reversibility_suite.sh` integration. The committed Phase-0 spike (`Code/phase0_reversibility_hysteresis_spike.R`) is the descriptive precursor and warm-start.

**Tech Stack:** R, `testthat`, `renv`, `targets`; new deps `rEDM` (S-map/CCM, Sugihara school) + `multispatialCCM` (short-series spatial CCM) + `changepoint` (candidate transitions); base/`stats` for drift–diffusion and regime models; pub-figure-pipeline `theme_pub`.

**Spec:** `docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md`
**Sibling (do not assume executed):** `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md`. `detect_candidate_transitions()`/`survey_artifact_null()` are specced as EWS-shared but are NOT yet implemented (EWS plan unexecuted). This plan implements its own copies in the `R/12_reversibility.R` namespace; Phase 9 Task 24 records the dedupe obligation.

---

## Self-containment & firewall invariants (hold for every task)

- Nothing under `talk-usuk-forum-2026/` is ever `source()`d or read by `R/` or `Code/`. Talk pulls *from* these outputs only.
- Latent layer = `m1_stier_11` only. No held branches. No new Stan branches. No DFO-SCA as a data layer. Predator products enter the effective-driver composite as *context only*, provenance-tagged, no promoted coefficient.
- Every dynamical index is computed over `m1_stier_11` posterior draws → median + CI, never a point estimate, never collapsed before the CI.
- Fixed, recorded seeds on every surrogate/simulation/bootstrap step.
- Control-sheet language: outputs are descriptive/dynamical evidence, never "the system tipped"; the discrimination table keeps explanations (i)–(iv) all reachable, including the honest negative.

## File structure (decomposition locked here)

| Path | Responsibility |
|---|---|
| `R/12_reversibility.R` | Pure functions: `exploitation_rate`, `effective_driver`, `detect_candidate_transitions`, `survey_artifact_null`, `edm_embed`, `smap_nonlinearity`, `smap_jacobian_eigen`, `ccm_drivers`, `potential_landscape`, `regime_models`, `state_modality`, `driver_state_loop`, `reversibility_controls`, `discrimination_table`. No I/O. |
| `tests/testthat/test-reversibility.R` | Analytic-case unit tests for every library function (mirrors `test-early-warning.R` style). |
| `Code/12_reversibility_01_driver_axis.R` … `_10_discrimination_synthesis.R` | Dependency-ordered diagnostic scripts: load inputs, call the lib, write `Output/diagnostics/reversibility_*`. |
| `Code/run_reversibility_suite.sh` | zsh runner, `set -euo pipefail`, sequential, mirrors `Code/08_refresh_may9_analysis_suite.sh`. |
| `R/12_reversibility_figs.R` | pub-figure-pipeline figure builders (`theme_pub`). |
| `_targets.R` (modify, before final `)`) | Reversibility targets downstream of posterior extraction + portfolio. |
| `Output/diagnostics/reversibility_*` | Outputs per spec §6.2 (gitignored; `.md`/`.csv` force-added like the spike). |

## Phases

0 Branch & deps · 1 Driver + **effective-driver (prioritized)** · 2 Candidate-transitions + survey-artifact null · 3 EDM core · 4 Attractor/regime · 5 Driver-space loop · 6 Controls/power (integration test) · 7 Diagnostic scripts + discrimination synthesis · 8 Figures + targets + suite · 9 Dedupe/reconcile + final run.

---

## Phase 0 — Branch, dependencies, scaffolding

### Task 1: Feature branch + dependency probe

**Files:**
- Create: `tests/testthat/test-reversibility.R`
- Modify: `renv.lock` (via `renv::install`/`snapshot`)

- [ ] **Step 1: Create and switch to a feature branch**

Run:
```bash
cd /Users/adrianstier/stier-2027-herring-metapopulation
git checkout -b feat/reversibility-hysteresis-analysis
```
Expected: `Switched to a new branch 'feat/reversibility-hysteresis-analysis'`

- [ ] **Step 2: Write the failing dependency probe test**

Create `tests/testthat/test-reversibility.R`:
```r
library(testthat)
source(here::here("R/12_reversibility.R"))

test_that("reversibility dependencies are installed", {
  expect_true(requireNamespace("rEDM", quietly = TRUE))
  expect_true(requireNamespace("multispatialCCM", quietly = TRUE))
  expect_true(requireNamespace("changepoint", quietly = TRUE))
})
```

- [ ] **Step 3: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `cannot open file 'R/12_reversibility.R'` (and/or namespace not available).

- [ ] **Step 4: Install dependencies and create the empty library**

Run:
```bash
Rscript -e 'renv::install(c("rEDM","multispatialCCM","changepoint")); renv::snapshot(prompt = FALSE)'
```
Expected: packages install; `renv.lock` updated. If a source build fails, fall back to `install.packages(type="binary")` then `renv::snapshot()`; record the version actually pinned in the commit message.

Create `R/12_reversibility.R` with only a header comment:
```r
# R/12_reversibility.R
# Reversibility / hysteresis / alternative-state library (pure functions, no I/O).
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md
```

- [ ] **Step 5: Run the probe to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS (1 test).

- [ ] **Step 6: Commit**

```bash
git add tests/testthat/test-reversibility.R R/12_reversibility.R renv.lock
git commit -m "feat(reversibility): branch, deps (rEDM/multispatialCCM/changepoint), empty lib"
```

---

## Phase 1 — Driver axis + effective-driver reconstruction (prioritized: make-or-break)

### Task 2: `exploitation_rate()`

**Files:**
- Modify: `R/12_reversibility.R`
- Modify: `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-reversibility.R`:
```r
test_that("exploitation_rate = catch / biomass, NA- and zero-robust", {
  catch <- data.frame(year = 2000:2002, total_catch = c(50, 0, 30))
  bio   <- data.frame(year = 2000:2002, biomass = c(100, 200, 0))
  out <- exploitation_rate(catch, bio)
  expect_equal(out$u, c(0.5, 0.0, NA_real_))      # zero biomass -> NA, not Inf
  expect_equal(nrow(out), 3L)
  expect_true(all(c("year","total_catch","biomass","u") %in% names(out)))
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "exploitation_rate"`.

- [ ] **Step 3: Implement**

Append to `R/12_reversibility.R`:
```r
#' Exploitation-rate driver: u = annual total catch / latent biomass.
#' Zero/NA biomass -> NA (never Inf); inner-joined on year.
exploitation_rate <- function(catch_by_year, biomass_by_year) {
  m <- merge(catch_by_year, biomass_by_year, by = "year")
  m <- m[order(m$year), ]
  b <- m$biomass
  m$u <- ifelse(is.na(b) | b <= 0, NA_real_, m$total_catch / b)
  m[, c("year", "total_catch", "biomass", "u")]
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): exploitation_rate driver axis"
```

### Task 3: `effective_driver()` — composite net control parameter

**Files:**
- Modify: `R/12_reversibility.R`
- Modify: `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("effective_driver z-combines components, tags provenance, NA-robust", {
  df <- data.frame(
    year = 2000:2004,
    u            = c(0.4, 0.3, 0.0, 0.0, 0.0),   # fishing removed
    predation    = c(1, 1, 2, 3, 4),              # rises post-closure
    k_proxy      = c(0, 0, 1, 1, 2)               # higher = worse (K down)
  )
  out <- effective_driver(df,
            components = c("u","predation","k_proxy"),
            provenance = c(u="m1_stier_11", predation="predator-repo:context",
                           k_proxy="pdo_screen"))
  expect_true("effective_driver" %in% names(out))
  expect_equal(nrow(out), 5L)
  # fishing-only driver falls to 0 by 2002 but the composite need NOT:
  expect_gt(out$effective_driver[5], out$u[5])
  expect_identical(attr(out, "provenance")[["predation"]], "predator-repo:context")
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "effective_driver"`.

- [ ] **Step 3: Implement**

Append to `R/12_reversibility.R`:
```r
#' Effective (net) control parameter: standardize each component to z-scores
#' and average. Used ONLY for the discrimination layer (spec §2.4 explanation
#' ii). Components are provenance-tagged; predator inputs are context-only.
effective_driver <- function(df, components, provenance = character()) {
  z <- function(v) {
    s <- stats::sd(v, na.rm = TRUE)
    if (is.na(s) || s == 0) return(rep(0, length(v)))
    (v - mean(v, na.rm = TRUE)) / s
  }
  Z <- vapply(components, function(cn) z(df[[cn]]), numeric(nrow(df)))
  df$effective_driver <- rowMeans(Z, na.rm = TRUE)
  attr(df, "provenance") <- as.list(provenance)
  attr(df, "components") <- components
  df
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): effective_driver composite (provenance-tagged, context-only predators)"
```

---

## Phase 2 — Candidate transitions + survey-artifact null (self-contained)

### Task 4: `detect_candidate_transitions()`

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("detect_candidate_transitions finds a known mean shift, ignores noise", {
  set.seed(1)
  x_step <- c(rnorm(30, 0, 0.3), rnorm(30, 3, 0.3))           # shift at index 31
  yrs <- 1951:2010
  cp <- detect_candidate_transitions(x_step, yrs)
  expect_true(any(abs(cp$year - 1981) <= 2))                  # ~ index 31
  x_flat <- rnorm(60, 0, 0.3)
  cp0 <- detect_candidate_transitions(x_flat, yrs)
  expect_lte(nrow(cp0), 1L)                                   # ~no spurious cp
  expect_true(all(c("year","index","kind") %in% names(cp)))
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "detect_candidate_transitions"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Objective candidate regime-shift points via PELT mean+variance change
#' (changepoint::cpt.meanvar). Self-contained copy of the EWS-shared util;
#' Phase 9 records the dedupe obligation.
detect_candidate_transitions <- function(x, years, penalty = "MBIC") {
  stopifnot(length(x) == length(years))
  ok <- is.finite(x)
  cp <- changepoint::cpt.meanvar(as.numeric(x[ok]), method = "PELT",
                                 penalty = penalty)
  idx <- changepoint::cpts(cp)
  yy  <- years[ok]
  data.frame(year = yy[idx], index = idx,
             kind = rep("meanvar_PELT", length(idx)))
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): detect_candidate_transitions (PELT, self-contained)"
```

### Task 5: `survey_artifact_null()`

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("survey_artifact_null is seed-deterministic and injects only a q-shift", {
  truth <- rep(1000, 60)                           # NO resilience change
  a <- survey_artifact_null(truth, era_break = 30,
                            q = c(0.6, 1.0), seed = 42)
  b <- survey_artifact_null(truth, era_break = 30,
                            q = c(0.6, 1.0), seed = 42)
  expect_identical(a, b)                            # determinism
  expect_lt(mean(a[1:30]), mean(a[31:60]))          # q rises across the break
  expect_equal(length(a), 60L)
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "survey_artifact_null"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Survey-method false-positive generator: a series with NO resilience change
#' but the documented two-era catchability shift + lognormal obs error.
#' Self-contained copy of the EWS-shared util (Phase 9 dedupe).
survey_artifact_null <- function(truth, era_break, q, cv = 0.2, seed) {
  set.seed(seed)
  n <- length(truth)
  qv <- ifelse(seq_len(n) <= era_break, q[1], q[2])
  obs <- qv * truth * stats::rlnorm(n, -0.5 * cv^2, cv)
  as.numeric(obs)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): survey_artifact_null (deterministic q-shift, self-contained)"
```

---

## Phase 3 — EDM core (Sugihara school)

### Task 6: `edm_embed()` — simplex embedding dimension & predictability

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("edm_embed recovers low embedding dim for the logistic map", {
  x <- numeric(200); x[1] <- 0.4
  for (i in 2:200) x[i] <- 3.8 * x[i-1] * (1 - x[i-1])   # chaotic logistic
  e <- edm_embed(x[51:200])
  expect_true(e$E_best >= 1 && e$E_best <= 4)
  expect_gt(e$rho_best, 0.8)                              # highly predictable
  expect_true(all(c("E_best","rho_best","rho_by_E") %in% names(e)))
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "edm_embed"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Simplex projection (rEDM): optimal embedding dimension E and predictability
#' rho. Theiler window via exclusionRadius for autocorrelation.
edm_embed <- function(x, E_max = 8, theiler = 1) {
  df <- data.frame(t = seq_along(x), x = as.numeric(x))
  half <- floor(nrow(df) / 2)
  s <- rEDM::EmbedDimension(dataFrame = df, lib = c(1, half),
        pred = c(half + 1, nrow(df)), columns = "x", target = "x",
        maxE = E_max, exclusionRadius = theiler, showPlot = FALSE)
  list(E_best = s$E[which.max(s$rho)],
       rho_best = max(s$rho, na.rm = TRUE),
       rho_by_E = s)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): edm_embed (rEDM simplex, Theiler window)"
```

### Task 7: `smap_nonlinearity()` — the Q1 nonlinearity gate + surrogate

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("smap_nonlinearity flags the nonlinear logistic map, not AR(1) noise", {
  set.seed(7)
  x <- numeric(250); x[1] <- 0.4
  for (i in 2:250) x[i] <- 3.8 * x[i-1] * (1 - x[i-1])
  nl <- smap_nonlinearity(x[51:250], E = 2, n_surr = 50, seed = 7)
  expect_gt(nl$rho_theta_best, nl$rho_theta0)            # nonlinear gain
  expect_lt(nl$p_value, 0.05)                            # vs surrogates
  ar <- as.numeric(stats::arima.sim(list(ar = 0.5), 200))
  nl2 <- smap_nonlinearity(ar, E = 2, n_surr = 50, seed = 7)
  expect_gte(nl2$p_value, 0.05)                          # linear -> n.s.
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "smap_nonlinearity"`.

- [ ] **Step 3: Implement**

Append:
```r
#' S-map theta-sweep nonlinearity test (Sugihara 1994). Significance vs
#' phase-randomized (Ebisuzaki) surrogates: is rho(theta>0) - rho(0) larger
#' than under a linear-stochastic null?
.ebisuzaki <- function(x) {                # phase-randomized surrogate
  n <- length(x); ft <- stats::fft(x)
  ph <- c(0, stats::runif(floor((n-1)/2), 0, 2*pi))
  amp <- Mod(ft)[2:(floor((n-1)/2)+1)]
  re <- amp * cos(ph); im <- amp * sin(ph)
  half <- complex(real = re, imaginary = im)
  spec <- c(Re(ft[1]), half, if (n %% 2 == 0) Re(ft[n/2+1]) else NULL,
            Conj(rev(half)))
  Re(stats::fft(spec, inverse = TRUE) / n)
}
smap_nonlinearity <- function(x, E, n_surr = 200, seed) {
  set.seed(seed)
  fit <- function(v) {
    df <- data.frame(t = seq_along(v), x = as.numeric(scale(v)))
    half <- floor(nrow(df) / 2)
    s <- rEDM::PredictNonlinear(dataFrame = df, lib = c(1, half),
          pred = c(half + 1, nrow(df)), columns = "x", target = "x",
          E = E, showPlot = FALSE)
    c(rho0 = s$rho[s$Theta == 0], rhob = max(s$rho, na.rm = TRUE))
  }
  obs <- fit(x); delta_obs <- obs["rhob"] - obs["rho0"]
  surr <- replicate(n_surr, {
    f <- fit(.ebisuzaki(x)); f["rhob"] - f["rho0"]
  })
  list(rho_theta0 = unname(obs["rho0"]),
       rho_theta_best = unname(obs["rhob"]),
       delta = unname(delta_obs),
       p_value = (1 + sum(surr >= delta_obs)) / (1 + n_surr))
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS (both branches; allow re-run if a surrogate draw is borderline — the seed is fixed so it is deterministic).

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): smap_nonlinearity Q1 gate + Ebisuzaki surrogate"
```

### Task 8: `smap_jacobian_eigen()` — time-varying stability |λ_max(t)|

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("smap_jacobian_eigen recovers the eigenvalue of a known linear AR system", {
  set.seed(3)
  phi <- 0.7
  x <- as.numeric(stats::arima.sim(list(ar = phi), 300))
  j <- smap_jacobian_eigen(x, E = 1, theta = 0)         # theta=0 -> linear
  expect_true(abs(median(j$lambda_max, na.rm = TRUE) - phi) < 0.2)
  expect_equal(length(j$lambda_max), length(x))
  expect_true(all(c("t","lambda_max") %in% names(j)))
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "smap_jacobian_eigen"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Time-varying local stability: leading-eigenvalue modulus of the S-map
#' Jacobian at each time (Ushio et al. 2018). Returns |lambda_max(t)|.
smap_jacobian_eigen <- function(x, E, theta = 2) {
  df <- data.frame(t = seq_along(x), x = as.numeric(x))
  n <- nrow(df)
  sm <- rEDM::SMap(dataFrame = df, lib = c(1, n), pred = c(1, n),
        columns = "x", target = "x", E = E, theta = theta,
        embedded = FALSE, showPlot = FALSE)
  co <- sm$coefficients                               # one row per time
  ccols <- grep("^C[0-9]", names(co), value = TRUE)   # C1..CE = local Jacobian
  lam <- apply(co[, ccols, drop = FALSE], 1, function(r) {
    if (any(is.na(r))) return(NA_real_)
    if (length(r) == 1) return(abs(r))
    J <- rbind(r, cbind(diag(length(r) - 1), 0))      # companion form
    max(Mod(eigen(J, only.values = TRUE)$values))
  })
  data.frame(t = co$t, lambda_max = as.numeric(lam))
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): smap_jacobian_eigen time-varying |lambda_max|"
```

### Task 9: `ccm_drivers()` — causal attribution (CCM + multispatial)

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("ccm_drivers detects a known driver, not an independent series", {
  set.seed(11)
  d <- numeric(300); d[1] <- 0.3
  for (i in 2:300) d[i] <- 3.7 * d[i-1] * (1 - d[i-1])  # driver
  n <- numeric(300); n[1] <- 0.2
  for (i in 2:300) n[i] <- 3.6 * n[i-1] * (1 - n[i-1]) + 0.3 * d[i-1]
  indep <- runif(300)
  r <- ccm_drivers(target = n[51:300],
                   drivers = list(d = d[51:300], indep = indep[51:300]),
                   E = 3)
  expect_gt(r$rho_max[r$driver == "d"], r$rho_max[r$driver == "indep"])
  expect_true(r$converges[r$driver == "d"])
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "ccm_drivers"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Convergent cross mapping: does each driver causally force the target
#' (rho rises with library size = convergence)?
ccm_drivers <- function(target, drivers, E, libSizes = NULL) {
  n <- length(target)
  if (is.null(libSizes)) libSizes <- paste(E + 2, n, max(5, floor(n/10)))
  res <- lapply(names(drivers), function(nm) {
    df <- data.frame(t = seq_len(n), tgt = as.numeric(target),
                      drv = as.numeric(drivers[[nm]]))
    cm <- rEDM::CCM(dataFrame = df, E = E, columns = "tgt", target = "drv",
          libSizes = libSizes, sample = 100, showPlot = FALSE)
    rcol <- grep(":", names(cm), value = TRUE)[1]
    data.frame(driver = nm,
               rho_min = cm[[rcol]][1],
               rho_max = cm[[rcol]][nrow(cm)],
               converges = cm[[rcol]][nrow(cm)] - cm[[rcol]][1] > 0.1)
  })
  do.call(rbind, res)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): ccm_drivers causal attribution"
```

---

## Phase 4 — Attractor / regime structure

### Task 10: `potential_landscape()` — drift–diffusion U(x), pre vs post

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("potential_landscape: double-well -> 2 minima, single-well -> 1", {
  set.seed(5)
  # bistable: dx = -dU/dx with U = x^4/4 - x^2/2 (wells at -1, +1)
  bi <- numeric(4000); bi[1] <- 1
  for (i in 2:4000) bi[i] <- bi[i-1] + (bi[i-1] - bi[i-1]^3)*0.05 +
                              rnorm(1, 0, 0.25)
  pb <- potential_landscape(bi, n_bin = 30)
  expect_gte(length(pb$minima), 2L)
  mono <- numeric(4000); mono[1] <- 0
  for (i in 2:4000) mono[i] <- mono[i-1] - 0.1*mono[i-1] + rnorm(1, 0, 0.3)
  pm <- potential_landscape(mono, n_bin = 30)
  expect_equal(length(pm$minima), 1L)
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "potential_landscape"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Nonparametric drift f(x)=E[dx|x], diffusion g2(x)=E[dx^2|x], effective
#' potential U(x) = -cumsum(f/g2). Stable equilibria = minima of U.
potential_landscape <- function(x, n_bin = 25) {
  x <- as.numeric(x); dx <- diff(x); xc <- x[-length(x)]
  br <- seq(min(xc), max(xc), length.out = n_bin + 1)
  bin <- cut(xc, br, include.lowest = TRUE)
  ctr <- (br[-1] + br[-length(br)]) / 2
  drift <- tapply(dx, bin, mean)
  diff2 <- tapply(dx^2, bin, mean); diff2[is.na(diff2) | diff2 == 0] <- NA
  keep <- is.finite(drift) & is.finite(diff2)
  ctr <- ctr[keep]; U <- -cumsum((drift[keep] / diff2[keep])) * mean(diff(br))
  is_min <- which(c(FALSE, diff(sign(diff(U))) > 0, FALSE))
  list(x = ctr, U = as.numeric(U), drift = as.numeric(drift[keep]),
       minima = ctr[is_min])
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): potential_landscape drift-diffusion U(x)"
```

### Task 11: `regime_models()` + `state_modality()`

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("regime_models prefers depensation for an Allee recruit series; modality works", {
  set.seed(9)
  S <- seq(5, 200, length.out = 120)
  # depensatory recruitment: R = a S^2 / (b^2 + S^2)
  R <- 300 * S^2 / (60^2 + S^2) * exp(rnorm(120, 0, 0.15))
  mm <- regime_models(stock = S, recruit = R)
  expect_equal(mm$best, "depensatory")
  expect_true(all(c("model","aic","best") %in% c(names(mm), names(mm$table))))
  d <- state_modality(c(rnorm(200, -2, 0.4), rnorm(200, 2, 0.4)))
  expect_lt(d$dip_p, 0.05)                               # bimodal
  expect_gte(state_modality(rnorm(400))$dip_p, 0.05)     # unimodal
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "regime_models"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Beverton-Holt vs depensatory (Allee) recruitment model selection by AIC.
regime_models <- function(stock, recruit) {
  d <- data.frame(S = stock, R = recruit)
  d <- d[is.finite(d$S) & is.finite(d$R) & d$S > 0 & d$R > 0, ]
  bh <- try(stats::nls(R ~ a * S / (b + S), data = d,
              start = list(a = max(d$R), b = stats::median(d$S))),
            silent = TRUE)
  dp <- try(stats::nls(R ~ a * S^2 / (b^2 + S^2), data = d,
              start = list(a = max(d$R), b = stats::median(d$S))),
            silent = TRUE)
  sc <- function(m) if (inherits(m, "try-error")) Inf else stats::AIC(m)
  tab <- data.frame(model = c("beverton_holt","depensatory"),
                     aic = c(sc(bh), sc(dp)))
  list(table = tab, best = tab$model[which.min(tab$aic)])
}

#' Hartigan dip test of multimodality.
state_modality <- function(x) {
  x <- x[is.finite(x)]
  dt <- diptest::dip.test(x)
  list(dip = unname(dt$statistic), dip_p = unname(dt$p.value))
}
```

Add `diptest` to deps: `Rscript -e 'renv::install("diptest"); renv::snapshot(prompt=FALSE)'`

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R renv.lock
git commit -m "feat(reversibility): regime_models (BH vs depensation) + state_modality"
```

---

## Phase 5 — Driver-space hysteresis geometry

### Task 12: `driver_state_loop()` + loop-null

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("driver_state_loop: hysteretic path has nonzero signed area, monotone ~0", {
  # hysteretic loop in (driver, state)
  th <- seq(0, 2*pi, length.out = 80)
  drv <- cos(th); st <- sin(th)
  L <- driver_state_loop(driver = drv, state = st,
                         year = seq_along(th), pivot = 40)
  expect_gt(abs(L$signed_area), 1.5)                     # ~ pi for unit circle
  # single-valued path: down then exact retrace -> ~0 area
  d2 <- c(seq(0,1,length.out=40), seq(1,0,length.out=40))
  s2 <- d2 * 2
  L2 <- driver_state_loop(d2, s2, seq_along(d2), pivot = 40)
  expect_lt(abs(L2$signed_area), 0.05)
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "driver_state_loop"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Driver-state path geometry. Signed loop area via the shoelace formula
#' (nonzero = non-retracing = hysteresis-like); also the vertical state gap
#' between down- and up-limb at matched driver deciles.
driver_state_loop <- function(driver, state, year, pivot) {
  ok <- is.finite(driver) & is.finite(state)
  d <- driver[ok]; s <- state[ok]; y <- year[ok]
  area <- 0.5 * sum(d * c(s[-1], s[1]) - c(d[-1], d[1]) * s)
  limb <- ifelse(y <= pivot, "down", "up")
  qd <- stats::quantile(d, probs = seq(0, 1, 0.1), na.rm = TRUE)
  bin <- cut(d, unique(qd), include.lowest = TRUE)
  gap <- tapply(seq_along(d), bin, function(ix) {
    dn <- s[ix][limb[ix] == "down"]; up <- s[ix][limb[ix] == "up"]
    if (!length(dn) || !length(up)) return(NA_real_)
    mean(dn) - mean(up)
  })
  list(signed_area = as.numeric(area),
       matched_gap = as.numeric(mean(gap, na.rm = TRUE)),
       gap_by_decile = gap)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): driver_state_loop signed area + matched-driver gap"
```

### Task 13: loop-null via `survey_artifact_null` (single-equilibrium + q-shift must not fake a loop)

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("loop_null_pvalue: a single-equilibrium + q-shift series does not fake a loop", {
  set.seed(2)
  truth <- 1000 + cumsum(rnorm(60, 0, 5))                # single attractor
  obs <- survey_artifact_null(truth, era_break = 30, q = c(0.6, 1.0), seed = 2)
  drv <- c(seq(0.3, 0, length.out = 30), rep(0, 30))     # driver removed
  p <- loop_null_pvalue(driver = drv, state = obs, year = 1:60,
                        pivot = 30, era_break = 30, q = c(0.6, 1.0),
                        n_null = 200, seed = 2)
  expect_gte(p, 0.05)                                    # not a real loop
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "loop_null_pvalue"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Null for the loop index: regenerate the state from a single-equilibrium
#' process + the documented q-shift; what fraction of null signed-areas are
#' at least as extreme as observed? (p >= 0.05 -> loop not distinguishable
#' from a survey artifact).
loop_null_pvalue <- function(driver, state, year, pivot, era_break, q,
                             n_null = 500, seed) {
  set.seed(seed)
  obs_area <- abs(driver_state_loop(driver, state, year, pivot)$signed_area)
  base <- stats::predict(stats::loess(state ~ seq_along(state)))
  null_area <- replicate(n_null, {
    sim <- survey_artifact_null(base, era_break, q,
              seed = sample.int(1e6, 1))
    abs(driver_state_loop(driver, sim, year, pivot)$signed_area)
  })
  (1 + sum(null_area >= obs_area)) / (1 + n_null)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): loop_null_pvalue (survey-artifact loop null)"
```

---

## Phase 6 — Controls / power (the integration test)

### Task 14: `reversibility_controls()` — positive & negative controls

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("battery detects an approaching fold (CSD primary) and stays quiet on a linear-stochastic system", {
  ctl <- reversibility_controls(seed = 4, n = 70)
  # PRIMARY criterion (spec §5): pre-transition |lambda| CSD rise on the
  # genuine ramped saddle-node, clearly exceeding the linear negative control.
  expect_gt(ctl$positive$lambda_trend, 0)
  expect_gt(ctl$positive$lambda_trend, ctl$negative$lambda_trend)
  expect_lt(abs(ctl$negative$lambda_trend), 5e-3)        # linear AR -> ~flat
  # SECONDARY, robust (not the underpowered p<0.05 gate): the cusp is more
  # nonlinear than linear AR even when n~70 is too short for significance.
  expect_gte(ctl$positive$nl_delta, ctl$negative$nl_delta)
  # Honest specificity hard-assert: a genuinely LINEAR process must NOT be
  # flagged nonlinear (this is now scientifically sound).
  expect_false(ctl$negative$nonlinearity_detected)
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "reversibility_controls"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Power calibration (spec §5, redesigned 2026-05-19).
#' POSITIVE: a system ramped through a saddle-node fold — cusp normal form
#'   x_{t} = x_{t-1} + (r_t + x_{t-1} - x_{t-1}^3)*dt + noise, r ramped so the
#'   upper branch annihilates and the trajectory transitions to the REAL lower
#'   attractor (NO numerical clamp). Critical slowing: the local map multiplier
#'   1+dt*f'(x*) -> 1 as the fold is approached, so |lambda_max| RISES pre-
#'   transition. PRIMARY detector = the pre-transition |lambda_max| trend.
#' NEGATIVE: a linear-stochastic single attractor — AR(1)/OU mean-reverting to
#'   one equilibrium + noise (genuinely linear: S-map theta must NOT flag it;
#'   |lambda_max| ~ constant -> ~zero trend).
#' Generic S-map theta nonlinearity is SECONDARY and underpowered at n~70 —
#'   reported (nl_p, nl_delta), never a hard pass/fail gate.
reversibility_controls <- function(seed, n = 70) {
  set.seed(seed)
  # POSITIVE — cusp f(x)=r+x-x^3 ramped through the fold (r: 0.7 -> -0.7),
  # start on the upper stable branch; transitions to the lower real attractor.
  r <- seq(0.7, -0.7, length.out = n)
  pos <- numeric(n); pos[1] <- 1.30          # upper equilibrium near r=0.7
  for (t in 2:n) pos[t] <- pos[t-1] +
      (r[t] + pos[t-1] - pos[t-1]^3) * 0.10 + rnorm(1, 0, 0.03)
  # NEGATIVE — OU/AR(1): x_t = x_{t-1} + k*(mu - x_{t-1}) + noise
  # (k=0.30 -> AR coefficient 0.70; one stable equilibrium; linear).
  neg <- numeric(n); neg[1] <- 8
  for (t in 2:n) neg[t] <- neg[t-1] + 0.30 * (8 - neg[t-1]) +
                            rnorm(1, 0, 0.30)
  # transition index = largest absolute one-step change (the catastrophic jump)
  jump_idx <- function(v) which.max(abs(diff(v))) + 1L
  summ <- function(v, ramped) {
    nl <- smap_nonlinearity(v, E = 2, n_surr = 100, seed = seed)
    je <- smap_jacobian_eigen(v, E = 2, theta = 2)
    je <- je[is.finite(je$lambda_max), ]
    if (ramped) {                       # CSD is the APPROACH: pre-transition only
      jt <- jump_idx(v)
      je <- je[je$t < jt - 1L, , drop = FALSE]
    }
    lt <- if (nrow(je) < 3L) NA_real_ else
            unname(stats::coef(stats::lm(lambda_max ~ t, data = je))[2])
    list(nonlinearity_detected = isTRUE(nl$p_value < 0.05),
         nl_p = nl$p_value, nl_delta = nl$delta,
         lambda_trend = lt)
  }
  list(positive = summ(pos, ramped = TRUE),
       negative = summ(neg, ramped = FALSE), seed = seed)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS. The cusp's pre-transition CSD rise gives `positive$lambda_trend > 0` and ≫ the flat linear `negative$lambda_trend`; the linear AR(1) is genuinely not flagged nonlinear. `nl_p`/`nl_delta` are reported (the n≈70 nonlinearity power limit is a documented finding, NOT a gate). If a PRIMARY (λ/CSD) criterion is genuinely borderline, that is a real power finding — record it as DONE_WITH_CONCERNS with the observed numbers; never weaken the test or cherry-pick a seed.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): reversibility_controls positive/negative power calibration"
```

### Task 15: `discrimination_table()`

**Files:** Modify `R/12_reversibility.R`, `tests/testthat/test-reversibility.R`

- [ ] **Step 1: Write the failing test**

Append:
```r
test_that("discrimination_table scores the four explanations with verdicts", {
  ev <- list(
    nonlinear = TRUE, lambda_failed_to_relax = TRUE,
    state_dependent_dF = TRUE, new_potential_well = TRUE,
    effective_driver_returned = FALSE, loop_p = 0.02,
    regime_best = "depensatory", artifact_reproduces = FALSE)
  tab <- discrimination_table(ev)
  expect_setequal(tab$explanation,
    c("hysteresis","unreturned_driver","long_transient","artifact"))
  expect_true(all(tab$verdict %in%
    c("supported","weak","refuted","indeterminate")))
  expect_equal(tab$verdict[tab$explanation == "artifact"], "refuted")
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: FAIL — `could not find function "discrimination_table"`.

- [ ] **Step 3: Implement**

Append:
```r
#' Map the evidence bundle onto the four non-exclusive explanations (spec
#' §2.4). Returns a verdict + the supporting signatures per row. Never emits
#' "the system tipped"; honest negatives are first-class verdicts.
discrimination_table <- function(ev) {
  row <- function(expl, cond_sup, cond_ref, signs) {
    v <- if (isTRUE(cond_sup) && !isTRUE(cond_ref)) "supported"
         else if (isTRUE(cond_ref)) "refuted"
         else if (is.na(cond_sup)) "indeterminate" else "weak"
    data.frame(explanation = expl, verdict = v, signatures = signs)
  }
  rbind(
    row("hysteresis",
        ev$nonlinear && ev$lambda_failed_to_relax &&
          ev$new_potential_well && ev$loop_p < 0.05,
        isTRUE(ev$effective_driver_returned),
        "nonlinear + |lambda| not relaxed + new well + sig. loop"),
    row("unreturned_driver",
        identical(ev$effective_driver_returned, FALSE),
        isTRUE(ev$effective_driver_returned),
        "fishing removed but effective driver did not return"),
    row("long_transient",
        ev$lambda_failed_to_relax == FALSE && ev$loop_p >= 0.05,
        ev$new_potential_well,
        "restoring but slow; no new well; n.s. loop"),
    row("artifact",
        isTRUE(ev$artifact_reproduces),
        identical(ev$artifact_reproduces, FALSE),
        "survey-artifact null reproduces the observed signal")
  )
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_file("tests/testthat/test-reversibility.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/12_reversibility.R tests/testthat/test-reversibility.R
git commit -m "feat(reversibility): discrimination_table (four-explanation scorer)"
```

---

## Phase 7 — Diagnostic scripts + synthesis

> Pattern for every script: `source("R/12_reversibility.R")`; read inputs from `Data/processed/` + `Output/diagnostics/m1_stier_11_*`; loop over posterior draws where the spec requires CIs; `dir.create("Output/diagnostics", showWarnings=FALSE)`; write CSV/MD; print a one-line `[reversibility]` summary. No `talk-usuk-forum-2026/` reads.

### Task 16: `Code/12_reversibility_01_driver_axis.R`

**Files:** Create `Code/12_reversibility_01_driver_axis.R`

- [ ] **Step 1: Write the script**
```r
#!/usr/bin/env Rscript
source("R/12_reversibility.R")
catch <- read.csv("Data/processed/herring_catch_local_1950_2024.csv")
bio   <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")
ac <- aggregate(TotalCatch ~ Year, data = catch, sum)
names(ac) <- c("year","total_catch")
b11 <- bio[bio$report_set=="all_11", c("year","median")]; names(b11)[2] <- "biomass"
d <- exploitation_rate(ac, b11)
dir.create("Output/diagnostics", showWarnings = FALSE)
write.csv(d, "Output/diagnostics/reversibility_driver_axis.csv", row.names = FALSE)
cat(sprintf("[reversibility] driver axis: %d yr, u in [%.3f, %.3f]\n",
            nrow(d), min(d$u,na.rm=TRUE), max(d$u,na.rm=TRUE)))
```

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_01_driver_axis.R`
Expected: prints `[reversibility] driver axis: 74 yr, u in [0.000, ...]`; `Output/diagnostics/reversibility_driver_axis.csv` exists.

- [ ] **Step 3: Commit**
```bash
git add Code/12_reversibility_01_driver_axis.R
git add -f Output/diagnostics/reversibility_driver_axis.csv
git commit -m "feat(reversibility): 01 driver-axis diagnostic script"
```

### Task 17: `Code/12_reversibility_02_effective_driver.R` (prioritized)

**Files:** Create `Code/12_reversibility_02_effective_driver.R`

- [ ] **Step 1: Write the script** — read the driver axis, the in-repo PDO/`pdo_*` screen and `Data/processed/predators/` context products (per spec §3.4), build the composite, write `Output/diagnostics/reversibility_effective_driver.csv` with a `provenance` attribute serialized to `reversibility_effective_driver_provenance.md`.
```r
#!/usr/bin/env Rscript
source("R/12_reversibility.R")
d <- read.csv("Output/diagnostics/reversibility_driver_axis.csv")
# context-only covariates (provenance-tagged, no promoted coefficient)
pred_path <- "Data/processed/predators/HG_pressure_climate_predator_covariates.csv"
if (file.exists(pred_path)) {
  cov <- read.csv(pred_path)
  d <- merge(d, cov, by.x = "year", by.y = intersect("year", names(cov))[1],
             all.x = TRUE)
}
comp <- intersect(c("u","predation_pressure_index","pdo"), names(d))
prov <- c(u = "m1_stier_11", predation_pressure_index = "predator-repo:context",
          pdo = "pdo_screen")[comp]
ed <- effective_driver(d, components = comp, provenance = prov)
dir.create("Output/diagnostics", showWarnings = FALSE)
write.csv(ed[, c("year","u","effective_driver")],
          "Output/diagnostics/reversibility_effective_driver.csv",
          row.names = FALSE)
writeLines(c("# Effective-driver provenance (context-only)",
             paste0("- ", names(prov), ": ", prov)),
           "Output/diagnostics/reversibility_effective_driver_provenance.md")
cat(sprintf("[reversibility] effective driver: components = %s\n",
            paste(comp, collapse = ", ")))
```

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_02_effective_driver.R`
Expected: prints the component list; both output files exist. (If the predator covariate file is absent, the script still runs on `u` alone and the provenance md records the omission — verify this branch by temporarily renaming the file, then restore.)

- [ ] **Step 3: Commit**
```bash
git add Code/12_reversibility_02_effective_driver.R
git add -f Output/diagnostics/reversibility_effective_driver.csv Output/diagnostics/reversibility_effective_driver_provenance.md
git commit -m "feat(reversibility): 02 effective-driver reconstruction (context-only, provenance-tagged)"
```

### Task 18: `Code/12_reversibility_03_edm.R` (embedding, nonlinearity, Jacobian, CCM; posterior loop)

**Files:** Create `Code/12_reversibility_03_edm.R`

- [ ] **Step 1: Write the script** — read `Output/diagnostics/m1_stier_11_total_biomass_by_year.csv` (use `median` as the latent series; loop over the 80/90 bounds as a coarse posterior envelope since per-draw files are summarized), `Data/processed/portfolio_metrics_rolling.csv` (synchrony), and the driver axis; for each state variable {biomass, synchrony, occupancy if present}: `edm_embed` → `smap_nonlinearity` → `smap_jacobian_eigen` → `ccm_drivers` against {u, effective_driver, pdo, predation}; write `reversibility_edm_nonlinearity.csv`, `reversibility_edm_jacobian_eigen.csv`, `reversibility_ccm_driver_causality.csv`. Use a fixed `seed <- 20260519`. Run on `all_11` and `focal_9`.
```r
#!/usr/bin/env Rscript
source("R/12_reversibility.R"); seed <- 20260519
bio <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")
port <- read.csv("Data/processed/portfolio_metrics_rolling.csv")
drv <- read.csv("Output/diagnostics/reversibility_driver_axis.csv")
states <- list(
  biomass_all11 = bio[bio$report_set=="all_11", c("year","median")],
  biomass_focal9 = bio[bio$report_set=="focal_9", c("year","median")])
nl <- do.call(rbind, lapply(names(states), function(nm) {
  s <- states[[nm]]; v <- s$median
  e <- edm_embed(v); r <- smap_nonlinearity(v, E = e$E_best, n_surr = 500,
                                            seed = seed)
  data.frame(state = nm, E = e$E_best, rho = e$rho_best,
             rho0 = r$rho_theta0, rho_best = r$rho_theta_best,
             p_value = r$p_value)
}))
je <- do.call(rbind, lapply(names(states), function(nm) {
  s <- states[[nm]]; e <- edm_embed(s$median)
  j <- smap_jacobian_eigen(s$median, E = e$E_best, theta = 2)
  j$state <- nm; j$year <- s$year[j$t]; j
}))
dir.create("Output/diagnostics", showWarnings = FALSE)
write.csv(nl, "Output/diagnostics/reversibility_edm_nonlinearity.csv", row.names = FALSE)
write.csv(je, "Output/diagnostics/reversibility_edm_jacobian_eigen.csv", row.names = FALSE)
cat(sprintf("[reversibility] EDM: %d states, nonlinearity p = %s\n",
            nrow(nl), paste(round(nl$p_value,3), collapse=", ")))
```
(CCM step added analogously writing `reversibility_ccm_driver_causality.csv`; keep the script under ~80 lines — if it grows, split CCM into `Code/12_reversibility_04_ccm.R` and renumber downstream.)

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_03_edm.R`
Expected: prints nonlinearity p-values; the three CSVs exist; `lambda_max` is non-degenerate (not all NA) — if all NA, the series is too short for that E; record it and reduce E.

- [ ] **Step 3: Commit**
```bash
git add Code/12_reversibility_03_edm.R
git add -f Output/diagnostics/reversibility_edm_*.csv Output/diagnostics/reversibility_ccm_driver_causality.csv
git commit -m "feat(reversibility): 03 EDM nonlinearity + Jacobian + CCM"
```

### Task 19: `Code/12_reversibility_05_attractor_regime.R`

**Files:** Create `Code/12_reversibility_05_attractor_regime.R`

- [ ] **Step 1: Write the script** — split the latent biomass at the closure (`year <= 2005` vs `> 2005`); `potential_landscape()` on each era; `regime_models()` on stock–recruit if a recruit proxy is available else on lag-1 state map; `state_modality()` on the driver-conditioned residual pre vs post; write `reversibility_potential_landscape_pre_post.csv`, `reversibility_regime_model_selection.csv`, `reversibility_state_modality.csv`.

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_05_attractor_regime.R`
Expected: prints `[reversibility] potential minima pre=k1 post=k2 | regime best=...`; three CSVs exist.

- [ ] **Step 3: Commit**
```bash
git add Code/12_reversibility_05_attractor_regime.R
git add -f Output/diagnostics/reversibility_potential_landscape_pre_post.csv Output/diagnostics/reversibility_regime_model_selection.csv Output/diagnostics/reversibility_state_modality.csv
git commit -m "feat(reversibility): 05 potential landscape + regime models + modality"
```

### Task 20: `Code/12_reversibility_06_driver_loop.R`

**Files:** Create `Code/12_reversibility_06_driver_loop.R`

- [ ] **Step 1: Write the script** — for state ∈ {biomass, synchrony}: `driver_state_loop()` against both `u` and `effective_driver`; `loop_null_pvalue()` using the `m1_stier_11` two-era q (read from `Output/diagnostics/` q estimates; if unavailable use `q=c(0.6,1.0)` and record the assumption); write `reversibility_driver_state_hysteresis_loop.csv` (signed area, matched gap, loop p, driver = {u, effective}). Promote the committed Phase-0 spike numbers as a sanity cross-check row.

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_06_driver_loop.R`
Expected: prints signed area + loop p for each (state, driver); CSV exists; the `u`-driver biomass row reproduces the spike's qualitative non-retrace.

- [ ] **Step 3: Commit**
```bash
git add Code/12_reversibility_06_driver_loop.R
git add -f Output/diagnostics/reversibility_driver_state_hysteresis_loop.csv
git commit -m "feat(reversibility): 06 driver-space loop + survey-artifact loop null"
```

### Task 21: `Code/12_reversibility_07_controls.R`

**Files:** Create `Code/12_reversibility_07_controls.R`

- [ ] **Step 1: Write the script** — call `reversibility_controls(seed=20260519, n=70)`; assert (in-script `stopifnot`) the positive control is detected and the negative is quiet; write `reversibility_controls.md` with the pass/fail and the numeric trends. **This script must error and stop the suite if the battery fails its own power calibration** (controls before interpretation, spec §5).

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_07_controls.R`
Expected: `reversibility_controls.md` written; exit status 0 only if controls pass; otherwise non-zero and a clear message.

- [ ] **Step 3: Commit**
```bash
git add Code/12_reversibility_07_controls.R
git add -f Output/diagnostics/reversibility_controls.md
git commit -m "feat(reversibility): 07 power controls gate (fails suite if battery fails)"
```

### Task 22: `Code/12_reversibility_10_discrimination_synthesis.R`

**Files:** Create `Code/12_reversibility_10_discrimination_synthesis.R`

- [ ] **Step 1: Write the script** — read all `reversibility_*` CSVs, assemble the `ev` bundle (nonlinear?, |λ| relaxed post-closure?, state-dependent ∂N/∂F?, new potential well?, effective driver returned?, loop p, regime best, artifact reproduces?), call `discrimination_table(ev)`; write `reversibility_discrimination_table.{csv,md}`, the readable `reversibility_synthesis.md`, and `reversibility_claim_control.md` (safe-sentence ↔ do-not-say, extending `docs/talk-model-claim-control-sheet.md`; every row carries the descriptive-only caveat and the "effective driver" alternative).

- [ ] **Step 2: Run it**

Run: `Rscript Code/12_reversibility_10_discrimination_synthesis.R`
Expected: prints the per-explanation verdicts; all four output files exist; no file contains the phrase "the system tipped".

- [ ] **Step 3: Verify claim-safety**

Run: `grep -i "the system tipped\|proves a fold\|caused by predators" Output/diagnostics/reversibility_synthesis.md || echo CLEAN`
Expected: `CLEAN`.

- [ ] **Step 4: Commit**
```bash
git add Code/12_reversibility_10_discrimination_synthesis.R
git add -f Output/diagnostics/reversibility_discrimination_table.csv Output/diagnostics/reversibility_discrimination_table.md Output/diagnostics/reversibility_synthesis.md Output/diagnostics/reversibility_claim_control.md
git commit -m "feat(reversibility): 10 discrimination table + synthesis + claim-control"
```

---

## Phase 8 — Figures, targets, suite runner

### Task 23: Figures + `_targets.R` + `Code/run_reversibility_suite.sh`

**Files:** Create `R/12_reversibility_figs.R`, `Code/run_reversibility_suite.sh`; Modify `_targets.R`

- [ ] **Step 1: Write the figure builders (`R/12_reversibility_figs.R`)** using pub-figure-pipeline `theme_pub` per the R/ggplot2 standards: `fig_lambda_trajectory()` (|λ_max(t)| vs candidate transitions, observed vs latent), `fig_state_dependent_dF()`, `fig_potential_pre_post()` (the talk visual), `fig_driver_loop()`, `fig_controls_panel()`. Each returns a ggplot; explicit `ggsave(..., device = cairo_pdf, width/height in mm)`; companion legend `.md` per figure.

- [ ] **Step 2: Apply the Figure Iteration Protocol** — render each at print size, downscale (`sips -Z 1200`), inspect, fix overlaps/margins/legend per the CLAUDE.md protocol, then dispatch the figure-critic agent (40-pt rubric, PASS ≥ 32, no dim < 3). Record the critique verdict in `Output/diagnostics/reversibility_figure_qa.md`.

- [ ] **Step 3: Add `_targets.R` targets** before the final `)` of the `list(...)`, mirroring the existing `tar_target(..., save_figure(...), format = "file")` pattern, downstream of the posterior-extraction + portfolio targets. Exact insertion: after `fig_recolonization_file`, add `tar_target(reversibility_discrimination_file, ...)` and one `tar_target` per figure.

- [ ] **Step 4: Write `Code/run_reversibility_suite.sh`** (zsh, `set -euo pipefail`, `cd "$(dirname "$0")/.."`, log file), running `Code/12_reversibility_01..10` in order, then the figure script. Mirror `Code/08_refresh_may9_analysis_suite.sh` exactly in structure.

- [ ] **Step 5: Run the full suite end-to-end**

Run: `zsh Code/run_reversibility_suite.sh`
Expected: exits 0; all `Output/diagnostics/reversibility_*` and `Output/figures/reversibility_*` regenerate from clean; the controls gate (Task 21) passes.

- [ ] **Step 6: Commit**
```bash
git add R/12_reversibility_figs.R Code/run_reversibility_suite.sh _targets.R
git add -f Output/diagnostics/reversibility_figure_qa.md
git commit -m "feat(reversibility): figures (Figure Iteration Protocol) + targets + suite runner"
```

---

## Phase 9 — Reconcile, dedupe, finalize

### Task 24: EWS dedupe note, cross-spec reconciliation, full test + finishing-a-branch

**Files:** Modify `docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md` (add a "Reconciliation" appendix); create `docs/reversibility-ews-shared-utils.md`

- [ ] **Step 1: Write the dedupe/reconciliation note** (`docs/reversibility-ews-shared-utils.md`): `detect_candidate_transitions()` + `survey_artifact_null()` exist in BOTH `R/12_reversibility.R` (here) and are specced for `R/11_early_warning.R` (EWS). When the EWS plan executes, the canonical copies move to the EWS lib and `R/12_reversibility.R` `source()`s them; until then this plan's copies are authoritative. Record the exact function signatures so the EWS implementation matches.

- [ ] **Step 2: Run the entire test suite**

Run: `Rscript -e 'testthat::test_dir("tests/testthat")'`
Expected: all tests pass, including the pre-existing `test-early-warning.R`, `test-data-cleaning.R`, `test-figures.R` (no regressions) and the full `test-reversibility.R`.

- [ ] **Step 3: Run the suite once more from clean and confirm claim-safety**

Run:
```bash
zsh Code/run_reversibility_suite.sh
grep -RiL "the system tipped" Output/diagnostics/reversibility_synthesis.md && echo "claim-safe"
```
Expected: suite exits 0; `claim-safe`.

- [ ] **Step 4: Update spec status + commit**
```bash
git add docs/reversibility-ews-shared-utils.md docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md
git commit -m "docs(reversibility): EWS dedupe note + cross-spec reconciliation; suite green"
```

- [ ] **Step 5: Finish the branch** — invoke `superpowers:finishing-a-development-branch` to choose merge/PR/cleanup (the deck is unaffected; this is core-pipeline only).

---

## Self-Review (run before execution)

**1. Spec coverage:**

- §2.1 Q1 nonlinearity → Task 7. §2.2 Q2 alternative state → Tasks 10, 11, 19. §2.3 Q3 reversibility → Tasks 8, 12, 20. §2.4 discrimination table → Tasks 15, 22.
- §3.1 three co-equal state variables → Tasks 18–20 run biomass + synchrony (+ occupancy where present). §3.2 observed + latent → Task 18 (latent median + bounds envelope; per-draw deferred to the documented summarized-posterior approach). §3.3 core-9 + all-11 → Tasks 18, 20. §3.4 driver + effective-driver → Tasks 2, 3, 16, 17. §3.5 candidate eras → Task 4.
- §4 M1/M2/M3/M4 → Phases 3/4/5 + Task 15. §5 nulls/controls → Tasks 5, 13, 14, 21. §6 architecture/outputs/firewall → Phases 7–8 + invariants block. §7 numerical robustness → NA-robust tests in Tasks 2–13; even-sampling/short-window guards exercised in Task 18 Step 2. §8 verification → analytic tests throughout + Task 14 integration + Task 24 Step 2. §9 EWS relationship → Task 24. §10 YAGNI → invariants block (no coastwide, no Stan, no DFO-SCA layer, no deck redesign).

*Gap check:* §3.2 "EWS computed over posterior draws" — the per-year files are posterior *summaries* not raw draws; the plan uses the median + 80/90 envelope and states this explicitly (Task 18). If raw draws are required for true CIs, that is a follow-up task against the posterior-extraction layer — recorded here, not silently dropped.

**2. Placeholder scan:** No "TBD"/"add error handling"/"similar to Task N". Tasks 19, 20, 22, 23 describe scripts at the spec level but every library function they call has complete code in Phases 1–6 and a concrete output contract + run/expected-output; the script bodies are mechanical I/O wrappers around tested functions (acceptable: the testable logic is fully specified and TDD-covered).

**3. Type consistency:** `exploitation_rate`→`{year,total_catch,biomass,u}` consumed identically in Tasks 16/17/20. `effective_driver` adds `effective_driver` col + `provenance` attr, consumed in Tasks 17/20/22. `smap_jacobian_eigen`→`{t,lambda_max}` consumed in Tasks 18/23. `driver_state_loop`→`{signed_area,matched_gap,gap_by_decile}` consumed in Tasks 13/20. `discrimination_table` consumes the `ev` bundle assembled in Task 22 with the exact keys tested in Task 15. Consistent.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-19-herring-reversibility-hysteresis.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — fresh subagent per task, two-stage review between tasks, fast iteration.

**2. Inline Execution** — execute tasks in this session via executing-plans, batched with checkpoints.

**Which approach?**
