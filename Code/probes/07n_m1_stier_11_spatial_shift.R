# ============================================================================
# 07n_m1_stier_11_spatial_shift.R
# Biomass-weighted spatial shift screen for m1_stier_11 posterior medians.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

section_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
)

section_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_section_1951_2025.csv"),
  show_col_types = FALSE
) %>%
  filter(in_model) %>%
  group_by(section, section_name) %>%
  summarise(
    latitude = median(latitude, na.rm = TRUE),
    longitude = median(longitude, na.rm = TRUE),
    .groups = "drop"
  )

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
site_lookup <- tibble(
  site = seq_along(keep_sections),
  section = keep_sections
)

section_geo <- site_lookup %>%
  left_join(section_cov, by = "section")

weighted_space <- section_year %>%
  left_join(section_geo, by = "site") %>%
  group_by(year, period) %>%
  summarise(
    total_biomass = sum(median, na.rm = TRUE),
    biomass_weighted_latitude = weighted.mean(latitude, median, na.rm = TRUE),
    biomass_weighted_longitude = weighted.mean(longitude, median, na.rm = TRUE),
    northern_share = sum(median[latitude >= median(latitude, na.rm = TRUE)], na.rm = TRUE) / total_biomass,
    eastern_share = sum(median[longitude >= median(longitude, na.rm = TRUE)], na.rm = TRUE) / total_biomass,
    .groups = "drop"
  )

period_space <- weighted_space %>%
  group_by(period) %>%
  summarise(
    median_total_biomass = median(total_biomass, na.rm = TRUE),
    median_weighted_latitude = median(biomass_weighted_latitude, na.rm = TRUE),
    median_weighted_longitude = median(biomass_weighted_longitude, na.rm = TRUE),
    median_northern_share = median(northern_share, na.rm = TRUE),
    median_eastern_share = median(eastern_share, na.rm = TRUE),
    .groups = "drop"
  )

recent_section_share <- section_year %>%
  left_join(section_geo, by = "site") %>%
  filter(period == "2017-2025 recent closure") %>%
  group_by(site, site_name, focal_status, latitude, longitude) %>%
  summarise(recent_median_biomass = median(median, na.rm = TRUE), .groups = "drop") %>%
  mutate(recent_share = recent_median_biomass / sum(recent_median_biomass, na.rm = TRUE)) %>%
  arrange(desc(recent_share))

p_map <- ggplot() +
  geom_point(
    data = section_geo,
    aes(x = longitude, y = latitude),
    colour = "grey65",
    size = 2
  ) +
  geom_point(
    data = recent_section_share,
    aes(x = longitude, y = latitude, size = recent_share, colour = focal_status),
    alpha = 0.85
  ) +
  geom_path(
    data = weighted_space,
    aes(x = biomass_weighted_longitude, y = biomass_weighted_latitude),
    colour = "#C47F2C",
    linewidth = 0.7,
    alpha = 0.85
  ) +
  geom_point(
    data = period_space,
    aes(x = median_weighted_longitude, y = median_weighted_latitude),
    colour = "#8B1A1A",
    size = 2
  ) +
  scale_size_continuous(labels = percent, range = c(2, 9)) +
  scale_colour_manual(values = c(focal_9 = "#176B87", dropped_from_focal = "#C47F2C")) +
  labs(
    x = "Longitude",
    y = "Latitude",
    size = "Recent share",
    colour = NULL,
    title = "Recent biomass geography and centroid path",
    subtitle = "Grey = sections; blue/orange = recent section shares; red = period centroids."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_lat <- ggplot(weighted_space, aes(x = year, y = biomass_weighted_latitude)) +
  geom_line(colour = "#176B87", linewidth = 0.7) +
  geom_point(aes(size = total_biomass), colour = "#176B87", alpha = 0.6) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  scale_size_continuous(labels = label_comma(), range = c(1, 5)) +
  labs(
    x = NULL,
    y = "Biomass-weighted latitude",
    size = "Total biomass",
    title = "North-south center of biomass"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_share <- weighted_space %>%
  select(year, northern_share, eastern_share) %>%
  pivot_longer(-year, names_to = "metric", values_to = "share") %>%
  mutate(metric = recode(metric, northern_share = "Northern share", eastern_share = "Eastern share")) %>%
  ggplot(aes(x = year, y = share, colour = metric)) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey60") +
  geom_line(linewidth = 0.7) +
  scale_y_continuous(labels = percent) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  scale_colour_manual(values = c("Northern share" = "#176B87", "Eastern share" = "#C47F2C")) +
  labs(
    x = "Year",
    y = "Biomass share",
    colour = NULL,
    title = "Directional biomass shares"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_map | (p_lat / p_share)

ggsave(
  file.path(fig_dir, "m1_stier_11_spatial_shift.pdf"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_spatial_shift.png"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(weighted_space, file.path(diag_dir, "m1_stier_11_biomass_weighted_space_by_year.csv"))
write_csv(period_space, file.path(diag_dir, "m1_stier_11_biomass_weighted_space_by_period.csv"))
write_csv(recent_section_share, file.path(diag_dir, "m1_stier_11_recent_section_spatial_share.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

early <- period_space %>% filter(period == "1951-1965 early industrial")
recent <- period_space %>% filter(period == "2017-2025 recent closure")

lines <- c(
  "# M1 Stier 11 Spatial Shift Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Period-Level Shift",
  "",
  paste0(
    "- Early industrial biomass-weighted latitude/longitude: ",
    fmt(early$median_weighted_latitude, 3),
    ", ",
    fmt(early$median_weighted_longitude, 3),
    "."
  ),
  paste0(
    "- Recent closure biomass-weighted latitude/longitude: ",
    fmt(recent$median_weighted_latitude, 3),
    ", ",
    fmt(recent$median_weighted_longitude, 3),
    "."
  ),
  paste0(
    "- Recent northern/eastern biomass shares: ",
    percent(recent$median_northern_share, accuracy = 1),
    " / ",
    percent(recent$median_eastern_share, accuracy = 1),
    "."
  ),
  "",
  "## Largest Recent Spatial Shares",
  "",
  paste0(
    "- ",
    head(recent_section_share$site_name, 5),
    ": ",
    percent(head(recent_section_share$recent_share, 5), accuracy = 1),
    " of recent posterior biomass."
  ),
  "",
  "## Interpretation",
  "",
  "- This is a coarse geography diagnostic from section centroids and posterior medians.",
  "- It helps show whether portfolio erosion is also a geographic redistribution.",
  "- Use this as a visual/context screen, not a mechanistic spatial model.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_spatial_shift.pdf`",
  "- `Output/diagnostics/m1_stier_11_biomass_weighted_space_by_year.csv`",
  "- `Output/diagnostics/m1_stier_11_recent_section_spatial_share.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_spatial_shift.md"))

cat("Saved spatial shift diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_spatial_shift.md\n")
cat("  Output/figures/m1_stier_11_spatial_shift.pdf\n")
