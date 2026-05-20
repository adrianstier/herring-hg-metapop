# ============================================================================
# 07t_spawn_index_scale_audit.R
# Compare the legacy Stier SHI scale against the maintained DFO tonnes scale.
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

legacy_path <- file.path(
  proj_dir,
  "Data",
  "raw",
  "legacy-2019",
  "HG_Spawn_Survey_1940_2015.csv"
)
processed_path <- file.path(
  proj_dir,
  "Data",
  "processed",
  "HG_Spawn_Survey_1951_2025_all_sections.csv"
)

legacy <- read_csv(legacy_path, show_col_types = FALSE) %>%
  transmute(
    year,
    section,
    section_name,
    legacy_shi = SHI,
    legacy_records = totalrecords,
    legacy_dive_pct = dive_survey_percent
  )

processed <- read_csv(processed_path, show_col_types = FALSE) %>%
  transmute(
    year,
    section,
    section_name,
    dfo_spawn_tonnes = spawn_index_tonnes,
    dfo_records = totalrecords,
    dfo_dive_pct = dive_survey_pct
  )

scale_overlap <- legacy %>%
  inner_join(processed, by = c("year", "section"), suffix = c("_legacy", "_dfo")) %>%
  mutate(
    section_name = coalesce(section_name_legacy, section_name_dfo),
    both_positive = legacy_shi > 0 & dfo_spawn_tonnes > 0,
    either_positive = legacy_shi > 0 | dfo_spawn_tonnes > 0,
    positive_mismatch = xor(legacy_shi > 0, dfo_spawn_tonnes > 0),
    ratio_shi_per_tonne = if_else(both_positive, legacy_shi / dfo_spawn_tonnes, NA_real_),
    log_ratio = log(ratio_shi_per_tonne),
    log_legacy_shi = log(legacy_shi),
    log_dfo_tonnes = log(dfo_spawn_tonnes),
    era = case_when(
      year <= 1987 ~ "Surface era",
      year <= 1992 ~ "Transition era",
      TRUE ~ "Dive-dominant era"
    )
  ) %>%
  select(
    year,
    section,
    section_name,
    era,
    legacy_shi,
    dfo_spawn_tonnes,
    ratio_shi_per_tonne,
    log_ratio,
    log_legacy_shi,
    log_dfo_tonnes,
    legacy_records,
    dfo_records,
    legacy_dive_pct,
    dfo_dive_pct,
    both_positive,
    either_positive,
    positive_mismatch
  )

positive_overlap <- scale_overlap %>%
  filter(both_positive, is.finite(ratio_shi_per_tonne))

global_summary <- tibble(
  n_overlap_rows = nrow(scale_overlap),
  n_both_positive = nrow(positive_overlap),
  n_positive_mismatch = sum(scale_overlap$positive_mismatch, na.rm = TRUE),
  median_ratio = median(positive_overlap$ratio_shi_per_tonne, na.rm = TRUE),
  mean_ratio = mean(positive_overlap$ratio_shi_per_tonne, na.rm = TRUE),
  lo10_ratio = quantile(positive_overlap$ratio_shi_per_tonne, 0.10, na.rm = TRUE),
  hi90_ratio = quantile(positive_overlap$ratio_shi_per_tonne, 0.90, na.rm = TRUE),
  min_ratio = min(positive_overlap$ratio_shi_per_tonne, na.rm = TRUE),
  max_ratio = max(positive_overlap$ratio_shi_per_tonne, na.rm = TRUE),
  cor_log = cor(
    positive_overlap$log_legacy_shi,
    positive_overlap$log_dfo_tonnes,
    use = "complete.obs"
  )
)

section_summary <- positive_overlap %>%
  group_by(section, section_name) %>%
  summarise(
    n = n(),
    median_ratio = median(ratio_shi_per_tonne, na.rm = TRUE),
    lo10_ratio = quantile(ratio_shi_per_tonne, 0.10, na.rm = TRUE),
    hi90_ratio = quantile(ratio_shi_per_tonne, 0.90, na.rm = TRUE),
    cor_log = cor(log_legacy_shi, log_dfo_tonnes, use = "complete.obs"),
    .groups = "drop"
  ) %>%
  arrange(desc(median_ratio))

era_summary <- positive_overlap %>%
  group_by(era) %>%
  summarise(
    n = n(),
    median_ratio = median(ratio_shi_per_tonne, na.rm = TRUE),
    lo10_ratio = quantile(ratio_shi_per_tonne, 0.10, na.rm = TRUE),
    hi90_ratio = quantile(ratio_shi_per_tonne, 0.90, na.rm = TRUE),
    cor_log = cor(log_legacy_shi, log_dfo_tonnes, use = "complete.obs"),
    .groups = "drop"
  ) %>%
  mutate(era = factor(era, levels = c("Surface era", "Transition era", "Dive-dominant era")))

outlier_summary <- positive_overlap %>%
  arrange(desc(abs(log_ratio - median(log_ratio, na.rm = TRUE)))) %>%
  slice_head(n = 20)

lm_global <- lm(log_legacy_shi ~ log_dfo_tonnes, data = positive_overlap)
lm_section <- lm(log_legacy_shi ~ log_dfo_tonnes + factor(section), data = positive_overlap)
lm_compare <- anova(lm_global, lm_section)

model_summary <- tibble(
  model = c("global_log_linear", "section_intercepts"),
  n_parameters = c(length(coef(lm_global)), length(coef(lm_section))),
  adj_r_squared = c(summary(lm_global)$adj.r.squared, summary(lm_section)$adj.r.squared),
  sigma = c(summary(lm_global)$sigma, summary(lm_section)$sigma),
  aic = c(AIC(lm_global), AIC(lm_section))
)

p_scatter <- ggplot(
  positive_overlap,
  aes(x = dfo_spawn_tonnes, y = legacy_shi, colour = era)
) +
  geom_point(alpha = 0.65, size = 1.3) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, linewidth = 0.6, colour = "grey25") +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "Maintained DFO spawn index tonnes",
    y = "Legacy SHI",
    title = "Legacy SHI and maintained DFO tonnes are related, but not identical",
    subtitle = "Positive overlapping section-years, 1951-2015"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_section <- section_summary %>%
  mutate(section_name = fct_reorder(section_name, median_ratio)) %>%
  ggplot(aes(x = median_ratio, y = section_name)) +
  geom_errorbar(aes(xmin = lo10_ratio, xmax = hi90_ratio), width = 0.18, colour = "grey45") +
  geom_point(size = 2, colour = "#0072B2") +
  scale_x_log10(labels = label_comma()) +
  labs(
    x = "Legacy SHI / DFO tonnes",
    y = NULL,
    title = "The scale conversion varies by section",
    subtitle = "Points are medians; bars are 10th-90th percentile ratios."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_era <- ggplot(positive_overlap, aes(x = era, y = ratio_shi_per_tonne, fill = era)) +
  geom_boxplot(outlier.alpha = 0.25, width = 0.65) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = NULL,
    y = "Legacy SHI / DFO tonnes",
    title = "Scale differences also vary by survey era"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none",
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

p <- p_scatter / (p_section | p_era) +
  plot_annotation(
    title = "Spawn Index Scale Audit",
    subtitle = "A simple constant conversion from DFO tonnes back to legacy SHI would be too crude."
  )

ggsave(
  file.path(fig_dir, "spawn_index_scale_audit.pdf"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "spawn_index_scale_audit.png"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(scale_overlap, file.path(diag_dir, "spawn_index_scale_overlap.csv"))
write_csv(global_summary, file.path(diag_dir, "spawn_index_scale_global_summary.csv"))
write_csv(section_summary, file.path(diag_dir, "spawn_index_scale_by_section.csv"))
write_csv(era_summary, file.path(diag_dir, "spawn_index_scale_by_era.csv"))
write_csv(outlier_summary, file.path(diag_dir, "spawn_index_scale_outliers.csv"))
write_csv(model_summary, file.path(diag_dir, "spawn_index_scale_model_summary.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

top_section_lines <- section_summary %>%
  slice_head(n = 5) %>%
  transmute(
    line = paste0(
      "- ",
      section_name,
      ": median ratio ",
      fmt(median_ratio, 1),
      " (n=",
      n,
      ")."
    )
  ) %>%
  pull(line)

low_section_lines <- section_summary %>%
  slice_tail(n = 5) %>%
  transmute(
    line = paste0(
      "- ",
      section_name,
      ": median ratio ",
      fmt(median_ratio, 1),
      " (n=",
      n,
      ")."
    )
  ) %>%
  pull(line)

era_lines <- era_summary %>%
  transmute(
    line = paste0(
      "- ",
      era,
      ": median ratio ",
      fmt(median_ratio, 1),
      ", 10th-90th percentile ",
      fmt(lo10_ratio, 1),
      " to ",
      fmt(hi90_ratio, 1),
      "."
    )
  ) %>%
  pull(line)

lines <- c(
  "# Spawn Index Scale Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Positive overlapping section-years: ",
    global_summary$n_both_positive,
    "."
  ),
  paste0(
    "- Median legacy SHI / DFO tonnes ratio: ",
    fmt(global_summary$median_ratio, 1),
    "."
  ),
  paste0(
    "- 10th-90th percentile ratio: ",
    fmt(global_summary$lo10_ratio, 1),
    " to ",
    fmt(global_summary$hi90_ratio, 1),
    "."
  ),
  paste0(
    "- Full ratio range: ",
    fmt(global_summary$min_ratio, 1),
    " to ",
    fmt(global_summary$max_ratio, 1),
    "."
  ),
  paste0(
    "- Log-scale correlation between the two indices: ",
    fmt(global_summary$cor_log, 3),
    "."
  ),
  "",
  "Interpretation: `spawn_index_tonnes` is internally consistent, but it is not a simple numeric continuation of the legacy SHI scale. q absorbs the absolute scale in the current model, but a legacy-SHI sensitivity cannot be produced by multiplying DFO tonnes by one constant.",
  "",
  "## Section Differences",
  "",
  "Highest median ratios:",
  "",
  top_section_lines,
  "",
  "Lowest median ratios:",
  "",
  low_section_lines,
  "",
  "## Era Differences",
  "",
  era_lines,
  "",
  "## Model Check",
  "",
  paste0(
    "- Global log-linear adjusted R2: ",
    fmt(model_summary$adj_r_squared[model_summary$model == "global_log_linear"], 3),
    "; residual sigma: ",
    fmt(model_summary$sigma[model_summary$model == "global_log_linear"], 3),
    "."
  ),
  paste0(
    "- Section-intercept adjusted R2: ",
    fmt(model_summary$adj_r_squared[model_summary$model == "section_intercepts"], 3),
    "; residual sigma: ",
    fmt(model_summary$sigma[model_summary$model == "section_intercepts"], 3),
    "."
  ),
  "",
  "## Decision",
  "",
  "- Do not describe `spawn_index_tonnes` as the same scale as Stier's legacy SHI.",
  "- Do not copy numerical q values from the legacy SHI model into the DFO-tonnes model.",
  "- If a legacy-scale sensitivity is needed, reconstruct it from the legacy SHI data through 2015 or build a section-aware calibration model; do not use a single global multiplier.",
  "",
  "## Files",
  "",
  "- `Output/figures/spawn_index_scale_audit.pdf`",
  "- `Output/diagnostics/spawn_index_scale_global_summary.csv`",
  "- `Output/diagnostics/spawn_index_scale_by_section.csv`",
  "- `Output/diagnostics/spawn_index_scale_by_era.csv`",
  "- `Output/diagnostics/spawn_index_scale_model_summary.csv`"
)

writeLines(lines, file.path(diag_dir, "spawn_index_scale_audit.md"))
cat(paste(lines, collapse = "\n"))
cat("\n")
