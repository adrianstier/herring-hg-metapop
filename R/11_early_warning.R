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
