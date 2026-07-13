# ============================================================================
# 11_ews_03_covariance_eigen.R — Tier-2 covariance leading-EOF / MAR(1) EWS
# stier-2027-herring-metapopulation
#
# Task 3.3: For each of 4 input layers × window_len ∈ {10, 15, 20}, compute the
# covariance eigenvalue and MAR(1) dominant eigenvalue EWS indicators on the
# rolling year×section matrix.
#
# Indicators per (layer, unit, window_len, window_mid):
#   lambda_max  = ews_cov_eigen(W)$lambda_max   (leading covariance eigenvalue)
#   eig_share   = ews_cov_eigen(W)$eig_share    (fraction of variance on EOF1)
#   mar1_eigen  = ews_mar1_eigen(W)             (spectral radius of MAR(1) B)
#
# Spec §4.1:
#   latent   -> median + q05 (_lo) + q95 (_hi) across draws per window_mid
#   observed -> point, lo == hi == point
#
# Spec §8: R/11 functions return NA on degenerate; propagate, never error.
# R/11_early_warning.R is NOT modified by this task.
#
# Performance — observed NA pre-imputation (§PERFORMANCE):
#   Observed biomass has NA for zero-ambiguity years. Without imputation,
#   ews_mar1_eigen falls into the MARSS path (~2-10 s/window = 30+ min total).
#   We pre-impute observed NA with per-section linear interpolation
#   (zoo::na.approx, rule=2) before building any window matrices. Sections
#   that remain all-NA after interpolation stay NA; ews_cov_eigen and
#   ews_mar1_eigen handle column-wise NA via pairwise-complete / OLS-NA guards.
#   Latent values are finite by construction (ews_input_layers.rds contract);
#   no imputation is applied to the latent layer.
#
# Deterministic; firewall (no talk-usuk reads); does NOT modify R/11.
#
# Output: Output/diagnostics/ews_covariance_eigen.csv
# Schema: layer, unit, window_len, window_start, window_end, window_mid,
#         lambda_max, lambda_max_lo, lambda_max_hi,
#         eig_share,  eig_share_lo,  eig_share_hi,
#         mar1_eigen, mar1_eigen_lo, mar1_eigen_hi
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

cat("=== Task 3.3: Covariance leading-EOF / lambda_max + MAR(1) EWS ===\n")
cat(format(Sys.time()), "\n\n")

# ---------------------------------------------------------------------------
# 1. Read input layers
# ---------------------------------------------------------------------------
L <- readRDS(file.path(diag_dir, "ews_input_layers.rds"))
cat("Input layer names:", paste(names(L), collapse = ", "), "\n")

WINDOW_LENS <- c(10L, 15L, 20L)
INDICATORS  <- c("lambda_max", "eig_share", "mar1_eigen")

# ---------------------------------------------------------------------------
# 2. Observed NA pre-imputation
#    Per-section linear interpolation across years using zoo::na.approx.
#    rule=2 extends constant extrapolation to fill leading/trailing NA.
#    Sections that are all-NA stay all-NA after imputation; the EWS functions
#    handle those via pairwise-complete / column-filter guards.
#    Only applied to observed layers; latent is finite by construction.
# ---------------------------------------------------------------------------
impute_observed_na <- function(obs_df) {
  obs_df |>
    dplyr::arrange(section, year) |>
    dplyr::group_by(section) |>
    dplyr::mutate(
      value = tryCatch(
        as.numeric(zoo::na.approx(value, x = year, rule = 2, na.rm = FALSE)),
        error = function(e) value  # if zoo fails, keep original
      )
    ) |>
    dplyr::ungroup()
}

cat("Pre-imputing observed NA with per-section linear interpolation...\n")
L_obs_imputed <- list(
  observed_all11 = impute_observed_na(L$observed_all11),
  observed_core9 = impute_observed_na(L$observed_core9)
)

# Diagnostic: how much NA was removed?
for (nm in c("observed_all11", "observed_core9")) {
  n_before <- sum(is.na(L[[nm]]$value))
  n_after  <- sum(is.na(L_obs_imputed[[nm]]$value))
  cat(sprintf("  %s: NA before=%d, after=%d (imputed=%d)\n",
              nm, n_before, n_after, n_before - n_after))
}
cat("\n")

# ---------------------------------------------------------------------------
# 3. Per-window indicator helper
#    W = year×section matrix (rows = years, cols = sections, fixed order)
#    Returns named numeric vector of 3 indicators.
# ---------------------------------------------------------------------------
compute_window_indicators <- function(W) {
  eigen_res  <- ews_cov_eigen(W)
  lambda_max <- eigen_res$lambda_max
  eig_share  <- eigen_res$eig_share
  mar1_eigen <- ews_mar1_eigen(W)

  c(lambda_max = lambda_max,
    eig_share  = eig_share,
    mar1_eigen = mar1_eigen)
}

# ---------------------------------------------------------------------------
# 4. Process one (layer_name, unit_name) combination
#    lat_df : the data tibble for this combination (latent with $draw; observed without)
#    obs_df : the original observed tibble for this unit (used only for section ordering)
# ---------------------------------------------------------------------------
run_layer_unit <- function(layer_name, unit_name, lat_df, obs_df) {

  is_latent <- (layer_name == "latent")

  # Fixed section ordering (sorted) — consistent across all windows and draws
  sections_ordered <- sort(unique(obs_df$section))
  n_secs <- length(sections_ordered)

  # All calendar years in the layer
  all_years_sorted <- sort(unique(obs_df$year))

  # Draws
  if (is_latent) {
    draws <- sort(unique(lat_df$draw))
  } else {
    draws <- 0L  # pseudo-draw
  }

  cat(sprintf("  %s | %s: %d sections, %d years, %d draws\n",
              layer_name, unit_name, n_secs,
              length(all_years_sorted), length(draws)))

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
        draw_df <- lat_df  # observed (already imputed)
      }

      # Pivot to year×section matrix: rows=years, cols=sections (ordered)
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
        if (length(row_idx) < 3L) {
          # Need at least 3 rows for ews_cov_eigen; ews_mar1_eigen needs p+2
          win_rows[[si]] <- tibble::tibble(
            draw = dk, window_len = wlen,
            window_start = yr_s, window_end = yr_e, window_mid = yr_m,
            lambda_max = NA_real_, eig_share = NA_real_, mar1_eigen = NA_real_
          )
          next
        }

        W    <- mat_full[row_idx, , drop = FALSE]
        inds <- compute_window_indicators(W)
        win_rows[[si]] <- tibble::tibble(
          draw = dk, window_len = wlen,
          window_start = yr_s, window_end = yr_e, window_mid = yr_m,
          lambda_max = inds["lambda_max"],
          eig_share  = inds["eig_share"],
          mar1_eigen = inds["mar1_eigen"]
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
    # For observed (1 pseudo-draw): median == lo == hi == point
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
# 5. Run across all 4 layer × unit combinations
#    For observed: use the imputed data.  For latent: use the raw latent data.
# ---------------------------------------------------------------------------
layer_configs <- list(
  list(layer = "observed", unit = "all11",
       lat_key = NULL,             obs_key = "observed_all11",
       imputed_key = "observed_all11"),
  list(layer = "observed", unit = "core9",
       lat_key = NULL,             obs_key = "observed_core9",
       imputed_key = "observed_core9"),
  list(layer = "latent",   unit = "all11",
       lat_key = "latent_all11",   obs_key = "observed_all11",
       imputed_key = NULL),
  list(layer = "latent",   unit = "core9",
       lat_key = "latent_core9",   obs_key = "observed_core9",
       imputed_key = NULL)
)

t_start <- proc.time()

all_results <- vector("list", length(layer_configs))
n_latent_draws <- NA_integer_

for (i in seq_along(layer_configs)) {
  cfg <- layer_configs[[i]]
  cat(sprintf("\n[%d/%d] Processing: layer=%s, unit=%s\n",
              i, length(layer_configs), cfg$layer, cfg$unit))

  if (cfg$layer == "observed") {
    # Use pre-imputed observed data for both lat_df and obs_df
    data_df <- L_obs_imputed[[cfg$imputed_key]]
    res <- run_layer_unit(
      layer_name = cfg$layer,
      unit_name  = cfg$unit,
      lat_df     = data_df,
      obs_df     = L[[cfg$obs_key]]   # original for section ordering / year range
    )
  } else {
    # Latent: raw (finite by construction, no imputation needed)
    res <- run_layer_unit(
      layer_name = cfg$layer,
      unit_name  = cfg$unit,
      lat_df     = L[[cfg$lat_key]],
      obs_df     = L[[cfg$obs_key]]
    )
    if (is.na(n_latent_draws)) {
      n_latent_draws <- as.integer(dplyr::n_distinct(L[[cfg$lat_key]]$draw))
    }
  }

  all_results[[i]] <- res
}

final <- dplyr::bind_rows(all_results)

t_elapsed <- (proc.time() - t_start)[["elapsed"]]

# ---------------------------------------------------------------------------
# 6. Sanity checks
# ---------------------------------------------------------------------------
cat("\n=== Sanity checks ===\n")

# lambda_max > 0 for finite windows (variance is non-negative)
lm_finite <- final$lambda_max[is.finite(final$lambda_max)]
lm_pos    <- sum(lm_finite > 0)
cat(sprintf("lambda_max > 0: %d / %d finite (range: [%.4g, %.4g])\n",
            lm_pos, length(lm_finite),
            if (length(lm_finite) > 0) min(lm_finite) else NA,
            if (length(lm_finite) > 0) max(lm_finite) else NA))

# eig_share in [0, 1]
es_finite <- final$eig_share[is.finite(final$eig_share)]
es_ok     <- all(es_finite >= -1e-9 & es_finite <= 1 + 1e-9)
cat(sprintf("eig_share in [0,1]: %s (range: [%.4f, %.4f])\n",
            es_ok,
            if (length(es_finite) > 0) min(es_finite) else NA,
            if (length(es_finite) > 0) max(es_finite) else NA))

# Latent CI integrity: hi >= lo (or NA)
lat_chk    <- dplyr::filter(final, layer == "latent")
lm_ci_ok   <- all(lat_chk$lambda_max_hi >= lat_chk$lambda_max_lo |
                    is.na(lat_chk$lambda_max_lo), na.rm = TRUE)
any_lm_ci  <- any(lat_chk$lambda_max_hi > lat_chk$lambda_max_lo, na.rm = TRUE)
ci_integ   <- mean(lat_chk$lambda_max_hi > lat_chk$lambda_max_lo, na.rm = TRUE)
cat(sprintf("Latent: lambda_max_hi >= lo (or NA): %s\n", lm_ci_ok))
cat(sprintf("Latent: some rows have lambda_max_hi > lo: %s (frac=%.3f)\n",
            any_lm_ci, ci_integ))

# Observed: lo == mid == hi (point estimate)
obs_chk  <- dplyr::filter(final, layer == "observed")
obs_pt_ok <- all(obs_chk$lambda_max_lo == obs_chk$lambda_max |
                   is.na(obs_chk$lambda_max), na.rm = TRUE)
obs_pt_frac <- mean(obs_chk$lambda_max_lo == obs_chk$lambda_max,
                    na.rm = TRUE)
cat(sprintf("Observed: lambda_max_lo == lambda_max: %s (frac=%.3f)\n",
            obs_pt_ok, obs_pt_frac))

# mar1_eigen range
me_finite <- final$mar1_eigen[is.finite(final$mar1_eigen)]
cat(sprintf("mar1_eigen finite: %d rows (range: [%.4f, %.4f])\n",
            length(me_finite),
            if (length(me_finite) > 0) min(me_finite) else NA,
            if (length(me_finite) > 0) max(me_finite) else NA))

# NA counts
cat(sprintf("NA counts: lambda_max=%d, eig_share=%d, mar1_eigen=%d (of %d rows)\n",
            sum(is.na(final$lambda_max)),
            sum(is.na(final$eig_share)),
            sum(is.na(final$mar1_eigen)),
            nrow(final)))

# ---------------------------------------------------------------------------
# 7. Write CSV
# ---------------------------------------------------------------------------
out_path <- file.path(diag_dir, "ews_covariance_eigen.csv")
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
