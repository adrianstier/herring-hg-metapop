# R/layer_L1_biology.R
#
# L1 Biology Layer — frozen snapshot of m1_stier_11 total biomass by year.
#
# biomass_t is the model's posterior median of the HG total (all-11-section
# report set, report_set == "all_11"), faithfully imported from the promoted
# baseline model.  This is NOT a sum of section-level posterior medians.
#
# This layer is HG-only (Haida Gwaii).  The promoted baseline model
# (m1_stier_11) covers only the HG stock-assessment region (SAR); all rows
# map to region = "HG".  The other four SARs (PRD, CC, SoG, WCVI) are absent
# from the upstream model and must NOT be fabricated — they are simply not
# present in L1 for backbone v1.
#
# The one-directional firewall is enforced by the export script:
# data-raw/biology/export_biology_from_metapop.R reads from the sibling
# metapopulation repo and produces a frozen snapshot + PROVENANCE.yaml here.
# This loader is read-only with respect to the metapopulation repo.
#
# Depends (sourced before calling):
#   R/schema.R  — defines REGIONS

# ---------------------------------------------------------------------------
# read_provenance()
# Parse a simple "key: value" YAML file.  Works on the format written by
# export_biology_from_metapop.R (no block scalars, no nested structures).
# Returns a named list of character values.
# ---------------------------------------------------------------------------
read_provenance <- function(path) {
  lines <- readLines(path, warn = FALSE)
  # Drop blank lines
  lines <- lines[nzchar(trimws(lines))]
  kv    <- stringr::str_split(lines, ":\\s*", n = 2)
  # Drop entries that don't split cleanly into exactly 2 parts
  valid <- vapply(kv, length, integer(1L)) == 2L
  kv    <- kv[valid]
  vals  <- lapply(kv, `[[`, 2)
  keys  <- vapply(kv, `[[`, character(1L), 1)
  setNames(vals, keys)
}

# ---------------------------------------------------------------------------
# build_L1()
# Load the frozen total-biomass snapshot and return one HG row per year.
#
# Source columns used:
#   year       — calendar year (integer)
#   median     — posterior median HG-total biomass in tonnes (double)
#   report_set — "all_11" selects the all-sections HG total; "focal_9" is
#                excluded (subset of sections only)
#
# Returns one row per year:
#   region            = factor("HG", levels = REGIONS)
#   year              = as.integer(year)
#   biomass_t         = posterior median of HG total, tonnes
#   recruitment       = NA_real_  (not in source file)
#   exploitation_rate = NA_real_  (not in source file)
#
# NO section summation is performed; this is a faithful import of the
# model's already-aggregated HG-total posterior.
# ---------------------------------------------------------------------------
build_L1 <- function() {
  if (!exists("REGIONS")) stop("REGIONS not found - source R/schema.R before calling build_L1()")

  f <- here::here("data-raw", "biology", "m1_stier_11_biology_total_by_year.csv")
  if (!file.exists(f)) {
    stop(
      "L1 source file not found: ", f,
      "\nRun:  Rscript --vanilla data-raw/biology/export_biology_from_metapop.R"
    )
  }

  raw <- readr::read_csv(f, show_col_types = FALSE) |>
    janitor::clean_names()

  # Select all-11-section HG total rows only
  raw <- raw[raw$report_set == "all_11", ]

  stopifnot(
    "No rows with report_set == 'all_11' found in L1 snapshot" = nrow(raw) > 0
  )

  # One row per year: direct import of model's posterior median HG total.
  # No grouping/summation needed; each year appears exactly once in all_11.
  raw |>
    dplyr::transmute(
      region            = factor("HG", levels = REGIONS),
      year              = as.integer(year),
      biomass_t         = as.double(median),   # posterior median HG total, tonnes
      recruitment       = NA_real_,
      exploitation_rate = NA_real_
    )
}
