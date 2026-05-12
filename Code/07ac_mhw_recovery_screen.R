# ============================================================================
# 07ac_mhw_recovery_screen.R
# Summarize marine heatwave-period changes in the m1_stier_11 posterior states.
# ============================================================================

library(tidyverse)
library(here)
library(scales)
library(patchwork)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(filename) {
  path <- file.path(diag_dir, filename)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

driver_ts <- read_diag("m1_stier_11_driver_screening_timeseries.csv")
period_summary <- read_diag("m1_stier_11_period_summary.csv")
section_year <- read_diag("m1_stier_11_section_biomass_by_year.csv")
scorecard <- read_diag("m1_stier_11_section_scorecard.csv") %>%
  select(site, status, focal_status)

closure_periods <- c("2005-2013 closure", "2014-2016 marine heatwave", "2017-2025 recent closure")

mhw_summary <- period_summary %>%
  filter(period %in% closure_periods) %>%
  select(
    period, total_biomass_median, occupied_sections, fishing_fraction,
    pdo, growth_median
  )

section_mhw <- section_year %>%
  filter(period %in% closure_periods) %>%
  group_by(site, site_name, period) %>%
  summarise(period_mean_biomass = mean(median, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = period, values_from = period_mean_biomass) %>%
  left_join(scorecard, by = "site") %>%
  mutate(
    mhw_minus_pre = `2014-2016 marine heatwave` - `2005-2013 closure`,
    recent_minus_pre = `2017-2025 recent closure` - `2005-2013 closure`,
    recent_minus_mhw = `2017-2025 recent closure` - `2014-2016 marine heatwave`,
    recent_to_pre_ratio = `2017-2025 recent closure` / pmax(`2005-2013 closure`, 1e-6),
    recent_to_mhw_ratio = `2017-2025 recent closure` / pmax(`2014-2016 marine heatwave`, 1e-6)
  ) %>%
  arrange(recent_minus_pre)

write_csv(mhw_summary, file.path(diag_dir, "mhw_recovery_period_summary.csv"))
write_csv(section_mhw, file.path(diag_dir, "mhw_recovery_by_section.csv"))

p_total_y_min <- min(driver_ts$total_biomass_median[driver_ts$total_biomass_median > 0], na.rm = TRUE) * 0.85
p_total_y_max <- max(driver_ts$total_biomass_median, na.rm = TRUE) * 1.15
growth_y_min <- min(driver_ts$growth_median, na.rm = TRUE) * 1.10
growth_y_max <- max(driver_ts$growth_median, na.rm = TRUE) * 1.10
section_order <- section_mhw$site_name

p_total <- ggplot(driver_ts, aes(x = year)) +
  annotate(
    "rect",
    xmin = 2014, xmax = 2016,
    ymin = p_total_y_min, ymax = p_total_y_max,
    fill = "firebrick", alpha = 0.08
  ) +
  geom_line(aes(y = total_biomass_median), colour = "#0072B2", linewidth = 0.7) +
  geom_ribbon(aes(ymin = total_biomass_median * 0.98, ymax = total_biomass_median * 1.02), alpha = 0) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "Total posterior median biomass",
    title = "Archipelago biomass through closure and MHW window",
    subtitle = "Red band marks 2014-2016 marine heatwave period."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_growth <- driver_ts %>%
  filter(year >= 2005, !is.na(growth_median)) %>%
  ggplot(aes(x = year, y = growth_median, colour = period)) +
  annotate(
    "rect",
    xmin = 2014, xmax = 2016,
    ymin = growth_y_min, ymax = growth_y_max,
    fill = "firebrick", alpha = 0.08
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(size = 2) +
  geom_line(alpha = 0.5) +
  labs(
    x = "Year",
    y = "Latent growth",
    colour = NULL,
    title = "Closure-era growth"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_section <- ggplot(
  section_mhw,
  aes(
    x = recent_minus_pre,
    y = factor(site_name, levels = section_order),
    fill = status
  )
) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.35) +
  geom_col(width = 0.72) +
  scale_x_continuous(labels = label_comma()) +
  labs(
    x = "Recent closure minus pre-MHW closure biomass",
    y = NULL,
    fill = NULL,
    title = "Section changes since the pre-MHW closure period"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p <- p_total / (p_growth | p_section) +
  plot_layout(heights = c(1, 1.15)) +
  plot_annotation(
    title = "Marine heatwave and closure-era recovery screen",
    subtitle = "The MHW window does not explain all spatial recovery/depletion patterns."
  )

ggsave(
  file.path(fig_dir, "mhw_recovery_screen.pdf"),
  p,
  width = 230, height = 185, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "mhw_recovery_screen.png"),
  p,
  width = 230, height = 185, units = "mm", dpi = 300
)

label_change <- function(df, col, n = 3, decreasing = TRUE) {
  if (decreasing) {
    df <- arrange(df, desc({{ col }}))
  } else {
    df <- arrange(df, {{ col }})
  }
  df %>%
    slice_head(n = n) %>%
    transmute(label = paste0(site_name, " ", number({{ col }}, accuracy = 1, big.mark = ","))) %>%
    pull(label)
}

recent_pre_gains <- label_change(section_mhw, recent_minus_pre, decreasing = TRUE)
recent_pre_losses <- label_change(section_mhw, recent_minus_pre, decreasing = FALSE)
recent_mhw_gains <- label_change(section_mhw, recent_minus_mhw, decreasing = TRUE)
recent_mhw_losses <- label_change(section_mhw, recent_minus_mhw, decreasing = FALSE)

period_line <- function(period, col) {
  mhw_summary %>%
    filter(.data$period == !!period) %>%
    pull({{ col }}) %>%
    first()
}

md_lines <- c(
  "# Marine Heatwave And Recovery Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Period Summary",
  "",
  paste0(
    "- Total biomass median: pre-MHW closure `",
    number(period_line("2005-2013 closure", total_biomass_median), accuracy = 1, big.mark = ","),
    "`, MHW `",
    number(period_line("2014-2016 marine heatwave", total_biomass_median), accuracy = 1, big.mark = ","),
    "`, recent closure `",
    number(period_line("2017-2025 recent closure", total_biomass_median), accuracy = 1, big.mark = ","),
    "`."
  ),
  paste0(
    "- Occupied sections: pre-MHW `",
    number(period_line("2005-2013 closure", occupied_sections), accuracy = 0.1),
    "`, MHW `",
    number(period_line("2014-2016 marine heatwave", occupied_sections), accuracy = 0.1),
    "`, recent `",
    number(period_line("2017-2025 recent closure", occupied_sections), accuracy = 0.1),
    "`."
  ),
  "",
  "## Section Changes",
  "",
  paste0("- Largest recent-minus-pre-MHW gains: ", paste(recent_pre_gains, collapse = "; "), "."),
  paste0("- Largest recent-minus-pre-MHW losses: ", paste(recent_pre_losses, collapse = "; "), "."),
  paste0("- Largest recent-minus-MHW gains: ", paste(recent_mhw_gains, collapse = "; "), "."),
  paste0("- Largest recent-minus-MHW losses: ", paste(recent_mhw_losses, collapse = "; "), "."),
  "",
  "## Interpretation",
  "",
  "- The 2014-2016 heatwave window is a useful temporal marker, but it does not by itself explain the section-level recovery/depletion typology.",
  "- Closure-era biomass increases are concentrated in a few sections, while several depleted focal sections remain low after the MHW window.",
  "- Treat MHW as a period/context effect unless a future covariate branch improves calibration.",
  "",
  "## Files",
  "",
  "- `Output/figures/mhw_recovery_screen.pdf`",
  "- `Output/diagnostics/mhw_recovery_period_summary.csv`",
  "- `Output/diagnostics/mhw_recovery_by_section.csv`"
)

writeLines(md_lines, file.path(diag_dir, "mhw_recovery_screen.md"))

cat("Saved MHW recovery screen outputs:\n")
cat("  Output/figures/mhw_recovery_screen.pdf\n")
cat("  Output/diagnostics/mhw_recovery_screen.md\n")
