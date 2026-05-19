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
