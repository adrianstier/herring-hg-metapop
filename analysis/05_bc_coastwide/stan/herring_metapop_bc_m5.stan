// ============================================================================
// herring_metapop_bc_m5.stan — M3 + predator covariates (year-by-stock-area)
// analysis/05_bc_coastwide
//
// Adds -gamma[p, a] * predator_covs[a, t, p] term per predator species.
// Predator covariates are year-by-stock-area per provenance notes.
// ============================================================================

data {
  int<lower=1> N_sections;
  int<lower=1> N_years;
  int<lower=1> N_stock_areas;
  int<lower=0> N_pred_covs;
  array[N_sections] int<lower=1, upper=N_stock_areas> stock_area_of;
  array[N_sections, N_years] real<lower=0> y;
  array[N_sections, N_years] int<lower=0, upper=1> obs_mask;
  int<lower=0> N_D;
  vector[N_D] D_blocks;
  array[N_stock_areas] int<lower=1> block_starts;
  array[N_stock_areas] int<lower=0> block_sizes;
  array[N_stock_areas, N_years, N_pred_covs] real predator_covs;
}

transformed data {
  array[N_sections, N_years] real log_y;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      log_y[s, t] = obs_mask[s, t] == 1 ? log(y[s, t]) : 0.0;
}

parameters {
  vector[N_stock_areas] r_area;
  vector<lower=0, upper=1>[N_stock_areas] beta_area;
  vector[N_stock_areas] K_area;
  vector<lower=0>[N_stock_areas] sigma_area;
  vector<lower=0>[N_stock_areas] range_area;
  real<lower=0> sigma_obs;
  matrix[N_pred_covs, N_stock_areas] gamma_pred;   // predator effect per species per area
  array[N_sections, N_years] real z;
  vector[N_sections] z0;
}

model {
  r_area ~ normal(0, 0.5);
  beta_area ~ beta(2, 8);
  K_area ~ normal(log(500), 1);
  sigma_area ~ normal(0, 1);
  range_area ~ normal(50, 50);
  sigma_obs ~ normal(0, 1);
  z0 ~ normal(log(100), 2);
  to_vector(gamma_pred) ~ normal(0, 0.5);  // weakly informative around no-effect

  for (s in 1:N_sections) z[s, 1] ~ normal(z0[s], sigma_area[stock_area_of[s]]);
  for (s in 1:N_sections) {
    int a = stock_area_of[s];
    for (t in 2:N_years) {
      real pred_term = 0;
      for (p in 1:N_pred_covs)
        pred_term += gamma_pred[p, a] * predator_covs[a, t, p];
      real mu = z[s, t-1] + r_area[a]
              - beta_area[a] * (z[s, t-1] - K_area[a])
              - pred_term;
      z[s, t] ~ normal(mu, sigma_area[a]);
    }
  }
  for (s in 1:N_sections)
    for (t in 1:N_years)
      if (obs_mask[s, t] == 1) log_y[s, t] ~ normal(z[s, t], sigma_obs);
}

generated quantities {
  array[N_sections, N_years] real y_rep;
  array[N_sections, N_years] real log_lik;
  for (s in 1:N_sections) {
    for (t in 1:N_years) {
      y_rep[s, t] = lognormal_rng(z[s, t], sigma_obs);
      log_lik[s, t] = obs_mask[s, t] == 1
        ? normal_lpdf(log_y[s, t] | z[s, t], sigma_obs) : 0.0;
    }
  }
}
