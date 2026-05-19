# ============================================================================
# 12_reversibility.R — Reversibility / hysteresis / alternative-state library
# stier-2027-herring-metapopulation
#
# Pure functions only — no I/O, no plotting, no library() calls.
# All package calls use pkg::fn() namespace form.
#
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md
# ============================================================================

#' Exploitation-rate driver: u = annual total catch / latent biomass.
#' Zero/NA biomass -> NA (never Inf); inner-joined on year.
exploitation_rate <- function(catch_by_year, biomass_by_year) {
  m <- merge(catch_by_year, biomass_by_year, by = "year")
  m <- m[order(m$year), ]
  b <- m$biomass
  m$u <- ifelse(is.na(b) | b <= 0, NA_real_, m$total_catch / b)
  m[, c("year", "total_catch", "biomass", "u")]
}

#' Effective (net) control parameter: standardize each component to z-scores
#' and average. Used ONLY for the discrimination layer (spec §2.4 explanation
#' ii). Components are provenance-tagged; predator inputs are context-only.
effective_driver <- function(df, components, provenance = character()) {
  missing <- setdiff(components, names(df))
  if (length(missing)) {
    stop("effective_driver: component(s) not in df: ",
         paste(missing, collapse = ", "))
  }
  if (!length(components)) stop("effective_driver: 'components' is empty")
  z <- function(v) {
    s <- stats::sd(v, na.rm = TRUE)
    # All-NA component (covariate absent for this series): emit NA so
    # rowMeans(na.rm=TRUE) EXCLUDES it -- a missing covariate must not
    # bias the composite toward zero.
    if (is.na(s)) return(rep(NA_real_, length(v)))
    # Present constant column (real data, zero variance): a present
    # constant legitimately contributes a zero z-score.
    if (s == 0) return(rep(0, length(v)))
    (v - mean(v, na.rm = TRUE)) / s
  }
  Z <- vapply(components, function(cn) z(df[[cn]]), numeric(nrow(df)))
  raw <- rowMeans(Z, na.rm = TRUE)
  # All-NA row -> rowMeans returns NaN; emit NA, never a silent number.
  df$effective_driver <- ifelse(is.nan(raw), NA_real_, raw)
  attr(df, "provenance") <- as.list(provenance)
  attr(df, "components") <- components
  df
}

#' Objective candidate regime-shift points via PELT mean+variance change
#' (changepoint::cpt.meanvar). Self-contained copy of the EWS-shared util;
#' Phase 9 records the dedupe obligation. `index` = position in the ORIGINAL
#' x/years (NA-safe: maps back through the finite filter). Returns a 0-row
#' data.frame (year/index/kind columns present) when < 4 finite values.
detect_candidate_transitions <- function(x, years, penalty = "MBIC") {
  stopifnot(length(x) == length(years))
  ok <- is.finite(x)
  if (sum(ok) < 4L) {
    return(data.frame(year = integer(0), index = integer(0),
                      kind = character(0)))
  }
  cp <- changepoint::cpt.meanvar(as.numeric(x[ok]), method = "PELT",
                                 penalty = penalty)
  idx <- changepoint::cpts(cp)
  orig <- which(ok)
  idx_orig <- orig[idx]
  data.frame(year = years[idx_orig], index = idx_orig,
             kind = rep("meanvar_PELT", length(idx)))
}

# ============================================================================
# EDM functions (Tasks 6-9) — rEDM 1.15.4 dataFrame= interface
# ============================================================================

#' Simplex projection (rEDM): optimal embedding dimension E and predictability
#' rho. Theiler window via exclusionRadius for autocorrelation.
#'
#' @param x  Numeric vector (univariate time series).
#' @param E_max  Maximum E to search (default 8).
#' @param theiler  Theiler exclusion window (default 1).
#' @return  Named list: E_best (integer), rho_best (numeric),
#'          rho_by_E (data.frame with columns E and rho from rEDM::EmbedDimension).
edm_embed <- function(x, E_max = 8, theiler = 1) {
  df   <- data.frame(t = seq_along(x), x = as.numeric(x))
  half <- floor(nrow(df) / 2)
  s <- rEDM::EmbedDimension(
    dataFrame       = df,
    lib             = c(1, half),
    pred            = c(half + 1, nrow(df)),
    columns         = "x",
    target          = "x",
    maxE            = E_max,
    exclusionRadius = theiler,
    showPlot        = FALSE
  )
  list(
    E_best    = s$E[which.max(s$rho)],
    rho_best  = max(s$rho, na.rm = TRUE),
    rho_by_E  = s
  )
}

#' Ebisuzaki (1997) phase-randomised surrogate: preserves amplitude spectrum,
#' destroys nonlinear structure.  Internal helper.
.ebisuzaki <- function(x) {
  n  <- length(x)
  ft <- stats::fft(x)
  # Draw random phases for the positive-frequency half
  n_half <- floor((n - 1) / 2)
  ph  <- stats::runif(n_half, 0, 2 * pi)
  amp <- Mod(ft)[seq(2, n_half + 1)]
  re  <- amp * cos(ph)
  im  <- amp * sin(ph)
  half <- complex(real = re, imaginary = im)
  # Reconstruct full spectrum (Hermitian symmetry)
  nyq <- if (n %% 2 == 0) Re(ft[n / 2 + 1]) else NULL
  spec <- c(Re(ft[1]), half, nyq, Conj(rev(half)))
  Re(stats::fft(spec, inverse = TRUE) / n)
}

#' S-map nonlinearity test with Ebisuzaki surrogate distribution.
#'
#' PredictNonlinear output uses columns Theta and rho (rEDM 1.15.4).
#' Theta = 0 is not produced; the minimum Theta (0.01) is used as the
#' linear baseline (rho_theta0).
#'
#' @param x      Numeric vector (univariate time series).
#' @param E      Embedding dimension (integer).
#' @param n_surr Number of Ebisuzaki surrogates (default 200).
#' @param seed   Random seed for surrogates (reproducibility).
#' @return Named list: rho_theta0 (rho at min theta), rho_theta_best,
#'         delta (rho_best - rho0), p_value (one-sided surrogate test).
smap_nonlinearity <- function(x, E, n_surr = 200, seed) {
  set.seed(seed)
  .fit <- function(v) {
    df   <- data.frame(t = seq_along(v), x = as.numeric(scale(v)))
    half <- floor(nrow(df) / 2)
    s <- rEDM::PredictNonlinear(
      dataFrame = df,
      lib       = c(1, half),
      pred      = c(half + 1, nrow(df)),
      columns   = "x",
      target    = "x",
      E         = E,
      showPlot  = FALSE
    )
    # rEDM 1.15.4: smallest Theta is 0.01, not 0 — use it as linear baseline
    c(rho0 = s$rho[which.min(s$Theta)],
      rhob = max(s$rho, na.rm = TRUE))
  }
  obs       <- .fit(x)
  delta_obs <- obs["rhob"] - obs["rho0"]
  surr <- replicate(n_surr, {
    f <- .fit(.ebisuzaki(x))
    f["rhob"] - f["rho0"]
  })
  list(
    rho_theta0    = unname(obs["rho0"]),
    rho_theta_best = unname(obs["rhob"]),
    delta         = unname(delta_obs),
    p_value       = (1 + sum(surr >= delta_obs)) / (1 + n_surr)
  )
}

#' Survey-method false-positive generator: a series with NO resilience change
#' but the documented two-era catchability shift + lognormal obs error.
#' Self-contained copy of the EWS-shared util (Phase 9 dedupe).
#' Calls set.seed(seed): advances the global RNG state (deterministic by design).
survey_artifact_null <- function(truth, era_break, q, cv = 0.2, seed) {
  stopifnot(length(q) == 2L)
  set.seed(seed)
  n <- length(truth)
  qv <- ifelse(seq_len(n) <= era_break, q[1], q[2])
  obs <- qv * truth * stats::rlnorm(n, -0.5 * cv^2, cv)
  as.numeric(obs)
}
