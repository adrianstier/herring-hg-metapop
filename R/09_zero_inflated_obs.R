# ============================================================================
# 09_zero_inflated_obs.R — Zero-inflated / left-censored observation helpers
# stier-2027-herring-metapopulation
#
# The maintained data contract distinguishes zero-SHI site-years from true
# missing effort before data reach Stan. Zeros come in two flavors:
#
#   1. Surveyed-zero (totalrecords > 0, SHI == 0): The site WAS surveyed
#      and no spawning was detected. This is informative — it tells us
#      that latent biomass is below the detection threshold. In a formal
#      observation model, this is a LEFT-CENSORED observation:
#        Y_obs = log(SHI) is undefined, but we know SHI < threshold
#
#   2. Not-surveyed (totalrecords == 0): The site was NOT visited. We
#      have no information about whether herring spawned there. This is
#      TRUE missing data (NA).
#
# This script provides helper functions that create the observation
# matrices needed for left-censored observation models in Stan. The occupancy
# model (08_occupancy_model.R, site_occupancy.stan) uses the same distinction
# for binary occupied/not-occupied analysis.
#
# FUTURE INTEGRATION:
# ------------------
# The censored observation model would modify the Stan likelihood from:
#
#   Current (v1):
#     if (Y_obs[t,j] == 1)
#       Y[t,j] ~ normal(X[t,j] + log_q[q_idx[t]], sigma_obs);
#
#   Future (censored):
#     if (Y_status[t,j] == 1)   // observed positive SHI
#       Y[t,j] ~ normal(X[t,j] + log_q[q_idx[t]], sigma_obs);
#     else if (Y_status[t,j] == -1)  // surveyed-zero (left-censored)
#       target += normal_lcdf(log_threshold | X[t,j] + log_q[q_idx[t]], sigma_obs);
#     // Y_status == 0: not surveyed, skip entirely
#
# This properly accounts for the information in surveyed-zeros: the latent
# biomass is somewhere below the detection limit, not "missing."
#
# References:
#   - Conn et al. 2018. Ecol Monogr. (accounting for incomplete detection)
#   - Stan User Guide, Chapter on Censored Data
# ============================================================================

# Reader note:
# This file is the staging area for a future censored-observation extension.
# It matters because the continuous biomass models currently drop surveyed
# zeros on the log scale, while the occupancy path already treats those zeros
# as informative observations rather than missing effort.


# ── prepare_censored_data() ─────────────────────────────────────────────────
#' Create observation matrices distinguishing positive, censored, and missing
#'
#' Reads the raw legacy and newer DFO spawn survey data to recover survey
#' effort, then classifies each (year, site) cell into three categories:
#'
#'   - Observed positive: totalrecords > 0 AND SHI > 0 (Y_observed)
#'   - Left-censored:     totalrecords > 0 AND SHI == 0 (Y_censored)
#'   - Not surveyed:      totalrecords == 0 (Y_missing)
#'
#' @param spawn_clean List returned by clean_spawn(). Contains $wide (the
#'   log(SHI) matrix with NA for zeros) and $long.
#' @param path_legacy Path to legacy CSV with totalrecords column.
#' @param path_new Optional path to the newer DFO spawn CSV with
#'   `total_records`. When present, post-2015 survey effort is merged so
#'   surveyed zeros are not misclassified as missing.
#' @param sections_drop Integer vector of sections to exclude.
#' @return Named list:
#'   - Y_observed:  integer matrix (N_YEARS x N_SITES). 1 = observed positive
#'                  SHI, 0 = otherwise. Same as current Y_obs in Stan data.
#'   - Y_censored:  integer matrix (N_YEARS x N_SITES). 1 = surveyed-zero
#'                  (totalrecords > 0, SHI == 0), 0 = otherwise.
#'   - Y_missing:   integer matrix (N_YEARS x N_SITES). 1 = not surveyed
#'                  (totalrecords == 0), 0 = otherwise.
#'   - Y_status:    integer matrix (N_YEARS x N_SITES).
#'                  +1 = observed positive, -1 = left-censored, 0 = missing.
#'   - summary:     tibble with per-site counts of each category
#'   - coverage:    tibble with per-year survey coverage stats
#'
prepare_censored_data <- function(
    spawn_clean,
    path_legacy    = here::here("Data", "raw", "legacy-2019",
                                "HG_Spawn_Survey_1940_2015.csv"),
    path_new       = here::here("Data", "raw", "dfo-spawn",
                                "HG_spawn_index_by_section_1951_2025.csv"),
    sections_drop  = c(4L, 11L)
) {

  # ── Read legacy data to get totalrecords ──
  legacy_raw <- readr::read_csv(path_legacy, show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::rename(spawn_index = shi) |>
    dplyr::mutate(section = as.integer(section))

  # ── Filter and complete the grid ──
  survey_info <- legacy_raw |>
    dplyr::filter(
      !section %in% sections_drop,
      year >= YEAR_START,
      year <= YEAR_END
    ) |>
    dplyr::select(year, section, totalrecords, spawn_index)

  if (!is.null(path_new) && file.exists(path_new)) {
    new_raw <- readr::read_csv(path_new, show_col_types = FALSE) |>
      janitor::clean_names()

    if ("spawn_index_tonnes" %in% names(new_raw)) {
      new_raw <- new_raw |>
        dplyr::rename(spawn_index = spawn_index_tonnes)
    } else if ("spawn_index_t" %in% names(new_raw)) {
      new_raw <- new_raw |>
        dplyr::rename(spawn_index = spawn_index_t)
    }

    if ("total_records" %in% names(new_raw)) {
      new_raw <- new_raw |>
        dplyr::rename(totalrecords = total_records)
    }

    new_raw <- new_raw |>
      dplyr::mutate(section = as.integer(section)) |>
      dplyr::filter(
        !section %in% sections_drop,
        year >= YEAR_START,
        year <= YEAR_END
      ) |>
      dplyr::select(year, section, totalrecords, spawn_index)

    survey_info <- dplyr::bind_rows(
      new_raw,
      dplyr::anti_join(survey_info, new_raw, by = c("year", "section"))
    )
  }

  complete_grid <- tidyr::expand_grid(
    year    = seq(YEAR_START, YEAR_END),
    section = SECTIONS_KEEP
  )

  survey_info <- complete_grid |>
    dplyr::left_join(survey_info, by = c("year", "section")) |>
    dplyr::mutate(
      totalrecords = tidyr::replace_na(totalrecords, 0L),
      spawn_index  = tidyr::replace_na(spawn_index, 0)
    )

  # ── Classify each cell ──
  survey_info <- survey_info |>
    dplyr::mutate(
      status = dplyr::case_when(
        totalrecords > 0 & spawn_index > 0  ~  1L,  # observed positive
        totalrecords > 0 & spawn_index == 0 ~ -1L,  # surveyed-zero (censored)
        totalrecords == 0                   ~  0L,   # not surveyed (missing)
        TRUE                                ~  0L
      )
    )

  # ── Add section names ──
  section_lookup <- SECTIONS_ALL |>
    dplyr::filter(section %in% SECTIONS_KEEP) |>
    dplyr::select(section, section_name)

  survey_info <- survey_info |>
    dplyr::left_join(section_lookup, by = "section")

  # ── Pivot to matrices ──
  status_wide <- survey_info |>
    dplyr::select(year, section_name, status) |>
    tidyr::pivot_wider(names_from = section_name, values_from = status) |>
    dplyr::arrange(year)

  status_mat <- status_wide |>
    dplyr::select(dplyr::all_of(SITE_NAMES)) |>
    as.matrix()

  rownames(status_mat) <- status_wide$year

  # Derived binary matrices
  Y_observed <- (status_mat == 1L) * 1L
  Y_censored <- (status_mat == -1L) * 1L
  Y_missing  <- (status_mat == 0L) * 1L

  # ── Dimension checks ──
  stopifnot(
    "Row count must equal N_YEARS" = nrow(status_mat) == N_YEARS,
    "Col count must equal N_SITES" = ncol(status_mat) == N_SITES,
    "Status categories must be exhaustive" =
      all((Y_observed + Y_censored + Y_missing) == 1)
  )

  # ── Per-site summary ──
  site_summary <- survey_info |>
    dplyr::group_by(section, section_name) |>
    dplyr::summarise(
      n_observed = sum(status == 1L),
      n_censored = sum(status == -1L),
      n_missing  = sum(status == 0L),
      n_total    = dplyr::n(),
      pct_surveyed = 100 * (n_observed + n_censored) / n_total,
      .groups = "drop"
    ) |>
    dplyr::arrange(section)

  # ── Per-year coverage ──
  year_coverage <- survey_info |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_sites_surveyed  = sum(status != 0L),
      n_sites_spawning  = sum(status == 1L),
      n_sites_zero      = sum(status == -1L),
      n_sites_missing   = sum(status == 0L),
      pct_surveyed      = 100 * n_sites_surveyed / N_SITES,
      .groups = "drop"
    )

  # ── Print summary ──
  cat("Censored data classification:\n")
  cat("  Observed positive (SHI > 0):", sum(Y_observed), "\n")
  cat("  Left-censored (surveyed, SHI = 0):", sum(Y_censored), "\n")
  cat("  Not surveyed (totalrecords = 0):", sum(Y_missing), "\n")
  cat("  Total cells:", length(status_mat), "\n")
  cat("\nPer-site survey coverage:\n")
  print(site_summary |> dplyr::select(section_name, n_observed, n_censored,
                                       n_missing, pct_surveyed))

  list(
    Y_observed = Y_observed,
    Y_censored = Y_censored,
    Y_missing  = Y_missing,
    Y_status   = status_mat,
    summary    = site_summary,
    coverage   = year_coverage
  )
}
