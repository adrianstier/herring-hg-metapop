# ============================================================================
# 05_prepare_stan_data.R — Assemble BC-wide Stan data list
# analysis/05_bc_coastwide
#
# Input:  Data/processed/bc_spawn_by_section_year.csv
#         Data/processed/bc_catch_by_section_year_gear.csv
#         Data/processed/bc_predator_covariates.csv
#         Data/processed/bc_distance_within_stock_area.rds
#         Data/processed/bc_fishery_events.csv
# Output: Data/processed/bc_stan_data.rds (named list ready for rstan::sampling())
#
# The list contains:
#   N_sections, N_years, N_stock_areas, stock_area_of[N_sections]
#   y[N_sections, N_years]      spawn-index tonnes (positive-only; zeros NA)
#   obs_mask[N_sections, N_years]  1 if y observed positive, 0 otherwise
#   D_blocks: long vector of within-area distances
#   block_starts, block_sizes: indices that reconstruct D as block-diagonal
#   predator_covs[N_stock_areas, N_years, P]
#   fishery_active[N_sections, N_years]   0/1 indicator using bc_fishery_events
#   n_years_active[N_sections]            count, for prior scaling
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))

spawn <- read_csv(here::here("Data", "processed",
                             "bc_spawn_by_section_year.csv"),
                  show_col_types = FALSE)
catch <- read_csv(here::here("Data", "processed",
                             "bc_catch_by_section_year_gear.csv"),
                  show_col_types = FALSE)
covs  <- read_csv(here::here("Data", "processed",
                             "bc_predator_covariates.csv"),
                  show_col_types = FALSE)
D_list <- readRDS(here::here("Data", "processed",
                             "bc_distance_within_stock_area.rds"))
events <- read_csv(here::here("Data", "processed",
                              "bc_fishery_events.csv"),
                   show_col_types = FALSE)

section_key <- spawn |>
  distinct(stock_area, statistical_area, section) |>
  arrange(stock_area, statistical_area, section) |>
  mutate(section_idx = row_number())

stock_areas <- sort(unique(section_key$stock_area))
section_key <- section_key |>
  mutate(stock_area_idx = match(stock_area, stock_areas))

N_sections <- nrow(section_key)
N_years    <- length(YEARS)
N_stock_areas <- length(stock_areas)

# y matrix (positive spawn only; zeros → NA → masked)
y_mat <- matrix(NA_real_, nrow = N_sections, ncol = N_years,
                dimnames = list(section_key$section_idx, YEARS))
spawn_keyed <- spawn |>
  inner_join(section_key, by = c("stock_area", "statistical_area", "section"))
for (i in seq_len(nrow(spawn_keyed))) {
  r <- spawn_keyed[i, ]
  if (!is.na(r$spawn_index_tonnes) && r$spawn_index_tonnes > 0) {
    y_mat[r$section_idx, as.character(r$year)] <- r$spawn_index_tonnes
  }
}
obs_mask <- (!is.na(y_mat)) * 1L
y_mat[is.na(y_mat)] <- 0  # Stan can't take NA; mask gates the likelihood

# Block-diagonal D: stack within-area matrices in stock-area order
D_blocks <- numeric()
block_starts <- integer()
block_sizes <- integer()
cur <- 0L
for (sa in stock_areas) {
  D <- D_list[[sa]]
  if (is.null(D)) D <- matrix(0, 0, 0)
  block_starts <- c(block_starts, cur + 1L)
  block_sizes <- c(block_sizes, nrow(D))
  D_blocks <- c(D_blocks, as.numeric(D))
  cur <- cur + length(D)
}

# Predator covariates: collapse to stock-area-year (predator data is
# stock-area-level per provenance file)
pred_pivot <- covs |>
  group_by(stock_area, year) |>
  summarise(across(any_of(c("harbour_seal_index", "steller_index",
                            "humpback_index")),
                   ~ mean(.x, na.rm = TRUE)),
            .groups = "drop")
pred_cols <- intersect(c("harbour_seal_index", "steller_index", "humpback_index"),
                       names(pred_pivot))
P <- length(pred_cols)
pred_arr <- array(0.0, dim = c(N_stock_areas, N_years, P),
                  dimnames = list(stock_areas, YEARS, pred_cols))
for (sa in stock_areas) {
  for (yr in YEARS) {
    row <- pred_pivot |> filter(stock_area == sa, year == yr)
    if (nrow(row) == 1L) {
      for (p in pred_cols) {
        v <- row[[p]]
        pred_arr[sa, as.character(yr), p] <- ifelse(is.finite(v), v, 0.0)
      }
    }
  }
}

# Fishery-active matrix from bc_fishery_events
fishery_active <- matrix(1L, nrow = N_sections, ncol = N_years,
                         dimnames = list(section_key$section_idx, YEARS))
for (i in seq_len(nrow(events))) {
  r <- events[i, ]
  if (r$event_kind == "closure" && !is.na(r$event_year)) {
    sec_mask <- section_key$stock_area == r$stock_area
    year_mask <- as.integer(YEARS) >= r$event_year
    fishery_active[sec_mask, year_mask] <- 0L
  }
}
n_years_active <- rowSums(fishery_active)

stan_data <- list(
  N_sections     = N_sections,
  N_years        = N_years,
  N_stock_areas  = N_stock_areas,
  N_pred_covs    = P,
  N_D            = length(D_blocks),
  stock_area_of  = section_key$stock_area_idx,
  y              = y_mat,
  obs_mask       = obs_mask,
  D_blocks       = D_blocks,
  block_starts   = block_starts,
  block_sizes    = block_sizes,
  predator_covs  = pred_arr,
  fishery_active = fishery_active,
  n_years_active = n_years_active,
  era_break_year = rep(1988L, N_stock_areas),  # placeholder; per-area in M3+
  section_meta   = section_key,
  stock_area_codes = stock_areas,
  years          = YEARS
)

out_path <- here::here("Data", "processed", "bc_stan_data.rds")
saveRDS(stan_data, out_path)
cat("Wrote Stan data list to", out_path, "\n")
cat("  N_sections:", N_sections, "\n")
cat("  N_years:", N_years, "\n")
cat("  N_stock_areas:", N_stock_areas, "\n")
cat("  Total positive obs:", sum(obs_mask), "\n")
