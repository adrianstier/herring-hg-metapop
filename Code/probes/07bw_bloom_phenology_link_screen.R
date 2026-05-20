## ==========================================================================
##  07bw_bloom_phenology_link_screen.R
##
##  Build a short-window satellite chlorophyll bloom-phenology product for
##  Haida Gwaii / Hecate Strait and screen whether bloom timing/intensity
##  explains m1_stier_11 adult-growth residual patterns.
##
##  This is a data/readiness screen, not a promoted process-model branch.
##  It keeps the promoted Stier observation layer untouched.
## ==========================================================================  

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(scales)
})

options(timeout = max(600, getOption("timeout", 60)))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir  <- file.path(proj_dir, "Output", "figures")
proc_dir <- file.path(proj_dir, "Data", "processed")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(proc_dir, showWarnings = FALSE, recursive = TRUE)

regional_8day_path <- file.path(proc_dir, "chla_haida_gwaii_8day_regional_modis_r2022sq.csv")
phenology_path     <- file.path(proc_dir, "bloom_phenology_haida_gwaii_8day_modis_proxy.csv")
link_path          <- file.path(diag_dir, "bloom_phenology_herring_link_screen.csv")
screen_path        <- file.path(diag_dir, "bloom_phenology_herring_screen.md")
figure_path        <- file.path(fig_dir, "bloom_phenology_herring_screen.pdf")

dataset_id <- "erdMH1chla8day_R202SQ"
source_url <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdMH1chla8day_R202SQ.html"

fetch_modis_8day <- function(force = FALSE) {
  if (file.exists(regional_8day_path) && !force) {
    message("Using cached regional 8-day Chl-a: ", regional_8day_path)
    return(read_csv(regional_8day_path, show_col_types = FALSE))
  }

  message("Downloading strided MODIS Aqua 8-day Chl-a from CoastWatch ERDDAP...")

  raw <- map_dfr(2003:2025, function(yr) {
    time_min <- sprintf("%s-01-01T00:00:00Z", yr)
    time_max <- if (yr == 2025) "2025-10-28T00:00:00Z" else sprintf("%s-12-31T00:00:00Z", yr)
    query <- paste0(
      "https://coastwatch.pfeg.noaa.gov/erddap/griddap/", dataset_id, ".csvp?",
      "chlor_a",
      "%5B(", time_min, "):1:(", time_max, ")%5D",
      "%5B(51.5):8:(54.5)%5D",
      "%5B(-133):8:(-129)%5D"
    )

    tmp <- tempfile(fileext = ".csv")
    message("  fetching ", yr)
    ok <- tryCatch({
      status <- system2(
        "curl",
        args = c("-L", "--fail", "--max-time", "60", "-sS", "-o", shQuote(tmp), shQuote(query))
      )
      identical(status, 0L)
    }, error = function(e) {
      message("  ", yr, " failed: ", conditionMessage(e))
      FALSE
    })

    if (!ok) {
      return(tibble())
    }

    dat <- read_csv(
      tmp,
      show_col_types = FALSE,
      na = c("NaN", "nan", "NA", "")
    )
    if (nrow(dat) == 0) return(tibble())

    dat %>%
      rename(
        time = `time (UTC)`,
        latitude = `latitude (degrees_north)`,
        longitude = `longitude (degrees_east)`,
        chla = `chlor_a (mg m-3)`
      ) %>%
      mutate(
        time_utc = as.POSIXct(time, tz = "UTC"),
        date = as.Date(time_utc),
        year = year(date),
        month = month(date),
        doy = yday(date)
      )
  })

  if (nrow(raw) == 0) {
    stop("Could not download any ", dataset_id, " data from ERDDAP.")
  }

  regional <- raw %>%
    group_by(date, year, month, doy) %>%
    summarise(
      chla_mean = mean(chla, na.rm = TRUE),
      chla_median = median(chla, na.rm = TRUE),
      chla_sd = sd(chla, na.rm = TRUE),
      n_valid = sum(is.finite(chla)),
      n_total = n(),
      pct_valid = 100 * n_valid / n_total,
      .groups = "drop"
    ) %>%
    mutate(
      chla_mean = if_else(is.nan(chla_mean), NA_real_, chla_mean),
      chla_median = if_else(is.nan(chla_median), NA_real_, chla_median),
      source_dataset = dataset_id,
      spatial_window = "51.5-54.5N, 129-133W, every 8th 4-km grid cell"
    ) %>%
    arrange(date)

  write_csv(regional, regional_8day_path)
  regional
}

safe_cor <- function(x, y, method = "pearson") {
  keep <- is.finite(x) & is.finite(y)
  if (sum(keep) < 5 || sd(x[keep]) == 0 || sd(y[keep]) == 0) {
    return(NA_real_)
  }
  suppressWarnings(cor(x[keep], y[keep], method = method))
}

safe_lm_coef <- function(formula, data, term) {
  fit <- tryCatch(lm(formula, data = data), error = function(e) NULL)
  if (is.null(fit)) return(NA_real_)
  coefs <- coef(summary(fit))
  if (!term %in% rownames(coefs)) return(NA_real_)
  unname(coefs[term, "Estimate"])
}

z <- function(x) {
  sx <- sd(x, na.rm = TRUE)
  if (!is.finite(sx) || sx == 0) {
    return(rep(0, length(x)))
  }
  (x - mean(x, na.rm = TRUE)) / sx
}

bloom_onset_row <- function(dat) {
  winter <- dat %>%
    filter(month %in% 1:2, is.finite(chla_mean))
  spring <- dat %>%
    filter(month %in% 3:6, is.finite(chla_mean))
  search <- dat %>%
    filter(month %in% 1:6, is.finite(chla_mean)) %>%
    arrange(date)

  if (nrow(winter) < 2 || nrow(spring) < 3 || nrow(search) == 0) {
    return(tibble(
      bloom_onset_date = as.Date(NA),
      bloom_onset_doy = NA_real_,
      bloom_threshold = NA_real_
    ))
  }

  baseline <- median(winter$chla_mean, na.rm = TRUE)
  peak <- max(spring$chla_mean, na.rm = TRUE)
  threshold <- baseline + 0.5 * (peak - baseline)
  onset <- search %>%
    filter(chla_mean >= threshold) %>%
    slice_head(n = 1)

  if (nrow(onset) == 0) {
    tibble(
      bloom_onset_date = as.Date(NA),
      bloom_onset_doy = NA_real_,
      bloom_threshold = threshold
    )
  } else {
    tibble(
      bloom_onset_date = onset$date,
      bloom_onset_doy = onset$doy,
      bloom_threshold = threshold
    )
  }
}

regional_8day <- fetch_modis_8day(force = identical(Sys.getenv("FORCE_DOWNLOAD_CHLA_8DAY"), "1"))

phenology <- regional_8day %>%
  filter(year >= 2003, year <= 2025) %>%
  group_by(year) %>%
  group_modify(~{
    dat <- .x
    spring <- dat %>%
      filter(month %in% 3:6, is.finite(chla_mean))
    growing <- dat %>%
      filter(month %in% 4:9, is.finite(chla_mean))
    peak <- spring %>%
      arrange(desc(chla_mean), date) %>%
      slice_head(n = 1)
    onset <- bloom_onset_row(dat)

    tibble(
      chla_spring_mean_8day = mean(spring$chla_mean, na.rm = TRUE),
      chla_spring_integral_8day = sum(spring$chla_mean * 8, na.rm = TRUE),
      chla_growing_mean_8day = mean(growing$chla_mean, na.rm = TRUE),
      spring_peak_chla_8day = if (nrow(peak) == 0) NA_real_ else peak$chla_mean,
      spring_peak_date = if (nrow(peak) == 0) as.Date(NA) else peak$date,
      spring_peak_doy = if (nrow(peak) == 0) NA_real_ else peak$doy,
      n_spring_8day = nrow(spring),
      median_spring_valid_pct = median(spring$pct_valid, na.rm = TRUE)
    ) %>%
      bind_cols(onset)
  }) %>%
  ungroup() %>%
  mutate(
    chla_spring_mean_8day = if_else(is.nan(chla_spring_mean_8day), NA_real_, chla_spring_mean_8day),
    chla_spring_integral_8day = if_else(n_spring_8day == 0, NA_real_, chla_spring_integral_8day),
    data_quality_flag = case_when(
      n_spring_8day < 8 ~ "low_spring_temporal_coverage",
      median_spring_valid_pct < 20 ~ "low_spring_spatial_validity",
      TRUE ~ "screen_ok"
    )
  )

write_csv(phenology, phenology_path)

driver_ts <- read_csv(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  show_col_types = FALSE
) %>%
  select(
    year, growth_median, pdo_lag1, fishing_fraction_median_lag1,
    total_biomass_median, occupied_sections, weighted_spawn_start_doy,
    chla_spring_mean_monthly = chla_spring_mean
  )

linked <- driver_ts %>%
  left_join(phenology, by = "year") %>%
  arrange(year) %>%
  mutate(
    spawn_minus_bloom_onset_days = weighted_spawn_start_doy - bloom_onset_doy,
    spawn_minus_spring_peak_days = weighted_spawn_start_doy - spring_peak_doy,
    larval_20d_minus_spring_peak_days = weighted_spawn_start_doy + 20 - spring_peak_doy,
    abs_larval_20d_minus_spring_peak_days = abs(larval_20d_minus_spring_peak_days),
    across(
      c(
        chla_spring_mean_8day, chla_spring_integral_8day,
        chla_growing_mean_8day, spring_peak_chla_8day,
        bloom_onset_doy, spring_peak_doy,
        spawn_minus_bloom_onset_days, spawn_minus_spring_peak_days,
        abs_larval_20d_minus_spring_peak_days
      ),
      list(lag1 = ~ lag(.x, 1)),
      .names = "{.col}_{.fn}"
    )
  )

predictors <- tribble(
  ~predictor, ~label, ~expected_direction, ~interpretation,
  "chla_spring_mean_8day", "spring Chl-a mean", "positive", "same-year spring bloom biomass/intensity proxy",
  "chla_spring_mean_8day_lag1", "spring Chl-a mean lag 1", "positive", "prior-year bloom biomass/intensity proxy",
  "chla_spring_integral_8day", "spring Chl-a integral", "positive", "same-year bloom integral proxy",
  "chla_spring_integral_8day_lag1", "spring Chl-a integral lag 1", "positive", "prior-year bloom integral proxy",
  "spring_peak_chla_8day", "spring peak Chl-a", "positive", "same-year bloom peak proxy",
  "spring_peak_chla_8day_lag1", "spring peak Chl-a lag 1", "positive", "prior-year bloom peak proxy",
  "bloom_onset_doy", "bloom onset DOY", "unclear", "same-year 50% winter-to-peak threshold crossing",
  "bloom_onset_doy_lag1", "bloom onset DOY lag 1", "unclear", "prior-year 50% threshold crossing",
  "spring_peak_doy", "spring peak DOY", "unclear", "same-year peak timing",
  "spring_peak_doy_lag1", "spring peak DOY lag 1", "unclear", "prior-year peak timing",
  "spawn_minus_spring_peak_days", "spawn minus bloom peak", "near_zero_best", "adult spawn timing relative to spring bloom peak",
  "spawn_minus_spring_peak_days_lag1", "spawn minus bloom peak lag 1", "near_zero_best", "prior-year timing mismatch proxy",
  "abs_larval_20d_minus_spring_peak_days", "|larval window minus bloom peak|", "negative", "absolute larval-window mismatch proxy",
  "abs_larval_20d_minus_spring_peak_days_lag1", "|larval window minus bloom peak| lag 1", "negative", "prior-year absolute mismatch proxy"
)

screen_tbl <- predictors %>%
  mutate(result = map(predictor, function(pred) {
    dat <- tibble(
      year = linked$year,
      growth_median = linked$growth_median,
      predictor_value = linked[[pred]],
      pdo_lag1 = linked$pdo_lag1,
      fishing_fraction_median_lag1 = linked$fishing_fraction_median_lag1
    ) %>%
      filter(is.finite(growth_median), is.finite(predictor_value))

    detrended_r <- if (nrow(dat) >= 8) {
      gx <- resid(lm(growth_median ~ year, data = dat))
      px <- resid(lm(predictor_value ~ year, data = dat))
      safe_cor(px, gx, method = "pearson")
    } else {
      NA_real_
    }

    adjusted_dat <- dat %>%
      mutate(
        pred_z = z(predictor_value),
        pdo_z = z(pdo_lag1),
        fish_z = z(fishing_fraction_median_lag1),
        year_z = z(year)
      )

    tibble(
      n = nrow(dat),
      year_min = if_else(nrow(dat) == 0, NA_integer_, min(dat$year)),
      year_max = if_else(nrow(dat) == 0, NA_integer_, max(dat$year)),
      spearman_rho = safe_cor(dat$predictor_value, dat$growth_median, "spearman"),
      detrended_r = detrended_r,
      adjusted_beta = safe_lm_coef(
        growth_median ~ pred_z + pdo_z + fish_z + year_z,
        adjusted_dat,
        "pred_z"
      )
    )
  })) %>%
  unnest(result) %>%
  mutate(
    screen_gate = case_when(
      n < 15 ~ "data_short",
      is.na(adjusted_beta) ~ "not_estimable",
      abs(detrended_r) >= 0.35 & abs(adjusted_beta) >= 0.15 ~ "follow_up_candidate",
      TRUE ~ "weak_screen_only"
    )
  ) %>%
  arrange(desc(screen_gate == "follow_up_candidate"), desc(abs(replace_na(detrended_r, 0))))

write_csv(screen_tbl, link_path)

top_tbl <- screen_tbl %>%
  select(
    label, n, year_min, year_max, spearman_rho, detrended_r,
    adjusted_beta, screen_gate, interpretation
  ) %>%
  slice_head(n = 8)

coverage <- phenology %>%
  summarise(
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE),
    n_years = n(),
    median_spring_valid_pct = median(median_spring_valid_pct, na.rm = TRUE),
    median_n_spring_8day = median(n_spring_8day, na.rm = TRUE)
  )

blob_tbl <- linked %>%
  mutate(period = case_when(
    year %in% 2003:2013 ~ "pre-Blob satellite years",
    year %in% 2014:2016 ~ "Blob/MHW years",
    year %in% 2017:2025 ~ "post-Blob satellite years"
  )) %>%
  filter(!is.na(period)) %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    median_spring_chla = median(chla_spring_mean_8day, na.rm = TRUE),
    median_bloom_onset_doy = median(bloom_onset_doy, na.rm = TRUE),
    median_spring_peak_doy = median(spring_peak_doy, na.rm = TRUE),
    median_growth = median(growth_median, na.rm = TRUE),
    median_occupied_sections = median(occupied_sections, na.rm = TRUE),
    .groups = "drop"
  )

fmt <- function(x, digits = 2) {
  ifelse(is.na(x), "NA", number(x, accuracy = 10^-digits))
}

summary_lines <- c(
  "# Bloom Phenology / Herring Link Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
  "",
  "## Data Product",
  "",
  paste0("- Satellite source: NOAA CoastWatch ERDDAP `", dataset_id, "`; NASA/GSFC OBPG MODIS Aqua R2022 science-quality 8-day Chl-a."),
  paste0("- Source URL: ", source_url),
  "- Spatial window: 51.5-54.5N, 129-133W; every eighth 4-km grid cell to keep the product light and reproducible.",
  paste0("- Annual bloom phenology years: `", coverage$first_year, "-", coverage$last_year, "`; n `", coverage$n_years, "`."),
  paste0("- Median spring observations per year: `", fmt(coverage$median_n_spring_8day, 1), "` 8-day composites; median valid spring grid share `", fmt(coverage$median_spring_valid_pct, 1), "%`."),
  "",
  "## Interpretation Guardrail",
  "",
  "- This product measures satellite chlorophyll-a: a phytoplankton biomass / bloom proxy. It does not directly measure zooplankton biomass, prey size, copepod lipid content, euphausiids, or larval herring feeding success.",
  "- Use it to test whether the Blob / marine heatwave window coincided with a bloom-intensity or bloom-timing anomaly. Treat any adult herring growth association as a short-window diagnostic until in-situ plankton or prey-quality data are linked.",
  "- The promoted model remains `m1_stier_11`; this screen does not change zeros, survey q, or Stan process structure.",
  "",
  "## Blob-Window Descriptive Check",
  "",
  knitr::kable(blob_tbl, digits = 2, format = "pipe"),
  "",
  "## Growth-Screen Results",
  "",
  knitr::kable(top_tbl, digits = 3, format = "pipe"),
  "",
  "## Clear Answer For The Heatwave Question",
  "",
  "- We can now answer the first-order satellite-bloom version locally: test whether 2014-2016 had anomalous Chl-a timing/intensity and whether those annual metrics line up with `m1_stier_11` latent growth.",
  "- This is still not a zooplankton-energy answer. The stronger bottom-up test needs in-situ zooplankton biomass/community data or a trusted regional lower-trophic model product.",
  "- Near-term model modification, if a bloom metric survives review: add one post-2003 active-only Chl-a phenology covariate on the Stier observation layer, compare to PDO/fishing-adjusted screens, and keep missing pre-satellite years inactive rather than interpolated.",
  "",
  "## Files Written",
  "",
  paste0("- `", regional_8day_path, "`"),
  paste0("- `", phenology_path, "`"),
  paste0("- `", link_path, "`"),
  paste0("- `", figure_path, "`")
)

writeLines(summary_lines, screen_path)

plot_dat <- linked %>%
  filter(year >= 2003)

p_chla <- ggplot(regional_8day %>% filter(year >= 2003), aes(date, chla_mean)) +
  geom_line(colour = "#1b9e77", linewidth = 0.35, alpha = 0.75, na.rm = TRUE) +
  geom_point(
    data = phenology,
    aes(spring_peak_date, spring_peak_chla_8day),
    inherit.aes = FALSE,
    colour = "#d95f02",
    size = 1.6,
    na.rm = TRUE
  ) +
  annotate("rect",
    xmin = as.Date("2014-01-01"), xmax = as.Date("2016-12-31"),
    ymin = -Inf, ymax = Inf, alpha = 0.08, fill = "#d95f02"
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(
    title = "Haida Gwaii / Hecate Strait MODIS Aqua 8-day chlorophyll",
    subtitle = "Orange points are spring peaks; shaded interval is 2014-2016 Blob/MHW window",
    x = NULL,
    y = "Regional mean Chl-a (mg m^-3)"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_link <- ggplot(plot_dat, aes(chla_spring_mean_8day_lag1, growth_median)) +
  geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.25) +
  geom_point(aes(colour = year %in% 2014:2016), size = 2, na.rm = TRUE) +
  geom_smooth(method = "lm", se = FALSE, colour = "grey35", linewidth = 0.5, na.rm = TRUE) +
  scale_colour_manual(values = c(`FALSE` = "#377eb8", `TRUE` = "#d95f02"), guide = "none") +
  labs(
    title = "Prior-year spring Chl-a versus promoted-model latent growth",
    subtitle = "Short satellite window; use as screen, not promoted mechanism",
    x = "Lag-1 spring Chl-a mean (mg m^-3)",
    y = "m1_stier_11 latent growth median"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_mismatch <- ggplot(plot_dat, aes(abs_larval_20d_minus_spring_peak_days, growth_median)) +
  geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.25) +
  geom_point(aes(colour = year %in% 2014:2016), size = 2, na.rm = TRUE) +
  geom_smooth(method = "lm", se = FALSE, colour = "grey35", linewidth = 0.5, na.rm = TRUE) +
  scale_colour_manual(values = c(`FALSE` = "#4daf4a", `TRUE` = "#d95f02"), guide = "none") +
  labs(
    title = "Larval-window mismatch proxy versus latent growth",
    subtitle = "Adult spawn start + 20 days relative to spring bloom peak",
    x = "Absolute mismatch (days)",
    y = "m1_stier_11 latent growth median"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

pdf(figure_path, width = 8.5, height = 5.5)
print(p_chla)
print(p_link)
print(p_mismatch)
dev.off()

message("Wrote: ", screen_path)
