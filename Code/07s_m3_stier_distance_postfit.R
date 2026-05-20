# ============================================================================
# 07s_m3_stier_distance_postfit.R
# Interpret the m3_stier_distance branch after it finishes.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(readxl)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

fit_path <- file.path(data_dir, "m3_stier_distance_fit.rds")
if (!file.exists(fit_path)) {
  stop("m3_stier_distance_fit.rds not found. Run Code/03_fit_m3_stier_distance.R first.")
}

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(fit_path)
post <- rstan::extract(
  fit,
  pars = c(
    "phi",
    "practical_range_km",
    "sigma_proc",
    "sigma_obs",
    "Umu",
    "pdocoef",
    "log_q"
  )
)

summarise_draws <- function(x) {
  tibble(
    mean = mean(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE),
    p_gt_0 = mean(x > 0, na.rm = TRUE)
  )
}

xlsx_path <- file.path(
  proj_dir,
  "Data",
  "raw",
  "Euclidean & effective distance matrices herring & Steller.xlsx"
)
dist_raw <- read_excel(xlsx_path, sheet = "Herring Effective")
section_ids <- as.integer(dist_raw[[1]][1:13])
id_cols <- paste0("Id", section_ids)
D_full <- as.matrix(dist_raw[1:13, id_cols])
D_full <- apply(D_full, 2, as.numeric)
rownames(D_full) <- section_ids
colnames(D_full) <- section_ids

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
D_km <- D_full[as.character(keep_sections), as.character(keep_sections)] / 1000
D_km <- (D_km + t(D_km)) / 2
diag(D_km) <- 0
max_dist <- max(D_km)

global_summary <- bind_rows(
  summarise_draws(post$phi) %>% mutate(parameter = "phi"),
  summarise_draws(post$practical_range_km) %>% mutate(parameter = "practical_range_km"),
  summarise_draws(post$sigma_proc) %>% mutate(parameter = "sigma_proc"),
  summarise_draws(post$sigma_obs) %>% mutate(parameter = "sigma_obs"),
  summarise_draws(post$Umu) %>% mutate(parameter = "Umu"),
  summarise_draws(post$pdocoef) %>% mutate(parameter = "pdocoef"),
  map_dfr(seq_len(ncol(post$log_q)), function(i) {
    summarise_draws(post$log_q[, i]) %>%
      mutate(parameter = paste0("log_q[", i, "]"))
  })
) %>%
  select(parameter, everything())

distance_grid <- tibble(distance_km = seq(0, max_dist, length.out = 160))
cor_decay <- distance_grid %>%
  mutate(
    median = map_dbl(distance_km, ~ median(exp(-post$phi * .x), na.rm = TRUE)),
    lo90 = map_dbl(distance_km, ~ quantile(exp(-post$phi * .x), 0.05, na.rm = TRUE)),
    hi90 = map_dbl(distance_km, ~ quantile(exp(-post$phi * .x), 0.95, na.rm = TRUE))
  )

pair_corr_path <- file.path(diag_dir, "m1_stier_11_residual_spatial_pairs.csv")
pair_corr <- if (file.exists(pair_corr_path)) {
  read_csv(pair_corr_path, show_col_types = FALSE) %>%
    transmute(
      effective_distance_km,
      residual_correlation = cor_all,
      n_overlap = n_overlap_all
    ) %>%
    filter(is.finite(residual_correlation), n_overlap >= 5)
} else {
  tibble(
    effective_distance_km = numeric(),
    residual_correlation = numeric(),
    n_overlap = integer()
  )
}

comparison_path <- file.path(diag_dir, "model_comparison.csv")
comparison_context <- if (file.exists(comparison_path)) {
  read_csv(comparison_path, show_col_types = FALSE) %>%
    filter(model %in% c("m1_stier_11", "m3_stier_distance")) %>%
    select(
      model,
      comparison_status,
      sampler_clean,
      loo_resolved,
      looic_decision,
      max_pareto_k,
      divergences,
      treedepth_hits,
      max_rhat,
      min_ebfmi,
      any_of(c(
        "exact_reloo_completed",
        "exact_reloo_refits_clean",
        "exact_reloo_looic_total",
        "exact_reloo_looic_delta",
        "exact_reloo_treedepth_hits",
        "exact_reloo_min_ebfmi"
      )),
      positive_signal_log_rmse,
      positive_signal_log_bias
    )
} else {
  tibble()
}

loo_path <- file.path(proj_dir, "Output", "posteriors", "loo_m3_stier_distance.rds")
pareto_points <- if (file.exists(loo_path)) {
  loo_obj <- readRDS(loo_path)
  obs_map <- map_dfr(seq_len(jags_data$nYears), function(t) {
    tibble(
      t = t,
      site = which(jags_data$Y_obs[t, ] == 1L)
    )
  }) %>%
    mutate(
      log_lik_index = row_number(),
      year = jags_data$years[t],
      site_name = jags_data$site_names[site],
      observed_log = map2_dbl(t, site, ~ jags_data$Y[.x, .y]),
      observed = exp(observed_log),
      pareto_k = loo_obj$diagnostics$pareto_k[log_lik_index]
    ) %>%
    arrange(desc(pareto_k))

  obs_map
} else {
  tibble()
}

reloo_path <- file.path(diag_dir, "m3_stier_distance_triage_reloo.csv")
reloo_context <- if (file.exists(reloo_path)) {
  read_csv(reloo_path, show_col_types = FALSE) %>%
    summarise(
      n_required = max(n_high_pareto_total, na.rm = TRUE),
      n_completed = max(n_exact_refit_completed, na.rm = TRUE),
      completed = n_completed >= n_required,
      corrected_looic = first(looic_total_exact_corrected),
      psis_looic = first(looic_total_psis),
      delta_looic = corrected_looic - psis_looic,
      exact_refit_divergences = sum(divergences, na.rm = TRUE),
      exact_refit_treedepth_hits = sum(treedepth_hits, na.rm = TRUE),
      exact_refit_min_ebfmi = min(min_ebfmi, na.rm = TRUE),
      heldout_points = paste0(year, " ", site_name, " (k=", round(pareto_k, 3), ")", collapse = "; ")
    )
} else {
  tibble()
}

p_range <- tibble(practical_range_km = post$practical_range_km) %>%
  filter(is.finite(practical_range_km)) %>%
  ggplot(aes(x = practical_range_km)) +
  geom_histogram(bins = 50, fill = "#0072B2", colour = "white", alpha = 0.85) +
  geom_vline(xintercept = max_dist, linetype = "dashed", colour = "grey35") +
  scale_x_continuous(labels = label_number()) +
  labs(
    x = "Practical range 3 / phi (km)",
    y = "Posterior draws",
    title = "Distance-decay practical range",
    subtitle = "Dashed line is the maximum effective distance among fitted sections."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_decay <- ggplot(cor_decay, aes(x = distance_km)) +
  geom_ribbon(aes(ymin = lo90, ymax = hi90), fill = "#0072B2", alpha = 0.18) +
  geom_line(aes(y = median), colour = "#0072B2", linewidth = 0.8) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_point(
    data = pair_corr,
    aes(x = effective_distance_km, y = residual_correlation, size = n_overlap),
    inherit.aes = FALSE,
    colour = "#D55E00",
    alpha = 0.65
  ) +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_size_continuous(range = c(1, 5)) +
  labs(
    x = "Effective distance (km)",
    y = "Correlation",
    size = "Residual overlap",
    title = "Implied process correlation decay",
    subtitle = "Blue is posterior process correlation; orange points are m1_stier_11 positive-residual correlations."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_global <- global_summary %>%
  filter(parameter %in% c("Umu", "pdocoef", "sigma_proc", "sigma_obs", "log_q[1]", "log_q[2]")) %>%
  mutate(parameter = fct_reorder(parameter, median)) %>%
  ggplot(aes(x = median, y = parameter)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
  geom_errorbar(aes(xmin = lo90, xmax = hi90), width = 0.16, colour = "grey35") +
  geom_point(size = 2.2, colour = "#009E73") +
  labs(
    x = "Posterior median and 90% interval",
    y = NULL,
    title = "Global parameter context"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- p_range / (p_decay | p_global) +
  plot_annotation(
    title = "M3 Stier Distance Post-Fit Diagnostic",
    subtitle = "Checks whether distance-correlated process error is supported without changing the Stier observation layer."
  )

ggsave(
  file.path(fig_dir, "m3_stier_distance_postfit.pdf"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m3_stier_distance_postfit.png"),
  p,
  width = 240,
  height = 210,
  units = "mm",
  dpi = 300
)

write_csv(global_summary, file.path(diag_dir, "m3_stier_distance_global_parameters.csv"))
write_csv(cor_decay, file.path(diag_dir, "m3_stier_distance_correlation_decay.csv"))
write_csv(comparison_context, file.path(diag_dir, "m3_stier_distance_comparison_context.csv"))
write_csv(pareto_points, file.path(diag_dir, "m3_stier_distance_pareto_k_points.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

phi_row <- global_summary %>% filter(parameter == "phi")
range_row <- global_summary %>% filter(parameter == "practical_range_km")
sigma_row <- global_summary %>% filter(parameter == "sigma_proc")
pdo_row <- global_summary %>% filter(parameter == "pdocoef")

comparison_lines <- if (nrow(comparison_context) > 0) {
  paste0(
    "- `",
    comparison_context$model,
    "`: status = ",
    comparison_context$comparison_status,
    ", sampler clean = ",
    comparison_context$sampler_clean,
    ", LOO resolved = ",
    comparison_context$loo_resolved,
    ", LOOIC decision = ",
    fmt(comparison_context$looic_decision, 2),
    ", max Pareto k = ",
    fmt(comparison_context$max_pareto_k, 3),
    ", positive RMSE = ",
    fmt(comparison_context$positive_signal_log_rmse, 3),
    ", positive bias = ",
    fmt(comparison_context$positive_signal_log_bias, 3)
  )
} else {
  "- Comparison table not available yet."
}

pareto_lines <- if (nrow(pareto_points) > 0) {
  pareto_points %>%
    filter(pareto_k > 0.7) %>%
    mutate(
      line = paste0(
        "- Index ",
        log_lik_index,
        ": ",
        year,
        ", ",
        site_name,
        ", observed = ",
        fmt(observed, 1),
        ", Pareto k = ",
        fmt(pareto_k, 3),
        "."
      )
    ) %>%
    pull(line)
} else {
  "- LOO object not available."
}

if (length(pareto_lines) == 0) {
  pareto_lines <- "- No Pareto-k values above 0.7."
}

reloo_lines <- if (nrow(reloo_context) == 1) {
  c(
    paste0(
      "- Exact re-LOO completed for ",
      reloo_context$n_completed,
      "/",
      reloo_context$n_required,
      " high-k points."
    ),
    paste0(
      "- Corrected LOOIC = ",
      fmt(reloo_context$corrected_looic, 2),
      " (PSIS LOOIC = ",
      fmt(reloo_context$psis_looic, 2),
      "; delta = ",
      fmt(reloo_context$delta_looic, 2),
      ")."
    ),
    paste0(
      "- Exact refit health: divergences = ",
      reloo_context$exact_refit_divergences,
      ", treedepth hits = ",
      reloo_context$exact_refit_treedepth_hits,
      ", min E-BFMI = ",
      fmt(reloo_context$exact_refit_min_ebfmi, 3),
      "."
    ),
    paste0("- Refitted held-out points: ", reloo_context$heldout_points, "."),
    "- Interpretation: exact re-LOO is complete, but the 2024 Englefield Bay exact refit hit treedepth repeatedly, so this branch remains spatial context rather than a promoted baseline."
  )
} else {
  "- Exact re-LOO triage file not found."
}

lines <- c(
  "# M3 Stier Distance Post-Fit Diagnostic",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Distance-Decay Parameter",
  "",
  paste0(
    "- phi median = ",
    fmt(phi_row$median, 4),
    " (90% interval ",
    fmt(phi_row$lo90, 4),
    " to ",
    fmt(phi_row$hi90, 4),
    ")."
  ),
  paste0(
    "- Practical range median = ",
    fmt(range_row$median, 1),
    " km (90% interval ",
    fmt(range_row$lo90, 1),
    " to ",
    fmt(range_row$hi90, 1),
    " km)."
  ),
  paste0("- Maximum effective distance among fitted sections = ", fmt(max_dist, 1), " km."),
  "",
  "## Global Process Context",
  "",
  paste0(
    "- sigma_proc median = ",
    fmt(sigma_row$median, 3),
    " (90% interval ",
    fmt(sigma_row$lo90, 3),
    " to ",
    fmt(sigma_row$hi90, 3),
    ")."
  ),
  paste0(
    "- PDO coefficient median = ",
    fmt(pdo_row$median, 3),
    " (90% interval ",
    fmt(pdo_row$lo90, 3),
    " to ",
    fmt(pdo_row$hi90, 3),
    ")."
  ),
  "",
  "## Model-Comparison Context",
  "",
  comparison_lines,
  "",
  "## Influential LOO Points",
  "",
  pareto_lines,
  "",
  "## Exact Re-LOO Triage",
  "",
  reloo_lines,
  "",
  "## Files",
  "",
  "- `Output/figures/m3_stier_distance_postfit.pdf`",
  "- `Output/diagnostics/m3_stier_distance_global_parameters.csv`",
  "- `Output/diagnostics/m3_stier_distance_correlation_decay.csv`",
  "- `Output/diagnostics/m3_stier_distance_comparison_context.csv`",
  "- `Output/diagnostics/m3_stier_distance_pareto_k_points.csv`"
)

writeLines(lines, file.path(diag_dir, "m3_stier_distance_postfit.md"))
cat(paste(lines, collapse = "\n"))
cat("\n")
