// ============================================================================
// herring_metapop_m5_predators.stan — Distance-decay + site DD + predators
//
// Extends m4 with predator covariates (whales, Steller sea lions, harbour seals).
// Predator data may not be available for all years, so we use a predator
// observation mask to only include predator effects where data exist.
//
// PROCESS MODEL:
//   Z[t,j] = Z[t-1,j] + U[j] + beta[j] * (Z[t-1,j] - K_log[j])
//            + pdocoef * pdo[t-1]
//            + whale_coef * whale[t-1] * whale_obs[t-1]
//            + ssl_coef * ssl[t-1,j] * pred_obs[t-1]
//            + seal_coef * seal[t-1,j] * pred_obs[t-1]
//            + epsilon[t-1,j]
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//
//   pred_obs[t] = 1 if predator data available at time t, 0 otherwise
//   whale_obs[t] = 1 if whale data available at time t, 0 otherwise
//   When obs = 0, the covariate contribution is zeroed out.
//
// SPATIAL CORRELATION:
//   epsilon[t,] ~ MVN(0, Sigma)
//   Omega[i,j] = exp(-D[i,j] / phi)
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs;

  vector[N_years] pdo;

  // Predator indices
  vector[N_years] whale;                   // humpback whale index (region-level)
  matrix[N_years, N_sites] ssl;           // Steller sea lion index (site-level)
  matrix[N_years, N_sites] seal;          // harbour seal index (site-level)

  // Predator observation masks (1 = data available, 0 = missing/NA)
  array[N_years] int<lower=0, upper=1> whale_obs;  // whale data availability
  array[N_years] int<lower=0, upper=1> pred_obs;   // ssl/seal data availability

  array[N_years] int<lower=1, upper=2> q_idx;

  // Effective distance matrix
  matrix[N_sites, N_sites] dist_mat;

  // Catch indexing
  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_row;
  array[N_catch] int<lower=1, upper=N_sites> catch_col;
  vector[N_catch] log_catch;

  // Flag for prior predictive simulation
  int<lower=0, upper=1> prior_only;
}

transformed data {
  real sigma_catch = 0.01;
}

parameters {
  // -- Growth rate (hierarchical) --
  real U_mu;
  real<lower=0> sigma_U;
  vector[N_sites] U_raw;

  // -- Environmental coefficient --
  real pdocoef;

  // -- Predator coefficients --
  real whale_coef;
  real ssl_coef;
  real seal_coef;

  // -- Site-specific Gompertz DD (hierarchical, non-centered) --
  real<upper=0> beta_mu;
  real<lower=0> sigma_beta;
  vector[N_sites] beta_raw;

  real K_mu;
  real<lower=0> sigma_K;
  vector[N_sites] K_raw;

  // -- Process error: distance-decay spatial correlation --
  vector<lower=0>[N_sites] sigma_site;
  real<lower=0> phi;

  // -- Observation error --
  real<lower=0> sigma_obs;

  // -- Catchability --
  vector[2] log_q;

  // -- Proportion catch (logit scale) --
  vector[N_catch] Pc_logit;

  // -- Process errors (standardized) --
  matrix[N_years - 1, N_sites] epsilon_raw;

  // -- Initial states --
  vector[N_sites] Z_init;
}

transformed parameters {
  vector[N_sites] U;
  vector<upper=0>[N_sites] beta;
  vector[N_sites] K_log;
  vector<lower=0,upper=1>[N_catch] Pc;
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;

  // -- Build distance-decay covariance and transform errors --
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
    L_Sigma = cholesky_decompose(Sigma);

    for (t in 1:(N_years - 1)) {
      epsilon[t] = (L_Sigma * epsilon_raw[t]')';
    }
  }

  // -- Non-centered site growth rates --
  U = U_mu + sigma_U * U_raw;

  // -- Non-centered site-specific DD --
  for (j in 1:N_sites) {
    beta[j] = fmin(beta_mu + sigma_beta * beta_raw[j], -1e-8);
  }
  K_log = K_mu + sigma_K * K_raw;

  // -- Transform Pc --
  Pc = inv_logit(Pc_logit);

  // -- Build Pc matrix --
  Pc_mat = rep_matrix(0.0, N_years, N_sites);
  for (k in 1:N_catch) {
    Pc_mat[catch_row[k], catch_col[k]] = Pc[k];
  }

  // -- Initial conditions --
  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
  }

  // -- State dynamics with DD + predator covariates --
  // Predator masks ensure covariates only contribute when data exist.
  // When whale_obs[t-1] = 0 or pred_obs[t-1] = 0, those terms vanish.
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      Z[t, j] = Z[t - 1, j]
                + U[j]
                + beta[j] * (Z[t - 1, j] - K_log[j])
                + pdocoef * pdo[t - 1]
                + whale_coef * whale[t - 1] * whale_obs[t - 1]
                + ssl_coef * ssl[t - 1, j] * pred_obs[t - 1]
                + seal_coef * seal[t - 1, j] * pred_obs[t - 1]
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

  // Predator effects: weakly informative, centered at zero
  whale_coef ~ normal(0, 1);
  ssl_coef ~ normal(0, 1);
  seal_coef ~ normal(0, 1);

  // Hierarchical DD
  beta_mu ~ normal(-0.3, 0.3);
  sigma_beta ~ student_t(3, 0, 0.5);
  beta_raw ~ std_normal();

  K_mu ~ normal(10, 3);
  sigma_K ~ student_t(3, 0, 2.5);
  K_raw ~ std_normal();

  // Process error
  sigma_site ~ student_t(3, 0, 2.5);
  phi ~ inv_gamma(5, 5);
  to_vector(epsilon_raw) ~ std_normal();

  // Observation error
  sigma_obs ~ student_t(3, 0, 2.5);

  // Catchability
  log_q ~ normal(0, 2);

  // Proportion catch
  Pc_logit ~ normal(-1.386, 0.707);

  // Initial states
  Z_init ~ normal(5, 10);

  // ========================================================================
  // LIKELIHOOD
  // ========================================================================

  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs[t, j] == 1) {
          Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }

    for (k in 1:N_catch) {
      log_catch[k] ~ normal(Z[catch_row[k], catch_col[k]] + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  vector[N_years * N_sites] log_lik;
  matrix[N_years, N_sites] biomass_pred;
  matrix[N_years, N_sites] fishing_rate;
  matrix[N_years, N_sites] Y_rep;
  corr_matrix[N_sites] Omega;

  for (i in 1:N_sites) {
    Omega[i, i] = 1.0;
    for (j in (i + 1):N_sites) {
      Omega[i, j] = exp(-dist_mat[i, j] / phi);
      Omega[j, i] = Omega[i, j];
    }
  }

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        idx += 1;
        if (Y_obs[t, j] == 1) {
          log_lik[idx] = normal_lpdf(Y[t, j] | X[t, j] + log_q[q_idx[t]], sigma_obs);
          Y_rep[t, j] = normal_rng(X[t, j] + log_q[q_idx[t]], sigma_obs);
        } else {
          log_lik[idx] = 0.0;
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
}
