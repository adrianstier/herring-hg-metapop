test_that("outputs (csv, dictionary, QA) are written and complete", {
  source(here::here("R","write_outputs.R"))
  r <- write_outputs()
  expect_true(file.exists(here::here("data","herring_bioeconomic_backbone.csv")))
  expect_true(file.exists(here::here("docs","DATA_DICTIONARY.md")))
  expect_true(file.exists(here::here("Output","backbone_qa.md")))
  expect_gt(r$rows, 0)
  qa <- readLines(here::here("Output","backbone_qa.md"))
  expect_true(any(grepl("Anchor reconciliation", qa)))
  expect_true(any(grepl("Layer coverage", qa)))
  dd <- readLines(here::here("docs","DATA_DICTIONARY.md"))
  expect_true(any(grepl("^\\| `region` \\|", dd)))   # schema rendered
})
