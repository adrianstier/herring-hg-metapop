# ============================================================================
# 03d_posterior_predictive_checks_v3.R
# Posterior predictive checks for completed herring models.
#
# Focuses on the core features the analysis is claiming to explain:
#   - observed positive survey detections,
#   - surveyed-but-below-detection zeros,
#   - catch accounting/removal consistency,
#   - occupied sections by year.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)

proj_dir <- here::here()
proc_dir <- file.path(proj_dir, "Data", "processed")
post_dir <- file.path(proj_dir, "Output", "posteriors")
out_dir  <- file.path(proj_dir, "Output", "diagnostics")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

load(file.path(proc_dir, "jags_model_inputs_v2.RData"))

surveyed <- (jags_data$Y_obs + jags_data$Y_censored) == 1L
obs_positive <- jags_data$Y_obs == 1L
obs_censored <- jags_data$Y_censored == 1L
obs_occ_by_year <- rowSums(obs_positive)
catch_yr <- jags_data$INDEX[, 1]
catch_site <- jags_data$INDEX[, 2]
observed_log_catch <- jags_data$ctab[jags_data$INDEX]

models <- tribble(
  ~model,   ~fit_path,                              ~stan_path,                                             ~fit_script_path,
  "m1_v3",  file.path(proc_dir, "m1_v3_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_v3.stan"), file.path(proj_dir, "Code/03_fit_m1_v3.R"),
  "m3_v3",  file.path(proc_dir, "m3_v3_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m3_v3.stan"), file.path(proj_dir, "Code/03_fit_m3_v3.R"),
  "m5_v3",  file.path(proc_dir, "m5_v3_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_v3.stan"), file.path(proj_dir, "Code/03_fit_m5_v3.R"),
  "m1_stier_11",  file.path(proc_dir, "m1_stier_11_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_stier_11.stan"), file.path(proj_dir, "Code/03_fit_m1_stier_11.R"),
  "m1_stier_method_sensitivity",  file.path(proc_dir, "m1_stier_method_sensitivity_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_stier_method_sensitivity.stan"), file.path(proj_dir, "Code/03_fit_m1_stier_method_sensitivity.R"),
  "m1_stier_obs_hier",  file.path(proc_dir, "m1_stier_obs_hier_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_stier_obs_hier.stan"), file.path(proj_dir, "Code/03_fit_m1_stier_obs_hier.R"),
  "m2_stier_site_growth",  file.path(proc_dir, "m2_stier_site_growth_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m2_stier_site_growth.stan"), file.path(proj_dir, "Code/03_fit_m2_stier_site_growth.R"),
  "m3_stier_distance",  file.path(proc_dir, "m3_stier_distance_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m3_stier_distance.stan"), file.path(proj_dir, "Code/03_fit_m3_stier_distance.R"),
  "m5_stier_predation_pressure",  file.path(proc_dir, "m5_stier_predation_pressure_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_stier_predation_pressure.stan"), file.path(proj_dir, "Code/03_fit_m5_stier_predation_pressure.R"),
  "m5_stier_predator_demand_total",  file.path(proc_dir, "m5_stier_predator_demand_total_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_stier_predator_demand_total.stan"), file.path(proj_dir, "Code/03_fit_m5_stier_predator_demand_total.R"),
  "m5_stier_doherty_proxy_removals",  file.path(proc_dir, "m5_stier_doherty_proxy_removals_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_stier_doherty_proxy_removals.stan"), file.path(proj_dir, "Code/03_fit_m5_stier_doherty_proxy_removals.R"),
  "m5_v5",  file.path(proc_dir, "m5_v5_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_v5.stan"), file.path(proj_dir, "Code/03_fit_m5_v5.R"),
  "m5_combined",  file.path(proc_dir, "m5_combined_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_combined.stan"), file.path(proj_dir, "Code/03_fit_m5_combined.R"),
  "m1_v4",  file.path(proc_dir, "m1_v4_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_v4.stan"), file.path(proj_dir, "Code/03_fit_m1_v4.R"),
  "m1_v5",  file.path(proc_dir, "m1_v5_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_v5.stan"), file.path(proj_dir, "Code/03_fit_m1_v5.R"),
  "m3_v5",  file.path(proc_dir, "m3_v5_fit.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m3_v5.stan"), file.path(proj_dir, "Code/03_fit_m3_v5.R")
) %>%
  mutate(
    source_mtime = pmap_dbl(
      list(stan_path, fit_script_path),
      function(stan_path, fit_script_path) {
        source_paths <- c(stan_path, fit_script_path)
        source_paths <- source_paths[file.exists(source_paths)]
        if (length(source_paths) == 0) {
          return(0)
        }
        max(as.numeric(file.info(source_paths)$mtime), na.rm = TRUE)
      }
    ),
    fit_mtime = if_else(file.exists(fit_path), as.numeric(file.info(fit_path)$mtime), NA_real_),
    artifact_current = file.exists(fit_path) & fit_mtime >= source_mtime
  )

stale_models <- models %>%
  filter(file.exists(fit_path), !artifact_current)
if (nrow(stale_models) > 0) {
  write_csv(stale_models, file.path(out_dir, "stale_fit_artifacts.csv"))
}

models <- models %>%
  filter(file.exists(fit_path))

if (nrow(models) == 0) {
  stop("No completed fits found.")
}

summarize_metric <- function(x, observed) {
  tibble(
    observed = observed,
    pred_median = stats::median(x, na.rm = TRUE),
    pred_q05 = stats::quantile(x, 0.05, na.rm = TRUE),
    pred_q95 = stats::quantile(x, 0.95, na.rm = TRUE),
    ppc_p_lower = mean(x <= observed, na.rm = TRUE),
    ppc_p_upper = mean(x >= observed, na.rm = TRUE)
  )
}

ppc_one <- function(model, fit_path, artifact_current) {
  fit <- readRDS(fit_path)
  draws <- rstan::extract(fit, pars = "Y_rep", permuted = TRUE)
  y_rep <- draws$Y_rep
  n_draws <- dim(y_rep)[1]

  detected_available <- any(grepl("^detected_rep(\\[|$)", fit@sim$fnames_oi))
  below_available <- any(grepl("^below_detection_rep(\\[|$)", fit@sim$fnames_oi))
  if (detected_available) {
    pred_positive <- rstan::extract(fit, pars = "detected_rep", permuted = TRUE)$detected_rep == 1L
  } else if (below_available) {
    below_rep <- rstan::extract(fit, pars = "below_detection_rep", permuted = TRUE)$below_detection_rep == 1L
    pred_positive <- !below_rep
  } else {
    pred_positive <- y_rep > 0.1
  }

  total_positive <- vapply(
    seq_len(n_draws),
    function(i) sum(pred_positive[i, , ] & surveyed),
    numeric(1)
  )
  total_censored <- vapply(
    seq_len(n_draws),
    function(i) sum((!pred_positive[i, , ]) & surveyed),
    numeric(1)
  )

  pred_occ_by_year <- t(vapply(
    seq_len(n_draws),
    function(i) rowSums(pred_positive[i, , ] & surveyed),
    numeric(jags_data$nYears)
  ))

  observed_positive_signal_by_year <- vapply(
    seq_len(jags_data$nYears),
    function(t) {
      idx <- which(obs_positive[t, ])
      if (length(idx) == 0) {
        return(0)
      }
      sum(exp(jags_data$Y[t, idx]), na.rm = TRUE)
    },
    numeric(1)
  )

  pred_positive_signal_by_year <- t(vapply(
    seq_len(n_draws),
    function(i) {
      vapply(
        seq_len(jags_data$nYears),
        function(t) {
          idx <- which(obs_positive[t, ])
          if (length(idx) == 0) {
            return(0)
          }
          sum(y_rep[i, t, idx], na.rm = TRUE)
        },
        numeric(1)
      )
    },
    numeric(jags_data$nYears)
  ))

  positive_signal_log_resid <- sweep(
    log10(pred_positive_signal_by_year + 1),
    2,
    log10(observed_positive_signal_by_year + 1),
    "-"
  )
  aggregate_positive_signal_log_rmse <- apply(
    positive_signal_log_resid,
    1,
    function(x) sqrt(mean(x^2, na.rm = TRUE))
  )
  aggregate_positive_signal_log_bias <- rowMeans(
    positive_signal_log_resid,
    na.rm = TRUE
  )

  catch_fit_available <- all(c("biomass_pred", "fishing_rate") %in% fit@sim$pars_oi) &&
    length(observed_log_catch) > 0
  if (catch_fit_available) {
    catch_draws <- rstan::extract(
      fit,
      pars = c("biomass_pred", "fishing_rate"),
      permuted = TRUE
    )
    catch_fit_log <- vapply(
      seq_along(observed_log_catch),
      function(k) {
        log(pmax(catch_draws$biomass_pred[, catch_yr[k], catch_site[k]], 1e-12)) +
          log(pmax(catch_draws$fishing_rate[, catch_yr[k], catch_site[k]], 1e-12))
      },
      numeric(n_draws)
    )
    catch_log_resid <- sweep(catch_fit_log, 2, observed_log_catch, "-")
    catch_log_rmse <- apply(
      catch_log_resid,
      1,
      function(x) sqrt(mean(x^2, na.rm = TRUE))
    )
    catch_log_bias <- rowMeans(catch_log_resid, na.rm = TRUE)
  } else {
    catch_log_rmse <- NA_real_
    catch_log_bias <- NA_real_
  }

  summary_tbl <- bind_rows(
    summarize_metric(total_positive, sum(obs_positive)) %>% mutate(metric = "total_positive_survey_detections"),
    summarize_metric(total_censored, sum(obs_censored)) %>% mutate(metric = "total_below_detection_surveys"),
    summarize_metric(rowMeans(pred_occ_by_year), mean(obs_occ_by_year)) %>% mutate(metric = "mean_occupied_sections_per_year"),
    summarize_metric(
      apply(pred_occ_by_year, 1, function(x) sqrt(mean((x - obs_occ_by_year)^2))),
      0
    ) %>% mutate(metric = "occupied_sections_rmse")
    ,
    summarize_metric(aggregate_positive_signal_log_rmse, 0) %>%
      mutate(metric = "aggregate_positive_signal_log_rmse"),
    summarize_metric(aggregate_positive_signal_log_bias, 0) %>%
      mutate(metric = "aggregate_positive_signal_log_bias"),
    summarize_metric(catch_log_rmse, 0) %>%
      mutate(metric = "catch_log_rmse"),
    summarize_metric(catch_log_bias, 0) %>%
      mutate(metric = "catch_log_bias")
  ) %>%
    mutate(
      model = model,
      artifact_current = artifact_current,
      .before = 1
    )

  by_year_tbl <- tibble(
    model = model,
    artifact_current = artifact_current,
    year = jags_data$years,
    observed_occupied_sections = obs_occ_by_year,
    pred_median_occupied_sections = apply(pred_occ_by_year, 2, stats::median),
    pred_q05_occupied_sections = apply(pred_occ_by_year, 2, stats::quantile, probs = 0.05),
    pred_q95_occupied_sections = apply(pred_occ_by_year, 2, stats::quantile, probs = 0.95),
    observed_positive_signal = observed_positive_signal_by_year,
    pred_median_positive_signal = apply(pred_positive_signal_by_year, 2, stats::median),
    pred_q05_positive_signal = apply(pred_positive_signal_by_year, 2, stats::quantile, probs = 0.05),
    pred_q95_positive_signal = apply(pred_positive_signal_by_year, 2, stats::quantile, probs = 0.95)
  )

  list(summary = summary_tbl, by_year = by_year_tbl)
}

ppc_results <- purrr::pmap(
  models %>% select(model, fit_path, artifact_current),
  ppc_one
)

summary_tbl <- bind_rows(purrr::map(ppc_results, "summary"))
by_year_tbl <- bind_rows(purrr::map(ppc_results, "by_year"))

write_csv(summary_tbl, file.path(out_dir, "posterior_predictive_summary.csv"))
write_csv(by_year_tbl, file.path(out_dir, "posterior_predictive_by_year.csv"))
write_csv(summary_tbl, file.path(out_dir, "posterior_predictive_summary_v3.csv"))
write_csv(by_year_tbl, file.path(out_dir, "posterior_predictive_by_year_v3.csv"))

print(summary_tbl)
