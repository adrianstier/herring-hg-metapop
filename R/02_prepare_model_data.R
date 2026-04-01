# ============================================================================
# 02_prepare_model_data.R — Assemble validated data list for Stan/JAGS
# stier-2027-herring-metapopulation
#
# Takes cleaned outputs from 01_data_cleaning.R and assembles the named
# list that gets passed directly to the model. All dimension and alignment
# checks happen here — if this function returns without error, the data
# are model-ready.
# ============================================================================

#' Assemble the complete data list for the herring metapopulation model.
#'
#' @param spawn     List returned by clean_spawn() — must contain $wide, $site_order
#' @param catch     List returned by clean_catch() — must contain $wide, $log_catch, $site_order
#' @param pdo       Named numeric vector returned by clean_pdo()
#' @param predators Tibble returned by clean_predators() (optional, default NULL)
#' @param format    Character, "stan" (default) or "jags" for legacy use.
#' @param spatial   Logical (default FALSE). If TRUE, appends spatial data:
#'   distance matrix, spatially-weighted predator indices.
#' @param distance_matrix Numeric matrix (N_SITES × N_SITES) of inter-section
#'   distances (km). Required when spatial = TRUE.
#' @param predator_spatial List returned by build_predator_spatial_index().
#'   Required when spatial = TRUE. Must contain $ssl_spatial and $seal_spatial.
#' @return Named list suitable for passing to Stan or JAGS:
#'   When format = "stan":
#'   - N_years, N_sites: integer dimensions
#'   - Y: log(SHI) matrix (N_years x N_sites), NAs replaced with 0
#'   - Y_obs: integer matrix (N_years x N_sites), 1 if observed, 0 if missing
#'   - pdo: numeric vector (length N_years)
#'   - q_idx: integer array (length N_years), 1=surface, 2=dive
#'   - N_catch: integer, number of (year,site) pairs with catch > 0
#'   - catch_row: integer array, year indices for positive catch
#'   - catch_col: integer array, site indices for positive catch
#'   - log_catch: numeric vector, log(catch+1) at positive-catch positions
#'   - N_zero: integer, number of (year,site) pairs with zero catch
#'   - zero_row: integer array, year indices for zero catch
#'   - zero_col: integer array, site indices for zero catch
#'   When spatial = TRUE (Stan only), additionally:
#'   - D: distance matrix (N_sites x N_sites), km
#'   - predator_ssl_spatial: matrix (N_years x N_sites), spatially-weighted SSL index
#'   - predator_seal_spatial: matrix (N_years x N_sites), spatially-weighted seal index
#'   When format = "jags" (legacy):
#'   - Y, nYears, nSites, pdo, ctab, INDEX, INDEX.zero, nIndex, nIndex.zero, q_idx
prepare_model_data <- function(spawn, catch, pdo, predators = NULL,
                               format = "stan",
                               spatial = FALSE,
                               distance_matrix = NULL,
                               predator_spatial = NULL) {

  stopifnot(format %in% c("stan", "jags"))

  # ── Validate inputs exist and have correct structure ──
  stopifnot(
    "spawn must be a list with $wide"       = is.list(spawn) && "wide" %in% names(spawn),
    "spawn must have $site_order"           = "site_order" %in% names(spawn),
    "catch must be a list with $wide"       = is.list(catch) && "wide" %in% names(catch),
    "catch must have $log_catch"            = "log_catch" %in% names(catch),
    "catch must have $site_order"           = "site_order" %in% names(catch),
    "pdo must be a numeric vector"          = is.numeric(pdo)
  )

  Y         <- spawn$wide
  log_catch <- catch$log_catch

  # ── Dimension checks ──
  stopifnot(
    "Spawn rows must equal N_YEARS"  = nrow(Y) == N_YEARS,
    "Spawn cols must equal N_SITES"  = ncol(Y) == N_SITES,
    "Catch rows must equal N_YEARS"  = nrow(log_catch) == N_YEARS,
    "Catch cols must equal N_SITES"  = ncol(log_catch) == N_SITES,
    "PDO length must equal N_YEARS"  = length(pdo) == N_YEARS
  )

  # ── Column alignment: spawn and catch must have same site order ──
  stopifnot(
    "Spawn and catch site order must match" =
      identical(spawn$site_order, catch$site_order),
    "Spawn column names must match catch column names" =
      identical(colnames(Y), colnames(log_catch))
  )

  # ── Year alignment: row names (if present) must match ──
  if (!is.null(rownames(Y)) && !is.null(rownames(log_catch))) {
    stopifnot(
      "Spawn and catch year labels must match" =
        identical(rownames(Y), rownames(log_catch))
    )
  }

  if (!is.null(names(pdo))) {
    stopifnot(
      "PDO year labels must match YEARS" =
        identical(as.integer(names(pdo)), YEARS)
    )
  }

  # ── Build catch index ──
  catch_idx <- build_catch_index(catch$wide)

  # ── Build survey method index ──
  q_idx <- build_survey_index()

  # ── Assemble the data list based on format ──

  if (format == "stan") {
    # Stan-compatible format matching herring_metapop_v1.stan data block

    # Observation indicator: 1 = observed, 0 = missing/NA
    Y_obs <- matrix(as.integer(!is.na(Y)), nrow = N_YEARS, ncol = N_SITES)

    # Replace NAs with 0 for Stan (not used in likelihood when Y_obs == 0)
    Y_clean <- Y
    Y_clean[is.na(Y_clean)] <- 0.0

    # Catch indexing: (year, site) pairs where catch > 0
    catch_positive <- which(log_catch > 0, arr.ind = TRUE)
    catch_zero     <- which(log_catch == 0, arr.ind = TRUE)

    model_data <- list(
      N_years   = N_YEARS,
      N_sites   = N_SITES,
      Y         = Y_clean,
      Y_obs     = Y_obs,
      pdo       = as.numeric(pdo),
      q_idx     = as.array(q_idx),
      N_catch   = nrow(catch_positive),
      catch_row = as.array(catch_positive[, 1]),
      catch_col = as.array(catch_positive[, 2]),
      log_catch = log_catch[catch_positive],
      N_zero    = nrow(catch_zero),
      zero_row  = as.array(catch_zero[, 1]),
      zero_col  = as.array(catch_zero[, 2])
    )
  } else {
    # Legacy JAGS naming convention
    model_data <- list(
      Y            = Y,
      nYears       = N_YEARS,
      nSites       = N_SITES,
      pdo          = as.numeric(pdo),
      ctab         = log_catch,
      INDEX        = as.matrix(catch_idx$INDEX),
      INDEX.zero   = as.matrix(catch_idx$INDEX_zero),
      nIndex       = catch_idx$n_index,
      nIndex.zero  = catch_idx$n_index_zero,
      q_idx        = q_idx
    )
  }

  # ── Optional: append predator data ──
  if (!is.null(predators)) {
    stopifnot(
      "predators must be a tibble/data.frame" = is.data.frame(predators),
      "predators must have 'year' column"     = "year" %in% names(predators),
      "predators must cover N_YEARS rows"     = nrow(predators) == N_YEARS
    )
    model_data$predators <- predators
  }

  # ── Optional: append spatial data (distance matrix + predator indices) ──
  if (spatial && format == "stan") {
    if (is.null(distance_matrix)) {
      stop("spatial = TRUE requires a distance_matrix argument")
    }
    if (is.null(predator_spatial)) {
      stop("spatial = TRUE requires a predator_spatial argument ",
           "(from build_predator_spatial_index())")
    }

    # Validate distance matrix
    stopifnot(
      "distance_matrix must be a matrix"       = is.matrix(distance_matrix),
      "distance_matrix must be N_SITES x N_SITES" =
        nrow(distance_matrix) == N_SITES && ncol(distance_matrix) == N_SITES
    )

    # Validate predator spatial indices
    stopifnot(
      "predator_spatial must be a list"            = is.list(predator_spatial),
      "predator_spatial must contain ssl_spatial"   = "ssl_spatial" %in% names(predator_spatial),
      "predator_spatial must contain seal_spatial"  = "seal_spatial" %in% names(predator_spatial),
      "ssl_spatial must be N_YEARS x N_SITES"      =
        nrow(predator_spatial$ssl_spatial) == N_YEARS &&
        ncol(predator_spatial$ssl_spatial) == N_SITES,
      "seal_spatial must be N_YEARS x N_SITES"     =
        nrow(predator_spatial$seal_spatial) == N_YEARS &&
        ncol(predator_spatial$seal_spatial) == N_SITES
    )

    model_data$D                    <- distance_matrix
    model_data$predator_ssl_spatial  <- predator_spatial$ssl_spatial
    model_data$predator_seal_spatial <- predator_spatial$seal_spatial
  }

  # ── Final sanity checks ──
  if (format == "stan") {
    stopifnot(
      "N_catch + N_zero must equal N_years * N_sites" =
        (model_data$N_catch + model_data$N_zero) == (N_YEARS * N_SITES),
      "q_idx length must equal N_years" =
        length(model_data$q_idx) == model_data$N_years
    )
  } else {
    stopifnot(
      "INDEX rows + INDEX.zero rows must equal N_YEARS * N_SITES" =
        (model_data$nIndex + model_data$nIndex.zero) == (N_YEARS * N_SITES),
      "q_idx length must equal nYears" =
        length(model_data$q_idx) == model_data$nYears
    )
  }

  model_data
}
