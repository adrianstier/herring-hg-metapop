# ============================================================================
# 07h_m1_stier_11_residual_spatial_correlation.R
# Residual spatial-correlation screen for the promoted m1_stier_11 baseline.
# ============================================================================

library(tidyverse)
library(here)
library(readxl)
library(patchwork)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

resid_df <- read_csv(
  file.path(diag_dir, "m1_stier_11_positive_spawn_fit.csv"),
  show_col_types = FALSE
) %>%
  mutate(
    era = if_else(method == "Surface", "surface", "scuba_dive")
  )

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
site_lookup <- tibble(
  site = seq_along(keep_sections),
  section_id = keep_sections
) %>%
  left_join(
    resid_df %>%
      distinct(site, site_name),
    by = "site"
  )

xlsx_path <- file.path(
  proj_dir,
  "Data",
  "raw",
  "Euclidean & effective distance matrices herring & Steller.xlsx"
)

dist_raw <- read_excel(xlsx_path, sheet = "Herring Effective")
section_ids <- as.integer(dist_raw[[1]][1:13])
id_cols <- paste0("Id", section_ids)
D_full <- as.matrix(dist_raw[1:13, id_cols])
D_full <- apply(D_full, 2, as.numeric)
rownames(D_full) <- section_ids
colnames(D_full) <- section_ids

D_km <- D_full[as.character(keep_sections), as.character(keep_sections)] / 1000
D_km <- (D_km + t(D_km)) / 2

pairs <- combn(seq_along(keep_sections), 2, simplify = FALSE)

safe_cor <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 5) {
    return(NA_real_)
  }
  cor(x[ok], y[ok])
}

pair_tbl <- map_dfr(pairs, function(pair) {
  s1 <- pair[[1]]
  s2 <- pair[[2]]

  joined <- resid_df %>%
    filter(site %in% c(s1, s2)) %>%
    select(year, site, era, log_residual) %>%
    pivot_wider(names_from = site, values_from = log_residual, names_prefix = "site_")

  x <- joined[[paste0("site_", s1)]]
  y <- joined[[paste0("site_", s2)]]

  surf <- joined %>% filter(era == "surface")
  dive <- joined %>% filter(era == "scuba_dive")

  tibble(
    site_1 = s1,
    site_2 = s2,
    section_1 = keep_sections[s1],
    section_2 = keep_sections[s2],
    site_name_1 = site_lookup$site_name[match(s1, site_lookup$site)],
    site_name_2 = site_lookup$site_name[match(s2, site_lookup$site)],
    effective_distance_km = D_km[s1, s2],
    n_overlap_all = sum(is.finite(x) & is.finite(y)),
    cor_all = safe_cor(x, y),
    n_overlap_surface = sum(is.finite(surf[[paste0("site_", s1)]]) & is.finite(surf[[paste0("site_", s2)]])),
    cor_surface = safe_cor(surf[[paste0("site_", s1)]], surf[[paste0("site_", s2)]]),
    n_overlap_scuba_dive = sum(is.finite(dive[[paste0("site_", s1)]]) & is.finite(dive[[paste0("site_", s2)]])),
    cor_scuba_dive = safe_cor(dive[[paste0("site_", s1)]], dive[[paste0("site_", s2)]])
  )
})

pair_long <- pair_tbl %>%
  select(
    site_1,
    site_2,
    site_name_1,
    site_name_2,
    effective_distance_km,
    starts_with("n_overlap"),
    starts_with("cor_")
  ) %>%
  pivot_longer(
    cols = starts_with("cor_"),
    names_to = "era",
    values_to = "residual_correlation"
  ) %>%
  mutate(
    era = recode(
      era,
      cor_all = "All positive observations",
      cor_surface = "Surface-era positives",
      cor_scuba_dive = "SCUBA/dive positives"
    ),
    n_overlap = case_when(
      era == "All positive observations" ~ n_overlap_all,
      era == "Surface-era positives" ~ n_overlap_surface,
      TRUE ~ n_overlap_scuba_dive
    )
  ) %>%
  filter(is.finite(residual_correlation), n_overlap >= 5)

era_summary <- pair_long %>%
  group_by(era) %>%
  summarise(
    n_pairs = n(),
    median_pair_correlation = median(residual_correlation, na.rm = TRUE),
    distance_correlation = cor(effective_distance_km, residual_correlation, use = "complete.obs", method = "spearman"),
    .groups = "drop"
  )

nearest_pairs <- pair_tbl %>%
  arrange(effective_distance_km) %>%
  select(
    site_name_1,
    site_name_2,
    effective_distance_km,
    n_overlap_all,
    cor_all,
    n_overlap_surface,
    cor_surface,
    n_overlap_scuba_dive,
    cor_scuba_dive
  ) %>%
  slice_head(n = 10)

p_distance <- ggplot(
  pair_long,
  aes(x = effective_distance_km, y = residual_correlation)
) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_point(aes(size = n_overlap), alpha = 0.75, colour = "#176B87") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#C47F2C", linewidth = 0.7) +
  facet_wrap(~era, ncol = 1) +
  scale_size_continuous(range = c(1.5, 5)) +
  labs(
    x = "Effective distance between sections (km)",
    y = "Pairwise residual correlation",
    size = "Overlap",
    title = "Do m1_stier_11 residuals show spatial structure?",
    subtitle = "Positive-spawn residual correlations by section-pair distance."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

heat_df <- pair_tbl %>%
  select(site_1, site_2, cor_all) %>%
  bind_rows(
    pair_tbl %>%
      transmute(site_1 = site_2, site_2 = site_1, cor_all),
    tibble(site_1 = seq_along(keep_sections), site_2 = seq_along(keep_sections), cor_all = 1)
  ) %>%
  left_join(site_lookup %>% select(site_1 = site, site_name_1 = site_name), by = "site_1") %>%
  left_join(site_lookup %>% select(site_2 = site, site_name_2 = site_name), by = "site_2") %>%
  mutate(
    site_name_1 = factor(site_name_1, levels = site_lookup$site_name),
    site_name_2 = factor(site_name_2, levels = rev(site_lookup$site_name))
  )

p_heat <- ggplot(heat_df, aes(x = site_name_1, y = site_name_2, fill = cor_all)) +
  geom_tile(colour = "white", linewidth = 0.1) +
  scale_fill_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1, 1),
    na.value = "grey85"
  ) +
  labs(
    x = NULL,
    y = NULL,
    fill = "r",
    title = "All-positive residual correlation matrix"
  ) +
  theme_minimal(base_size = 8) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    legend.position = "bottom"
  )

p <- p_distance | p_heat

ggsave(
  file.path(fig_dir, "m1_stier_11_residual_spatial_correlation.pdf"),
  p,
  width = 260,
  height = 170,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_residual_spatial_correlation.png"),
  p,
  width = 260,
  height = 170,
  units = "mm",
  dpi = 300
)

write_csv(pair_tbl, file.path(diag_dir, "m1_stier_11_residual_spatial_pairs.csv"))
write_csv(era_summary, file.path(diag_dir, "m1_stier_11_residual_spatial_summary.csv"))
write_csv(nearest_pairs, file.path(diag_dir, "m1_stier_11_nearest_residual_pairs.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE)
}

lines <- c(
  "# M1 Stier 11 Residual Spatial Correlation",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Summary By Observation Era",
  "",
  paste0(
    "- ",
    era_summary$era,
    ": n pairs = ",
    era_summary$n_pairs,
    ", median residual correlation = ",
    fmt(era_summary$median_pair_correlation, 2),
    ", Spearman distance-correlation = ",
    fmt(era_summary$distance_correlation, 2)
  ),
  "",
  "## Nearest Section Pairs",
  "",
  paste0(
    "- ",
    nearest_pairs$site_name_1,
    " / ",
    nearest_pairs$site_name_2,
    ": distance = ",
    fmt(nearest_pairs$effective_distance_km, 1),
    " km, all-era residual r = ",
    fmt(nearest_pairs$cor_all, 2),
    " (overlap n = ",
    nearest_pairs$n_overlap_all,
    ")"
  ),
  "",
  "## Interpretation",
  "",
  "- This is a residual diagnostic, not a fitted spatial process model.",
  "- If residual correlations decline with effective distance, the next process branch should test a distance-correlated residual process after the section-productivity branch.",
  "- If correlations are weak or method-specific, observation calibration remains the higher priority than spatial process complexity.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_residual_spatial_correlation.pdf`",
  "- `Output/diagnostics/m1_stier_11_residual_spatial_pairs.csv`",
  "- `Output/diagnostics/m1_stier_11_residual_spatial_summary.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_residual_spatial_correlation.md"))

cat("Saved residual spatial-correlation diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_residual_spatial_correlation.md\n")
cat("  Output/figures/m1_stier_11_residual_spatial_correlation.pdf\n")
