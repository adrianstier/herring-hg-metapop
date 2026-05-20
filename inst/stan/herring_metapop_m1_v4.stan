// ============================================================================
// herring_metapop_m1_v4.stan — M1v4: Stable baseline + explicit detection layer
//
// IMPROVEMENTS from v3:
//   1. Keeps the sampler-stable M1 baseline process structure.
//   2. Adds a biomass-linked detection model for surveyed zeros.
//   3. Uses method-specific detection intercepts.
//   4. Conditions positive observations on clearing the survey threshold.
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;
  array[N_years, N_sites] int<lower=0, upper=1> Y_censored_flag;

  vector[N_years] pdo;

  int<lower=2, upper=3> N_methods;
  array[N_years] int<lower=1, upper=3> q_idx;

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
  int N_surveyed = 0;
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (Y_obs_flag[t, j] == 1) N_obs += 1;
      if (Y_obs_flag[t, j] == 1 || Y_censored_flag[t, j] == 1) N_surveyed += 1;
    }
  }
}

parameters {
  real Umu;
  real pdocoef;
  real<lower=0> sigma_proc;

  // Hierarchical Site-specific Observation error
  real mu_sigma_obs;
  real<lower=0> tau_sigma_obs;
  vector<lower=0>[N_sites] sigma_obs;
  real<lower=2> nu_obs;

  vector[N_methods] alpha_det;
  real<lower=0> beta_det;

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
      Z[t, j] = X[t - 1, j] + Umu + pdocoef * pdo[t - 1] + sigma_proc * delta_raw[t - 1, j];
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  Umu ~ normal(0, 1);
  pdocoef ~ normal(0, 1);
  sigma_proc ~ student_t(3, 0, 2.5);

  mu_sigma_obs ~ normal(0.5, 0.2);
  tau_sigma_obs ~ student_t(3, 0, 0.2);
  sigma_obs ~ normal(mu_sigma_obs, tau_sigma_obs);
  nu_obs ~ gamma(2, 0.1);

  alpha_det ~ normal(-0.5, 1.0);
  beta_det ~ normal(1.0, 0.5);

  log_q[3] ~ normal(0, 0.05);
  log_q[1] ~ normal(0, 2.0);
  log_q[2] ~ normal(0, 2.0);

  Pc_logit ~ normal(-1.386, 0.707);
  Z_init ~ normal(5, 10);
  to_vector(delta_raw) ~ std_normal();

  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        real mu = X[t, j] + log_q[q_idx[t]];
        real p_detect = inv_logit(alpha_det[q_idx[t]] + beta_det * (mu - log_detection_threshold));
        if (Y_obs_flag[t, j] == 1) {
          target += bernoulli_lpmf(1 | p_detect);
          target += student_t_lpdf(Y[t, j] | nu_obs, mu, sigma_obs[j]) -
            student_t_lccdf(log_detection_threshold | nu_obs, mu, sigma_obs[j]);
        }
        if (Y_censored_flag[t, j] == 1) {
          target += bernoulli_lpmf(0 | p_detect);
        }
      }
    }
    for (k in 1:N_catch) {
      log_catch[k] ~ normal(Z[catch_yr[k], catch_site[k]] + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  vector[N_surveyed] log_lik;
  matrix[N_years, N_sites] Y_rep;
  matrix[N_years, N_sites] biomass_pred;
  matrix[N_years, N_sites] fishing_rate;
  matrix[N_years, N_sites] detection_prob;
  array[N_years, N_sites] int<lower=0, upper=1> detected_rep;

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        real mu = X[t, j] + log_q[q_idx[t]];
        real p_detect = inv_logit(alpha_det[q_idx[t]] + beta_det * (mu - log_detection_threshold));
        int detected = bernoulli_rng(p_detect);
        if (Y_obs_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = bernoulli_lpmf(1 | p_detect) +
            student_t_lpdf(Y[t, j] | nu_obs, mu, sigma_obs[j]) -
            student_t_lccdf(log_detection_threshold | nu_obs, mu, sigma_obs[j]);
        }
        if (Y_censored_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = bernoulli_lpmf(0 | p_detect);
        }
        if (detected == 1) {
          real y_rep_log = student_t_rng(nu_obs, mu, sigma_obs[j]);
          while (y_rep_log <= log_detection_threshold) {
            y_rep_log = student_t_rng(nu_obs, mu, sigma_obs[j]);
          }
          Y_rep[t, j] = exp(y_rep_log);
        } else {
          Y_rep[t, j] = 0.0;
        }
        biomass_pred[t, j] = exp(Z[t, j]);
        fishing_rate[t, j] = Pc_mat[t, j];
        detection_prob[t, j] = p_detect;
        detected_rep[t, j] = detected;
      }
    }
  }
}
