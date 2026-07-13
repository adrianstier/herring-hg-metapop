library(testthat)
library(here)

# Anchor here() to bioeconomics/ via the .here sentinel
here::i_am(".here")

test_that("assembled backbone conforms to schema and reconciles anchors", {
  source(here::here("R", "schema.R"))
  source(here::here("R", "assemble_backbone.R"))

  bb <- assemble_backbone()
  s  <- backbone_schema()

  # --- plan's 6 assertions ---
  expect_true(all(s$column[s$required] %in% names(bb)))
  expect_false(any(is.na(bb$region)) || any(is.na(bb$year)))
  expect_setequal(levels(bb$region), REGIONS)
  expect_true(all(bb$year >= 1950 & bb$year <= 2026))
  expect_true("biomass_t" %in% names(bb))
  roe <- dplyr::filter(bb, region == "HG", !is.na(roe_value_cad_real2020))
  expect_true(nrow(roe) == 0 || any(roe$roe_value_cad_real2020 != roe$roe_value_cad_nominal))

  # --- 5 strengthening additions (Task 10 controller corrections) ---
  expect_s3_class(bb$region, "factor")
  expect_true(is.integer(bb$year))
  expect_gt(nrow(bb), 0)
  expect_true("regime" %in% names(bb))
  expect_equal(nrow(bb), length(REGIONS) * length(1950:2026))
})

test_that("if Comtrade cache exists, kazunoko columns reach the backbone (regression guard)", {
  cache <- here::here("data-raw","trade","comtrade_jpn_030520.csv")
  testthat::skip_if_not(file.exists(cache), "Comtrade cache not present (Task 7 needs COMTRADE_PRIMARY_KEY)")
  source(here::here("R","schema.R")); source(here::here("R","assemble_backbone.R"))
  bb <- assemble_backbone()
  expect_true("kazunoko_import_qty_t" %in% names(bb))
  expect_true(any(!is.na(bb$kazunoko_import_qty_t)))
})
