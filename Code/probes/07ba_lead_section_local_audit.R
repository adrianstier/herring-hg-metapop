# ============================================================================
# 07ba_lead_section_local_audit.R
# Local survey/context audit for lead mechanism and portfolio-concern sections.
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

target_sections <- c(
  "Louscoone Inlet",
  "Cumshewa Inlet",
  "Laskeek Bay",
  "Skidegate Inlet"
)

spawn <- read_csv(
  file.path(proj_dir, "Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
) %>%
  filter(section_name %in% target_sections) %>%
  mutate(
    period = factor(period_for_year(year), levels = period_levels),
    surveyed = totalrecords > 0,
    positive = surveyed & spawn_index_tonnes > 0,
    zero_record = surveyed & spawn_index_tonnes <= 0,
    survey_status = case_when(
      positive ~ "positive",
      zero_record ~ "zero record",
      TRUE ~ "missing/unsurveyed"
    )
  )

section_action <- read_csv(file.path(diag_dir, "section_action_matrix.csv"), show_col_types = FALSE) %>%
  filter(site_name %in% target_sections) %>%
  select(site_name, talk_use, problem_axis, evidence_grade, driver_hypothesis, next_analysis)

annual_summary <- spawn %>%
  group_by(section, section_name) %>%
  summarise(
    years = n(),
    surveyed_years = sum(surveyed, na.rm = TRUE),
    positive_years = sum(positive, na.rm = TRUE),
    zero_record_years = sum(zero_record, na.rm = TRUE),
    missing_years = sum(!surveyed, na.rm = TRUE),
    survey_coverage = surveyed_years / years,
    first_positive_year = suppressWarnings(min(year[positive], na.rm = TRUE)),
    last_positive_year = suppressWarnings(max(year[positive], na.rm = TRUE)),
    median_positive_spawn_t = median(spawn_index_tonnes[positive], na.rm = TRUE),
    recent_positive_years = sum(positive & year >= 2017, na.rm = TRUE),
    recent_surveyed_years = sum(surveyed & year >= 2017, na.rm = TRUE),
    median_spawn_doy = median(spawn_date_xbar[positive], na.rm = TRUE),
    median_dive_pct = median(dive_survey_pct[surveyed], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    first_positive_year = if_else(is.infinite(first_positive_year), NA_real_, first_positive_year),
    last_positive_year = if_else(is.infinite(last_positive_year), NA_real_, last_positive_year)
  ) %>%
  left_join(section_action, by = c("section_name" = "site_name"))

period_summary <- spawn %>%
  group_by(section, section_name, period) %>%
  summarise(
    years = n(),
    surveyed_years = sum(surveyed, na.rm = TRUE),
    positive_years = sum(positive, na.rm = TRUE),
    zero_record_years = sum(zero_record, na.rm = TRUE),
    survey_coverage = surveyed_years / years,
    total_spawn_t = sum(spawn_index_tonnes[positive], na.rm = TRUE),
    median_positive_spawn_t = median(spawn_index_tonnes[positive], na.rm = TRUE),
    median_spawn_doy = median(spawn_date_xbar[positive], na.rm = TRUE),
    median_total_length_m = median(total_length[positive], na.rm = TRUE),
    median_width_m = median(mean_width[positive], na.rm = TRUE),
    median_dive_pct = median(dive_survey_pct[surveyed], na.rm = TRUE),
    .groups = "drop"
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
    length_m = as.numeric(Length),
    width_m = as.numeric(Width),
    surface = as.numeric(Surface),
    macrocystis = as.numeric(Macrocystis),
    understory = as.numeric(Understory),
    raw_component_signal = rowSums(across(c(surface, macrocystis, understory)), na.rm = TRUE),
    period = factor(period_for_year(year), levels = period_levels)
  )

raw_location_summary <- raw_spawn %>%
  group_by(section_name, LocationCode, LocationName) %>%
  summarise(
    records = n(),
    years = n_distinct(year),
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE),
    total_raw_component_signal = sum(raw_component_signal, na.rm = TRUE),
    median_length_m = median(length_m, na.rm = TRUE),
    median_width_m = median(width_m, na.rm = TRUE),
    methods = paste(sort(unique(Method)), collapse = "/"),
    .groups = "drop"
  ) %>%
  group_by(section_name) %>%
  mutate(raw_signal_share = total_raw_component_signal / sum(total_raw_component_signal, na.rm = TRUE)) %>%
  ungroup() %>%
  arrange(section_name, desc(total_raw_component_signal))

raw_period_summary <- raw_spawn %>%
  group_by(section_name, period) %>%
  summarise(
    records = n(),
    locations = n_distinct(LocationCode),
    total_raw_component_signal = sum(raw_component_signal, na.rm = TRUE),
    median_start_doy = median(start_doy, na.rm = TRUE),
    median_length_m = median(length_m, na.rm = TRUE),
    median_width_m = median(width_m, na.rm = TRUE),
    dive_record_share = mean(Method == "Dive", na.rm = TRUE),
    surface_component_share = sum(surface, na.rm = TRUE) / total_raw_component_signal,
    macrocystis_component_share = sum(macrocystis, na.rm = TRUE) / total_raw_component_signal,
    understory_component_share = sum(understory, na.rm = TRUE) / total_raw_component_signal,
    .groups = "drop"
  )

write_csv(annual_summary, file.path(diag_dir, "lead_section_local_audit_annual_summary.csv"))
write_csv(period_summary, file.path(diag_dir, "lead_section_local_audit_period_summary.csv"))
write_csv(raw_location_summary, file.path(diag_dir, "lead_section_local_audit_raw_locations.csv"))
write_csv(raw_period_summary, file.path(diag_dir, "lead_section_local_audit_raw_periods.csv"))

p_annual <- spawn %>%
  mutate(section_name = factor(section_name, levels = target_sections)) %>%
  ggplot(aes(x = year, y = pmax(spawn_index_tonnes, 0.1), colour = survey_status)) +
  geom_line(aes(group = section_name), colour = "grey70", linewidth = 0.25) +
  geom_point(size = 1.4, alpha = 0.9) +
  facet_wrap(~ section_name, scales = "free_y", ncol = 2) +
  scale_y_log10(labels = label_comma()) +
  scale_colour_manual(
    values = c("positive" = "#0072B2", "zero record" = "#D55E00", "missing/unsurveyed" = "grey70")
  ) +
  labs(
    x = NULL,
    y = "Annual spawn index tonnes, log scale",
    colour = NULL,
    title = "Lead-section annual spawn records",
    subtitle = "Missing/unsurveyed points are placed at a plotting floor and should not be read as biomass."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_period <- period_summary %>%
  mutate(section_name = factor(section_name, levels = target_sections)) %>%
  ggplot(aes(x = period, y = section_name, fill = survey_coverage)) +
  geom_tile(colour = "white", linewidth = 0.35) +
  geom_text(aes(label = paste0(positive_years, "/", surveyed_years)), size = 2.7) +
  scale_fill_gradient(low = "grey95", high = "#2166AC", labels = percent, limits = c(0, 1)) +
  labs(
    x = NULL,
    y = NULL,
    fill = "Survey\ncoverage",
    title = "Coverage and positive records by period",
    subtitle = "Tile labels are positive years / surveyed years."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "bottom"
  )

p_locations <- raw_location_summary %>%
  group_by(section_name) %>%
  slice_max(total_raw_component_signal, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    section_name = factor(section_name, levels = target_sections),
    LocationName = fct_reorder(LocationName, raw_signal_share)
  ) %>%
  ggplot(aes(x = raw_signal_share, y = LocationName, fill = section_name)) +
  geom_col(width = 0.75, show.legend = FALSE) +
  facet_wrap(~ section_name, scales = "free_y", ncol = 1) +
  scale_x_continuous(labels = percent) +
  labs(
    x = "Share of raw component signal within section",
    y = NULL,
    title = "Top raw spawn locations",
    subtitle = "Only HG raw sections available for Louscoone, Cumshewa, and Laskeek are shown."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- (p_annual / p_period) | p_locations +
  plot_layout(widths = c(1.35, 0.9)) +
  plot_annotation(
    title = "Local audit for lead mechanism and portfolio-concern sections",
    subtitle = "This checks whether section interpretation is entangled with survey coverage, method mix, and location concentration."
  )

ggsave(
  file.path(fig_dir, "lead_section_local_audit.pdf"),
  p,
  width = 250, height = 190, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "lead_section_local_audit.png"),
  p,
  width = 250, height = 190, units = "mm", dpi = 300
)

annual_md <- annual_summary %>%
  transmute(
    section = section_name,
    `talk use` = talk_use,
    `survey coverage` = percent(survey_coverage, accuracy = 1),
    `positive years` = positive_years,
    `zero records` = zero_record_years,
    `recent positives/surveys` = paste0(recent_positive_years, "/", recent_surveyed_years),
    `median positive spawn` = number(median_positive_spawn_t, accuracy = 1),
    `median dive pct` = percent(median_dive_pct / 100, accuracy = 1),
    `next action` = next_analysis
  )

period_md <- period_summary %>%
  filter(period %in% c("1951-1965 early industrial", "1972-2004 roe fishery", "2017-2025 recent closure")) %>%
  transmute(
    section = section_name,
    period,
    `survey coverage` = percent(survey_coverage, accuracy = 1),
    `positive/surveyed` = paste0(positive_years, "/", surveyed_years),
    `total spawn` = number(total_spawn_t, accuracy = 1),
    `median spawn doy` = number(median_spawn_doy, accuracy = 1),
    `median dive pct` = percent(median_dive_pct / 100, accuracy = 1)
  )

location_md <- raw_location_summary %>%
  group_by(section_name) %>%
  slice_max(total_raw_component_signal, n = 3, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    section = section_name,
    location = LocationName,
    records,
    years,
    `first-last` = paste0(first_year, "-", last_year),
    `raw signal share` = percent(raw_signal_share, accuracy = 1),
    methods
  )

lines <- c(
  "# Lead Section Local Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This audit focuses on the sections that currently matter most for mechanism and portfolio interpretation: Louscoone, Cumshewa, Laskeek, and Skidegate.",
  "",
  "## Main Read",
  "",
  "- Cumshewa and Louscoone remain priority mechanism cases, but Cumshewa has materially weaker survey coverage than Louscoone.",
  "- Laskeek is a well-covered portfolio-erosion case, so its depletion signal is harder to dismiss as a sparse-data artifact.",
  "- Skidegate is important but observation-limited because its positive-spawn fit caveat is severe in the early surface era.",
  "- Raw HG location records are available for Louscoone, Cumshewa, and Laskeek; Skidegate is covered in the processed section series but not in this raw HG section extract.",
  "",
  "## Annual Summary",
  "",
  knitr::kable(annual_md, format = "pipe"),
  "",
  "## Period Summary",
  "",
  knitr::kable(period_md, format = "pipe"),
  "",
  "## Top Raw Locations",
  "",
  knitr::kable(location_md, format = "pipe"),
  "",
  "## Interpretation",
  "",
  "- The next high-value local data work is not another regional predator coefficient. It is a targeted audit of local survey access, habitat/substrate, and spatial exposure for Cumshewa and Louscoone.",
  "- Skidegate should stay in the portfolio story, but causal claims from its early observed magnitudes need the positive-spawn residual caveat.",
  "- Laskeek is a stronger mechanistic candidate than its `portfolio concern` label alone suggests because survey coverage is relatively high and recent biomass remains low.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/lead_section_local_audit.pdf`",
  "- `Output/diagnostics/lead_section_local_audit_annual_summary.csv`",
  "- `Output/diagnostics/lead_section_local_audit_period_summary.csv`",
  "- `Output/diagnostics/lead_section_local_audit_raw_locations.csv`",
  "- `Output/diagnostics/lead_section_local_audit_raw_periods.csv`"
)

writeLines(lines, file.path(diag_dir, "lead_section_local_audit.md"))

cat("Saved lead section local audit:\n")
cat("  Output/diagnostics/lead_section_local_audit.md\n")
cat("  Output/figures/lead_section_local_audit.pdf\n")
