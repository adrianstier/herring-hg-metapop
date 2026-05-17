# ============================================================================
# 07bb_predator_spatial_exposure_prototype.R
# Section-level predator exposure data product from raw haulout/rookery data.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

haversine_km <- function(lon1, lat1, lon2, lat2) {
  r <- 6371
  to_rad <- pi / 180
  dlat <- (lat2 - lat1) * to_rad
  dlon <- (lon2 - lon1) * to_rad
  a <- sin(dlat / 2)^2 +
    cos(lat1 * to_rad) * cos(lat2 * to_rad) * sin(dlon / 2)^2
  2 * r * atan2(sqrt(a), sqrt(1 - a))
}

period_for_year <- function(year) {
  case_when(
    year >= 1951 & year <= 1965 ~ "1951-1965 early industrial",
    year >= 1966 & year <= 1971 ~ "1966-1971 late reduction",
    year >= 1972 & year <= 2004 ~ "1972-2004 roe fishery",
    year >= 2005 & year <= 2013 ~ "2005-2013 closure",
    year >= 2014 & year <= 2016 ~ "2014-2016 marine heatwave",
    year >= 2017 & year <= 2025 ~ "2017-2025 recent closure",
    TRUE ~ "other"
  )
}

as_numeric_quiet <- function(x) {
  suppressWarnings(as.numeric(x))
}

z <- function(x) {
  if (sum(is.finite(x)) < 2L || sd(x, na.rm = TRUE) == 0) {
    return(rep(NA_real_, length(x)))
  }
  as.numeric((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))
}

fill_site_counts <- function(dat, years = 1951:2025) {
  dat %>%
    group_by(
      predator_group,
      predator_species_or_source,
      count_sensitivity,
      source_dataset,
      source_file,
      predator_site
    ) %>%
    arrange(year, .by_group = TRUE) %>%
    group_modify(function(.x, .y) {
      source_rows <- .x %>%
        filter(is.finite(year), is.finite(count))

      if (nrow(source_rows) == 0L) {
        return(tibble())
      }

      year_min <- min(source_rows$year, na.rm = TRUE)
      year_max <- max(source_rows$year, na.rm = TRUE)
      count_filled <- if (nrow(source_rows) == 1L) {
        rep(source_rows$count[[1]], length(years))
      } else {
        stats::approx(
          x = source_rows$year,
          y = source_rows$count,
          xout = years,
          rule = 2,
          ties = mean
        )$y
      }

      tibble(year = years) %>%
        left_join(
          source_rows %>%
            select(
              year,
              source_count = count,
              observed_source_count_flag,
              source_fill_column_flag
            ),
          by = "year"
        ) %>%
        mutate(
          pred_lon = median(source_rows$pred_lon, na.rm = TRUE),
          pred_lat = median(source_rows$pred_lat, na.rm = TRUE),
          first_source_year = year_min,
          last_source_year = year_max,
          count = count_filled,
          observed_count_flag = replace_na(observed_source_count_flag, FALSE),
          source_fill_column_flag = replace_na(source_fill_column_flag, FALSE),
          annual_interpolated_flag = !observed_count_flag & year > year_min & year < year_max,
          annual_extrapolated_flag = !observed_count_flag & (year < year_min | year > year_max),
          interpolated_flag = source_fill_column_flag | annual_interpolated_flag,
          extrapolated_flag = annual_extrapolated_flag
        )
    }) %>%
    ungroup()
}

centroids <- read_csv(
  file.path(proj_dir, "Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
) %>%
  filter(!section %in% c(4, 11)) %>%
  group_by(section, section_name) %>%
  summarise(
    section_lat = median(latitude, na.rm = TRUE),
    section_lon = median(longitude, na.rm = TRUE),
    coord_years = sum(!is.na(latitude) & !is.na(longitude)),
    .groups = "drop"
  ) %>%
  filter(is.finite(section_lat), is.finite(section_lon)) %>%
  rename(raw_section = section)

harbour <- read_csv(
  file.path(proj_dir, "Data", "raw", "predators", "Harbour_seal_counts_haulout_locs_BCcoast.csv"),
  show_col_types = FALSE
) %>%
  filter(Region == "Haida Gwaii") %>%
  transmute(
    predator_group = "mammals",
    predator_species_or_source = "Harbour seal",
    count_sensitivity = "observed_complex_count_annual_fill",
    source_dataset = "DFO harbour seal Haida Gwaii haulout complex counts",
    source_file = "Data/raw/predators/Harbour_seal_counts_haulout_locs_BCcoast.csv",
    predator_site = Complex,
    year = as.integer(Year),
    pred_lon = as.numeric(Longitude),
    pred_lat = as.numeric(Latitude),
    count = as.numeric(complex_count),
    observed_source_count_flag = is.finite(count),
    source_fill_column_flag = FALSE
  ) %>%
  filter(is.finite(year), is.finite(pred_lon), is.finite(pred_lat), is.finite(count)) %>%
  # complex_count is a complex-level count repeated across subsites; collapse
  # to one complex-year record to avoid artificial exposure inflation.
  group_by(
    predator_group,
    predator_species_or_source,
    count_sensitivity,
    source_dataset,
    source_file,
    predator_site,
    year
  ) %>%
  summarise(
    pred_lon = median(pred_lon, na.rm = TRUE),
    pred_lat = median(pred_lat, na.rm = TRUE),
    count = max(count, na.rm = TRUE),
    observed_source_count_flag = any(observed_source_count_flag),
    source_fill_column_flag = FALSE,
    .groups = "drop"
  )

ssl_raw <- read_csv(
  file.path(proj_dir, "Data", "raw", "predators", "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv"),
  show_col_types = FALSE
)

steller_source <- ssl_raw %>%
  filter(REGION == "Haida Gwaii") %>%
  transmute(
    predator_site = SITE,
    year = as.integer(`SURVEY YEAR`),
    pred_lon = as.numeric(LONGITUDE),
    pred_lat = as.numeric(LATITUDE),
    non_pup_raw = as_numeric_quiet(`COUNT NON-PUP`),
    non_pup_fill = as_numeric_quiet(`COUNT NON-PUP INTERPOLATED/EXTRAPOLATED`),
    pup_raw = as_numeric_quiet(`COUNT PUP`),
    pup_fill = as_numeric_quiet(`COUNT PUP INTERPOLATED/EXTRAPOLATED`),
    pre_rookery_raw = as_numeric_quiet(`COUNT PUP PRE-ROOKERY`),
    pre_rookery_fill = as_numeric_quiet(`COUNT PUP PRE-ROOKERY INTERPOLATED/EXTRAPOLATED`)
  ) %>%
  filter(is.finite(year), is.finite(pred_lon), is.finite(pred_lat))

steller_raw_non_pup <- steller_source %>%
  filter(is.finite(non_pup_raw)) %>%
  transmute(
    predator_group = "mammals",
    predator_species_or_source = "Steller sea lion raw non-pup",
    count_sensitivity = "raw_non_pup_annual_fill",
    source_dataset = "DFO Steller sea lion Haida Gwaii summer haulout counts",
    source_file = "Data/raw/predators/Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv",
    predator_site,
    year,
    pred_lon,
    pred_lat,
    count = non_pup_raw,
    observed_source_count_flag = TRUE,
    source_fill_column_flag = FALSE
  )

steller_filled_total <- steller_source %>%
  mutate(
    non_pup_count = coalesce(non_pup_fill, non_pup_raw, 0),
    pup_count = coalesce(pup_fill, pup_raw, 0),
    pre_rookery_count = coalesce(pre_rookery_fill, pre_rookery_raw, 0),
    count = non_pup_count + pup_count + pre_rookery_count,
    observed_source_count_flag = if_any(
      c(non_pup_raw, pup_raw, pre_rookery_raw),
      is.finite
    ),
    source_fill_column_flag = if_any(
      c(non_pup_fill, pup_fill, pre_rookery_fill),
      is.finite
    )
  ) %>%
  filter(is.finite(count)) %>%
  transmute(
    predator_group = "mammals",
    predator_species_or_source = "Steller sea lion filled total",
    count_sensitivity = "filled_total_annual_fill",
    source_dataset = "DFO Steller sea lion Haida Gwaii summer haulout counts",
    source_file = "Data/raw/predators/Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv",
    predator_site,
    year,
    pred_lon,
    pred_lat,
    count,
    observed_source_count_flag,
    source_fill_column_flag
  )

steller <- bind_rows(steller_raw_non_pup, steller_filled_total) %>%
  filter(is.finite(year), is.finite(pred_lon), is.finite(pred_lat), is.finite(count)) %>%
  group_by(
    predator_group,
    predator_species_or_source,
    count_sensitivity,
    source_dataset,
    source_file,
    predator_site,
    year
  ) %>%
  summarise(
    pred_lon = median(pred_lon, na.rm = TRUE),
    pred_lat = median(pred_lat, na.rm = TRUE),
    count = sum(count, na.rm = TRUE),
    observed_source_count_flag = any(observed_source_count_flag),
    source_fill_column_flag = any(source_fill_column_flag),
    .groups = "drop"
  )

pred_sites_observed <- bind_rows(harbour, steller)

pred_sites <- fill_site_counts(pred_sites_observed)

availability <- pred_sites %>%
  group_by(predator_group, predator_species_or_source, count_sensitivity) %>%
  summarise(
    first_source_year = min(first_source_year, na.rm = TRUE),
    last_source_year = max(last_source_year, na.rm = TRUE),
    observed_years = n_distinct(year[observed_count_flag]),
    interpolated_years = n_distinct(year[interpolated_flag]),
    extrapolated_years = n_distinct(year[extrapolated_flag]),
    predator_sites = n_distinct(predator_site),
    source_site_years = n_distinct(paste(predator_site, year)[observed_count_flag | source_fill_column_flag]),
    annual_site_years = n(),
    max_site_year_count = max(count, na.rm = TRUE),
    .groups = "drop"
  )

range_grid <- tibble(range_km = c(25, 50, 100))

exposure <- pred_sites %>%
  crossing(centroids, range_grid) %>%
  mutate(
    distance_km = haversine_km(pred_lon, pred_lat, section_lon, section_lat),
    exposure_contribution = count * exp(-distance_km / range_km)
  ) %>%
  group_by(
    predator_group,
    predator_species_or_source,
    count_sensitivity,
    source_dataset,
    source_file,
    range_km,
    year,
    raw_section,
    section_name
  ) %>%
  summarise(
    exposure = sum(exposure_contribution, na.rm = TRUE),
    observed_exposure = sum(exposure_contribution[observed_count_flag], na.rm = TRUE),
    interpolated_exposure = sum(exposure_contribution[interpolated_flag], na.rm = TRUE),
    extrapolated_exposure = sum(exposure_contribution[extrapolated_flag], na.rm = TRUE),
    nearest_predator_site_km = min(distance_km, na.rm = TRUE),
    weighted_mean_distance_km = weighted.mean(distance_km, w = pmax(exposure_contribution, 1e-12), na.rm = TRUE),
    source_site_count = n_distinct(predator_site),
    observed_site_count = n_distinct(predator_site[observed_count_flag]),
    interpolated_site_count = n_distinct(predator_site[interpolated_flag]),
    extrapolated_site_count = n_distinct(predator_site[extrapolated_flag]),
    source_fill_column_site_count = n_distinct(predator_site[source_fill_column_flag]),
    first_source_year = min(first_source_year, na.rm = TRUE),
    last_source_year = max(last_source_year, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(predator_species_or_source, count_sensitivity, range_km) %>%
  mutate(exposure_z = z(log1p(exposure))) %>%
  ungroup() %>%
  mutate(
    section = raw_section,
    kernel_km = range_km,
    observed_exposure_share = observed_exposure / pmax(exposure, 1e-12),
    interpolated_exposure_share = interpolated_exposure / pmax(exposure, 1e-12),
    extrapolated_exposure_share = extrapolated_exposure / pmax(exposure, 1e-12),
    observed_count_flag = observed_site_count > 0,
    interpolated_flag = interpolated_site_count > 0 | source_fill_column_site_count > 0,
    extrapolated_flag = extrapolated_site_count > 0,
    extrapolated_dominant_flag = extrapolated_exposure_share >= 0.5,
    exposure_data_status = case_when(
      extrapolated_exposure_share >= 0.99 ~ "all_extrapolated",
      observed_exposure_share >= 0.5 & extrapolated_exposure_share < 0.5 ~ "observed_or_observed_dominant",
      interpolated_exposure_share >= 0.5 & extrapolated_exposure_share < 0.5 ~ "interpolated_or_source_filled",
      extrapolated_exposure_share >= 0.5 ~ "extrapolated_dominant",
      observed_site_count > 0 & (interpolated_flag | extrapolated_flag) ~ "mixed_observed_filled",
      TRUE ~ "filled"
    ),
    provenance_note = case_when(
      predator_species_or_source == "Harbour seal" ~ "Complex counts collapsed to one complex-year, then linearly filled annually.",
      predator_species_or_source == "Steller sea lion raw non-pup" ~ "Raw non-pup counts only; annual values linearly filled between survey years and edge-held outside survey years.",
      predator_species_or_source == "Steller sea lion filled total" ~ "Non-pup, pup, and pre-rookery counts; source interpolated/extrapolated columns used when present, then linearly filled annually.",
      TRUE ~ "Annual section exposure from predator site counts and exponential distance kernel."
    )
  )

biomass <- read_csv(file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"), show_col_types = FALSE) %>%
  arrange(site, year) %>%
  group_by(site, site_name) %>%
  mutate(
    next_year_growth = log(lead(median) / median),
    next_year = year + 1
  ) %>%
  ungroup() %>%
  select(site, site_name, year, next_year_growth)

exposure_growth <- exposure %>%
  filter(!extrapolated_dominant_flag) %>%
  left_join(biomass, by = c("section_name" = "site_name", "year")) %>%
  filter(is.finite(next_year_growth), is.finite(exposure_z))

cor_summary <- exposure_growth %>%
  group_by(predator_group, predator_species_or_source, count_sensitivity, range_km) %>%
  summarise(
    n = n(),
    years = n_distinct(year),
    sections = n_distinct(site),
    rho_growth = cor(exposure_z, next_year_growth, method = "spearman", use = "complete.obs"),
    r_growth = cor(exposure_z, next_year_growth, method = "pearson", use = "complete.obs"),
    rho_year = cor(exposure_z, year, method = "spearman", use = "complete.obs"),
    observed_section_years = sum(observed_count_flag),
    interpolated_section_years = sum(interpolated_flag),
    extrapolated_section_years = sum(extrapolated_flag),
    gate = case_when(
      n < 20 ~ "too_sparse",
      abs(rho_year) > 0.5 ~ "time_confounded",
      rho_growth >= 0 ~ "wrong_or_weak_sign",
      TRUE ~ "screen_only_candidate"
    ),
    .groups = "drop"
  )

section_exposure <- exposure %>%
  filter(range_km == 50) %>%
  mutate(period = period_for_year(year)) %>%
  left_join(
    biomass %>% distinct(site, site_name),
    by = c("section_name" = "site_name")
  ) %>%
  group_by(predator_species_or_source, count_sensitivity, raw_section, site, section_name, period) %>%
  summarise(
    years = n_distinct(year),
    median_exposure = median(exposure, na.rm = TRUE),
    median_exposure_z = median(exposure_z, na.rm = TRUE),
    nearest_predator_site_km = median(nearest_predator_site_km, na.rm = TRUE),
    extrapolated_year_share = mean(extrapolated_dominant_flag, na.rm = TRUE),
    median_extrapolated_exposure_share = median(extrapolated_exposure_share, na.rm = TRUE),
    .groups = "drop"
  )

recent_exposure <- section_exposure %>%
  filter(period %in% c("2005-2013 closure", "2014-2016 marine heatwave", "2017-2025 recent closure")) %>%
  group_by(predator_species_or_source, count_sensitivity, raw_section, site, section_name) %>%
  summarise(
    recent_median_exposure = median(median_exposure, na.rm = TRUE),
    recent_median_exposure_z = median(median_exposure_z, na.rm = TRUE),
    nearest_predator_site_km = median(nearest_predator_site_km, na.rm = TRUE),
    recent_extrapolated_year_share = mean(extrapolated_year_share, na.rm = TRUE),
    recent_median_extrapolated_exposure_share = median(median_extrapolated_exposure_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(section = raw_section) %>%
  group_by(predator_species_or_source) %>%
  mutate(exposure_rank = min_rank(desc(recent_median_exposure))) %>%
  ungroup()

write_csv(availability, file.path(diag_dir, "predator_spatial_exposure_availability.csv"))
write_csv(
  exposure %>%
    select(
      year,
      section,
      section_name,
      predator_group,
      predator_species_or_source,
      count_sensitivity,
      kernel_km,
      exposure,
    exposure_z,
    nearest_site_km = nearest_predator_site_km,
    weighted_mean_distance_km,
    observed_exposure_share,
    interpolated_exposure_share,
    extrapolated_exposure_share,
    observed_count_flag,
    interpolated_flag,
    extrapolated_flag,
    extrapolated_dominant_flag,
      exposure_data_status,
      source_site_count,
      observed_site_count,
      interpolated_site_count,
      extrapolated_site_count,
      source_fill_column_site_count,
      first_source_year,
      last_source_year,
      source_dataset,
      source_file,
      provenance_note
    ),
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv")
)
write_csv(cor_summary, file.path(diag_dir, "predator_spatial_exposure_growth_correlations.csv"))
write_csv(recent_exposure, file.path(diag_dir, "predator_spatial_exposure_recent_by_section.csv"))

p_map <- ggplot() +
  geom_point(
    data = pred_sites_observed %>% distinct(predator_species_or_source, predator_site, pred_lon, pred_lat),
    aes(x = pred_lon, y = pred_lat, colour = predator_species_or_source),
    alpha = 0.55, size = 1.5
  ) +
  geom_point(
    data = centroids,
    aes(x = section_lon, y = section_lat),
    shape = 21, fill = "white", colour = "black", size = 2.4
  ) +
  geom_text(
    data = centroids,
    aes(x = section_lon, y = section_lat, label = raw_section),
    size = 2.4, nudge_y = 0.035
  ) +
  coord_equal() +
  labs(
    x = "Longitude",
    y = "Latitude",
    colour = NULL,
    title = "Raw predator locations and herring section centroids",
    subtitle = "Prototype only: no effort correction or movement model."
  ) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")

p_exposure <- recent_exposure %>%
  filter(predator_species_or_source %in% c("Harbour seal", "Steller sea lion filled total")) %>%
  mutate(section_name = fct_reorder(section_name, recent_median_exposure_z)) %>%
  ggplot(aes(x = recent_median_exposure_z, y = section_name, fill = predator_species_or_source)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.3) +
  labs(
    x = "Recent median exposure, log-z scale, 50 km kernel",
    y = NULL,
    fill = NULL,
    title = "Section-level predator exposure product",
    subtitle = "Higher values are spatially closer to larger HG predator counts."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_corr <- cor_summary %>%
  filter(predator_species_or_source %in% c("Harbour seal", "Steller sea lion filled total")) %>%
  mutate(range_km = factor(range_km)) %>%
  pivot_longer(c(rho_growth, rho_year), names_to = "metric", values_to = "rho") %>%
  mutate(metric = recode(metric, rho_growth = "exposure vs next-year growth", rho_year = "exposure vs year")) %>%
  ggplot(aes(x = range_km, y = rho, fill = metric)) +
  geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  facet_wrap(~ predator_species_or_source) +
  scale_y_continuous(limits = c(-1, 1)) +
  labs(
    x = "Kernel range (km)",
    y = "Spearman rho",
    fill = NULL,
    title = "Exposure correlations are still confounded",
    subtitle = "A useful exposure product must separate spatial exposure from time trend."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_map / (p_exposure | p_corr) +
  plot_layout(heights = c(1, 1.1)) +
  plot_annotation(
    title = "Section-level predator exposure from raw Haida Gwaii sites",
    subtitle = "This supports data-product development, not a promoted predator effect."
  )

ggsave(
  file.path(fig_dir, "predator_spatial_exposure_prototype.pdf"),
  p,
  width = 250, height = 210, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "predator_spatial_exposure_prototype.png"),
  p,
  width = 250, height = 210, units = "mm", dpi = 300
)

availability_md <- availability %>%
  transmute(
    predator = predator_species_or_source,
    sensitivity = count_sensitivity,
    `source span` = paste0(first_source_year, "-", last_source_year),
    `observed years` = observed_years,
    `interpolated years` = interpolated_years,
    `extrapolated years` = extrapolated_years,
    `sites` = predator_sites,
    `source site-years` = source_site_years,
    `max site-year count` = number(max_site_year_count, accuracy = 1)
  )

cor_md <- cor_summary %>%
  filter(range_km == 50) %>%
  transmute(
    predator = predator_species_or_source,
    sensitivity = count_sensitivity,
    `n section-years` = n,
    years,
    sections,
    `rho exposure-growth` = number(rho_growth, accuracy = 0.01),
    `rho exposure-year` = number(rho_year, accuracy = 0.01),
    gate
  )

top_exposure_md <- recent_exposure %>%
  filter(predator_species_or_source %in% c("Harbour seal", "Steller sea lion filled total")) %>%
  group_by(predator_species_or_source) %>%
  slice_min(exposure_rank, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    predator = predator_species_or_source,
    section = section_name,
    rank = exposure_rank,
    `recent exposure z` = number(recent_median_exposure_z, accuracy = 0.01),
    `nearest site km` = number(nearest_predator_site_km, accuracy = 1),
    `dominant extrapolated years` = percent(recent_extrapolated_year_share, accuracy = 1),
    `median extrapolated exposure` = percent(recent_median_extrapolated_exposure_share, accuracy = 1)
  )

lines <- c(
  "# Predator Spatial Exposure Product",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This data product asks whether Haida Gwaii harbour seal and Steller sea lion locations can support a future section-level predator exposure covariate. It is not a predator-effect model.",
  "",
  "## Main Read",
  "",
  "- A section-level exposure product is now explicit about source spans, count sensitivities, annual interpolation, edge extrapolation, and provenance.",
  "- Harbour seal complex-year counts remain collapsed to one complex-year record so repeated subsite rows do not inflate exposure.",
  "- Steller sea lions are split into a raw non-pup sensitivity and a filled-total sensitivity that uses source interpolated/extrapolated fields where present.",
  "- Growth screens below exclude section-years where edge-held counts dominate exposure; remaining screens still do not justify promoting a predator coefficient yet.",
  "- Humpback exposure remains the weak link because the current abundance series is basin-scale rather than section-level.",
  "",
  "## Source And Fill Availability",
  "",
  knitr::kable(availability_md, format = "pipe"),
  "",
  "## 50 km Non-Dominant-Extrapolated Kernel Correlation Screen",
  "",
  knitr::kable(cor_md, format = "pipe"),
  "",
  "## Highest Recent Section Exposures",
  "",
  knitr::kable(top_exposure_md, format = "pipe"),
  "",
  "## Decision",
  "",
  "- Keep predator effects out of the promoted Stan model path until a section-year exposure or demand candidate passes residual screens and smoke tests.",
  "- Use this table as the input for pre-Stan exposure screens and local follow-up targeting.",
  "- Do not reuse the regional combined predator index or observed-spawn pressure ratio for causal inference.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/predator_spatial_exposure_prototype.pdf`",
  "- `Output/diagnostics/predator_spatial_exposure_availability.csv`",
  "- `Output/diagnostics/predator_spatial_exposure_section_year.csv`",
  "- `Output/diagnostics/predator_spatial_exposure_growth_correlations.csv`",
  "- `Output/diagnostics/predator_spatial_exposure_recent_by_section.csv`"
)

writeLines(lines, file.path(diag_dir, "predator_spatial_exposure_prototype.md"))

cat("Saved predator spatial exposure product:\n")
cat("  Output/diagnostics/predator_spatial_exposure_prototype.md\n")
cat("  Output/figures/predator_spatial_exposure_prototype.pdf\n")
