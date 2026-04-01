# ============================================================================
# 03_fit_model.R — Compile, fit, diagnose, and extract Stan models
# stier-2027-herring-metapopulation
#
# Uses cmdstanr for Stan interface. All functions return tidy outputs
# compatible with tidybayes and the loo package.
#
# Model versions:
#   m1 (= v1) — Diagonal-equal baseline (no spatial correlation)
#   m2        — Distance-decay spatial correlation (no DD)
#   m3        — Distance-decay + global Gompertz DD
#   m4        — Distance-decay + site-specific Gompertz DD
#   m5        — Distance-decay + site DD + predator covariates
#   m6        — Time-varying distance-decay + site DD + predators
# ============================================================================

# Note: packages (cmdstanr, posterior, tidybayes, loo) are loaded via
# tar_option_set(packages = ...) in _targets.R. Do NOT add library() or
# source() calls here — tar_source("R") handles sourcing.


# ── Model version mapping ──────────────────────────────────────────────────
# Maps short version labels to Stan file names
.model_file_map <- c(

  "v1" = "herring_metapop_v1.stan",
  "v2" = "herring_metapop_v2.stan",
  "m1" = "herring_metapop_v1.stan",          # m1 = v1 (baseline)
  "m2" = "herring_metapop_m2_distance.stan",
  "m3" = "herring_metapop_m3_dd_global.stan",
  "m4" = "herring_metapop_m4_dd_site.stan",
  "m5" = "herring_metapop_m5_predators.stan",
  "m6" = "herring_metapop_m6_timevarying.stan"
)

# Models that require the distance matrix in the data list
.spatial_models <- c("m2", "m3", "m4", "m5", "m6")

# Models that require predator data + observation masks
.predator_models <- c("m5", "m6")


# ── compile_model() ─────────────────────────────────────────────────────────
#' Compile a Stan model
#'
#' @param version Character, one of "v1", "v2", "m1" through "m6".
#'   "m1" is an alias for "v1" (diagonal-equal baseline).
#' @param force_recompile Logical, force recompilation even if binary exists.
#' @return A CmdStanModel object (compiled, ready for sampling).
#'
compile_model <- function(version = "v1", force_recompile = FALSE) {
  valid_versions <- names(.model_file_map)
  if (!version %in% valid_versions) {
    stop("version must be one of: ", paste(valid_versions, collapse = ", "),
         call. = FALSE)
  }

  stan_file <- here::here("inst", "stan", .model_file_map[version])

  if (!file.exists(stan_file)) {
    stop("Stan file not found: ", stan_file, call. = FALSE)
  }

  cat("Compiling Stan model:", basename(stan_file), "\n")

  mod <- cmdstan_model(
    stan_file    = stan_file,
    dir          = here::here("inst", "stan"),
    force_recompile = force_recompile
  )

  cat("Compilation successful.\n")
  mod
}


# ── fit_model() ──────────────────────────────────────────────────────────────
#' Fit a Stan model to herring data
#'
#' For spatial models (m2-m6), the distance matrix must be included in
#' \code{stan_data}. Use \code{prepare_stan_data_spatial()} to add it.
#'
#' @param stan_data Named list of data for Stan. Must contain all variables
#'   declared in the data{} block of the chosen model version.
#' @param version Character, one of "v1", "v2", "m1" through "m6".
#' @param chains Integer, number of MCMC chains (default 4).
#' @param iter_warmup Integer, warmup iterations per chain (default 1000).
#' @param iter_sampling Integer, sampling iterations per chain (default 1000).
#' @param adapt_delta Numeric, target acceptance rate (default 0.95).
#'   High value recommended for state-space models to reduce divergences.
#' @param max_treedepth Integer, maximum tree depth for NUTS (default 12).
#' @param parallel_chains Integer, chains to run in parallel (default 4).
#' @param seed Integer, random seed for reproducibility.
#' @param ... Additional arguments passed to CmdStanModel$sample().
#' @return A CmdStanMCMC object.
#'
fit_model <- function(stan_data,
                      version          = "v1",
                      chains           = 4L,
                      iter_warmup      = 1000L,
                      iter_sampling    = 1000L,
                      adapt_delta      = 0.95,
                      max_treedepth    = 12L,
                      parallel_chains  = 4L,
                      seed             = 2027L,
                      ...) {

  # Validate that spatial models have the distance matrix
  if (version %in% .spatial_models && is.null(stan_data$dist_mat)) {
    stop("Model ", version, " requires 'dist_mat' in stan_data. ",
         "Use prepare_stan_data_spatial() to add it.", call. = FALSE)
  }

  # Validate that predator models have predator masks

  if (version %in% .predator_models) {
    if (is.null(stan_data$whale_obs) || is.null(stan_data$pred_obs)) {
      stop("Model ", version, " requires 'whale_obs' and 'pred_obs' in stan_data. ",
           "Use prepare_stan_data_spatial() to add them.", call. = FALSE)
    }
  }

  mod <- compile_model(version)

  cat("Fitting model", version, "with",
      chains, "chains x", iter_sampling, "post-warmup samples\n")

  fit <- mod$sample(
    data             = stan_data,
    chains           = chains,
    parallel_chains  = parallel_chains,
    iter_warmup      = iter_warmup,
    iter_sampling    = iter_sampling,
    adapt_delta      = adapt_delta,
    max_treedepth    = max_treedepth,
    seed             = seed,
    refresh          = 200,
    ...
  )

  cat("Sampling complete.\n")
  fit
}


# ── check_diagnostics() ─────────────────────────────────────────────────────
#' Run comprehensive MCMC diagnostics
#'
#' Checks: divergent transitions, max treedepth, E-BFMI, Rhat, bulk/tail ESS.
#' Prints a summary and returns a named list of diagnostic results.
#'
#' @param fit A CmdStanMCMC object from fit_model().
#' @param rhat_threshold Numeric, flag parameters with Rhat above this (default 1.01).
#' @param ess_threshold Numeric, flag parameters with bulk or tail ESS below this (default 400).
#' @return A list with components:
#'   - divergences: integer count of divergent transitions
#'   - treedepth_exceeded: integer count of iterations hitting max treedepth
#'   - ebfmi: numeric vector of E-BFMI per chain (flag if < 0.3)
#'   - rhat_problems: tibble of parameters with Rhat > threshold
#'   - ess_problems: tibble of parameters with low ESS
#'   - passed: logical, TRUE if all diagnostics pass
#'
check_diagnostics <- function(fit, rhat_threshold = 1.01, ess_threshold = 400) {

  cat("\n", strrep("=", 60), "\n")
  cat(" MCMC DIAGNOSTICS\n")
  cat(strrep("=", 60), "\n\n")

  # -- Divergences --
  diag_summary <- fit$diagnostic_summary()
  n_divergent  <- sum(diag_summary$num_divergent)
  cat("Divergent transitions:", n_divergent, "\n")

  # -- Max treedepth --
  n_treedepth <- sum(diag_summary$num_max_treedepth)
  cat("Max treedepth exceeded:", n_treedepth, "\n")

  # -- E-BFMI (energy Bayesian fraction of missing information) --
  ebfmi <- diag_summary$ebfmi
  cat("E-BFMI per chain:", paste(round(ebfmi, 3), collapse = ", "), "\n")
  ebfmi_low <- any(ebfmi < 0.3)
  if (ebfmi_low) cat("  WARNING: E-BFMI < 0.3 in some chains\n")


  # -- Parameter-level diagnostics --
  summ <- fit$summary() |>
    as_tibble()

  # Rhat
  rhat_bad <- summ |>
    filter(rhat > rhat_threshold) |>
    select(variable, rhat, ess_bulk, ess_tail)

  cat("\nParameters with Rhat >", rhat_threshold, ":", nrow(rhat_bad), "\n")
  if (nrow(rhat_bad) > 0 && nrow(rhat_bad) <= 20) {
    print(rhat_bad, n = 20)
  } else if (nrow(rhat_bad) > 20) {
    cat("  (showing first 20 of", nrow(rhat_bad), ")\n")
    print(head(rhat_bad, 20))
  }

  # ESS
  ess_bad <- summ |>
    filter(ess_bulk < ess_threshold | ess_tail < ess_threshold) |>
    select(variable, ess_bulk, ess_tail, rhat)

  cat("\nParameters with ESS <", ess_threshold, ":", nrow(ess_bad), "\n")
  if (nrow(ess_bad) > 0 && nrow(ess_bad) <= 20) {
    print(ess_bad, n = 20)
  } else if (nrow(ess_bad) > 20) {
    cat("  (showing first 20 of", nrow(ess_bad), ")\n")
    print(head(ess_bad, 20))
  }

  # -- Overall assessment --
  passed <- (n_divergent == 0) &&
            (n_treedepth == 0) &&
            (!ebfmi_low) &&
            (nrow(rhat_bad) == 0) &&
            (nrow(ess_bad) == 0)

  cat("\n", strrep("-", 40), "\n")
  if (passed) {
    cat("PASSED: All diagnostics look good.\n")
  } else {
    cat("FAILED: Some diagnostics need attention.\n")
    if (n_divergent > 0)   cat("  -> Increase adapt_delta or reparameterize.\n")
    if (n_treedepth > 0)   cat("  -> Increase max_treedepth.\n")
    if (ebfmi_low)         cat("  -> Potential energy issues; consider reparameterization.\n")
    if (nrow(rhat_bad) > 0) cat("  -> Run longer chains or check for multimodality.\n")
    if (nrow(ess_bad) > 0)  cat("  -> Run more iterations or thin less.\n")
  }
  cat(strrep("=", 60), "\n\n")

  invisible(list(
    divergences       = n_divergent,
    treedepth_exceeded = n_treedepth,
    ebfmi             = ebfmi,
    rhat_problems     = rhat_bad,
    ess_problems      = ess_bad,
    passed            = passed
  ))
}


# ── extract_posteriors() ─────────────────────────────────────────────────────
#' Extract key posterior quantities as tidy tibbles
#'
#' Uses tidybayes to produce long-format data frames for biomass trajectories,
#' fishing rates, and covariate effects. Adds meaningful labels (year, site name).
#'
#' @param fit A CmdStanMCMC object.
#' @param stan_data The named list that was passed to Stan (needed for dimensions
#'   and labeling).
#' @param years Integer vector of calendar years (length N_years).
#'   Defaults to YEARS from 00_setup.R.
#' @param site_names Character vector of site names (length N_sites).
#'   Defaults to SITE_NAMES from 00_setup.R.
#' @return A named list of tibbles:
#'   - biomass: posterior summaries of Z (pre-fishing log biomass) by year x site
#'   - post_fishing: posterior summaries of X (post-fishing log biomass)
#'   - fishing_rate: posterior summaries of Pc_mat by year x site
#'   - growth: posterior summary of U (global or site-level)
#'   - pdo_effect: posterior summary of pdocoef
#'   - catchability: posterior summary of log_q
#'   - sigma: posterior summary of process error SD(s)
#'   - sigma_obs: posterior summary of observation error SD
#'
extract_posteriors <- function(fit,
                               stan_data,
                               years      = YEARS,
                               site_names = SITE_NAMES) {

  draws <- fit$draws(format = "draws_df")

  N_years <- stan_data$N_years
  N_sites <- stan_data$N_sites

  # Helper: create year and site labels for matrix-indexed parameters
  make_labels <- function(n_years, n_sites) {
    expand_grid(
      year_idx = 1:n_years,
      site_idx = 1:n_sites
    ) |>
      mutate(
        year = years[year_idx],
        site = site_names[site_idx]
      )
  }

  labels <- make_labels(N_years, N_sites)

  # -- Pre-fishing log biomass Z[t,j] --
  biomass <- draws |>
    gather_draws(Z[year_idx, site_idx]) |>
    left_join(labels, by = c("year_idx", "site_idx")) |>
    group_by(year, site) |>
    median_qi(.value, .width = c(0.50, 0.90)) |>
    ungroup() |>
    mutate(
      biomass     = exp(.value),       # back-transform to natural scale
      biomass_lo  = exp(.lower),
      biomass_hi  = exp(.upper)
    )

  # -- Post-fishing log biomass X[t,j] --
  post_fishing <- draws |>
    gather_draws(X[year_idx, site_idx]) |>
    left_join(labels, by = c("year_idx", "site_idx")) |>
    group_by(year, site) |>
    median_qi(.value, .width = c(0.50, 0.90)) |>
    ungroup()

  # -- Fishing rate Pc_mat[t,j] --
  fishing_rate <- draws |>
    gather_draws(Pc_mat[year_idx, site_idx]) |>
    left_join(labels, by = c("year_idx", "site_idx")) |>
    group_by(year, site) |>
    median_qi(.value, .width = 0.90) |>
    ungroup() |>
    rename(fishing_rate = .value)

  # -- Growth rate U (scalar for v1, vector for v2) --
  # Try U[j] first (v2), fall back to U (v1)
  growth_vars <- names(draws)[str_detect(names(draws), "^U\\[")]
  if (length(growth_vars) > 0) {
    # v2: site-level growth rates
    growth <- draws |>
      gather_draws(U[site_idx]) |>
      mutate(site = site_names[site_idx]) |>
      group_by(site) |>
      median_qi(.value, .width = 0.90) |>
      ungroup()
  } else {
    # v1: single global growth rate
    growth <- draws |>
      gather_draws(U) |>
      median_qi(.value, .width = 0.90) |>
      ungroup()
  }

  # -- PDO effect --
  pdo_effect <- draws |>
    gather_draws(pdocoef) |>
    median_qi(.value, .width = 0.90)

  # -- Catchability --
  catchability <- draws |>
    gather_draws(log_q[q_type]) |>
    mutate(survey = c("surface", "dive")[q_type]) |>
    group_by(survey) |>
    median_qi(.value, .width = 0.90) |>
    ungroup()

  # -- Process error SD --
  # v1: sigma (scalar); v2: sigma_site (vector)
  sigma_vars <- names(draws)[str_detect(names(draws), "^sigma_site\\[")]
  if (length(sigma_vars) > 0) {
    sigma_post <- draws |>
      gather_draws(sigma_site[site_idx]) |>
      mutate(site = site_names[site_idx]) |>
      group_by(site) |>
      median_qi(.value, .width = 0.90) |>
      ungroup()
  } else {
    sigma_post <- draws |>
      gather_draws(sigma) |>
      median_qi(.value, .width = 0.90)
  }

  # -- Observation error SD --
  sigma_obs_post <- draws |>
    gather_draws(sigma_obs) |>
    median_qi(.value, .width = 0.90)

  # ── Build biomass_estimates with expected column names ──
  # _targets.R and 06_figures.R expect $biomass_estimates with columns:
  #   section_name, year, biomass_median, biomass_lower, biomass_upper, .width
  biomass_estimates <- biomass |>
    rename(section_name = site) |>
    mutate(
      biomass_median = biomass,
      biomass_lower  = biomass_lo,
      biomass_upper  = biomass_hi
    )

  # ── Build fishing_estimates with expected column names ──
  # _targets.R and 06_figures.R expect $fishing_estimates with columns:
  #   section_name, year, pc_median, .lower, .upper
  fishing_estimates <- fishing_rate |>
    rename(
      section_name = site,
      pc_median    = fishing_rate
    )

  list(
    biomass_estimates  = biomass_estimates,
    fishing_estimates  = fishing_estimates,
    # Keep original names as aliases for backward compatibility
    biomass            = biomass_estimates,
    post_fishing       = post_fishing,
    fishing_rate       = fishing_estimates,
    growth             = growth,
    pdo_effect         = pdo_effect,
    catchability       = catchability,
    sigma              = sigma_post,
    sigma_obs          = sigma_obs_post
  )
}


# NOTE: prepare_stan_data_v1() and prepare_stan_data_v2() have been removed.
# Stan data preparation is now handled by prepare_model_data(format = "stan")
# in R/02_prepare_model_data.R, which produces the correct data list format
# matching herring_metapop_v1.stan's data{} block directly.


# ── prepare_stan_data_spatial() ─────────────────────────────────────────────
#' Add distance matrix and predator masks to a Stan data list
#'
#' Reads the effective distance matrix from the Excel file, subsets to the
#' 11 retained sections (SECTIONS_KEEP), scales distances to km, and appends
#' to the existing Stan data list. Also creates predator observation masks
#' for models m5/m6.
#'
#' @param stan_data Named list produced by \code{prepare_model_data(format = "stan")}.
#' @param distance_type Character, "effective" (default, accounts for coastline)
#'   or "euclidean". Effective distances are preferred because they reflect
#'   actual dispersal pathways around islands.
#' @param scale_km Logical, if TRUE (default) divide distances by 1000 to convert
#'   from metres to km. This keeps phi on a sensible scale (~10-200 km).
#' @return The input \code{stan_data} list with added elements:
#'   - dist_mat: N_sites x N_sites distance matrix (symmetric, diagonal = 0)
#'   - whale_obs: integer vector (N_years), 1 if whale data non-missing
#'   - pred_obs: integer vector (N_years), 1 if ssl/seal data non-missing
#'
prepare_stan_data_spatial <- function(stan_data,
                                      distance_type = "effective",
                                      scale_km = TRUE) {

  stopifnot(distance_type %in% c("effective", "euclidean"))

  # ── Read the distance matrix from Excel ──
  xlsx_path <- here::here("Data", "raw",
                           "Euclidean & effective distance matrices herring & Steller.xlsx")

  if (!file.exists(xlsx_path)) {
    stop("Distance matrix file not found: ", xlsx_path, call. = FALSE)
  }

  sheet_name <- if (distance_type == "effective") {
    "Herring Effective"
  } else {
    "Herring Euclidean"
  }

  dist_raw <- readxl::read_xlsx(xlsx_path, sheet = sheet_name)

  # First column is the row labels (section IDs), rest are distance values
  # Column names are "Id1", "Id2", ..., "Id25" (section IDs with "Id" prefix)
  # Row labels are in the first column (unnamed or named)

  # Extract section IDs from column names (strip "Id" prefix)
  col_ids <- as.integer(gsub("^Id", "", names(dist_raw)[-1]))

  # The first column contains row labels (section IDs)
  row_ids <- as.integer(dist_raw[[1]])

  # Remove any NA rows (padding in Excel)
  valid_rows <- !is.na(row_ids)
  row_ids <- row_ids[valid_rows]

  # Extract numeric matrix
  dist_full <- as.matrix(dist_raw[valid_rows, -1])
  rownames(dist_full) <- row_ids
  colnames(dist_full) <- col_ids

  # ── Subset to SECTIONS_KEEP (11 retained sites) ──
  # SECTIONS_KEEP is defined in 00_setup.R: c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
  keep_str <- as.character(SECTIONS_KEEP)

  if (!all(keep_str %in% rownames(dist_full))) {
    missing <- setdiff(keep_str, rownames(dist_full))
    stop("Sections not found in distance matrix: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  dist_sub <- dist_full[keep_str, keep_str]

  # Convert to numeric (may be character from Excel read)
  dist_sub <- apply(dist_sub, 2, as.numeric)

  # Verify symmetry and zero diagonal
  stopifnot(
    "Distance matrix must be square" = nrow(dist_sub) == ncol(dist_sub),
    "Distance matrix must match N_sites" = nrow(dist_sub) == stan_data$N_sites,
    "Diagonal must be zero" = all(diag(dist_sub) == 0),
    "Matrix must be symmetric" = all(abs(dist_sub - t(dist_sub)) < 1e-6)
  )

  # ── Optional: scale to km ──
  if (scale_km) {
    dist_sub <- dist_sub / 1000
  }

  stan_data$dist_mat <- dist_sub

  # ── Build predator observation masks ──
  # whale_obs[t] = 1 if whale data is non-zero/non-NA at time t

  # pred_obs[t] = 1 if ssl/seal data is non-zero/non-NA at time t
  # For models without predator data, these are all zeros (safe — multiplied by coef)

  if (!is.null(stan_data$whale)) {
    stan_data$whale_obs <- as.array(as.integer(
      !is.na(stan_data$whale) & stan_data$whale != 0
    ))
  } else {
    # Default: all zeros (no whale data available)
    stan_data$whale     <- rep(0.0, stan_data$N_years)
    stan_data$whale_obs <- as.array(rep(0L, stan_data$N_years))
  }

  if (!is.null(stan_data$ssl) && !is.null(stan_data$seal)) {
    # Mark years where at least some ssl/seal data exists (any site non-zero)
    ssl_has_data <- apply(stan_data$ssl, 1, function(r) any(!is.na(r) & r != 0))
    seal_has_data <- apply(stan_data$seal, 1, function(r) any(!is.na(r) & r != 0))
    stan_data$pred_obs <- as.array(as.integer(ssl_has_data | seal_has_data))
  } else {
    # Default: all zeros
    stan_data$ssl      <- matrix(0.0, nrow = stan_data$N_years, ncol = stan_data$N_sites)
    stan_data$seal     <- matrix(0.0, nrow = stan_data$N_years, ncol = stan_data$N_sites)
    stan_data$pred_obs <- as.array(rep(0L, stan_data$N_years))
  }

  cat("Spatial data prepared:",
      "distance_type =", distance_type,
      ", scale_km =", scale_km,
      ", range = [", round(min(dist_sub[dist_sub > 0]), 1), ",",
      round(max(dist_sub), 1), "]",
      if (scale_km) "km" else "m", "\n")

  stan_data
}
