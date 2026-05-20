# ============================================================================
# 11_ews_06_sensitivity_grid.R — EWS sensitivity grid
# stier-2027-herring-metapopulation
#
# Task 4.2: For every (indicator × layer × unit × window × detrend ×
# estimator × leave_out_section) cell, recompute the indicator trajectory
# from ews_input_layers.rds (so leave-one-out can drop a section) and run
# ews_kendall_surrogate(n_surr = 300L); emit tau, p_value, robust flag.
#
# Reads:  Output/diagnostics/ews_input_layers.rds
# Writes: Output/diagnostics/ews_sensitivity_grid.csv
#
# SIMPLIFICATION CAVEAT (mirrors Task 4.1):
#   Phase-3 collapsed to summary CSVs, but this script recomputes indicator
#   trajectories directly from ews_input_layers.rds to support leave-one-out.
#   For the latent layer we summarise across draws by MEDIAN per window-year
#   and run one Kendall tau per cell (point estimate). tau is a point estimate
#   per cell; p_value is from the AR(1)-surrogate ensemble (n_surr = 300).
#   Per-draw Kendall credible intervals would require per-draw output — out of
#   scope here. See Task 4.1 header for same caveat.
#
#   AR1 latent path: We collapse 2000 draws to the posterior-median aggregate
#   time series FIRST (median across draws per year, then row-sum across
#   sections), then call ews_generic_battery() once on that series — the same
#   median-first approach used for all spatial indicators. Running 2000
#   generic_ews calls per cell would take ~52 h (0.7 s × 2000 × 132 cells)
#   and is infeasible. The median-first approach is consistent with the stated
#   "median per window across draws" simplification caveat.
#
# Indicators covered:
#   phi, eta, ar1, eig_share, mar1_eigen, cv_ratio, morans_i, spatial_var
#
# Design space:
#   layers          : observed, latent
#   units           : all11, core9
#   windows         : 10, 15, 20 (for spatial/eigen indicators)
#                     win_frac ∈ {0.33, 0.5} for ar1 only
#   detrend         : gaussian, first-diff, none — ONLY for ar1; NA for others
#   estimator       : "default" for all (single-estimator functions; do NOT
#                     modify R/11_early_warning.R)
#   leave_out       : "none" ∪ each section name for the chosen unit
#
# Robust flag (group-level):
#   For each (indicator, layer, unit, window) group: robust == TRUE if
#   sign(tau) is consistent AND p_value < 0.05 in >= 80% of leave_out rows
#   (and across detrend for ar1). Attached to every row in the group.
#
# Performance:
#   ~1188 cells × 300 surrogates ≈ 5-15 min depending on mar1_eigen (MARSS).
#   Latent ar1 cells: posterior-median aggregate computed once via apply()
#   before calling ews_generic_battery once per cell (not 2000× per cell).
#   Progress is cat()-printed every ~100 cells so the user can see it's alive.
#   Observed NA pre-imputed per-section (zoo::na.approx) to avoid MARSS path
#   for observed windows (mirrors 11_ews_03_covariance_eigen.R §PERFORMANCE).
#   Each cell is wrapped in tryCatch so one bad cell cannot abort the grid.
#
# References: Dakos et al. 2008 PNAS 105:14308-14312; 2012 PLoS ONE 7:e41010
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(zoo)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

cat("=== Task 4.2: EWS sensitivity grid (window × detrend × unit × leave-out × indicator) ===\n")
cat(format(Sys.time()), "\n\n")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
N_SURR      <- 300L
SEED        <- 20260519L

INDICATORS_SPATIAL <- c("phi", "eta", "eig_share", "mar1_eigen",
                         "cv_ratio", "morans_i", "spatial_var")
INDICATOR_AR1      <- "ar1"
ALL_INDICATORS     <- c(INDICATORS_SPATIAL, INDICATOR_AR1)

WINDOWS_SPATIAL    <- c(10L, 15L, 20L)
WIN_FRACS_AR1      <- c(0.33, 0.5)
DETRENDS_AR1       <- c("gaussian", "first-diff", "none")
LAYERS             <- c("observed", "latent")
UNITS              <- c("all11", "core9")

# ---------------------------------------------------------------------------
# 1. Read input layers (once)
# ---------------------------------------------------------------------------
rds_path <- file.path(diag_dir, "ews_input_layers.rds")
if (!file.exists(rds_path)) {
  stop("ews_input_layers.rds not found at: ", rds_path,
       "\nRun Code/11_ews_00_data_layers.R first.")
}

cat("Reading ews_input_layers.rds ... ")
L <- readRDS(rds_path)
cat("done.\n")
cat("Layer names:", paste(names(L), collapse = ", "), "\n\n")

# ---------------------------------------------------------------------------
# 2. Utility: build year×section matrix for one (layer_name, unit_name, draw)
#    Returns ordered matrix + year vector + section names + coord matrix.
# ---------------------------------------------------------------------------

build_coords_lookup <- function(obs_df) {
  # Use 'site' (character name) as the key, not numeric 'section'
  obs_df |>
    dplyr::filter(is.finite(longitude) & is.finite(latitude)) |>
    dplyr::group_by(site) |>
    dplyr::slice(1L) |>
    dplyr::ungroup() |>
    dplyr::select(site, longitude, latitude) |>
    dplyr::arrange(site)
}

impute_na_by_section <- function(obs_df) {
  # Use 'site' (character name) as the grouping key (consistent with pivot_wider)
  obs_df |>
    dplyr::arrange(site, year) |>
    dplyr::group_by(site) |>
    dplyr::mutate(
      value = tryCatch(
        as.numeric(zoo::na.approx(value, x = year, rule = 2, na.rm = FALSE)),
        error = function(e) value
      )
    ) |>
    dplyr::ungroup()
}

# Precompute per (layer, unit): the full year×section matrix list
# For observed: one matrix; for latent: a list keyed by draw (or pre-collapsed
# to per-draw). Since latent has 2000 draws, we store as a 3-D array to avoid
# list overhead. But memory: 75yr × 11secs × 2000 draws × 8 bytes ≈ 13 MB.
# That is fine. We build it once.

precompute_layer_unit <- function(layer_name, unit_name) {
  key     <- paste0(layer_name, "_", unit_name)
  raw     <- L[[key]]
  is_lat  <- (layer_name == "latent")

  # Observed reference for section names & coords
  obs_key  <- paste0("observed_", unit_name)
  obs_raw  <- L[[obs_key]]

  # Sections sorted (consistent order for matrix cols)
  sections <- sort(unique(obs_raw$site))
  n_sec    <- length(sections)

  # Coords matrix (lon, lat) aligned to sections (site names as row labels)
  coords_lu  <- build_coords_lookup(obs_raw)   # already uses 'site' as key
  cmat       <- dplyr::tibble(site = sections) |>
    dplyr::left_join(coords_lu, by = "site")
  coords_mat <- as.matrix(dplyr::select(cmat, longitude, latitude))
  rownames(coords_mat) <- sections

  # Years
  all_years <- sort(unique(obs_raw$year))

  if (!is_lat) {
    # Observed: impute NA, then build one matrix
    obs_imp <- impute_na_by_section(obs_raw)
    wide <- obs_imp |>
      dplyr::select(year, site, value) |>
      tidyr::pivot_wider(names_from = site, values_from = value,
                         names_sort = TRUE) |>
      dplyr::arrange(year)
    # Ensure all sections present
    for (s in sections) {
      if (!s %in% names(wide)) wide[[s]] <- NA_real_
    }
    mat <- as.matrix(wide[, sections, drop = FALSE])
    rownames(mat) <- as.character(wide$year)
    list(
      is_latent  = FALSE,
      sections   = sections,
      years      = all_years,
      coords_mat = coords_mat,
      # observed: wrap in list of length 1 (draw=0) for uniform interface
      draws      = 0L,
      mat_list   = list(`0` = mat)
    )
  } else {
    # Latent: build 3D array [year × section × draw]
    # Use a fast pivot of the entire latent df in one pass (avoid 2000 filter calls)
    draws <- sort(unique(raw$draw))
    n_yr  <- length(all_years)
    n_dr  <- length(draws)
    arr   <- array(NA_real_, dim = c(n_yr, n_sec, n_dr),
                   dimnames = list(as.character(all_years), sections, as.character(draws)))

    # Pivot all draws at once: wide df has cols year, draw, <site1>, <site2>, ...
    wide_all <- raw |>
      dplyr::select(draw, year, site, value) |>
      tidyr::pivot_wider(names_from = site, values_from = value, names_sort = TRUE) |>
      dplyr::arrange(draw, year)
    for (s in sections) {
      if (!s %in% names(wide_all)) wide_all[[s]] <- NA_real_
    }
    yr_vec  <- wide_all$year
    dr_vec  <- wide_all$draw
    mat_all <- as.matrix(wide_all[, sections, drop = FALSE])

    for (di in seq_along(draws)) {
      dk      <- draws[di]
      row_idx <- which(dr_vec == dk)
      yr_idx  <- match(as.character(yr_vec[row_idx]), as.character(all_years))
      arr[yr_idx, , di] <- mat_all[row_idx, , drop = FALSE]
    }
    list(
      is_latent  = TRUE,
      sections   = sections,
      years      = all_years,
      coords_mat = coords_mat,
      draws      = draws,
      arr        = arr    # [n_yr × n_sec × n_draw]
    )
  }
}

# ---------------------------------------------------------------------------
# 3. Indicator computation helpers
#    All return a numeric vector (trajectory) over rolling windows.
#    Input: cache object (from precompute_layer_unit), leave_out site name or "none",
#           window parameter.
# ---------------------------------------------------------------------------

# Helper: slice mat rows for a window, drop leave_out column if specified
slice_window <- function(mat_full, year_vec, yr_s, yr_e, sections_all,
                          leave_out_site) {
  row_idx <- which(year_vec >= yr_s & year_vec <= yr_e)
  if (length(row_idx) < 2L) return(NULL)
  W <- mat_full[row_idx, , drop = FALSE]
  if (leave_out_site != "none") {
    # Drop that section's column
    keep_cols <- colnames(W) != leave_out_site
    if (!any(keep_cols)) return(NULL)  # shouldn't happen
    W <- W[, keep_cols, drop = FALSE]
  }
  W
}

# Memo cache: stores pre-collapsed median matrices keyed by "cache_key:leave_out"
# Reused across indicator × window cells sharing the same (layer, unit, leave_out).
# 22 keys × [75 × ≤11] matrix — trivially small.
.med_mat_cache <- new.env(hash = TRUE, parent = emptyenv())

get_latent_med_mat <- function(arr, col_keep, sec_names, cache_key, leave_out_site) {
  memo_key <- paste0(cache_key, ":", leave_out_site)
  if (exists(memo_key, envir = .med_mat_cache, inherits = FALSE)) {
    return(get(memo_key, envir = .med_mat_cache, inherits = FALSE))
  }
  # Compute once and store
  m <- apply(arr[, col_keep, , drop = FALSE], c(1, 2), stats::median, na.rm = TRUE)
  if (!is.matrix(m)) m <- matrix(m, ncol = 1)
  colnames(m) <- sec_names[col_keep]
  assign(memo_key, m, envir = .med_mat_cache)
  m
}

# Compute one spatial/eigen indicator trajectory for (cache, leave_out, window_len, ind)
# Returns numeric vector of length = number of windows (rolling window midpoints)
compute_traj_spatial <- function(cache, cache_key, leave_out_site, window_len, ind) {
  sections <- cache$sections
  if (leave_out_site != "none") sections <- sections[sections != leave_out_site]
  if (length(sections) < 2L) return(rep(NA_real_, 0L))

  years     <- cache$years
  n_yr      <- length(years)
  starts    <- years[seq_len(max(0L, n_yr - window_len + 1L))]
  n_win     <- length(starts)
  if (n_win == 0L) return(numeric(0))

  # Precompute coords for remaining sections
  coords_sub <- cache$coords_mat[sections, , drop = FALSE]

  if (!cache$is_latent) {
    # Observed: one matrix
    mat_full  <- cache$mat_list[["0"]]
    year_vec  <- as.numeric(rownames(mat_full))
    # Keep only relevant columns (after leave-out)
    col_keep  <- colnames(mat_full) %in% sections
    mat_full  <- mat_full[, col_keep, drop = FALSE]

    out <- vapply(seq_len(n_win), function(si) {
      yr_s <- starts[si]
      yr_e <- yr_s + window_len - 1L
      row_idx <- which(year_vec >= yr_s & year_vec <= yr_e)
      if (length(row_idx) < 2L) return(NA_real_)
      W <- mat_full[row_idx, , drop = FALSE]
      compute_one_indicator(W, coords_sub, ind)
    }, numeric(1L))

  } else {
    # Latent: collapse draws to posterior-MEDIAN matrix first, then treat as
    # observed (one indicator call per window).  Running 2000 indicator calls
    # per window × ~56 windows × 132 latent cells is infeasible; the
    # median-first approach is consistent with the stated simplification
    # caveat and with the ar1 latent path.
    arr       <- cache$arr   # [n_yr × n_sec × n_draw]
    sec_names <- dimnames(arr)[[2]]
    col_keep  <- sec_names %in% sections

    # Use memoised median matrix (shared across indicator × window cells
    # with the same cache_key and leave_out_site, computed only once).
    med_mat  <- get_latent_med_mat(arr, col_keep, sec_names,
                                   cache_key, leave_out_site)
    year_vec <- as.numeric(dimnames(arr)[[1]])

    out <- vapply(seq_len(n_win), function(si) {
      yr_s <- starts[si]
      yr_e <- yr_s + window_len - 1L
      row_idx <- which(year_vec >= yr_s & year_vec <= yr_e)
      if (length(row_idx) < 2L) return(NA_real_)
      W <- med_mat[row_idx, , drop = FALSE]
      compute_one_indicator(W, coords_sub, ind)
    }, numeric(1L))
  }

  out
}

# Single-window indicator
compute_one_indicator <- function(W, coords_sub, ind) {
  tryCatch({
    switch(ind,
      phi        = ews_synchrony_phi(W),
      eta        = ews_synchrony_eta(W),
      eig_share  = {
        r <- ews_cov_eigen(W)
        if (is.list(r)) r$eig_share else NA_real_
      },
      mar1_eigen = ews_mar1_eigen(W),
      cv_ratio   = {
        n_sec  <- ncol(W)
        n_yr   <- nrow(W)
        sec_cvs <- vapply(seq_len(n_sec), function(j) {
          v <- W[, j]; v <- v[is.finite(v)]
          if (length(v) < 3L) return(NA_real_)
          m <- mean(v)
          if (!is.finite(m) || m == 0) return(NA_real_)
          stats::sd(v) / m
        }, numeric(1L))
        mean_sec_cv <- if (any(is.finite(sec_cvs))) mean(sec_cvs, na.rm = TRUE) else NA_real_
        agg <- rowSums(W, na.rm = TRUE)
        agg_v <- agg[is.finite(agg)]
        agg_cv <- if (length(agg_v) < 3L) NA_real_ else {
          m <- mean(agg_v)
          if (!is.finite(m) || m == 0) NA_real_ else stats::sd(agg_v) / m
        }
        if (is.finite(mean_sec_cv) && is.finite(agg_cv) && agg_cv != 0)
          mean_sec_cv / agg_cv
        else NA_real_
      },
      morans_i   = {
        n_yr <- nrow(W)
        mi_yr <- vapply(seq_len(n_yr),
                        function(i) ews_morans_i(W[i, ], coords_sub),
                        numeric(1L))
        if (any(is.finite(mi_yr))) mean(mi_yr, na.rm = TRUE) else NA_real_
      },
      spatial_var = {
        n_yr <- nrow(W)
        sv_yr <- vapply(seq_len(n_yr),
                        function(i) ews_spatial_variance(W[i, ]),
                        numeric(1L))
        if (any(is.finite(sv_yr))) mean(sv_yr, na.rm = TRUE) else NA_real_
      },
      NA_real_
    )
  }, error = function(e) NA_real_)
}

# Compute ar1 trajectory for one cell (uses aggregate sum across sections)
compute_traj_ar1 <- function(cache, leave_out_site, win_frac, detrend) {
  sections <- cache$sections
  if (leave_out_site != "none") sections <- sections[sections != leave_out_site]
  if (length(sections) < 1L) return(numeric(0))

  if (!cache$is_latent) {
    mat_full <- cache$mat_list[["0"]]
    col_keep <- colnames(mat_full) %in% sections
    mat_sub  <- mat_full[, col_keep, drop = FALSE]
    agg      <- rowSums(mat_sub, na.rm = TRUE)
    agg[agg == 0] <- NA_real_   # treat zero-aggregate years as NA
    r <- ews_generic_battery(agg, win_frac = win_frac, detrend = detrend)
    if (nrow(r) == 0L) return(numeric(0))
    r$ar1
  } else {
    arr       <- cache$arr
    sec_names <- dimnames(arr)[[2]]
    col_keep  <- sec_names %in% sections

    # Summarise latent draws to posterior-MEDIAN aggregate time series FIRST,
    # then run ews_generic_battery once on that series (consistent with the
    # spatial indicator path which also collapses draws to a per-window median
    # before the Kendall test).  Running 2000 generic_ews calls per cell is
    # infeasible (~0.7 s each × 2000 × 132 latent-ar1 cells ≈ 52 h).
    #
    # arr is [n_yr × n_sec × n_draw]; apply() over draw dimension gives
    # [n_yr × n_sec] matrix of medians, then row-sum to aggregate.
    med_mat <- apply(arr[, col_keep, , drop = FALSE], c(1, 2), stats::median,
                     na.rm = TRUE)   # [n_yr × n_sec_sub]
    agg <- rowSums(med_mat, na.rm = TRUE)
    agg[agg == 0] <- NA_real_
    r <- ews_generic_battery(agg, win_frac = win_frac, detrend = detrend)
    if (nrow(r) == 0L) return(numeric(0))
    r$ar1
  }
}

# ---------------------------------------------------------------------------
# 4. Build the cell grid (tractable factorial)
# ---------------------------------------------------------------------------
cat("Building cell grid...\n")

# Section names by unit
all11_secs <- sort(unique(L$observed_all11$site))
core9_secs <- sort(unique(L$observed_core9$site))

leave_outs_all11 <- c("none", all11_secs)  # 12 variants
leave_outs_core9 <- c("none", core9_secs)  # 10 variants

# Spatial/eigen indicators: no detrend dimension
grid_spatial <- tidyr::expand_grid(
  indicator  = INDICATORS_SPATIAL,
  layer      = LAYERS,
  unit       = UNITS,
  window     = as.integer(WINDOWS_SPATIAL),
  detrend    = NA_character_,
  estimator  = "default"
) |>
  dplyr::mutate(
    leave_out_vec = dplyr::case_when(
      unit == "all11" ~ list(leave_outs_all11),
      unit == "core9" ~ list(leave_outs_core9)
    )
  ) |>
  tidyr::unnest(leave_out_vec) |>
  dplyr::rename(leave_out = leave_out_vec)

# ar1 indicator: detrend × win_frac dimensions
grid_ar1 <- tidyr::expand_grid(
  indicator  = INDICATOR_AR1,
  layer      = LAYERS,
  unit       = UNITS,
  window     = WIN_FRACS_AR1,   # win_frac stored in 'window' column
  detrend    = DETRENDS_AR1,
  estimator  = "default"
) |>
  dplyr::mutate(
    leave_out_vec = dplyr::case_when(
      unit == "all11" ~ list(leave_outs_all11),
      unit == "core9" ~ list(leave_outs_core9)
    )
  ) |>
  tidyr::unnest(leave_out_vec) |>
  dplyr::rename(leave_out = leave_out_vec)

grid_all <- dplyr::bind_rows(grid_spatial, grid_ar1) |>
  dplyr::arrange(indicator, layer, unit, window, detrend, leave_out)

cat(sprintf("Total cells in grid: %d\n", nrow(grid_all)))
cat(sprintf("  Spatial/eigen cells: %d\n", nrow(grid_spatial)))
cat(sprintf("  AR1 cells:           %d\n", nrow(grid_ar1)))
cat("Unique indicators:", paste(ALL_INDICATORS, collapse = ", "), "\n\n")

# ---------------------------------------------------------------------------
# 5. Precompute layer-unit caches (4 combinations)
# ---------------------------------------------------------------------------
cat("Precomputing layer-unit caches (may take ~1-2 min for latent arrays)...\n")
t_cache_start <- proc.time()

caches <- list()
for (ly in LAYERS) {
  for (un in UNITS) {
    key <- paste0(ly, "_", un)
    cat(sprintf("  Cache: %s ... ", key))
    caches[[key]] <- precompute_layer_unit(ly, un)
    cat("done.\n")
  }
}
t_cache_end <- proc.time()
cat(sprintf("Cache build: %.1f s\n\n", (t_cache_end - t_cache_start)["elapsed"]))

# ---------------------------------------------------------------------------
# 6. Main grid loop
# ---------------------------------------------------------------------------
cat("Running grid cells...\n")
t_grid_start <- proc.time()

n_cells     <- nrow(grid_all)
results_list <- vector("list", n_cells)
PROGRESS_EVERY <- 100L

for (ci in seq_len(n_cells)) {
  if (ci %% PROGRESS_EVERY == 0L || ci == 1L || ci == n_cells) {
    elapsed <- (proc.time() - t_grid_start)["elapsed"]
    cat(sprintf("  Cell %d / %d  [%.0f s elapsed]\n", ci, n_cells, elapsed))
  }

  row_i <- grid_all[ci, ]
  ind       <- row_i$indicator
  ly        <- row_i$layer
  un        <- row_i$unit
  win_val   <- row_i$window
  det       <- row_i$detrend
  lo_site   <- row_i$leave_out

  cache_key <- paste0(ly, "_", un)
  cache_i   <- caches[[cache_key]]

  # Compute trajectory for this cell
  traj <- tryCatch({
    if (ind == "ar1") {
      compute_traj_ar1(cache_i, lo_site, win_frac = win_val, detrend = det)
    } else {
      compute_traj_spatial(cache_i, cache_key, lo_site,
                           window_len = as.integer(win_val), ind = ind)
    }
  }, error = function(e) {
    cat(sprintf("    ERROR in cell %d (%s|%s|%s|win=%s|%s|lo=%s): %s\n",
                ci, ind, ly, un, win_val, ifelse(is.na(det), "-", det),
                lo_site, conditionMessage(e)))
    numeric(0)
  })

  # Run Kendall surrogate
  surr <- tryCatch(
    ews_kendall_surrogate(traj, n_surr = N_SURR, seed = SEED),
    error = function(e) list(tau = NA_real_, p_value = NA_real_, n = 0L)
  )

  results_list[[ci]] <- tibble::tibble(
    indicator = ind,
    layer     = ly,
    unit      = un,
    window    = win_val,
    detrend   = if (ind == "ar1") det else NA_character_,
    estimator = "default",
    leave_out = lo_site,
    tau       = surr$tau,
    p_value   = surr$p_value,
    n         = as.integer(surr$n)
  )
}

t_grid_end <- proc.time()
cat(sprintf("\nGrid loop complete: %.1f s\n", (t_grid_end - t_grid_start)["elapsed"]))

# ---------------------------------------------------------------------------
# 7. Bind results and compute robust flag
# ---------------------------------------------------------------------------
cat("Computing robust flag...\n")

grid_result <- dplyr::bind_rows(results_list)

# Robust flag: per (indicator, layer, unit, window) group
# Among all leave_out rows in that group (across detrend if applicable):
#   - consistent sign (all finite tau have the same sign)
#   - p_value < 0.05 in >= 80% of rows with finite tau/p_value
ROBUST_FRAC <- 0.80

grid_result <- grid_result |>
  dplyr::group_by(indicator, layer, unit, window) |>
  dplyr::mutate(
    robust = {
      fin <- is.finite(tau) & is.finite(p_value)
      if (sum(fin) == 0L) {
        FALSE
      } else {
        tau_fin  <- tau[fin]
        pval_fin <- p_value[fin]
        sign_ok  <- all(sign(tau_fin) == sign(tau_fin[1]))
        sig_frac <- mean(pval_fin < 0.05)
        sign_ok && sig_frac >= ROBUST_FRAC
      }
    }
  ) |>
  dplyr::ungroup()

# ---------------------------------------------------------------------------
# 8. Write output
# ---------------------------------------------------------------------------
out_path <- file.path(diag_dir, "ews_sensitivity_grid.csv")
readr::write_csv(grid_result, out_path)
cat(sprintf("\nWrote: %s\n", out_path))

# ---------------------------------------------------------------------------
# 9. Sanity summary
# ---------------------------------------------------------------------------
cat("\n=== Sanity summary ===\n")
cat(sprintf("Total cells:          %d\n", nrow(grid_result)))
cat("Cells per indicator:\n")
d_cnt <- grid_result |>
  dplyr::count(indicator) |>
  dplyr::arrange(dplyr::desc(n))
cat(paste0("  ", d_cnt$indicator, ": ", d_cnt$n, "\n", collapse = ""))

n_robust <- sum(grid_result$robust, na.rm = TRUE)
frac_rob <- mean(grid_result$robust, na.rm = TRUE)
cat(sprintf("\nFraction robust==TRUE: %.3f (%d / %d cells)\n",
            frac_rob, n_robust, nrow(grid_result)))

cat("\nRobust fraction by indicator:\n")
d_rob <- grid_result |>
  dplyr::group_by(indicator) |>
  dplyr::summarise(frac_robust = mean(robust, na.rm = TRUE), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(frac_robust))
cat(paste0("  ", d_rob$indicator, ": ", round(d_rob$frac_robust, 3), "\n", collapse = ""))

cat("\nTop robust groups (indicator/layer/unit/window with robust=TRUE):\n")
top_robust <- grid_result |>
  dplyr::filter(robust) |>
  dplyr::distinct(indicator, layer, unit, window) |>
  dplyr::arrange(indicator, layer, unit, window)
if (nrow(top_robust) == 0L) {
  cat("  (none — no robust group found)\n")
} else {
  print(as.data.frame(top_robust), row.names = FALSE)
}

cat(sprintf("\nTotal runtime (including cache build): %.1f s\n",
            (proc.time() - t_cache_start)["elapsed"]))
cat("\nDone.\n")
