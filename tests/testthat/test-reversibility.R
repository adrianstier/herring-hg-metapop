library(testthat)
source(here::here("R/12_reversibility.R"))

test_that("reversibility dependencies are installed", {
  expect_true(requireNamespace("rEDM", quietly = TRUE))
  expect_true(requireNamespace("multispatialCCM", quietly = TRUE))
  expect_true(requireNamespace("changepoint", quietly = TRUE))
})
