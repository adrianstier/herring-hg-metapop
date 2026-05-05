// ============================================================================
// herring_metapop_m5_v2.stan — Fixed M5: DD + combined predator (all bugs fixed)
//
// FIXES from original M5:
//   C3: Uses X[t-1,j] (post-fishing) instead of Z[t-1,j] (pre-fishing) in
//       the state equation.
//   M4: Unifies Gompertz parameterization with M3: (1+b)*X[t-1,j] + U[j]
//   C1: log_lik computed only for N_obs observed data points.
//   Student-t observation model (nu_obs)
//   Censored zeros: left-censored likelihood for surveyed zeros.
//   Informative sigma_obs prior: normal(0.5, 0.3)
//   Consistent phi prior: half-normal scaled to max_dist.
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;      // 1 = positive observation
  array[N_years, N_sites] int<lower=0, upper=1> Y_censored_flag;  // 1 = surveyed zero (left-censored)

  vector[N_years] pdo;
  vector[N_years] pred_combined;

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
  real U_mu;
  real<lower=0> sigma_U;
  vector[N_sites] U_raw;

  real pdocoef;
  real pred_coef;
  real<lower=-2, upper=0.5> b;

  vector<lower=0>[N_sites] sigma_site;
  real<lower=0> phi;

  real<lower=0> sigma_obs;
  real<lower=2> nu_obs;

  vector[N_methods] log_q;
  vector[N_catch] Pc_logit;

  matrix[N_years - 1, N_sites] epsilon_raw;
  vector[N_sites] Z_init;
}

transformed parameters {
  vector[N_sites] U;
  vector<lower=0,upper=1>[N_catch] Pc;
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;

  {
    matrix[N_sites, N_sites] Omega;
    matrix[N_sites, N_sites] Sigma;
    matrix[N_sites, N_sites] L_Sigma;

    for (i in 1:N_sites) {
      Omega[i, i] = 1.0;
      for (j in (i + 1):N_sites) {
        Omega[i, j] = exp(-dist_mat[i, j] / phi);
        Omega[j, i] = Omega[i, j];
      }
    }

    Sigma = quad_form_diag(Omega, sigma_site);
    for (i in 1:N_sites) Sigma[i, i] += 1e-8;
    L_Sigma = cholesky_decompose(Sigma);

    for (t in 1:(N_years - 1)) {
      epsilon[t] = (L_Sigma * epsilon_raw[t]')';
    }
  }

  U = U_mu + sigma_U * U_raw;
  Pc = inv_logit(Pc_logit);

  Pc_mat = rep_matrix(0.0, N_years, N_sites);
  for (k in 1:N_catch) {
    Pc_mat[catch_yr[k], catch_site[k]] = Pc[k];
  }

  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
  }

  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      Z[t, j] = (1 + b) * X[t - 1, j]
                + U[j]
                + pdocoef * pdo[t - 1]
                + pred_coef * pred_combined[t - 1]
                + epsilon[t - 1, j];
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  U_mu ~ normal(0, 1);
  sigma_U ~ student_t(3, 0, 1);
  U_raw ~ std_normal();
  pdocoef ~ normal(0, 1);
  pred_coef ~ normal(0, 0.5);
  b ~ normal(0, 0.5);
  sigma_site ~ student_t(3, 0, 2.5);
  phi ~ normal(0, max_dist / 3.0);
  to_vector(epsilon_raw) ~ std_normal();
  sigma_obs ~ normal(0.5, 0.3);
  nu_obs ~ gamma(2, 0.1);
  log_q ~ normal(0, 2);
  Pc_logit ~ normal(-1.386, 0.707);
  Z_init ~ normal(5, 10);

  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          target += student_t_lpdf(Y[t, j] | nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
        if (Y_censored_flag[t, j] == 1) {
          target += student_t_lcdf(log_detection_threshold | nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs);
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
  corr_matrix[N_sites] Omega;
  vector[N_years] pred_effect_total;
  vector[N_sites] X_equilibrium;
  array[N_sites] int<lower=0, upper=1> equilibrium_defined;

  for (i in 1:N_sites) {
    Omega[i, i] = 1.0;
    for (j in (i + 1):N_sites) {
      Omega[i, j] = exp(-dist_mat[i, j] / phi);
      Omega[j, i] = Omega[i, j];
    }
  }

  for (t in 1:N_years) pred_effect_total[t] = pred_coef * pred_combined[t];

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = student_t_lpdf(Y[t, j] | nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs);
          Y_rep[t, j] = exp(student_t_rng(nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs));
        } else {
          Y_rep[t, j] = 0.0;
        }
      }
    }
  }

  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      biomass_pred[t, j] = exp(Z[t, j]);
      fishing_rate[t, j] = Pc_mat[t, j];
    }
  }

  for (j in 1:N_sites) {
    if (b < -1e-6) {
      X_equilibrium[j] = -U[j] / b;
      equilibrium_defined[j] = 1;
    } else {
      X_equilibrium[j] = 0.0;
      equilibrium_defined[j] = 0;
    }
  }
}
