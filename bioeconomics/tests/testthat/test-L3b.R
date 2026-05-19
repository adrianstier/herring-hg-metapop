test_that("Japan kazunoko import series is plausible and covers the roe era", {
  source(here::here("R", "layer_L3b_kazunoko.R"))

  cache_path <- here::here("data-raw", "trade", "comtrade_jpn_030520.csv")
  avail <- file.exists(cache_path)

  if (!avail) {
    k <- tryCatch(build_L3b(), error = function(e) e)
    if (inherits(k, "error") || inherits(k, "condition")) {
      testthat::skip(paste("Comtrade kazunoko data unavailable:", conditionMessage(k)))
    }
  } else {
    k <- build_L3b()
  }

  # Column contract
  expect_true(all(c("year", "kazunoko_import_qty_t", "kazunoko_import_val_usd") %in% names(k)))

  # Year coverage: must span the roe era (min <= 1995, max >= 2006)
  expect_true(min(k$year) <= 1995 && max(k$year) >= 2006)

  # Non-negative quantities
  expect_true(all(k$kazunoko_import_qty_t >= 0))

  # Magnitude: Japan is a very large herring-roe importer; peak > 1000 t
  expect_gt(max(k$kazunoko_import_qty_t, na.rm = TRUE), 1000)
})
