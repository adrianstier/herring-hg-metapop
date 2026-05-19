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

test_that("edm_embed recovers low embedding dim for the logistic map", {
  x <- numeric(200); x[1] <- 0.4
  for (i in 2:200) x[i] <- 3.8 * x[i-1] * (1 - x[i-1])
  e <- edm_embed(x[51:200])
  expect_true(e$E_best >= 1 && e$E_best <= 4)
  expect_gt(e$rho_best, 0.8)
  expect_true(all(c("E_best","rho_best","rho_by_E") %in% names(e)))
  expect_true(is.integer(e$E_best))                 # M2: integer E_best
})

test_that("edm_embed guards a too-short series with an NA-shaped return", {
  e <- edm_embed(rnorm(10))                          # n=10 < 2*E_max+2 = 18
  expect_true(is.na(e$E_best))
  expect_true(is.na(e$rho_best))
  expect_equal(nrow(e$rho_by_E), 0L)
  expect_true(all(c("E_best","rho_best","rho_by_E") %in% names(e)))
})

test_that("smap_nonlinearity flags the nonlinear logistic map, not AR(1) noise", {
  set.seed(7)
  x <- numeric(250); x[1] <- 0.4
  for (i in 2:250) x[i] <- 3.8 * x[i-1] * (1 - x[i-1])
  nl <- smap_nonlinearity(x[51:250], E = 2, n_surr = 50, seed = 7)
  expect_gt(nl$rho_theta_best, nl$rho_theta0)
  expect_lt(nl$p_value, 0.05)
  ar <- as.numeric(stats::arima.sim(list(ar = 0.5), 200))
  nl2 <- smap_nonlinearity(ar, E = 2, n_surr = 99, seed = 7)   # M3: n_surr 99
  expect_gte(nl2$p_value, 0.05)
})

test_that("smap_nonlinearity guards a too-short series with an NA-shaped return", {
  nl <- smap_nonlinearity(rnorm(4), E = 2, n_surr = 50, seed = 7)  # 4 < 2*2+2 = 6
  expect_true(is.na(nl$rho_theta0))
  expect_true(is.na(nl$rho_theta_best))
  expect_true(is.na(nl$delta))
  expect_true(is.na(nl$p_value))
  expect_true(all(c("rho_theta0","rho_theta_best","delta","p_value") %in% names(nl)))
})

test_that("smap_jacobian_eigen recovers the eigenvalue of a known linear AR system", {
  set.seed(3)
  phi <- 0.7
  x <- as.numeric(stats::arima.sim(list(ar = phi), 300))
  j <- smap_jacobian_eigen(x, E = 1, theta = 0)
  expect_true(abs(median(j$lambda_max, na.rm = TRUE) - phi) < 0.2)
  expect_equal(length(j$lambda_max), length(x))
  expect_true(all(c("t","lambda_max") %in% names(j)))
})

test_that("smap_jacobian_eigen guards a too-short series (NA-shaped, length preserved)", {
  x <- rnorm(6)                                      # 6 < 2*3+2 = 8 for E=3
  j <- smap_jacobian_eigen(x, E = 3, theta = 0)
  expect_equal(nrow(j), length(x))
  expect_equal(length(j$lambda_max), length(x))
  expect_true(all(is.na(j$lambda_max)))
  expect_true(all(c("t","lambda_max") %in% names(j)))
})

test_that("smap_jacobian_eigen left-join NA-pads early rows (E=3, ~120 pts)", {
  set.seed(5)
  x <- as.numeric(stats::arima.sim(list(ar = 0.6), 120))
  j <- smap_jacobian_eigen(x, E = 3, theta = 2)
  expect_equal(nrow(j), length(x))                   # M5: length contract
  expect_gt(sum(is.na(j$lambda_max)), 0L)            # M5: NA-padding documented
})

test_that("ccm_drivers detects a known driver, not an independent series", {
  # Uses multiplicative Sugihara (2012) coupling: n[i] = n[i-1]*(r - r*n[i-1] - B*d[i-1])
  # which stays bounded in (0,1). The plan's additive formula (+0.3*d) diverges
  # to -Inf by index 20 for these fixed ICs (d[1]=0.3, n[1]=0.2); the
  # Sugihara multiplicative form is the canonical CCM benchmark and preserves
  # the scientific contract (d causes n, indep does not).
  set.seed(11)
  d <- numeric(300); d[1] <- 0.3
  for (i in 2:300) d[i] <- d[i-1] * (3.7 - 3.7 * d[i-1])
  n <- numeric(300); n[1] <- 0.2
  for (i in 2:300) n[i] <- n[i-1] * (3.6 - 3.6 * n[i-1] - 0.3 * d[i-1])
  indep <- runif(300)
  r <- ccm_drivers(target = n[51:300],
                   drivers = list(d = d[51:300], indep = indep[51:300]),
                   E = 3, seed = 11)
  expect_gt(r$rho_max[r$driver == "d"], r$rho_max[r$driver == "indep"])
  # converges_strict is the authoritative discrimination gate (Kendall + rho floor)
  expect_true(r$converges_strict[r$driver == "d"])
  expect_false(r$converges_strict[r$driver == "indep"])   # M1: false-positive direction
  expect_true("converges_heuristic" %in% names(r))         # I1: renamed legacy flag
})

test_that("ccm_drivers is seed-deterministic (spec §8 recorded-seed contract)", {
  set.seed(11)
  d <- numeric(300); d[1] <- 0.3
  for (i in 2:300) d[i] <- d[i-1] * (3.7 - 3.7 * d[i-1])
  n <- numeric(300); n[1] <- 0.2
  for (i in 2:300) n[i] <- n[i-1] * (3.6 - 3.6 * n[i-1] - 0.3 * d[i-1])
  a <- ccm_drivers(target = n[51:300], drivers = list(d = d[51:300]),
                   E = 3, seed = 11)
  b <- ccm_drivers(target = n[51:300], drivers = list(d = d[51:300]),
                   E = 3, seed = 11)
  expect_identical(a, b)
})

test_that("ccm_drivers guards a too-short target with a 0-row contract frame", {
  # spec §7: never crash / never a silent number. cor.test() THROWS (not warns)
  # on a < 3-point rho vector, so suppressWarnings cannot protect it.
  r <- ccm_drivers(target = rnorm(10),
                   drivers = list(drv = rnorm(10)), E = 3, seed = 1)
  expect_equal(nrow(r), 0L)
  expect_true(all(c("driver", "rho_min", "rho_max",
                    "converges_heuristic", "converges_strict") %in% names(r)))
})

test_that("ccm_drivers: a degenerate per-driver rho vector yields strict=FALSE, not NA/error", {
  # A constant driver makes CCM rho degenerate (no rank variation) -> cor.test
  # would error; converges_strict must be a real logical FALSE, and a good
  # driver in the same call must still be evaluated normally.
  set.seed(11)
  d <- numeric(300); d[1] <- 0.3
  for (i in 2:300) d[i] <- d[i-1] * (3.7 - 3.7 * d[i-1])
  n <- numeric(300); n[1] <- 0.2
  for (i in 2:300) n[i] <- n[i-1] * (3.6 - 3.6 * n[i-1] - 0.3 * d[i-1])
  flat <- rep(0.5, 300)                       # constant -> degenerate rho
  r <- ccm_drivers(target = n[51:300],
                   drivers = list(d = d[51:300], flat = flat[51:300]),
                   E = 3, seed = 11)
  expect_false(r$converges_strict[r$driver == "flat"])
  expect_false(is.na(r$converges_strict[r$driver == "flat"]))
  expect_true(r$converges_strict[r$driver == "d"])      # good driver unaffected
})

# ============================================================================
# Task 12: driver_state_loop
# ============================================================================

test_that("driver_state_loop: hysteretic path has nonzero signed area, monotone ~0", {
  th <- seq(0, 2*pi, length.out = 80)
  drv <- cos(th); st <- sin(th)
  L <- driver_state_loop(driver = drv, state = st,
                         year = seq_along(th), pivot = 40)
  expect_gt(abs(L$signed_area), 1.5)                     # ~ pi for unit circle
  d2 <- c(seq(0,1,length.out=40), seq(1,0,length.out=40))
  s2 <- d2 * 2
  L2 <- driver_state_loop(d2, s2, seq_along(d2), pivot = 40)
  expect_lt(abs(L2$signed_area), 0.05)
})

test_that("driver_state_loop §7 guard: constant driver returns NA contract silently", {
  # constant driver -> non-unique quantile breaks -> crash without guard
  expect_silent(
    r1 <- driver_state_loop(rep(2, 10), rnorm(10), 1:10, pivot = 5)
  )
  expect_true(is.na(r1$signed_area))
  expect_true(is.na(r1$matched_gap))
  expect_null(r1$gap_by_decile)
  expect_true(all(c("signed_area", "matched_gap", "gap_by_decile") %in% names(r1)))
})

test_that("driver_state_loop §7 guard: too-short input (< 3 finite pairs) returns NA contract silently", {
  expect_silent(
    r2 <- driver_state_loop(c(1, 2), c(1, 2), 1:2, pivot = 1)
  )
  expect_true(is.na(r2$signed_area))
  expect_true(is.na(r2$matched_gap))
  expect_null(r2$gap_by_decile)
})

test_that("driver_state_loop §7 guard: NA-bearing input computes on finite pairs", {
  th <- seq(0, 2*pi, length.out = 80)
  drv <- cos(th); st <- sin(th)
  drv[c(5, 20)] <- NA_real_   # inject two NAs
  expect_silent(
    L_na <- driver_state_loop(drv, st, seq_along(drv), pivot = 40)
  )
  # After stripping 2 NAs, 78 finite pairs remain -> should still compute
  expect_true(is.finite(L_na$signed_area))
})

test_that("driver_state_loop: one-directional driver -> matched_gap is NA_real_ not NaN", {
  drv <- seq(0.1, 0.9, length.out = 10)
  st  <- rev(drv) * 1000
  L   <- driver_state_loop(driver = drv, state = st, year = 1:10, pivot = 100)
  expect_true(is.na(L$matched_gap))
  expect_false(is.nan(L$matched_gap))
  expect_true(is.finite(L$signed_area))
})

# ── Task 10: potential_landscape ──────────────────────────────────────────────
test_that("potential_landscape: double-well -> 2 minima, single-well -> 1", {
  set.seed(5)
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

# ── Task 11: regime_models + state_modality ───────────────────────────────────
test_that("regime_models prefers depensation for an Allee recruit series; modality works", {
  set.seed(9)
  S <- seq(5, 200, length.out = 120)
  R <- 300 * S^2 / (60^2 + S^2) * exp(rnorm(120, 0, 0.15))
  mm <- regime_models(stock = S, recruit = R)
  expect_equal(mm$best, "depensatory")
  expect_true(all(c("model","aic") %in% names(mm$table)))
  expect_true("best" %in% names(mm))
  d <- state_modality(c(rnorm(200, -2, 0.4), rnorm(200, 2, 0.4)))
  expect_lt(d$dip_p, 0.05)
  expect_gte(state_modality(rnorm(400))$dip_p, 0.05)
})

# ── Phase 4 degenerate-input guards (spec §7: emit NA + shape, never crash) ────
test_that("potential_landscape: constant / all-NA / NA-embedded input -> empty contract, no crash", {
  nm <- c("x", "U", "drift", "minima")
  expect_silent(pc <- potential_landscape(rep(5, 50)))
  expect_named(pc, nm)
  expect_length(pc$x, 0L); expect_length(pc$U, 0L); expect_length(pc$minima, 0L)

  expect_silent(pn <- potential_landscape(rep(NA_real_, 50)))
  expect_named(pn, nm)
  expect_length(pn$x, 0L); expect_length(pn$U, 0L); expect_length(pn$minima, 0L)

  # Finite series with embedded NAs: NAs stripped, estimator still runs (no crash)
  set.seed(5)
  bi <- numeric(4000); bi[1] <- 1
  for (i in 2:4000) bi[i] <- bi[i-1] + (bi[i-1] - bi[i-1]^3)*0.05 +
                              rnorm(1, 0, 0.25)
  bi_na <- bi; bi_na[c(10, 500, 2500)] <- NA_real_
  expect_silent(pe <- potential_landscape(bi_na, n_bin = 30))
  expect_named(pe, nm)
  expect_gte(length(pe$minima), 2L)            # contract preserved after NA-strip

  # Exactly-2-distinct-finite window: x_fin = c(3,5) (len 2) -> xc len 1 ->
  # seq(3,3,...) -> cut() 'breaks' are not unique crash. Needs >= 3 finite x
  # (estimator needs xc length >= 2). Must hit the empty 4-name contract.
  expect_silent(p2 <- potential_landscape(c(NA, 3, 5, NA)))
  expect_named(p2, nm)
  expect_length(p2$x, 0L); expect_length(p2$U, 0L); expect_length(p2$minima, 0L)

  expect_silent(p2b <- potential_landscape(c(3, 5)))
  expect_named(p2b, nm)
  expect_length(p2b$x, 0L); expect_length(p2b$U, 0L)
  expect_length(p2b$minima, 0L)
})

test_that("regime_models: <3 finite positive pairs -> NA contract, no crash; AIC picks better-fitting model when both converge", {
  expect_silent(r0 <- regime_models(stock = c(1, NA, -2),
                                    recruit = c(5, 3, NA)))
  expect_true(all(c("model", "aic") %in% names(r0$table)))
  expect_true(is.na(r0$best))
  expect_true(all(is.na(r0$table$aic)))

  # AIC-selection sanity: a clean Beverton-Holt series where BOTH nls
  # converge (BH AIC ~ 744.6, depensatory ~ 779.7) -> best must be the
  # lower-AIC (better-fitting) model, not a degenerate/NA path. The
  # both-nls-fail NA path is covered by the <3-rows guard above + the
  # sc()->NA logic (which.min ignores NA: which.min(c(NA, 3)) == 2).
  set.seed(21)
  S <- seq(5, 200, length.out = 80)
  R <- 400 * S / (30 + S) * exp(rnorm(80, 0, 0.08))
  rb <- regime_models(stock = S, recruit = R)
  expect_false(is.na(rb$best))
  expect_false(any(is.na(rb$table$aic)))       # both fits converged
  expect_equal(rb$best, rb$table$model[which.min(rb$table$aic)])
})

test_that("state_modality: <4 / all-NA input -> NA dip + NA p, no crash", {
  s1 <- state_modality(rep(NA_real_, 20))
  expect_named(s1, c("dip", "dip_p"))
  expect_identical(s1$dip, NA_real_)
  expect_identical(s1$dip_p, NA_real_)

  s2 <- state_modality(c(1, 2, 3))
  expect_named(s2, c("dip", "dip_p"))
  expect_identical(s2$dip, NA_real_)
  expect_identical(s2$dip_p, NA_real_)

  # Tied values trigger a benign diptest regularize.values "collapsing to
  # unique 'x' values" warning; the suite asserts WARN 0 and the downstream
  # pipeline treats warnings as signals, so it must be suppressed (not escape).
  expect_silent(s3 <- state_modality(c(1, 1, 2, 2, 3, 3, 4, 4)))
  expect_named(s3, c("dip", "dip_p"))
  expect_true(is.finite(s3$dip))
  expect_true(is.finite(s3$dip_p))
})

# ============================================================================
# Task 13: loop_null_pvalue
# ============================================================================

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

test_that("loop_null_pvalue §7 guard: too-short state returns NA_real_ silently", {
  # length 3 < 4 finite threshold -> NA contract
  expect_silent(
    p_short <- loop_null_pvalue(
      driver = c(1, 2, 3), state = c(100, 110, 120), year = 1:3,
      pivot = 2, era_break = 2, q = c(0.6, 1.0),
      n_null = 50, seed = 1
    )
  )
  expect_true(is.na(p_short))
  expect_identical(p_short, NA_real_)
})

test_that("loop_null_pvalue is seed-deterministic (same seed -> identical p)", {
  set.seed(2)
  truth <- 1000 + cumsum(rnorm(60, 0, 5))
  obs <- survey_artifact_null(truth, era_break = 30, q = c(0.6, 1.0), seed = 2)
  drv <- c(seq(0.3, 0, length.out = 30), rep(0, 30))
  p1 <- loop_null_pvalue(driver = drv, state = obs, year = 1:60,
                         pivot = 30, era_break = 30, q = c(0.6, 1.0),
                         n_null = 200, seed = 2)
  p2 <- loop_null_pvalue(driver = drv, state = obs, year = 1:60,
                         pivot = 30, era_break = 30, q = c(0.6, 1.0),
                         n_null = 200, seed = 2)
  expect_identical(p1, p2)
})

# ============================================================================
# Task 14: reversibility_controls
# ============================================================================

test_that("battery detects an approaching fold and stays quiet on a stationary system", {
  ctl <- reversibility_controls(seed = 4, n = 70)
  expect_gt(ctl$positive$lambda_trend, 0)
  expect_true(ctl$positive$nonlinearity_detected)
  expect_false(ctl$negative$nonlinearity_detected)
  expect_lt(abs(ctl$negative$lambda_trend), abs(ctl$positive$lambda_trend))
})

# ============================================================================
# Task 15: discrimination_table
# ============================================================================

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

test_that("discrimination_table: NA ev fields -> indeterminate (not crash, not false supported/refuted)", {
  ev_na <- list(
    nonlinear = TRUE, lambda_failed_to_relax = NA,
    state_dependent_dF = TRUE, new_potential_well = TRUE,
    effective_driver_returned = FALSE, loop_p = NA,
    regime_best = "depensatory", artifact_reproduces = FALSE)
  expect_silent(tab_na <- discrimination_table(ev_na))
  # hysteresis: loop_p = NA -> cond_sup is NA/indeterminate
  expect_equal(tab_na$verdict[tab_na$explanation == "hysteresis"], "indeterminate")
  # long_transient: lambda_failed_to_relax = NA -> cond_sup is indeterminate
  expect_equal(tab_na$verdict[tab_na$explanation == "long_transient"], "indeterminate")
  # artifact: artifact_reproduces = FALSE -> explicitly refuted (unaffected by other NAs)
  expect_equal(tab_na$verdict[tab_na$explanation == "artifact"], "refuted")
  # No errors, no NA verdicts -- every row has a real verdict string
  expect_false(any(is.na(tab_na$verdict)))
})
