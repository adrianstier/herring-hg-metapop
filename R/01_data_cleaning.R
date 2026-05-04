# ============================================================================
# 01_data_cleaning.R — Data cleaning functions
# stier-2027-herring-metapopulation
#
# Pure functions for reading, cleaning, and harmonizing raw data.
# Each function takes file paths as arguments and returns tidy outputs.
# Source 00_setup.R before calling any of these.
# ============================================================================

# Reader note:
# This file is where raw observations become analysis-ready objects with
# explicit semantics. The most important decisions here are how zeros,
# missing effort, annual aggregation, and site alignment are represented
# before anything reaches a model.

# ── Spawn index ──────────────────────────────────────────────────────────────

#' Read legacy and new DFO spawn survey data, merge, filter, and pivot wide.
#'
#' @param path_legacy Path to legacy CSV (HG_Spawn_Survey_1940_2015.csv)
#' @param path_new    Path to newer DFO section-year CSV. Prefer the processed
#'   `HG_Spawn_Survey_1951_2025_all_sections.csv` used by the model fits;
#'   the older raw aggregate schema is also accepted.
#' @return List with components:
#'   - wide:    matrix (N_YEARS x N_SITES) of log positive SHI; zeros and
#'              missing cells are NA because the log transform is undefined
#'   - long:    tibble with survey-state columns. Surveyed zeros keep
#'              spawn_index == 0 and survey_status == "censored_zero".
#'   - site_order: character vector of section_name column order
clean_spawn <- function(path_legacy, path_new) {

  # ---- Read legacy data (1940-2015, all 13 sections) ----
  legacy <- read_csv(path_legacy, show_col_types = FALSE) |>
    clean_names() |>
    rename(spawn_index = shi) |>
    select(year, section, section_name, totalrecords, spawn_index) |>
    mutate(section = as.integer(section))

  # ---- Read new DFO data (1951-2025, subset of sections) ----
  # New DFO uses zero-padded section numbers (e.g., "006") and may have
  # different section_name labels (e.g., section 2 = "Englefield Bay" in
  # 2025 vs "Port Louis" in legacy). Join on section number (integer),
  # NOT on section_name, to avoid merge failures from renamed sections.
  new_dfo <- read_csv(path_new, show_col_types = FALSE) |>
    clean_names()

  if ("spawn_index_tonnes" %in% names(new_dfo)) {
    new_dfo <- new_dfo |>
      rename(spawn_index = spawn_index_tonnes)
  } else if ("spawn_index_t" %in% names(new_dfo)) {
    new_dfo <- new_dfo |>
      rename(spawn_index = spawn_index_t)
  } else if (!"spawn_index" %in% names(new_dfo)) {
    stop("New DFO spawn file must contain spawn_index_tonnes, spawn_index_t, or spawn_index.")
  }

  if ("total_records" %in% names(new_dfo)) {
    new_dfo <- new_dfo |>
      rename(totalrecords = total_records)
  } else if (!"totalrecords" %in% names(new_dfo)) {
    stop("New DFO spawn file must contain totalrecords or total_records.")
  }

  new_dfo <- new_dfo |>
    mutate(section = as.integer(section)) |>
    select(year, section, totalrecords, spawn_index)

  # ---- Validate: section numbers in new DFO must exist in SECTIONS_ALL ----
  unknown_sections <- setdiff(unique(new_dfo$section), SECTIONS_ALL$section)
  if (length(unknown_sections) > 0) {
    warning("New DFO data contains section numbers not in SECTIONS_ALL: ",
            paste(unknown_sections, collapse = ", "),
            ". These rows will be dropped.")
    new_dfo <- new_dfo |> filter(section %in% SECTIONS_ALL$section)
  }

  # ---- Merge: prefer the newer DFO section-year file on overlap ----
  # Join on section number (integer) to handle renamed sections.
  # The current model inputs are built from the DFO 1951-2025 tonnes file for
  # the full period, so the maintained R path should use the same precedence.
  legacy_extra <- legacy |>
    anti_join(new_dfo, by = c("year", "section"))

  # Apply canonical section_name from SECTIONS_ALL after joining.
  combined <- bind_rows(
      new_dfo,
      legacy_extra |> select(year, section, totalrecords, spawn_index)
    ) |>
    left_join(SECTIONS_ALL |> select(section, section_name), by = "section") |>
    arrange(year, section)

  # ---- Filter to SECTIONS_KEEP and YEAR_START:YEAR_END ----
  stopifnot(
    "SECTIONS_KEEP not defined — source 00_setup.R first" = exists("SECTIONS_KEEP"),
    "YEAR_START not defined — source 00_setup.R first"    = exists("YEAR_START"),
    "YEAR_END not defined — source 00_setup.R first"      = exists("YEAR_END")
  )

  filtered <- combined |>
    filter(
      section %in% SECTIONS_KEEP,
      year >= YEAR_START,
      year <= YEAR_END
    )

  # ---- Ensure every year x section combination exists ----
  complete_grid <- expand_grid(
    year         = seq(YEAR_START, YEAR_END),
    section      = SECTIONS_KEEP
  )

  # Build section name lookup from the data
  section_lookup <- SECTIONS_ALL |>
    filter(section %in% SECTIONS_KEEP) |>
    select(section, section_name)

  filtered <- complete_grid |>
    left_join(section_lookup, by = "section") |>
    left_join(
      filtered |> select(year, section, totalrecords, spawn_index),
      by = c("year", "section")
    )

  # ---- Build long tibble ----
  long <- filtered |>
    mutate(
      totalrecords = replace_na(totalrecords, 0),
      spawn_index = replace_na(spawn_index, 0),
      surveyed = totalrecords > 0,
      positive_spawn = spawn_index > 0,
      survey_status = case_when(
        positive_spawn ~ "positive",
        surveyed ~ "censored_zero",
        TRUE ~ "missing"
      ),
      log_shi = if_else(positive_spawn, log(spawn_index), NA_real_)
    ) |>
    arrange(year, section)

  # ---- Pivot to wide matrix ----
  # Column order follows SECTIONS_KEEP order (which matches SITE_NAMES)
  wide_tbl <- long |>
    select(year, section_name, log_shi) |>
    pivot_wider(
      names_from  = section_name,
      values_from = log_shi
    ) |>
    arrange(year)

  # Enforce column order to match SITE_NAMES
  stopifnot(all(SITE_NAMES %in% names(wide_tbl)))
  wide_mat <- wide_tbl |>
    select(all_of(SITE_NAMES)) |>
    as.matrix()

  rownames(wide_mat) <- wide_tbl$year

  stopifnot(
    "Wide matrix row count must equal N_YEARS" = nrow(wide_mat) == N_YEARS,
    "Wide matrix col count must equal N_SITES" = ncol(wide_mat) == N_SITES
  )

  list(
    wide       = wide_mat,
    long       = long,
    site_order = SITE_NAMES
  )
}


# ── Catch ────────────────────────────────────────────────────────────────────

#' Read legacy and new catch data, merge, filter, and align to spawn site order.
#'
#' @param path_legacy Path to legacy catch CSV (herring_catch_local2015.csv)
#' @param path_new    Path to new catch CSV (herring_catch_local2024.csv)
#' @return List with components:
#'   - wide:       matrix (N_YEARS x N_SITES) of spring catch (CatchJan_Apr)
#'   - log_catch:  matrix of log(catch + 1)
#'   - long:       tibble with columns year, section, section_name, catch_spring,
#'                 catch_observed (TRUE = original data was not NA; FALSE = was NA,
#'                 zero-filled for the matrix)
#'   - site_order: character vector of section_name column order
clean_catch <- function(path_legacy, path_new) {

  read_catch <- function(path) {
    read_csv(path, show_col_types = FALSE) |>
      clean_names() |>
      rename(
        section      = section,
        section_name = name,
        catch_spring = catch_jan_apr
      ) |>
      select(year, section, section_name, catch_spring) |>
      # Track whether catch was actually observed vs. missing (NA).
      # The model needs numeric values so we fill NA with 0, but
      # catch_observed lets downstream code (e.g., build_catch_index)
      # distinguish true zeros ("fished, caught nothing") from
      # missing data ("no fishing occurred").
      mutate(
        catch_observed = !is.na(catch_spring),
        catch_spring   = replace_na(catch_spring, 0)
      )
  }

  legacy <- read_catch(path_legacy)
  new    <- read_catch(path_new)

  # Ensure section is integer for consistent joining
  legacy <- legacy |>
    mutate(section = as.integer(section)) |>
    filter(!is.na(section_name), section_name != "NA")
  new <- new |>
    mutate(section = as.integer(section)) |>
    filter(!is.na(section_name), section_name != "NA")

  # ---- Merge: anti-join on section number (integer), not section_name ----
  # DFO may change section_name labels across data releases (same issue as spawn).
  new_rows <- new |>
    anti_join(legacy, by = c("year", "section"))

  # Apply canonical section_name from SECTIONS_ALL after joining
  combined <- bind_rows(
      legacy |> select(year, section, catch_spring, catch_observed),
      new_rows |> select(year, section, catch_spring, catch_observed)
    ) |>
    left_join(SECTIONS_ALL |> select(section, section_name), by = "section") |>
    arrange(year, section)

  # ---- Filter to SECTIONS_KEEP and YEAR_START:YEAR_END ----
  filtered <- combined |>
    filter(
      section %in% SECTIONS_KEEP,
      year >= YEAR_START,
      year <= YEAR_END
    )

  # ---- Ensure every year x section combination exists ----
  section_lookup <- SECTIONS_ALL |>
    filter(section %in% SECTIONS_KEEP) |>
    select(section, section_name)

  complete_grid <- expand_grid(
    year    = seq(YEAR_START, YEAR_END),
    section = SECTIONS_KEEP
  )

  long <- complete_grid |>
    left_join(section_lookup, by = "section") |>
    left_join(
      filtered |> select(year, section, catch_spring, catch_observed),
      by = c("year", "section")
    ) |>
    # Grid-expanded rows (year x section combos not in the original data)
    # are truly missing — mark as unobserved, fill with zero for the matrix.
    mutate(
      catch_observed = replace_na(catch_observed, FALSE),
      catch_spring   = replace_na(catch_spring, 0)
    ) |>
    arrange(year, section)

  # ---- Sum catch by year x section (in case of duplicate rows) ----
  long <- long |>
    group_by(year, section, section_name) |>
    summarise(
      catch_spring   = sum(catch_spring, na.rm = TRUE),
      # If any row in the group was observed, the aggregate is observed
      catch_observed = any(catch_observed),
      .groups = "drop"
    ) |>
    arrange(year, section)

  # ---- Pivot to wide matrix, aligned to SITE_NAMES by name ----
  wide_tbl <- long |>
    select(year, section_name, catch_spring) |>
    pivot_wider(
      names_from  = section_name,
      values_from = catch_spring
    ) |>
    arrange(year)

  stopifnot(all(SITE_NAMES %in% names(wide_tbl)))

  wide_mat <- wide_tbl |>
    select(all_of(SITE_NAMES)) |>
    as.matrix()

  rownames(wide_mat) <- wide_tbl$year

  log_catch <- log(wide_mat + 1)

  stopifnot(
    "Catch matrix row count must equal N_YEARS" = nrow(wide_mat) == N_YEARS,
    "Catch matrix col count must equal N_SITES" = ncol(wide_mat) == N_SITES,
    "Catch columns must match spawn site order"  =
      identical(colnames(wide_mat), SITE_NAMES)
  )

  list(
    wide       = wide_mat,
    log_catch  = log_catch,
    long       = long,
    site_order = SITE_NAMES
  )
}


# ── PDO ──────────────────────────────────────────────────────────────────────

#' Read legacy and extension PDO data, merge, compute spring average.
#'
#' @param path_legacy    Path to legacy PDO CSV (pdo.csv)
#' @param path_extension Path to extension PDO CSV (pdo_2015_2025.csv)
#' @return Named numeric vector of spring (Mar-Jun) PDO by year,
#'         covering YEAR_START:YEAR_END
clean_pdo <- function(path_legacy, path_extension) {

  legacy <- read_csv(path_legacy, show_col_types = FALSE) |>
    clean_names()

  extension <- read_csv(path_extension, show_col_types = FALSE) |>
    clean_names()

  # Columns should be: value, year, month
  stopifnot(
    all(c("value", "year", "month") %in% names(legacy)),
    all(c("value", "year", "month") %in% names(extension))
  )

  # ---- Merge: prefer legacy for overlapping year-months ----
  new_rows <- extension |>
    anti_join(legacy, by = c("year", "month"))

  combined <- bind_rows(legacy, new_rows) |>
    arrange(year, month)

  # ---- Compute spring average (PDO_MONTHS = March-June) ----
  spring_pdo <- combined |>
    filter(month %in% PDO_MONTHS) |>
    group_by(year) |>
    summarise(pdo_spring = mean(value, na.rm = TRUE), .groups = "drop") |>
    filter(year >= YEAR_START, year <= YEAR_END) |>
    arrange(year)

  # Coerce both sides to integer for comparison — read_csv may parse year

  # as integer or double depending on column contents, so identical() can
  # fail on type mismatch even when values are the same.
  stopifnot(
    "PDO must cover all years" = nrow(spring_pdo) == N_YEARS,
    "PDO years must match YEARS" =
      identical(as.integer(spring_pdo$year), as.integer(YEARS))
  )

  pdo_vec <- spring_pdo$pdo_spring
  names(pdo_vec) <- spring_pdo$year

  pdo_vec
}


# ── SST ──────────────────────────────────────────────────────────────────────

#' Read OISST data and compute spring average for the Haida Gwaii region.
#'
#' @param path Path to OISST monthly CSV (or vector of paths to bind)
#' @return Tibble with columns year, sst_spring, anom_spring
#' @details OISST data has a units row (row 2) that must be skipped.
#'   Spring = months 3-6 (same as PDO_MONTHS). Returns only years with
#'   complete spring data.
clean_sst <- function(path) {

  paths <- as.character(path)

  read_sst_file <- function(p) {
    raw <- read_csv(p, show_col_types = FALSE) |>
      clean_names()

    # Current checked-in monthly files are already aggregated and expose
    # year/month/sst_mean/anom_mean directly.
    if (all(c("year", "month", "sst_mean", "anom_mean") %in% names(raw))) {
      return(
        raw |>
          transmute(
            year  = as.integer(year),
            month = as.integer(month),
            sst   = as.numeric(sst_mean),
            anom  = as.numeric(anom_mean)
          )
      )
    }

    # Older ERDDAP exports include a units row below the header and raw
    # per-cell SST/anomaly columns.
    raw <- read_csv(p, show_col_types = FALSE, skip = 1)

    if (ncol(raw) < 6) {
      cli::cli_abort(
        "SST file {.file {p}} does not match a supported schema."
      )
    }

    raw <- raw |>
      set_names(c("time", "zlev", "latitude", "longitude", "sst", "anom"))

    first_time <- raw$time[1]
    if (!is.na(first_time) && is.na(suppressWarnings(as.Date(first_time)))) {
      cli::cli_abort(c(
        "First row of {p} does not look like a date: {.val {first_time}}.",
        "i" = "The OISST units row may not have been skipped correctly."
      ))
    }

    raw |>
      transmute(
        year  = year(as.Date(time)),
        month = month(as.Date(time)),
        sst   = as.numeric(sst),
        anom  = as.numeric(anom)
      )
  }

  raw <- map_dfr(paths, read_sst_file)

  sst <- raw |>
    filter(month %in% PDO_MONTHS) |>
    group_by(year, month) |>
    summarise(
      sst_mean  = mean(sst, na.rm = TRUE),
      anom_mean = mean(anom, na.rm = TRUE),
      .groups = "drop"
    ) |>
    group_by(year) |>
    summarise(
      sst_spring  = mean(sst_mean, na.rm = TRUE),
      anom_spring = mean(anom_mean, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(year)

  sst
}


# ── Predators ────────────────────────────────────────────────────────────────

#' Read predator survey data (SSL, harbour seal, humpback whale),
#' filter to Haida Gwaii region, return annual indices.
#'
#' @param path_ssl   Path to Steller sea lion CSV
#' @param path_seal  Path to harbour seal CSV
#' @param path_whale Path to humpback whale CSV
#' @return Tibble with columns year and annual abundance indices for each
#'         predator group. Only years within YEAR_START:YEAR_END are included.
clean_predators <- function(path_ssl, path_seal, path_whale) {

  # ---- Steller sea lions (filter to Haida Gwaii) ----
  ssl_raw <- read_csv(path_ssl, show_col_types = FALSE) |>
    clean_names()

  # Validate that the expected region column contains "Haida Gwaii"
  if (!"region" %in% names(ssl_raw) ||
      !any(ssl_raw$region == "Haida Gwaii", na.rm = TRUE)) {
    warning(
      "SSL data has no rows with region == 'Haida Gwaii'. ",
      "Available regions: ",
      paste(unique(ssl_raw$region), collapse = ", "),
      call. = FALSE
    )
  }

  ssl <- ssl_raw |>
    filter(region == "Haida Gwaii") |>
    mutate(
      year          = as.integer(survey_year),
      count_non_pup = suppressWarnings(as.numeric(count_non_pup))
    ) |>
    group_by(year) |>
    summarise(
      ssl_count = sum(count_non_pup, na.rm = TRUE),
      .groups   = "drop"
    )

  # ---- Harbour seals (filter to Haida Gwaii) ----
  # This file may have non-UTF8 characters
  seal_raw <- read_csv(path_seal, show_col_types = FALSE,
                       locale = locale(encoding = "latin1")) |>
    clean_names()

  # Validate that the expected region column contains "Haida Gwaii"
  if (!"region" %in% names(seal_raw) ||
      !any(seal_raw$region == "Haida Gwaii", na.rm = TRUE)) {
    warning(
      "Seal data has no rows with region == 'Haida Gwaii'. ",
      "Available regions: ",
      paste(unique(seal_raw$region), collapse = ", "),
      call. = FALSE
    )
  }

  seal <- seal_raw |>
    filter(region == "Haida Gwaii") |>
    mutate(
      year          = as.integer(year),
      complex_count = suppressWarnings(as.numeric(complex_count))
    ) |>
    group_by(year) |>
    summarise(
      seal_count = sum(complex_count, na.rm = TRUE),
      .groups    = "drop"
    )

  # ---- Humpback whales (North Pacific — not spatially filtered) ----
  whale <- read_csv(path_whale, show_col_types = FALSE) |>
    clean_names() |>
    select(year, abundance) |>
    mutate(
      year      = as.integer(year),
      abundance = suppressWarnings(as.numeric(abundance))
    ) |>
    rename(whale_abundance = abundance)

  # ---- Combine into single tibble ----
  year_grid <- tibble(year = seq(YEAR_START, YEAR_END))

  predators <- year_grid |>
    left_join(ssl,   by = "year") |>
    left_join(seal,  by = "year") |>
    left_join(whale, by = "year") |>
    arrange(year)

  predators
}


# ── Catch index (design matrix) ──────────────────────────────────────────────

#' Build INDEX and INDEX.zero matrices for the state-space model.
#'
#' The model estimates catch rates only where catch was reported (>0).
#' INDEX identifies (row, col) positions where log(catch) > 0.
#' INDEX.zero identifies (row, col) positions where catch == 0.
#'
#' @param catch_matrix Numeric matrix of raw catch (not log-transformed).
#'   Rows = years, columns = sites.
#' @return List with components:
#'   - INDEX:       tibble with columns row, col (catch > 0)
#'   - INDEX_zero:  tibble with columns row, col (catch == 0)
#'   - n_index:     integer, nrow(INDEX)
#'   - n_index_zero: integer, nrow(INDEX_zero)
#'   - catch_dummy: binary matrix (1 where catch > 0, 0 otherwise)
build_catch_index <- function(catch_matrix) {

  stopifnot(is.matrix(catch_matrix), is.numeric(catch_matrix))

  log_catch <- log(catch_matrix + 1)

  # Vectorized: find all (row, col) positions
  pos_idx  <- which(log_catch > 0, arr.ind = TRUE)
  zero_idx <- which(log_catch == 0, arr.ind = TRUE)

  INDEX <- tibble(
    row = as.integer(pos_idx[, "row"]),
    col = as.integer(pos_idx[, "col"])
  ) |> arrange(row, col)

  INDEX_zero <- tibble(
    row = as.integer(zero_idx[, "row"]),
    col = as.integer(zero_idx[, "col"])
  ) |> arrange(row, col)

  catch_dummy <- ifelse(log_catch > 0, 1L, 0L)

  list(
    INDEX       = INDEX,
    INDEX_zero  = INDEX_zero,
    n_index      = nrow(INDEX),
    n_index_zero = nrow(INDEX_zero),
    catch_dummy  = catch_dummy
  )
}


# ── Survey method index ──────────────────────────────────────────────────────

#' Build the q_idx vector that indexes survey method.
#'
#' Surface surveys (q=1): YEAR_START to SURVEY_MIXED_START_YEAR - 1
#' Mixed transition (q=2): SURVEY_MIXED_START_YEAR to SURVEY_DIVE_START_YEAR - 1
#' SCUBA/dive surveys (q=3): SURVEY_DIVE_START_YEAR to YEAR_END
#'
#' @param years Integer vector of years (default: YEARS from 00_setup.R)
#' @return Integer vector of length N_YEARS, values 1, 2, or 3
build_survey_index <- function(years = YEARS) {
  stopifnot(
    "SURVEY_MIXED_START_YEAR not defined" = exists("SURVEY_MIXED_START_YEAR"),
    "SURVEY_DIVE_START_YEAR not defined" = exists("SURVEY_DIVE_START_YEAR")
  )

  q_idx <- case_when(
    years < SURVEY_MIXED_START_YEAR ~ 1L,
    years < SURVEY_DIVE_START_YEAR ~ 2L,
    TRUE ~ 3L
  )

  stopifnot(
    "q_idx length must match N_YEARS" = length(q_idx) == length(years),
    "q_idx must be 1, 2, or 3"       = all(q_idx %in% c(1L, 2L, 3L))
  )

  q_idx
}
