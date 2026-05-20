# ============================================================================
# 04f_m1_stier_11_exact_reloo.R
# Exact holdout refit for the highest-Pareto observation in m1_stier_11.
#
# The current problematic point is selected automatically from
# loo_m1_stier_11.rds. The selected positive-spawn observation is removed from
# the likelihood, the model is refit, and the held-out log predictive density
# is calculated from the refit posterior.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(posterior)

rstan_options(auto_write = TRUE)
options(mc.cores = 4)

source(here("R", "00_setup.R"))

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
post_dir <- file.path(proj_dir, "Output", "posteriors")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(post_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
loo_obj <- readRDS(file.path(post_dir, "loo_m1_stier_11.rds"))

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)
method_labels <- c("Surface", "SCUBA/dive")

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
    method = method_labels[q_idx_stier[t]],
    log_spawn = map2_dbl(t, site, ~ jags_data$Y[.x, .y]),
    pareto_k = loo_obj$diagnostics$pareto_k[log_lik_index]
  ) %>%
  arrange(desc(pareto_k))

holdout <- obs_map %>% slice(1)

cat("Exact reloo holdout:\n")
cat("  log_lik_index:", holdout$log_lik_index, "\n")
cat("  year:", holdout$year, "\n")
cat("  site:", holdout$site_name, "\n")
cat("  method:", holdout$method, "\n")
cat("  log_spawn:", holdout$log_spawn, "\n")
cat("  pareto_k:", holdout$pareto_k, "\n\n")

stan_data <- list(
  N_years = jags_data$nYears,
  N_sites = jags_data$nSites,
  Y = jags_data$Y,
  Y_obs_flag = jags_data$Y_obs,
  pdo = jags_data$pdo,
  N_methods = 2L,
  q_idx = q_idx_stier,
  N_catch = jags_data$nIndex,
  catch_yr = jags_data$INDEX[, 1],
  catch_site = jags_data$INDEX[, 2],
  log_catch = jags_data$ctab[jags_data$INDEX],
  prior_only = 0L
)

stan_data$Y_obs_flag[holdout$t, holdout$site] <- 0L
stan_data$Y[stan_data$Y_obs_flag == 0L] <- 0.0

make_init_m1_stier_11 <- function() {
  list(
    Umu = 0,
    pdocoef = 0,
    sigma_proc = 0.7,
    sigma_obs = 0.8,
    log_q = c(-1.2, -0.2),
    Pc_logit = rep(-2.0, stan_data$N_catch),
    Z_init = rep(5, stan_data$N_sites),
    delta_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
  )
}

stan_file <- here("inst", "stan", "herring_metapop_m1_stier_11.stan")
fit <- stan(
  file = stan_file,
  data = stan_data,
  chains = 4,
  iter = 4500,
  warmup = 2000,
  cores = 4,
  refresh = 100,
  init = make_init_m1_stier_11,
  control = list(adapt_delta = 0.95, max_treedepth = 15),
  seed = 124
)

suffix <- paste0("idx", holdout$log_lik_index)
saveRDS(
  fit,
  file.path(data_dir, paste0("m1_stier_11_exact_reloo_", suffix, "_fit.rds"))
)

post <- rstan::extract(fit, pars = c("X", "log_q", "sigma_obs"))
mu_holdout <- post$X[, holdout$t, holdout$site] + post$log_q[, q_idx_stier[holdout$t]]
log_pred_draws <- dnorm(
  holdout$log_spawn,
  mean = mu_holdout,
  sd = post$sigma_obs,
  log = TRUE
)

log_mean_exp <- function(x) {
  max_x <- max(x)
  max_x + log(mean(exp(x - max_x)))
}

exact_elpd <- log_mean_exp(log_pred_draws)
pointwise <- as.data.frame(loo_obj$pointwise)
psis_elpd <- pointwise$elpd_loo[holdout$log_lik_index]
psis_looic <- if ("looic" %in% names(pointwise)) {
  pointwise$looic[holdout$log_lik_index]
} else {
  -2 * psis_elpd
}
looic_total <- loo_obj$estimates["looic", "Estimate"]
looic_exact_corrected <- looic_total - psis_looic + (-2 * exact_elpd)

sampler <- rstan::get_sampler_params(fit, inc_warmup = FALSE)
divergences <- sum(vapply(sampler, function(x) sum(x[, "divergent__"]), numeric(1)))
treedepth_hits <- sum(vapply(sampler, function(x) sum(x[, "treedepth__"] >= 15), numeric(1)))
ebfmi <- vapply(sampler, function(x) {
  e <- x[, "energy__"]
  sum(diff(e)^2) / length(e) / stats::var(e)
}, numeric(1))

result <- tibble(
  model = "m1_stier_11",
  heldout_log_lik_index = holdout$log_lik_index,
  year = holdout$year,
  site = holdout$site,
  site_name = holdout$site_name,
  method = holdout$method,
  log_spawn = holdout$log_spawn,
  pareto_k = holdout$pareto_k,
  psis_elpd = psis_elpd,
  exact_elpd = exact_elpd,
  psis_looic_point = psis_looic,
  exact_looic_point = -2 * exact_elpd,
  looic_total_psis = looic_total,
  looic_total_exact_corrected = looic_exact_corrected,
  divergences = divergences,
  treedepth_hits = treedepth_hits,
  min_ebfmi = min(ebfmi)
)

write_csv(result, file.path(diag_dir, "m1_stier_11_exact_reloo.csv"))

summ <- summarize_draws(fit)
write.csv(
  summ,
  file.path(proj_dir, "Output", paste0("m1_stier_11_exact_reloo_", suffix, "_parameter_summary.csv")),
  row.names = FALSE
)

lines <- c(
  "# M1 Stier 11 Exact Re-LOO",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Held-Out Point",
  "",
  paste0("- Index: ", holdout$log_lik_index),
  paste0("- Year: ", holdout$year),
  paste0("- Site: ", holdout$site_name),
  paste0("- Method: ", holdout$method),
  paste0("- log spawn: ", round(holdout$log_spawn, 3)),
  paste0("- original Pareto k: ", round(holdout$pareto_k, 3)),
  "",
  "## Exact Refit Result",
  "",
  paste0("- PSIS elpd for point: ", round(psis_elpd, 3)),
  paste0("- Exact held-out elpd for point: ", round(exact_elpd, 3)),
  paste0("- Original total PSIS LOOIC: ", round(looic_total, 2)),
  paste0("- Exact-corrected total LOOIC: ", round(looic_exact_corrected, 2)),
  paste0("- Refit divergences: ", divergences),
  paste0("- Refit treedepth hits: ", treedepth_hits),
  paste0("- Refit min E-BFMI: ", round(min(ebfmi), 3))
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_exact_reloo.md"))
cat(paste(lines, collapse = "\n"))
