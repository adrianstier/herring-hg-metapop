# ============================================================================
# 07bj_wcvi_predation_replication_bridge.R
# WCVI predator-paper analogue for the HG Stier-aligned model.
#
# The WCVI paper treats predator consumption as removals/predation mortality in
# an age-structured assessment. This diagnostic keeps the current HG model
# biomass-based, but puts the predator product onto the same interpretive scale:
# annual consumption, removal-rate analogues, demand-vs-pressure separation,
# and negative-control screens before another Stan fit.
# ============================================================================

library(tidyverse)
library(here)
library(patchwork)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
pred_dir <- file.path(proj_dir, "Data", "processed", "predators")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

required_files <- c(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  file.path(pred_dir, "hg_predation_pressure_covariates.csv"),
  file.path(pred_dir, "hg_predator_consumption_by_group_year.csv")
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop(
    "Required diagnostic/predator files are missing. Rerun ",
    "`Code/07_m1_stier_11_population_driver_analysis.R` and ",
    "`Code/02c_integrate_hg_predator_repo_products.R`. Missing: ",
    paste(missing_files, collapse = ", ")
  )
}

fmt <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
}

z <- function(x) {
  as.numeric((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))
}

safe_cor <- function(x, y, method = "spearman") {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 10 || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

coef_or_na <- function(fit, term, column) {
  coefs <- coef(summary(fit))
  if (!term %in% rownames(coefs) || !column %in% colnames(coefs)) {
    return(NA_real_)
  }
  unname(coefs[term, column])
}

gate_lag1_screens <- function(tbl) {
  future_scores <- tbl %>%
    filter(lag_label == "future_1_negative_control") %>%
    transmute(label, class, grain, future_score = robust_score)

  tbl %>%
    left_join(future_scores, by = c("label", "class", "grain")) %>%
    mutate(
      future_score = replace_na(future_score, Inf),
      expected_negative = class %in% c(
        "demand",
        "pressure",
        "mortality_proxy",
        "spatial_exposure",
        "climate"
      ),
      expected_sign_ok = !expected_negative | (
        is.finite(spearman_rho) &
          is.finite(detrended_r) &
          is.finite(adjusted_beta) &
          spearman_rho < 0 &
          detrended_r < 0 &
          adjusted_beta < 0
      ),
      beats_future_negative_control = robust_score > future_score + 0.05,
      gate = case_when(
        lag_label != "lag_1" ~ screen_role,
        n < 20 ~ "fail_too_sparse",
        !expected_sign_ok ~ "fail_expected_sign_or_detrend",
        !beats_future_negative_control ~ "fail_future_negative_control",
        abs(detrended_r) < 0.05 ~ "fail_weak_detrended_signal",
        TRUE ~ "candidate_followup_only"
      )
    )
}

driver_ts <- read_csv(
  file.path(diag_dir, "m1_stier_11_driver_screening_timeseries.csv"),
  show_col_types = FALSE
) %>%
  arrange(year)

section_biomass <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  arrange(site_name, year) %>%
  group_by(site_name) %>%
  mutate(next_year_growth = log(lead(median) / median)) %>%
  ungroup() %>%
  select(section_name = site_name, site, year, next_year_growth)

exposure_tbl <- read_csv(
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  show_col_types = FALSE
)

pred_cov <- read_csv(
  file.path(pred_dir, "hg_predation_pressure_covariates.csv"),
  show_col_types = FALSE
) %>%
  arrange(year)

needed_pred_cols <- c(
  "C_total_kt",
  "C_birds_kt",
  "C_fish_kt",
  "C_mammals_kt",
  "C_salmon_kt",
  "pressure_pct",
  "pred_demand_total_log_z",
  "pred_mortality_mid_z",
  "pred_mortality_mid_detrended_z"
)
missing_cols <- setdiff(needed_pred_cols, names(pred_cov))
if (length(missing_cols) > 0) {
  stop(
    "Predator covariate file lacks demand columns: ",
    paste(missing_cols, collapse = ", "),
    ". Rerun Code/02c_integrate_hg_predator_repo_products.R."
  )
}

group_tbl <- read_csv(
  file.path(pred_dir, "hg_predator_consumption_by_group_year.csv"),
  show_col_types = FALSE
)

bridge_ts <- driver_ts %>%
  left_join(
    pred_cov %>%
      select(
        year,
        C_total_kt,
        C_birds_kt,
        C_fish_kt,
        C_mammals_kt,
        C_salmon_kt,
        pressure_pct,
        pred_demand_total_log_z,
        pred_demand_birds_log_z,
        pred_demand_fish_log_z,
        pred_demand_mammals_log_z,
        pred_demand_salmon_log_z,
        pred_pressure_log_z,
        pred_mortality_mid_z,
        pred_mortality_mid_detrended_z
      ),
    by = "year"
  ) %>%
  arrange(year) %>%
  mutate(
    total_biomass_kt = total_biomass_median / 1000,
    fishery_catch_kt = observed_catch_tonnes / 1000,
    predator_removal_rate = C_total_kt / pmax(total_biomass_kt + C_total_kt, 1e-12),
    fishery_removal_rate = fishery_catch_kt / pmax(total_biomass_kt + fishery_catch_kt, 1e-12),
    predator_plus_fishery_rate = (C_total_kt + fishery_catch_kt) /
      pmax(total_biomass_kt + C_total_kt + fishery_catch_kt, 1e-12),
    demand_total_log_z = z(log1p(C_total_kt)),
    demand_fish_log_z = z(log1p(C_fish_kt)),
    demand_mammals_log_z = z(log1p(C_mammals_kt)),
    demand_salmon_log_z = z(log1p(C_salmon_kt)),
    demand_birds_log_z = z(log1p(C_birds_kt)),
    pressure_ratio_log_z = z(log1p(pressure_pct)),
    year_z = z(year),
    pdo_lag1_z = z(pdo_lag1),
    fishing_lag1_z = z(fishing_fraction_median_lag1)
  )

predictor_specs <- tribble(
  ~predictor, ~label, ~class,
  "demand_total_log_z", "Total predator demand", "demand",
  "demand_fish_log_z", "Fish predator demand", "demand",
  "demand_mammals_log_z", "Marine mammal demand", "demand",
  "demand_salmon_log_z", "Salmon predator demand", "demand",
  "demand_birds_log_z", "Bird/egg predator demand", "demand",
  "pressure_ratio_log_z", "Predator pressure ratio", "pressure",
  "pred_mortality_mid_z", "Doherty Mp proxy", "mortality_proxy",
  "pred_mortality_mid_detrended_z", "Detrended Doherty Mp proxy", "mortality_proxy",
  "pdo", "PDO", "climate"
)

lag_specs <- tribble(
  ~lag_label, ~lag_n, ~screen_role,
  "future_1_negative_control", -1L, "negative control",
  "lag_0", 0L, "same year",
  "lag_1", 1L, "main candidate",
  "lag_2", 2L, "delayed candidate"
)

score_one <- function(pred_col, pred_label, pred_class, lag_label, lag_n, screen_role) {
  dat <- bridge_ts %>%
    transmute(
      year,
      period,
      growth = growth_median,
      predictor = if (lag_n < 0) {
        lead(.data[[pred_col]], abs(lag_n))
      } else if (lag_n > 0) {
        lag(.data[[pred_col]], lag_n)
      } else {
        .data[[pred_col]]
      },
      pdo_lag1_z,
      fishing_lag1_z,
      year_z,
      post_2005 = year >= 2005
    ) %>%
    filter(is.finite(growth), is.finite(predictor))

  if (nrow(dat) < 10 || sd(dat$growth) == 0 || sd(dat$predictor) == 0) {
    return(tibble(
      predictor = pred_col,
      label = pred_label,
      class = pred_class,
      lag_label,
      lag_n,
      screen_role,
      n = nrow(dat),
      spearman_rho = NA_real_,
      pearson_r = NA_real_,
      detrended_r = NA_real_,
      adjusted_beta = NA_real_,
      adjusted_p = NA_real_,
      adjusted_r2 = NA_real_,
      post_2005_rho = NA_real_
    ))
  }

  detrended_growth <- lm(growth ~ year_z, data = dat)
  detrended_predictor <- lm(predictor ~ year_z, data = dat)

  adj_dat <- dat %>%
    mutate(
      predictor_z = z(predictor),
      pdo_lag1_z = replace_na(pdo_lag1_z, 0),
      fishing_lag1_z = replace_na(fishing_lag1_z, 0)
    )
  adjusted <- lm(growth ~ predictor_z + pdo_lag1_z + fishing_lag1_z + year_z, data = adj_dat)

  tibble(
    predictor = pred_col,
    label = pred_label,
    class = pred_class,
    lag_label,
    lag_n,
    screen_role,
    n = nrow(dat),
    spearman_rho = safe_cor(dat$growth, dat$predictor, "spearman"),
    pearson_r = safe_cor(dat$growth, dat$predictor, "pearson"),
    detrended_r = safe_cor(resid(detrended_growth), resid(detrended_predictor), "pearson"),
    adjusted_beta = coef_or_na(adjusted, "predictor_z", "Estimate"),
    adjusted_p = coef_or_na(adjusted, "predictor_z", "Pr(>|t|)"),
    adjusted_r2 = summary(adjusted)$adj.r.squared,
    post_2005_rho = safe_cor(
      dat$growth[dat$post_2005],
      dat$predictor[dat$post_2005],
      "spearman"
    )
  )
}

screen_tbl <- crossing(predictor_specs, lag_specs) %>%
  pmap_dfr(function(predictor, label, class, lag_label, lag_n, screen_role) {
    score_one(predictor, label, class, lag_label, lag_n, screen_role)
  }) %>%
  mutate(
    grain = "annual",
    robust_score = abs(spearman_rho) + abs(detrended_r) + abs(adjusted_beta),
    main_candidate = predictor == "demand_total_log_z" & lag_label == "lag_1"
  )

exposure_candidates <- exposure_tbl %>%
  filter(
    kernel_km == 50,
    !extrapolated_dominant_flag,
    predator_species_or_source %in% c(
      "Harbour seal",
      "Steller sea lion raw non-pup",
      "Steller sea lion filled total"
    )
  ) %>%
  transmute(
    section_name,
    year,
    predictor = exposure_z,
    predictor_id = paste0(
      "exposure_",
      str_replace_all(str_to_lower(predator_species_or_source), "[^a-z0-9]+", "_")
    ),
    label = paste0(predator_species_or_source, " exposure"),
    class = "spatial_exposure",
    grain = "section_year",
    observed_count_flag,
    interpolated_flag,
    extrapolated_exposure_share,
    source_site_count
  )

combined_mammal_exposure <- exposure_tbl %>%
  filter(
    kernel_km == 50,
    !extrapolated_dominant_flag,
    predator_species_or_source %in% c("Harbour seal", "Steller sea lion filled total")
  ) %>%
  group_by(section_name, year) %>%
  summarise(
    extrapolated_exposure_share = sum(extrapolated_exposure_share * exposure, na.rm = TRUE) /
      pmax(sum(exposure, na.rm = TRUE), 1e-12),
    exposure = sum(exposure, na.rm = TRUE),
    observed_count_flag = any(observed_count_flag),
    interpolated_flag = any(interpolated_flag),
    source_site_count = sum(source_site_count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    predictor = z(log1p(exposure)),
    predictor_id = "exposure_combined_mammal",
    label = "Combined mammal exposure",
    class = "spatial_exposure",
    grain = "section_year"
  ) %>%
  select(
    section_name,
    year,
    predictor,
    predictor_id,
    label,
    class,
    grain,
    observed_count_flag,
    interpolated_flag,
    extrapolated_exposure_share,
    source_site_count
  )

exposure_candidates <- bind_rows(exposure_candidates, combined_mammal_exposure)

score_exposure_one <- function(pred_id, pred_label, pred_class, pred_grain, lag_label, lag_n, screen_role) {
  dat <- exposure_candidates %>%
    filter(predictor_id == pred_id) %>%
    mutate(growth_year = year + lag_n) %>%
    inner_join(
      section_biomass,
      by = c("section_name", "growth_year" = "year")
    ) %>%
    left_join(
      bridge_ts %>%
        select(year, period, pdo_lag1_z, fishing_lag1_z, year_z),
      by = c("growth_year" = "year")
    ) %>%
    transmute(
      year = growth_year,
      section_name,
      site,
      period,
      growth = next_year_growth,
      predictor,
      pdo_lag1_z,
      fishing_lag1_z,
      year_z,
      post_2005 = growth_year >= 2005,
      observed_count_flag,
      interpolated_flag,
      extrapolated_exposure_share,
      source_site_count
    ) %>%
    filter(is.finite(growth), is.finite(predictor), is.finite(year_z))

  if (nrow(dat) < 20 || sd(dat$growth) == 0 || sd(dat$predictor) == 0) {
    return(tibble(
      predictor = pred_id,
      label = pred_label,
      class = pred_class,
      grain = pred_grain,
      lag_label,
      lag_n,
      screen_role,
      n = nrow(dat),
      n_sections = n_distinct(dat$section_name),
      n_years = n_distinct(dat$year),
      observed_share = mean(dat$observed_count_flag, na.rm = TRUE),
      interpolated_share = mean(dat$interpolated_flag, na.rm = TRUE),
      median_extrapolated_exposure_share = median(dat$extrapolated_exposure_share, na.rm = TRUE),
      spearman_rho = NA_real_,
      pearson_r = NA_real_,
      detrended_r = NA_real_,
      adjusted_beta = NA_real_,
      adjusted_p = NA_real_,
      adjusted_r2 = NA_real_,
      post_2005_rho = NA_real_
    ))
  }

  detrended_growth <- lm(growth ~ year_z + section_name, data = dat)
  detrended_predictor <- lm(predictor ~ year_z + section_name, data = dat)

  adj_dat <- dat %>%
    mutate(
      predictor_z = z(predictor),
      pdo_lag1_z = replace_na(pdo_lag1_z, 0),
      fishing_lag1_z = replace_na(fishing_lag1_z, 0)
    )
  adjusted <- lm(
    growth ~ predictor_z + pdo_lag1_z + fishing_lag1_z + year_z + section_name,
    data = adj_dat
  )

  tibble(
    predictor = pred_id,
    label = pred_label,
    class = pred_class,
    grain = pred_grain,
    lag_label,
    lag_n,
    screen_role,
    n = nrow(dat),
    n_sections = n_distinct(dat$section_name),
    n_years = n_distinct(dat$year),
    observed_share = mean(dat$observed_count_flag, na.rm = TRUE),
    interpolated_share = mean(dat$interpolated_flag, na.rm = TRUE),
    median_extrapolated_exposure_share = median(dat$extrapolated_exposure_share, na.rm = TRUE),
    spearman_rho = safe_cor(dat$growth, dat$predictor, "spearman"),
    pearson_r = safe_cor(dat$growth, dat$predictor, "pearson"),
    detrended_r = safe_cor(resid(detrended_growth), resid(detrended_predictor), "pearson"),
    adjusted_beta = coef_or_na(adjusted, "predictor_z", "Estimate"),
    adjusted_p = coef_or_na(adjusted, "predictor_z", "Pr(>|t|)"),
    adjusted_r2 = summary(adjusted)$adj.r.squared,
    post_2005_rho = safe_cor(
      dat$growth[dat$post_2005],
      dat$predictor[dat$post_2005],
      "spearman"
    )
  )
}

exposure_specs <- exposure_candidates %>%
  distinct(predictor_id, label, class, grain)

exposure_screen_tbl <- crossing(exposure_specs, lag_specs) %>%
  pmap_dfr(function(predictor_id, label, class, grain, lag_label, lag_n, screen_role) {
    score_exposure_one(predictor_id, label, class, grain, lag_label, lag_n, screen_role)
  }) %>%
  mutate(
    robust_score = abs(spearman_rho) + abs(detrended_r) + abs(adjusted_beta),
    main_candidate = FALSE
  )

screen_tbl <- bind_rows(
  screen_tbl %>%
    mutate(
      n_sections = NA_integer_,
      n_years = n,
      observed_share = NA_real_,
      interpolated_share = NA_real_,
      median_extrapolated_exposure_share = NA_real_
    ),
  exposure_screen_tbl
) %>%
  gate_lag1_screens() %>%
  arrange(desc(main_candidate), desc(robust_score))

removal_period <- bridge_ts %>%
  group_by(period) %>%
  summarise(
    n_years = n(),
    median_biomass_kt = median(total_biomass_kt, na.rm = TRUE),
    median_predator_consumption_kt = median(C_total_kt, na.rm = TRUE),
    median_predator_removal_rate = median(predator_removal_rate, na.rm = TRUE),
    median_fishery_removal_rate = median(fishery_removal_rate, na.rm = TRUE),
    median_predator_plus_fishery_rate = median(predator_plus_fishery_rate, na.rm = TRUE),
    .groups = "drop"
  )

recent_group <- group_tbl %>%
  filter(year >= 2015, year <= 2024) %>%
  group_by(group) %>%
  summarise(mean_consumption_kt = mean(C_kt, na.rm = TRUE), .groups = "drop") %>%
  mutate(share = mean_consumption_kt / sum(mean_consumption_kt, na.rm = TRUE)) %>%
  arrange(desc(mean_consumption_kt))

recent_summary <- bridge_ts %>%
  filter(year >= 2015, year <= 2024) %>%
  summarise(
    mean_predator_consumption_kt = mean(C_total_kt, na.rm = TRUE),
    mean_biomass_kt = mean(total_biomass_kt, na.rm = TRUE),
    mean_predator_removal_rate = mean(predator_removal_rate, na.rm = TRUE),
    median_predator_removal_rate = median(predator_removal_rate, na.rm = TRUE),
    mean_pressure_pct = mean(pressure_pct, na.rm = TRUE),
    median_pressure_pct = median(pressure_pct, na.rm = TRUE),
    .groups = "drop"
  )

main_screen <- screen_tbl %>%
  filter(main_candidate) %>%
  slice(1)

exposure_lag1 <- screen_tbl %>%
  filter(class == "spatial_exposure", lag_label == "lag_1") %>%
  arrange(gate, desc(robust_score))

best_exposure <- exposure_lag1 %>%
  slice_max(robust_score, n = 1, with_ties = FALSE)

screen_gate_md <- screen_tbl %>%
  filter(lag_label == "lag_1", class %in% c("demand", "spatial_exposure", "mortality_proxy")) %>%
  arrange(class, gate, desc(robust_score)) %>%
  transmute(
    predictor = label,
    grain,
    n,
    `n sections` = n_sections,
    `rho` = number(spearman_rho, accuracy = 0.01),
    `detrended r` = number(detrended_r, accuracy = 0.01),
    `adjusted beta` = number(adjusted_beta, accuracy = 0.01),
    `median extrapolated exposure` = if_else(
      is.na(median_extrapolated_exposure_share),
      NA_character_,
      percent(median_extrapolated_exposure_share, accuracy = 1)
    ),
    `future control beaten` = if_else(beats_future_negative_control, "yes", "no"),
    gate
  )

p_removals <- bridge_ts %>%
  select(year, period, predator_removal_rate, fishery_removal_rate, predator_plus_fishery_rate) %>%
  pivot_longer(
    c(predator_removal_rate, fishery_removal_rate, predator_plus_fishery_rate),
    names_to = "rate",
    values_to = "value"
  ) %>%
  mutate(
    rate = recode(
      rate,
      predator_removal_rate = "Predator consumption analogue",
      fishery_removal_rate = "Fishery catch analogue",
      predator_plus_fishery_rate = "Predator + fishery analogue"
    )
  ) %>%
  ggplot(aes(x = year, y = value, colour = rate)) +
  geom_line(linewidth = 0.7, alpha = 0.92) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_colour_manual(values = c(
    "Predator consumption analogue" = "#7A3B2E",
    "Fishery catch analogue" = "#176B87",
    "Predator + fishery analogue" = "#4F7F52"
  )) +
  labs(
    x = NULL,
    y = "Removal-rate analogue",
    colour = NULL,
    title = "WCVI-style removals lens for Haida Gwaii",
    subtitle = "Rates use current HG predator consumption and m1_stier_11 posterior median biomass."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_screen <- screen_tbl %>%
  filter(lag_label %in% c("future_1_negative_control", "lag_1")) %>%
  mutate(
    label = paste0(label, " / ", grain, " (", lag_label, ")"),
    spearman_plot = replace_na(spearman_rho, 0),
    label = fct_reorder(label, spearman_plot)
  ) %>%
  ggplot(aes(x = spearman_plot, y = label, fill = screen_role)) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.3) +
  geom_col(width = 0.72) +
  scale_fill_manual(values = c(
    "main candidate" = "#176B87",
    "negative control" = "#999999"
  )) +
  labs(
    x = "Spearman rho with next-year latent growth",
    y = NULL,
    fill = NULL,
    title = "Demand screens with future-demand negative controls",
    subtitle = "A robust predator branch should beat time-trend and future-lag checks."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_group <- recent_group %>%
  mutate(group = fct_reorder(str_to_title(group), mean_consumption_kt)) %>%
  ggplot(aes(x = mean_consumption_kt, y = group, fill = group)) +
  geom_col(width = 0.72, show.legend = FALSE) +
  scale_fill_manual(values = c(
    Birds = "#8A7B28",
    Fish = "#176B87",
    Mammals = "#7A3B2E",
    Salmon = "#4F7F52"
  )) +
  labs(
    x = "Mean consumption, 2015-2024 (kt/yr)",
    y = NULL,
    title = "Current HG predator demand is not just mammals"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())

p <- p_removals / (p_screen | p_group) +
  plot_annotation(
    title = "Predation Replication Bridge",
    subtitle = "A biomass-based analogue to the WCVI predator-removals approach."
  )

ggsave(
  file.path(fig_dir, "wcvi_predation_replication_bridge.pdf"),
  p,
  width = 250,
  height = 230,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "wcvi_predation_replication_bridge.png"),
  p,
  width = 250,
  height = 230,
  units = "mm",
  dpi = 300
)

write_csv(bridge_ts, file.path(diag_dir, "wcvi_predation_replication_bridge_timeseries.csv"))
write_csv(screen_tbl, file.path(diag_dir, "wcvi_predator_demand_residual_screen.csv"))
write_csv(removal_period, file.path(diag_dir, "wcvi_predation_removal_period_summary.csv"))
write_csv(recent_group, file.path(diag_dir, "wcvi_predation_recent_group_contributions.csv"))

method_crosswalk <- tribble(
  ~wcvi_step, ~hg_replication_status, ~next_hg_action,
  "Bioenergetic predator consumption by predator group/species",
  "Partly replicated through the sibling HG predator consumption budget.",
  "Keep total and group demand as annual covariates; document species coverage and fill rules.",
  "Predators treated as removals/catch-like mortality",
  "Replicated descriptively with C/(B + C) removal-rate analogues, not yet inside the HG state process.",
  "Use demand covariate as the next Stier-aligned branch; only later consider a constrained predation-removal process.",
  "Catch-at-age herring assessment with predator selectivity",
  "Not replicated because the current HG analysis is intentionally biomass-based and section-level.",
  "Hold age/size structure; use group-specific demand and spatial exposure before adding age dimensions.",
  "Predation mortality compared with random-walk natural mortality",
  "Conceptually mirrored by comparing predator-demand screens against the promoted m1_stier_11 process and PDO.",
  "Fit one demand branch against m1_stier_11; do not combine predator groups unless a single branch clears gates.",
  "Section-level predator overlap / spatial exposure",
  "Partly replicated for harbour seal and Steller sea lion through 25/50/100 km distance-kernel exposure products.",
  "Use section-year exposure as a gated future branch only if it survives detrending, section controls, and future-lag negative controls.",
  "Future predator scenarios and unfished-equilibrium projections",
  "Not currently replicated.",
  "After a promoted or clearly useful predator process, build scenario projections; otherwise keep for discussion only."
)

write_csv(method_crosswalk, file.path(diag_dir, "wcvi_predation_method_crosswalk.csv"))

lines <- c(
  "# WCVI Predation Replication Bridge",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This diagnostic translates the Doherty et al. WCVI predation approach into the current Haida Gwaii analysis without leaving the promoted Stier-aligned observation layer.",
  "",
  "## Paper Method Being Replicated",
  "",
  "- WCVI paper: Doherty et al. 2025, ICES Journal of Marine Science, doi:10.1093/icesjms/fsae183.",
  "- Core idea: estimate predator consumption externally, then treat predator consumption as catch-like removals/predation mortality inside a herring assessment.",
  "- HG analogue here: use audited HG predator consumption as annual demand, compute removal-rate analogues against `m1_stier_11` biomass, and screen demand covariates before fitting another single-covariate branch.",
  "- Added HG spatial-exposure analogue: harbour seal and Steller sea lion site/count exposure is screened at the section-year grain before any section-level predator Stan branch.",
  "",
  "## Method Crosswalk",
  "",
  knitr::kable(method_crosswalk, format = "pipe"),
  "",
  "## Recent HG Scale",
  "",
  paste0(
    "- 2015-2024 mean predator consumption: `",
    fmt(recent_summary$mean_predator_consumption_kt, 2),
    "` kt/yr."
  ),
  paste0(
    "- 2015-2024 mean `m1_stier_11` all-11 biomass: `",
    fmt(recent_summary$mean_biomass_kt, 2),
    "` kt."
  ),
  paste0(
    "- 2015-2024 mean predator removal-rate analogue: `",
    percent(recent_summary$mean_predator_removal_rate, accuracy = 0.1),
    "`; median `",
    percent(recent_summary$median_predator_removal_rate, accuracy = 0.1),
    "`."
  ),
  paste0(
    "- 2015-2024 mean pressure ratio using observed spawn deposition: `",
    percent(recent_summary$mean_pressure_pct / 100, accuracy = 1),
    "`; median `",
    percent(recent_summary$median_pressure_pct / 100, accuracy = 1),
    "`."
  ),
  "",
  "## Demand Screen For The Next Branch",
  "",
  paste0(
    "- Main candidate `lag_1` total demand: n `",
    main_screen$n,
    "`, Spearman rho `",
    fmt(main_screen$spearman_rho, 2),
    "`, detrended r `",
    fmt(main_screen$detrended_r, 2),
    "`, adjusted beta `",
    fmt(main_screen$adjusted_beta, 2),
    "`, post-2005 rho `",
    fmt(main_screen$post_2005_rho, 2),
    "`."
  ),
  "- Treat pressure ratio as descriptive because it divides by observed HG spawn; use predator demand for the next model covariate.",
  "- Future-demand rows in `wcvi_predator_demand_residual_screen.csv` are negative controls; a credible branch should not rely only on monotonic calendar time.",
  "- The screen now includes raw and detrended Doherty-style `Mp_mid` proxies; the detrended row asks whether Mp carries signal after removing its linear calendar trend.",
  "",
  "## Exposure And Demand Gates",
  "",
  "Lag-1 rows are the only model-candidate rows. Future-lag rows remain in the CSV as negative controls, and section-year exposure rows exclude years where edge-held counts dominate exposure.",
  "",
  knitr::kable(screen_gate_md, format = "pipe"),
  "",
  paste0(
    "- Best 50 km section-exposure lag-1 row: `",
    best_exposure$label,
    "`, n `",
    best_exposure$n,
    "`, sections `",
    best_exposure$n_sections,
    "`, Spearman rho `",
    fmt(best_exposure$spearman_rho, 2),
    "`, detrended r `",
    fmt(best_exposure$detrended_r, 2),
    "`, adjusted beta `",
    fmt(best_exposure$adjusted_beta, 2),
    "`, gate `",
    best_exposure$gate,
    "`."
  ),
  "",
  "## Decision",
  "",
  "- Treat `m5_stier_predator_demand_total` as completed/held and do not submit another annual predator branch without a stronger residual-screen gate.",
  "- Prepare future `m6_stier_predator_exposure_mammals` only as a gated candidate; do not submit it until a section-year exposure signal survives detrending and future-lag controls.",
  "- Treat `m5_stier_doherty_proxy_removals` and `m5_stier_doherty_mp_covariate` as geometry-gated until reparameterized; use this bridge as the talk-safe predator diagnostic.",
  "- Keep zeros ambiguous, use two-era q, fit all 11 sections, and compare only against `m1_stier_11`.",
  "- Do not resurrect `m5_combined`; do not add group combinations until total demand or one group-specific branch improves calibration and remains sampler-clean.",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/wcvi_predation_replication_bridge_timeseries.csv`",
  "- `Output/diagnostics/wcvi_predator_demand_residual_screen.csv`",
  "- `Output/diagnostics/wcvi_predation_removal_period_summary.csv`",
  "- `Output/figures/wcvi_predation_replication_bridge.pdf`"
)

writeLines(lines, file.path(diag_dir, "wcvi_predation_replication_bridge.md"))

cat("Saved WCVI predation bridge diagnostics:\n")
cat("  Output/diagnostics/wcvi_predation_replication_bridge.md\n")
cat("  Output/diagnostics/wcvi_predator_demand_residual_screen.csv\n")
cat("  Output/figures/wcvi_predation_replication_bridge.pdf\n")
