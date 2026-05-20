# tests/testthat/test-schema.R
test_that("backbone schema contract is well-formed", {
  source(here::here("R", "schema.R"))
  s <- backbone_schema()
  expect_setequal(names(s), c("column", "type", "unit", "layer", "required"))
  expect_true(all(c("region","year") %in% s$column[s$required]))
  expect_true(all(s$layer %in% c("key","L0","L1","L2","L3")))
  # real-terms market columns must be paired nominal+real
  expect_true(all(c("roe_value_cad_nominal","roe_value_cad_real2020") %in% s$column))
})
