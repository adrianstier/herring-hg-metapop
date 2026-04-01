# ============================================================================
# 05_portfolio.R — Portfolio effect and synchrony analysis
# stier-2027-herring-metapopulation
#
# Implements portfolio analysis from Stier et al. (2020) using tidyverse
# conventions. Replaces the loop-based approach from the legacy figures.R.
#
# Key metrics:
#   - CV ratio (subpopulation CV / archipelago CV) — portfolio effect
#   - Loreau & de Mazancourt (2008) synchrony index
#   - Moving-window pairwise cross-correlation
#   - Site occupancy for collective memory analysis
#
# References:
#   - Schindler et al. 2010. Nature 465:609-612 (portfolio effect in salmon)
#   - Loreau & de Mazancourt 2008. Am Nat 172:E48-E66 (synchrony index)
#   - Anderson et al. 2013. Ecol Lett 16:17-26 (mean-variance PE)
#   - Ono et al. 2025. Nature (collective memory loss)
# ============================================================================

# ── Portfolio effect: CV ratio ──────────────────────────────────────────────

#' Compute portfolio effect metrics over a moving window
#'
#' For each window, computes:
#'   - mean CV across subpopulations
#'   - CV of the total archipelago biomass
#'   - CV ratio (portfolio effect = mean_subpop_CV / archipelago_CV)
#'   - Loreau & de Mazancourt synchrony index
#'
#' @param biomass_estimates Tibble from extract_posteriors()$biomass with
#'   columns: year, site, .value, .width, biomass, biomass_lo, biomass_hi.
#'   Uses the 90% CI rows (.width == 0.9). Biomass is on natural (not log) scale.
#' @param window Integer, width of moving window in years. Default 10.
#' @param sections_drop Character vector of site names to exclude from
#'   portfolio calculations (e.g., sparse-data sites). Default drops
#'   "Tasu Sound & Gowgaia Bay" and "Naden Harbour" following Stier et al. 2020.
#' @return Tibble with columns: window_start, window_end, cv_subpop_mean,
#'   cv_archipelago, cv_ratio, synchrony_lm
compute_portfolio <- function(
    biomass_estimates,
    window = 10L,
    sections_drop = c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
) {

  # Filter to core subpopulations and use 90% CI rows
  biomass_core <- biomass_estimates |>
    filter(
      .width == 0.9,
      !site %in% sections_drop
    )

  years <- sort(unique(biomass_core$year))
  n_years <- length(years)
  n_windows <- n_years - window + 1L

  if (n_windows < 1L) {
    cli::cli_abort("Not enough years ({n_years}) for window size {window}")
  }

  # Pivot to wide matrix: rows = years, columns = sites
  biomass_wide <- biomass_core |>
    select(year, site, biomass) |>
    pivot_wider(names_from = site, values_from = biomass) |>
    arrange(year)

  year_vec <- biomass_wide$year
  bio_mat <- biomass_wide |> select(-year) |> as.matrix()

  # Compute metrics for each window
  purrr::map_dfr(seq_len(n_windows), function(i) {
    idx <- i:(i + window - 1L)
    window_mat <- bio_mat[idx, , drop = FALSE]
    window_years <- year_vec[idx]

    # Subpopulation CVs
    subpop_cvs <- apply(window_mat, 2, function(x) {
      x_pos <- x[x > 0 & !is.na(x)]
      if (length(x_pos) < 3) return(NA_real_)
      sd(x_pos) / mean(x_pos)
    })

    # Archipelago CV (total biomass across subpops per year)
    total_biomass <- rowSums(window_mat, na.rm = TRUE)
    cv_arch <- sd(total_biomass) / mean(total_biomass)

    # Loreau & de Mazancourt synchrony index
    # phi = var(sum) / (sum(sd))^2
    # Ranges from 0 (perfect asynchrony) to 1 (perfect synchrony)
    sync_lm <- compute_synchrony_lm(window_mat)

    tibble(
      window_start = min(window_years),
      window_end   = max(window_years),
      window_mid   = mean(window_years),
      cv_subpop_mean = mean(subpop_cvs, na.rm = TRUE),
      cv_archipelago = cv_arch,
      cv_ratio       = mean(subpop_cvs, na.rm = TRUE) / cv_arch,
      synchrony_lm   = sync_lm
    )
  })
}


# ── Loreau & de Mazancourt synchrony (single window) ───────────────────────

#' Compute Loreau & de Mazancourt (2008) synchrony index
#'
#' phi = var(sum_j X_j) / (sum_j sd(X_j))^2
#'
#' @param mat Numeric matrix, rows = time, columns = subpopulations
#' @return Scalar synchrony index in [0, 1]
compute_synchrony_lm <- function(mat) {
  # Remove columns that are all-zero or all-NA
  valid_cols <- apply(mat, 2, function(x) {
    sum(!is.na(x) & x > 0) >= 3
  })
  mat <- mat[, valid_cols, drop = FALSE]

  if (ncol(mat) < 2) return(NA_real_)

  # Replace NA with 0 for summation
  mat[is.na(mat)] <- 0

  total <- rowSums(mat)
  var_total <- var(total)
  sum_sd <- sum(apply(mat, 2, sd))

  if (sum_sd == 0) return(NA_real_)

  var_total / sum_sd^2
}


# ── Moving-window pairwise cross-correlation ───────────────────────────────

#' Compute moving-window pairwise Spearman correlation among subpopulations
#'
#' Replaces the triple-nested for loop in legacy figures.R with a vectorized
#' tidyverse approach. Uses rank-based (Spearman) correlation following
#' Stier et al. 2020.
#'
#' @param biomass_estimates Tibble from extract_posteriors()$biomass with
#'   columns: year, site, .width, biomass.
#' @param window Integer, width of moving window in years. Default 10.
#' @param sections_drop Character vector of site names to exclude.
#' @return Tibble with columns: window_start, window_end, window_mid,
#'   mean_pairwise_cor, sd_pairwise_cor, n_pairs
compute_synchrony <- function(
    biomass_estimates,
    window = 10L,
    sections_drop = c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
) {

  biomass_core <- biomass_estimates |>
    filter(
      .width == 0.9,
      !site %in% sections_drop
    )

  # Pivot to wide matrix
  biomass_wide <- biomass_core |>
    select(year, site, biomass) |>
    pivot_wider(names_from = site, values_from = biomass) |>
    arrange(year)

  year_vec <- biomass_wide$year
  bio_mat <- biomass_wide |> select(-year) |> as.matrix()

  n_years <- nrow(bio_mat)
  n_sites <- ncol(bio_mat)
  n_windows <- n_years - window + 1L

  if (n_windows < 1L) {
    cli::cli_abort("Not enough years ({n_years}) for window size {window}")
  }

  # Pre-compute all site pairs (upper triangle) to avoid growing vectors
  pair_indices <- combn(n_sites, 2)
  n_max_pairs  <- ncol(pair_indices)

  purrr::map_dfr(seq_len(n_windows), function(i) {
    idx <- i:(i + window - 1L)
    window_mat <- bio_mat[idx, , drop = FALSE]
    window_years <- year_vec[idx]

    # Compute pairwise Spearman correlations — pre-allocated vector
    pair_cors <- vapply(seq_len(n_max_pairs), function(k) {
      a <- pair_indices[1, k]
      b <- pair_indices[2, k]
      x <- window_mat[, a]
      y <- window_mat[, b]

      # Filter to pairs where both have positive values
      valid <- !is.na(x) & !is.na(y) & (x > 0 | y > 0)
      if (sum(valid) >= 4) {
        cor(rank(x[valid]), rank(y[valid]))
      } else {
        NA_real_
      }
    }, FUN.VALUE = numeric(1))

    # Drop pairs without enough data
    pair_cors <- pair_cors[!is.na(pair_cors)]

    tibble(
      window_start     = min(window_years),
      window_end       = max(window_years),
      window_mid       = mean(window_years),
      mean_pairwise_cor = if (length(pair_cors) > 0) mean(pair_cors) else NA_real_,
      sd_pairwise_cor   = if (length(pair_cors) > 1) sd(pair_cors) else NA_real_,
      n_pairs           = length(pair_cors)
    )
  })
}


# ── Site occupancy for collective memory analysis ──────────────────────────

#' Compute binary spawning site occupancy and summary metrics
#'
#' Inspired by Ono et al. (2025, Nature) showing collective memory loss in
#' herring. Spawning site abandonment and recolonization patterns reveal
#' whether subpopulations "remember" historical spawning grounds.
#'
#' @param spawn_data Tibble with columns: year, section, section_name,
#'   spawn_index (from clean_spawn()$long). NA indicates no spawning observed.
#' @param sections_drop Integer vector of sections to exclude. Default c(4, 11).
#' @return List with components:
#'   - occupancy_wide: tibble with year and binary (0/1) columns per section
#'   - occupancy_long: long-form tibble with year, section_name, occupied
#'   - summary: tibble with per-section metrics (years_occupied, pct_occupied,
#'     longest_absence, last_spawned)
#'   - n_occupied_ts: tibble with year, n_sites_occupied, pct_sites_occupied
compute_site_occupancy <- function(
    spawn_data,
    sections_drop = c(4L, 11L)
) {

  occ <- spawn_data |>
    filter(!section %in% sections_drop) |>
    mutate(occupied = as.integer(!is.na(spawn_index) & spawn_index > 0))

  # Long form
  occ_long <- occ |>
    select(year, section, section_name, occupied)

  # Wide form
  occ_wide <- occ_long |>
    select(year, section_name, occupied) |>
    pivot_wider(names_from = section_name, values_from = occupied) |>
    arrange(year)

  # Per-section summary
  site_summary <- occ_long |>
    group_by(section, section_name) |>
    summarise(
      first_year      = min(year),
      last_year       = max(year),
      n_years         = n(),
      years_occupied  = sum(occupied),
      pct_occupied    = 100 * years_occupied / n_years,
      last_spawned    = ifelse(any(occupied == 1), max(year[occupied == 1]), NA_integer_),
      .groups = "drop"
    ) |>
    # Compute longest consecutive absence
    left_join(
      occ_long |>
        group_by(section, section_name) |>
        arrange(year) |>
        summarise(
          longest_absence = compute_longest_run(occupied, target = 0L),
          .groups = "drop"
        ),
      by = c("section", "section_name")
    ) |>
    arrange(section)

  # Time series of number of occupied sites
  n_occupied_ts <- occ_long |>
    group_by(year) |>
    summarise(
      n_sites_occupied  = sum(occupied),
      n_sites_total     = n(),
      pct_sites_occupied = 100 * n_sites_occupied / n_sites_total,
      .groups = "drop"
    )

  list(
    occupancy_wide  = occ_wide,
    occupancy_long  = occ_long,
    summary         = site_summary,
    n_occupied_ts   = n_occupied_ts
  )
}


# ── Helper: longest consecutive run of a value ─────────────────────────────

#' Find the longest consecutive run of a target value in a vector
#'
#' @param x Integer or logical vector
#' @param target Value to look for (default 0)
#' @return Integer length of longest run
compute_longest_run <- function(x, target = 0L) {
  if (length(x) == 0) return(0L)

  runs <- rle(x)
  target_runs <- runs$lengths[runs$values == target]

  if (length(target_runs) == 0) return(0L)
  max(target_runs)
}
