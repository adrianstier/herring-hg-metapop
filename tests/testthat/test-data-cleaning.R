# ============================================================================
# test-data-cleaning.R — Unit tests for data cleaning functions
# stier-2027-herring-metapopulation
#
# Run with: testthat::test_file("tests/testthat/test-data-cleaning.R")
# Or:       testthat::test_dir("tests/testthat")
# ============================================================================

library(testthat)
library(tidyverse)
library(here)
library(janitor)

# Source the setup and cleaning functions
source(here("R", "00_setup.R"))
source(here("R", "01_data_cleaning.R"))
source(here("R", "02_prepare_model_data.R"))
source(here("R", "03_fit_model.R"))
source(here("R", "08_occupancy_model.R"))
source(here("R", "09_zero_inflated_obs.R"))
source(here("R", "10_spatial_data.R"))

# ── Paths to test data ──
path_spawn_legacy <- here("Data", "raw", "legacy-2019", "HG_Spawn_Survey_1940_2015.csv")
path_spawn_new    <- here("Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv")
path_catch_legacy <- here("Data", "raw", "legacy-2019", "herring_catch_local2015.csv")
path_catch_new    <- here("Data", "raw", "dfo-catch", "herring_catch_local2024.csv")
path_pdo_legacy   <- here("Data", "raw", "legacy-2019", "pdo.csv")
path_pdo_ext      <- here("Data", "raw", "environmental", "pdo_2015_2025.csv")
path_ssl          <- here("Data", "raw", "predators",
                          "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv")
path_seal         <- here("Data", "raw", "predators",
                          "Harbour_seal_counts_haulout_locs_BCcoast.csv")
path_whale        <- here("Data", "raw", "predators",
                          "humpback_whale_NorthPacific_abundance_Cheeseman2024.csv")
path_sst          <- here("Data", "raw", "environmental",
                          "oisst_haida_gwaii_monthly_regional_avg_2014_2025.csv")
path_distance_xlsx <- here("Data", "raw",
                           "Euclidean & effective distance matrices herring & Steller.xlsx")

# ============================================================================
# clean_spawn
# ============================================================================

test_that("clean_spawn returns correct dimensions", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)

  expect_type(spawn, "list")
  expect_named(spawn, c("wide", "long", "site_order"), ignore.order = TRUE)

  # Wide matrix: N_YEARS rows x N_SITES columns

  expect_equal(nrow(spawn$wide), N_YEARS)
  expect_equal(ncol(spawn$wide), N_SITES)

  # Column names should be SITE_NAMES
  expect_equal(colnames(spawn$wide), SITE_NAMES)

  # Row names should be the year sequence as character
  expect_equal(rownames(spawn$wide), as.character(YEARS))

  # Long tibble should have one row per year x site combo
  expect_equal(nrow(spawn$long), N_YEARS * N_SITES)
})

test_that("clean_spawn preserves surveyed zeros and logs positives only", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)

  expect_true(all(c("totalrecords", "surveyed", "positive_spawn", "survey_status") %in%
                    names(spawn$long)))

  zero_rows <- spawn$long |>
    filter(survey_status == "censored_zero")
  nonzero_rows <- spawn$long |>
    filter(survey_status == "positive")
  missing_rows <- spawn$long |>
    filter(survey_status == "missing")

  # Surveyed zeros remain explicit in the long data and are censored on log scale.
  expect_gt(nrow(zero_rows), 0)
  expect_true(all(zero_rows$surveyed))
  expect_true(all(zero_rows$spawn_index == 0))
  expect_true(all(is.na(zero_rows$log_shi)))

  # Positive values are the only cells with finite log-SHI.
  expect_true(all(nonzero_rows$spawn_index > 0))
  expect_true(all(!is.na(nonzero_rows$log_shi)))
  expect_true(all(!missing_rows$surveyed))
  expect_true(all(is.na(missing_rows$log_shi)))

  # The wide matrix should have NO exact zeros (they should all be NA)
  non_na_values <- spawn$wide[!is.na(spawn$wide)]
  # log(SHI) could be any real number, but there should be no -Inf (log(0))
  expect_true(all(is.finite(non_na_values)))
})

test_that("clean_spawn filters out dropped sections", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)

  # Sections 4 (Cartwright Sound) and 11 (Masset Inlet) should be excluded
  sections_in_data <- unique(spawn$long$section)
  expect_false(4L %in% sections_in_data)
  expect_false(11L %in% sections_in_data)
  expect_equal(sort(sections_in_data), sort(SECTIONS_KEEP))
})

test_that("clean_spawn site_order matches SITE_NAMES", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  expect_equal(spawn$site_order, SITE_NAMES)
})


# ============================================================================
# clean_catch
# ============================================================================

test_that("clean_catch returns correct dimensions", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)

  expect_type(catch, "list")
  expect_named(catch, c("wide", "log_catch", "long", "site_order"),
               ignore.order = TRUE)

  expect_equal(nrow(catch$wide), N_YEARS)
  expect_equal(ncol(catch$wide), N_SITES)
  expect_equal(nrow(catch$log_catch), N_YEARS)
  expect_equal(ncol(catch$log_catch), N_SITES)
})

test_that("clean_catch columns align with spawn columns by name", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)

  # Column names must be identical (same site order)
  expect_equal(colnames(catch$wide), colnames(spawn$wide))
  expect_equal(colnames(catch$log_catch), colnames(spawn$wide))
  expect_equal(catch$site_order, spawn$site_order)
})

test_that("clean_catch log_catch is log(catch + 1)", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)

  # Verify the log transform
  expected_log <- log(catch$wide + 1)
  expect_equal(catch$log_catch, expected_log)
})

test_that("clean_catch has no negative values", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  expect_true(all(catch$wide >= 0))
})


# ============================================================================
# clean_pdo
# ============================================================================

test_that("clean_pdo returns correct length", {
  pdo <- clean_pdo(path_pdo_legacy, path_pdo_ext)

  expect_type(pdo, "double")
  expect_length(pdo, N_YEARS)
  expect_equal(as.integer(names(pdo)), YEARS)
})

test_that("clean_pdo has no NAs", {
  pdo <- clean_pdo(path_pdo_legacy, path_pdo_ext)
  expect_true(all(!is.na(pdo)))
})

test_that("clean_pdo values are reasonable (between -4 and 4)", {
  pdo <- clean_pdo(path_pdo_legacy, path_pdo_ext)
  expect_true(all(pdo > -4 & pdo < 4))
})


# ============================================================================
# build_catch_index
# ============================================================================

test_that("build_catch_index produces correct number of entries", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  idx   <- build_catch_index(catch$wide)

  # Total entries must equal N_YEARS * N_SITES
  expect_equal(idx$n_index + idx$n_index_zero, N_YEARS * N_SITES)

  # INDEX and INDEX_zero must have matching row counts
  expect_equal(nrow(idx$INDEX), idx$n_index)
  expect_equal(nrow(idx$INDEX_zero), idx$n_index_zero)
})

test_that("build_catch_index INDEX contains only positive-catch positions", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  idx   <- build_catch_index(catch$wide)

  # Every (row, col) in INDEX should correspond to positive catch
  for (k in seq_len(nrow(idx$INDEX))) {
    r <- idx$INDEX$row[k]
    c <- idx$INDEX$col[k]
    expect_gt(catch$wide[r, c], 0,
              label = paste0("catch[", r, ",", c, "] should be > 0"))
  }
})

test_that("build_catch_index INDEX.zero contains only zero-catch positions", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  idx   <- build_catch_index(catch$wide)

  # Every (row, col) in INDEX_zero should be zero catch
  for (k in seq_len(min(nrow(idx$INDEX_zero), 50))) {
    # Check first 50 to keep test fast
    r <- idx$INDEX_zero$row[k]
    c <- idx$INDEX_zero$col[k]
    expect_equal(catch$wide[r, c], 0,
                 label = paste0("catch[", r, ",", c, "] should be 0"))
  }
})

test_that("build_catch_index catch_dummy is binary", {
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  idx   <- build_catch_index(catch$wide)

  expect_true(all(idx$catch_dummy %in% c(0L, 1L)))
  expect_equal(sum(idx$catch_dummy), idx$n_index)
})


# ============================================================================
# build_survey_index
# ============================================================================

test_that("build_survey_index returns correct length and values", {
  q_idx <- build_survey_index()

  expect_length(q_idx, N_YEARS)
  expect_true(all(q_idx %in% c(1L, 2L, 3L)))

  # Surface surveys before the mixed transition
  n_surface <- sum(YEARS < SURVEY_MIXED_START_YEAR)
  expect_equal(sum(q_idx == 1L), n_surface)

  # Mixed transition years
  n_mixed <- sum(YEARS >= SURVEY_MIXED_START_YEAR & YEARS < SURVEY_DIVE_START_YEAR)
  expect_equal(sum(q_idx == 2L), n_mixed)

  # Dive-dominant years
  n_dive <- sum(YEARS >= SURVEY_DIVE_START_YEAR)
  expect_equal(sum(q_idx == 3L), n_dive)
})

test_that("build_survey_index transition is at correct year", {
  q_idx <- build_survey_index()

  # 1989 should be surface (1), 1990-1992 mixed (2), 1993 dive (3)
  idx_1989 <- which(YEARS == 1989L)
  idx_1990 <- which(YEARS == 1990L)
  idx_1992 <- which(YEARS == 1992L)
  idx_1993 <- which(YEARS == 1993L)

  expect_equal(q_idx[idx_1989], 1L)
  expect_equal(q_idx[idx_1990], 2L)
  expect_equal(q_idx[idx_1992], 2L)
  expect_equal(q_idx[idx_1993], 3L)
})


# ============================================================================
# prepare_model_data (integration)
# ============================================================================

test_that("prepare_model_data (format='stan') assembles valid Stan data list", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  pdo   <- clean_pdo(path_pdo_legacy, path_pdo_ext)

  model_data <- prepare_model_data(spawn, catch, pdo, format = "stan")

  expect_type(model_data, "list")

  # Check all Stan-format components are present
  expected_names <- c("N_years", "N_sites", "Y", "Y_obs", "Y_censored",
                      "Y_missing", "Y_obs_flag", "Y_censored_flag",
                      "Y_missing_flag", "pdo", "q_idx",
                      "N_catch", "catch_row", "catch_col", "log_catch",
                      "N_zero", "zero_row", "zero_col", "prior_only")
  expect_true(all(expected_names %in% names(model_data)))

  # Verify dimensions
  expect_equal(model_data$N_years, N_YEARS)
  expect_equal(model_data$N_sites, N_SITES)
  expect_equal(dim(model_data$Y), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$Y_obs), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$Y_censored), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$Y_missing), c(N_YEARS, N_SITES))
  expect_equal(length(model_data$pdo), N_YEARS)
  expect_equal(length(model_data$q_idx), N_YEARS)

  # Y should have no NAs (NAs replaced with 0 for Stan)
  expect_false(any(is.na(model_data$Y)))

  # Y_obs should be binary (0 or 1)
  expect_true(all(model_data$Y_obs %in% c(0L, 1L)))
  expect_true(all(model_data$Y_censored %in% c(0L, 1L)))
  expect_true(all(model_data$Y_missing %in% c(0L, 1L)))
  expect_true(all(model_data$Y_obs + model_data$Y_censored + model_data$Y_missing == 1L))
  expect_gt(sum(model_data$Y_censored), 0)
  expect_identical(model_data$Y_obs_flag, model_data$Y_obs)
  expect_identical(model_data$Y_censored_flag, model_data$Y_censored)
  expect_identical(model_data$Y_missing_flag, model_data$Y_missing)

  # catch_row and catch_col should have length N_catch
  expect_equal(length(model_data$catch_row), model_data$N_catch)
  expect_equal(length(model_data$catch_col), model_data$N_catch)
  expect_equal(length(model_data$log_catch), model_data$N_catch)

  # zero_row and zero_col should have length N_zero
  expect_equal(length(model_data$zero_row), model_data$N_zero)
  expect_equal(length(model_data$zero_col), model_data$N_zero)

  # Total entries check
  expect_equal(model_data$N_catch + model_data$N_zero,
               N_YEARS * N_SITES)
})

test_that("prepare_model_data default format is 'stan'", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  pdo   <- clean_pdo(path_pdo_legacy, path_pdo_ext)

  model_data <- prepare_model_data(spawn, catch, pdo)

  # Default should produce Stan format (N_years, not nYears)
  expect_true("N_years" %in% names(model_data))
  expect_false("nYears" %in% names(model_data))
})

test_that("prepare_model_data (format='jags') assembles valid JAGS data list", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  pdo   <- clean_pdo(path_pdo_legacy, path_pdo_ext)

  model_data <- prepare_model_data(spawn, catch, pdo, format = "jags")

  expect_type(model_data, "list")

  # Check all JAGS-format components are present
  expected_names <- c("Y", "Y_clean", "Y_obs", "Y_censored", "Y_missing",
                      "nYears", "nSites", "pdo", "ctab",
                      "INDEX", "INDEX.zero", "nIndex", "nIndex.zero", "q_idx")
  expect_true(all(expected_names %in% names(model_data)))

  # Verify dimensions
  expect_equal(model_data$nYears, N_YEARS)
  expect_equal(model_data$nSites, N_SITES)
  expect_equal(dim(model_data$Y), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$Y_clean), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$Y_obs), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$Y_censored), c(N_YEARS, N_SITES))
  expect_true(all(model_data$Y_obs + model_data$Y_censored + model_data$Y_missing == 1L))
  expect_equal(dim(model_data$ctab), c(N_YEARS, N_SITES))
  expect_equal(length(model_data$pdo), N_YEARS)
  expect_equal(length(model_data$q_idx), N_YEARS)

  # INDEX is a matrix with 2 columns (row, col)
  expect_equal(ncol(model_data$INDEX), 2)
  expect_equal(ncol(model_data$INDEX.zero), 2)

  # Total entries check
  expect_equal(model_data$nIndex + model_data$nIndex.zero,
               N_YEARS * N_SITES)
})

test_that("prepare_model_data appends predators when provided", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  pdo   <- clean_pdo(path_pdo_legacy, path_pdo_ext)

  skip_if_not(
    file.exists(path_ssl) && file.exists(path_seal) && file.exists(path_whale),
    "Predator data files not found"
  )

  pred <- clean_predators(path_ssl, path_seal, path_whale)
  model_data <- prepare_model_data(spawn, catch, pdo, predators = pred)

  expect_true("predators" %in% names(model_data))
  expect_equal(nrow(model_data$predators), N_YEARS)
})

test_that("prepare_model_data appends spatial predator data with current names", {
  skip_if_not(
    file.exists(path_ssl) && file.exists(path_seal) &&
      file.exists(path_whale) && file.exists(path_distance_xlsx),
    "Spatial predator input files not found"
  )

  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  pdo   <- clean_pdo(path_pdo_legacy, path_pdo_ext)
  pred  <- clean_predators(path_ssl, path_seal, path_whale)
  D     <- load_distance_matrix(path_distance_xlsx)
  cent  <- get_spawn_centroids(path_spawn_new, path_distance_xlsx)

  predator_spatial <- build_predator_spatial_index(
    ssl_data  = read_csv(path_ssl, show_col_types = FALSE),
    seal_data = read_csv(path_seal, show_col_types = FALSE,
                         locale = locale(encoding = "latin1")),
    spawn_coords = cent,
    distance_decay_km = 50
  )

  model_data <- prepare_model_data(
    spawn = spawn,
    catch = catch,
    pdo = pdo,
    predators = pred,
    spatial = TRUE,
    distance_matrix = D,
    predator_spatial = predator_spatial
  )

  expect_true(all(c("dist_mat", "max_dist", "ssl_spatial", "seal_spatial",
                    "whale_obs", "pred_obs") %in% names(model_data)))
  expect_equal(dim(model_data$dist_mat), c(N_SITES, N_SITES))
  expect_equal(dim(model_data$ssl_spatial), c(N_YEARS, N_SITES))
  expect_equal(dim(model_data$seal_spatial), c(N_YEARS, N_SITES))
  expect_equal(length(model_data$whale_obs), N_YEARS)
  expect_equal(length(model_data$pred_obs), N_YEARS)
})

test_that(".build_stan_input maps version-specific fields correctly", {
  skip_if_not(
    file.exists(path_ssl) && file.exists(path_seal) &&
      file.exists(path_whale) && file.exists(path_distance_xlsx),
    "Stan input files not found"
  )

  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)
  catch <- clean_catch(path_catch_legacy, path_catch_new)
  pdo   <- clean_pdo(path_pdo_legacy, path_pdo_ext)
  pred  <- clean_predators(path_ssl, path_seal, path_whale)
  D     <- load_distance_matrix(path_distance_xlsx)
  cent  <- get_spawn_centroids(path_spawn_new, path_distance_xlsx)

  predator_spatial <- build_predator_spatial_index(
    ssl_data  = read_csv(path_ssl, show_col_types = FALSE),
    seal_data = read_csv(path_seal, show_col_types = FALSE,
                         locale = locale(encoding = "latin1")),
    spawn_coords = cent,
    distance_decay_km = 50
  )

  model_base <- prepare_model_data(spawn, catch, pdo, predators = pred)
  model_spatial <- prepare_model_data(
    spawn = spawn,
    catch = catch,
    pdo = pdo,
    predators = pred,
    spatial = TRUE,
    distance_matrix = D,
    predator_spatial = predator_spatial
  )

  v1_input <- .build_stan_input(model_base, "v1")
  m2_input <- .build_stan_input(model_spatial, "m2")
  m5_input <- .build_stan_input(model_spatial, "m5")
  m6_input <- .build_stan_input(model_spatial, "m6")

  expect_true("prior_only" %in% names(v1_input))
  expect_true(all(c("dist_mat", "max_dist") %in% names(m2_input)))
  expect_equal(length(m5_input$seal), N_YEARS)
  expect_equal(length(m5_input$ssl), N_YEARS)
  expect_equal(dim(m6_input$seal), c(N_YEARS, N_SITES))
  expect_equal(dim(m6_input$ssl), c(N_YEARS, N_SITES))
  expect_equal(length(m6_input$whale_obs), N_YEARS)
  expect_equal(length(m6_input$pred_obs), N_YEARS)
})

test_that("prepare_stan_data_spatial appends validated distance data and masks", {
  skip_if_not(file.exists(path_distance_xlsx), "Distance matrix file not found")

  stan_data <- list(
    N_years = N_YEARS,
    N_sites = N_SITES,
    whale = rep(c(0, 1), length.out = N_YEARS),
    ssl = matrix(0, nrow = N_YEARS, ncol = N_SITES),
    seal = matrix(0, nrow = N_YEARS, ncol = N_SITES)
  )
  stan_data$ssl[1, 1] <- 1
  stan_data$seal[2, 1] <- 1

  out <- prepare_stan_data_spatial(stan_data, distance_type = "effective")

  expect_true(all(c("dist_mat", "max_dist", "whale_obs", "pred_obs") %in% names(out)))
  expect_equal(dim(out$dist_mat), c(N_SITES, N_SITES))
  expect_equal(length(out$whale_obs), N_YEARS)
  expect_equal(length(out$pred_obs), N_YEARS)
  expect_equal(out$whale_obs[1], 0L)
  expect_equal(out$whale_obs[2], 1L)
  expect_equal(out$pred_obs[1], 1L)
  expect_equal(out$pred_obs[2], 1L)
})


# ============================================================================
# clean_sst
# ============================================================================

test_that("clean_sst returns correct structure", {
  skip_if_not(file.exists(path_sst), "SST data file not found")

  sst <- clean_sst(path_sst)

  expect_s3_class(sst, "tbl_df")
  expect_true(all(c("year", "sst_spring", "anom_spring") %in% names(sst)))
})

test_that("clean_sst has correct year range and no NA in years", {
  skip_if_not(file.exists(path_sst), "SST data file not found")

  sst <- clean_sst(path_sst)

  # All years should be valid integers (no NA)
  expect_true(all(!is.na(sst$year)))

  # Years should be within a plausible range
  expect_true(all(sst$year >= 1980 & sst$year <= 2030))

  # No unexpected NAs in SST columns for years that have data
  expect_true(all(!is.na(sst$sst_spring)))
  expect_true(all(!is.na(sst$anom_spring)))
})

test_that("clean_sst handles multiple paths", {
  skip_if_not(file.exists(path_sst), "SST data file not found")

  raw_sst <- read_csv(path_sst, show_col_types = FALSE)
  tmp1 <- tempfile(fileext = ".csv")
  tmp2 <- tempfile(fileext = ".csv")
  write_csv(raw_sst |> slice(1:(nrow(raw_sst) %/% 2)), tmp1)
  write_csv(raw_sst |> slice((nrow(raw_sst) %/% 2 + 1):n()), tmp2)

  sst <- clean_sst(c(tmp1, tmp2))

  expect_s3_class(sst, "tbl_df")
  sst_single <- clean_sst(path_sst)
  expect_equal(sst, sst_single)
})


# ============================================================================
# clean_predators
# ============================================================================

test_that("clean_predators returns correct structure", {
  skip_if_not(
    file.exists(path_ssl) && file.exists(path_seal) && file.exists(path_whale),
    "Predator data files not found"
  )

  pred <- clean_predators(path_ssl, path_seal, path_whale)

  expect_s3_class(pred, "tbl_df")
  expect_true(all(c("year", "ssl_count", "seal_count", "whale_abundance") %in%
                    names(pred)))
})

test_that("clean_predators covers full year range", {
  skip_if_not(
    file.exists(path_ssl) && file.exists(path_seal) && file.exists(path_whale),
    "Predator data files not found"
  )

  pred <- clean_predators(path_ssl, path_seal, path_whale)

  # Year column should span YEAR_START to YEAR_END with no gaps
  expect_equal(pred$year, seq(YEAR_START, YEAR_END))
  expect_equal(nrow(pred), N_YEARS)
})

test_that("clean_predators has no unexpected NAs in year column", {
  skip_if_not(
    file.exists(path_ssl) && file.exists(path_seal) && file.exists(path_whale),
    "Predator data files not found"
  )

  pred <- clean_predators(path_ssl, path_seal, path_whale)

  # Year should never be NA (it's the grid)
  expect_true(all(!is.na(pred$year)))

  # Predator counts may have NAs (survey gaps), but year must be complete
  expect_equal(length(pred$year), N_YEARS)
})


# ============================================================================
# prepare_occupancy_data
# ============================================================================

test_that("prepare_occupancy_data includes post-2015 survey effort", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)

  occ <- prepare_occupancy_data(
    spawn_clean = spawn,
    path_legacy = path_spawn_legacy,
    path_new    = path_spawn_new
  )

  post_2015_idx <- which(YEARS >= 2016L)
  expect_gt(sum(occ$surveyed[post_2015_idx, ]), 0)
})

test_that("prepare_censored_data includes post-2015 survey effort", {
  spawn <- clean_spawn(path_spawn_legacy, path_spawn_new)

  censored <- prepare_censored_data(
    spawn_clean = spawn,
    path_legacy = path_spawn_legacy,
    path_new    = path_spawn_new
  )

  post_2015_idx <- which(YEARS >= 2016L)
  expect_gt(
    sum(censored$Y_observed[post_2015_idx, ] + censored$Y_censored[post_2015_idx, ]),
    0
  )
  expect_true(all(
    censored$Y_observed + censored$Y_censored + censored$Y_missing == 1L
  ))
})
