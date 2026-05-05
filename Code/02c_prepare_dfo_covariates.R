## ============================================================================
##  02c_prepare_dfo_covariates.R
##  Build additional DFO-derived covariate tables for the Haida Gwaii herring
##  metapopulation analysis.
##
##  Outputs:
##    1. Data/processed/dfo_spawn_covariates_section_1951_2025.csv
##       Section-year covariates from the full DFO location-level spawn file.
##    2. Data/processed/dfo_spawn_covariates_region_1951_2025.csv
##       Region-year covariates aggregated across the 11 modeled sections.
##    3. Data/processed/dfo_data_stream_inventory.csv
##       Inventory of DFO data streams that are ready now vs. still missing.
##
##  Notes:
##    - This script does not trust HG_spawn_index_by_section_1951_2025.csv
##      because its section crosswalk is incomplete / mis-mapped.
##    - It rebuilds covariates directly from the full location-level DFO file.
## ============================================================================

library(tidyverse)

proj_dir <- here::here()
raw_dir  <- file.path(proj_dir, "Data", "raw", "dfo-spawn")
proc_dir <- file.path(proj_dir, "Data", "processed")
dir.create(proc_dir, showWarnings = FALSE, recursive = TRUE)

section_lookup <- tribble(
  ~section, ~section_name,
  1,  "Tasu Sound & Gowgaia Bay",
  2,  "Port Louis",
  3,  "Rennell Sound",
  4,  "Cartwright Sound",
  5,  "Englefield Bay",
  6,  "Louscoone Inlet",
  11, "Masset Inlet",
  12, "Naden Harbour",
  21, "Juan Perez Sound",
  22, "Skidegate Inlet",
  23, "Cumshewa Inlet",
  24, "Laskeek Bay",
  25, "Skincuttle Inlet"
)

model_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)

safe_mean <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  mean(x, na.rm = TRUE)
}

safe_sd <- function(x) {
  if (sum(!is.na(x)) < 2) {
    return(NA_real_)
  }
  stats::sd(x, na.rm = TRUE)
}

safe_min <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  min(x, na.rm = TRUE)
}

safe_max <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  max(x, na.rm = TRUE)
}

weighted_mean_safe <- function(x, w) {
  keep <- is.finite(x) & is.finite(w) & w > 0
  if (!any(keep)) {
    return(NA_real_)
  }
  sum(x[keep] * w[keep]) / sum(w[keep])
}

shannon_from_totals <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x) & x > 0]
  if (length(x) == 0 || sum(x) <= 0) {
    return(NA_real_)
  }
  p <- x / sum(x)
  -sum(p * log(p))
}

dfo_raw <- read_csv(
  file.path(raw_dir, "Pacific_herring_spawn_index_data_2025_EN.csv"),
  show_col_types = FALSE
)

years <- seq(min(dfo_raw$Year, na.rm = TRUE), max(dfo_raw$Year, na.rm = TRUE))

dfo_hg <- dfo_raw %>%
  mutate(
    section = suppressWarnings(as.integer(Section)),
    Surface = replace_na(as.numeric(Surface), 0),
    Macrocystis = replace_na(as.numeric(Macrocystis), 0),
    Understory = replace_na(as.numeric(Understory), 0),
    record_spawn_t = Surface + Macrocystis + Understory,
    method = case_when(
      Method %in% c("Dive", "Surface", "Incomplete") ~ Method,
      TRUE ~ "Unknown"
    ),
    start_date = suppressWarnings(as.Date(StartDate)),
    end_date = suppressWarnings(as.Date(EndDate)),
    start_doy = suppressWarnings(as.numeric(format(start_date, "%j"))),
    duration_days = if_else(
      !is.na(start_date) & !is.na(end_date),
      as.numeric(end_date - start_date) + 1,
      NA_real_
    )
  ) %>%
  filter(section %in% section_lookup$section)

section_covariates <- dfo_hg %>%
  group_by(year = Year, section) %>%
  summarise(
    total_records = n(),
    spawn_index_tonnes = sum(record_spawn_t, na.rm = TRUE),
    surface_t = sum(Surface, na.rm = TRUE),
    macrocystis_t = sum(Macrocystis, na.rm = TRUE),
    understory_t = sum(Understory, na.rm = TRUE),
    spawn_start_doy_mean = safe_mean(start_doy),
    spawn_start_doy_weighted = weighted_mean_safe(start_doy, record_spawn_t),
    spawn_start_doy_sd = safe_sd(start_doy),
    spawn_start_doy_min = safe_min(start_doy),
    spawn_start_doy_max = safe_max(start_doy),
    spawn_duration_days_mean = safe_mean(duration_days),
    spawn_duration_days_weighted = weighted_mean_safe(duration_days, record_spawn_t),
    dive_record_pct = 100 * mean(method == "Dive", na.rm = TRUE),
    surface_record_pct = 100 * mean(method == "Surface", na.rm = TRUE),
    incomplete_record_pct = 100 * mean(method == "Incomplete", na.rm = TRUE),
    latitude = safe_mean(as.numeric(Latitude)),
    longitude = safe_mean(as.numeric(Longitude)),
    .groups = "drop"
  )

section_complete <- expand_grid(
  year = years,
  section = section_lookup$section
) %>%
  left_join(section_lookup, by = "section") %>%
  left_join(section_covariates, by = c("year", "section")) %>%
  mutate(
    in_model = section %in% model_sections,
    total_records = replace_na(total_records, 0L),
    spawn_index_tonnes = replace_na(spawn_index_tonnes, 0),
    surface_t = replace_na(surface_t, 0),
    macrocystis_t = replace_na(macrocystis_t, 0),
    understory_t = replace_na(understory_t, 0),
    subtidal_t = macrocystis_t + understory_t,
    surveyed = total_records > 0,
    positive_spawn = spawn_index_tonnes > 0,
    surveyed_zero = surveyed & !positive_spawn,
    surface_share = if_else(positive_spawn, surface_t / spawn_index_tonnes, NA_real_),
    macrocystis_share = if_else(positive_spawn, macrocystis_t / spawn_index_tonnes, NA_real_),
    understory_share = if_else(positive_spawn, understory_t / spawn_index_tonnes, NA_real_),
    subtidal_share = if_else(positive_spawn, subtidal_t / spawn_index_tonnes, NA_real_),
    substrate_richness = if_else(
      positive_spawn,
      as.integer((surface_t > 0) + (macrocystis_t > 0) + (understory_t > 0)),
      NA_integer_
    )
  ) %>%
  mutate(
    substrate_shannon = pmap_dbl(
      list(surface_t, macrocystis_t, understory_t),
      ~ shannon_from_totals(c(..1, ..2, ..3))
    ),
    substrate_effective_n = if_else(
      is.na(substrate_shannon),
      NA_real_,
      exp(substrate_shannon)
    )
  ) %>%
  select(
    year, section, section_name, in_model,
    surveyed, positive_spawn, surveyed_zero,
    total_records, spawn_index_tonnes,
    surface_t, macrocystis_t, understory_t, subtidal_t,
    surface_share, macrocystis_share, understory_share, subtidal_share,
    substrate_richness, substrate_shannon, substrate_effective_n,
    spawn_start_doy_mean, spawn_start_doy_weighted,
    spawn_start_doy_sd, spawn_start_doy_min, spawn_start_doy_max,
    spawn_duration_days_mean, spawn_duration_days_weighted,
    dive_record_pct, surface_record_pct, incomplete_record_pct,
    latitude, longitude
  ) %>%
  arrange(section, year)

region_covariates <- section_complete %>%
  filter(in_model) %>%
  group_by(year) %>%
  summarise(
    n_sections = n(),
    surveyed_sections = sum(surveyed),
    occupied_sections = sum(positive_spawn),
    surveyed_zero_sections = sum(surveyed_zero),
    total_spawn_index_tonnes = sum(spawn_index_tonnes, na.rm = TRUE),
    surface_t = sum(surface_t, na.rm = TRUE),
    macrocystis_t = sum(macrocystis_t, na.rm = TRUE),
    understory_t = sum(understory_t, na.rm = TRUE),
    subtidal_t = sum(subtidal_t, na.rm = TRUE),
    surface_share = if_else(total_spawn_index_tonnes > 0, surface_t / total_spawn_index_tonnes, NA_real_),
    macrocystis_share = if_else(total_spawn_index_tonnes > 0, macrocystis_t / total_spawn_index_tonnes, NA_real_),
    understory_share = if_else(total_spawn_index_tonnes > 0, understory_t / total_spawn_index_tonnes, NA_real_),
    subtidal_share = if_else(total_spawn_index_tonnes > 0, subtidal_t / total_spawn_index_tonnes, NA_real_),
    weighted_spawn_start_doy = weighted_mean_safe(spawn_start_doy_weighted, spawn_index_tonnes),
    mean_spawn_start_doy = safe_mean(spawn_start_doy_mean),
    sd_spawn_start_doy = safe_sd(spawn_start_doy_mean),
    timing_window_days = safe_max(spawn_start_doy_max) - safe_min(spawn_start_doy_min),
    mean_spawn_duration_days = weighted_mean_safe(spawn_duration_days_weighted, spawn_index_tonnes),
    dive_record_pct = weighted_mean_safe(dive_record_pct, total_records),
    surface_record_pct = weighted_mean_safe(surface_record_pct, total_records),
    incomplete_record_pct = weighted_mean_safe(incomplete_record_pct, total_records),
    substrate_shannon = shannon_from_totals(c(surface_t, macrocystis_t, understory_t)),
    .groups = "drop"
  ) %>%
  mutate(
    substrate_effective_n = if_else(
      is.na(substrate_shannon),
      NA_real_,
      exp(substrate_shannon)
    )
  ) %>%
  arrange(year)

inventory <- tribble(
  ~data_stream, ~available_locally, ~ready_now, ~best_use, ~note,
  "spawn_timing", TRUE, TRUE, "process covariate", "Built from location-level StartDate records.",
  "substrate_specific_spawn", TRUE, TRUE, "process covariate or observation-model refinement", "Surface, Macrocystis, and Understory tonnes are in the raw DFO spawn file.",
  "regional_predator_index", TRUE, TRUE, "regional process covariate", "Already prepared in Data/processed/predator_indices.csv.",
  "age_composition", FALSE, FALSE, "regional covariate or prior", "Local workspace only has references and partial summaries, not usable raw age-composition tables.",
  "weight_at_age", FALSE, FALSE, "regional covariate or prior", "DFO materials document it, but raw year-by-age series are not packaged locally.",
  "test_fishery_biology", FALSE, FALSE, "regional covariate or age-structured extension", "Input-data manifests indicate availability, but the underlying raw series are not present locally.",
  "section_level_age_structure", FALSE, FALSE, "not currently supported", "Would require much denser local age data than are available in this workspace."
)

write_csv(
  section_complete,
  file.path(proc_dir, "dfo_spawn_covariates_section_1951_2025.csv")
)
write_csv(
  region_covariates,
  file.path(proc_dir, "dfo_spawn_covariates_region_1951_2025.csv")
)
write_csv(
  inventory,
  file.path(proc_dir, "dfo_data_stream_inventory.csv")
)

cat("\nSaved:\n")
cat("  -", file.path(proc_dir, "dfo_spawn_covariates_section_1951_2025.csv"), "\n")
cat("  -", file.path(proc_dir, "dfo_spawn_covariates_region_1951_2025.csv"), "\n")
cat("  -", file.path(proc_dir, "dfo_data_stream_inventory.csv"), "\n")

cat("\nSection-level covariates:\n")
cat("  Rows:", nrow(section_complete), "\n")
cat("  Surveyed zeros recovered:", sum(section_complete$surveyed_zero), "\n")
cat("  Modeled sections:", paste(model_sections, collapse = ", "), "\n")

cat("\nRegional covariates sample:\n")
print(
  region_covariates %>%
    select(
      year, occupied_sections, total_spawn_index_tonnes,
      weighted_spawn_start_doy, macrocystis_share, subtidal_share
    ) %>%
    tail(5)
)
