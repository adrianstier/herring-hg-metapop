// ============================================================================
// herring_metapop_m2_distance.stan — Distance-decay spatial correlation model
//
// Model M2: replaces the independent diagonal-equal process variance (M1)
// with a distance-decay spatial correlation structure.
//
// READER GUIDE:
//   Compare this file directly to `herring_metapop_v1.stan`.
//   The main conceptual change is in how process error covariance is built
//   from `dist_mat` and `phi`, not in the observation or catch layers.
//
// KEY DIFFERENCE FROM M1:
//   M1: delta[t,j] ~ Normal(0, sigma^2)   independently
//   M2: delta[t, ]  ~ MVN(0, Sigma)
//        where Sigma[i,j] = sigma^2 * exp(-phi * d[i,j])
//
// This encodes the expectation that nearby spawning sites share correlated
// process noise (e.g., common environmental drivers), with correlation
// decaying exponentially with inter-site distance. It replaces 55 free
// correlation parameters (for 11 sites under LKJ) with a SINGLE distance-
// decay parameter phi, plus the shared marginal variance sigma^2.
//
// PARAMETERIZATION:
//   sigma = marginal SD of process noise (shared across all sites)
//   phi   = distance-decay rate (1/km): larger phi = faster decay = less
//           spatial correlation; smaller phi = slower decay = more correlation
//   Sigma[i,j] = sigma^2 * exp(-phi * d[i,j])
//   Sigma[i,i] = sigma^2  (since d[i,i] = 0)
//
// PROCESS MODEL:
//   Z[t,j] = X[t-1,j] + U[j] + pdocoef * pdo[t-1] + epsilon[t-1,j]
//
//   where epsilon[t,] ~ MVN(0, Sigma)
//         Sigma[i,j] = sigma^2 * exp(-phi * d[i,j])
//         D = effective distance matrix (data, in km)
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
//   log_catch[k] ~ Normal(Z[row_k, col_k] + log_inv_logit(Pc_logit[k]),
//                          sigma_catch)
// ============================================================================

data {
  int<lower=1> N_years;                    // number of years (T)
  int<lower=1> N_sites;                    // number of spawning sections (J = 11)
  matrix[N_years, N_sites] Y;             // observed log spawn index
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs; // 1 if observed, 0 if missing

  vector[N_years] pdo;                     // spring PDO index

  array[N_years] int<lower=1, upper=3> q_idx; // survey method index: 1=surface, 2=mixed, 3=dive

  // Effective distance matrix (N_sites x N_sites, symmetric, diagonal = 0)
  // Units: km (divided by 1000 in R before passing to Stan)
  matrix[N_sites, N_sites] dist_mat;

  // Catch indexing
  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_row;
  array[N_catch] int<lower=1, upper=N_sites> catch_col;
  vector[N_catch] log_catch;

  // Maximum inter-site distance (km), used to scale phi prior
  real<lower=0> max_dist;

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
  real<lower=0> sigma;                     // marginal SD (shared across all sites)
  real<lower=0> phi;                       // distance-decay rate (1/km)

  // -- Observation error --
  real<lower=0> sigma_obs;

  // -- Catchability --
  vector[3] log_q;

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

  // -- Build distance-decay covariance matrix and Cholesky factor --
  // Sigma[i,j] = sigma^2 * exp(-phi * d[i,j])
  //
  // When phi -> 0: all sites perfectly correlated (Sigma = sigma^2 * 11)
  // When phi -> inf: independent sites (Sigma = sigma^2 * I)
  // Practical range (correlation ~ 0.05): d ~ 3/phi
  {
    matrix[N_sites, N_sites] Sigma;
    matrix[N_sites, N_sites] L_Sigma;

    for (i in 1:N_sites) {
      Sigma[i, i] = square(sigma);          // diagonal = sigma^2
      for (j in (i + 1):N_sites) {
        Sigma[i, j] = square(sigma) * exp(-phi * dist_mat[i, j]);
        Sigma[j, i] = Sigma[i, j];
      }
    }

    // Add small jitter for numerical stability of Cholesky decomposition
    for (i in 1:N_sites) {
      Sigma[i, i] += 1e-8;
    }

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
                + epsilon[t - 1, j];                 // spatially correlated error
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

  // -- Process error SD: half-t(3, 0, 2.5) --
  // Single marginal SD shared across all sites; spatial structure
  // is captured entirely by the distance-decay correlation.
  sigma ~ student_t(3, 0, 2.5);

  // -- Distance-decay rate: half-normal scaled to max inter-site distance --
  // phi has units 1/km. The "practical range" where correlation drops to
  // ~5% is 3/phi. Setting the half-normal SD so that the prior median
  // practical range is roughly max_dist/2:
  //   3/phi_median ~ max_dist/2  =>  phi_median ~ 6/max_dist
  // Half-normal(0, s) has median = s * 0.6745, so s = phi_median/0.6745
  //   => s ~ 6 / (max_dist * 0.6745) ~ 8.9 / max_dist
  //
  // We use a simpler scaling: half-normal(0, 3/max_dist) puts ~95% of the
  // prior mass on practical ranges > max_dist/2 (phi < 6/max_dist).
  // This is weakly informative: it says "the practical range is probably

  // at least as large as half the study area, but could be much smaller."
  phi ~ normal(0, 3.0 / max_dist);

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
      log_catch[k] ~ normal(Z[catch_row[k], catch_col[k]]
                              + log_inv_logit(Pc_logit[k]), sigma_catch);
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

  // Reconstruct Omega from distance-decay: rho(i,j) = exp(-phi * d[i,j])
  for (i in 1:N_sites) {
    Omega[i, i] = 1.0;
    for (j in (i + 1):N_sites) {
      Omega[i, j] = exp(-phi * dist_mat[i, j]);
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
          log_lik[idx] = normal_lpdf(Y[t, j] | X[t, j] + log_q[q_idx[t]],
                                     sigma_obs);
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
