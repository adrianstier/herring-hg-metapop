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
#' Boundary note: at n just above the 2*E_max+2 guard, rEDM emits "nan found"
#' warnings and the largest-E rho values are unreliable; real HG section
#' lengths (~30-50 obs) are well clear of this boundary.
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
#'          Spec §7 short-series guard: returns a 0-row frame with all five
#'          columns present (never crash / silent number) when the target is
#'          too short to (a) embed at E (< 2*E + 2 finite points, mirrors the
#'          other EDM guards) or (b) yield a >=3-point CCM convergence
#'          trajectory (the Kendall monotonicity test's precondition).
ccm_drivers <- function(target, drivers, E, seed, libSizes = NULL) {
  set.seed(seed)
  contract0 <- function() data.frame(
    driver              = character(0),
    rho_min             = numeric(0),
    rho_max             = numeric(0),
    converges_strict    = logical(0),
    converges_heuristic = logical(0)
  )
  n_fin <- sum(is.finite(target))
  if (n_fin < 2L * E + 2L) return(contract0())
  n <- length(target)
  # Max lib size: n - E - 1 (rEDM requires libSize < n - E - Tp, Tp=0 default)
  max_lib <- n - E - 1L
  step    <- max(5L, floor(max_lib / 10L))
  # CCM convergence needs >= 3 library sizes for a computable Kendall test of
  # rho-vs-libSize; below that the auto trajectory is degenerate -> 0-row.
  if (is.null(libSizes) &&
      (max_lib < E + 2L ||
       length(seq(E + 2L, max_lib, by = step)) < 3L)) {
    return(contract0())
  }
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
    # cor.test() THROWS (not warns) on a degenerate rho vector (< 3 finite,
    # no rank variation); tryCatch -> NA p.value -> strict = FALSE (never NA).
    kendall_p <- tryCatch(
      suppressWarnings(
        stats::cor.test(seq_along(rho), rho, method = "kendall")$p.value
      ),
      error = function(e) NA_real_
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

#' Nonparametric drift f(x)=E[dx|x], diffusion g2(x)=E[dx^2|x], effective
#' potential U(x) = -cumsum(f/g2). Stable equilibria = minima of U.
#' Sparse tail bins (< min_count obs) are excluded before integration; U is
#' lightly smoothed with a 3-point running average to suppress noise-driven
#' false inflections (standard Fokker-Planck landscape practice).
#' @return Degenerate contract: returns the 4-name list with zero-length
#'   x/U/drift/minima (never crashes) when < 3 finite values or constant x
#'   (the estimator needs xc = x[-length(x)] of length >= 2, i.e. >= 3 finite x;
#'   2 distinct finite values collapse seq() breaks and crash cut()).
potential_landscape <- function(x, n_bin = 25, min_count = 5) {
  x <- as.numeric(x)
  x_fin <- x[is.finite(x)]
  if (length(x_fin) < 3L || min(x_fin) == max(x_fin)) {
    return(list(x = numeric(0), U = numeric(0),
                drift = numeric(0), minima = numeric(0)))
  }
  x <- x_fin   # estimator is index-free; strip NAs (same idiom as ews_spatial_* in R/11)
  dx <- diff(x); xc <- x[-length(x)]
  br <- seq(min(xc), max(xc), length.out = n_bin + 1)
  bin <- cut(xc, br, include.lowest = TRUE)
  ctr <- (br[-1] + br[-length(br)]) / 2
  cnt  <- as.numeric(table(bin))
  drift <- tapply(dx, bin, mean)
  diff2 <- tapply(dx^2, bin, mean); diff2[is.na(diff2) | diff2 == 0] <- NA
  keep <- is.finite(drift) & is.finite(diff2) & cnt >= min_count
  ctr_k <- ctr[keep]
  U_raw <- -cumsum((drift[keep] / diff2[keep])) * mean(diff(br))
  n_k <- length(U_raw)
  if (n_k >= 3) {
    U <- as.numeric(stats::filter(U_raw, rep(1/3, 3), sides = 2))
    U[is.na(U)] <- U_raw[is.na(U)]
  } else {
    U <- U_raw
  }
  is_min <- which(c(FALSE, diff(sign(diff(U))) > 0, FALSE))
  list(x = ctr_k, U = U, drift = as.numeric(drift[keep]),
       minima = ctr_k[is_min])
}

#' Beverton-Holt vs depensatory (Allee) recruitment model selection by AIC.
#' @return Degenerate contract: when < 3 finite positive (S,R) pairs, returns
#'   table with aic = c(NA, NA) and best = NA_character_ (never a silent
#'   structural answer); a failed nls scores NA so the converging model wins.
regime_models <- function(stock, recruit) {
  d <- data.frame(S = stock, R = recruit)
  d <- d[is.finite(d$S) & is.finite(d$R) & d$S > 0 & d$R > 0, ]
  if (nrow(d) < 3L) {
    return(list(table = data.frame(model = c("beverton_holt", "depensatory"),
                                   aic = c(NA_real_, NA_real_)),
                best = NA_character_))
  }
  bh <- try(stats::nls(R ~ a * S / (b + S), data = d,
              start = list(a = max(d$R), b = stats::median(d$S))),
            silent = TRUE)
  dp <- try(stats::nls(R ~ a * S^2 / (b^2 + S^2), data = d,
              start = list(a = max(d$R), b = stats::median(d$S))),
            silent = TRUE)
  sc <- function(m) if (inherits(m, "try-error")) NA_real_ else stats::AIC(m)
  tab <- data.frame(model = c("beverton_holt","depensatory"),
                     aic = c(sc(bh), sc(dp)))
  best <- if (all(is.na(tab$aic))) NA_character_ else tab$model[which.min(tab$aic)]
  list(table = tab, best = best)
}

#' Hartigan dip test of multimodality.
#' @return Degenerate contract: returns dip = NA_real_, dip_p = NA_real_ when
#'   < 4 finite values (dip test undefined below n = 4); never a silent 0/1.
state_modality <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 4L) return(list(dip = NA_real_, dip_p = NA_real_))
  # Tied/duplicate values make diptest call regularize.values(), which warns
  # "collapsing to unique 'x' values"; benign for the dip statistic (the ECDF
  # is unaffected) -> suppress so it doesn't escape as a pipeline signal.
  dt <- suppressWarnings(diptest::dip.test(x))
  list(dip = unname(dt$statistic), dip_p = unname(dt$p.value))
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

# ============================================================================
# Task 12: driver_state_loop
# ============================================================================

#' Driver-state path geometry. Signed loop area via the shoelace formula
#' (nonzero = non-retracing = hysteresis-like); also the vertical state gap
#' between down- and up-limb at matched driver deciles.
#'
#' @param driver Numeric vector — the control parameter (e.g. exploitation rate).
#' @param state  Numeric vector — the response (e.g. biomass). Same length as driver.
#' @param year   Numeric/integer vector — time index. Same length as driver.
#' @param pivot  Scalar — year (or index value) separating the "down-limb"
#'               (driver increasing/collapse phase) from the "up-limb"
#'               (driver decreasing/recovery phase).
#' @return Named list: signed_area (numeric), matched_gap (numeric),
#'   gap_by_decile (named array or NULL).
#'   Degenerate contract (spec §7): returns
#'     list(signed_area = NA_real_, matched_gap = NA_real_, gap_by_decile = NULL)
#'   silently (never crashes, never a silent wrong number) when:
#'     - fewer than 3 finite (driver, state) pairs, OR
#'     - the driver has fewer than 2 distinct finite values
#'       (constant driver -> non-unique quantile breaks -> cut() crash).
#'   NOTE: matched_gap may be NA_real_ even on a NON-degenerate return (finite
#'   signed_area, populated gap_by_decile) when every observation falls on a
#'   single limb -- no decile then has both down- and up-limb points, so no
#'   matched gap is defined. Phase 7 callers should test is.finite(matched_gap)
#'   rather than assume an NA matched_gap implies a fully degenerate result.
driver_state_loop <- function(driver, state, year, pivot) {
  ok <- is.finite(driver) & is.finite(state)
  d <- driver[ok]; s <- state[ok]; y <- year[ok]
  # §7 guard: need >= 3 finite pairs AND >= 2 distinct driver values
  if (length(d) < 3L || length(unique(d)) < 2L) {
    return(list(signed_area = NA_real_, matched_gap = NA_real_,
                gap_by_decile = NULL))
  }
  # Shoelace formula (signed area of the closed driver-state polygon)
  area <- 0.5 * sum(d * c(s[-1], s[1]) - c(d[-1], d[1]) * s)
  limb <- ifelse(y <= pivot, "down", "up")
  # Decile binning: unique() breaks guard collapses due to quantile ties
  qd  <- stats::quantile(d, probs = seq(0, 1, 0.1), na.rm = TRUE)
  uqd <- unique(qd)           # drop duplicate break values (e.g. near-constant)
  bin <- cut(d, uqd, include.lowest = TRUE)
  gap <- tapply(seq_along(d), bin, function(ix) {
    dn <- s[ix][limb[ix] == "down"]; up <- s[ix][limb[ix] == "up"]
    if (!length(dn) || !length(up)) return(NA_real_)
    mean(dn) - mean(up)
  })
  # One-directional driver (all obs on one limb -> every decile gap NA ->
  # mean(.., na.rm=TRUE) = NaN). Emit NA_real_, never a silent NaN -- same
  # no-silent-NaN class as effective_driver (Phase 1) and per the @return
  # contract; Phase 7 writes matched_gap to CSV where NaN round-trips badly.
  mg_raw <- mean(gap, na.rm = TRUE)
  list(signed_area   = as.numeric(area),
       matched_gap   = if (is.nan(mg_raw)) NA_real_ else as.numeric(mg_raw),
       gap_by_decile = gap)
}

# ============================================================================
# Task 13: loop_null_pvalue
# ============================================================================

#' Null p-value for the driver-state loop index.
#'
#' Regenerates the state from a single-equilibrium process (loess baseline of
#' the observed series) plus the documented two-era catchability q-shift
#' (survey_artifact_null). The fraction of null |signed_area| values at least
#' as extreme as observed is the p-value: p >= 0.05 means the loop is NOT
#' distinguishable from a pure survey artifact.
#'
#' Determinism: set.seed(seed) governs the outer call AND the sample.int()
#' draws inside replicate(), making the full null reproducible. Two calls with
#' the same seed produce identical p.
#'
#' @param driver     Numeric vector — control parameter (same length as state).
#' @param state      Numeric vector — response (observed, possibly q-shifted).
#' @param year       Numeric/integer vector — time index.
#' @param pivot      Scalar — year separating down/up limbs (passed to driver_state_loop).
#' @param era_break  Integer — era boundary passed to survey_artifact_null.
#' @param q          Length-2 numeric — catchability in each era.
#' @param n_null     Integer — number of null replicates (default 500).
#' @param seed       REQUIRED integer seed for reproducibility.
#' @return Numeric scalar p-value in (0, 1], or NA_real_ (spec §7 contract)
#'   when:
#'     - the observed loop is undefined (driver_state_loop returns NA signed_area), OR
#'     - the series is too short for loess (< 4 finite state values).
#'   Never crashes; never returns a misleading p.
loop_null_pvalue <- function(driver, state, year, pivot, era_break, q,
                             n_null = 500, seed) {
  set.seed(seed)
  # §7 guard: too-short series -> loess crashes or is undefined
  if (sum(is.finite(state)) < 4L) return(NA_real_)
  obs_area_signed <- driver_state_loop(driver, state, year, pivot)$signed_area
  # §7 guard: loop undefined (constant/short driver) -> NA, not a misleading p
  if (!is.finite(obs_area_signed)) return(NA_real_)
  obs_area <- abs(obs_area_signed)
  # Loess baseline: smooth the observed series to get a single-attractor null base.
  # NAs are passed through to loess intentionally -- predict() keeps the output
  # length-n / index-aligned (loess returns NA at NA positions), which
  # survey_artifact_null requires; NA-stripping here would misalign the era split.
  base <- stats::predict(stats::loess(state ~ seq_along(state)))
  null_area <- replicate(n_null, {
    sim <- survey_artifact_null(base, era_break, q,
                                seed = sample.int(1e6, 1))
    abs(driver_state_loop(driver, sim, year, pivot)$signed_area)
  })
  (1 + sum(null_area >= obs_area, na.rm = TRUE)) / (1 + n_null)
}

# ============================================================================
# Task 14: reversibility_controls
# ============================================================================

#' Power calibration (spec §5, redesigned 2026-05-19).
#' POSITIVE: a system ramped through a saddle-node fold — cusp normal form
#'   x_{t} = x_{t-1} + (r_t + x_{t-1} - x_{t-1}^3)*dt + noise, r ramped so the
#'   fold is approached (upper branch decays; lower attractor not yet reached at
#'   n=70 default — slow-passage regime). NO numerical clamp; the lower attractor
#'   is reached at n~200+. Critical slowing: the local map multiplier
#'   1+dt*f'(x*) -> 1 as the fold is approached, so |lambda_max| RISES pre-
#'   transition. PRIMARY detector = the pre-transition |lambda_max| trend.
#' NEGATIVE: a linear-stochastic single attractor — AR(1)/OU mean-reverting to
#'   one equilibrium + noise (genuinely linear: S-map theta must NOT flag it;
#'   |lambda_max| ~ constant -> ~zero trend).
#' Generic S-map theta nonlinearity is SECONDARY and underpowered at n~70 —
#'   reported (nl_p, nl_delta), never a hard pass/fail gate.
reversibility_controls <- function(seed, n = 70) {
  set.seed(seed)
  # POSITIVE — cusp f(x)=r+x-x^3 ramped through the fold (r: 0.7 -> -0.7),
  # start on the upper stable branch; at the n=70 default this is the
  # slow-passage approach (fold approached, lower attractor not yet reached).
  r <- seq(0.7, -0.7, length.out = n)
  pos <- numeric(n); pos[1] <- 1.30          # upper equilibrium near r=0.7
  for (t in 2:n) pos[t] <- pos[t-1] +
      (r[t] + pos[t-1] - pos[t-1]^3) * 0.10 + rnorm(1, 0, 0.03)
  # NEGATIVE — OU/AR(1): x_t = x_{t-1} + k*(mu - x_{t-1}) + noise
  # (k=0.30 -> AR coefficient 0.70; one stable equilibrium; linear).
  neg <- numeric(n); neg[1] <- 8
  for (t in 2:n) neg[t] <- neg[t-1] + 0.30 * (8 - neg[t-1]) +
                            rnorm(1, 0, 0.30)
  # transition index = the largest absolute one-step change in the series. At n=70
  # the positive control is in slow-passage drift (the fold is approached but the
  # lower attractor is not yet reached within the window); jump_idx therefore
  # identifies the noisiest step, not a completed bifurcation crossing. The
  # pre-transition window cut (je$t < jt - 1L) is still methodologically correct:
  # it isolates the CSD approach from whatever noise peak or eventual crossing
  # terminates the upper-branch trajectory. The heuristic is NOT a bifurcation detector.
  jump_idx <- function(v) which.max(abs(diff(v))) + 1L
  summ <- function(v, ramped) {
    nl <- smap_nonlinearity(v, E = 2, n_surr = 100, seed = seed)
    je <- smap_jacobian_eigen(v, E = 2, theta = 2)
    je <- je[is.finite(je$lambda_max), ]
    if (ramped) {                       # CSD is the APPROACH: pre-transition only
      jt <- jump_idx(v)
      # Exclude t=jt (jump/noise peak) AND t=jt-1 (may already be transitioning);
      # the CSD window is conservatively the pre-approach trajectory only.
      je <- je[je$t < jt - 1L, , drop = FALSE]
    }
    lt <- if (nrow(je) < 3L) NA_real_ else
            unname(stats::coef(stats::lm(lambda_max ~ t, data = je))[2])
    list(nonlinearity_detected = isTRUE(nl$p_value < 0.05),
         nl_p = nl$p_value, nl_delta = nl$delta,
         lambda_trend = lt)
  }
  list(positive = summ(pos, ramped = TRUE),
       negative = summ(neg, ramped = FALSE), seed = seed)
}

# ============================================================================
# Task 15: discrimination_table
# ============================================================================

#' Map the evidence bundle onto the four non-exclusive explanations (spec
#' §2.4). Returns a verdict + the supporting signatures per row. Never emits
#' "the system tipped"; honest negatives are first-class verdicts.
#'
#' NA-robustness: any ev field that is NA or NULL is treated as missing
#' evidence. Each explanation tracks which ev fields it depends on; if any
#' relevant field is NA/NULL the verdict is "indeterminate" for that row —
#' never a false "supported" or "refuted", never a crash. Fields not used by
#' a given explanation do not affect its verdict.
discrimination_table <- function(ev) {
  # Helper: extract one ev field; NULL -> NA (avoids && crash on NULL).
  .f <- function(field) {
    x <- ev[[field]]
    if (is.null(x)) NA else x
  }
  # Helper: TRUE iff a value is missing/malformed for verdict purposes —
  # NULL, non-scalar (length != 1), or NA. A non-scalar field cannot yield a
  # trustworthy supported/refuted verdict, so it is treated as missing.
  .is_missing <- function(x) is.null(x) || length(x) != 1L || is.na(x)
  # Core row builder. ev_deps: named list of ev field values this row uses.
  # If any dep is NA/NULL -> "indeterminate" (trumps cond_ref).
  # Otherwise: cond_sup TRUE & cond_ref FALSE -> "supported";
  #            cond_ref TRUE -> "refuted"; cond_sup NA -> "indeterminate";
  #            else "weak".
  row <- function(expl, cond_sup, cond_ref, signs, ev_deps) {
    if (any(sapply(ev_deps, .is_missing))) {
      return(data.frame(explanation = expl, verdict = "indeterminate",
                        signatures = signs, stringsAsFactors = FALSE))
    }
    v <- if (isTRUE(cond_sup) && !isTRUE(cond_ref)) "supported"
         else if (isTRUE(cond_ref)) "refuted"
         else if (is.na(cond_sup)) "indeterminate" else "weak"
    data.frame(explanation = expl, verdict = v, signatures = signs,
               stringsAsFactors = FALSE)
  }
  # Extract ev fields once (NULL -> NA where needed).
  nonlinear             <- .f("nonlinear")
  ltr                   <- .f("lambda_failed_to_relax")
  new_well              <- .f("new_potential_well")
  loop_p                <- .f("loop_p")
  eff_ret               <- .f("effective_driver_returned")
  artifact_reproduces   <- .f("artifact_reproduces")
  rbind(
    row("hysteresis",
        cond_sup = isTRUE(nonlinear) && isTRUE(ltr) &&
                   isTRUE(new_well) && isTRUE(loop_p < 0.05),
        cond_ref = isTRUE(eff_ret),
        signs    = "nonlinear + |lambda| not relaxed + new well + sig. loop",
        ev_deps  = list(nonlinear, ltr, new_well, loop_p, eff_ret)),
    row("unreturned_driver",
        cond_sup = identical(eff_ret, FALSE),
        cond_ref = isTRUE(eff_ret),
        signs    = "fishing removed but effective driver did not return",
        ev_deps  = list(eff_ret)),
    row("long_transient",
        cond_sup = identical(ltr, FALSE) && isTRUE(loop_p >= 0.05),
        cond_ref = isTRUE(new_well),
        signs    = "restoring but slow; no new well; n.s. loop",
        ev_deps  = list(ltr, loop_p, new_well)),
    row("artifact",
        cond_sup = isTRUE(artifact_reproduces),
        cond_ref = identical(artifact_reproduces, FALSE),
        signs    = "survey-artifact null reproduces the observed signal",
        ev_deps  = list(artifact_reproduces))
  )
}
