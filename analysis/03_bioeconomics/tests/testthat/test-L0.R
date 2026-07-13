# tests/testthat/test-L0.R
test_that("L0 regime timeline matches documented history", {
  source(here::here("R","schema.R")); source(here::here("R","layer_L0_institutions.R"))
  L0 <- build_L0(years = 1950:2026)
  expect_s3_class(L0$regime, "factor")
  expect_identical(levels(L0$regime),
    c("reduction","moratorium","roe_openaccess","roe_ivq_pool"))
  hg <- dplyr::filter(L0, region == "HG")
  expect_equal(as.character(unique(hg$regime[hg$year %in% 1950:1966])), "reduction")
  expect_equal(as.character(unique(hg$regime[hg$year %in% 1968:1971])), "moratorium")
  expect_equal(as.character(unique(hg$regime[hg$year == 1967])), "moratorium")
  expect_equal(as.character(unique(hg$regime[hg$year %in% 1972:1997])), "roe_openaccess")
  expect_equal(as.character(unique(hg$regime[hg$year %in% 1998:1998])), "roe_ivq_pool")
  expect_false(any(hg$fishery_open[hg$year %in% c(1999:2001, 2003:2026)]))
  expect_true(all(hg$fishery_open[hg$year %in% 1980:1990]))
})

test_that("HG commercial closure is open-ended (not frozen at 2026)", {
  source(here::here("R","schema.R")); source(here::here("R","layer_L0_institutions.R"))
  L0b <- build_L0(years = 2025:2030)
  hg <- dplyr::filter(L0b, region == "HG")
  expect_true(all(hg$fishery_open == FALSE))   # HG still closed every year 2025-2030
  # 2002 remains a deliberate open gap year
  L0c <- build_L0(years = 2000:2004)
  hgc <- dplyr::filter(L0c, region == "HG")
  expect_true(hgc$fishery_open[hgc$year == 2002])
  expect_false(hgc$fishery_open[hgc$year == 2001])
  expect_false(hgc$fishery_open[hgc$year == 2003])
})
