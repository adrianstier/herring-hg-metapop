# ============================================================================
# 11_ews_00_data_layers.R
# Task 2.1 — Build EWS input data layers (observed + latent posterior draws)
#
# Writes Output/diagnostics/ews_input_layers.rds, a named list of 4 tibbles:
#   observed_all11  — observed spawn index, 11 fitted sections, zeros → NA
#   observed_core9  — same, minus Tasu Sound & Gowgaia Bay + Naden Harbour
#   latent_all11    — per-draw posterior biomass (natural scale), 11 sections
#   latent_core9    — same, minus the 2 sparse sections
#
# Firewall: reads NOTHING from talk-usuk-forum-2026/.
#
# STEP-0 findings (do NOT modify without re-running inspection):
#   fit class     : stanfit (rstan), NOT CmdStanMCMC
#   latent param  : Z[t, j]  — t = year index (1=1951, 75=2025),
#                              j = site index (1..11 per SITE_NAMES order)
#   scale         : LOG scale; exp() required.
#   Scale check   : median(exp(Z[1,2])) = 678.42 matches CSV Port Louis 1951
#                   median = 678.42 — CONFIRMED natural scale after exp().
#   n_draws       : 10 000 (4 chains × 2500 iterations)
#   Thinning      : systematic every 5th draw → 2000 draws retained.
#                   Free system memory ~631 MB; full 10K-draw tibble ~660 MB
#                   plus already-loaded fit; thinning to 2000 keeps peak RSS
#                   safely under 350 MB for this array + tibble creation.
#   extract_posteriors() in R/03_fit_model.R uses gather_draws() on a
#                   CmdStanMCMC draws_df — NOT reusable for rstan stanfit.
#                   We read the stanfit directly via rstan::extract().
#   SECTIONS_KEEP ordering (j index): SITE_NAMES[j] from 00_setup.R
#     j=1  Tasu Sound & Gowgaia Bay   (core-9 EXCLUDED)
#     j=2  Port Louis
#     j=3  Rennell Sound
#     j=4  Englefield Bay
#     j=5  Louscoone Inlet
#     j=6  Naden Harbour              (core-9 EXCLUDED)
#     j=7  Juan Perez Sound
#     j=8  Skidegate Inlet
#     j=9  Cumshewa Inlet
#     j=10 Laskeek Bay
#     j=11 Skincuttle Inlet
#   lat/lon       : from spawn CSV; ~45% rows have coords (vary by year).
#                   We fill missing with per-section median to ensure every
#                   year × section row carries a coordinate.
# ============================================================================

suppressPackageStartupMessages({
  library(here)
  library(tidyverse)
  library(rstan)
})

# ── Paths ────────────────────────────────────────────────────────────────────
proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

# ── Canonical section / year mapping (from 00_setup.R) ──────────────────────
source(here::here("R", "00_setup.R"))
# After sourcing: SITE_NAMES, YEARS, N_SITES, SECTIONS_KEEP are in scope.
# SECTIONS_KEEP = c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25) — the 11 fitted
# sections in the order Stan received them (= j=1..11 in the latent array).

stopifnot(length(SITE_NAMES) == 11L, length(YEARS) == 75L)
cat("Canonical mapping loaded:\n")
cat("  N_SITES =", N_SITES, "\n")
cat("  YEARS   =", min(YEARS), "-", max(YEARS), "\n")
cat("  SECTIONS_KEEP:", paste(SECTIONS_KEEP, collapse = " "), "\n")

# Core-9 excludes these two sparse sections:
CORE9_EXCLUDE <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")


# ── 1. Observed layer ────────────────────────────────────────────────────────
spawn_path <- here::here("Data", "processed",
                         "HG_Spawn_Survey_1951_2025_all_sections.csv")
stopifnot(file.exists(spawn_path))

spawn_raw <- read_csv(spawn_path, show_col_types = FALSE)

# Compute per-section median lat/lon to fill rows that lack coordinates
section_coords <- spawn_raw |>
  group_by(section) |>
  summarise(
    lat_med = median(latitude,  na.rm = TRUE),
    lon_med = median(longitude, na.rm = TRUE),
    .groups = "drop"
  )

observed_all11 <- spawn_raw |>
  # Keep only the 11 fitted sections
  filter(section %in% SECTIONS_KEEP) |>
  # Ambiguous-zero convention: spawn_index_tonnes > 0 → value; else NA
  mutate(value = if_else(spawn_index_tonnes > 0, spawn_index_tonnes, NA_real_)) |>
  left_join(section_coords, by = "section") |>
  # Fill missing coords with per-section median
  mutate(
    latitude  = if_else(is.na(latitude),  lat_med, latitude),
    longitude = if_else(is.na(longitude), lon_med, longitude)
  ) |>
  select(year, section, site = section_name, value, latitude, longitude) |>
  arrange(year, section)

stopifnot(
  setequal(unique(observed_all11$year), 1951:2025),
  !any(observed_all11$value == 0, na.rm = TRUE)
)

observed_core9 <- observed_all11 |>
  filter(!site %in% CORE9_EXCLUDE)

cat("\nObserved layers:\n")
cat("  observed_all11: ", nrow(observed_all11), "rows,",
    n_distinct(observed_all11$section), "sections\n")
cat("  observed_core9: ", nrow(observed_core9), "rows,",
    n_distinct(observed_core9$section), "sections\n")
cat("  Zero-value check (should be 0):",
    sum(observed_all11$value == 0, na.rm = TRUE), "\n")


# ── 2. Latent layer — draw-level posterior biomass from stanfit ──────────────
fit_path <- here::here("Data", "processed", "m1_stier_11_fit.rds")
stopifnot(file.exists(fit_path))

cat("\nReading stanfit (~760 MB) — once only ...\n")
fit <- readRDS(fit_path)

if (!inherits(fit, "stanfit")) {
  stop("Expected an rstan stanfit object; got class: ", paste(class(fit), collapse = ", "),
       "\nInspect the fit and update this script's extraction branch.")
}

cat("  fit class confirmed: stanfit (rstan)\n")

# Extract Z[t, j] — log-scale latent state (pre-fishing biomass)
# rstan::extract returns a list; $Z is draws × T × J array
# Permuted = TRUE (default) concatenates chains into one draw dimension
cat("  Extracting Z draws ...\n")
Z_arr <- rstan::extract(fit, pars = "Z", permuted = TRUE)$Z
# dim: [n_draws, N_years, N_sites] = [10000, 75, 11]
n_draws_full <- dim(Z_arr)[1]
N_years_arr  <- dim(Z_arr)[2]
N_sites_arr  <- dim(Z_arr)[3]

stopifnot(N_years_arr == length(YEARS), N_sites_arr == N_SITES)
cat("  Z array dim:", paste(dim(Z_arr), collapse = " x "), "\n")

# Scale cross-check: median(exp(Z[draw, t=1, j=2])) should ~ 678.4
# (Port Louis, 1951; verified against m1_stier_11_section_biomass_by_year.csv)
scale_check <- median(exp(Z_arr[, 1, 2]))
cat(sprintf("  Scale check — Port Louis 1951 median: %.1f (expected ~678.4)\n",
            scale_check))
if (abs(scale_check - 678.4) > 50) {
  warning("Scale check deviation > 50 tonnes: exp() may be wrong or indexing is off. ",
          "Got ", round(scale_check, 1), " expected ~678.4")
}

# ── Thinning ─────────────────────────────────────────────────────────────────
# Full 10K-draw tibble ~ 660 MB RAM; system has ~631 MB free at script start
# (loaded fit already consumes ~760 MB of virtual/swap). Thin to 2000 draws
# (every 5th) for safe in-process tibble construction.
THIN_EVERY <- 5L
draw_idx <- seq(1L, n_draws_full, by = THIN_EVERY)
n_draws_kept <- length(draw_idx)
cat(sprintf("  Thinning: keeping %d of %d draws (every %dth)\n",
            n_draws_kept, n_draws_full, THIN_EVERY))

Z_thin <- Z_arr[draw_idx, , ]  # [2000, 75, 11]
rm(Z_arr); gc(verbose = FALSE)

# ── Build tidy tibble ─────────────────────────────────────────────────────────
# Map (draw_seq, t, j) -> (draw, year, section, site, value)
# YEARS[t] gives calendar year; SITE_NAMES[j] gives site name;
# SECTIONS_KEEP[j] gives the canonical section number.
cat("  Building latent tibble ...\n")

grid <- expand.grid(
  t_idx    = seq_len(N_years_arr),
  j_idx    = seq_len(N_sites_arr),
  draw_seq = seq_len(n_draws_kept),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

# exp() here — Z is on log scale (confirmed by scale check above)
latent_all11 <- tibble(
  draw    = grid$draw_seq,
  year    = YEARS[grid$t_idx],
  section = SECTIONS_KEEP[grid$j_idx],
  site    = SITE_NAMES[grid$j_idx],
  value   = exp(Z_thin[cbind(grid$draw_seq, grid$t_idx, grid$j_idx)])
) |>
  arrange(draw, year, section)

stopifnot(
  all(is.finite(latent_all11$value)),
  n_distinct(latent_all11$draw) > 1
)

latent_core9 <- latent_all11 |>
  filter(!site %in% CORE9_EXCLUDE)

cat(sprintf("  latent_all11: %d rows (%d draws x %d years x %d sections)\n",
            nrow(latent_all11), n_draws_kept, N_years_arr, N_sites_arr))
cat(sprintf("  latent_core9: %d rows (%d draws x %d years x %d sections)\n",
            nrow(latent_core9), n_draws_kept, N_years_arr,
            n_distinct(latent_core9$section)))
cat("  Finite-value check (all TRUE):", all(is.finite(latent_all11$value)), "\n")


# ── 3. Assemble and save ─────────────────────────────────────────────────────
layers <- list(
  observed_all11 = observed_all11,
  observed_core9 = observed_core9,
  latent_all11   = latent_all11,
  latent_core9   = latent_core9
)

# Attach metadata as attributes for downstream auditability
attr(layers, "n_draws")     <- n_draws_kept
attr(layers, "thin_every")  <- THIN_EVERY
attr(layers, "n_draws_full")<- n_draws_full
attr(layers, "latent_param")<- "Z[t,j] (log-scale pre-fishing biomass; exp() applied)"
attr(layers, "scale_check") <- sprintf("Port Louis 1951 median = %.2f (expected ~678.4)", scale_check)
attr(layers, "built")       <- as.character(Sys.time())

out_path <- file.path(diag_dir, "ews_input_layers.rds")
saveRDS(layers, out_path)

cat("\n=== ews_input_layers.rds written ===\n")
cat("  Path:", out_path, "\n")
cat("  Draws kept:", n_draws_kept, "(thinned from", n_draws_full, ")\n")
cat("  observed_all11 rows:", nrow(observed_all11), "\n")
cat("  observed_core9 rows:", nrow(observed_core9), "\n")
cat("  latent_all11  rows:", nrow(latent_all11), "\n")
cat("  latent_core9  rows:", nrow(latent_core9), "\n")
cat("  Scale check:", attr(layers, "scale_check"), "\n")
cat("Done.\n")
