# ============================================================================
# 04g_m3_stier_distance_exact_reloo.R
# Exact holdout refits for high-Pareto observations in m3_stier_distance.
#
# The distance branch currently has multiple Pareto-k values above 0.7. This
# script refits the same model once per high-k positive-spawn observation,
# removing that observation from the likelihood and evaluating its exact held-
# out log predictive density from the refit posterior.
# ============================================================================

library(tidyverse)
library(here)
library(readxl)
library(rstan)
library(posterior)
library(loo)

rstan_options(auto_write = TRUE)

reloo_label <- Sys.getenv("M3_DISTANCE_RELOO_LABEL", "exact")
reloo_holdout_rank <- Sys.getenv("M3_DISTANCE_RELOO_HOLDOUT_RANK", "")
aws_array_index <- Sys.getenv("AWS_BATCH_JOB_ARRAY_INDEX", "")
source_job_id <- Sys.getenv("M3_DISTANCE_RELOO_SOURCE_JOB_ID", "m3_stier_distance")
fit_chains <- as.integer(Sys.getenv("M3_DISTANCE_RELOO_CHAINS", "4"))
fit_iter <- as.integer(Sys.getenv("M3_DISTANCE_RELOO_ITER", "4500"))
fit_warmup <- as.integer(Sys.getenv("M3_DISTANCE_RELOO_WARMUP", "2000"))
fit_cores <- as.integer(Sys.getenv("M3_DISTANCE_RELOO_CORES", as.character(fit_chains)))
fit_refresh <- as.integer(Sys.getenv("M3_DISTANCE_RELOO_REFRESH", "100"))
fit_adapt_delta <- as.numeric(Sys.getenv("M3_DISTANCE_RELOO_ADAPT_DELTA", "0.97"))
fit_max_treedepth <- as.integer(Sys.getenv("M3_DISTANCE_RELOO_MAX_TREEDEPTH", "15"))

options(mc.cores = fit_cores)

source(here("R", "00_setup.R"))

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
post_dir <- file.path(proj_dir, "Output", "posteriors")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(post_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

ensure_cloud_dependency <- function(local_path, s3_relative_path) {
  if (file.exists(local_path)) {
    return(invisible(local_path))
  }

  s3_prefix <- sub("/+$", "", Sys.getenv("S3_PREFIX", ""))
  if (!nzchar(s3_prefix)) {
    stop(
      "Required re-LOO dependency is missing locally: `",
      local_path,
      "`. Run `m3_stier_distance` first, promote its artifacts locally, ",
      "or submit this script from AWS Batch with S3_PREFIX set."
    )
  }

  s3_path <- paste(s3_prefix, "jobs", source_job_id, s3_relative_path, sep = "/")
  dir.create(dirname(local_path), showWarnings = FALSE, recursive = TRUE)
  cat("Required re-LOO dependency missing locally; fetching from S3:\n")
  cat("  ", s3_path, "\n", sep = "")

  result <- system2(
    "aws",
    c("s3", "cp", s3_path, local_path),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    cat(paste(result, collapse = "\n"), "\n")
    stop(
      "Could not fetch required re-LOO dependency from S3. ",
      "This usually means `",
      source_job_id,
      "` has not finished uploading artifacts yet."
    )
  }
  if (!file.exists(local_path)) {
    stop("S3 dependency fetch reported success but did not create: `", local_path, "`.")
  }

  invisible(local_path)
}

loo_path <- file.path(post_dir, "loo_m3_stier_distance.rds")
ensure_cloud_dependency(loo_path, "Output/posteriors/loo_m3_stier_distance.rds")

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
loo_obj <- readRDS(loo_path)

q_idx_stier <- if_else(jags_data$years <= 1987, 1L, 2L)
method_labels <- c("Surface", "SCUBA/dive")

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

holdouts <- obs_map %>%
  filter(pareto_k > 0.7)

if (nrow(holdouts) == 0) {
  stop("No m3_stier_distance Pareto-k values above 0.7.")
}

if (!nzchar(reloo_holdout_rank) && nzchar(aws_array_index)) {
  # AWS Batch array indexes are zero-based; holdout ranks are one-based.
  reloo_holdout_rank <- as.character(as.integer(aws_array_index) + 1L)
}

if (nzchar(reloo_holdout_rank)) {
  holdout_rank <- as.integer(reloo_holdout_rank)
  if (is.na(holdout_rank) || holdout_rank < 1L || holdout_rank > nrow(holdouts)) {
    stop(
      "M3_DISTANCE_RELOO_HOLDOUT_RANK must be between 1 and ",
      nrow(holdouts),
      "; got `",
      reloo_holdout_rank,
      "`."
    )
  }
  holdouts <- holdouts %>% slice(holdout_rank)
} else {
  holdout_rank <- NA_integer_
}

out_stem <- if (identical(reloo_label, "exact")) {
  "m3_stier_distance_exact_reloo"
} else {
  paste0("m3_stier_distance_", reloo_label, "_reloo")
}
if (!is.na(holdout_rank)) {
  out_stem <- paste0(out_stem, "_rank", sprintf("%03d", holdout_rank))
}
out_csv <- file.path(diag_dir, paste0(out_stem, ".csv"))
completed <- if (file.exists(out_csv)) {
  read_csv(out_csv, show_col_types = FALSE)
} else {
  tibble()
}

completed_idx <- if ("heldout_log_lik_index" %in% names(completed)) {
  completed$heldout_log_lik_index
} else {
  integer()
}

pointwise <- as.data.frame(loo_obj$pointwise)
looic_total <- loo_obj$estimates["looic", "Estimate"]

log_mean_exp <- function(x) {
  max_x <- max(x)
  max_x + log(mean(exp(x - max_x)))
}

make_stan_data <- function(holdout) {
  stan_data <- list(
    N_years = jags_data$nYears,
    N_sites = jags_data$nSites,
    Y = jags_data$Y,
    Y_obs_flag = jags_data$Y_obs,
    pdo = jags_data$pdo,
    N_methods = 2L,
    q_idx = q_idx_stier,
    dist_mat = D_km,
    max_dist = max_dist,
    N_catch = jags_data$nIndex,
    catch_yr = jags_data$INDEX[, 1],
    catch_site = jags_data$INDEX[, 2],
    log_catch = jags_data$ctab[jags_data$INDEX],
    prior_only = 0L
  )

  stan_data$Y_obs_flag[holdout$t, holdout$site] <- 0L
  stan_data$Y[stan_data$Y_obs_flag == 0L] <- 0.0
  stan_data
}

make_init <- function(stan_data) {
  function() {
    list(
      Umu = 0,
      pdocoef = 0,
      sigma_proc = 0.7,
      phi = 3 / stan_data$max_dist,
      sigma_obs = 0.8,
      log_q = c(-1.2, -0.2),
      Pc_logit = rep(-2.0, stan_data$N_catch),
      Z_init = rep(5, stan_data$N_sites),
      epsilon_raw = matrix(0, nrow = stan_data$N_years - 1, ncol = stan_data$N_sites)
    )
  }
}

stan_file <- here("inst", "stan", "herring_metapop_m3_stier_distance.stan")

for (i in seq_len(nrow(holdouts))) {
  holdout <- holdouts %>% slice(i)
  if (holdout$log_lik_index %in% completed_idx) {
    next
  }

  cat("M3 distance ", reloo_label, " reloo holdout ", i, " / ", nrow(holdouts), ":\n", sep = "")
  cat("  log_lik_index:", holdout$log_lik_index, "\n")
  cat("  year:", holdout$year, "\n")
  cat("  site:", holdout$site_name, "\n")
  cat("  method:", holdout$method, "\n")
  cat("  log_spawn:", holdout$log_spawn, "\n")
  cat("  pareto_k:", holdout$pareto_k, "\n\n")
  cat(
    "  settings: chains=", fit_chains,
    ", iter=", fit_iter,
    ", warmup=", fit_warmup,
    ", adapt_delta=", fit_adapt_delta,
    ", max_treedepth=", fit_max_treedepth,
    "\n\n",
    sep = ""
  )

  stan_data <- make_stan_data(holdout)
  fit <- stan(
    file = stan_file,
    data = stan_data,
    chains = fit_chains,
    iter = fit_iter,
    warmup = fit_warmup,
    cores = fit_cores,
    refresh = fit_refresh,
    init = make_init(stan_data),
    control = list(adapt_delta = fit_adapt_delta, max_treedepth = fit_max_treedepth),
    seed = 300 + holdout$log_lik_index
  )

  suffix <- paste0("idx", holdout$log_lik_index)
  saveRDS(
    fit,
    file.path(data_dir, paste0(out_stem, "_", suffix, "_fit.rds"))
  )

  post <- rstan::extract(fit, pars = c("X", "log_q", "sigma_obs"))
  mu_holdout <- post$X[, holdout$t, holdout$site] +
    post$log_q[, q_idx_stier[holdout$t]]
  log_pred_draws <- dnorm(
    holdout$log_spawn,
    mean = mu_holdout,
    sd = post$sigma_obs,
    log = TRUE
  )

  exact_elpd <- log_mean_exp(log_pred_draws)
  psis_elpd <- pointwise$elpd_loo[holdout$log_lik_index]
  psis_looic <- if ("looic" %in% names(pointwise)) {
    pointwise$looic[holdout$log_lik_index]
  } else {
    -2 * psis_elpd
  }

  sampler <- rstan::get_sampler_params(fit, inc_warmup = FALSE)
  divergences <- sum(vapply(sampler, function(x) sum(x[, "divergent__"]), numeric(1)))
  treedepth_hits <- sum(vapply(sampler, function(x) sum(x[, "treedepth__"] >= 15), numeric(1)))
  ebfmi <- vapply(sampler, function(x) {
    e <- x[, "energy__"]
    sum(diff(e)^2) / length(e) / stats::var(e)
  }, numeric(1))

  row <- tibble(
    model = "m3_stier_distance",
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
    divergences = divergences,
    treedepth_hits = treedepth_hits,
    min_ebfmi = min(ebfmi),
    n_high_pareto_total = nrow(holdouts)
  )

  completed <- bind_rows(completed, row) %>%
    arrange(desc(pareto_k)) %>%
    mutate(
      n_exact_refit_completed = n(),
      looic_total_exact_corrected = first(looic_total_psis) -
        sum(psis_looic_point, na.rm = TRUE) +
        sum(exact_looic_point, na.rm = TRUE)
    )

  write_csv(completed, out_csv)

  summ <- summarize_draws(fit)
  write.csv(
    summ,
    file.path(proj_dir, "Output", paste0(out_stem, "_", suffix, "_parameter_summary.csv")),
    row.names = FALSE
  )
}

if (nrow(completed) > 0) {
  lines <- c(
    paste0("# M3 Stier Distance ", str_to_title(reloo_label), " Re-LOO"),
    "",
    paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    "",
    "## Settings",
    "",
    paste0("- Label: `", reloo_label, "`"),
    paste0("- Chains: ", fit_chains),
    paste0("- Iterations: ", fit_iter),
    paste0("- Warmup: ", fit_warmup),
    paste0("- adapt_delta: ", fit_adapt_delta),
    paste0("- max_treedepth: ", fit_max_treedepth),
    "",
    "## Held-Out Points",
    "",
    paste0(
      "- Index ",
      completed$heldout_log_lik_index,
      ": ",
      completed$year,
      " ",
      completed$site_name,
      ", method = ",
      completed$method,
      ", log spawn = ",
      round(completed$log_spawn, 3),
      ", original Pareto k = ",
      round(completed$pareto_k, 3),
      ", exact elpd = ",
      round(completed$exact_elpd, 3)
    ),
    "",
    "## Exact Refit Result",
    "",
    paste0("- High-k points requiring exact refit: ", first(completed$n_high_pareto_total)),
    paste0("- Exact refits completed: ", first(completed$n_exact_refit_completed)),
    paste0("- Original total PSIS LOOIC: ", round(first(completed$looic_total_psis), 2)),
    paste0("- Exact-corrected total LOOIC so far: ", round(last(completed$looic_total_exact_corrected), 2)),
    paste0("- Total refit divergences: ", sum(completed$divergences)),
    paste0("- Total refit treedepth hits: ", sum(completed$treedepth_hits)),
    paste0("- Minimum refit E-BFMI: ", round(min(completed$min_ebfmi), 3))
  )

  writeLines(lines, file.path(diag_dir, paste0(out_stem, ".md")))
  cat(paste(lines, collapse = "\n"))
  cat("\n")
}
