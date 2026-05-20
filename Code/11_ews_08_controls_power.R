# ============================================================================
# 11_ews_08_controls_power.R — EWS power & false-positive controls
# stier-2027-herring-metapopulation
#
# Task 4.4: Run the full EWS battery on simulated:
#   (a) approaching_fold — positive control for genuine CSD detection
#   (b) stationary       — null control for false-positive calibration
#
# Both scenarios use ews_sim_metapop() directly — NO observation distortions.
# This isolates the battery's intrinsic power from survey-artifact confounding
# (survey artifacts are addressed separately in Task 4.3).
#
# Outputs:
#   Output/diagnostics/ews_controls_power.csv
#     columns: scenario, indicator, detect_rate, n_rep, n_finite_traj,
#              power_gate_pass (logical)
#   Output/diagnostics/ews_controls_power.md
#     Narrative: Simulator / Per-indicator table / Validity gate verdict /
#     Important caveat (phi coupling-confound) / Implications for HG claim-control
#
# Validity gates (Task 1.8 / plan spec §5.4):
#   stationary:       every indicator detect_rate < 0.25  (FP control)
#   approaching_fold: phi AND eig_share AND (ar1 OR variance) detect_rate > 0.6
#
# Spatial indicators use a synthetic straight-line coords matrix
#   cbind(1:9, 0) — simulated sites, no real geography; documented below.
#
# MARSS-bypass: ews_mar1_eigen() uses lm.fit fallback (OLS VAR(1)) when
#   the matrix is complete; MARSS is skipped for the 200×200 MC budget.
#   Windows with NA values return NA_real_ for mar1_eigen; documented.
#
# n_rep = 200, n_surr = 200.  Seeds: 20260519L + scenario_idx*100000 + rep_idx.
#
# Runtime target: ~10-25 min on a single-core Mac.
#
# FIREWALL: reads from R/00_setup.R + R/11_early_warning.R only.
#   Never reads from Data/, Output/, or other Code/ scripts.
#   Does NOT modify R/11_early_warning.R.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(purrr)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

cat("=== Task 4.4: EWS power & false-positive controls ===\n")
cat(format(Sys.time()), "\n\n")

diag_dir <- here::here("Output", "diagnostics")
if (!dir.exists(diag_dir)) dir.create(diag_dir, recursive = TRUE)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
N_REP          <- 200L
N_SURR         <- 200L
N_SITES        <- 9L
N_YEARS        <- 60L
WIN_FRAC       <- 0.5
DETREND        <- "gaussian"
WINDOW_LEN_15  <- 15L     # primary rolling window for spatial indicators
SEED_BASE      <- 20260519L
SCENARIOS      <- c("approaching_fold", "stationary")

# Synthetic straight-line coords: simulated sites, no real geography.
# Using cbind(1:9, 0) — 9 sites spaced 1 unit apart along a single axis.
# Documents that Moran's I here reflects only the linear ordering of
# simulated sites, not real HG section geography.
SYNTH_COORDS   <- cbind(seq_len(N_SITES), 0)

cat(sprintf("n_rep = %d | n_surr = %d | n_years = %d | n_sites = %d\n",
            N_REP, N_SURR, N_YEARS, N_SITES))
cat(sprintf("win_frac = %.2f | detrend = '%s' | spatial window = %d yr\n",
            WIN_FRAC, DETREND, WINDOW_LEN_15))
cat(sprintf("Synth coords: cbind(1:%d, 0) — straight-line, no real geography\n\n",
            N_SITES))

# ---------------------------------------------------------------------------
# Spatial indicator rolling window helper
# Returns named numeric vectors (one value per rolling window position).
# Uses lm.fit fallback for MAR(1); MARSS skipped for speed in MC budget.
# Windows with any NA → mar1_eigen = NA_real_ (documented above).
# ---------------------------------------------------------------------------
compute_spatial_rolling <- function(mat, win_len, coords) {
  n_yr   <- nrow(mat)
  starts <- seq_len(max(0L, n_yr - win_len + 1L))
  n_win  <- length(starts)

  if (n_win == 0L) {
    return(list(phi        = NA_real_,
                eta        = NA_real_,
                spatial_var = NA_real_,
                morans_i   = NA_real_,
                eig_share  = NA_real_,
                mar1_eigen = NA_real_))
  }

  phi_v  <- numeric(n_win)
  eta_v  <- numeric(n_win)
  sv_v   <- numeric(n_win)
  mi_v   <- numeric(n_win)
  eig_v  <- numeric(n_win)
  mar1_v <- numeric(n_win)

  for (si in seq_along(starts)) {
    s <- starts[si]
    e <- s + win_len - 1L
    W <- mat[s:e, , drop = FALSE]

    phi_v[si]  <- tryCatch(ews_synchrony_phi(W),  error = function(e) NA_real_)
    eta_v[si]  <- tryCatch(ews_synchrony_eta(W),  error = function(e) NA_real_)

    sv_yr     <- vapply(seq_len(nrow(W)),
                        function(i) ews_spatial_variance(W[i, ]),
                        numeric(1L))
    sv_v[si]  <- if (any(is.finite(sv_yr))) mean(sv_yr, na.rm = TRUE) else NA_real_

    mi_yr     <- vapply(seq_len(nrow(W)),
                        function(i) tryCatch(
                          ews_morans_i(W[i, ], coords),
                          error = function(e) NA_real_),
                        numeric(1L))
    mi_v[si]  <- if (any(is.finite(mi_yr))) mean(mi_yr, na.rm = TRUE) else NA_real_

    ce        <- tryCatch(ews_cov_eigen(W),
                          error = function(e) list(lambda_max = NA_real_,
                                                   eig_share  = NA_real_))
    eig_v[si] <- if (!is.null(ce$eig_share)) ce$eig_share else NA_real_

    # MAR(1) via lm.fit (OLS VAR(1)); MARSS skipped for MC budget.
    # Windows with NA → NA_real_ (documented in header).
    mar1_v[si] <- tryCatch({
      if (anyNA(W)) {
        NA_real_
      } else {
        p  <- ncol(W)
        Yr <- W[-1L,       , drop = FALSE]
        Zr <- W[-nrow(W),  , drop = FALSE]
        cf <- stats::lm.fit(Zr, Yr)$coefficients
        if (anyNA(cf)) NA_real_
        else {
          B  <- t(matrix(cf, p, p))
          ev <- max(Mod(eigen(B, only.values = TRUE)$values))
          if (is.finite(ev)) ev else NA_real_
        }
      }
    }, error = function(e) NA_real_)
  }

  list(phi         = phi_v,
       eta         = eta_v,
       spatial_var = sv_v,
       morans_i    = mi_v,
       eig_share   = eig_v,
       mar1_eigen  = mar1_v)
}

# ---------------------------------------------------------------------------
# Single-rep function
# Returns tibble: indicator, tau, p_value
# ---------------------------------------------------------------------------
run_one_rep <- function(rep_idx, scenario, scenario_idx) {
  rep_seed <- SEED_BASE + scenario_idx * 100000L + rep_idx

  # Simulate metapopulation (no distortions — pure process)
  X <- tryCatch(
    ews_sim_metapop(n_sites  = N_SITES,
                    n_years  = N_YEARS,
                    scenario = scenario,
                    seed     = rep_seed),
    error = function(e) matrix(NA_real_, N_YEARS, N_SITES)
  )

  rows <- list()

  # --- Generic battery on aggregate biomass ---
  agg  <- rowSums(X, na.rm = TRUE)
  # If all sites NA in a year, aggregate is meaningless → set to NA
  all_na_yr <- apply(X, 1, function(r) all(is.na(r)))
  agg[all_na_yr] <- NA_real_

  batt <- tryCatch(
    ews_generic_battery(agg, win_frac = WIN_FRAC, detrend = DETREND),
    error = function(e) tibble::tibble()
  )

  generic_inds <- c("ar1", "variance", "sd", "skew", "kurtosis", "cv",
                    "densratio", "returnrate")

  for (ind in generic_inds) {
    traj <- if (ind %in% names(batt)) batt[[ind]] else NULL
    if (!is.null(traj) && any(is.finite(traj))) {
      ks <- tryCatch(
        ews_kendall_surrogate(traj, n_surr = N_SURR,
                              seed = rep_seed + match(ind, generic_inds) * 1000L),
        error = function(e) list(tau = NA_real_, p_value = NA_real_)
      )
    } else {
      ks <- list(tau = NA_real_, p_value = NA_real_)
    }
    rows[[length(rows) + 1L]] <- tibble::tibble(
      indicator = ind,
      tau       = ks$tau,
      p_value   = ks$p_value
    )
  }

  # --- Spatial indicators: 15-yr rolling window on site-level matrix ---
  si_res <- tryCatch(
    compute_spatial_rolling(X, WINDOW_LEN_15, SYNTH_COORDS),
    error = function(e)
      setNames(lapply(c("phi","eta","spatial_var","morans_i","eig_share","mar1_eigen"),
                      function(.) NA_real_),
               c("phi","eta","spatial_var","morans_i","eig_share","mar1_eigen"))
  )

  spatial_inds <- c("phi", "eta", "spatial_var", "morans_i",
                    "eig_share", "mar1_eigen")

  for (ind in spatial_inds) {
    traj <- si_res[[ind]]
    if (!is.null(traj) && any(is.finite(traj))) {
      ks <- tryCatch(
        ews_kendall_surrogate(traj, n_surr = N_SURR,
                              seed = rep_seed + WINDOW_LEN_15 * 100L +
                                       match(ind, spatial_inds) * 10000L),
        error = function(e) list(tau = NA_real_, p_value = NA_real_)
      )
    } else {
      ks <- list(tau = NA_real_, p_value = NA_real_)
    }
    rows[[length(rows) + 1L]] <- tibble::tibble(
      indicator = ind,
      tau       = ks$tau,
      p_value   = ks$p_value
    )
  }

  dplyr::bind_rows(rows)
}

# ---------------------------------------------------------------------------
# Run both scenarios
# ---------------------------------------------------------------------------
all_scenario_results <- vector("list", length(SCENARIOS))

for (sc_idx in seq_along(SCENARIOS)) {
  sc <- SCENARIOS[sc_idx]
  cat(sprintf("--- Scenario: %s (scenario_idx = %d) ---\n", sc, sc_idx))
  t_sc <- proc.time()["elapsed"]

  rep_list <- vector("list", N_REP)
  for (ri in seq_len(N_REP)) {
    if (ri %% 25L == 1L || ri == N_REP)
      cat(sprintf("  Rep %d / %d  [%.0f s elapsed]\n", ri, N_REP,
                  proc.time()["elapsed"] - t_sc))
    rep_list[[ri]] <- tryCatch(
      run_one_rep(ri, sc, sc_idx),
      error = function(e) tibble::tibble(indicator = character(0),
                                          tau       = double(0),
                                          p_value   = double(0))
    )
  }

  all_reps <- dplyr::bind_rows(rep_list, .id = "rep")
  all_scenario_results[[sc_idx]] <- all_reps |>
    dplyr::mutate(scenario = sc)

  t_sc_elapsed <- proc.time()["elapsed"] - t_sc
  cat(sprintf("  Done in %.0f s (%.1f min)\n\n", t_sc_elapsed, t_sc_elapsed / 60))
}

all_results <- dplyr::bind_rows(all_scenario_results)

# ---------------------------------------------------------------------------
# Summarise: per (scenario, indicator) detect_rate
# ---------------------------------------------------------------------------
cat("--- Summarising detect_rate per (scenario, indicator) ---\n")

power_summary <- all_results |>
  dplyr::group_by(scenario, indicator) |>
  dplyr::summarise(
    n_rep          = dplyr::n(),
    n_finite_traj  = sum(is.finite(tau) & is.finite(p_value)),
    detect_rate    = mean(p_value < 0.05 & tau > 0, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(scenario, indicator)

# ---------------------------------------------------------------------------
# Validity gate logic
# For each (scenario, indicator):
#   stationary:      PASS if detect_rate < 0.25
#   approaching_fold: PASS if detect_rate > 0.60
#   power_gate_pass is the per-indicator verdict (used in the md narrative
#   to explain the two-gate system — md interprets across indicators)
# ---------------------------------------------------------------------------
power_summary <- power_summary |>
  dplyr::mutate(
    power_gate_pass = dplyr::case_when(
      scenario == "stationary"       ~ detect_rate < 0.25,
      scenario == "approaching_fold" ~ detect_rate > 0.60,
      TRUE ~ NA
    )
  )

cat("\nPer-(scenario, indicator) detect_rate:\n")
print(power_summary, n = Inf)

# ---------------------------------------------------------------------------
# Write CSV
# ---------------------------------------------------------------------------
out_csv <- file.path(diag_dir, "ews_controls_power.csv")
readr::write_csv(power_summary, out_csv)
cat(sprintf("\nWritten: %s\n", out_csv))

# ---------------------------------------------------------------------------
# Gate-level verdicts for the report
# ---------------------------------------------------------------------------

# Gate A — stationary: ALL indicators must have detect_rate < 0.25
gate_a <- power_summary |>
  dplyr::filter(scenario == "stationary") |>
  dplyr::summarise(
    gate_pass      = all(detect_rate < 0.25, na.rm = TRUE),
    n_fail         = sum(detect_rate >= 0.25, na.rm = TRUE),
    max_detect     = max(detect_rate, na.rm = TRUE),
    fail_inds      = paste(indicator[detect_rate >= 0.25], collapse = ", "),
    .groups = "drop"
  )

# Gate B — approaching_fold: phi AND eig_share AND (ar1 OR variance) > 0.6
fold_dr <- power_summary |>
  dplyr::filter(scenario == "approaching_fold") |>
  dplyr::select(indicator, detect_rate)

gate_b_phi      <- fold_dr |> dplyr::filter(indicator == "phi")      |> dplyr::pull(detect_rate)
gate_b_eig      <- fold_dr |> dplyr::filter(indicator == "eig_share")|> dplyr::pull(detect_rate)
gate_b_ar1      <- fold_dr |> dplyr::filter(indicator == "ar1")      |> dplyr::pull(detect_rate)
gate_b_var      <- fold_dr |> dplyr::filter(indicator == "variance") |> dplyr::pull(detect_rate)

gate_b_phi_ok   <- length(gate_b_phi) > 0 && gate_b_phi  > 0.60
gate_b_eig_ok   <- length(gate_b_eig) > 0 && gate_b_eig  > 0.60
gate_b_ar1_ok   <- length(gate_b_ar1) > 0 && gate_b_ar1  > 0.60
gate_b_var_ok   <- length(gate_b_var) > 0 && gate_b_var  > 0.60
gate_b_pass     <- gate_b_phi_ok && gate_b_eig_ok && (gate_b_ar1_ok || gate_b_var_ok)

gate_a_str <- if (gate_a$gate_pass) "PASS" else "FAIL"
gate_b_str <- if (gate_b_pass) "PASS" else "FAIL"

cat(sprintf("\nGate A (stationary FP < 0.25): %s (max = %.3f, n_fail = %d)\n",
            gate_a_str, gate_a$max_detect, gate_a$n_fail))
cat(sprintf("Gate B (fold: phi & eig_share & (ar1|var) > 0.60): %s\n",
            gate_b_str))
cat(sprintf("  phi=%.3f  eig_share=%.3f  ar1=%.3f  variance=%.3f\n\n",
            if (length(gate_b_phi) > 0) gate_b_phi else NA,
            if (length(gate_b_eig) > 0) gate_b_eig else NA,
            if (length(gate_b_ar1) > 0) gate_b_ar1 else NA,
            if (length(gate_b_var) > 0) gate_b_var else NA))

# ---------------------------------------------------------------------------
# Build markdown narrative
# ---------------------------------------------------------------------------
cat("--- Writing ews_controls_power.md ---\n")

# Build per-indicator table (both scenarios together, wide)
tbl_wide <- power_summary |>
  dplyr::select(scenario, indicator, detect_rate, n_rep, n_finite_traj, power_gate_pass) |>
  dplyr::mutate(
    detect_rate    = round(detect_rate, 3),
    power_gate_pass = as.character(power_gate_pass)
  )

# Validity gate verdict lines (per indicator, two gates)
stationary_dr <- power_summary |>
  dplyr::filter(scenario == "stationary") |>
  dplyr::select(indicator, stat_dr = detect_rate, stat_n_fin = n_finite_traj)

fold_dr_full <- power_summary |>
  dplyr::filter(scenario == "approaching_fold") |>
  dplyr::select(indicator, fold_dr = detect_rate, fold_n_fin = n_finite_traj)

verdict_joined <- dplyr::full_join(stationary_dr, fold_dr_full, by = "indicator") |>
  dplyr::arrange(indicator)

verdict_lines <- character(nrow(verdict_joined))
for (i in seq_len(nrow(verdict_joined))) {
  vr      <- verdict_joined[i, ]
  ind     <- vr$indicator
  s_dr    <- if (is.na(vr$stat_dr))  "NA" else sprintf("%.3f", vr$stat_dr)
  f_dr    <- if (is.na(vr$fold_dr)) "NA" else sprintf("%.3f", vr$fold_dr)
  s_ok    <- !is.na(vr$stat_dr) && vr$stat_dr < 0.25
  f_ok    <- !is.na(vr$fold_dr) && vr$fold_dr > 0.60

  s_tag   <- if (is.na(vr$stat_dr)) "N/A" else if (s_ok) "PASS (FP < 0.25)" else "FAIL (FP >= 0.25)"
  f_tag   <- if (is.na(vr$fold_dr)) "N/A" else if (f_ok) "PASS (power > 0.60)" else "WEAK (power <= 0.60)"

  verdict_lines[i] <- sprintf(
    "- **%s**: stationary FP = %s [%s]; fold power = %s [%s]",
    ind, s_dr, s_tag, f_dr, f_tag
  )
}

# MD table header
tbl_header <- paste(
  "| scenario | indicator | detect_rate | n_rep | n_finite_traj | power_gate_pass |",
  "| --- | --- | --- | --- | --- | --- |",
  sep = "\n"
)
tbl_rows <- paste(
  sprintf("| %s | %s | %.3f | %d | %d | %s |",
          tbl_wide$scenario,
          tbl_wide$indicator,
          as.numeric(tbl_wide$detect_rate),
          tbl_wide$n_rep,
          tbl_wide$n_finite_traj,
          tbl_wide$power_gate_pass),
  collapse = "\n"
)
tbl_full <- paste(tbl_header, tbl_rows, sep = "\n")

timing_total <- proc.time()["elapsed"]
timing_str   <- sprintf("%.0f s (%.1f min)", timing_total, timing_total / 60)

md_lines <- c(
  "# EWS Power & False-Positive Controls",
  "",
  sprintf("Generated: %s", format(Sys.time())),
  "",
  "---",
  "",
  "## Simulator",
  "",
  paste0(
    "Simulations generated by `ews_sim_metapop()` (R/11_early_warning.R) with ",
    "`n_sites = ", N_SITES, "`, `n_years = ", N_YEARS, "` for two scenarios: ",
    "`approaching_fold` (positive control for genuine CSD) and `stationary` ",
    "(null control for false-positive calibration). ",
    "**No observation distortions applied** — this isolates intrinsic battery power ",
    "from survey-artifact confounding (that is handled separately in Task 4.3). ",
    "n_rep = ", N_REP, " realisations per scenario; seeds: ", SEED_BASE, "L + scenario_idx×100000 + rep_idx. ",
    "n_surr = ", N_SURR, " AR(1)-surrogate permutations per Kendall τ."
  ),
  "",
  paste0(
    "**Generic battery** (`ews_generic_battery()`) runs on aggregate biomass ",
    "(rowSums) with `win_frac = ", WIN_FRAC, "`, `detrend = '", DETREND, "'`. ",
    "**Spatial indicators** (`ews_synchrony_phi`, `ews_synchrony_eta`, ",
    "`ews_spatial_variance`, `ews_morans_i`, `ews_cov_eigen`, `ews_mar1_eigen`) ",
    "run per 15-year rolling window on the site-level matrix. ",
    "Moran's I uses a **synthetic straight-line coordinate matrix** `cbind(1:", N_SITES, ", 0)` ",
    "— simulated sites have no real Haida Gwaii geography; this reflects only ",
    "the linear ordering of the 9 sites and is documented as such. ",
    "MAR(1) uses an inline `lm.fit` OLS VAR(1) fallback (MARSS skipped for the ",
    "200-rep × 200-surr Monte Carlo budget); windows with any NA return `NA_real_` ",
    "for `mar1_eigen`."
  ),
  sprintf("  \n*Runtime: %s*", timing_str),
  "",
  "---",
  "",
  "## Per-indicator power / false-positive table",
  "",
  paste0(
    "`detect_rate` = mean(p < 0.05 & τ > 0) across reps. ",
    "`power_gate_pass` = TRUE if stationary detect_rate < 0.25 (FP gate) ",
    "or approaching_fold detect_rate > 0.60 (power gate)."
  ),
  "",
  tbl_full,
  "",
  "---",
  "",
  "## Validity gate verdict per indicator",
  "",
  paste0(
    "Two gates (Task 1.8 / plan spec §5.4):",
    "\n- **Gate A (FP control):** stationary detect_rate < 0.25 for every indicator.",
    sprintf("\n  Overall verdict: **%s** (max FP = %.3f", gate_a_str, gate_a$max_detect),
    if (gate_a$n_fail > 0) sprintf("; failing indicators: %s", gate_a$fail_inds) else "",
    ")",
    "\n- **Gate B (power):** approaching_fold detect_rate > 0.60 for φ AND eig_share AND (ar1 OR variance).",
    sprintf("\n  Overall verdict: **%s** (φ = %.3f, eig_share = %.3f, ar1 = %.3f, variance = %.3f)",
            gate_b_str,
            if (length(gate_b_phi) > 0) gate_b_phi else NA,
            if (length(gate_b_eig) > 0) gate_b_eig else NA,
            if (length(gate_b_ar1) > 0) gate_b_ar1 else NA,
            if (length(gate_b_var) > 0) gate_b_var else NA)
  ),
  "",
  "Per-indicator breakdown:",
  "",
  paste(verdict_lines, collapse = "\n"),
  "",
  "---",
  "",
  "## Important caveat",
  "",
  paste0(
    "**φ rise in the fold scenario is partly coupling-driven (confounded positive control).**\n\n",
    "In `ews_sim_metapop()`, the `approaching_fold` scenario increases inter-site coupling ",
    "from 0.02 to 0.60 (a ~30× increase) while the idiosyncratic noise standard deviation ",
    "decreases from 3 to near 0 (as `3*(1-cpl)`). The shared:idiosyncratic noise ratio ",
    "therefore rises approximately 75-fold across the simulation. ",
    "This means that synchrony-based EWS indicators (φ, η, eig_share) will detect a strong ",
    "positive trend in the positive control — but that trend is **at least partly driven by ",
    "coupling amplification**, not exclusively by critical slowing down (CSD). ",
    "These indicators will therefore achieve high power (detect_rate) in Gate B, but their ",
    "positive control is partially confounded with a structural change in the noise architecture ",
    "of the simulator rather than pure CSD.\n\n",
    "Conversely, AR1 and variance are calibrated against a positive control where the CSD ",
    "signal competes with declining idiosyncratic noise — the aggregate AR1 trend may be ",
    "compressed relative to a purely CSD-driven simulation. **Weak AR1/variance power in ",
    "Gate B does NOT mean the battery cannot detect CSD** — it means the positive control ",
    "is itself a partially-confounded benchmark. This distinction is critical for interpreting ",
    "the HG observed-vs-latent claim-control in Phase 5."
  ),
  "",
  "---",
  "",
  "## Implications for the HG observed-vs-latent claim-control",
  "",
  paste0(
    "The Gate B results above identify which indicators have genuine intrinsic power ",
    "under the positive control, and which are weak. When interpreting HG EWS results:\n\n",
    "- **Indicators with strong fold power (detect_rate > 0.60):** a significant positive ",
    "τ in HG observed or latent data is informative — the indicator has demonstrated ",
    "sensitivity to approaching-fold dynamics in simulations of comparable dimensionality. ",
    "A null result (non-significant τ) for one of these indicators IS meaningful evidence ",
    "against a fold-approaching trajectory.\n\n",
    "- **Indicators with weak fold power (detect_rate ≤ 0.60):** the battery itself is ",
    "insensitive in the positive control. A null result for these indicators in HG data ",
    "should NOT be claimed as 'system is resilient' — the battery may simply lack power. ",
    "A significant positive τ for a weak-power indicator is harder to interpret (battery ",
    "rarely detects it under simulated CSD, so what produces the HG signal?).\n\n",
    "- **Synchrony indicators (φ, η, eig_share):** interpret all fold-power figures ",
    "with the caveat above — high power partly reflects coupling amplification, not ",
    "exclusively CSD. A significant φ in HG data is consistent with both approaching-fold ",
    "CSD and with coupling-regime change (e.g. climate forcing). Claim language must reflect ",
    "this ambiguity and cite the Task 1.8 coupling-confound note."
  ),
  "",
  "---",
  "",
  sprintf("*Script*: `Code/11_ews_08_controls_power.R` (Task 4.4)")
)

out_md <- file.path(diag_dir, "ews_controls_power.md")
writeLines(md_lines, out_md)
cat(sprintf("Written: %s\n\n", out_md))

# ---------------------------------------------------------------------------
# Final sanity print
# ---------------------------------------------------------------------------
cat("=== Final sanity summary ===\n")
cat(sprintf("  Runtime: %s\n", timing_str))
cat(sprintf("  Scenarios: %s\n", paste(SCENARIOS, collapse = ", ")))
cat(sprintf("  Indicators per scenario: %d\n",
            nrow(power_summary) / length(SCENARIOS)))
cat(sprintf("  Gate A (FP control): %s\n", gate_a_str))
cat(sprintf("  Gate B (power): %s\n", gate_b_str))

cat("\nDetect-rate table (approaching_fold):\n")
print(
  power_summary |>
    dplyr::filter(scenario == "approaching_fold") |>
    dplyr::select(indicator, detect_rate, n_finite_traj, power_gate_pass) |>
    dplyr::arrange(dplyr::desc(detect_rate)),
  n = Inf
)

cat("\nDetect-rate table (stationary):\n")
print(
  power_summary |>
    dplyr::filter(scenario == "stationary") |>
    dplyr::select(indicator, detect_rate, n_finite_traj, power_gate_pass) |>
    dplyr::arrange(dplyr::desc(detect_rate)),
  n = Inf
)

cat("\nDone.\n")
