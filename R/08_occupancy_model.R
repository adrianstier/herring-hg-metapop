# ============================================================================
# 08_occupancy_model.R — Bayesian site occupancy model for collective memory
# stier-2027-herring-metapopulation
#
# Implements the spawning site occupancy sub-model that tests whether
# collective memory (Ono et al. 2025, Nature) predicts site fidelity at
# Haida Gwaii. Uses the legacy spawn survey data where totalrecords > 0
# distinguishes true surveyed-zeros from unsurveyed site-years.
#
# Functions:
#   - prepare_occupancy_data()  — builds binary occupancy matrix + Stan data
#   - fit_occupancy()           — fits the Stan model via cmdstanr
#   - extract_occupancy_posteriors() — extracts key parameters
#   - fig_occupancy_heatmap()   — observed vs predicted occupancy heatmap
#   - fig_recolonization()      — recolonization probability over time
#
# References:
#   - Ono et al. 2025. Nature. (collective memory loss in herring)
#   - Stier et al. 2020. (portfolio effect at Haida Gwaii)
# ============================================================================

# Note: packages (cmdstanr, posterior, tidybayes, tidyverse, etc.) are loaded
# via tar_option_set(packages = ...) in _targets.R.


# ── prepare_occupancy_data() ────────────────────────────────────────────────
#' Build binary occupancy matrix and Stan data list from raw spawn survey data
#'
#' Uses the `totalrecords` column from the legacy spawn survey to distinguish:
#'   - surveyed, spawning detected (totalrecords > 0, SHI > 0) → occupied = 1
#'   - surveyed, no spawning (totalrecords > 0, SHI == 0) → occupied = 0
#'   - not surveyed (totalrecords == 0) → surveyed = 0 (missing data)
#'
#' @param spawn_clean List returned by clean_spawn(). Must contain $long with
#'   columns: year, section, section_name, spawn_index, log_shi.
#' @param path_legacy Path to legacy CSV with totalrecords column.
#'   Default: the standard legacy file path.
#' @param log_N_total Optional numeric vector of log total population size
#'   (length N_YEARS). If NULL, computed as log of sum of non-NA SHI across
#'   all sections per year.
#' @param age_index Optional numeric vector of age structure index
#'   (length N_YEARS). If NULL, the has_age_data flag is set to 0.
#' @param sections_drop Integer vector of sections to exclude.
#' @return Named list suitable for cmdstanr$sample(data = ...):
#'   - N_years, N_sites: dimensions
#'   - occupied: integer matrix (N_years x N_sites), 0/1
#'   - surveyed: integer matrix (N_years x N_sites), 0/1
#'   - log_N_total: numeric vector (length N_years)
#'   - has_age_data: integer 0 or 1
#'   - age_index: numeric vector (length N_years), zeros if no age data
#'   - prior_only: integer 0
#'   - metadata: list with year_labels, site_labels (not passed to Stan)
#'
prepare_occupancy_data <- function(
    spawn_clean,
    path_legacy    = here::here("Data", "raw", "legacy-2019",
                                "HG_Spawn_Survey_1940_2015.csv"),
    log_N_total    = NULL,
    age_index      = NULL,
    sections_drop  = c(4L, 11L)
) {

  # ── Read legacy data to get totalrecords ──
  legacy_raw <- readr::read_csv(path_legacy, show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::rename(spawn_index = shi) |>
    dplyr::mutate(section = as.integer(section))

  # ── Filter to analysis sections and year range ──
  survey_data <- legacy_raw |>
    dplyr::filter(
      !section %in% sections_drop,
      year >= YEAR_START,
      year <= YEAR_END
    ) |>
    dplyr::select(year, section, totalrecords, spawn_index)

  # ── Complete the grid: ensure every year x section exists ──
  complete_grid <- tidyr::expand_grid(
    year    = seq(YEAR_START, YEAR_END),
    section = SECTIONS_KEEP
  )

  survey_data <- complete_grid |>
    dplyr::left_join(survey_data, by = c("year", "section")) |>
    dplyr::mutate(
      totalrecords = tidyr::replace_na(totalrecords, 0L),
      spawn_index  = tidyr::replace_na(spawn_index, 0)
    )

  # ── Build occupancy and survey matrices ──
  # surveyed = 1 if totalrecords > 0 (site was visited by surveyors)
  # occupied = 1 if surveyed AND spawn_index > 0 (spawning detected)
  survey_data <- survey_data |>
    dplyr::mutate(
      surveyed = as.integer(totalrecords > 0),
      occupied = as.integer(totalrecords > 0 & spawn_index > 0)
    )

  # Pivot to matrices (rows = years, cols = sites ordered by SECTIONS_KEEP)
  section_lookup <- SECTIONS_ALL |>
    dplyr::filter(section %in% SECTIONS_KEEP) |>
    dplyr::select(section, section_name)

  survey_data <- survey_data |>
    dplyr::left_join(section_lookup, by = "section")

  # Occupancy matrix
  occ_wide <- survey_data |>
    dplyr::select(year, section_name, occupied) |>
    tidyr::pivot_wider(names_from = section_name, values_from = occupied) |>
    dplyr::arrange(year)

  occ_mat <- occ_wide |>
    dplyr::select(dplyr::all_of(SITE_NAMES)) |>
    as.matrix()

  # Survey mask matrix
  surv_wide <- survey_data |>
    dplyr::select(year, section_name, surveyed) |>
    tidyr::pivot_wider(names_from = section_name, values_from = surveyed) |>
    dplyr::arrange(year)

  surv_mat <- surv_wide |>
    dplyr::select(dplyr::all_of(SITE_NAMES)) |>
    as.matrix()

  # ── Build log_N_total if not provided ──
  if (is.null(log_N_total)) {
    # Sum SHI across all sections per year (using the clean spawn long data)
    total_shi <- spawn_clean$long |>
      dplyr::filter(!section %in% sections_drop) |>
      dplyr::group_by(year) |>
      dplyr::summarise(
        total_shi = sum(spawn_index, na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::arrange(year)

    # Handle years with zero total SHI: use log(SHI + 1) to avoid -Inf
    log_N_total <- log(total_shi$total_shi + 1)
  }

  stopifnot(
    "log_N_total length must equal N_YEARS" = length(log_N_total) == N_YEARS
  )

  # Standardize log_N_total for better sampling
  log_N_total_scaled <- as.numeric(scale(log_N_total))

  # ── Handle age_index ──
  has_age_data <- 0L
  if (!is.null(age_index)) {
    stopifnot(
      "age_index length must equal N_YEARS" = length(age_index) == N_YEARS
    )
    has_age_data <- 1L
    age_index_scaled <- as.numeric(scale(age_index))
  } else {
    age_index_scaled <- rep(0, N_YEARS)
  }

  # ── Assemble Stan data list ──
  stan_data <- list(
    N_years      = N_YEARS,
    N_sites      = N_SITES,
    occupied     = occ_mat,
    surveyed     = surv_mat,
    log_N_total  = log_N_total_scaled,
    has_age_data = has_age_data,
    age_index    = age_index_scaled,
    prior_only   = 0L
  )

  # ── Attach metadata (not passed to Stan, used for labeling) ──
  stan_data$metadata <- list(
    year_labels     = occ_wide$year,
    site_labels     = SITE_NAMES,
    log_N_total_raw = log_N_total,
    log_N_total_center = attr(scale(log_N_total), "scaled:center"),
    log_N_total_scale  = attr(scale(log_N_total), "scaled:scale"),
    occ_long        = survey_data
  )

  # ── Summary for user ──
  n_surveyed   <- sum(surv_mat)
  n_occupied   <- sum(occ_mat[surv_mat == 1])
  n_zero       <- n_surveyed - n_occupied
  n_unsurveyed <- length(surv_mat) - n_surveyed

  cat("Occupancy data prepared:\n")
  cat("  Dimensions:", N_YEARS, "years x", N_SITES, "sites\n")
  cat("  Surveyed site-years:", n_surveyed, "\n")
  cat("  Occupied (spawning detected):", n_occupied, "\n")

  cat("  Surveyed zeros (no spawning):", n_zero, "\n")
  cat("  Unsurveyed (totalrecords == 0):", n_unsurveyed, "\n")
  cat("  Age data:", ifelse(has_age_data, "provided", "not available"), "\n")

  stan_data
}


# ── fit_occupancy() ─────────────────────────────────────────────────────────
#' Fit the spawning site occupancy Stan model
#'
#' Compiles and samples from inst/stan/site_occupancy.stan using cmdstanr.
#'
#' @param occupancy_data Named list from prepare_occupancy_data().
#' @param chains Integer, number of MCMC chains (default 4).
#' @param iter_warmup Integer, warmup iterations per chain (default 1000).
#' @param iter_sampling Integer, sampling iterations per chain (default 2000).
#' @param adapt_delta Numeric, target acceptance rate (default 0.90).
#' @param max_treedepth Integer (default 10).
#' @param parallel_chains Integer (default 4).
#' @param seed Integer, random seed (default 2027).
#' @return A CmdStanMCMC object.
#'
fit_occupancy <- function(
    occupancy_data,
    chains          = 4L,
    iter_warmup     = 1000L,
    iter_sampling   = 2000L,
    adapt_delta     = 0.90,
    max_treedepth   = 10L,
    parallel_chains = 4L,
    seed            = 2027L
) {

  stan_file <- here::here("inst", "stan", "site_occupancy.stan")

  if (!file.exists(stan_file)) {
    stop("Stan file not found: ", stan_file, call. = FALSE)
  }

  cat("Compiling site occupancy model...\n")
  mod <- cmdstanr::cmdstan_model(
    stan_file = stan_file,
    dir       = here::here("inst", "stan")
  )

  # Strip metadata before passing to Stan (it's not a Stan variable)
  stan_input <- occupancy_data[!names(occupancy_data) %in% "metadata"]

  cat("Fitting site occupancy model with",
      chains, "chains x", iter_sampling, "post-warmup samples\n")

  fit <- mod$sample(
    data            = stan_input,
    chains          = chains,
    parallel_chains = parallel_chains,
    iter_warmup     = iter_warmup,
    iter_sampling   = iter_sampling,
    adapt_delta     = adapt_delta,
    max_treedepth   = max_treedepth,
    seed            = seed,
    refresh         = 200
  )

  cat("Occupancy model sampling complete.\n")
  fit
}


# ── extract_occupancy_posteriors() ──────────────────────────────────────────
#' Extract key posteriors from the occupancy model
#'
#' @param fit CmdStanMCMC object from fit_occupancy().
#' @param occupancy_data The Stan data list (with metadata) from
#'   prepare_occupancy_data().
#' @return Named list:
#'   - gamma: tibble with posterior summary of persistence parameter
#'   - delta_pop: tibble with posterior summary of population effect
#'   - delta_age: tibble with posterior summary of age effect (if applicable)
#'   - alpha: tibble with site-level intercepts
#'   - p_pred: tibble with predicted occupancy (year x site, long format)
#'   - p_recol: tibble with recolonization probabilities (year x site)
#'   - p_persist: tibble with persistence probabilities (year x site)
#'   - diagnostics: list with Rhat and ESS summaries
#'
extract_occupancy_posteriors <- function(fit, occupancy_data) {

  draws <- fit$draws(format = "draws_df")

  years      <- occupancy_data$metadata$year_labels
  site_names <- occupancy_data$metadata$site_labels
  N_years    <- occupancy_data$N_years
  N_sites    <- occupancy_data$N_sites

  # ── Key scalar parameters ──
  gamma_post <- draws |>
    tidybayes::gather_draws(gamma) |>
    tidybayes::median_qi(.value, .width = c(0.50, 0.90)) |>
    dplyr::ungroup()

  delta_pop_post <- draws |>
    tidybayes::gather_draws(delta_pop) |>
    tidybayes::median_qi(.value, .width = c(0.50, 0.90)) |>
    dplyr::ungroup()

  delta_age_post <- draws |>
    tidybayes::gather_draws(delta_age) |>
    tidybayes::median_qi(.value, .width = c(0.50, 0.90)) |>
    dplyr::ungroup()

  # ── Site random intercepts ──
  alpha_post <- draws |>
    tidybayes::gather_draws(alpha[site_idx]) |>
    dplyr::mutate(site = site_names[site_idx]) |>
    dplyr::group_by(site) |>
    tidybayes::median_qi(.value, .width = 0.90) |>
    dplyr::ungroup()

  # ── Predicted occupancy probability p_pred[t,j] ──
  labels <- tidyr::expand_grid(
    year_idx = 1:N_years,
    site_idx = 1:N_sites
  ) |>
    dplyr::mutate(
      year = years[year_idx],
      site = site_names[site_idx]
    )

  p_pred <- draws |>
    tidybayes::gather_draws(p_pred[year_idx, site_idx]) |>
    dplyr::left_join(labels, by = c("year_idx", "site_idx")) |>
    dplyr::group_by(year, site) |>
    tidybayes::median_qi(.value, .width = 0.90) |>
    dplyr::ungroup() |>
    dplyr::rename(p_pred = .value, p_pred_lo = .lower, p_pred_hi = .upper)

  # ── Recolonization probability p_recol[t,j] ──
  p_recol <- draws |>
    tidybayes::gather_draws(p_recol[year_idx, site_idx]) |>
    dplyr::left_join(labels, by = c("year_idx", "site_idx")) |>
    dplyr::group_by(year, site) |>
    tidybayes::median_qi(.value, .width = 0.90) |>
    dplyr::ungroup() |>
    dplyr::rename(p_recol = .value, p_recol_lo = .lower, p_recol_hi = .upper)

  # ── Persistence probability p_persist[t,j] ──
  p_persist <- draws |>
    tidybayes::gather_draws(p_persist[year_idx, site_idx]) |>
    dplyr::left_join(labels, by = c("year_idx", "site_idx")) |>
    dplyr::group_by(year, site) |>
    tidybayes::median_qi(.value, .width = 0.90) |>
    dplyr::ungroup() |>
    dplyr::rename(p_persist = .value, p_persist_lo = .lower, p_persist_hi = .upper)

  # ── Basic diagnostics ──
  summ <- fit$summary() |> tibble::as_tibble()
  key_params <- summ |>
    dplyr::filter(stringr::str_detect(variable,
      "^(gamma|delta_pop|delta_age|alpha_mu|sigma_alpha)$"))

  diagnostics <- list(
    key_params = key_params,
    max_rhat   = max(summ$rhat, na.rm = TRUE),
    min_ess    = min(summ$ess_bulk, na.rm = TRUE)
  )

  cat("\nOccupancy model key parameters:\n")
  print(key_params |> dplyr::select(variable, mean, median, sd, q5, q95,
                                     rhat, ess_bulk, ess_tail))

  list(
    gamma       = gamma_post,
    delta_pop   = delta_pop_post,
    delta_age   = delta_age_post,
    alpha       = alpha_post,
    p_pred      = p_pred,
    p_recol     = p_recol,
    p_persist   = p_persist,
    diagnostics = diagnostics
  )
}


# ── fig_occupancy_heatmap() ─────────────────────────────────────────────────
#' Heatmap of observed vs predicted spawning site occupancy
#'
#' Two-panel heatmap:
#'   A) Observed occupancy (binary: dark = spawning, light = no spawning,
#'      grey = not surveyed)
#'   B) Predicted occupancy probability from the model (continuous 0-1)
#'
#' Sites ordered by total years occupied (most to least). Site abandonment
#' events are visually apparent as transitions from dark to light.
#'
#' @param occupancy_data Stan data list from prepare_occupancy_data()
#' @param posteriors List from extract_occupancy_posteriors()
#' @return ggplot object (patchwork)
#'
fig_occupancy_heatmap <- function(occupancy_data, posteriors) {

  meta <- occupancy_data$metadata
  occ_long <- meta$occ_long

  # ── Order sites by total years occupied (descending) ──
  site_order <- occ_long |>
    dplyr::filter(surveyed == 1) |>
    dplyr::group_by(section_name) |>
    dplyr::summarise(pct_occupied = mean(occupied), .groups = "drop") |>
    dplyr::arrange(pct_occupied) |>
    dplyr::pull(section_name)

  # ── Panel A: Observed occupancy ──
  obs_plot_data <- occ_long |>
    dplyr::mutate(
      section_name = factor(section_name, levels = site_order),
      status = dplyr::case_when(
        surveyed == 0            ~ "Not surveyed",
        surveyed == 1 & occupied == 1 ~ "Spawning",
        surveyed == 1 & occupied == 0 ~ "No spawning",
        TRUE                     ~ "Unknown"
      ),
      status = factor(status, levels = c("Spawning", "No spawning", "Not surveyed"))
    )

  p_obs <- ggplot2::ggplot(obs_plot_data,
                            ggplot2::aes(x = year, y = section_name, fill = status)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.1) +
    ggplot2::scale_fill_manual(
      values = c(
        "Spawning"     = PAL$navy,
        "No spawning"  = PAL$teal,
        "Not surveyed" = "grey85"
      ),
      name = NULL
    ) +
    ggplot2::scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    ggplot2::labs(x = NULL, y = NULL, subtitle = "Observed") +
    theme_pub(base_size = 9) +
    ggplot2::theme(
      axis.text.x  = ggplot2::element_blank(),
      legend.position = "bottom"
    )

  # ── Panel B: Predicted occupancy probability ──
  pred_data <- posteriors$p_pred |>
    dplyr::mutate(section_name = factor(site, levels = site_order))

  p_pred <- ggplot2::ggplot(pred_data,
                             ggplot2::aes(x = year, y = section_name, fill = p_pred)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.1) +
    ggplot2::scale_fill_viridis_c(
      option = "D",
      limits = c(0, 1),
      name   = "P(occupied)"
    ) +
    ggplot2::scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    ggplot2::labs(x = "Year", y = NULL, subtitle = "Predicted") +
    theme_pub(base_size = 9) +
    ggplot2::theme(legend.position = "bottom")

  # ── Combine ──
  p_obs / p_pred +
    patchwork::plot_annotation(tag_levels = "A") +
    patchwork::plot_layout(heights = c(1, 1))
}


# ── fig_recolonization() ───────────────────────────────────────────────────
#' Recolonization probability over time
#'
#' Shows how the probability of recolonizing an abandoned spawning site
#' has changed over time. A declining trend would support the collective
#' memory hypothesis: as the population shrinks and loses experienced
#' spawners, sites are less likely to be rediscovered.
#'
#' Shows both the site-averaged recolonization probability (thick line)
#' and individual site trajectories (thin lines).
#'
#' @param posteriors List from extract_occupancy_posteriors()
#' @return ggplot object
#'
fig_recolonization <- function(posteriors) {

  recol <- posteriors$p_recol

  # ── Site-averaged recolonization probability ──
  recol_mean <- recol |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      p_recol_mean = mean(p_recol, na.rm = TRUE),
      p_recol_lo   = mean(p_recol_lo, na.rm = TRUE),
      p_recol_hi   = mean(p_recol_hi, na.rm = TRUE),
      .groups = "drop"
    )

  ggplot2::ggplot() +
    # Individual site trajectories (thin, transparent)
    ggplot2::geom_line(
      data = recol,
      ggplot2::aes(x = year, y = p_recol, group = site),
      colour = PAL$teal, alpha = 0.2, linewidth = 0.3
    ) +
    # Site-averaged recolonization with CI ribbon
    ggplot2::geom_ribbon(
      data = recol_mean,
      ggplot2::aes(x = year, ymin = p_recol_lo, ymax = p_recol_hi),
      fill = PAL$navy, alpha = 0.2
    ) +
    ggplot2::geom_line(
      data = recol_mean,
      ggplot2::aes(x = year, y = p_recol_mean),
      colour = PAL$navy, linewidth = 1
    ) +
    ggplot2::scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    ggplot2::scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
    ggplot2::labs(
      x = "Year",
      y = "Recolonization Probability",
      subtitle = "P(occupied | previously unoccupied)"
    ) +
    theme_pub(base_size = 10)
}
