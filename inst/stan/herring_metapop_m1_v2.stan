// ============================================================================
// herring_metapop_m1_v2.stan — M1v2: Diagonal-Equal Variance (improved)
// Updated baseline herring metapopulation state-space model
//
// Changes from v1:
//   C1: Log-likelihood output sized to N_obs only (no 0.0 contamination for LOO)
//   C2: Supports max_treedepth=15, longer chains for convergence
//   C4: Left-censored observation model for surveyed zeros
//   M1: Informative sigma_obs prior: normal(0.5, 0.3) T[0,]
//   M2: Student-t observation model (heavy tails, estimated nu_obs)
//
// PROCESS MODEL:
//   Z[t,j] = X[t-1,j] + Umu + pdocoef * pdo[t-1] + sigma_proc * delta_raw[t-1,j]
//   X[t,j] = Z[t,j] + log(1 - Pc[t,j])
//   delta_raw[t,j] ~ Normal(0, 1)  (non-centered parameterization)
//
// OBSERVATION MODEL (positive obs):
//   Y[t,j] ~ Student-t(nu_obs, X[t,j] + log_q[q_idx[t]], sigma_obs)
//
// CENSORED ZERO MODEL:
//   If surveyed zero: P(Y < log_detection_threshold | X[t,j], sigma_obs)
//
// CATCH CONSTRAINT:
//   ctab[k] ~ Normal(Z[row_k, col_k] + log(Pc[k]), sigma_catch)
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;

  // Observed log spawn index -- NAs replaced with 0.0 in R; use Y_obs_flag to mask
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;      // 1 = positive observation
  array[N_years, N_sites] int<lower=0, upper=1> Y_censored_flag;  // 1 = surveyed zero (left-censored)

  // PDO covariate
  vector[N_years] pdo;

  // Survey method index (1=surface, 2=transition, 3=dive)
  int<lower=2, upper=3> N_methods;
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
  real log_detection_threshold = log(0.1);  // 0.1 tonnes minimum detectable spawn

  // Count observed and censored data points for log_lik sizing
  int N_obs = 0;
  int N_censored = 0;
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (Y_obs_flag[t, j] == 1) N_obs += 1;
      if (Y_censored_flag[t, j] == 1) N_censored += 1;
    }
  }
}

parameters {
  real Umu;                                   // global mean growth rate
  real pdocoef;                               // PDO effect on growth
  real<lower=0> sigma_proc;                   // process error SD (diagonal, equal)
  real<lower=0> sigma_obs;                    // observation error SD
  real<lower=2> nu_obs;                       // Student-t degrees of freedom
  vector[N_methods] log_q;                    // log catchability per survey method
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

  // Observation error SD -- informative prior based on survey CV 30-50%
  // sigma_obs on log scale = sqrt(log(1+CV^2)) ~ 0.3-0.5
  sigma_obs ~ normal(0.5, 0.3);
  // (implicit lower bound from declaration: sigma_obs > 0)

  // Student-t degrees of freedom for observation model
  // gamma(2, 0.1) puts mass on nu ~ 5-30 (moderate to heavy tails)
  nu_obs ~ gamma(2, 0.1);

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

  // Observation model: positive observations
  // Y[t,j] ~ Student-t(nu_obs, X[t,j] + log_q[q_idx[t]], sigma_obs)
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (Y_obs_flag[t, j] == 1) {
        Y[t, j] ~ student_t(nu_obs, X[t, j] + log_q[q_idx[t]], sigma_obs);
      }
    }
  }

  // Censored zeros: surveyed but zero spawn detected
  // Left-censored: true log-biomass is below detection threshold
  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      if (Y_censored_flag[t, j] == 1) {
        target += student_t_lcdf(log_detection_threshold | nu_obs,
                                 X[t, j] + log_q[q_idx[t]], sigma_obs);
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
  // Log-likelihood for LOO-CV: only N_obs values (positive observations)
  // This avoids contaminating LOO with 0.0 entries for missing data
  vector[N_obs] log_lik;

  // Posterior predictive replications (full grid for residual checks)
  matrix[N_years, N_sites] Y_rep;

  {
    int obs_idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        real mu = X[t, j] + log_q[q_idx[t]];

        if (Y_obs_flag[t, j] == 1) {
          obs_idx += 1;
          log_lik[obs_idx] = student_t_lpdf(Y[t, j] | nu_obs, mu, sigma_obs);
        }

        // Posterior predictive draws for all cells
        Y_rep[t, j] = student_t_rng(nu_obs, mu, sigma_obs);
      }
    }
  }
}
