// ============================================================================
// herring_metapop_m3_v2.stan — Distance-decay + global Gompertz DD (v2)
//
// Fixes relative to v1:
//   C1: log_lik only for observed data (N_obs-length vector, no zeros)
//   Student-t observation model with estimated df (nu_obs)
//   Left-censored likelihood for surveyed zeros (Y_censored)
//   Informative sigma_obs prior: Normal(0.5, 0.3)
//   Consistent phi prior: half-normal scaled to study area (matches M2)
//   Shared sigma (not site-specific) to match M2 parameterization
//
// PROCESS MODEL:
//   Z[t,j] = (1 + b) * X[t-1,j] + U[j] + pdocoef * pdo[t-1] + eps[t-1,j]
//   eps[t,] ~ MVN(0, Sigma)
//   Sigma[i,j] = sigma^2 * exp(-phi * d[i,j])
//
// CATCH ADJUSTMENT:
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//
// OBSERVATION MODEL (Student-t):
//   Y[t,j] ~ Student_t(nu_obs, X[t,j] + log_q[q_idx[t]], sigma_obs)
//
// CENSORED ZEROS:
//   If Y_censored[t,j] == 1:
//     target += student_t_lcdf(log(0.1) | nu_obs, mu, sigma_obs)
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;      // 1 = positive observation
  array[N_years, N_sites] int<lower=0, upper=1> Y_censored_flag;  // 1 = surveyed zero (left-censored)

  vector[N_years] pdo;

  // Survey method index (1=surface, 2=transition, 3=dive)
  int<lower=2, upper=3> N_methods;
  array[N_years] int<lower=1, upper=3> q_idx;

  matrix[N_sites, N_sites] dist_mat;

  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_yr;
  array[N_catch] int<lower=1, upper=N_sites> catch_site;
  vector[N_catch] log_catch;

  real<lower=0> max_dist;

  int<lower=0, upper=1> prior_only;
}

transformed data {
  real sigma_catch = 0.01;
  real log_detection_threshold = log(0.1);

  // Count observed data points for correctly-sized log_lik
  int N_obs = 0;
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (Y_obs_flag[t, j] == 1) {
        N_obs += 1;
      }
    }
  }
}

parameters {
  real U_mu;
  real<lower=0> sigma_U;
  vector[N_sites] U_raw;

  real pdocoef;

  // Global Gompertz density dependence
  real<lower=-2, upper=0.5> b;

  // Process error: shared marginal SD + distance-decay
  real<lower=0> sigma;
  real<lower=0> phi;

  real<lower=0> sigma_obs;
  real<lower=2> nu_obs;  // Student-t degrees of freedom

  vector[N_methods] log_q;

  vector[N_catch] Pc_logit;

  matrix[N_years - 1, N_sites] epsilon_raw;

  vector[N_sites] Z_init;
}

transformed parameters {
  vector[N_sites] U;
  vector<lower=0, upper=1>[N_catch] Pc;
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;

  // Build distance-decay covariance matrix and Cholesky factor
  // Using shared sigma (not site-specific) to match M2 parameterization
  {
    matrix[N_sites, N_sites] Sigma;
    matrix[N_sites, N_sites] L_Sigma;

    for (i in 1:N_sites) {
      Sigma[i, i] = square(sigma) + 1e-8;
      for (j in (i + 1):N_sites) {
        Sigma[i, j] = square(sigma) * exp(-phi * dist_mat[i, j]);
        Sigma[j, i] = Sigma[i, j];
      }
    }

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

  // Initial conditions
  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
  }

  // State dynamics with global Gompertz DD
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      Z[t, j] = (1 + b) * X[t - 1, j]
                + U[j]
                + pdocoef * pdo[t - 1]
                + epsilon[t - 1, j];
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  // ========================================================================
  // PRIORS
  // ========================================================================

  U_mu ~ normal(0, 1);
  sigma_U ~ student_t(3, 0, 1);
  U_raw ~ std_normal();

  pdocoef ~ normal(0, 1);

  // Gompertz DD: Normal(0, 0.5) truncated to (-2, 0.5)
  b ~ normal(0, 0.5);

  // Process error SD
  sigma ~ student_t(3, 0, 2.5);

  // Distance-decay rate: half-normal scaled to study area (CONSISTENT with M2)
  phi ~ normal(0, 3.0 / max_dist);

  to_vector(epsilon_raw) ~ std_normal();

  // Informative observation error prior: ~30-50% survey CV
  sigma_obs ~ normal(0.5, 0.3);

  // Student-t df prior
  nu_obs ~ gamma(2, 0.1);

  log_q ~ normal(0, 2);

  Pc_logit ~ normal(-1.386, 0.707);

  Z_init ~ normal(5, 10);

  // ========================================================================
  // LIKELIHOOD
  // ========================================================================

  if (prior_only == 0) {
    // Spawn index observations (Student-t)
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          target += student_t_lpdf(Y[t, j] | nu_obs,
                                    X[t, j] + log_q[q_idx[t]],
                                    sigma_obs);
        }
        // Censored zeros: surveyed but zero observed
        if (Y_censored_flag[t, j] == 1) {
          target += student_t_lcdf(log_detection_threshold | nu_obs,
                                    X[t, j] + log_q[q_idx[t]],
                                    sigma_obs);
        }
      }
    }

    // Catch observations
    for (k in 1:N_catch) {
      log_catch[k] ~ normal(Z[catch_yr[k], catch_site[k]]
                              + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  // log_lik only for observed data points (N_obs-length vector)
  vector[N_obs] log_lik;

  matrix[N_years, N_sites] biomass_pred;
  matrix[N_years, N_sites] fishing_rate;
  matrix[N_years, N_sites] Y_rep;

  corr_matrix[N_sites] Omega;

  // Equilibrium biomass (Gompertz)
  vector[N_sites] X_equilibrium;
  array[N_sites] int<lower=0, upper=1> equilibrium_defined;

  // Reconstruct Omega
  for (i in 1:N_sites) {
    Omega[i, i] = 1.0;
    for (j in (i + 1):N_sites) {
      Omega[i, j] = exp(-phi * dist_mat[i, j]);
      Omega[j, i] = Omega[i, j];
    }
  }

  // Log-likelihood and posterior predictive (observed only)
  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = student_t_lpdf(Y[t, j] | nu_obs,
                                         X[t, j] + log_q[q_idx[t]],
                                         sigma_obs);
          Y_rep[t, j] = exp(student_t_rng(nu_obs,
                                       X[t, j] + log_q[q_idx[t]],
                                       sigma_obs));
        } else {
          Y_rep[t, j] = 0.0;
        }
      }
    }
  }

  // Predicted biomass and fishing rates
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      biomass_pred[t, j] = exp(Z[t, j]);
      fishing_rate[t, j] = Pc_mat[t, j];
    }
  }

  // Equilibrium log-biomass per site (only interpretable when b < 0)
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
