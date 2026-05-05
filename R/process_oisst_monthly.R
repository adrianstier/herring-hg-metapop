# ============================================================================
# process_oisst_monthly.R — Regenerate monthly OISST files used by clean_sst()
# Region: Haida Gwaii / Hecate Strait, BC, Canada
#   Latitude:  51.5°N to 54.5°N
#   Longitude: 129°W to 133°W
# Period: 2014-2025
# Source: NOAA CoastWatch ERDDAP (ncdcOisst21Agg_LonPM180)
# ============================================================================

# Reader note:
# This is an optional preprocessing utility, not part of `tar_make()`.
# Run it only when refreshing the raw daily NOAA downloads that feed
# `Data/raw/environmental/oisst_haida_gwaii_monthly_regional_avg_2014_2025.csv`.

library(tidyverse)
library(lubridate)
library(here)

data_dir <- here("Data", "raw", "environmental")
out_dir  <- data_dir

# --- 1. Read and combine all daily files ---
years <- 2014:2025
daily_files <- file.path(data_dir,
                         paste0("oisst_haida_gwaii_daily_", years, ".csv"))
available_files <- daily_files[file.exists(daily_files)]

if (length(available_files) == 0) {
  stop(
    "No daily OISST files found under ", data_dir, ". ",
    "Expected files like `oisst_haida_gwaii_daily_2014.csv`.",
    call. = FALSE
  )
}

cat("Reading daily OISST files...\n")
daily <- map_dfr(available_files, function(f) {
  # ERDDAP CSVs have a units row (row 2); skip it

  read_csv(f, skip = 2, col_names = c("time", "zlev", "latitude", "longitude", "sst", "anom"),
           col_types = cols(
             time = col_datetime(),
             zlev = col_double(),
             latitude = col_double(),
             longitude = col_double(),
             sst = col_double(),
             anom = col_double()
           ),
           show_col_types = FALSE)
})

if (nrow(daily) == 0) {
  stop("Daily OISST files were found but produced no rows after import.", call. = FALSE)
}

cat("Total daily observations:", nrow(daily), "\n")
cat("Date range:", as.character(min(daily$time, na.rm = TRUE)), "to",
    as.character(max(daily$time, na.rm = TRUE)), "\n")
cat("Lat range:", min(daily$latitude), "to", max(daily$latitude), "\n")
cat("Lon range:", min(daily$longitude), "to", max(daily$longitude), "\n")

# Remove NaN SST values (land pixels)
daily_ocean <- daily %>% filter(!is.na(sst))
if (nrow(daily_ocean) == 0) {
  stop("All imported OISST rows had missing SST values.", call. = FALSE)
}
cat("Ocean observations (non-NA):", nrow(daily_ocean), "\n")
cat("Unique grid cells:", daily_ocean %>% distinct(latitude, longitude) %>% nrow(), "\n")

# --- 2. Compute monthly spatial average (area-mean SST for the region) ---
monthly_regional <- daily_ocean %>%
  mutate(year  = year(time),
         month = month(time),
         date_ym = floor_date(time, "month")) %>%
  group_by(year, month, date_ym) %>%
  summarise(
    sst_mean     = mean(sst, na.rm = TRUE),
    sst_sd       = sd(sst, na.rm = TRUE),
    sst_min      = min(sst, na.rm = TRUE),
    sst_max      = max(sst, na.rm = TRUE),
    anom_mean    = mean(anom, na.rm = TRUE),
    anom_sd      = sd(anom, na.rm = TRUE),
    n_obs        = n(),
    n_days       = n_distinct(time),
    n_grid_cells = n_distinct(paste(latitude, longitude)),
    .groups = "drop"
  ) %>%
  arrange(date_ym)

cat("\nMonthly regional averages computed:", nrow(monthly_regional), "months\n")

# --- 3. Compute monthly averages per grid cell ---
monthly_gridded <- daily_ocean %>%
  mutate(year  = year(time),
         month = month(time),
         date_ym = floor_date(time, "month")) %>%
  group_by(year, month, date_ym, latitude, longitude) %>%
  summarise(
    sst_mean  = mean(sst, na.rm = TRUE),
    anom_mean = mean(anom, na.rm = TRUE),
    n_days    = n(),
    .groups = "drop"
  ) %>%
  arrange(date_ym, latitude, longitude)

cat("Monthly gridded values computed:", nrow(monthly_gridded), "cell-months\n")

# --- 4. Save outputs ---
write_csv(monthly_regional,
          file.path(out_dir, "oisst_haida_gwaii_monthly_regional_avg_2014_2025.csv"))
cat("Saved: oisst_haida_gwaii_monthly_regional_avg_2014_2025.csv\n")

write_csv(monthly_gridded,
          file.path(out_dir, "oisst_haida_gwaii_monthly_gridded_2014_2025.csv"))
cat("Saved: oisst_haida_gwaii_monthly_gridded_2014_2025.csv\n")

# --- 5. Quick summary statistics ---
cat("\n=== REGIONAL MONTHLY SST SUMMARY ===\n")
cat("Overall mean SST:", round(mean(monthly_regional$sst_mean), 2), "°C\n")
cat("Overall mean anomaly:", round(mean(monthly_regional$anom_mean), 2), "°C\n")

# Identify warmest months (the blob)
warmest <- monthly_regional %>%
  arrange(desc(anom_mean)) %>%
  head(10)
cat("\nTop 10 warmest anomaly months:\n")
print(warmest %>% select(year, month, sst_mean, anom_mean))

# Annual means
annual <- monthly_regional %>%
  group_by(year) %>%
  summarise(
    sst_annual = mean(sst_mean),
    anom_annual = mean(anom_mean),
    .groups = "drop"
  )
cat("\nAnnual mean SST and anomalies:\n")
print(annual, n = 20)

cat("\nDone!\n")
