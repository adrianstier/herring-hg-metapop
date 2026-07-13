# ============================================================================
# 01_assemble_bc_spawn.R — Aggregate DFO spawn-index data to section-year panel
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv
#         (31,168 rows, spawn-event level)
# Output: Data/processed/bc_spawn_by_section_year.csv
#         (one row per section-year with spawn-index sum in tonnes + event count)
#
# Stock-area codes retained: HG, PRD, CC, SoG, WCVI, A27, A2W, NA (all 8).
# Year range: 1951–2025.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))

raw_path <- here::here("Data", "raw", "dfo-spawn",
                       "Pacific_herring_spawn_index_data_2025_EN.csv")
stopifnot(file.exists(raw_path))

raw <- read_csv(raw_path, show_col_types = FALSE) |>
  janitor::clean_names()

# Rename Region → stock_area; coerce types
spawn_events <- raw |>
  rename(stock_area = region,
         statistical_area = statistical_area,
         section = section) |>
  mutate(year = as.integer(year),
         stock_area = if_else(is.na(stock_area), "NA", as.character(stock_area)),
         statistical_area = as.character(statistical_area),
         section = as.character(section),
         spawn_number = as.numeric(spawn_number))

# Aggregate to section-year
panel <- spawn_events |>
  group_by(year, stock_area, statistical_area, section) |>
  summarise(spawn_index_tonnes = sum(spawn_number, na.rm = TRUE),
            n_events = n(),
            .groups = "drop") |>
  arrange(year, stock_area, statistical_area, section) |>
  filter(year >= 1951L, year <= 2025L)

out_path <- here::here("Data", "processed", "bc_spawn_by_section_year.csv")
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_csv(panel, out_path)

cat("Wrote", nrow(panel), "rows to", out_path, "\n")
cat("Stock-area distribution:\n")
print(panel |> count(stock_area))
