# ============================================================================
# 07bs_predator_mechanism_integration_screen.R
# Integrated pre-Stan screen for predator hypotheses with fishing, PDO, and
# timing/substrate context.
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
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  file.path(diag_dir, "m1_stier_11_section_year_fishing_pressure.csv"),
  file.path(diag_dir, "fishing_pressure_decomposition_by_section.csv"),
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  file.path(diag_dir, "spawn_timing_substrate_section_change.csv"),
  file.path(pred_dir, "hg_predation_pressure_covariates.csv")
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Missing required files: ", paste(missing_files, collapse = ", "))
}

fmt <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
}

z <- function(x) {
  if (sum(is.finite(x)) < 2L || sd(x, na.rm = TRUE) == 0) {
    return(rep(NA_real_, length(x)))
  }
  as.numeric((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))
}

coef_or_na <- function(fit, term, column) {
  coefs <- coef(summary(fit))
  if (!term %in% rownames(coefs) || !column %in% colnames(coefs)) {
    return(NA_real_)
  }
  unname(coefs[term, column])
}

fit_term_screen <- function(dat, formula, term, min_n = 50L) {
  if (nrow(dat) < min_n) {
    return(tibble(
      term_beta = NA_real_,
      term_p = NA_real_,
      adjusted_r2 = NA_real_,
      gate_note = "too_sparse"
    ))
  }

  needed <- all.vars(formula)
  dat <- dat %>%
    filter(if_all(all_of(needed), ~ !is.na(.x)))

  if (nrow(dat) < min_n) {
    return(tibble(
      term_beta = NA_real_,
      term_p = NA_real_,
      adjusted_r2 = NA_real_,
      gate_note = "too_sparse_after_na_filter"
    ))
  }

  fit <- try(lm(formula, data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(tibble(
      term_beta = NA_real_,
      term_p = NA_real_,
      adjusted_r2 = NA_real_,
      gate_note = "lm_failed"
    ))
  }

  tibble(
    term_beta = coef_or_na(fit, term, "Estimate"),
    term_p = coef_or_na(fit, term, "Pr(>|t|)"),
    adjusted_r2 = summary(fit)$adj.r.squared,
    gate_note = if_else(is.finite(term_beta), "fit_ok", "term_unavailable")
  )
}

safe_cor <- function(x, y, method = "spearman") {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 10L || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

section_biomass <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  arrange(site_name, year) %>%
  group_by(site, site_name) %>%
  mutate(
    next_year_growth = log(lead(median) / median),
    next_year = year + 1
  ) %>%
  ungroup() %>%
  mutate(section_name = site_name) %>%
  select(site, site_name, section_name, year, next_year_growth)

section_fishing <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_year_fishing_pressure.csv"),
  show_col_types = FALSE
) %>%
  select(site, site_name, year, annual_fishing_fraction = fishing_fraction_median)

historical_fishing <- read_csv(
  file.path(diag_dir, "fishing_pressure_decomposition_by_section.csv"),
  show_col_types = FALSE
) %>%
  select(
    site,
    site_name,
    focal_status,
    recent_to_early_ratio,
    log_recent_to_early,
    mean_fishing_fraction_1951_2004,
    catch_per_early_biomass,
    fishing_only_resid,
    survey_coverage,
    spawn_fit_rmse,
    recovery_class
  ) %>%
  mutate(
    historical_fishing_z = z(mean_fishing_fraction_1951_2004),
    catch_per_early_biomass_z = z(catch_per_early_biomass),
    fishing_only_resid_z = z(fishing_only_resid)
  )

pred_cov <- read_csv(
  file.path(pred_dir, "hg_predation_pressure_covariates.csv"),
  show_col_types = FALSE
) %>%
  arrange(year) %>%
  mutate(
    demand_total_z = z(log1p(C_total_kt)),
    demand_fish_z = z(log1p(C_fish_kt)),
    demand_mammals_z = z(log1p(C_mammals_kt)),
    demand_salmon_z = z(log1p(C_salmon_kt)),
    demand_birds_z = z(log1p(C_birds_kt)),
    pressure_ratio_z = z(log1p(pressure_pct)),
    pdo_lag1_z = z(lag(pdo, 1)),
    pdo_z = z(pdo),
    year_z = z(year)
  ) %>%
  select(
    year,
    demand_total_z,
    demand_fish_z,
    demand_mammals_z,
    demand_salmon_z,
    demand_birds_z,
    pressure_ratio_z,
    pred_mortality_mid_detrended_z,
    pdo_lag1_z,
    pdo_z,
    year_z
  )

growth_base <- section_biomass %>%
  left_join(section_fishing, by = c("site", "site_name", "year")) %>%
  left_join(historical_fishing, by = c("site", "site_name")) %>%
  left_join(pred_cov, by = "year") %>%
  mutate(
    annual_fishing_z = z(annual_fishing_fraction),
    annual_fishing_z = replace_na(annual_fishing_z, 0),
    pdo_lag1_z = replace_na(pdo_lag1_z, 0),
    year_z = replace_na(year_z, 0)
  ) %>%
  filter(is.finite(next_year_growth))

annual_predictors <- tribble(
  ~predictor, ~label, ~class,
  "demand_total_z", "Total predator demand", "annual_demand",
  "demand_fish_z", "Fish predator demand", "annual_demand",
  "demand_mammals_z", "Marine mammal demand", "annual_demand",
  "demand_salmon_z", "Salmon predator demand", "annual_demand",
  "demand_birds_z", "Bird/egg predator demand", "annual_demand",
  "pred_mortality_mid_detrended_z", "Detrended Doherty Mp proxy", "mortality_proxy"
)

lag_specs <- tribble(
  ~lag_label, ~lag_n, ~screen_role,
  "future_1_negative_control", -1L, "negative_control",
  "lag_0", 0L, "same_year",
  "lag_1", 1L, "main_candidate",
  "lag_2", 2L, "delayed_candidate"
)

make_lagged_annual <- function(tbl, pred_col, lag_n) {
  year_tbl <- tbl %>%
    distinct(year, .data[[pred_col]]) %>%
    arrange(year)

  if (lag_n < 0) {
    year_tbl <- year_tbl %>%
      mutate(predictor = lead(.data[[pred_col]], abs(lag_n)))
  } else if (lag_n > 0) {
    year_tbl <- year_tbl %>%
      mutate(predictor = lag(.data[[pred_col]], lag_n))
  } else {
    year_tbl <- year_tbl %>%
      mutate(predictor = .data[[pred_col]])
  }

  year_tbl <- year_tbl %>%
    select(year, predictor)

  tbl %>%
    select(-any_of("predictor")) %>%
    left_join(year_tbl, by = "year")
}

score_annual <- function(pred_col, label, class, lag_label, lag_n, screen_role) {
  dat <- make_lagged_annual(growth_base, pred_col, lag_n) %>%
    filter(is.finite(predictor), is.finite(historical_fishing_z))

  main_fit <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor)),
    next_year_growth ~ predictor_z + pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z"
  )

  fishing_interaction <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor), moderator_z = historical_fishing_z),
    next_year_growth ~ predictor_z * moderator_z + pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z:moderator_z"
  )

  bind_rows(
    tibble(
      test_id = paste0(pred_col, "_main"),
      predictor = pred_col,
      label,
      class,
      mechanism = "annual_predator_main_effect",
      term = "predictor_z",
      expected_term_sign = "negative"
    ) %>%
      bind_cols(main_fit),
    tibble(
      test_id = paste0(pred_col, "_x_historical_fishing"),
      predictor = pred_col,
      label = paste0(label, " x historical fishing"),
      class,
      mechanism = "predator_x_historical_fishing",
      term = "predictor_z:moderator_z",
      expected_term_sign = "negative"
    ) %>%
      bind_cols(fishing_interaction)
  ) %>%
    mutate(
      lag_label,
      lag_n,
      screen_role,
      grain = "section_year",
      n = nrow(dat),
      n_sections = n_distinct(dat$site_name),
      n_years = n_distinct(dat$year),
      spearman_rho = safe_cor(dat$next_year_growth, dat$predictor, "spearman"),
      post_2005_rho = safe_cor(
        dat$next_year_growth[dat$year >= 2005],
        dat$predictor[dat$year >= 2005],
        "spearman"
      ),
      median_extrapolated_exposure_share = NA_real_,
      source_data = "Data/processed/predators/hg_predation_pressure_covariates.csv"
    )
}

annual_screen <- crossing(annual_predictors, lag_specs) %>%
  pmap_dfr(function(predictor, label, class, lag_label, lag_n, screen_role) {
    score_annual(predictor, label, class, lag_label, lag_n, screen_role)
  })

exposure_raw <- read_csv(
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  show_col_types = FALSE
)

exposure_candidates <- exposure_raw %>%
  filter(
    !extrapolated_dominant_flag,
    (
      predator_species_or_source == "Harbour seal" &
        kernel_role == "working_default_local_haulout"
    ) |
      (
        predator_species_or_source %in% c("Steller sea lion filled total", "Steller sea lion raw non-pup") &
          kernel_role == "working_default_ssl_haulout_foraging"
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
    observed_count_flag,
    interpolated_flag,
    extrapolated_exposure_share,
    source_data = source_file
  )

combined_mammal_exposure <- exposure_raw %>%
  filter(
    !extrapolated_dominant_flag,
    (
      predator_species_or_source == "Harbour seal" &
        kernel_role == "working_default_local_haulout"
    ) |
      (
        predator_species_or_source == "Steller sea lion filled total" &
          kernel_role == "working_default_ssl_haulout_foraging"
      )
  ) %>%
  group_by(section_name, year) %>%
  summarise(
    exposure = sum(exposure, na.rm = TRUE),
    extrapolated_exposure_share = sum(extrapolated_exposure_share * exposure, na.rm = TRUE) /
      pmax(sum(exposure, na.rm = TRUE), 1e-12),
    observed_count_flag = any(observed_count_flag),
    interpolated_flag = any(interpolated_flag),
    source_data = paste(unique(source_file), collapse = "; "),
    .groups = "drop"
  ) %>%
  mutate(
    predictor = z(log1p(exposure)),
    predictor_id = "exposure_combined_mammal_working_defaults",
    label = "Combined mammal exposure",
    class = "spatial_exposure"
  ) %>%
  select(
    section_name,
    year,
    predictor,
    predictor_id,
    label,
    class,
    observed_count_flag,
    interpolated_flag,
    extrapolated_exposure_share,
    source_data
  )

exposure_candidates <- bind_rows(exposure_candidates, combined_mammal_exposure)

score_exposure <- function(pred_id, label, class, lag_label, lag_n, screen_role) {
  dat <- exposure_candidates %>%
    filter(predictor_id == pred_id) %>%
    mutate(growth_year = year + lag_n) %>%
    inner_join(
      growth_base,
      by = c("section_name", "growth_year" = "year")
    ) %>%
    filter(is.finite(predictor), is.finite(next_year_growth), is.finite(historical_fishing_z))

  main_fit <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor)),
    next_year_growth ~ predictor_z + pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z"
  )

  fishing_interaction <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor), moderator_z = historical_fishing_z),
    next_year_growth ~ predictor_z * moderator_z + pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z:moderator_z"
  )

  pdo_interaction <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor)),
    next_year_growth ~ predictor_z * pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z:pdo_lag1_z"
  )

  bind_rows(
    tibble(
      test_id = paste0(pred_id, "_main"),
      predictor = pred_id,
      label,
      class,
      mechanism = "section_exposure_main_effect",
      term = "predictor_z",
      expected_term_sign = "negative"
    ) %>%
      bind_cols(main_fit),
    tibble(
      test_id = paste0(pred_id, "_x_historical_fishing"),
      predictor = pred_id,
      label = paste0(label, " x historical fishing"),
      class,
      mechanism = "exposure_x_historical_fishing",
      term = "predictor_z:moderator_z",
      expected_term_sign = "negative"
    ) %>%
      bind_cols(fishing_interaction),
    tibble(
      test_id = paste0(pred_id, "_x_pdo"),
      predictor = pred_id,
      label = paste0(label, " x PDO"),
      class,
      mechanism = "exposure_x_pdo",
      term = "predictor_z:pdo_lag1_z",
      expected_term_sign = "screen_only"
    ) %>%
      bind_cols(pdo_interaction)
  ) %>%
    mutate(
      lag_label,
      lag_n,
      screen_role,
      grain = "section_year",
      n = nrow(dat),
      n_sections = n_distinct(dat$section_name),
      n_years = n_distinct(dat$growth_year),
      spearman_rho = safe_cor(dat$next_year_growth, dat$predictor, "spearman"),
      post_2005_rho = safe_cor(
        dat$next_year_growth[dat$growth_year >= 2005],
        dat$predictor[dat$growth_year >= 2005],
        "spearman"
      ),
      median_extrapolated_exposure_share = median(dat$extrapolated_exposure_share, na.rm = TRUE),
      source_data = paste(unique(dat$source_data), collapse = "; ")
    )
}

exposure_specs <- exposure_candidates %>%
  distinct(predictor_id, label, class)

exposure_screen <- crossing(exposure_specs, lag_specs) %>%
  pmap_dfr(function(predictor_id, label, class, lag_label, lag_n, screen_role) {
    score_exposure(predictor_id, label, class, lag_label, lag_n, screen_role)
  })

apply_gate <- function(tbl) {
  future_scores <- tbl %>%
    filter(lag_label == "future_1_negative_control") %>%
    transmute(test_id, future_abs_beta = abs(term_beta))

  tbl %>%
    left_join(future_scores, by = "test_id") %>%
    mutate(
      future_abs_beta = replace_na(future_abs_beta, Inf),
      abs_beta = abs(term_beta),
      expected_sign_ok = case_when(
        expected_term_sign == "negative" ~ is.finite(term_beta) & term_beta < 0,
        expected_term_sign == "positive" ~ is.finite(term_beta) & term_beta > 0,
        TRUE ~ is.finite(term_beta)
      ),
      directional_correlation_ok = case_when(
        mechanism %in% c("annual_predator_main_effect", "section_exposure_main_effect") ~
          is.finite(spearman_rho) & spearman_rho < 0 &
            (!is.finite(post_2005_rho) | post_2005_rho < 0),
        TRUE ~ TRUE
      ),
      beats_future_negative_control = abs_beta > future_abs_beta + 0.02,
      gate = case_when(
        lag_label != "lag_1" ~ screen_role,
        gate_note != "fit_ok" ~ paste0("fail_", gate_note),
        n < 50 ~ "fail_too_sparse",
        n_sections < 8 ~ "fail_too_few_sections",
        expected_term_sign == "screen_only" ~ "screen_only_no_directional_gate",
        !expected_sign_ok ~ "fail_expected_sign",
        !directional_correlation_ok ~ "fail_raw_or_recent_direction",
        abs_beta < 0.05 ~ "fail_weak_effect_size",
        !beats_future_negative_control ~ "fail_future_negative_control",
        is.finite(term_p) & term_p > 0.2 ~ "followup_only_weak_p",
        TRUE ~ "candidate_followup_only"
      )
    )
}

integrated_screen <- bind_rows(annual_screen, exposure_screen) %>%
  apply_gate() %>%
  arrange(
    desc(lag_label == "lag_1"),
    desc(gate == "candidate_followup_only"),
    desc(abs_beta)
  )

timing_change <- read_csv(
  file.path(diag_dir, "spawn_timing_substrate_section_change.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    site_name = model_site_name,
    delta_spawn_start_doy,
    delta_subtidal_share,
    delta_substrate_effective_n
  )

recent_exposure_section <- exposure_raw %>%
  filter(
    year >= 2017,
    (
      predator_species_or_source == "Harbour seal" &
        kernel_role == "working_default_local_haulout"
    ) |
      (
        predator_species_or_source == "Steller sea lion filled total" &
          kernel_role == "working_default_ssl_haulout_foraging"
      )
  ) %>%
  group_by(section_name, predator_species_or_source) %>%
  summarise(
    recent_exposure_z = median(exposure_z, na.rm = TRUE),
    median_extrapolated_exposure_share = median(extrapolated_exposure_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(predator_key = case_when(
    predator_species_or_source == "Harbour seal" ~ "harbour_seal",
    predator_species_or_source == "Steller sea lion filled total" ~ "steller_sea_lion",
    TRUE ~ str_replace_all(str_to_lower(predator_species_or_source), "[^a-z0-9]+", "_")
  )) %>%
  select(section_name, predator_key, recent_exposure_z) %>%
  pivot_wider(
    names_from = predator_key,
    values_from = recent_exposure_z,
    names_glue = "{predator_key}_recent_exposure_z"
  ) %>%
  rename(site_name = section_name)

if (!"harbour_seal_recent_exposure_z" %in% names(recent_exposure_section)) {
  recent_exposure_section$harbour_seal_recent_exposure_z <- NA_real_
}
if (!"steller_sea_lion_recent_exposure_z" %in% names(recent_exposure_section)) {
  recent_exposure_section$steller_sea_lion_recent_exposure_z <- NA_real_
}

section_endpoint <- historical_fishing %>%
  left_join(recent_exposure_section, by = "site_name") %>%
  left_join(timing_change, by = "site_name") %>%
  mutate(
    harbour_seal_recent_exposure_z = z(harbour_seal_recent_exposure_z),
    steller_sea_lion_recent_exposure_z = z(steller_sea_lion_recent_exposure_z),
    delta_spawn_start_doy_z = z(delta_spawn_start_doy),
    delta_subtidal_share_z = z(delta_subtidal_share),
    delta_substrate_effective_n_z = z(delta_substrate_effective_n)
  )

section_fit <- function(pred_col, label, family, min_n = 8L) {
  dat <- section_endpoint %>%
    mutate(predictor_z = .data[[pred_col]]) %>%
    filter(is.finite(log_recent_to_early), is.finite(predictor_z))

  fit <- fit_term_screen(
    dat,
    log_recent_to_early ~ predictor_z,
    "predictor_z",
    min_n = min_n
  )

  tibble(
    test_id = paste0("section_endpoint_", pred_col),
    label,
    class = family,
    mechanism = "section_recovery_endpoint",
    grain = "section",
    n = nrow(dat),
    n_sections = n_distinct(dat$site_name),
    n_years = NA_integer_,
    lag_label = "recent_vs_early",
    lag_n = NA_integer_,
    screen_role = "section_endpoint",
    term = "predictor_z",
    expected_term_sign = "screen_only",
    spearman_rho = safe_cor(dat$log_recent_to_early, dat$predictor_z, "spearman"),
    post_2005_rho = NA_real_,
    median_extrapolated_exposure_share = NA_real_,
    source_data = "Output/diagnostics/fishing_pressure_decomposition_by_section.csv; Output/diagnostics/spawn_timing_substrate_section_change.csv; Output/diagnostics/predator_spatial_exposure_section_year.csv"
  ) %>%
    bind_cols(fit) %>%
    mutate(
      future_abs_beta = NA_real_,
      abs_beta = abs(term_beta),
      expected_sign_ok = TRUE,
      beats_future_negative_control = NA,
      gate = case_when(
        n < min_n ~ "descriptive_too_sparse",
        TRUE ~ "descriptive_section_endpoint"
      )
    )
}

section_endpoint_screen <- bind_rows(
  section_fit("historical_fishing_z", "Historical fishing pressure", "historical_fishing"),
  section_fit("harbour_seal_recent_exposure_z", "Recent harbour seal exposure", "spatial_exposure"),
  section_fit("steller_sea_lion_recent_exposure_z", "Recent Steller sea lion exposure", "spatial_exposure"),
  section_fit("delta_spawn_start_doy_z", "Recent minus early spawn timing", "timing_substrate", min_n = 5L),
  section_fit("delta_subtidal_share_z", "Recent minus early subtidal share", "timing_substrate", min_n = 5L),
  section_fit("delta_substrate_effective_n_z", "Recent minus early substrate diversity", "timing_substrate", min_n = 5L)
)

write_csv(
  integrated_screen,
  file.path(diag_dir, "predator_mechanism_integration_screen.csv")
)
write_csv(
  section_endpoint_screen,
  file.path(diag_dir, "predator_mechanism_section_endpoint_screen.csv")
)

lag1_screen <- integrated_screen %>%
  filter(lag_label == "lag_1")

candidate_rows <- lag1_screen %>%
  filter(gate == "candidate_followup_only")

strongest_rows <- lag1_screen %>%
  arrange(desc(abs_beta)) %>%
  slice_head(n = 12)

best_predator_fishing <- lag1_screen %>%
  filter(str_detect(mechanism, "historical_fishing")) %>%
  arrange(desc(abs_beta)) %>%
  slice(1)

best_exposure <- lag1_screen %>%
  filter(class == "spatial_exposure") %>%
  arrange(desc(abs_beta)) %>%
  slice(1)

section_top <- section_endpoint_screen %>%
  arrange(desc(abs_beta)) %>%
  slice_head(n = 8)

p_lag1 <- lag1_screen %>%
  filter(mechanism %in% c(
    "predator_x_historical_fishing",
    "exposure_x_historical_fishing",
    "section_exposure_main_effect",
    "annual_predator_main_effect"
  )) %>%
  filter(is.finite(term_beta)) %>%
  mutate(
    label = fct_reorder(str_wrap(label, 34), term_beta),
    gate_group = case_when(
      gate == "candidate_followup_only" ~ "candidate",
      str_detect(gate, "^followup") ~ "weak follow-up",
      TRUE ~ "failed gate"
    )
  ) %>%
  ggplot(aes(x = term_beta, y = label, fill = gate_group)) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(width = 0.7) +
  facet_wrap(~ mechanism, scales = "free_y", ncol = 1) +
  labs(
    x = "Lag-1 standardized coefficient or interaction coefficient",
    y = NULL,
    fill = NULL,
    title = "Predator integration screens against m1_stier_11 growth",
    subtitle = "Negative values match the expected predator/recovery direction; gates require beating future-lag controls."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_section <- section_endpoint_screen %>%
  filter(is.finite(term_beta)) %>%
  mutate(label = fct_reorder(str_wrap(label, 28), term_beta)) %>%
  ggplot(aes(x = term_beta, y = label, fill = class)) +
  geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.3) +
  geom_col(width = 0.7) +
  labs(
    x = "Section endpoint scaled slope",
    y = NULL,
    fill = NULL,
    title = "Section recovery endpoint remains descriptive",
    subtitle = "n = 11 or fewer; useful for triage, not causal identification."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_lag1 | p_section

ggsave(
  file.path(fig_dir, "predator_mechanism_integration_screen.pdf"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "predator_mechanism_integration_screen.png"),
  p,
  width = 260,
  height = 190,
  units = "mm",
  dpi = 300
)

screen_md <- strongest_rows %>%
  transmute(
    mechanism,
    label,
    n,
    sections = n_sections,
    beta = number(term_beta, accuracy = 0.01),
    p = number(term_p, accuracy = 0.01),
    `future beta` = number(future_abs_beta, accuracy = 0.01),
    gate
  )

section_md <- section_top %>%
  transmute(
    family = class,
    label,
    n,
    beta = number(term_beta, accuracy = 0.01),
    rho = number(spearman_rho, accuracy = 0.01),
    gate
  )

candidate_text <- if (nrow(candidate_rows) == 0) {
  "- No integrated predator screen clears the lag-1 candidate gate."
} else {
  candidate_rows %>%
    transmute(line = paste0(
      "- Candidate: `", label, "` via `", mechanism, "`, beta `",
      number(term_beta, accuracy = 0.01),
      "`, p `", number(term_p, accuracy = 0.01), "`."
    )) %>%
    pull(line)
}

best_pf_text <- if (nrow(best_predator_fishing) == 0) {
  "- No predator x historical-fishing row was available."
} else {
  paste0(
    "- Strongest predator/fishing integration row: `",
    best_predator_fishing$label,
    "` beta `",
    number(best_predator_fishing$term_beta, accuracy = 0.01),
    "`, p `",
    number(best_predator_fishing$term_p, accuracy = 0.01),
    "`, gate `",
    best_predator_fishing$gate,
    "`."
  )
}

best_exposure_text <- if (nrow(best_exposure) == 0) {
  "- No section-exposure row was available."
} else {
  paste0(
    "- Strongest exposure row: `",
    best_exposure$label,
    "` beta `",
    number(best_exposure$term_beta, accuracy = 0.01),
    "`, p `",
    number(best_exposure$term_p, accuracy = 0.01),
    "`, gate `",
    best_exposure$gate,
    "`."
  )
}

lines <- c(
  "# Predator Mechanism Integration Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  "- This is a pre-Stan residual screen against `m1_stier_11` section-year growth, not a fitted predator model.",
  "- It tests whether predator demand or section exposure becomes more informative when combined with historical fishing pressure, PDO, and section/year controls.",
  candidate_text,
  best_pf_text,
  best_exposure_text,
  "- Section endpoint timing/substrate rows remain descriptive because only a subset of sections has complete early-vs-recent timing/substrate contrasts.",
  "",
  "## Gate Logic",
  "",
  "- Main lag is `lag_1`; `future_1_negative_control` is used as the negative-control benchmark.",
  "- Predator and predator x fishing terms must be negative, have absolute standardized coefficient at least 0.05, use at least 50 section-years and 8 sections, and beat the future-lag coefficient by at least 0.02.",
  "- Main-effect predator rows must also have the expected negative raw and recent-period direction; a negative adjusted coefficient alone is not enough.",
  "- `candidate_followup_only` means the row can justify a targeted local smoke or data-product refinement; it is not promotion evidence.",
  "",
  "## Strongest Lag-1 Integrated Rows",
  "",
  knitr::kable(screen_md, format = "pipe"),
  "",
  "## Section Endpoint Context",
  "",
  knitr::kable(section_md, format = "pipe"),
  "",
  "## Decision",
  "",
  "- Do not launch a combined predator Stan model from this screen alone.",
  "- If a next model is needed, prefer a single interaction branch only after the candidate row also makes biological sense in section plots and local data provenance.",
  "- Keep the talk framing as: predation is plausible and large, but current integrated evidence points to data-product refinement before predator-effect inference.",
  "",
  "## Source Files",
  "",
  "- `Output/diagnostics/m1_stier_11_section_biomass_by_year.csv`",
  "- `Output/diagnostics/m1_stier_11_section_year_fishing_pressure.csv`",
  "- `Output/diagnostics/fishing_pressure_decomposition_by_section.csv`",
  "- `Output/diagnostics/predator_spatial_exposure_section_year.csv`",
  "- `Output/diagnostics/spawn_timing_substrate_section_change.csv`",
  "- `Data/processed/predators/hg_predation_pressure_covariates.csv`",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/predator_mechanism_integration_screen.csv`",
  "- `Output/diagnostics/predator_mechanism_section_endpoint_screen.csv`",
  "- `Output/figures/predator_mechanism_integration_screen.pdf`"
)

writeLines(lines, file.path(diag_dir, "predator_mechanism_integration_screen.md"))

cat("Saved predator mechanism integration screen:\n")
cat("  Output/diagnostics/predator_mechanism_integration_screen.md\n")
cat("  Output/diagnostics/predator_mechanism_integration_screen.csv\n")
cat("  Output/figures/predator_mechanism_integration_screen.pdf\n")
