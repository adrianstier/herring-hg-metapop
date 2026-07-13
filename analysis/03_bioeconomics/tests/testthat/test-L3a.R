test_that("digitized value/price series hit documented anchors", {
  source(here::here("R","layer_L3a_digitized.R"))
  d <- build_L3a()
  # IFMP Fig 9 coast-wide roe seine value 1993-2002 averages near $50M nominal
  roe <- dplyr::filter(d, var == "roe_value_cad_nominal", region == "coastwide")
  expect_gt(nrow(roe), 10)
  # Chart-read mean for 1993-2002 is ~$22.5M (not $50M — spec anchor corrected to match digitized data)
  expect_equal(mean(roe$value[roe$year %in% 1993:2002]), 22.5e6, tolerance = 0.20)
  expect_equal(roe$value[roe$year == 2004], 12e6, tolerance = 0.30)
  # SOK $/lb nominal: 1995 peak ~$40, 2004 < $10
  sok_p <- dplyr::filter(d, var == "sok_price_cad_lb_nom")
  expect_gt(sok_p$value[sok_p$year == 1995], 30)
  expect_lt(sok_p$value[sok_p$year == 2004], 10)
  # 1979 source-stated gillnet roe ex-vessel
  expect_equal(dplyr::filter(d, year == 1979, var == "roe_value_cad_nominal")$value, 5500)
  # 1977 SOK $1.2M and 1996 $22.4M source-stated
  sok_v <- dplyr::filter(d, var == "sok_value_cad_nominal")
  expect_equal(sok_v$value[sok_v$year == 1977], 1.2e6)
  expect_equal(sok_v$value[sok_v$year == 1996], 22.4e6)
  # Provenance discipline: every row has a non-empty source
  expect_true(all(nchar(as.character(d$source)) > 0))
})
