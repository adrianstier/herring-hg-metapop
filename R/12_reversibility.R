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
#'          Spec §7 short-series guard: < 2*E_max + 2 finite points returns the
#'          NA-shaped contract (E_best=NA, rho_best=NA, 0-row rho_by_E).
edm_embed <- function(x, E_max = 8, theiler = 1) {
  if (sum(is.finite(x)) < 2L * E_max + 2L) {
    return(list(
      E_best   = NA_integer_,
      rho_best = NA_real_,
      rho_by_E = data.frame(E = integer(0), rho = numeric(0))
    ))
  }
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
    E_best    = as.integer(s$E[which.max(s$rho)]),
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
#'         Spec §7 short-series guard: < 2*E + 2 finite points returns the
#'         all-NA contract.
smap_nonlinearity <- function(x, E, n_surr = 200, seed) {
  if (sum(is.finite(x)) < 2L * E + 2L) {
    return(list(
      rho_theta0     = NA_real_,
      rho_theta_best = NA_real_,
      delta          = NA_real_,
      p_value        = NA_real_
    ))
  }
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

#' S-map time-varying Jacobian: |lambda_max(t)| from local linear coefficients.
#'
#' rEDM 1.15.4 SMap coefficients frame: columns are t, C0 (intercept), then
#' partial-derivative columns named "dx/dx(t-0)", "dx/dx(t-1)", etc. (unicode ∂).
#' The Jacobian row is assembled from those partial-derivative columns only;
#' companion-form eigenvalue is returned.
#'
#' The coefficients frame may have up to n+1 rows and the last row's t may
#' exceed length(x). We left-join onto t = 1:length(x) so the returned frame
#' has exactly length(x) rows; early/edge rows without SMap estimates are NA.
#'
#' @param x      Numeric vector (univariate time series).
#' @param E      Embedding dimension (integer >= 1).
#' @param theta  S-map localisation parameter (0 = global/linear).
#' @return  data.frame with columns t (integer, 1..length(x)) and lambda_max
#'          (numeric, NA where SMap could not estimate).
#'          Spec §7 short-series guard: < 2*E + 2 finite points returns an
#'          all-NA data.frame of length length(x) (length contract preserved).
smap_jacobian_eigen <- function(x, E, theta = 2) {
  n  <- length(x)
  if (sum(is.finite(x)) < 2L * E + 2L) {
    return(data.frame(t = seq_len(n), lambda_max = rep(NA_real_, n)))
  }
  df <- data.frame(t = seq_len(n), x = as.numeric(x))
  sm <- rEDM::SMap(
    dataFrame = df,
    lib       = c(1, n),
    pred      = c(1, n),
    columns   = "x",
    target    = "x",
    E         = E,
    theta     = theta,
    embedded  = FALSE,
    showPlot  = FALSE
  )
  co <- sm$coefficients
  # Jacobian columns: exclude the time index ("t") and constant term ("C0").
  # rEDM 1.15.4 uses unicode partial-derivative names; exclude by position/name.
  jcols <- setdiff(names(co), c("t", "C0"))
  # Restrict to t values within the original series (coefficients may have
  # one extra row at t = n+1 for the one-step-ahead prediction).
  co_in <- co[co$t <= n, , drop = FALSE]
  # Left-join onto the full t = 1..n index so length is always n.
  base  <- data.frame(t = seq_len(n))
  merged <- merge(base, co_in[, c("t", jcols), drop = FALSE],
                  by = "t", all.x = TRUE, sort = TRUE)
  # Compute |lambda_max| from the companion-form Jacobian for each time step.
  lam <- apply(merged[, jcols, drop = FALSE], 1, function(r) {
    if (any(is.na(r))) return(NA_real_)
    if (length(r) == 1L) return(abs(r))
    J <- rbind(r, cbind(diag(length(r) - 1L), 0))
    max(Mod(eigen(J, only.values = TRUE)$values))
  })
  data.frame(t = seq_len(n), lambda_max = as.numeric(lam))
}

#' Convergent cross-mapping (rEDM) for causal attribution.
#'
#' rEDM 1.15.4 CCM output: columns LibSize, "<columns>:<target>", "<target>:<columns>".
#' The causal-direction cross-map rho is "<columns>:<target>", which is the rho
#' for "target shadow manifold predicts columns" — i.e. target xmap driver —
#' confirming driver -> target causality (Sugihara et al. 2012).
#'
#' libSizes argument: string "start end step" (rEDM 1.15.4 API).
#' Maximum library size is constrained to n - E - 1 to avoid rEDM error.
#'
#' Determinism (spec §8): `seed` is REQUIRED (no default) — set.seed(seed) is
#' called before the driver loop AND passed to rEDM::CCM(seed=) (CCM's internal
#' sampler is NOT governed by the global RNG), so the discrimination table that
#' consumes this output is fully reproducible.
#'
#' Discrimination gate (spec §2.4): use `converges_strict` — TRUE iff
#' (a) rho increases monotonically with library size
#'     (Kendall rank test of rho vs ascending libSize, p < 0.05) AND
#' (b) rho_max > 0.2 (rho floor).
#' `rho_max` is the primary magnitude criterion. `converges_heuristic`
#' (Δρ = rho_max - rho_min > 0.1) is a NON-AUTHORITATIVE supporting flag —
#' it is false-positive-prone on short/noisy series (an independent series can
#' show a spurious Δρ > 0.1) and MUST NOT be used as the discrimination gate.
#'
#' @param target    Numeric vector (response time series).
#' @param drivers   Named list of numeric vectors (candidate drivers; same length as target).
#' @param E         Embedding dimension (integer).
#' @param seed      REQUIRED integer seed (reproducibility; spec §8).
#' @param libSizes  NULL (auto) or a custom libSizes string passed to rEDM::CCM.
#' @return  data.frame: driver (character), rho_min, rho_max,
#'          converges_strict (logical; the authoritative gate),
#'          converges_heuristic (logical; non-authoritative legacy Δρ>0.1 flag).
ccm_drivers <- function(target, drivers, E, seed, libSizes = NULL) {
  set.seed(seed)
  n <- length(target)
  # Max lib size: n - E - 1 (rEDM requires libSize < n - E - Tp, Tp=0 default)
  max_lib <- n - E - 1L
  step    <- max(5L, floor(max_lib / 10L))
  if (is.null(libSizes)) libSizes <- paste(E + 2L, max_lib, step)
  res <- lapply(names(drivers), function(nm) {
    df <- data.frame(
      t   = seq_len(n),
      tgt = as.numeric(target),
      drv = as.numeric(drivers[[nm]])
    )
    cm <- rEDM::CCM(
      dataFrame = df,
      E         = E,
      columns   = "tgt",
      target    = "drv",
      libSizes  = libSizes,
      sample    = 100,
      seed      = seed,    # rEDM CCM sampler is not governed by global RNG
      showPlot  = FALSE
    )
    # Pick the cross-map rho column: "tgt:drv" (tgt xmap drv).
    # In rEDM 1.15.4 this is "<columns>:<target>" = "tgt:drv".
    rcol <- grep(":", names(cm), value = TRUE)[1]
    rho  <- cm[[rcol]]                     # ascending libSize trajectory
    rho_max <- rho[length(rho)]
    # converges_strict: monotone rho-vs-libSize (Kendall) AND rho floor.
    kendall_p <- suppressWarnings(
      stats::cor.test(seq_along(rho), rho, method = "kendall")$p.value
    )
    converges_strict <- isTRUE(kendall_p < 0.05) && isTRUE(rho_max > 0.2)
    data.frame(
      driver              = nm,
      rho_min             = rho[1L],
      rho_max             = rho_max,
      converges_strict    = converges_strict,
      converges_heuristic = (rho_max - rho[1L]) > 0.1
    )
  })
  do.call(rbind, res)
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
