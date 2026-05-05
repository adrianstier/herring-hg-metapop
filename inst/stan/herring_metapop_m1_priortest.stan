// ============================================================================
// herring_metapop_m1_priortest.stan — M1 with data-level prior hyperparameters
//
// Identical to herring_metapop_m1.stan but priors are controlled via data
// inputs so the same compiled model can be refit under different prior specs.
// ============================================================================

data {
  int<lower=1> N_years;
  int<lower=1> N_sites;

  matrix[N_years, N_sites] Y;
  array[N_years, N_sites] int<lower=0, upper=1> y_obs;

  vector[N_years] pdo;
  array[N_years] int<lower=1, upper=3> q_idx;

  int<lower=0> N_catch;
  array[N_catch] int<lower=1, upper=N_years> catch_yr;
  array[N_catch] int<lower=1, upper=N_sites> catch_site;
  vector[N_catch] log_catch;

  int<lower=0> N_zero;
  array[N_zero] int<lower=1, upper=N_years> zero_yr;
  array[N_zero] int<lower=1, upper=N_sites> zero_site;

  // === Prior hyperparameters (passed as data) ===
  real prior_Umu_mean;
  real<lower=0> prior_Umu_sd;

  real prior_pdocoef_mean;
  real<lower=0> prior_pdocoef_sd;

  real<lower=0> prior_sigma_proc_scale;   // half-t scale
  real<lower=0> prior_sigma_proc_df;      // half-t df

  real<lower=0> prior_sigma_obs_scale;    // half-t scale
  real<lower=0> prior_sigma_obs_df;       // half-t df

  real prior_log_q_mean;
  real<lower=0> prior_log_q_sd;

  real prior_Pc_logit_mean;
  real<lower=0> prior_Pc_logit_sd;

  real prior_Z_init_mean;
  real<lower=0> prior_Z_init_sd;

  int<lower=0, upper=1> prior_only;  // 1 = skip likelihood (prior predictive)
}

transformed data {
  real sigma_catch = 0.01;
}

parameters {
  real Umu;
  real pdocoef;
  real<lower=0> sigma_proc;
  real<lower=0> sigma_obs;
  vector[3] log_q;
  vector[N_catch] Pc_logit;
  vector[N_sites] Z_init;
  matrix[N_years - 1, N_sites] delta_raw;
}

transformed parameters {
  matrix[N_years, N_sites] Z;
  matrix[N_years, N_sites] X;
  vector<lower=0, upper=1>[N_catch] Pc;

  Pc = inv_logit(Pc_logit);

  {
    matrix[N_years, N_sites] Pc_mat = rep_matrix(0.0, N_years, N_sites);

    for (k in 1:N_catch) {
      Pc_mat[catch_yr[k], catch_site[k]] = Pc[k];
    }

    for (j in 1:N_sites) {
      Z[1, j] = Z_init[j];
      X[1, j] = Z[1, j] + log1m(Pc_mat[1, j]);
    }

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
  // === PRIORS (data-level hyperparameters) ===
  Umu ~ normal(prior_Umu_mean, prior_Umu_sd);
  pdocoef ~ normal(prior_pdocoef_mean, prior_pdocoef_sd);
  sigma_proc ~ student_t(prior_sigma_proc_df, 0, prior_sigma_proc_scale);
  sigma_obs ~ student_t(prior_sigma_obs_df, 0, prior_sigma_obs_scale);
  log_q ~ normal(prior_log_q_mean, prior_log_q_sd);
  Pc_logit ~ normal(prior_Pc_logit_mean, prior_Pc_logit_sd);
  Z_init ~ normal(prior_Z_init_mean, prior_Z_init_sd);
  to_vector(delta_raw) ~ std_normal();

  // === LIKELIHOOD (skip if prior_only == 1) ===
  if (prior_only == 0) {
    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        if (y_obs[t, j] == 1) {
          Y[t, j] ~ normal(X[t, j] + log_q[q_idx[t]], sigma_obs);
        }
      }
    }

    for (k in 1:N_catch) {
      log_catch[k] ~ normal(Z[catch_yr[k], catch_site[k]]
                            + log(Pc[k]), sigma_catch);
    }
  }
}

generated quantities {
  // Posterior predictive replications (always generated)
  matrix[N_years, N_sites] Y_rep;

  for (t in 1:N_years) {
    for (j in 1:N_sites) {
      Y_rep[t, j] = normal_rng(X[t, j] + log_q[q_idx[t]], sigma_obs);
    }
  }
}
