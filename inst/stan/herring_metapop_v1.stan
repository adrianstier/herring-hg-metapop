// ============================================================================
// herring_metapop_v1.stan — Herring metapopulation state-space model
// "Diagonal and Equal" variance structure (v1 baseline)
//
// Direct translation of JAGS Model1_diagonal_equal.R with improved priors.
//
// MODEL OVERVIEW:
// ---------------
// State-space model for Pacific herring (Clupea pallasii) spawn biomass
// across 11 spawning sections at Haida Gwaii, British Columbia.
//
// PROCESS MODEL (latent dynamics):
//   Z[t,j] = X[t-1,j] + U + pdocoef * pdo[t-1] + delta[t-1,j]
//
//   Z[t,j]   = pre-fishing log spawn biomass at time t, site j
//   X[t-1,j] = post-fishing log spawn biomass at time t-1, site j
//   U        = global mean population growth rate (shared across sites)
//   pdocoef  = effect of Pacific Decadal Oscillation on growth
//   pdo[t-1] = spring (Mar-Jun) PDO index at time t-1
//   delta[t-1,j] ~ Normal(0, sigma) = process error (iid across sites)
//
// CATCH ADJUSTMENT:
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//
//   Pc[t,j] = proportion of biomass caught at site j in year t
//   When Pc = 0 (no catch reported), X = Z (no adjustment)
//
// OBSERVATION MODEL:
//   Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
//
//   Y[t,j]  = observed log spawn index (surface or dive survey)
//   log_q[] = log catchability coefficients:
//             q[1] for surface surveys (1950-1987)
//             q[2] for dive surveys (1988-present)
//   sigma_obs = observation error standard deviation
//
// CATCH LIKELIHOOD:
//   log_catch[k] ~ Normal(Z[row_k, col_k] + log_inv_logit(Pc_logit[k]), sigma_catch)
//
//   Only evaluated at (year, site) pairs where catch > 0.
//   Uses log_inv_logit(Pc_logit) instead of log(Pc) for numerical stability
//   when Pc is near 0 (avoids log(0) issues).
//   sigma_catch is fixed small (0.01) to tightly constrain catch.
//
// CHANGES FROM JAGS VERSION:
//   - Half-Cauchy(0,2.5) on sigma and sigma_obs instead of gamma(0.001,0.001)
//   - Wider Normal(0, 5) prior on log_q instead of Normal(0, 1/10)
//   - Added generated quantities for LOO-CV (log_lik)
//   - Parameterized in terms of sigma (SD) not tau (precision)
// ============================================================================

data {
  int<lower=1> N_years;                    // number of years (T)
  int<lower=1> N_sites;                    // number of spawning sections (J)
  matrix[N_years, N_sites] Y;             // observed log spawn index (with NaN for missing)
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs; // 1 if Y[t,j] observed, 0 if missing

  vector[N_years] pdo;                     // spring PDO index (Mar-Jun average)
  array[N_years] int<lower=1, upper=2> q_idx; // survey method index: 1=surface, 2=dive

  // Catch indexing: only estimate Pc where catch > 0
  int<lower=0> N_catch;                    // number of (year,site) pairs with catch > 0
  array[N_catch] int<lower=1, upper=N_years> catch_row; // year index for each catch observation
  array[N_catch] int<lower=1, upper=N_sites> catch_col; // site index for each catch observation
  vector[N_catch] log_catch;               // log(catch + 1) at those positions

  // Flag for prior predictive simulation (1 = skip likelihood)
  int<lower=0, upper=1> prior_only;
}

transformed data {
  // Fixed catch observation SD (very tight, as in JAGS: precision = 1/0.0001)
  real sigma_catch = 0.01;
}

parameters {
  // -- Process model parameters --
  real U;                                   // global mean growth rate
  real pdocoef;                            // PDO effect on growth

  // -- Variance parameters --
  real<lower=0> sigma;                     // process error SD (diagonal & equal)
  real<lower=0> sigma_obs;                 // observation error SD

  // -- Catchability --
  vector[2] log_q;                         // log catchability: surface, dive

  // -- Proportion catch (logit scale) --
  vector[N_catch] Pc_logit;                // logit(Pc) for catch > 0 positions

  // -- Process errors --
  matrix[N_years - 1, N_sites] delta_raw;  // standardized process errors (rows 1..T-1 used for transitions 2..T)

  // -- Initial states --
  vector[N_sites] Z_init;                  // Z[1,j] = pre-fishing log biomass at t=1
}

transformed parameters {
  // -- Derived quantities --
  vector<lower=0,upper=1>[N_catch] Pc;     // proportion caught (catch > 0)
  matrix[N_years, N_sites] Z;             // pre-fishing log biomass
  matrix[N_years, N_sites] X;             // post-fishing log biomass
  matrix[N_years, N_sites] Pc_mat;        // full Pc matrix (0 where no catch)

  // -- Transform Pc from logit scale --
  Pc = inv_logit(Pc_logit);

  // -- Build full Pc matrix --
  // Initialize to zero (no catch)
  Pc_mat = rep_matrix(0.0, N_years, N_sites);

  // Fill in non-zero catch positions
  for (k in 1:N_catch) {
    Pc_mat[catch_row[k], catch_col[k]] = Pc[k];
  }

  // -- Initial conditions (t = 1) --
  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]); // log(1 - Pc) via log1m for stability
  }

  // -- State dynamics (t = 2, ..., T) --
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      // Process model: growth from post-fishing biomass
      Z[t, j] = X[t - 1, j] + U + pdocoef * pdo[t - 1] + sigma * delta_raw[t - 1, j];
      // Catch adjustment
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  // ========================================================================
  // PRIORS
  // ========================================================================

  // -- Growth rate --
  U ~ normal(0, 1);                        // weakly informative

  // -- PDO coefficient --
  pdocoef ~ normal(0, 1);                  // weakly informative

  // -- Process error SD: half-t(3, 0, 2.5) --
  // Student-t(3, 0, 2.5) preferred over Cauchy for more stable HMC sampling;
  // finite variance with heavy tails. Lower bound of 0 enforces half-t.
  sigma ~ student_t(3, 0, 2.5);

  // -- Observation error SD: half-t(3, 0, 2.5) --
  sigma_obs ~ student_t(3, 0, 2.5);

  // -- Catchability: weakly informative --
  // Normal(0, 2): 95% prior range ≈ exp(-4) to exp(4) ≈ [0.018, 54.6] on q scale.
  // Tightened from N(0, 5) which allowed implausibly large catchability values.
  log_q ~ normal(0, 2);

  // -- Proportion catch (logit scale) --
  // JAGS: Pc.logit ~ dnorm(-1.386, 2) → N(mean=-1.386, sd=0.707)
  // -1.386 on logit scale ≈ 0.20 on probability scale (prior mean ~20% catch)
  Pc_logit ~ normal(-1.386, 0.707);

  // -- Initial states --
  // JAGS: Z[1,j] ~ dnorm(5, 1/100) → N(5, sd=10)
  Z_init ~ normal(5, 10);

  // -- Process errors (standardized, non-centered parameterization) --
  to_vector(delta_raw) ~ std_normal();

  // ========================================================================
  // LIKELIHOOD — Observation model
  // ========================================================================

  if (prior_only == 0) {
    // Spawn index observations
    // NOTE: Could be vectorized by collecting observed indices into a vector
    // and using a single normal_lpdf call for speedup, e.g.:
    //   Y_observed ~ normal(mu_observed, sigma_obs);
    // Keeping the loop version for clarity.
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs[t, j] == 1) {
          Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }

    // Catch observations (only where catch > 0)
    for (k in 1:N_catch) {
      // Expected log catch = log(pre-fishing biomass) + log(proportion caught)
      // = Z[t,j] + log(Pc[k])
      // Use log_inv_logit(Pc_logit[k]) instead of log(Pc[k]) for numerical stability
      // when Pc is near 0 (avoids log(0) underflow).
      log_catch[k] ~ normal(Z[catch_row[k], catch_col[k]] + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  // ========================================================================
  // LOG-LIKELIHOOD for LOO-CV via the loo package
  // ========================================================================

  // log_lik covers spawn observations only, not catch likelihood.
  // This is intentional: LOO-CV targets the observation model (spawn index),
  // not the catch constraint which is a model component, not a prediction target.

  // One log_lik entry per observed Y[t,j]
  // We store in a vector; the R code can reshape as needed
  // Total possible observations: N_years * N_sites
  vector[N_years * N_sites] log_lik;

  // Posterior predictive replications for spawn index
  matrix[N_years, N_sites] Y_rep;

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        idx += 1;
        if (Y_obs[t, j] == 1) {
          log_lik[idx] = normal_lpdf(Y[t, j] | X[t, j] + log_q[q_idx[t]], sigma_obs);
          Y_rep[t, j] = normal_rng(X[t, j] + log_q[q_idx[t]], sigma_obs);
        } else {
          log_lik[idx] = 0.0; // no observation — contributes nothing
          Y_rep[t, j] = 0.0;  // no observation — placeholder (not used in PPC)
        }
      }
    }
  }
}
