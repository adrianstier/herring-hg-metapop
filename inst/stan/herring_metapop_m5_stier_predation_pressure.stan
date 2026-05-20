// ============================================================================
// herring_metapop_m5_stier_predation_pressure.stan
//
// Stier-aligned predator branch:
//   1. Keeps the 11-section positive-only, zeros-ambiguous observation model.
//   2. Keeps the two-era surface/SCUBA q split.
//   3. Adds a lagged HG predation-pressure covariate from the predator repo.
//   4. Holds off on age/size structure and section-specific predator exposure.
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;

  vector[N_years] pdo;
  vector[N_years] pred_pressure;

  int<lower=2, upper=2> N_methods;
  array[N_years] int<lower=1, upper=2> q_idx;

  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_yr;
  array[N_catch] int<lower=1, upper=N_sites> catch_site;
  vector[N_catch] log_catch;

  int<lower=0, upper=1> prior_only;
}

transformed data {
  real sigma_catch = 0.01;
  real log_detection_threshold = log(0.1);

  int N_obs = 0;
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (Y_obs_flag[t, j] == 1) N_obs += 1;
    }
  }
}

parameters {
  real Umu;
  real pdocoef;
  real predcoef;
  real<lower=0> sigma_proc;
  real<lower=0> sigma_obs;

  vector[N_methods] log_q;
  vector[N_catch] Pc_logit;
  vector[N_sites] Z_init;
  matrix[N_years - 1, N_sites] delta_raw;
}

transformed parameters {
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;

  Pc_mat = rep_matrix(0.0, N_years, N_sites);
  for (k in 1:N_catch) {
    Pc_mat[catch_yr[k], catch_site[k]] = inv_logit(Pc_logit[k]);
  }

  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
  }

  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      Z[t, j] = X[t - 1, j] + Umu +
        pdocoef * pdo[t - 1] +
        predcoef * pred_pressure[t - 1] +
        sigma_proc * delta_raw[t - 1, j];
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  Umu ~ normal(0, 1);
  pdocoef ~ normal(0, 1);
  predcoef ~ normal(0, 1);
  sigma_proc ~ student_t(3, 0, 2.5);

  // Current DFO tonnes-scale q values should be estimated, not copied from
  // Stier's original spawn-habitat-index scale.
  sigma_obs ~ normal(0.75, 0.35);
  log_q ~ normal(0, 2.0);

  Pc_logit ~ normal(-1.386, 0.707);
  Z_init ~ normal(5, 10);
  to_vector(delta_raw) ~ std_normal();

  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }
    for (k in 1:N_catch) {
      log_catch[k] ~ normal(
        Z[catch_yr[k], catch_site[k]] + log_inv_logit(Pc_logit[k]),
        sigma_catch
      );
    }
  }
}

generated quantities {
  vector[N_obs] log_lik;
  matrix[N_years, N_sites] Y_rep;
  matrix[N_years, N_sites] biomass_pred;
  matrix[N_years, N_sites] fishing_rate;
  matrix[N_years, N_sites] pred_effect_total;
  matrix[N_years, N_sites] p_below_detection;
  array[N_years, N_sites] int<lower=0, upper=1> below_detection_rep;

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        real mu = X[t, j] + log_q[q_idx[t]];
        real y_rep_log = normal_rng(mu, sigma_obs);
        if (Y_obs_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = normal_lpdf(Y[t, j] | mu, sigma_obs);
        }
        Y_rep[t, j] = exp(y_rep_log);
        biomass_pred[t, j] = exp(Z[t, j]);
        fishing_rate[t, j] = Pc_mat[t, j];
        pred_effect_total[t, j] = predcoef * pred_pressure[t];
        p_below_detection[t, j] = normal_cdf(
          log_detection_threshold | mu, sigma_obs
        );
        below_detection_rep[t, j] = y_rep_log <= log_detection_threshold;
      }
    }
  }
}
