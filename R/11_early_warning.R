# ============================================================================
# 11_early_warning.R — Early-warning-signal indicator library
# stier-2027-herring-metapopulation
#
# Pure functions only — no I/O, no plotting, no library() calls.
# All package calls use pkg::fn() namespace form.
#
# Spec: docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md
# ============================================================================

#' Loreau & de Mazancourt (2008) synchrony index phi
#'
#' phi = var(rowSums(mat)) / (sum_j sd(X_j))^2
#'
#' Mirrors the valid-column logic of R/05_portfolio.R::compute_synchrony_lm:
#' columns with fewer than 3 finite positive values are dropped, and any
#' remaining NA are set to 0 before summation.
#'
#' @param mat Numeric matrix, rows = time, columns = subpopulations
#' @return Scalar synchrony index in [0, 1], or NA_real_ if fewer than 2
#'   usable columns remain or the denominator is non-finite/zero.
#' @references Loreau & de Mazancourt 2008. Am Nat 172:E48-E66.
ews_synchrony_phi <- function(mat) {
  mat <- as.matrix(mat)
  # Mirror compute_synchrony_lm: keep columns with >= 3 finite positive values
  valid_cols <- apply(mat, 2, function(x) {
    sum(is.finite(x) & x > 0) >= 3
  })
  mat <- mat[, valid_cols, drop = FALSE]
  if (ncol(mat) < 2L) return(NA_real_)
  # Replace NA with 0 for summation (mirrors compute_synchrony_lm)
  mat[is.na(mat)] <- 0
  sds <- apply(mat, 2, stats::sd)
  denom <- sum(sds)^2
  if (!is.finite(denom) || denom == 0) return(NA_real_)
  as.numeric(stats::var(rowSums(mat)) / denom)
}

#' Gross et al. (2014) synchrony eta in [-1, 1]
#'
#' Mean pairwise Pearson correlation across columns. Incomplete columns
#' (NA-variance or zero variance) are dropped before correlation, mirroring
#' the valid-column handling in R/05_portfolio.R::compute_synchrony_lm.
#'
#' @param mat Numeric matrix, rows = time, columns = subpopulations
#' @return Scalar mean pairwise correlation in [-1, 1], or NA_real_ if fewer
#'   than 2 usable columns remain after dropping degenerate columns.
#' @references Gross et al. 2014. Am Nat 183:1-12.
ews_synchrony_eta <- function(mat) {
  mat <- as.matrix(mat)
  ok <- apply(mat, 2, function(z) {
    v <- stats::var(z, na.rm = TRUE)
    is.finite(v) && v > 0
  })
  mat <- mat[, ok, drop = FALSE]
  if (ncol(mat) < 2L) return(NA_real_)
  cm <- stats::cor(mat, use = "pairwise.complete.obs")
  mean(cm[upper.tri(cm)])
}

#' Leading eigen-structure of the cross-section covariance.
#'
#' Computes the leading (largest) eigenvalue of the sample covariance matrix
#' across subpopulation columns, the fraction of total variance explained by
#' the leading EOF (empirical orthogonal function), and the eigenvector
#' loadings. This indicator formalises the link between synchrony and critical
#' slowing down: as a system approaches a tipping point the dominant covariance
#' eigenvalue lambda_max grows and eig_share approaches 1.
#'
#' @param mat Numeric matrix with rows = time steps and columns =
#'   subpopulations (sections). At least 2 columns and 3 rows are required
#'   for a meaningful covariance estimate. NA handled pairwise (incomplete
#'   pairs dropped); windows with no usable covariance return all-NA.
#' @return A named list with three elements:
#'   \describe{
#'     \item{lambda_max}{Numeric scalar. The leading eigenvalue of the sample
#'       covariance matrix (largest variance explained by a single EOF). Returns
#'       \code{NA_real_} when the NA-guard is triggered.}
#'     \item{eig_share}{Numeric scalar in [0, 1]. Fraction of total variance
#'       (trace of S) on the leading EOF: lambda_max / sum(eigenvalues). Equal
#'       to 1 for a rank-1 (perfectly synchronous) system and approaches 1/p
#'       for p independent equal-variance columns. Returns \code{NA_real_} when
#'       the NA-guard is triggered.}
#'     \item{loadings}{Numeric vector of length \code{ncol(mat)}. Entries of
#'       the leading eigenvector (EOF pattern), indicating each subpopulation's
#'       relative contribution to the dominant mode of co-variation. Returns a
#'       vector of \code{NA_real_} values when the NA-guard is triggered.}
#'   }
#'   NA-guard: all three elements are returned as \code{NA_real_} (or a vector
#'   of \code{NA_real_} for \code{loadings}) if \code{mat} has fewer than 2
#'   columns or fewer than 3 rows, if pairwise covariance still contains NA
#'   (no overlapping observations), or if the total clipped variance is
#'   non-finite or zero (degenerate / zero-variance window).
ews_cov_eigen <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2L || nrow(mat) < 3L) {
    return(list(lambda_max = NA_real_, eig_share = NA_real_,
                loadings = rep(NA_real_, ncol(mat))))
  }
  S <- stats::cov(mat, use = "pairwise.complete.obs")
  if (anyNA(S)) {
    return(list(lambda_max = NA_real_, eig_share = NA_real_,
                loadings = rep(NA_real_, ncol(mat))))
  }
  e <- eigen(S, symmetric = TRUE)
  lam <- pmax(e$values, 0)
  den <- sum(lam)
  if (!is.finite(den) || den == 0) {
    return(list(lambda_max = NA_real_, eig_share = NA_real_,
                loadings = rep(NA_real_, ncol(mat))))
  }
  list(
    lambda_max = lam[1],
    eig_share  = lam[1] / den,
    loadings   = e$vectors[, 1]
  )
}

#' Spatial variance across sections within a year (one EWS sample).
#'
#' Computes the sample variance of \code{v} across spatial sections for a
#' single year. In the spatial early-warning-signals (EWS) literature, rising
#' variance (together with rising skewness and Moran's I) is an indicator of
#' approach to a tipping point. Finite values only; degenerate inputs return
#' \code{NA_real_} rather than erroring.
#'
#' @param v Numeric vector. One value per spatial section for a given year.
#'   Non-finite values (\code{NA}, \code{NaN}, \code{Inf}) are silently dropped
#'   before computation.
#' @return Numeric scalar. The sample variance (\code{stats::var()}) of finite
#'   elements of \code{v}. Returns \code{NA_real_} if fewer than 2 finite
#'   values remain after dropping non-finite elements.
#' @references
#'   Kéfi, S., Dakos, V., Scheffer, M., Van Nes, E.H., and Rietkerk, M.
#'   (2013). Early warning signals also precede non-catastrophic transitions.
#'   \emph{Oikos} 122(5): 641-648. \doi{10.1111/j.1600-0706.2012.20838.x}
#'
#'   Génin, A., Majumder, S., Sankaran, S., Danet, A., Guttal, V., Schneider,
#'   F.D., and Kéfi, S. (2018). Monitoring ecosystem degradation using spatial
#'   data and the R package \pkg{spatialwarnings}. \emph{Methods in Ecology
#'   and Evolution} 9(10): 2067-2075. \doi{10.1111/2041-210X.13058}
ews_spatial_variance <- function(v) {
  v <- v[is.finite(v)]
  if (length(v) < 2L) return(NA_real_)
  stats::var(v)
}

#' Spatial skewness across sections within a year.
#'
#' Computes the population-biased third standardised central moment (g1) of
#' \code{v} across spatial sections for a single year. Rising positive skewness
#' across sections is a spatial early-warning indicator: as a system approaches
#' a tipping point local patches begin to spend more time in degraded states,
#' pulling the distribution's tail positive. Finite values only; degenerate
#' inputs return \code{NA_real_} rather than erroring.
#'
#' @param v Numeric vector. One value per spatial section for a given year.
#'   Non-finite values (\code{NA}, \code{NaN}, \code{Inf}) are silently dropped
#'   before computation.
#' @return Numeric scalar. The population-biased skewness moment g1
#'   (\eqn{\hat{\mu}_3 / \hat{\sigma}^3}) of finite elements of \code{v},
#'   where \eqn{\hat{\mu}_3 = \frac{1}{n} \sum (x_i - \bar{x})^3} and
#'   \eqn{\hat{\sigma}^2 = \frac{1}{n} \sum (x_i - \bar{x})^2}. This is the
#'   population biased moment (g1); it matches
#'   \code{moments::skewness} and \code{e1071::skewness(type=1)} and
#'   \pkg{spatialwarnings}; the same convention that \pkg{earlywarnings} uses.
#'   Returns \code{NA_real_} if fewer than 3 finite values remain or if the
#'   population variance is zero (prevents \code{NaN}/\code{Inf} escaping).
#' @references
#'   Kéfi, S., Dakos, V., Scheffer, M., Van Nes, E.H., and Rietkerk, M.
#'   (2013). Early warning signals also precede non-catastrophic transitions.
#'   \emph{Oikos} 122(5): 641-648. \doi{10.1111/j.1600-0706.2012.20838.x}
#'
#'   Génin, A., Majumder, S., Sankaran, S., Danet, A., Guttal, V., Schneider,
#'   F.D., and Kéfi, S. (2018). Monitoring ecosystem degradation using spatial
#'   data and the R package \pkg{spatialwarnings}. \emph{Methods in Ecology
#'   and Evolution} 9(10): 2067-2075. \doi{10.1111/2041-210X.13058}
ews_spatial_skew <- function(v) {
  v <- v[is.finite(v)]
  if (length(v) < 3L) return(NA_real_)
  m <- mean(v)
  s2 <- mean((v - m)^2)
  if (!is.finite(s2) || s2 == 0) return(NA_real_)
  mean((v - m)^3) / s2^1.5
}

#' Generic temporal early-warning-signal battery (earlywarnings wrapper).
#'
#' Wraps \code{earlywarnings::generic_ews()} and returns a stable-column
#' tibble that isolates callers from the package's exact return-column names.
#' Designed to be called by Task 3.1 over rolling windows of aggregate biomass
#' for both observed and latent layers.
#'
#' \strong{Column mapping from earlywarnings v1.x to the stable contract:}
#' \code{timeindex -> time}, \code{ar1 -> ar1}, \code{sd -> sd},
#' \code{sd^2 -> variance} (computed here), \code{sk -> skew},
#' \code{kurt -> kurtosis}, \code{cv -> cv}, \code{densratio -> densratio},
#' \code{returnrate -> returnrate}.  The \code{acf1} column from
#' \code{generic_ews} is intentionally omitted from the stable contract
#' (\code{ar1} is the rolling lag-1 autocorrelation used for EWS;
#' \code{acf1} is a whole-series summary).
#'
#' \strong{Detrending argument map} (\code{detrend=} -> \code{generic_ews
#' detrending=}):
#' \code{"none" -> "no"}, \code{"gaussian" -> "gaussian"},
#' \code{"first-diff" -> "first-diff"}, \code{"linear" -> "linear"},
#' \code{"loess" -> "loess"}.
#'
#' @param x Numeric vector. The observed univariate time series. Coerced via
#'   \code{as.numeric()}. Leading and trailing \code{NA} are stripped; isolated
#'   internal \code{NA} are passed to \code{generic_ews} which handles them via
#'   linear interpolation when \code{interpolate = TRUE}; here interpolation is
#'   enabled automatically when internal \code{NA} are detected. If the
#'   remaining finite-value count is less than 12 or less than
#'   \code{2 * win_pct} (absolute window length), the function returns a 0-row
#'   contract tibble rather than erroring.
#' @param win_frac Numeric scalar in (0, 1). Rolling-window size expressed as a
#'   fraction of the series length.  Mapped to \code{winsize =
#'   max(10, round(100 * win_frac))} (integer percent).  Default \code{0.5}.
#' @param detrend Character. Detrending method. One of
#'   \code{"none"} (pass through raw series), \code{"gaussian"} (Gaussian
#'   kernel filter), \code{"first-diff"} (first differencing),
#'   \code{"linear"} (linear detrend), \code{"loess"} (LOESS smoother).
#'   Matched via \code{match.arg()}; default \code{"gaussian"}.
#' @param bandwidth Numeric or \code{NULL}. Gaussian kernel bandwidth as a
#'   percentage of the series length.  Passed directly to
#'   \code{earlywarnings::generic_ews()}; \code{NULL} uses the package default
#'   (\code{bw.nrd0} bandwidth selector).
#'
#' @return A \code{tibble::tibble} with at least the columns
#'   \code{time}, \code{ar1}, \code{variance}, \code{sd}, \code{skew},
#'   \code{kurtosis}, \code{cv}, \code{densratio}, \code{returnrate},
#'   \code{detrend}, \code{win_frac}.
#'   \describe{
#'     \item{time}{Integer time indices from \code{generic_ews} (half-window
#'       to end of series).}
#'     \item{ar1}{Lag-1 autocorrelation within the rolling window.}
#'     \item{variance}{Rolling within-window variance (\code{sd^2}).}
#'     \item{sd}{Rolling within-window standard deviation.}
#'     \item{skew}{Rolling within-window skewness (population-biased g1).}
#'     \item{kurtosis}{Rolling within-window kurtosis.}
#'     \item{cv}{Rolling coefficient of variation (\code{sd / mean}).}
#'     \item{densratio}{Rolling low-to-high spectral density ratio.}
#'     \item{returnrate}{Rolling return rate.  \code{NA_real_} if the installed
#'       version does not produce it.}
#'     \item{detrend}{The \code{detrend} argument value used (character).}
#'     \item{win_frac}{The \code{win_frac} argument value used (numeric).}
#'   }
#'   \strong{Degenerate input contract (§8 robustness):} a 0-row tibble with
#'   all contract columns is returned (never an error or escaped warning) when
#'   the series is too short (\eqn{n < 12} finite values or \eqn{n <} absolute
#'   window length), or when \code{generic_ews} itself errors on a degenerate
#'   (e.g. constant) series.
#'
#' @note Plotting from \code{earlywarnings::generic_ews()} is internally
#'   suppressed to a temporary pdf device (cleaned up after each call), so this
#'   function is headless / \code{Rscript}-safe and never spawns \code{Rplots*.pdf}
#'   or leaks graphics devices across large sweeps.
#'
#' @references
#'   Dakos, V., Carpenter, S.R., Ellison, A.M., Guttal, V., Ives, A.R.,
#'   Kéfi, S., Livina, V., Seekell, D.A., van Nes, E.H., and Scheffer, M.
#'   (2012). Methods for detecting early warnings of critical transitions in
#'   time series illustrated using simulated ecological data. \emph{PLoS ONE}
#'   7(7): e41010. \doi{10.1371/journal.pone.0041010}
ews_generic_battery <- function(x,
                                 win_frac  = 0.5,
                                 detrend   = c("gaussian", "none",
                                               "first-diff", "linear",
                                               "loess"),
                                 bandwidth = NULL) {
  detrend <- match.arg(detrend)

  # Map our stable detrend names to earlywarnings::generic_ews's actual values.
  # Confirmed via ?earlywarnings::generic_ews: c("no","gaussian","loess",
  # "linear","first-diff")
  detrend_map <- c(
    "none"       = "no",
    "gaussian"   = "gaussian",
    "first-diff" = "first-diff",
    "linear"     = "linear",
    "loess"      = "loess"
  )
  ews_detrending <- unname(detrend_map[detrend])

  # Build the 0-row contract tibble used for all early-exit paths.
  empty_contract <- tibble::tibble(
    time       = integer(0),
    ar1        = double(0),
    variance   = double(0),
    sd         = double(0),
    skew       = double(0),
    kurtosis   = double(0),
    cv         = double(0),
    densratio  = double(0),
    returnrate = double(0),
    detrend    = character(0),
    win_frac   = double(0)
  )

  # --- Coerce and strip leading/trailing NA ---
  x <- as.numeric(x)
  finite_idx <- which(is.finite(x))
  if (length(finite_idx) == 0L) return(empty_contract)
  x <- x[min(finite_idx):max(finite_idx)]

  # --- Window size as integer percent ---
  win_pct <- as.integer(max(10L, round(100 * win_frac)))

  # --- Guard: too short to compute rolling stats ---
  n <- length(x)
  abs_win <- max(2L, round(win_pct / 100 * n))
  n_finite <- sum(is.finite(x))
  if (n_finite < 12L || abs_win >= n) return(empty_contract)

  # --- Handle internal NA: enable generic_ews interpolation ---
  has_internal_na <- anyNA(x)

  # --- Call generic_ews, catching all conditions ---
  # earlywarnings::generic_ews() calls dev.new()/plot() unconditionally. Under
  # a headless `Rscript` dev.new() falls back to the default device, which
  # spews Rplots*.pdf into the cwd; ~thousands of sweep calls exhaust the
  # 1000-name limit, after which dev.new() errors, the tryCatch below silently
  # returns a 0-row contract, and real results are masked. We point the
  # `device` option at a temp-pdf opener for the duration of the call so every
  # dev.new() lands in one disposable file, then close all devices opened
  # during the call and restore the option. Done inline (not via on.exit) so
  # nothing -- device or temp file -- leaks across the sweep.
  .gp          <- tempfile(fileext = ".pdf")
  .dev_opt     <- getOption("device")
  .devs_before <- grDevices::dev.list()
  options(device = function() grDevices::pdf(.gp))
  raw <- tryCatch(
    suppressWarnings(
      earlywarnings::generic_ews(
        timeseries   = x,
        winsize      = win_pct,
        detrending   = ews_detrending,
        bandwidth    = bandwidth,
        interpolate  = has_internal_na
      )
    ),
    error = function(e) NULL
  )
  options(device = .dev_opt)
  for (.d in rev(setdiff(grDevices::dev.list(), .devs_before))) {
    tryCatch(grDevices::dev.off(.d), error = function(e) NULL)
  }
  unlink(.gp)

  if (is.null(raw) || !is.data.frame(raw) || nrow(raw) == 0L) {
    return(empty_contract)
  }

  # --- Map raw columns to the stable contract ---
  # Actual columns: timeindex, ar1, sd, sk, kurt, cv, returnrate, densratio, acf1
  # variance = sd^2 (computed here)
  out <- tibble::tibble(
    time       = as.integer(raw[["timeindex"]]),
    ar1        = as.double(raw[["ar1"]]),
    variance   = as.double(raw[["sd"]]^2),
    sd         = as.double(raw[["sd"]]),
    skew       = as.double(raw[["sk"]]),
    kurtosis   = as.double(raw[["kurt"]]),
    cv         = if ("cv" %in% names(raw)) as.double(raw[["cv"]])
                 else NA_real_, # generic_ews exposes no rolling-window mean; cv unavailable -> NA
    densratio  = if ("densratio"  %in% names(raw)) as.double(raw[["densratio"]])
                 else NA_real_,
    returnrate = if ("returnrate" %in% names(raw)) as.double(raw[["returnrate"]])
                 else NA_real_,
    detrend    = detrend,
    win_frac   = win_frac
  )

  # Final guard: ensure no NaN/Inf escapes (replace with NA)
  out[] <- lapply(out, function(col) {
    if (is.double(col)) {
      col[!is.finite(col)] <- NA_real_
    }
    col
  })

  out
}

#' Moran's I with inverse-distance, row-standardised weights.
#'
#' Computes Moran's I for a single cross-section of section-level values using
#' inverse-distance, row-standardised spatial weights. Rising Moran's I
#' (increasing spatial autocorrelation) is a key spatial early-warning signal
#' of approach to a tipping point: as a system destabilises, local patches
#' synchronise. Uses only finite-valued sections; degenerate inputs return
#' \code{NA_real_} rather than \code{NaN}/\code{Inf}/error.
#'
#' @param vals Numeric vector. One value per spatial section for a given year,
#'   row-aligned with \code{coords}. Non-finite values (and corresponding rows
#'   of \code{coords}) are dropped before computation.
#' @param coords Two-column numeric matrix. Spatial coordinates (longitude,
#'   latitude) for each section, row-aligned with \code{vals}.
#' @return Numeric scalar. Moran's I statistic computed with inverse-distance,
#'   row-standardised weights. Returns \code{NA_real_} if fewer than 3 usable
#'   sections remain after dropping non-finite values, if the spatial variance
#'   of \code{vals} is zero, if any pairwise distance is zero (identical
#'   coordinates produce infinite weights; these are zeroed and if no positive
#'   weights remain, returns \code{NA_real_}), or if the result would be
#'   non-finite. Never returns \code{NaN} or \code{Inf}.
#' @references
#'   Kéfi, S., Dakos, V., Scheffer, M., Van Nes, E.H., and Rietkerk, M.
#'   (2013). Early warning signals also precede non-catastrophic transitions.
#'   \emph{Oikos} 122(5): 641-648. \doi{10.1111/j.1600-0706.2012.20838.x}
#'
#'   Génin, A., Majumder, S., Sankaran, S., Danet, A., Guttal, V., Schneider,
#'   F.D., and Kéfi, S. (2018). Monitoring ecosystem degradation using spatial
#'   data and the R package \pkg{spatialwarnings}. \emph{Methods in Ecology
#'   and Evolution} 9(10): 2067-2075. \doi{10.1111/2041-210X.13058}
ews_morans_i <- function(vals, coords) {
  coords <- as.matrix(coords)
  ok <- is.finite(vals) & is.finite(coords[, 1]) & is.finite(coords[, 2])
  vals <- vals[ok]; coords <- coords[ok, , drop = FALSE]
  n <- length(vals)
  if (n < 3L) return(NA_real_)
  z <- vals - mean(vals)
  zz <- sum(z^2)
  if (!is.finite(zz) || zz == 0) return(NA_real_)
  d <- as.matrix(stats::dist(coords))
  w <- 1 / d
  diag(w) <- 0
  w[!is.finite(w)] <- 0
  s0 <- sum(w)
  if (!is.finite(s0) || s0 == 0) return(NA_real_)
  rs <- rowSums(w)
  w <- sweep(w, 1, ifelse(rs == 0, 1, rs), "/")
  s0 <- sum(w)
  val <- (n / s0) * (as.numeric(t(z) %*% w %*% z) / zz)
  if (!is.finite(val)) return(NA_real_)
  val
}

#' Kendall tau trend statistic with an AR(1)-surrogate p-value (Dakos 2008).
#' Surrogates preserve lag-1 autocorrelation and variance but destroy trend.
#' @param y numeric vector (an indicator trajectory; non-finite values dropped)
#' @param n_surr integer number of AR(1) surrogate series
#' @param seed integer RNG seed (results are deterministic given seed)
#' @return list(tau, p_value, n); tau/p_value are NA_real_ if fewer than 5
#'   finite points or the series has ~zero variance. Never NaN/Inf; no
#'   warnings escape. p_value is a Monte-Carlo estimate with resolution
#'   1/n_surr; a reported p_value of 0 means 0 of n_surr surrogates met or
#'   exceeded |tau_obs| (i.e. p < 1/n_surr), not exact zero.
#' @references Dakos et al. 2008 PNAS 105:14308-14312; 2012 PLoS ONE 7:e41010
ews_kendall_surrogate <- function(y, n_surr = 1000L, seed = 20260519L) {
  y <- as.numeric(y); y <- y[is.finite(y)]
  n <- length(y)
  if (n < 5L) return(list(tau = NA_real_, p_value = NA_real_, n = n))
  s <- stats::sd(y)
  if (!is.finite(s) || s == 0) {
    return(list(tau = NA_real_, p_value = NA_real_, n = n))
  }
  tau_obs <- suppressWarnings(
    as.numeric(Kendall::Kendall(seq_len(n), y)$tau))
  if (!is.finite(tau_obs)) {
    return(list(tau = NA_real_, p_value = NA_real_, n = n))
  }
  a <- suppressWarnings(stats::acf(y, lag.max = 1, plot = FALSE)$acf[2])
  if (!is.finite(a)) a <- 0
  a <- max(min(a, 0.99), -0.99)
  set.seed(seed)
  tau_null <- vapply(seq_len(n_surr), function(i) {
    e <- if (a == 0) stats::rnorm(n, 0, s)
         else as.numeric(stats::arima.sim(
           list(ar = a), n = n, sd = s * sqrt(1 - a^2)))
    suppressWarnings(as.numeric(Kendall::Kendall(seq_len(n), e)$tau))
  }, numeric(1))
  tau_null <- tau_null[is.finite(tau_null)]
  p <- if (length(tau_null) == 0L) NA_real_
       else mean(abs(tau_null) >= abs(tau_obs))
  list(tau = tau_obs, p_value = p, n = n)
}

#' Dominant eigenvalue modulus of the MAR(1)/VAR(1) interaction matrix B.
#' Rising lambda toward 1 == multivariate critical slowing down.
#' Uses OLS VAR(1) when the matrix is complete; MARSS when NAs are present.
#' @param X numeric matrix, rows = time, cols = subpopulations
#' @return numeric scalar (spectral radius of B); NA_real_ if <2 columns,
#'   insufficient time rows, singular/non-converging fit, or non-finite result.
#'   Never NaN/Inf; no warnings escape.
#' @references Ives et al. 2003 Ecol Monogr 73:301-330 (MAR(1)); Dakos 2018
#'   Ecol Indic (multivariate EWS)
ews_mar1_eigen <- function(X) {
  X <- as.matrix(X)
  p <- ncol(X)
  if (p < 2L) return(NA_real_)
  if (nrow(X) < (p + 2L)) return(NA_real_)
  B <- tryCatch({
    if (anyNA(X)) {
      fit <- suppressWarnings(suppressMessages(
        MARSS::MARSS(t(X),
          model = list(B = "unconstrained", Q = "diagonal and unequal",
                       R = "zero", U = "zero"),
          silent = TRUE, control = list(maxit = 500, safe = TRUE))
      ))
      # NB: return() here exits ews_mar1_eigen(), not just the tryCatch
      if (isTRUE(fit$convergence != 0)) return(NA_real_)
      # coef.marssMLE is a registered S3 method (not in MARSS NAMESPACE
      # exports); plain coef() dispatches correctly
      matrix(coef(fit, type = "matrix")$B, p, p)
    } else {
      Yr <- X[-1, , drop = FALSE]
      Zr <- X[-nrow(X), , drop = FALSE]
      cf <- stats::lm.fit(Zr, Yr)$coefficients
      if (anyNA(cf)) return(NA_real_)
      # lm.fit(Zr, Yr)$coefficients is p x p: column k = regression of Y[,k] on Z,
      # i.e. cf[j, k] = B[k, j].  So B = t(matrix(cf, p, p)).
      t(matrix(cf, p, p))
    }
  }, error = function(e) NULL)
  if (is.null(B) || anyNA(B)) return(NA_real_)
  ev <- tryCatch(max(Mod(eigen(B, only.values = TRUE)$values)),
                 error = function(e) NA_real_)
  if (!is.finite(ev)) return(NA_real_)
  ev
}

#' Candidate regime-shift years via (a) sequential-t (Rodionov STARS-like)
#' and (b) strucchange breakpoints on the mean.
#' @param years integer-coercible vector of years aligned to x
#' @param x numeric series (non-finite values dropped with their years)
#' @param l integer half-window for the sequential-t scan (default 10)
#' @param p numeric significance threshold for the sequential-t (default 0.05)
#' @return a tibble with columns `year` (integer) and `method` (character:
#'   "stars" or "breakpoint"); a 0-row tibble WITH those columns if no
#'   shift is detectable or the input is too short/degenerate. Never errors,
#'   warns, or returns NaN/Inf.
#' @note The sequential-t scan runs an uncorrected two-sample test at every
#'   interior point with overlapping windows, so a single true shift produces
#'   a contiguous band of ~2*l flagged 'stars' years; for autocorrelated EWS
#'   series (lag-1 acf > ~0.4) the per-series false-positive rate approaches
#'   100%. STARS output is a CANDIDATE pool requiring deduplication and
#'   cross-validation against the strucchange breakpoints and documented era
#'   boundaries — individual flagged years must not be reported as confirmed
#'   transitions.
#' @references Rodionov 2004 GRL 31:L09204 (STARS); Zeileis et al. 2003
#'   Comput Stat Data Anal 44:109-123 (strucchange breakpoints)
ews_detect_transitions <- function(years, x, l = 10L, p = 0.05) {
  empty <- tibble::tibble(year = integer(0), method = character(0))
  years <- suppressWarnings(as.integer(years))
  x <- suppressWarnings(as.numeric(x))
  if (length(x) != length(years)) return(empty)
  ok <- is.finite(x) & is.finite(years)
  years <- years[ok]; x <- x[ok]
  n <- length(x)
  if (n < 4L) return(empty)
  out <- list()
  # (a) sequential-t STARS-like
  if (n >= (2L * l + 1L)) {
    i <- l + 1L
    while (i <= n - l) {
      pre  <- x[(i - l):(i - 1L)]
      post <- x[i:(i + l - 1L)]
      tt <- tryCatch(
        suppressWarnings(stats::t.test(pre, post)$p.value),
        error = function(e) NA_real_)
      if (is.finite(tt) && tt < p) {
        out[[length(out) + 1L]] <- tibble::tibble(
          year = years[i], method = "stars")
      }
      i <- i + 1L
    }
  }
  # (b) strucchange breakpoints on the mean
  bp <- tryCatch(
    suppressWarnings(strucchange::breakpoints(x ~ 1)$breakpoints),
    error = function(e) NA)
  if (length(bp) >= 1L && !anyNA(bp)) {
    # NB: strucchange returns the LAST index of the old regime; years[bp] is the last year before the shift, not the first year of the new regime (Task 3.4 picks the convention).
    out[[length(out) + 1L]] <- tibble::tibble(
      year = years[bp], method = "breakpoint")
  }
  if (length(out) == 0L) return(empty)
  res <- dplyr::distinct(dplyr::bind_rows(out))
  res$year <- as.integer(res$year)
  res$method <- as.character(res$method)
  res[, c("year", "method")]
}

#' Simulate a coupled metapopulation for EWS power calibration.
#' "approaching_fold": coupling and harvest drift up toward a saddle-node so
#' synchrony and critical slowing down must rise. "stationary": fixed
#' parameters (negative control).
#' @param n_sites integer number of subpopulations (columns)
#' @param n_years integer number of time steps (rows)
#' @param scenario "approaching_fold" or "stationary"
#' @param seed integer RNG seed (output is deterministic given seed)
#' @return a finite numeric matrix, n_years x n_sites (never NaN/Inf)
#' @note In 'approaching_fold' the synchrony rise is primarily coupling-driven
#'   (shared:idiosyncratic noise variance ratio rises ~75x as cpl 0.02->0.60);
#'   genuine critical slowing down is present but secondary (Jacobian->0,
#'   rolling AR1 ~0.43->0.74). Synchrony-based EWS are a strong positive
#'   control here; isolated AR1/variance detection is a weaker, confounded
#'   signal — calibrate Task 4.4 power expectations accordingly.
#' @references Scheffer et al. 2009 Nature 461:53-59; Dakos et al. 2012
#'   PLoS ONE 7:e41010 (EWS power calibration on simulated transitions)
ews_sim_metapop <- function(n_sites = 9L, n_years = 60L,
                            scenario = c("approaching_fold", "stationary"),
                            seed = 20260519L) {
  scenario <- match.arg(scenario)
  set.seed(seed)
  if (n_years < 2L || n_sites < 1L)
    return(matrix(NA_real_, max(n_years, 0L), max(n_sites, 0L)))
  r <- 0.6; K <- 100; A <- 5                  # logistic + weak Allee
  X <- matrix(NA_real_, n_years, n_sites)
  X[1, ] <- stats::runif(n_sites, 60, 90)
  for (t in 2:n_years) {
    frac <- (t - 1) / (n_years - 1)
    cpl     <- if (scenario == "approaching_fold") 0.02 + 0.58 * frac else 0.05
    harvest <- if (scenario == "approaching_fold") 0.05 + 0.10 * frac else 0.05
    common <- stats::rnorm(1, 0, 6) * cpl
    for (j in seq_len(n_sites)) {
      xj <- X[t - 1L, j]
      growth <- r * xj * (1 - xj / K) * ((xj - A) / K)
      xn <- xj + growth - harvest * xj + common +
        stats::rnorm(1, 0, 3 * (1 - cpl))
      # hard finiteness clamp: keep state in [0.1, 5K], never NaN/Inf
      if (!is.finite(xn)) xn <- 0.1
      X[t, j] <- min(max(xn, 0.1), 5 * K)
    }
  }
  X
}
