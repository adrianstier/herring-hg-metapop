library(testthat)
source(here::here("R/12_reversibility.R"))

test_that("reversibility dependencies are installed", {
  expect_true(requireNamespace("rEDM", quietly = TRUE))
  expect_true(requireNamespace("multispatialCCM", quietly = TRUE))
  expect_true(requireNamespace("changepoint", quietly = TRUE))
})

test_that("exploitation_rate = catch / biomass, NA- and zero-robust", {
  catch <- data.frame(year = 2000:2002, total_catch = c(50, 0, 30))
  bio   <- data.frame(year = 2000:2002, biomass = c(100, 200, 0))
  out <- exploitation_rate(catch, bio)
  expect_equal(out$u, c(0.5, 0.0, NA_real_))      # zero biomass -> NA, not Inf
  expect_equal(nrow(out), 3L)
  expect_true(all(c("year","total_catch","biomass","u") %in% names(out)))
})

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

test_that("exploitation_rate inner-joins non-overlapping years", {
  catch <- data.frame(year = 2000:2002, total_catch = c(50, 60, 30))
  bio   <- data.frame(year = 2001:2003, biomass = c(100, 200, 150))
  out <- exploitation_rate(catch, bio)
  expect_equal(nrow(out), 2L)              # only 2001, 2002 overlap
  expect_equal(out$year, c(2001, 2002))
  expect_equal(out$u, c(60 / 100, 30 / 200))
})

test_that("effective_driver excludes an all-NA component (not pulled to zero)", {
  # a and b are NOT mirror-symmetric, so a wrongly zero-substituted absent
  # column shifts the composite away from the (a,b)-only mean -> test bites.
  df <- data.frame(
    year   = 2000:2003,
    a      = c(1, 2, 4, 7),
    b      = c(2, 2, 3, 9),
    absent = NA_real_                       # covariate absent for this series
  )
  out_all  <- effective_driver(df, components = c("a", "b", "absent"))
  out_pair <- effective_driver(df, components = c("a", "b"))
  # all-NA component must be EXCLUDED, so composite == mean of a,b only
  expect_equal(out_all$effective_driver, out_pair$effective_driver)
  expect_false(any(is.na(out_all$effective_driver)))
})

test_that("effective_driver: a present constant component contributes 0", {
  df <- data.frame(
    year  = 2000:2003,
    a     = c(1, 2, 3, 4),
    flat  = c(5, 5, 5, 5)                   # real data, zero variance
  )
  out <- effective_driver(df, components = c("a", "flat"))
  expect_false(any(is.na(out$effective_driver)))   # well-defined, not NA
  # composite == mean(z(a), 0) == z(a)/2
  za <- (df$a - mean(df$a)) / stats::sd(df$a)
  expect_equal(out$effective_driver, za / 2)
})

test_that("effective_driver: an all-NA row yields NA_real_, never NaN", {
  df <- data.frame(
    year = 2000:2003,
    a    = c(1, 2, NA, 4),
    b    = c(4, 3, NA, 1)
  )
  out <- effective_driver(df, components = c("a", "b"))
  x <- out$effective_driver[3]
  expect_true(is.na(x))
  expect_false(is.nan(x))
})

test_that("effective_driver errors when a component is absent from df", {
  df <- data.frame(year = 2000:2002, a = c(1, 2, 3))
  expect_error(effective_driver(df, components = c("a", "missing_col")),
               regexp = "not in df")
})

test_that("effective_driver errors on empty components (no silent NA)", {
  df <- data.frame(year = 2000:2002, a = c(1, 2, 3))
  expect_error(effective_driver(df, components = character(0)),
               regexp = "components.*empty")
})

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

test_that("detect_candidate_transitions guards degenerate (short / all-NA) input", {
  yrs11 <- 1951:1961
  cp_na <- detect_candidate_transitions(rep(NA_real_, 11), yrs11)
  expect_equal(nrow(cp_na), 0L)                     # all-NA -> 0-row frame
  expect_true(all(c("year","index","kind") %in% names(cp_na)))
  cp3 <- detect_candidate_transitions(c(1, 2, 3), 2001:2003)
  expect_equal(nrow(cp3), 0L)                       # < 4 finite -> 0-row frame
  expect_true(all(c("year","index","kind") %in% names(cp3)))
})

test_that("detect_candidate_transitions index references the ORIGINAL series under an NA gap", {
  set.seed(7)
  x <- c(rnorm(30, 0, 0.3), rnorm(30, 3, 0.3))      # clear step at index 31
  x[16] <- NA_real_                                 # NA gap before the step
  yrs <- 1951:2010
  cp <- detect_candidate_transitions(x, yrs)
  expect_gt(nrow(cp), 0L)
  # index must address the ORIGINAL x/years vectors, not the NA-filtered one:
  expect_equal(yrs[cp$index], cp$year)
})

test_that("survey_artifact_null rejects q of wrong length (no silent NA-poison)", {
  truth <- rep(1000, 60)
  expect_error(
    survey_artifact_null(truth, era_break = 30, q = 0.6, seed = 42),
    regexp = "length\\(q\\)")
})
