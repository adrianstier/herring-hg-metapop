# ============================================================================
# 11_ews_05_surrogate_significance.R — Kendall τ + AR(1)-surrogate significance
# stier-2027-herring-metapopulation
#
# Task 4.1: For every indicator trajectory (Tier 1 generic/aggregate,
# Tier 2 spatial/synchrony, Tier 3 covariance/eigenvalue), run
# ews_kendall_surrogate() with two pre-window variants:
#   "full"    — entire trajectory
#   "pre1966" — rows with t <= 1965 (run-up to 1966 reduction-fishery crash)
#
# CAVEAT (for Task 5.2 claim-control sheet):
#   Phase-3 CSVs collapse posterior draws to median+q05+q95 per indicator-year.
#   We do NOT have per-draw trajectories here, so tau is a POINT ESTIMATE on
#   the median (latent) or observed trajectory. The surrogate null provides
#   p_value uncertainty at Monte-Carlo resolution = 1/n_surr = 0.001.
#   Per-draw Kendall τ credible intervals require re-running the Phase-3
#   pipeline with per-draw output — out of scope for Task 4.1.
#
# Inputs (bail with stop() if missing):
#   Output/diagnostics/ews_generic_aggregate.csv   (Tier 1, Task 3.1)
#   Output/diagnostics/ews_spatial_synchrony.csv   (Tier 2, Task 3.2)
#   Output/diagnostics/ews_covariance_eigen.csv    (Tier 3, Task 3.3)
#   Output/diagnostics/ews_candidate_transitions.csv (Task 3.4; confirms 1966 era)
#
# Output:
#   Output/diagnostics/ews_surrogate_significance.csv
#   Columns: tier, layer, unit, indicator, window_def, pre_window,
#            n, tau, p_value
#
# Pattern: Code/11_ews_02_spatial_synchrony.R (source header, sanity cat())
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

cat("=== Task 4.1: Kendall tau + AR(1)-surrogate significance ===\n")
cat(format(Sys.time()), "\n\n")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
N_SURR   <- 1000L
SEED     <- 20260519L
PRE_YEAR <- 1965L   # pre1966 filter: t <= 1965

TIER1_INDICATORS <- c("ar1", "variance", "sd", "skew",
                       "kurtosis", "cv", "densratio", "returnrate")
TIER2_INDICATORS <- c("phi", "eta", "spatial_var",
                       "spatial_skew", "morans_i", "cv_ratio")
TIER3_INDICATORS <- c("lambda_max", "eig_share", "mar1_eigen")

# ---------------------------------------------------------------------------
# 1. Check inputs
# ---------------------------------------------------------------------------
needed <- c(
  file.path(diag_dir, "ews_generic_aggregate.csv"),
  file.path(diag_dir, "ews_spatial_synchrony.csv"),
  file.path(diag_dir, "ews_covariance_eigen.csv"),
  file.path(diag_dir, "ews_candidate_transitions.csv")
)
missing_files <- needed[!file.exists(needed)]
if (length(missing_files) > 0L) {
  stop("Missing required input files:\n",
       paste(" -", missing_files, collapse = "\n"))
}
cat("All input files present.\n\n")

# ---------------------------------------------------------------------------
# 2. Read inputs
# ---------------------------------------------------------------------------
cat("Reading Phase-3 CSVs...\n")
t1 <- readr::read_csv(file.path(diag_dir, "ews_generic_aggregate.csv"),
                      show_col_types = FALSE)
t2 <- readr::read_csv(file.path(diag_dir, "ews_spatial_synchrony.csv"),
                      show_col_types = FALSE)
t3 <- readr::read_csv(file.path(diag_dir, "ews_covariance_eigen.csv"),
                      show_col_types = FALSE)
ct <- readr::read_csv(file.path(diag_dir, "ews_candidate_transitions.csv"),
                      show_col_types = FALSE)

cat(sprintf("  Tier 1: %d rows, years %d-%d\n",
            nrow(t1), min(t1$year), max(t1$year)))
cat(sprintf("  Tier 2: %d rows, window_mid %.1f-%.1f\n",
            nrow(t2), min(t2$window_mid), max(t2$window_mid)))
cat(sprintf("  Tier 3: %d rows, window_mid %.1f-%.1f\n",
            nrow(t3), min(t3$window_mid), max(t3$window_mid)))

# Confirm documented era anchor for 1966 is present
doc1966 <- ct |> dplyr::filter(method == "documented", year == 1966L)
if (nrow(doc1966) == 0L) {
  cat("WARNING: No documented era anchor at 1966 in candidate_transitions — ",
      "using PRE_YEAR=1965 as specified regardless.\n")
} else {
  cat(sprintf("  Confirmed documented era anchor: year=1966 (%s).\n",
              doc1966$label[1]))
}

# ---------------------------------------------------------------------------
# 3. Build long combined table
#    Columns: tier, layer, unit, indicator, window_def, t, value
# ---------------------------------------------------------------------------
cat("\nBuilding long indicator table...\n")

# Tier 1: median of the (indicator) column; t = year
tier1_long <- t1 |>
  dplyr::mutate(window_def = paste(detrend, win_frac, sep = "|")) |>
  dplyr::select(layer, unit, window_def, year,
                dplyr::all_of(TIER1_INDICATORS)) |>
  tidyr::pivot_longer(cols = dplyr::all_of(TIER1_INDICATORS),
                      names_to = "indicator", values_to = "value") |>
  dplyr::arrange(layer, unit, indicator, window_def, year) |>
  dplyr::rename(t = year) |>
  dplyr::mutate(tier = 1L)

# Tier 2: median column (no _lo/_hi suffix); t = window_mid
tier2_long <- t2 |>
  dplyr::mutate(window_def = paste0("w", window_len)) |>
  dplyr::select(layer, unit, window_def, window_mid,
                dplyr::all_of(TIER2_INDICATORS)) |>
  tidyr::pivot_longer(cols = dplyr::all_of(TIER2_INDICATORS),
                      names_to = "indicator", values_to = "value") |>
  dplyr::arrange(layer, unit, indicator, window_def, window_mid) |>
  dplyr::rename(t = window_mid) |>
  dplyr::mutate(tier = 2L)

# Tier 3: median column (no _lo/_hi suffix); t = window_mid
tier3_long <- t3 |>
  dplyr::mutate(window_def = paste0("w", window_len)) |>
  dplyr::select(layer, unit, window_def, window_mid,
                dplyr::all_of(TIER3_INDICATORS)) |>
  tidyr::pivot_longer(cols = dplyr::all_of(TIER3_INDICATORS),
                      names_to = "indicator", values_to = "value") |>
  dplyr::arrange(layer, unit, indicator, window_def, window_mid) |>
  dplyr::rename(t = window_mid) |>
  dplyr::mutate(tier = 3L)

long_all <- dplyr::bind_rows(tier1_long, tier2_long, tier3_long)

cat(sprintf("  Combined long table: %d rows, %d distinct trajectories\n",
            nrow(long_all),
            nrow(dplyr::distinct(long_all, tier, layer, unit, indicator, window_def))))

# ---------------------------------------------------------------------------
# 4. Enumerate all (tier, layer, unit, indicator, window_def) trajectories
#    Then split into full + pre1966 variants.
# ---------------------------------------------------------------------------
trajectory_keys <- long_all |>
  dplyr::distinct(tier, layer, unit, indicator, window_def)

cat(sprintf("  Total distinct trajectories: %d (x2 pre_window = %d calls)\n",
            nrow(trajectory_keys),
            nrow(trajectory_keys) * 2L))

# ---------------------------------------------------------------------------
# 5. Surrogate runner
#    Called once per (trajectory_key + pre_window variant)
# ---------------------------------------------------------------------------
run_surrogate <- function(tier, layer, unit, indicator, window_def,
                           pre_window, trajectory_df) {

  # Select rows for this trajectory
  traj <- trajectory_df |>
    dplyr::filter(.data$tier      == .env$tier,
                  .data$layer     == .env$layer,
                  .data$unit      == .env$unit,
                  .data$indicator == .env$indicator,
                  .data$window_def == .env$window_def) |>
    dplyr::arrange(.data$t)

  if (pre_window == "pre1966") {
    traj <- dplyr::filter(traj, .data$t <= PRE_YEAR)
  }

  values <- traj$value

  r <- tryCatch(
    ews_kendall_surrogate(values, n_surr = N_SURR, seed = SEED),
    error = function(e) list(tau = NA_real_, p_value = NA_real_, n = 0L)
  )

  # Clamp tau to [-1, 1]: Kendall::Kendall() occasionally returns values like
  # 1.0 + 1.19e-7 due to single-precision float arithmetic. This is a benign
  # numerical artifact — clamp before writing so the output contract holds.
  tau_clamped <- if (is.finite(r$tau)) max(-1, min(1, r$tau)) else r$tau

  tibble::tibble(
    tier       = tier,
    layer      = layer,
    unit       = unit,
    indicator  = indicator,
    window_def = window_def,
    pre_window = pre_window,
    n          = as.integer(r$n),
    tau        = tau_clamped,
    p_value    = r$p_value
  )
}

# ---------------------------------------------------------------------------
# 6. Run all trajectories x 2 pre_window variants
# ---------------------------------------------------------------------------
cat("\nRunning surrogate tests...\n")
t_start <- proc.time()

# Build all (key x pre_window) combinations — purrr::pmap_dfr over rows
keys_with_variants <- dplyr::bind_rows(
  dplyr::mutate(trajectory_keys, pre_window = "full"),
  dplyr::mutate(trajectory_keys, pre_window = "pre1966")
) |> dplyr::arrange(tier, layer, unit, indicator, window_def, pre_window)

n_calls <- nrow(keys_with_variants)
cat(sprintf("  Total calls: %d\n", n_calls))

# Progress tracker: print a dot every 50 calls
progress_env <- new.env(parent = emptyenv())
progress_env$count <- 0L
progress_env$n_total <- n_calls

results <- purrr::pmap_dfr(
  keys_with_variants,
  function(tier, layer, unit, indicator, window_def, pre_window) {
    progress_env$count <- progress_env$count + 1L
    if (progress_env$count %% 50L == 0L || progress_env$count == 1L) {
      cat(sprintf("  ... %d/%d (%.0f%%)\n",
                  progress_env$count, progress_env$n_total,
                  100 * progress_env$count / progress_env$n_total))
    }
    run_surrogate(tier, layer, unit, indicator, window_def,
                  pre_window, long_all)
  }
)

t_elapsed <- (proc.time() - t_start)[["elapsed"]]
cat(sprintf("\nDone. %.1f s elapsed.\n", t_elapsed))

# ---------------------------------------------------------------------------
# 7. Sanity checks
# ---------------------------------------------------------------------------
cat("\n=== Sanity checks ===\n")

cat(sprintf("Total rows: %d\n", nrow(results)))
cat(sprintf("Distinct tiers: %s\n",
            paste(sort(unique(results$tier)), collapse = ", ")))
cat(sprintf("Distinct layers: %s\n",
            paste(sort(unique(results$layer)), collapse = ", ")))
cat(sprintf("Distinct units: %s\n",
            paste(sort(unique(results$unit)), collapse = ", ")))
cat(sprintf("Distinct pre_window: %s\n",
            paste(sort(unique(results$pre_window)), collapse = ", ")))

finite_rows <- results |> dplyr::filter(is.finite(tau) & is.finite(p_value))
cat(sprintf("Rows with finite tau+p_value: %d (%.1f%%)\n",
            nrow(finite_rows), 100 * nrow(finite_rows) / nrow(results)))

frac_sig <- mean(finite_rows$p_value < 0.05, na.rm = TRUE)
cat(sprintf("Fraction with p<0.05 (of finite rows): %.3f\n", frac_sig))

tau_ok <- all(finite_rows$tau >= -1 - 1e-9 & finite_rows$tau <= 1 + 1e-9)
p_ok   <- all(finite_rows$p_value >= 0 - 1e-9 & finite_rows$p_value <= 1 + 1e-9)
cat(sprintf("tau in [-1,1]: %s\n", tau_ok))
cat(sprintf("p_value in [0,1]: %s\n", p_ok))

# Rows per tier
for (ti in c(1L, 2L, 3L)) {
  n_ti <- nrow(dplyr::filter(results, tier == ti))
  cat(sprintf("  Tier %d: %d rows\n", ti, n_ti))
}

# Top-5 most significant
cat("\nTop-5 most significant (finite, smallest p_value):\n")
top5 <- finite_rows |>
  dplyr::arrange(p_value, dplyr::desc(abs(tau))) |>
  dplyr::slice_head(n = 5L) |>
  dplyr::select(indicator, window_def, pre_window, layer, unit, tau, p_value)
print(as.data.frame(top5))

# ---------------------------------------------------------------------------
# 8. Write output
# ---------------------------------------------------------------------------
out_path <- file.path(diag_dir, "ews_surrogate_significance.csv")
readr::write_csv(results, out_path)

cat("\n=== DONE ===\n")
cat(sprintf("Rows written    : %d\n", nrow(results)))
cat(sprintf("Output          : %s\n", out_path))
cat(sprintf("Columns         : %s\n", paste(names(results), collapse = ", ")))
cat(sprintf("Runtime         : %.1f s\n", t_elapsed))
cat("\nNOTE: tau is a point estimate on the median (latent) or observed",
    "trajectory.\n")
cat("p_value uncertainty: Monte-Carlo resolution = 1/n_surr = 0.001.\n")
cat("Per-draw Kendall CI: requires re-running Phase-3 with per-draw output",
    "(Task 5.2 scope).\n")
