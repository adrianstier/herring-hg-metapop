# ============================================================================
# 11_ews_02_spatial_synchrony.R — Tier-2 spatial/synchrony EWS battery
# stier-2027-herring-metapopulation
#
# Task 3.2: For each of 4 input layers × window_len ∈ {10, 15, 20}, compute
# the spatial/synchrony EWS battery on the rolling year×section matrix.
#
# Indicators per window:
#   phi         = ews_synchrony_phi(W)           Loreau & de Mazancourt 2008
#   eta         = ews_synchrony_eta(W)            Gross et al. 2014
#   spatial_var = mean over years of ews_spatial_variance(section_vals_yr)
#   spatial_skew= mean over years of ews_spatial_skew(section_vals_yr)
#   morans_i    = mean over years of ews_morans_i(section_vals_yr, coords)
#   cv_ratio    = (mean section CV in window) / (CV of annual aggregate in window)
#   n_occupied  = sections with value>0 in >=1 year of the window (observed-basis)
#
# Spec §4.1: latent -> median + q05 (_lo) + q95 (_hi) across draws.
#            observed -> point, lo == hi == point.
#
# Spec §8: degenerate windows yield NA from R/11 functions; propagate, never error.
#
# Deterministic; firewall (no talk-usuk reads); does NOT modify R/11_early_warning.R.
#
# Output: Output/diagnostics/ews_spatial_synchrony.csv
# Schema: layer, unit, window_len, window_start, window_end, window_mid,
#         phi, phi_lo, phi_hi, eta, eta_lo, eta_hi,
#         spatial_var, spatial_var_lo, spatial_var_hi,
#         spatial_skew, spatial_skew_lo, spatial_skew_hi,
#         morans_i, morans_i_lo, morans_i_hi,
#         cv_ratio, cv_ratio_lo, cv_ratio_hi,
#         n_occupied
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

cat("=== Task 3.2: Spatial/synchrony EWS ===\n")
cat(format(Sys.time()), "\n\n")

# ---------------------------------------------------------------------------
# 1. Read input layers
# ---------------------------------------------------------------------------
L <- readRDS(file.path(diag_dir, "ews_input_layers.rds"))
cat("Input layer names:", paste(names(L), collapse = ", "), "\n")

WINDOW_LENS <- c(10L, 15L, 20L)
INDICATORS  <- c("phi", "eta", "spatial_var", "spatial_skew", "morans_i", "cv_ratio")

# ---------------------------------------------------------------------------
# 2. Coord lookup: per section, first finite (longitude, latitude)
#    Built from the OBSERVED layer of each unit.
# ---------------------------------------------------------------------------
build_coords_lookup <- function(obs_df) {
  obs_df |>
    dplyr::filter(is.finite(longitude) & is.finite(latitude)) |>
    dplyr::group_by(section) |>
    dplyr::slice(1L) |>
    dplyr::ungroup() |>
    dplyr::select(section, longitude, latitude) |>
    dplyr::arrange(section)
}

# ---------------------------------------------------------------------------
# 3. Per-window indicator helper
#    W    = year×section matrix (rows = years in window, cols = sections, FIXED order)
#    yrs  = integer vector of years in window (same length as nrow(W))
#    coords_mat = cbind(lon, lat) aligned to cols of W
#    Returns named numeric vector of the 6 indicators.
# ---------------------------------------------------------------------------
compute_window_indicators <- function(W, coords_mat) {

  phi <- ews_synchrony_phi(W)
  eta <- ews_synchrony_eta(W)

  # Spatial variance and skew: mean over years of per-year within-section statistic
  n_years <- nrow(W)
  sv_yr   <- vapply(seq_len(n_years),
                    function(i) ews_spatial_variance(W[i, ]),
                    numeric(1L))
  sk_yr   <- vapply(seq_len(n_years),
                    function(i) ews_spatial_skew(W[i, ]),
                    numeric(1L))
  spatial_var  <- if (any(is.finite(sv_yr))) mean(sv_yr, na.rm = TRUE) else NA_real_
  spatial_skew <- if (any(is.finite(sk_yr))) mean(sk_yr, na.rm = TRUE) else NA_real_

  # Moran's I: mean over years of per-year within-section Moran's I
  mi_yr <- vapply(seq_len(n_years),
                  function(i) ews_morans_i(W[i, ], coords_mat),
                  numeric(1L))
  morans_i <- if (any(is.finite(mi_yr))) mean(mi_yr, na.rm = TRUE) else NA_real_

  # cv_ratio = (mean over sections of per-section within-window CV) /
  #            (CV of per-year aggregate biomass across the window)
  # CV = sd/mean; guard: mean==0 or <3 pts -> NA
  n_sec    <- ncol(W)
  sec_cvs  <- vapply(seq_len(n_sec), function(j) {
    v <- W[, j]
    v <- v[is.finite(v)]
    if (length(v) < 3L) return(NA_real_)
    m <- mean(v)
    if (!is.finite(m) || m == 0) return(NA_real_)
    stats::sd(v) / m
  }, numeric(1L))
  mean_sec_cv <- if (any(is.finite(sec_cvs))) mean(sec_cvs, na.rm = TRUE) else NA_real_

  agg <- rowSums(W, na.rm = TRUE)
  agg_cv <- {
    v <- agg[is.finite(agg)]
    if (length(v) < 3L) NA_real_
    else {
      m <- mean(v)
      if (!is.finite(m) || m == 0) NA_real_
      else stats::sd(v) / m
    }
  }
  cv_ratio <- if (is.finite(mean_sec_cv) && is.finite(agg_cv) && agg_cv != 0) {
    mean_sec_cv / agg_cv
  } else NA_real_

  c(phi = phi, eta = eta, spatial_var = spatial_var,
    spatial_skew = spatial_skew, morans_i = morans_i, cv_ratio = cv_ratio)
}

# ---------------------------------------------------------------------------
# 4. n_occupied helper (observed-basis, per window)
#    Returns number of sections with value > 0 in >= 1 year of the window.
#    Uses the observed data (no draws).
# ---------------------------------------------------------------------------
build_occupancy_lookup <- function(obs_df, sections_ordered, window_len_vec, all_years) {
  # For each window, count sections with value>0 in >=1 year of window
  # Precompute: per (year, section) whether value>0
  pos_df <- obs_df |>
    dplyr::mutate(pos = is.finite(value) & value > 0) |>
    dplyr::select(year, section, pos)

  # For each window_len and window_start, compute n_occupied
  results <- vector("list", length(window_len_vec))
  for (wi in seq_along(window_len_vec)) {
    wlen <- window_len_vec[wi]
    starts <- all_years[seq_len(max(0L, length(all_years) - wlen + 1L))]
    occ_rows <- vector("list", length(starts))
    for (si in seq_along(starts)) {
      yr_s <- starts[si]
      yr_e <- yr_s + wlen - 1L
      yr_m <- yr_s + (wlen - 1L) / 2
      # sections with any positive in window
      n_occ <- pos_df |>
        dplyr::filter(year >= yr_s & year <= yr_e & section %in% sections_ordered) |>
        dplyr::filter(pos) |>
        dplyr::summarise(n = dplyr::n_distinct(section)) |>
        dplyr::pull(n)
      occ_rows[[si]] <- tibble::tibble(
        window_len   = wlen,
        window_start = yr_s,
        window_end   = yr_e,
        window_mid   = yr_m,
        n_occupied   = as.integer(n_occ)
      )
    }
    results[[wi]] <- dplyr::bind_rows(occ_rows)
  }
  dplyr::bind_rows(results)
}

# ---------------------------------------------------------------------------
# 5. Process one (layer_name, unit_name) combination
# ---------------------------------------------------------------------------
run_layer_unit <- function(layer_name, unit_name, lat_df, obs_df) {
  # lat_df: the latent or observed layer tibble for this unit
  # obs_df: the observed layer tibble for this unit (always needed for coords/occupancy)

  is_latent <- (layer_name == "latent")

  # Fixed section ordering (sorted) — consistent across all windows and draws
  sections_ordered <- sort(unique(obs_df$section))
  n_secs <- length(sections_ordered)

  # Coordinate matrix aligned to sections_ordered
  coords_lu   <- build_coords_lookup(obs_df)
  coords_mat  <- coords_lu |>
    dplyr::filter(section %in% sections_ordered) |>
    dplyr::arrange(section)
  # Ensure all sections present (some may lack coords — fill with NA)
  if (nrow(coords_mat) < n_secs) {
    missing_secs <- setdiff(sections_ordered, coords_mat$section)
    coords_mat <- dplyr::bind_rows(
      coords_mat,
      tibble::tibble(section = missing_secs, longitude = NA_real_, latitude = NA_real_)
    ) |> dplyr::arrange(section)
  }
  coords_matrix <- as.matrix(dplyr::select(coords_mat, longitude, latitude))

  # All calendar years in the layer
  all_years_sorted <- sort(unique(obs_df$year))

  # Occupancy lookup (observed-basis, once per unit)
  occ_lu <- build_occupancy_lookup(obs_df, sections_ordered, WINDOW_LENS, all_years_sorted)

  # Draws
  if (is_latent) {
    draws <- sort(unique(lat_df$draw))
  } else {
    draws <- 0L  # pseudo-draw
  }

  cat(sprintf("  %s | %s: %d sections, %d years, %d draws\n",
              layer_name, unit_name, n_secs,
              length(all_years_sorted), length(draws)))

  # Precompute per-draw: section-ordered array [year × section] for each draw
  # For observed: just one matrix.
  # We iterate per window_len, per draw, per window_start.

  # --- Collect results: list indexed by window_len ---
  window_results <- vector("list", length(WINDOW_LENS))

  for (wi in seq_along(WINDOW_LENS)) {
    wlen   <- WINDOW_LENS[wi]
    starts <- all_years_sorted[seq_len(max(0L, length(all_years_sorted) - wlen + 1L))]

    if (length(starts) == 0L) {
      window_results[[wi]] <- NULL
      next
    }

    # draw_results: list over draws, each containing rows for all windows
    draw_results <- vector("list", length(draws))

    for (di in seq_along(draws)) {
      dk <- draws[di]

      # Build the full year×section matrix for this draw (all years)
      if (is_latent) {
        draw_df <- dplyr::filter(lat_df, draw == dk)
      } else {
        draw_df <- lat_df  # observed has no draw column
      }

      # Pivot to year×section matrix: rows=years, cols=sections (ordered)
      # Use tidyr::pivot_wider then reorder columns
      wide <- draw_df |>
        dplyr::select(year, section, value) |>
        tidyr::pivot_wider(names_from = section, values_from = value,
                           names_sort = TRUE) |>
        dplyr::arrange(year)

      # Ensure all sections present as columns (fill absent with NA)
      for (sc in as.character(sections_ordered)) {
        if (!sc %in% names(wide)) wide[[sc]] <- NA_real_
      }

      # Build ordered matrix: rows=years, cols=sections in sections_ordered order
      year_vec  <- wide$year
      mat_full  <- as.matrix(wide[, as.character(sections_ordered), drop = FALSE])
      rownames(mat_full) <- NULL; colnames(mat_full) <- NULL

      # Slide windows
      win_rows <- vector("list", length(starts))
      for (si in seq_along(starts)) {
        yr_s <- starts[si]
        yr_e <- yr_s + wlen - 1L
        yr_m <- yr_s + (wlen - 1L) / 2

        # Row indices for this window
        row_idx <- which(year_vec >= yr_s & year_vec <= yr_e)
        if (length(row_idx) < 2L) {
          win_rows[[si]] <- tibble::tibble(
            draw = dk, window_len = wlen,
            window_start = yr_s, window_end = yr_e, window_mid = yr_m,
            phi = NA_real_, eta = NA_real_,
            spatial_var = NA_real_, spatial_skew = NA_real_,
            morans_i = NA_real_, cv_ratio = NA_real_
          )
          next
        }

        W <- mat_full[row_idx, , drop = FALSE]
        inds <- compute_window_indicators(W, coords_matrix)
        win_rows[[si]] <- tibble::tibble(
          draw = dk, window_len = wlen,
          window_start = yr_s, window_end = yr_e, window_mid = yr_m,
          phi          = inds["phi"],
          eta          = inds["eta"],
          spatial_var  = inds["spatial_var"],
          spatial_skew = inds["spatial_skew"],
          morans_i     = inds["morans_i"],
          cv_ratio     = inds["cv_ratio"]
        )
      }
      draw_results[[di]] <- dplyr::bind_rows(win_rows)
    }  # end draws loop

    # Bind all draws for this window_len
    all_draws_df <- dplyr::bind_rows(draw_results)

    if (nrow(all_draws_df) == 0L) {
      window_results[[wi]] <- NULL
      next
    }

    # Summarise across draws: median + q05 + q95
    # For observed (1 pseudo-draw): median=lo=hi=point
    summarised <- all_draws_df |>
      dplyr::group_by(window_len, window_start, window_end, window_mid) |>
      dplyr::summarise(
        dplyr::across(
          dplyr::all_of(INDICATORS),
          list(
            med = ~ stats::median(.x, na.rm = TRUE),
            lo  = ~ stats::quantile(.x, 0.05, na.rm = TRUE, names = FALSE),
            hi  = ~ stats::quantile(.x, 0.95, na.rm = TRUE, names = FALSE)
          ),
          .names = "{.col}__{.fn}"
        ),
        .groups = "drop"
      )

    # Reshape to contract schema: ind, ind_lo, ind_hi
    result_cols <- list(
      window_len   = summarised$window_len,
      window_start = summarised$window_start,
      window_end   = summarised$window_end,
      window_mid   = summarised$window_mid
    )
    for (ind in INDICATORS) {
      result_cols[[ind]]                <- summarised[[paste0(ind, "__med")]]
      result_cols[[paste0(ind, "_lo")]] <- summarised[[paste0(ind, "__lo")]]
      result_cols[[paste0(ind, "_hi")]] <- summarised[[paste0(ind, "__hi")]]
    }
    result_tbl <- tibble::as_tibble(result_cols)

    # Join occupancy (observed-basis point estimate)
    result_tbl <- result_tbl |>
      dplyr::left_join(
        dplyr::select(occ_lu, window_len, window_start, n_occupied),
        by = c("window_len", "window_start")
      )

    window_results[[wi]] <- dplyr::bind_cols(
      tibble::tibble(layer = layer_name, unit = unit_name),
      result_tbl
    )

    cat(sprintf("    window_len=%d: %d windows, %d draws -> %d rows\n",
                wlen, length(starts), length(draws), nrow(result_tbl)))
  }  # end window_lens loop

  out <- dplyr::bind_rows(window_results)
  cat(sprintf("  Total rows for %s|%s: %d\n", layer_name, unit_name, nrow(out)))
  out
}

# ---------------------------------------------------------------------------
# 6. Run across all 4 layers
# ---------------------------------------------------------------------------
# Map: (layer, unit) -> latent tibble + obs tibble
layer_configs <- list(
  list(layer = "observed", unit = "all11",
       lat_key = "observed_all11", obs_key = "observed_all11"),
  list(layer = "observed", unit = "core9",
       lat_key = "observed_core9", obs_key = "observed_core9"),
  list(layer = "latent",   unit = "all11",
       lat_key = "latent_all11",   obs_key = "observed_all11"),
  list(layer = "latent",   unit = "core9",
       lat_key = "latent_core9",   obs_key = "observed_core9")
)

t_start <- proc.time()

all_results <- vector("list", length(layer_configs))
n_latent_draws <- NA_integer_

for (i in seq_along(layer_configs)) {
  cfg <- layer_configs[[i]]
  cat(sprintf("\n[%d/%d] Processing: layer=%s, unit=%s\n",
              i, length(layer_configs), cfg$layer, cfg$unit))

  res <- run_layer_unit(
    layer_name = cfg$layer,
    unit_name  = cfg$unit,
    lat_df     = L[[cfg$lat_key]],
    obs_df     = L[[cfg$obs_key]]
  )
  all_results[[i]] <- res

  if (cfg$layer == "latent" && is.na(n_latent_draws)) {
    n_latent_draws <- as.integer(dplyr::n_distinct(L[[cfg$lat_key]]$draw))
  }
}

final <- dplyr::bind_rows(all_results)

t_elapsed <- (proc.time() - t_start)[["elapsed"]]

# ---------------------------------------------------------------------------
# 7. Sanity checks
# ---------------------------------------------------------------------------
cat("\n=== Sanity checks ===\n")

lat_chk <- dplyr::filter(final, layer == "latent")
phi_lat_ok <- all(lat_chk$phi_hi >= lat_chk$phi_lo | is.na(lat_chk$phi_lo), na.rm = TRUE)
cat(sprintf("Latent: phi_hi >= phi_lo (or NA): %s\n", phi_lat_ok))

any_ci <- any(lat_chk$phi_hi > lat_chk$phi_lo, na.rm = TRUE)
cat(sprintf("Latent: some rows have phi_hi > phi_lo: %s\n", any_ci))

obs_chk   <- dplyr::filter(final, layer == "observed")
obs_phi_ok <- all(obs_chk$phi_lo == obs_chk$phi | is.na(obs_chk$phi), na.rm = TRUE)
cat(sprintf("Observed: phi_lo == phi == phi_hi: %s\n", obs_phi_ok))

ph_finite <- final$phi[is.finite(final$phi)]
phi_range_ok <- length(ph_finite) > 0 && all(ph_finite >= -1e-9 & ph_finite <= 1 + 1e-9)
cat(sprintf("phi in [0, 1]: %s (range: [%.4f, %.4f])\n",
            phi_range_ok,
            if (length(ph_finite) > 0) min(ph_finite) else NA,
            if (length(ph_finite) > 0) max(ph_finite) else NA))

nocc_ok <- all(final$n_occupied <= 11L, na.rm = TRUE)
cat(sprintf("n_occupied <= 11 (all11 max): %s (max=%d)\n",
            nocc_ok,
            max(final$n_occupied, na.rm = TRUE)))

# ---------------------------------------------------------------------------
# 8. Write CSV
# ---------------------------------------------------------------------------
out_path <- file.path(diag_dir, "ews_spatial_synchrony.csv")
readr::write_csv(final, out_path)

cat("\n=== DONE ===\n")
cat(sprintf("Rows written    : %d\n", nrow(final)))
cat(sprintf("Layers          : %s\n", paste(sort(unique(final$layer)), collapse = ", ")))
cat(sprintf("Units           : %s\n", paste(sort(unique(final$unit)), collapse = ", ")))
cat(sprintf("Window lens     : %s\n", paste(sort(unique(final$window_len)), collapse = ", ")))
cat(sprintf("Window_mid range: %.1f - %.1f\n",
            min(final$window_mid, na.rm = TRUE),
            max(final$window_mid, na.rm = TRUE)))
cat(sprintf("Latent draws    : %d\n", n_latent_draws))
cat(sprintf("Output          : %s\n", out_path))
cat(sprintf("Columns         : %s\n", paste(names(final), collapse = ", ")))
cat(sprintf("Runtime         : %.1f s\n", t_elapsed))
