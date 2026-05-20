# ============================================================================
# 07ai_fishing_closure_response.R
# Summarise fishing history, closure response, and section outcomes.
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

fmt_num <- function(x, accuracy = 0.1) {
  if (accuracy <= 0) {
    accuracy <- 1
  }
  number(x, accuracy = accuracy, big.mark = ",")
}

fmt_pct <- function(x, accuracy = 1) {
  percent(x, accuracy = accuracy)
}

driver_ts <- read_diag("m1_stier_11_driver_screening_timeseries.csv") %>%
  mutate(
    period = factor(
      period,
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

section_score <- read_diag("m1_stier_11_section_scorecard.csv")
fishing_decomp <- read_diag("fishing_pressure_decomposition_by_section.csv") %>%
  select(site, catch_share, fishing_only_resid, pressure_size_resid)
concentration <- read_diag("m1_stier_11_spatial_concentration.csv")

concentration_period <- concentration %>%
  filter(report_set == "all_11") %>%
  left_join(driver_ts %>% select(year, period), by = "year")

period_response <- driver_ts %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    biomass_median = median(total_biomass_median, na.rm = TRUE),
    biomass_lo90_median = median(total_biomass_lo90, na.rm = TRUE),
    biomass_hi90_median = median(total_biomass_hi90, na.rm = TRUE),
    occupied_sections_median = median(occupied_sections, na.rm = TRUE),
    surveyed_sections_median = median(surveyed_sections, na.rm = TRUE),
    catch_total = sum(observed_catch_tonnes, na.rm = TRUE),
    catch_median = median(observed_catch_tonnes, na.rm = TRUE),
    fishing_fraction_median = median(fishing_fraction_median, na.rm = TRUE),
    growth_median = median(growth_median, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    concentration_period %>%
      group_by(period) %>%
      summarise(
        top3_share_median = median(top3_share_median, na.rm = TRUE),
        simpson_effective_sections_median = median(simpson_effective_sections_median, na.rm = TRUE),
        .groups = "drop"
      ),
    by = "period"
  )

period_lookup <- function(label, column) {
  period_response %>%
    filter(period == label) %>%
    pull({{ column }}) %>%
    first()
}

roe_biomass <- period_lookup("1972-2004 roe fishery", biomass_median)
recent_biomass <- period_lookup("2017-2025 recent closure", biomass_median)
early_biomass <- period_lookup("1951-1965 early industrial", biomass_median)
roe_fishing <- period_lookup("1972-2004 roe fishery", fishing_fraction_median)
recent_fishing <- period_lookup("2017-2025 recent closure", fishing_fraction_median)
roe_occupied <- period_lookup("1972-2004 roe fishery", occupied_sections_median)
recent_occupied <- period_lookup("2017-2025 recent closure", occupied_sections_median)
recent_top3 <- period_lookup("2017-2025 recent closure", top3_share_median)
recent_eff <- period_lookup("2017-2025 recent closure", simpson_effective_sections_median)

closure_summary <- tibble(
  metric = c(
    "recent_vs_roe_biomass_ratio",
    "recent_vs_early_biomass_ratio",
    "roe_fishing_fraction_median",
    "recent_fishing_fraction_median",
    "roe_occupied_sections_median",
    "recent_occupied_sections_median",
    "recent_top3_biomass_share_median",
    "recent_simpson_effective_sections_median"
  ),
  value = c(
    recent_biomass / roe_biomass,
    recent_biomass / early_biomass,
    roe_fishing,
    recent_fishing,
    roe_occupied,
    recent_occupied,
    recent_top3,
    recent_eff
  )
)

section_response <- section_score %>%
  left_join(fishing_decomp, by = "site") %>%
  mutate(
    fishing_pressure_class = if_else(
      mean_fishing_fraction_1951_2004 >= median(mean_fishing_fraction_1951_2004, na.rm = TRUE),
      "higher historical fishing",
      "lower historical fishing"
    ),
    closure_response_class = case_when(
      recent_to_early_ratio < 0.2 & fishing_only_resid < -0.75 ~ "depleted beyond fishing screen",
      recent_to_early_ratio < 0.2 ~ "persistently depleted",
      closure_pct_per_year > 5 & rebound_from_postclosure_min > 2 ~ "clear closure-era rebound",
      recent_to_early_ratio >= 1 ~ "above early baseline",
      TRUE ~ "partial or weak response"
    ),
    talk_read = case_when(
      closure_response_class == "depleted beyond fishing screen" ~
        "Local productivity, habitat, survey scale, or access history likely matters beyond mean fishing pressure.",
      closure_response_class == "clear closure-era rebound" ~
        "Useful contrast showing post-closure recovery can occur in some sections.",
      closure_response_class == "above early baseline" ~
        "Treat as recovery contrast, with coverage caveats for sparse sections.",
      closure_response_class == "persistently depleted" ~
        "Important portfolio warning even if the archipelago total has partly rebounded.",
      TRUE ~ "Intermediate section; use for context rather than a headline."
    )
  ) %>%
  arrange(recent_to_early_ratio)

lag_fishing_cor <- driver_ts %>%
  filter(is.finite(growth_median), is.finite(fishing_fraction_median_lag1)) %>%
  summarise(
    n = n(),
    spearman_rho = cor(growth_median, fishing_fraction_median_lag1, method = "spearman"),
    pearson_r = cor(growth_median, fishing_fraction_median_lag1)
  )

readr::write_csv(period_response, file.path(diag_dir, "fishing_closure_response_by_period.csv"))
readr::write_csv(section_response, file.path(diag_dir, "fishing_closure_response_by_section.csv"))
readr::write_csv(closure_summary, file.path(diag_dir, "fishing_closure_response_summary.csv"))
readr::write_csv(lag_fishing_cor, file.path(diag_dir, "fishing_closure_growth_correlation.csv"))

period_cols <- c(
  "1951-1965 early industrial" = "#8D6E63",
  "1966-1971 late reduction" = "#B47F2A",
  "1972-2004 roe fishery" = "#D55E00",
  "2005-2013 closure" = "#009E73",
  "2014-2016 marine heatwave" = "#CC79A7",
  "2017-2025 recent closure" = "#0072B2"
)

biomass_y_min <- min(driver_ts$total_biomass_lo90[driver_ts$total_biomass_lo90 > 0], na.rm = TRUE)
biomass_y_max <- max(driver_ts$total_biomass_hi90, na.rm = TRUE)

p_biomass <- ggplot(driver_ts, aes(x = year)) +
  geom_rect(
    data = tibble(
      xmin = 2005,
      xmax = 2025,
      ymin = biomass_y_min * 0.85,
      ymax = biomass_y_max * 1.15
    ),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    inherit.aes = FALSE,
    fill = "#009E73",
    alpha = 0.04
  ) +
  geom_ribbon(
    aes(ymin = total_biomass_lo90, ymax = total_biomass_hi90),
    fill = "#0072B2",
    alpha = 0.13
  ) +
  geom_line(aes(y = total_biomass_median), colour = "#0072B2", linewidth = 0.65) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = NULL,
    y = "Posterior biomass",
    title = "Biomass partly rebounded after fishing closure",
    subtitle = "All-11 posterior median and 90% interval from m1_stier_11."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_fishing <- ggplot(driver_ts, aes(x = year)) +
  geom_col(aes(y = observed_catch_tonnes), fill = "#D55E00", alpha = 0.42) +
  geom_line(
    aes(y = fishing_fraction_median * max(observed_catch_tonnes, na.rm = TRUE)),
    colour = "#101827",
    linewidth = 0.55
  ) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_y_continuous(
    labels = label_comma(),
    sec.axis = sec_axis(
      ~ .x / max(driver_ts$observed_catch_tonnes, na.rm = TRUE),
      labels = percent_format(accuracy = 1),
      name = "Posterior fishing fraction"
    )
  ) +
  labs(
    x = NULL,
    y = "Observed catch",
    title = "Direct fishing pressure drops to zero after 2005"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_period <- period_response %>%
  ggplot(aes(x = period, y = biomass_median, fill = period)) +
  geom_col(width = 0.7, alpha = 0.82) +
  geom_point(
    aes(y = occupied_sections_median * max(biomass_median, na.rm = TRUE) / 11),
    colour = "#101827",
    size = 2
  ) +
  scale_fill_manual(values = period_cols, guide = "none") +
  scale_y_continuous(
    labels = label_comma(),
    sec.axis = sec_axis(
      ~ .x * 11 / max(period_response$biomass_median, na.rm = TRUE),
      breaks = seq(0, 11, by = 2),
      name = "Median occupied sections"
    )
  ) +
  labs(
    x = NULL,
    y = "Median period biomass",
    title = "Biomass recovery does not equal portfolio recovery",
    subtitle = "Bars are period biomass; black points are median occupied sections."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid.minor = element_blank()
  )

p_sections <- ggplot(
  section_response,
  aes(
    x = mean_fishing_fraction_1951_2004,
    y = recent_to_early_ratio,
    colour = closure_response_class,
    size = catch_share
  )
) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey55") +
  geom_hline(yintercept = 0.2, linetype = "dotted", colour = "firebrick") +
  geom_point(alpha = 0.9) +
  geom_text(aes(label = site_name), check_overlap = TRUE, nudge_y = 0.05, size = 2.4) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_y_log10(labels = label_number(accuracy = 0.01)) +
  scale_size_continuous(labels = percent_format(accuracy = 1), range = c(1.8, 6)) +
  labs(
    x = "Mean fishing fraction, 1951-2004",
    y = "Recent / early biomass",
    colour = NULL,
    size = "Catch share",
    title = "Closure-era outcomes are section-specific",
    subtitle = "Fishing pressure matters, but some sections remain more depleted than fishing alone predicts."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p <- (p_biomass | p_fishing) / (p_period | p_sections) +
  plot_annotation(
    title = "Fishing closure response diagnostic",
    subtitle = "The fishery closure removed direct catch pressure, but recovery is uneven and portfolio concentration remains high."
  )

ggsave(
  file.path(fig_dir, "fishing_closure_response.pdf"),
  p,
  width = 240,
  height = 185,
  units = "mm",
  dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "fishing_closure_response.png"),
  p,
  width = 240,
  height = 185,
  units = "mm",
  dpi = 300
)

worse_than_fishing <- section_response %>%
  filter(closure_response_class == "depleted beyond fishing screen") %>%
  transmute(label = paste0(site_name, " (resid ", number(fishing_only_resid, accuracy = 0.01), ")")) %>%
  pull(label)

clear_rebounds <- section_response %>%
  filter(closure_response_class == "clear closure-era rebound") %>%
  transmute(label = paste0(site_name, " (+", number(closure_pct_per_year, accuracy = 0.1), "%/yr)")) %>%
  pull(label)

md_lines <- c(
  "# Fishing Closure Response",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  paste0(
    "- Median recent biomass is `", fmt_num(recent_biomass, 0),
    "`, about `", fmt_num(recent_biomass / roe_biomass, 0.01),
    "x` the roe-fishery median and `", fmt_num(recent_biomass / early_biomass, 0.01),
    "x` the early-industrial median."
  ),
  paste0(
    "- Median fishing fraction dropped from `", fmt_pct(roe_fishing, 0.1),
    "` during the roe fishery to `", fmt_pct(recent_fishing, 0.1),
    "` in the recent closure period."
  ),
  paste0(
    "- Median occupied sections declined from `", fmt_num(roe_occupied, 0.1),
    "` during the roe fishery to `", fmt_num(recent_occupied, 0.1),
    "` recently."
  ),
  paste0(
    "- Recent biomass concentration remains high: top-three share `",
    fmt_pct(recent_top3, 1),
    "`, Simpson effective sections `", fmt_num(recent_eff, 0.01), "`."
  ),
  "",
  "## Section Read",
  "",
  paste0("- More depleted than the fishing screen predicts: ", paste(worse_than_fishing, collapse = "; "), "."),
  paste0("- Clear closure-era rebounds: ", paste(clear_rebounds, collapse = "; "), "."),
  "",
  "## Interpretation",
  "",
  "- Closure removed direct fishing mortality, so persistent depletion is not explained by ongoing catch.",
  "- Historical fishing remains a strong descriptive axis, but the most useful science question is why some sections did not recover after closure.",
  "- The talk should separate aggregate biomass recovery from portfolio recovery: total biomass can rebound while occupied sections and effective sections remain low.",
  "",
  "## Files",
  "",
  "- `Output/figures/fishing_closure_response.pdf`",
  "- `Output/diagnostics/fishing_closure_response_by_period.csv`",
  "- `Output/diagnostics/fishing_closure_response_by_section.csv`",
  "- `Output/diagnostics/fishing_closure_response_summary.csv`"
)

writeLines(md_lines, file.path(diag_dir, "fishing_closure_response.md"))

cat("Saved fishing closure-response outputs:\n")
cat("  Output/figures/fishing_closure_response.pdf\n")
cat("  Output/diagnostics/fishing_closure_response.md\n")
