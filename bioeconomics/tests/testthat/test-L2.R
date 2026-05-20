test_that("L2 HG harvest faithfully reproduces the DFO source and is near the Hourston 1956 anchor", {
  source(here::here("R","schema.R")); source(here::here("R","layer_L2_harvest.R"))
  L2 <- build_L2()
  hg <- dplyr::filter(L2, region == "HG")
  hg_1956 <- sum(hg$catch_total_t[hg$year == 1956])

  # (a) Pipeline fidelity: build_L2's 1956 HG total must equal the direct sum of
  # TotalCatch in the DFO source CSV. This catches any pipeline mangling and does
  # not depend on a magic number.
  raw <- readr::read_csv(
    here::here("data-raw","harvest","herring_catch_local_1950_2024.csv"),
    show_col_types = FALSE) |> janitor::clean_names()
  raw_1956 <- sum(raw$total_catch[raw$year == 1956], na.rm = TRUE)
  expect_equal(hg_1956, raw_1956)

  # (b) Historical cross-reference: Hourston (1980) reports ~77,500 t for the
  # QCI/HG stock in 1956 (the exceptional 1951 year-class). The DFO section
  # database differs ~8% (statistical-area / methodology differences); the
  # backbone treats the DFO data as authoritative. Assert the documented
  # record-year magnitude is within 12% of the Hourston literature anchor
  # (a meaningful, non-vacuous bound; |Δ|/77500 must be < 0.12).
  expect_lt(abs(hg_1956 - 77500) / 77500, 0.12)

  # roe catch only exists 1972-2002 at HG
  expect_true(all(hg$catch_roe_t[hg$year < 1972] == 0 |
                  is.na(hg$catch_roe_t[hg$year < 1972])))
  expect_true(any(hg$catch_roe_t[hg$year %in% 1972:2002] > 0))

  # roe is structurally absent after 2002 at HG
  expect_true(all(hg$catch_roe_t[hg$year > 2002] == 0))
  # pre-1972 roe is exactly 0 (replace_na already applied; tighten the assertion)
  expect_true(all(hg$catch_roe_t[hg$year < 1972] == 0))
  # SOK fidelity: catch_sok_t must equal the raw local `sok` column (PRODUCT series),
  # recomputed independently — NOT the impound-biomass harvest-sok-hg.csv.
  raw_sok_1989 <- sum(raw$sok[raw$year == 1989], na.rm = TRUE)
  expect_equal(sum(hg$catch_sok_t[hg$year == 1989]), raw_sok_1989)
  expect_gt(sum(L2$catch_sok_t), 0)
  # guard against accidentally switching to the impound file (~85,214 t at 1989)
  expect_lt(sum(hg$catch_sok_t[hg$year == 1989]), 5000)

  # schema-contract shape
  expect_s3_class(L2$region, "factor")
  expect_identical(levels(L2$region), REGIONS)
  expect_true(all(c("catch_total_t","catch_roe_t","catch_sok_t") %in% names(L2)))
})
