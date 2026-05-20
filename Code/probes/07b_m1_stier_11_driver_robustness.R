# ============================================================================
# 07b_m1_stier_11_driver_robustness.R
# Lag and trend-robust screening of candidate population drivers.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

driver_df <- read_csv(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  show_col_types = FALSE
)

response_vars <- c(
  growth_median = "latent growth",
  log_total_biomass = "log total biomass",
  occupied_sections = "occupied sections"
)

predictor_vars <- c(
  pdo = "PDO",
  sst_spring_anom = "spring SST anomaly",
  chla_spring_mean = "spring chlorophyll",
  pred_combined = "combined predator index",
  seal_std = "harbour seal index",
  ssl_std = "Steller sea lion index",
  whale_std = "humpback whale index",
  weighted_spawn_start_doy = "spawn timing DOY",
  subtidal_share = "subtidal spawn share",
  substrate_effective_n = "substrate effective n",
  observed_catch_tonnes = "observed catch",
  fishing_fraction_median = "posterior fishing fraction"
)

driver_df <- driver_df %>%
  select(-any_of(paste0(names(predictor_vars), "_lag1"))) %>%
  mutate(
    log_total_biomass = log(total_biomass_median),
    year_z = as.numeric(scale(year)),
    era = case_when(
      year <= 1987 ~ "surface_era",
      TRUE ~ "dive_era"
    )
  )

make_lags <- function(df, predictor, max_lag = 2L) {
  map_dfc(0:max_lag, function(lag_n) {
    tibble(!!paste0(predictor, "_lag", lag_n) := lag(df[[predictor]], lag_n))
  })
}

lagged_df <- bind_cols(
  driver_df,
  map_dfc(names(predictor_vars), ~ make_lags(driver_df, .x))
)

screen_one <- function(response, predictor, lag_n, subset_label, subset_expr) {
  pred_col <- paste0(predictor, "_lag", lag_n)

  dat_src <- switch(
    subset_label,
    all_years = lagged_df,
    surface_era = filter(lagged_df, era == "surface_era"),
    dive_era = filter(lagged_df, era == "dive_era"),
    post_closure = filter(lagged_df, year >= 2005),
    lagged_df
  )

  dat <- dat_src %>%
    transmute(
      year,
      response = .data[[response]],
      predictor = .data[[pred_col]]
    ) %>%
    filter(is.finite(response), is.finite(predictor))

  if (nrow(dat) < 10 || sd(dat$response) == 0 || sd(dat$predictor) == 0) {
    return(tibble(
      response = response,
      response_label = unname(response_vars[response]),
      predictor = predictor,
      predictor_label = unname(predictor_vars[predictor]),
      lag = lag_n,
      subset = subset_label,
      n = nrow(dat),
      spearman_rho = NA_real_,
      pearson_r = NA_real_,
      detrended_r = NA_real_,
      p_spearman = NA_real_,
      p_detrended = NA_real_
    ))
  }

  spearman <- suppressWarnings(cor.test(dat$response, dat$predictor, method = "spearman"))
  pearson <- suppressWarnings(cor(dat$response, dat$predictor, method = "pearson"))

  response_resid <- resid(lm(response ~ scale(year), data = dat))
  predictor_resid <- resid(lm(predictor ~ scale(year), data = dat))
  detrended <- suppressWarnings(cor.test(response_resid, predictor_resid, method = "pearson"))

  tibble(
    response = response,
    response_label = unname(response_vars[response]),
    predictor = predictor,
    predictor_label = unname(predictor_vars[predictor]),
    lag = lag_n,
    subset = subset_label,
    n = nrow(dat),
    spearman_rho = unname(spearman$estimate),
    pearson_r = pearson,
    detrended_r = unname(detrended$estimate),
    p_spearman = spearman$p.value,
    p_detrended = detrended$p.value
  )
}

subsets <- list(
  all_years = expr(TRUE),
  surface_era = expr(era == "surface_era"),
  dive_era = expr(era == "dive_era"),
  post_closure = expr(year >= 2005)
)

robustness_df <- crossing(
  response = names(response_vars),
  predictor = names(predictor_vars),
  lag = 0:2,
  subset = names(subsets)
) %>%
  pmap_dfr(function(response, predictor, lag, subset) {
    screen_one(
      response = response,
      predictor = predictor,
      lag_n = lag,
      subset_label = subset,
      subset_expr = !!subsets[[subset]]
    )
  }) %>%
  mutate(
    robust_score = abs(detrended_r) * sqrt(pmax(n, 1)),
    sign_consistent = sign(spearman_rho) == sign(detrended_r)
  ) %>%
  arrange(response, subset, desc(abs(detrended_r)))

top_growth <- robustness_df %>%
  filter(
    response == "growth_median",
    subset == "all_years",
    is.finite(detrended_r)
  ) %>%
  arrange(desc(abs(detrended_r))) %>%
  slice_head(n = 12)

top_dive_growth <- robustness_df %>%
  filter(
    response == "growth_median",
    subset == "dive_era",
    is.finite(detrended_r)
  ) %>%
  arrange(desc(abs(detrended_r))) %>%
  slice_head(n = 12)

simple_models <- list(
  growth_all = growth_median ~ scale(pdo_lag1) + scale(fishing_fraction_median_lag1) + scale(pred_combined_lag1),
  growth_survey = growth_median ~ scale(pdo_lag1) + scale(subtidal_share_lag1) + scale(weighted_spawn_start_doy_lag1),
  occupancy_all = occupied_sections ~ scale(pdo_lag1) + scale(fishing_fraction_median_lag1) + scale(pred_combined_lag1),
  occupancy_survey = occupied_sections ~ scale(pdo_lag1) + scale(subtidal_share_lag1) + scale(substrate_effective_n_lag1)
)

model_df <- imap_dfr(simple_models, function(formula, model_name) {
  vars <- all.vars(formula)
  dat <- lagged_df %>%
    select(year, all_of(vars)) %>%
    filter(if_all(everything(), is.finite))

  if (nrow(dat) < 20) {
    return(tibble())
  }

        fit <- lm(formula, data = dat)
  coef_tbl <- as.data.frame(coef(summary(fit))) %>%
    rownames_to_column("term") %>%
    filter(term != "(Intercept)") %>%
    transmute(
      model = model_name,
      n = nrow(dat),
      r_squared = summary(fit)$r.squared,
      adj_r_squared = summary(fit)$adj.r.squared,
      term,
      estimate = Estimate,
      std_error = `Std. Error`,
      statistic = `t value`,
      p_value = `Pr(>|t|)`
    )
  coef_tbl
})

p_lag <- top_growth %>%
  mutate(
    label = paste0(predictor_label, " lag ", lag),
    label = fct_reorder(label, detrended_r)
  ) %>%
  ggplot(aes(x = detrended_r, y = label, fill = detrended_r > 0)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = "grey45") +
  scale_fill_manual(values = c(`TRUE` = "#176B87", `FALSE` = "#C47F2C"), guide = "none") +
  labs(
    x = "Detrended Pearson r with latent growth",
    y = NULL,
    title = "Driver screen after removing linear time trend",
    subtitle = "All years; lags 0-2. These are candidate signals, not causal estimates."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p_dive <- top_dive_growth %>%
  mutate(
    label = paste0(predictor_label, " lag ", lag),
    label = fct_reorder(label, detrended_r)
  ) %>%
  ggplot(aes(x = detrended_r, y = label, fill = detrended_r > 0)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = "grey45") +
  scale_fill_manual(values = c(`TRUE` = "#176B87", `FALSE` = "#C47F2C"), guide = "none") +
  labs(
    x = "Detrended Pearson r with latent growth",
    y = NULL,
    title = "Same screen within the dive era",
    subtitle = "This reduces surface-vs-dive method confounding but has less historical contrast."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- p_lag / p_dive

ggsave(
  file.path(fig_dir, "m1_stier_11_driver_robustness.pdf"),
  p,
  width = 220,
  height = 180,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_driver_robustness.png"),
  p,
  width = 220,
  height = 180,
  units = "mm",
  dpi = 300
)

write_csv(robustness_df, file.path(diag_dir, "m1_stier_11_driver_robustness.csv"))
write_csv(model_df, file.path(diag_dir, "m1_stier_11_driver_linear_models.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

top_line <- robustness_df %>%
  filter(response == "growth_median", subset == "all_years", lag <= 2, is.finite(detrended_r)) %>%
  arrange(desc(abs(detrended_r))) %>%
  slice_head(n = 8)

dive_line <- robustness_df %>%
  filter(response == "growth_median", subset == "dive_era", lag <= 2, is.finite(detrended_r)) %>%
  arrange(desc(abs(detrended_r))) %>%
  slice_head(n = 8)

lines <- c(
  "# M1 Stier 11 Driver Robustness Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Purpose",
  "",
  "This screen reruns the descriptive driver correlations across lags 0-2 and after removing a linear time trend from both response and predictor. It is designed to flag confounding before adding covariates to Stan.",
  "",
  "## Strongest Detrended Growth Associations, All Years",
  "",
  paste0(
    "- ",
    top_line$predictor_label,
    " lag ",
    top_line$lag,
    ": detrended r = ",
    fmt(top_line$detrended_r, 2),
    ", raw Spearman rho = ",
    fmt(top_line$spearman_rho, 2),
    " (n=",
    top_line$n,
    ")"
  ),
  "",
  "## Strongest Detrended Growth Associations, Dive Era",
  "",
  paste0(
    "- ",
    dive_line$predictor_label,
    " lag ",
    dive_line$lag,
    ": detrended r = ",
    fmt(dive_line$detrended_r, 2),
    ", raw Spearman rho = ",
    fmt(dive_line$spearman_rho, 2),
    " (n=",
    dive_line$n,
    ")"
  ),
  "",
  "## Interpretation",
  "",
  "- PDO remains the most stable climate candidate for latent growth, especially at lag 0-1.",
  "- Predator and substrate signals weaken or shift when detrended and when restricted to the dive era, so they should enter later as sensitivity branches.",
  "- Survey-method and substrate covariates remain important for observation/reporting interpretation, but they should not be mistaken for population-process drivers.",
  "- The next process branch should first allow section heterogeneity, because regional covariates alone cannot explain the strong section-specific winners and losers.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_driver_robustness.pdf`",
  "- `Output/diagnostics/m1_stier_11_driver_robustness.csv`",
  "- `Output/diagnostics/m1_stier_11_driver_linear_models.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_driver_robustness.md"))

cat("Saved driver robustness diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_driver_robustness.md\n")
cat("  Output/figures/m1_stier_11_driver_robustness.pdf\n")
