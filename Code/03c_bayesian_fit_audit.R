# ============================================================================
# 03c_bayesian_fit_audit.R
# Bayesian fit audit for completed herring models.
#
# Produces a compact, source-of-truth table of:
#   - sampler pathologies,
#   - R-hat / ESS warnings,
#   - E-BFMI,
#   - LOO summaries when available.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(loo)

proj_dir <- here::here()
proc_dir <- file.path(proj_dir, "Data", "processed")
post_dir <- file.path(proj_dir, "Output", "posteriors")
out_dir  <- file.path(proj_dir, "Output", "diagnostics")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

models <- tribble(
  ~model,   ~fit_path,                              ~loo_path,                              ~stan_path,                                                ~fit_script_path,                         ~max_treedepth,
  "m1_v3",  file.path(proc_dir, "m1_v3_fit.rds"),  file.path(post_dir, "loo_m1_v3.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_v3.stan"), file.path(proj_dir, "Code/03_fit_m1_v3.R"), 15L,
  "m3_v3",  file.path(proc_dir, "m3_v3_fit.rds"),  file.path(post_dir, "loo_m3_v3.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m3_v3.stan"), file.path(proj_dir, "Code/03_fit_m3_v3.R"), 15L,
  "m5_v3",  file.path(proc_dir, "m5_v3_fit.rds"),  file.path(post_dir, "loo_m5_v3.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_v3.stan"), file.path(proj_dir, "Code/03_fit_m5_v3.R"), 15L,
  "m1_stier_11",  file.path(proc_dir, "m1_stier_11_fit.rds"),  file.path(post_dir, "loo_m1_stier_11.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_stier_11.stan"), file.path(proj_dir, "Code/03_fit_m1_stier_11.R"), 15L,
  "m1_stier_method_sensitivity",  file.path(proc_dir, "m1_stier_method_sensitivity_fit.rds"),  file.path(post_dir, "loo_m1_stier_method_sensitivity.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_stier_method_sensitivity.stan"), file.path(proj_dir, "Code/03_fit_m1_stier_method_sensitivity.R"), 15L,
  "m1_stier_obs_hier",  file.path(proc_dir, "m1_stier_obs_hier_fit.rds"),  file.path(post_dir, "loo_m1_stier_obs_hier.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_stier_obs_hier.stan"), file.path(proj_dir, "Code/03_fit_m1_stier_obs_hier.R"), 15L,
  "m2_stier_site_growth",  file.path(proc_dir, "m2_stier_site_growth_fit.rds"),  file.path(post_dir, "loo_m2_stier_site_growth.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m2_stier_site_growth.stan"), file.path(proj_dir, "Code/03_fit_m2_stier_site_growth.R"), 15L,
  "m3_stier_distance",  file.path(proc_dir, "m3_stier_distance_fit.rds"),  file.path(post_dir, "loo_m3_stier_distance.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m3_stier_distance.stan"), file.path(proj_dir, "Code/03_fit_m3_stier_distance.R"), 15L,
  "m5_stier_predation_pressure",  file.path(proc_dir, "m5_stier_predation_pressure_fit.rds"),  file.path(post_dir, "loo_m5_stier_predation_pressure.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_stier_predation_pressure.stan"), file.path(proj_dir, "Code/03_fit_m5_stier_predation_pressure.R"), 15L,
  "m5_v5",  file.path(proc_dir, "m5_v5_fit.rds"),  file.path(post_dir, "loo_m5_v5.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_v5.stan"), file.path(proj_dir, "Code/03_fit_m5_v5.R"), 15L,
  "m5_combined",  file.path(proc_dir, "m5_combined_fit.rds"),  file.path(post_dir, "loo_m5_combined.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m5_combined.stan"), file.path(proj_dir, "Code/03_fit_m5_combined.R"), 14L,
  "m1_v4",  file.path(proc_dir, "m1_v4_fit.rds"),  file.path(post_dir, "loo_m1_v4.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_v4.stan"), file.path(proj_dir, "Code/03_fit_m1_v4.R"), 16L,
  "m1_v5",  file.path(proc_dir, "m1_v5_fit.rds"),  file.path(post_dir, "loo_m1_v5.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m1_v5.stan"), file.path(proj_dir, "Code/03_fit_m1_v5.R"), 16L,
  "m3_v5",  file.path(proc_dir, "m3_v5_fit.rds"),  file.path(post_dir, "loo_m3_v5.rds"),  file.path(proj_dir, "inst/stan/herring_metapop_m3_v5.stan"), file.path(proj_dir, "Code/03_fit_m3_v5.R"), 15L
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
    loo_mtime = if_else(file.exists(loo_path), as.numeric(file.info(loo_path)$mtime), NA_real_),
    artifact_current = file.exists(fit_path) &
      fit_mtime >= source_mtime &
      (is.na(loo_mtime) | loo_mtime >= source_mtime)
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

load(file.path(proc_dir, "jags_model_inputs_v2.RData"))
n_positive <- sum(jags_data$Y_obs == 1L)
n_surveyed <- sum((jags_data$Y_obs + jags_data$Y_censored) == 1L)

audit_one <- function(
    model, fit_path, loo_path, max_treedepth,
    artifact_current, source_mtime, fit_mtime, loo_mtime
) {
  fit <- readRDS(fit_path)
  sampler <- rstan::get_sampler_params(fit, inc_warmup = FALSE)

  div <- sum(vapply(sampler, function(x) sum(x[, "divergent__"]), numeric(1)))
  td  <- sum(vapply(sampler, function(x) sum(x[, "treedepth__"] >= max_treedepth), numeric(1)))
  ebfmi <- vapply(
    sampler,
    function(x) {
      e <- x[, "energy__"]
      sum(diff(e)^2) / length(e) / stats::var(e)
    },
    numeric(1)
  )

  summ <- as.data.frame(summary(fit)$summary)
  param_rows <- rownames(summ)
  n_log_lik <- sum(grepl("^log_lik\\[", param_rows))
  core <- !grepl(
    "lp__|log_lik\\[|Y_rep\\[|biomass_pred\\[|fishing_rate\\[|p_below_detection\\[|below_detection_rep\\[|detection_prob\\[|detected_rep\\[|pred_effect_total\\[",
    param_rows
  )
  summ_core <- summ[core, , drop = FALSE]

  looic <- NA_real_
  elpd <- NA_real_
  max_pareto_k <- NA_real_
  n_loo_points <- NA_integer_
  n_pareto_k_gt_0_7 <- NA_integer_
  n_pareto_k_gt_1_0 <- NA_integer_
  if (file.exists(loo_path)) {
    loo_obj <- readRDS(loo_path)
    looic <- loo_obj$estimates["looic", "Estimate"]
    elpd  <- loo_obj$estimates["elpd_loo", "Estimate"]
    n_loo_points <- nrow(loo_obj$pointwise)
    pareto_k <- loo_obj$diagnostics$pareto_k
    max_pareto_k <- max(pareto_k, na.rm = TRUE)
    n_pareto_k_gt_0_7 <- sum(pareto_k > 0.7, na.rm = TRUE)
    n_pareto_k_gt_1_0 <- sum(pareto_k > 1.0, na.rm = TRUE)
  }

  likelihood_count <- if (!is.na(n_loo_points)) n_loo_points else n_log_lik
  likelihood_unit <- dplyr::case_when(
    likelihood_count == n_positive ~ "positive_only",
    likelihood_count == n_surveyed ~ "surveyed_cells",
    TRUE ~ "unknown"
  )

  tibble(
    model = model,
    artifact_current = artifact_current,
    source_mtime = source_mtime,
    fit_mtime = fit_mtime,
    loo_mtime = loo_mtime,
    likelihood_unit = likelihood_unit,
    n_log_lik = n_log_lik,
    n_loo_points = n_loo_points,
    n_positive_obs = n_positive,
    n_surveyed_cells = n_surveyed,
    max_treedepth = max_treedepth,
    n_params_checked = nrow(summ_core),
    divergences = div,
    treedepth_hits = td,
    max_rhat = max(summ_core[, "Rhat"], na.rm = TRUE),
    n_rhat_gt_1_01 = sum(summ_core[, "Rhat"] > 1.01, na.rm = TRUE),
    min_bulk_ess = min(summ_core[, "n_eff"], na.rm = TRUE),
    min_ebfmi = min(ebfmi, na.rm = TRUE),
    looic = looic,
    elpd_loo = elpd,
    max_pareto_k = max_pareto_k,
    n_pareto_k_gt_0_7 = n_pareto_k_gt_0_7,
    n_pareto_k_gt_1_0 = n_pareto_k_gt_1_0
  )
}

audit_tbl <- pmap_dfr(
  models %>%
    select(
      model, fit_path, loo_path, max_treedepth,
      artifact_current, source_mtime, fit_mtime, loo_mtime
    ),
  audit_one
)
write_csv(audit_tbl, file.path(out_dir, "bayesian_fit_audit.csv"))
write_csv(audit_tbl, file.path(out_dir, "bayesian_fit_audit_v3.csv"))
print(audit_tbl)
