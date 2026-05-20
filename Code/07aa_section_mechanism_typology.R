# ============================================================================
# 07aa_section_mechanism_typology.R
# Consolidate section-level status, pressure, uncertainty, and current biomass.
# ============================================================================

library(tidyverse)
library(here)
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

scorecard <- read_diag("m1_stier_11_section_scorecard.csv")
fishing_decomp <- read_diag("fishing_pressure_decomposition_by_section.csv") %>%
  select(site, fishing_only_resid, pressure_size_resid, catch_share, catch_per_early_biomass)
uncertainty <- read_diag("m1_stier_11_uncertainty_by_section.csv") %>%
  select(site, recent_rel_width_90)
current_status <- read_diag("m1_stier_11_current_year_status.csv") %>%
  select(site, current_share, survey_status, positive, zero_record, missing)

typology <- scorecard %>%
  left_join(fishing_decomp, by = "site") %>%
  left_join(uncertainty, by = "site") %>%
  left_join(current_status, by = "site") %>%
  mutate(
    recent_to_early_class = case_when(
      recent_to_early_ratio < 0.2 ~ "below 20% early",
      recent_to_early_ratio < 0.5 ~ "20-50% early",
      recent_to_early_ratio < 1 ~ "50-100% early",
      TRUE ~ "above early"
    ),
    fishing_pressure_class = case_when(
      mean_fishing_fraction_1951_2004 >= quantile(mean_fishing_fraction_1951_2004, 0.75, na.rm = TRUE) ~ "high",
      mean_fishing_fraction_1951_2004 <= quantile(mean_fishing_fraction_1951_2004, 0.25, na.rm = TRUE) ~ "low",
      TRUE ~ "medium"
    ),
    fishing_residual_class = case_when(
      fishing_only_resid <= quantile(fishing_only_resid, 0.25, na.rm = TRUE) ~ "worse than fishing predicts",
      fishing_only_resid >= quantile(fishing_only_resid, 0.75, na.rm = TRUE) ~ "better than fishing predicts",
      TRUE ~ "near fishing expectation"
    ),
    survey_coverage_class = case_when(
      survey_coverage < 0.4 ~ "low coverage",
      survey_coverage < 0.7 ~ "moderate coverage",
      TRUE ~ "high coverage"
    ),
    uncertainty_class = case_when(
      recent_rel_width_90 >= quantile(recent_rel_width_90, 0.75, na.rm = TRUE) ~ "high uncertainty",
      recent_rel_width_90 <= quantile(recent_rel_width_90, 0.25, na.rm = TRUE) ~ "low uncertainty",
      TRUE ~ "moderate uncertainty"
    ),
    current_share_class = case_when(
      current_share >= 0.2 ~ "major 2025 share",
      current_share >= 0.05 ~ "moderate 2025 share",
      TRUE ~ "minor 2025 share"
    ),
    typology = case_when(
      status == "persistently depleted" &
        fishing_residual_class == "worse than fishing predicts" ~ "persistent depletion beyond fishing",
      status %in% c("persistently depleted", "flat or declining") ~ "depleted or stagnant",
      focal_status == "dropped_from_focal" |
        survey_coverage_class == "low coverage" |
        uncertainty_class == "high uncertainty" ~ "sparse/uncertain sensitivity",
      status == "rebounded above early" ~ "rebounded",
      TRUE ~ "intermediate"
    )
  ) %>%
  arrange(
    factor(
      typology,
      levels = c(
        "persistent depletion beyond fishing",
        "depleted or stagnant",
        "sparse/uncertain sensitivity",
        "intermediate",
        "rebounded"
      )
    ),
    recent_to_early_ratio
  )

write_csv(typology, file.path(diag_dir, "section_mechanism_typology.csv"))

section_order <- rev(typology$site_name)

tile_tbl <- typology %>%
  select(
    site_name, typology, recent_to_early_class, fishing_pressure_class,
    fishing_residual_class, survey_coverage_class, uncertainty_class,
    current_share_class
  ) %>%
  pivot_longer(
    cols = -c(site_name, typology),
    names_to = "axis",
    values_to = "class"
  ) %>%
  mutate(
    axis = recode(
      axis,
      recent_to_early_class = "Recent / early",
      fishing_pressure_class = "Fishing pressure",
      fishing_residual_class = "After-fishing residual",
      survey_coverage_class = "Survey coverage",
      uncertainty_class = "Uncertainty",
      current_share_class = "2025 biomass share"
    ),
    axis = factor(
      axis,
      levels = c(
        "Recent / early", "Fishing pressure", "After-fishing residual",
        "Survey coverage", "Uncertainty", "2025 biomass share"
      )
    ),
    site_name = factor(site_name, levels = section_order)
  )

class_cols <- c(
  "below 20% early" = "#B2182B",
  "20-50% early" = "#EF8A62",
  "50-100% early" = "#FDDBC7",
  "above early" = "#67A9CF",
  "high" = "#B2182B",
  "medium" = "#F4A582",
  "low" = "#92C5DE",
  "worse than fishing predicts" = "#B2182B",
  "near fishing expectation" = "#D9D9D9",
  "better than fishing predicts" = "#2166AC",
  "low coverage" = "#B2182B",
  "moderate coverage" = "#F4A582",
  "high coverage" = "#92C5DE",
  "high uncertainty" = "#B2182B",
  "moderate uncertainty" = "#D9D9D9",
  "low uncertainty" = "#2166AC",
  "major 2025 share" = "#2166AC",
  "moderate 2025 share" = "#67A9CF",
  "minor 2025 share" = "#D9D9D9"
)

p <- ggplot(tile_tbl, aes(x = axis, y = site_name, fill = class)) +
  geom_tile(colour = "white", linewidth = 0.35) +
  scale_fill_manual(values = class_cols, drop = FALSE) +
  labs(
    x = NULL,
    y = NULL,
    fill = NULL,
    title = "Section mechanism typology",
    subtitle = "Each row combines depletion status, fishing pressure, residual outcome, survey coverage, uncertainty, and 2025 concentration."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 25, hjust = 1),
    legend.position = "bottom",
    legend.key.size = unit(3, "mm")
  ) +
  guides(fill = guide_legend(ncol = 3))

ggsave(
  file.path(fig_dir, "section_mechanism_typology.pdf"),
  p,
  width = 210, height = 150, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "section_mechanism_typology.png"),
  p,
  width = 210, height = 150, units = "mm", dpi = 300
)

typology_summary <- typology %>%
  count(typology, name = "n") %>%
  arrange(desc(n), typology)
write_csv(typology_summary, file.path(diag_dir, "section_mechanism_typology_summary.csv"))

section_list <- function(type) {
  typology %>%
    filter(typology == type) %>%
    pull(site_name) %>%
    paste(collapse = "; ")
}

md_lines <- c(
  "# Section Mechanism Typology",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Result",
  "",
  paste0(
    "- Persistent depletion beyond fishing: ",
    section_list("persistent depletion beyond fishing"),
    "."
  ),
  paste0("- Depleted or stagnant: ", section_list("depleted or stagnant"), "."),
  paste0(
    "- Sparse/uncertain sensitivity sections: ",
    section_list("sparse/uncertain sensitivity"),
    "."
  ),
  paste0("- Rebounded sections: ", section_list("rebounded"), "."),
  "",
  "## Interpretation",
  "",
  "- Cumshewa, Louscoone, and Laskeek are the clearest sections where current depletion cannot be reduced to mean fishing pressure alone.",
  "- Tasu and Naden remain useful in the all-11 fit, but their low coverage and uncertainty make them sensitivity sections rather than headline evidence.",
  "- Juan Perez, Skincuttle, and Port Louis dominate the recent/current biomass portfolio, so total biomass can mask depleted sections.",
  "",
  "## Files",
  "",
  "- `Output/figures/section_mechanism_typology.pdf`",
  "- `Output/diagnostics/section_mechanism_typology.csv`",
  "- `Output/diagnostics/section_mechanism_typology_summary.csv`"
)

writeLines(md_lines, file.path(diag_dir, "section_mechanism_typology.md"))

cat("Saved section mechanism typology outputs:\n")
cat("  Output/figures/section_mechanism_typology.pdf\n")
cat("  Output/diagnostics/section_mechanism_typology.md\n")
