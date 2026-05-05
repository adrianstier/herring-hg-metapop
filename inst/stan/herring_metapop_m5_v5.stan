// ============================================================================
// herring_metapop_m5_v5.stan — DD + predators + lagged timing / habitat covariates
//
// IMPROVEMENTS from v2 (borrowed from Okamoto et al. 2020):
//   1. Tight dive-method prior used in the Okamoto empirical model: Normal(0, 0.05)
//   2. Site-specific Gompertz b hierarchical: b[j] ~ Normal(mu_b, sigma_b)
//   3. Site-specific observation error: sigma_obs[j]
//   4. Distance-decay process error (phi)
//   5. Combined predator effect (pred_coef)
//   6. Lagged regional timing / habitat covariates with regularizing priors
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;
  array[N_years, N_sites] int<lower=0, upper=1> Y_censored_flag;

  vector[N_years] pdo;
  vector[N_years] pred_combined;
  int<lower=1> K_cov;
  matrix[N_years, K_cov] spawn_cov;

  int<lower=2, upper=3> N_methods;
  array[N_years] int<lower=1, upper=3> q_idx;

  matrix[N_sites, N_sites] dist_mat;
  real<lower=0> max_dist;

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
  // Growth rate
  real U_mu;
  real<lower=0> sigma_U;
  vector[N_sites] U_raw;

  real pdocoef;
  real pred_coef;

  // Hierarchical Site-specific Gompertz b
  real mu_b;
  real<lower=0> sigma_b;
  vector[N_sites] b_raw;
  vector[K_cov] beta_cov;

  // Process error parameters
  real<lower=0> sigma_proc;
  real<lower=0> phi;

  // Site-specific Observation error
  real mu_sigma_obs;
  real<lower=0> tau_sigma_obs;
  vector<lower=0>[N_sites] sigma_obs;
  real<lower=2> nu_obs;

  // Catchability (per method)
  vector[N_methods] log_q;

  vector[N_catch] Pc_logit;
  matrix[N_years - 1, N_sites] epsilon_raw;
  vector[N_sites] Z_init;
}

transformed parameters {
  vector[N_sites] U;
  vector[N_sites] b;
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;

  U = U_mu + sigma_U * U_raw;
  b = mu_b + sigma_b * b_raw;

  {
    matrix[N_sites, N_sites] Omega;
    matrix[N_sites, N_sites] Sigma;
    matrix[N_sites, N_sites] L_Sigma;

    for (i in 1:N_sites) {
      Omega[i, i] = 1.0;
      if (i < N_sites) {
        for (j in (i + 1):N_sites) {
          Omega[i, j] = exp(-dist_mat[i, j] / phi);
          Omega[j, i] = Omega[i, j];
        }
      }
    }

    Sigma = quad_form_diag(Omega, rep_vector(sigma_proc, N_sites));
    for (i in 1:N_sites) Sigma[i, i] += 1e-8;
    L_Sigma = cholesky_decompose(Sigma);

    for (t in 1:(N_years - 1)) {
      epsilon[t] = (L_Sigma * epsilon_raw[t]')';
    }
  }

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
      Z[t, j] = (1 + b[j]) * X[t - 1, j]
                + U[j]
                + pdocoef * pdo[t - 1]
                + pred_coef * pred_combined[t - 1]
                + spawn_cov[t - 1] * beta_cov
                + epsilon[t - 1, j];
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  // Priors
  U_mu ~ normal(0, 1);
  sigma_U ~ student_t(3, 0, 1);
  U_raw ~ std_normal();
  pdocoef ~ normal(0, 1);
  pred_coef ~ normal(0, 0.5);

  mu_b ~ normal(0, 0.5);
  sigma_b ~ student_t(3, 0, 0.5);
  b_raw ~ std_normal();
  beta_cov ~ normal(0, 0.3);

  sigma_proc ~ student_t(3, 0, 2.5);
  phi ~ normal(0, max_dist / 3.0);
  to_vector(epsilon_raw) ~ std_normal();

  // Site-specific sigma_obs hierarchical
  mu_sigma_obs ~ normal(0.5, 0.2);
  tau_sigma_obs ~ student_t(3, 0, 0.2);
  sigma_obs ~ normal(mu_sigma_obs, tau_sigma_obs);
  nu_obs ~ gamma(2, 0.1);

  // Tight survey-bias prior used in the Okamoto empirical model
  log_q[3] ~ normal(0, 0.05);
  log_q[1] ~ normal(0, 2.0);
  log_q[2] ~ normal(0, 2.0);

  Pc_logit ~ normal(-1.386, 0.707);
  Z_init ~ normal(5, 10);

  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          target += student_t_lpdf(Y[t, j] | nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs[j]);
        }
        if (Y_censored_flag[t, j] == 1) {
          target += student_t_lcdf(log_detection_threshold | nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs[j]);
        }
      }
    }
    for (k in 1:N_catch) {
      log_catch[k] ~ normal(Z[catch_yr[k], catch_site[k]] + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  vector[N_obs] log_lik;
  matrix[N_years, N_sites] biomass_pred;
  matrix[N_years, N_sites] fishing_rate;
  matrix[N_years, N_sites] Y_rep;
  matrix[N_years, N_sites] p_below_detection;
  array[N_years, N_sites] int<lower=0, upper=1> below_detection_rep;
  vector[N_years] pred_effect_total;

  for (t in 1:N_years) pred_effect_total[t] = pred_coef * pred_combined[t];

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        real mu = X[t, j] + log_q[q_idx[t]];
        real y_rep_log = student_t_rng(nu_obs, mu, sigma_obs[j]);

        if (Y_obs_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = student_t_lpdf(Y[t, j] | nu_obs, mu, sigma_obs[j]);
        }

        Y_rep[t, j] = exp(y_rep_log);
        p_below_detection[t, j] = student_t_cdf(
          log_detection_threshold | nu_obs, mu, sigma_obs[j]
        );
        below_detection_rep[t, j] = y_rep_log <= log_detection_threshold;
        biomass_pred[t, j] = exp(Z[t, j]);
        fishing_rate[t, j] = Pc_mat[t, j];
      }
    }
  }
}
