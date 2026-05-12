# ============================================================================
# 07bb_predator_spatial_exposure_prototype.R
# Rough section-level predator exposure prototype from raw haulout/rookery data.
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
  filter(is.finite(section_lat), is.finite(section_lon))

harbour <- read_csv(
  file.path(proj_dir, "Data", "raw", "predators", "Harbour_seal_counts_haulout_locs_BCcoast.csv"),
  show_col_types = FALSE
) %>%
  filter(Region == "Haida Gwaii") %>%
  transmute(
    predator = "Harbour seal",
    predator_site = Complex,
    year = as.integer(Year),
    pred_lon = as.numeric(Longitude),
    pred_lat = as.numeric(Latitude),
    count = as.numeric(complex_count)
  ) %>%
  filter(is.finite(year), is.finite(pred_lon), is.finite(pred_lat), is.finite(count)) %>%
  # complex_count is a complex-level count repeated across subsites; collapse
  # to one complex-year record to avoid artificial exposure inflation.
  group_by(predator, predator_site, year) %>%
  summarise(
    pred_lon = median(pred_lon, na.rm = TRUE),
    pred_lat = median(pred_lat, na.rm = TRUE),
    count = max(count, na.rm = TRUE),
    .groups = "drop"
  )

ssl_raw <- read_csv(
  file.path(proj_dir, "Data", "raw", "predators", "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv"),
  show_col_types = FALSE
)

steller <- ssl_raw %>%
  filter(REGION == "Haida Gwaii") %>%
  transmute(
    predator = "Steller sea lion",
    predator_site = SITE,
    year = as.integer(`SURVEY YEAR`),
    pred_lon = as.numeric(LONGITUDE),
    pred_lat = as.numeric(LATITUDE),
    non_pup = coalesce(
      as_numeric_quiet(`COUNT NON-PUP INTERPOLATED/EXTRAPOLATED`),
      as_numeric_quiet(`COUNT NON-PUP`),
      0
    ),
    pup = coalesce(
      as_numeric_quiet(`COUNT PUP INTERPOLATED/EXTRAPOLATED`),
      as_numeric_quiet(`COUNT PUP`),
      0
    ),
    pre_rookery = coalesce(
      as_numeric_quiet(`COUNT PUP PRE-ROOKERY INTERPOLATED/EXTRAPOLATED`),
      as_numeric_quiet(`COUNT PUP PRE-ROOKERY`),
      0
    ),
    count = non_pup + pup + pre_rookery
  ) %>%
  filter(is.finite(year), is.finite(pred_lon), is.finite(pred_lat), is.finite(count)) %>%
  group_by(predator, predator_site, year) %>%
  summarise(
    pred_lon = median(pred_lon, na.rm = TRUE),
    pred_lat = median(pred_lat, na.rm = TRUE),
    count = sum(count, na.rm = TRUE),
    .groups = "drop"
  )

pred_sites <- bind_rows(harbour, steller)

availability <- pred_sites %>%
  group_by(predator) %>%
  summarise(
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE),
    observed_years = n_distinct(year),
    predator_sites = n_distinct(predator_site),
    site_years = n(),
    total_count_all_site_years = sum(count, na.rm = TRUE),
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
  group_by(predator, range_km, year, section, section_name) %>%
  summarise(
    exposure = sum(exposure_contribution, na.rm = TRUE),
    nearest_predator_site_km = min(distance_km, na.rm = TRUE),
    weighted_mean_distance_km = weighted.mean(distance_km, w = pmax(exposure_contribution, 1e-12), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(predator, range_km) %>%
  mutate(exposure_z = as.numeric(scale(log1p(exposure)))) %>%
  ungroup()

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
  left_join(biomass, by = c("section" = "site", "section_name" = "site_name", "year")) %>%
  filter(is.finite(next_year_growth), is.finite(exposure_z))

cor_summary <- exposure_growth %>%
  group_by(predator, range_km) %>%
  summarise(
    n = n(),
    years = n_distinct(year),
    sections = n_distinct(section),
    rho_growth = cor(exposure_z, next_year_growth, method = "spearman", use = "complete.obs"),
    r_growth = cor(exposure_z, next_year_growth, method = "pearson", use = "complete.obs"),
    rho_year = cor(exposure_z, year, method = "spearman", use = "complete.obs"),
    .groups = "drop"
  )

section_exposure <- exposure %>%
  filter(range_km == 50) %>%
  mutate(period = period_for_year(year)) %>%
  group_by(predator, section, section_name, period) %>%
  summarise(
    years = n_distinct(year),
    median_exposure = median(exposure, na.rm = TRUE),
    median_exposure_z = median(exposure_z, na.rm = TRUE),
    nearest_predator_site_km = median(nearest_predator_site_km, na.rm = TRUE),
    .groups = "drop"
  )

recent_exposure <- section_exposure %>%
  filter(period %in% c("2005-2013 closure", "2014-2016 marine heatwave", "2017-2025 recent closure")) %>%
  group_by(predator, section, section_name) %>%
  summarise(
    recent_median_exposure = median(median_exposure, na.rm = TRUE),
    recent_median_exposure_z = median(median_exposure_z, na.rm = TRUE),
    nearest_predator_site_km = median(nearest_predator_site_km, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(predator) %>%
  mutate(exposure_rank = min_rank(desc(recent_median_exposure))) %>%
  ungroup()

write_csv(availability, file.path(diag_dir, "predator_spatial_exposure_availability.csv"))
write_csv(exposure, file.path(diag_dir, "predator_spatial_exposure_section_year.csv"))
write_csv(cor_summary, file.path(diag_dir, "predator_spatial_exposure_growth_correlations.csv"))
write_csv(recent_exposure, file.path(diag_dir, "predator_spatial_exposure_recent_by_section.csv"))

p_map <- ggplot() +
  geom_point(
    data = pred_sites %>% distinct(predator, predator_site, pred_lon, pred_lat),
    aes(x = pred_lon, y = pred_lat, colour = predator),
    alpha = 0.55, size = 1.5
  ) +
  geom_point(
    data = centroids,
    aes(x = section_lon, y = section_lat),
    shape = 21, fill = "white", colour = "black", size = 2.4
  ) +
  geom_text(
    data = centroids,
    aes(x = section_lon, y = section_lat, label = section),
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
  mutate(section_name = fct_reorder(section_name, recent_median_exposure_z)) %>%
  ggplot(aes(x = recent_median_exposure_z, y = section_name, fill = predator)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.3) +
  labs(
    x = "Recent median exposure, log-z scale, 50 km kernel",
    y = NULL,
    fill = NULL,
    title = "Section-level predator exposure prototype",
    subtitle = "Higher values are spatially closer to larger HG predator counts."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_corr <- cor_summary %>%
  mutate(range_km = factor(range_km)) %>%
  pivot_longer(c(rho_growth, rho_year), names_to = "metric", values_to = "rho") %>%
  mutate(metric = recode(metric, rho_growth = "exposure vs next-year growth", rho_year = "exposure vs year")) %>%
  ggplot(aes(x = range_km, y = rho, fill = metric)) +
  geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  facet_wrap(~ predator) +
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
    title = "Prototype section-level predator exposure from raw Haida Gwaii sites",
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
    predator,
    `first-last` = paste0(first_year, "-", last_year),
    `observed years` = observed_years,
    `sites` = predator_sites,
    `site-years` = site_years,
    `max site-year count` = number(max_site_year_count, accuracy = 1)
  )

cor_md <- cor_summary %>%
  filter(range_km == 50) %>%
  transmute(
    predator,
    `n section-years` = n,
    years,
    `rho exposure-growth` = number(rho_growth, accuracy = 0.01),
    `rho exposure-year` = number(rho_year, accuracy = 0.01)
  )

top_exposure_md <- recent_exposure %>%
  group_by(predator) %>%
  slice_min(exposure_rank, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    predator,
    section = section_name,
    rank = exposure_rank,
    `recent exposure z` = number(recent_median_exposure_z, accuracy = 0.01),
    `nearest site km` = number(nearest_predator_site_km, accuracy = 1)
  )

lines <- c(
  "# Predator Spatial Exposure Prototype",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This prototype asks whether raw Haida Gwaii harbour seal and Steller sea lion locations can support a future section-level predator exposure covariate. It is not a predator-effect model.",
  "",
  "## Main Read",
  "",
  "- A section-level exposure product is feasible for harbour seals and Steller sea lions because both have Haida Gwaii locations and repeated counts.",
  "- The prototype still shows time-trend confounding, so it does not justify promoting a predator coefficient yet.",
  "- The next predator step should be data-product refinement: effort correction, interpolation choices, biologically defensible distance kernels, and possibly season/rookery type separation.",
  "- Humpback exposure remains the weak link because the current abundance series is basin-scale rather than section-level.",
  "",
  "## Raw Data Availability",
  "",
  knitr::kable(availability_md, format = "pipe"),
  "",
  "## 50 km Kernel Correlation Screen",
  "",
  knitr::kable(cor_md, format = "pipe"),
  "",
  "## Highest Recent Section Exposures",
  "",
  knitr::kable(top_exposure_md, format = "pipe"),
  "",
  "## Decision",
  "",
  "- Keep predator effects out of the promoted Stan model path for now.",
  "- Keep this prototype as evidence that a better section-level predator exposure data product is possible.",
  "- Do not reuse the current regional combined predator index for causal inference; it remains too time-confounded.",
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

cat("Saved predator spatial exposure prototype:\n")
cat("  Output/diagnostics/predator_spatial_exposure_prototype.md\n")
cat("  Output/figures/predator_spatial_exposure_prototype.pdf\n")
