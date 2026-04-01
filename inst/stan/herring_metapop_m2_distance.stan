// ============================================================================
// herring_metapop_m2_distance.stan — Distance-decay spatial correlation model
//
// Replaces the free LKJ correlation matrix (55 free parameters) with a
// distance-decay function: rho(i,j) = exp(-d(i,j) / phi), where d is the
// effective distance matrix (passed as data) and phi is an estimated range
// parameter. This reduces the correlation structure to 1 free parameter.
//
// NO density dependence — tests spatial structure alone.
//
// PROCESS MODEL:
//   Z[t,j] = X[t-1,j] + U[j] + pdocoef * pdo[t-1] + epsilon[t-1,j]
//
//   where epsilon[t,] ~ MVN(0, Sigma)
//         Sigma = diag(sigma_site) * Omega * diag(sigma_site)
//         Omega[i,j] = exp(-D[i,j] / phi)
//         D = effective distance matrix (data)
//         phi = spatial range parameter (estimated)
//
//   U[j] ~ Normal(U_mu, sigma_U)  (non-centered)
//
// CATCH ADJUSTMENT:
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//
// OBSERVATION MODEL:
//   Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
//
// CATCH LIKELIHOOD:
//   log_catch[k] ~ Normal(Z[row_k, col_k] + log_inv_logit(Pc_logit[k]), sigma_catch)
// ============================================================================

data {
  int<lower=1> N_years;                    // number of years (T)
  int<lower=1> N_sites;                    // number of spawning sections (J = 11)
  matrix[N_years, N_sites] Y;             // observed log spawn index
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs; // 1 if observed, 0 if missing

  vector[N_years] pdo;                     // spring PDO index

  array[N_years] int<lower=1, upper=2> q_idx; // survey method index: 1=surface, 2=dive

  // Effective distance matrix (N_sites x N_sites, symmetric, diagonal = 0)
  matrix[N_sites, N_sites] dist_mat;

  // Catch indexing
  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_row;
  array[N_catch] int<lower=1, upper=N_sites> catch_col;
  vector[N_catch] log_catch;

  // Flag for prior predictive simulation (1 = skip likelihood)
  int<lower=0, upper=1> prior_only;
}

transformed data {
  real sigma_catch = 0.01;                 // fixed tight catch SD
}

parameters {
  // -- Growth rate (hierarchical across sites) --
  real U_mu;                               // hyper-mean growth rate
  real<lower=0> sigma_U;                   // hyper-SD for site-level growth
  vector[N_sites] U_raw;                   // non-centered random effects

  // -- Environmental coefficient --
  real pdocoef;                            // PDO effect

  // -- Process error: distance-decay spatial correlation --
  vector<lower=0>[N_sites] sigma_site;    // site-specific process error SDs
  real<lower=0> phi;                       // spatial range parameter (distance-decay)

  // -- Observation error --
  real<lower=0> sigma_obs;

  // -- Catchability --
  vector[2] log_q;

  // -- Proportion catch (logit scale) --
  vector[N_catch] Pc_logit;

  // -- Process errors (standardized for non-centered MVN) --
  matrix[N_years - 1, N_sites] epsilon_raw; // N(0,1) draws for transitions 2..T

  // -- Initial states --
  vector[N_sites] Z_init;
}

transformed parameters {
  // -- Derived quantities --
  vector[N_sites] U;                       // site-level growth rates
  vector<lower=0,upper=1>[N_catch] Pc;
  matrix[N_years, N_sites] Z;             // pre-fishing log biomass
  matrix[N_years, N_sites] X;             // post-fishing log biomass
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;   // actual process errors (MVN)

  // -- Build distance-decay correlation matrix and Cholesky factor --
  // Omega[i,j] = exp(-D[i,j] / phi): exponential decay with range phi
  // Larger phi = more spatial correlation; smaller phi = more independent
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

    // Build full covariance: Sigma = diag(sigma_site) * Omega * diag(sigma_site)
    Sigma = quad_form_diag(Omega, sigma_site);

    // Cholesky decompose for efficient MVN sampling
    L_Sigma = cholesky_decompose(Sigma);

    // Transform standardized errors to correlated errors
    for (t in 1:(N_years - 1)) {
      epsilon[t] = (L_Sigma * epsilon_raw[t]')';
    }
  }

  // -- Non-centered site growth rates --
  U = U_mu + sigma_U * U_raw;

  // -- Transform Pc --
  Pc = inv_logit(Pc_logit);

  // -- Build Pc matrix --
  Pc_mat = rep_matrix(0.0, N_years, N_sites);
  for (k in 1:N_catch) {
    Pc_mat[catch_row[k], catch_col[k]] = Pc[k];
  }

  // -- Initial conditions (t = 1) --
  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
  }

  // -- State dynamics (t = 2, ..., T) --
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      Z[t, j] = X[t - 1, j]
                + U[j]                               // site-specific growth
                + pdocoef * pdo[t - 1]               // PDO effect
                + epsilon[t - 1, j];                 // spatially correlated process error
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  // ========================================================================
  // PRIORS
  // ========================================================================

  // -- Hierarchical growth rate --
  U_mu ~ normal(0, 1);
  sigma_U ~ student_t(3, 0, 1);
  U_raw ~ std_normal();

  // -- Environmental effect --
  pdocoef ~ normal(0, 1);

  // -- Process error SDs: half-t(3, 0, 2.5) --
  sigma_site ~ student_t(3, 0, 2.5);

  // -- Spatial range parameter --
  // inv_gamma(5, 5): mode = 5/6 ~ 0.83 (in units of distance/scale),
  // weakly informative with finite variance. Must be > 0.
  // In practice, phi should be on the order of inter-site distances.
  // We pass distances in km (divided by 1000 in R), so phi ~ 10-200 km is sensible.
  phi ~ inv_gamma(5, 5);

  // -- Process errors (standardized) --
  to_vector(epsilon_raw) ~ std_normal();

  // -- Observation error SD --
  sigma_obs ~ student_t(3, 0, 2.5);

  // -- Catchability --
  log_q ~ normal(0, 2);

  // -- Proportion catch --
  Pc_logit ~ normal(-1.386, 0.707);

  // -- Initial states --
  Z_init ~ normal(5, 10);

  // ========================================================================
  // LIKELIHOOD
  // ========================================================================

  if (prior_only == 0) {
    // Spawn index observations
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs[t, j] == 1) {
          Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }

    // Catch observations
    for (k in 1:N_catch) {
      log_catch[k] ~ normal(Z[catch_row[k], catch_col[k]] + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  // -- Log-likelihood for LOO-CV --
  vector[N_years * N_sites] log_lik;

  // -- Predicted biomass (natural scale) --
  matrix[N_years, N_sites] biomass_pred;

  // -- Fishing rate --
  matrix[N_years, N_sites] fishing_rate;

  // -- Posterior predictive replications --
  matrix[N_years, N_sites] Y_rep;

  // -- Reconstructed correlation matrix (for reporting) --
  corr_matrix[N_sites] Omega;

  // Reconstruct Omega from distance-decay
  for (i in 1:N_sites) {
    Omega[i, i] = 1.0;
    for (j in (i + 1):N_sites) {
      Omega[i, j] = exp(-dist_mat[i, j] / phi);
      Omega[j, i] = Omega[i, j];
    }
  }

  // Log-likelihood and posterior predictive
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

  // Predicted biomass and fishing rates
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      biomass_pred[t, j] = exp(Z[t, j]);
      fishing_rate[t, j] = Pc_mat[t, j];
    }
  }
}
