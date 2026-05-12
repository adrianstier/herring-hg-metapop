# ============================================================================
# 06h_companion_and_supplement_figures_updated.R
#
# Companion and supplement figures for the updated Stier et al. 2020 analysis.
# Uses the promoted Stier-aligned baseline fit when available.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
base_fig_dir <- file.path(proj_dir, "Output", "figures", "stier2020_updated")
companion_dir <- file.path(base_fig_dir, "companions")
supp_dir <- file.path(base_fig_dir, "supplement")
dir.create(companion_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(supp_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

source(file.path(proj_dir, "R", "00_setup.R"))
load(file.path(data_dir, "jags_model_inputs_v2.RData"))

fit_candidates <- tibble(
  model = c("m1_stier_11", "m1_stier_obs_hier"),
  path = file.path(data_dir, c("m1_stier_11_fit.rds", "m1_stier_obs_hier_fit.rds"))
)

fit_row <- fit_candidates %>% filter(file.exists(path)) %>% slice(1)
if (nrow(fit_row) == 0) {
  stop("No Stier-aligned fit artifact found.")
}

model_name <- fit_row$model
fit <- readRDS(fit_row$path)
message("Using ", model_name, " for companion and supplement figures.")

extract_pars <- c(
  "X", "Z", "delta_raw", "Umu", "pdocoef", "sigma_proc",
  "log_q", "Pc_logit"
)
if (model_name == "m1_stier_obs_hier") {
  extract_pars <- c(extract_pars, "sigma_obs_site", "sigma_method_mult",
                    "log_sigma_surface_extra", "tau_log_sigma_obs")
}

post <- rstan::extract(fit, pars = extract_pars)

years <- jags_data$years
site_names <- jags_data$site_names
n_years <- length(years)
n_sites <- length(site_names)
n_draws <- length(post$Umu)
q_idx_stier <- if_else(years <= 1987, 1L, 2L)
method_labels <- c("Surface", "SCUBA/dive")
method_cols <- c("Surface" = "#D55E00", "SCUBA/dive" = "#0072B2")

focal_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_idx <- which(!site_names %in% focal_drop)

period_levels <- c(
  "1951-1965 early industrial",
  "1966-1971 late reduction",
  "1972-2004 roe fishery",
  "2005-2013 closure",
  "2014-2016 marine heatwave",
  "2017-2025 recent closure"
)

period_for_year <- function(year) {
  case_when(
    year <= 1965 ~ "1951-1965 early industrial",
    year <= 1971 ~ "1966-1971 late reduction",
    year <= 2004 ~ "1972-2004 roe fishery",
    year <= 2013 ~ "2005-2013 closure",
    year <= 2016 ~ "2014-2016 marine heatwave",
    TRUE ~ "2017-2025 recent closure"
  )
}

theme_updated <- function(base_size = 9) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom",
      legend.title = element_blank()
    )
}

save_both <- function(plot, dir, stem, width = 220, height = 160) {
  pdf_path <- file.path(dir, paste0(stem, ".pdf"))
  png_path <- file.path(dir, paste0(stem, ".png"))
  ggsave(pdf_path, plot, width = width, height = height, units = "mm", device = cairo_pdf)
  ggsave(png_path, plot, width = width, height = height, units = "mm", dpi = 300)
  invisible(c(pdf_path, png_path))
}

summarise_draws <- function(x) {
  tibble(
    median = median(x, na.rm = TRUE),
    lo80 = quantile(x, 0.10, na.rm = TRUE),
    hi80 = quantile(x, 0.90, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE)
  )
}

z_score <- function(x) {
  if (all(is.na(x)) || sd(x, na.rm = TRUE) == 0) {
    return(rep(NA_real_, length(x)))
  }
  as.numeric(scale(x))
}

status_cols <- c(
  "No record / not surveyed" = "grey92",
  "Zero / ambiguous record" = "#F0E442",
  "Positive spawn" = "#0072B2"
)

site_order <- rev(site_names)

X_med <- apply(post$X, c(2, 3), median)
Z_med <- apply(post$Z, c(2, 3), median)
total_x_draws <- apply(exp(post$X), c(1, 2), sum)
total_z_draws <- apply(exp(post$Z), c(1, 2), sum)
delta_proc <- sweep(post$delta_raw, 1, post$sigma_proc, "*")
delta_med <- apply(delta_proc, c(2, 3), median)

survey_df <- expand_grid(t = seq_len(n_years), site = seq_len(n_sites)) %>%
  mutate(
    year = years[t],
    site_name = factor(site_names[site], levels = site_order),
    method = factor(method_labels[q_idx_stier[t]], levels = method_labels),
    survey_status = case_when(
      jags_data$Y_obs[cbind(t, site)] == 1L ~ "Positive spawn",
      jags_data$Y_censored[cbind(t, site)] == 1L ~ "Zero / ambiguous record",
      TRUE ~ "No record / not surveyed"
    ),
    survey_status = factor(survey_status, levels = names(status_cols)),
    catch_positive = jags_data$ctab[cbind(t, site)] > 0,
    period = factor(period_for_year(year), levels = period_levels)
  )

region_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_region_1951_2025.csv"),
  show_col_types = FALSE
)
section_cov <- read_csv(
  file.path(data_dir, "dfo_spawn_covariates_section_1951_2025.csv"),
  show_col_types = FALSE
)
env_cov <- read_csv(file.path(data_dir, "environmental_covariates.csv"), show_col_types = FALSE)
pred_cov <- read_csv(file.path(data_dir, "predator_indices.csv"), show_col_types = FALSE)

# ============================================================================
# Common posterior summaries
# ============================================================================

section_biomass_df <- map_dfr(seq_len(n_sites), function(j) {
  map_dfr(seq_len(n_years), function(t) {
    summarise_draws(exp(post$X[, t, j])) %>%
      mutate(
        year = years[t],
        site = j,
        site_name = site_names[j],
        focal_status = if_else(j %in% focal_idx, "focal 9", "sparse sensitivity")
      )
  })
}) %>%
  mutate(
    site_name = factor(site_name, levels = site_names),
    period = factor(period_for_year(year), levels = period_levels)
  )

total_biomass_df <- map_dfr(seq_len(n_years), function(t) {
  bind_rows(
    summarise_draws(total_x_draws[, t]) %>%
      mutate(year = years[t], state = "post-fishing biomass"),
    summarise_draws(total_z_draws[, t]) %>%
      mutate(year = years[t], state = "pre-fishing biomass")
  )
}) %>%
  mutate(period = factor(period_for_year(year), levels = period_levels))

linear_growth <- delta_proc
for (t in seq_len(n_years - 1)) {
  transition_effect <- post$Umu + post$pdocoef * jags_data$pdo[t]
  linear_growth[, t, ] <- sweep(linear_growth[, t, ], 1, transition_effect, "+")
}
realized_growth <- exp(linear_growth)
transition_years <- years[-1]

growth_summary <- map_dfr(seq_len(n_sites), function(j) {
  map_dfr(seq_len(n_years - 1), function(t) {
    summarise_draws(realized_growth[, t, j]) %>%
      mutate(
        year = transition_years[t],
        site = j,
        site_name = site_names[j],
        log_biomass_lag_median = median(post$X[, t, j], na.rm = TRUE),
        delta_median = median(delta_proc[, t, j], na.rm = TRUE)
      )
  })
}) %>%
  mutate(
    site_name = factor(site_name, levels = site_names),
    period = factor(period_for_year(year), levels = period_levels)
  )

share_df <- map_dfr(seq_len(n_years), function(t) {
  b <- exp(X_med[t, ])
  tibble(
    year = years[t],
    site = seq_len(n_sites),
    site_name = site_names,
    biomass = b,
    biomass_share = b / sum(b, na.rm = TRUE),
    rank = rank(-b, ties.method = "first")
  )
})

portfolio_annual <- share_df %>%
  group_by(year) %>%
  summarise(
    effective_sections = 1 / sum(biomass_share^2, na.rm = TRUE),
    top3_share = sum(biomass_share[rank <= 3], na.rm = TRUE),
    top1_share = max(biomass_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    region_cov %>%
      select(year, surveyed_sections, occupied_sections, surveyed_zero_sections, total_spawn_index_tonnes),
    by = "year"
  ) %>%
  mutate(period = factor(period_for_year(year), levels = period_levels))

catch_fit_df <- tibble(
  k = seq_len(jags_data$nIndex),
  t = jags_data$INDEX[, 1],
  site = jags_data$INDEX[, 2],
  year = years[t],
  site_name = factor(site_names[site], levels = site_names),
  observed_log_catch = jags_data$ctab[jags_data$INDEX]
) %>%
  mutate(
    fitted_log_median = pmap_dbl(
      list(k, t, site),
      ~ median(post$Z[, ..2, ..3] + log(plogis(post$Pc_logit[, ..1])), na.rm = TRUE)
    ),
    fitted_log_lo90 = pmap_dbl(
      list(k, t, site),
      ~ quantile(post$Z[, ..2, ..3] + log(plogis(post$Pc_logit[, ..1])), 0.05, na.rm = TRUE)
    ),
    fitted_log_hi90 = pmap_dbl(
      list(k, t, site),
      ~ quantile(post$Z[, ..2, ..3] + log(plogis(post$Pc_logit[, ..1])), 0.95, na.rm = TRUE)
    ),
    catch_resid = observed_log_catch - fitted_log_median
  )

Pc_draws <- array(0, dim = c(n_draws, n_years, n_sites))
for (k in seq_len(jags_data$nIndex)) {
  Pc_draws[, jags_data$INDEX[k, 1], jags_data$INDEX[k, 2]] <- plogis(post$Pc_logit[, k])
}

fishing_year <- map_dfr(seq_len(n_years), function(t) {
  caught_sites <- which(jags_data$ctab[t, ] > 0)
  arch_draws <- rowMeans(Pc_draws[, t, , drop = FALSE][, 1, ])
  local_draws <- if (length(caught_sites) == 0) {
    rep(0, n_draws)
  } else if (length(caught_sites) == 1) {
    Pc_draws[, t, caught_sites]
  } else {
    rowMeans(Pc_draws[, t, caught_sites, drop = FALSE][, 1, ])
  }
  bind_rows(
    summarise_draws(arch_draws) %>% mutate(year = years[t], scale = "Archipelago-wide"),
    summarise_draws(local_draws) %>% mutate(year = years[t], scale = "Fished sections only")
  ) %>%
    mutate(n_fished_sections = length(caught_sites))
})

positive_cells <- which(jags_data$Y_obs == 1L, arr.ind = TRUE)
spawn_fit_df <- map_dfr(seq_len(nrow(positive_cells)), function(i) {
  t <- positive_cells[i, "row"]
  j <- positive_cells[i, "col"]
  m <- q_idx_stier[t]
  fitted_draws <- post$X[, t, j] + post$log_q[, m]
  sigma_draws <- if (model_name == "m1_stier_obs_hier") {
    post$sigma_obs_site[, j] * post$sigma_method_mult[, m]
  } else {
    rep(sd(fitted_draws), length(fitted_draws))
  }
  tibble(
    year = years[t],
    site = j,
    site_name = site_names[j],
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
    log_resid = observed_log - fitted_log_median,
    pred90_covered = observed_log >= pred_log_lo90 & observed_log <= pred_log_hi90,
    period = factor(period_for_year(year), levels = period_levels),
    site_name = factor(site_name, levels = site_names)
  )

spawn_year_fit <- spawn_fit_df %>%
  group_by(year, method) %>%
  summarise(
    observed_signal = sum(observed, na.rm = TRUE),
    fitted_signal = sum(fitted_median, na.rm = TRUE),
    n_positive = n(),
    mean_log_resid = mean(log_resid, na.rm = TRUE),
    .groups = "drop"
  )

# ============================================================================
# Companion 01: data coverage / survey method figure
# ============================================================================

p_method <- tibble(year = years, method = factor(method_labels[q_idx_stier], levels = method_labels)) %>%
  ggplot(aes(x = year, y = "survey method", fill = method)) +
  geom_tile(height = 0.7) +
  scale_fill_manual(values = method_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10), expand = c(0, 0)) +
  labs(x = NULL, y = NULL, title = "Survey era") +
  theme_updated(8) +
  theme(axis.text.y = element_blank(), legend.position = "bottom")

p_survey <- ggplot(survey_df, aes(x = year, y = site_name, fill = survey_status)) +
  geom_tile(colour = "white", linewidth = 0.08) +
  geom_point(
    data = survey_df %>% filter(catch_positive),
    aes(x = year, y = site_name),
    inherit.aes = FALSE,
    shape = 21,
    fill = "black",
    colour = "white",
    size = 0.8,
    stroke = 0.15
  ) +
  scale_fill_manual(values = status_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10), expand = c(0, 0)) +
  labs(
    x = "Year",
    y = NULL,
    title = "Section-year survey coverage, zero ambiguity, and catch",
    subtitle = "Black circles indicate section-years with reported catch."
  ) +
  theme_updated(8)

p_companion_01 <- p_method / p_survey +
  plot_layout(heights = c(0.28, 1.6)) +
  plot_annotation(
    title = "Companion 1. Data coverage and survey method context",
    subtitle = "This is the key context for treating zeros and no-survey years as ambiguous."
  )

save_both(p_companion_01, companion_dir, "companion_01_data_coverage_methods", 235, 170)

# ============================================================================
# Companion 02: observed vs fitted spawn and residuals
# ============================================================================

p_spawn_agg <- ggplot(spawn_year_fit, aes(x = year, colour = method)) +
  geom_line(aes(y = fitted_signal), linewidth = 0.7) +
  geom_point(aes(y = observed_signal), size = 1.5, alpha = 0.85) +
  scale_colour_manual(values = method_cols) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = NULL,
    y = "Aggregate positive spawn signal",
    title = "A. Annual positive-spawn signal",
    subtitle = "Points are observed positive cells; lines are fitted positive signal on those same cells."
  ) +
  theme_updated(9)

p_spawn_scatter <- ggplot(spawn_fit_df, aes(x = fitted_median, y = observed, colour = method)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_point(alpha = 0.65, size = 1.1) +
  scale_colour_manual(values = method_cols) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_comma()) +
  labs(x = "Fitted positive spawn", y = "Observed positive spawn", title = "B. Cell-level fit") +
  theme_updated(8) +
  theme(legend.position = "none")

p_spawn_resid <- ggplot(spawn_fit_df, aes(x = year, y = log_resid, colour = method)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_point(alpha = 0.65, size = 1.0) +
  geom_smooth(se = FALSE, method = "loess", formula = y ~ x, linewidth = 0.55) +
  scale_colour_manual(values = method_cols) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = "observed - fitted log spawn", title = "C. Residuals through time") +
  theme_updated(8) +
  theme(legend.position = "none")

p_spawn_section <- spawn_fit_df %>%
  group_by(site_name, method) %>%
  summarise(
    n = n(),
    rmse = sqrt(mean(log_resid^2, na.rm = TRUE)),
    bias = mean(log_resid, na.rm = TRUE),
    coverage = mean(pred90_covered, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = rmse, y = fct_reorder(site_name, rmse), colour = method)) +
  geom_point(size = 2) +
  scale_colour_manual(values = method_cols) +
  labs(x = "log-scale RMSE", y = NULL, title = "D. Section/method fit error") +
  theme_updated(8)

p_companion_02 <- p_spawn_agg / (p_spawn_scatter | p_spawn_resid | p_spawn_section) +
  plot_layout(heights = c(0.95, 1.05)) +
  plot_annotation(
    title = "Companion 2. Observed vs fitted spawn for the current model",
    subtitle = paste0("Fit artifact: ", model_name, ". Positive observations only; zeros remain ambiguous.")
  )

save_both(p_companion_02, companion_dir, "companion_02_spawn_fit_observed_predicted", 245, 190)

# ============================================================================
# Companion 03: catch fit and fishing pressure
# ============================================================================

p_catch_sections <- ggplot(catch_fit_df, aes(x = year)) +
  geom_ribbon(aes(ymin = fitted_log_lo90, ymax = fitted_log_hi90), fill = "#009E73", alpha = 0.16) +
  geom_line(aes(y = fitted_log_median), colour = "#009E73", linewidth = 0.35) +
  geom_point(aes(y = observed_log_catch), size = 0.65, alpha = 0.78) +
  facet_wrap(vars(site_name), scales = "free_y", ncol = 4) +
  labs(
    x = NULL,
    y = "log catch",
    title = "A. Catch fit by section",
    subtitle = "Catch is modeled through pre-fishing biomass and fishing fraction."
  ) +
  theme_updated(7) +
  theme(legend.position = "none", strip.text = element_text(size = 6.5))

p_fishing_year <- ggplot(fishing_year, aes(x = year, y = median, colour = scale, fill = scale)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), alpha = 0.14, colour = NA) +
  geom_line(linewidth = 0.7) +
  geom_hline(yintercept = 0.2, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  scale_colour_manual(values = c("Archipelago-wide" = "#0072B2", "Fished sections only" = "#D55E00")) +
  scale_fill_manual(values = c("Archipelago-wide" = "#0072B2", "Fished sections only" = "#D55E00")) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = "Fishing fraction", title = "B. Fishing pressure") +
  theme_updated(8)

p_catch_resid <- ggplot(catch_fit_df, aes(x = fitted_log_median, y = observed_log_catch)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_point(alpha = 0.75, size = 1.1, colour = "#009E73") +
  labs(x = "Fitted log catch", y = "Observed log catch", title = "C. Catch calibration") +
  theme_updated(8)

p_companion_03 <- p_catch_sections / (p_fishing_year | p_catch_resid) +
  plot_layout(heights = c(1.25, 0.9)) +
  plot_annotation(title = "Companion 3. Catch fit and fishing pressure")

save_both(p_companion_03, companion_dir, "companion_03_catch_fit_fishing_pressure", 245, 220)

# ============================================================================
# Companion 04: realized growth change effect sizes
# ============================================================================

growth_period_effect <- map_dfr(seq_len(n_sites), function(j) {
  hist_idx <- which(transition_years >= 1952 & transition_years <= 1994)
  post_idx <- which(transition_years >= 1995 & transition_years <= 2025)
  hist_log <- apply(linear_growth[, hist_idx, j, drop = FALSE], 1, mean, na.rm = TRUE)
  post_log <- apply(linear_growth[, post_idx, j, drop = FALSE], 1, mean, na.rm = TRUE)
  diff <- post_log - hist_log
  summarise_draws(diff) %>%
    mutate(
      site = j,
      site_name = site_names[j],
      prob_decline = mean(diff < 0, na.rm = TRUE),
      hist_growth_median = median(exp(hist_log), na.rm = TRUE),
      post_growth_median = median(exp(post_log), na.rm = TRUE)
    )
}) %>%
  mutate(
    site_name = fct_reorder(site_name, median),
    reporting = if_else(site %in% focal_idx, "focal 9", "sparse sensitivity")
  )

p_growth_diff <- ggplot(growth_period_effect, aes(x = median, y = site_name, colour = reporting)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_pointrange(aes(xmin = lo90, xmax = hi90), linewidth = 0.35) +
  scale_colour_manual(values = c("focal 9" = "#0072B2", "sparse sensitivity" = "grey45")) +
  labs(
    x = "Post-1994 minus historical mean log realized growth",
    y = NULL,
    title = "A. Posterior effect size"
  ) +
  theme_updated(9)

p_growth_prob <- ggplot(growth_period_effect, aes(x = prob_decline, y = site_name, fill = reporting)) +
  geom_col(width = 0.68) +
  geom_vline(xintercept = 0.8, linetype = "dashed", colour = "grey35", linewidth = 0.35) +
  scale_fill_manual(values = c("focal 9" = "#0072B2", "sparse sensitivity" = "grey70")) +
  scale_x_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  labs(x = "Pr(post-1994 growth < historical growth)", y = NULL, title = "B. Probability of decline") +
  theme_updated(9) +
  theme(axis.text.y = element_blank())

p_companion_04 <- p_growth_diff | p_growth_prob +
  plot_annotation(
    title = "Companion 4. Realized-growth decline by section",
    subtitle = "A talk-ready effect-size version of updated Stier Fig. 5."
  )

save_both(p_companion_04, companion_dir, "companion_04_realized_growth_change", 235, 150)

# ============================================================================
# Companion 05: process error heatmap
# ============================================================================

delta_heat <- as_tibble(delta_med, .name_repair = "minimal") %>%
  set_names(site_names) %>%
  mutate(year = transition_years) %>%
  pivot_longer(-year, names_to = "site_name", values_to = "delta") %>%
  mutate(
    site_name = factor(site_name, levels = site_order),
    period = factor(period_for_year(year), levels = period_levels)
  )

delta_arch <- delta_heat %>%
  group_by(year) %>%
  summarise(mean_delta = mean(delta, na.rm = TRUE), .groups = "drop")

p_delta_heat <- ggplot(delta_heat, aes(x = year, y = site_name, fill = delta)) +
  geom_tile(colour = "white", linewidth = 0.08) +
  scale_fill_gradient2(low = "#D55E00", mid = "white", high = "#0072B2", midpoint = 0) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10), expand = c(0, 0)) +
  labs(x = NULL, y = NULL, title = "A. Section-year process deviations") +
  theme_updated(8) +
  theme(legend.position = "right")

p_delta_mean <- ggplot(delta_arch, aes(x = year, y = mean_delta)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_line(linewidth = 0.75, colour = "grey25") +
  geom_point(size = 1.1, colour = "grey25") +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = "Mean process deviation", title = "B. Archipelago mean process deviation") +
  theme_updated(8)

p_companion_05 <- p_delta_heat / p_delta_mean +
  plot_layout(heights = c(1.35, 0.65)) +
  plot_annotation(
    title = "Companion 5. Process-error structure through time",
    subtitle = expression(delta[s * "," * t] * " after removing intrinsic growth and PDO effect.")
  )

save_both(p_companion_05, companion_dir, "companion_05_process_error_heatmap", 235, 185)

# ============================================================================
# Companion 06: spatial portfolio erosion
# ============================================================================

p_eff <- ggplot(portfolio_annual, aes(x = year)) +
  geom_line(aes(y = effective_sections), colour = "#0072B2", linewidth = 0.75) +
  geom_point(aes(y = occupied_sections), colour = "#D55E00", size = 1.2, alpha = 0.8) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = NULL,
    y = "Sections",
    title = "A. Effective biomass-bearing sections",
    subtitle = "Blue line = Simpson effective sections from latent biomass; orange = observed positive sections."
  ) +
  theme_updated(8)

p_topshare <- ggplot(portfolio_annual, aes(x = year)) +
  geom_line(aes(y = top3_share), colour = "#D55E00", linewidth = 0.75) +
  geom_line(aes(y = top1_share), colour = "grey30", linewidth = 0.55, linetype = "dashed") +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = "Biomass share", title = "B. Concentration in top sections") +
  theme_updated(8)

p_shares <- share_df %>%
  mutate(site_name = fct_reorder(site_name, site)) %>%
  ggplot(aes(x = year, y = biomass_share, fill = site_name)) +
  geom_area(linewidth = 0) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = "Share of latent biomass", title = "C. Section biomass shares") +
  theme_updated(8) +
  guides(fill = guide_legend(ncol = 2))

p_companion_06 <- (p_eff | p_topshare) / p_shares +
  plot_layout(heights = c(0.9, 1.1)) +
  plot_annotation(
    title = "Companion 6. Spatial portfolio erosion and concentration",
    subtitle = "High total biomass can still be concentrated in too few sections."
  )

save_both(p_companion_06, companion_dir, "companion_06_spatial_portfolio_erosion", 235, 195)

# ============================================================================
# Companion 07: driver dashboard
# ============================================================================

driver_dashboard <- total_biomass_df %>%
  filter(state == "post-fishing biomass") %>%
  select(year, biomass = median) %>%
  left_join(
    fishing_year %>%
      filter(scale == "Archipelago-wide") %>%
      select(year, fishing_fraction = median),
    by = "year"
  ) %>%
  left_join(
    region_cov %>%
      select(year, occupied_sections, surveyed_sections, total_spawn_index_tonnes,
             weighted_spawn_start_doy, subtidal_share),
    by = "year"
  ) %>%
  left_join(env_cov, by = "year") %>%
  left_join(pred_cov %>% select(year, pred_combined, seal_std, ssl_std, whale_std), by = "year") %>%
  transmute(
    year,
    `Latent total biomass` = log(biomass),
    `Observed total spawn` = log1p(total_spawn_index_tonnes),
    `Observed occupied sections` = occupied_sections,
    `Fishing fraction` = fishing_fraction,
    `PDO` = pdo,
    `Spring SST anomaly` = sst_spring_anom,
    `Predator index` = pred_combined,
    `Subtidal spawn share` = subtidal_share,
    `Spawn start DOY` = weighted_spawn_start_doy
  ) %>%
  pivot_longer(-year, names_to = "driver", values_to = "value") %>%
  group_by(driver) %>%
  mutate(z = z_score(value)) %>%
  ungroup() %>%
  mutate(
    driver = factor(driver, levels = c(
      "Latent total biomass", "Observed total spawn", "Observed occupied sections",
      "Fishing fraction", "PDO", "Spring SST anomaly", "Predator index",
      "Subtidal spawn share", "Spawn start DOY"
    ))
  )

p_companion_07 <- ggplot(driver_dashboard, aes(x = year, y = z)) +
  geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.25) +
  geom_line(colour = "#0072B2", linewidth = 0.55, na.rm = TRUE) +
  geom_point(size = 0.7, alpha = 0.7, na.rm = TRUE) +
  facet_wrap(vars(driver), ncol = 3, scales = "free_y") +
  scale_x_continuous(breaks = seq(1950, 2030, by = 20)) +
  labs(
    x = "Year",
    y = "Standardized value",
    title = "Companion 7. Candidate driver dashboard",
    subtitle = "Descriptive context only; predator and time trends remain strongly confounded."
  ) +
  theme_updated(8) +
  theme(strip.text = element_text(size = 7.5))

save_both(p_companion_07, companion_dir, "companion_07_driver_dashboard", 235, 185)

# ============================================================================
# Companion 08: before/after closure state figure
# ============================================================================

period_state <- portfolio_annual %>%
  group_by(period) %>%
  summarise(
    effective_sections = median(effective_sections, na.rm = TRUE),
    top3_share = median(top3_share, na.rm = TRUE),
    occupied_sections = median(occupied_sections, na.rm = TRUE),
    surveyed_sections = median(surveyed_sections, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    total_biomass_df %>%
      filter(state == "post-fishing biomass") %>%
      group_by(period) %>%
      summarise(total_biomass = median(median, na.rm = TRUE), .groups = "drop"),
    by = "period"
  ) %>%
  left_join(
    growth_summary %>%
      group_by(period) %>%
      summarise(realized_growth = median(median, na.rm = TRUE), .groups = "drop"),
    by = "period"
  )

period_long <- period_state %>%
  pivot_longer(
    -period,
    names_to = "metric",
    values_to = "value"
  ) %>%
  group_by(metric) %>%
  mutate(z = z_score(value)) %>%
  ungroup()

p_period_heat <- ggplot(period_long, aes(x = period, y = metric, fill = z)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  geom_text(aes(label = number(value, accuracy = 0.01)), size = 2.4) +
  scale_fill_gradient2(low = "#D55E00", mid = "white", high = "#0072B2", midpoint = 0) +
  labs(x = NULL, y = NULL, title = "A. Period state summary") +
  theme_updated(8) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1), legend.position = "right")

p_period_biomass <- total_biomass_df %>%
  filter(state == "post-fishing biomass") %>%
  ggplot(aes(x = year, y = median, colour = period, fill = period)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), alpha = 0.10, colour = NA) +
  geom_line(linewidth = 0.6) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = "Latent total biomass", title = "B. Periods on total biomass trajectory") +
  theme_updated(8) +
  theme(legend.position = "none")

p_companion_08 <- p_period_heat / p_period_biomass +
  plot_layout(heights = c(1, 0.85)) +
  plot_annotation(
    title = "Companion 8. Before/after closure and heatwave state comparison",
    subtitle = "Periods are intentionally broad; read sparse-survey periods with the coverage figure."
  )

save_both(p_companion_08, companion_dir, "companion_08_before_after_state", 245, 190)

# ============================================================================
# Companion 09: model comparison / decision figure
# ============================================================================

branch_status_path <- file.path(diag_dir, "model_branch_status_table.csv")
branch_tbl <- if (file.exists(branch_status_path)) {
  read_csv(branch_status_path, show_col_types = FALSE)
} else {
  tibble()
}

branch_plot_base <- if (nrow(branch_tbl) > 0) {
  branch_tbl %>%
    transmute(
      model,
      family = model_family,
      fit_ok = as.character(fit_ok),
      monday_use = as.character(use_for_monday),
      pos_rmse = positive_signal_log_rmse,
      max_k = max_pareto_k
    )
} else {
  tibble(
    model = character(),
    family = character(),
    fit_ok = character(),
    monday_use = character(),
    pos_rmse = numeric(),
    max_k = numeric()
  )
}

if (nrow(branch_plot_base) == 0) {
  branch_plot_base <- tibble(
    model = model_name,
    family = if_else(model_name == "m1_stier_11", "baseline", "fallback model"),
    fit_ok = "yes",
    monday_use = if_else(model_name == "m1_stier_11", "yes - promoted baseline", "candidate - fallback"),
    pos_rmse = sqrt(mean(spawn_fit_df$log_resid^2, na.rm = TRUE)),
    max_k = NA_real_
  )
}

plot_branch <- branch_plot_base %>%
  mutate(
    model = factor(model, levels = rev(unique(model))),
    status = case_when(
      str_detect(monday_use, "^yes") ~ "use",
      str_detect(monday_use, "context") ~ "context",
      TRUE ~ "exclude/stale"
    )
  )

p_model_rmse <- ggplot(plot_branch, aes(x = pos_rmse, y = model, colour = status)) +
  geom_point(size = 2.1, na.rm = TRUE) +
  scale_colour_manual(values = c("use" = "#0072B2", "context" = "#E69F00", "exclude/stale" = "grey60")) +
  labs(x = "Positive-spawn log RMSE", y = NULL, title = "A. Positive-spawn calibration") +
  theme_updated(8)

p_model_status <- ggplot(plot_branch, aes(x = status, y = model, fill = status)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("use" = "#0072B2", "context" = "#E69F00", "exclude/stale" = "grey75")) +
  labs(x = NULL, y = NULL, title = "B. Decision status") +
  theme_updated(8) +
  theme(axis.text.y = element_blank())

p_companion_09 <- p_model_rmse | p_model_status +
  plot_annotation(
    title = "Companion 9. Current model decision figure",
    subtitle = "Promoted baseline is used for these figures; observation hierarchy, spatial, and predator branches remain held unless they improve calibration cleanly."
  )

save_both(p_companion_09, companion_dir, "companion_09_model_decision", 220, 150)

# ============================================================================
# Supplement S1: updated data availability
# ============================================================================

p_supp_s1 <- p_companion_01 +
  plot_annotation(
    title = "Updated Supplement S1. Data availability through 2025",
    subtitle = "Updated version of the legacy Fig. S1 data-availability figure."
  )
save_both(p_supp_s1, supp_dir, "supp_s1_data_availability_updated", 235, 170)

# ============================================================================
# Supplement S2: parameter/posterior context
# ============================================================================

param_df <- bind_rows(
  summarise_draws(post$Umu) %>% mutate(parameter = "Umu"),
  summarise_draws(post$pdocoef) %>% mutate(parameter = "PDO coefficient"),
  summarise_draws(post$sigma_proc) %>% mutate(parameter = "process SD")
) %>%
  mutate(parameter_group = "process")

q_df <- map_dfr(seq_along(method_labels), function(m) {
  summarise_draws(exp(post$log_q[, m])) %>%
    mutate(parameter = paste0("q: ", method_labels[m]), parameter_group = "survey q")
})

sigma_df <- if (model_name == "m1_stier_obs_hier") {
  bind_rows(
    summarise_draws(exp(post$log_sigma_surface_extra)) %>%
      mutate(parameter = "surface SD multiplier", parameter_group = "observation SD"),
    summarise_draws(post$tau_log_sigma_obs) %>%
      mutate(parameter = "section SD heterogeneity", parameter_group = "observation SD")
  )
} else {
  tibble()
}

param_plot_df <- bind_rows(param_df, q_df, sigma_df) %>%
  mutate(parameter = fct_reorder(parameter, median))

p_supp_s2 <- ggplot(param_plot_df, aes(x = median, y = parameter, colour = parameter_group)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey75") +
  geom_pointrange(aes(xmin = lo90, xmax = hi90), linewidth = 0.35) +
  labs(
    x = "Posterior median and 90% interval",
    y = NULL,
    title = "Updated Supplement S2. Key posterior parameters",
    subtitle = paste0("Model: ", model_name)
  ) +
  theme_updated(9)

save_both(p_supp_s2, supp_dir, "supp_s2_parameter_posteriors_updated", 210, 135)

# ============================================================================
# Supplement S3: updated estimated biomass by subpopulation
# ============================================================================

p_supp_s3 <- ggplot(section_biomass_df, aes(x = year)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), fill = "#0072B2", alpha = 0.16) +
  geom_line(aes(y = median), colour = "#0072B2", linewidth = 0.45) +
  facet_wrap(vars(site_name), scales = "free_y", ncol = 4) +
  scale_y_continuous(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 20)) +
  labs(
    x = "Year",
    y = "Estimated post-fishing biomass",
    title = "Updated Supplement S3. Estimated biomass by subpopulation",
    subtitle = "Posterior median and 90% interval through 2025."
  ) +
  theme_updated(8) +
  theme(strip.text = element_text(size = 7))

save_both(p_supp_s3, supp_dir, "supp_s3_estimated_biomass_by_subpopulation_updated", 235, 225)

# ============================================================================
# Supplement S4: archipelago biomass trajectory
# ============================================================================

arch_obs <- region_cov %>%
  select(year, observed_spawn = total_spawn_index_tonnes, surveyed_sections, occupied_sections)

p_supp_s4 <- ggplot(total_biomass_df, aes(x = year, colour = state, fill = state)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), alpha = 0.12, colour = NA) +
  geom_line(aes(y = median), linewidth = 0.7) +
  geom_point(
    data = arch_obs,
    aes(x = year, y = pmax(observed_spawn, 1e-6)),
    inherit.aes = FALSE,
    size = 1.0,
    alpha = 0.6,
    colour = "grey25"
  ) +
  scale_y_log10(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "Archipelago biomass / observed spawn index",
    title = "Updated Supplement S4. Archipelago biomass trajectory",
    subtitle = "Black points are raw observed spawn-index totals; lines are latent model states."
  ) +
  theme_updated(9)

save_both(p_supp_s4, supp_dir, "supp_s4_archipelago_biomass_updated", 220, 150)

# ============================================================================
# Supplement S5: PDO forcing component
# ============================================================================

pdo_effect <- sapply(seq_along(years), function(t) post$pdocoef * jags_data$pdo[t])
pdo_effect_df <- as_tibble(
  t(apply(pdo_effect, 2, quantile, probs = c(0.05, 0.25, 0.5, 0.75, 0.95))),
  .name_repair = "minimal"
) %>%
  set_names(c("lo90", "q25", "median", "q75", "hi90")) %>%
  mutate(year = years, pdo = jags_data$pdo)

p_supp_s5 <- ggplot(pdo_effect_df, aes(x = year)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), fill = "grey70", alpha = 0.18) +
  geom_ribbon(aes(ymin = q25, ymax = q75), fill = "grey50", alpha = 0.20) +
  geom_line(aes(y = median), colour = "#0072B2", linewidth = 0.65) +
  geom_point(aes(y = median, colour = pdo > 0), size = 1.0) +
  scale_colour_manual(values = c(`TRUE` = "#D55E00", `FALSE` = "#0072B2")) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = expression(pi[PDO] * PDO[t]),
    title = "Updated Supplement S5. PDO forcing through time",
    subtitle = "Positive values indicate years when PDO contribution increases realized growth under the fitted sign convention."
  ) +
  theme_updated(9)

save_both(p_supp_s5, supp_dir, "supp_s5_pdo_forcing_updated", 220, 145)

# ============================================================================
# Supplement S6: productivity / density screen
# ============================================================================

density_screen <- growth_summary %>%
  filter(site %in% focal_idx) %>%
  mutate(log_realized_growth = log(median))

p_supp_s6 <- ggplot(density_screen, aes(x = log_biomass_lag_median, y = log_realized_growth)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_point(aes(colour = period), size = 1.0, alpha = 0.65) +
  geom_smooth(method = "lm", se = TRUE, colour = "grey20", linewidth = 0.6) +
  facet_wrap(vars(site_name), scales = "free_x", ncol = 3) +
  labs(
    x = "Lagged log post-fishing biomass",
    y = "Log realized growth",
    title = "Updated Supplement S6. Growth-density screen",
    subtitle = "Descriptive screen for density dependence; focal 9 sections only."
  ) +
  theme_updated(8) +
  theme(strip.text = element_text(size = 7))

save_both(p_supp_s6, supp_dir, "supp_s6_growth_density_screen_updated", 235, 210)

# ============================================================================
# Diagnostics and index
# ============================================================================

write_csv(survey_df, file.path(diag_dir, "stier2020_updated_companion_survey_coverage.csv"))
write_csv(spawn_fit_df, file.path(diag_dir, "stier2020_updated_companion_spawn_fit.csv"))
write_csv(catch_fit_df, file.path(diag_dir, "stier2020_updated_companion_catch_fit.csv"))
write_csv(growth_period_effect, file.path(diag_dir, "stier2020_updated_companion_growth_change.csv"))
write_csv(delta_heat, file.path(diag_dir, "stier2020_updated_companion_process_deviations.csv"))
write_csv(portfolio_annual, file.path(diag_dir, "stier2020_updated_companion_portfolio_annual.csv"))
write_csv(driver_dashboard, file.path(diag_dir, "stier2020_updated_companion_driver_dashboard.csv"))
write_csv(period_state, file.path(diag_dir, "stier2020_updated_companion_period_state.csv"))
write_csv(plot_branch, file.path(diag_dir, "stier2020_updated_companion_model_decision.csv"))

companion_files <- c(
  "companions/companion_01_data_coverage_methods.pdf",
  "companions/companion_02_spawn_fit_observed_predicted.pdf",
  "companions/companion_03_catch_fit_fishing_pressure.pdf",
  "companions/companion_04_realized_growth_change.pdf",
  "companions/companion_05_process_error_heatmap.pdf",
  "companions/companion_06_spatial_portfolio_erosion.pdf",
  "companions/companion_07_driver_dashboard.pdf",
  "companions/companion_08_before_after_state.pdf",
  "companions/companion_09_model_decision.pdf"
)

supp_files <- c(
  "supplement/supp_s1_data_availability_updated.pdf",
  "supplement/supp_s2_parameter_posteriors_updated.pdf",
  "supplement/supp_s3_estimated_biomass_by_subpopulation_updated.pdf",
  "supplement/supp_s4_archipelago_biomass_updated.pdf",
  "supplement/supp_s5_pdo_forcing_updated.pdf",
  "supplement/supp_s6_growth_density_screen_updated.pdf"
)

index_lines <- c(
  "# Updated Companion And Supplement Figures",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste0("Model artifact: `", model_name, "`."),
  "",
  "## Companion Figures",
  "",
  paste0("- `Output/figures/stier2020_updated/", companion_files, "`"),
  "",
  "## Updated Supplement Figures",
  "",
  paste0("- `Output/figures/stier2020_updated/", supp_files, "`"),
  "",
  "## Notes",
  "",
  "- Companion figures are designed for interpretation and talk-building around the updated Stier figure set.",
  "- Supplement figures update the legacy data-availability and biomass supplement figures and add current appendix-style checks for parameters, archipelago biomass, PDO forcing, and growth-density structure.",
  "- Zeros and no-survey records remain ambiguous in the fitted baseline; coverage figures display them explicitly rather than treating them as confirmed biological absences.",
  "- `m1_stier_11` is used as the promoted baseline; `m1_stier_obs_hier` is only a fallback if the promoted baseline artifact is unavailable."
)

writeLines(index_lines, file.path(diag_dir, "stier2020_updated_companion_supplement_index.md"))
cat(paste(index_lines, collapse = "\n"))
