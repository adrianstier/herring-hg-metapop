# ============================================================================
# 07ad_survey_coverage_zero_ambiguity.R
# Survey coverage and ambiguous-zero diagnostic for the Stier-aligned baseline.
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

period_for_year <- function(year) {
  case_when(
    year <= 1965 ~ "1951-1965 early industrial",
    year <= 1971 ~ "1966-1971 late reduction",
    year <= 2004 ~ "1972-2004 roe fishery",
    year <= 2013 ~ "2005-2013 closure",
    year <= 2016 ~ "2014-2016 marine heatwave",
    TRUE ~ "2017-2025 recent closure"
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

method_labels <- c("Surface", "Mixed transition", "SCUBA / dive")

load(file.path(data_dir, "jags_model_inputs_v2.RData"))

spawn_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_section_1951_2025.csv"),
  show_col_types = FALSE
) %>%
  filter(in_model) %>%
  mutate(
    site = match(section_name, jags_data$site_names),
    period = factor(period_for_year(year), levels = period_levels),
    survey_method_era = factor(method_labels[jags_data$q_idx[match(year, jags_data$years)]], levels = method_labels),
    status = case_when(
      positive_spawn ~ "positive spawn",
      surveyed_zero ~ "zero record",
      TRUE ~ "missing / unsurveyed"
    ),
    status = factor(status, levels = c("positive spawn", "zero record", "missing / unsurveyed")),
    survey_flag = positive_spawn | surveyed_zero
  ) %>%
  arrange(site, year)

stopifnot(
  nrow(spawn_cov) == jags_data$nYears * jags_data$nSites,
  all(!is.na(spawn_cov$site))
)

status_cols <- c(
  "positive spawn" = "#0072B2",
  "zero record" = "#D55E00",
  "missing / unsurveyed" = "grey78"
)

overall_summary <- spawn_cov %>%
  summarise(
    n_site_years = n(),
    positive_site_years = sum(positive_spawn),
    zero_record_site_years = sum(surveyed_zero),
    missing_site_years = sum(!survey_flag),
    surveyed_site_years = sum(survey_flag),
    pct_positive = 100 * positive_site_years / n_site_years,
    pct_zero_record = 100 * zero_record_site_years / n_site_years,
    pct_missing = 100 * missing_site_years / n_site_years,
    pct_surveyed = 100 * surveyed_site_years / n_site_years
  )

year_meta <- spawn_cov %>%
  distinct(year, period, survey_method_era)

year_summary <- spawn_cov %>%
  count(year, status, name = "n_sections") %>%
  complete(year = sort(unique(spawn_cov$year)), status, fill = list(n_sections = 0)) %>%
  left_join(year_meta, by = "year") %>%
  group_by(year, period, survey_method_era) %>%
  mutate(
    surveyed_sections = sum(n_sections[status != "missing / unsurveyed"]),
    positive_sections = sum(n_sections[status == "positive spawn"]),
    zero_record_sections = sum(n_sections[status == "zero record"]),
    missing_sections = sum(n_sections[status == "missing / unsurveyed"]),
    survey_coverage = surveyed_sections / jags_data$nSites
  ) %>%
  ungroup()

year_wide <- year_summary %>%
  distinct(year, period, survey_method_era, surveyed_sections, positive_sections, zero_record_sections, missing_sections, survey_coverage) %>%
  arrange(year)

period_summary <- year_wide %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    median_surveyed_sections = median(surveyed_sections, na.rm = TRUE),
    min_surveyed_sections = min(surveyed_sections, na.rm = TRUE),
    max_surveyed_sections = max(surveyed_sections, na.rm = TRUE),
    median_positive_sections = median(positive_sections, na.rm = TRUE),
    total_zero_records = sum(zero_record_sections, na.rm = TRUE),
    total_missing_cells = sum(missing_sections, na.rm = TRUE),
    pct_cells_surveyed = 100 * sum(surveyed_sections, na.rm = TRUE) / (n() * jags_data$nSites),
    .groups = "drop"
  )

section_summary <- spawn_cov %>%
  group_by(site, section, section_name) %>%
  summarise(
    positive_years = sum(positive_spawn),
    zero_record_years = sum(surveyed_zero),
    missing_years = sum(!survey_flag),
    surveyed_years = sum(survey_flag),
    survey_coverage = surveyed_years / n(),
    first_positive_year = if_else(any(positive_spawn), min(year[positive_spawn]), NA_integer_),
    last_positive_year = if_else(any(positive_spawn), max(year[positive_spawn]), NA_integer_),
    first_surveyed_year = if_else(any(survey_flag), min(year[survey_flag]), NA_integer_),
    last_surveyed_year = if_else(any(survey_flag), max(year[survey_flag]), NA_integer_),
    .groups = "drop"
  ) %>%
  arrange(survey_coverage, zero_record_years)

method_period_summary <- spawn_cov %>%
  group_by(survey_method_era, period) %>%
  summarise(
    n_site_years = n(),
    positive_site_years = sum(positive_spawn),
    zero_record_site_years = sum(surveyed_zero),
    missing_site_years = sum(!survey_flag),
    pct_surveyed = 100 * (positive_site_years + zero_record_site_years) / n_site_years,
    pct_zero_among_surveyed = 100 * zero_record_site_years / pmax(positive_site_years + zero_record_site_years, 1),
    .groups = "drop"
  )

zero_context <- spawn_cov %>%
  filter(surveyed_zero) %>%
  rowwise() %>%
  mutate(
    previous_positive_year = {
      yrs <- spawn_cov$year[spawn_cov$section == section & spawn_cov$positive_spawn & spawn_cov$year < year]
      if (length(yrs) == 0) NA_integer_ else max(yrs)
    },
    next_positive_year = {
      yrs <- spawn_cov$year[spawn_cov$section == section & spawn_cov$positive_spawn & spawn_cov$year > year]
      if (length(yrs) == 0) NA_integer_ else min(yrs)
    },
    years_since_previous_positive = year - previous_positive_year,
    years_to_next_positive = next_positive_year - year
  ) %>%
  ungroup() %>%
  select(
    year, section, section_name, survey_method_era, total_records,
    previous_positive_year, years_since_previous_positive,
    next_positive_year, years_to_next_positive
  )

low_coverage_years <- year_wide %>%
  filter(surveyed_sections <= 5) %>%
  arrange(year)

p_year <- ggplot(year_summary, aes(x = year, y = n_sections, fill = status)) +
  geom_col(width = 0.9) +
  geom_hline(yintercept = jags_data$nSites, colour = "grey35", linewidth = 0.25) +
  scale_fill_manual(values = status_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  labs(
    x = NULL,
    y = "Sections",
    title = "Survey status by year",
    subtitle = "Zero records are rare and missing/unsurveyed cells are common, especially in low-coverage years."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_heat <- ggplot(spawn_cov, aes(x = year, y = fct_rev(factor(section_name, levels = jags_data$site_names)), fill = status)) +
  geom_tile(colour = "white", linewidth = 0.08) +
  scale_fill_manual(values = status_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, 10), expand = c(0, 0)) +
  labs(
    x = "Year",
    y = NULL,
    title = "Section-year observation matrix",
    subtitle = "The Stier-aligned baseline uses positive cells and treats zero records as ambiguous rather than confirmed absences."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_section <- section_summary %>%
  pivot_longer(
    c(positive_years, zero_record_years, missing_years),
    names_to = "status_count",
    values_to = "n_years"
  ) %>%
  mutate(
    status = recode(
      status_count,
      positive_years = "positive spawn",
      zero_record_years = "zero record",
      missing_years = "missing / unsurveyed"
    ),
    status = factor(status, levels = c("positive spawn", "zero record", "missing / unsurveyed")),
    section_name = fct_reorder(section_name, survey_coverage)
  ) %>%
  ggplot(aes(x = n_years, y = section_name, fill = status)) +
  geom_col(width = 0.75) +
  scale_fill_manual(values = status_cols) +
  labs(
    x = "Years",
    y = NULL,
    title = "Coverage differs strongly by section"
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p <- p_year / (p_heat | p_section) +
  plot_layout(heights = c(0.8, 1.4), widths = c(1.35, 0.9)) +
  plot_annotation(
    title = "Survey coverage and zero-record ambiguity",
    subtitle = "This diagnostic supports the current baseline choice: zero records and no-survey cells should not be treated as simple biological absences."
  )

ggsave(
  file.path(fig_dir, "survey_coverage_zero_ambiguity.pdf"),
  p,
  width = 230, height = 190, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "survey_coverage_zero_ambiguity.png"),
  p,
  width = 230, height = 190, units = "mm", dpi = 300
)

write_csv(overall_summary, file.path(diag_dir, "survey_coverage_zero_ambiguity_overall.csv"))
write_csv(year_wide, file.path(diag_dir, "survey_coverage_zero_ambiguity_by_year.csv"))
write_csv(period_summary, file.path(diag_dir, "survey_coverage_zero_ambiguity_by_period.csv"))
write_csv(section_summary, file.path(diag_dir, "survey_coverage_zero_ambiguity_by_section.csv"))
write_csv(method_period_summary, file.path(diag_dir, "survey_coverage_zero_ambiguity_by_method_period.csv"))
write_csv(zero_context, file.path(diag_dir, "survey_coverage_zero_record_context.csv"))
write_csv(low_coverage_years, file.path(diag_dir, "survey_coverage_low_coverage_years.csv"))

fmt_pct <- function(x) number(x, accuracy = 0.1)
fmt_int <- function(x) number(x, accuracy = 1)

lowest_sections <- section_summary %>%
  slice_head(n = 3)

most_zero_sections <- section_summary %>%
  arrange(desc(zero_record_years), survey_coverage) %>%
  slice_head(n = 3)

weak_periods <- period_summary %>%
  arrange(median_surveyed_sections) %>%
  slice_head(n = 2)

lines <- c(
  "# Survey Coverage And Zero-Record Ambiguity",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Purpose",
  "",
  "This diagnostic documents why the promoted `m1_stier_11` baseline treats zero spawn records as ambiguous/missing rather than as confirmed biological absences.",
  "",
  "The key practical distinction is that a zero or blank in these section-year data can arise from survey coverage, access, governance, or method context as well as biological scarcity. In Haida Gwaii, some no-survey years can reflect Haida preferences or access decisions rather than low expected biomass.",
  "",
  "## Overall Data State",
  "",
  paste0("- Positive section-years: `", fmt_int(overall_summary$positive_site_years), "` (`", fmt_pct(overall_summary$pct_positive), "%`)."),
  paste0("- Zero-record section-years: `", fmt_int(overall_summary$zero_record_site_years), "` (`", fmt_pct(overall_summary$pct_zero_record), "%`)."),
  paste0("- Missing / unsurveyed section-years: `", fmt_int(overall_summary$missing_site_years), "` (`", fmt_pct(overall_summary$pct_missing), "%`)."),
  paste0("- Surveyed section-years, counting positives plus zero records: `", fmt_int(overall_summary$surveyed_site_years), "` of `", fmt_int(overall_summary$n_site_years), "` (`", fmt_pct(overall_summary$pct_surveyed), "%`)."),
  "",
  "## Coverage Weak Points",
  "",
  paste0(
    "- Lowest-coverage sections: ",
    paste0(lowest_sections$section_name, " (`", lowest_sections$surveyed_years, " / 75` years)", collapse = "; "),
    "."
  ),
  paste0(
    "- Sections with the most zero records: ",
    paste0(most_zero_sections$section_name, " (`", most_zero_sections$zero_record_years, "`)", collapse = "; "),
    "."
  ),
  paste0(
    "- Weakest-coverage periods by median surveyed sections: ",
    paste0(as.character(weak_periods$period), " (`", weak_periods$median_surveyed_sections, "`)", collapse = "; "),
    "."
  ),
  paste0("- Years with five or fewer surveyed sections: `", nrow(low_coverage_years), "`."),
  "",
  "## Modeling Implication",
  "",
  "- The current baseline should continue to skip zero records in the positive log-spawn likelihood.",
  "- Detection-aware zero models remain sensitivity analyses because they assume surveyed zero records are informative nondetections.",
  "- Process or driver conclusions should be reported with survey coverage because apparent archipelago totals are coverage-sensitive.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/survey_coverage_zero_ambiguity.pdf`",
  "- `Output/diagnostics/survey_coverage_zero_ambiguity_by_section.csv`",
  "- `Output/diagnostics/survey_coverage_zero_ambiguity_by_period.csv`",
  "- `Output/diagnostics/survey_coverage_zero_record_context.csv`"
)

writeLines(lines, file.path(diag_dir, "survey_coverage_zero_ambiguity.md"))

cat("Saved survey coverage ambiguity diagnostics:\n")
cat("  Output/figures/survey_coverage_zero_ambiguity.pdf\n")
cat("  Output/diagnostics/survey_coverage_zero_ambiguity.md\n")
