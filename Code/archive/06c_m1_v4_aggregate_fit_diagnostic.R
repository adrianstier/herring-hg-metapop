library(rstan)
library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(file.path(data_dir, "m1_v4_fit.rds"))
post <- rstan::extract(fit, pars = c("X", "log_q"))

years <- jags_data$years
y <- jags_data$Y
y_obs <- jags_data$Y_obs
q_idx <- jags_data$q_idx

method_labels <- c("Surface", "Mixed", "Dive")
method_cols <- c("Surface" = "#D55E00", "Mixed" = "#CC79A7", "Dive" = "#0072B2")

agg_df <- map_dfr(seq_along(years), function(t) {
  idx <- which(y_obs[t, ] == 1L)
  if (length(idx) == 0) {
    return(tibble(
      year = years[t],
      method = factor(method_labels[q_idx[t]], levels = method_labels),
      surveyed_sites = sum(jags_data$Y_obs[t, ] + jags_data$Y_censored[t, ]),
      obs_total = 0,
      fit_median = NA_real_,
      fit_lo80 = NA_real_,
      fit_hi80 = NA_real_,
      fit_lo95 = NA_real_,
      fit_hi95 = NA_real_
    ))
  }

  fit_draws <- apply(
    exp(sweep(post$X[, t, idx, drop = FALSE], 1, post$log_q[, q_idx[t]], "+")),
    1,
    sum
  )

  tibble(
    year = years[t],
    method = factor(method_labels[q_idx[t]], levels = method_labels),
    surveyed_sites = sum(jags_data$Y_obs[t, ] + jags_data$Y_censored[t, ]),
    obs_total = sum(exp(y[t, idx]), na.rm = TRUE),
    fit_median = quantile(fit_draws, 0.50, na.rm = TRUE),
    fit_lo80 = quantile(fit_draws, 0.10, na.rm = TRUE),
    fit_hi80 = quantile(fit_draws, 0.90, na.rm = TRUE),
    fit_lo95 = quantile(fit_draws, 0.025, na.rm = TRUE),
    fit_hi95 = quantile(fit_draws, 0.975, na.rm = TRUE)
  )
})

metric_df <- agg_df %>%
  mutate(
    log_obs = log10(obs_total + 1),
    log_fit = log10(fit_median + 1),
    log_resid = log_obs - log_fit
  )

method_metrics <- metric_df %>%
  group_by(method) %>%
  summarise(
    n = n(),
    cor = cor(log_obs, log_fit, use = "complete.obs"),
    rmse = sqrt(mean((log_obs - log_fit)^2, na.rm = TRUE)),
    .groups = "drop"
  )

subtitle_text <- paste0(
  "Surface RMSE=", round(method_metrics$rmse[method_metrics$method == "Surface"], 2),
  ", Mixed RMSE=", round(method_metrics$rmse[method_metrics$method == "Mixed"], 2),
  ", Dive RMSE=", round(method_metrics$rmse[method_metrics$method == "Dive"], 2),
  " on log10 aggregate positive signal."
)

p_time <- ggplot(metric_df, aes(x = year, colour = method, fill = method)) +
  geom_ribbon(aes(ymin = fit_lo95, ymax = fit_hi95), alpha = 0.08, colour = NA) +
  geom_ribbon(aes(ymin = fit_lo80, ymax = fit_hi80), alpha = 0.16, colour = NA) +
  geom_line(aes(y = fit_median), linewidth = 0.7, show.legend = FALSE) +
  geom_point(aes(y = obs_total, shape = method), size = 1.7, alpha = 0.9) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  scale_shape_manual(values = c(16, 17, 15)) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "Aggregate observed positive spawn index",
    title = "Aggregate positive-signal fit by survey method",
    subtitle = "Points are observed totals across positive cells only; ribbons/lines are fitted totals on those same positive cells."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_scatter <- ggplot(metric_df, aes(x = fit_median, y = obs_total, colour = method)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_point(size = 2, alpha = 0.9) +
  scale_colour_manual(values = method_cols) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "Fitted aggregate positive signal",
    y = "Observed aggregate positive signal",
    title = "Observed vs fitted aggregate positive signal",
    subtitle = subtitle_text
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

p_resid <- ggplot(metric_df, aes(x = year, y = log_resid, colour = method)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_point(size = 1.7, alpha = 0.9) +
  geom_line(alpha = 0.5) +
  scale_colour_manual(values = method_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "log10(observed + 1) - log10(fitted + 1)",
    title = "Residual pattern through time",
    subtitle = "Negative values indicate the model is overpredicting aggregate positive signal."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

p <- (p_time / (p_scatter | p_resid)) +
  plot_annotation(
    title = "M1 v4 aggregate-fit diagnostic",
    subtitle = "The remaining magnitude misfit is concentrated in the early surface-survey era, not in the dive era."
  )

ggsave(
  file.path(fig_dir, "m1_v4_aggregate_fit_diagnostic.pdf"),
  p,
  width = 220, height = 180, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_v4_aggregate_fit_diagnostic.png"),
  p,
  width = 220, height = 180, units = "mm", dpi = 300
)

cat("Saved:\n")
cat("  Output/figures/m1_v4_aggregate_fit_diagnostic.pdf\n")
cat("  Output/figures/m1_v4_aggregate_fit_diagnostic.png\n")
