# ============================================================================
# test-early-warning.R — Early-warning-signal indicator library tests
# stier-2027-herring-metapopulation
#
# Run with: testthat::test_file("tests/testthat/test-early-warning.R")
# ============================================================================

library(testthat)
source(here::here("R", "11_early_warning.R"))

test_that("EWS dependencies are installed", {
  for (pkg in c("earlywarnings", "spatialwarnings", "MARSS",
                "posterior", "Kendall", "strucchange", "zoo")) {
    expect_true(requireNamespace(pkg, quietly = TRUE),
                info = paste("missing package:", pkg))
  }
})

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

test_that("synchrony indicators are NA-robust (mirror compute_synchrony_lm)", {
  m <- cbind(c(1,2,3,4,5), c(2,1,4,3,5), c(NA,NA,NA,NA,NA))
  expect_true(is.finite(ews_synchrony_eta(m)))   # all-NA col dropped
  expect_true(is.finite(ews_synchrony_phi(m)))
  m2 <- cbind(c(1,2,3,4,5), c(5,5,5,5,5))         # zero-variance col
  expect_no_warning(ews_synchrony_eta(m2))
  expect_true(is.na(ews_synchrony_eta(m2)))
  expect_no_warning(ews_synchrony_phi(m2))
})

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

test_that("ews_cov_eigen is guard- and NA-robust", {
  g <- ews_cov_eigen(matrix(1:4, ncol = 1))           # ncol<2 guard
  expect_true(is.na(g$lambda_max) && length(g$loadings) == 1)
  s <- ews_cov_eigen(matrix(c(1,1,1,1,1,1), ncol = 2)) # zero-variance / degenerate
  expect_true(is.na(s$eig_share) || (is.finite(s$eig_share) && s$eig_share <= 1 + 1e-9))
  m <- cbind(c(1,2,3,NA,5,6), c(2,1,4,3,5,4), c(1,3,2,4,6,5))
  out <- ews_cov_eigen(m)                              # NA present -> no crash
  expect_true(is.na(out$eig_share) || (out$eig_share >= 0 && out$eig_share <= 1 + 1e-9))
})

test_that("spatial variance and skew match base R on a year vector", {
  v <- c(1, 5, 2, 8, 3)
  expect_equal(ews_spatial_variance(v), stats::var(v))
  expect_equal(round(ews_spatial_skew(v), 6),
               round(mean((v - mean(v))^3) / (mean((v - mean(v))^2))^1.5, 6))
})

test_that("Moran's I matches an independent double-sum computation and detects gradient", {
  coords <- cbind(1:6, rep(0, 6)); vals <- as.numeric(1:6)
  # independent reference: I = (n/S0) * sum_ij w_ij z_i z_j / sum_i z_i^2
  d <- as.matrix(stats::dist(coords)); W <- 1/d; diag(W) <- 0
  rs <- rowSums(W); W <- W / rs                    # row-standardised
  z <- vals - mean(vals); n <- length(vals)
  num <- 0; for (i in 1:n) for (j in 1:n) num <- num + W[i,j]*z[i]*z[j]
  ref <- (n / sum(W)) * num / sum(z^2)
  expect_equal(ews_morans_i(vals, coords), ref, tolerance = 1e-8)
  expect_gt(ews_morans_i(vals, coords), 0)         # positive autocorrelation
  # detects structure: gradient I exceeds mean I of random permutations
  set.seed(20260519L)
  perm <- replicate(200, ews_morans_i(sample(vals), coords))
  expect_gt(ews_morans_i(vals, coords), mean(perm, na.rm = TRUE))
})

test_that("spatial EWS are degenerate/NA-robust (spec §8)", {
  expect_true(is.na(ews_spatial_variance(c(3))))            # <2 finite
  expect_true(is.na(ews_spatial_variance(c(NA, NA))))
  expect_true(is.na(ews_spatial_skew(c(5, 5, 5, 5))))       # zero variance -> NA not NaN
  expect_true(is.na(ews_spatial_skew(c(1, 2))))             # <3 finite -> NA
  expect_false(is.nan(ews_spatial_skew(c(5,5,5,5))))
  cc <- cbind(c(1,1,1), c(0,0,0))                           # identical coords
  expect_true(is.na(ews_morans_i(c(1,2,3), cc)))
  expect_true(is.na(ews_morans_i(c(5,5,5,5), cbind(1:4, 0)))) # zero spatial variance -> NA not Inf
  expect_no_warning(ews_morans_i(c(5,5,5,5), cbind(1:4, 0)))
})

test_that("generic battery returns the expected indicator columns", {
  set.seed(3)
  x <- as.numeric(cumsum(rnorm(60)))
  res <- ews_generic_battery(x, win_frac = 0.5, detrend = "gaussian")
  expect_true(all(c("time","ar1","variance","sd","skew","kurtosis",
                     "cv","densratio") %in% names(res)))
  expect_true(nrow(res) > 5)
  expect_false("acf1" %in% names(res))
})

test_that("generic battery is degenerate-robust (spec §8)", {
  short <- ews_generic_battery(rnorm(8), win_frac = 0.5, detrend = "none")
  expect_s3_class(short, "tbl_df")                       # empty tibble, not error
  expect_true(all(c("time","ar1","variance","sd","skew","kurtosis",
                     "cv","densratio") %in% names(short)))
  expect_equal(nrow(short), 0L)
  flat <- ews_generic_battery(rep(5, 60), win_frac = 0.5, detrend = "none")
  expect_s3_class(flat, "tbl_df")                        # constant series: no crash
  expect_no_warning(ews_generic_battery(c(rnorm(40), NA, rnorm(19)),
                                        win_frac = 0.5, detrend = "gaussian"))
})

test_that("MAR1 dominant eigenvalue recovers a known stable AR system", {
  set.seed(4)
  n <- 300; B <- matrix(c(0.6, 0.05, 0.0, 0.5), 2, 2)
  X <- matrix(0, n, 2)
  for (t in 2:n) X[t, ] <- B %*% X[t - 1, ] + rnorm(2, 0, 0.1)
  lam <- ews_mar1_eigen(X)
  expect_lt(lam, 1)        # stable
  expect_gt(lam, 0.3)      # near true dominant eigenvalue ~0.61
})

test_that("ews_mar1_eigen is degenerate/NA-robust (spec §8)", {
  expect_true(is.na(ews_mar1_eigen(matrix(1:6, ncol = 2))))     # too few rows
  expect_true(is.na(ews_mar1_eigen(matrix(rnorm(4), ncol = 1))))# <2 cols
  Xc <- matrix(rep(c(2, 5), each = 30), ncol = 2)               # constant cols
  expect_true(is.na(ews_mar1_eigen(Xc)))                        # singular OLS -> NA
  expect_no_warning(ews_mar1_eigen(matrix(1:6, ncol = 2)))
  Xna <- matrix(rnorm(120), ncol = 2); Xna[5, 1] <- NA          # NA -> MARSS path
  v <- suppressWarnings(ews_mar1_eigen(Xna))
  expect_true(is.na(v) || (is.finite(v) && v >= 0))
})
