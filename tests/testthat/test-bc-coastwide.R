# ============================================================================
# test-bc-coastwide.R — Unit + integration tests for analysis/05_bc_coastwide/
# stier-2027-herring-metapopulation
#
# Run with: testthat::test_file("tests/testthat/test-bc-coastwide.R")
#
# Tests are gated by file existence — they SKIP rather than FAIL if upstream
# scripts haven't produced their outputs yet. This lets the file run cleanly
# from any pipeline state.
# ============================================================================

library(testthat)
library(tidyverse)
library(here)

# ── Spawn panel ──

test_that("bc_spawn panel exists and has expected columns", {
  path <- here("Data", "processed", "bc_spawn_by_section_year.csv")
  expect_true(file.exists(path),
              info = "run analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R first")
  panel <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("year", "stock_area", "statistical_area", "section",
                    "spawn_index_tonnes", "n_events") %in% names(panel)))
})

test_that("bc_spawn covers all 8 stock-area codes", {
  path <- here("Data", "processed", "bc_spawn_by_section_year.csv")
  skip_if_not(file.exists(path))
  panel <- read_csv(path, show_col_types = FALSE)
  expected_codes <- c("HG", "PRD", "CC", "SoG", "WCVI", "A27", "A2W", "NA")
  expect_true(all(expected_codes %in% panel$stock_area))
})

test_that("bc_spawn year range is 1951–2025", {
  path <- here("Data", "processed", "bc_spawn_by_section_year.csv")
  skip_if_not(file.exists(path))
  panel <- read_csv(path, show_col_types = FALSE)
  expect_equal(min(panel$year), 1951L)
  expect_equal(max(panel$year), 2025L)
})

test_that("bc_spawn has no negative spawn-index values", {
  path <- here("Data", "processed", "bc_spawn_by_section_year.csv")
  skip_if_not(file.exists(path))
  panel <- read_csv(path, show_col_types = FALSE)
  expect_true(all(panel$spawn_index_tonnes >= 0, na.rm = TRUE))
})

# ── Catch panel (raw + processed) ──

test_that("bc commercial catch raw download exists and has stock-area-resolved rows", {
  path <- here("Data", "raw", "dfo-catch", "bc_commercial_catch_OPEN_DATA.csv")
  expect_true(file.exists(path),
              info = "run analysis/05_bc_coastwide/scripts/00_data_acquisition.R first")
  raw <- read_csv(path, show_col_types = FALSE, n_max = 200)
  cols <- tolower(names(raw))
  expect_true(any(grepl("section", cols)) || any(grepl("statistical", cols)))
})

test_that("bc_catch panel exists with section-year-gear schema", {
  path <- here("Data", "processed", "bc_catch_by_section_year_gear.csv")
  expect_true(file.exists(path),
              info = "run scripts/02_assemble_bc_catch.R first")
  panel <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("year", "stock_area", "statistical_area", "section",
                    "gear", "catch_tonnes") %in% names(panel)))
})

test_that("bc_catch year range starts at 1951 or earlier", {
  path <- here("Data", "processed", "bc_catch_by_section_year_gear.csv")
  skip_if_not(file.exists(path))
  panel <- read_csv(path, show_col_types = FALSE)
  expect_true(min(panel$year, na.rm = TRUE) <= 1951L)
})

test_that("bc_catch covers at least 5 major stock areas", {
  path <- here("Data", "processed", "bc_catch_by_section_year_gear.csv")
  skip_if_not(file.exists(path))
  panel <- read_csv(path, show_col_types = FALSE)
  major <- c("HG", "PRD", "CC", "SoG", "WCVI")
  expect_true(all(major %in% panel$stock_area))
})

# ── CSAS cross-check ──

test_that("CSAS appendix catch table exists and matches Open Data within tolerance", {
  csas_path <- here("Data", "processed", "bc_catch_csas_appendix.csv")
  od_path   <- here("Data", "processed", "bc_catch_by_section_year_gear.csv")
  skip_if_not(file.exists(csas_path),
              "run scripts/02b_csas_appendix_crosscheck.R first")
  skip_if_not(file.exists(od_path))
  csas <- read_csv(csas_path, show_col_types = FALSE)
  od   <- read_csv(od_path, show_col_types = FALSE)

  od_sum <- od |>
    group_by(year, stock_area) |>
    summarise(od_t = sum(catch_tonnes, na.rm = TRUE), .groups = "drop")
  csas_sum <- csas |>
    group_by(year, stock_area) |>
    summarise(csas_t = sum(catch_tonnes, na.rm = TRUE), .groups = "drop")

  comp <- inner_join(od_sum, csas_sum, by = c("year", "stock_area")) |>
    filter(csas_t > 0) |>
    mutate(rel_diff = abs(od_t - csas_t) / csas_t)

  expect_gte(mean(comp$rel_diff <= 0.02), 0.95)
  expect_lte(max(comp$rel_diff), 0.10)
})

# ── Predator covariates ──

test_that("bc_predator_covariates exists with stock-area-year schema", {
  path <- here("Data", "processed", "bc_predator_covariates.csv")
  expect_true(file.exists(path),
              info = "run scripts/03_assemble_bc_predator_covs.R first")
  covs <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("year", "stock_area", "section") %in% names(covs)))
  numeric_cols <- names(covs)[sapply(covs, is.numeric)]
  expect_true(length(setdiff(numeric_cols, c("year"))) >= 1)
})

test_that("bc_predator_covariates_provenance.md documents per-species resolution", {
  path <- here("Data", "processed", "bc_predator_covariates_provenance.md")
  skip_if_not(file.exists(path))
  text <- readLines(path, warn = FALSE) |> paste(collapse = "\n")
  for (sp in c("harbour_seal", "steller", "humpback")) {
    expect_match(text, sp, fixed = TRUE,
                 info = paste("provenance should document", sp))
  }
})

# ── Distance matrices ──

test_that("bc_distance_within_stock_area is a list of symmetric distance matrices", {
  path <- here("Data", "processed", "bc_distance_within_stock_area.rds")
  expect_true(file.exists(path),
              info = "run scripts/04_assemble_distance_matrix.R first")
  D_list <- readRDS(path)
  expect_type(D_list, "list")
  expect_true(length(D_list) >= 5)
  for (nm in names(D_list)) {
    D <- D_list[[nm]]
    expect_true(is.matrix(D), info = paste(nm, "must be a matrix"))
    expect_equal(nrow(D), ncol(D), info = paste(nm, "must be square"))
    expect_equal(D, t(D), info = paste(nm, "must be symmetric"))
    expect_true(all(diag(D) == 0), info = paste(nm, "diagonal must be 0"))
  }
})

# ── Stan data list ──

test_that("bc_stan_data.rds is a complete Stan data list", {
  path <- here("Data", "processed", "bc_stan_data.rds")
  expect_true(file.exists(path),
              info = "run scripts/05_prepare_stan_data.R first")
  d <- readRDS(path)
  expect_true(is.list(d))
  required <- c("N_sections", "N_years", "N_stock_areas",
                "stock_area_of", "y", "obs_mask",
                "D_blocks", "block_starts", "block_sizes",
                "predator_covs",
                "fishery_active", "n_years_active")
  expect_true(all(required %in% names(d)),
              info = paste("missing:", paste(setdiff(required, names(d)), collapse=", ")))
  expect_true(d$N_sections >= 80)
  expect_equal(d$N_years, 75L)  # 1951–2025
  expect_equal(d$N_stock_areas, 8L)
})

test_that("bc_fishery_events.csv lists anchor years per stock area", {
  path <- here("Data", "processed", "bc_fishery_events.csv")
  expect_true(file.exists(path))
  evt <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("stock_area", "event_year", "event_kind") %in% names(evt)))
  hg_close <- evt |> filter(stock_area == "HG", event_kind == "closure")
  expect_true(any(hg_close$event_year %in% 2001:2003))
})

# ── Stan models (compile only — fast smoke test) ──

test_that("herring_metapop_bc_m1.stan compiles and smoke-fits on 5-section synthetic data", {
  skip_on_cran()
  skip_if_not_installed("rstan")
  stan_path <- here("analysis", "05_bc_coastwide", "stan",
                    "herring_metapop_bc_m1.stan")
  expect_true(file.exists(stan_path))

  set.seed(20260521)
  N_s <- 5L; N_y <- 10L; N_a <- 2L
  z <- matrix(rnorm(N_s * N_y), N_s, N_y)
  y <- exp(z + rnorm(N_s * N_y, 0, 0.1))
  obs_mask <- matrix(1L, N_s, N_y)
  D1 <- as.matrix(dist(matrix(rnorm(6), 3, 2)))
  D2 <- as.matrix(dist(matrix(rnorm(4), 2, 2)))
  D_blocks <- c(as.numeric(D1), as.numeric(D2))
  block_starts <- c(1L, length(as.numeric(D1)) + 1L)
  block_sizes <- c(3L, 2L)
  stan_data <- list(
    N_sections = N_s, N_years = N_y, N_stock_areas = N_a,
    stock_area_of = c(1L, 1L, 1L, 2L, 2L),
    y = y, obs_mask = obs_mask,
    N_D = length(D_blocks),
    D_blocks = D_blocks,
    block_starts = block_starts, block_sizes = block_sizes
  )

  mod <- rstan::stan_model(stan_path, verbose = FALSE)
  fit <- rstan::sampling(mod, data = stan_data, chains = 1, iter = 200,
                         warmup = 100, refresh = 0, verbose = FALSE)
  expect_true(inherits(fit, "stanfit"))
})

test_that("herring_metapop_bc_m3.stan compiles", {
  skip_on_cran()
  skip_if_not_installed("rstan")
  stan_path <- here("analysis", "05_bc_coastwide", "stan",
                    "herring_metapop_bc_m3.stan")
  expect_true(file.exists(stan_path))
  expect_silent(rstan::stan_model(stan_path, verbose = FALSE))
})

test_that("herring_metapop_bc_m5.stan compiles", {
  skip_on_cran()
  skip_if_not_installed("rstan")
  stan_path <- here("analysis", "05_bc_coastwide", "stan",
                    "herring_metapop_bc_m5.stan")
  expect_true(file.exists(stan_path))
  expect_silent(rstan::stan_model(stan_path, verbose = FALSE))
})

# ── Fits + integration gates ──

test_that("m1_bc subset (HG+WCVI) posteriors overlap existing M1_stier_11 on HG sections", {
  skip_on_cran()
  subset_path <- here("analysis", "05_bc_coastwide", "output",
                      "m1_bc_subset_HG_WCVI_fit.rds")
  hg_path <- here("Output", "posteriors", "m1_stier_11_fit.rds")
  skip_if_not(file.exists(subset_path),
              "run scripts/06_fit_m1_bc.R with SUBSET=HG_WCVI first")
  skip_if_not(file.exists(hg_path), "HG M1_stier_11 fit not on disk")

  bc_fit <- readRDS(subset_path)
  hg_fit <- readRDS(hg_path)

  bc_r <- rstan::extract(bc_fit$fit, "r_area")$r_area
  hg_idx <- which(bc_fit$stock_areas == "HG")
  bc_r_hg <- bc_r[, hg_idx]
  hg_r <- rstan::extract(hg_fit, "r")$r

  bc_q <- quantile(bc_r_hg, c(0.1, 0.9))
  hg_q <- quantile(hg_r, c(0.1, 0.9))
  overlap <- max(0, min(bc_q[2], hg_q[2]) - max(bc_q[1], hg_q[1]))
  range_total <- max(bc_q[2], hg_q[2]) - min(bc_q[1], hg_q[1])
  expect_gt(overlap / range_total, 0.5)
})

test_that("m1_bc full-fit HG-section posteriors still overlap M1_stier_11 at 80% CI", {
  skip_on_cran()
  full_path <- here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds")
  hg_path <- here("Output", "posteriors", "m1_stier_11_fit.rds")
  skip_if_not(file.exists(full_path), "run full m1_bc cloud fit first")
  skip_if_not(file.exists(hg_path), "HG M1_stier_11 fit not on disk")

  bc <- readRDS(full_path)
  hg <- readRDS(hg_path)

  bc_r <- rstan::extract(bc$fit, "r_area")$r_area
  hg_idx <- which(bc$stock_areas == "HG")
  bc_r_hg <- bc_r[, hg_idx]
  hg_r <- rstan::extract(hg, "r")$r

  bc_q <- quantile(bc_r_hg, c(0.1, 0.9))
  hg_q <- quantile(hg_r, c(0.1, 0.9))
  overlap <- max(0, min(bc_q[2], hg_q[2]) - max(bc_q[1], hg_q[1]))
  range_total <- max(bc_q[2], hg_q[2]) - min(bc_q[1], hg_q[1])
  expect_gt(overlap / range_total, 0.5)
})

test_that("M3 BC fit (if present) has Gompertz beta posteriors per stock area", {
  skip_on_cran()
  path <- here("analysis", "05_bc_coastwide", "output", "m3_bc_fit.rds")
  skip_if_not(file.exists(path), "run scripts/07_fit_m3_bc.R first")
  obj <- readRDS(path)
  beta <- rstan::extract(obj$fit, "beta_area")$beta_area
  expect_equal(ncol(beta), length(obj$stock_areas))
})

test_that("M5 BC fit (if present) has gamma_pred posteriors per species per area", {
  skip_on_cran()
  path <- here("analysis", "05_bc_coastwide", "output", "m5_bc_fit.rds")
  skip_if_not(file.exists(path), "run scripts/08_fit_m5_bc.R first")
  obj <- readRDS(path)
  gamma <- rstan::extract(obj$fit, "gamma_pred")$gamma_pred
  expect_equal(dim(gamma)[2], 3)  # harbour_seal, steller, humpback
  expect_equal(dim(gamma)[3], length(obj$stock_areas))
})

# ── Post-fit diagnostics ──

test_that("MCMC diagnostics + LOO outputs exist after scripts/09", {
  mcmc_p <- here("Output", "diagnostics", "bc_coastwide_mcmc_diagnostics.md")
  loo_p  <- here("Output", "diagnostics", "bc_coastwide_loo_table.csv")
  skip_if_not(file.exists(mcmc_p) && file.exists(loo_p),
              "run scripts/09_diagnostics.R first")
  loo_tab <- read_csv(loo_p, show_col_types = FALSE)
  expect_true(all(c("model", "elpd_loo", "se_elpd_loo") %in% names(loo_tab)))
  expect_true(all(c("m1_bc", "m3_bc", "m5_bc") %in% loo_tab$model))
})

test_that("Comparative-areas summary CSV has required columns", {
  path <- here("Output", "diagnostics", "bc_comparative_areas.csv")
  skip_if_not(file.exists(path), "run scripts/10_comparative_areas.R first")
  tab <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("stock_area", "recovery_metric_value",
                    "recovery_metric_name", "years_post_event") %in% names(tab)))
  expect_true(all(c("HG", "WCVI", "SoG", "CC", "PRD") %in% tab$stock_area))
})

test_that("BC portfolio metrics output has synchrony + cv_ratio + occupancy", {
  path <- here("Output", "diagnostics", "bc_portfolio_metrics.csv")
  skip_if_not(file.exists(path), "run scripts/11_bc_portfolio.R first")
  pm <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("stock_area", "metric", "value") %in% names(pm)))
  metrics <- unique(pm$metric)
  expect_true(all(c("phi_synchrony", "cv_ratio", "occupancy_fraction") %in% metrics))
})

test_that("All 5 BC-coastwide manuscript figures exist as PDF + PNG with legends", {
  for (n in 1:5) {
    for (ext in c("pdf", "png")) {
      path <- here("Output", "figures",
                   sprintf("bc_coastwide_fig%d.%s", n, ext))
      skip_if_not(file.exists(path),
                  paste("missing:", path, "— run scripts/12_manuscript_figures.R"))
    }
    legend_path <- here("Output", "figures", "legends",
                        sprintf("bc_coastwide_fig%d_legend.md", n))
    skip_if_not(file.exists(legend_path),
                paste("missing:", legend_path))
  }
  # If we reach here, all 5 figs+legends exist; pass with explicit expect.
  expect_true(TRUE)
})
