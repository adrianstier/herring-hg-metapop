// ============================================================================
// herring_metapop_m3_stier_distance.stan
//
// Stier-aligned distance-covariance branch:
//   1. Same observation layer as m1_stier_11.
//   2. Zero spawn records are ambiguous and skipped in the likelihood.
//   3. Two survey-era q terms: surface and SCUBA/dive.
//   4. Annual process shocks are spatially correlated by effective distance.
//   5. No site-specific productivity, density dependence, predators, size, or
//      age structure.
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;
  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> Y_obs_flag;

  vector[N_years] pdo;

  int<lower=2, upper=2> N_methods;
  array[N_years] int<lower=1, upper=2> q_idx;

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
  real Umu;
  real pdocoef;
  real<lower=0> sigma_proc;
  real<lower=0> phi;
  real<lower=0> sigma_obs;

  vector[N_methods] log_q;
  vector[N_catch] Pc_logit;
  vector[N_sites] Z_init;
  matrix[N_years - 1, N_sites] epsilon_raw;
}

transformed parameters {
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  matrix[N_years, N_sites] Pc_mat;
  matrix[N_years - 1, N_sites] epsilon;

  {
    matrix[N_sites, N_sites] Sigma;
    matrix[N_sites, N_sites] L_Sigma;

    for (i in 1:N_sites) {
      Sigma[i, i] = square(sigma_proc);
      for (j in (i + 1):N_sites) {
        Sigma[i, j] = square(sigma_proc) * exp(-phi * dist_mat[i, j]);
        Sigma[j, i] = Sigma[i, j];
      }
    }
    for (i in 1:N_sites) {
      Sigma[i, i] += 1e-8;
    }
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
      Z[t, j] = X[t - 1, j] + Umu + pdocoef * pdo[t - 1] +
        epsilon[t - 1, j];
      X[t, j] = Z[t, j] + log1m(Pc_mat[t, j]);
    }
  }
}

model {
  Umu ~ normal(0, 1);
  pdocoef ~ normal(0, 1);
  sigma_proc ~ student_t(3, 0, 2.5);

  // phi is a distance-decay rate in 1/km. This weakly favors correlations
  // that decay over study-area scales while still allowing near independence.
  phi ~ normal(0, 3.0 / max_dist);

  sigma_obs ~ normal(0.75, 0.35);
  log_q ~ normal(0, 2.0);

  Pc_logit ~ normal(-1.386, 0.707);
  Z_init ~ normal(5, 10);
  to_vector(epsilon_raw) ~ std_normal();

  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (Y_obs_flag[t, j] == 1) {
          Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }
    for (k in 1:N_catch) {
      log_catch[k] ~ normal(
        Z[catch_yr[k], catch_site[k]] + log_inv_logit(Pc_logit[k]),
        sigma_catch
      );
    }
  }
}

generated quantities {
  vector[N_obs] log_lik;
  matrix[N_years, N_sites] Y_rep;
  matrix[N_years, N_sites] biomass_pred;
  matrix[N_years, N_sites] fishing_rate;
  matrix[N_years, N_sites] p_below_detection;
  array[N_years, N_sites] int<lower=0, upper=1> below_detection_rep;
  real practical_range_km = 3.0 / phi;

  {
    int idx = 0;
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        real mu = X[t, j] + log_q[q_idx[t]];
        real y_rep_log = normal_rng(mu, sigma_obs);
        if (Y_obs_flag[t, j] == 1) {
          idx += 1;
          log_lik[idx] = normal_lpdf(Y[t, j] | mu, sigma_obs);
        }
        Y_rep[t, j] = exp(y_rep_log);
        biomass_pred[t, j] = exp(Z[t, j]);
        fishing_rate[t, j] = Pc_mat[t, j];
        p_below_detection[t, j] = normal_cdf(
          log_detection_threshold | mu, sigma_obs
        );
        below_detection_rep[t, j] = y_rep_log <= log_detection_threshold;
      }
    }
  }
}
