# tests/testthat/test-L1.R
# Contract test for L1 biology import layer.
# PROVENANCE.yaml must exist (created by export_biology_from_metapop.R).
# build_L1() must return a tidy region×year tibble with correct columns,
# factor levels matching the schema REGIONS vector, and the sha256 in
# PROVENANCE.yaml must match the on-disk snapshot copy.

source(here::here("R", "schema.R"))

test_that("L1 biology import is provenance-tagged and read-only", {
  source(here::here("R", "layer_L1_biology.R"))
  pv <- here::here("data-raw", "biology", "PROVENANCE.yaml")
  skip_if_not(file.exists(pv), "run export_biology first")

  meta <- read_provenance(pv)

  # Provenance metadata integrity
  expect_true(grepl("m1_stier_11", meta$model_branch))
  expect_true(nchar(meta$sha256) == 64)

  # build_L1 returns a valid tibble
  L1 <- build_L1()

  # Required columns present
  expect_true(all(c("region", "year", "biomass_t",
                    "recruitment", "exploitation_rate") %in% names(L1)))

  # NA columns for variables absent from source
  expect_true(all(is.na(L1$recruitment)) && all(is.na(L1$exploitation_rate)))

  # Type contracts
  expect_s3_class(L1$region, "factor")
  expect_identical(levels(L1$region), REGIONS)
  expect_true(is.integer(L1$year))
  expect_true(is.double(L1$biomass_t) && all(!is.na(L1$biomass_t)) && all(L1$biomass_t > 0))

  # Region contract: all rows are HG, no rows outside REGIONS
  expect_true(all(L1$region %in% REGIONS))

  # sha256 in PROVENANCE.yaml must match the on-disk snapshot copy
  # (catches stale/mutated snapshot that would silently produce wrong biomass)
  snap <- here::here("data-raw", "biology", "m1_stier_11_biology_total_by_year.csv")
  expect_true(file.exists(snap), label = "total-biomass snapshot CSV must exist")
  expect_identical(unname(meta$sha256),
                   digest::digest(file = snap, algo = "sha256"))
})
