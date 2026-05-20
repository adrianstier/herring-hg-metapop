# ============================================================================
# 07u_legacy_shi_overlap_sensitivity.R
# Check whether observed section patterns through 2015 depend on legacy SHI vs
# maintained DFO tonnes.
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

legacy <- read_csv(
  file.path(proj_dir, "Data", "raw", "legacy-2019", "HG_Spawn_Survey_1940_2015.csv"),
  show_col_types = FALSE
) %>%
  filter(section %in% keep_sections, year >= 1951, year <= 2015) %>%
  transmute(
    year,
    section,
    section_name,
    report_set = if_else(section %in% focal_sections, "focal_9", "all_11_only"),
    legacy_shi = if_else(SHI > 0, SHI, NA_real_),
    legacy_positive = SHI > 0
  )

dfo <- read_csv(
  file.path(proj_dir, "Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
) %>%
  filter(section %in% keep_sections, year >= 1951, year <= 2015) %>%
  transmute(
    year,
    section,
    dfo_tonnes = if_else(spawn_index_tonnes > 0, spawn_index_tonnes, NA_real_),
    dfo_positive = spawn_index_tonnes > 0
  )

overlap <- legacy %>%
  left_join(dfo, by = c("year", "section")) %>%
  mutate(
    period = case_when(
      year <= 1965 ~ "1951-1965 early industrial",
      year <= 2004 ~ "1972-2004 roe fishery",
      TRUE ~ "2005-2015 closure overlap"
    )
  )

annual_totals <- overlap %>%
  group_by(year) %>%
  summarise(
    legacy_total = sum(legacy_shi, na.rm = TRUE),
    dfo_total = sum(dfo_tonnes, na.rm = TRUE),
    legacy_occupied = sum(legacy_positive, na.rm = TRUE),
    dfo_occupied = sum(dfo_positive, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    legacy_scaled = legacy_total / median(legacy_total[year <= 1965 & legacy_total > 0], na.rm = TRUE),
    dfo_scaled = dfo_total / median(dfo_total[year <= 1965 & dfo_total > 0], na.rm = TRUE)
  )

period_section <- overlap %>%
  group_by(section, section_name, report_set, period) %>%
  summarise(
    legacy_mean_positive = mean(legacy_shi, na.rm = TRUE),
    dfo_mean_positive = mean(dfo_tonnes, na.rm = TRUE),
    legacy_n_positive = sum(legacy_positive, na.rm = TRUE),
    dfo_n_positive = sum(dfo_positive, na.rm = TRUE),
    .groups = "drop"
  )

section_ratios <- period_section %>%
  select(section, section_name, report_set, period, legacy_mean_positive, dfo_mean_positive) %>%
  pivot_wider(
    names_from = period,
    values_from = c(legacy_mean_positive, dfo_mean_positive)
  ) %>%
  mutate(
    legacy_recent_early = `legacy_mean_positive_2005-2015 closure overlap` /
      `legacy_mean_positive_1951-1965 early industrial`,
    dfo_recent_early = `dfo_mean_positive_2005-2015 closure overlap` /
      `dfo_mean_positive_1951-1965 early industrial`,
    legacy_roe_early = `legacy_mean_positive_1972-2004 roe fishery` /
      `legacy_mean_positive_1951-1965 early industrial`,
    dfo_roe_early = `dfo_mean_positive_1972-2004 roe fishery` /
      `dfo_mean_positive_1951-1965 early industrial`
  )

section_ratio_summary <- section_ratios %>%
  mutate(
    robust_direction = case_when(
      !is.finite(legacy_recent_early) | !is.finite(dfo_recent_early) ~ "insufficient_overlap",
      legacy_recent_early < 1 & dfo_recent_early < 1 ~ "lower_recent_both_scales",
      legacy_recent_early > 1 & dfo_recent_early > 1 ~ "higher_recent_both_scales",
      TRUE ~ "scale_sensitive_direction"
    )
  ) %>%
  arrange(dfo_recent_early)

scale_agreement <- tibble(
  metric = c(
    "annual_total_log_correlation",
    "annual_occupied_correlation",
    "section_recent_early_log_correlation",
    "section_recent_early_spearman"
  ),
  value = c(
    cor(log10(annual_totals$legacy_total + 1), log10(annual_totals$dfo_total + 1)),
    cor(annual_totals$legacy_occupied, annual_totals$dfo_occupied),
    cor(log10(section_ratios$legacy_recent_early), log10(section_ratios$dfo_recent_early), use = "complete.obs"),
    cor(section_ratios$legacy_recent_early, section_ratios$dfo_recent_early, method = "spearman", use = "complete.obs")
  )
)

p_annual <- annual_totals %>%
  select(year, legacy_scaled, dfo_scaled) %>%
  pivot_longer(-year, names_to = "scale", values_to = "scaled_total") %>%
  mutate(scale = recode(scale, legacy_scaled = "Legacy SHI", dfo_scaled = "DFO tonnes")) %>%
  ggplot(aes(x = year, y = scaled_total, colour = scale)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.1, alpha = 0.75) +
  scale_y_log10(labels = label_number()) +
  scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
  labs(
    x = "Year",
    y = "Annual positive-signal total, scaled to early median",
    colour = NULL,
    title = "Observed annual signal is broadly similar across scales",
    subtitle = "Totals ignore zero/missing cells and are only a scale diagnostic."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_section <- ggplot(
  section_ratio_summary %>%
    filter(
      is.finite(dfo_recent_early),
      is.finite(legacy_recent_early),
      dfo_recent_early > 0,
      legacy_recent_early > 0
    ),
  aes(x = dfo_recent_early, y = legacy_recent_early, label = section_name)
) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_hline(yintercept = 1, linetype = "dotted", colour = "grey60") +
  geom_vline(xintercept = 1, linetype = "dotted", colour = "grey60") +
  geom_point(aes(colour = robust_direction), size = 2.2) +
  ggrepel::geom_text_repel(size = 2.4, max.overlaps = Inf, show.legend = FALSE) +
  scale_x_log10(labels = label_number()) +
  scale_y_log10(labels = label_number()) +
  labs(
    x = "DFO tonnes recent / early",
    y = "Legacy SHI recent / early",
    colour = NULL,
    title = "Section recent/early direction is mostly robust",
    subtitle = "Ratios use positive observations through 2015 only."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_occupancy <- annual_totals %>%
  ggplot(aes(x = dfo_occupied, y = legacy_occupied)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_point(alpha = 0.8, size = 1.6, colour = "#0072B2") +
  scale_x_continuous(breaks = 0:11, limits = c(0, 11)) +
  scale_y_continuous(breaks = 0:11, limits = c(0, 11)) +
  labs(
    x = "DFO positive sections",
    y = "Legacy positive sections",
    title = "Observed occupancy is nearly identical across scales"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- p_annual / (p_section | p_occupancy) +
  plot_annotation(
    title = "Legacy SHI Overlap Sensitivity",
    subtitle = "Through 2015, the scale choice changes magnitudes more than the broad spatial story."
  )

ggsave(
  file.path(fig_dir, "legacy_shi_overlap_sensitivity.pdf"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "legacy_shi_overlap_sensitivity.png"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(overlap, file.path(diag_dir, "legacy_shi_overlap_cells.csv"))
write_csv(annual_totals, file.path(diag_dir, "legacy_shi_overlap_annual_totals.csv"))
write_csv(period_section, file.path(diag_dir, "legacy_shi_overlap_period_section.csv"))
write_csv(section_ratio_summary, file.path(diag_dir, "legacy_shi_overlap_section_ratios.csv"))
write_csv(scale_agreement, file.path(diag_dir, "legacy_shi_overlap_scale_agreement.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

depleted_both <- section_ratio_summary %>%
  filter(robust_direction == "lower_recent_both_scales") %>%
  arrange(dfo_recent_early) %>%
  pull(section_name)

higher_both <- section_ratio_summary %>%
  filter(robust_direction == "higher_recent_both_scales") %>%
  arrange(desc(dfo_recent_early)) %>%
  pull(section_name)

scale_sensitive <- section_ratio_summary %>%
  filter(robust_direction == "scale_sensitive_direction") %>%
  pull(section_name)

insufficient_overlap <- section_ratio_summary %>%
  filter(robust_direction == "insufficient_overlap") %>%
  pull(section_name)

lines <- c(
  "# Legacy SHI Overlap Sensitivity",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Annual total positive-signal log correlation: ",
    fmt(scale_agreement$value[scale_agreement$metric == "annual_total_log_correlation"], 3),
    "."
  ),
  paste0(
    "- Annual occupied-section correlation: ",
    fmt(scale_agreement$value[scale_agreement$metric == "annual_occupied_correlation"], 3),
    "."
  ),
  paste0(
    "- Section recent/early Spearman correlation: ",
    fmt(scale_agreement$value[scale_agreement$metric == "section_recent_early_spearman"], 3),
    "."
  ),
  "",
  "Interpretation: through the shared 1951-2015 window, legacy SHI and DFO tonnes do not share a simple numeric scale, but the broad observed annual and section-direction patterns are similar enough that the current population story is not obviously an artifact of using tonnes.",
  "",
  "## Section Direction",
  "",
  paste0("- Lower recent than early under both scales: ", paste(depleted_both, collapse = "; "), "."),
  paste0("- Higher recent than early under both scales: ", paste(higher_both, collapse = "; "), "."),
  paste0(
    "- Direction differs by scale: ",
    ifelse(length(scale_sensitive) == 0, "none", paste(scale_sensitive, collapse = "; ")),
    "."
  ),
  paste0(
    "- Insufficient early/recent positive overlap: ",
    ifelse(length(insufficient_overlap) == 0, "none", paste(insufficient_overlap, collapse = "; ")),
    "."
  ),
  "",
  "## Caveat",
  "",
  "This is an observed-data overlap check, not a posterior state-space refit. It ignores ambiguous zeros and ends in 2015, so it cannot replace the `m1_stier_11` posterior. It is useful for deciding whether a legacy-SHI refit is likely to change the broad story.",
  "",
  "## Files",
  "",
  "- `Output/figures/legacy_shi_overlap_sensitivity.pdf`",
  "- `Output/diagnostics/legacy_shi_overlap_scale_agreement.csv`",
  "- `Output/diagnostics/legacy_shi_overlap_section_ratios.csv`",
  "- `Output/diagnostics/legacy_shi_overlap_annual_totals.csv`"
)

writeLines(lines, file.path(diag_dir, "legacy_shi_overlap_sensitivity.md"))
cat(paste(lines, collapse = "\n"))
cat("\n")
