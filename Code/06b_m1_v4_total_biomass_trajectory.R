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

post <- rstan::extract(fit, pars = c("X", "log_q", "Y_rep"))

years <- jags_data$years
n_sites <- jags_data$nSites
log_q_mean <- colMeans(post$log_q)
surveyed_flag <- jags_data$Y_obs + jags_data$Y_censored

total_biomass_samps <- apply(exp(post$X), c(1, 2), sum)

total_summary <- tibble(
  year = years,
  median = apply(total_biomass_samps, 2, median),
  lo95 = apply(total_biomass_samps, 2, quantile, 0.025),
  hi95 = apply(total_biomass_samps, 2, quantile, 0.975),
  lo80 = apply(total_biomass_samps, 2, quantile, 0.10),
  hi80 = apply(total_biomass_samps, 2, quantile, 0.90)
)

obs_total_df <- tibble(
  year = years,
  obs_total_lb = map_dbl(seq_along(years), function(t) {
    obs_idx <- which(jags_data$Y_obs[t, ] == 1L)
    if (length(obs_idx) == 0) {
      return(0)
    }
    sum(exp(jags_data$Y[t, obs_idx] - log_q_mean[jags_data$q_idx[t]]), na.rm = TRUE)
  }),
  n_surveyed_sites = rowSums(surveyed_flag),
  coverage = if_else(n_surveyed_sites == n_sites, "All sites surveyed", "Partial survey coverage")
)

y_rep_surveyed <- map(seq_along(years), function(t) {
  idx <- which(surveyed_flag[t, ] == 1L)
  if (length(idx) == 0) {
    return(rep(NA_real_, dim(post$Y_rep)[1]))
  }
  apply(post$Y_rep[, t, idx, drop = FALSE], 1, sum)
})

survey_fit_summary <- tibble(
  year = years,
  median = map_dbl(y_rep_surveyed, ~ quantile(.x, 0.50, na.rm = TRUE)),
  lo80 = map_dbl(y_rep_surveyed, ~ quantile(.x, 0.10, na.rm = TRUE)),
  hi80 = map_dbl(y_rep_surveyed, ~ quantile(.x, 0.90, na.rm = TRUE)),
  lo95 = map_dbl(y_rep_surveyed, ~ quantile(.x, 0.025, na.rm = TRUE)),
  hi95 = map_dbl(y_rep_surveyed, ~ quantile(.x, 0.975, na.rm = TRUE))
) %>%
  left_join(obs_total_df, by = "year")

y_max <- max(c(total_summary$hi95, obs_total_df$obs_total_lb), na.rm = TRUE)
y_min <- min(c(total_summary$lo95, obs_total_df$obs_total_lb[obs_total_df$obs_total_lb > 0]), na.rm = TRUE)
y_text <- y_max * 1.15

p_latent <- ggplot(total_summary, aes(x = year)) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95), fill = "#009E73", alpha = 0.15) +
  geom_ribbon(aes(ymin = lo80, ymax = hi80), fill = "#009E73", alpha = 0.25) +
  geom_line(aes(y = median), colour = "#009E73", linewidth = 0.7) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey40", linewidth = 0.35) +
  annotate(
    "rect",
    xmin = 2014, xmax = 2016,
    ymin = y_min * 0.85, ymax = y_max * 1.25,
    fill = "firebrick", alpha = 0.06
  ) +
  annotate(
    "text",
    x = 2005, y = y_text, label = "Fishery\nclosure",
    vjust = 1.1, hjust = 1.1, size = 2.8, colour = "grey40"
  ) +
  annotate(
    "text",
    x = 2015, y = y_text, label = "MHW",
    vjust = 1.1, hjust = 0.5, size = 2.8, colour = "firebrick"
  ) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Archipelago post-fishing biomass",
    title = "Latent archipelago biomass (M1 v4 baseline)",
    subtitle = "Posterior total biomass across 11 sites. This latent quantity is not observed directly."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = "grey35")
  )

survey_y_max <- max(c(survey_fit_summary$hi95, survey_fit_summary$obs_total_lb), na.rm = TRUE)
survey_y_min <- min(c(survey_fit_summary$lo95[survey_fit_summary$lo95 > 0], survey_fit_summary$obs_total_lb[survey_fit_summary$obs_total_lb > 0]), na.rm = TRUE)

p_survey <- ggplot(survey_fit_summary, aes(x = year)) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95), fill = "#0072B2", alpha = 0.15) +
  geom_ribbon(aes(ymin = lo80, ymax = hi80), fill = "#0072B2", alpha = 0.25) +
  geom_line(aes(y = median), colour = "#0072B2", linewidth = 0.7) +
  geom_point(
    aes(y = pmax(obs_total_lb, 1e-6), shape = coverage),
    size = 1.6,
    colour = "#D55E00",
    alpha = 0.85
  ) +
  geom_vline(xintercept = 2005, linetype = "dashed", colour = "grey40", linewidth = 0.35) +
  annotate(
    "rect",
    xmin = 2014, xmax = 2016,
    ymin = survey_y_min * 0.85, ymax = survey_y_max * 1.25,
    fill = "firebrick", alpha = 0.06
  ) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  scale_y_log10(labels = label_comma()) +
  scale_shape_manual(values = c(16, 1)) +
  labs(
    x = "Year",
    y = "Aggregate survey-positive spawn index",
    title = "Observed vs fitted aggregate survey signal",
    subtitle = paste(
      "Blue = posterior predictive total over surveyed sites only;",
      "orange = observed positive detections on the same site coverage."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = "grey35"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p <- p_latent / p_survey +
  plot_annotation(
    title = "Archipelago-wide baseline summary for M1 v4",
    subtitle = "Top: latent total biomass. Bottom: the aggregate survey-scale quantity the model is actually asked to fit."
  )

ggsave(
  file.path(fig_dir, "m1_v4_total_biomass_trajectory.pdf"),
  p,
  width = 200, height = 180, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_v4_total_biomass_trajectory.png"),
  p,
  width = 200, height = 180, units = "mm", dpi = 300
)

# Overwrite the stale legacy filenames so the main figure path is no longer misleading.
ggsave(
  file.path(fig_dir, "m1_total_biomass_trajectory.pdf"),
  p,
  width = 200, height = 180, units = "mm", dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_total_biomass_trajectory.png"),
  p,
  width = 200, height = 180, units = "mm", dpi = 300
)

cat("Saved corrected total biomass figures:\n")
cat("  Output/figures/m1_v4_total_biomass_trajectory.pdf\n")
cat("  Output/figures/m1_v4_total_biomass_trajectory.png\n")
cat("  Output/figures/m1_total_biomass_trajectory.pdf\n")
cat("  Output/figures/m1_total_biomass_trajectory.png\n")
