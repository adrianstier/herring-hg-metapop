test_that("to_real deflates nominal to constant 2020 dollars", {
  source(here::here("R","deflate.R"))
  defl <- tibble::tibble(year = as.integer(c(2000, 2020)), cpi_ca_2020base = c(50, 100))
  x <- tibble::tibble(year = as.integer(c(2000, 2020)), v_nom = c(10, 10))
  out <- to_real(x, value_col = "v_nom", defl = defl)
  expect_equal(out$v_real[out$year == 2000], 20)   # 10 / (50/100)
  expect_equal(out$v_real[out$year == 2020], 10)
  expect_true("v_nom" %in% names(out))
  expect_false("cpi_ca_2020base" %in% names(out))
  expect_equal(nrow(out), nrow(x))
})

test_that("to_real returns NA real value for years absent from the deflator (documented contract)", {
  source(here::here("R","deflate.R"))
  defl <- tibble::tibble(year = as.integer(c(2000, 2020)), cpi_ca_2020base = c(50, 100))
  x2 <- tibble::tibble(year = as.integer(c(2000, 1975)), v_nom = c(10, 10))
  out2 <- to_real(x2, value_col = "v_nom", defl = defl)
  expect_true(is.na(out2$v_real[out2$year == 1975]))
  expect_equal(out2$v_real[out2$year == 2000], 20)
})

test_that("to_real fails loudly on duplicate years in the deflator (no silent fanout)", {
  source(here::here("R","deflate.R"))
  defl_dup <- tibble::tibble(year = as.integer(c(2020, 2020)), cpi_ca_2020base = c(100, 100))
  x <- tibble::tibble(year = as.integer(c(2020)), v_nom = c(10))
  expect_error(to_real(x, value_col = "v_nom", defl = defl_dup))
})
