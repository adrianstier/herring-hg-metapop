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

# Reader note:
# `prepare_model_data()` builds a richer, version-agnostic data object.
# This file is the narrowing bridge that maps that object onto a specific
# Stan `data {}` contract, then translates posterior arrays back into
# labeled tibbles that the ecological summary code can read.

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
.region_predator_models <- c("m5")
.matrix_predator_models <- c("v2", "m6")
.masked_predator_models <- c("m5", "m6")


.standardize_series_for_stan <- function(x) {
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


# Convert the canonical analysis object into the exact data list expected by
# one Stan file. This keeps model-specific contracts in one place instead of
# scattering ad hoc data munging across fitting scripts.
.build_stan_input <- function(stan_data, version) {
  required_base <- c(
    "N_years", "N_sites", "Y", "Y_obs", "pdo", "q_idx",
    "N_catch", "catch_row", "catch_col", "log_catch"
  )
  missing_base <- setdiff(required_base, names(stan_data))
  if (length(missing_base) > 0) {
    stop(
      "stan_data is missing required fields for ", version, ": ",
      paste(missing_base, collapse = ", "),
      call. = FALSE
    )
  }

  predators_tbl <- stan_data$predators
  if (!is.null(predators_tbl)) {
    predators_tbl <- predators_tbl |>
      arrange(year)
  }

  dist_mat <- stan_data$dist_mat
  if (is.null(dist_mat) && !is.null(stan_data$D)) {
    dist_mat <- stan_data$D
  }

  ssl_spatial_raw <- stan_data$ssl_spatial
  if (is.null(ssl_spatial_raw) && !is.null(stan_data$predator_ssl_spatial)) {
    ssl_spatial_raw <- stan_data$predator_ssl_spatial
  }

  seal_spatial_raw <- stan_data$seal_spatial
  if (is.null(seal_spatial_raw) && !is.null(stan_data$predator_seal_spatial)) {
    seal_spatial_raw <- stan_data$predator_seal_spatial
  }

  whale_vec <- stan_data$whale
  if (is.null(whale_vec) && !is.null(predators_tbl)) {
    whale_vec <- .standardize_series_for_stan(predators_tbl$whale_abundance)
  }

  ssl_region <- stan_data$ssl_region
  if (is.null(ssl_region) && !is.null(predators_tbl)) {
    ssl_region <- .standardize_series_for_stan(predators_tbl$ssl_count)
  }

  seal_region <- stan_data$seal_region
  if (is.null(seal_region) && !is.null(predators_tbl)) {
    seal_region <- .standardize_series_for_stan(predators_tbl$seal_count)
  }

  ssl_matrix <- NULL
  if (!is.null(ssl_spatial_raw)) {
    ssl_matrix <- as.matrix(ssl_spatial_raw)
  } else if (!is.null(stan_data$ssl) && is.matrix(stan_data$ssl)) {
    ssl_matrix <- as.matrix(stan_data$ssl)
  }

  seal_matrix <- NULL
  if (!is.null(seal_spatial_raw)) {
    seal_matrix <- as.matrix(seal_spatial_raw)
  } else if (!is.null(stan_data$seal) && is.matrix(stan_data$seal)) {
    seal_matrix <- as.matrix(stan_data$seal)
  }

  whale_obs <- stan_data$whale_obs
  if (is.null(whale_obs) && !is.null(predators_tbl)) {
    whale_obs <- as.array(as.integer(
      !is.na(predators_tbl$whale_abundance) & predators_tbl$whale_abundance != 0
    ))
  }

  pred_obs <- stan_data$pred_obs
  if (is.null(pred_obs) && !is.null(ssl_spatial_raw) && !is.null(seal_spatial_raw)) {
    pred_obs <- as.array(as.integer(
      apply(ssl_spatial_raw, 1, function(x) any(!is.na(x) & x != 0)) |
        apply(seal_spatial_raw, 1, function(x) any(!is.na(x) & x != 0))
    ))
  } else if (is.null(pred_obs) && !is.null(predators_tbl)) {
    pred_obs <- as.array(as.integer(
      (!is.na(predators_tbl$ssl_count) & predators_tbl$ssl_count != 0) |
        (!is.na(predators_tbl$seal_count) & predators_tbl$seal_count != 0)
    ))
  }

  stan_input <- list(
    N_years   = stan_data$N_years,
    N_sites   = stan_data$N_sites,
    Y         = stan_data$Y,
    Y_obs     = stan_data$Y_obs,
    pdo       = as.numeric(stan_data$pdo),
    q_idx     = as.array(stan_data$q_idx),
    N_catch   = stan_data$N_catch,
    catch_row = as.array(stan_data$catch_row),
    catch_col = as.array(stan_data$catch_col),
    log_catch = as.numeric(stan_data$log_catch),
    prior_only = as.integer(if (is.null(stan_data$prior_only)) 0L else stan_data$prior_only)
  )

  if (version %in% .spatial_models) {
    if (is.null(dist_mat)) {
      stop(
        "Model ", version, " requires a distance matrix. ",
        "Provide `dist_mat` directly or use `prepare_model_data(..., spatial = TRUE)`.",
        call. = FALSE
      )
    }

    stan_input$dist_mat <- as.matrix(dist_mat)

    if (version == "m2") {
      stan_input$max_dist <- as.numeric(
        if (is.null(stan_data$max_dist)) max(dist_mat) else stan_data$max_dist
      )
    }
  }

  if (version %in% .region_predator_models) {
    if (is.null(whale_vec) || is.null(ssl_region) || is.null(seal_region)) {
      stop(
        "Model ", version, " requires region-level predator covariates. ",
        "Provide `predators` to `prepare_model_data()`.",
        call. = FALSE
      )
    }

    stan_input$whale <- as.numeric(whale_vec)
    stan_input$ssl <- as.numeric(ssl_region)
    stan_input$seal <- as.numeric(seal_region)
  }

  if (version %in% .matrix_predator_models) {
    if (is.null(whale_vec) || is.null(ssl_matrix) || is.null(seal_matrix)) {
      stop(
        "Model ", version, " requires whale plus site-level predator matrices. ",
        "Provide `predators` and `predator_spatial` via `prepare_model_data(..., spatial = TRUE)`.",
        call. = FALSE
      )
    }

    stan_input$whale <- as.numeric(whale_vec)
    stan_input$ssl <- ssl_matrix
    stan_input$seal <- seal_matrix
  }

  if (version %in% .masked_predator_models) {
    if (is.null(whale_obs) || is.null(pred_obs)) {
      stop(
        "Model ", version, " requires `whale_obs` and `pred_obs`. ",
        "Provide predator covariates through `prepare_model_data(..., spatial = TRUE)` ",
        "or `prepare_stan_data_spatial()`.",
        call. = FALSE
      )
    }

    stan_input$whale_obs <- as.array(as.integer(whale_obs))
    stan_input$pred_obs <- as.array(as.integer(pred_obs))
  }

  if (version == "v2") {
    stan_input$use_gompertz <- as.integer(
      if (is.null(stan_data$use_gompertz)) 0L else stan_data$use_gompertz
    )
    stan_input$lkj_eta <- as.numeric(
      if (is.null(stan_data$lkj_eta)) 2 else stan_data$lkj_eta
    )
  }

  stan_input
}


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
#' @param stan_data Named list produced by `prepare_model_data()` or by
#'   `prepare_stan_data_spatial()`. It may be richer than the chosen Stan
#'   model requires; `.build_stan_input()` selects the exact subset needed.
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
  stan_input <- .build_stan_input(stan_data, version)

  mod <- compile_model(version)

  cat("Fitting model", version, "with",
      chains, "chains x", iter_sampling, "post-warmup samples\n")

  fit <- mod$sample(
    data             = stan_input,
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
    mutate(section_name = site) |>
    mutate(
      biomass_median = biomass,
      biomass_lower  = biomass_lo,
      biomass_upper  = biomass_hi
    )

  # ── Build fishing_estimates with expected column names ──
  # _targets.R and 06_figures.R expect $fishing_estimates with columns:
  #   section_name, year, pc_median, .lower, .upper
  fishing_estimates <- fishing_rate |>
    mutate(section_name = site) |>
    rename(pc_median = fishing_rate)

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
#' Backward-compatible helper for older manual fitting workflows.
#' The maintained targets path now prefers `prepare_model_data(..., spatial = TRUE)`,
#' but this helper is still useful when a collaborator starts from a simpler
#' Stan list and wants to append distance data plus predator observation masks.
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

  dist_sub <- load_distance_matrix(
    path_xlsx = xlsx_path,
    sheet = sheet_name,
    units_out = if (scale_km) "km" else "m"
  )

  stopifnot(
    "Distance matrix must match N_sites" = nrow(dist_sub) == stan_data$N_sites
  )

  stan_data$dist_mat <- dist_sub

  # ── Max inter-site distance (for M2 phi prior scaling) ──
  stan_data$max_dist <- max(dist_sub)

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
