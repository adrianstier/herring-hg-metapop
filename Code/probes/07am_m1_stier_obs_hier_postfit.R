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

fit_path <- file.path(data_dir, "m1_stier_obs_hier_fit.rds")
if (!file.exists(fit_path)) {
  stop("m1_stier_obs_hier_fit.rds not found. Run Code/03_fit_m1_stier_obs_hier.R first.")
}

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(fit_path)
post <- rstan::extract(
  fit,
  pars = c(
    "X", "log_q", "sigma_obs_site", "sigma_method_mult",
    "Umu", "pdocoef", "sigma_proc", "log_sigma_surface_extra",
    "tau_log_sigma_obs"
  )
)

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)
method_labels <- c("Surface", "SCUBA/dive")
method_cols <- c("Surface" = "#D55E00", "SCUBA/dive" = "#0072B2")

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
      years = paste(range(jags_data$years[q_idx_stier == i]), collapse = "-"),
      n_years = sum(q_idx_stier == i),
      n_positive_obs = sum(jags_data$Y_obs[q_idx_stier == i, , drop = FALSE] == 1L),
      .before = 1
    )
})

sigma_site_summary <- map_dfr(seq_len(jags_data$nSites), function(j) {
  summarise_draws(post$sigma_obs_site[, j]) %>%
    mutate(
      site = j,
      site_name = jags_data$site_names[j],
      .before = 1
    )
})

global_summary <- bind_rows(
  summarise_draws(post$Umu) %>% mutate(parameter = "Umu"),
  summarise_draws(post$pdocoef) %>% mutate(parameter = "pdocoef"),
  summarise_draws(post$sigma_proc) %>% mutate(parameter = "sigma_proc"),
  summarise_draws(post$tau_log_sigma_obs) %>% mutate(parameter = "tau_log_sigma_obs"),
  summarise_draws(exp(post$log_sigma_surface_extra)) %>%
    mutate(parameter = "surface_sigma_multiplier")
) %>%
  select(parameter, everything())

positive_cells <- which(jags_data$Y_obs == 1L, arr.ind = TRUE)
cell_fit <- map_dfr(seq_len(nrow(positive_cells)), function(i) {
  t <- positive_cells[i, "row"]
  j <- positive_cells[i, "col"]
  m <- q_idx_stier[t]
  fitted_draws <- post$X[, t, j] + post$log_q[, m]
  sigma_draws <- post$sigma_obs_site[, j] * post$sigma_method_mult[, m]
  tibble(
    year = jags_data$years[t],
    site = j,
    site_name = jags_data$site_names[j],
    method = factor(method_labels[m], levels = method_labels),
    observed_log = jags_data$Y[t, j],
    fitted_log_median = median(fitted_draws, na.rm = TRUE),
    fitted_log_lo90 = quantile(fitted_draws, 0.05, na.rm = TRUE),
    fitted_log_hi90 = quantile(fitted_draws, 0.95, na.rm = TRUE),
    pred_log_lo90 = quantile(fitted_draws - 1.645 * sigma_draws, 0.05, na.rm = TRUE),
    pred_log_hi90 = quantile(fitted_draws + 1.645 * sigma_draws, 0.95, na.rm = TRUE)
  )
}) %>%
  mutate(
    observed = exp(observed_log),
    fitted_median = exp(fitted_log_median),
    fitted_lo90 = exp(fitted_log_lo90),
    fitted_hi90 = exp(fitted_log_hi90),
    log_resid = fitted_log_median - observed_log,
    covered_pred90 = observed_log >= pred_log_lo90 & observed_log <= pred_log_hi90
  )

method_fit_summary <- cell_fit %>%
  group_by(method) %>%
  summarise(
    n = n(),
    log_rmse = sqrt(mean(log_resid^2, na.rm = TRUE)),
    log_bias = mean(log_resid, na.rm = TRUE),
    cor_log = cor(observed_log, fitted_log_median, use = "complete.obs"),
    pred90_coverage = mean(covered_pred90, na.rm = TRUE),
    .groups = "drop"
  )

year_fit <- map_dfr(seq_along(jags_data$years), function(t) {
  idx <- which(jags_data$Y_obs[t, ] == 1L)
  if (length(idx) == 0) {
    return(tibble())
  }
  m <- q_idx_stier[t]
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

p_sigma <- sigma_site_summary %>%
  mutate(site_name = fct_reorder(site_name, median)) %>%
  ggplot(aes(x = median, xmin = lo90, xmax = hi90, y = site_name)) +
  geom_pointrange(linewidth = 0.35, colour = "grey25") +
  scale_x_continuous(labels = label_number(accuracy = 0.1)) +
  labs(
    x = "section observation SD",
    y = NULL,
    title = "Section-specific observation error",
    subtitle = "Posterior median and 90% interval on the log-spawn scale."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_fit <- ggplot(year_fit, aes(x = year, colour = method, fill = method)) +
  geom_ribbon(aes(ymin = fitted_lo90, ymax = fitted_hi90), alpha = 0.14, colour = NA) +
  geom_line(aes(y = fitted_signal), linewidth = 0.65) +
  geom_point(aes(y = observed_signal, shape = method), size = 1.7, alpha = 0.9) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  scale_shape_manual(values = c(16, 15)) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "Aggregate positive spawn signal",
    title = "Observed vs fitted positive signal by Stier survey era",
    subtitle = "Points are observed positive-cell totals; lines/ribbons are fitted values on those same cells.",
    colour = NULL,
    fill = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_scatter <- ggplot(cell_fit, aes(x = fitted_median, y = observed, colour = method)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_point(alpha = 0.75, size = 1.4) +
  scale_colour_manual(values = method_cols) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "fitted positive spawn",
    y = "observed positive spawn",
    title = "Cell-level positive-spawn calibration",
    subtitle = "Variance should improve coverage without needing a new process term.",
    colour = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_fit / (p_sigma | p_scatter) +
  plot_annotation(
    title = "M1 Stier Observation-Hierarchy Postfit Diagnostic",
    subtitle = "Tests section-specific observation error and surface-era extra variance."
  )

ggsave(
  file.path(fig_dir, "m1_stier_obs_hier_postfit.pdf"),
  p,
  width = 230, height = 190, units = "mm", device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_obs_hier_postfit.png"),
  p,
  width = 230, height = 190, units = "mm", dpi = 300
)

write_csv(q_summary, file.path(diag_dir, "m1_stier_obs_hier_q_summary.csv"))
write_csv(sigma_site_summary, file.path(diag_dir, "m1_stier_obs_hier_sigma_by_section.csv"))
write_csv(global_summary, file.path(diag_dir, "m1_stier_obs_hier_global_parameters.csv"))
write_csv(method_fit_summary, file.path(diag_dir, "m1_stier_obs_hier_method_fit_summary.csv"))
write_csv(year_fit, file.path(diag_dir, "m1_stier_obs_hier_year_fit.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

surface_row <- method_fit_summary %>% filter(method == "Surface")
dive_row <- method_fit_summary %>% filter(method == "SCUBA/dive")
surface_mult <- global_summary %>% filter(parameter == "surface_sigma_multiplier")

lines <- c(
  "# M1 Stier Observation-Hierarchy Postfit Diagnostic",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Purpose",
  "",
  "`m1_stier_obs_hier` keeps the `m1_stier_11` process and ambiguous-zero likelihood, but allows section-specific observation error and extra surface-era positive-observation variance.",
  "",
  "## Key Readout",
  "",
  paste0(
    "- Surface positive-spawn log RMSE: `", fmt(surface_row$log_rmse), "`; bias: `",
    fmt(surface_row$log_bias), "`; predictive 90% coverage: `",
    fmt(100 * surface_row$pred90_coverage, 0), "%`."
  ),
  paste0(
    "- SCUBA/dive positive-spawn log RMSE: `", fmt(dive_row$log_rmse), "`; bias: `",
    fmt(dive_row$log_bias), "`; predictive 90% coverage: `",
    fmt(100 * dive_row$pred90_coverage, 0), "%`."
  ),
  paste0(
    "- Surface observation SD multiplier median: `",
    fmt(surface_mult$median), "` (90% interval `",
    fmt(surface_mult$lo90), "`-`", fmt(surface_mult$hi90), "`)."
  ),
  "",
  "## Decision Rule",
  "",
  "- Promote only if sampler diagnostics stay clean, PSIS/exact re-LOO is resolved, positive-spawn RMSE improves materially, and q/sigma tradeoffs do not change the section story implausibly.",
  "- If surface RMSE does not improve but the surface multiplier is large, the next branch should consider a weak surface-era bias term rather than process complexity.",
  "",
  "## Files",
  "",
  "- `Output/figures/m1_stier_obs_hier_postfit.pdf`",
  "- `Output/diagnostics/m1_stier_obs_hier_method_fit_summary.csv`",
  "- `Output/diagnostics/m1_stier_obs_hier_sigma_by_section.csv`",
  "- `Output/diagnostics/m1_stier_obs_hier_global_parameters.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_obs_hier_postfit.md"))
cat(paste(lines, collapse = "\n"))
