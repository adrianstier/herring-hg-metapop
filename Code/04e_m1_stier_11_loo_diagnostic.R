# ============================================================================
# 04e_m1_stier_11_loo_diagnostic.R
# Focused PSIS-LOO diagnostic for the Stier-aligned 11-section baseline.
#
# This does not replace exact reloo. It identifies the high-Pareto point and
# writes a compact sensitivity report so the model is not mistaken for a
# sampler failure.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(loo)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
post_dir <- file.path(proj_dir, "Output", "posteriors")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(file.path(data_dir, "m1_stier_11_fit.rds"))
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
    log_spawn = map2_dbl(t, site, ~ jags_data$Y[.x, .y])
  )

pareto_k <- loo_obj$diagnostics$pareto_k
pointwise <- as.data.frame(loo_obj$pointwise)
log_lik <- rstan::extract(fit, pars = "log_lik", permuted = TRUE)$log_lik
post <- rstan::extract(fit, pars = c("X", "log_q"), permuted = TRUE)

log_mean_exp <- function(x) {
  max_x <- max(x)
  max_x + log(mean(exp(x - max_x)))
}

diagnostic_tbl <- obs_map %>%
  mutate(
    pareto_k = pareto_k[log_lik_index],
    psis_elpd = pointwise$elpd_loo[log_lik_index],
    psis_looic = if ("looic" %in% names(pointwise)) {
      pointwise$looic[log_lik_index]
    } else {
      -2 * pointwise$elpd_loo[log_lik_index]
    },
    full_posterior_lpd = map_dbl(log_lik_index, ~ log_mean_exp(log_lik[, .x])),
    fitted_log_median = pmap_dbl(
      list(t, site),
      ~ median(post$X[, ..1, ..2] + post$log_q[, q_idx_stier[..1]])
    ),
    fitted_log_lo90 = pmap_dbl(
      list(t, site),
      ~ quantile(post$X[, ..1, ..2] + post$log_q[, q_idx_stier[..1]], 0.05)
    ),
    fitted_log_hi90 = pmap_dbl(
      list(t, site),
      ~ quantile(post$X[, ..1, ..2] + post$log_q[, q_idx_stier[..1]], 0.95)
    ),
    log_residual = log_spawn - fitted_log_median,
    abs_log_residual = abs(log_residual)
  ) %>%
  arrange(desc(pareto_k))

write_csv(
  diagnostic_tbl,
  file.path(diag_dir, "m1_stier_11_high_pareto_points.csv")
)

bad_tbl <- diagnostic_tbl %>%
  filter(pareto_k > 0.7)

looic_total <- loo_obj$estimates["looic", "Estimate"]
looic_without_bad <- if (nrow(bad_tbl) > 0) {
  sum(diagnostic_tbl$psis_looic[!diagnostic_tbl$log_lik_index %in% bad_tbl$log_lik_index])
} else {
  looic_total
}

pareto_table <- loo::pareto_k_table(loo_obj)

lines <- c(
  "# M1 Stier 11 LOO Diagnostic",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## PSIS Summary",
  "",
  paste0("- Total LOOIC: ", round(looic_total, 2), "."),
  paste0("- Max Pareto k: ", round(max(pareto_k), 3), "."),
  paste0("- Points with Pareto k > 0.7: ", sum(pareto_k > 0.7), "."),
  paste0("- Points with Pareto k > 1: ", sum(pareto_k > 1), "."),
  paste0(
    "- LOOIC excluding high-k points, for scale only: ",
    round(looic_without_bad, 2),
    ". This is not exact reloo."
  ),
  "",
  "## Interpretation",
  "",
  "- The Stan sampler is clean; the issue is PSIS-LOO reliability for a small number of observations.",
  "- Do not use the total PSIS-LOOIC for promotion until the high-k point is handled by exact reloo, moment matching, or a defensible sensitivity decision.",
  "- The high-k point should be treated as an influential historical observation, not as evidence that the whole model failed.",
  "",
  "## High Pareto-k Points",
  ""
)

if (nrow(bad_tbl) == 0) {
  lines <- c(lines, "- None.")
} else {
  point_lines <- pmap_chr(
    bad_tbl,
    function(
        t, site, log_lik_index, year, site_name, method, log_spawn,
        pareto_k, psis_elpd, psis_looic, full_posterior_lpd,
        fitted_log_median, fitted_log_lo90, fitted_log_hi90,
        log_residual, abs_log_residual
    ) {
      paste0(
        "- Index ", log_lik_index, ": ", year, ", ", site_name,
        " (", method, "), log spawn=", round(log_spawn, 3),
        ", fitted median=", round(fitted_log_median, 3),
        " [90% ", round(fitted_log_lo90, 3), ", ",
        round(fitted_log_hi90, 3), "]",
        ", residual=", round(log_residual, 3),
        ", Pareto k=", round(pareto_k, 3), "."
      )
    }
  )
  lines <- c(lines, point_lines)
}

lines <- c(
  lines,
  "",
  "## Pareto-k Table",
  "",
  capture.output(print(pareto_table))
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_loo_diagnostic.md"))
cat(paste(lines, collapse = "\n"))
