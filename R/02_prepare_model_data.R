# ============================================================================
# 02_prepare_model_data.R — Assemble validated data list for Stan/JAGS
# stier-2027-herring-metapopulation
#
# Takes cleaned outputs from 01_data_cleaning.R and assembles the named
# list that gets passed directly to the model. All dimension and alignment
# checks happen here — if this function returns without error, the data
# are model-ready.
# ============================================================================

# Reader note:
# This is the main theory-to-data contract file in the maintained pipeline.
# It creates one canonical analysis object with fixed dimensions and optional
# predator/spatial covariates; `R/03_fit_model.R` then trims that richer
# object down to the exact data block required by each Stan model version.

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
#' @return Named list suitable for passing to Stan or JAGS.
#'   For `format = "stan"`, the list always includes the canonical biomass
#'   model contract: `N_years`, `N_sites`, `Y`, `Y_obs`, `Y_censored`,
#'   `Y_missing`, `pdo`, `q_idx`, `N_catch`, `catch_row`, `catch_col`,
#'   `log_catch`, `N_zero`, `zero_row`, `zero_col`, and `prior_only`.
#'   If `predators` is supplied, the Stan list also includes the original
#'   annual predator tibble plus standardized predator covariates
#'   (`whale`, `ssl_region`, `seal_region`) and their observation masks
#'   (`whale_obs`, `pred_obs`).
#'   If `spatial = TRUE`, the Stan list also includes `dist_mat`, `max_dist`,
#'   standardized site-level predator matrices (`ssl_spatial`, `seal_spatial`),
#'   and backward-compatible aliases (`D`, `predator_ssl_spatial`,
#'   `predator_seal_spatial`).
#'   For `format = "jags"`, the list uses the legacy names expected by the
#'   historical scripts: `Y`, `nYears`, `nSites`, `pdo`, `ctab`, `INDEX`,
#'   `INDEX.zero`, `nIndex`, `nIndex.zero`, and `q_idx`.
prepare_model_data <- function(spawn, catch, pdo, predators = NULL,
                               format = "stan",
                               spatial = FALSE,
                               distance_matrix = NULL,
                               predator_spatial = NULL) {

  standardize_series <- function(x) {
    x <- as.numeric(x)
    out <- rep(0, length(x))
    keep <- !is.na(x)

    if (!any(keep)) {
      return(out)
    }

    center <- mean(x[keep])
    spread <- stats::sd(x[keep])

    if (is.na(spread) || spread == 0) {
      out[keep] <- x[keep] - center
    } else {
      out[keep] <- (x[keep] - center) / spread
    }

    out
  }

  standardize_matrix_cols <- function(mat) {
    mat <- as.matrix(mat)
    out <- matrix(
      0.0,
      nrow = nrow(mat),
      ncol = ncol(mat),
      dimnames = dimnames(mat)
    )

    for (j in seq_len(ncol(mat))) {
      out[, j] <- standardize_series(mat[, j])
    }

    out
  }

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

  # ── Build survey-state matrices ──
  if ("long" %in% names(spawn) && "survey_status" %in% names(spawn$long)) {
    status_wide <- spawn$long |>
      select(year, section_name, survey_status) |>
      pivot_wider(names_from = section_name, values_from = survey_status) |>
      arrange(year)

    status_mat <- status_wide |>
      select(all_of(SITE_NAMES)) |>
      as.matrix()

    Y_obs <- array(as.integer(status_mat == "positive"), dim = c(N_YEARS, N_SITES))
    Y_censored <- array(as.integer(status_mat == "censored_zero"), dim = c(N_YEARS, N_SITES))
    Y_missing <- array(as.integer(status_mat == "missing"), dim = c(N_YEARS, N_SITES))
  } else {
    # Backward-compatible fallback for older spawn objects.
    Y_obs <- array(as.integer(!is.na(Y)), dim = c(N_YEARS, N_SITES))
    Y_censored <- array(0L, dim = c(N_YEARS, N_SITES))
    Y_missing <- array(as.integer(is.na(Y)), dim = c(N_YEARS, N_SITES))
  }

  stopifnot(
    "Survey states must be exhaustive" =
      all((Y_obs + Y_censored + Y_missing) == 1L),
    "Positive observations must match non-missing log-SHI cells" =
      identical(Y_obs, array(as.integer(!is.na(Y)), dim = c(N_YEARS, N_SITES)))
  )

  # Replace NAs with 0 for Stan/JAGS storage. Likelihoods use the flags.
  Y_clean <- Y
  Y_clean[is.na(Y_clean)] <- 0.0

  # ── Assemble the data list based on format ──

  if (format == "stan") {
    # Stan-compatible format matching herring_metapop_v1.stan data block

    # Catch indexing: (year, site) pairs where catch > 0
    catch_positive <- which(log_catch > 0, arr.ind = TRUE)
    catch_zero     <- which(log_catch == 0, arr.ind = TRUE)

    model_data <- list(
      N_years   = N_YEARS,
      N_sites   = N_SITES,
      Y         = Y_clean,
      Y_obs     = Y_obs,
      Y_censored = Y_censored,
      Y_missing = Y_missing,
      Y_obs_flag = Y_obs,
      Y_censored_flag = Y_censored,
      Y_missing_flag = Y_missing,
      pdo       = as.numeric(pdo),
      q_idx     = as.array(q_idx),
      N_catch   = nrow(catch_positive),
      catch_row = as.array(catch_positive[, 1]),
      catch_col = as.array(catch_positive[, 2]),
      log_catch = log_catch[catch_positive],
      N_zero    = nrow(catch_zero),
      zero_row  = as.array(catch_zero[, 1]),
      zero_col  = as.array(catch_zero[, 2]),
      prior_only = 0L
    )
  } else {
    # Legacy JAGS naming convention
    model_data <- list(
      Y            = Y,
      Y_clean      = Y_clean,
      Y_obs        = Y_obs,
      Y_censored   = Y_censored,
      Y_missing    = Y_missing,
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
    predators <- predators |>
      arrange(year)

    stopifnot(
      "predators must be a tibble/data.frame" = is.data.frame(predators),
      "predators must have 'year' column"     = "year" %in% names(predators),
      "predators must cover N_YEARS rows"     = nrow(predators) == N_YEARS,
      "predators must align to YEARS"         =
        identical(as.integer(predators$year), as.integer(YEARS))
    )
    model_data$predators <- predators

    if (format == "stan") {
      model_data$whale <- standardize_series(predators$whale_abundance)
      model_data$ssl_region <- standardize_series(predators$ssl_count)
      model_data$seal_region <- standardize_series(predators$seal_count)
      model_data$whale_obs <- as.array(as.integer(
        !is.na(predators$whale_abundance) & predators$whale_abundance != 0
      ))
      model_data$pred_obs <- as.array(as.integer(
        (!is.na(predators$ssl_count) & predators$ssl_count != 0) |
          (!is.na(predators$seal_count) & predators$seal_count != 0)
      ))
    }
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

    ssl_raw  <- as.matrix(predator_spatial$ssl_spatial)
    seal_raw <- as.matrix(predator_spatial$seal_spatial)

    model_data$dist_mat <- distance_matrix
    model_data$max_dist <- max(distance_matrix)
    model_data$ssl_spatial <- standardize_matrix_cols(ssl_raw)
    model_data$seal_spatial <- standardize_matrix_cols(seal_raw)
    model_data$pred_obs <- as.array(as.integer(
      apply(ssl_raw, 1, function(x) any(!is.na(x) & x != 0)) |
        apply(seal_raw, 1, function(x) any(!is.na(x) & x != 0))
    ))

    # Backward-compatible aliases for older scripts.
    model_data$D <- model_data$dist_mat
    model_data$predator_ssl_spatial <- model_data$ssl_spatial
    model_data$predator_seal_spatial <- model_data$seal_spatial
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
