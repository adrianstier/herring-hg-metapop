# ============================================================================
# 00_data_acquisition.R — Refresh BC-wide DFO datasets
# analysis/05_bc_coastwide
#
# Downloads/refreshes:
#   - Pacific Herring spawn index (BC-wide; already present, re-download for refresh)
#   - Pacific Herring commercial catch (BC-wide, Open Data Portal)
#
# Open Data Portal landing:
#   https://open.canada.ca/data/en/dataset?q=pacific+herring
#
# IMPORTANT: DFO occasionally rotates the resource URL on the portal. If the
# request returns a 404, browse the portal, find the most recent "Pacific
# Herring Commercial Catch" resource, update CATCH_URL below, and re-run.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(httr)
})

source(here::here("R", "00_setup.R"))

raw_dir <- here::here("Data", "raw", "dfo-catch")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

# Resolve the most recent Open Data resource. As of 2026-05-21 the canonical
# resource lives at the Pacific Herring Commercial Catch dataset; update
# CATCH_URL from the portal if the next refresh 404s.
CATCH_URL <- Sys.getenv(
  "DFO_HERRING_CATCH_URL",
  unset = "https://open.canada.ca/data/en/dataset/2deec71e-fcf9-4cf6-8c8a-fa4097ef0fd9"
)

cat("Fetching DFO commercial catch from:\n  ", CATCH_URL, "\n")
cat("If this 404s, browse https://open.canada.ca/data/en/dataset?q=pacific+herring,\n",
    "find the current Pacific Herring Commercial Catch resource, set\n",
    "DFO_HERRING_CATCH_URL env var to the .csv resource URL, and re-run.\n\n")

dest_path <- file.path(raw_dir, "bc_commercial_catch_OPEN_DATA.csv")

resp <- httr::GET(CATCH_URL, httr::write_disk(dest_path, overwrite = TRUE))

if (httr::status_code(resp) != 200L) {
  stop("Download failed (HTTP ", httr::status_code(resp), "). ",
       "Resolve the portal URL manually and set DFO_HERRING_CATCH_URL.")
}

cat("Wrote", file.size(dest_path), "bytes to", dest_path, "\n")

# Sanity check: file should not be an HTML error page
first_line <- readLines(dest_path, n = 1L)
if (grepl("^<", first_line)) {
  stop("Downloaded file appears to be HTML, not CSV. ",
       "The URL likely points to a portal landing page; ",
       "you need the direct CSV resource URL.")
}

cat("First line preview:", substring(first_line, 1L, 120L), "\n")
