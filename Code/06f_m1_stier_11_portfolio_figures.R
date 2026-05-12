# ============================================================================
# 06f_m1_stier_11_portfolio_figures.R
# Regenerate main portfolio figures from the promoted m1_stier_11 outputs.
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

portfolio <- read_diag("m1_stier_11_vs_9_portfolio_metrics.csv") %>%
  mutate(
    report_set = factor(report_set, levels = c("all_11", "focal_9")),
    report_label = recode(
      as.character(report_set),
      all_11 = "All 11 fitted sections",
      focal_9 = "Stier 9 focal sections"
    )
  )

concentration <- read_diag("m1_stier_11_spatial_concentration.csv") %>%
  filter(report_set %in% c("all_11", "focal_9")) %>%
  mutate(
    report_set = factor(report_set, levels = c("all_11", "focal_9")),
    report_label = recode(
      as.character(report_set),
      all_11 = "All 11 fitted sections",
      focal_9 = "Stier 9 focal sections"
    ),
    period = factor(
      period_for_year(year),
      levels = c(
        "1951-1965 early industrial",
        "1966-1971 late reduction",
        "1972-2004 roe fishery",
        "2005-2013 closure",
        "2014-2016 marine heatwave",
        "2017-2025 recent closure"
      )
    )
  )

period_summary <- concentration %>%
  group_by(report_set, report_label, period) %>%
  summarise(
    top3_share = median(top3_share_median, na.rm = TRUE),
    simpson_effective_sections = median(simpson_effective_sections_median, na.rm = TRUE),
    entropy_effective_sections = median(entropy_effective_sections_median, na.rm = TRUE),
    .groups = "drop"
  )

portfolio_summary <- portfolio %>%
  mutate(window_period = period_for_year(window_mid)) %>%
  group_by(report_set, report_label, window_period) %>%
  summarise(
    cv_ratio = median(cv_ratio, na.rm = TRUE),
    synchrony_lm = median(synchrony_lm, na.rm = TRUE),
    .groups = "drop"
  )

recent_summary <- period_summary %>%
  filter(period == "2017-2025 recent closure") %>%
  select(report_set, report_label, top3_share, simpson_effective_sections, entropy_effective_sections) %>%
  left_join(
    portfolio_summary %>%
      filter(window_period == "2017-2025 recent closure") %>%
      select(report_set, cv_ratio, synchrony_lm),
    by = "report_set"
  )

readr::write_csv(period_summary, file.path(diag_dir, "m1_stier_11_portfolio_period_summary.csv"))
readr::write_csv(recent_summary, file.path(diag_dir, "m1_stier_11_portfolio_recent_summary.csv"))

report_cols <- c(
  "All 11 fitted sections" = "#0072B2",
  "Stier 9 focal sections" = "#009E73"
)

p_cv <- portfolio %>%
  ggplot(aes(x = window_mid, y = cv_ratio, colour = report_label)) +
  geom_line(linewidth = 0.75) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_colour_manual(values = report_cols) +
  labs(
    x = NULL,
    y = "Portfolio effect (CV ratio)",
    colour = NULL,
    title = "Portfolio buffering through time",
    subtitle = "Ten-year moving windows from posterior median biomass."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_sync <- portfolio %>%
  ggplot(aes(x = window_mid, y = synchrony_lm, colour = report_label)) +
  geom_line(linewidth = 0.75) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_colour_manual(values = report_cols) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(
    x = "Window midpoint",
    y = "Synchrony",
    colour = NULL,
    title = "Synchrony remains elevated after closure"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_top3 <- concentration %>%
  ggplot(aes(x = year, y = top3_share_median, colour = report_label, fill = report_label)) +
  geom_ribbon(aes(ymin = top3_share_lo90, ymax = top3_share_hi90), alpha = 0.11, colour = NA) +
  geom_line(linewidth = 0.75) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_colour_manual(values = report_cols) +
  scale_fill_manual(values = report_cols) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  labs(
    x = NULL,
    y = "Top-three biomass share",
    colour = NULL,
    fill = NULL,
    title = "Biomass concentration"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_eff <- concentration %>%
  ggplot(aes(x = year, y = simpson_effective_sections_median, colour = report_label, fill = report_label)) +
  geom_ribbon(
    aes(ymin = simpson_effective_sections_lo90, ymax = simpson_effective_sections_hi90),
    alpha = 0.11,
    colour = NA
  ) +
  geom_line(linewidth = 0.75) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_colour_manual(values = report_cols) +
  scale_fill_manual(values = report_cols) +
  labs(
    x = "Year",
    y = "Simpson effective sections",
    colour = NULL,
    fill = NULL,
    title = "Effective biomass-bearing sections"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_period <- period_summary %>%
  filter(report_set == "all_11") %>%
  pivot_longer(
    c(top3_share, simpson_effective_sections),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = recode(
      metric,
      top3_share = "Top-three share",
      simpson_effective_sections = "Simpson effective sections"
    )
  ) %>%
  ggplot(aes(x = period, y = value, fill = metric)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_y_continuous(
    labels = function(x) if_else(x <= 1, percent(x, accuracy = 1), number(x, accuracy = 0.1))
  ) +
  scale_fill_manual(values = c("Top-three share" = "#D55E00", "Simpson effective sections" = "#0072B2")) +
  labs(
    x = NULL,
    y = NULL,
    fill = NULL,
    title = "All-11 portfolio state by period"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 35, hjust = 1),
    legend.position = "bottom"
  )

p <- (p_cv | p_sync) / (p_top3 | p_eff) / p_period +
  plot_layout(heights = c(1, 1, 0.9)) +
  plot_annotation(
    title = "M1 Stier 11 portfolio metrics",
    subtitle = "Regenerated from the promoted baseline; all-11 fit is shown alongside the Stier 9-focal reporting subset."
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_portfolio_metrics_combined.pdf"),
  p,
  width = 240,
  height = 270,
  units = "mm",
  dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_portfolio_metrics_combined.png"),
  p,
  width = 240,
  height = 270,
  units = "mm",
  dpi = 300
)

# Overwrite stale legacy names so "main figures" open the promoted baseline.
ggsave(
  file.path(fig_dir, "portfolio_metrics_combined.pdf"),
  p,
  width = 240,
  height = 270,
  units = "mm",
  dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "portfolio_metrics_combined.png"),
  p,
  width = 240,
  height = 270,
  units = "mm",
  dpi = 300
)

fmt <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
}

recent_all <- recent_summary %>% filter(report_set == "all_11") %>% slice(1)
recent_focal <- recent_summary %>% filter(report_set == "focal_9") %>% slice(1)

md_lines <- c(
  "# M1 Stier 11 Portfolio Metrics",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  paste0(
    "- All-11 recent top-three biomass share: `", percent(recent_all$top3_share, accuracy = 1),
    "`; Simpson effective sections: `", fmt(recent_all$simpson_effective_sections, 2), "`."
  ),
  paste0(
    "- 9-focal recent top-three biomass share: `", percent(recent_focal$top3_share, accuracy = 1),
    "`; Simpson effective sections: `", fmt(recent_focal$simpson_effective_sections, 2), "`."
  ),
  paste0(
    "- Recent synchrony from 10-year windows is `", fmt(recent_all$synchrony_lm, 2),
    "` for all 11 and `", fmt(recent_focal$synchrony_lm, 2), "` for focal 9."
  ),
  "",
  "## Interpretation",
  "",
  "- The portfolio story should be based on this regenerated m1_stier_11 figure, not the stale April 2 portfolio figure.",
  "- Biomass recovery and portfolio recovery remain separate: recent biomass is concentrated and effective-section counts remain low.",
  "",
  "## Files",
  "",
  "- `Output/figures/m1_stier_11_portfolio_metrics_combined.pdf`",
  "- `Output/figures/portfolio_metrics_combined.pdf`",
  "- `Output/diagnostics/m1_stier_11_portfolio_recent_summary.csv`",
  "- `Output/diagnostics/m1_stier_11_portfolio_period_summary.csv`"
)

writeLines(md_lines, file.path(diag_dir, "m1_stier_11_portfolio_metrics.md"))

cat("Saved m1_stier_11 portfolio figures:\n")
cat("  Output/figures/m1_stier_11_portfolio_metrics_combined.pdf\n")
cat("  Output/figures/portfolio_metrics_combined.pdf\n")
