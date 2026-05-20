# ============================================================================
# 06e_m1_stier_9_focal_reporting.R
# Report the Stier 9-focal-subpopulation sensitivity from the m1_stier_11 fit.
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

drop_sites <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_site_idx <- which(!jags_data$site_names %in% drop_sites)

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)
method_labels <- c("Surface", "SCUBA/dive")
method_cols <- c("Surface" = "#D55E00", "SCUBA/dive" = "#0072B2")

post <- rstan::extract(fit, pars = c("X", "log_q"))

summarise_draws <- function(x) {
  tibble(
    median = median(x, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE)
  )
}

positive_fit_df <- map_dfr(seq_len(jags_data$nYears), function(t) {
  idx <- which(jags_data$Y_obs[t, focal_site_idx] == 1L)
  if (length(idx) == 0) {
    return(tibble())
  }
  site_idx <- focal_site_idx[idx]
  map_dfr(site_idx, function(j) {
    fit_draws <- post$X[, t, j] + post$log_q[, q_idx_stier[t]]
    summarise_draws(fit_draws) %>%
      mutate(
        year = jags_data$years[t],
        site = j,
        site_name = factor(
          jags_data$site_names[j],
          levels = jags_data$site_names[focal_site_idx]
        ),
        method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
        observed_log_spawn = jags_data$Y[t, j],
        log_residual = observed_log_spawn - median
      )
  })
})

aggregate_fit_df <- map_dfr(seq_len(jags_data$nYears), function(t) {
  site_sets <- list(
    all_11 = seq_len(jags_data$nSites),
    focal_9 = focal_site_idx
  )

  map_dfr(names(site_sets), function(report_set) {
    idx <- which(jags_data$Y_obs[t, site_sets[[report_set]]] == 1L)
    if (length(idx) == 0) {
      return(tibble(
        report_set = report_set,
        year = jags_data$years[t],
        method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
        n_positive_sites = 0L,
        observed_positive_total = 0,
        fitted_positive_median = NA_real_,
        fitted_positive_lo90 = NA_real_,
        fitted_positive_hi90 = NA_real_
      ))
    }

    site_idx <- site_sets[[report_set]][idx]
    fitted_draws <- rowSums(
      exp(post$X[, t, site_idx, drop = FALSE] + post$log_q[, q_idx_stier[t]])
    )

    tibble(
      report_set = report_set,
      year = jags_data$years[t],
      method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
      n_positive_sites = length(site_idx),
      observed_positive_total = sum(exp(jags_data$Y[t, site_idx]), na.rm = TRUE),
      fitted_positive_median = median(fitted_draws, na.rm = TRUE),
      fitted_positive_lo90 = quantile(fitted_draws, 0.05, na.rm = TRUE),
      fitted_positive_hi90 = quantile(fitted_draws, 0.95, na.rm = TRUE)
    )
  })
})

latent_biomass_df <- map_dfr(seq_len(jags_data$nYears), function(t) {
  map_dfr(seq_len(jags_data$nSites), function(j) {
    summarise_draws(exp(post$X[, t, j])) %>%
      mutate(
        year = jags_data$years[t],
        site = j,
        site_name = jags_data$site_names[j],
        report_set = if_else(j %in% focal_site_idx, "focal_9", "dropped_from_focal")
      )
  })
})

total_biomass_df <- map_dfr(seq_len(jags_data$nYears), function(t) {
  site_sets <- list(
    all_11 = seq_len(jags_data$nSites),
    focal_9 = focal_site_idx
  )
  map_dfr(names(site_sets), function(report_set) {
    total_draws <- rowSums(exp(post$X[, t, site_sets[[report_set]], drop = FALSE]))
    summarise_draws(total_draws) %>%
      mutate(
        year = jags_data$years[t],
        report_set = report_set
      )
  })
})

window_metrics <- function(biomass_df, sites, report_set, window = 10L) {
  bio_wide <- biomass_df %>%
    filter(site %in% sites) %>%
    select(year, site_name, median) %>%
    pivot_wider(names_from = site_name, values_from = median) %>%
    arrange(year)

  years <- bio_wide$year
  mat <- bio_wide %>% select(-year) %>% as.matrix()
  n_windows <- length(years) - window + 1L
  if (n_windows < 1L) {
    return(tibble())
  }

  map_dfr(seq_len(n_windows), function(i) {
    idx <- i:(i + window - 1L)
    window_mat <- mat[idx, , drop = FALSE]
    subpop_cvs <- apply(window_mat, 2, function(x) {
      x <- x[x > 0 & !is.na(x)]
      if (length(x) < 3) {
        return(NA_real_)
      }
      sd(x) / mean(x)
    })
    total_biomass <- rowSums(window_mat, na.rm = TRUE)
    cv_arch <- sd(total_biomass) / mean(total_biomass)
    valid_cols <- apply(window_mat, 2, function(x) {
      sum(!is.na(x) & x > 0) >= 3
    })
    sync_mat <- window_mat[, valid_cols, drop = FALSE]
    synchrony_lm <- if (ncol(sync_mat) >= 2) {
      sync_mat[is.na(sync_mat)] <- 0
      var(rowSums(sync_mat)) / sum(apply(sync_mat, 2, sd))^2
    } else {
      NA_real_
    }

    tibble(
      report_set = report_set,
      window_start = min(years[idx]),
      window_end = max(years[idx]),
      window_mid = mean(years[idx]),
      cv_subpop_mean = mean(subpop_cvs, na.rm = TRUE),
      cv_archipelago = cv_arch,
      cv_ratio = mean(subpop_cvs, na.rm = TRUE) / cv_arch,
      synchrony_lm = synchrony_lm
    )
  })
}

portfolio_df <- bind_rows(
  window_metrics(latent_biomass_df, seq_len(jags_data$nSites), "all_11"),
  window_metrics(latent_biomass_df, focal_site_idx, "focal_9")
)

report_labels <- c(
  all_11 = "All 11 fitted sections",
  focal_9 = "Stier 9 focal sections"
)
report_cols <- c(all_11 = "#009E73", focal_9 = "#0072B2")

write_csv(
  positive_fit_df,
  file.path(diag_dir, "m1_stier_9_focal_positive_spawn_fit.csv")
)
write_csv(
  aggregate_fit_df,
  file.path(diag_dir, "m1_stier_11_vs_9_aggregate_positive_spawn_fit.csv")
)
write_csv(
  total_biomass_df,
  file.path(diag_dir, "m1_stier_11_vs_9_total_biomass.csv")
)
write_csv(
  portfolio_df,
  file.path(diag_dir, "m1_stier_11_vs_9_portfolio_metrics.csv")
)

p_focal_spawn <- ggplot(positive_fit_df, aes(x = year)) +
  geom_ribbon(
    aes(ymin = lo90, ymax = hi90, fill = method),
    alpha = 0.18,
    colour = NA
  ) +
  geom_line(aes(y = median, colour = method), linewidth = 0.45) +
  geom_point(aes(y = observed_log_spawn, colour = method), size = 0.9, alpha = 0.8) +
  facet_wrap(vars(site_name), scales = "free_y", ncol = 3) +
  scale_colour_manual(values = method_cols) +
  scale_fill_manual(values = method_cols) +
  labs(
    x = "Year",
    y = "log positive spawn index",
    title = "M1 Stier baseline: positive spawn fit for 9 focal sections",
    subtitle = "Tasu Sound & Gowgaia Bay and Naden Harbour are excluded only from this reporting view."
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_aggregate <- aggregate_fit_df %>%
  filter(report_set %in% c("all_11", "focal_9")) %>%
  ggplot(aes(x = year)) +
  geom_ribbon(
    aes(ymin = fitted_positive_lo90, ymax = fitted_positive_hi90, fill = report_set),
    alpha = 0.12,
    colour = NA
  ) +
  geom_line(aes(y = fitted_positive_median, colour = report_set), linewidth = 0.65) +
  geom_point(
    aes(y = pmax(observed_positive_total, 1e-6), colour = report_set),
    size = 1.2,
    alpha = 0.75
  ) +
  facet_wrap(vars(report_set), labeller = as_labeller(report_labels), ncol = 1) +
  scale_colour_manual(values = report_cols, labels = report_labels) +
  scale_fill_manual(values = report_cols, labels = report_labels) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Aggregate positive spawn signal",
    title = "Aggregate positive-spawn fit: 11 fitted sections vs 9 focal sections",
    subtitle = "Observed and fitted totals are calculated only over positive observed cells."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

p_total <- total_biomass_df %>%
  ggplot(aes(x = year, colour = report_set, fill = report_set)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), alpha = 0.12, colour = NA) +
  geom_line(aes(y = median), linewidth = 0.7) +
  scale_colour_manual(values = report_cols, labels = report_labels) +
  scale_fill_manual(values = report_cols, labels = report_labels) +
  scale_y_log10(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Post-fishing biomass",
    title = "Latent biomass totals from the same 11-section fit",
    subtitle = "The 9-focal series is a reporting subset, not a separate model fit."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_portfolio <- portfolio_df %>%
  select(report_set, window_mid, cv_ratio, synchrony_lm) %>%
  pivot_longer(c(cv_ratio, synchrony_lm), names_to = "metric", values_to = "value") %>%
  mutate(
    metric = recode(
      metric,
      cv_ratio = "Portfolio effect (CV ratio)",
      synchrony_lm = "Synchrony"
    )
  ) %>%
  ggplot(aes(x = window_mid, y = value, colour = report_set)) +
  geom_line(linewidth = 0.7) +
  facet_wrap(vars(metric), scales = "free_y", ncol = 1) +
  scale_colour_manual(values = report_cols, labels = report_labels) +
  labs(
    x = "Window midpoint",
    y = NULL,
    title = "Portfolio metrics: 11 fitted sections vs 9 focal sections",
    subtitle = "Metrics use posterior median biomass from the promoted m1_stier_11 fit."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )

p_summary <- p_aggregate / (p_total | p_portfolio) +
  plot_annotation(
    title = "M1 Stier baseline: 9-focal reporting sensitivity",
    subtitle = "The model is fit to 11 sections; this view mirrors Stier et al.'s 9 data-rich focal-section framing."
  )

ggsave(
  file.path(fig_dir, "m1_stier_9_focal_positive_spawn_fit_by_section.pdf"),
  p_focal_spawn,
  width = 220,
  height = 230,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_9_focal_positive_spawn_fit_by_section.png"),
  p_focal_spawn,
  width = 220,
  height = 230,
  units = "mm",
  dpi = 300
)
ggsave(
  file.path(fig_dir, "m1_stier_9_focal_reporting_summary.pdf"),
  p_summary,
  width = 240,
  height = 260,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_9_focal_reporting_summary.png"),
  p_summary,
  width = 240,
  height = 260,
  units = "mm",
  dpi = 300
)

cat("Saved M1 Stier 9-focal reporting sensitivity:\n")
cat("  Output/figures/m1_stier_9_focal_positive_spawn_fit_by_section.pdf\n")
cat("  Output/figures/m1_stier_9_focal_reporting_summary.pdf\n")
