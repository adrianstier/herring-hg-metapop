# ============================================================================
# 07af_section_narrative_table.R
# One-row-per-section synthesis table for rapid interpretation.
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

read_diag <- function(filename) {
  path <- file.path(diag_dir, filename)
  if (!file.exists(path)) {
    stop("Required diagnostic file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

typology <- read_diag("section_mechanism_typology.csv")
change_tbl <- read_diag("section_change_contribution.csv")
mhw_tbl <- read_diag("mhw_recovery_by_section.csv")
survey_tbl <- read_diag("survey_coverage_zero_ambiguity_by_section.csv") %>%
  select(site, section, first_positive_year, last_positive_year, first_surveyed_year, last_surveyed_year)

residual_clusters <- read_diag("positive_spawn_top_residual_clusters.csv") %>%
  group_by(site_name) %>%
  summarise(
    top_residual_cluster_n = sum(n, na.rm = TRUE),
    top_residual_context = paste0(
      method[which.max(n)], " / ",
      period[which.max(n)], " / ",
      residual_direction[which.max(n)]
    ),
    .groups = "drop"
  )

recent_early_change <- change_tbl %>%
  select(site, contribution_recent_minus_early = recent_minus_early)

recent_roe_change <- change_tbl %>%
  select(site, contribution_recent_minus_roe = recent_minus_roe)

mhw_change <- mhw_tbl %>%
  select(site, recent_minus_pre_mhw = recent_minus_pre, recent_minus_mhw)

narrative_tbl <- typology %>%
  left_join(recent_early_change, by = "site") %>%
  left_join(recent_roe_change, by = "site") %>%
  left_join(mhw_change, by = "site") %>%
  left_join(survey_tbl, by = "site") %>%
  left_join(residual_clusters, by = "site_name") %>%
  mutate(
    top_residual_cluster_n = replace_na(top_residual_cluster_n, 0),
    top_residual_context = replace_na(top_residual_context, "no dominant residual cluster"),
    talk_role = case_when(
      typology == "persistent depletion beyond fishing" ~ "mechanism scrutiny",
      typology == "depleted or stagnant" ~ "portfolio concern",
      typology == "sparse/uncertain sensitivity" ~ "sensitivity caveat",
      typology == "rebounded" ~ "recovery contrast",
      TRUE ~ "intermediate context"
    ),
    main_caveat = case_when(
      survey_coverage < 0.25 ~ "very sparse survey coverage",
      top_residual_cluster_n >= 3 ~ "historical positive-spawn fit caveat",
      spawn_fit_rmse > 1.5 ~ "weak positive-spawn fit",
      recent_rel_width_90 > 10 ~ "wide recent posterior uncertainty",
      TRUE ~ "standard uncertainty"
    ),
    headline_sentence = case_when(
      typology == "persistent depletion beyond fishing" ~
        paste0(site_name, " remains depleted after accounting for fishing pressure and should be a primary mechanistic focus."),
      typology == "depleted or stagnant" ~
        paste0(site_name, " is depleted or stagnant and contributes to portfolio weakness."),
      typology == "sparse/uncertain sensitivity" ~
        paste0(site_name, " is retained in the 11-section fit but should be treated mainly as a sparse-data sensitivity."),
      typology == "rebounded" ~
        paste0(site_name, " provides a recovery contrast against persistently depleted sections."),
      TRUE ~
        paste0(site_name, " is intermediate and helps separate total-biomass recovery from portfolio recovery.")
    )
  ) %>%
  arrange(
    factor(talk_role, levels = c("mechanism scrutiny", "portfolio concern", "intermediate context", "recovery contrast", "sensitivity caveat")),
    recent_to_early_ratio
  ) %>%
  select(
    site, site_name, focal_status, talk_role, typology, headline_sentence,
    recent_to_early_ratio, recent_biomass_share, current_share,
    contribution_recent_minus_early, contribution_recent_minus_roe,
    mean_fishing_fraction_1951_2004, fishing_only_resid, catch_share,
    survey_coverage, surveyed_years, zero_record_years, missing_years,
    first_surveyed_year, last_surveyed_year,
    recent_rel_width_90, spawn_fit_rmse, spawn_fit_bias,
    top_residual_cluster_n, top_residual_context,
    recent_minus_pre_mhw, recent_minus_mhw,
    main_caveat
  )

metric_plot <- narrative_tbl %>%
  transmute(
    site_name = fct_reorder(site_name, recent_to_early_ratio),
    `Recent / early biomass` = log10(pmax(recent_to_early_ratio, 1e-6)),
    `Fishing residual` = fishing_only_resid,
    `Survey coverage` = survey_coverage,
    `Recent uncertainty` = -log10(pmax(recent_rel_width_90, 1e-6)),
    `Current share` = current_share
  ) %>%
  pivot_longer(-site_name, names_to = "metric", values_to = "value") %>%
  group_by(metric) %>%
  mutate(
    metric_min = min(value, na.rm = TRUE),
    metric_max = max(value, na.rm = TRUE),
    scaled_value = if_else(
      metric_max == metric_min,
      0,
      2 * (value - metric_min) / (metric_max - metric_min) - 1
    )
  ) %>%
  ungroup() %>%
  select(-metric_min, -metric_max)

p_matrix <- ggplot(metric_plot, aes(x = metric, y = site_name, fill = scaled_value)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  scale_fill_gradient2(
    low = "#B2182B",
    mid = "grey92",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Relative\nwithin metric"
  ) +
  labs(
    x = NULL,
    y = NULL,
    title = "Section-level diagnostic matrix",
    subtitle = "Blue is relatively high or favourable within a metric; red is relatively low or concerning."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "bottom"
  )

p_roles <- narrative_tbl %>%
  mutate(site_name = fct_reorder(site_name, recent_to_early_ratio)) %>%
  ggplot(aes(x = recent_to_early_ratio, y = site_name, colour = talk_role, size = survey_coverage)) +
  geom_vline(xintercept = 0.2, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_point(alpha = 0.9) +
  scale_x_log10(labels = label_number(accuracy = 0.01)) +
  scale_size_continuous(labels = percent, range = c(2, 6)) +
  labs(
    x = "Recent / early biomass ratio",
    y = NULL,
    colour = NULL,
    size = "Survey\ncoverage",
    title = "Section roles for interpretation",
    subtitle = "Dashed line marks 20% of early section baseline."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p <- p_matrix / p_roles +
  plot_layout(heights = c(1.1, 1)) +
  plot_annotation(
    title = "Section narrative synthesis",
    subtitle = "A compact guide to which sections carry the strongest population and mechanism evidence."
  )

ggsave(
  file.path(fig_dir, "section_narrative_synthesis.pdf"),
  p,
  width = 220, height = 190, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "section_narrative_synthesis.png"),
  p,
  width = 220, height = 190, units = "mm", dpi = 300
)

write_csv(narrative_tbl, file.path(diag_dir, "section_narrative_synthesis.csv"))

md_tbl <- narrative_tbl %>%
  transmute(
    section = site_name,
    role = talk_role,
    typology,
    `recent/early` = number(recent_to_early_ratio, accuracy = 0.01),
    `fishing residual` = number(fishing_only_resid, accuracy = 0.01),
    `survey coverage` = percent(survey_coverage, accuracy = 1),
    `top residual context` = top_residual_context,
    caveat = main_caveat
  )

lines <- c(
  "# Section Narrative Synthesis",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This table combines the current `m1_stier_11` section diagnostics into one interpretation layer. It is meant for analysis triage, not as a final slide.",
  "",
  "## Main Grouping",
  "",
  "- Mechanism scrutiny: sections depleted beyond what the simple fishing-pressure screen predicts.",
  "- Portfolio concern: sections that remain depleted or stagnant but are less cleanly separated from fishing pressure.",
  "- Recovery contrast: sections that help show recovery is spatially uneven.",
  "- Sensitivity caveat: sections retained in the 11-section fit but too sparse/uncertain for headline inference.",
  "- Historical positive-spawn fit caveats identify sections where the promoted baseline has large residual clusters, especially in the surface-survey era.",
  "",
  knitr::kable(md_tbl, format = "pipe"),
  "",
  "## Outputs",
  "",
  "- `Output/figures/section_narrative_synthesis.pdf`",
  "- `Output/diagnostics/section_narrative_synthesis.csv`"
)

writeLines(lines, file.path(diag_dir, "section_narrative_synthesis.md"))

cat("Saved section narrative synthesis:\n")
cat("  Output/figures/section_narrative_synthesis.pdf\n")
cat("  Output/diagnostics/section_narrative_synthesis.md\n")
