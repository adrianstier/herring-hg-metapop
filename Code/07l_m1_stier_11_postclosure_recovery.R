# ============================================================================
# 07l_m1_stier_11_postclosure_recovery.R
# Post-closure section recovery screen from m1_stier_11 posterior medians.
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

section_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
)

total_year <- read_csv(
  file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  filter(report_set == "all_11")

fit_slope <- function(df) {
  df <- df %>% filter(is.finite(median), median > 0)
  if (nrow(df) < 5 || sd(df$year) == 0) {
    return(tibble(log_slope = NA_real_, pct_per_year = NA_real_, r2 = NA_real_))
  }
  mod <- lm(log(median) ~ year, data = df)
  slope <- unname(coef(mod)[["year"]])
  tibble(
    log_slope = slope,
    pct_per_year = 100 * (exp(slope) - 1),
    r2 = summary(mod)$r.squared
  )
}

section_recovery <- section_year %>%
  filter(year >= 2005) %>%
  group_by(site, site_name, focal_status) %>%
  group_modify(~ {
    closure_slope <- fit_slope(.x %>% filter(year >= 2005))
    recent_slope <- fit_slope(.x %>% filter(year >= 2017))
    post_min <- .x %>% slice_min(median, n = 1, with_ties = FALSE)
    recent <- .x %>%
      filter(year >= 2017) %>%
      summarise(recent_median = median(median, na.rm = TRUE), .groups = "drop")
    tibble(
      closure_pct_per_year = closure_slope$pct_per_year,
      closure_r2 = closure_slope$r2,
      recent_pct_per_year = recent_slope$pct_per_year,
      recent_r2 = recent_slope$r2,
      postclosure_min_year = post_min$year,
      postclosure_min_biomass = post_min$median,
      recent_median = recent$recent_median,
      rebound_from_postclosure_min = recent$recent_median / post_min$median
    )
  }) %>%
  ungroup() %>%
  mutate(
    recovery_class = case_when(
      closure_pct_per_year >= 5 & recent_median > postclosure_min_biomass * 2 ~ "clear rebound",
      closure_pct_per_year > 0 ~ "weak positive",
      closure_pct_per_year <= 0 ~ "flat/declining",
      TRUE ~ "uncertain"
    )
  ) %>%
  arrange(desc(closure_pct_per_year))

annual_recovery <- total_year %>%
  filter(year >= 2005) %>%
  mutate(
    rel_to_2005 = median / median[year == 2005],
    log_total = log(median)
  )

p_slopes <- section_recovery %>%
  mutate(site_name = fct_reorder(site_name, closure_pct_per_year)) %>%
  ggplot(aes(x = closure_pct_per_year, y = site_name, fill = recovery_class)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_col(alpha = 0.9) +
  scale_fill_manual(values = c(
    "clear rebound" = "#2166AC",
    "weak positive" = "#67A9CF",
    "flat/declining" = "#B2182B",
    "uncertain" = "grey60"
  )) +
  labs(
    x = "Post-closure trend (% per year), 2005-2025",
    y = NULL,
    fill = NULL,
    title = "Section recovery rates after fishery closure"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_traj <- section_year %>%
  filter(year >= 2005) %>%
  left_join(
    section_recovery %>% select(site, recovery_class),
    by = "site"
  ) %>%
  group_by(site) %>%
  mutate(rel_to_2005 = median / median[year == 2005]) %>%
  ungroup() %>%
  ggplot(aes(x = year, y = rel_to_2005, group = site, colour = recovery_class)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey65") +
  geom_line(alpha = 0.75, linewidth = 0.65) +
  scale_y_log10(labels = label_number(accuracy = 0.1)) +
  scale_colour_manual(values = c(
    "clear rebound" = "#2166AC",
    "weak positive" = "#67A9CF",
    "flat/declining" = "#B2182B",
    "uncertain" = "grey60"
  )) +
  labs(
    x = "Year",
    y = "Relative to 2005",
    colour = NULL,
    title = "Post-closure section trajectories"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_total <- ggplot(annual_recovery, aes(x = year, y = rel_to_2005)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey65") +
  geom_line(colour = "#176B87", linewidth = 0.8) +
  geom_point(colour = "#176B87", size = 1.5) +
  scale_y_log10(labels = label_number(accuracy = 0.1)) +
  labs(
    x = "Year",
    y = "All-11 biomass relative to 2005",
    title = "Archipelago total after closure"
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p <- p_slopes | (p_total / p_traj)

ggsave(
  file.path(fig_dir, "m1_stier_11_postclosure_recovery.pdf"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_postclosure_recovery.png"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(section_recovery, file.path(diag_dir, "m1_stier_11_postclosure_recovery_by_section.csv"))
write_csv(annual_recovery, file.path(diag_dir, "m1_stier_11_postclosure_total_recovery.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier 11 Post-Closure Recovery Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Fastest Positive Post-Closure Trends",
  "",
  paste0(
    "- ",
    head(section_recovery$site_name, 5),
    ": ",
    fmt(head(section_recovery$closure_pct_per_year, 5), 1),
    "% per year, rebound from post-closure minimum = ",
    fmt(head(section_recovery$rebound_from_postclosure_min, 5), 1),
    "x"
  ),
  "",
  "## Weakest Post-Closure Trends",
  "",
  paste0(
    "- ",
    tail(section_recovery$site_name, 5),
    ": ",
    fmt(tail(section_recovery$closure_pct_per_year, 5), 1),
    "% per year, rebound from post-closure minimum = ",
    fmt(tail(section_recovery$rebound_from_postclosure_min, 5), 1),
    "x"
  ),
  "",
  "## Recovery Classes",
  "",
  paste0(
    "- ",
    names(table(section_recovery$recovery_class)),
    ": ",
    as.integer(table(section_recovery$recovery_class)),
    " sections"
  ),
  "",
  "## Interpretation",
  "",
  "- Closure-era recovery is section-specific, not spatially even.",
  "- Sections can show positive post-closure trend and still remain depleted relative to the early baseline.",
  "- This is another reason to prioritize section-specific productivity before adding regional predator covariates.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_postclosure_recovery.pdf`",
  "- `Output/diagnostics/m1_stier_11_postclosure_recovery_by_section.csv`",
  "- `Output/diagnostics/m1_stier_11_postclosure_total_recovery.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_postclosure_recovery.md"))

cat("Saved post-closure recovery diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_postclosure_recovery.md\n")
cat("  Output/figures/m1_stier_11_postclosure_recovery.pdf\n")
