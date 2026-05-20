# ============================================================================
# 07ab_section_change_contribution.R
# Attribute period-to-period biomass changes to individual sections.
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

section_year_tbl <- read_diag("m1_stier_11_section_biomass_by_year.csv")
scorecard <- read_diag("m1_stier_11_section_scorecard.csv") %>%
  select(site, status, focal_status)

period_section_tbl <- section_year_tbl %>%
  group_by(site, site_name, period) %>%
  summarise(period_mean_biomass = mean(median, na.rm = TRUE), .groups = "drop")

wide <- period_section_tbl %>%
  pivot_wider(names_from = period, values_from = period_mean_biomass) %>%
  left_join(scorecard, by = "site")

change_tbl <- wide %>%
  transmute(
    site,
    site_name,
    focal_status,
    status,
    early = `1951-1965 early industrial`,
    roe = `1972-2004 roe fishery`,
    recent = `2017-2025 recent closure`,
    recent_minus_early = recent - early,
    recent_minus_roe = recent - roe,
    recent_to_early_ratio = recent / pmax(early, 1e-6),
    recent_to_roe_ratio = recent / pmax(roe, 1e-6)
  ) %>%
  mutate(
    early_change_share = recent_minus_early / sum(abs(recent_minus_early), na.rm = TRUE),
    roe_change_share = recent_minus_roe / sum(abs(recent_minus_roe), na.rm = TRUE)
  )

total_summary <- tibble(
  comparison = c("recent_minus_early", "recent_minus_roe"),
  total_change = c(
    sum(change_tbl$recent_minus_early, na.rm = TRUE),
    sum(change_tbl$recent_minus_roe, na.rm = TRUE)
  ),
  total_abs_change = c(
    sum(abs(change_tbl$recent_minus_early), na.rm = TRUE),
    sum(abs(change_tbl$recent_minus_roe), na.rm = TRUE)
  )
)

write_csv(change_tbl, file.path(diag_dir, "section_change_contribution.csv"))
write_csv(total_summary, file.path(diag_dir, "section_change_contribution_summary.csv"))

plot_tbl <- change_tbl %>%
  select(site_name, status, recent_minus_early, recent_minus_roe) %>%
  pivot_longer(
    cols = starts_with("recent_minus"),
    names_to = "comparison",
    values_to = "change"
  ) %>%
  mutate(
    comparison = recode(
      comparison,
      recent_minus_early = "Recent closure minus early industrial",
      recent_minus_roe = "Recent closure minus roe fishery"
    ),
    direction = if_else(change >= 0, "gain", "loss")
  )

section_order <- change_tbl %>%
  arrange(recent_minus_early) %>%
  pull(site_name)

p_change <- ggplot(
  plot_tbl,
  aes(x = change, y = factor(site_name, levels = section_order), fill = direction)
) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.35) +
  geom_col(width = 0.72) +
  facet_wrap(~ comparison, scales = "free_x") +
  scale_x_continuous(labels = label_comma()) +
  scale_fill_manual(values = c("gain" = "#0072B2", "loss" = "#D55E00")) +
  labs(
    x = "Change in posterior median biomass",
    y = NULL,
    fill = NULL,
    title = "Which sections drive apparent loss or recovery?",
    subtitle = "Bars show section contributions to period-to-period biomass change under m1_stier_11."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_ratio <- ggplot(
  change_tbl,
  aes(x = recent_to_early_ratio, y = factor(site_name, levels = section_order), colour = status)
) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = 0.2, linetype = "dotted", colour = "firebrick") +
  geom_point(size = 2.5) +
  scale_x_log10(labels = label_number(accuracy = 0.01)) +
  labs(
    x = "Recent / early biomass ratio",
    y = NULL,
    colour = NULL,
    title = "Current status relative to early section baseline"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p <- p_change / p_ratio +
  plot_layout(heights = c(1.2, 1)) +
  plot_annotation(
    title = "Section contribution to archipelago biomass change",
    subtitle = "The recent total masks opposing section-level gains and losses."
  )

ggsave(
  file.path(fig_dir, "section_change_contribution.pdf"),
  p,
  width = 220, height = 185, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "section_change_contribution.png"),
  p,
  width = 220, height = 185, units = "mm", dpi = 300
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

early_gains <- label_change(change_tbl, recent_minus_early, decreasing = TRUE)
early_losses <- label_change(change_tbl, recent_minus_early, decreasing = FALSE)
roe_gains <- label_change(change_tbl, recent_minus_roe, decreasing = TRUE)
roe_losses <- label_change(change_tbl, recent_minus_roe, decreasing = FALSE)

md_lines <- c(
  "# Section Contribution To Biomass Change",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Net recent-minus-early change: `",
    number(total_summary$total_change[total_summary$comparison == "recent_minus_early"], accuracy = 1, big.mark = ","),
    "`."
  ),
  paste0(
    "- Net recent-minus-roe-fishery change: `",
    number(total_summary$total_change[total_summary$comparison == "recent_minus_roe"], accuracy = 1, big.mark = ","),
    "`."
  ),
  paste0("- Largest recent-minus-early gains: ", paste(early_gains, collapse = "; "), "."),
  paste0("- Largest recent-minus-early losses: ", paste(early_losses, collapse = "; "), "."),
  paste0("- Largest recent-minus-roe gains: ", paste(roe_gains, collapse = "; "), "."),
  paste0("- Largest recent-minus-roe losses: ", paste(roe_losses, collapse = "; "), "."),
  "",
  "## Interpretation",
  "",
    "- The apparent closure-era recovery relative to the roe-fishery period is concentrated in a subset of sections.",
    "- Recent biomass remains below the early-industrial section-summed mean because gains in Port Louis, Englefield, and Naden do not offset losses in Skidegate, Louscoone, Laskeek, Skincuttle, and Cumshewa.",
    "- Contributions use period means of annual section posterior medians so the section changes add up; this differs from the separate period-summary table that reports medians of annual archipelago totals.",
  "- Use this as a population-state decomposition, not a causal attribution by itself.",
  "",
  "## Files",
  "",
  "- `Output/figures/section_change_contribution.pdf`",
  "- `Output/diagnostics/section_change_contribution.csv`",
  "- `Output/diagnostics/section_change_contribution_summary.csv`"
)

writeLines(md_lines, file.path(diag_dir, "section_change_contribution.md"))

cat("Saved section-change contribution outputs:\n")
cat("  Output/figures/section_change_contribution.pdf\n")
cat("  Output/diagnostics/section_change_contribution.md\n")
