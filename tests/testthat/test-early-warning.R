# ============================================================================
# test-early-warning.R — Early-warning-signal indicator library tests
# stier-2027-herring-metapopulation
#
# Run with: testthat::test_file("tests/testthat/test-early-warning.R")
# ============================================================================

library(testthat)
source(here::here("R", "11_early_warning.R"))

test_that("EWS dependencies are installed", {
  for (pkg in c("earlywarnings", "spatialwarnings", "MARSS",
                "posterior", "Kendall", "strucchange", "zoo")) {
    expect_true(requireNamespace(pkg, quietly = TRUE),
                info = paste("missing package:", pkg))
  }
})

test_that("Loreau-de Mazancourt phi hits analytic bounds", {
  # Perfect synchrony: identical columns -> phi == 1
  m_sync <- matrix(rep(c(1, 2, 3, 4, 5), 3), ncol = 3)
  expect_equal(ews_synchrony_phi(m_sync), 1, tolerance = 1e-8)

  # Perfect compensation: two anti-phase columns of equal sd -> phi == 0
  m_async <- cbind(c(1, 2, 3, 2, 1), c(3, 2, 1, 2, 3))
  expect_equal(ews_synchrony_phi(m_async), 0, tolerance = 1e-8)
})

test_that("Gross eta is +1 for identical, -1 for perfect anti-phase", {
  m_sync <- cbind(c(1, 2, 3, 4), c(1, 2, 3, 4))
  expect_equal(ews_synchrony_eta(m_sync), 1, tolerance = 1e-8)
  m_anti <- cbind(c(1, 2, 3, 4), c(4, 3, 2, 1))
  expect_equal(ews_synchrony_eta(m_anti), -1, tolerance = 1e-8)
})

test_that("synchrony indicators are NA-robust (mirror compute_synchrony_lm)", {
  m <- cbind(c(1,2,3,4,5), c(2,1,4,3,5), c(NA,NA,NA,NA,NA))
  expect_true(is.finite(ews_synchrony_eta(m)))   # all-NA col dropped
  expect_true(is.finite(ews_synchrony_phi(m)))
  m2 <- cbind(c(1,2,3,4,5), c(5,5,5,5,5))         # zero-variance col
  expect_no_warning(ews_synchrony_eta(m2))
  expect_true(is.na(ews_synchrony_eta(m2)))
  expect_no_warning(ews_synchrony_phi(m2))
})

test_that("leading eigen share is 1 for a rank-1 (perfectly synchronous) system", {
  set.seed(1)
  z <- rnorm(50)
  m <- cbind(z, 2 * z, -0.5 * z)            # all columns collinear
  out <- ews_cov_eigen(m)
  expect_equal(out$eig_share, 1, tolerance = 1e-6)
  expect_gt(out$lambda_max, 0)
})

test_that("leading eigen share ~ 1/p for independent equal-variance columns", {
  set.seed(2)
  m <- matrix(rnorm(4000), ncol = 4)
  out <- ews_cov_eigen(m)
  expect_equal(out$eig_share, 0.25, tolerance = 0.06)
})

test_that("ews_cov_eigen is guard- and NA-robust", {
  g <- ews_cov_eigen(matrix(1:4, ncol = 1))           # ncol<2 guard
  expect_true(is.na(g$lambda_max) && length(g$loadings) == 1)
  s <- ews_cov_eigen(matrix(c(1,1,1,1,1,1), ncol = 2)) # zero-variance / degenerate
  expect_true(is.na(s$eig_share) || (is.finite(s$eig_share) && s$eig_share <= 1 + 1e-9))
  m <- cbind(c(1,2,3,NA,5,6), c(2,1,4,3,5,4), c(1,3,2,4,6,5))
  out <- ews_cov_eigen(m)                              # NA present -> no crash
  expect_true(is.na(out$eig_share) || (out$eig_share >= 0 && out$eig_share <= 1 + 1e-9))
})

test_that("spatial variance and skew match base R on a year vector", {
  v <- c(1, 5, 2, 8, 3)
  expect_equal(ews_spatial_variance(v), stats::var(v))
  expect_equal(round(ews_spatial_skew(v), 6),
               round(mean((v - mean(v))^3) / (mean((v - mean(v))^2))^1.5, 6))
})

test_that("Moran's I matches an independent double-sum computation and detects gradient", {
  coords <- cbind(1:6, rep(0, 6)); vals <- as.numeric(1:6)
  # independent reference: I = (n/S0) * sum_ij w_ij z_i z_j / sum_i z_i^2
  d <- as.matrix(stats::dist(coords)); W <- 1/d; diag(W) <- 0
  rs <- rowSums(W); W <- W / rs                    # row-standardised
  z <- vals - mean(vals); n <- length(vals)
  num <- 0; for (i in 1:n) for (j in 1:n) num <- num + W[i,j]*z[i]*z[j]
  ref <- (n / sum(W)) * num / sum(z^2)
  expect_equal(ews_morans_i(vals, coords), ref, tolerance = 1e-8)
  expect_gt(ews_morans_i(vals, coords), 0)         # positive autocorrelation
  # detects structure: gradient I exceeds mean I of random permutations
  set.seed(20260519L)
  perm <- replicate(200, ews_morans_i(sample(vals), coords))
  expect_gt(ews_morans_i(vals, coords), mean(perm, na.rm = TRUE))
})

test_that("spatial EWS are degenerate/NA-robust (spec §8)", {
  expect_true(is.na(ews_spatial_variance(c(3))))            # <2 finite
  expect_true(is.na(ews_spatial_variance(c(NA, NA))))
  expect_true(is.na(ews_spatial_skew(c(5, 5, 5, 5))))       # zero variance -> NA not NaN
  expect_true(is.na(ews_spatial_skew(c(1, 2))))             # <3 finite -> NA
  expect_false(is.nan(ews_spatial_skew(c(5,5,5,5))))
  cc <- cbind(c(1,1,1), c(0,0,0))                           # identical coords
  expect_true(is.na(ews_morans_i(c(1,2,3), cc)))
  expect_true(is.na(ews_morans_i(c(5,5,5,5), cbind(1:4, 0)))) # zero spatial variance -> NA not Inf
  expect_no_warning(ews_morans_i(c(5,5,5,5), cbind(1:4, 0)))
})

test_that("generic battery returns the expected indicator columns", {
  set.seed(3)
  x <- as.numeric(cumsum(rnorm(60)))
  res <- ews_generic_battery(x, win_frac = 0.5, detrend = "gaussian")
  expect_true(all(c("time","ar1","variance","sd","skew","kurtosis",
                     "cv","densratio") %in% names(res)))
  expect_true(nrow(res) > 5)
  expect_false("acf1" %in% names(res))
})

test_that("generic battery is degenerate-robust (spec §8)", {
  short <- ews_generic_battery(rnorm(8), win_frac = 0.5, detrend = "none")
  expect_s3_class(short, "tbl_df")                       # empty tibble, not error
  expect_true(all(c("time","ar1","variance","sd","skew","kurtosis",
                     "cv","densratio") %in% names(short)))
  expect_equal(nrow(short), 0L)
  flat <- ews_generic_battery(rep(5, 60), win_frac = 0.5, detrend = "none")
  expect_s3_class(flat, "tbl_df")                        # constant series: no crash
  expect_no_warning(ews_generic_battery(c(rnorm(40), NA, rnorm(19)),
                                        win_frac = 0.5, detrend = "gaussian"))
})

test_that("ews_generic_battery is headless-robust (no screen device needed)", {
  nd <- length(grDevices::dev.list())
  set.seed(11)
  r <- ews_generic_battery(as.numeric(cumsum(rnorm(80))), 0.5, "gaussian")
  expect_gt(nrow(r), 5)                              # NOT the empty contract
  expect_true(any(is.finite(r$ar1)))                 # real EWS values
  expect_equal(length(grDevices::dev.list()), nd)    # no leaked device
})

test_that("MAR1 dominant eigenvalue recovers a known stable AR system", {
  set.seed(4)
  n <- 300; B <- matrix(c(0.6, 0.05, 0.0, 0.5), 2, 2)
  X <- matrix(0, n, 2)
  for (t in 2:n) X[t, ] <- B %*% X[t - 1, ] + rnorm(2, 0, 0.1)
  lam <- ews_mar1_eigen(X)
  expect_lt(lam, 1)        # stable
  expect_gt(lam, 0.3)      # near true dominant eigenvalue ~0.61
})

test_that("ews_mar1_eigen is degenerate/NA-robust (spec §8)", {
  expect_true(is.na(ews_mar1_eigen(matrix(1:6, ncol = 2))))     # too few rows
  expect_true(is.na(ews_mar1_eigen(matrix(rnorm(4), ncol = 1))))# <2 cols
  Xc <- matrix(rep(c(2, 5), each = 30), ncol = 2)               # constant cols
  expect_true(is.na(ews_mar1_eigen(Xc)))                        # singular OLS -> NA
  expect_no_warning(ews_mar1_eigen(matrix(1:6, ncol = 2)))
  Xna <- matrix(rnorm(120), ncol = 2); Xna[5, 1] <- NA          # NA -> MARSS path
  v <- suppressWarnings(ews_mar1_eigen(Xna))
  expect_true(is.na(v) || (is.finite(v) && v >= 0))
})

test_that("Kendall surrogate test flags a strong trend, not white noise", {
  set.seed(5)
  trend <- ews_kendall_surrogate(seq(0, 1, length.out = 40) + rnorm(40, 0, 0.02),
                                  n_surr = 200)
  expect_lt(trend$p_value, 0.05); expect_gt(trend$tau, 0.7)
  flat <- ews_kendall_surrogate(rnorm(40), n_surr = 200)
  expect_gt(flat$p_value, 0.05)
})

test_that("ews_kendall_surrogate is degenerate-robust and deterministic (spec §8)", {
  expect_true(is.na(ews_kendall_surrogate(c(1, 2, 3), n_surr = 50)$tau))   # n<5
  cflat <- ews_kendall_surrogate(rep(7, 30), n_surr = 50)                  # constant
  expect_true(is.na(cflat$tau) || is.na(cflat$p_value))
  expect_no_warning(ews_kendall_surrogate(rep(7, 30), n_surr = 50))
  expect_no_warning(ews_kendall_surrogate(c(NA, 1:30, NA), n_surr = 50))   # NA stripped
  expect_no_warning(ews_kendall_surrogate(                                 # acf1 == 0 -> a==0
    c(1,0,-1,0,1,0,-1,0,1,0,-1,0,1,0,-1,0,1,0,-1,0), n_surr = 50))
  set.seed(42L); z <- cumsum(rnorm(30))                                    # fixed y
  a <- ews_kendall_surrogate(z, n_surr = 100, seed = 42L)
  b <- ews_kendall_surrogate(z, n_surr = 100, seed = 42L)
  expect_equal(a$p_value, b$p_value)                                       # deterministic
  c_diff <- ews_kendall_surrogate(z, n_surr = 100, seed = 999L)            # seed discriminates
  expect_false(isTRUE(all.equal(a$p_value, c_diff$p_value)))
})

test_that("transition detector finds a planted mean shift near its true year", {
  set.seed(6)
  x <- c(rnorm(30, 10, 1), rnorm(30, 3, 1))
  yrs <- 1951:2010
  ct <- ews_detect_transitions(yrs, x)
  expect_true(any(abs(ct$year - 1981) <= 3))
})

test_that("ews_detect_transitions returns a stable empty contract and is §8-robust", {
  empty <- ews_detect_transitions(integer(0), numeric(0))
  expect_s3_class(empty, "tbl_df")
  expect_identical(names(empty), c("year", "method"))
  expect_equal(nrow(empty), 0L)
  expect_type(empty$year, "integer"); expect_type(empty$method, "character")
  # all-NA x -> empty contract, no error/warning
  e2 <- ews_detect_transitions(1951:1970, rep(NA_real_, 20))
  expect_identical(names(e2), c("year", "method")); expect_equal(nrow(e2), 0L)
  # constant series -> no t.test "essentially constant" error, empty contract
  expect_no_warning(ews_detect_transitions(1951:1980, rep(5, 30)))
  cc <- ews_detect_transitions(1951:1980, rep(5, 30))
  expect_identical(names(cc), c("year", "method"))
  # too-short series -> empty contract, no crash
  short <- ews_detect_transitions(1951:1955, rnorm(5))
  expect_identical(names(short), c("year", "method"))
})

test_that("battery detects an approaching fold and stays quiet on a stationary system", {
  # NB: ews_sim_metapop reseeds internally per `seed` arg; fold/stat share the stream start and differ only by scenario (intended controlled contrast)
  fold <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "approaching_fold")
  stat <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "stationary")
  phi_fold <- zoo::rollapply(fold, 15,
    function(w) ews_synchrony_phi(matrix(w, ncol = 9)),
    by.column = FALSE, align = "right")
  tf <- ews_kendall_surrogate(phi_fold[is.finite(phi_fold)], n_surr = 200)
  phi_stat <- zoo::rollapply(stat, 15,
    function(w) ews_synchrony_phi(matrix(w, ncol = 9)),
    by.column = FALSE, align = "right")
  ts <- ews_kendall_surrogate(phi_stat[is.finite(phi_stat)], n_surr = 200)
  expect_gt(ts$p_value, 0.20)            # negative control: no spurious trend
  expect_lt(tf$p_value, 0.10)
})

test_that("ews_sim_metapop is finite, shaped, and deterministic (spec §8)", {
  a <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "stationary", seed = 1L)
  expect_true(is.matrix(a) && all(dim(a) == c(60, 9)))
  expect_true(all(is.finite(a)))                         # never NaN/Inf
  b <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "stationary", seed = 1L)
  expect_identical(a, b)                                 # deterministic given seed
  c2 <- ews_sim_metapop(n_sites = 9, n_years = 60, scenario = "stationary", seed = 2L)
  expect_false(isTRUE(all.equal(a, c2)))                 # seed actually drives it
  f <- ews_sim_metapop(n_sites = 5, n_years = 40, scenario = "approaching_fold", seed = 1L)
  expect_true(is.matrix(f) && all(dim(f) == c(40, 5)) && all(is.finite(f)))
})

test_that("ews_detect_transitions strucchange-only mode (n < 2l+1) still detects a clear step", {
  x <- c(rep(2, 7), rep(9, 7)); yrs <- 1990:2003   # n=14, l=10 -> STARS gated off
  ct <- ews_detect_transitions(yrs, x)
  expect_identical(names(ct), c("year", "method"))
  expect_true(nrow(ct) >= 1L && all(ct$method == "breakpoint"))
})

# ── Task 2.1: data-layer builder contract test ──────────────────────────────
test_that("data-layer builder writes both layers x both units with the right contract", {
  fit_path <- here::here("Data", "processed", "m1_stier_11_fit.rds")
  skip_if_not(file.exists(fit_path), "m1_stier_11_fit.rds absent")
  out <- system2("Rscript", here::here("Code", "11_ews_00_data_layers.R"),
                  stdout = TRUE, stderr = TRUE)
  f <- here::here("Output", "diagnostics", "ews_input_layers.rds")
  expect_true(file.exists(f))
  L <- readRDS(f)
  expect_setequal(names(L),
    c("observed_all11", "observed_core9", "latent_all11", "latent_core9"))
  expect_true(all(c("year", "section", "site", "value", "latitude", "longitude")
                  %in% names(L$observed_all11)))
  expect_true(all(c("draw", "year", "section", "site", "value")
                  %in% names(L$latent_core9)))
  expect_gt(dplyr::n_distinct(L$latent_core9$draw), 1)          # real draws
  expect_setequal(unique(L$observed_all11$year), 1951:2025)
  expect_false(any(L$observed_all11$value == 0, na.rm = TRUE))  # zeros -> NA
  # core-9 excludes the 2 sparse sections; all-11 includes them
  expect_false(any(grepl("Tasu|Naden", L$observed_core9$site)))
  expect_true(any(grepl("Tasu|Naden", L$observed_all11$site)))
  expect_true(all(is.finite(L$latent_core9$value)))             # natural scale, finite
})

# ── Task 3.1: generic aggregate EWS output-contract test ────────────────────
test_that("generic aggregate EWS output: schema, layers, latent CI present", {
  skip_if_not(file.exists(here::here("Output","diagnostics","ews_input_layers.rds")))
  out <- system2("Rscript",
    here::here("Code","11_ews_01_generic_aggregate.R"),
    stdout = TRUE, stderr = TRUE)
  f <- here::here("Output","diagnostics","ews_generic_aggregate.csv")
  expect_true(file.exists(f))
  d <- readr::read_csv(f, show_col_types = FALSE)
  needed <- c("layer","unit","detrend","win_frac","year",
              "ar1","ar1_lo","ar1_hi","variance","variance_lo","variance_hi",
              "sd","skew","kurtosis","cv","densratio","returnrate")
  expect_true(all(needed %in% names(d)))
  expect_setequal(unique(d$layer), c("observed","latent"))
  expect_setequal(unique(d$unit),  c("all11","core9"))
  expect_true(any(is.finite(d$ar1)) && any(is.finite(d$variance)))
  # latent CI is a real interval somewhere (hi > lo for at least some rows)
  lat <- dplyr::filter(d, layer == "latent")
  expect_true(any(lat$ar1_hi > lat$ar1_lo, na.rm = TRUE))
  # observed point: lo == hi == point
  obs <- dplyr::filter(d, layer == "observed")
  expect_true(all(obs$ar1_lo == obs$ar1 | is.na(obs$ar1), na.rm = TRUE))
})

# ── Task 3.2: spatial/synchrony EWS output-contract test ────────────────────
test_that("spatial/synchrony EWS output: schema, phi in [0,1], latent CI, units", {
  skip_if_not(file.exists(here::here("Output","diagnostics","ews_input_layers.rds")))
  system2("Rscript", here::here("Code","11_ews_02_spatial_synchrony.R"),
          stdout = TRUE, stderr = TRUE)
  f <- here::here("Output","diagnostics","ews_spatial_synchrony.csv")
  expect_true(file.exists(f))
  d <- readr::read_csv(f, show_col_types = FALSE)
  need <- c("layer","unit","window_len","window_mid",
            "phi","phi_lo","phi_hi","eta","spatial_var","spatial_skew",
            "morans_i","cv_ratio","n_occupied")
  expect_true(all(need %in% names(d)))
  expect_setequal(unique(d$layer), c("observed","latent"))
  expect_setequal(unique(d$unit),  c("all11","core9"))
  expect_setequal(unique(d$window_len), c(10,15,20))
  ph <- d$phi[is.finite(d$phi)]
  expect_true(length(ph) > 0 && all(ph >= -1e-9 & ph <= 1 + 1e-9))   # phi in [0,1]
  lat <- dplyr::filter(d, layer == "latent")
  expect_true(any(lat$phi_hi > lat$phi_lo, na.rm = TRUE))            # real CI
  obs <- dplyr::filter(d, layer == "observed")
  expect_true(all(obs$phi_lo == obs$phi | is.na(obs$phi), na.rm = TRUE))
  # core9 has 2 fewer sections than all11 -> n_occupied generally lower/eq
  expect_true(all(d$n_occupied <= 11, na.rm = TRUE))
})

# ── Task 3.3: covariance leading-EOF / lambda_max + MAR(1) eigenvalue ───────
test_that("covariance eigen + MAR(1) EWS output: schema, ranges, latent CI", {
  skip_if_not(file.exists(here::here("Output","diagnostics","ews_input_layers.rds")))
  system2("Rscript", here::here("Code","11_ews_03_covariance_eigen.R"),
          stdout = TRUE, stderr = TRUE)
  f <- here::here("Output","diagnostics","ews_covariance_eigen.csv")
  expect_true(file.exists(f))
  d <- readr::read_csv(f, show_col_types = FALSE)
  need <- c("layer","unit","window_len","window_mid",
            "lambda_max","lambda_max_lo","lambda_max_hi",
            "eig_share","eig_share_lo","eig_share_hi",
            "mar1_eigen","mar1_eigen_lo","mar1_eigen_hi")
  expect_true(all(need %in% names(d)))
  expect_setequal(unique(d$layer), c("observed","latent"))
  expect_setequal(unique(d$unit),  c("all11","core9"))
  expect_setequal(unique(d$window_len), c(10,15,20))
  es <- d$eig_share[is.finite(d$eig_share)]
  expect_true(length(es) > 0 && all(es >= -1e-9 & es <= 1 + 1e-9))   # in [0,1]
  expect_true(any(d$lambda_max > 0, na.rm = TRUE))                    # variance positive
  lat <- dplyr::filter(d, layer == "latent")
  expect_true(any(lat$lambda_max_hi > lat$lambda_max_lo, na.rm = TRUE))  # real CI
  obs <- dplyr::filter(d, layer == "observed")
  expect_true(all(obs$lambda_max_lo == obs$lambda_max | is.na(obs$lambda_max),
                  na.rm = TRUE))
})

test_that("candidate transitions output: schema, documented eras present, convention", {
  skip_if_not(file.exists(here::here("Output","diagnostics","ews_input_layers.rds")))
  skip_if_not(file.exists(here::here("Output","diagnostics","ews_spatial_synchrony.csv")))
  system2("Rscript",
    here::here("Code","11_ews_04_candidate_transitions.R"),
    stdout = TRUE, stderr = TRUE)
  f <- here::here("Output","diagnostics","ews_candidate_transitions.csv")
  expect_true(file.exists(f))
  d <- readr::read_csv(f, show_col_types = FALSE)
  expect_true(all(c("target","year","method","label","year_convention") %in% names(d)))
  expect_setequal(unique(d$target), c("biomass","synchrony","occupancy"))
  expect_true(all(unique(d$method) %in% c("stars","breakpoint","documented")))
  # documented era anchors must be present
  doc <- dplyr::filter(d, method == "documented")
  expect_true(any(doc$year == 1966) && any(doc$year == 2005))
  # year_convention is the constant string everywhere
  expect_true(all(d$year_convention == "first_year_of_new_regime"))
  # years are reasonable integers within data range
  expect_true(all(d$year >= 1951 & d$year <= 2026))
  expect_true(is.integer(d$year) || all(d$year == as.integer(d$year)))
})

test_that("surrogate significance output: schema, ranges, both pre_window variants", {
  f <- here::here("Output","diagnostics","ews_surrogate_significance.csv")
  skip_if_not(file.exists(f), "ews_surrogate_significance.csv absent — run Code/11_ews_05_surrogate_significance.R first")
  d <- readr::read_csv(f, show_col_types = FALSE)
  expect_true(all(c("tier","layer","unit","indicator","window_def",
                    "pre_window","n","tau","p_value") %in% names(d)))
  expect_setequal(unique(d$layer), c("observed","latent"))
  expect_setequal(unique(d$unit),  c("all11","core9"))
  expect_setequal(unique(d$pre_window), c("full","pre1966"))
  expect_setequal(unique(d$tier), c(1,2,3))
  finite <- d[is.finite(d$tau) & is.finite(d$p_value), ]
  expect_true(nrow(finite) > 50)                                           # real signal
  expect_true(all(finite$tau >= -1 - 1e-9 & finite$tau <= 1 + 1e-9))       # Kendall in [-1,1]
  expect_true(all(finite$p_value >= 0 - 1e-9 & finite$p_value <= 1 + 1e-9))
  # at least one strong-trend row should be significant (sanity)
  expect_true(any(finite$p_value < 0.05))
})

test_that("sensitivity grid output: schema, robust flag, leave-out coverage", {
  f <- here::here("Output","diagnostics","ews_sensitivity_grid.csv")
  skip_if_not(file.exists(f), "ews_sensitivity_grid.csv absent — run Code/11_ews_06_sensitivity_grid.R first")
  d <- readr::read_csv(f, show_col_types = FALSE)
  expect_true(all(c("indicator","layer","unit","window","detrend","estimator",
                    "leave_out","tau","p_value","n","robust") %in% names(d)))
  expect_setequal(unique(d$layer), c("observed","latent"))
  expect_setequal(unique(d$unit),  c("all11","core9"))
  expect_true("none" %in% unique(d$leave_out))
  expect_true(length(unique(d$leave_out)) > 1)   # actual leave-outs present
  expect_true(is.logical(d$robust))
  fin <- d[is.finite(d$tau) & is.finite(d$p_value), ]
  expect_true(nrow(fin) > 100)
  expect_true(all(fin$tau >= -1 - 1e-9 & fin$tau <= 1 + 1e-9))
  expect_true(all(fin$p_value >= 0 - 1e-9 & fin$p_value <= 1 + 1e-9))
})

test_that("artifact audit: disqualified CSV + md present, schema sane", {
  fc <- here::here("Output","diagnostics","ews_survey_artifact_disqualified.csv")
  fm <- here::here("Output","diagnostics","ews_survey_artifact_audit.md")
  skip_if_not(file.exists(fc), "ews_survey_artifact_disqualified.csv absent — run Code/11_ews_07_survey_artifact_audit.R first")
  skip_if_not(file.exists(fm))
  d <- readr::read_csv(fc, show_col_types = FALSE)
  expect_true(all(c("indicator","artifact_tau_median","artifact_pos_sig_frac",
                    "disqualified","n_rep") %in% names(d)))
  expect_true(is.logical(d$disqualified))
  expect_true(all(d$artifact_pos_sig_frac >= 0 & d$artifact_pos_sig_frac <= 1, na.rm = TRUE))
  expect_true(nrow(d) >= 6)  # at least 6 indicators (phi/eta/ar1/eig_share/mar1_eigen/spatial_var minimum)
  md <- readLines(fm)
  expect_true(any(grepl("Honest-failure verdict", md)))
  expect_true(any(grepl("Comparison vs observed", md)))
})
