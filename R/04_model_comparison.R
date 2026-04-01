# ============================================================================
# 04_model_comparison.R — LOO-CV model comparison
# stier-2027-herring-metapopulation
#
# Uses the loo package to compare herring metapopulation model variants
# via approximate leave-one-out cross-validation (Pareto smoothed
# importance sampling; Vehtari et al. 2017).
# ============================================================================

# Note: packages (loo, posterior) are loaded via tar_option_set(packages = ...)
# in _targets.R. Do NOT add library() or source() calls here — tar_source("R")
# handles sourcing.


# ── compare_models() ─────────────────────────────────────────────────────────
#' Compare two Stan model fits via LOO-CV
#'
#' Extracts log_lik from each CmdStanMCMC object, computes PSIS-LOO for each,
#' and returns a comparison table with standard errors on the difference.
#'
#' @param fit_v1 CmdStanMCMC object from herring_metapop_v1.stan.
#' @param fit_v2 CmdStanMCMC object from herring_metapop_v2.stan.
#' @param stan_data_v1 The data list passed to v1 (used to identify observed cells).
#' @param stan_data_v2 The data list passed to v2 (used to identify observed cells).
#'   If NULL, assumes same observation pattern as v1.
#' @param model_names Character vector of length 2 with display names.
#' @return A list with components:
#'   - loo_v1: loo object for model v1
#'   - loo_v2: loo object for model v2
#'   - comparison: loo_compare() output (data frame sorted by elpd)
#'   - elpd_diff: the elpd difference (positive favors first-listed model)
#'   - se_diff: standard error of the elpd difference
#'   - preferred: name of the preferred model
#'   - pareto_k_table: summary of Pareto k diagnostics for each model
#'
compare_models <- function(fit_v1,
                           fit_v2,
                           stan_data_v1,
                           stan_data_v2 = NULL,
                           model_names  = c("v1_diag_equal", "v2_mvn_predators")) {

  if (is.null(stan_data_v2)) stan_data_v2 <- stan_data_v1

  cat("\n", strrep("=", 60), "\n")
  cat(" LOO-CV MODEL COMPARISON\n")
  cat(strrep("=", 60), "\n\n")

  # ── Extract log_lik and filter to observed cells ──
  # NOTE: log_lik covers spawn observations only, not the catch likelihood.
  # This is intentional — we compare predictive performance on the quantity

  # of primary interest (spawn index), not on the auxiliary catch data.
  extract_log_lik_observed <- function(fit, stan_data) {
    # Extract full log_lik array: iterations x N_years*N_sites
    ll_array <- fit$draws("log_lik", format = "draws_matrix")

    # Identify which cells were actually observed
    Y_obs_vec <- as.vector(t(stan_data$Y_obs))  # row-major to match Stan indexing
    obs_idx   <- which(Y_obs_vec == 1)

    # Keep only observed cells (drop the zeros from missing data)
    ll_obs <- ll_array[, obs_idx]
    ll_obs
  }

  cat("Extracting log-likelihoods...\n")
  ll_v1 <- extract_log_lik_observed(fit_v1, stan_data_v1)
  ll_v2 <- extract_log_lik_observed(fit_v2, stan_data_v2)

  # ── Compute LOO for each model ──
  cat("Computing PSIS-LOO for", model_names[1], "...\n")
  loo_v1 <- loo(ll_v1, r_eff = relative_eff(exp(ll_v1)))

  cat("Computing PSIS-LOO for", model_names[2], "...\n")
  loo_v2 <- loo(ll_v2, r_eff = relative_eff(exp(ll_v2)))

  # ── Print individual LOO summaries ──
  cat("\n--- ", model_names[1], " ---\n")
  print(loo_v1)

  cat("\n--- ", model_names[2], " ---\n")
  print(loo_v2)

  # ── Compare ──
  comp <- loo_compare(list(loo_v1, loo_v2))
  rownames(comp) <- model_names[as.integer(gsub("model", "", rownames(comp)))]

  cat("\n--- Model comparison (sorted by elpd_loo) ---\n")
  print(comp)

  # Extract the difference
  elpd_diff <- comp[2, "elpd_diff"]
  se_diff   <- comp[2, "se_diff"]
  preferred <- rownames(comp)[1]

  cat("\nPreferred model:", preferred, "\n")
  cat("elpd_diff =", round(elpd_diff, 2),
      " (SE =", round(se_diff, 2), ")\n")

  # Interpret the difference
  z_score <- abs(elpd_diff / se_diff)
  if (z_score > 2) {
    cat("Interpretation: Strong evidence for", preferred, "(|z| =", round(z_score, 2), ")\n")
  } else if (z_score > 1) {
    cat("Interpretation: Moderate evidence for", preferred, "(|z| =", round(z_score, 2), ")\n")
  } else {
    cat("Interpretation: Models are similar (|z| =", round(z_score, 2), "); difference within noise.\n")
  }

  # ── Pareto k diagnostics ──
  pareto_k_table <- tibble(
    model = model_names,
    k_good    = c(sum(loo_v1$diagnostics$pareto_k < 0.5),
                  sum(loo_v2$diagnostics$pareto_k < 0.5)),
    k_ok      = c(sum(loo_v1$diagnostics$pareto_k >= 0.5 & loo_v1$diagnostics$pareto_k < 0.7),
                  sum(loo_v2$diagnostics$pareto_k >= 0.5 & loo_v2$diagnostics$pareto_k < 0.7)),
    k_bad     = c(sum(loo_v1$diagnostics$pareto_k >= 0.7 & loo_v1$diagnostics$pareto_k < 1),
                  sum(loo_v2$diagnostics$pareto_k >= 0.7 & loo_v2$diagnostics$pareto_k < 1)),
    k_very_bad = c(sum(loo_v1$diagnostics$pareto_k >= 1),
                   sum(loo_v2$diagnostics$pareto_k >= 1))
  )

  cat("\n--- Pareto k diagnostic summary ---\n")
  print(pareto_k_table)

  if (any(pareto_k_table$k_very_bad > 0)) {
    cat("\nWARNING: Some Pareto k values >= 1.0. Consider:\n")
    cat("  - Moment matching (loo::loo_moment_match())\n")
    cat("  - K-fold CV instead of PSIS-LOO\n")
    cat("  - Model reparameterization\n")
  }

  cat(strrep("=", 60), "\n\n")

  invisible(list(
    loo_v1         = loo_v1,
    loo_v2         = loo_v2,
    comparison     = comp,
    elpd_diff      = elpd_diff,
    se_diff        = se_diff,
    preferred      = preferred,
    pareto_k_table = pareto_k_table
  ))
}


# ── plot_loo_comparison() ────────────────────────────────────────────────────
#' Visualize LOO-CV comparison
#'
#' Creates two plots:
#' 1. Pareto k values for each model (identify influential observations)
#' 2. Pointwise elpd difference with site/year labels
#'
#' @param loo_result List returned by compare_models().
#' @param stan_data Data list (for year/site labels on plot 2).
#' @param years Integer vector of calendar years.
#' @param site_names Character vector of site names.
#' @return A patchwork plot object (invisible).
#'
plot_loo_comparison <- function(loo_result,
                                stan_data,
                                years      = YEARS,
                                site_names = SITE_NAMES) {

  library(patchwork)

  # -- Plot 1: Pareto k values --
  k_df <- tibble(
    obs = seq_along(loo_result$loo_v1$diagnostics$pareto_k),
    k_v1 = loo_result$loo_v1$diagnostics$pareto_k,
    k_v2 = loo_result$loo_v2$diagnostics$pareto_k
  ) |>
    pivot_longer(cols = c(k_v1, k_v2), names_to = "model", values_to = "pareto_k") |>
    mutate(model = ifelse(model == "k_v1", "v1 (diag equal)", "v2 (MVN + predators)"))

  p1 <- ggplot(k_df, aes(x = obs, y = pareto_k, color = model)) +
    geom_point(alpha = 0.5, size = 0.8) +
    geom_hline(yintercept = c(0.5, 0.7, 1.0), linetype = "dashed", color = "grey50") +
    scale_color_manual(values = c(PAL$teal, PAL$coral)) +
    labs(x = "Observation index", y = "Pareto k",
         title = "PSIS-LOO Pareto k diagnostics") +
    theme_pub(base_size = 10) +
    theme(legend.title = element_blank())

  # -- Plot 2: ELPD comparison --
  elpd_v1 <- loo_result$loo_v1$pointwise[, "elpd_loo"]
  elpd_v2 <- loo_result$loo_v2$pointwise[, "elpd_loo"]

  elpd_diff_df <- tibble(
    obs = seq_along(elpd_v1),
    diff = elpd_v1 - elpd_v2
  )

  p2 <- ggplot(elpd_diff_df, aes(x = obs, y = diff)) +
    geom_point(alpha = 0.4, size = 0.8, color = PAL$navy) +
    geom_hline(yintercept = 0, color = PAL$coral, linewidth = 0.6) +
    labs(x = "Observation index", y = "elpd_v1 - elpd_v2",
         title = "Pointwise elpd difference (positive favors v1)") +
    theme_pub(base_size = 10)

  p_combined <- p1 / p2 + plot_layout(heights = c(1, 1))

  ggsave(here::here("Output", "figures", "loo_comparison.pdf"),
         plot = p_combined, width = 170, height = 140, units = "mm",
         dpi = 300, device = cairo_pdf)

  cat("LOO comparison plot saved to Output/figures/loo_comparison.pdf\n")

  invisible(p_combined)
}
