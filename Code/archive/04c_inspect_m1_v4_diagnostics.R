library(rstan)

fit <- readRDS("Data/processed/m1_v4_fit.rds")
loo_obj <- readRDS("Output/posteriors/loo_m1_v4.rds")
load("Data/processed/jags_model_inputs_v2.RData")

cat("=== Parameter Summary ===\n")
s <- summary(fit, pars = c("Umu", "pdocoef", "mu_sigma_obs", "tau_sigma_obs",
                           "nu_obs", "alpha_det", "beta_det", "log_q"),
             probs = c(0.025, 0.5, 0.975))$summary
print(s[, c("mean", "sd", "2.5%", "50%", "97.5%", "Rhat", "n_eff")])

cat("\n=== Sampler By Chain ===\n")
sp <- rstan::get_sampler_params(fit, inc_warmup = FALSE)
print(data.frame(
  chain = seq_along(sp),
  treedepth_hits = sapply(sp, function(x) sum(x[, "treedepth__"] >= 15)),
  divergences = sapply(sp, function(x) sum(x[, "divergent__"])),
  stepsize = sapply(sp, function(x) unique(x[, "stepsize__"])[1])
))

cat("\n=== High Pareto-k Cells ===\n")
idx <- which(loo_obj$diagnostics$pareto_k > 0.7)
obs_idx <- which(jags_data$Y_obs == 1 | jags_data$Y_censored == 1, arr.ind = TRUE)
print(data.frame(
  log_lik_idx = idx,
  year = jags_data$years[obs_idx[idx, 1]],
  site = colnames(jags_data$Y)[obs_idx[idx, 2]],
  y_obs = jags_data$Y_obs[obs_idx[idx]],
  y_censored = jags_data$Y_censored[obs_idx[idx]],
  Y = jags_data$Y[obs_idx[idx]],
  pareto_k = loo_obj$diagnostics$pareto_k[idx]
))
