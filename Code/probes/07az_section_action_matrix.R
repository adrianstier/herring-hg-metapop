# ============================================================================
# 07az_section_action_matrix.R
# Section-level action matrix for interpreting current population state.
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
  readr::read_csv(path, show_col_types = FALSE)
}

fmt_num <- function(x, accuracy = 0.01) {
  scales::number(x, accuracy = accuracy)
}

fmt_pct <- function(x, accuracy = 1) {
  scales::percent(x, accuracy = accuracy)
}

narrative <- read_diag("section_narrative_synthesis.csv")
scorecard <- read_diag("m1_stier_11_section_scorecard.csv") %>%
  select(site, recovery_class, recent_years_below_20pct, recent_years_below_10pct,
         spawn_fit_coverage_90, closure_pct_per_year)
current <- read_diag("m1_stier_11_current_year_status.csv") %>%
  select(site, biomass_median, biomass_lo90, biomass_hi90, current_survey_status = survey_status)
tail_tbl <- read_diag("current_biomass_uncertainty_by_section.csv") %>%
  select(site, section_set, p_gt_100k_t, p_gt_500k_t, biomass_hi90_tail = hi90)
mhw <- read_diag("mhw_recovery_by_section.csv") %>%
  select(site, recent_to_pre_ratio, recent_to_mhw_ratio)

section_action <- narrative %>%
  left_join(scorecard, by = "site") %>%
  left_join(current, by = "site") %>%
  left_join(tail_tbl, by = "site") %>%
  left_join(mhw, by = "site") %>%
  mutate(
    section_set = replace_na(section_set, "Stier focal 9"),
    p_gt_100k_t = replace_na(p_gt_100k_t, 0),
    p_gt_500k_t = replace_na(p_gt_500k_t, 0),
    evidence_score = 100 -
      if_else(focal_status != "focal_9", 35, 0) -
      if_else(survey_coverage < 0.40, 25, 0) -
      if_else(spawn_fit_rmse > 1.50, 20, 0) -
      if_else(recent_rel_width_90 > 10, 15, 0) -
      if_else(spawn_fit_coverage_90 < 0.60, 10, 0),
    evidence_score = pmin(100, pmax(0, evidence_score)),
    evidence_grade = case_when(
      evidence_score >= 75 ~ "high",
      evidence_score >= 50 ~ "medium",
      TRUE ~ "low"
    ),
    problem_axis = case_when(
      focal_status != "focal_9" ~ "sparse-data sensitivity",
      recent_to_early_ratio < 0.20 & fishing_only_resid < -1 ~ "depletion beyond fishing",
      recent_to_early_ratio < 0.20 ~ "persistent depletion",
      recent_to_early_ratio < 0.50 ~ "portfolio erosion",
      current_share >= 0.20 ~ "current biomass concentration",
      recent_to_early_ratio >= 1.50 ~ "recovery contrast",
      TRUE ~ "intermediate state"
    ),
    driver_hypothesis = case_when(
      focal_status != "focal_9" ~
        "survey/data limitation dominates; do not use for driver inference",
      problem_axis == "depletion beyond fishing" ~
        "local productivity, habitat, access/governance, or spatial exposure beyond fishing",
      problem_axis == "persistent depletion" ~
        "persistent low biomass; fishing may contribute but is not sufficient",
      problem_axis == "portfolio erosion" & mean_fishing_fraction_1951_2004 >= 0.07 ~
        "historical fishing is a major axis, with unresolved recovery limitation",
      problem_axis == "portfolio erosion" ~
        "recovery limitation or local conditions beyond fishing pressure",
      problem_axis == "current biomass concentration" ~
        "dominant current biomass source; important for portfolio concentration",
      problem_axis == "recovery contrast" ~
        "positive contrast for post-closure recovery under the same regional climate",
      TRUE ~
        "context section for separating total biomass from portfolio recovery"
    ),
    next_analysis = case_when(
      focal_status != "focal_9" ~
        "keep in all-11 sensitivity; present focal-9 sensitivity and improve survey-history priors",
      site_name %in% c("Cumshewa Inlet", "Louscoone Inlet") ~
        "target local data audit: survey access, spawn habitat, local predator exposure, and post-closure observations",
      site_name == "Skidegate Inlet" ~
        "audit historical surface-era residuals before using this section for causal inference",
      talk_role == "portfolio concern" ~
        "use in portfolio-erosion story; test local covariates only after observation calibration remains stable",
      talk_role == "recovery contrast" ~
        "use as positive-control recovery contrast against depleted focal sections",
      current_share >= 0.20 ~
        "use as current biomass concentration evidence, not as full portfolio recovery",
      TRUE ~
        "keep as supporting context in section heterogeneity narrative"
    ),
    talk_use = case_when(
      site_name %in% c("Cumshewa Inlet", "Louscoone Inlet") ~ "lead mechanism cases",
      talk_role == "portfolio concern" ~ "portfolio erosion cases",
      current_share >= 0.20 ~ "current biomass concentration cases",
      talk_role == "recovery contrast" ~ "positive recovery contrasts",
      focal_status != "focal_9" ~ "uncertainty sensitivity only",
      TRUE ~ "supporting context"
    ),
    priority_order = case_when(
      talk_use == "lead mechanism cases" ~ 1,
      talk_use == "portfolio erosion cases" ~ 2,
      talk_use == "current biomass concentration cases" ~ 3,
      talk_use == "positive recovery contrasts" ~ 4,
      talk_use == "supporting context" ~ 5,
      TRUE ~ 6
    )
  ) %>%
  arrange(priority_order, desc(evidence_score), recent_to_early_ratio) %>%
  select(
    site, site_name, focal_status, talk_use, priority_order, problem_axis, evidence_grade,
    evidence_score, driver_hypothesis, next_analysis,
    biomass_median, biomass_lo90, biomass_hi90, current_share,
    recent_to_early_ratio, recent_biomass_share,
    fishing_only_resid, mean_fishing_fraction_1951_2004,
    closure_pct_per_year, recent_years_below_20pct,
    survey_coverage, spawn_fit_rmse, spawn_fit_coverage_90,
    recent_rel_width_90, p_gt_100k_t, p_gt_500k_t,
    main_caveat, top_residual_context
  )

write_csv(section_action, file.path(diag_dir, "section_action_matrix.csv"))

metric_plot <- section_action %>%
  transmute(
    site_name = fct_reorder(site_name, priority_order, .desc = TRUE),
    `depletion\nseverity` = pmin(1, pmax(0, -log10(pmax(recent_to_early_ratio, 1e-4)) / 2)),
    `beyond-fishing\nconcern` = pmin(1, pmax(0, -fishing_only_resid / 2.25)),
    `positive-fit\nconcern` = pmin(1, pmax(0, spawn_fit_rmse / 2.75)),
    `survey/uncertainty\nconcern` = pmin(1, pmax(0, (100 - evidence_score) / 100)),
    `current-share\nimportance` = pmin(1, current_share / max(current_share, na.rm = TRUE)),
    `tail-risk\nimportance` = pmin(1, p_gt_100k_t / max(p_gt_100k_t, na.rm = TRUE))
  ) %>%
  pivot_longer(-site_name, names_to = "metric", values_to = "value")

p_matrix <- ggplot(metric_plot, aes(x = metric, y = site_name, fill = value)) +
  geom_tile(colour = "white", linewidth = 0.35) +
  scale_fill_gradient(
    low = "grey95",
    high = "#B2182B",
    limits = c(0, 1),
    labels = percent,
    name = "Relative\npriority"
  ) +
  labs(
    x = NULL,
    y = NULL,
    title = "Section action matrix",
    subtitle = "Darker cells mark sections that most need interpretation, caution, or follow-up for that metric."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "bottom"
  )

p_priority <- section_action %>%
  mutate(
    site_name = fct_reorder(site_name, priority_order, .desc = TRUE),
    evidence_grade = factor(evidence_grade, levels = c("high", "medium", "low"))
  ) %>%
  ggplot(aes(x = recent_to_early_ratio, y = site_name, colour = talk_use, shape = evidence_grade)) +
  geom_vline(xintercept = 0.2, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_vline(xintercept = 1, linetype = "dotted", colour = "grey60", linewidth = 0.35) +
  geom_point(aes(size = current_share), alpha = 0.9) +
  scale_x_log10(labels = label_number(accuracy = 0.01)) +
  scale_size_continuous(labels = percent, range = c(2.4, 7)) +
  labs(
    x = "Recent / early biomass ratio",
    y = NULL,
    colour = NULL,
    shape = "Evidence",
    size = "2025\nshare",
    title = "How to use each section",
    subtitle = "Dashed line marks 20% of early baseline; dotted line marks parity with early baseline."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p <- p_matrix / p_priority +
  plot_layout(heights = c(1.05, 1)) +
  plot_annotation(
    title = "Haida Gwaii herring section action matrix",
    subtitle = "Built from the promoted m1_stier_11 baseline and current diagnostic suite."
  )

ggsave(
  file.path(fig_dir, "section_action_matrix.pdf"),
  p,
  width = 230, height = 190, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "section_action_matrix.png"),
  p,
  width = 230, height = 190, units = "mm", dpi = 300
)

lead_tbl <- section_action %>%
  transmute(
    section = site_name,
    `talk use` = talk_use,
    `problem axis` = problem_axis,
    evidence = evidence_grade,
    `recent/early` = fmt_num(recent_to_early_ratio),
    `2025 share` = fmt_pct(current_share),
    `fit RMSE` = fmt_num(spawn_fit_rmse),
    caveat = main_caveat,
    `next action` = next_analysis
  )

group_summary <- section_action %>%
  group_by(talk_use) %>%
  summarise(
    n = n(),
    sections = paste(site_name, collapse = "; "),
    median_recent_to_early = median(recent_to_early_ratio, na.rm = TRUE),
    total_current_share = sum(current_share, na.rm = TRUE),
    median_evidence_score = median(evidence_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(match(talk_use, unique(section_action$talk_use))) %>%
  transmute(
    `talk use` = talk_use,
    n,
    sections,
    `median recent/early` = fmt_num(median_recent_to_early),
    `2025 share` = fmt_pct(total_current_share),
    `median evidence score` = fmt_num(median_evidence_score, 1)
  )

lines <- c(
  "# Section Action Matrix",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This is the current section-by-section work plan from the promoted `m1_stier_11` baseline. It is deliberately not another causal model; it tells us where inference is strongest, where the story is concentrated, and where follow-up should go next.",
  "",
  "## Fast Read",
  "",
  "- Lead mechanism cases: Cumshewa and Louscoone remain the strongest depletion-beyond-fishing targets.",
  "- Portfolio erosion cases: Skidegate, Laskeek, and Rennell weaken the spatial portfolio, but Skidegate has a major historical positive-spawn fit caveat.",
  "- Current biomass concentration cases: Juan Perez and Skincuttle carry much of the current focal biomass; that is concentration, not portfolio recovery.",
  "- Recovery contrasts: Port Louis and Englefield show that post-closure recovery is possible under the same regional climate backdrop.",
  "- Uncertainty sensitivity only: Tasu and Naden should not drive headline inference; they explain much of the all-11 biomass upper tail.",
  "",
  "## Group Summary",
  "",
  knitr::kable(group_summary, format = "pipe"),
  "",
  "## Section Matrix",
  "",
  knitr::kable(lead_tbl, format = "pipe"),
  "",
  "## Interpretation Rules",
  "",
  "- Use the focal-9 estimate beside all-11 biomass whenever Tasu/Naden uncertainty matters.",
  "- Do not treat current biomass concentration in Juan Perez/Skincuttle as restored portfolio structure.",
  "- Treat Skidegate results as important but observation-limited because residual problems cluster in the early surface era.",
  "- Prioritize local data audits for Cumshewa/Louscoone before adding another regional predator branch.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/section_action_matrix.pdf`",
  "- `Output/figures/section_action_matrix.png`",
  "- `Output/diagnostics/section_action_matrix.csv`"
)

writeLines(lines, file.path(diag_dir, "section_action_matrix.md"))

cat("Saved section action matrix:\n")
cat("  Output/diagnostics/section_action_matrix.md\n")
cat("  Output/figures/section_action_matrix.pdf\n")
