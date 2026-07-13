// ============================================================================
// herring_metapop_bc_m1.stan — Hierarchical M1 baseline (block-diagonal Σ)
// analysis/05_bc_coastwide
//
// State: log-biomass per section per year, z[s, y]
// Hierarchy: section -> stock_area
// Σ block-diagonal: within-area independent (this baseline); distance-decay
// covariance can be layered in a follow-on variant if needed.
// Observation: positive spawn-index tonnes only (zeros = ambiguous)
// ============================================================================

data {
  int<lower=1> N_sections;
  int<lower=1> N_years;
  int<lower=1> N_stock_areas;
  array[N_sections] int<lower=1, upper=N_stock_areas> stock_area_of;

  array[N_sections, N_years] real<lower=0> y;          // 0 marks unobserved
  array[N_sections, N_years] int<lower=0, upper=1> obs_mask;

  // Block-diagonal distance entries in stock-area order
  int<lower=0> N_D;                                    // total entries
  vector[N_D] D_blocks;
  array[N_stock_areas] int<lower=1> block_starts;
  array[N_stock_areas] int<lower=0> block_sizes;
}

transformed data {
  // Compute log-y where observed (used in likelihood); guard zeros
  array[N_sections, N_years] real log_y;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      log_y[s, t] = obs_mask[s, t] == 1 ? log(y[s, t]) : 0.0;
}

parameters {
  vector[N_stock_areas] r_area;          // stock-area intrinsic growth
  vector<lower=0>[N_stock_areas] sigma_area;  // process sd
  vector<lower=0>[N_stock_areas] range_area;  // distance-decay range (km)
  real<lower=0> sigma_obs;               // log-normal observation sd
  array[N_sections, N_years] real z;     // latent log-biomass
  vector[N_sections] z0;                 // initial state
}

model {
  // Priors
  r_area ~ normal(0, 0.5);
  sigma_area ~ normal(0, 1);
  range_area ~ normal(50, 50);           // ~50 km characteristic range
  sigma_obs ~ normal(0, 1);
  z0 ~ normal(log(100), 2);              // ~100 tonnes section-level prior

  // Initial year
  for (s in 1:N_sections) z[s, 1] ~ normal(z0[s], sigma_area[stock_area_of[s]]);

  // Process: section-level random walk + stock-area intrinsic growth
  for (s in 1:N_sections)
    for (t in 2:N_years)
      z[s, t] ~ normal(z[s, t-1] + r_area[stock_area_of[s]],
                       sigma_area[stock_area_of[s]]);

  // Observation
  for (s in 1:N_sections)
    for (t in 1:N_years)
      if (obs_mask[s, t] == 1)
        log_y[s, t] ~ normal(z[s, t], sigma_obs);
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
