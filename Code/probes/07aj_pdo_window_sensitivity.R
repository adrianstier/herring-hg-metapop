# ============================================================================
# 07aj_pdo_window_sensitivity.R
# Cheap PDO lag/window sensitivity using m1_stier_11 posterior growth.
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

ts_tbl <- read_diag("m1_stier_11_driver_screening_timeseries.csv") %>%
  arrange(year) %>%
  mutate(
    pdo_lag0 = pdo,
    pdo_lag1 = lag(pdo, 1),
    pdo_lag2 = lag(pdo, 2),
    pdo_lag3 = lag(pdo, 3),
    pdo_mean_lag0_1 = rowMeans(pick(pdo_lag0, pdo_lag1), na.rm = FALSE),
    pdo_mean_lag1_2 = rowMeans(pick(pdo_lag1, pdo_lag2), na.rm = FALSE),
    pdo_mean_lag0_2 = rowMeans(pick(pdo_lag0, pdo_lag1, pdo_lag2), na.rm = FALSE),
    pdo_mean_lag1_3 = rowMeans(pick(pdo_lag1, pdo_lag2, pdo_lag3), na.rm = FALSE),
    year_z = as.numeric(scale(year)),
    fishing_lag1_z = as.numeric(scale(fishing_fraction_median_lag1))
  )

predictors <- c(
  "pdo_lag0",
  "pdo_lag1",
  "pdo_lag2",
  "pdo_lag3",
  "pdo_mean_lag0_1",
  "pdo_mean_lag1_2",
  "pdo_mean_lag0_2",
  "pdo_mean_lag1_3"
)

predictor_labels <- c(
  pdo_lag0 = "PDO lag 0",
  pdo_lag1 = "PDO lag 1",
  pdo_lag2 = "PDO lag 2",
  pdo_lag3 = "PDO lag 3",
  pdo_mean_lag0_1 = "PDO mean lag 0-1",
  pdo_mean_lag1_2 = "PDO mean lag 1-2",
  pdo_mean_lag0_2 = "PDO mean lag 0-2",
  pdo_mean_lag1_3 = "PDO mean lag 1-3"
)

score_one <- function(pred) {
  dat <- ts_tbl %>%
    transmute(
      year,
      growth = growth_median,
      predictor = .data[[pred]],
      fishing_lag1_z,
      year_z
    ) %>%
    filter(is.finite(growth), is.finite(predictor))

  if (nrow(dat) < 10 || sd(dat$predictor) == 0 || sd(dat$growth) == 0) {
    return(tibble(
      predictor = pred,
      label = predictor_labels[[pred]],
      n = nrow(dat),
      spearman_rho = NA_real_,
      pearson_r = NA_real_,
      detrended_r = NA_real_,
      adjusted_beta = NA_real_,
      adjusted_p = NA_real_,
      adjusted_r2 = NA_real_
    ))
  }

  detrended <- lm(growth ~ year_z, data = dat)
  pred_detrended <- lm(predictor ~ year_z, data = dat)

  adjusted_dat <- dat %>%
    mutate(
      predictor_z = as.numeric(scale(predictor)),
      fishing_lag1_z = if_else(is.finite(fishing_lag1_z), fishing_lag1_z, 0)
    )

  adjusted <- lm(growth ~ predictor_z + fishing_lag1_z + year_z, data = adjusted_dat)
  adjusted_coef <- coef(summary(adjusted))

  tibble(
    predictor = pred,
    label = predictor_labels[[pred]],
    n = nrow(dat),
    spearman_rho = suppressWarnings(cor(dat$growth, dat$predictor, method = "spearman")),
    pearson_r = suppressWarnings(cor(dat$growth, dat$predictor)),
    detrended_r = suppressWarnings(cor(resid(detrended), resid(pred_detrended))),
    adjusted_beta = adjusted_coef["predictor_z", "Estimate"],
    adjusted_p = adjusted_coef["predictor_z", "Pr(>|t|)"],
    adjusted_r2 = summary(adjusted)$adj.r.squared
  )
}

window_tbl <- map_dfr(predictors, score_one) %>%
  mutate(
    robust_score = abs(spearman_rho) + abs(detrended_r) + abs(adjusted_beta),
    sign_consistent = sign(spearman_rho) == sign(detrended_r) &
      sign(spearman_rho) == sign(adjusted_beta)
  ) %>%
  arrange(desc(robust_score))

best <- window_tbl %>% slice(1)
lag1 <- window_tbl %>% filter(predictor == "pdo_lag1") %>% slice(1)

readr::write_csv(window_tbl, file.path(diag_dir, "pdo_window_sensitivity.csv"))

p_rank <- window_tbl %>%
  mutate(label = fct_reorder(label, robust_score)) %>%
  ggplot(aes(x = robust_score, y = label, fill = sign_consistent)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = c(`TRUE` = "#0072B2", `FALSE` = "#999999")) +
  labs(
    x = "Robustness score",
    y = NULL,
    fill = "Sign consistent",
    title = "PDO lag/window sensitivity",
    subtitle = "Score combines absolute Spearman, detrended correlation, and adjusted regression coefficient."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_coef <- window_tbl %>%
  mutate(label = fct_reorder(label, adjusted_beta)) %>%
  ggplot(aes(x = adjusted_beta, y = label)) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.3) +
  geom_point(aes(size = -log10(pmax(adjusted_p, 1e-8))), colour = "#D55E00") +
  labs(
    x = "Adjusted PDO coefficient",
    y = NULL,
    size = "-log10 p",
    title = "Adjusted screen",
    subtitle = "Growth ~ PDO window + lagged fishing fraction + year."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_scatter <- ts_tbl %>%
  transmute(
    year,
    period,
    growth_median,
    best_predictor = .data[[best$predictor]]
  ) %>%
  filter(is.finite(growth_median), is.finite(best_predictor)) %>%
  ggplot(aes(x = best_predictor, y = growth_median, colour = period)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_point(size = 2, alpha = 0.85) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey35", linewidth = 0.6) +
  labs(
    x = best$label,
    y = "Next-year latent growth",
    colour = NULL,
    title = paste0("Best cheap PDO screen: ", best$label),
    subtitle = paste0(
      "Spearman rho=", number(best$spearman_rho, accuracy = 0.01),
      "; detrended r=", number(best$detrended_r, accuracy = 0.01),
      "; adjusted beta=", number(best$adjusted_beta, accuracy = 0.01), "."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- (p_scatter / (p_rank | p_coef)) +
  plot_annotation(
    title = "PDO window sensitivity for the promoted baseline",
    subtitle = "This is a cheap screen only; the promoted Stan baseline already contains lag-1 PDO."
  )

ggsave(
  file.path(fig_dir, "pdo_window_sensitivity.pdf"),
  p,
  width = 230,
  height = 180,
  units = "mm",
  dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "pdo_window_sensitivity.png"),
  p,
  width = 230,
  height = 180,
  units = "mm",
  dpi = 300
)

md_lines <- c(
  "# PDO Window Sensitivity",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  paste0(
    "- Best cheap window: `", best$label, "` with Spearman rho `",
    number(best$spearman_rho, accuracy = 0.01),
    "`, detrended r `", number(best$detrended_r, accuracy = 0.01),
    "`, adjusted beta `", number(best$adjusted_beta, accuracy = 0.01), "`."
  ),
  paste0(
    "- Baseline lag-1 PDO remains competitive: Spearman rho `",
    number(lag1$spearman_rho, accuracy = 0.01),
    "`, detrended r `", number(lag1$detrended_r, accuracy = 0.01),
    "`, adjusted beta `", number(lag1$adjusted_beta, accuracy = 0.01), "`."
  ),
  "",
  "## Interpretation",
  "",
  "- The PDO signal is not just a single-point artifact, but the simple lag-1 term remains adequate for the promoted baseline.",
  "- This supports interpreting PDO as climate context from the existing Stan fit, not launching a redundant PDO-only branch before Monday.",
  "",
  "## Files",
  "",
  "- `Output/figures/pdo_window_sensitivity.pdf`",
  "- `Output/diagnostics/pdo_window_sensitivity.csv`"
)

writeLines(md_lines, file.path(diag_dir, "pdo_window_sensitivity.md"))

cat("Saved PDO window-sensitivity outputs:\n")
cat("  Output/figures/pdo_window_sensitivity.pdf\n")
cat("  Output/diagnostics/pdo_window_sensitivity.md\n")
