## ==========================================================================
##  01c_chla_processing.R
##  Process satellite chlorophyll-a data for Haida Gwaii / Hecate Strait
##  region as a productivity covariate for herring population modeling.
##
##  Data sources:
##    1. MODIS Aqua L3SMI Science Quality monthly composite (2003-2022)
##       ERDDAP dataset: erdMH1chlamday
##    2. VIIRS S-NPP Science Quality monthly composite (2012-2026)
##       ERDDAP dataset: noaacwNPPVIIRSSQchlaMonthly
##
##  Region: 51.5-54.5°N, 129-133°W (Haida Gwaii / Hecate Strait)
##
##  Output: monthly and annual regional mean Chl-a, plus a blended
##  MODIS+VIIRS time series calibrated on the overlap period (2012-2022).
## ==========================================================================

library(tidyverse)

## ---- Paths ----
proj_dir <- here::here()
raw_dir  <- file.path(proj_dir, "Data", "raw", "environmental")
out_dir  <- file.path(proj_dir, "Data", "processed")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

## =========================================================================
##  1. Read and process MODIS Chl-a (2003-2022)
## =========================================================================

cat("Reading MODIS Chl-a data...\n")
modis_raw <- read_csv(
  file.path(raw_dir, "modis_chla_monthly_haida_gwaii_2003_2022.csv"),
  skip = 2,  # skip header + units rows
  col_names = c("time", "latitude", "longitude", "chlorophyll"),
  col_types = cols(
    time = col_character(),
    latitude = col_double(),
    longitude = col_double(),
    chlorophyll = col_double()
  )
) %>%
  mutate(time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))

# Compute monthly spatial means (averaging over all grid cells)
modis_monthly <- modis_raw %>%
  mutate(
    date  = as.Date(time),
    year  = year(date),
    month = month(date)
  ) %>%
  group_by(year, month, date) %>%
  summarise(
    chla_mean   = mean(chlorophyll, na.rm = TRUE),
    chla_median = median(chlorophyll, na.rm = TRUE),
    chla_sd     = sd(chlorophyll, na.rm = TRUE),
    n_cells     = sum(!is.na(chlorophyll)),
    n_total     = n(),
    pct_valid   = round(100 * n_cells / n_total, 1),
    .groups     = "drop"
  ) %>%
  mutate(sensor = "MODIS")

cat("  MODIS: ", nrow(modis_monthly), " months,",
    range(modis_monthly$year)[1], "-", range(modis_monthly$year)[2], "\n")

## =========================================================================
##  2. Read and process VIIRS Chl-a (2012-2026)
## =========================================================================

cat("Reading VIIRS Chl-a data...\n")
viirs_raw <- read_csv(
  file.path(raw_dir, "viirs_chla_monthly_haida_gwaii_2012_2026.csv"),
  skip = 2,  # skip header + units rows
  col_names = c("time", "altitude", "latitude", "longitude", "chlor_a"),
  col_types = cols(
    time = col_character(),
    altitude = col_double(),
    latitude = col_double(),
    longitude = col_double(),
    chlor_a = col_double()
  )
) %>%
  mutate(time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))

viirs_monthly <- viirs_raw %>%
  mutate(
    date  = as.Date(time),
    year  = year(date),
    month = month(date)
  ) %>%
  group_by(year, month, date) %>%
  summarise(
    chla_mean   = mean(chlor_a, na.rm = TRUE),
    chla_median = median(chlor_a, na.rm = TRUE),
    chla_sd     = sd(chlor_a, na.rm = TRUE),
    n_cells     = sum(!is.na(chlor_a)),
    n_total     = n(),
    pct_valid   = round(100 * n_cells / n_total, 1),
    .groups     = "drop"
  ) %>%
  mutate(sensor = "VIIRS")

cat("  VIIRS: ", nrow(viirs_monthly), " months,",
    range(viirs_monthly$year)[1], "-", range(viirs_monthly$year)[2], "\n")

## =========================================================================
##  3. Create blended time series
##  Strategy: use MODIS for 2003-2011, blend for 2012-2022, VIIRS for 2023+
##  During overlap, compute a linear calibration and use VIIRS adjusted values
## =========================================================================

cat("\nBlending MODIS + VIIRS on overlap period (2012-2022)...\n")

# Merge on year-month for overlap period
overlap <- inner_join(
  modis_monthly %>%
    filter(year >= 2012) %>%
    select(year, month, chla_modis = chla_mean),
  viirs_monthly %>%
    filter(year <= 2022) %>%
    select(year, month, chla_viirs = chla_mean),
  by = c("year", "month")
) %>%
  filter(!is.nan(chla_modis) & !is.nan(chla_viirs))

# Linear calibration: VIIRS ~ MODIS
if (nrow(overlap) > 10) {
  cal_model <- lm(chla_modis ~ chla_viirs, data = overlap)
  cat("  Calibration: MODIS = ",
      round(coef(cal_model)[1], 4), " + ",
      round(coef(cal_model)[2], 4), " * VIIRS\n")
  cat("  R-squared: ", round(summary(cal_model)$r.squared, 3), "\n")
  cat("  N overlap months: ", nrow(overlap), "\n")
} else {
  cat("  WARNING: too few overlap months for calibration\n")
  cal_model <- NULL
}

# Build blended time series
# MODIS-only: 2003-2011
# Average of both: 2012-2022
# VIIRS-adjusted: 2023+
blended <- bind_rows(
  # MODIS-only period
  modis_monthly %>%
    filter(year < 2012) %>%
    select(year, month, date, chla_mean, chla_median, chla_sd,
           n_cells, pct_valid, sensor),

  # Overlap period: average the two sensors
  inner_join(
    modis_monthly %>%
      filter(year >= 2012, year <= 2022) %>%
      select(year, month, date,
             chla_modis = chla_mean, sd_modis = chla_sd,
             n_modis = n_cells, pct_modis = pct_valid),
    viirs_monthly %>%
      filter(year >= 2012, year <= 2022) %>%
      select(year, month,
             chla_viirs = chla_mean, sd_viirs = chla_sd,
             n_viirs = n_cells, pct_viirs = pct_valid),
    by = c("year", "month")
  ) %>%
    mutate(
      chla_mean  = (chla_modis + chla_viirs) / 2,
      chla_sd    = sqrt((sd_modis^2 + sd_viirs^2) / 2),
      n_cells    = n_modis + n_viirs,
      pct_valid  = (pct_modis + pct_viirs) / 2,
      chla_median = NA_real_,
      sensor     = "MODIS+VIIRS"
    ) %>%
    select(year, month, date, chla_mean, chla_median, chla_sd,
           n_cells, pct_valid, sensor),

  # VIIRS-only period (2023+), calibrated to MODIS scale if model exists
  viirs_monthly %>%
    filter(year > 2022) %>%
    mutate(
      chla_mean = if (!is.null(cal_model)) {
        predict(cal_model, newdata = data.frame(chla_viirs = chla_mean))
      } else {
        chla_mean
      }
    ) %>%
    mutate(sensor = "VIIRS (calibrated)") %>%
    select(year, month, date, chla_mean, chla_median, chla_sd,
           n_cells, pct_valid, sensor)
) %>%
  arrange(year, month)

## =========================================================================
##  4. Compute annual summaries (for herring modeling)
## =========================================================================

# Annual mean (calendar year)
chla_annual <- blended %>%
  group_by(year) %>%
  summarise(
    chla_annual_mean   = mean(chla_mean, na.rm = TRUE),
    chla_annual_sd     = sd(chla_mean, na.rm = TRUE),
    n_months           = sum(!is.nan(chla_mean)),
    .groups            = "drop"
  )

# Spring bloom (Mar-Jun) — most relevant for herring productivity
chla_spring <- blended %>%
  filter(month >= 3, month <= 6) %>%
  group_by(year) %>%
  summarise(
    chla_spring_mean = mean(chla_mean, na.rm = TRUE),
    chla_spring_sd   = sd(chla_mean, na.rm = TRUE),
    n_spring_months  = sum(!is.nan(chla_mean)),
    .groups          = "drop"
  )

# Growing season (Apr-Sep)
chla_growing <- blended %>%
  filter(month >= 4, month <= 9) %>%
  group_by(year) %>%
  summarise(
    chla_growing_mean = mean(chla_mean, na.rm = TRUE),
    chla_growing_sd   = sd(chla_mean, na.rm = TRUE),
    n_growing_months  = sum(!is.nan(chla_mean)),
    .groups           = "drop"
  )

# Join all annual summaries
chla_annual_full <- chla_annual %>%
  left_join(chla_spring, by = "year") %>%
  left_join(chla_growing, by = "year")

## =========================================================================
##  5. Save outputs
## =========================================================================

# Monthly time series (blended)
write_csv(blended, file.path(out_dir, "chla_haida_gwaii_monthly_blended.csv"))
cat("\nSaved monthly blended Chl-a:", nrow(blended), "months\n")

# Annual summaries
write_csv(chla_annual_full, file.path(out_dir, "chla_haida_gwaii_annual.csv"))
cat("Saved annual Chl-a:", nrow(chla_annual_full), "years\n")

# Individual sensor monthly series (for reference/diagnostics)
write_csv(modis_monthly, file.path(out_dir, "chla_modis_monthly.csv"))
write_csv(viirs_monthly, file.path(out_dir, "chla_viirs_monthly.csv"))

## =========================================================================
##  6. Quick diagnostic summary
## =========================================================================

cat("\n=== Chlorophyll-a Summary ===\n")
cat("Region: Haida Gwaii / Hecate Strait (51.5-54.5°N, 129-133°W)\n")
cat("Full time series: ", min(blended$year), "-", max(blended$year), "\n")
cat("Total months: ", nrow(blended), "\n\n")

cat("Marine heatwave period (2014-2016):\n")
blended %>%
  filter(year %in% 2014:2016) %>%
  summarise(
    mean_chla = round(mean(chla_mean, na.rm = TRUE), 3),
    sd_chla   = round(sd(chla_mean, na.rm = TRUE), 3)
  ) %>%
  print()

cat("\nBaseline period (2003-2013):\n")
blended %>%
  filter(year %in% 2003:2013) %>%
  summarise(
    mean_chla = round(mean(chla_mean, na.rm = TRUE), 3),
    sd_chla   = round(sd(chla_mean, na.rm = TRUE), 3)
  ) %>%
  print()

cat("\nPost-heatwave (2017-2025):\n")
blended %>%
  filter(year >= 2017) %>%
  summarise(
    mean_chla = round(mean(chla_mean, na.rm = TRUE), 3),
    sd_chla   = round(sd(chla_mean, na.rm = TRUE), 3)
  ) %>%
  print()
