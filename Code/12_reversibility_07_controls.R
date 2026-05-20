#!/usr/bin/env Rscript
# Code/12_reversibility_07_controls.R
# Task 21: Power calibration — multi-seed reversibility_controls() loop.
#
# PRIMARY criterion (positive control): lambda_trend > 0 at canonical seed 20260519.
# SECONDARY (non-hard-gate): nl_p < 0.05 — reported but never a pass/fail gate
#   because S-map theta nonlinearity is underpowered at n~70.
# NEGATIVE control: nonlinearity_detected == FALSE AND lambda_trend ~ 0 (no CSD).
#
# Seeds looped: canonical 20260519 plus 11 additional seeds.
# Non-zero exit (quit(status=1)) if PRIMARY fails at canonical seed.
#
# Output:
#   Output/diagnostics/reversibility_controls.md
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md

source("R/12_reversibility.R")

CANONICAL_SEED <- 20260519L

## Seeds to loop (canonical first, then additional)
seeds <- c(CANONICAL_SEED, 1L, 2L, 3L, 4L, 5L, 7L, 11L, 21L, 42L, 99L, 123L)

## --- run controls across all seeds ------------------------------------------
results <- lapply(seeds, function(s) {
  ctrl <- reversibility_controls(seed = s, n = 70)
  data.frame(
    seed                  = s,
    is_canonical          = (s == CANONICAL_SEED),
    ## positive control
    pos_nonlinear_sig     = isTRUE(ctrl$positive$nonlinearity_detected),
    pos_nl_p              = ctrl$positive$nl_p,
    pos_nl_delta          = ctrl$positive$nl_delta,
    pos_lambda_trend      = ctrl$positive$lambda_trend,
    pos_primary_pass      = isTRUE(ctrl$positive$lambda_trend > 0),
    ## negative control
    neg_nonlinear_sig     = isTRUE(ctrl$negative$nonlinearity_detected),
    neg_nl_p              = ctrl$negative$nl_p,
    neg_nl_delta          = ctrl$negative$nl_delta,
    neg_lambda_trend      = ctrl$negative$lambda_trend,
    neg_primary_pass      = isTRUE(!ctrl$negative$nonlinearity_detected &&
                                    is.finite(ctrl$negative$lambda_trend) &&
                                    abs(ctrl$negative$lambda_trend) < 0.01),
    stringsAsFactors = FALSE
  )
})
ctrl_tab <- do.call(rbind, results)
rownames(ctrl_tab) <- NULL

## --- summarise ---------------------------------------------------------------
canonical <- ctrl_tab[ctrl_tab$is_canonical, ]
n_pos_pass <- sum(ctrl_tab$pos_primary_pass, na.rm = TRUE)
n_seeds    <- nrow(ctrl_tab)

canonical_primary_pass <- isTRUE(canonical$pos_primary_pass)

## --- write output -----------------------------------------------------------
dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)

lines <- c(
  "# Reversibility Controls — Power Calibration",
  "",
  paste0("Generated: ", Sys.time()),
  paste0("Canonical seed: ", CANONICAL_SEED),
  paste0("Seeds tested: ", n_seeds),
  "",
  "## Summary",
  "",
  paste0("- Positive control PRIMARY criterion (lambda_trend > 0): ",
         n_pos_pass, "/", n_seeds, " seeds pass"),
  paste0("- Canonical seed PRIMARY pass: ", canonical_primary_pass),
  "",
  paste0("- Canonical seed pos_lambda_trend  = ",
         sprintf("%.4f", canonical$pos_lambda_trend)),
  paste0("- Canonical seed pos_nl_p          = ",
         sprintf("%.3f", canonical$pos_nl_p),
         " (SECONDARY — not a gate)"),
  paste0("- Canonical seed neg_nonlinear_sig = ",
         canonical$neg_nonlinear_sig),
  paste0("- Canonical seed neg_lambda_trend  = ",
         sprintf("%.4f", canonical$neg_lambda_trend)),
  "",
  "## Design Notes",
  "",
  "PRIMARY criterion: positive control lambda_trend > 0 (pre-transition Jacobian",
  "eigenvalue rising as fold is approached — critical slowing down signature).",
  "",
  "SECONDARY criterion: S-map nonlinearity (nl_p < 0.05). Reported only; underpowered",
  "at n=70 (slow-passage slow-transition regime). Never used as a hard pass/fail gate.",
  "",
  "Negative control target: nonlinearity_detected = FALSE AND lambda_trend ~ 0",
  "(linear-stochastic OU/AR(1); no directional eigenvalue trend).",
  "",
  "Non-zero exit (status=1) fires if PRIMARY fails at canonical seed 20260519.",
  "",
  "## Per-Seed Results",
  "",
  "| seed | canonical | pos_lam_trend | pos_primary | neg_nonlin | neg_lam_trend |",
  "|------|-----------|--------------|-------------|------------|--------------|",
  ## M-2: vapply over rows (per-column typed access) instead of apply(),
  ## which coerces the whole data.frame to a character matrix. Rendered
  ## table is identical.
  vapply(seq_len(nrow(ctrl_tab)), function(i) {
    r <- ctrl_tab[i, ]
    sprintf("| %d | %s | %.4f | %s | %s | %.4f |",
            r$seed, r$is_canonical, r$pos_lambda_trend,
            r$pos_primary_pass, r$neg_nonlinear_sig, r$neg_lambda_trend)
  }, character(1L)),
  ""
)

writeLines(lines, "Output/diagnostics/reversibility_controls.md")

## --- sanity print -----------------------------------------------------------
cat(sprintf(
  "[reversibility] controls: canonical=%d pos_primary=%s pos_lambda=%.4f | neg_nonlin=%s | %d/%d seeds pos-PRIMARY-pass\n",
  CANONICAL_SEED,
  canonical_primary_pass,
  canonical$pos_lambda_trend,
  canonical$neg_nonlinear_sig,
  n_pos_pass, n_seeds
))

## --- gate: non-zero exit if canonical PRIMARY fails -------------------------
if (!canonical_primary_pass) {
  cat(sprintf(
    "FATAL: PRIMARY criterion failed at canonical seed %d: pos_lambda_trend=%.4f (must be > 0)\n",
    CANONICAL_SEED, canonical$pos_lambda_trend
  ))
  quit(status = 1L)
}
