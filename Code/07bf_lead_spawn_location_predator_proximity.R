# ============================================================================
# 07bf_lead_spawn_location_predator_proximity.R
# Local predator proximity screen for lead-section raw spawn locations.
# ============================================================================

library(tidyverse)
library(here)
library(scales)
library(patchwork)

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

as_numeric_quiet <- function(x) {
  suppressWarnings(as.numeric(x))
}

spawn_locations <- read_csv(
  file.path(diag_dir, "lead_section_location_map_points.csv"),
  show_col_types = FALSE
) %>%
  filter(is.finite(longitude), is.finite(latitude)) %>%
  select(
    section_name, LocationCode, LocationName, longitude, latitude,
    transition_status, signal_roe, signal_recent, signal_historical,
    signal_postclosure
  )

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

pred_sites <- bind_rows(harbour, steller) %>%
  mutate(period = if_else(year >= 2005, "postclosure_observed", "historical_observed"))

pred_recent_sites <- pred_sites %>%
  filter(year >= 2005) %>%
  group_by(predator, predator_site) %>%
  summarise(
    pred_lon = median(pred_lon, na.rm = TRUE),
    pred_lat = median(pred_lat, na.rm = TRUE),
    recent_years = n_distinct(year),
    recent_count = median(count, na.rm = TRUE),
    max_recent_count = max(count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(recent_count > 0)

distance_tbl <- spawn_locations %>%
  crossing(pred_recent_sites) %>%
  mutate(
    distance_km = haversine_km(longitude, latitude, pred_lon, pred_lat),
    exposure_25 = recent_count * exp(-distance_km / 25),
    exposure_50 = recent_count * exp(-distance_km / 50),
    exposure_100 = recent_count * exp(-distance_km / 100)
  )

nearest_tbl <- distance_tbl %>%
  group_by(section_name, LocationCode, LocationName, predator) %>%
  summarise(
    nearest_predator_site = predator_site[which.min(distance_km)],
    nearest_distance_km = min(distance_km, na.rm = TRUE),
    exposure_25 = sum(exposure_25, na.rm = TRUE),
    exposure_50 = sum(exposure_50, na.rm = TRUE),
    exposure_100 = sum(exposure_100, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(spawn_locations, by = c("section_name", "LocationCode", "LocationName")) %>%
  group_by(predator) %>%
  mutate(exposure_50_z = as.numeric(scale(log1p(exposure_50)))) %>%
  ungroup()

status_summary <- nearest_tbl %>%
  group_by(predator, transition_status) %>%
  summarise(
    n_locations = n(),
    median_nearest_distance_km = median(nearest_distance_km, na.rm = TRUE),
    median_exposure_50_z = median(exposure_50_z, na.rm = TRUE),
    .groups = "drop"
  )

section_summary <- nearest_tbl %>%
  group_by(predator, section_name) %>%
  summarise(
    n_locations = n(),
    median_nearest_distance_km = median(nearest_distance_km, na.rm = TRUE),
    median_exposure_50_z = median(exposure_50_z, na.rm = TRUE),
    lost_exposure_50_z = median(exposure_50_z[transition_status == "lost after roe fishery"], na.rm = TRUE),
    recent_exposure_50_z = median(exposure_50_z[signal_recent > 0], na.rm = TRUE),
    .groups = "drop"
  )

write_csv(nearest_tbl, file.path(diag_dir, "lead_spawn_location_predator_proximity.csv"))
write_csv(status_summary, file.path(diag_dir, "lead_spawn_location_predator_proximity_by_status.csv"))
write_csv(section_summary, file.path(diag_dir, "lead_spawn_location_predator_proximity_by_section.csv"))

p_dist <- nearest_tbl %>%
  ggplot(aes(x = transition_status, y = nearest_distance_km, fill = transition_status)) +
  geom_boxplot(outlier.alpha = 0.45, width = 0.65) +
  facet_wrap(~ predator, scales = "free_y") +
  coord_flip() +
  labs(
    x = NULL,
    y = "Nearest post-2005 predator site distance (km)",
    title = "Lead spawn locations: predator proximity by transition class",
    subtitle = "Distances use raw Haida Gwaii harbour seal and Steller sea lion sites with post-2005 observations."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

p_exposure <- nearest_tbl %>%
  ggplot(aes(x = exposure_50_z, y = fct_reorder(LocationName, exposure_50_z), colour = transition_status)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(aes(size = signal_historical + signal_postclosure), alpha = 0.85) +
  facet_grid(section_name ~ predator, scales = "free_y", space = "free_y") +
  scale_size_continuous(range = c(1.5, 6), trans = "sqrt", guide = "none") +
  labs(
    x = "Recent 50 km kernel exposure z-score",
    y = NULL,
    colour = NULL,
    title = "Local exposure screen by spawn location",
    subtitle = "This is a proximity/exposure audit target, not evidence of predator causation."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

p <- p_dist / p_exposure +
  plot_layout(heights = c(0.85, 1.4)) +
  plot_annotation(
    title = "Lead-section spawn-location predator proximity screen",
    subtitle = "Local predator data can now be linked to raw spawn locations, but the result remains descriptive."
  )

ggsave(
  file.path(fig_dir, "lead_spawn_location_predator_proximity.pdf"),
  p,
  width = 240, height = 230, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "lead_spawn_location_predator_proximity.png"),
  p,
  width = 240, height = 230, units = "mm", dpi = 300
)

status_md <- status_summary %>%
  transmute(
    predator,
    status = transition_status,
    n = n_locations,
    `median nearest km` = number(median_nearest_distance_km, accuracy = 0.1),
    `median exposure z` = number(median_exposure_50_z, accuracy = 0.01)
  )

section_md <- section_summary %>%
  transmute(
    predator,
    section = section_name,
    n = n_locations,
    `median nearest km` = number(median_nearest_distance_km, accuracy = 0.1),
    `median exposure z` = number(median_exposure_50_z, accuracy = 0.01),
    `lost exposure z` = number(lost_exposure_50_z, accuracy = 0.01),
    `recent exposure z` = number(recent_exposure_50_z, accuracy = 0.01)
  )

lines <- c(
  "# Lead Spawn-Location Predator Proximity",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This diagnostic links geocoded raw spawn locations in Louscoone, Cumshewa, and Laskeek to post-2005 harbour seal and Steller sea lion sites.",
  "",
  "## Main Read",
  "",
  "- Local predator proximity can be calculated for raw spawn locations, which makes predator work more spatially useful than a basin-wide index.",
  "- This is still descriptive: post-2005 predator observations do not reconstruct predator exposure during historical loss years.",
  "- Use this to target local follow-up on access, habitat/substrate, and exposure; do not treat it as predator-effect evidence.",
  "",
  "## By Transition Status",
  "",
  knitr::kable(status_md, format = "pipe"),
  "",
  "## By Section",
  "",
  knitr::kable(section_md, format = "pipe"),
  "",
  "## Outputs",
  "",
  "- `Output/figures/lead_spawn_location_predator_proximity.pdf`",
  "- `Output/diagnostics/lead_spawn_location_predator_proximity.csv`",
  "- `Output/diagnostics/lead_spawn_location_predator_proximity_by_status.csv`",
  "- `Output/diagnostics/lead_spawn_location_predator_proximity_by_section.csv`"
)

writeLines(lines, file.path(diag_dir, "lead_spawn_location_predator_proximity.md"))

cat("Saved lead spawn-location predator proximity diagnostic:\n")
cat("  Output/diagnostics/lead_spawn_location_predator_proximity.md\n")
cat("  Output/figures/lead_spawn_location_predator_proximity.pdf\n")
