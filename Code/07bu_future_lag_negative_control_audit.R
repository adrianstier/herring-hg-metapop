# ============================================================================
# 07bu_future_lag_negative_control_audit.R
# Audit future-lag negative controls and age-3 recruitment-return lags.
#
# This is a diagnostic screen, not a Stan model. It asks whether predator /
# climate rows that fail future-lag controls might still have a biologically
# plausible delayed signal for herring that return to spawn around age 3.
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
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  file.path(diag_dir, "dfo_hg_public_extract", "dfo_hg_appendix_b8_spawn.csv"),
  file.path(diag_dir, "dfo_hg_public_extract", "dfo_hg_appendix_b15_number_at_age_long.csv"),
  file.path(diag_dir, "dfo_newer_public_pdf_extract", "dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv"),
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

safe_cor <- function(x, y, method = "spearman", min_n = 8L) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < min_n || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

max_abs_or_na <- function(x) {
  x <- abs(x[is.finite(x)])
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(x)
}

best_lag_or_na <- function(lag, score) {
  ok <- is.finite(lag) & is.finite(score)
  if (sum(ok) == 0L) {
    return(NA_integer_)
  }
  lag[ok][which.max(abs(score[ok]))][1]
}

coef_or_na <- function(fit, term, column) {
  coefs <- coef(summary(fit))
  if (!term %in% rownames(coefs) || !column %in% colnames(coefs)) {
    return(NA_real_)
  }
  unname(coefs[term, column])
}

fit_term_screen <- function(dat, formula, term, min_n = 60L) {
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

lag_role <- function(lag_years) {
  case_when(
    lag_years <= 0 ~ "future_or_same_return_year_control",
    lag_years == 1 ~ "adult_immediate_growth_interval",
    lag_years == 2 ~ "delayed_adult_or_age2_sensitivity",
    lag_years == 3 ~ "age3_recruitment_return_candidate",
    lag_years == 4 ~ "age4_return_sensitivity",
    TRUE ~ "age5plus_return_sensitivity"
  )
}

section_growth <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  arrange(site_name, year) %>%
  group_by(site, site_name) %>%
  mutate(
    growth_into_year = log(median / lag(median)),
    previous_year = year - 1L
  ) %>%
  ungroup() %>%
  transmute(
    site,
    site_name,
    section_name = site_name,
    focal_status,
    response_year = year,
    previous_year,
    response_value = growth_into_year,
    response = "log_biomass_growth_into_year"
  ) %>%
  filter(is.finite(response_value), response_year >= 2006, response_year <= 2025)

section_fishing <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_year_fishing_pressure.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    site,
    site_name,
    response_year = year,
    annual_fishing_fraction = fishing_fraction_median
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
    pdo_z = z(pdo),
    mhw_indicator = as.integer(year >= 2014 & year <= 2016)
  ) %>%
  select(
    predictor_year = year,
    demand_total_z,
    demand_fish_z,
    demand_mammals_z,
    demand_salmon_z,
    demand_birds_z,
    pressure_ratio_z,
    pdo_z,
    mhw_indicator
  )

annual_predictors <- tribble(
  ~predictor, ~label, ~pathway, ~expected_sign, ~source_data,
  "demand_total_z", "Total predator demand", "annual predator demand", "negative", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "demand_fish_z", "Fish predator demand", "annual predator demand", "negative", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "demand_mammals_z", "Marine mammal demand", "annual predator demand", "negative", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "demand_salmon_z", "Salmon predator demand", "juvenile/recruitment context", "negative", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "demand_birds_z", "Bird/egg predator demand", "egg/recruitment context", "negative", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "pressure_ratio_z", "Predator pressure ratio", "descriptive pressure ratio", "negative", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "pdo_z", "PDO", "climate context", "screen_only", "Data/processed/predators/hg_predation_pressure_covariates.csv",
  "mhw_indicator", "Marine heatwave window", "climate context", "screen_only", "Data/processed/predators/hg_predation_pressure_covariates.csv"
)

lag_years <- -2:5
lag_tbl <- tibble(lag_years) %>%
  mutate(lag_role = lag_role(lag_years))

base_response <- section_growth %>%
  left_join(section_fishing, by = c("site", "site_name", "response_year")) %>%
  mutate(
    annual_fishing_fraction = replace_na(annual_fishing_fraction, 0)
  )

screen_fit <- function(dat, expected_sign, predictor_is_pdo = FALSE, min_n = 60L) {
  dat <- dat %>%
    mutate(
      predictor_z = z(predictor_value),
      response_year_z = z(response_year),
      annual_fishing_z = z(annual_fishing_fraction),
      annual_fishing_z = replace_na(annual_fishing_z, 0),
      pdo_control_z = z(pdo_z)
    )

  fit_main <- if (predictor_is_pdo) {
    fit_term_screen(
      dat,
      response_value ~ predictor_z + annual_fishing_z + response_year_z + site_name,
      "predictor_z",
      min_n = min_n
    )
  } else {
    fit_term_screen(
      dat,
      response_value ~ predictor_z + pdo_control_z + annual_fishing_z + response_year_z + site_name,
      "predictor_z",
      min_n = min_n
    )
  }

  demeaned <- dat %>%
    group_by(site_name) %>%
    mutate(
      response_dm = response_value - mean(response_value, na.rm = TRUE),
      predictor_dm = predictor_value - mean(predictor_value, na.rm = TRUE)
    ) %>%
    ungroup()

  recent <- dat %>%
    filter(response_year >= 2017)

  fit_recent <- if (predictor_is_pdo) {
    fit_term_screen(
      recent,
      response_value ~ predictor_z + annual_fishing_z + response_year_z + site_name,
      "predictor_z",
      min_n = 30L
    )
  } else {
    fit_term_screen(
      recent,
      response_value ~ predictor_z + pdo_control_z + annual_fishing_z + response_year_z + site_name,
      "predictor_z",
      min_n = 30L
    )
  }

  fit_main %>%
    mutate(
      raw_rho = safe_cor(dat$response_value, dat$predictor_value, "spearman", min_n = 20L),
      within_section_rho = safe_cor(
        demeaned$response_dm,
        demeaned$predictor_dm,
        "spearman",
        min_n = 20L
      ),
      recent_2017_2025_rho = safe_cor(
        recent$response_value,
        recent$predictor_value,
        "spearman",
        min_n = 20L
      ),
      recent_beta = fit_recent$beta,
      recent_p = fit_recent$p,
      recent_fit_note = fit_recent$fit_note,
      n = nrow(dat),
      n_sections = n_distinct(dat$site_name),
      n_years = n_distinct(dat$response_year)
    )
}

score_annual <- function(predictor, label, pathway, expected_sign, source_data, lag_years, lag_role) {
  dat <- base_response %>%
    mutate(
      predictor_year = response_year - lag_years,
      lag_years = lag_years,
      lag_role = lag_role
    ) %>%
    left_join(pred_cov, by = "predictor_year") %>%
    mutate(
      predictor_value = .data[[predictor]],
      predictor_is_pdo = predictor == "pdo_z"
    ) %>%
    filter(
      predictor_year >= 2005,
      predictor_year <= 2024,
      is.finite(response_value),
      is.finite(predictor_value)
    )

  screen_fit(dat, expected_sign, predictor_is_pdo = predictor == "pdo_z") %>%
    mutate(
      test_id = paste0("annual_", predictor),
      pathway,
      label,
      predictor,
      expected_sign,
      grain = "annual_predictor",
      lag_years,
      lag_role,
      median_extrapolated_exposure_share = NA_real_,
      source_data
    )
}

exposure_raw <- read_csv(
  file.path(diag_dir, "predator_spatial_exposure_section_year.csv"),
  show_col_types = FALSE
)

exposure_candidates <- exposure_raw %>%
  filter(
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
    predictor_year = year,
    predictor_value = exposure_z,
    predictor = paste0(
      "exposure_",
      str_replace_all(str_to_lower(predator_species_or_source), "[^a-z0-9]+", "_")
    ),
    label = paste0(predator_species_or_source, " exposure"),
    pathway = "section-year predator exposure",
    source_data = source_file,
    extrapolated_exposure_share,
    observed_count_flag,
    interpolated_flag,
    extrapolated_dominant_flag
  )

combined_exposure <- exposure_raw %>%
  filter(
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
    predictor_year = year,
    predictor_value = z(log1p(exposure)),
    predictor = "exposure_combined_mammal_working_defaults",
    label = "Combined mammal exposure",
    pathway = "section-year predator exposure"
  ) %>%
  select(
    section_name,
    predictor_year,
    predictor_value,
    predictor,
    label,
    pathway,
    source_data,
    extrapolated_exposure_share,
    observed_count_flag,
    interpolated_flag,
    extrapolated_dominant_flag
  )

exposure_candidates <- bind_rows(exposure_candidates, combined_exposure)

score_exposure <- function(predictor, label, pathway, lag_years, lag_role) {
  dat <- base_response %>%
    mutate(
      predictor_year = response_year - lag_years,
      lag_years = lag_years,
      lag_role = lag_role
    ) %>%
    inner_join(
      exposure_candidates %>% filter(predictor == !!predictor),
      by = c("section_name", "predictor_year")
    ) %>%
    left_join(pred_cov %>% select(predictor_year, pdo_z), by = "predictor_year") %>%
    filter(
      predictor_year >= 2005,
      predictor_year <= 2024,
      is.finite(response_value),
      is.finite(predictor_value)
    )

  screen_fit(dat, expected_sign = "negative", predictor_is_pdo = FALSE) %>%
    mutate(
      test_id = paste0("exposure_", predictor),
      pathway,
      label,
      predictor,
      expected_sign = "negative",
      grain = "section_year_exposure",
      lag_years,
      lag_role,
      median_extrapolated_exposure_share = median(dat$extrapolated_exposure_share, na.rm = TRUE),
      source_data = paste(unique(dat$source_data), collapse = "; ")
    )
}

annual_screen <- crossing(annual_predictors, lag_tbl) %>%
  pmap_dfr(function(predictor, label, pathway, expected_sign, source_data, lag_years, lag_role) {
    score_annual(predictor, label, pathway, expected_sign, source_data, lag_years, lag_role)
  })

exposure_screen <- crossing(
  exposure_candidates %>% distinct(predictor, label, pathway),
  lag_tbl
) %>%
  pmap_dfr(function(predictor, label, pathway, lag_years, lag_role) {
    score_exposure(predictor, label, pathway, lag_years, lag_role)
  })

apply_lag_gate <- function(tbl) {
  future_controls <- tbl %>%
    filter(lag_years <= 0) %>%
    group_by(test_id) %>%
    summarise(
      future_abs_beta_max = max_abs_or_na(beta),
      future_best_lag = best_lag_or_na(lag_years, beta),
      .groups = "drop"
    )

  tbl %>%
    left_join(future_controls, by = "test_id") %>%
    mutate(
      abs_beta = abs(beta),
      expected_sign_ok = case_when(
        expected_sign == "negative" ~ is.finite(beta) & beta < 0,
        expected_sign == "positive" ~ is.finite(beta) & beta > 0,
        TRUE ~ is.finite(beta)
      ),
      raw_direction_ok = case_when(
        expected_sign == "negative" ~
          is.finite(raw_rho) & raw_rho < 0 &
            (!is.finite(recent_2017_2025_rho) | recent_2017_2025_rho < 0),
        TRUE ~ TRUE
      ),
      within_direction_ok = case_when(
        expected_sign == "negative" ~ is.finite(within_section_rho) & within_section_rho < 0,
        TRUE ~ TRUE
      ),
      exposure_data_ok = if_else(
        grain == "section_year_exposure",
        is.na(median_extrapolated_exposure_share) | median_extrapolated_exposure_share < 0.6,
        TRUE
      ),
      beats_future_negative_control = is.finite(abs_beta) &
        is.finite(future_abs_beta_max) &
        abs_beta > future_abs_beta_max + 0.02,
      gate = case_when(
        lag_years <= 0 ~ "negative_control",
        fit_note != "fit_ok" ~ paste0("fail_", fit_note),
        n < 60 ~ "fail_too_sparse",
        n_sections < 8 ~ "fail_too_few_sections",
        expected_sign == "screen_only" ~ "screen_only_no_directional_gate",
        !expected_sign_ok ~ "fail_expected_sign",
        !raw_direction_ok ~ "fail_raw_or_recent_direction",
        !within_direction_ok ~ "fail_within_section_direction",
        abs_beta < 0.05 ~ "fail_weak_effect_size",
        !beats_future_negative_control ~ "fail_future_negative_control",
        !exposure_data_ok ~ "fail_exposure_extrapolation",
        lag_years == 1 ~ "adult_lag_followup_only",
        lag_years == 3 ~ "age3_lag_followup_only",
        TRUE ~ "delayed_sensitivity_followup_only"
      )
    )
}

lag_screen <- bind_rows(annual_screen, exposure_screen) %>%
  apply_lag_gate() %>%
  arrange(test_id, lag_years)

write_csv(lag_screen, file.path(diag_dir, "future_lag_negative_control_audit.csv"))

lag_summary <- lag_screen %>%
  group_by(test_id, label, pathway, predictor, grain, expected_sign) %>%
  summarise(
    n_lags = n(),
    adult_lag1_beta = beta[lag_years == 1][1],
    adult_lag1_gate = gate[lag_years == 1][1],
    age3_lag_beta = beta[lag_years == 3][1],
    age3_lag_p = p[lag_years == 3][1],
    age3_lag_rho = raw_rho[lag_years == 3][1],
    age3_lag_within_rho = within_section_rho[lag_years == 3][1],
    age3_lag_recent_rho = recent_2017_2025_rho[lag_years == 3][1],
    age3_lag_gate = gate[lag_years == 3][1],
    future_abs_beta_max = max_abs_or_na(future_abs_beta_max),
    future_best_lag = best_lag_or_na(lag_years[lag_years <= 0], beta[lag_years <= 0]),
    best_abs_beta = max_abs_or_na(beta),
    best_lag = best_lag_or_na(lag_years, beta),
    best_lag_gate = gate[which.max(replace_na(abs_beta, -Inf))][1],
    median_extrapolated_exposure_share = median(median_extrapolated_exposure_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    future_abs_beta_max = if_else(is.infinite(future_abs_beta_max), NA_real_, future_abs_beta_max),
    median_extrapolated_exposure_share = if_else(
      is.infinite(median_extrapolated_exposure_share),
      NA_real_,
      median_extrapolated_exposure_share
    ),
    timing_read = case_when(
      age3_lag_gate == "age3_lag_followup_only" ~ "age3 lag clears diagnostic gate",
      adult_lag1_gate == "adult_lag_followup_only" ~ "adult lag clears diagnostic gate",
      best_lag <= 0 ~ "best lag is future/same-return-year control",
      str_detect(coalesce(age3_lag_gate, ""), "future_negative_control") ~ "age3 lag fails future-control test",
      str_detect(coalesce(age3_lag_gate, ""), "weak_effect") ~ "age3 lag has weak effect size",
      str_detect(coalesce(age3_lag_gate, ""), "expected_sign|direction") ~ "age3 lag has wrong or unstable direction",
      TRUE ~ "screen only or data-limited"
    )
  ) %>%
  arrange(desc(age3_lag_gate == "age3_lag_followup_only"), desc(abs(age3_lag_beta)))

write_csv(lag_summary, file.path(diag_dir, "future_lag_negative_control_summary.csv"))

age3_screen <- lag_screen %>%
  filter(lag_years == 3) %>%
  arrange(desc(gate == "age3_lag_followup_only"), desc(abs_beta))

write_csv(age3_screen, file.path(diag_dir, "age3_recruitment_lag_screen.csv"))

public_spawn <- read_csv(
  file.path(diag_dir, "dfo_hg_public_extract", "dfo_hg_appendix_b8_spawn.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    brood_year = year,
    brood_spawn_index_tonnes = spawn_index_tonnes,
    brood_spawn_index_kt = spawn_index_kt
  )

public_age_comp <- read_csv(
  file.path(diag_dir, "dfo_hg_public_extract", "dfo_hg_appendix_b15_number_at_age_long.csv"),
  show_col_types = FALSE
) %>%
  group_by(return_year = year) %>%
  summarise(
    public_age_sample_n = sum(n_at_age, na.rm = TRUE),
    age2_n = sum(n_at_age[age == 2], na.rm = TRUE),
    age3_n = sum(n_at_age[age == 3], na.rm = TRUE),
    young_2_3_n = sum(n_at_age[age %in% c(2, 3)], na.rm = TRUE),
    age3_prop = age3_n / pmax(public_age_sample_n, 1),
    young_2_3_prop = young_2_3_n / pmax(public_age_sample_n, 1),
    mean_age_public = sum(age * n_at_age, na.rm = TRUE) / pmax(public_age_sample_n, 1),
    .groups = "drop"
  )

recent_sca_recruitment <- read_csv(
  file.path(diag_dir, "dfo_newer_public_pdf_extract", "dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    return_year = year,
    public_age_sample_n = NA_real_,
    age2_n = recruitment_millions_median,
    age3_n = NA_real_,
    young_2_3_n = NA_real_,
    age3_prop = NA_real_,
    young_2_3_prop = NA_real_,
    mean_age_public = NA_real_,
    sca_age2_recruitment_millions = recruitment_millions_median
  )

age_responses <- tribble(
  ~response_col, ~response_label, ~response_transform, ~response_expected_sign, ~min_n,
  "age3_prop", "Public Appendix B age-3 proportion", "direct", "negative", 20L,
  "young_2_3_prop", "Public Appendix B age-2/3 proportion", "direct", "negative", 20L,
  "age3_per_spawn_proxy", "Public age-3 per brood-year spawn proxy", "spawn_normalized_age3", "negative", 20L,
  "sca_age2_recruitment_millions", "DFO 2025 age-2 recruitment", "log1p", "negative", 8L
)

score_public_age <- function(predictor, label, pathway, expected_sign, source_data,
                             response_col, response_label, response_transform,
                             response_expected_sign, min_n) {
  response_tbl <- if (response_col == "sca_age2_recruitment_millions") {
    recent_sca_recruitment
  } else {
    public_age_comp %>%
      mutate(sca_age2_recruitment_millions = NA_real_)
  }

  dat <- crossing(
    response_tbl,
    tibble(lag_years = 2:4)
  ) %>%
    mutate(
      brood_year = return_year - lag_years,
      predictor_year = brood_year,
      lag_role = case_when(
        lag_years == 2 ~ "age2_recruitment_return_candidate",
        lag_years == 3 ~ "age3_recruitment_return_candidate",
        TRUE ~ "age4_return_sensitivity"
      )
    ) %>%
    left_join(pred_cov, by = "predictor_year") %>%
    left_join(public_spawn, by = "brood_year") %>%
    mutate(
      predictor_value = .data[[predictor]]
    )

  if (response_transform == "spawn_normalized_age3") {
    dat <- dat %>%
      mutate(response_value = log1p(age3_n) - log1p(brood_spawn_index_tonnes))
  } else if (response_transform == "log1p") {
    dat <- dat %>%
      mutate(response_value = log1p(.data[[response_col]]))
  } else {
    dat <- dat %>%
      mutate(response_value = .data[[response_col]])
  }

  dat <- dat %>%
    filter(
      is.finite(response_value),
      is.finite(predictor_value),
      is.finite(return_year),
      is.finite(brood_year)
    )

  map_dfr(sort(unique(dat$lag_years)), function(lag_i) {
    lag_dat <- dat %>%
      filter(lag_years == lag_i) %>%
      mutate(
        predictor_z = z(predictor_value),
        return_year_z = z(return_year),
        pdo_control_z = z(pdo_z)
      )

    predictor_is_pdo <- predictor == "pdo_z"
    fit <- if (predictor_is_pdo) {
      fit_term_screen(
        lag_dat,
        response_value ~ predictor_z + return_year_z,
        "predictor_z",
        min_n = min_n
      )
    } else {
      fit_term_screen(
        lag_dat,
        response_value ~ predictor_z + pdo_control_z + return_year_z,
        "predictor_z",
        min_n = min_n
      )
    }

    fit %>%
      mutate(
        test_id = paste0("public_age_", response_col, "_", predictor),
        pathway = paste0(pathway, " -> public age/recruitment proxy"),
        label = paste0(response_label, " vs ", label),
        predictor,
        response_col,
        response_label,
        expected_sign = if_else(expected_sign == "screen_only", "screen_only", response_expected_sign),
        grain = if_else(
          response_col == "sca_age2_recruitment_millions",
          "public_sca_age2_recruitment",
          "public_appendix_b_age_composition"
        ),
        lag_years = lag_i,
        lag_role = unique(lag_dat$lag_role)[1],
        n = nrow(lag_dat),
        n_years = n_distinct(lag_dat$return_year),
        raw_rho = safe_cor(lag_dat$response_value, lag_dat$predictor_value, "spearman", min_n = min_n),
        source_data = paste(
          source_data,
          "Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b15_number_at_age_long.csv",
          "Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b8_spawn.csv",
          "Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv",
          sep = "; "
        )
      )
  })
}

public_age_screen <- crossing(
  annual_predictors %>%
    filter(predictor %in% c(
      "demand_total_z",
      "demand_fish_z",
      "demand_mammals_z",
      "demand_salmon_z",
      "demand_birds_z",
      "pressure_ratio_z",
      "pdo_z",
      "mhw_indicator"
    )),
  age_responses
) %>%
  pmap_dfr(function(predictor, label, pathway, expected_sign, source_data,
                    response_col, response_label, response_transform,
                    response_expected_sign, min_n) {
    score_public_age(
      predictor,
      label,
      pathway,
      expected_sign,
      source_data,
      response_col,
      response_label,
      response_transform,
      response_expected_sign,
      min_n
    )
  }) %>%
  mutate(
    abs_beta = abs(beta),
    expected_sign_ok = case_when(
      expected_sign == "negative" ~ is.finite(beta) & beta < 0,
      expected_sign == "positive" ~ is.finite(beta) & beta > 0,
      TRUE ~ is.finite(beta)
    ),
    raw_direction_ok = case_when(
      expected_sign == "negative" ~ is.finite(raw_rho) & raw_rho < 0,
      expected_sign == "positive" ~ is.finite(raw_rho) & raw_rho > 0,
      TRUE ~ TRUE
    ),
    gate = case_when(
      fit_note != "fit_ok" ~ paste0("fail_", fit_note),
      expected_sign == "screen_only" ~ "screen_only_no_directional_gate",
      !expected_sign_ok ~ "fail_expected_sign",
      !raw_direction_ok ~ "fail_raw_direction",
      abs_beta < 0.05 ~ "fail_weak_effect_size",
      p > 0.20 ~ "fail_uncertain_public_proxy",
      lag_years == 3 & str_detect(grain, "appendix_b") ~ "age3_public_proxy_audit_target",
      lag_years == 2 & str_detect(grain, "sca_age2") ~ "short_sca_age2_audit_target",
      TRUE ~ "delayed_public_proxy_audit_target"
    )
  ) %>%
  arrange(desc(gate %in% c(
    "age3_public_proxy_audit_target",
    "short_sca_age2_audit_target"
  )), desc(abs_beta))

write_csv(public_age_screen, file.path(diag_dir, "public_age_recruitment_lag_proxy_screen.csv"))

candidate_age3 <- age3_screen %>%
  filter(gate == "age3_lag_followup_only")

candidate_adult <- lag_screen %>%
  filter(lag_years == 1, gate == "adult_lag_followup_only")

best_age3 <- age3_screen %>%
  filter(is.finite(abs_beta)) %>%
  arrange(desc(abs_beta)) %>%
  slice(1)

future_failure_rows <- lag_screen %>%
  filter(str_detect(gate, "future_negative_control")) %>%
  arrange(desc(abs_beta)) %>%
  slice_head(n = 10)

summary_md <- lag_summary %>%
  transmute(
    pathway,
    label,
    adult_beta = number(adult_lag1_beta, accuracy = 0.01),
    adult_gate = adult_lag1_gate,
    age3_beta = number(age3_lag_beta, accuracy = 0.01),
    age3_rho = number(age3_lag_rho, accuracy = 0.01),
    age3_gate = age3_lag_gate,
    future_max = number(future_abs_beta_max, accuracy = 0.01),
    best_lag,
    timing_read
  )

age3_md <- age3_screen %>%
  transmute(
    pathway,
    label,
    n,
    years = n_years,
    beta = number(beta, accuracy = 0.01),
    p = number(p, accuracy = 0.01),
    rho = number(raw_rho, accuracy = 0.01),
    within_rho = number(within_section_rho, accuracy = 0.01),
    recent_rho = number(recent_2017_2025_rho, accuracy = 0.01),
    future_max = number(future_abs_beta_max, accuracy = 0.01),
    gate
  )

future_md <- future_failure_rows %>%
  transmute(
    pathway,
    label,
    lag_years,
    lag_role,
    beta = number(beta, accuracy = 0.01),
    future_max = number(future_abs_beta_max, accuracy = 0.01),
    rho = number(raw_rho, accuracy = 0.01),
    gate
  )

public_age_top <- public_age_screen %>%
  filter(is.finite(abs_beta)) %>%
  arrange(desc(gate %in% c(
    "age3_public_proxy_audit_target",
    "short_sca_age2_audit_target"
  )), desc(abs_beta)) %>%
  slice_head(n = 14)

public_age_md <- public_age_top %>%
  transmute(
    grain,
    lag_years,
    label,
    n,
    beta = number(beta, accuracy = 0.01),
    p = number(p, accuracy = 0.01),
    rho = number(raw_rho, accuracy = 0.01),
    gate
  )

public_age_followup_n <- public_age_screen %>%
  filter(gate %in% c(
    "age3_public_proxy_audit_target",
    "short_sca_age2_audit_target",
    "delayed_public_proxy_audit_target"
  )) %>%
  nrow()

candidate_lines <- c(
  paste0("- Adult lag-1 follow-up rows: `", nrow(candidate_adult), "`."),
  paste0("- Age-3 biomass-growth proxy follow-up rows: `", nrow(candidate_age3), "`."),
  paste0("- Public age/recruitment proxy audit-target rows: `", public_age_followup_n, "`.")
)

best_age3_line <- if (nrow(best_age3) == 0) {
  "- No age-3 row could be ranked."
} else {
  paste0(
    "- Strongest age-3 row: `", best_age3$label, "` beta `",
    number(best_age3$beta, accuracy = 0.01),
    "`, rho `", number(best_age3$raw_rho, accuracy = 0.01),
    "`, gate `", best_age3$gate, "`."
  )
}

timing_takeaway <- if (nrow(candidate_age3) == 0) {
  "- The age-3 lag idea is biologically important, but biomass-growth proxy screens alone do not yet produce a model-ready predator/recruitment covariate."
} else {
  "- At least one age-3 lag clears the diagnostic gate; this should be followed with exact age-3 recruitment or age-composition data before a Stan branch."
}

plot_data <- lag_screen %>%
  filter(expected_sign != "screen_only", is.finite(beta)) %>%
  mutate(
    label = str_wrap(label, 24),
    gate_group = case_when(
      gate %in% c("adult_lag_followup_only", "age3_lag_followup_only", "delayed_sensitivity_followup_only") ~ "follow-up only",
      lag_years <= 0 ~ "future control",
      TRUE ~ "failed gate"
    )
  )

p_profile <- plot_data %>%
  ggplot(aes(x = lag_years, y = beta, group = label)) +
  annotate(
    "rect",
    xmin = -Inf,
    xmax = 0.5,
    ymin = -Inf,
    ymax = Inf,
    fill = "grey90",
    alpha = 0.5
  ) +
  geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey45") +
  geom_vline(xintercept = 3, linetype = "dashed", linewidth = 0.25, colour = "grey35") +
  geom_line(colour = "grey60", linewidth = 0.35) +
  geom_point(aes(colour = gate_group), size = 1.8) +
  facet_wrap(~label, scales = "free_y", ncol = 4) +
  scale_x_continuous(breaks = lag_years) +
  labs(
    x = "Lag in years: response year minus predictor year",
    y = "Adjusted coefficient",
    colour = NULL,
    title = "Future-control and delayed-lag audit",
    subtitle = "Grey band marks same/future controls; dashed line marks age-3 recruitment-return timing."
  ) +
  theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_age3 <- age3_screen %>%
  filter(expected_sign != "screen_only", is.finite(beta)) %>%
  mutate(
    label = fct_reorder(str_wrap(label, 28), beta),
    gate_group = case_when(
      gate == "age3_lag_followup_only" ~ "age-3 follow-up",
      TRUE ~ "failed gate"
    )
  ) %>%
  ggplot(aes(x = beta, y = label, fill = gate_group)) +
  geom_vline(xintercept = 0, linewidth = 0.25, colour = "grey45") +
  geom_col(width = 0.72) +
  labs(
    x = "Age-3 lag coefficient",
    y = NULL,
    fill = NULL,
    title = "Age-3 lag screen",
    subtitle = "These are recruitment-return proxies, not age-structured estimates."
  ) +
  theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_summary <- lag_summary %>%
  filter(expected_sign != "screen_only", is.finite(age3_lag_beta), is.finite(future_abs_beta_max)) %>%
  mutate(label = fct_reorder(str_wrap(label, 28), age3_lag_beta)) %>%
  ggplot(aes(x = future_abs_beta_max, y = abs(age3_lag_beta), colour = timing_read)) +
  geom_abline(slope = 1, intercept = 0.02, linetype = "dashed", linewidth = 0.25, colour = "grey40") +
  geom_point(size = 2) +
  labs(
    x = "Largest same/future-control |beta|",
    y = "Age-3 lag |beta|",
    colour = NULL,
    title = "Does age-3 beat the control?",
    subtitle = "Points above the dashed line beat future controls by >0.02."
  ) +
  theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_public_age <- public_age_screen %>%
  filter(
    is.finite(beta),
    lag_years %in% c(2, 3, 4),
    expected_sign != "screen_only",
    str_detect(response_col, "age3|sca_age2")
  ) %>%
  mutate(
    label = fct_reorder(str_wrap(label, 30), beta),
    gate_group = case_when(
      gate %in% c(
        "age3_public_proxy_audit_target",
        "short_sca_age2_audit_target",
        "delayed_public_proxy_audit_target"
      ) ~ "public proxy audit target",
      TRUE ~ "failed gate"
    )
  ) %>%
  ggplot(aes(x = beta, y = label, fill = gate_group)) +
  geom_vline(xintercept = 0, linewidth = 0.25, colour = "grey45") +
  geom_col(width = 0.72) +
  facet_wrap(~lag_years, scales = "free_y", ncol = 3, labeller = label_both) +
  labs(
    x = "Public age/recruitment proxy coefficient",
    y = NULL,
    fill = NULL,
    title = "Public age/recruitment proxy screen",
    subtitle = "Appendix B age composition is long but provisional; DFO 2025 recruitment is short but model-estimated."
  ) +
  theme_minimal(base_size = 7) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- p_profile / (p_age3 | p_summary) / p_public_age +
  plot_layout(heights = c(1.2, 0.9, 1.1)) +
  plot_annotation(
    title = "Predator and climate lag audit for post-closure recovery",
    subtitle = "Adult predation should be fast; recruitment effects may appear when age-3 cohorts return."
  )

ggsave(
  file.path(fig_dir, "future_lag_negative_control_audit.pdf"),
  p,
  width = 280,
  height = 230,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "future_lag_negative_control_audit.png"),
  p,
  width = 280,
  height = 230,
  units = "mm",
  dpi = 300
)

lines <- c(
  "# Future-Lag Negative-Control And Age-3 Lag Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  "- This diagnostic uses `m1_stier_11` posterior-median biomass growth into each year: `log(B[year] / B[year - 1])`.",
  "- Lag is defined as `response year - predictor year`. Lags `<= 0` are same/future-return-year controls, lag `1` is the adult growth interval, and lag `3` is the age-3 recruitment-return hypothesis.",
  "- Adult predation should show a fast lag; egg/juvenile/recruitment pathways can plausibly appear around lag 3 because many herring return to spawn about three years after birth.",
  "- The public DFO 2025 recruitment table is short because it is a recent SCA summary for 2015-2024. The longer public age-composition extract is CSAS 2018/028 Appendix B Table B.15, covering 1951-2017, but it remains a provisional PDF extraction and schema screen.",
  "- Spawn habitat index / spawn index is an egg-deposition or spawning-output index, not a pure recruitment index. It can be used as brood-year parent-output context or as a coarse return proxy, but it mixes survival, age composition, repeat spawning, q, and survey method.",
  candidate_lines,
  best_age3_line,
  timing_takeaway,
  "- Treat any positive age-3 result as a proxy only until exact age-3 recruitment, catch-at-age, or age-composition data are integrated.",
  "",
  "## Predictor Summary",
  "",
  knitr::kable(summary_md, format = "pipe"),
  "",
  "## Age-3 Lag Rows",
  "",
  knitr::kable(age3_md, format = "pipe"),
  "",
  "## Public Age / Recruitment Proxy Rows",
  "",
  knitr::kable(public_age_md, format = "pipe"),
  "",
  "## Future-Control Failures",
  "",
  knitr::kable(future_md, format = "pipe"),
  "",
  "## Quantitative Follow-Ups Not Yet Done",
  "",
  "- Fit the same lag screen to exact DFO age-3 recruitment or age-composition time series rather than biomass-growth proxies.",
  "- Replace the Appendix B provisional number-at-age screen with exact SCA/SISCAH age-composition input files, including effective sample sizes and source/fleet labels.",
  "- Build cohort-aligned juvenile exposure covariates: egg/larval predators and salmon demand in brood year, then age-3 return biomass or recruitment.",
  "- Use distributed-lag models with shrinkage across lags 0-5 instead of choosing one lag manually.",
  "- Add blocked/permutation negative controls that preserve trend and section structure, because ordinary future controls are hard to beat when all predator series are highly trended.",
  "- Split exposure years into observed, interpolated, and extrapolated subsets; a lag signal that exists only in extrapolated years is not model-ready.",
  "- Test section-specific recovery contrasts with leave-one-section-out influence checks, especially Cumshewa, Louscoone, and Skidegate.",
  "",
  "## Source Files",
  "",
  "- `Output/diagnostics/m1_stier_11_section_biomass_by_year.csv`",
  "- `Output/diagnostics/m1_stier_11_section_year_fishing_pressure.csv`",
  "- `Output/diagnostics/predator_spatial_exposure_section_year.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b8_spawn.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b15_number_at_age_long.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv`",
  "- `Data/processed/predators/hg_predation_pressure_covariates.csv`",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/future_lag_negative_control_audit.csv`",
  "- `Output/diagnostics/future_lag_negative_control_summary.csv`",
  "- `Output/diagnostics/age3_recruitment_lag_screen.csv`",
  "- `Output/diagnostics/public_age_recruitment_lag_proxy_screen.csv`",
  "- `Output/figures/future_lag_negative_control_audit.pdf`"
)

writeLines(lines, file.path(diag_dir, "future_lag_negative_control_audit.md"))

cat("Saved future-lag negative-control audit:\n")
cat("  Output/diagnostics/future_lag_negative_control_audit.md\n")
cat("  Output/diagnostics/future_lag_negative_control_audit.csv\n")
cat("  Output/diagnostics/future_lag_negative_control_summary.csv\n")
cat("  Output/diagnostics/age3_recruitment_lag_screen.csv\n")
cat("  Output/diagnostics/public_age_recruitment_lag_proxy_screen.csv\n")
cat("  Output/figures/future_lag_negative_control_audit.pdf\n")
