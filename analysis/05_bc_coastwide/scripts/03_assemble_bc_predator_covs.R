# ============================================================================
# 03_assemble_bc_predator_covs.R — Section/area-resolved predator covariates
# analysis/05_bc_coastwide
#
# Input: Sibling repo ~/pacific-herring-predators/data/processed/
# Output: Data/processed/bc_predator_covariates.csv (long format)
#         Data/processed/bc_predator_covariates_provenance.md (per-species notes)
#
# Spatial-resolution strategy:
#   - Where section-resolved data exists (HG), use it directly.
#   - Where only stock-area-aggregate exists (most species, most BC areas),
#     replicate the stock-area value across all sections in that area.
#   - Document per-species resolution in the provenance file so the modeling
#     step can decide which species to use as section-level vs stock-area-level
#     covariates.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))

PRED_REPO <- Sys.getenv("PREDATOR_REPO_PATH",
                        unset = "/Users/adrianstier/pacific-herring-predators")
stopifnot(dir.exists(PRED_REPO))

bc_spawn <- read_csv(here::here("Data", "processed", "bc_spawn_by_section_year.csv"),
                     show_col_types = FALSE)
section_key <- bc_spawn |>
  distinct(stock_area, statistical_area, section) |>
  arrange(stock_area, statistical_area, section)

# ── 1. Harbour seal: BC-wide interpolated curve (Olesiuk 2010), stock-area scope ──
hs_path <- file.path(PRED_REPO, "data", "processed", "consumption_budget",
                     "harbour_seal_BC_interpolated_along_Olesiuk_2010_curve.csv")
hs <- if (file.exists(hs_path)) {
  read_csv(hs_path, show_col_types = FALSE) |>
    select(year, harbour_seal_index = any_of(c("seal_n", "abundance", "value")))
} else {
  warning("harbour seal file missing: ", hs_path)
  tibble(year = integer(), harbour_seal_index = numeric())
}

# ── 2. Steller sea lion: BC-wide counts, stock-area scope ──
ssl_path <- file.path(PRED_REPO, "data", "processed", "consumption_budget",
                      "steller_sea_lion_BC_pup_count.csv")
ssl <- if (file.exists(ssl_path)) {
  read_csv(ssl_path, show_col_types = FALSE) |>
    select(year, steller_index = any_of(c("pups", "n", "count")))
} else {
  warning("steller sea lion file missing: ", ssl_path)
  tibble(year = integer(), steller_index = numeric())
}

# ── 3. Humpback whale: BC-wide photo-ID counts ──
hw_path <- file.path(PRED_REPO, "data", "processed", "consumption_budget",
                     "cheeseman_2024_humpback_BC_annual_indiv_encounters.csv")
hw <- if (file.exists(hw_path)) {
  read_csv(hw_path, show_col_types = FALSE) |>
    select(year, humpback_index = any_of(c("n_indiv_BC", "n", "abundance")))
} else {
  warning("humpback file missing: ", hw_path)
  tibble(year = integer(), humpback_index = numeric())
}

bc_year_cov <- reduce(list(hs, ssl, hw),
                     ~ full_join(.x, .y, by = "year")) |>
  arrange(year)

# Expand BC-wide year-covariates to section-year by replicating across sections.
covs_long <- crossing(year = YEARS,
                      section_key) |>
  left_join(bc_year_cov, by = "year")

out_path <- here::here("Data", "processed", "bc_predator_covariates.csv")
write_csv(covs_long, out_path)
cat("Wrote", nrow(covs_long), "rows to", out_path, "\n")

# Provenance file
prov_path <- here::here("Data", "processed", "bc_predator_covariates_provenance.md")
sink(prov_path)
cat("# BC Predator Covariates — Provenance and Spatial Resolution\n\n")
cat("Generated:", format(Sys.time()), "\n\n")
cat("Source repo: `", PRED_REPO, "`\n\n")
cat("## Per-species notes\n\n")
cat("| Species | Source file | Native resolution | Used in model as |\n")
cat("|---|---|---|---|\n")
cat("| harbour_seal | `harbour_seal_BC_interpolated_along_Olesiuk_2010_curve.csv` | BC-wide year | Stock-area-level covariate (replicated across sections within a stock area is identical) |\n")
cat("| steller | `steller_sea_lion_BC_pup_count.csv` | BC-wide year | Stock-area-level covariate (same) |\n")
cat("| humpback | `cheeseman_2024_humpback_BC_annual_indiv_encounters.csv` | BC-wide year | Stock-area-level covariate (same) |\n")
cat("\n")
cat("**Implication:** in scripts/08_fit_m5_bc.R, predator covariates enter as\n")
cat("year-by-stock-area effects, not section-by-year. Section-level predator\n")
cat("variation will be added in a later iteration if section-resolved data\n")
cat("becomes available from the sibling repo's consumption-budget products.\n")
sink()
cat("Wrote provenance to", prov_path, "\n")
