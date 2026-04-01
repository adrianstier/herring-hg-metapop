library(tidyverse)

raw_dir <- file.path("Data", "raw", "environmental")
out_dir <- file.path("Data", "processed")

sst_files <- list.files(raw_dir, pattern = "oisst.*monthly.*\\.csv$", full.names = TRUE)
cat("SST files found:\n")
cat(sst_files, sep = "\n")

sst_all <- map_dfr(sst_files, function(f) {
  read_csv(f, show_col_types = FALSE, skip = 2,
           col_names = c("time", "zlev", "latitude", "longitude", "sst", "anom"))
})

sst_monthly <- sst_all %>%
  mutate(
    date  = as.Date(time),
    year  = year(date),
    month = month(date)
  ) %>%
  group_by(year, month) %>%
  summarise(
    sst_mean      = mean(sst, na.rm = TRUE),
    sst_anom_mean = mean(anom, na.rm = TRUE),
    n_cells       = n(),
    .groups       = "drop"
  )

write_csv(sst_monthly, file.path(out_dir, "sst_haida_gwaii_monthly.csv"))
cat("\nSST monthly:", nrow(sst_monthly), "months, years",
    range(sst_monthly$year), "\n")
