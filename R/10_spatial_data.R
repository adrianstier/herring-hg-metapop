# ============================================================================
# 10_spatial_data.R — Spatial data functions for metapopulation models
# stier-2027-herring-metapopulation
#
# Functions for loading/computing distance matrices between herring spawning
# sections and building spatially-weighted predator indices. These data feed
# the spatial Stan models (M2-M6).
#
# Source 00_setup.R before calling any of these.
# ============================================================================

# ── Distance matrix from Excel ──────────────────────────────────────────────

#' Load the effective distance matrix between herring spawning sections
#' from the pre-computed Excel file.
#'
#' The Excel file contains four sheets: Stellers Euclidean, Stellers Effective,
#' Herring Euclidean, Herring Effective. This function reads the "Herring
#' Effective" sheet (effective = shortest water path, not straight-line), extracts
#' the 13×13 matrix, subsets to SECTIONS_KEEP (11 sites), and converts from
#' metres to kilometres.
#'
#' @param path_xlsx Path to "Euclidean & effective distance matrices herring &
#'   Steller.xlsx"
#' @param sheet Sheet name to read (default: "Herring Effective"). Can also use
#'   "Herring Euclidean" for straight-line distances.
#' @param units_out Character, "km" (default) or "m". The raw data are in metres;
#'   if "km", divides by 1000.
#' @return Numeric matrix (N_SITES × N_SITES), symmetric, zero diagonal.
#'   Row/column names are SITE_NAMES. Units in km (default) or m.
load_distance_matrix <- function(path_xlsx,
                                 sheet = "Herring Effective",
                                 units_out = "km") {

  stopifnot(
    "readxl package required" = requireNamespace("readxl", quietly = TRUE),
    "SECTIONS_KEEP not defined — source 00_setup.R" = exists("SECTIONS_KEEP"),
    "SITE_NAMES not defined — source 00_setup.R"    = exists("SITE_NAMES"),
    "N_SITES not defined — source 00_setup.R"       = exists("N_SITES")
  )

  stopifnot(file.exists(path_xlsx))
  stopifnot(units_out %in% c("km", "m"))

  # Verify the requested sheet exists
  available_sheets <- readxl::excel_sheets(path_xlsx)
  if (!sheet %in% available_sheets) {
    stop("Sheet '", sheet, "' not found. Available sheets: ",
         paste(available_sheets, collapse = ", "))
  }

  raw <- readxl::read_excel(path_xlsx, sheet = sheet)

  # ---- Extract section IDs from first column (rows 1:13) ----
  # Column 1 holds section IDs as characters: "1","2","3","4","5","6",
  # "11","12","21","22","23","24","25"
  # Columns 2:14 hold the distance values, named Id1, Id2, ..., Id25
  section_ids_char <- raw[[1]][1:13]
  section_ids <- as.integer(section_ids_char)

  # Validate we got the expected 13 sections
  expected_all <- SECTIONS_ALL$section
  if (!all(expected_all %in% section_ids)) {
    stop("Distance matrix does not contain all expected section IDs. ",
         "Found: ", paste(section_ids, collapse = ", "),
         ". Expected: ", paste(expected_all, collapse = ", "))
  }

  # ---- Extract the 13×13 numeric distance matrix ----
  # Column names are Id1, Id2, ..., Id25; extract them by matching section IDs
  id_cols <- paste0("Id", section_ids)

  # Verify columns exist
  missing_cols <- setdiff(id_cols, names(raw))
  if (length(missing_cols) > 0) {
    stop("Missing columns in distance matrix: ", paste(missing_cols, collapse = ", "))
  }

  D_full <- raw[1:13, id_cols] |>
    as.data.frame() |>
    sapply(as.numeric)

  rownames(D_full) <- section_ids
  colnames(D_full) <- section_ids

  # ---- Subset to SECTIONS_KEEP ----
  keep_char <- as.character(SECTIONS_KEEP)

  if (!all(keep_char %in% rownames(D_full))) {
    stop("SECTIONS_KEEP contains sections not in distance matrix: ",
         paste(setdiff(keep_char, rownames(D_full)), collapse = ", "))
  }

  D <- D_full[keep_char, keep_char]

  # ---- Convert units ----
  if (units_out == "km") {
    D <- D / 1000
  }

  # ---- Assign readable names ----
  rownames(D) <- SITE_NAMES
  colnames(D) <- SITE_NAMES

  # ---- Validate ----
  validate_distance_matrix(D)

  D
}


# ── Compute distance matrix from spawn coordinates ──────────────────────────

#' Compute great-circle distances between herring spawning section centroids.
#'
#' Uses the Haversine formula on mean Latitude/Longitude per section from
#' the spawn survey data. This is a fallback when the Excel distance matrix
#' is unavailable or its format changes.
#'
#' @param spawn_clean List returned by clean_spawn() — needs $long tibble with
#'   section, section_name columns. Used only for section ordering.
#' @param spawn_coords Tibble with columns section (integer), latitude, longitude.
#'   If NULL, reads coordinates from the DFO spawn CSV or legacy CSV.
#' @param path_spawn_csv Path to the DFO spawn CSV with Latitude/Longitude
#'   columns. Used if spawn_coords is NULL.
#' @param path_spawn_legacy Path to legacy spawn CSV (has Latitude, Longitude).
#'   Used as additional source if path_spawn_csv is NULL.
#' @param path_distance_xlsx Path to the distance matrix Excel file (optional
#'   fallback for section coordinates not in the spawn CSV).
#' @return Numeric matrix (N_SITES × N_SITES), symmetric, zero diagonal,
#'   in kilometres. Row/column names are SITE_NAMES.
compute_distance_matrix <- function(spawn_clean = NULL,
                                    spawn_coords = NULL,
                                    path_spawn_csv = NULL,
                                    path_spawn_legacy = NULL,
                                    path_distance_xlsx = NULL) {

  stopifnot(
    "SECTIONS_KEEP not defined — source 00_setup.R" = exists("SECTIONS_KEEP"),
    "SITE_NAMES not defined — source 00_setup.R"    = exists("SITE_NAMES"),
    "N_SITES not defined — source 00_setup.R"       = exists("N_SITES")
  )

  # ---- Get coordinates per section ----
  if (!is.null(spawn_coords)) {
    # User-provided coordinates
    coords <- spawn_coords |>
      filter(section %in% SECTIONS_KEEP) |>
      group_by(section) |>
      summarise(
        lat = mean(latitude, na.rm = TRUE),
        lon = mean(longitude, na.rm = TRUE),
        .groups = "drop"
      )
  } else if (!is.null(path_spawn_csv)) {
    raw <- read_csv(path_spawn_csv, show_col_types = FALSE) |>
      janitor::clean_names() |>
      mutate(section = as.integer(section))

    coords <- raw |>
      filter(section %in% SECTIONS_KEEP, !is.na(latitude), !is.na(longitude)) |>
      group_by(section) |>
      summarise(
        lat = mean(latitude, na.rm = TRUE),
        lon = mean(longitude, na.rm = TRUE),
        .groups = "drop"
      )
  } else if (!is.null(path_spawn_legacy)) {
    raw <- read_csv(path_spawn_legacy, show_col_types = FALSE) |>
      janitor::clean_names() |>
      mutate(section = as.integer(section))

    coords <- raw |>
      filter(section %in% SECTIONS_KEEP, !is.na(latitude), !is.na(longitude)) |>
      group_by(section) |>
      summarise(
        lat = mean(latitude, na.rm = TRUE),
        lon = mean(longitude, na.rm = TRUE),
        .groups = "drop"
      )
  } else {
    stop("Must provide one of: spawn_coords, path_spawn_csv, or path_spawn_legacy")
  }

  # Fill missing sections from distance matrix xlsx if available
  missing_sections <- setdiff(SECTIONS_KEEP, coords$section)
  if (length(missing_sections) > 0 && !is.null(path_distance_xlsx) &&
      file.exists(path_distance_xlsx)) {
    xlsx_coords <- get_coords_from_distance_xlsx(path_distance_xlsx)
    fill_coords <- xlsx_coords |> filter(section %in% missing_sections)
    coords <- bind_rows(coords, fill_coords)
    missing_sections <- setdiff(SECTIONS_KEEP, coords$section)
  }

  if (length(missing_sections) > 0) {
    warning("No coordinates found for sections: ",
            paste(missing_sections, collapse = ", "),
            ". Using NA — these will produce NA distances.")
  }

  # Ensure ordering matches SECTIONS_KEEP
  coords <- tibble(section = SECTIONS_KEEP) |>
    left_join(coords, by = "section")

  # ---- Compute Haversine distance matrix ----
  D <- matrix(0, nrow = N_SITES, ncol = N_SITES)

  for (i in seq_len(N_SITES)) {
    for (j in seq_len(N_SITES)) {
      if (i != j) {
        D[i, j] <- haversine_km(
          coords$lat[i], coords$lon[i],
          coords$lat[j], coords$lon[j]
        )
      }
    }
  }

  rownames(D) <- SITE_NAMES
  colnames(D) <- SITE_NAMES

  # Enforce perfect symmetry (Haversine should be symmetric, but guard

  # against floating-point asymmetry)
  D <- (D + t(D)) / 2

  validate_distance_matrix(D)

  D
}


#' Haversine great-circle distance between two points (km).
#'
#' @param lat1,lon1 Latitude/longitude of point 1 (decimal degrees)
#' @param lat2,lon2 Latitude/longitude of point 2 (decimal degrees)
#' @return Distance in kilometres
#' @keywords internal
haversine_km <- function(lat1, lon1, lat2, lon2) {
  R <- 6371  # Earth radius in km

  to_rad <- pi / 180
  dlat <- (lat2 - lat1) * to_rad
  dlon <- (lon2 - lon1) * to_rad
  lat1_r <- lat1 * to_rad
  lat2_r <- lat2 * to_rad

  a <- sin(dlat / 2)^2 + cos(lat1_r) * cos(lat2_r) * sin(dlon / 2)^2
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))

  R * c
}


# ── Spatially-weighted predator index ───────────────────────────────────────

#' Build spatially-weighted predator indices for each herring section and year.
#'
#' For each herring spawning section j and year t, computes:
#'   predator_index[t, j] = Σ_k count[t, k] * exp(-d(j, k) / decay_km)
#' where k indexes predator haulout/complex sites and d(j, k) is the distance
#' from herring section j to predator site k.
#'
#' @param ssl_data Data frame of Steller sea lion counts with columns:
#'   REGION, SITE, LATITUDE, LONGITUDE, SURVEY.YEAR (or survey_year),
#'   COUNT.NON.PUP (or count_non_pup). Filtered internally to Haida Gwaii.
#' @param seal_data Data frame of harbour seal counts with columns:
#'   Region, Complex, Longitude, Latitude, Year, complex_count.
#'   Filtered internally to Haida Gwaii.
#' @param spawn_coords Data frame with columns section, lat, lon — centroid
#'   coordinates for each herring spawning section. Must include all
#'   SECTIONS_KEEP.
#' @param distance_decay_km Numeric, the spatial decay scale in km (default 50).
#'   Predator sites within decay_km contribute ~37% of their count; at 2×decay
#'   they contribute ~14%.
#' @param years Integer vector of years for the output matrix (default: YEARS).
#' @return Named list with components:
#'   - ssl_spatial: matrix (N_YEARS × N_SITES), spatially-weighted SSL index
#'   - seal_spatial: matrix (N_YEARS × N_SITES), spatially-weighted seal index
#'   - ssl_sites: tibble of unique SSL haulout locations used
#'   - seal_sites: tibble of unique seal complex locations used
#'   - decay_km: the decay parameter used
build_predator_spatial_index <- function(ssl_data,
                                         seal_data,
                                         spawn_coords,
                                         distance_decay_km = 50,
                                         years = YEARS) {

  stopifnot(
    "SECTIONS_KEEP not defined" = exists("SECTIONS_KEEP"),
    "SITE_NAMES not defined"    = exists("SITE_NAMES"),
    "N_SITES not defined"       = exists("N_SITES"),
    "spawn_coords must have section, lat, lon" =
      all(c("section", "lat", "lon") %in% names(spawn_coords)),
    "distance_decay_km must be positive" = distance_decay_km > 0
  )

  n_years <- length(years)

  # ---- Ensure spawn_coords ordered by SECTIONS_KEEP ----
  herring_coords <- tibble(section = SECTIONS_KEEP) |>
    left_join(spawn_coords, by = "section")

  stopifnot(
    "spawn_coords must cover all SECTIONS_KEEP" =
      all(SECTIONS_KEEP %in% herring_coords$section),
    "spawn_coords lat/lon must not be NA for SECTIONS_KEEP" =
      !any(is.na(herring_coords$lat) | is.na(herring_coords$lon))
  )

  # ---- Process SSL data ----
  ssl_clean <- ssl_data |>
    janitor::clean_names() |>
    filter(region == "Haida Gwaii") |>
    rename(
      year     = survey_year,
      lat_pred = latitude,
      lon_pred = longitude,
      count    = count_non_pup
    ) |>
    mutate(count = suppressWarnings(as.numeric(count)),
           count = replace_na(count, 0)) |>
    select(site, lat_pred, lon_pred, year, count)

  # Unique SSL site locations (use mean position in case of minor variation)
  ssl_sites <- ssl_clean |>
    group_by(site) |>
    summarise(
      lat_pred = mean(lat_pred, na.rm = TRUE),
      lon_pred = mean(lon_pred, na.rm = TRUE),
      .groups = "drop"
    )

  # ---- Process seal data ----
  seal_clean <- seal_data |>
    janitor::clean_names() |>
    filter(region == "Haida Gwaii") |>
    rename(
      lat_pred = latitude,
      lon_pred = longitude,
      count    = complex_count
    ) |>
    mutate(count = replace_na(count, 0)) |>
    select(complex, lat_pred, lon_pred, year, count)

  # Unique seal complex locations
  seal_sites <- seal_clean |>
    group_by(complex) |>
    summarise(
      lat_pred = mean(lat_pred, na.rm = TRUE),
      lon_pred = mean(lon_pred, na.rm = TRUE),
      .groups = "drop"
    )

  # ---- Compute distance weights: herring sections → predator sites ----
  # SSL weights: N_SITES × n_ssl_sites
  ssl_weights <- compute_spatial_weights(
    herring_coords$lat, herring_coords$lon,
    ssl_sites$lat_pred, ssl_sites$lon_pred,
    decay_km = distance_decay_km
  )

  # Seal weights: N_SITES × n_seal_sites
  seal_weights <- compute_spatial_weights(
    herring_coords$lat, herring_coords$lon,
    seal_sites$lat_pred, seal_sites$lon_pred,
    decay_km = distance_decay_km
  )

  # ---- Build year × site count matrices for predators ----
  # SSL: pivot to years × sites matrix
  ssl_count_mat <- build_predator_count_matrix(
    ssl_clean, ssl_sites, years, site_col = "site"
  )

  # Seal: pivot to years × sites matrix
  seal_count_mat <- build_predator_count_matrix(
    seal_clean, seal_sites, years, site_col = "complex"
  )

  # ---- Compute spatially-weighted index ----
  # ssl_spatial[t, j] = Σ_k ssl_count[t, k] * ssl_weights[j, k]
  ssl_spatial  <- ssl_count_mat  %*% t(ssl_weights)
  seal_spatial <- seal_count_mat %*% t(seal_weights)

  rownames(ssl_spatial)  <- years
  rownames(seal_spatial) <- years
  colnames(ssl_spatial)  <- SITE_NAMES
  colnames(seal_spatial) <- SITE_NAMES

  stopifnot(
    nrow(ssl_spatial)  == n_years,
    ncol(ssl_spatial)  == N_SITES,
    nrow(seal_spatial) == n_years,
    ncol(seal_spatial) == N_SITES
  )

  list(
    ssl_spatial  = ssl_spatial,
    seal_spatial = seal_spatial,
    ssl_sites    = ssl_sites,
    seal_sites   = seal_sites,
    decay_km     = distance_decay_km
  )
}


#' Compute exponential-decay spatial weight matrix.
#'
#' @param lat_from,lon_from Numeric vectors of "from" locations (herring sections)
#' @param lat_to,lon_to Numeric vectors of "to" locations (predator sites)
#' @param decay_km Decay scale parameter in km
#' @return Matrix (length(lat_from) × length(lat_to)) of weights in [0, 1]
#' @keywords internal
compute_spatial_weights <- function(lat_from, lon_from, lat_to, lon_to,
                                    decay_km) {
  n_from <- length(lat_from)
  n_to   <- length(lat_to)
  W <- matrix(0, nrow = n_from, ncol = n_to)

  for (i in seq_len(n_from)) {
    for (k in seq_len(n_to)) {
      d <- haversine_km(lat_from[i], lon_from[i], lat_to[k], lon_to[k])
      W[i, k] <- exp(-d / decay_km)
    }
  }

  W
}


#' Build a years × predator-sites count matrix from long-form predator data.
#'
#' @param pred_long Tibble with columns: site_col, year, count
#' @param pred_sites Tibble of unique sites with a site_col column
#' @param years Integer vector of years for the output
#' @param site_col Character, name of the site column (e.g. "site" or "complex")
#' @return Numeric matrix (n_years × n_pred_sites), zeros for missing year-site combos
#' @keywords internal
build_predator_count_matrix <- function(pred_long, pred_sites, years,
                                        site_col = "site") {

  n_years <- length(years)
  sites   <- pred_sites[[site_col]]
  n_sites <- length(sites)

  # Aggregate counts per year × site (sum if duplicates)
  agg <- pred_long |>
    group_by(.data[[site_col]], year) |>
    summarise(count = sum(count, na.rm = TRUE), .groups = "drop")

  # Build empty matrix
  mat <- matrix(0, nrow = n_years, ncol = n_sites)
  rownames(mat) <- years
  colnames(mat) <- sites

  # Fill in observed counts
  for (r in seq_len(nrow(agg))) {
    yr  <- agg$year[r]
    st  <- agg[[site_col]][r]
    yi  <- match(yr, years)
    si  <- match(st, sites)
    if (!is.na(yi) && !is.na(si)) {
      mat[yi, si] <- agg$count[r]
    }
  }

  mat
}


# ── Extract spawn section centroids ─────────────────────────────────────────

#' Extract centroid coordinates for each herring spawning section.
#'
#' Computes the mean Latitude/Longitude across all years for each section.
#' Can use either the DFO spawn CSV (has lat/lon) or the legacy CSV, or the
#' coordinates embedded in the distance matrix Excel file.
#'
#' @param path_spawn_csv Path to DFO spawn CSV with latitude/longitude columns
#' @param path_distance_xlsx Path to the distance matrix Excel file (optional
#'   fallback — uses the lookup table embedded in the sheet)
#' @return Tibble with columns: section (integer), section_name, lat, lon
get_spawn_centroids <- function(path_spawn_csv = NULL,
                                path_distance_xlsx = NULL) {

  stopifnot(
    "SECTIONS_KEEP not defined" = exists("SECTIONS_KEEP"),
    "SECTIONS_ALL not defined"  = exists("SECTIONS_ALL")
  )

  if (!is.null(path_spawn_csv) && file.exists(path_spawn_csv)) {
    # Primary: compute centroids from spawn survey lat/lon
    raw <- read_csv(path_spawn_csv, show_col_types = FALSE) |>
      janitor::clean_names() |>
      mutate(section = as.integer(section))

    coords <- raw |>
      filter(section %in% SECTIONS_KEEP, !is.na(latitude), !is.na(longitude)) |>
      group_by(section) |>
      summarise(
        lat = mean(latitude, na.rm = TRUE),
        lon = mean(longitude, na.rm = TRUE),
        .groups = "drop"
      )

    # Some sections may have no coords in the DFO data — try the distance
    # matrix xlsx for those
    missing <- setdiff(SECTIONS_KEEP, coords$section)

    if (length(missing) > 0 && !is.null(path_distance_xlsx)) {
      xlsx_coords <- get_coords_from_distance_xlsx(path_distance_xlsx)
      fill_coords <- xlsx_coords |> filter(section %in% missing)
      coords <- bind_rows(coords, fill_coords)
    }

  } else if (!is.null(path_distance_xlsx) && file.exists(path_distance_xlsx)) {
    # Fallback: use coordinates embedded in the distance matrix Excel file
    coords <- get_coords_from_distance_xlsx(path_distance_xlsx)
  } else {
    stop("Must provide at least one of path_spawn_csv or path_distance_xlsx")
  }

  # Join section names and enforce SECTIONS_KEEP order
  result <- SECTIONS_ALL |>
    filter(section %in% SECTIONS_KEEP) |>
    left_join(coords, by = "section") |>
    select(section, section_name, lat, lon)

  # Warn about any remaining missing coordinates
  if (any(is.na(result$lat))) {
    warning("Missing coordinates for sections: ",
            paste(result$section[is.na(result$lat)], collapse = ", "))
  }

  result
}


#' Extract section coordinates from the distance matrix Excel lookup table.
#'
#' The "Herring Effective" sheet has a lookup table starting at row 20
#' (0-indexed from the data portion) with columns: section_id, column_id,
#' name, latitude. Longitude is stored in the Id4 column at those rows.
#'
#' @param path_xlsx Path to distance matrix Excel file
#' @return Tibble with columns: section, lat, lon
#' @keywords internal
get_coords_from_distance_xlsx <- function(path_xlsx) {

  raw <- readxl::read_excel(path_xlsx, sheet = "Herring Effective")

  # Lookup table is in rows 20-32 (1-indexed), which is R rows 20:32
  # after the header. Column 1 = section_id, column 4 (Id4 in full sheet) = longitude
  # For latitude: it's in column 4 of the data (the "Id4" column name),

  # but actually the lookup table reuses the grid structure.
  # Row 19 (header): "Row", "Column", "Name", "Latitude" (in cols 1-4)
  # and "Longitude" is in col 5 (Id5 in original, but here stored as Id4)

  # Safer approach: look for the row with "Row" in column 1

  row_header_idx <- which(raw[[1]] == "Row")

  if (length(row_header_idx) == 0) {
    stop("Could not find lookup table header ('Row') in distance matrix xlsx")
  }

  # Data rows follow the header
  data_start <- row_header_idx + 1
  data_end   <- data_start + 12  # 13 sections

  section_ids <- as.integer(raw[[1]][data_start:data_end])
  # Latitude is in column 4 ("Id3" after readxl renaming, but it's the 4th col)
  # Longitude is in column 5 ("Id4")
  latitudes  <- as.numeric(raw[[4]][data_start:data_end])
  longitudes <- as.numeric(raw[[5]][data_start:data_end])

  coords <- tibble(
    section = section_ids,
    lat     = latitudes,
    lon     = longitudes
  ) |>
    filter(section %in% SECTIONS_KEEP)

  coords
}


# ── Validation ──────────────────────────────────────────────────────────────

#' Validate a distance matrix meets model requirements.
#'
#' Checks: square, symmetric, non-negative, zero diagonal, correct dimensions,
#' no NAs, row/col names match SITE_NAMES.
#'
#' @param D Numeric matrix to validate
#' @param check_names Logical, whether to check row/col names (default TRUE)
#' @return Invisible TRUE if all checks pass; stops with informative error
#'   otherwise
validate_distance_matrix <- function(D, check_names = TRUE) {

  stopifnot("D must be a matrix" = is.matrix(D))
  stopifnot("D must be numeric"  = is.numeric(D))

  # Square
  if (nrow(D) != ncol(D)) {
    stop("Distance matrix is not square: ", nrow(D), " rows × ", ncol(D), " cols")
  }

  # Correct dimensions
  if (nrow(D) != N_SITES) {
    stop("Distance matrix has ", nrow(D), " rows but N_SITES = ", N_SITES)
  }

  # No NAs
  if (any(is.na(D))) {
    n_na <- sum(is.na(D))
    stop("Distance matrix contains ", n_na, " NA values")
  }

  # Non-negative
  if (any(D < 0)) {
    stop("Distance matrix contains negative values")
  }

  # Zero diagonal
  if (any(diag(D) != 0)) {
    stop("Distance matrix diagonal is not zero: ",
         paste(round(diag(D), 4), collapse = ", "))
  }

  # Symmetric (within floating-point tolerance)
  max_asym <- max(abs(D - t(D)))
  if (max_asym > 1e-6) {
    stop("Distance matrix is not symmetric. Max asymmetry: ", max_asym)
  }

  # Row/column names
  if (check_names) {
    if (!is.null(rownames(D)) && !identical(rownames(D), SITE_NAMES)) {
      stop("Distance matrix row names do not match SITE_NAMES")
    }
    if (!is.null(colnames(D)) && !identical(colnames(D), SITE_NAMES)) {
      stop("Distance matrix column names do not match SITE_NAMES")
    }
  }

  invisible(TRUE)
}
