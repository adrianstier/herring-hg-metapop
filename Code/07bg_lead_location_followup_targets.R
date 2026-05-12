# ============================================================================
# 07bg_lead_location_followup_targets.R
# Prioritized local follow-up targets for lead Haida Gwaii sections.
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
    year >= 1951 & year <= 1965 ~ "1951-1965 early industrial",
    year >= 1966 & year <= 1971 ~ "1966-1971 late reduction",
    year >= 1972 & year <= 2004 ~ "1972-2004 roe fishery",
    year >= 2005 & year <= 2013 ~ "2005-2013 closure",
    year >= 2014 & year <= 2016 ~ "2014-2016 marine heatwave",
    year >= 2017 & year <= 2025 ~ "2017-2025 recent closure",
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
    start_date = suppressWarnings(ymd(StartDate)),
    start_doy = yday(start_date),
    longitude = suppressWarnings(as.numeric(Longitude)),
    latitude = suppressWarnings(as.numeric(Latitude)),
    length_m = suppressWarnings(as.numeric(Length)),
    width_m = suppressWarnings(as.numeric(Width)),
    surface = suppressWarnings(as.numeric(Surface)),
    macrocystis = suppressWarnings(as.numeric(Macrocystis)),
    understory = suppressWarnings(as.numeric(Understory)),
    raw_signal = rowSums(across(c(surface, macrocystis, understory)), na.rm = TRUE),
    period = period_for_year(year)
  ) %>%
  filter(is.finite(year), raw_signal > 0)

location_transitions <- read_csv(
  file.path(diag_dir, "lead_section_location_transitions.csv"),
  show_col_types = FALSE,
  col_types = cols(.default = col_guess(), LocationCode = col_character())
)

location_map <- read_csv(
  file.path(diag_dir, "lead_section_location_map_points.csv"),
  show_col_types = FALSE,
  col_types = cols(.default = col_guess(), LocationCode = col_character())
) %>%
  select(section_name, LocationCode, LocationName, longitude, latitude)

predator_proximity <- read_csv(
  file.path(diag_dir, "lead_spawn_location_predator_proximity.csv"),
  show_col_types = FALSE,
  col_types = cols(.default = col_guess(), LocationCode = col_character())
) %>%
  mutate(
    predator_key = case_when(
      predator == "Harbour seal" ~ "seal",
      predator == "Steller sea lion" ~ "ssl",
      TRUE ~ str_replace_all(str_to_lower(predator), "[^a-z0-9]+", "_")
    )
  ) %>%
  select(
    section_name, LocationCode, LocationName, predator_key,
    nearest_predator_site, nearest_distance_km, exposure_50_z
  ) %>%
  pivot_wider(
    names_from = predator_key,
    values_from = c(nearest_predator_site, nearest_distance_km, exposure_50_z),
    names_glue = "{predator_key}_{.value}"
  )

location_metadata <- raw_spawn %>%
  group_by(section_name, LocationCode, LocationName) %>%
  summarise(
    raw_records = n(),
    raw_years = n_distinct(year),
    first_raw_year = min(year, na.rm = TRUE),
    last_raw_year = max(year, na.rm = TRUE),
    median_start_doy = median(start_doy, na.rm = TRUE),
    median_length_m = median(length_m, na.rm = TRUE),
    median_width_m = median(width_m, na.rm = TRUE),
    total_surface = sum(surface, na.rm = TRUE),
    total_macrocystis = sum(macrocystis, na.rm = TRUE),
    total_understory = sum(understory, na.rm = TRUE),
    methods = paste(sort(unique(Method[!is.na(Method) & Method != ""])), collapse = "; "),
    active_periods = paste(sort(unique(period[period != "other"])), collapse = "; "),
    .groups = "drop"
  ) %>%
  mutate(
    total_substrate_signal = total_surface + total_macrocystis + total_understory,
    surface_share = if_else(total_substrate_signal > 0, total_surface / total_substrate_signal, NA_real_),
    macrocystis_share = if_else(total_substrate_signal > 0, total_macrocystis / total_substrate_signal, NA_real_),
    understory_share = if_else(total_substrate_signal > 0, total_understory / total_substrate_signal, NA_real_),
    dominant_substrate = case_when(
      is.na(total_substrate_signal) | total_substrate_signal <= 0 ~ "unknown",
      total_surface >= total_macrocystis & total_surface >= total_understory ~ "surface",
      total_macrocystis >= total_surface & total_macrocystis >= total_understory ~ "macrocystis",
      total_understory >= total_surface & total_understory >= total_macrocystis ~ "understory",
      TRUE ~ "mixed"
    )
  )

followup_targets <- location_transitions %>%
  left_join(location_metadata, by = c("section_name", "LocationCode", "LocationName")) %>%
  left_join(location_map, by = c("section_name", "LocationCode", "LocationName")) %>%
  left_join(predator_proximity, by = c("section_name", "LocationCode", "LocationName")) %>%
  mutate(
    signal_roe = replace_na(signal_roe, 0),
    signal_recent = replace_na(signal_recent, 0),
    recent_share_of_roe = if_else(signal_roe > 0, signal_recent / signal_roe, NA_real_),
    loss_priority = transition_status == "lost after roe fishery" & signal_roe > quantile(signal_roe, 0.60, na.rm = TRUE),
    persistence_priority = transition_status == "persisted into recent closure" &
      signal_recent > quantile(signal_recent[signal_recent > 0], 0.50, na.rm = TRUE),
    recolonization_priority = transition_status == "recent after historical gap",
    predator_priority = coalesce(seal_exposure_50_z, -Inf) > 1 | coalesce(ssl_exposure_50_z, -Inf) > 1,
    priority_class = case_when(
      loss_priority & predator_priority ~ "lost high-signal location with high predator exposure",
      loss_priority ~ "lost high-signal roe-era location",
      persistence_priority & predator_priority ~ "recent persistence with high predator exposure",
      persistence_priority ~ "recent persistence anchor",
      recolonization_priority ~ "possible recolonization after historical gap",
      predator_priority ~ "high predator-exposure local check",
      transition_status == "lost after roe fishery" ~ "lower-signal lost location",
      transition_status == "persisted into recent closure" ~ "lower-signal persistence location",
      TRUE ~ "context location"
    ),
    priority_score = case_when(
      loss_priority ~ 4,
      persistence_priority ~ 3,
      recolonization_priority ~ 3,
      TRUE ~ 1
    ) +
      pmin(log1p(signal_roe) / 4, 3) +
      pmin(log1p(signal_recent) / 4, 2) +
      if_else(predator_priority, 1, 0) +
      if_else(!is.na(longitude) & !is.na(latitude), 0.25, -0.5),
    followup_question = case_when(
      str_detect(priority_class, "^lost") ~
        "Was this roe-era spawn location still surveyed/accessed after closure, and did substrate or local disturbance change?",
      str_detect(priority_class, "persistence") ~
        "Why did this location retain recent spawn when nearby historical locations did not?",
      str_detect(priority_class, "recolonization") ~
        "Is this a true recolonization signal, a survey-coverage artifact, or a location-name/code change?",
      predator_priority ~
        "Does local predator use overlap the spawn window closely enough to matter biologically?",
      TRUE ~
        "Use as supporting context for local section interpretation."
    )
  ) %>%
  arrange(desc(priority_score), section_name, LocationName) %>%
  mutate(priority_rank = row_number()) %>%
  select(
    priority_rank, section_name, LocationCode, LocationName, priority_class,
    transition_status, followup_question,
    signal_roe, signal_recent, recent_share_of_roe,
    raw_records, raw_years, first_raw_year, last_raw_year,
    median_start_doy, median_length_m, median_width_m,
    dominant_substrate, surface_share, macrocystis_share, understory_share,
    methods, active_periods,
    longitude, latitude,
    seal_nearest_predator_site, seal_nearest_distance_km, seal_exposure_50_z,
    ssl_nearest_predator_site, ssl_nearest_distance_km, ssl_exposure_50_z,
    priority_score
  )

top_targets <- followup_targets %>%
  slice_head(n = 20)

target_plot_df <- top_targets %>%
  mutate(
    plot_label = paste0(priority_rank, ". ", LocationName, " (", section_name, ")"),
    plot_label = fct_reorder(plot_label, priority_score)
  )

p <- ggplot(target_plot_df, aes(x = plot_label, y = priority_score, fill = priority_class)) +
  geom_col(width = 0.7) +
  geom_text(
    aes(label = paste0("roe ", comma(round(signal_roe)), "; recent ", comma(round(signal_recent)))),
    hjust = -0.05,
    size = 2.4,
    colour = "grey20"
  ) +
  coord_flip(clip = "off") +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.28))) +
  scale_fill_brewer(palette = "Dark2") +
  labs(
    x = NULL,
    y = "Priority score",
    title = "Named local follow-up targets",
    subtitle = "Ranked raw spawn locations in Cumshewa, Laskeek, and Louscoone. Lost-location labels are not effort-adjusted absence evidence.",
    fill = "Priority class"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.margin = margin(6, 40, 6, 6)
  )

write_csv(
  followup_targets,
  file.path(diag_dir, "lead_location_followup_targets.csv")
)

ggsave(
  file.path(fig_dir, "lead_location_followup_targets.pdf"),
  p,
  width = 220, height = 180, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "lead_location_followup_targets.png"),
  p,
  width = 220, height = 180, units = "mm", dpi = 300
)

top_targets_md <- top_targets %>%
  transmute(
    Rank = priority_rank,
    Section = section_name,
    Location = LocationName,
    Class = priority_class,
    `Roe signal` = comma(round(signal_roe, 1)),
    `Recent signal` = comma(round(signal_recent, 1)),
    `Seal km` = round(seal_nearest_distance_km, 1),
    `SSL km` = round(ssl_nearest_distance_km, 1),
    `Follow-up question` = followup_question
  )

section_counts <- followup_targets %>%
  count(section_name, priority_class, name = "locations") %>%
  arrange(section_name, desc(locations), priority_class)

lines <- c(
  "# Lead Location Follow-up Targets",
  "",
  paste0("Generated: ", Sys.time()),
  "",
  "This table turns the local raw spawn-location audits into a practical target list for Cumshewa, Laskeek, and Louscoone.",
  "It combines location-transition status, raw spawn-method/substrate metadata, coordinates, and nearest harbour seal / Steller sea lion proximity.",
  "",
  "Important caveat: a `lost after roe fishery` label means no recent positive raw spawn record in this extract. It is not proof of true absence, because survey access and local non-survey decisions remain unresolved.",
  "",
  "## Top Targets",
  "",
  knitr::kable(top_targets_md, format = "pipe"),
  "",
  "## Counts by Section and Priority Class",
  "",
  knitr::kable(section_counts, format = "pipe"),
  "",
  "## Interpretation",
  "",
  "- The highest-value follow-up locations are high roe-era signal locations that do not show recent positive raw spawn records.",
  "- Persistent recent locations are equally important because they identify candidate refugia or remaining local anchors.",
  "- Predator proximity is included as local context only; the current screen does not show that lost locations are more predator-exposed than persisted locations.",
  "- The next data need is effort/access confirmation for these named locations, especially places where Haida access concerns may explain non-survey rather than absence.",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/lead_location_followup_targets.csv`",
  "- `Output/diagnostics/lead_location_followup_targets.md`",
  "- `Output/figures/lead_location_followup_targets.pdf`"
)

writeLines(lines, file.path(diag_dir, "lead_location_followup_targets.md"))

cat("Saved:\n")
cat("  Output/diagnostics/lead_location_followup_targets.csv\n")
cat("  Output/diagnostics/lead_location_followup_targets.md\n")
cat("  Output/figures/lead_location_followup_targets.pdf\n")
