test_that("FX (CAD-JPY) loads with sane range, coverage, and attribute", {
  source(here::here("R","layer_L3c_fx_deflators.R"))
  fx <- tryCatch(build_fx(), error = function(e) e)
  if (inherits(fx, "error") || inherits(fx, "condition"))
    testthat::skip(paste("BoC FX unavailable:", conditionMessage(fx)))
  expect_true(all(c("year","fx_jpy_per_cad") %in% names(fx)))
  # NOTE: (50,150) suits the BoC ~2017+ window (median ~94). If the pre-2017
  # upgrade-track FX is ever added, 1970s-80s annual means (~250-400 JPY/CAD)
  # may push the median up — revisit this bound in that acquisition task.
  expect_true(median(fx$fx_jpy_per_cad) > 50 && median(fx$fx_jpy_per_cad) < 150)
  # Load-bearing coverage guards (BoC FXJPYCAD reality is ~2017+):
  expect_true(max(fx$year) >= 2017)
  expect_true(min(fx$year) <= 2019)
  expect_gte(nrow(fx), 5L)
  # fx_year_range attr is the signal Task 9/10 use to detect short coverage:
  expect_false(is.null(attr(fx, "fx_year_range")))
  expect_equal(attr(fx, "fx_year_range"), range(fx$year))
})

test_that("Canada CPI deflator loads and rebases to 2020=100", {
  source(here::here("R","layer_L3c_fx_deflators.R"))
  d <- tryCatch(build_deflator(), error = function(e) e)
  if (inherits(d, "error") || inherits(d, "condition"))
    testthat::skip(paste("FRED CPI unavailable:", conditionMessage(d)))
  expect_true(all(c("year","cpi_ca","cpi_ca_2020base") %in% names(d)))
  expect_equal(d$cpi_ca_2020base[d$year == 2020], 100, tolerance = 1)
})
