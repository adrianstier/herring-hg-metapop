## ==========================================================================
##  02b_predator_processing.R
##  Process marine predator time series for Haida Gwaii herring metapopulation
##  model M5. Produces annual indices for harbour seals, Steller sea lions,
##  and humpback whales aligned to the model year range (1951-2025).
##
##  Data sources:
##    - Harbour seal:   DFO haul-out counts, HG region, 1986-2017
##    - Steller sea lion: DFO summer counts, HG region, 1971-2013
##    - Humpback whale:   Cheeseman et al. 2024, N Pacific, 2002-2021
##
##  Approach:
##    1. Aggregate raw counts to annual Haida Gwaii totals
##    2. Log-transform (log(count + 1)) for each species
##    3. Interpolate gaps with loess smoothing on observed years
##    4. Extrapolate forward/backward using growth-rate assumptions
##    5. Standardize each series to zero mean, unit SD over the full time span
##    6. Create a combined predator index (mean of standardized species)
##    7. Build observation masks indicating which years have actual data
##    8. Save to Data/processed/predator_indices.csv
##
##  Output columns:
##    year, seal_raw, ssl_raw, whale_raw,
##    seal_log, ssl_log, whale_log,
##    seal_std, ssl_std, whale_std,
##    pred_combined, seal_obs, ssl_obs, whale_obs
## ==========================================================================

library(tidyverse)

proj_dir <- here::here()
raw_dir  <- file.path(proj_dir, "Data", "raw", "predators")
proc_dir <- file.path(proj_dir, "Data", "processed")

## Load model year range from processed data
load(file.path(proc_dir, "jags_model_inputs.RData"))
model_years <- jags_data$years
cat("Model year range:", min(model_years), "-", max(model_years), "\n")


## =========================================================================
##  1. HARBOUR SEAL — Haida Gwaii annual totals
## =========================================================================

seal_raw <- read_csv(
  file.path(raw_dir, "Harbour_seal_counts_haulout_locs_BCcoast.csv"),
  show_col_types = FALSE
)

# Filter to Haida Gwaii, aggregate to annual totals
# Use sum of complex_count across all subsites surveyed that year
seal_hg <- seal_raw %>%
  filter(Region == "Haida Gwaii") %>%
  group_by(Year) %>%
  summarise(
    seal_count    = sum(complex_count, na.rm = TRUE),
    n_subsites    = n_distinct(SubsiteID),
    .groups       = "drop"
  ) %>%
  arrange(Year)

cat("\n=== Harbour Seal (Haida Gwaii) ===\n")
cat("Survey years:", paste(seal_hg$Year, collapse = ", "), "\n")
cat("Counts:", paste(seal_hg$seal_count, collapse = ", "), "\n")

# The survey effort (n_subsites) varies widely across years.
# Normalize counts by the number of subsites to get a per-site average,
# then use that as the index (avoids bias from variable effort).
seal_hg <- seal_hg %>%
  mutate(seal_per_site = seal_count / n_subsites)


## =========================================================================
##  2. STELLER SEA LION — Haida Gwaii annual totals
## =========================================================================

ssl_raw <- read_csv(
  file.path(raw_dir, "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv"),
  show_col_types = FALSE
)

# Filter to Haida Gwaii, parse numeric count, sum annually
ssl_hg <- ssl_raw %>%
  filter(REGION == "Haida Gwaii") %>%
  mutate(
    count_np = suppressWarnings(as.numeric(`COUNT NON-PUP`))
  ) %>%
  filter(!is.na(count_np)) %>%
  group_by(`SURVEY YEAR`) %>%
  summarise(
    ssl_count = sum(count_np, na.rm = TRUE),
    n_sites   = n_distinct(SITE),
    .groups   = "drop"
  ) %>%
  rename(Year = `SURVEY YEAR`) %>%
  arrange(Year)

cat("\n=== Steller Sea Lion (Haida Gwaii) ===\n")
cat("Survey years:", paste(ssl_hg$Year, collapse = ", "), "\n")
cat("Non-pup counts:", paste(ssl_hg$ssl_count, collapse = ", "), "\n")


## =========================================================================
##  3. HUMPBACK WHALE — North Pacific basin-wide
## =========================================================================

whale_raw <- read_csv(
  file.path(raw_dir, "humpback_whale_NorthPacific_abundance_Cheeseman2024.csv"),
  show_col_types = FALSE
)

whale_np <- whale_raw %>%
  select(Year, Abundance) %>%
  rename(whale_count = Abundance) %>%
  arrange(Year)

cat("\n=== Humpback Whale (North Pacific) ===\n")
cat("Years:", paste(whale_np$Year, collapse = ", "), "\n")
cat("Abundance range:", range(whale_np$whale_count), "\n")


## =========================================================================
##  4. INTERPOLATE AND EXTRAPOLATE TO MODEL YEARS
## =========================================================================
##
## Strategy:
##   - For each species, fit a loess curve through log(observed values)
##     to interpolate between survey years.
##   - Extrapolate backward/forward using species-specific growth rates
##     derived from population dynamics literature:
##       * Harbour seals: grew ~5.6%/yr 1970s-2000s, then plateaued (Olesiuk 2010)
##       * SSL Eastern DPS: ~4.25%/yr 1987-2017, leveling off post-2017 (NOAA 2024)
##       * Humpback: ~5.9%/yr 2002-2013, then -3.0%/yr 2014-2021 (Cheeseman 2024)
##   - Before 1970 (pre-protection era): use low baseline values
##
## These extrapolations are necessarily uncertain, but the model uses
## observation masks to flag years without actual data.
## =========================================================================

full_years <- tibble(Year = model_years)

## --- Harbour seal interpolation/extrapolation ---
# Log-transform the effort-corrected index
seal_obs <- seal_hg %>%
  mutate(seal_log = log(seal_per_site + 1))

# Fit loess to observed years for interpolation
if (nrow(seal_obs) >= 4) {
  seal_loess <- loess(seal_log ~ Year, data = seal_obs, span = 1.0)
} else {
  # Too few points for loess — use linear
  seal_loess <- lm(seal_log ~ Year, data = seal_obs)
}

# Build full series
seal_full <- full_years %>%
  left_join(seal_obs %>% select(Year, seal_log), by = "Year") %>%
  mutate(seal_observed = !is.na(seal_log))

# Interpolate within data range
interp_range <- seal_obs$Year
seal_interp_years <- which(
  seal_full$Year >= min(interp_range) &
  seal_full$Year <= max(interp_range) &
  is.na(seal_full$seal_log)
)
if (length(seal_interp_years) > 0) {
  seal_full$seal_log[seal_interp_years] <- predict(
    seal_loess,
    newdata = data.frame(Year = seal_full$Year[seal_interp_years])
  )
}

# Extrapolate backward: seals were heavily depleted pre-1970s,
# recovering ~5.6%/yr through the 1970s-1980s
earliest_obs <- min(seal_obs$Year)
earliest_val <- seal_full$seal_log[seal_full$Year == earliest_obs]
r_seal_early <- log(1 + 0.056)  # 5.6%/yr growth rate (log scale)

backward_years <- which(seal_full$Year < earliest_obs)
if (length(backward_years) > 0) {
  for (idx in rev(backward_years)) {
    yrs_back <- earliest_obs - seal_full$Year[idx]
    seal_full$seal_log[idx] <- max(
      earliest_val - r_seal_early * yrs_back,
      log(1 + 1)  # floor: at least 1 seal
    )
  }
}

# Extrapolate forward: seals roughly stable post-2015 (DFO SAR 2022)
latest_obs <- max(seal_obs$Year)
latest_val <- seal_full$seal_log[seal_full$Year == latest_obs]
# Stable or very slight decline
r_seal_late <- 0.0  # stable

forward_years <- which(seal_full$Year > latest_obs)
if (length(forward_years) > 0) {
  seal_full$seal_log[forward_years] <- latest_val + r_seal_late *
    (seal_full$Year[forward_years] - latest_obs)
}

## --- Steller sea lion interpolation/extrapolation ---
ssl_obs <- ssl_hg %>%
  mutate(ssl_log = log(ssl_count + 1))

if (nrow(ssl_obs) >= 4) {
  ssl_loess <- loess(ssl_log ~ Year, data = ssl_obs, span = 0.75)
} else {
  ssl_loess <- lm(ssl_log ~ Year, data = ssl_obs)
}

ssl_full <- full_years %>%
  left_join(ssl_obs %>% select(Year, ssl_log), by = "Year") %>%
  mutate(ssl_observed = !is.na(ssl_log))

# Interpolate within data range
ssl_interp_range <- ssl_obs$Year
ssl_interp_years <- which(
  ssl_full$Year >= min(ssl_interp_range) &
  ssl_full$Year <= max(ssl_interp_range) &
  is.na(ssl_full$ssl_log)
)
if (length(ssl_interp_years) > 0) {
  ssl_full$ssl_log[ssl_interp_years] <- predict(
    ssl_loess,
    newdata = data.frame(Year = ssl_full$Year[ssl_interp_years])
  )
}

# Extrapolate backward: SSL were heavily depleted in 1960s from bounty hunting,
# starting recovery in late 1960s at ~4-5%/yr
earliest_ssl <- min(ssl_obs$Year)
earliest_ssl_val <- ssl_full$ssl_log[ssl_full$Year == earliest_ssl]
r_ssl_early <- log(1 + 0.0425)  # 4.25%/yr (NOAA 2024)

backward_ssl <- which(ssl_full$Year < earliest_ssl)
if (length(backward_ssl) > 0) {
  for (idx in rev(backward_ssl)) {
    yrs_back <- earliest_ssl - ssl_full$Year[idx]
    ssl_full$ssl_log[idx] <- max(
      earliest_ssl_val - r_ssl_early * yrs_back,
      log(1 + 1)  # floor
    )
  }
}

# Extrapolate forward: ~4.25%/yr 2013-2017, then stable/slight decline
latest_ssl <- max(ssl_obs$Year)
latest_ssl_val <- ssl_full$ssl_log[ssl_full$Year == latest_ssl]
r_ssl_late <- log(1 + 0.02)  # slowing growth post-2017

forward_ssl <- which(ssl_full$Year > latest_ssl)
if (length(forward_ssl) > 0) {
  for (idx in forward_ssl) {
    yrs_fwd <- ssl_full$Year[idx] - latest_ssl
    if (yrs_fwd <= 4) {
      # 2014-2017: continued at ~4.25%/yr
      ssl_full$ssl_log[idx] <- latest_ssl_val + log(1 + 0.0425) * yrs_fwd
    } else {
      # Post-2017: slowing growth (~2%/yr)
      val_2017 <- latest_ssl_val + log(1 + 0.0425) * 4
      ssl_full$ssl_log[idx] <- val_2017 + r_ssl_late * (yrs_fwd - 4)
    }
  }
}

## --- Humpback whale interpolation/extrapolation ---
whale_obs <- whale_np %>%
  mutate(whale_log = log(whale_count + 1))

whale_full <- full_years %>%
  left_join(whale_obs %>% select(Year, whale_log), by = "Year") %>%
  mutate(whale_observed = !is.na(whale_log))

# Extrapolate backward: Humpbacks were severely depleted by whaling,
# protected in 1966, very slow initial recovery.
# Pre-whaling N Pacific: ~15,000. Reduced to ~1,000-2,000 by 1966.
# Recovery ~5-8%/yr from late 1960s onward.
earliest_whale <- min(whale_obs$Year)
earliest_whale_val <- whale_full$whale_log[whale_full$Year == earliest_whale]
r_whale_early <- log(1 + 0.059)  # 5.9%/yr (Cheeseman 2024)

backward_whale <- which(whale_full$Year < earliest_whale)
if (length(backward_whale) > 0) {
  for (idx in rev(backward_whale)) {
    yrs_back <- earliest_whale - whale_full$Year[idx]
    # Back-project at recovery rate, with a floor of ~1000 whales
    whale_full$whale_log[idx] <- max(
      earliest_whale_val - r_whale_early * yrs_back,
      log(1000 + 1)  # floor: ~1000 whales at population minimum
    )
  }
}

# Extrapolate forward: -3.0%/yr post-2014 (marine heatwave decline)
latest_whale <- max(whale_obs$Year)
latest_whale_val <- whale_full$whale_log[whale_full$Year == latest_whale]
r_whale_late <- log(1 - 0.03)  # -3%/yr decline

forward_whale <- which(whale_full$Year > latest_whale)
if (length(forward_whale) > 0) {
  whale_full$whale_log[forward_whale] <- latest_whale_val + r_whale_late *
    (whale_full$Year[forward_whale] - latest_whale)
}

# Interpolate within observed range (should be mostly continuous 2002-2021)
whale_interp_years <- which(
  whale_full$Year >= min(whale_obs$Year) &
  whale_full$Year <= max(whale_obs$Year) &
  is.na(whale_full$whale_log)
)
if (length(whale_interp_years) > 0) {
  whale_loess <- loess(whale_log ~ Year, data = whale_obs, span = 0.5)
  whale_full$whale_log[whale_interp_years] <- predict(
    whale_loess,
    newdata = data.frame(Year = whale_full$Year[whale_interp_years])
  )
}


## =========================================================================
##  5. STANDARDIZE TO ZERO MEAN, UNIT SD
## =========================================================================

pred_df <- full_years %>%
  left_join(seal_full %>% select(Year, seal_log, seal_observed), by = "Year") %>%
  left_join(ssl_full %>% select(Year, ssl_log, ssl_observed), by = "Year") %>%
  left_join(whale_full %>% select(Year, whale_log, whale_observed), by = "Year")

# Standardize each log-transformed series
pred_df <- pred_df %>%
  mutate(
    seal_std  = (seal_log  - mean(seal_log,  na.rm = TRUE)) / sd(seal_log,  na.rm = TRUE),
    ssl_std   = (ssl_log   - mean(ssl_log,   na.rm = TRUE)) / sd(ssl_log,   na.rm = TRUE),
    whale_std = (whale_log - mean(whale_log, na.rm = TRUE)) / sd(whale_log, na.rm = TRUE)
  )

# Combined predator index: mean of standardized series
pred_df <- pred_df %>%
  mutate(
    pred_combined = (seal_std + ssl_std + whale_std) / 3
  )

# Observation masks: 1 = actual data exists, 0 = interpolated/extrapolated
# For the model, these determine when predator terms are "trusted"
pred_df <- pred_df %>%
  mutate(
    seal_obs  = as.integer(seal_observed),
    ssl_obs   = as.integer(ssl_observed),
    whale_obs = as.integer(whale_observed)
  )

# Back-transform to raw scale for reference
pred_df <- pred_df %>%
  mutate(
    seal_raw  = exp(seal_log) - 1,
    ssl_raw   = exp(ssl_log) - 1,
    whale_raw = exp(whale_log) - 1
  )


## =========================================================================
##  6. DIAGNOSTICS
## =========================================================================

cat("\n===================================================\n")
cat("  PREDATOR INDEX SUMMARY\n")
cat("===================================================\n")
cat("  Years:         ", min(pred_df$Year), "-", max(pred_df$Year), "\n")
cat("  Seal obs yrs:  ", sum(pred_df$seal_obs), "of", nrow(pred_df), "\n")
cat("  SSL obs yrs:   ", sum(pred_df$ssl_obs), "of", nrow(pred_df), "\n")
cat("  Whale obs yrs: ", sum(pred_df$whale_obs), "of", nrow(pred_df), "\n")

cat("\n  Standardized predator indices (summary):\n")
cat("  seal_std:  ", round(range(pred_df$seal_std), 2), "\n")
cat("  ssl_std:   ", round(range(pred_df$ssl_std), 2), "\n")
cat("  whale_std: ", round(range(pred_df$whale_std), 2), "\n")
cat("  combined:  ", round(range(pred_df$pred_combined), 2), "\n")

# Correlation among predator indices
cat("\n  Correlation among standardized indices:\n")
cor_mat <- cor(pred_df[, c("seal_std", "ssl_std", "whale_std")])
print(round(cor_mat, 3))

cat("===================================================\n")


## =========================================================================
##  7. SAVE
## =========================================================================

out_df <- pred_df %>%
  select(
    year = Year,
    seal_raw, ssl_raw, whale_raw,
    seal_log, ssl_log, whale_log,
    seal_std, ssl_std, whale_std,
    pred_combined,
    seal_obs, ssl_obs, whale_obs
  )

write_csv(out_df, file.path(proc_dir, "predator_indices.csv"))
cat("\nSaved predator indices to:", file.path(proc_dir, "predator_indices.csv"), "\n")

# Also save a quick diagnostic plot
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)

  p <- out_df %>%
    select(year, seal_std, ssl_std, whale_std, pred_combined) %>%
    pivot_longer(-year, names_to = "species", values_to = "index") %>%
    mutate(species = factor(species,
      levels = c("seal_std", "ssl_std", "whale_std", "pred_combined"),
      labels = c("Harbour seal", "Steller sea lion", "Humpback whale", "Combined")
    )) %>%
    ggplot(aes(x = year, y = index, colour = species)) +
    geom_line(linewidth = 0.8) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
    labs(
      x = "Year", y = "Standardized index",
      title = "Predator indices for Haida Gwaii herring model (M5)",
      colour = NULL
    ) +
    scale_colour_manual(values = c(
      "Harbour seal"     = "#E69F00",
      "Steller sea lion" = "#56B4E9",
      "Humpback whale"   = "#009E73",
      "Combined"         = "#0072B2"
    )) +
    theme_minimal(base_size = 10) +
    theme(legend.position = "bottom")

  ggsave(
    file.path(proj_dir, "Output", "predator_indices_diagnostic.png"),
    plot = p, width = 180, height = 100, units = "mm", dpi = 150
  )
  cat("Saved diagnostic plot to Output/predator_indices_diagnostic.png\n")
}
