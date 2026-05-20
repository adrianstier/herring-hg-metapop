# ============================================================================
# 11_ews_01_generic_aggregate.R — Tier-1 generic temporal EWS on aggregate biomass
# stier-2027-herring-metapopulation
#
# Task 3.1: For each of 4 input layers × {detrend × win_frac} grid, compute
# the generic temporal EWS battery on the per-year AGGREGATE biomass (sum
# across sections).
#
# Spec §4.1: For latent layers, run battery per draw, then summarise to
# median + lo (q05) + hi (q95) across draws. For observed layers (no draws),
# the indicator is a point; set lo == hi == point to keep the CSV schema uniform.
#
# Output: Output/diagnostics/ews_generic_aggregate.csv
# Schema: layer, unit, detrend, win_frac, year, + 8 indicators each with
#         {ind, ind_lo, ind_hi}
#
# Spec §8: ews_generic_battery() returns a 0-row tibble for degenerate input;
#          filter those draws out — never error.
#
# Deterministic; no talk-usuk reads; pure script (does NOT modify R/11_early_warning.R).
#
# Note: earlywarnings::generic_ews() plots unconditionally. We redirect each
# call through a null graphics device to avoid hitting R's device limit and
# accumulating Rplots*.pdf files during the 2000-draw loop.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

# ews_generic_battery() is headless-robust at the source (R/11_early_warning.R
# suppresses earlywarnings::generic_ews() plotting to an internal temp pdf and
# cleans up after every call), so no script-level device hack is needed.
source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

cat("=== Task 3.1: Generic aggregate EWS ===\n")
cat(format(Sys.time()), "\n\n")

# ---------------------------------------------------------------------------
# 1. Read input layers
# ---------------------------------------------------------------------------
L <- readRDS(file.path(diag_dir, "ews_input_layers.rds"))

cat("Input layer names:", paste(names(L), collapse = ", "), "\n")
for (nm in names(L)) {
  d <- L[[nm]]
  n_draws <- if ("draw" %in% names(d)) dplyr::n_distinct(d$draw) else 0L
  cat(sprintf("  %s: %d rows, years %d-%d, draws=%d\n",
              nm, nrow(d), min(d$year), max(d$year), n_draws))
}

# ---------------------------------------------------------------------------
# 2. Parameter grid
# ---------------------------------------------------------------------------
grid <- tidyr::expand_grid(
  detrend  = c("gaussian", "first-diff", "none"),
  win_frac = c(0.33, 0.5)
)

# Indicators for which we emit the triplet (columns in contract)
INDICATORS <- c("ar1", "variance", "sd", "skew", "kurtosis",
                "cv", "densratio", "returnrate")

# ---------------------------------------------------------------------------
# 3. Aggregate-series helper
#    If the layer has a draw column: group_by(draw, year) -> tot
#    Else:                           group_by(year)        -> tot, draw=0L
# ---------------------------------------------------------------------------
agg_series <- function(df) {
  if ("draw" %in% names(df)) {
    df |>
      dplyr::group_by(draw, year) |>
      dplyr::summarise(tot = sum(value, na.rm = TRUE), .groups = "drop") |>
      dplyr::arrange(draw, year)
  } else {
    df |>
      dplyr::group_by(year) |>
      dplyr::summarise(tot = sum(value, na.rm = TRUE), .groups = "drop") |>
      dplyr::mutate(draw = 0L) |>
      dplyr::arrange(year)
  }
}

# ---------------------------------------------------------------------------
# 4. Run battery per draw × grid row, then summarise to median/lo/hi
# ---------------------------------------------------------------------------
run_layer <- function(layer_name, df) {
  # Parse layer and unit from name (e.g. "latent_all11" -> layer="latent", unit="all11")
  parts     <- strsplit(layer_name, "_", fixed = TRUE)[[1]]
  lyr       <- parts[1]                             # "observed" or "latent"
  unt       <- paste(parts[-1], collapse = "_")     # "all11" or "core9"

  cat(sprintf("\nProcessing layer: %s (layer=%s, unit=%s)\n",
              layer_name, lyr, unt))

  agg    <- agg_series(df)
  draws  <- sort(unique(agg$draw))

  cat(sprintf("  %d years, %d draws\n",
              dplyr::n_distinct(agg$year), length(draws)))

  # Collect results across all grid rows
  layer_results <- vector("list", nrow(grid))

  for (gi in seq_len(nrow(grid))) {
    dtr  <- grid$detrend[gi]
    wfrc <- grid$win_frac[gi]

    # For each draw, run the battery and attach calendar year via time-index
    draw_rows <- vector("list", length(draws))

    for (di in seq_along(draws)) {
      dk  <- draws[di]
      sub <- dplyr::filter(agg, draw == dk) |> dplyr::arrange(year)
      x   <- sub$tot
      yr  <- sub$year

      batt <- ews_generic_battery(x, win_frac = wfrc, detrend = dtr)

      if (nrow(batt) == 0L) next

      # Map battery's `time` (1-based index into trimmed series) back to
      # calendar year.  ews_generic_battery strips leading/trailing NA before
      # calling generic_ews, so we replicate that trimming to get the aligned
      # year vector.
      x_num      <- as.numeric(x)
      finite_idx <- which(is.finite(x_num))
      if (length(finite_idx) == 0L) next
      yr_trimmed <- yr[min(finite_idx):max(finite_idx)]

      batt_year <- yr_trimmed[batt$time]

      draw_rows[[di]] <- dplyr::bind_cols(
        tibble::tibble(draw = dk, year = batt_year),
        dplyr::select(batt, dplyr::all_of(INDICATORS))
      )
    }

    # Bind all draws for this grid cell
    draw_df <- dplyr::bind_rows(draw_rows)

    if (nrow(draw_df) == 0L) {
      layer_results[[gi]] <- NULL
      next
    }

    # Summarise across draws to median + q05 + q95.
    # For observed (1 draw): median = lo = hi = point value.
    summarised <- draw_df |>
      dplyr::group_by(year) |>
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

    # Reshape from wide (ind__med, ind__lo, ind__hi) to contract schema
    # (ind, ind_lo, ind_hi)
    result_cols <- list(year = summarised$year)
    for (ind in INDICATORS) {
      result_cols[[ind]]                <- summarised[[paste0(ind, "__med")]]
      result_cols[[paste0(ind, "_lo")]] <- summarised[[paste0(ind, "__lo")]]
      result_cols[[paste0(ind, "_hi")]] <- summarised[[paste0(ind, "__hi")]]
    }
    result_tbl <- tibble::as_tibble(result_cols)

    layer_results[[gi]] <- dplyr::bind_cols(
      tibble::tibble(
        layer    = lyr,
        unit     = unt,
        detrend  = dtr,
        win_frac = wfrc
      ),
      result_tbl
    )

    cat(sprintf("  [%s / win_frac=%.2f] %d years × %d draws -> %d rows\n",
                dtr, wfrc, dplyr::n_distinct(result_tbl$year),
                length(draws), nrow(result_tbl)))
  }

  out <- dplyr::bind_rows(layer_results)
  cat(sprintf("  -> %d rows written total\n", nrow(out)))
  out
}

# ---------------------------------------------------------------------------
# 5. Run across all 4 layers
# ---------------------------------------------------------------------------
all_results        <- vector("list", length(L))
n_latent_draws_used <- NA_integer_

for (i in seq_along(L)) {
  nm  <- names(L)[i]
  res <- run_layer(nm, L[[nm]])
  all_results[[i]] <- res
  # Track number of latent draws used (same for both latent layers)
  if (grepl("^latent", nm) && is.na(n_latent_draws_used)) {
    if ("draw" %in% names(L[[nm]])) {
      n_latent_draws_used <- as.integer(dplyr::n_distinct(L[[nm]]$draw))
    }
  }
}

final <- dplyr::bind_rows(all_results)

# ---------------------------------------------------------------------------
# 6. Sanity checks (printed; never fatal)
# ---------------------------------------------------------------------------
cat("\n=== Sanity checks ===\n")

# Latent: hi >= lo
lat_check  <- dplyr::filter(final, layer == "latent")
ar1_hi_ok  <- all(lat_check$ar1_hi >= lat_check$ar1_lo | is.na(lat_check$ar1_lo),
                  na.rm = TRUE)
cat(sprintf("Latent: ar1_hi >= ar1_lo (or NA): %s\n", ar1_hi_ok))

# Observed: lo == point == hi
obs_check  <- dplyr::filter(final, layer == "observed")
obs_ar1_ok <- all(abs(obs_check$ar1_lo - obs_check$ar1) < 1e-12 |
                    is.na(obs_check$ar1), na.rm = TRUE)
cat(sprintf("Observed: ar1_lo == ar1 == ar1_hi: %s\n", obs_ar1_ok))

# Spot-check: at least some latent rows have a real CI interval
any_ci <- any(lat_check$ar1_hi > lat_check$ar1_lo, na.rm = TRUE)
cat(sprintf("Latent: some rows have ar1_hi > ar1_lo: %s\n", any_ci))

# ---------------------------------------------------------------------------
# 7. Write CSV
# ---------------------------------------------------------------------------
out_path <- file.path(diag_dir, "ews_generic_aggregate.csv")
readr::write_csv(final, out_path)

cat("\n=== DONE ===\n")
cat(sprintf("Rows written  : %d\n", nrow(final)))
cat(sprintf("Layers        : %s\n", paste(sort(unique(final$layer)), collapse = ", ")))
cat(sprintf("Units         : %s\n", paste(sort(unique(final$unit)),  collapse = ", ")))
cat(sprintf("Detrend grid  : %s\n", paste(sort(unique(final$detrend)), collapse = ", ")))
cat(sprintf("Win_frac grid : %s\n", paste(sort(unique(final$win_frac)), collapse = ", ")))
cat(sprintf("Year range    : %d - %d\n", min(final$year), max(final$year)))
cat(sprintf("Latent draws  : %d\n", n_latent_draws_used))
cat(sprintf("Output        : %s\n", out_path))
cat(sprintf("Columns       : %s\n", paste(names(final), collapse = ", ")))
