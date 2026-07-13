# ============================================================================
# 07o_m1_stier_11_current_year_status.R
# Current-year section status from m1_stier_11 posterior medians.
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

target_year <- 2025

section_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
)

scorecard <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_scorecard.csv"),
  show_col_types = FALSE
)

collapse <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_collapse_status_by_year.csv"),
  show_col_types = FALSE
)

survey_status <- read_csv(
  file.path(diag_dir, "survey_status_by_section_year.csv"),
  show_col_types = FALSE
)

current_total_path <- file.path(diag_dir, "current_biomass_estimate_total.csv")
current_total <- if (file.exists(current_total_path)) {
  read_csv(current_total_path, show_col_types = FALSE) %>%
    filter(
      year == target_year,
      state == "post-fishing",
      section_set == "all 11 sections"
    ) %>%
    slice(1)
} else {
  tibble()
}

current_status <- section_year %>%
  filter(year == target_year) %>%
  select(site, site_name, focal_status, biomass_median = median, biomass_lo90 = lo90, biomass_hi90 = hi90) %>%
  mutate(current_share = biomass_median / sum(biomass_median, na.rm = TRUE)) %>%
  left_join(
    scorecard %>%
      select(site, status, recent_to_early_ratio, closure_pct_per_year, survey_coverage, observed_catch_1951_2004),
    by = "site"
  ) %>%
  left_join(
    collapse %>%
      filter(year == target_year) %>%
      select(site, rel_to_early, below_20pct_early, below_10pct_early),
    by = "site"
  ) %>%
  left_join(
    survey_status %>%
      filter(year == target_year) %>%
      select(site, survey_status = status, positive, zero_record, missing, total_records, dive_record_pct, surface_record_pct),
    by = "site"
  ) %>%
  arrange(desc(current_share))

summary_tbl <- current_status %>%
  summarise(
    sum_section_medians = sum(biomass_median, na.rm = TRUE),
    total_biomass_median = if (nrow(current_total) > 0) {
      current_total$median
    } else {
      sum_section_medians
    },
    total_biomass_lo80 = if (nrow(current_total) > 0) current_total$lo80 else NA_real_,
    total_biomass_hi80 = if (nrow(current_total) > 0) current_total$hi80 else NA_real_,
    total_biomass_lo90 = if (nrow(current_total) > 0) current_total$lo90 else NA_real_,
    total_biomass_hi90 = if (nrow(current_total) > 0) current_total$hi90 else NA_real_,
    top3_share = sum(head(current_share, 3), na.rm = TRUE),
    n_below_20pct = sum(below_20pct_early, na.rm = TRUE),
    n_focal_below_20pct = sum(below_20pct_early & focal_status == "focal_9", na.rm = TRUE),
    surveyed_sections = sum(!missing, na.rm = TRUE),
    positive_sections = sum(positive, na.rm = TRUE),
    zero_record_sections = sum(zero_record, na.rm = TRUE)
  )

p_share <- current_status %>%
  mutate(site_name = fct_reorder(site_name, current_share)) %>%
  ggplot(aes(x = current_share, y = site_name, fill = status)) +
  geom_col(alpha = 0.9) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = c(
    "persistently depleted" = "#8B1A1A",
    "flat or declining" = "#D55E00",
    "rebounding but below early" = "#F0E442",
    "intermediate" = "grey55",
    "rebounded above early" = "#2166AC"
  )) +
  labs(
    x = paste0(target_year, " biomass share"),
    y = NULL,
    fill = NULL,
    title = paste0(target_year, " posterior biomass share by section")
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_rel <- current_status %>%
  mutate(site_name = fct_reorder(site_name, rel_to_early)) %>%
  ggplot(aes(x = rel_to_early, y = site_name, fill = below_20pct_early)) +
  geom_vline(xintercept = 0.2, linetype = "dashed", colour = "grey45") +
  geom_vline(xintercept = 1.0, linetype = "dashed", colour = "grey65") +
  geom_col(alpha = 0.9) +
  scale_x_log10(labels = label_number(accuracy = 0.1)) +
  scale_fill_manual(values = c(`TRUE` = "#8B1A1A", `FALSE` = "#2166AC")) +
  labs(
    x = paste0(target_year, " / early biomass"),
    y = NULL,
    fill = "Below 20%",
    title = paste0(target_year, " relative to early section baseline")
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_survey <- current_status %>%
  count(survey_status) %>%
  ggplot(aes(x = survey_status, y = n, fill = survey_status)) +
  geom_col(alpha = 0.9) +
  scale_y_continuous(breaks = 0:11) +
  scale_fill_manual(values = c(
    "positive spawn" = "#176B87",
    "zero record" = "#C47F2C",
    "missing / unsurveyed" = "grey70"
  )) +
  labs(
    x = NULL,
    y = "Sections",
    fill = NULL,
    title = paste0(target_year, " survey status")
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "none")

p <- p_share | (p_rel / p_survey)

ggsave(
  file.path(fig_dir, "m1_stier_11_current_year_status.pdf"),
  p,
  width = 260,
  height = 180,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_current_year_status.png"),
  p,
  width = 260,
  height = 180,
  units = "mm",
  dpi = 300
)

write_csv(current_status, file.path(diag_dir, "m1_stier_11_current_year_status.csv"))
write_csv(summary_tbl, file.path(diag_dir, "m1_stier_11_current_year_summary.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier 11 Current-Year Status",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Current-Year Summary",
  "",
  paste0("- Year: ", target_year),
  paste0(
    "- Posterior median of all-11 total biomass: ",
    fmt(summary_tbl$total_biomass_median, 0),
    ifelse(
      is.finite(summary_tbl$total_biomass_lo80),
      paste0(
        " (80% interval ",
        fmt(summary_tbl$total_biomass_lo80, 0),
        "-",
        fmt(summary_tbl$total_biomass_hi80, 0),
        ")"
      ),
      ""
    )
  ),
  paste0("- Sum of section-level medians: ", fmt(summary_tbl$sum_section_medians, 0)),
  paste0("- Top-3 biomass share: ", percent(summary_tbl$top3_share, accuracy = 1)),
  paste0("- Sections below 20% early baseline: ", summary_tbl$n_below_20pct, " / 11"),
  paste0("- Focal sections below 20% early baseline: ", summary_tbl$n_focal_below_20pct, " / 9"),
  paste0("- Surveyed / positive / zero-record sections: ", summary_tbl$surveyed_sections, " / ", summary_tbl$positive_sections, " / ", summary_tbl$zero_record_sections),
  "",
  "## Largest Current Shares",
  "",
  paste0(
    "- ",
    head(current_status$site_name, 6),
    ": ",
    percent(head(current_status$current_share, 6), accuracy = 1),
    " of posterior biomass; current/early = ",
    fmt(head(current_status$rel_to_early, 6), 2),
    "; survey status = ",
    head(current_status$survey_status, 6)
  ),
  "",
  "## Interpretation",
  "",
  "- The current-year view should be read with survey coverage; unsurveyed or ambiguous records are not biological zeros.",
  "- Total biomass is reported as median(sum across sections); section shares are based on section medians, so the total is not expected to equal the sum of section medians under skewed posterior uncertainty.",
  "- The current population remains concentrated in a small number of sections.",
  "- Current-year status is useful for communication, but inference should lean on period summaries because annual section estimates can be noisy.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_current_year_status.pdf`",
  "- `Output/diagnostics/m1_stier_11_current_year_status.csv`",
  "- `Output/diagnostics/m1_stier_11_current_year_summary.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_current_year_status.md"))

cat("Saved current-year status:\n")
cat("  Output/diagnostics/m1_stier_11_current_year_status.md\n")
cat("  Output/figures/m1_stier_11_current_year_status.pdf\n")
