# ============================================================================
# test-figures.R — Basic interface tests for figure helpers
# stier-2027-herring-metapopulation
# ============================================================================

library(testthat)
library(tidyverse)
library(here)

source(here("R", "00_setup.R"))
source(here("R", "06_figures.R"))
source(here("R", "07_lecture_figures.R"))

make_figure_biomass <- function(n_years = 12, n_sites = 3) {
  years <- seq(2000, length.out = n_years)
  sites <- paste("Site", LETTERS[seq_len(n_sites)])

  tidyr::expand_grid(year = years, section_name = sites, .width = 0.9) |>
    mutate(biomass = exp(rnorm(n(), 4, 0.5)))
}

make_figure_fishing <- function(n_years = 12, n_sites = 3) {
  years <- seq(2000, length.out = n_years)
  sites <- paste("Site", LETTERS[seq_len(n_sites)])

  tidyr::expand_grid(year = years, section_name = sites) |>
    mutate(pc_median = runif(n(), 0, 0.4))
}

test_that("fig_lecture_biomass accepts section_name input", {
  p <- fig_lecture_biomass(
    make_figure_biomass(),
    sections_drop = character(0)
  )

  expect_s3_class(p, "ggplot")
})

test_that("fig_lecture_fishing_rates accepts pc_median input", {
  p <- fig_lecture_fishing_rates(make_figure_fishing())

  expect_s3_class(p, "ggplot")
})

test_that("fig_biomass_timeseries accepts site + biomass input", {
  p <- fig_biomass_timeseries(
    tidyr::expand_grid(
      year = 2000:2011,
      site = paste("Site", LETTERS[1:3]),
      .width = 0.9
    ) |>
      mutate(biomass = exp(rnorm(n(), 4, 0.5))),
    sections_drop = character(0)
  )

  expect_s3_class(p, "ggplot")
})

test_that("fig_fishing_rates accepts fishing_rate input", {
  p <- fig_fishing_rates(
    tidyr::expand_grid(
      year = 2000:2011,
      site = paste("Site", LETTERS[1:3])
    ) |>
      mutate(fishing_rate = runif(n(), 0, 0.4))
  )

  expect_s3_class(p, "ggplot")
})
