# ============================================================================
# 07al_positive_spawn_fit_caveat.R
# Compact caveat table for positive-spawn fit quality.
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

method_fit <- read_diag("m1_stier_11_spawn_fit_by_method.csv")
period_fit <- read_diag("m1_stier_11_spawn_fit_by_period.csv")
section_fit <- read_diag("m1_stier_11_spawn_fit_by_section.csv")
worst_resid <- read_diag("m1_stier_11_worst_positive_spawn_residuals.csv")

top_sections <- section_fit %>%
  arrange(desc(rmse)) %>%
  slice_head(n = 5)

top_periods <- period_fit %>%
  arrange(desc(rmse)) %>%
  slice_head(n = 3)

top_residual_clusters <- worst_resid %>%
  slice_head(n = 30) %>%
  count(site_name, method, period, residual_direction, sort = TRUE) %>%
  slice_head(n = 10)

fit_caveat_summary <- tibble(
  claim = c(
    "surface era is the main positive-spawn fit weakness",
    "recent closure positive-spawn fit is much better",
    "worst section fit is concentrated in Skidegate and sparse Naden",
    "largest residuals are individual historical outliers, not recent systematic failure"
  ),
  evidence = c(
    paste0(
      "Surface RMSE ", number(method_fit$rmse[method_fit$method == "Surface"], accuracy = 0.01),
      " with 90% coverage ", percent(method_fit$coverage_90[method_fit$method == "Surface"], accuracy = 1),
      "; SCUBA/dive RMSE ", number(method_fit$rmse[method_fit$method == "SCUBA/dive"], accuracy = 0.01),
      " with coverage ", percent(method_fit$coverage_90[method_fit$method == "SCUBA/dive"], accuracy = 1), "."
    ),
    paste0(
      "Recent closure RMSE ", number(period_fit$rmse[period_fit$period == "2017-2025 recent closure"], accuracy = 0.01),
      " versus early-industrial RMSE ", number(period_fit$rmse[period_fit$period == "1951-1965 early industrial"], accuracy = 0.01),
      "."
    ),
    paste0(
      "Highest section RMSEs: ",
      paste0(top_sections$site_name, "=", number(top_sections$rmse, accuracy = 0.01), collapse = "; "),
      "."
    ),
    paste0(
      "Top residual clusters are dominated by ",
      paste0(
        top_residual_clusters$site_name[1:min(3, nrow(top_residual_clusters))],
        " / ",
        top_residual_clusters$period[1:min(3, nrow(top_residual_clusters))],
        collapse = "; "
      ),
      "."
    )
  ),
  caveat = c(
    "Do not oversell early absolute biomass fit from surface observations.",
    "Recent figures are safer for observed-vs-fitted communication.",
    "Skidegate is a real portfolio concern but also has poor positive-magnitude calibration; Naden is sparse.",
    "Use outlier diagnostics as caveats, not as evidence that the promoted baseline failed overall."
  )
)

write_csv(fit_caveat_summary, file.path(diag_dir, "positive_spawn_fit_caveat_summary.csv"))
write_csv(top_residual_clusters, file.path(diag_dir, "positive_spawn_top_residual_clusters.csv"))

p_method <- method_fit %>%
  mutate(method = fct_reorder(method, rmse)) %>%
  ggplot(aes(x = rmse, y = method, fill = method)) +
  geom_col(alpha = 0.85) +
  geom_text(
    aes(label = paste0("90% cov. ", percent(coverage_90, accuracy = 1))),
    hjust = -0.05,
    size = 2.8
  ) +
  scale_x_continuous(
    limits = c(0, max(method_fit$rmse, na.rm = TRUE) * 1.35),
    labels = label_number(accuracy = 0.1)
  ) +
  scale_fill_manual(values = c("Surface" = "#D55E00", "SCUBA/dive" = "#0072B2")) +
  labs(x = "Positive-spawn log RMSE", y = NULL, title = "A. Survey era") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "none")

p_period <- period_fit %>%
  mutate(period = fct_reorder(period, rmse)) %>%
  ggplot(aes(x = rmse, y = period)) +
  geom_col(fill = "grey65", alpha = 0.9) +
  geom_text(aes(label = number(rmse, accuracy = 0.01)), hjust = -0.08, size = 2.6) +
  scale_x_continuous(
    limits = c(0, max(period_fit$rmse, na.rm = TRUE) * 1.2),
    labels = label_number(accuracy = 0.1)
  ) +
  labs(x = "Positive-spawn log RMSE", y = NULL, title = "B. Period") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_section <- top_sections %>%
  mutate(site_name = fct_reorder(site_name, rmse)) %>%
  ggplot(aes(x = rmse, y = site_name)) +
  geom_col(fill = "#CC79A7", alpha = 0.85) +
  geom_text(aes(label = number(rmse, accuracy = 0.01)), hjust = -0.08, size = 2.6) +
  scale_x_continuous(
    limits = c(0, max(top_sections$rmse, na.rm = TRUE) * 1.2),
    labels = label_number(accuracy = 0.1)
  ) +
  labs(x = "Positive-spawn log RMSE", y = NULL, title = "C. Highest-RMSE sections") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_caveat <- p_method / (p_period | p_section) +
  plot_layout(heights = c(0.8, 1.2)) +
  plot_annotation(
    title = "Positive-spawn fit caveat for the promoted baseline",
    subtitle = "The model is strongest for modern/recent communication and weakest for early surface-era magnitudes."
  )

ggsave(
  file.path(fig_dir, "positive_spawn_fit_caveat.pdf"),
  p_caveat,
  width = 230,
  height = 170,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "positive_spawn_fit_caveat.png"),
  p_caveat,
  width = 230,
  height = 170,
  units = "mm",
  dpi = 300
)

md_lines <- c(
  "# Positive Spawn Fit Caveat",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This memo condenses where the promoted `m1_stier_11` baseline fits positive spawn observations least well.",
  "",
  "## Main Read",
  "",
  paste0(
    "- Surface-era positive-spawn fit is weaker than SCUBA/dive: RMSE `",
    number(method_fit$rmse[method_fit$method == "Surface"], accuracy = 0.01),
    "` versus `",
    number(method_fit$rmse[method_fit$method == "SCUBA/dive"], accuracy = 0.01),
    "`."
  ),
  paste0(
    "- Early-industrial period RMSE is `",
    number(period_fit$rmse[period_fit$period == "1951-1965 early industrial"], accuracy = 0.01),
    "`, while recent-closure RMSE is `",
    number(period_fit$rmse[period_fit$period == "2017-2025 recent closure"], accuracy = 0.01),
    "`."
  ),
  paste0(
    "- Worst section fits: ",
    paste0(top_sections$site_name, " (RMSE ", number(top_sections$rmse, accuracy = 0.01), ")", collapse = "; "),
    "."
  ),
  "",
  "## Interpretation",
  "",
  "- The promoted baseline is strongest for the modern/recent observed-spawn story and weakest for early surface-era magnitude calibration.",
  "- This supports emphasizing section status, portfolio concentration, and period summaries rather than over-reading individual early surface observations.",
  "- Skidegate is both a real depletion/portfolio concern and a fit-caveat section; Naden should stay a sparse-section sensitivity caveat.",
  "",
  "## Top Residual Clusters",
  "",
  knitr::kable(top_residual_clusters, format = "pipe"),
  "",
  "## Files",
  "",
  "- `Output/diagnostics/positive_spawn_fit_caveat_summary.csv`",
  "- `Output/diagnostics/positive_spawn_top_residual_clusters.csv`",
  "- `Output/figures/positive_spawn_fit_caveat.pdf`"
)

writeLines(md_lines, file.path(diag_dir, "positive_spawn_fit_caveat.md"))

cat("Saved positive spawn fit caveat:\n")
cat("  Output/diagnostics/positive_spawn_fit_caveat.md\n")
cat("  Output/figures/positive_spawn_fit_caveat.pdf\n")
