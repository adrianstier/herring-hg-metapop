# ============================================================================
# 07g_survey_method_coverage_audit.R
# Survey coverage, zero ambiguity, and method-transition diagnostics.
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

load(file.path(data_dir, "jags_model_inputs_v2.RData"))

region_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_region_1951_2025.csv"),
  show_col_types = FALSE
)
section_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_section_1951_2025.csv"),
  show_col_types = FALSE
)

survey_matrix_df <- tibble(
  year = rep(jags_data$years, each = jags_data$nSites),
  site = rep(seq_len(jags_data$nSites), times = jags_data$nYears),
  site_name = rep(jags_data$site_names, times = jags_data$nYears),
  positive = as.vector(t(jags_data$Y_obs == 1L)),
  zero_record = as.vector(t(jags_data$Y_censored == 1L)),
  missing = as.vector(t(jags_data$Y_missing == 1L))
) %>%
  mutate(
    surveyed = positive | zero_record,
    status = case_when(
      positive ~ "positive spawn",
      zero_record ~ "zero record",
      TRUE ~ "missing / unsurveyed"
    ),
    era = if_else(year <= 1987, "surface era", "SCUBA/dive era")
  ) %>%
  left_join(
    section_cov %>%
      select(
        year,
        section = section,
        total_records,
        dive_record_pct,
        surface_record_pct,
        incomplete_record_pct,
        spawn_start_doy_weighted,
        subtidal_share,
        substrate_effective_n
      ),
    by = c("year", "site" = "section")
  ) %>%
  mutate(
    total_records = coalesce(total_records, 0),
    dive_records = total_records * coalesce(dive_record_pct, 0) / 100,
    surface_records = total_records * coalesce(surface_record_pct, 0) / 100,
    incomplete_records = total_records * coalesce(incomplete_record_pct, 0) / 100
  )

annual_survey <- survey_matrix_df %>%
  group_by(year, era) %>%
  summarise(
    surveyed_sections = sum(surveyed),
    positive_sections = sum(positive),
    zero_records = sum(zero_record),
    missing_sections = sum(missing),
    total_records = sum(total_records, na.rm = TRUE),
    dive_records = sum(dive_records, na.rm = TRUE),
    surface_records = sum(surface_records, na.rm = TRUE),
    incomplete_records = sum(incomplete_records, na.rm = TRUE),
    dive_record_pct = if_else(total_records > 0, 100 * dive_records / total_records, NA_real_),
    surface_record_pct = if_else(total_records > 0, 100 * surface_records / total_records, NA_real_),
    incomplete_record_pct = if_else(total_records > 0, 100 * incomplete_records / total_records, NA_real_),
    .groups = "drop"
  ) %>%
  left_join(region_cov, by = "year", suffix = c("_from_matrix", "_region"))

section_survey <- survey_matrix_df %>%
  group_by(site, site_name) %>%
  summarise(
    n_years = n(),
    surveyed_years = sum(surveyed),
    positive_years = sum(positive),
    zero_record_years = sum(zero_record),
    missing_years = sum(missing),
    surface_era_surveyed = sum(surveyed & year <= 1987),
    dive_era_surveyed = sum(surveyed & year > 1987),
    survey_coverage = surveyed_years / n_years,
    positive_given_surveyed = positive_years / pmax(surveyed_years, 1),
    zero_given_surveyed = zero_record_years / pmax(surveyed_years, 1),
    .groups = "drop"
  ) %>%
  arrange(survey_coverage)

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

period_summary <- annual_survey %>%
  mutate(period = period_for_year(year)) %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    surveyed_sections = median(surveyed_sections_from_matrix, na.rm = TRUE),
    positive_sections = median(positive_sections, na.rm = TRUE),
    zero_records = median(zero_records, na.rm = TRUE),
    missing_sections = median(missing_sections, na.rm = TRUE),
    surface_pct = median(surface_record_pct_from_matrix, na.rm = TRUE),
    dive_pct = median(dive_record_pct_from_matrix, na.rm = TRUE),
    .groups = "drop"
  )

p_status <- survey_matrix_df %>%
  mutate(site_name = fct_rev(factor(site_name, levels = unique(jags_data$site_names)))) %>%
  ggplot(aes(x = year, y = site_name, fill = status)) +
  geom_tile(colour = "white", linewidth = 0.05) +
  scale_fill_manual(values = c(
    "positive spawn" = "#176B87",
    "zero record" = "#C47F2C",
    "missing / unsurveyed" = "grey83"
  )) +
  labs(
    x = NULL,
    y = NULL,
    fill = NULL,
    title = "Survey status by section-year",
    subtitle = "Grey cells are not biological absences in the Stier-aligned baseline."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid = element_blank(), legend.position = "bottom")

p_methods <- annual_survey %>%
  select(year, surface_record_pct_from_matrix, dive_record_pct_from_matrix, incomplete_record_pct_from_matrix) %>%
  pivot_longer(-year, names_to = "method", values_to = "pct") %>%
  filter(is.finite(pct)) %>%
  mutate(
    method = recode(
      method,
      surface_record_pct_from_matrix = "Surface",
      dive_record_pct_from_matrix = "Dive",
      incomplete_record_pct_from_matrix = "Incomplete"
    )
  ) %>%
  ggplot(aes(x = year, y = pct / 100, fill = method)) +
  geom_area(alpha = 0.85) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = c(Surface = "#C47F2C", Dive = "#176B87", Incomplete = "grey55")) +
  labs(
    x = NULL,
    y = "Record share",
    fill = NULL,
    title = "Survey method transition",
    subtitle = "Raw DFO method labels are mixed after 1988; they are not identical to the Stier q-era split."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_counts <- annual_survey %>%
  select(year, positive_sections, zero_records, missing_sections) %>%
  pivot_longer(-year, names_to = "count_type", values_to = "n") %>%
  mutate(count_type = recode(
    count_type,
    positive_sections = "Positive",
    zero_records = "Zero record",
    missing_sections = "Missing/unsurveyed"
  )) %>%
  ggplot(aes(x = year, y = n, colour = count_type)) +
  geom_line(linewidth = 0.65) +
  scale_colour_manual(values = c(Positive = "#176B87", `Zero record` = "#C47F2C", `Missing/unsurveyed` = "grey40")) +
  scale_y_continuous(breaks = 0:11) +
  labs(
    x = "Year",
    y = "Sections",
    colour = NULL,
    title = "Coverage changes through time"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_status / (p_methods | p_counts) +
  plot_annotation(
    title = "Survey coverage and method audit",
    subtitle = "Zero and missing records require explicit interpretation before being used as absence data."
  )

ggsave(
  file.path(fig_dir, "survey_method_coverage_audit.pdf"),
  p,
  width = 250,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "survey_method_coverage_audit.png"),
  p,
  width = 250,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(survey_matrix_df, file.path(diag_dir, "survey_status_by_section_year.csv"))
write_csv(annual_survey, file.path(diag_dir, "survey_status_by_year.csv"))
write_csv(section_survey, file.path(diag_dir, "survey_status_by_section.csv"))
write_csv(period_summary, file.path(diag_dir, "survey_status_by_period.csv"))

fmt <- function(x, digits = 1) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# Survey Method And Coverage Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Why This Matters",
  "",
  "The Stier-aligned baseline treats zero records and unsurveyed cells as ambiguous unless there is explicit survey metadata supporting true nondetection. This audit describes the coverage and method context behind that decision.",
  "",
  "## Overall Counts",
  "",
  paste0("- Positive section-years: ", sum(survey_matrix_df$positive)),
  paste0("- Zero-record section-years: ", sum(survey_matrix_df$zero_record)),
  paste0("- Missing / unsurveyed section-years: ", sum(survey_matrix_df$missing)),
  "",
  "## Lowest Survey Coverage Sections",
  "",
  paste0(
    "- ",
    head(section_survey$site_name, 5),
    ": surveyed ",
    head(section_survey$surveyed_years, 5),
    " / ",
    head(section_survey$n_years, 5),
    " years; zero records = ",
    head(section_survey$zero_record_years, 5)
  ),
  "",
  "## Period Summary",
  "",
  paste0(
    "- ",
    period_summary$period,
    ": median surveyed sections = ",
    fmt(period_summary$surveyed_sections, 1),
    ", median positive sections = ",
    fmt(period_summary$positive_sections, 1),
    ", median missing sections = ",
    fmt(period_summary$missing_sections, 1),
    ", median surface/dive = ",
    fmt(period_summary$surface_pct, 0),
    "%/",
    fmt(period_summary$dive_pct, 0),
    "%"
  ),
  "",
  "## Interpretation",
  "",
  "- Missing cells dominate enough of the matrix that they must not be interpreted as low biomass.",
  "- The Stier-style q-era split remains necessary, but raw DFO method labels show that post-1988 survey records are mixed rather than a clean dive-only era.",
  "- Survey coverage is uneven among sections, supporting 11-section fitting plus 9-focal reporting sensitivity.",
  "- Detection-aware zero models remain useful sensitivity analyses, not the default biological interpretation.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/survey_method_coverage_audit.pdf`",
  "- `Output/diagnostics/survey_status_by_section_year.csv`",
  "- `Output/diagnostics/survey_status_by_year.csv`",
  "- `Output/diagnostics/survey_status_by_section.csv`"
)

writeLines(lines, file.path(diag_dir, "survey_method_coverage_audit.md"))

cat("Saved survey coverage diagnostics:\n")
cat("  Output/diagnostics/survey_method_coverage_audit.md\n")
cat("  Output/figures/survey_method_coverage_audit.pdf\n")
