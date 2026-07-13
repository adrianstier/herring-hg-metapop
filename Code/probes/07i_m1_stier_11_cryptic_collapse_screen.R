# ============================================================================
# 07i_m1_stier_11_cryptic_collapse_screen.R
# Section-level low-biomass screen using m1_stier_11 posterior medians.
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

section_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
)

total_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  filter(report_set == "all_11")

early_baseline <- section_year %>%
  filter(period == "1951-1965 early industrial") %>%
  group_by(site, site_name, focal_status) %>%
  summarise(
    early_median_biomass = median(median, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    threshold_20pct_early = 0.20 * early_median_biomass,
    threshold_10pct_early = 0.10 * early_median_biomass
  )

collapse_df <- section_year %>%
  left_join(early_baseline, by = c("site", "site_name", "focal_status")) %>%
  mutate(
    rel_to_early = median / early_median_biomass,
    below_20pct_early = median < threshold_20pct_early,
    below_10pct_early = median < threshold_10pct_early
  )

annual_collapse <- collapse_df %>%
  group_by(year, period) %>%
  summarise(
    n_sections_below_20pct = sum(below_20pct_early, na.rm = TRUE),
    n_sections_below_10pct = sum(below_10pct_early, na.rm = TRUE),
    n_focal_sections_below_20pct = sum(below_20pct_early & focal_status == "focal_9", na.rm = TRUE),
    n_focal_sections_below_10pct = sum(below_10pct_early & focal_status == "focal_9", na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    total_year %>%
      select(year, total_median = median, total_lo90 = lo90, total_hi90 = hi90),
    by = "year"
  )

period_collapse <- collapse_df %>%
  group_by(period, focal_status) %>%
  summarise(
    median_sections_below_20pct = median(below_20pct_early, na.rm = TRUE),
    mean_section_years_below_20pct = mean(below_20pct_early, na.rm = TRUE),
    .groups = "drop"
  )

recent_section_status <- collapse_df %>%
  filter(period == "2017-2025 recent closure") %>%
  group_by(site, site_name, focal_status) %>%
  summarise(
    recent_median_rel_to_early = median(rel_to_early, na.rm = TRUE),
    recent_years_below_20pct = sum(below_20pct_early, na.rm = TRUE),
    recent_years_below_10pct = sum(below_10pct_early, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(recent_median_rel_to_early)

p_total <- ggplot(annual_collapse, aes(x = year)) +
  geom_ribbon(aes(ymin = total_lo90, ymax = total_hi90), fill = "#176B87", alpha = 0.15) +
  geom_line(aes(y = total_median), colour = "#176B87", linewidth = 0.7) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  labs(
    x = NULL,
    y = "All-11 biomass",
    title = "Archipelago total can recover while sections remain depleted"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_counts <- ggplot(annual_collapse, aes(x = year)) +
  geom_line(aes(y = n_sections_below_20pct), colour = "#B2182B", linewidth = 0.75) +
  geom_line(aes(y = n_focal_sections_below_20pct), colour = "#C47F2C", linewidth = 0.75, linetype = "dashed") +
  scale_y_continuous(breaks = 0:11, limits = c(0, 11)) +
  scale_x_continuous(breaks = seq(1950, 2030, 10)) +
  labs(
    x = "Year",
    y = "Sections below 20% early baseline",
    title = "Cryptic depletion count",
    subtitle = "Solid = all 11 sections; dashed = Stier focal 9."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_heat <- collapse_df %>%
  mutate(
    site_name = factor(site_name, levels = rev(unique(section_year$site_name))),
    rel_plot = pmin(rel_to_early, 2)
  ) %>%
  ggplot(aes(x = year, y = site_name, fill = rel_plot)) +
  geom_tile(colour = "white", linewidth = 0.05) +
  scale_fill_gradientn(
    colours = c("#8B1A1A", "#F4A582", "white", "#4393C3", "#2166AC"),
    values = rescale(c(0, 0.2, 1, 1.5, 2)),
    limits = c(0, 2),
    labels = c("0", "0.5", "1", "1.5", ">=2")
  ) +
  labs(
    x = NULL,
    y = NULL,
    fill = "Relative\nto early",
    title = "Section biomass relative to 1951-1965 baseline"
  ) +
  theme_minimal(base_size = 8) +
  theme(panel.grid = element_blank())

p <- (p_total | p_counts) / p_heat +
  plot_annotation(
    title = "M1 Stier 11 cryptic-collapse screen",
    subtitle = "Low-biomass threshold is 20% of each section's 1951-1965 median posterior biomass."
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_cryptic_collapse_screen.pdf"),
  p,
  width = 240,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_cryptic_collapse_screen.png"),
  p,
  width = 240,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(collapse_df, file.path(diag_dir, "m1_stier_11_section_collapse_status_by_year.csv"))
write_csv(annual_collapse, file.path(diag_dir, "m1_stier_11_annual_cryptic_collapse.csv"))
write_csv(recent_section_status, file.path(diag_dir, "m1_stier_11_recent_cryptic_collapse_status.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

recent_annual <- annual_collapse %>%
  filter(period == "2017-2025 recent closure")

lines <- c(
  "# M1 Stier 11 Cryptic-Collapse Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Definition",
  "",
  "Each section is flagged as low when its annual posterior median biomass is below 20% of that section's 1951-1965 median posterior biomass. This is a screening analogue to substock-collapse thresholds, not a formal reference-point estimate.",
  "",
  "## Recent Closure Summary",
  "",
  paste0(
    "- Median all-11 sections below 20% early baseline in 2017-2025: ",
    fmt(median(recent_annual$n_sections_below_20pct, na.rm = TRUE), 1),
    " / 11."
  ),
  paste0(
    "- Median focal-9 sections below 20% early baseline in 2017-2025: ",
    fmt(median(recent_annual$n_focal_sections_below_20pct, na.rm = TRUE), 1),
    " / 9."
  ),
  "",
  "## Sections With Lowest Recent Relative Biomass",
  "",
  paste0(
    "- ",
    head(recent_section_status$site_name, 6),
    ": recent median / early median = ",
    fmt(head(recent_section_status$recent_median_rel_to_early, 6), 2),
    "; recent years below 20% = ",
    head(recent_section_status$recent_years_below_20pct, 6),
    " / 9"
  ),
  "",
  "## Interpretation",
  "",
  "- This screen distinguishes total-biomass recovery from spatially even recovery.",
  "- Persistent low-biomass sections support a portfolio-erosion story even if the archipelago total is no longer at its minimum.",
  "- Thresholds are relative to an early model baseline and should be treated as diagnostic, not management reference points.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_cryptic_collapse_screen.pdf`",
  "- `Output/diagnostics/m1_stier_11_annual_cryptic_collapse.csv`",
  "- `Output/diagnostics/m1_stier_11_recent_cryptic_collapse_status.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_cryptic_collapse_screen.md"))

cat("Saved cryptic-collapse diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_cryptic_collapse_screen.md\n")
cat("  Output/figures/m1_stier_11_cryptic_collapse_screen.pdf\n")
