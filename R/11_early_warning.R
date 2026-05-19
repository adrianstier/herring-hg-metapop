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
#' @param v numeric vector (one value per section for a given year)
#' @return numeric scalar; NA_real_ if fewer than 2 finite values
ews_spatial_variance <- function(v) {
  v <- v[is.finite(v)]
  if (length(v) < 2L) return(NA_real_)
  stats::var(v)
}

#' Spatial skewness across sections within a year.
#' @param v numeric vector (one value per section)
#' @return numeric scalar; NA_real_ if <3 finite values or zero variance
ews_spatial_skew <- function(v) {
  v <- v[is.finite(v)]
  if (length(v) < 3L) return(NA_real_)
  m <- mean(v)
  s2 <- mean((v - m)^2)
  if (!is.finite(s2) || s2 == 0) return(NA_real_)
  mean((v - m)^3) / s2^1.5
}

#' Moran's I with inverse-distance, row-standardised weights.
#' @param vals numeric vector (one value per section, one year)
#' @param coords two-column matrix (lon, lat) row-aligned to vals
#' @return numeric scalar; NA_real_ if <3 usable sections, zero spatial
#'   variance, or no positive weights (never NaN/Inf)
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
