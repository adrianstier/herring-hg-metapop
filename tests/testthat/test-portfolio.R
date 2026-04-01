# ============================================================================
# test-portfolio.R — Unit tests for portfolio effect and synchrony functions
# stier-2027-herring-metapopulation
#
# Run with: testthat::test_file("tests/testthat/test-portfolio.R")
# ============================================================================

library(testthat)
library(tidyverse)
library(here)

# Source the setup and portfolio functions
source(here("R", "00_setup.R"))
source(here("R", "05_portfolio.R"))


# ============================================================================
# Test helpers: synthetic biomass data
# ============================================================================

# Build a minimal synthetic biomass tibble that matches the expected structure
# from extract_posteriors()$biomass: year, site, .value, .width, biomass
make_test_biomass <- function(n_years = 30, n_sites = 5, seed = 42) {
  set.seed(seed)
  years <- seq(2000, 2000 + n_years - 1)
  sites <- paste("Site", LETTERS[seq_len(n_sites)])

  expand_grid(year = years, site = sites, .width = 0.9) |>
    mutate(
      .value  = rnorm(n(), 5, 1),
      biomass = exp(.value),
      biomass_lo = biomass * 0.8,
      biomass_hi = biomass * 1.2
    )
}


# ============================================================================
# compute_portfolio
# ============================================================================

test_that("compute_portfolio returns expected structure", {
  bio <- make_test_biomass(n_years = 20, n_sites = 5)

  result <- compute_portfolio(bio, window = 10L, sections_drop = character(0))

  expect_s3_class(result, "tbl_df")
  expected_cols <- c("window_start", "window_end", "window_mid",
                     "cv_subpop_mean", "cv_archipelago", "cv_ratio",
                     "synchrony_lm")
  expect_true(all(expected_cols %in% names(result)))
})

test_that("compute_portfolio returns correct number of windows", {
  bio <- make_test_biomass(n_years = 20, n_sites = 4)

  result <- compute_portfolio(bio, window = 10L, sections_drop = character(0))

  # 20 years with a 10-year window => 11 windows

  expect_equal(nrow(result), 20 - 10 + 1)
})

test_that("compute_portfolio CV ratio is positive", {
  bio <- make_test_biomass(n_years = 25, n_sites = 5)

  result <- compute_portfolio(bio, window = 10L, sections_drop = character(0))

  # CV ratio should be positive (both CVs are positive)
  expect_true(all(result$cv_ratio > 0, na.rm = TRUE))
})

test_that("compute_portfolio errors on insufficient years", {
  bio <- make_test_biomass(n_years = 5, n_sites = 3)

  expect_error(
    compute_portfolio(bio, window = 10L, sections_drop = character(0)),
    "Not enough years"
  )
})


# ============================================================================
# compute_synchrony (pairwise cross-correlation)
# ============================================================================

test_that("compute_synchrony returns values between -1 and 1", {
  bio <- make_test_biomass(n_years = 25, n_sites = 5)

  result <- compute_synchrony(bio, window = 10L, sections_drop = character(0))

  expect_s3_class(result, "tbl_df")
  expect_true("mean_pairwise_cor" %in% names(result))

  # Correlation values must be in [-1, 1]
  valid_cors <- result$mean_pairwise_cor[!is.na(result$mean_pairwise_cor)]
  expect_true(all(valid_cors >= -1 & valid_cors <= 1))
})

test_that("compute_synchrony returns correct number of windows", {
  bio <- make_test_biomass(n_years = 20, n_sites = 4)

  result <- compute_synchrony(bio, window = 10L, sections_drop = character(0))

  expect_equal(nrow(result), 20 - 10 + 1)
})

test_that("compute_synchrony reports correct n_pairs", {
  n_sites <- 6
  bio <- make_test_biomass(n_years = 20, n_sites = n_sites)

  result <- compute_synchrony(bio, window = 10L, sections_drop = character(0))

  # Upper triangle of n_sites x n_sites = choose(n_sites, 2)
  expected_pairs <- choose(n_sites, 2)
  expect_true(all(result$n_pairs <= expected_pairs))
})

test_that("compute_synchrony with perfectly correlated sites returns ~1", {
  # Build data where all sites have the same trajectory
  years <- seq(2000, 2020)
  sites <- paste("Site", LETTERS[1:3])
  bio <- expand_grid(year = years, site = sites, .width = 0.9) |>
    mutate(
      biomass = rep(seq_along(years), times = length(sites)),
      .value  = log(biomass),
      biomass_lo = biomass * 0.9,
      biomass_hi = biomass * 1.1
    )

  result <- compute_synchrony(bio, window = 10L, sections_drop = character(0))

  # Perfectly correlated sites should give correlation near 1
  expect_true(all(result$mean_pairwise_cor > 0.95, na.rm = TRUE))
})


# ============================================================================
# compute_synchrony_lm (Loreau & de Mazancourt)
# ============================================================================

test_that("compute_synchrony_lm returns value in [0, 1]", {
  set.seed(99)
  mat <- matrix(abs(rnorm(50)), nrow = 10, ncol = 5)

  sync <- compute_synchrony_lm(mat)

  expect_true(!is.na(sync))
  expect_true(sync >= 0 & sync <= 1)
})

test_that("compute_synchrony_lm returns 1 for identical columns", {
  # Identical time series => perfect synchrony
  x <- seq(1, 10)
  mat <- cbind(x, x, x)

  sync <- compute_synchrony_lm(mat)

  expect_equal(sync, 1.0)
})

test_that("compute_synchrony_lm returns NA for single-column matrix", {
  mat <- matrix(1:10, ncol = 1)
  sync <- compute_synchrony_lm(mat)
  expect_true(is.na(sync))
})


# ============================================================================
# compute_site_occupancy
# ============================================================================

test_that("compute_site_occupancy returns binary values", {
  # Build minimal spawn data
  spawn_data <- tibble(
    year         = rep(2000:2010, each = 3),
    section      = rep(c(1L, 2L, 3L), times = 11),
    section_name = rep(c("Site A", "Site B", "Site C"), times = 11),
    spawn_index  = c(
      100, NA,  50,   # 2000
      200, 30,  NA,   # 2001
      NA,  NA,  80,   # 2002
      150, 40,  60,   # 2003
      0,   NA,  NA,   # 2004
      NA,  20,  NA,   # 2005
      300, NA,  90,   # 2006
      NA,  50,  NA,   # 2007
      100, 60,  70,   # 2008
      NA,  NA,  NA,   # 2009
      200, 30,  40    # 2010
    )
  )

  result <- compute_site_occupancy(spawn_data, sections_drop = integer(0))

  expect_type(result, "list")
  expect_true(all(c("occupancy_wide", "occupancy_long", "summary",
                     "n_occupied_ts") %in% names(result)))

  # Occupancy values must be 0 or 1
  expect_true(all(result$occupancy_long$occupied %in% c(0L, 1L)))
})

test_that("compute_site_occupancy correctly identifies occupied sites", {
  spawn_data <- tibble(
    year         = rep(2000:2002, each = 2),
    section      = rep(c(1L, 2L), times = 3),
    section_name = rep(c("Site A", "Site B"), times = 3),
    spawn_index  = c(100, NA, NA, 50, 200, 0)
  )

  result <- compute_site_occupancy(spawn_data, sections_drop = integer(0))

  occ <- result$occupancy_long |> arrange(year, section)

  # Year 2000: Site A = occupied (100), Site B = not (NA)
  expect_equal(occ$occupied[occ$year == 2000 & occ$section == 1], 1L)
  expect_equal(occ$occupied[occ$year == 2000 & occ$section == 2], 0L)

  # Year 2001: Site A = not (NA), Site B = occupied (50)
  expect_equal(occ$occupied[occ$year == 2001 & occ$section == 1], 0L)
  expect_equal(occ$occupied[occ$year == 2001 & occ$section == 2], 1L)

  # Year 2002: Site A = occupied (200), Site B = not occupied (0)
  expect_equal(occ$occupied[occ$year == 2002 & occ$section == 1], 1L)
  expect_equal(occ$occupied[occ$year == 2002 & occ$section == 2], 0L)
})

test_that("compute_site_occupancy n_occupied_ts sums correctly", {
  spawn_data <- tibble(
    year         = rep(2000:2002, each = 3),
    section      = rep(c(1L, 2L, 3L), times = 3),
    section_name = rep(c("A", "B", "C"), times = 3),
    spawn_index  = c(100, 50, NA, NA, NA, NA, 200, 100, 50)
  )

  result <- compute_site_occupancy(spawn_data, sections_drop = integer(0))
  ts <- result$n_occupied_ts

  expect_equal(ts$n_sites_occupied[ts$year == 2000], 2L)
  expect_equal(ts$n_sites_occupied[ts$year == 2001], 0L)
  expect_equal(ts$n_sites_occupied[ts$year == 2002], 3L)
})


# ============================================================================
# compute_longest_run (helper)
# ============================================================================

test_that("compute_longest_run finds correct run length", {
  expect_equal(compute_longest_run(c(1, 0, 0, 0, 1, 0, 1), target = 0L), 3L)
  expect_equal(compute_longest_run(c(1, 1, 1, 1), target = 0L), 0L)
  expect_equal(compute_longest_run(c(0, 0, 0, 0), target = 0L), 4L)
  expect_equal(compute_longest_run(integer(0), target = 0L), 0L)
})
