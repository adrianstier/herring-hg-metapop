# ============================================================================
# 07ax_stier_signal_persistence_summary.R
# Does the original Stier et al. signal persist with the 2025 update?
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
out_path <- file.path(diag_dir, "stier_signal_persistence_summary.md")

read_diag <- function(filename) {
  path <- file.path(diag_dir, filename)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

growth <- read_diag("stier2020_updated_companion_growth_change.csv")
process_dev <- read_diag("stier2020_updated_companion_process_deviations.csv")
portfolio_window <- read_diag("stier2020_updated_fig6_portfolio_metrics.csv")
portfolio_period <- read_diag("m1_stier_11_portfolio_period_summary.csv")
scorecard <- read_diag("m1_stier_11_section_scorecard.csv")

focal_growth <- growth %>%
  filter(reporting == "focal 9")

growth_summary <- tibble(
  metric = c(
    "focal_sections_with_prob_decline_ge_0.75",
    "focal_sections_with_prob_decline_ge_0.90",
    "median_historical_growth",
    "median_post_1994_growth",
    "median_post_minus_historical"
  ),
  value = c(
    sum(focal_growth$prob_decline >= 0.75, na.rm = TRUE),
    sum(focal_growth$prob_decline >= 0.90, na.rm = TRUE),
    median(focal_growth$hist_growth_median, na.rm = TRUE),
    median(focal_growth$post_growth_median, na.rm = TRUE),
    median(focal_growth$post_growth_median - focal_growth$hist_growth_median, na.rm = TRUE)
  )
)

growth_decline_tbl <- focal_growth %>%
  transmute(
    section = site_name,
    `historical growth` = number(hist_growth_median, accuracy = 0.01),
    `post-1994 growth` = number(post_growth_median, accuracy = 0.01),
    `Pr(post < historical)` = percent(prob_decline, accuracy = 1)
  ) %>%
  arrange(desc(`Pr(post < historical)`))

process_period <- process_dev %>%
  mutate(reporting = if_else(
    site_name %in% c("Tasu Sound & Gowgaia Bay", "Naden Harbour"),
    "sparse sensitivity",
    "focal 9"
  )) %>%
  filter(reporting == "focal 9") %>%
  group_by(period) %>%
  summarise(
    n = n(),
    process_sd = sd(delta, na.rm = TRUE),
    process_mad = mad(delta, na.rm = TRUE),
    .groups = "drop"
  )

portfolio_period_focal <- portfolio_period %>%
  filter(report_set == "focal_9") %>%
  transmute(
    period,
    `top-3 share` = percent(top3_share, accuracy = 1),
    `Simpson effective sections` = number(simpson_effective_sections, accuracy = 0.01),
    `entropy effective sections` = number(entropy_effective_sections, accuracy = 0.01)
  )

window_summary <- portfolio_window %>%
  mutate(window_group = case_when(
    window_mid <= 1965 ~ "early windows",
    window_mid >= 2015 ~ "recent windows",
    TRUE ~ "middle windows"
  )) %>%
  group_by(window_group) %>%
  summarise(
    n = n(),
    median_growth_correlation = median(growth_correlation, na.rm = TRUE),
    median_asynchrony = median(asynchrony, na.rm = TRUE),
    median_portfolio_effect = median(portfolio_effect, na.rm = TRUE),
    .groups = "drop"
  )

depleted_sections <- scorecard %>%
  filter(status %in% c("persistently depleted", "flat or declining")) %>%
  transmute(
    section = site_name,
    status = as.character(status),
    `recent/early` = number(recent_to_early_ratio, accuracy = 0.01),
    `post-closure trend` = paste0(number(closure_pct_per_year, accuracy = 0.1), "%/yr"),
    `survey coverage` = percent(survey_coverage, accuracy = 1)
  )

write_csv(growth_summary, file.path(diag_dir, "stier_signal_growth_summary.csv"))
write_csv(process_period, file.path(diag_dir, "stier_signal_process_by_period.csv"))
write_csv(window_summary, file.path(diag_dir, "stier_signal_portfolio_window_summary.csv"))

lines <- c(
  "# Stier Signal Persistence Summary",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This memo asks whether the original Stier et al. metapopulation signal persists after updating the time series through 2025 and using the promoted `m1_stier_11` baseline.",
  "",
  "## Bottom Line",
  "",
  "- Yes, the qualitative signal persists: spatial portfolio structure remains eroded and recent biomass is still concentrated in few sections.",
  "- The realized-growth decline also persists for most focal sections, but it is heterogeneous rather than uniform.",
  "- The process-error story should be communicated as uneven section dynamics and reduced portfolio buffering, not as a single clean archipelago-wide driver.",
  "- Early surface-era positive-spawn magnitudes remain the main observation caveat.",
  "",
  "## Realized Growth",
  "",
  paste0(
    "- Focal sections with posterior Pr(post-1994 growth < historical growth) >= 0.75: ",
    growth_summary$value[growth_summary$metric == "focal_sections_with_prob_decline_ge_0.75"], " / 9."
  ),
  paste0(
    "- Focal sections with posterior Pr(post-1994 growth < historical growth) >= 0.90: ",
    growth_summary$value[growth_summary$metric == "focal_sections_with_prob_decline_ge_0.90"], " / 9."
  ),
  paste0(
    "- Median focal historical growth factor: ",
    number(growth_summary$value[growth_summary$metric == "median_historical_growth"], accuracy = 0.01),
    "; median post-1994 growth factor: ",
    number(growth_summary$value[growth_summary$metric == "median_post_1994_growth"], accuracy = 0.01), "."
  ),
  "",
  knitr::kable(growth_decline_tbl, format = "pipe"),
  "",
  "## Process-Deviation Spread",
  "",
  "Process deviations remain variable, but period-to-period differences are not a standalone causal explanation. Use them as evidence of uneven section shocks and weak portfolio buffering.",
  "",
  knitr::kable(
    process_period %>%
      transmute(
        period,
        n,
        `process sd` = number(process_sd, accuracy = 0.01),
        `process MAD` = number(process_mad, accuracy = 0.01)
      ),
    format = "pipe"
  ),
  "",
  "## Portfolio Persistence",
  "",
  "The spatial portfolio remains concentrated in the recent closure period.",
  "",
  knitr::kable(portfolio_period_focal, format = "pipe"),
  "",
  "Windowed portfolio metrics also show that recent windows have higher synchrony / lower asynchrony than the most asynchronous early windows.",
  "",
  knitr::kable(
    window_summary %>%
      transmute(
        `window group` = window_group,
        n,
        `median growth corr.` = number(median_growth_correlation, accuracy = 0.01),
        `median asynchrony` = number(median_asynchrony, accuracy = 0.01),
        `median portfolio effect` = number(median_portfolio_effect, accuracy = 0.01)
      ),
    format = "pipe"
  ),
  "",
  "## Persistent-Depletion Sections",
  "",
  knitr::kable(depleted_sections, format = "pipe"),
  "",
  "## Files",
  "",
  "- `Output/diagnostics/stier_signal_growth_summary.csv`",
  "- `Output/diagnostics/stier_signal_process_by_period.csv`",
  "- `Output/diagnostics/stier_signal_portfolio_window_summary.csv`",
  "- `Output/figures/stier2020_updated/fig5_realized_growth_updated.pdf`",
  "- `Output/figures/stier2020_updated/fig6_process_portfolio_updated.pdf`",
  "- `Output/diagnostics/positive_spawn_fit_caveat.md`"
)

writeLines(lines, out_path)
cat("Saved Stier signal persistence summary:\n")
cat("  Output/diagnostics/stier_signal_persistence_summary.md\n")
