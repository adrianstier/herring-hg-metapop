# =============================================================================
# 07_prior_sensitivity.R — Prior sensitivity analysis for M1 baseline model
#
# Tests whether posterior estimates are data-driven or prior-driven by
# refitting M1 under 4 prior specifications:
#   1. Weakly informative (current defaults)
#   2. Vague/diffuse (2-3x wider)
#   3. Informative (ecologically grounded)
#   4. Skeptical (strong prior mass on null effects)
#
# Also runs a prior predictive check (sampling from priors with no data).
#
# Output:
#   - Output/diagnostics/prior_sensitivity_*.pdf (density comparisons)
#   - Output/diagnostics/prior_sensitivity_summary.csv
#   - Output/diagnostics/prior_predictive_check.pdf
# =============================================================================

library(rstan)
library(ggplot2)
library(dplyr)
library(tidyr)

options(mc.cores = 4)
rstan_options(auto_write = TRUE)

# Okabe-Ito palette for prior specs
prior_cols <- c(
  "Weakly informative" = "#0072B2",
  "Vague/diffuse"      = "#E69F00",
  "Informative"        = "#009E73",
  "Skeptical"          = "#D55E00"
)

# =============================================================================
# 1. Load data (same prep as 03_fit_m1.R)
# =============================================================================

cat("Loading data...\n")
load("Data/processed/jags_model_inputs.RData")

Y_raw    <- jags_data$Y
nYears   <- jags_data$nYears
nSites   <- jags_data$nSites
pdo      <- jags_data$pdo
ctab     <- jags_data$ctab
INDEX    <- jags_data$INDEX
INDEX_z  <- jags_data$INDEX.zero
nIndex   <- jags_data$nIndex
nIndex_z <- jags_data$nIndex.zero
q_idx    <- jags_data$q_idx
years    <- jags_data$years
sites    <- jags_data$site_names

y_obs <- ifelse(is.na(Y_raw), 0L, 1L)
Y_stan <- Y_raw
Y_stan[is.na(Y_stan)] <- 0.0

catch_yr   <- as.integer(INDEX[, 1])
catch_site <- as.integer(INDEX[, 2])
log_catch  <- numeric(nIndex)
for (k in seq_len(nIndex)) {
  log_catch[k] <- ctab[catch_yr[k], catch_site[k]]
}
zero_yr   <- as.integer(INDEX_z[, 1])
zero_site <- as.integer(INDEX_z[, 2])

# Base data list (shared across all prior specs)
base_data <- list(
  N_years    = nYears,
  N_sites    = nSites,
  Y          = Y_stan,
  y_obs      = y_obs,
  pdo        = as.numeric(pdo),
  q_idx      = as.integer(q_idx),
  N_catch    = nIndex,
  catch_yr   = catch_yr,
  catch_site = catch_site,
  log_catch  = log_catch,
  N_zero     = nIndex_z,
  zero_yr    = zero_yr,
  zero_site  = zero_site
)

# =============================================================================
# 2. Define prior specifications
# =============================================================================
# Current Stan file priors:
#   Umu        ~ Normal(0, 1)
#   pdocoef    ~ Normal(0, 1)
#   sigma_proc ~ half-t(3, 0, 2.5)
#   sigma_obs  ~ half-t(3, 0, 2.5)
#   log_q      ~ Normal(0, 2)
#   Pc_logit   ~ Normal(-1.386, 0.707)
#   Z_init     ~ Normal(5, 10)
# =============================================================================

prior_specs <- list(

  # --- 1. Weakly informative (current defaults) ---
  "Weakly informative" = list(
    prior_Umu_mean       = 0,
    prior_Umu_sd         = 1,
    prior_pdocoef_mean   = 0,
    prior_pdocoef_sd     = 1,
    prior_sigma_proc_scale = 2.5,
    prior_sigma_proc_df    = 3,
    prior_sigma_obs_scale  = 2.5,
    prior_sigma_obs_df     = 3,
    prior_log_q_mean     = 0,
    prior_log_q_sd       = 2,
    prior_Pc_logit_mean  = -1.386,
    prior_Pc_logit_sd    = 0.707,
    prior_Z_init_mean    = 5,
    prior_Z_init_sd      = 10,
    prior_only           = 0L
  ),

  # --- 2. Vague/diffuse (2-3x wider) ---
  "Vague/diffuse" = list(
    prior_Umu_mean       = 0,
    prior_Umu_sd         = 3,       # 3x wider
    prior_pdocoef_mean   = 0,
    prior_pdocoef_sd     = 3,       # 3x wider
    prior_sigma_proc_scale = 5,     # 2x wider scale
    prior_sigma_proc_df    = 1,     # Cauchy (heavier tails)
    prior_sigma_obs_scale  = 5,     # 2x wider scale
    prior_sigma_obs_df     = 1,     # Cauchy
    prior_log_q_mean     = 0,
    prior_log_q_sd       = 5,       # 2.5x wider
    prior_Pc_logit_mean  = -1.386,
    prior_Pc_logit_sd    = 2,       # ~3x wider
    prior_Z_init_mean    = 5,
    prior_Z_init_sd      = 20,      # 2x wider
    prior_only           = 0L
  ),

  # --- 3. Informative (ecologically grounded) ---
  # Herring growth: annual log-growth ~0, SD ~0.3 (populations near equilibrium)
  # PDO effect: small but nonzero, ~0.05 per unit PDO, SD ~0.15
  # sigma_proc: process variation ~0.3-0.5 on log scale for fish populations
  # sigma_obs: survey observation error ~0.5-1.0 on log scale
  # log_q: surface surveys tend to underestimate (-0.5 to -1.5)
  "Informative" = list(
    prior_Umu_mean       = 0,
    prior_Umu_sd         = 0.3,     # tight around zero growth
    prior_pdocoef_mean   = 0,
    prior_pdocoef_sd     = 0.3,     # small effect expected
    prior_sigma_proc_scale = 0.5,   # centered on plausible process SD
    prior_sigma_proc_df    = 5,     # moderate tails
    prior_sigma_obs_scale  = 1.0,   # centered on plausible obs SD
    prior_sigma_obs_df     = 5,
    prior_log_q_mean     = -1,      # surface surveys underestimate
    prior_log_q_sd       = 0.5,
    prior_Pc_logit_mean  = -1.386,
    prior_Pc_logit_sd    = 0.5,     # tighter around 20% catch
    prior_Z_init_mean    = 5,
    prior_Z_init_sd      = 3,       # tighter
    prior_only           = 0L
  ),

  # --- 4. Skeptical (null effects) ---
  # Strong prior on b=0 (no PDO effect), small growth, tight variances
  "Skeptical" = list(
    prior_Umu_mean       = 0,
    prior_Umu_sd         = 0.2,     # very tight around zero
    prior_pdocoef_mean   = 0,
    prior_pdocoef_sd     = 0.1,     # strong skepticism about PDO effect
    prior_sigma_proc_scale = 0.5,
    prior_sigma_proc_df    = 5,
    prior_sigma_obs_scale  = 0.5,
    prior_sigma_obs_df     = 5,
    prior_log_q_mean     = 0,
    prior_log_q_sd       = 0.5,     # tight around q=1
    prior_Pc_logit_mean  = -1.386,
    prior_Pc_logit_sd    = 0.5,
    prior_Z_init_mean    = 5,
    prior_Z_init_sd      = 5,
    prior_only           = 0L
  )
)

# =============================================================================
# 3. Compile the prior-test Stan model
# =============================================================================

cat("\n--- Compiling prior-test Stan model ---\n")
stan_file <- "inst/stan/herring_metapop_m1_priortest.stan"
model <- stan_model(file = stan_file, verbose = FALSE)
cat("Compilation successful!\n")

# =============================================================================
# 4. Fit model under each prior specification
# =============================================================================

key_params <- c("Umu", "pdocoef", "sigma_proc", "sigma_obs", "log_q[1]", "log_q[2]")

fits <- list()
summaries <- list()
posterior_draws <- list()

for (spec_name in names(prior_specs)) {
  cat("\n===================================================\n")
  cat(" Fitting:", spec_name, "\n")
  cat("===================================================\n")

  # Merge base data with prior hyperparameters
  stan_data <- c(base_data, prior_specs[[spec_name]])

  fit <- sampling(
    model,
    data    = stan_data,
    chains  = 4,
    warmup  = 500,
    iter    = 1000,
    thin    = 1,
    seed    = 42,
    control = list(
      adapt_delta   = 0.95,
      max_treedepth = 12
    )
  )

  fits[[spec_name]] <- fit

  # Extract summary for key params
  fit_summ <- summary(fit)$summary
  summaries[[spec_name]] <- fit_summ[key_params, , drop = FALSE]

  # Check diagnostics
  sampler_params <- get_sampler_params(fit, inc_warmup = FALSE)
  n_div <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
  rhat_vals <- fit_summ[, "Rhat"]
  rhat_vals <- rhat_vals[!is.na(rhat_vals)]
  n_bad_rhat <- sum(rhat_vals > 1.05, na.rm = TRUE)

  cat("  Divergent transitions:", n_div, "\n")
  cat("  Parameters with Rhat > 1.05:", n_bad_rhat, "\n")
  cat("  Key parameter estimates:\n")
  print(fit_summ[key_params, c("mean", "sd", "2.5%", "97.5%", "Rhat")])

  # Extract posterior draws for key params
  draws <- as.data.frame(rstan::extract(fit, pars = c("Umu", "pdocoef",
                                                       "sigma_proc", "sigma_obs",
                                                       "log_q")))
  # rename log_q columns
  if ("log_q.1" %in% names(draws)) {
    names(draws)[names(draws) == "log_q.1"] <- "log_q[1]"
    names(draws)[names(draws) == "log_q.2"] <- "log_q[2]"
  }
  draws$prior_spec <- spec_name
  posterior_draws[[spec_name]] <- draws
}

# =============================================================================
# 5. Combine and create comparison plots
# =============================================================================

cat("\n--- Creating comparison plots ---\n")
dir.create("Output/diagnostics", recursive = TRUE, showWarnings = FALSE)

all_draws <- bind_rows(posterior_draws)
all_draws$prior_spec <- factor(all_draws$prior_spec,
                                levels = names(prior_specs))

# Parameters to plot
params_to_plot <- c("Umu", "pdocoef", "sigma_proc", "sigma_obs",
                    "log_q[1]", "log_q[2]")
param_labels <- c(
  "Umu"        = "Growth rate (Umu)",
  "pdocoef"    = "PDO coefficient",
  "sigma_proc" = "Process error SD",
  "sigma_obs"  = "Observation error SD",
  "log_q[1]"   = "log catchability (surface)",
  "log_q[2]"   = "log catchability (dive)"
)

# Pivot to long format
draws_long <- all_draws %>%
  pivot_longer(
    cols = all_of(params_to_plot),
    names_to = "parameter",
    values_to = "value"
  ) %>%
  mutate(parameter = factor(parameter, levels = params_to_plot,
                             labels = param_labels[params_to_plot]))

# --- Panel plot: all parameters ---
p_all <- ggplot(draws_long, aes(x = value, fill = prior_spec, color = prior_spec)) +
  geom_density(alpha = 0.25, linewidth = 0.6) +
  facet_wrap(~parameter, scales = "free", ncol = 2) +
  scale_fill_manual(values = prior_cols, name = "Prior specification") +
  scale_color_manual(values = prior_cols, name = "Prior specification") +
  labs(
    title = "Prior sensitivity analysis: M1 baseline model",
    subtitle = "Posterior densities under 4 prior specifications (500 warmup, 500 sampling)",
    x = "Parameter value",
    y = "Posterior density"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 9),
    plot.margin = margin(10, 10, 10, 10, "mm")
  )

ggsave("Output/diagnostics/prior_sensitivity_all_params.pdf",
       plot = p_all, width = 200, height = 250, units = "mm", dpi = 300)
cat("  Saved: Output/diagnostics/prior_sensitivity_all_params.pdf\n")

# --- Individual parameter plots (higher resolution) ---
for (i in seq_along(params_to_plot)) {
  param <- params_to_plot[i]
  label <- param_labels[param]
  safe_name <- gsub("[\\[\\]]", "", param)

  draws_param <- all_draws %>%
    select(all_of(param), prior_spec) %>%
    rename(value = !!sym(param))

  p <- ggplot(draws_param, aes(x = value, fill = prior_spec, color = prior_spec)) +
    geom_density(alpha = 0.25, linewidth = 0.8) +
    scale_fill_manual(values = prior_cols, name = "Prior specification") +
    scale_color_manual(values = prior_cols, name = "Prior specification") +
    labs(
      title = paste("Prior sensitivity:", label),
      x = label,
      y = "Posterior density"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      plot.margin = margin(10, 10, 10, 10, "mm")
    )

  fname <- paste0("Output/diagnostics/prior_sensitivity_", safe_name, ".pdf")
  ggsave(fname, plot = p, width = 150, height = 100, units = "mm", dpi = 300)
  cat("  Saved:", fname, "\n")
}

# =============================================================================
# 6. Summary table: prior/posterior comparison
# =============================================================================

cat("\n--- Building summary table ---\n")

summary_rows <- list()
for (spec_name in names(prior_specs)) {
  s <- summaries[[spec_name]]
  for (param in key_params) {
    summary_rows[[length(summary_rows) + 1]] <- data.frame(
      prior_spec = spec_name,
      parameter  = param,
      post_mean  = s[param, "mean"],
      post_sd    = s[param, "sd"],
      post_2.5   = s[param, "2.5%"],
      post_97.5  = s[param, "97.5%"],
      n_eff      = s[param, "n_eff"],
      Rhat       = s[param, "Rhat"],
      stringsAsFactors = FALSE
    )
  }
}
summary_df <- bind_rows(summary_rows)

# Add prior specification details for reference
prior_detail <- data.frame(
  prior_spec = rep(names(prior_specs), each = length(key_params)),
  parameter  = rep(key_params, times = length(prior_specs)),
  stringsAsFactors = FALSE
)

# Add a column flagging sensitivity: max absolute shift in posterior mean
# relative to "Weakly informative" baseline
baseline <- summary_df %>%
  filter(prior_spec == "Weakly informative") %>%
  select(parameter, baseline_mean = post_mean, baseline_sd = post_sd)

summary_df <- summary_df %>%
  left_join(baseline, by = "parameter") %>%
  mutate(
    mean_shift   = post_mean - baseline_mean,
    shift_in_sds = ifelse(baseline_sd > 0,
                          abs(post_mean - baseline_mean) / baseline_sd,
                          NA),
    sensitivity  = case_when(
      shift_in_sds < 0.1 ~ "insensitive",
      shift_in_sds < 0.5 ~ "mildly sensitive",
      shift_in_sds < 1.0 ~ "moderately sensitive",
      TRUE               ~ "SENSITIVE"
    )
  )

write.csv(summary_df, "Output/diagnostics/prior_sensitivity_summary.csv",
          row.names = FALSE)
cat("  Saved: Output/diagnostics/prior_sensitivity_summary.csv\n")

# Print summary
cat("\n======================================================\n")
cat("  PRIOR SENSITIVITY SUMMARY\n")
cat("======================================================\n\n")

cat("Sensitivity flags (shift from baseline in units of baseline posterior SD):\n\n")
summary_df %>%
  select(prior_spec, parameter, post_mean, post_sd, shift_in_sds, sensitivity) %>%
  arrange(parameter, prior_spec) %>%
  as.data.frame() %>%
  print()

# =============================================================================
# 7. Prior predictive check
# =============================================================================

cat("\n\n--- Running prior predictive check ---\n")
cat("  (Sampling from priors only, no likelihood)\n")

# Use weakly informative priors for the prior predictive
prior_pred_data <- c(base_data, prior_specs[["Weakly informative"]])
prior_pred_data$prior_only <- 1L

fit_prior <- sampling(
  model,
  data    = prior_pred_data,
  chains  = 4,
  warmup  = 500,
  iter    = 1000,
  thin    = 1,
  seed    = 42,
  control = list(
    adapt_delta   = 0.90,
    max_treedepth = 10
  )
)

# Extract Z (pre-fishing log biomass) trajectories from prior predictive
# Z is N_years x N_sites matrix; extract a sample of draws
Z_draws <- rstan::extract(fit_prior, pars = "Z")$Z  # n_draws x N_years x N_sites
n_draws <- dim(Z_draws)[1]

# Sample 200 draws for plotting
set.seed(42)
draw_idx <- sample(1:n_draws, min(200, n_draws))

# Convert to total spawning biomass across all sites (sum on natural scale)
# Z is log biomass, so total = sum(exp(Z)) per year
total_biomass <- matrix(NA, length(draw_idx), nYears)
for (i in seq_along(draw_idx)) {
  for (t in 1:nYears) {
    total_biomass[i, t] <- sum(exp(Z_draws[draw_idx[i], t, ]))
  }
}

# Also get observed total biomass for comparison
Y_total_obs <- rep(NA, nYears)
for (t in 1:nYears) {
  obs_sites <- which(y_obs[t, ] == 1)
  if (length(obs_sites) > 0) {
    Y_total_obs[t] <- sum(exp(Y_raw[t, obs_sites]), na.rm = TRUE)
  }
}

# Build data frame for plotting
prior_traj <- data.frame(
  year    = rep(years[1:nYears], each = length(draw_idx)),
  draw    = rep(1:length(draw_idx), times = nYears),
  biomass = as.vector(t(total_biomass))
)

obs_df <- data.frame(
  year    = years[1:nYears],
  biomass = Y_total_obs
)

# Compute prior predictive quantiles
prior_quantiles <- prior_traj %>%
  group_by(year) %>%
  summarise(
    median = median(biomass, na.rm = TRUE),
    q05    = quantile(biomass, 0.05, na.rm = TRUE),
    q25    = quantile(biomass, 0.25, na.rm = TRUE),
    q75    = quantile(biomass, 0.75, na.rm = TRUE),
    q95    = quantile(biomass, 0.95, na.rm = TRUE),
    .groups = "drop"
  )

# Cap extreme values for plotting (prior predictive can produce huge values)
y_upper <- quantile(prior_quantiles$q95, 0.95, na.rm = TRUE)

p_prior_pred <- ggplot() +
  geom_ribbon(data = prior_quantiles,
              aes(x = year, ymin = pmin(q05, y_upper),
                  ymax = pmin(q95, y_upper)),
              fill = "#0072B2", alpha = 0.15) +
  geom_ribbon(data = prior_quantiles,
              aes(x = year, ymin = pmin(q25, y_upper),
                  ymax = pmin(q75, y_upper)),
              fill = "#0072B2", alpha = 0.3) +
  geom_line(data = prior_quantiles,
            aes(x = year, y = pmin(median, y_upper)),
            color = "#0072B2", linewidth = 0.8) +
  geom_point(data = obs_df %>% filter(!is.na(biomass)),
             aes(x = year, y = biomass),
             color = "black", size = 1.2, alpha = 0.7) +
  coord_cartesian(ylim = c(0, y_upper * 1.1)) +
  labs(
    title = "Prior predictive check: total spawning biomass",
    subtitle = "Blue bands = 50%/90% prior predictive intervals; black points = observed data",
    x = "Year",
    y = "Total spawning biomass (tonnes)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 10, 10, 10, "mm")
  )

ggsave("Output/diagnostics/prior_predictive_check.pdf",
       plot = p_prior_pred, width = 200, height = 120, units = "mm", dpi = 300)
cat("  Saved: Output/diagnostics/prior_predictive_check.pdf\n")

# Prior predictive on log scale (more informative for state-space models)
p_prior_pred_log <- ggplot() +
  geom_ribbon(data = prior_quantiles,
              aes(x = year, ymin = q05, ymax = q95),
              fill = "#0072B2", alpha = 0.15) +
  geom_ribbon(data = prior_quantiles,
              aes(x = year, ymin = q25, ymax = q75),
              fill = "#0072B2", alpha = 0.3) +
  geom_line(data = prior_quantiles,
            aes(x = year, y = median),
            color = "#0072B2", linewidth = 0.8) +
  geom_point(data = obs_df %>% filter(!is.na(biomass)),
             aes(x = year, y = biomass),
             color = "black", size = 1.2, alpha = 0.7) +
  scale_y_log10() +
  labs(
    title = "Prior predictive check: total spawning biomass (log scale)",
    subtitle = "Blue bands = 50%/90% prior predictive intervals; black points = observed",
    x = "Year",
    y = "Total spawning biomass (log scale)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 10, 10, 10, "mm")
  )

ggsave("Output/diagnostics/prior_predictive_check_log.pdf",
       plot = p_prior_pred_log, width = 200, height = 120, units = "mm", dpi = 300)
cat("  Saved: Output/diagnostics/prior_predictive_check_log.pdf\n")

# =============================================================================
# 8. Prior vs posterior comparison (for key params under default priors)
# =============================================================================

cat("\n--- Prior vs posterior overlay ---\n")

# Extract prior draws for key params
prior_draws <- as.data.frame(rstan::extract(fit_prior,
                                             pars = c("Umu", "pdocoef",
                                                      "sigma_proc", "sigma_obs",
                                                      "log_q")))
if ("log_q.1" %in% names(prior_draws)) {
  names(prior_draws)[names(prior_draws) == "log_q.1"] <- "log_q[1]"
  names(prior_draws)[names(prior_draws) == "log_q.2"] <- "log_q[2]"
}
prior_draws$source <- "Prior"

# Posterior draws (weakly informative)
post_draws <- posterior_draws[["Weakly informative"]]
post_draws$source <- "Posterior"
post_draws$prior_spec <- NULL

both_draws <- bind_rows(prior_draws, post_draws)

both_long <- both_draws %>%
  pivot_longer(
    cols = all_of(params_to_plot),
    names_to = "parameter",
    values_to = "value"
  ) %>%
  mutate(parameter = factor(parameter, levels = params_to_plot,
                             labels = param_labels[params_to_plot]))

p_prior_post <- ggplot(both_long, aes(x = value, fill = source, color = source)) +
  geom_density(alpha = 0.25, linewidth = 0.6) +
  facet_wrap(~parameter, scales = "free", ncol = 2) +
  scale_fill_manual(values = c("Prior" = "#CC79A7", "Posterior" = "#0072B2"),
                    name = "") +
  scale_color_manual(values = c("Prior" = "#CC79A7", "Posterior" = "#0072B2"),
                     name = "") +
  labs(
    title = "Prior vs posterior: M1 baseline (weakly informative priors)",
    subtitle = "Data is informative where posterior concentrates away from prior",
    x = "Parameter value",
    y = "Density"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 9),
    plot.margin = margin(10, 10, 10, 10, "mm")
  )

ggsave("Output/diagnostics/prior_vs_posterior.pdf",
       plot = p_prior_post, width = 200, height = 250, units = "mm", dpi = 300)
cat("  Saved: Output/diagnostics/prior_vs_posterior.pdf\n")

# =============================================================================
# 9. Final interpretation
# =============================================================================

cat("\n======================================================\n")
cat("  PRIOR SENSITIVITY ANALYSIS COMPLETE\n")
cat("======================================================\n\n")

cat("Key outputs:\n")
cat("  1. Output/diagnostics/prior_sensitivity_all_params.pdf\n")
cat("     - Overlay of posteriors under 4 prior specifications\n")
cat("  2. Output/diagnostics/prior_sensitivity_<param>.pdf\n")
cat("     - Individual parameter comparison plots\n")
cat("  3. Output/diagnostics/prior_sensitivity_summary.csv\n")
cat("     - Numerical summary with sensitivity flags\n")
cat("  4. Output/diagnostics/prior_predictive_check.pdf\n")
cat("     - Prior predictive trajectories vs observed data\n")
cat("  5. Output/diagnostics/prior_vs_posterior.pdf\n")
cat("     - Prior vs posterior overlay (data informativeness)\n\n")

cat("Interpretation guide:\n")
cat("  - 'insensitive' (shift < 0.1 SD): posteriors unchanged by priors -> data-driven\n")
cat("  - 'mildly sensitive' (0.1-0.5 SD): minor shifts -> mostly data-driven\n")
cat("  - 'moderately sensitive' (0.5-1.0 SD): noticeable shifts -> some prior influence\n")
cat("  - 'SENSITIVE' (> 1.0 SD): substantial shifts -> prior-driven, needs attention\n")
