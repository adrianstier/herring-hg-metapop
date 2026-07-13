library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

fit_path <- file.path(data_dir, "m1_stier_method_sensitivity_fit.rds")
if (!file.exists(fit_path)) {
  stop("m1_stier_method_sensitivity_fit.rds not found. Run Code/03_fit_m1_stier_method_sensitivity.R first.")
}

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(fit_path)
post <- rstan::extract(fit, pars = c("X", "log_q", "Umu", "pdocoef", "sigma_proc", "sigma_obs"))

method_labels <- c("Surface", "Mixed transition", "Dive-dominant")
method_cols <- c(
  "Surface" = "#D55E00",
  "Mixed transition" = "#CC79A7",
  "Dive-dominant" = "#0072B2"
)

summarise_draws <- function(x) {
  tibble(
    mean = mean(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE)
  )
}

q_summary <- map_dfr(seq_along(method_labels), function(i) {
  summarise_draws(post$log_q[, i]) %>%
    mutate(
      method = method_labels[i],
      q_median = exp(median),
      q_lo90 = exp(lo90),
      q_hi90 = exp(hi90),
      years = paste(range(jags_data$years[jags_data$q_idx == i]), collapse = "-"),
      n_years = sum(jags_data$q_idx == i),
      n_positive_obs = sum(jags_data$Y_obs[jags_data$q_idx == i, , drop = FALSE] == 1L),
      .before = 1
    )
})

global_summary <- bind_rows(
  summarise_draws(post$Umu) %>% mutate(parameter = "Umu"),
  summarise_draws(post$pdocoef) %>% mutate(parameter = "pdocoef"),
  summarise_draws(post$sigma_proc) %>% mutate(parameter = "sigma_proc"),
  summarise_draws(post$sigma_obs) %>% mutate(parameter = "sigma_obs")
) %>%
  select(parameter, everything())

positive_cells <- which(jags_data$Y_obs == 1L, arr.ind = TRUE)
cell_fit <- map_dfr(seq_len(nrow(positive_cells)), function(i) {
  t <- positive_cells[i, "row"]
  j <- positive_cells[i, "col"]
  m <- jags_data$q_idx[t]
  fitted_draws <- post$X[, t, j] + post$log_q[, m]
  tibble(
    year = jags_data$years[t],
    site = j,
    site_name = jags_data$site_names[j],
    method = factor(method_labels[m], levels = method_labels),
    observed_log = jags_data$Y[t, j],
    fitted_log_median = median(fitted_draws, na.rm = TRUE),
    fitted_log_lo90 = quantile(fitted_draws, 0.05, na.rm = TRUE),
    fitted_log_hi90 = quantile(fitted_draws, 0.95, na.rm = TRUE)
  )
}) %>%
  mutate(
    observed = exp(observed_log),
    fitted_median = exp(fitted_log_median),
    fitted_lo90 = exp(fitted_log_lo90),
    fitted_hi90 = exp(fitted_log_hi90),
    log_resid = fitted_log_median - observed_log
  )

method_fit_summary <- cell_fit %>%
  group_by(method) %>%
  summarise(
    n = n(),
    log_rmse = sqrt(mean(log_resid^2, na.rm = TRUE)),
    log_bias = mean(log_resid, na.rm = TRUE),
    cor_log = cor(observed_log, fitted_log_median, use = "complete.obs"),
    .groups = "drop"
  )

residual_year <- cell_fit %>%
  group_by(year, method) %>%
  summarise(
    median_log_resid = median(log_resid, na.rm = TRUE),
    lo90_log_resid = quantile(log_resid, 0.05, na.rm = TRUE),
    hi90_log_resid = quantile(log_resid, 0.95, na.rm = TRUE),
    .groups = "drop"
  )

year_fit <- map_dfr(seq_along(jags_data$years), function(t) {
  idx <- which(jags_data$Y_obs[t, ] == 1L)
  if (length(idx) == 0) {
    return(tibble())
  }
  m <- jags_data$q_idx[t]
  fit_draws <- apply(
    exp(sweep(post$X[, t, idx, drop = FALSE], 1, post$log_q[, m], "+")),
    1,
    sum
  )
  tibble(
    year = jags_data$years[t],
    method = factor(method_labels[m], levels = method_labels),
    observed_signal = sum(exp(jags_data$Y[t, idx]), na.rm = TRUE),
    fitted_signal = median(fit_draws, na.rm = TRUE),
    fitted_lo90 = quantile(fit_draws, 0.05, na.rm = TRUE),
    fitted_hi90 = quantile(fit_draws, 0.95, na.rm = TRUE),
    n_positive = length(idx)
  )
})

p_q <- q_summary %>%
  mutate(method = factor(method, levels = method_labels)) %>%
  ggplot(aes(x = method, y = q_median, ymin = q_lo90, ymax = q_hi90, colour = method)) +
  geom_pointrange(linewidth = 0.45) +
  scale_colour_manual(values = method_cols, guide = "none") +
  scale_y_log10(labels = label_number(accuracy = 0.01)) +
  labs(
    x = NULL,
    y = "q = exp(log_q)",
    title = "Estimated survey-era q",
    subtitle = "Three-era sensitivity: surface, mixed transition, and dive-dominant years."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_fit <- ggplot(year_fit, aes(x = year, colour = method, fill = method)) +
  geom_ribbon(aes(ymin = fitted_lo90, ymax = fitted_hi90), alpha = 0.14, colour = NA) +
  geom_line(aes(y = fitted_signal), linewidth = 0.65) +
  geom_point(aes(y = observed_signal, shape = method), size = 1.7, alpha = 0.9) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  scale_shape_manual(values = c(16, 17, 15)) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "Aggregate positive spawn signal",
    title = "Observed vs fitted positive signal by survey era",
    subtitle = "Points are observed positive-cell totals; lines/ribbons are fitted values on those same cells.",
    colour = NULL,
    fill = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p_resid <- ggplot(residual_year, aes(x = year, colour = method, fill = method)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_ribbon(aes(ymin = lo90_log_resid, ymax = hi90_log_resid), alpha = 0.14, colour = NA) +
  geom_line(aes(y = median_log_resid), linewidth = 0.65) +
  geom_point(aes(y = median_log_resid), size = 1.4, alpha = 0.85) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "median fitted log spawn - observed log spawn",
    title = "Annual positive-cell residual summaries",
    subtitle = "Positive values indicate overprediction on the log spawn scale.",
    colour = NULL,
    fill = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

p <- p_q / p_fit / p_resid +
  plot_annotation(
    title = "M1 Stier Method-Sensitivity Postfit Diagnostic",
    subtitle = "Checks whether a three-era q split improves the Stier-aligned positive-only baseline."
  )

ggsave(
  file.path(fig_dir, "m1_stier_method_sensitivity_postfit.pdf"),
  p,
  width = 220, height = 260, units = "mm", device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_method_sensitivity_postfit.png"),
  p,
  width = 220, height = 260, units = "mm", dpi = 300
)

write_csv(q_summary, file.path(diag_dir, "m1_stier_method_sensitivity_q_summary.csv"))
write_csv(global_summary, file.path(diag_dir, "m1_stier_method_sensitivity_global_parameters.csv"))
write_csv(method_fit_summary, file.path(diag_dir, "m1_stier_method_sensitivity_method_fit_summary.csv"))
write_csv(year_fit, file.path(diag_dir, "m1_stier_method_sensitivity_year_fit.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier Method-Sensitivity Postfit Diagnostic",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## q by Survey Era",
  "",
  paste0(
    "- ", q_summary$method, " (", q_summary$years, ", n positive obs = ",
    q_summary$n_positive_obs, "): q median = ", fmt(q_summary$q_median, 3),
    ", 90% interval ", fmt(q_summary$q_lo90, 3), " to ",
    fmt(q_summary$q_hi90, 3), "."
  ),
  "",
  "## Positive-Cell Fit by Survey Era",
  "",
  paste0(
    "- ", method_fit_summary$method, ": log RMSE = ",
    fmt(method_fit_summary$log_rmse, 3), ", log bias = ",
    fmt(method_fit_summary$log_bias, 3), ", log-scale correlation = ",
    fmt(method_fit_summary$cor_log, 3), " (n = ", method_fit_summary$n, ")."
  ),
  "",
  "## Global Parameters",
  "",
  paste0(
    "- ", global_summary$parameter, ": median = ", fmt(global_summary$median, 3),
    ", 90% interval ", fmt(global_summary$lo90, 3), " to ",
    fmt(global_summary$hi90, 3), "."
  ),
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_method_sensitivity_postfit.pdf`",
  "- `Output/diagnostics/m1_stier_method_sensitivity_q_summary.csv`",
  "- `Output/diagnostics/m1_stier_method_sensitivity_method_fit_summary.csv`",
  "- `Output/diagnostics/m1_stier_method_sensitivity_year_fit.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_method_sensitivity_postfit.md"))

cat("Saved method-sensitivity postfit diagnostics:\n")
cat("  Output/diagnostics/m1_stier_method_sensitivity_postfit.md\n")
cat("  Output/figures/m1_stier_method_sensitivity_postfit.pdf\n")
