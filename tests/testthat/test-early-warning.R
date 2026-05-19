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
  expect_true(is.na(ews_synchrony_eta(m2)) || is.finite(ews_synchrony_eta(m2)))
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
