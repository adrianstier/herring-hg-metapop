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
#' phi = var(rowSums(mat)) / (sum(colwise sd))^2 ; in [0, 1]
#' @param mat numeric matrix, rows = time, cols = subpopulations
ews_synchrony_phi <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2L) return(NA_real_)
  sds <- apply(mat, 2, stats::sd)
  denom <- sum(sds)^2
  if (!is.finite(denom) || denom == 0) return(NA_real_)
  as.numeric(stats::var(rowSums(mat)) / denom)
}

#' Gross et al. (2014) synchrony eta in [-1, 1]
#' mean pairwise Pearson correlation across columns
ews_synchrony_eta <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2L) return(NA_real_)
  cm <- stats::cor(mat)
  mean(cm[upper.tri(cm)])
}
