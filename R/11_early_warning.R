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
#' \code{returnrate -> returnrate}.  The \code{acf1} column returned by
#' \code{generic_ews} is retained in the output as-is.
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
                 else as.double(raw[["sd"]] / abs(rowMeans(raw[, "sd", drop = FALSE]))),
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
