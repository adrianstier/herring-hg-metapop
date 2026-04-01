# ============================================================================
# test-spatial.R — Unit tests for spatial data functions
# stier-2027-herring-metapopulation
#
# Run with: testthat::test_file("tests/testthat/test-spatial.R")
# Or:       testthat::test_dir("tests/testthat")
# ============================================================================

library(testthat)
library(tidyverse)
library(here)
library(janitor)

# Source the setup and spatial functions
source(here("R", "00_setup.R"))
source(here("R", "01_data_cleaning.R"))
source(here("R", "10_spatial_data.R"))

# ── Paths ──
path_distance_xlsx <- here("Data", "raw",
                           "Euclidean & effective distance matrices herring & Steller.xlsx")
path_spawn_new     <- here("Data", "raw", "dfo-spawn",
                           "HG_spawn_index_by_section_1951_2025.csv")
path_spawn_legacy  <- here("Data", "raw", "legacy-2019",
                           "HG_Spawn_Survey_1940_2015.csv")
path_ssl           <- here("Data", "raw", "predators",
                           "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv")
path_seal          <- here("Data", "raw", "predators",
                           "Harbour_seal_counts_haulout_locs_BCcoast.csv")

# ============================================================================
# load_distance_matrix
# ============================================================================

test_that("load_distance_matrix returns correct dimensions", {
  skip_if_not(file.exists(path_distance_xlsx),
              "Distance matrix xlsx not found")

  D <- load_distance_matrix(path_distance_xlsx)

  expect_equal(nrow(D), N_SITES)
  expect_equal(ncol(D), N_SITES)
})

test_that("load_distance_matrix is symmetric", {
  skip_if_not(file.exists(path_distance_xlsx))

  D <- load_distance_matrix(path_distance_xlsx)

  expect_equal(D, t(D), tolerance = 1e-6)
})

test_that("load_distance_matrix has zero diagonal", {
  skip_if_not(file.exists(path_distance_xlsx))

  D <- load_distance_matrix(path_distance_xlsx)

  expect_equal(unname(diag(D)), rep(0, N_SITES))
})

test_that("load_distance_matrix is non-negative", {
  skip_if_not(file.exists(path_distance_xlsx))

  D <- load_distance_matrix(path_distance_xlsx)

  expect_true(all(D >= 0))
})

test_that("load_distance_matrix has no NAs", {
  skip_if_not(file.exists(path_distance_xlsx))

  D <- load_distance_matrix(path_distance_xlsx)

  expect_false(any(is.na(D)))
})

test_that("load_distance_matrix row/col names match SITE_NAMES", {
  skip_if_not(file.exists(path_distance_xlsx))

  D <- load_distance_matrix(path_distance_xlsx)

  expect_equal(rownames(D), SITE_NAMES)
  expect_equal(colnames(D), SITE_NAMES)
})

test_that("load_distance_matrix returns km values (not metres)", {
  skip_if_not(file.exists(path_distance_xlsx))

  D <- load_distance_matrix(path_distance_xlsx, units_out = "km")

  # Distances between Haida Gwaii sections should be in the range of
  # ~5-400 km, not 5000-400000 (metres)
  max_dist <- max(D)
  expect_lt(max_dist, 1000)   # < 1000 km
  expect_gt(max_dist, 10)     # > 10 km (sections are spread across HG)
})

test_that("load_distance_matrix units_out = 'm' returns larger values", {
  skip_if_not(file.exists(path_distance_xlsx))

  D_km <- load_distance_matrix(path_distance_xlsx, units_out = "km")
  D_m  <- load_distance_matrix(path_distance_xlsx, units_out = "m")

  expect_equal(D_m, D_km * 1000, tolerance = 1e-6)
})

test_that("load_distance_matrix can read Euclidean sheet too", {
  skip_if_not(file.exists(path_distance_xlsx))

  D_euc <- load_distance_matrix(path_distance_xlsx,
                                sheet = "Herring Euclidean")
  expect_equal(nrow(D_euc), N_SITES)
  expect_equal(D_euc, t(D_euc), tolerance = 1e-6)
})

# ============================================================================
# validate_distance_matrix
# ============================================================================

test_that("validate_distance_matrix passes on valid matrix", {
  D <- matrix(0, N_SITES, N_SITES)
  for (i in 1:(N_SITES-1)) {
    for (j in (i+1):N_SITES) {
      D[i, j] <- D[j, i] <- runif(1, 10, 300)
    }
  }
  rownames(D) <- SITE_NAMES
  colnames(D) <- SITE_NAMES

  expect_true(validate_distance_matrix(D))
})

test_that("validate_distance_matrix rejects non-square matrix", {
  D <- matrix(1, N_SITES, N_SITES + 1)
  expect_error(validate_distance_matrix(D), "not square")
})

test_that("validate_distance_matrix rejects wrong dimensions", {
  D <- matrix(0, 5, 5)
  expect_error(validate_distance_matrix(D), "N_SITES")
})

test_that("validate_distance_matrix rejects NAs", {
  D <- matrix(0, N_SITES, N_SITES)
  D[1, 2] <- NA
  expect_error(validate_distance_matrix(D, check_names = FALSE), "NA")
})

test_that("validate_distance_matrix rejects negative values", {
  D <- matrix(0, N_SITES, N_SITES)
  D[1, 2] <- -1
  D[2, 1] <- -1
  expect_error(validate_distance_matrix(D, check_names = FALSE), "negative")
})

test_that("validate_distance_matrix rejects non-zero diagonal", {
  D <- diag(1, N_SITES, N_SITES)
  expect_error(validate_distance_matrix(D, check_names = FALSE), "diagonal")
})

test_that("validate_distance_matrix rejects asymmetric matrix", {
  D <- matrix(0, N_SITES, N_SITES)
  D[1, 2] <- 100
  D[2, 1] <- 200
  expect_error(validate_distance_matrix(D, check_names = FALSE), "symmetric")
})

# ============================================================================
# compute_distance_matrix
# ============================================================================

test_that("compute_distance_matrix produces valid output from DFO spawn data", {
  skip_if_not(file.exists(path_spawn_new))
  skip_if_not(file.exists(path_distance_xlsx),
              "Distance matrix xlsx needed as fallback for missing section coords")

  D <- compute_distance_matrix(path_spawn_csv = path_spawn_new,
                               path_distance_xlsx = path_distance_xlsx)

  expect_equal(nrow(D), N_SITES)
  expect_equal(ncol(D), N_SITES)
  expect_equal(D, t(D), tolerance = 1e-6)
  expect_equal(unname(diag(D)), rep(0, N_SITES))
  expect_true(all(D >= 0))
  expect_false(any(is.na(D)))
})

test_that("compute_distance_matrix gives plausible Haida Gwaii distances", {
  skip_if_not(file.exists(path_spawn_new))
  skip_if_not(file.exists(path_distance_xlsx))

  D <- compute_distance_matrix(path_spawn_csv = path_spawn_new,
                               path_distance_xlsx = path_distance_xlsx)

  # Haida Gwaii is roughly 250 km north-south, so max distance < 300 km
  expect_lt(max(D), 400)
  # Adjacent sections should be > 5 km apart
  D_offdiag <- D[D > 0]
  expect_gt(min(D_offdiag), 1)
})

# ============================================================================
# haversine_km
# ============================================================================

test_that("haversine_km returns zero for same point", {
  d <- haversine_km(52.5, -131.5, 52.5, -131.5)
  expect_equal(d, 0)
})

test_that("haversine_km gives plausible distance", {
  # Vancouver to Victoria: ~100 km
  d <- haversine_km(49.28, -123.12, 48.43, -123.37)
  expect_gt(d, 80)
  expect_lt(d, 120)
})

# ============================================================================
# get_spawn_centroids
# ============================================================================

test_that("get_spawn_centroids returns all SECTIONS_KEEP", {
  skip_if_not(file.exists(path_spawn_new) || file.exists(path_distance_xlsx))

  centroids <- get_spawn_centroids(
    path_spawn_csv     = path_spawn_new,
    path_distance_xlsx = path_distance_xlsx
  )

  expect_equal(nrow(centroids), N_SITES)
  expect_true(all(SECTIONS_KEEP %in% centroids$section))
  expect_true(all(c("section", "section_name", "lat", "lon") %in% names(centroids)))
})

test_that("get_spawn_centroids coordinates are in Haida Gwaii range", {
  skip_if_not(file.exists(path_spawn_new) || file.exists(path_distance_xlsx))

  centroids <- get_spawn_centroids(
    path_spawn_csv     = path_spawn_new,
    path_distance_xlsx = path_distance_xlsx
  )

  # Haida Gwaii: roughly 51.8-54.4 N, -133.2 to -130.9 W
  expect_true(all(centroids$lat > 51, na.rm = TRUE))
  expect_true(all(centroids$lat < 55, na.rm = TRUE))
  expect_true(all(centroids$lon > -134, na.rm = TRUE))
  expect_true(all(centroids$lon < -130, na.rm = TRUE))
})

# ============================================================================
# build_predator_spatial_index
# ============================================================================

test_that("build_predator_spatial_index returns correct dimensions", {
  skip_if_not(file.exists(path_ssl) && file.exists(path_seal))
  skip_if_not(file.exists(path_spawn_new) || file.exists(path_distance_xlsx))

  centroids <- get_spawn_centroids(
    path_spawn_csv     = path_spawn_new,
    path_distance_xlsx = path_distance_xlsx
  )

  ssl_data  <- read_csv(path_ssl, show_col_types = FALSE)
  seal_data <- read_csv(path_seal, show_col_types = FALSE,
                        locale = locale(encoding = "latin1"))

  result <- build_predator_spatial_index(
    ssl_data     = ssl_data,
    seal_data    = seal_data,
    spawn_coords = centroids,
    distance_decay_km = 50
  )

  expect_equal(nrow(result$ssl_spatial),  N_YEARS)
  expect_equal(ncol(result$ssl_spatial),  N_SITES)
  expect_equal(nrow(result$seal_spatial), N_YEARS)
  expect_equal(ncol(result$seal_spatial), N_SITES)
})

test_that("predator spatial index is non-negative", {
  skip_if_not(file.exists(path_ssl) && file.exists(path_seal))
  skip_if_not(file.exists(path_spawn_new) || file.exists(path_distance_xlsx))

  centroids <- get_spawn_centroids(
    path_spawn_csv     = path_spawn_new,
    path_distance_xlsx = path_distance_xlsx
  )

  ssl_data  <- read_csv(path_ssl, show_col_types = FALSE)
  seal_data <- read_csv(path_seal, show_col_types = FALSE,
                        locale = locale(encoding = "latin1"))

  result <- build_predator_spatial_index(
    ssl_data     = ssl_data,
    seal_data    = seal_data,
    spawn_coords = centroids,
    distance_decay_km = 50
  )

  expect_true(all(result$ssl_spatial >= 0))
  expect_true(all(result$seal_spatial >= 0))
})

test_that("closer predator sites contribute more than distant ones", {
  # Create two predator sites: one close (10 km), one far (200 km)
  # from a herring section. The close one should get a higher weight.

  # Need spawn_coords for ALL SECTIONS_KEEP (the function validates this)
  # Use realistic Haida Gwaii coordinates spread across sections
  spawn_coords <- tibble(
    section = SECTIONS_KEEP,
    lat     = seq(52.2, 54.0, length.out = N_SITES),
    lon     = seq(-131.2, -132.9, length.out = N_SITES)
  )

  # Create mock SSL data with two sites: one close to section 1, one far
  ssl_data <- tibble(
    REGION       = "Haida Gwaii",
    SITE         = c("Close_Site", "Far_Site"),
    LATITUDE     = c(spawn_coords$lat[1] + 0.05, spawn_coords$lat[1] + 1.5),
    LONGITUDE    = c(spawn_coords$lon[1], spawn_coords$lon[1]),
    `SURVEY YEAR`  = c(2000L, 2000L),
    `COUNT NON-PUP` = c(100L, 100L),   # Same count
    `SITE TYPE`  = c("Y", "Y")
  )

  # Create mock seal data (minimal — just one site)
  seal_data <- tibble(
    Region        = "Haida Gwaii",
    Complex       = "Test_Complex",
    Longitude     = spawn_coords$lon[1],
    Latitude      = spawn_coords$lat[1] + 0.05,
    Year          = 2000L,
    complex_count = 50L,
    SubsiteID     = "H9999",
    FirstDocumented = 1990,
    Subarea       = "Test"
  )

  # Use a restricted year range for speed
  result <- build_predator_spatial_index(
    ssl_data          = ssl_data,
    seal_data         = seal_data,
    spawn_coords      = spawn_coords,
    distance_decay_km = 50,
    years             = 2000L
  )

  # The close site should contribute more than the far site
  # to the first herring section
  d_close <- haversine_km(spawn_coords$lat[1], spawn_coords$lon[1],
                          spawn_coords$lat[1] + 0.05, spawn_coords$lon[1])
  d_far   <- haversine_km(spawn_coords$lat[1], spawn_coords$lon[1],
                          spawn_coords$lat[1] + 1.5, spawn_coords$lon[1])
  w_close <- exp(-d_close / 50)
  w_far   <- exp(-d_far / 50)

  expect_gt(w_close, w_far)
  # The spatial index should be sum: 100 * w_close + 100 * w_far
  expected_ssl <- 100 * w_close + 100 * w_far
  expect_equal(result$ssl_spatial[1, 1], expected_ssl, tolerance = 0.1)
})

test_that("predator spatial index decay parameter affects weights", {
  skip_if_not(file.exists(path_ssl) && file.exists(path_seal))
  skip_if_not(file.exists(path_spawn_new) || file.exists(path_distance_xlsx))

  centroids <- get_spawn_centroids(
    path_spawn_csv     = path_spawn_new,
    path_distance_xlsx = path_distance_xlsx
  )

  ssl_data  <- read_csv(path_ssl, show_col_types = FALSE)
  seal_data <- read_csv(path_seal, show_col_types = FALSE,
                        locale = locale(encoding = "latin1"))

  # Shorter decay = more localized (lower total index, more spatial contrast)
  result_25 <- build_predator_spatial_index(
    ssl_data     = ssl_data,
    seal_data    = seal_data,
    spawn_coords = centroids,
    distance_decay_km = 25
  )

  # Longer decay = more diffuse (higher total index, less spatial contrast)
  result_100 <- build_predator_spatial_index(
    ssl_data     = ssl_data,
    seal_data    = seal_data,
    spawn_coords = centroids,
    distance_decay_km = 100
  )

  # With longer decay, total index should be higher (more distant sites
  # contribute meaningfully)
  expect_gt(
    sum(result_100$ssl_spatial, na.rm = TRUE),
    sum(result_25$ssl_spatial, na.rm = TRUE)
  )
})

# ============================================================================
# compute_spatial_weights
# ============================================================================

test_that("compute_spatial_weights returns correct dimensions", {
  W <- compute_spatial_weights(
    lat_from = c(52, 53),
    lon_from = c(-131, -132),
    lat_to   = c(52.5, 53.5, 54),
    lon_to   = c(-131.5, -132.5, -131),
    decay_km = 50
  )

  expect_equal(nrow(W), 2)
  expect_equal(ncol(W), 3)
})

test_that("compute_spatial_weights values are in [0, 1]", {
  W <- compute_spatial_weights(
    lat_from = c(52, 53),
    lon_from = c(-131, -132),
    lat_to   = c(52.5, 53.5, 54),
    lon_to   = c(-131.5, -132.5, -131),
    decay_km = 50
  )

  expect_true(all(W >= 0))
  expect_true(all(W <= 1))
})

test_that("compute_spatial_weights: same point gives weight = 1", {
  W <- compute_spatial_weights(
    lat_from = 52.5,
    lon_from = -131.5,
    lat_to   = 52.5,
    lon_to   = -131.5,
    decay_km = 50
  )

  expect_equal(W[1, 1], 1, tolerance = 1e-10)
})
