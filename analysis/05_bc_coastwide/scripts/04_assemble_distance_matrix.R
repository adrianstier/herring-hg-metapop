# ============================================================================
# 04_assemble_distance_matrix.R — Within-stock-area distance matrices
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv
# Output: Data/processed/bc_distance_within_stock_area.rds
#         (named list of haversine distance matrices, one per stock area, km)
#
# Section centroid = median(lat, long) over all spawn events ever recorded
# in that section. Block-diagonal Σ in the Stan model uses these within-area
# matrices; cross-area distances are set to Inf and yield Σ entries of 0.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(geosphere)
})

source(here::here("R", "00_setup.R"))

raw <- read_csv(here::here("Data", "raw", "dfo-spawn",
                           "Pacific_herring_spawn_index_data_2025_EN.csv"),
                show_col_types = FALSE) |>
  janitor::clean_names()

centroids <- raw |>
  filter(!is.na(longitude), !is.na(latitude)) |>
  rename(stock_area = region) |>
  mutate(stock_area = if_else(is.na(stock_area), "NA", as.character(stock_area)),
         statistical_area = as.character(statistical_area),
         section = as.character(section)) |>
  group_by(stock_area, statistical_area, section) |>
  summarise(lon = median(longitude, na.rm = TRUE),
            lat = median(latitude,  na.rm = TRUE),
            .groups = "drop")

stopifnot(nrow(centroids) > 0)
cat("Section centroids computed for", nrow(centroids), "sections across",
    n_distinct(centroids$stock_area), "stock areas.\n")

D_list <- centroids |>
  split(centroids$stock_area) |>
  map(function(df) {
    if (nrow(df) < 2L) {
      return(matrix(0, nrow = nrow(df), ncol = nrow(df),
                    dimnames = list(df$section, df$section)))
    }
    coords <- as.matrix(df[, c("lon", "lat")])
    D_m <- geosphere::distm(coords, fun = geosphere::distHaversine)
    D_km <- D_m / 1000
    dimnames(D_km) <- list(df$section, df$section)
    D_km
  })

out_path <- here::here("Data", "processed", "bc_distance_within_stock_area.rds")
saveRDS(D_list, out_path)
cat("Wrote distance-matrix list to", out_path, "\n")
cat("Stock areas:", paste(names(D_list), collapse = ", "), "\n")
cat("Sizes (sections):",
    paste(sprintf("%s=%d", names(D_list), sapply(D_list, nrow)),
          collapse = ", "), "\n")
