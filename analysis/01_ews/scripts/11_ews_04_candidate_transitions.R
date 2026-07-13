# ============================================================================
# 11_ews_04_candidate_transitions.R — Candidate-transition years per EWS target
# stier-2027-herring-metapopulation
#
# Task 3.4: For three target series (biomass, synchrony, occupancy), detect
# candidate regime-shift years via ews_detect_transitions() (STARS + strucchange)
# and combine with two mandatory documented era boundaries (1966, 2005).
# A third documented row (synchronization episode) is emitted only if a
# breakpoint is detected on the synchrony target.
#
# Input files:
#   Output/diagnostics/ews_input_layers.rds     — latent_core9 (Task 2.1)
#   Output/diagnostics/ews_spatial_synchrony.csv — synchrony φ (Task 3.2)
#   Data/processed/portfolio_metrics_annual.csv  — effective_n / occupancy
#
# Output:
#   Output/diagnostics/ews_candidate_transitions.csv
#
# Schema: target, year, method, label, year_convention
#   target         : "biomass" | "synchrony" | "occupancy"
#   year           : integer; for method=="breakpoint" already +1L (first year
#                    of NEW regime); STARS and documented years kept as-is
#   method         : "stars" | "breakpoint" | "documented"
#   label          : descriptive string for documented rows; "" for detected rows
#   year_convention: constant "first_year_of_new_regime" for all rows
#
# strucchange off-by-one convention (§4 of spec):
#   ews_detect_transitions() returns the LAST year of the OLD regime for
#   method=="breakpoint" (strucchange convention). We add +1L here so every
#   breakpoint row refers to the FIRST year of the new regime. STARS rows are
#   point detections and are kept as returned. All rows carry
#   year_convention = "first_year_of_new_regime" so Task 5.1 lead-time math
#   is unambiguous.
#
# Target construction choices:
#   biomass   : latent_core9 layer; sum across the 9 core sections, MEDIAN
#               across 2000 draws, per year (1951:2025). Drops sparse sections
#               by design — core9 excludes the two sparse all11-only sections.
#   synchrony : latent | core9 | window_len == 15. Rationale: latent layer
#               avoids observation-noise contamination of phi; core9 matches
#               the biomass target for consistency; window_len=15 is the
#               canonical medium window that balances resolution vs smoothing.
#               window_mid is used as the year axis (integer year at window
#               centre).
#   occupancy : effective_n from portfolio_metrics_annual.csv; full span
#               1951:2025.
#
# Firewall: does NOT import from analysis/04_talks/2026-royalsociety/; does NOT modify R/11.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

cat("=== Task 3.4: Candidate-transition years per EWS target ===\n")
cat(format(Sys.time()), "\n\n")

# ---------------------------------------------------------------------------
# 1. Load input data
# ---------------------------------------------------------------------------
cat("--- Loading inputs ---\n")

L <- readRDS(file.path(diag_dir, "ews_input_layers.rds"))
cat("ews_input_layers.rds loaded; layers:", paste(names(L), collapse = ", "), "\n")

sync_all <- readr::read_csv(
  file.path(diag_dir, "ews_spatial_synchrony.csv"),
  show_col_types = FALSE
)
cat("ews_spatial_synchrony.csv rows:", nrow(sync_all), "\n")

port <- readr::read_csv(
  file.path(proj_dir, "Data", "processed", "portfolio_metrics_annual.csv"),
  show_col_types = FALSE
)
cat("portfolio_metrics_annual.csv rows:", nrow(port), "\n")

# ---------------------------------------------------------------------------
# 2. Helper: apply +1L to breakpoint years (strucchange off-by-one fix)
#    STARS years are kept as returned. Documented years: always as specified.
# ---------------------------------------------------------------------------
apply_convention <- function(detected_tbl) {
  # detected_tbl: tibble with columns year (integer), method (character)
  if (nrow(detected_tbl) == 0L) return(detected_tbl)
  detected_tbl <- detected_tbl |>
    dplyr::mutate(
      year = dplyr::if_else(method == "breakpoint", year + 1L, year)
    )
  detected_tbl
}

# ---------------------------------------------------------------------------
# 3. Target: biomass
#    latent_core9 — sum across sections, MEDIAN across draws, per year
# ---------------------------------------------------------------------------
cat("\n--- Target: biomass ---\n")

lc9 <- L[["latent_core9"]]
cat("latent_core9: draws =", dplyr::n_distinct(lc9$draw),
    " sections =", dplyr::n_distinct(lc9$section),
    " years =", dplyr::n_distinct(lc9$year), "\n")

# Aggregate: sum across sections per (draw, year), then median across draws
biomass_series <- lc9 |>
  dplyr::group_by(draw, year) |>
  dplyr::summarise(agg = sum(value, na.rm = TRUE), .groups = "drop") |>
  dplyr::group_by(year) |>
  dplyr::summarise(x = stats::median(agg, na.rm = TRUE), .groups = "drop") |>
  dplyr::arrange(year)

cat("Biomass series: years", min(biomass_series$year), "-",
    max(biomass_series$year), "| n =", nrow(biomass_series), "\n")
cat("Biomass range: [", round(min(biomass_series$x)), ",",
    round(max(biomass_series$x)), "]\n")

bio_raw <- ews_detect_transitions(
  years = biomass_series$year,
  x     = biomass_series$x,
  l     = 10L,
  p     = 0.05
)
bio_detected <- apply_convention(bio_raw)
bio_detected <- bio_detected |>
  dplyr::mutate(
    target         = "biomass",
    label          = "",
    year_convention = "first_year_of_new_regime"
  )
cat("Biomass detected transitions (after +1L for breakpoints):\n")
print(bio_detected)

# ---------------------------------------------------------------------------
# 4. Target: synchrony
#    latent | core9 | window_len == 15; window_mid as integer year; phi column
# ---------------------------------------------------------------------------
cat("\n--- Target: synchrony ---\n")

# Canonical choice: latent layer, core9 unit, 15-year window.
# Rationale: latent removes observation-noise; core9 aligns with biomass target;
# window_len=15 is the medium window (10 is noisy, 20 loses early-era resolution).
sync_sub <- sync_all |>
  dplyr::filter(layer == "latent" & unit == "core9" & window_len == 15L) |>
  dplyr::arrange(window_mid)

cat("Synchrony subset (latent|core9|window_len=15): rows =", nrow(sync_sub),
    " | window_mid range:", min(sync_sub$window_mid), "-",
    max(sync_sub$window_mid), "\n")

sync_raw <- ews_detect_transitions(
  years = as.integer(sync_sub$window_mid),
  x     = sync_sub$phi,
  l     = 10L,
  p     = 0.05
)
sync_detected <- apply_convention(sync_raw)
sync_detected <- sync_detected |>
  dplyr::mutate(
    target          = "synchrony",
    label           = "",
    year_convention = "first_year_of_new_regime"
  )
cat("Synchrony detected transitions (after +1L for breakpoints):\n")
print(sync_detected)

# Capture the synchrony breakpoint year (if any) for the conditional documented row
sync_bp_rows <- sync_detected |> dplyr::filter(method == "breakpoint")
sync_bp_year <- if (nrow(sync_bp_rows) >= 1L) sync_bp_rows$year[1L] else NULL

if (!is.null(sync_bp_year)) {
  cat(sprintf(
    "Synchrony breakpoint detected at year %d (will emit synchronization documented row).\n",
    sync_bp_year
  ))
} else {
  cat("No synchrony breakpoint detected — synchronization documented row OMITTED.\n")
}

# ---------------------------------------------------------------------------
# 5. Target: occupancy (effective_n)
# ---------------------------------------------------------------------------
cat("\n--- Target: occupancy ---\n")

occ_series <- port |>
  dplyr::select(year, effective_n) |>
  dplyr::filter(is.finite(effective_n)) |>
  dplyr::arrange(year)

cat("Occupancy series: years", min(occ_series$year), "-",
    max(occ_series$year), "| n =", nrow(occ_series), "\n")
cat("effective_n range: [", round(min(occ_series$effective_n), 2), ",",
    round(max(occ_series$effective_n), 2), "]\n")

occ_raw <- ews_detect_transitions(
  years = occ_series$year,
  x     = occ_series$effective_n,
  l     = 10L,
  p     = 0.05
)
occ_detected <- apply_convention(occ_raw)
occ_detected <- occ_detected |>
  dplyr::mutate(
    target          = "occupancy",
    label           = "",
    year_convention = "first_year_of_new_regime"
  )
cat("Occupancy detected transitions (after +1L for breakpoints):\n")
print(occ_detected)

# ---------------------------------------------------------------------------
# 6. Documented era boundaries (always emitted, regardless of detection)
#    year 1966: 1960s reduction-fishery crash — applied to all 3 targets
#    year 2005: fishery closure — applied to all 3 targets
#    synchronization episode: conditional on sync breakpoint detection
# ---------------------------------------------------------------------------
cat("\n--- Building documented era rows ---\n")

# Mandatory documented rows (both eras × all 3 targets)
doc_rows <- dplyr::bind_rows(
  # 1966 — 1960s reduction-fishery crash
  tibble::tibble(
    target          = c("biomass", "synchrony", "occupancy"),
    year            = 1966L,
    method          = "documented",
    label           = "1960s reduction-fishery crash",
    year_convention = "first_year_of_new_regime"
  ),
  # 2005 — fishery closure
  tibble::tibble(
    target          = c("biomass", "synchrony", "occupancy"),
    year            = 2005L,
    method          = "documented",
    label           = "fishery closure",
    year_convention = "first_year_of_new_regime"
  )
)

# Conditional synchronization documented row — only if breakpoint found on synchrony
if (!is.null(sync_bp_year)) {
  sync_doc_row <- tibble::tibble(
    target          = c("biomass", "synchrony", "occupancy"),
    year            = as.integer(sync_bp_year),
    method          = "documented",
    label           = "synchronization episode (breakpoint on phi, latent|core9|15yr)",
    year_convention = "first_year_of_new_regime"
  )
  doc_rows <- dplyr::bind_rows(doc_rows, sync_doc_row)
  cat(sprintf("Synchronization documented rows added at year %d.\n", sync_bp_year))
} else {
  cat("No synchronization documented rows added (no breakpoint on synchrony).\n")
}

# ---------------------------------------------------------------------------
# 7. Bind all results and write CSV
# ---------------------------------------------------------------------------
cat("\n--- Binding results ---\n")

final <- dplyr::bind_rows(
  bio_detected,
  sync_detected,
  occ_detected,
  doc_rows
) |>
  dplyr::mutate(
    year            = as.integer(year),
    year_convention = as.character(year_convention)
  ) |>
  dplyr::select(target, year, method, label, year_convention) |>
  dplyr::arrange(target, method, year)

cat("Final rows:", nrow(final), "\n")
cat("Rows per target:\n")
print(final |> dplyr::count(target, method))

# ---------------------------------------------------------------------------
# 8. Sanity checks
# ---------------------------------------------------------------------------
cat("\n=== Sanity checks ===\n")

schema_ok <- all(c("target", "year", "method", "label", "year_convention") %in% names(final))
cat(sprintf("Schema columns present        : %s\n", schema_ok))

targets_ok <- setequal(unique(final$target), c("biomass", "synchrony", "occupancy"))
cat(sprintf("All 3 targets present         : %s\n", targets_ok))

methods_ok <- all(unique(final$method) %in% c("stars", "breakpoint", "documented"))
cat(sprintf("Methods valid                 : %s\n", methods_ok))

doc_1966 <- any(dplyr::filter(final, method == "documented")$year == 1966L)
doc_2005 <- any(dplyr::filter(final, method == "documented")$year == 2005L)
cat(sprintf("Documented 1966 present       : %s\n", doc_1966))
cat(sprintf("Documented 2005 present       : %s\n", doc_2005))

conv_ok <- all(final$year_convention == "first_year_of_new_regime")
cat(sprintf("year_convention constant      : %s\n", conv_ok))

yr_range_ok <- all(final$year >= 1951L & final$year <= 2026L)
cat(sprintf("Years in [1951, 2026]         : %s (range: %d-%d)\n",
            yr_range_ok, min(final$year), max(final$year)))

# ---------------------------------------------------------------------------
# 9. Write output
# ---------------------------------------------------------------------------
out_path <- file.path(diag_dir, "ews_candidate_transitions.csv")
readr::write_csv(final, out_path)

cat("\n=== DONE ===\n")
cat(sprintf("Output                     : %s\n", out_path))
cat(sprintf("Total rows written         : %d\n", nrow(final)))
cat(sprintf("Rows per target (summary)  :\n"))
final |>
  dplyr::count(target, name = "n_rows") |>
  dplyr::arrange(target) |>
  print()

cat("\nDetected transition years per target/method:\n")
final |>
  dplyr::filter(method != "documented") |>
  dplyr::arrange(target, method, year) |>
  print(n = 100)

cat("\nDocumented era rows:\n")
final |>
  dplyr::filter(method == "documented") |>
  dplyr::distinct(year, label) |>
  dplyr::arrange(year) |>
  print()

sync_doc_included <- !is.null(sync_bp_year)
cat(sprintf("\nSynchronization documented row included: %s", sync_doc_included))
if (sync_doc_included) {
  cat(sprintf(" (year %d)\n", sync_bp_year))
} else {
  cat("\n")
}
