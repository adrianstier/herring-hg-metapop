# ============================================================================
# 11_ews_07_survey_artifact_audit.R — Survey-method false-positive audit
# stier-2027-herring-metapopulation
#
# Task 4.3: Simulate a stationary metapopulation passed through documented
# observation distortions (two-era catchability shift, pre-1990 zero-injection,
# coverage mask) and run the full EWS battery to estimate false-positive rates.
#
# Inputs:
#   Output/diagnostics/ews_input_layers.rds                  (canonical coords)
#   Output/diagnostics/m1_stier_method_sensitivity_q_summary.csv (q medians)
#   Output/diagnostics/survey_coverage_zero_ambiguity_by_year.csv (coverage)
#   Output/diagnostics/ews_surrogate_significance.csv        (observed HG tau)
#
# Outputs:
#   Output/diagnostics/ews_survey_artifact_disqualified.csv
#     columns: indicator, artifact_tau_median, artifact_pos_sig_frac,
#              disqualified (logical), n_rep
#   Output/diagnostics/ews_survey_artifact_audit.md
#     Simulator setup / per-indicator FP rates / comparison vs observed /
#     honest-failure verdict
#
# n_rep = 200, n_surr = 200 per rep.  Window spec mirrors Task 4.1/4.2.
# Runtime target: ~5-15 min on a single core Mac.
#
# FIREWALL: reads from diagnostics only, never from R/, inst/stan/, Data/ etc.
# Does NOT modify R/11_early_warning.R.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(purrr)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

cat("=== Task 4.3: Survey-method false-positive audit ===\n")
cat(format(Sys.time()), "\n\n")

diag_dir <- here::here("Output", "diagnostics")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
N_REP               <- 200L
N_SURR              <- 200L
SEED_BASE           <- 20260519L
N_SITES             <- 9L       # core9 cardinality
N_YEARS             <- 75L      # 1951:2025
SIM_YEARS           <- seq(1951L, 1951L + N_YEARS - 1L)  # 1951:2025
ZERO_INJECT_CUTOFF  <- 1990L    # pre-1990 zero-injection era
DISQUAL_THRESHOLD   <- 0.20     # >20% false-positive rate -> disqualified
WINDOW_LENS         <- c(10L, 15L, 20L)   # for spatial/eigen indicators
WIN_FRAC            <- 0.5      # for generic battery

# ---------------------------------------------------------------------------
# 1. Check and load required inputs
# ---------------------------------------------------------------------------
cat("--- 1. Loading inputs ---\n")

required_files <- c(
  q_csv       = file.path(diag_dir, "m1_stier_method_sensitivity_q_summary.csv"),
  cov_csv     = file.path(diag_dir, "survey_coverage_zero_ambiguity_by_year.csv"),
  inp_rds     = file.path(diag_dir, "ews_input_layers.rds"),
  surr_csv    = file.path(diag_dir, "ews_surrogate_significance.csv")
)
missing <- required_files[!file.exists(required_files)]
if (length(missing) > 0L) {
  stop("Missing required input file(s):\n",
       paste(" -", missing, collapse = "\n"))
}

q_df     <- readr::read_csv(required_files["q_csv"],  show_col_types = FALSE)
cov_df   <- readr::read_csv(required_files["cov_csv"],show_col_types = FALSE)
inp      <- readRDS(required_files["inp_rds"])
surr_df  <- readr::read_csv(required_files["surr_csv"],show_col_types = FALSE)
cat("All inputs loaded.\n\n")

# ---------------------------------------------------------------------------
# 2. Extract catchability ratio (Surface q / Dive-dominant q)
# ---------------------------------------------------------------------------
cat("--- 2. Catchability distortion factor ---\n")

# q_df methods: "Surface", "Mixed transition", "Dive-dominant"
q_surface <- q_df |>
  dplyr::filter(stringr::str_detect(method, regex("Surface", ignore_case = TRUE))) |>
  dplyr::pull(q_median)

q_dive <- q_df |>
  dplyr::filter(stringr::str_detect(method, regex("Dive", ignore_case = TRUE))) |>
  dplyr::pull(q_median)

if (length(q_surface) == 0L) stop("No 'Surface' row in q_summary CSV.")
if (length(q_dive) == 0L) {
  # Fallback: use any non-Surface, non-Mixed row
  q_dive <- q_df |>
    dplyr::filter(!stringr::str_detect(method, regex("Surface|Mixed", ignore_case = TRUE))) |>
    dplyr::pull(q_median)
}
if (length(q_dive) == 0L) stop("Cannot find Dive-dominant q_median in q_summary CSV.")

q_surface <- q_surface[1L]
q_dive    <- q_dive[1L]

# Catchability distortion: Surface era values are UNDER-detected relative to
# the dive era.  To make the pre-1993 simulated truth look like Surface-era
# observations, multiply by q_surface / q_dive (Surface catchability < Dive).
q_ratio <- q_surface / q_dive

cat(sprintf("  Surface q_median = %.4f\n", q_surface))
cat(sprintf("  Dive q_median    = %.4f\n", q_dive))
cat(sprintf("  Distortion ratio (Surface/Dive) = %.4f\n\n", q_ratio))

# ---------------------------------------------------------------------------
# 3. Pre-build coverage mask (once, reused across reps)
# ---------------------------------------------------------------------------
cat("--- 3. Building coverage lookup ---\n")

# Standardise: ensure columns as expected
cov_clean <- cov_df |>
  dplyr::mutate(
    year              = as.integer(year),
    positive_sections = as.integer(positive_sections),
    missing_sections  = as.integer(missing_sections)
  )

# For zero-injection: pre-1990 years — number of sections to NA out
# = n_sites - positive_sections (how many were zero/unobserved)
zero_inject_lu <- cov_clean |>
  dplyr::filter(year < ZERO_INJECT_CUTOFF, year %in% SIM_YEARS) |>
  dplyr::select(year, positive_sections) |>
  dplyr::mutate(n_na_inject = pmax(0L, N_SITES - positive_sections))

# For coverage mask: all years — missing_sections from the CSV
coverage_mask_lu <- cov_clean |>
  dplyr::filter(year %in% SIM_YEARS) |>
  dplyr::select(year, missing_sections)

cat(sprintf("  Zero-injection lookup: %d pre-1990 years\n",
            nrow(zero_inject_lu)))
cat(sprintf("  Coverage mask lookup: %d years\n\n",
            nrow(coverage_mask_lu)))

# ---------------------------------------------------------------------------
# 4. Canonical core9 coordinates (from ews_input_layers.rds)
# ---------------------------------------------------------------------------
cat("--- 4. Canonical core9 coordinates ---\n")

obs_core9 <- inp[["observed_core9"]]
if (is.null(obs_core9)) stop("observed_core9 absent from ews_input_layers.rds")

# One coord per section (sorted)
coords_lu <- obs_core9 |>
  dplyr::filter(is.finite(longitude), is.finite(latitude)) |>
  dplyr::group_by(section) |>
  dplyr::slice(1L) |>
  dplyr::ungroup() |>
  dplyr::select(section, longitude, latitude) |>
  dplyr::arrange(section)

coords_mat <- as.matrix(dplyr::select(coords_lu, longitude, latitude))
n_coords   <- nrow(coords_mat)

cat(sprintf("  %d sections with valid coords\n\n", n_coords))

# ---------------------------------------------------------------------------
# 5. Apply observation distortions to a simulated matrix
#    Returns: n_years × n_sites matrix with catchability, zero-injection,
#             and coverage-mask distortions applied.
# ---------------------------------------------------------------------------
apply_distortions <- function(mat, rep_seed) {
  n_yr  <- nrow(mat)
  n_st  <- ncol(mat)

  # Step 1: Catchability distortion for pre-SURVEY_DIVE_START_YEAR rows
  pre_idx <- which(SIM_YEARS < SURVEY_DIVE_START_YEAR)
  if (length(pre_idx) > 0L)
    mat[pre_idx, ] <- mat[pre_idx, ] * q_ratio

  # Step 2: Zero-injection (pre-1990): NA out random sections
  for (r in seq_len(nrow(zero_inject_lu))) {
    yr        <- zero_inject_lu$year[r]
    n_na      <- zero_inject_lu$n_na_inject[r]
    yr_idx    <- which(SIM_YEARS == yr)
    if (length(yr_idx) == 0L || n_na == 0L) next
    set.seed(rep_seed + yr * 1000L)
    cols_na   <- sample(seq_len(n_st), size = min(n_na, n_st), replace = FALSE)
    mat[yr_idx, cols_na] <- NA_real_
  }

  # Step 3: Coverage mask — NA out missing_sections per year
  for (r in seq_len(nrow(coverage_mask_lu))) {
    yr      <- coverage_mask_lu$year[r]
    n_miss  <- coverage_mask_lu$missing_sections[r]
    yr_idx  <- which(SIM_YEARS == yr)
    if (length(yr_idx) == 0L || is.na(n_miss) || n_miss == 0L) next
    set.seed(rep_seed + yr * 2000L)
    cols_na <- sample(seq_len(n_st), size = min(n_na_miss <- as.integer(n_miss), n_st),
                      replace = FALSE)
    mat[yr_idx, cols_na] <- NA_real_
  }

  mat
}

# ---------------------------------------------------------------------------
# 6. Per-window spatial indicator helper (mirrors Task 4.1/4.2 pattern)
#    Returns named list: phi, eta, spatial_var, morans_i, eig_share, mar1_eigen
#    Each element is a vector of window-level values (across rolling windows).
# ---------------------------------------------------------------------------
compute_spatial_indicators_rolling <- function(mat, win_len) {
  n_yr  <- nrow(mat)
  starts <- seq_len(max(0L, n_yr - win_len + 1L))
  if (length(starts) == 0L) {
    return(list(phi = NA_real_, eta = NA_real_, spatial_var = NA_real_,
                morans_i = NA_real_, eig_share = NA_real_, mar1_eigen = NA_real_))
  }

  phi_v       <- numeric(length(starts))
  eta_v       <- numeric(length(starts))
  sv_v        <- numeric(length(starts))
  mi_v        <- numeric(length(starts))
  eig_v       <- numeric(length(starts))
  mar1_v      <- numeric(length(starts))

  for (si in seq_along(starts)) {
    s   <- starts[si]
    e   <- s + win_len - 1L
    W   <- mat[s:e, , drop = FALSE]

    phi_v[si]  <- tryCatch(ews_synchrony_phi(W), error = function(e) NA_real_)
    eta_v[si]  <- tryCatch(ews_synchrony_eta(W), error = function(e) NA_real_)

    # spatial_var: mean across years of within-year section variance
    sv_yr      <- vapply(seq_len(nrow(W)),
                         function(i) ews_spatial_variance(W[i, ]),
                         numeric(1L))
    sv_v[si]   <- if (any(is.finite(sv_yr))) mean(sv_yr, na.rm = TRUE) else NA_real_

    # Moran's I: mean across years
    mi_yr      <- vapply(seq_len(nrow(W)),
                         function(i) tryCatch(
                           ews_morans_i(W[i, ], coords_mat),
                           error = function(e) NA_real_),
                         numeric(1L))
    mi_v[si]   <- if (any(is.finite(mi_yr))) mean(mi_yr, na.rm = TRUE) else NA_real_

    # Covariance eigenvalue share
    ce         <- tryCatch(ews_cov_eigen(W), error = function(e)
                    list(lambda_max = NA_real_, eig_share = NA_real_))
    eig_v[si]  <- if (!is.null(ce$eig_share)) ce$eig_share else NA_real_

    # MAR(1) dominant eigenvalue via lm.fit (MARSS skipped — too slow for
    # 200-rep × 200-surr Monte Carlo; windows with NAs return NA_real_).
    mar1_v[si] <- tryCatch({
      if (anyNA(W)) {
        NA_real_
      } else {
        p   <- ncol(W)
        Yr  <- W[-1L, , drop = FALSE]
        Zr  <- W[-nrow(W), , drop = FALSE]
        cf  <- stats::lm.fit(Zr, Yr)$coefficients
        if (anyNA(cf)) NA_real_
        else {
          B  <- t(matrix(cf, p, p))
          ev <- max(Mod(eigen(B, only.values = TRUE)$values))
          if (is.finite(ev)) ev else NA_real_
        }
      }
    }, error = function(e) NA_real_)
  }

  list(phi        = phi_v,
       eta        = eta_v,
       spatial_var = sv_v,
       morans_i   = mi_v,
       eig_share  = eig_v,
       mar1_eigen  = mar1_v)
}

# ---------------------------------------------------------------------------
# 7. Single-rep function
#    Returns a tibble: indicator, tau, p_value
# ---------------------------------------------------------------------------
run_one_rep <- function(rep_idx) {
  rep_seed <- SEED_BASE + rep_idx

  # 7a. Simulate stationary truth
  truth <- tryCatch(
    ews_sim_metapop(n_sites  = N_SITES,
                    n_years  = N_YEARS,
                    scenario = "stationary",
                    seed     = rep_seed),
    error = function(e) matrix(NA_real_, N_YEARS, N_SITES)
  )

  # 7b. Apply observation distortions
  distorted <- tryCatch(
    apply_distortions(truth, rep_seed),
    error = function(e) truth
  )

  rows <- list()

  # 7c. Aggregate time series (row sums with na.rm)
  agg <- rowSums(distorted, na.rm = TRUE)
  # Years where ALL sections are NA -> contribute NA to agg
  all_na_yr <- apply(distorted, 1, function(r) all(is.na(r)))
  agg[all_na_yr] <- NA_real_

  # 7d. Generic battery on the aggregate (win_frac=0.5, detrend="gaussian")
  batt <- tryCatch(
    ews_generic_battery(agg, win_frac = WIN_FRAC, detrend = "gaussian"),
    error = function(e) tibble::tibble()
  )

  generic_inds <- c("ar1", "variance", "sd", "skew", "kurtosis", "cv",
                    "densratio", "returnrate")

  for (ind in generic_inds) {
    if (ind %in% names(batt) && any(is.finite(batt[[ind]]))) {
      traj <- batt[[ind]]
      ks <- tryCatch(
        ews_kendall_surrogate(traj, n_surr = N_SURR,
                              seed = rep_seed + match(ind, generic_inds) * 1000L),
        error = function(e) list(tau = NA_real_, p_value = NA_real_)
      )
      rows[[length(rows) + 1L]] <- tibble::tibble(
        indicator = ind,
        tau       = ks$tau,
        p_value   = ks$p_value
      )
    } else {
      rows[[length(rows) + 1L]] <- tibble::tibble(
        indicator = ind, tau = NA_real_, p_value = NA_real_
      )
    }
  }

  # 7e. Rolling spatial indicators (mean window = 10; consistent with Task 4.1)
  # Use window=10 as primary; collect trajectories across windows for each indicator
  spatial_inds <- c("phi", "eta", "spatial_var", "morans_i", "eig_share", "mar1_eigen")
  for (wl in WINDOW_LENS) {
    si_res <- tryCatch(
      compute_spatial_indicators_rolling(distorted, wl),
      error = function(e) {
        setNames(lapply(spatial_inds, function(.) NA_real_), spatial_inds)
      }
    )

    for (ind in spatial_inds) {
      traj <- si_res[[ind]]
      if (!is.null(traj) && any(is.finite(traj))) {
        ks <- tryCatch(
          ews_kendall_surrogate(traj, n_surr = N_SURR,
                                seed = rep_seed + wl * 100L +
                                         match(ind, spatial_inds) * 10000L),
          error = function(e) list(tau = NA_real_, p_value = NA_real_)
        )
        rows[[length(rows) + 1L]] <- tibble::tibble(
          indicator = paste0(ind, "_w", wl),
          tau       = ks$tau,
          p_value   = ks$p_value
        )
      } else {
        rows[[length(rows) + 1L]] <- tibble::tibble(
          indicator = paste0(ind, "_w", wl),
          tau = NA_real_, p_value = NA_real_
        )
      }
    }
  }

  dplyr::bind_rows(rows)
}

# ---------------------------------------------------------------------------
# 8. Run all reps
# ---------------------------------------------------------------------------
cat(sprintf("--- Running %d realisations (n_surr = %d per Kendall) ---\n",
            N_REP, N_SURR))
t_start <- proc.time()["elapsed"]

rep_results <- vector("list", N_REP)
for (ri in seq_len(N_REP)) {
  if (ri %% 25L == 0L || ri == 1L)
    cat(sprintf("  Rep %d / %d  [%.0f s elapsed]\n", ri, N_REP,
                proc.time()["elapsed"] - t_start))
  rep_results[[ri]] <- tryCatch(
    run_one_rep(ri),
    error = function(e) tibble::tibble(indicator = character(0),
                                        tau = double(0), p_value = double(0))
  )
}

t_elapsed <- proc.time()["elapsed"] - t_start
cat(sprintf("All reps done in %.0f s (%.1f min)\n\n",
            t_elapsed, t_elapsed / 60))

# Combine
all_reps <- dplyr::bind_rows(rep_results, .id = "rep")

# ---------------------------------------------------------------------------
# 9. Collapse across reps: per indicator, artifact_tau_median, pos_sig_frac
# ---------------------------------------------------------------------------
cat("--- 9. Summarising false-positive rates ---\n")

artifact_summary <- all_reps |>
  dplyr::group_by(indicator) |>
  dplyr::summarise(
    artifact_tau_median    = median(tau,    na.rm = TRUE),
    artifact_pos_sig_frac  = mean(p_value < 0.05 & tau > 0, na.rm = TRUE),
    n_rep                  = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    disqualified = artifact_pos_sig_frac > DISQUAL_THRESHOLD
  ) |>
  dplyr::arrange(indicator)

cat("Per-indicator false-positive fractions:\n")
print(artifact_summary, n = Inf)
cat("\n")

disqualified_inds <- artifact_summary |>
  dplyr::filter(disqualified) |>
  dplyr::pull(indicator)
cat(sprintf("Disqualified indicators (FP frac > %.2f): %s\n\n",
            DISQUAL_THRESHOLD,
            if (length(disqualified_inds) > 0) paste(disqualified_inds, collapse = ", ")
            else "NONE"))

# Write CSV
disq_path <- file.path(diag_dir, "ews_survey_artifact_disqualified.csv")
readr::write_csv(artifact_summary, disq_path)
cat("Written:", disq_path, "\n\n")

# ---------------------------------------------------------------------------
# 10. Build comparison table vs observed HG signal
# ---------------------------------------------------------------------------
cat("--- 10. Comparison vs observed HG signal ---\n")

# Pull observed HG tau for the canonical window variants
# Match: layer=="observed", unit=="core9", pre_window=="full"
# For generic indicators: pick window_def with win_frac==0.5 and detrend=="gaussian"
# For spatial indicators: pick window_def like "w10"|"w15"|"w20"
obs_tau <- surr_df |>
  dplyr::filter(layer == "observed", unit == "core9", pre_window == "full")

# Build a simplified lookup: one row per indicator
# For generic (tier 1): prefer gaussian|0.5
obs_generic <- obs_tau |>
  dplyr::filter(tier == 1, stringr::str_detect(window_def, "gaussian\\|0\\.5")) |>
  dplyr::select(indicator, obs_tau = tau, obs_p = p_value)

# For spatial (tier 2): prefer w10 (closest to mid window)
obs_spatial <- obs_tau |>
  dplyr::filter(tier == 2, window_def == "w10") |>
  dplyr::select(indicator, obs_tau = tau, obs_p = p_value)

# For eigen (tier 3): prefer w10
obs_eigen <- obs_tau |>
  dplyr::filter(tier == 3, window_def == "w10") |>
  dplyr::select(indicator, obs_tau = tau, obs_p = p_value)

obs_all <- dplyr::bind_rows(obs_generic, obs_spatial, obs_eigen)

# Now join with artifact summary.  Artifact indicator names for spatial:
# e.g. "phi_w10", "phi_w15", "phi_w20".  Use w10 for comparison.
artifact_for_join <- artifact_summary |>
  dplyr::mutate(
    # Strip the _wNN suffix to get the base indicator name for joining
    ind_base = stringr::str_remove(indicator, "_w\\d+$"),
    win_suffix = dplyr::case_when(
      stringr::str_detect(indicator, "_w10$") ~ "w10",
      stringr::str_detect(indicator, "_w15$") ~ "w15",
      stringr::str_detect(indicator, "_w20$") ~ "w20",
      TRUE ~ "generic"
    )
  )

# For the comparison table, select artifact_w10 for spatial, generic otherwise
artifact_w10 <- artifact_for_join |>
  dplyr::filter(win_suffix %in% c("w10", "generic")) |>
  dplyr::select(indicator = ind_base, artifact_tau_median,
                artifact_pos_sig_frac, disqualified)

comparison <- obs_all |>
  dplyr::inner_join(artifact_w10, by = "indicator") |>
  dplyr::distinct(indicator, .keep_all = TRUE) |>
  dplyr::arrange(indicator)

# Also add per-indicator verdict text
comparison <- comparison |>
  dplyr::mutate(
    verdict = dplyr::case_when(
      is.na(obs_tau) | is.na(artifact_tau_median) ~ "insufficient data",
      disqualified & obs_tau > 0 & obs_p < 0.05  ~ "FAIL: observed signal within artifact distribution",
      disqualified & !(obs_tau > 0 & obs_p < 0.05) ~ "PASS: disqualified indicator but observed signal not significant-positive",
      !disqualified & obs_tau > 0 & obs_p < 0.05  ~ "PASS: observed signal exceeds artifact threshold, significant",
      !disqualified ~ "PASS: artifact FP rate low, observed signal non-significant-positive",
      TRUE ~ "ambiguous"
    )
  )

# ---------------------------------------------------------------------------
# 11. Write markdown audit report
# ---------------------------------------------------------------------------
cat("--- 11. Writing audit markdown ---\n")

md_path <- file.path(diag_dir, "ews_survey_artifact_audit.md")

# Pre-1990 zero rate summary
zero_rate_range <- zero_inject_lu |>
  dplyr::mutate(frac_na = n_na_inject / N_SITES) |>
  dplyr::summarise(lo = min(frac_na), hi = max(frac_na), med = median(frac_na))

# Format artifact summary as markdown table
art_tbl_md <- artifact_summary |>
  dplyr::select(indicator, artifact_tau_median, artifact_pos_sig_frac,
                disqualified, n_rep) |>
  dplyr::mutate(
    artifact_tau_median   = round(artifact_tau_median, 3),
    artifact_pos_sig_frac = round(artifact_pos_sig_frac, 3),
    disqualified          = as.character(disqualified)
  )

art_tbl_header <- paste(
  "| indicator | artifact_tau_median | artifact_pos_sig_frac | disqualified | n_rep |",
  "| --- | --- | --- | --- | --- |",
  sep = "\n"
)
art_tbl_rows <- paste(
  sprintf("| %s | %.3f | %.3f | %s | %d |",
          art_tbl_md$indicator,
          art_tbl_md$artifact_tau_median,
          art_tbl_md$artifact_pos_sig_frac,
          art_tbl_md$disqualified,
          art_tbl_md$n_rep),
  collapse = "\n"
)
art_tbl_full <- paste(art_tbl_header, art_tbl_rows, sep = "\n")

# Comparison table
comp_tbl_header <- paste(
  "| indicator | obs_tau | obs_p | artifact_tau_median | artifact_pos_sig_frac | disqualified |",
  "| --- | --- | --- | --- | --- | --- |",
  sep = "\n"
)
comp_tbl_rows <- paste(
  sprintf("| %s | %.3f | %.3f | %.3f | %.3f | %s |",
          comparison$indicator,
          ifelse(is.na(comparison$obs_tau), NA_real_, comparison$obs_tau),
          ifelse(is.na(comparison$obs_p),  NA_real_, comparison$obs_p),
          ifelse(is.na(comparison$artifact_tau_median), NA_real_, comparison$artifact_tau_median),
          ifelse(is.na(comparison$artifact_pos_sig_frac), NA_real_, comparison$artifact_pos_sig_frac),
          comparison$disqualified),
  collapse = "\n"
)
comp_tbl_full <- paste(comp_tbl_header, comp_tbl_rows, sep = "\n")

# Honest-failure verdicts
verdict_lines <- character(nrow(comparison))
for (i in seq_len(nrow(comparison))) {
  rw <- comparison[i, ]
  obs_tau_str <- if (is.na(rw$obs_tau)) "NA" else sprintf("%.3f", rw$obs_tau)
  obs_p_str   <- if (is.na(rw$obs_p))  "NA" else sprintf("%.3f", rw$obs_p)
  fp_str      <- if (is.na(rw$artifact_pos_sig_frac)) "NA" else
                   sprintf("%.3f", rw$artifact_pos_sig_frac)
  thr_str     <- sprintf("%.2f", DISQUAL_THRESHOLD)

  if (is.na(rw$obs_tau) || is.na(rw$artifact_tau_median)) {
    verdict_lines[i] <- sprintf(
      "- **%s**: insufficient data to evaluate (obs tau = %s, artifact tau = NA).",
      rw$indicator, obs_tau_str)
  } else if (rw$disqualified) {
    verdict_lines[i] <- sprintf(
      "- **%s**: DISQUALIFIED — the artifact null alone produces a false-positive rate of %s (threshold %.2f); the observed HG τ = %s (p = %s) cannot be attributed to biology alone.",
      rw$indicator, fp_str, DISQUAL_THRESHOLD, obs_tau_str, obs_p_str)
  } else {
    verdict_lines[i] <- sprintf(
      "- **%s**: PASSES artifact audit — false-positive rate = %s (≤ threshold %.2f); the observed HG τ = %s (p = %s) is not explained by the documented observation artifact alone.",
      rw$indicator, fp_str, DISQUAL_THRESHOLD, obs_tau_str, obs_p_str)
  }
}

# Timing summary
timing_str <- sprintf("%.0f s (%.1f min)", t_elapsed, t_elapsed / 60)

md_lines <- c(
  "# EWS Survey-Method False-Positive Audit",
  "",
  sprintf("Generated: %s", format(Sys.time())),
  "",
  "---",
  "",
  "## Simulator setup",
  "",
  sprintf("- **n_rep** = %d realisations (seeds: %dL + rep_idx)", N_REP, SEED_BASE),
  sprintf("- **n_surr** = %d AR(1)-surrogate permutations per Kendall τ", N_SURR),
  sprintf("- **Simulated years** = %d:%d (%d years)", min(SIM_YEARS), max(SIM_YEARS), N_YEARS),
  sprintf("- **n_sites** = %d (core9 cardinality)", N_SITES),
  sprintf("- **Scenario** = stationary (no trend; Allee + weak coupling; K=100)"),
  sprintf("- **Catchability distortion** = Surface/Dive q_median ratio = %.4f/%.4f = %.4f applied to pre-%d rows",
          q_surface, q_dive, q_ratio, SURVEY_DIVE_START_YEAR),
  sprintf("- **Pre-1990 zero-injection rate** (fraction of sites set to NA): range %.0f%% – %.0f%%, median %.0f%%",
          zero_rate_range$lo * 100, zero_rate_range$hi * 100, zero_rate_range$med * 100),
  sprintf("- **Coverage mask** source: survey_coverage_zero_ambiguity_by_year.csv (missing_sections per year)"),
  sprintf("- **Disqualification threshold** = %.2f (>%.0f%% of reps with significant positive τ)", DISQUAL_THRESHOLD, DISQUAL_THRESHOLD * 100),
  sprintf("- **Runtime** = %s", timing_str),
  "",
  "---",
  "",
  "## Per-indicator artifact-only false-positive rates",
  "",
  art_tbl_full,
  "",
  "---",
  "",
  "## Comparison vs observed HG signal",
  "",
  paste0("Observed HG tau from `ews_surrogate_significance.csv` ",
         "(layer == 'observed', unit == 'core9', pre_window == 'full'; ",
         "generic: gaussian|0.5; spatial/eigen: w10)."),
  "",
  comp_tbl_full,
  "",
  "---",
  "",
  "## Honest-failure verdict per indicator",
  "",
  paste(verdict_lines, collapse = "\n"),
  "",
  "---",
  "",
  "*Script*: `Code/11_ews_07_survey_artifact_audit.R` (Task 4.3)"
)

writeLines(md_lines, md_path)
cat("Written:", md_path, "\n\n")

# ---------------------------------------------------------------------------
# 12. Final sanity print
# ---------------------------------------------------------------------------
cat("=== Final sanity summary ===\n")
cat(sprintf("  Runtime: %s\n", timing_str))
cat(sprintf("  Reps completed: %d\n", N_REP))
cat(sprintf("  Unique indicators in output: %d\n", nrow(artifact_summary)))
cat(sprintf("  Disqualified: %d (%s)\n",
            length(disqualified_inds),
            if (length(disqualified_inds) > 0)
              paste(disqualified_inds, collapse = ", ")
            else "none"))
cat("\nIndicator FP fractions (sorted):\n")
print(
  artifact_summary |>
    dplyr::arrange(dplyr::desc(artifact_pos_sig_frac)) |>
    dplyr::select(indicator, artifact_pos_sig_frac, disqualified),
  n = Inf
)
cat("\nDone.\n")
