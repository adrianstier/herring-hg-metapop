# ============================================================================
# 07be_lead_section_location_map.R
# Map raw spawn-location persistence/loss for lead local sections.
# ============================================================================

library(tidyverse)
library(here)
library(lubridate)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

period_for_year <- function(year) {
  case_when(
    year >= 1951 & year <= 1965 ~ "early",
    year >= 1966 & year <= 1971 ~ "late_reduction",
    year >= 1972 & year <= 2004 ~ "roe",
    year >= 2005 & year <= 2013 ~ "closure",
    year >= 2014 & year <= 2016 ~ "mhw",
    year >= 2017 & year <= 2025 ~ "recent",
    TRUE ~ "other"
  )
}

raw_map <- tribble(
  ~raw_section, ~section_name,
  "006", "Louscoone Inlet",
  "023", "Cumshewa Inlet",
  "024", "Laskeek Bay"
)

raw_spawn <- read_csv(
  file.path(proj_dir, "Data", "raw", "dfo-spawn", "Pacific_herring_spawn_index_data_2025_EN.csv"),
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) %>%
  filter(Region == "HG") %>%
  left_join(raw_map, by = c("Section" = "raw_section")) %>%
  filter(!is.na(section_name)) %>%
  mutate(
    year = as.integer(Year),
    longitude = suppressWarnings(as.numeric(Longitude)),
    latitude = suppressWarnings(as.numeric(Latitude)),
    surface = suppressWarnings(as.numeric(Surface)),
    macrocystis = suppressWarnings(as.numeric(Macrocystis)),
    understory = suppressWarnings(as.numeric(Understory)),
    raw_component_signal = rowSums(across(c(surface, macrocystis, understory)), na.rm = TRUE),
    period_key = period_for_year(year)
  ) %>%
  filter(
    is.finite(year),
    is.finite(longitude),
    is.finite(latitude),
    raw_component_signal > 0,
    period_key != "other"
  )

location_status <- raw_spawn %>%
  group_by(section_name, LocationCode, LocationName) %>%
  summarise(
    longitude = median(longitude, na.rm = TRUE),
    latitude = median(latitude, na.rm = TRUE),
    signal_early = sum(raw_component_signal[period_key == "early"], na.rm = TRUE),
    signal_late_reduction = sum(raw_component_signal[period_key == "late_reduction"], na.rm = TRUE),
    signal_roe = sum(raw_component_signal[period_key == "roe"], na.rm = TRUE),
    signal_closure = sum(raw_component_signal[period_key == "closure"], na.rm = TRUE),
    signal_mhw = sum(raw_component_signal[period_key == "mhw"], na.rm = TRUE),
    signal_recent = sum(raw_component_signal[period_key == "recent"], na.rm = TRUE),
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    signal_historical = signal_early + signal_late_reduction + signal_roe,
    signal_postclosure = signal_closure + signal_mhw + signal_recent,
    recent_share_of_roe = if_else(signal_roe > 0, signal_recent / signal_roe, NA_real_),
    transition_status = case_when(
      signal_recent > 0 & signal_roe > 0 ~ "persisted into recent closure",
      signal_recent > 0 & signal_roe == 0 & signal_historical > 0 ~ "recent after historical gap",
      signal_recent > 0 & signal_historical == 0 ~ "recent-only in raw extract",
      signal_recent == 0 & signal_roe > 0 ~ "lost after roe fishery",
      signal_recent == 0 & signal_historical > 0 ~ "historical only",
      TRUE ~ "low information"
    ),
    map_size = pmax(signal_historical + signal_postclosure, 1),
    label_rank = case_when(
      transition_status == "lost after roe fishery" ~ dense_rank(desc(signal_roe)),
      signal_recent > 0 ~ dense_rank(desc(signal_recent)),
      TRUE ~ NA_integer_
    ),
    label = if_else(
      (transition_status == "lost after roe fishery" & label_rank <= 2) |
        (signal_recent > 0 & label_rank <= 2),
      LocationName,
      NA_character_
    )
  )

status_cols <- c(
  "persisted into recent closure" = "#0072B2",
  "recent after historical gap" = "#009E73",
  "recent-only in raw extract" = "#56B4E9",
  "lost after roe fishery" = "#D55E00",
  "historical only" = "grey50",
  "low information" = "grey75"
)

section_summary <- location_status %>%
  group_by(section_name) %>%
  summarise(
    raw_locations = n(),
    recent_locations = sum(signal_recent > 0, na.rm = TRUE),
    lost_after_roe_locations = sum(transition_status == "lost after roe fishery", na.rm = TRUE),
    recent_signal = sum(signal_recent, na.rm = TRUE),
    roe_signal = sum(signal_roe, na.rm = TRUE),
    recent_to_roe_signal = recent_signal / roe_signal,
    .groups = "drop"
  )

write_csv(location_status, file.path(diag_dir, "lead_section_location_map_points.csv"))

p <- ggplot(location_status, aes(x = longitude, y = latitude)) +
  geom_point(
    aes(fill = transition_status, size = map_size),
    shape = 21,
    colour = "white",
    stroke = 0.35,
    alpha = 0.92
  ) +
  geom_text(
    aes(label = label),
    size = 2.3,
    check_overlap = TRUE,
    vjust = -0.75,
    colour = "grey15",
    na.rm = TRUE
  ) +
  facet_wrap(~ section_name, ncol = 2) +
  coord_equal() +
  scale_fill_manual(values = status_cols, drop = FALSE) +
  scale_size_continuous(
    range = c(2.2, 9),
    trans = "sqrt",
    labels = label_comma(),
    name = "Total raw\nsignal"
  ) +
  labs(
    x = "Longitude",
    y = "Latitude",
    fill = NULL,
    title = "Lead-section raw spawn-location map",
    subtitle = "Locations are classified by roe-era persistence/loss and recent closure signal; point size is total raw component signal.",
    caption = "Raw DFO section-location records only. This is not effort-adjusted and should not be read as proof of absence at unsurveyed sites."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

ggsave(
  file.path(fig_dir, "lead_section_location_map.pdf"),
  p,
  width = 230, height = 170, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "lead_section_location_map.png"),
  p,
  width = 230, height = 170, units = "mm", dpi = 300
)

summary_md <- section_summary %>%
  transmute(
    section = section_name,
    `raw locations` = raw_locations,
    `recent locations` = recent_locations,
    `lost after roe` = lost_after_roe_locations,
    `recent/roe signal` = percent(recent_to_roe_signal, accuracy = 0.1)
  )

lines <- c(
  "# Lead Section Location Map",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This diagnostic maps the same raw HG location-transition screen used in `lead_section_location_transition.md`.",
  "",
  "## Main Read",
  "",
  "- Cumshewa and Louscoone have many roe-era locations that do not appear in the recent closure period.",
  "- Laskeek has more recent raw locations than Cumshewa or Louscoone, but recent signal remains well below the roe-fishery period.",
  "- The map is for local audit targeting: access, substrate/habitat, and local predator exposure. It is not effort-adjusted absence evidence.",
  "",
  "## Section Summary",
  "",
  knitr::kable(summary_md, format = "pipe"),
  "",
  "## Outputs",
  "",
  "- `Output/figures/lead_section_location_map.pdf`",
  "- `Output/diagnostics/lead_section_location_map_points.csv`"
)

writeLines(lines, file.path(diag_dir, "lead_section_location_map.md"))

cat("Saved lead section location map diagnostic:\n")
cat("  Output/diagnostics/lead_section_location_map.md\n")
cat("  Output/figures/lead_section_location_map.pdf\n")
