#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

log_file="may9_analysis_suite_refresh.log"

{
  echo "[$(date)] Starting May 9 analysis suite refresh"

  Rscript Code/02c_integrate_hg_predator_repo_products.R

  Rscript Code/06e_m1_stier_9_focal_reporting.R
  Rscript Code/06f_m1_stier_11_portfolio_figures.R
  Rscript Code/07_m1_stier_11_population_driver_analysis.R
  Rscript Code/07b_m1_stier_11_driver_robustness.R
  Rscript Code/07c_m1_stier_11_section_pressure_screen.R
  Rscript Code/07d_m1_stier_11_fit_quality_summary.R
  Rscript Code/07al_positive_spawn_fit_caveat.R
  Rscript Code/07e_m1_stier_11_spatial_concentration.R
  Rscript Code/07g_survey_method_coverage_audit.R
  Rscript Code/07h_m1_stier_11_residual_spatial_correlation.R
  Rscript Code/07i_m1_stier_11_cryptic_collapse_screen.R
  Rscript Code/07j_spawn_timing_substrate_screen.R
  Rscript Code/07k_m1_stier_11_driver_confounding_audit.R
  Rscript Code/07l_m1_stier_11_postclosure_recovery.R
  Rscript Code/07m_m1_stier_11_section_scorecard.R
  Rscript Code/07n_m1_stier_11_spatial_shift.R
  Rscript Code/07o_m1_stier_11_current_year_status.R
  Rscript Code/07p_m1_stier_11_uncertainty_audit.R
  Rscript Code/07au_current_biomass_estimate.R
  Rscript Code/07ay_biomass_uncertainty_decomposition.R
  Rscript Code/07t_spawn_index_scale_audit.R
  Rscript Code/07u_legacy_shi_overlap_sensitivity.R
  Rscript Code/07v_observed_occupancy_transition_screen.R
  Rscript Code/07w_density_dependence_screen.R
  Rscript Code/07y_fishing_pressure_decomposition.R
  Rscript Code/07ai_fishing_closure_response.R
  Rscript Code/07z_pdo_climate_signal_screen.R
  Rscript Code/07aj_pdo_window_sensitivity.R
  Rscript Code/07aa_section_mechanism_typology.R
  Rscript Code/07ab_section_change_contribution.R
  Rscript Code/07ac_mhw_recovery_screen.R
  Rscript Code/07ad_survey_coverage_zero_ambiguity.R
  Rscript Code/07ae_predator_data_feasibility_audit.R
  Rscript Code/07bb_predator_spatial_exposure_prototype.R
  Rscript Code/07af_section_narrative_table.R
  Rscript Code/07ah_section_driver_dossiers.R
  Rscript Code/07az_section_action_matrix.R
  Rscript Code/07ba_lead_section_local_audit.R
  Rscript Code/07bd_lead_section_location_transition.R
  Rscript Code/07be_lead_section_location_map.R
  Rscript Code/07bf_lead_spawn_location_predator_proximity.R
  Rscript Code/07bg_lead_location_followup_targets.R
  Rscript Code/07bc_section_recovery_covariate_screen.R
  Rscript Code/07bt_postclosure_recovery_mechanism_screen.R
  Rscript Code/07bu_future_lag_negative_control_audit.R
  Rscript Code/07bh_covariate_readiness_registry.R

  Rscript Code/03c_bayesian_fit_audit.R
  Rscript Code/03d_posterior_predictive_checks_v3.R
  Rscript Code/04_compare_models_v3.R
  Rscript Code/04b_interpret_model_outputs.R

  if [[ -f "Data/processed/m2_stier_site_growth_fit.rds" ]]; then
    Rscript Code/07f_m2_stier_site_growth_postfit.R
  else
    echo "[$(date)] Skipping m2 postfit; m2 fit artifact is not present yet."
  fi

  if [[ -f "Data/processed/m1_stier_method_sensitivity_fit.rds" ]]; then
    Rscript Code/07r_m1_stier_method_sensitivity_postfit.R
  else
    echo "[$(date)] Skipping method-sensitivity postfit; fit artifact is not present yet."
  fi

  if [[ -f "Data/processed/m1_stier_obs_hier_fit.rds" ]]; then
    Rscript Code/07am_m1_stier_obs_hier_postfit.R
  else
    echo "[$(date)] Skipping m1_stier_obs_hier postfit; fit artifact is not present yet."
  fi

  if [[ -f "Data/processed/m3_stier_distance_fit.rds" ]]; then
    Rscript Code/07s_m3_stier_distance_postfit.R
  else
    echo "[$(date)] Skipping m3 distance postfit; fit artifact is not present yet."
  fi

  Rscript Code/07x_driver_model_triage.R
  Rscript Code/07q_may9_headline_findings_table.R
  Rscript Code/07ag_integrated_evidence_matrix.R
  Rscript Code/07ak_model_branch_status_table.R
  Rscript Code/07ax_stier_signal_persistence_summary.R
  Rscript Code/07aw_promoted_baseline_evidence_package.R
  Rscript Code/07av_may11_status_snapshot.R
  python3 cloud/summarize_aws_batch_status.py
  Rscript Code/09_check_document_references.R

  echo "[$(date)] May 9 analysis suite refresh complete"
} 2>&1 | tee "$log_file"
