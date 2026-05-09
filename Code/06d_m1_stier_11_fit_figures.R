# ============================================================================
# 06d_m1_stier_11_fit_figures.R
# Data-fit figures for the Stier-aligned 11-section baseline.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
fig_dir <- file.path(proj_dir, "Output", "figures")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(file.path(data_dir, "m1_stier_11_fit.rds"))

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)
method_labels <- c("Surface", "SCUBA/dive")
method_cols <- c("Surface" = "#D55E00", "SCUBA/dive" = "#0072B2")

post <- rstan::extract(fit, pars = c("X", "Z", "log_q", "Pc_logit"))
n_draws <- dim(post$X)[1]

obs_df <- map_dfr(seq_len(jags_data$nYears), function(t) {
  tibble(
    t = t,
    site = which(jags_data$Y_obs[t, ] == 1L)
  )
}) %>%
  mutate(
    year = jags_data$years[t],
    site_name = factor(jags_data$site_names[site], levels = jags_data$site_names),
    method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
    observed_log_spawn = map2_dbl(t, site, ~ jags_data$Y[.x, .y])
  )

fit_obs_df <- obs_df %>%
  mutate(
    fitted_log_median = pmap_dbl(
      list(t, site),
      ~ median(post$X[, ..1, ..2] + post$log_q[, q_idx_stier[..1]])
    ),
    fitted_log_lo90 = pmap_dbl(
      list(t, site),
      ~ quantile(post$X[, ..1, ..2] + post$log_q[, q_idx_stier[..1]], 0.05)
    ),
    fitted_log_hi90 = pmap_dbl(
      list(t, site),
      ~ quantile(post$X[, ..1, ..2] + post$log_q[, q_idx_stier[..1]], 0.95)
    ),
    log_residual = observed_log_spawn - fitted_log_median
  )

aggregate_df <- map_dfr(seq_len(jags_data$nYears), function(t) {
  idx <- which(jags_data$Y_obs[t, ] == 1L)
  if (length(idx) == 0) {
    return(tibble(
      year = jags_data$years[t],
      method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
      n_positive_sites = 0L,
      observed_positive_total = 0,
      fitted_positive_median = NA_real_,
      fitted_positive_lo90 = NA_real_,
      fitted_positive_hi90 = NA_real_
    ))
  }

  fitted_draws <- rowSums(exp(post$X[, t, idx, drop = FALSE] + post$log_q[, q_idx_stier[t]]))

  tibble(
    year = jags_data$years[t],
    method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
    n_positive_sites = length(idx),
    observed_positive_total = sum(exp(jags_data$Y[t, idx]), na.rm = TRUE),
    fitted_positive_median = median(fitted_draws),
    fitted_positive_lo90 = quantile(fitted_draws, 0.05),
    fitted_positive_hi90 = quantile(fitted_draws, 0.95)
  )
})

catch_df <- tibble(
  k = seq_len(jags_data$nIndex),
  t = jags_data$INDEX[, 1],
  site = jags_data$INDEX[, 2],
  year = jags_data$years[t],
  site_name = factor(jags_data$site_names[site], levels = jags_data$site_names),
  observed_log_catch = jags_data$ctab[jags_data$INDEX]
) %>%
  mutate(
    fitted_log_median = pmap_dbl(
      list(k, t, site),
      ~ median(post$Z[, ..2, ..3] + log(plogis(post$Pc_logit[, ..1])))
    ),
    fitted_log_lo90 = pmap_dbl(
      list(k, t, site),
      ~ quantile(post$Z[, ..2, ..3] + log(plogis(post$Pc_logit[, ..1])), 0.05)
    ),
    fitted_log_hi90 = pmap_dbl(
      list(k, t, site),
      ~ quantile(post$Z[, ..2, ..3] + log(plogis(post$Pc_logit[, ..1])), 0.95)
    ),
    log_residual = observed_log_catch - fitted_log_median
  )

write_csv(fit_obs_df, file.path(diag_dir, "m1_stier_11_positive_spawn_fit.csv"))
write_csv(aggregate_df, file.path(diag_dir, "m1_stier_11_aggregate_positive_spawn_fit.csv"))
write_csv(catch_df, file.path(diag_dir, "m1_stier_11_catch_fit.csv"))

p_spawn_site <- ggplot(fit_obs_df, aes(x = year)) +
  geom_ribbon(
    aes(ymin = fitted_log_lo90, ymax = fitted_log_hi90, fill = method),
    alpha = 0.18,
    colour = NA
  ) +
  geom_line(aes(y = fitted_log_median, colour = method), linewidth = 0.45) +
  geom_point(aes(y = observed_log_spawn, colour = method), size = 0.9, alpha = 0.8) +
  facet_wrap(vars(site_name), scales = "free_y", ncol = 3) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  labs(
    x = "Year",
    y = "log positive spawn index",
    title = "M1 Stier 11 positive spawn fit by section",
    subtitle = "Points are positive observations; lines and ribbons are posterior fitted positive-spawn signal."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_aggregate <- ggplot(aggregate_df, aes(x = year)) +
  geom_ribbon(
    aes(ymin = fitted_positive_lo90, ymax = fitted_positive_hi90, fill = method),
    alpha = 0.18,
    colour = NA
  ) +
  geom_line(aes(y = fitted_positive_median, colour = method), linewidth = 0.7) +
  geom_point(aes(y = pmax(observed_positive_total, 1e-6), colour = method), size = 1.5) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Aggregate positive spawn signal",
    title = "M1 Stier 11 aggregate positive-spawn fit",
    subtitle = "Observed and fitted totals are calculated only over positive observed cells."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_resid_time <- ggplot(fit_obs_df, aes(x = year, y = log_residual, colour = method)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(size = 1.2, alpha = 0.75) +
  geom_smooth(se = FALSE, method = "loess", linewidth = 0.6) +
  scale_colour_manual(values = method_cols) +
  labs(
    x = "Year",
    y = "observed - fitted log spawn",
    title = "Positive-spawn residuals by survey era",
    subtitle = "Residuals are calculated only for positive spawn observations."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_resid_scatter <- ggplot(fit_obs_df, aes(x = fitted_log_median, y = observed_log_spawn, colour = method)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(size = 1.2, alpha = 0.75) +
  scale_colour_manual(values = method_cols) +
  labs(
    x = "Fitted log positive spawn",
    y = "Observed log positive spawn",
    title = "Observed vs fitted positive-spawn cells"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

p_catch <- ggplot(catch_df, aes(x = year)) +
  geom_ribbon(aes(ymin = fitted_log_lo90, ymax = fitted_log_hi90), fill = "#009E73", alpha = 0.18) +
  geom_line(aes(y = fitted_log_median), colour = "#009E73", linewidth = 0.45) +
  geom_point(aes(y = observed_log_catch), colour = "black", size = 0.85, alpha = 0.75) +
  facet_wrap(vars(site_name), scales = "free_y", ncol = 3) +
  labs(
    x = "Year",
    y = "log catch",
    title = "M1 Stier 11 catch fit by section",
    subtitle = "Catch is fit tightly through the fishing-rate component."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_residuals <- p_resid_scatter | p_resid_time
p_summary <- p_aggregate / p_residuals +
  plot_annotation(
    title = "M1 Stier 11 positive-spawn fit summary",
    subtitle = "Zeros are treated as ambiguous/missing; diagnostics focus on positive observations."
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_positive_spawn_fit_by_section.pdf"),
  p_spawn_site,
  width = 220,
  height = 260,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_positive_spawn_fit_by_section.png"),
  p_spawn_site,
  width = 220,
  height = 260,
  units = "mm",
  dpi = 300
)
ggsave(
  file.path(fig_dir, "m1_stier_11_positive_spawn_fit_summary.pdf"),
  p_summary,
  width = 220,
  height = 180,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_positive_spawn_fit_summary.png"),
  p_summary,
  width = 220,
  height = 180,
  units = "mm",
  dpi = 300
)
ggsave(
  file.path(fig_dir, "m1_stier_11_catch_fit_by_section.pdf"),
  p_catch,
  width = 220,
  height = 260,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_catch_fit_by_section.png"),
  p_catch,
  width = 220,
  height = 260,
  units = "mm",
  dpi = 300
)

cat("Saved M1 Stier 11 fit figures:\n")
cat("  Output/figures/m1_stier_11_positive_spawn_fit_by_section.pdf\n")
cat("  Output/figures/m1_stier_11_positive_spawn_fit_summary.pdf\n")
cat("  Output/figures/m1_stier_11_catch_fit_by_section.pdf\n")
