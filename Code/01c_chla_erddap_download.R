## ==========================================================================
##  01c_chla_erddap_download.R
##  Programmatic download of satellite chlorophyll-a from ERDDAP servers
##  for the Haida Gwaii / Hecate Strait region using the rerddap package.
##
##  This script downloads the raw gridded data. Run 01c_chla_processing.R
##  afterwards to compute regional means and blended time series.
##
##  Datasets:
##    1. erdMH1chlamday — MODIS Aqua Science Quality, 4km, 2003-2022
##    2. noaacwNPPVIIRSSQchlaMonthly — VIIRS S-NPP Science Quality, 4km, 2012-2026
##    3. erdMBchlamday_LonPM180 — MODIS experimental Pacific, 0.025°, 2006-present
##
##  Install if needed:
##    install.packages("rerddap")
##    install.packages("ncdf4")
## ==========================================================================

library(tidyverse)
library(rerddap)

## ---- Configuration ----
proj_dir <- here::here()
raw_dir  <- file.path(proj_dir, "Data", "raw", "environmental")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

# Region of interest: Haida Gwaii / Hecate Strait
lat_range <- c(51.5, 54.5)
lon_range <- c(-133.0, -129.0)

# ERDDAP server URLs
pfeg_url  <- "https://coastwatch.pfeg.noaa.gov/erddap/"
noaa_url  <- "https://coastwatch.noaa.gov/erddap/"

## =========================================================================
##  1. MODIS Aqua — Science Quality Monthly (2003-2022)
##     Dataset: erdMH1chlamday
##     Server: coastwatch.pfeg.noaa.gov
##     Resolution: ~4km (0.0417°)
##     This is the gold-standard MODIS L3 product from NASA OBPG.
## =========================================================================

cat("=== Downloading MODIS Aqua Chl-a (erdMH1chlamday) ===\n")

# Get dataset info
modis_info <- info("erdMH1chlamday", url = pfeg_url)
print(modis_info)

# Download gridded data — this returns a NetCDF file cached locally
# Stride of 3 in lat/lon (~12km) keeps file size manageable
modis_data <- griddap(
  modis_info,
  time   = c("2003-01-16", "2022-05-16"),
  latitude  = lat_range,
  longitude = lon_range,
  stride = c(1, 3, 3),     # time stride=1 (all months), spatial stride=3
  fields = "chlorophyll",
  fmt    = "csv"
)

# Convert to tibble and save
modis_df <- as_tibble(modis_data$data) %>%
  mutate(time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ"))

write_csv(
  modis_df,
  file.path(raw_dir, "modis_chla_monthly_haida_gwaii_2003_2022.csv")
)
cat("  Saved:", nrow(modis_df), "rows\n\n")

## =========================================================================
##  2. VIIRS S-NPP — Science Quality Monthly (2012-present)
##     Dataset: noaacwNPPVIIRSSQchlaMonthly
##     Server: coastwatch.noaa.gov
##     Resolution: ~4km (0.0375°)
##     Note: this dataset has an altitude dimension (fixed at 0.0m)
## =========================================================================

cat("=== Downloading VIIRS S-NPP Chl-a (noaacwNPPVIIRSSQchlaMonthly) ===\n")

viirs_info <- info("noaacwNPPVIIRSSQchlaMonthly", url = noaa_url)
print(viirs_info)

viirs_data <- griddap(
  viirs_info,
  time      = c("2012-01-02", "2026-02-01"),
  altitude  = c(0, 0),
  latitude  = lat_range,
  longitude = lon_range,
  stride    = c(1, 1, 3, 3),  # time, altitude, lat stride, lon stride

  fields    = "chlor_a",
  fmt       = "csv"
)

viirs_df <- as_tibble(viirs_data$data) %>%
  mutate(time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ"))

write_csv(
  viirs_df,
  file.path(raw_dir, "viirs_chla_monthly_haida_gwaii_2012_2026.csv")
)
cat("  Saved:", nrow(viirs_df), "rows\n\n")

## =========================================================================
##  3. Direct URL download (alternative if rerddap not available)
##     These are the raw ERDDAP query URLs that can be used with curl/wget.
## =========================================================================

cat("=== Direct ERDDAP URLs (for reference or manual download) ===\n\n")

# MODIS Science Quality (erdMH1chlamday) — 2003 to 2022
modis_url <- paste0(
  "https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdMH1chlamday.csv?",
  "chlorophyll",
  "[(2003-01-16T00:00:00Z):1:(2022-05-16T00:00:00Z)]",
  "[(51.5):3:(54.5)]",
  "[(-133.0):3:(-129.0)]"
)
cat("MODIS (2003-2022):\n", modis_url, "\n\n")

# VIIRS Science Quality (noaacwNPPVIIRSSQchlaMonthly) — 2012 to present
viirs_url <- paste0(
  "https://coastwatch.noaa.gov/erddap/griddap/noaacwNPPVIIRSSQchlaMonthly.csv?",
  "chlor_a",
  "[(2012-01-02T12:00:00Z):1:(2026-02-01T12:00:00Z)]",
  "[(0.0)]",
  "[(51.5):3:(54.5)]",
  "[(-133.0):3:(-129.0)]"
)
cat("VIIRS (2012-2026):\n", viirs_url, "\n\n")

# MODIS Pacific experimental (erdMBchlamday_LonPM180) — 2006 to present
# Higher resolution (0.025°) but labeled EXPERIMENTAL
pacific_url <- paste0(
  "https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdMBchlamday_LonPM180.csv?",
  "chlorophyll",
  "[(2006-01-16T12:00:00Z):1:(2026-02-14T12:00:00Z)]",
  "[(0.0)]",
  "[(51.5):8:(54.5)]",
  "[(-133.0):8:(-129.0)]"
)
cat("MODIS Pacific experimental (2006-present):\n", pacific_url, "\n\n")

## =========================================================================
##  4. Oregon State VGPM Net Primary Production (alternative)
##     Not on ERDDAP — requires direct HDF download and extraction.
##     Monthly files at: https://orca.science.oregonstate.edu/
##     Use the satin R package: read.osunpp() for HDF files.
## =========================================================================

cat("=== Oregon State VGPM NPP ===\n")
cat("For net primary production (NPP) instead of chlorophyll-a:\n")
cat("  Monthly HDF files: https://orca.science.oregonstate.edu/1080.by.2160.monthly.hdf.vgpm.m.chl.m.sst.php\n")
cat("  R package 'satin' has read.osunpp() for these files.\n")
cat("  Resolution: 1/6° (~18km), Global, 2002-present\n")
cat("  install.packages('satin'); library(satin)\n\n")

## =========================================================================
##  5. Summary of all available data sources
## =========================================================================

cat("=== Data Source Summary ===\n\n")

sources <- tribble(
  ~source, ~dataset_id, ~server, ~resolution, ~time_range, ~status,
  "MODIS Aqua L3SMI (Science Quality)", "erdMH1chlamday",
    "coastwatch.pfeg.noaa.gov", "4km", "2003-01 to 2022-05", "Downloaded",
  "VIIRS S-NPP (Science Quality)", "noaacwNPPVIIRSSQchlaMonthly",
    "coastwatch.noaa.gov", "4km", "2012-01 to 2026-02", "Downloaded",
  "MODIS Pacific (Experimental)", "erdMBchlamday_LonPM180",
    "coastwatch.pfeg.noaa.gov", "2.5km", "2006-01 to 2026-02", "URL provided",
  "VIIRS North Pacific 750m", "erdVHNchlamday",
    "coastwatch.pfeg.noaa.gov", "750m", "2015-01 to present", "URL provided",
  "Oregon State VGPM NPP", "N/A (HDF files)",
    "orca.science.oregonstate.edu", "18km", "2002-present", "Manual download",
  "Copernicus GlobColour L4", "OCEANCOLOUR_GLO_BGC_L4_MY_009_104",
    "data.marine.copernicus.eu", "4km", "1997-present", "Requires account",
  "DFO Canada Chl-a Climatology", "cf612f99-e1e8-43fd-804e-65fe9c2814ee",
    "open.canada.ca", "4km", "2003-2020 climatology", "Climatology only"
)

print(sources, width = 120)
