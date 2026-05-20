// ============================================================================
// herring_metapop_m1.stan — M1: Diagonal-Equal Variance
// Baseline herring metapopulation state-space model (Stier et al. 2020)
//
// State-space model for Pacific herring (Clupea pallasii) spawn biomass
// across 11 spawning sections at Haida Gwaii, BC.
//
// PROCESS MODEL:
//   Z[t,j] = X[t-1,j] + Umu + pdocoef * pdo[t-1] + sigma_proc * delta_raw[t-1,j]
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//   delta_raw[t,j] ~ Normal(0, 1)  (non-centered parameterization)
//
// OBSERVATION MODEL:
//   Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
//
// CATCH CONSTRAINT:
//   ctab[k] ~ Normal(Z[row_k, col_k] + log(Pc[k]), sigma_catch)
//   Only for (year,site) pairs where catch > 0.
//
// Uses non-centered parameterization for process errors to break
// the sigma_proc-delta correlation that causes funnel geometry.
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;

  // Observed log spawn index -- NAs replaced with 0.0 in R; use y_obs to mask
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> y_obs;  // 1 = observed

  // PDO covariate
  vector[N_years] pdo;

  // Survey method index (1=surface, 2=mixed, 3=dive)
  array[N_years] int<lower=1, upper=3> q_idx;

  // Catch > 0 indexing
  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_yr;
  array[N_catch] int<lower=1, upper=N_sites> catch_site;
  vector[N_catch] log_catch;  // log(catch + 1)

  // Catch == 0 indexing
  int<lower=0> N_zero;
  array[N_zero] int<lower=1, upper=N_years> zero_yr;
  array[N_zero] int<lower=1, upper=N_sites> zero_site;
}

transformed data {
  real sigma_catch = 0.01;  // tight constraint on catch (matches JAGS precision 1/0.0001)
}

parameters {
  real Umu;                                   // global mean growth rate
  real pdocoef;                               // PDO effect on growth
  real<lower=0> sigma_proc;                   // process error SD (diagonal, equal)
  real<lower=0> sigma_obs;                    // observation error SD
  vector[3] log_q;                            // log catchability (surface, mixed, dive)
  vector[N_catch] Pc_logit;                   // logit(Pc) where catch > 0
  vector[N_sites] Z_init;                     // initial pre-fishing log biomass Z[1,j]
  matrix[N_years - 1, N_sites] delta_raw;     // standardized process errors (non-centered)
}

transformed parameters {
  matrix[N_years, N_sites] Z;     // pre-fishing log biomass
  matrix[N_years, N_sites] X;     // post-fishing log biomass
  vector<lower=0, upper=1>[N_catch] Pc;

  // Transform catch proportions
  Pc = inv_logit(Pc_logit);

  // Build Pc matrix: start with zero everywhere
  {
    matrix[N_years, N_sites] Pc_mat = rep_matrix(0.0, N_years, N_sites);

    // Fill non-zero catch positions
    for (k in 1:N_catch) {
      Pc_mat[catch_yr[k], catch_site[k]] = Pc[k];
    }

    // Initial conditions (t = 1)
    for (j in 1:N_sites) {
      Z[1, j] = Z_init[j];
      X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
    }

    // State dynamics (t = 2, ..., T)
    // Non-centered: delta = sigma_proc * delta_raw
    for (t in 2:N_years) {
      for (j in 1:N_sites) {
        Z[t, j] = X[t - 1, j] + Umu + pdocoef * pdo[t - 1]
                  + sigma_proc * delta_raw[t - 1, j];
        X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
      }
    }
  }
}

model {
  // === PRIORS ===

  // Growth rate
  Umu ~ normal(0, 1);

  // PDO coefficient
  pdocoef ~ normal(0, 1);

  // Process error SD -- half-t(3, 0, 2.5)
  sigma_proc ~ student_t(3, 0, 2.5);

  // Observation error SD -- half-t(3, 0, 2.5)
  sigma_obs ~ student_t(3, 0, 2.5);

  // Catchability
  log_q ~ normal(0, 2);

  // Proportion catch on logit scale
  // JAGS: dnorm(-1.386, precision=2) -> N(-1.386, sd=0.707)
  // -1.386 on logit ~ 0.20 on probability scale
  Pc_logit ~ normal(-1.386, 0.707);

  // Initial states: N(5, 10)
  Z_init ~ normal(5, 10);

  // Process errors -- non-centered: delta_raw ~ N(0,1)
  to_vector(delta_raw) ~ std_normal();

  // === LIKELIHOOD ===

  // Observation model: Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (y_obs[t, j] == 1) {
        Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
      }
    }
  }

  // Catch constraint: ctab[k] ~ Normal(Z[yr,site] + log(Pc[k]), sigma_catch)
  for (k in 1:N_catch) {
    log_catch[k] ~ normal(Z[catch_yr[k], catch_site[k]]
                          + log(Pc[k]), sigma_catch);
  }
}

generated quantities {
  // Log-likelihood for LOO-CV (spawn observations only)
  vector[N_years * N_sites] log_lik;
  // Posterior predictive replications
  matrix[N_years, N_sites] Y_rep;

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        idx += 1;
        if (y_obs[t, j] == 1) {
          log_lik[idx] = normal_lpdf(Y[t, j] | X[t, j] + log_q[q_idx[t]], sigma_obs);
          Y_rep[t, j] = normal_rng(X[t, j] + log_q[q_idx[t]], sigma_obs);
        } else {
          log_lik[idx] = 0.0;
          Y_rep[t, j] = normal_rng(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }
  }
}
