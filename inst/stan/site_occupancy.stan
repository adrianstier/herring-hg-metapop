// ============================================================================
// site_occupancy.stan — Bayesian spawning site occupancy model
// stier-2027-herring-metapopulation
//
// READER GUIDE:
//   This is a different response model, not a simplified biomass model.
//   Read `surveyed` and `occupied` in `data {}` first, then follow how the
//   autoregressive occupancy process uses last year's occupancy state.
//
// MODEL OVERVIEW:
// ---------------
// Autoregressive occupancy model for Pacific herring spawning sites at
// Haida Gwaii. Tests whether collective memory (site fidelity transmitted
// across generations by experienced spawners) predicts which sites are
// occupied in a given year.
//
// Inspired by Ono et al. (2025, Nature): Norwegian spring-spawning herring
// shifted spawning grounds ~800 km after age-selective fishing destroyed
// the collective memory held by older cohort members. This model asks
// whether similar site abandonment occurred at Haida Gwaii.
//
// OCCUPANCY MODEL:
//   occupied[t,j] ~ Bernoulli(p[t,j])
//   logit(p[t,j]) = alpha[j] + gamma * occupied[t-1,j]
//                  + delta_pop * log_N_total[t]
//                  + delta_age * age_index[t]    (if has_age_data == 1)
//
//   alpha[j]    ~ Normal(alpha_mu, sigma_alpha)   site-level random intercept
//   gamma       captures persistence / site fidelity
//                  positive => if spawning last year, more likely this year
//   delta_pop   captures population size effect
//                  positive => larger populations occupy more sites
//   delta_age   captures age structure / collective memory effect
//                  positive => more old fish => more sites remembered
//
// SURVEY MASK:
//   The likelihood is only evaluated for site-years where the section
//   was actually surveyed (surveyed[t,j] == 1). Unsurveyed site-years
//   (totalrecords == 0) are treated as missing data — their occupancy
//   state is imputed by the model via the autoregressive structure.
//
// GENERATED QUANTITIES:
//   - log_lik: pointwise log-likelihood for LOO-CV
//   - p_pred: predicted occupancy probabilities (full matrix)
//   - p_recol: recolonization probability — P(occupied | was unoccupied)
//              = inv_logit(alpha[j] + delta_pop * log_N_total[t]
//                         + delta_age * age_index[t])
//              i.e., gamma contribution is zero because occupied[t-1,j] = 0
// ============================================================================

data {
  int<lower=1> N_years;                          // number of years
  int<lower=1> N_sites;                          // number of spawning sections

  // Observed occupancy: 1 = spawning detected, 0 = no spawning or not surveyed
  array[N_years, N_sites] int<lower=0, upper=1> occupied;

  // Survey mask: 1 = site was surveyed that year, 0 = not surveyed
  // Only include in likelihood when surveyed == 1
  array[N_years, N_sites] int<lower=0, upper=1> surveyed;

  // Population-level covariates (length N_years)
  vector[N_years] log_N_total;                   // log total archipelago biomass or SHI

  // Optional age structure covariate
  int<lower=0, upper=1> has_age_data;            // 1 if age_index is provided, 0 otherwise
  vector[N_years] age_index;                     // age diversity or proportion old fish
                                                 // (ignored if has_age_data == 0)

  // Flag for prior predictive simulation (1 = skip likelihood)
  int<lower=0, upper=1> prior_only;
}

transformed data {
  // Count surveyed observations for t >= 2 (autoregressive model starts at t=2)
  int N_obs = 0;
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      if (surveyed[t, j] == 1) {
        N_obs += 1;
      }
    }
  }
}

parameters {
  // -- Hyperparameters for site random effects --
  real alpha_mu;                                 // population-level baseline log-odds
  real<lower=0> sigma_alpha;                     // SD of site random effects

  // -- Site random effects (non-centered) --
  vector[N_sites] alpha_raw;                     // standardized site effects

  // -- Fixed effects --
  real gamma;                                    // persistence / site fidelity
  real delta_pop;                                // population size effect
  real delta_age;                                // age structure effect (only used if has_age_data)
}

transformed parameters {
  // -- Site random intercepts --
  vector[N_sites] alpha = alpha_mu + sigma_alpha * alpha_raw;

  // -- Occupancy probabilities (full matrix) --
  matrix[N_years, N_sites] logit_p;

  // t = 1: no autoregressive term available; use baseline only
  for (j in 1:N_sites) {
    logit_p[1, j] = alpha[j] + delta_pop * log_N_total[1];
    if (has_age_data == 1) {
      logit_p[1, j] += delta_age * age_index[1];
    }
  }

  // t = 2, ..., T: full autoregressive model
  for (t in 2:N_years) {
    for (j in 1:N_sites) {
      logit_p[t, j] = alpha[j]
                     + gamma * occupied[t - 1, j]
                     + delta_pop * log_N_total[t];
      if (has_age_data == 1) {
        logit_p[t, j] += delta_age * age_index[t];
      }
    }
  }
}

model {
  // ========================================================================
  // PRIORS
  // ========================================================================

  // Baseline occupancy — weakly informative
  // alpha_mu ~ Normal(0, 2): 95% prior range on logit scale => [-4, 4]
  // => probability range [0.018, 0.982]
  alpha_mu ~ normal(0, 2);

  // Site heterogeneity — weakly informative half-t
  sigma_alpha ~ student_t(3, 0, 1);

  // Non-centered site effects
  alpha_raw ~ std_normal();

  // Persistence (site fidelity) — expect positive but allow negative
  // Normal(0, 2) is weakly informative
  gamma ~ normal(0, 2);

  // Population size effect — expect positive but weakly informative
  delta_pop ~ normal(0, 1);

  // Age structure effect — expect positive if collective memory hypothesis holds
  delta_age ~ normal(0, 1);

  // ========================================================================
  // LIKELIHOOD
  // ========================================================================

  if (prior_only == 0) {
    // t = 1: baseline (no lagged occupancy available)
    for (j in 1:N_sites) {
      if (surveyed[1, j] == 1) {
        occupied[1, j] ~ bernoulli_logit(logit_p[1, j]);
      }
    }

    // t = 2, ..., T: autoregressive model
    for (t in 2:N_years) {
      for (j in 1:N_sites) {
        if (surveyed[t, j] == 1) {
          occupied[t, j] ~ bernoulli_logit(logit_p[t, j]);
        }
      }
    }
  }
}

generated quantities {
  // ========================================================================
  // LOG-LIKELIHOOD for LOO-CV
  // ========================================================================
  // One entry per surveyed observation (t >= 2, where autoregressive applies).
  // t = 1 is excluded because it uses a different likelihood structure.
  vector[N_obs] log_lik;

  // ========================================================================
  // PREDICTED OCCUPANCY PROBABILITY (full matrix)
  // ========================================================================
  matrix[N_years, N_sites] p_pred;

  // ========================================================================
  // RECOLONIZATION PROBABILITY
  // P(occupied[t,j] = 1 | occupied[t-1,j] = 0)
  // = inv_logit(alpha[j] + 0*gamma + delta_pop*log_N + delta_age*age)
  // This is the probability of returning to a site after absence.
  // ========================================================================
  matrix[N_years, N_sites] p_recol;

  // ========================================================================
  // PERSISTENCE PROBABILITY
  // P(occupied[t,j] = 1 | occupied[t-1,j] = 1)
  // = inv_logit(alpha[j] + gamma + delta_pop*log_N + delta_age*age)
  // ========================================================================
  matrix[N_years, N_sites] p_persist;

  {
    int idx = 0;

    for (t in 1:N_years) {
      for (j in 1:N_sites) {
        p_pred[t, j] = inv_logit(logit_p[t, j]);

        if (t >= 2) {
          // Recolonization: gamma * 0 = 0, so just baseline + covariates
          real logit_recol = alpha[j] + delta_pop * log_N_total[t];
          if (has_age_data == 1) {
            logit_recol += delta_age * age_index[t];
          }
          p_recol[t, j] = inv_logit(logit_recol);

          // Persistence: gamma * 1 = gamma
          p_persist[t, j] = inv_logit(logit_recol + gamma);

          // Log-likelihood for surveyed t >= 2 observations
          if (surveyed[t, j] == 1) {
            idx += 1;
            log_lik[idx] = bernoulli_logit_lpmf(occupied[t, j] | logit_p[t, j]);
          }
        } else {
          // t = 1: no recolonization/persistence defined
          p_recol[1, j] = inv_logit(alpha[j] + delta_pop * log_N_total[1]);
          p_persist[1, j] = inv_logit(alpha[j] + gamma + delta_pop * log_N_total[1]);
        }
      }
    }
  }
}
