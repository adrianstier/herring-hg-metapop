# ============================================================================
# 07bv_heatwave_bottomup_scope.R
# Focused diagnostic for the "is non-recovery the Blob / bottom-up energy?"
# question using promoted m1_stier_11 outputs and existing climate data.
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

fmt <- function(x, digits = 2) {
  ifelse(is.na(x), "NA", format(round(x, digits), trim = TRUE, big.mark = ","))
}

z <- function(x) {
  if (sum(is.finite(x)) < 2 || is.na(sd(x, na.rm = TRUE)) || sd(x, na.rm = TRUE) == 0) {
    return(rep(NA_real_, length(x)))
  }
  as.numeric(scale(x))
}

safe_cor <- function(x, y, method = "spearman") {
  keep <- is.finite(x) & is.finite(y)
  if (sum(keep) < 4 || sd(x[keep]) == 0 || sd(y[keep]) == 0) return(NA_real_)
  suppressWarnings(cor(x[keep], y[keep], method = method))
}

safe_p <- function(x, y, method = "spearman") {
  keep <- is.finite(x) & is.finite(y)
  if (sum(keep) < 4 || sd(x[keep]) == 0 || sd(y[keep]) == 0) return(NA_real_)
  suppressWarnings(cor.test(x[keep], y[keep], method = method)$p.value)
}

driver_ts <- read_diag("m1_stier_11_driver_screening_timeseries.csv") %>%
  arrange(year) %>%
  mutate(
    mhw = as.integer(year >= 2014 & year <= 2016),
    mhw_lag1 = lag(mhw, 1),
    mhw_lead1 = lead(mhw, 1),
    pdo_lag0 = pdo,
    pdo_lag1 = lag(pdo, 1),
    pdo_mean_lag0_1 = rowMeans(pick(pdo_lag0, pdo_lag1), na.rm = FALSE),
    sst_spring_anom_lag0 = sst_spring_anom,
    sst_spring_anom_lag1 = lag(sst_spring_anom, 1),
    chla_spring_mean_lag0 = chla_spring_mean,
    chla_spring_mean_lag1 = lag(chla_spring_mean, 1),
    fishing_fraction_median_lag1 = lag(fishing_fraction_median, 1),
    year_z = z(year),
    pdo_lag1_z = z(pdo_lag1),
    fishing_lag1_z = z(fishing_fraction_median_lag1)
  )

period_summary <- read_diag("mhw_recovery_period_summary.csv")
section_mhw <- read_diag("mhw_recovery_by_section.csv")

predictor_tbl <- tribble(
  ~predictor, ~label, ~class, ~expected_direction, ~model_note,
  "pdo_lag1", "PDO lag 1", "long climate", "negative", "already in promoted model",
  "pdo_mean_lag0_1", "PDO mean lag 0-1", "long climate", "negative", "cheap window sensitivity only",
  "mhw", "2014-2016 MHW pulse", "event pulse", "negative", "three-year binary pulse",
  "mhw_lag1", "2014-2016 MHW pulse lag 1", "event pulse", "negative", "three-year lagged binary pulse",
  "mhw_lead1", "MHW future-lag negative control", "negative control", "none", "should not be interpreted mechanistically",
  "sst_spring_anom_lag0", "spring SST anomaly lag 0", "satellite SST", "negative", "2014-2025 only",
  "sst_spring_anom_lag1", "spring SST anomaly lag 1", "satellite SST", "negative", "2015-2025 only after lag",
  "chla_spring_mean_lag0", "spring chlorophyll lag 0", "satellite chlorophyll", "positive", "2003-2025 only",
  "chla_spring_mean_lag1", "spring chlorophyll lag 1", "satellite chlorophyll", "positive", "2004-2025 only after lag"
)

score_predictor <- function(predictor, label, class, expected_direction, model_note) {
  pred <- predictor
  dat <- driver_ts %>%
    transmute(
      year,
      growth = growth_median,
      predictor = .data[[pred]],
      pdo_lag1_z,
      fishing_lag1_z,
      year_z
    ) %>%
    filter(is.finite(growth), is.finite(predictor))

  if (nrow(dat) < 8 || sd(dat$growth) == 0 || sd(dat$predictor) == 0) {
    return(tibble(
      predictor = pred,
      label = label,
      class = class,
      expected_direction = expected_direction,
      model_note = model_note,
      n = nrow(dat),
      year_min = ifelse(nrow(dat) == 0, NA_integer_, min(dat$year)),
      year_max = ifelse(nrow(dat) == 0, NA_integer_, max(dat$year)),
      event_years = ifelse(nrow(dat) == 0, NA_integer_, sum(dat$predictor > 0, na.rm = TRUE)),
      rho_year = NA_real_,
      spearman_rho = NA_real_,
      pearson_r = NA_real_,
      detrended_r = NA_real_,
      adjusted_beta = NA_real_,
      adjusted_p = NA_real_,
      adjusted_r2 = NA_real_,
      future_control_flag = pred == "mhw_lead1"
    ))
  }

  detrended_growth <- resid(lm(growth ~ year_z, data = dat))
  detrended_pred <- resid(lm(predictor ~ year_z, data = dat))

  adjusted_dat <- dat %>%
    mutate(
      predictor_z = z(predictor),
      pdo_lag1_z = replace_na(pdo_lag1_z, 0),
      fishing_lag1_z = replace_na(fishing_lag1_z, 0)
    ) %>%
    filter(is.finite(predictor_z), is.finite(year_z))

  # Avoid controlling PDO by itself for the PDO rows; otherwise the screen is
  # mostly a collinearity check rather than a model-entry check.
  formula <- if (pred %in% c("pdo_lag1", "pdo_mean_lag0_1")) {
    growth ~ predictor_z + fishing_lag1_z + year_z
  } else {
    growth ~ predictor_z + pdo_lag1_z + fishing_lag1_z + year_z
  }

  adjusted <- lm(formula, data = adjusted_dat)
  adjusted_coef <- coef(summary(adjusted))

  tibble(
    predictor = pred,
    label = label,
    class = class,
    expected_direction = expected_direction,
    model_note = model_note,
    n = nrow(dat),
    year_min = min(dat$year),
    year_max = max(dat$year),
    event_years = sum(dat$predictor > 0, na.rm = TRUE),
    rho_year = safe_cor(dat$year, dat$predictor, method = "spearman"),
    spearman_rho = safe_cor(dat$growth, dat$predictor, method = "spearman"),
    pearson_r = safe_cor(dat$growth, dat$predictor, method = "pearson"),
    detrended_r = safe_cor(detrended_growth, detrended_pred, method = "pearson"),
    adjusted_beta = adjusted_coef["predictor_z", "Estimate"],
    adjusted_p = adjusted_coef["predictor_z", "Pr(>|t|)"],
    adjusted_r2 = summary(adjusted)$adj.r.squared,
    future_control_flag = pred == "mhw_lead1"
  )
}

signal_tbl <- pmap_dfr(predictor_tbl, score_predictor) %>%
  mutate(
    expected_match = case_when(
      expected_direction == "negative" ~ adjusted_beta < 0,
      expected_direction == "positive" ~ adjusted_beta > 0,
      TRUE ~ NA
    ),
    gate = case_when(
      future_control_flag ~ "negative_control",
      n < 20 ~ "too_short_for_stan",
      abs(adjusted_beta) < 0.08 ~ "weak_adjusted_effect",
      isFALSE(expected_match) ~ "wrong_adjusted_sign",
      abs(rho_year) > 0.70 ~ "time_confounded",
      TRUE ~ "candidate_context_only"
    )
  ) %>%
  arrange(factor(gate, levels = c("candidate_context_only", "weak_adjusted_effect", "wrong_adjusted_sign", "time_confounded", "too_short_for_stan", "negative_control")),
          desc(abs(adjusted_beta)))

coverage_tbl <- signal_tbl %>%
  select(label, class, n, year_min, year_max, rho_year, model_note, gate)

period_tbl <- period_summary %>%
  filter(period %in% c("2005-2013 closure", "2014-2016 marine heatwave", "2017-2025 recent closure")) %>%
  mutate(across(where(is.numeric), ~ round(.x, 4)))

spatial_tbl <- section_mhw %>%
  summarise(
    sections = n(),
    focal_sections = sum(focal_status == "focal_9", na.rm = TRUE),
    sections_mhw_below_pre = sum(mhw_minus_pre < 0, na.rm = TRUE),
    focal_mhw_below_pre = sum(mhw_minus_pre < 0 & focal_status == "focal_9", na.rm = TRUE),
    sections_recent_below_pre = sum(recent_minus_pre < 0, na.rm = TRUE),
    focal_recent_below_pre = sum(recent_minus_pre < 0 & focal_status == "focal_9", na.rm = TRUE),
    sections_recent_below_mhw = sum(recent_minus_mhw < 0, na.rm = TRUE),
    focal_recent_below_mhw = sum(recent_minus_mhw < 0 & focal_status == "focal_9", na.rm = TRUE),
    median_recent_to_pre_ratio = median(recent_to_pre_ratio, na.rm = TRUE),
    median_recent_to_mhw_ratio = median(recent_to_mhw_ratio, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(signal_tbl, file.path(diag_dir, "heatwave_bottomup_signal_screen.csv"))
write_csv(coverage_tbl, file.path(diag_dir, "heatwave_bottomup_covariate_coverage.csv"))
write_csv(spatial_tbl, file.path(diag_dir, "heatwave_bottomup_spatial_summary.csv"))

plot_signal <- signal_tbl %>%
  filter(!future_control_flag) %>%
  mutate(
    label = fct_reorder(label, adjusted_beta),
    class = factor(class, levels = c("long climate", "event pulse", "satellite SST", "satellite chlorophyll"))
  ) %>%
  ggplot(aes(x = adjusted_beta, y = label, fill = class)) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(width = 0.72) +
  labs(
    x = "Adjusted coefficient for posterior median growth",
    y = NULL,
    fill = NULL,
    title = "Climate and bottom-up screens",
    subtitle = "Adjusted for year, lagged fishing, and lagged PDO except on PDO rows."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

plot_timeseries <- driver_ts %>%
  filter(year >= 2003, !is.na(growth_median)) %>%
  ggplot(aes(x = year)) +
  annotate("rect", xmin = 2014, xmax = 2016, ymin = -Inf, ymax = Inf, fill = "firebrick", alpha = 0.08) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.3) +
  geom_line(aes(y = growth_median), colour = "#D55E00", linewidth = 0.7) +
  geom_point(aes(y = growth_median), colour = "#D55E00", size = 1.8) +
  geom_line(aes(y = z(chla_spring_mean) / 5), colour = "#009E73", linewidth = 0.6, na.rm = TRUE) +
  geom_line(aes(y = z(sst_spring_anom) / 5), colour = "#0072B2", linewidth = 0.6, na.rm = TRUE) +
  labs(
    x = "Year",
    y = "Growth; scaled SST/Chl-a divided by 5",
    title = "Post-2003 climate/productivity context",
    subtitle = "Orange is latent growth; green Chl-a and blue SST are scaled for visual comparison."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

plot_sections <- section_mhw %>%
  mutate(site_name = fct_reorder(site_name, recent_minus_pre)) %>%
  ggplot(aes(x = recent_minus_pre, y = site_name, fill = status)) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(width = 0.72) +
  scale_x_continuous(labels = label_comma()) +
  labs(
    x = "Recent closure minus pre-MHW closure biomass",
    y = NULL,
    fill = NULL,
    title = "Spatial pattern after the heatwave window"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

plot_obj <- plot_timeseries / (plot_signal | plot_sections) +
  plot_layout(heights = c(0.95, 1.05)) +
  plot_annotation(
    title = "Heatwave / Bottom-Up Scope Diagnostic",
    subtitle = "The Blob/MHW is context; current evidence does not make it the promoted mechanism for non-recovery."
  )

ggsave(
  file.path(fig_dir, "heatwave_bottomup_scope.pdf"),
  plot_obj,
  width = 240,
  height = 190,
  units = "mm",
  dpi = 300,
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "heatwave_bottomup_scope.png"),
  plot_obj,
  width = 240,
  height = 190,
  units = "mm",
  dpi = 300
)

row_for <- function(pred) signal_tbl %>% filter(predictor == pred) %>% slice(1)
pdo_row <- row_for("pdo_lag1")
mhw_row <- row_for("mhw_lag1")
mhw_now <- row_for("mhw")
chla_row <- row_for("chla_spring_mean_lag1")
sst_row <- row_for("sst_spring_anom_lag1")
neg_row <- row_for("mhw_lead1")

period_line <- function(period, col) {
  period_summary %>%
    filter(.data$period == !!period) %>%
    pull({{ col }}) %>%
    first()
}

lines <- c(
  "# Heatwave / Bottom-Up Model Scope",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Clear Answer",
  "",
  paste(
    "The 2014-2016 Blob / marine heatwave is a useful stress-test period,",
    "and bottom-up climate forcing remains plausible, but the current model",
    "evidence does not support making the heatwave the promoted explanation",
    "for Haida Gwaii non-recovery."
  ),
  "",
  "Use the talk-safe phrasing: **the Blob likely added climate stress to an already eroded portfolio; it is not, by itself, the recovery mechanism.**",
  "",
  "## Evidence",
  "",
  paste0(
    "- Closure period medians: total biomass `",
    number(period_line("2005-2013 closure", total_biomass_median), accuracy = 1, big.mark = ","),
    "` pre-MHW, `",
    number(period_line("2014-2016 marine heatwave", total_biomass_median), accuracy = 1, big.mark = ","),
    "` during MHW, and `",
    number(period_line("2017-2025 recent closure", total_biomass_median), accuracy = 1, big.mark = ","),
    "` recent. Occupied sections were `",
    fmt(period_line("2005-2013 closure", occupied_sections), 1),
    "`, `",
    fmt(period_line("2014-2016 marine heatwave", occupied_sections), 1),
    "`, and `",
    fmt(period_line("2017-2025 recent closure", occupied_sections), 1),
    "`."
  ),
  paste0(
    "- Lag-1 PDO remains the strongest long climate screen: n `", pdo_row$n,
    "`, Spearman rho `", fmt(pdo_row$spearman_rho, 2),
    "`, detrended r `", fmt(pdo_row$detrended_r, 2),
    "`, adjusted beta `", fmt(pdo_row$adjusted_beta, 2), "`."
  ),
  paste0(
    "- Lagged MHW pulse screen: n `", mhw_row$n,
    "`, Spearman rho `", fmt(mhw_row$spearman_rho, 2),
    "`, detrended r `", fmt(mhw_row$detrended_r, 2),
    "`, adjusted beta `", fmt(mhw_row$adjusted_beta, 2),
    "`, gate `", mhw_row$gate, "`. Contemporaneous MHW adjusted beta `",
    fmt(mhw_now$adjusted_beta, 2), "`."
  ),
  paste0(
    "- Satellite bottom-up covariates are short: lag-1 SST has n `", sst_row$n,
    "` and gate `", sst_row$gate, "`; lag-1 spring Chl-a has n `", chla_row$n,
    "` and gate `", chla_row$gate, "`."
  ),
  paste0(
    "- Spatially, `", spatial_tbl$sections_recent_below_pre, "` of `",
    spatial_tbl$sections, "` sections are lower in the recent closure period than pre-MHW; `",
    spatial_tbl$sections_recent_below_mhw, "` are lower than during MHW. A single regional pulse does not reproduce that heterogeneous section pattern."
  ),
  "",
  "## Modeling Implication",
  "",
  "- Do **not** launch a full AWS heatwave branch just to add a three-year binary pulse; the pulse is too short and too collinear with the post-closure context to carry a strong causal claim.",
  "- The promoted baseline already has the strongest model-ready climate term: lag-1 PDO. If climate needs one more model after the talk, the least risky branch is a **single-covariate sensitivity** that swaps or augments lag-1 PDO with PDO mean lag 0-1.",
  "- SST and Chl-a can support a post-2003 diagnostic, but they are not full-era model covariates. A Stan branch using them should be labelled a short-window sensitivity, not a promoted baseline candidate.",
  "- A real bottom-up energy test needs a zooplankton / forage-quality covariate, or an age/recruitment pathway. Those data are not yet in the promoted model input stream.",
  "",
  "## Candidate Branches If Needed",
  "",
  "1. `m1_stier_climate_window`: same observation layer, replace lag-1 PDO with PDO mean lag 0-1. Use only if a decision requires checking the exact window.",
  "2. `m1_stier_mhw_pulse`: add `beta_mhw * I(2014-2016)[t-1]` alongside lag-1 PDO. Treat as a negative-control sensitivity unless calibration improves materially.",
  "3. `m1_stier_chla_post2003`: Chl-a active only in years with satellite data, with missing years set inactive and reported as a short-window diagnostic.",
  "4. Future, not before talk: a recruitment/age or zooplankton-energy model once biological inputs and a source-traceable zooplankton product exist.",
  "",
  "## Files",
  "",
  "- `Output/figures/heatwave_bottomup_scope.pdf`",
  "- `Output/diagnostics/heatwave_bottomup_signal_screen.csv`",
  "- `Output/diagnostics/heatwave_bottomup_covariate_coverage.csv`",
  "- `Output/diagnostics/heatwave_bottomup_spatial_summary.csv`"
)

writeLines(lines, file.path(diag_dir, "heatwave_bottomup_scope.md"))

cat("Saved heatwave/bottom-up scope outputs:\n")
cat("  Output/diagnostics/heatwave_bottomup_scope.md\n")
cat("  Output/figures/heatwave_bottomup_scope.pdf\n")
