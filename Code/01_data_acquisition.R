## ==========================================================================
##  01_data_acquisition.R
##  Extract and aggregate all Haida Gwaii herring sub-stock data from the
##  full DFO Pacific Herring Spawn Index dataset (2025 release).
##
##  Section mapping (legacy 2-digit → DFO 3-digit, zero-padded):
##    Legacy   DFO     Name                         DFO Region
##    1        001     Tasu Sound & Gowgaia Bay     A2W
##    2        002     Port Louis                   A2W
##    3        003     Rennell Sound                A2W
##    4        004     Cartwright Sound             A2W
##    5        005     Englefield Bay               A2W
##    6        006     Louscoone Inlet              HG
##    11       011     Masset Inlet                 NA
##    12       012     Naden Harbour                NA
##    21       021     Juan Perez Sound             HG
##    22       022     Skidegate Inlet              NA
##    23       023     Cumshewa Inlet               HG
##    24       024     Laskeek Bay                  HG
##    25       025     Skincuttle Inlet             HG
## ==========================================================================

library(tidyverse)

## ---- Paths ----
proj_dir <- here::here()
raw_dir  <- file.path(proj_dir, "Data", "raw")
out_dir  <- file.path(proj_dir, "Data", "processed")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Section lookup ----
section_lookup <- tribble(
  ~dfo_section, ~legacy_section, ~section_name,
  "001",  1,  "Tasu Sound & Gowgaia Bay",
  "002",  2,  "Port Louis",
  "003",  3,  "Rennell Sound",
  "004",  4,  "Cartwright Sound",
  "005",  5,  "Englefield Bay",
  "006",  6,  "Louscoone Inlet",
  "011", 11,  "Masset Inlet",
  "012", 12,  "Naden Harbour",
  "021", 21,  "Juan Perez Sound",
  "022", 22,  "Skidegate Inlet",
  "023", 23,  "Cumshewa Inlet",
  "024", 24,  "Laskeek Bay",
  "025", 25,  "Skincuttle Inlet"
)

## =========================================================================
##  1. DFO SPAWN INDEX — full location-level data → section-year aggregates
## =========================================================================

dfo_raw <- read_csv(
  file.path(raw_dir, "dfo-spawn", "Pacific_herring_spawn_index_data_2025_EN.csv"),
  show_col_types = FALSE
)

# Filter to Haida Gwaii sections (across A2W, HG, and NA regions)
hg_sections <- sprintf("%03d", c(1:6, 11, 12, 21:25))

dfo_hg <- dfo_raw %>%
  filter(Section %in% hg_sections) %>%
  mutate(Section = as.character(Section))

# Aggregate spawn index by section and year
# Surface, Macrocystis, Understory are tonnes of spawn at each location
# SHI (Spawn Habitat Index) = Surface + Macrocystis + Understory
spawn_by_section <- dfo_hg %>%
  mutate(
    Surface     = replace_na(Surface, 0),
    Macrocystis = replace_na(Macrocystis, 0),
    Understory  = replace_na(Understory, 0),
    SHI = Surface + Macrocystis + Understory
  ) %>%
  group_by(Year, Section) %>%
  summarise(
    totalrecords      = n(),
    SHI               = sum(SHI, na.rm = TRUE),
    total_length      = sum(Length, na.rm = TRUE),
    mean_width        = mean(Width, na.rm = TRUE),
    spawn_date_xbar   = mean(as.numeric(format(as.Date(StartDate), "%j")), na.rm = TRUE),
    spawn_date_sd     = sd(as.numeric(format(as.Date(StartDate), "%j")), na.rm = TRUE),
    spawn_date_min    = min(as.numeric(format(as.Date(StartDate), "%j")), na.rm = TRUE),
    spawn_date_max    = max(as.numeric(format(as.Date(StartDate), "%j")), na.rm = TRUE),
    dive_survey_pct   = 100 * mean(Method == "Dive", na.rm = TRUE),
    latitude          = mean(Latitude, na.rm = TRUE),
    longitude         = mean(Longitude, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Replace Inf/-Inf from empty groups

mutate(across(where(is.numeric), ~ifelse(is.infinite(.), NA_real_, .)))

# Join section names
spawn_by_section <- spawn_by_section %>%
  left_join(section_lookup, by = c("Section" = "dfo_section")) %>%
  rename(
    year         = Year,
    section      = legacy_section
  ) %>%
  select(year, totalrecords, SHI, total_length, mean_width,
         spawn_date_xbar, spawn_date_sd, spawn_date_min, spawn_date_max,
         dive_survey_pct, section, section_name, latitude, longitude)

# Ensure all section-year combinations exist (fill missing with zeros)
all_years    <- min(spawn_by_section$year):max(spawn_by_section$year)
all_sections <- section_lookup %>% select(legacy_section, section_name)

complete_grid <- expand_grid(
  year = all_years,
  legacy_section = all_sections$legacy_section
) %>%
  left_join(all_sections, by = "legacy_section") %>%
  rename(section = legacy_section)

spawn_complete <- complete_grid %>%
  left_join(
    spawn_by_section,
    by = c("year", "section", "section_name")
  ) %>%
  mutate(
    totalrecords = replace_na(totalrecords, 0),
    SHI          = replace_na(SHI, 0)
  )

# Write the complete section-level spawn data
write_csv(spawn_complete,
  file.path(out_dir, "HG_Spawn_Survey_1951_2025_all_sections.csv")
)

cat("Spawn data: ", nrow(spawn_complete), "rows,",
    length(unique(spawn_complete$section)), "sections,",
    range(spawn_complete$year), "year range\n")

## =========================================================================
##  2. PDO — merge legacy + new
## =========================================================================

pdo_legacy <- read_csv(
  file.path(raw_dir, "legacy-2019", "pdo.csv"),
  show_col_types = FALSE
)
pdo_new <- read_csv(
  file.path(raw_dir, "environmental", "pdo_2015_2025.csv"),
  show_col_types = FALSE
)

# Legacy goes through Sep 2015; new starts Oct 2015
pdo_combined <- bind_rows(
  pdo_legacy %>% filter(!(year == 2015 & month >= 10)),
  pdo_new
) %>%
  arrange(year, month) %>%
  distinct(year, month, .keep_all = TRUE)

write_csv(pdo_combined,
  file.path(out_dir, "pdo_combined_1854_2025.csv")
)

cat("PDO data:", nrow(pdo_combined), "months, through",
    max(pdo_combined$year), "\n")

## =========================================================================
##  3. CATCH — merge legacy + new (mostly zeros post-2005)
## =========================================================================

catch_legacy <- read_csv(
  file.path(raw_dir, "legacy-2019", "herring_catch_local2015.csv"),
  show_col_types = FALSE
)
catch_new <- read_csv(
  file.path(raw_dir, "dfo-catch", "herring_catch_local2024.csv"),
  show_col_types = FALSE
)

# Replace NA with 0 in catch columns for the closure period
catch_new <- catch_new %>%
  mutate(across(c(Num_Record, TotalCatch, CatchJan_Apr, CatchMay_Aug,
                  CatchSep_Dec, Gillnet, Seine, Trawl, SOK),
                ~replace_na(., 0)))

catch_combined <- bind_rows(catch_legacy, catch_new) %>%
  arrange(Year, Section)

write_csv(catch_combined,
  file.path(out_dir, "herring_catch_local_1950_2024.csv")
)

cat("Catch data:", nrow(catch_combined), "rows, through",
    max(catch_combined$Year), "\n")

## =========================================================================
##  4. SST — combine monthly OISST files
## =========================================================================

sst_files <- list.files(
  file.path(raw_dir, "environmental"),
  pattern = "oisst.*monthly.*\\.csv$",
  full.names = TRUE
)

if (length(sst_files) > 0) {
  sst_all <- map_dfr(sst_files, ~{
    read_csv(.x, show_col_types = FALSE, skip = 1) %>%
      # Handle different column name formats
      rename_with(tolower)
  })

  # If gridded, compute regional monthly average
  if ("latitude" %in% names(sst_all) && "longitude" %in% names(sst_all)) {
    sst_monthly <- sst_all %>%
      mutate(
        date = as.Date(time),
        year = year(date),
        month = month(date)
      ) %>%
      group_by(year, month) %>%
      summarise(
        sst_mean = mean(sst, na.rm = TRUE),
        sst_anom_mean = mean(anom, na.rm = TRUE),
        n_cells = n(),
        .groups = "drop"
      )

    write_csv(sst_monthly,
      file.path(out_dir, "sst_haida_gwaii_monthly.csv")
    )
    cat("SST data:", nrow(sst_monthly), "months\n")
  }
}

## =========================================================================
##  5. Summary
## =========================================================================

cat("\n=== Data Acquisition Complete ===\n")
cat("Output files in:", out_dir, "\n")
list.files(out_dir, pattern = "\\.csv$") %>% cat(sep = "\n")
