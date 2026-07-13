# ============================================================================
# 07v_observed_occupancy_transition_screen.R
# Observed positive-detection persistence and recolonization screen.
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

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
focal_sections <- c(2, 3, 5, 6, 21, 22, 23, 24, 25)

spawn <- read_csv(
  file.path(proj_dir, "Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
) %>%
  filter(section %in% keep_sections) %>%
  mutate(
    surveyed = totalrecords > 0,
    positive = spawn_index_tonnes > 0,
    report_set = if_else(section %in% focal_sections, "focal_9", "all_11"),
    era = case_when(
      year <= 1971 ~ "1951-1971 reduction era",
      year <= 2004 ~ "1972-2004 roe fishery",
      TRUE ~ "2005-2025 closure"
    ),
    state = case_when(
      positive ~ "positive",
      surveyed ~ "zero_record",
      TRUE ~ "unsurveyed"
    )
  )

annual_status <- spawn %>%
  group_by(year, era) %>%
  summarise(
    surveyed_sections = sum(surveyed),
    positive_sections = sum(positive),
    zero_records = sum(state == "zero_record"),
    positive_rate_among_surveyed = positive_sections / surveyed_sections,
    .groups = "drop"
  )

transitions <- spawn %>%
  arrange(section, year) %>%
  group_by(section, section_name, report_set) %>%
  mutate(
    next_year = lead(year),
    next_surveyed = lead(surveyed),
    next_positive = lead(positive),
    next_state = lead(state),
    consecutive = next_year == year + 1
  ) %>%
  ungroup() %>%
  filter(consecutive, surveyed, next_surveyed) %>%
  mutate(
    transition = paste0(state, " -> ", next_state),
    era = case_when(
      year <= 1971 ~ "1951-1971 reduction era",
      year <= 2004 ~ "1972-2004 roe fishery",
      TRUE ~ "2005-2025 closure"
    )
  )

transition_summary <- transitions %>%
  summarise(
    n_adjacent_surveyed_pairs = n(),
    n_positive_start = sum(positive),
    n_zero_start = sum(!positive),
    persistence = sum(positive & next_positive) / n_positive_start,
    non_detection_to_positive = sum(!positive & next_positive) / n_zero_start,
    .groups = "drop"
  )

transition_by_era <- transitions %>%
  group_by(era) %>%
  summarise(
    n_adjacent_surveyed_pairs = n(),
    n_positive_start = sum(positive),
    n_zero_start = sum(!positive),
    persistence = sum(positive & next_positive) / n_positive_start,
    non_detection_to_positive = if_else(
      n_zero_start > 0,
      sum(!positive & next_positive) / n_zero_start,
      NA_real_
    ),
    .groups = "drop"
  )

transition_by_section <- transitions %>%
  group_by(section, section_name, report_set) %>%
  summarise(
    n_adjacent_surveyed_pairs = n(),
    n_positive_start = sum(positive),
    n_zero_start = sum(!positive),
    persistence = if_else(
      n_positive_start > 0,
      sum(positive & next_positive) / n_positive_start,
      NA_real_
    ),
    non_detection_to_positive = if_else(
      n_zero_start > 0,
      sum(!positive & next_positive) / n_zero_start,
      NA_real_
    ),
    .groups = "drop"
  ) %>%
  arrange(persistence)

transition_counts <- transitions %>%
  count(era, transition, name = "n") %>%
  group_by(era) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

p_annual <- ggplot(annual_status, aes(x = year)) +
  geom_col(aes(y = surveyed_sections), fill = "grey80", width = 0.9) +
  geom_line(aes(y = positive_sections), colour = "#0072B2", linewidth = 0.8) +
  geom_point(aes(y = positive_sections), colour = "#0072B2", size = 1.2) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  scale_y_continuous(breaks = 0:11, limits = c(0, 11)) +
  labs(
    x = "Year",
    y = "Sections",
    title = "Observed positive detections are coverage-limited",
    subtitle = "Bars = surveyed sections; blue = positive sections."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_transition <- transition_counts %>%
  ggplot(aes(x = era, y = prop, fill = transition)) +
  geom_col(width = 0.72) +
  scale_y_continuous(labels = percent) +
  labs(
    x = NULL,
    y = "Share of adjacent surveyed pairs",
    fill = NULL,
    title = "Observed transition mix",
    subtitle = "Only adjacent years with survey records in both years are included."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 20, hjust = 1),
    legend.position = "bottom"
  )

p_section <- transition_by_section %>%
  filter(n_positive_start >= 3) %>%
  mutate(section_name = fct_reorder(section_name, persistence)) %>%
  ggplot(aes(x = persistence, y = section_name)) +
  geom_point(aes(size = n_positive_start, colour = report_set), alpha = 0.85) +
  scale_x_continuous(labels = percent, limits = c(0, 1)) +
  labs(
    x = "Positive-detection persistence",
    y = NULL,
    size = "Positive starts",
    colour = NULL,
    title = "Section-level persistence is high where consecutive surveys exist"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_annual / (p_transition | p_section) +
  plot_annotation(
    title = "Observed Occupancy-Transition Screen",
    subtitle = "This is a survey-positive detection screen, not a true absence model."
  )

ggsave(
  file.path(fig_dir, "observed_occupancy_transition_screen.pdf"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "observed_occupancy_transition_screen.png"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(annual_status, file.path(diag_dir, "observed_annual_occupancy_status.csv"))
write_csv(transitions, file.path(diag_dir, "observed_occupancy_transitions.csv"))
write_csv(transition_summary, file.path(diag_dir, "observed_occupancy_transition_summary.csv"))
write_csv(transition_by_era, file.path(diag_dir, "observed_occupancy_transition_by_era.csv"))
write_csv(transition_by_section, file.path(diag_dir, "observed_occupancy_transition_by_section.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

era_lines <- transition_by_era %>%
  transmute(
    line = paste0(
      "- ",
      era,
      ": n=",
      n_adjacent_surveyed_pairs,
      ", persistence=",
      percent(persistence, accuracy = 0.1),
      ", zero-record to positive=",
      if_else(is.na(non_detection_to_positive), "not estimable", percent(non_detection_to_positive, accuracy = 0.1)),
      "."
    )
  ) %>%
  pull(line)

lowest_persistence <- transition_by_section %>%
  filter(n_positive_start >= 3) %>%
  arrange(persistence) %>%
  slice_head(n = 5) %>%
  transmute(
    line = paste0(
      "- ",
      section_name,
      ": persistence=",
      percent(persistence, accuracy = 0.1),
      ", positive starts=",
      n_positive_start,
      "."
    )
  ) %>%
  pull(line)

lines <- c(
  "# Observed Occupancy-Transition Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Adjacent surveyed year-section pairs: ",
    transition_summary$n_adjacent_surveyed_pairs,
    "."
  ),
  paste0(
    "- Positive-detection persistence: ",
    percent(transition_summary$persistence, accuracy = 0.1),
    "."
  ),
  paste0(
    "- Zero-record to positive-detection transition rate: ",
    percent(transition_summary$non_detection_to_positive, accuracy = 0.1),
    " across only ",
    transition_summary$n_zero_start,
    " zero-record starts."
  ),
  "",
  "Interpretation: positive detections tend to persist when adjacent surveyed years exist. This supports a site-retention story, but the zero-record sample is too small and governance/access issues make true absence inference unsafe.",
  "",
  "## By Era",
  "",
  era_lines,
  "",
  "## Lowest Positive-Detection Persistence",
  "",
  lowest_persistence,
  "",
  "## Decision",
  "",
  "- Use this as descriptive context for collective memory / site retention.",
  "- Do not treat it as a full occupancy model or as evidence that unsurveyed sites were empty.",
  "- A formal occupancy model still needs explicit survey-effort assumptions.",
  "",
  "## Files",
  "",
  "- `Output/figures/observed_occupancy_transition_screen.pdf`",
  "- `Output/diagnostics/observed_occupancy_transition_summary.csv`",
  "- `Output/diagnostics/observed_occupancy_transition_by_era.csv`",
  "- `Output/diagnostics/observed_occupancy_transition_by_section.csv`"
)

writeLines(lines, file.path(diag_dir, "observed_occupancy_transition_screen.md"))
cat(paste(lines, collapse = "\n"))
cat("\n")
