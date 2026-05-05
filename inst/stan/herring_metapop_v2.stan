// ============================================================================
// herring_metapop_v2.stan — Extended herring metapopulation state-space model
// Multivariate normal process errors + site-level random effects + predators
//
// EXTENSIONS OVER v1:
// -------------------
// 1. Multivariate normal process errors with LKJ correlation prior
//    → estimates spatial covariance in population dynamics across sites
// 2. Site-level random effects on growth rate: U[j] ~ Normal(U_mu, sigma_U)
//    → allows each site to have its own baseline growth tendency
// 3. Predator covariates: whale, Steller sea lion, harbour seal indices
//    → additional linear predictors on population growth
// 4. Optional Gompertz density dependence: beta * X[t-1,j]
//    → allows growth rate to decline at high biomass
// 5. Generated quantities: log_lik, predicted biomass, fishing rates
//
// PROCESS MODEL:
//   Z[t,j] = X[t-1,j] + U[j] + pdocoef * pdo[t-1]
//             + whale_coef * whale[t-1] + ssl_coef * ssl[t-1,j]
//             + seal_coef * seal[t-1,j]
//             + beta * X[t-1,j]          (Gompertz term, optional)
//             + epsilon[t-1,j]
//
//   where epsilon[t,] ~ MVN(0, Sigma)
//         Sigma = diag(sigma_site) * Omega * diag(sigma_site)
//         Omega ~ LKJcorr(eta)
//
//   U[j] ~ Normal(U_mu, sigma_U)   (non-centered: U[j] = U_mu + sigma_U * U_raw[j])
//
// CATCH ADJUSTMENT:
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//
// OBSERVATION MODEL:
//   Y[t,j] ~ Normal(X[t,j] + log_q[q_idx[t]], sigma_obs)
//
// CATCH LIKELIHOOD:
//   log_catch[k] ~ Normal(Z[row_k, col_k] + log_inv_logit(Pc_logit[k]), sigma_catch)
//
//   Uses log_inv_logit(Pc_logit) instead of log(Pc) for numerical stability
//   when Pc is near 0 (avoids log(0) issues).
// ============================================================================

data {
  int<lower=1> N_years;                    // number of years (T)
  int<lower=1> N_sites;                    // number of spawning sections (J)
  matrix[N_years, N_sites] Y;             // observed log spawn index
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs; // 1 if observed, 0 if missing

  vector[N_years] pdo;                     // spring PDO index

  // Predator indices (length N_years each; can be zeros if unavailable)
  vector[N_years] whale;                   // humpback whale index (region-level)
  matrix[N_years, N_sites] ssl;           // Steller sea lion index (site-level)
  matrix[N_years, N_sites] seal;          // harbour seal index (site-level)

  array[N_years] int<lower=1, upper=3> q_idx; // survey method index: 1=surface, 2=mixed, 3=dive

  // Catch indexing
  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_row;
  array[N_catch] int<lower=1, upper=N_sites> catch_col;
  vector[N_catch] log_catch;

  // Model switches
  int<lower=0,upper=1> use_gompertz;       // 1 = include density dependence
  real<lower=0> lkj_eta;                   // LKJ concentration parameter (2 = weakly informative)

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

  // -- Environmental / predator coefficients --
  real pdocoef;                            // PDO effect
  real whale_coef;                         // humpback whale effect
  real ssl_coef;                           // Steller sea lion effect
  real seal_coef;                          // harbour seal effect

  // -- Gompertz density dependence (optional) --
  real beta_raw;                           // unconstrained; only used if use_gompertz == 1

  // -- Process error: multivariate normal --
  vector<lower=0>[N_sites] sigma_site;    // site-specific process error SDs
  cholesky_factor_corr[N_sites] L_Omega;  // Cholesky factor of correlation matrix

  // -- Observation error --
  real<lower=0> sigma_obs;

  // -- Catchability --
  vector[3] log_q;

  // -- Proportion catch (logit scale) --
  vector[N_catch] Pc_logit;

  // -- Process errors (standardized for non-centered MVN) --
  matrix[N_years - 1, N_sites] epsilon_raw; // N(0,1) draws for transitions 2..T (rows 1..T-1)

  // -- Initial states --
  vector[N_sites] Z_init;
}

transformed parameters {
  // -- Derived quantities --
  vector[N_sites] U;                       // site-level growth rates
  real beta;                               // Gompertz coefficient (0 if not used)
  vector<lower=0,upper=1>[N_catch] Pc;
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;    // actual process errors (MVN), rows 1..T-1

  // -- Non-centered site growth rates --
  U = U_mu + sigma_U * U_raw;

  // -- Gompertz switch --
  beta = use_gompertz ? beta_raw : 0.0;

  // -- Transform Pc --
  Pc = inv_logit(Pc_logit);

  // -- Build Pc matrix --
  Pc_mat = rep_matrix(0.0, N_years, N_sites);
  for (k in 1:N_catch) {
    Pc_mat[catch_row[k], catch_col[k]] = Pc[k];
  }

  // -- Transform process errors: epsilon[t,] = diag(sigma_site) * L_Omega * epsilon_raw[t,]' --
  // This gives epsilon[t,] ~ MVN(0, Sigma) where Sigma = diag(sigma_site) * Omega * diag(sigma_site)
  for (t in 1:(N_years - 1)) {
    epsilon[t] = (diag_pre_multiply(sigma_site, L_Omega) * epsilon_raw[t]')';
  }

  // -- Initial conditions (t = 1) --
  for (j in 1:N_sites) {
    Z[1, j] = Z_init[j];
    X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
  }

  // -- State dynamics (t = 2, ..., T) --
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      // NOTE: Gompertz density dependence uses post-fishing biomass X[t-1,j],
      // not pre-fishing Z[t-1,j]. This is intentional: density-dependent feedback
      // should act on the biomass that actually persists to reproduce, which is
      // the population remaining after catch removal.
      Z[t, j] = X[t - 1, j]
                + U[j]                               // site-specific growth
                + pdocoef * pdo[t - 1]               // PDO effect
                + whale_coef * whale[t - 1]          // whale predation
                + ssl_coef * ssl[t - 1, j]           // sea lion predation (site-level)
                + seal_coef * seal[t - 1, j]         // seal predation (site-level)
                + beta * X[t - 1, j]                 // Gompertz DD on post-fishing biomass
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
  sigma_U ~ student_t(3, 0, 1);            // half-t(3) on hyper-SD, more stable than Cauchy
  U_raw ~ std_normal();                   // non-centered parameterization

  // -- Environmental / predator effects --
  pdocoef ~ normal(0, 1);
  whale_coef ~ normal(0, 1);
  ssl_coef ~ normal(0, 1);
  seal_coef ~ normal(0, 1);

  // -- Gompertz coefficient --
  // Only sample beta_raw when Gompertz is active. When use_gompertz == 0,
  // beta_raw has no prior and is not sampled (remains at its initial value,
  // but beta is set to 0 in transformed parameters so it has no effect).
  if (use_gompertz == 1) {
    // For Gompertz: beta should be negative (density-dependent decline)
    // Prior allows positive and negative, but expects near zero
    beta_raw ~ normal(0, 0.5);
  }

  // -- Process error SDs (site-specific): half-t(3, 0, 2.5) --
  // Student-t(3, 0, 2.5) preferred over Cauchy for more stable HMC sampling;
  // finite variance with heavy tails. Lower bound of 0 enforces half-t.
  sigma_site ~ student_t(3, 0, 2.5);

  // -- Correlation matrix: LKJ prior --
  // eta = 1 → uniform over correlations
  // eta = 2 → weakly favors identity (moderate shrinkage toward independence)
  L_Omega ~ lkj_corr_cholesky(lkj_eta);

  // -- Process errors (standardized for non-centered MVN) --
  to_vector(epsilon_raw) ~ std_normal();

  // -- Observation error SD: half-t(3, 0, 2.5) --
  sigma_obs ~ student_t(3, 0, 2.5);

  // -- Catchability: weakly informative --
  // Normal(0, 2): 95% prior range ≈ exp(-4) to exp(4) ≈ [0.018, 54.6] on q scale.
  // Tightened from N(0, 5) which allowed implausibly large catchability values.
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

    // Catch observations
    for (k in 1:N_catch) {
      // Use log_inv_logit(Pc_logit[k]) instead of log(Pc[k]) for numerical stability
      // when Pc is near 0 (avoids log(0) underflow).
      log_catch[k] ~ normal(Z[catch_row[k], catch_col[k]] + log_inv_logit(Pc_logit[k]), sigma_catch);
    }
  }
}

generated quantities {
  // ========================================================================
  // GENERATED QUANTITIES
  // ========================================================================

  // -- Log-likelihood for LOO-CV --
  // log_lik covers spawn observations only, not catch likelihood.
  // This is intentional: LOO-CV targets the observation model (spawn index),
  // not the catch constraint which is a model component, not a prediction target.
  vector[N_years * N_sites] log_lik;

  // -- Predicted biomass (natural scale, tonnes of spawn) --
  matrix[N_years, N_sites] biomass_pred;   // exp(Z) = pre-fishing biomass

  // -- Fishing rate (proportion caught each year at each site) --
  matrix[N_years, N_sites] fishing_rate;

  // -- Posterior predictive replications for spawn index --
  matrix[N_years, N_sites] Y_rep;

  // -- Correlation matrix (for reporting) --
  corr_matrix[N_sites] Omega;

  // Reconstruct correlation matrix from Cholesky factor
  Omega = multiply_lower_tri_self_transpose(L_Omega);

  // Log-likelihood and posterior predictive replications
  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        idx += 1;
        if (Y_obs[t, j] == 1) {
          log_lik[idx] = normal_lpdf(Y[t, j] | X[t, j] + log_q[q_idx[t]], sigma_obs);
          Y_rep[t, j] = normal_rng(X[t, j] + log_q[q_idx[t]], sigma_obs);
        } else {
          log_lik[idx] = 0.0;     // no observation — contributes nothing
          Y_rep[t, j] = 0.0;      // no observation — placeholder (not used in PPC)
        }
      }
    }
  }

  // Predicted biomass and fishing rates
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      biomass_pred[t, j] = exp(Z[t, j]);   // pre-fishing biomass (spawn index units)
      fishing_rate[t, j] = Pc_mat[t, j];   // proportion caught
    }
  }
}
