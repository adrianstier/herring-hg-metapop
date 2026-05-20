# ============================================================================
# 07bd_lead_section_location_transition.R
# Location-level persistence/loss screen for lead local sections.
# ============================================================================

library(tidyverse)
library(here)
library(lubridate)
library(patchwork)
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

period_levels <- c(
  "1951-1965 early industrial",
  "1966-1971 late reduction",
  "1972-2004 roe fishery",
  "2005-2013 closure",
  "2014-2016 marine heatwave",
  "2017-2025 recent closure"
)

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
    surface = suppressWarnings(as.numeric(Surface)),
    macrocystis = suppressWarnings(as.numeric(Macrocystis)),
    understory = suppressWarnings(as.numeric(Understory)),
    raw_component_signal = rowSums(across(c(surface, macrocystis, understory)), na.rm = TRUE),
    period = factor(period_for_year(year), levels = period_levels)
  ) %>%
  filter(is.finite(year), raw_component_signal > 0)

location_period <- raw_spawn %>%
  group_by(section_name, LocationCode, LocationName, period) %>%
  summarise(
    records = n(),
    years = n_distinct(year),
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE),
    total_signal = sum(raw_component_signal, na.rm = TRUE),
    median_start_doy = median(start_doy, na.rm = TRUE),
    .groups = "drop"
  )

location_wide <- location_period %>%
  select(section_name, LocationCode, LocationName, period, total_signal) %>%
  mutate(period_key = case_when(
    str_detect(as.character(period), "early") ~ "early",
    str_detect(as.character(period), "late reduction") ~ "late_reduction",
    str_detect(as.character(period), "roe") ~ "roe",
    str_detect(as.character(period), "2005") ~ "closure",
    str_detect(as.character(period), "2014") ~ "mhw",
    str_detect(as.character(period), "recent") ~ "recent",
    TRUE ~ "other"
  )) %>%
  select(-period) %>%
  pivot_wider(
    names_from = period_key,
    values_from = total_signal,
    values_fill = 0,
    names_prefix = "signal_"
  ) %>%
  mutate(
    across(starts_with("signal_"), ~ replace_na(.x, 0)),
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
    loss_score = log1p(signal_roe) - log1p(signal_recent)
  ) %>%
  arrange(section_name, desc(signal_historical))

section_transition <- location_wide %>%
  group_by(section_name) %>%
  summarise(
    raw_locations = n(),
    historical_locations = sum(signal_historical > 0, na.rm = TRUE),
    recent_locations = sum(signal_recent > 0, na.rm = TRUE),
    lost_after_roe_locations = sum(transition_status == "lost after roe fishery", na.rm = TRUE),
    persisted_recent_locations = sum(transition_status == "persisted into recent closure", na.rm = TRUE),
    recent_after_gap_locations = sum(transition_status == "recent after historical gap", na.rm = TRUE),
    roe_signal = sum(signal_roe, na.rm = TRUE),
    recent_signal = sum(signal_recent, na.rm = TRUE),
    recent_to_roe_signal = recent_signal / roe_signal,
    top_lost_location = {
      lost <- transition_status == "lost after roe fishery"
      if (any(lost, na.rm = TRUE)) {
        LocationName[lost][which.max(signal_roe[lost])]
      } else {
        NA_character_
      }
    },
    top_recent_location = {
      recent <- signal_recent > 0
      if (any(recent, na.rm = TRUE)) {
        LocationName[recent][which.max(signal_recent[recent])]
      } else {
        NA_character_
      }
    },
    .groups = "drop"
  ) %>%
  mutate(
    recent_to_roe_signal = if_else(roe_signal > 0, recent_to_roe_signal, NA_real_),
    raw_extract_note = if_else(
      section_name == "Skidegate Inlet",
      "not available in raw HG section extract",
      "raw HG section extract available"
    )
  )

top_location_transitions <- location_wide %>%
  group_by(section_name) %>%
  slice_max(signal_historical + signal_postclosure, n = 12, with_ties = FALSE) %>%
  ungroup()

write_csv(location_period, file.path(diag_dir, "lead_section_location_periods.csv"))
write_csv(location_wide, file.path(diag_dir, "lead_section_location_transitions.csv"))
write_csv(section_transition, file.path(diag_dir, "lead_section_location_transition_summary.csv"))

p_heat <- top_location_transitions %>%
  select(section_name, LocationName, starts_with("signal_")) %>%
  select(-signal_historical, -signal_postclosure) %>%
  pivot_longer(starts_with("signal_"), names_to = "period_key", values_to = "signal") %>%
  mutate(
    period_key = str_remove(period_key, "^signal_"),
    period_key = factor(
      period_key,
      levels = c("early", "late_reduction", "roe", "closure", "mhw", "recent"),
      labels = c("1951-65", "1966-71", "1972-04", "2005-13", "2014-16", "2017-25")
    ),
    LocationName = fct_reorder(LocationName, signal, .fun = sum)
  ) %>%
  ggplot(aes(x = period_key, y = LocationName, fill = log10(signal + 1))) +
  geom_tile(colour = "white", linewidth = 0.25) +
  facet_wrap(~ section_name, scales = "free_y", ncol = 1) +
  scale_fill_viridis_c(option = "C", name = "log10\nsignal + 1") +
  labs(
    x = NULL,
    y = NULL,
    title = "Location-level spawn signal by period",
    subtitle = "Top raw locations per section; raw component signal sums Surface, Macrocystis, and Understory."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "bottom"
  )

p_status <- location_wide %>%
  count(section_name, transition_status) %>%
  ggplot(aes(x = n, y = section_name, fill = transition_status)) +
  geom_col(width = 0.72) +
  labs(
    x = "Raw locations",
    y = NULL,
    fill = NULL,
    title = "Location transition classes",
    subtitle = "Classified from raw HG section extract, not from model states."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_ratio <- section_transition %>%
  ggplot(aes(x = recent_to_roe_signal, y = fct_reorder(section_name, recent_to_roe_signal))) +
  geom_col(fill = "#0072B2", width = 0.72) +
  scale_x_continuous(labels = percent) +
  labs(
    x = "Recent closure raw signal / roe-fishery raw signal",
    y = NULL,
    title = "Raw recent signal is far below roe-fishery signal",
    subtitle = "Useful local context; not adjusted for survey effort or method."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- p_heat | (p_status / p_ratio) +
  plot_layout(widths = c(1.2, 0.9)) +
  plot_annotation(
    title = "Lead-section raw spawn-location transitions",
    subtitle = "Louscoone, Cumshewa, and Laskeek have raw HG section-location data; Skidegate remains model-only for this local raw extract."
  )

ggsave(
  file.path(fig_dir, "lead_section_location_transition.pdf"),
  p,
  width = 260, height = 210, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "lead_section_location_transition.png"),
  p,
  width = 260, height = 210, units = "mm", dpi = 300
)

summary_md <- section_transition %>%
  transmute(
    section = section_name,
    `raw locations` = raw_locations,
    `recent locations` = recent_locations,
    `lost after roe` = lost_after_roe_locations,
    persisted = persisted_recent_locations,
    `recent/roe signal` = percent(recent_to_roe_signal, accuracy = 0.1),
    `top lost location` = top_lost_location,
    `top recent location` = top_recent_location
  )

lost_md <- location_wide %>%
  filter(transition_status == "lost after roe fishery") %>%
  group_by(section_name) %>%
  slice_max(signal_roe, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    section = section_name,
    location = LocationName,
    `roe signal` = number(signal_roe, accuracy = 1),
    `recent signal` = number(signal_recent, accuracy = 1),
    `loss score` = number(loss_score, accuracy = 0.1)
  )

recent_md <- location_wide %>%
  filter(signal_recent > 0) %>%
  group_by(section_name) %>%
  slice_max(signal_recent, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    section = section_name,
    location = LocationName,
    status = transition_status,
    `roe signal` = number(signal_roe, accuracy = 1),
    `recent signal` = number(signal_recent, accuracy = 1),
    `recent/roe` = percent(recent_share_of_roe, accuracy = 0.1)
  )

lines <- c(
  "# Lead Section Location Transition",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This diagnostic examines raw HG section-location records for Louscoone, Cumshewa, and Laskeek. Skidegate remains important in the model, but it is not available in this raw HG section extract used here.",
  "",
  "## Main Read",
  "",
  "- Louscoone, Cumshewa, and Laskeek all have many historical raw locations with much lower recent raw signal than roe-fishery signal.",
  "- This strengthens the interpretation that local mechanism work should ask where spawn persisted, disappeared, or shifted within sections, not only whether a section total changed.",
  "- The result is not survey-effort adjusted; use it as a local audit target list.",
  "",
  "## Section Summary",
  "",
  knitr::kable(summary_md, format = "pipe"),
  "",
  "## Largest Lost Roe-Era Locations",
  "",
  knitr::kable(lost_md, format = "pipe"),
  "",
  "## Largest Recent Locations",
  "",
  knitr::kable(recent_md, format = "pipe"),
  "",
  "## Decision",
  "",
  "- For Louscoone and Cumshewa, review local survey access, substrate, and predator exposure at the named lost and persistent locations.",
  "- For Laskeek, the local raw data support a portfolio-erosion story with continued but reduced recent spawn at multiple locations.",
  "- Do not use this as evidence of biological absence at unsurveyed locations without effort metadata.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/lead_section_location_transition.pdf`",
  "- `Output/diagnostics/lead_section_location_transition_summary.csv`",
  "- `Output/diagnostics/lead_section_location_transitions.csv`",
  "- `Output/diagnostics/lead_section_location_periods.csv`"
)

writeLines(lines, file.path(diag_dir, "lead_section_location_transition.md"))

cat("Saved lead section location transition diagnostic:\n")
cat("  Output/diagnostics/lead_section_location_transition.md\n")
cat("  Output/figures/lead_section_location_transition.pdf\n")
