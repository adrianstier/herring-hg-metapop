# ============================================================================
# 07bt_postclosure_recovery_mechanism_screen.R
# Integrated screen for why herring may not recover after the post-2005 closure.
#
# This is a diagnostic gate, not a Stan model. It separates:
#   1. historical fishing / legacy depletion,
#   2. local spawning-location persistence and recolonization,
#   3. post-closure predator and climate pressure,
#   4. timing/substrate endpoint context,
#   5. observation and survey-coverage caveats.
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
  file.path(diag_dir, "m1_stier_11_postclosure_recovery_by_section.csv"),
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  file.path(diag_dir, "spawn_timing_substrate_section_change.csv"),
  file.path(diag_dir, "lead_section_location_transition_summary.csv"),
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

safe_cor <- function(x, y, method = "spearman", min_n = 6L) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < min_n || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
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

fit_term_screen <- function(dat, formula, term, min_n = 20L) {
  needed <- all.vars(formula)
  dat <- dat %>%
    filter(if_all(all_of(needed), ~ !is.na(.x)))

  if (nrow(dat) < min_n) {
    return(tibble(
      beta = NA_real_,
      p = NA_real_,
      adjusted_r2 = NA_real_,
      fit_note = "too_sparse"
    ))
  }

  fit <- try(lm(formula, data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(tibble(
      beta = NA_real_,
      p = NA_real_,
      adjusted_r2 = NA_real_,
      fit_note = "lm_failed"
    ))
  }

  tibble(
    beta = coef_or_na(fit, term, "Estimate"),
    p = coef_or_na(fit, term, "Pr(>|t|)"),
    adjusted_r2 = summary(fit)$adj.r.squared,
    fit_note = if_else(is.finite(beta), "fit_ok", "term_unavailable")
  )
}

period_for_year <- function(year) {
  case_when(
    year >= 2005 & year <= 2013 ~ "2005-2013 closure",
    year >= 2014 & year <= 2016 ~ "2014-2016 marine heatwave",
    year >= 2017 & year <= 2025 ~ "2017-2025 recent closure",
    TRUE ~ "outside_postclosure"
  )
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
  select(site, site_name, section_name, focal_status, year, median, next_year_growth, next_year)

section_fishing <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_year_fishing_pressure.csv"),
  show_col_types = FALSE
) %>%
  select(site, site_name, year, annual_fishing_fraction = fishing_fraction_median)

fishing_endpoint <- read_csv(
  file.path(diag_dir, "fishing_pressure_decomposition_by_section.csv"),
  show_col_types = FALSE
) %>%
  select(
    site,
    site_name,
    focal_status,
    early_biomass,
    recent_biomass,
    recent_to_early_ratio,
    log_recent_to_early,
    mean_fishing_fraction_1951_2004,
    catch_per_early_biomass,
    fishing_only_resid,
    recent_pct_per_year,
    rebound_from_postclosure_min,
    recovery_class,
    spawn_fit_rmse,
    survey_coverage,
    recent_biomass_share,
    status
  ) %>%
  mutate(
    historical_fishing_z = z(mean_fishing_fraction_1951_2004),
    catch_per_early_biomass_z = z(catch_per_early_biomass),
    worse_than_fishing_z = z(-fishing_only_resid)
  )

postclosure_recovery <- read_csv(
  file.path(diag_dir, "m1_stier_11_postclosure_recovery_by_section.csv"),
  show_col_types = FALSE
) %>%
  select(
    site,
    postclosure_min_year,
    postclosure_min_biomass,
    closure_pct_per_year,
    closure_r2,
    recent_pct_per_year,
    recent_r2,
    postclosure_rebound_from_min = rebound_from_postclosure_min,
    recovery_class
  ) %>%
  rename(
    closure_trend_pct_per_year = closure_pct_per_year,
    recent_trend_pct_per_year = recent_pct_per_year,
    postclosure_recovery_class = recovery_class
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
    pressure_ratio_z = z(log1p(pressure_pct)),
    pdo_lag1_z = z(lag(pdo, 1)),
    mhw_indicator = as.integer(year >= 2014 & year <= 2016),
    recent_closure_indicator = as.integer(year >= 2017),
    year_z = z(year)
  ) %>%
  select(
    year,
    demand_total_z,
    demand_fish_z,
    demand_mammals_z,
    demand_salmon_z,
    pressure_ratio_z,
    pdo_lag1_z,
    mhw_indicator,
    recent_closure_indicator,
    year_z
  )

postclosure_growth <- section_biomass %>%
  filter(year >= 2005, year <= 2024) %>%
  left_join(section_fishing, by = c("site", "site_name", "year")) %>%
  left_join(fishing_endpoint, by = c("site", "site_name", "focal_status")) %>%
  left_join(pred_cov, by = "year") %>%
  mutate(
    period = period_for_year(year),
    annual_fishing_z = z(annual_fishing_fraction),
    annual_fishing_z = replace_na(annual_fishing_z, 0),
    pdo_lag1_z = replace_na(pdo_lag1_z, 0),
    year_z = replace_na(year_z, 0)
  ) %>%
  filter(is.finite(next_year_growth))

annual_predictors <- tribble(
  ~predictor, ~label, ~pathway, ~expected_sign,
  "demand_total_z", "Total predator demand", "postclosure predator demand", "negative",
  "demand_fish_z", "Fish predator demand", "postclosure predator demand", "negative",
  "demand_mammals_z", "Marine mammal demand", "postclosure predator demand", "negative",
  "demand_salmon_z", "Salmon predator demand", "recruitment/juvenile context", "negative",
  "pdo_lag1_z", "Lag-1 PDO", "postclosure climate", "negative",
  "mhw_indicator", "Marine heatwave window", "postclosure climate", "screen_only"
)

lag_specs <- tribble(
  ~lag_label, ~lag_n, ~screen_role,
  "future_1_negative_control", -1L, "negative_control",
  "lag_0", 0L, "same_year",
  "lag_1", 1L, "main_candidate",
  "lag_2", 2L, "delayed_candidate"
)

make_lagged_predictor <- function(tbl, pred_col, lag_n) {
  year_tbl <- tbl %>%
    distinct(year, .data[[pred_col]]) %>%
    arrange(year)

  if (lag_n < 0) {
    year_tbl <- year_tbl %>% mutate(predictor_value = lead(.data[[pred_col]], abs(lag_n)))
  } else if (lag_n > 0) {
    year_tbl <- year_tbl %>% mutate(predictor_value = lag(.data[[pred_col]], lag_n))
  } else {
    year_tbl <- year_tbl %>% mutate(predictor_value = .data[[pred_col]])
  }

  tbl %>%
    select(-any_of("predictor_value")) %>%
    left_join(year_tbl %>% select(year, predictor_value), by = "year")
}

score_annual <- function(pred_col, label, pathway, expected_sign, lag_label, lag_n, screen_role) {
  dat <- make_lagged_predictor(postclosure_growth, pred_col, lag_n) %>%
    filter(is.finite(predictor_value), is.finite(next_year_growth))

  fit_main <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor_value)),
    next_year_growth ~ predictor_z + annual_fishing_z + year_z + site_name,
    "predictor_z",
    min_n = 60L
  )

  fit_legacy_interaction <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor_value), moderator_z = historical_fishing_z),
    next_year_growth ~ predictor_z * moderator_z + annual_fishing_z + year_z + site_name,
    "predictor_z:moderator_z",
    min_n = 60L
  )

  bind_rows(
    tibble(
      test_id = paste0(pred_col, "_main"),
      pathway,
      mechanism = "postclosure_section_year_main_effect",
      label,
      predictor = pred_col,
      term = "predictor_z",
      expected_sign
    ) %>%
      bind_cols(fit_main),
    tibble(
      test_id = paste0(pred_col, "_x_historical_fishing"),
      pathway = paste0(pathway, " x legacy"),
      mechanism = "postclosure_pressure_x_historical_fishing",
      label = paste0(label, " x historical fishing"),
      predictor = pred_col,
      term = "predictor_z:moderator_z",
      expected_sign = if_else(expected_sign == "screen_only", "screen_only", "negative")
    ) %>%
      bind_cols(fit_legacy_interaction)
  ) %>%
    mutate(
      grain = "section_year_postclosure",
      lag_label,
      lag_n,
      screen_role,
      n = nrow(dat),
      n_sections = n_distinct(dat$site_name),
      n_years = n_distinct(dat$year),
      raw_rho = safe_cor(dat$next_year_growth, dat$predictor_value, "spearman", min_n = 20L),
      recent_2017_2024_rho = safe_cor(
        dat$next_year_growth[dat$year >= 2017],
        dat$predictor_value[dat$year >= 2017],
        "spearman",
        min_n = 20L
      ),
      median_extrapolated_exposure_share = NA_real_,
      source_data = "Data/processed/predators/hg_predation_pressure_covariates.csv"
    )
}

annual_screen <- crossing(annual_predictors, lag_specs) %>%
  pmap_dfr(function(predictor, label, pathway, expected_sign, lag_label, lag_n, screen_role) {
    score_annual(predictor, label, pathway, expected_sign, lag_label, lag_n, screen_role)
  })

exposure_raw <- read_csv(
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  show_col_types = FALSE
)

exposure_candidates <- exposure_raw %>%
  filter(
    year >= 2005,
    year <= 2024,
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
    predictor_value = exposure_z,
    predictor_id = paste0(
      "exposure_",
      str_replace_all(str_to_lower(predator_species_or_source), "[^a-z0-9]+", "_")
    ),
    label = paste0(predator_species_or_source, " exposure"),
    pathway = "postclosure predator exposure",
    source_data = source_file,
    extrapolated_exposure_share,
    observed_count_flag,
    interpolated_flag,
    extrapolated_dominant_flag
  )

combined_exposure <- exposure_raw %>%
  filter(
    year >= 2005,
    year <= 2024,
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
    extrapolated_dominant_flag = any(extrapolated_dominant_flag),
    source_data = paste(unique(source_file), collapse = "; "),
    .groups = "drop"
  ) %>%
  mutate(
    predictor_value = z(log1p(exposure)),
    predictor_id = "exposure_combined_mammal_working_defaults",
    label = "Combined mammal exposure",
    pathway = "postclosure predator exposure"
  ) %>%
  select(
    section_name,
    year,
    predictor_value,
    predictor_id,
    label,
    pathway,
    source_data,
    extrapolated_exposure_share,
    observed_count_flag,
    interpolated_flag,
    extrapolated_dominant_flag
  )

exposure_candidates <- bind_rows(exposure_candidates, combined_exposure)

score_exposure <- function(pred_id, label, pathway, lag_label, lag_n, screen_role) {
  dat <- exposure_candidates %>%
    filter(predictor_id == pred_id) %>%
    mutate(growth_year = year + lag_n) %>%
    inner_join(
      postclosure_growth,
      by = c("section_name", "growth_year" = "year")
    ) %>%
    filter(is.finite(predictor_value), is.finite(next_year_growth))

  fit_main <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor_value)),
    next_year_growth ~ predictor_z + pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z",
    min_n = 60L
  )

  fit_legacy_interaction <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor_value), moderator_z = historical_fishing_z),
    next_year_growth ~ predictor_z * moderator_z + pdo_lag1_z + annual_fishing_z + year_z + site_name,
    "predictor_z:moderator_z",
    min_n = 60L
  )

  bind_rows(
    tibble(
      test_id = paste0(pred_id, "_main"),
      pathway,
      mechanism = "postclosure_section_year_main_effect",
      label,
      predictor = pred_id,
      term = "predictor_z",
      expected_sign = "negative"
    ) %>%
      bind_cols(fit_main),
    tibble(
      test_id = paste0(pred_id, "_x_historical_fishing"),
      pathway = paste0(pathway, " x legacy"),
      mechanism = "postclosure_pressure_x_historical_fishing",
      label = paste0(label, " x historical fishing"),
      predictor = pred_id,
      term = "predictor_z:moderator_z",
      expected_sign = "negative"
    ) %>%
      bind_cols(fit_legacy_interaction)
  ) %>%
    mutate(
      grain = "section_year_postclosure",
      lag_label,
      lag_n,
      screen_role,
      n = nrow(dat),
      n_sections = n_distinct(dat$section_name),
      n_years = n_distinct(dat$growth_year),
      raw_rho = safe_cor(dat$next_year_growth, dat$predictor_value, "spearman", min_n = 20L),
      recent_2017_2024_rho = safe_cor(
        dat$next_year_growth[dat$growth_year >= 2017],
        dat$predictor_value[dat$growth_year >= 2017],
        "spearman",
        min_n = 20L
      ),
      median_extrapolated_exposure_share = median(dat$extrapolated_exposure_share, na.rm = TRUE),
      source_data = paste(unique(dat$source_data), collapse = "; ")
    )
}

exposure_screen <- crossing(
  exposure_candidates %>% distinct(predictor_id, label, pathway),
  lag_specs
) %>%
  pmap_dfr(function(predictor_id, label, pathway, lag_label, lag_n, screen_role) {
    score_exposure(predictor_id, label, pathway, lag_label, lag_n, screen_role)
  })

apply_section_year_gate <- function(tbl) {
  future_scores <- tbl %>%
    filter(lag_label == "future_1_negative_control") %>%
    transmute(test_id, future_abs_beta = abs(beta))

  tbl %>%
    left_join(future_scores, by = "test_id") %>%
    mutate(
      future_abs_beta = replace_na(future_abs_beta, Inf),
      abs_beta = abs(beta),
      expected_sign_ok = case_when(
        expected_sign == "negative" ~ is.finite(beta) & beta < 0,
        expected_sign == "positive" ~ is.finite(beta) & beta > 0,
        TRUE ~ is.finite(beta)
      ),
      raw_direction_ok = case_when(
        mechanism == "postclosure_section_year_main_effect" &
          expected_sign == "negative" ~
          is.finite(raw_rho) & raw_rho < 0 &
            (!is.finite(recent_2017_2024_rho) | recent_2017_2024_rho < 0),
        TRUE ~ TRUE
      ),
      exposure_data_ok = if_else(
        str_detect(predictor, "^exposure_"),
        is.na(median_extrapolated_exposure_share) | median_extrapolated_exposure_share < 0.6,
        TRUE
      ),
      beats_future_negative_control = abs_beta > future_abs_beta + 0.02,
      gate = case_when(
        lag_label != "lag_1" ~ screen_role,
        fit_note != "fit_ok" ~ paste0("fail_", fit_note),
        n < 60 ~ "fail_too_sparse",
        n_sections < 8 ~ "fail_too_few_sections",
        expected_sign == "screen_only" ~ "screen_only_no_directional_gate",
        !expected_sign_ok ~ "fail_expected_sign",
        !raw_direction_ok ~ "fail_raw_or_recent_direction",
        abs_beta < 0.05 ~ "fail_weak_effect_size",
        !beats_future_negative_control ~ "fail_future_negative_control",
        !exposure_data_ok ~ "fail_exposure_extrapolation",
        TRUE ~ "candidate_followup_only"
      )
    )
}

section_year_screen <- bind_rows(annual_screen, exposure_screen) %>%
  apply_section_year_gate() %>%
  arrange(desc(lag_label == "lag_1"), desc(gate == "candidate_followup_only"), desc(abs_beta))

timing_change <- read_csv(
  file.path(diag_dir, "spawn_timing_substrate_section_change.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    site,
    site_name = model_site_name,
    delta_spawn_start_doy,
    delta_subtidal_share,
    delta_substrate_effective_n
  ) %>%
  mutate(
    delta_spawn_start_doy_z = z(delta_spawn_start_doy),
    delta_subtidal_share_z = z(delta_subtidal_share),
    delta_substrate_effective_n_z = z(delta_substrate_effective_n)
  )

location_transition <- read_csv(
  file.path(diag_dir, "lead_section_location_transition_summary.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    site_name = section_name,
    raw_locations,
    historical_locations,
    recent_locations,
    lost_after_roe_locations,
    persisted_recent_locations,
    recent_to_roe_signal,
    location_loss_fraction = lost_after_roe_locations / pmax(historical_locations, 1),
    site_persistence_fraction = persisted_recent_locations / pmax(historical_locations, 1),
    top_lost_location,
    top_recent_location
  ) %>%
  mutate(
    location_loss_fraction_z = z(location_loss_fraction),
    recent_to_roe_signal_z = z(recent_to_roe_signal),
    site_persistence_fraction_z = z(site_persistence_fraction)
  )

recent_exposure_endpoint <- exposure_candidates %>%
  filter(year >= 2017) %>%
  group_by(section_name, label) %>%
  summarise(
    recent_exposure_z = median(predictor_value, na.rm = TRUE),
    recent_extrapolated_share = median(extrapolated_exposure_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(key = case_when(
    label == "Harbour seal exposure" ~ "harbour",
    label == "Steller sea lion filled total exposure" ~ "ssl_filled",
    label == "Combined mammal exposure" ~ "combined_mammal",
    TRUE ~ str_replace_all(str_to_lower(label), "[^a-z0-9]+", "_")
  )) %>%
  filter(key %in% c("harbour", "ssl_filled", "combined_mammal")) %>%
  select(section_name, key, recent_exposure_z, recent_extrapolated_share) %>%
  pivot_wider(
    names_from = key,
    values_from = c(recent_exposure_z, recent_extrapolated_share),
    names_glue = "{key}_{.value}"
  ) %>%
  rename(site_name = section_name)

section_endpoint <- fishing_endpoint %>%
  left_join(postclosure_recovery, by = "site") %>%
  left_join(timing_change, by = c("site", "site_name")) %>%
  left_join(location_transition, by = "site_name") %>%
  left_join(recent_exposure_endpoint, by = "site_name") %>%
  mutate(
    harbour_recent_exposure_z = z(harbour_recent_exposure_z),
    ssl_filled_recent_exposure_z = z(ssl_filled_recent_exposure_z),
    combined_mammal_recent_exposure_z = z(combined_mammal_recent_exposure_z)
  )

score_endpoint <- function(pred_col, label, pathway, expected_sign = "screen_only", min_n = 6L) {
  dat <- section_endpoint %>%
    mutate(predictor_value = .data[[pred_col]]) %>%
    filter(is.finite(log_recent_to_early), is.finite(predictor_value))

  fit <- fit_term_screen(
    dat %>% mutate(predictor_z = z(predictor_value)),
    log_recent_to_early ~ predictor_z,
    "predictor_z",
    min_n = min_n
  )

  tibble(
    test_id = paste0("endpoint_", pred_col),
    pathway,
    mechanism = "section_endpoint_recovery",
    label,
    predictor = pred_col,
    term = "predictor_z",
    expected_sign,
    grain = "section_endpoint",
    lag_label = "recent_vs_early",
    lag_n = NA_integer_,
    screen_role = "descriptive_endpoint",
    n = nrow(dat),
    n_sections = n_distinct(dat$site_name),
    n_years = NA_integer_,
    raw_rho = safe_cor(dat$log_recent_to_early, dat$predictor_value, "spearman", min_n = min_n),
    recent_2017_2024_rho = NA_real_,
    median_extrapolated_exposure_share = NA_real_,
    source_data = "Output/diagnostics/fishing_pressure_decomposition_by_section.csv; Output/diagnostics/spawn_timing_substrate_section_change.csv; Output/diagnostics/lead_section_location_transition_summary.csv; Output/diagnostics/predator_spatial_exposure_section_year.csv"
  ) %>%
    bind_cols(fit) %>%
    mutate(
      future_abs_beta = NA_real_,
      abs_beta = abs(beta),
      expected_sign_ok = TRUE,
      raw_direction_ok = TRUE,
      exposure_data_ok = TRUE,
      beats_future_negative_control = NA,
      gate = case_when(
        n < min_n ~ "descriptive_too_sparse",
        TRUE ~ "descriptive_endpoint"
      )
    )
}

endpoint_screen <- bind_rows(
  score_endpoint("historical_fishing_z", "Historical fishing pressure", "legacy fishing", "negative", min_n = 8L),
  score_endpoint("catch_per_early_biomass_z", "Catch per early biomass", "legacy fishing", "negative", min_n = 8L),
  score_endpoint("worse_than_fishing_z", "Worse-than-fishing residual depletion", "legacy plus unresolved local mechanism", "negative", min_n = 8L),
  score_endpoint("location_loss_fraction_z", "Raw-location loss fraction", "site persistence / recolonization", "negative", min_n = 3L),
  score_endpoint("recent_to_roe_signal_z", "Recent-to-roe raw-location signal", "site persistence / recolonization", "positive", min_n = 3L),
  score_endpoint("harbour_recent_exposure_z", "Recent harbour seal exposure", "predator endpoint context", "negative", min_n = 8L),
  score_endpoint("ssl_filled_recent_exposure_z", "Recent Steller sea lion exposure", "predator endpoint context", "negative", min_n = 8L),
  score_endpoint("combined_mammal_recent_exposure_z", "Recent combined mammal exposure", "predator endpoint context", "negative", min_n = 8L),
  score_endpoint("delta_spawn_start_doy_z", "Recent minus early spawn timing", "timing/substrate", "screen_only", min_n = 5L),
  score_endpoint("delta_subtidal_share_z", "Recent minus early subtidal share", "timing/substrate", "screen_only", min_n = 5L),
  score_endpoint("delta_substrate_effective_n_z", "Recent minus early substrate diversity", "timing/substrate", "screen_only", min_n = 5L),
  score_endpoint("survey_coverage", "Survey coverage", "evidence-quality caveat", "screen_only", min_n = 8L),
  score_endpoint("spawn_fit_rmse", "Positive-spawn fit RMSE", "evidence-quality caveat", "screen_only", min_n = 8L)
)

screen_all <- bind_rows(section_year_screen, endpoint_screen) %>%
  arrange(
    grain,
    desc(lag_label == "lag_1"),
    desc(gate == "candidate_followup_only"),
    desc(abs_beta)
  )

write_csv(screen_all, file.path(diag_dir, "postclosure_recovery_mechanism_screen.csv"))

section_scorecard <- section_endpoint %>%
  transmute(
    site,
    section = site_name,
    focal_status,
    recent_to_early_ratio,
    log_recent_to_early,
    recent_trend_pct_per_year,
    rebound_from_postclosure_min,
    recovery_class = postclosure_recovery_class,
    mean_fishing_fraction_1951_2004,
    fishing_only_resid,
    survey_coverage,
    spawn_fit_rmse,
    location_loss_fraction,
    recent_to_roe_signal,
    top_lost_location,
    top_recent_location,
    harbour_recent_exposure_z,
    ssl_filled_recent_exposure_z,
    combined_mammal_recent_exposure_z,
    delta_spawn_start_doy,
    delta_subtidal_share,
    delta_substrate_effective_n,
    primary_followup = case_when(
      recent_to_early_ratio < 0.2 & mean_fishing_fraction_1951_2004 >= median(mean_fishing_fraction_1951_2004, na.rm = TRUE) ~ "legacy fishing plus portfolio erosion",
      recent_to_early_ratio < 0.2 & !is.na(location_loss_fraction) & location_loss_fraction >= 0.5 ~ "site persistence / recolonization audit",
      recent_to_early_ratio < 0.2 ~ "persistent depletion beyond current covariates",
      recent_trend_pct_per_year < 0 ~ "recent decline audit",
      TRUE ~ "recovery contrast / lower priority"
    )
  ) %>%
  arrange(recent_to_early_ratio)

write_csv(section_scorecard, file.path(diag_dir, "postclosure_recovery_section_scorecard.csv"))

lag1_rows <- section_year_screen %>%
  filter(lag_label == "lag_1")

candidate_rows <- lag1_rows %>%
  filter(gate == "candidate_followup_only")

best_lag1 <- lag1_rows %>%
  filter(is.finite(abs_beta)) %>%
  arrange(desc(abs_beta)) %>%
  slice_head(n = 10)

endpoint_top <- endpoint_screen %>%
  filter(is.finite(abs_beta)) %>%
  arrange(desc(abs_beta)) %>%
  slice_head(n = 12)

candidate_lines <- if (nrow(candidate_rows) == 0) {
  "- No post-closure section-year row clears the strict candidate gate."
} else {
  candidate_rows %>%
    transmute(line = paste0(
      "- Candidate: `", label, "` via `", mechanism, "` beta `",
      number(beta, accuracy = 0.01),
      "`, gate `", gate, "`."
    )) %>%
    pull(line)
}

best_endpoint_line <- endpoint_top %>%
  slice(1) %>%
  transmute(line = paste0(
    "- Strongest endpoint association: `", label, "` beta `",
    number(beta, accuracy = 0.01),
    "`, rho `",
    number(raw_rho, accuracy = 0.01),
    "`, n `", n, "`."
  )) %>%
  pull(line)

scorecard_md <- section_scorecard %>%
  transmute(
    section,
    `recent/early` = number(recent_to_early_ratio, accuracy = 0.01),
    `recent trend` = paste0(number(recent_trend_pct_per_year, accuracy = 0.1), "%/yr"),
    `hist fishing` = percent(mean_fishing_fraction_1951_2004, accuracy = 0.1),
    `fish resid` = number(fishing_only_resid, accuracy = 0.01),
    `site loss` = if_else(is.na(location_loss_fraction), "NA", percent(location_loss_fraction, accuracy = 1)),
    `SSL exp z` = number(ssl_filled_recent_exposure_z, accuracy = 0.01),
    `follow-up` = primary_followup
  )

screen_md <- best_lag1 %>%
  transmute(
    pathway,
    mechanism,
    label,
    n,
    sections = n_sections,
    beta = number(beta, accuracy = 0.01),
    p = number(p, accuracy = 0.01),
    rho = number(raw_rho, accuracy = 0.01),
    `recent rho` = number(recent_2017_2024_rho, accuracy = 0.01),
    gate
  )

endpoint_md <- endpoint_top %>%
  transmute(
    pathway,
    label,
    n,
    beta = number(beta, accuracy = 0.01),
    rho = number(raw_rho, accuracy = 0.01),
    gate
  )

p_endpoint <- endpoint_screen %>%
  filter(is.finite(beta), !pathway %in% c("evidence-quality caveat")) %>%
  mutate(label = fct_reorder(str_wrap(label, 28), beta)) %>%
  ggplot(aes(x = beta, y = label, fill = pathway)) +
  geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey45") +
  geom_col(width = 0.72) +
  labs(
    x = "Scaled endpoint slope vs log(recent / early biomass)",
    y = NULL,
    fill = NULL,
    title = "Endpoint mechanisms after two decades of closure",
    subtitle = "Historical fishing and local persistence are endpoint screens, not causal identification."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_lag1 <- lag1_rows %>%
  filter(is.finite(beta), mechanism != "postclosure_pressure_x_historical_fishing") %>%
  mutate(
    label = fct_reorder(str_wrap(label, 28), beta),
    gate_group = case_when(
      gate == "candidate_followup_only" ~ "candidate",
      str_detect(gate, "screen_only") ~ "screen only",
      TRUE ~ "failed gate"
    )
  ) %>%
  ggplot(aes(x = beta, y = label, fill = gate_group)) +
  geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey45") +
  geom_col(width = 0.72) +
  labs(
    x = "Lag-1 post-closure coefficient",
    y = NULL,
    fill = NULL,
    title = "Post-closure growth screens do not clear model gates",
    subtitle = "Gates require expected sign, raw/recent direction, and future-lag control checks."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_score <- section_scorecard %>%
  mutate(section = fct_reorder(section, recent_to_early_ratio)) %>%
  ggplot(aes(x = recent_to_early_ratio, y = section, colour = primary_followup)) +
  geom_vline(xintercept = 0.2, linetype = "dashed", linewidth = 0.3, colour = "grey45") +
  geom_point(size = 2.2) +
  scale_x_log10(labels = label_number(accuracy = 0.01)) +
  labs(
    x = "Recent / early biomass, log scale",
    y = NULL,
    colour = NULL,
    title = "Recovery remains section-specific",
    subtitle = "Low ratios flag sections where closure alone has not restored the old state."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- (p_endpoint | p_lag1) / p_score +
  plot_layout(heights = c(1, 0.95)) +
  plot_annotation(
    title = "Post-closure recovery mechanism screen",
    subtitle = "Closure removed fishing, but legacy depletion and local persistence remain the clearest testable pathways."
  )

ggsave(
  file.path(fig_dir, "postclosure_recovery_mechanism_screen.pdf"),
  p,
  width = 270,
  height = 210,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "postclosure_recovery_mechanism_screen.png"),
  p,
  width = 270,
  height = 210,
  units = "mm",
  dpi = 300
)

lines <- c(
  "# Post-Closure Recovery Mechanism Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  "- This diagnostic asks why sections may not recover after the post-2005 fishery closure. It is not a new Stan model.",
  "- Closure removed direct fishing mortality, but the screen separates legacy depletion, site persistence/recolonization, post-closure predator/climate pressure, timing/substrate shifts, and evidence-quality caveats.",
  candidate_lines,
  best_endpoint_line,
  "- Site-persistence evidence is currently available only for the lead raw-location sections, so it is a local audit pathway rather than a fitted all-section covariate.",
  "- Predator rows remain data-product targets because exposure extrapolation, raw/recent direction, and section-level humpback exposure are unresolved.",
  "",
  "## Strongest Post-Closure Section-Year Rows",
  "",
  knitr::kable(screen_md, format = "pipe"),
  "",
  "## Endpoint Context",
  "",
  knitr::kable(endpoint_md, format = "pipe"),
  "",
  "## Section Scorecard",
  "",
  knitr::kable(scorecard_md, format = "pipe"),
  "",
  "## Decision",
  "",
  "- For the talk, frame no-fishing as necessary but not sufficient: closure did not automatically restore local spawning structure, recruitment, or the modern predator/climate regime.",
  "- The next model should not be a combined predator model. The next data work should target section-level humpback exposure, effort/access-aware local persistence, and age/recruitment context.",
  "- If a Stan branch is needed later, use this screen to choose one pathway at a time after a row clears the strict post-closure gate.",
  "",
  "## Source Files",
  "",
  "- `Output/diagnostics/m1_stier_11_section_biomass_by_year.csv`",
  "- `Output/diagnostics/m1_stier_11_section_year_fishing_pressure.csv`",
  "- `Output/diagnostics/fishing_pressure_decomposition_by_section.csv`",
  "- `Output/diagnostics/m1_stier_11_postclosure_recovery_by_section.csv`",
  "- `Output/diagnostics/predator_spatial_exposure_section_year.csv`",
  "- `Output/diagnostics/spawn_timing_substrate_section_change.csv`",
  "- `Output/diagnostics/lead_section_location_transition_summary.csv`",
  "- `Data/processed/predators/hg_predation_pressure_covariates.csv`",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/postclosure_recovery_mechanism_screen.csv`",
  "- `Output/diagnostics/postclosure_recovery_section_scorecard.csv`",
  "- `Output/figures/postclosure_recovery_mechanism_screen.pdf`"
)

writeLines(lines, file.path(diag_dir, "postclosure_recovery_mechanism_screen.md"))

cat("Saved post-closure recovery mechanism screen:\n")
cat("  Output/diagnostics/postclosure_recovery_mechanism_screen.md\n")
cat("  Output/diagnostics/postclosure_recovery_mechanism_screen.csv\n")
cat("  Output/diagnostics/postclosure_recovery_section_scorecard.csv\n")
cat("  Output/figures/postclosure_recovery_mechanism_screen.pdf\n")
