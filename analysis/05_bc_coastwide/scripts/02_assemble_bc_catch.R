# ============================================================================
# 02_assemble_bc_catch.R — Assemble BC-wide catch panel from Open Data
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-catch/bc_commercial_catch_OPEN_DATA.csv
#         (from scripts/00_data_acquisition.R)
# Output: Data/processed/bc_catch_by_section_year_gear.csv
#         (one row per section-year-gear with catch in metric tonnes)
#
# Schema target: year, stock_area, statistical_area, section, gear, catch_tonnes.
# The DFO Open Data raw column names vary release-to-release; this script does
# name harmonization via clean_names() + an explicit rename map.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(janitor)
})

source(here::here("R", "00_setup.R"))

raw_path <- here::here("Data", "raw", "dfo-catch", "bc_commercial_catch_OPEN_DATA.csv")
stopifnot(file.exists(raw_path))

raw <- read_csv(raw_path, show_col_types = FALSE) |> clean_names()

cat("Raw catch columns:", paste(names(raw), collapse = ", "), "\n")

# Map common DFO column names → canonical schema. Update this map after
# inspecting the raw header; the script below assumes the most common DFO
# publication names. If names differ, alter the rename block.
panel <- raw |>
  rename(year = any_of(c("year", "calendar_year", "fishing_year")),
         stock_area = any_of(c("stock_assessment_region", "stock_area", "region")),
         statistical_area = any_of(c("statistical_area", "stat_area", "area")),
         section = any_of(c("section")),
         gear = any_of(c("gear", "gear_type")),
         catch_tonnes = any_of(c("sum_of_catch_metric_tonnes",
                                  "catch_tonnes", "catch", "catch_t"))) |>
  mutate(year = as.integer(year),
         stock_area = as.character(stock_area),
         statistical_area = as.character(statistical_area),
         section = as.character(section),
         gear = as.character(gear),
         catch_tonnes = as.numeric(catch_tonnes)) |>
  filter(!is.na(year), !is.na(stock_area)) |>
  select(year, stock_area, statistical_area, section, gear, catch_tonnes) |>
  arrange(year, stock_area, statistical_area, section, gear)

out_path <- here::here("Data", "processed", "bc_catch_by_section_year_gear.csv")
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_csv(panel, out_path)

cat("Wrote", nrow(panel), "rows to", out_path, "\n")
cat("Stock-area distribution:\n")
print(panel |> count(stock_area))
cat("Gear distribution:\n")
print(panel |> count(gear))
