# ============================================================================
# _targets.R — Pipeline definition for herring metapopulation analysis
# stier-2027-herring-metapopulation
#
# Stages:
#   1. Raw data files (format = "file")
#   2. Data cleaning (spawn, catch, PDO, predators)
#   3. Model data preparation
#   4. Model fitting (Stan, deployment = "main")
#   5. Diagnostics
#   6. Posterior extraction
#   7. Portfolio analysis
#   8. Figures (format = "file")
# ============================================================================

# Reader note:
# Read this file after the maintained function files and primary Stan models.
# The transformation logic lives in `R/`; `_targets.R` is the orchestration
# summary that wires those contracts together into a reproducible pipeline.

library(targets)
library(tarchetypes)

# ── Source all R/ functions ──
tar_source("R")

# ── Global options ──
tar_option_set(
  packages = c(
    # Core tidyverse
    "tidyverse", "here", "janitor",
    # Stan / Bayesian
    "cmdstanr", "posterior", "bayesplot", "loo", "tidybayes",
    # Figures
    "patchwork", "scales", "ggrepel",
    # Utilities
    "qs"
  ),
  format = "qs",
  workspace_on_error = TRUE
)

# ============================================================================
# PIPELINE
# ============================================================================

list(

  # ========================================================================
  # STAGE 1: Raw data files (tracked for changes)
  # ========================================================================

  # -- Legacy data (1940-2015) --
  tar_target(
    file_spawn_legacy,
    here("Data", "raw", "legacy-2019", "HG_Spawn_Survey_1940_2015.csv"),
    format = "file"
  ),

  tar_target(
    file_spawn_new,
    here("Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv"),
    format = "file"
  ),

  tar_target(
    file_catch_legacy,
    here("Data", "raw", "legacy-2019", "herring_catch_local2015.csv"),
    format = "file"
  ),

  tar_target(
    file_catch_new,
    here("Data", "raw", "dfo-catch", "herring_catch_local2024.csv"),
    format = "file"
  ),

  tar_target(
    file_pdo_legacy,
    here("Data", "raw", "legacy-2019", "pdo.csv"),
    format = "file"
  ),

  tar_target(
    file_pdo_extension,
    here("Data", "raw", "environmental", "pdo_2015_2025.csv"),
    format = "file"
  ),

  # -- Predator data --
  tar_target(
    file_ssl,
    here("Data", "raw", "predators",
         "Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv"),
    format = "file"
  ),

  tar_target(
    file_seal,
    here("Data", "raw", "predators",
         "Harbour_seal_counts_haulout_locs_BCcoast.csv"),
    format = "file"
  ),

  tar_target(
    file_whale,
    here("Data", "raw", "predators",
         "humpback_whale_NorthPacific_abundance_Cheeseman2024.csv"),
    format = "file"
  ),

  # -- SST data --
  tar_target(
    file_sst,
    here("Data", "raw", "environmental",
         "oisst_haida_gwaii_monthly_regional_avg_2014_2025.csv"),
    format = "file"
  ),

  # -- Distance matrix --
  tar_target(
    file_distance_matrix,
    here("Data", "raw",
         "Euclidean & effective distance matrices herring & Steller.xlsx"),
    format = "file"
  ),

  # ========================================================================
  # STAGE 2: Data cleaning
  # ========================================================================

  tar_target(
    spawn_clean,
    clean_spawn(
      path_legacy = file_spawn_legacy,
      path_new    = file_spawn_new
    )
  ),

  tar_target(
    catch_clean,
    clean_catch(
      path_legacy = file_catch_legacy,
      path_new    = file_catch_new
    )
  ),

  tar_target(
    pdo_clean,
    clean_pdo(
      path_legacy    = file_pdo_legacy,
      path_extension = file_pdo_extension
    )
  ),

  tar_target(
    predators_clean,
    clean_predators(
      path_ssl   = file_ssl,
      path_seal  = file_seal,
      path_whale = file_whale
    )
  ),

  tar_target(
    sst_clean,
    clean_sst(file_sst)
  ),

  # ========================================================================
  # STAGE 2b: Spatial data (distance matrix + predator indices)
  # ========================================================================

  # Distance matrix from pre-computed Excel file (effective water distances)
  tar_target(
    distance_matrix,
    load_distance_matrix(
      path_xlsx = file_distance_matrix,
      sheet     = "Herring Effective",
      units_out = "km"
    )
  ),

  # Section centroid coordinates (for spatially-weighting predator counts)
  tar_target(
    spawn_centroids,
    get_spawn_centroids(
      path_spawn_csv      = file_spawn_new,
      path_distance_xlsx  = file_distance_matrix
    )
  ),

  # Spatially-weighted predator indices (SSL + harbour seal)
  tar_target(
    predator_spatial,
    build_predator_spatial_index(
      ssl_data         = read_csv(file_ssl, show_col_types = FALSE),
      seal_data        = read_csv(file_seal, show_col_types = FALSE,
                                  locale = locale(encoding = "latin1")),
      spawn_coords     = spawn_centroids,
      distance_decay_km = 50
    )
  ),

  # ========================================================================
  # STAGE 3: Model data preparation
  # ========================================================================

  tar_target(
    model_data,
    prepare_model_data(
      spawn     = spawn_clean,
      catch     = catch_clean,
      pdo       = pdo_clean,
      predators = predators_clean,
      format    = "stan"
    )
  ),

  # Spatial model data (includes distance matrix + spatially-weighted predators)
  tar_target(
    model_data_spatial,
    prepare_model_data(
      spawn            = spawn_clean,
      catch            = catch_clean,
      pdo              = pdo_clean,
      predators        = predators_clean,
      format           = "stan",
      spatial          = TRUE,
      distance_matrix  = distance_matrix,
      predator_spatial = predator_spatial
    )
  ),

  # ========================================================================
  # STAGE 4: Model fitting (long-running, deployment = "main")
  # ========================================================================

  # Reader note:
  # The maintained targets graph currently wires the baseline biomass model
  # (`v1`) and the separate occupancy model end to end. The broader Stan
  # hierarchy (`m2`-`m6`, `v2`) is supported by `fit_model()` and documented
  # in the repo, but those fits are not all run automatically in this default
  # pipeline yet.

  tar_target(
    fit_v1,
    fit_model(
      stan_data     = model_data,
      version       = "v1",
      iter_warmup   = 1000L,
      iter_sampling = 2000L,
      chains        = 4L
    ),
    format     = "rds",
    deployment = "main"
  ),

  # v2 placeholder: predator covariates extension
  # tar_target(
  #   fit_v2,
  #   fit_model(
  #     stan_data     = model_data_v2,
  #     version       = "v2",
  #     iter_warmup   = 1000L,
  #     iter_sampling = 2000L,
  #     chains        = 4L
  #   ),
  #   deployment = "main"
  # ),

  # ========================================================================
  # STAGE 5: Diagnostics
  # ========================================================================

  tar_target(
    diagnostics_v1,
    check_diagnostics(fit_v1)
  ),

  # ========================================================================
  # STAGE 6: Posterior extraction
  # ========================================================================

  tar_target(
    posteriors_v1,
    extract_posteriors(fit_v1, stan_data = model_data)
  ),

  # ========================================================================
  # STAGE 7: Portfolio analysis
  # ========================================================================

  tar_target(
    portfolio_metrics,
    compute_portfolio(posteriors_v1$biomass_estimates)
  ),

  tar_target(
    synchrony_metrics,
    compute_synchrony(posteriors_v1$biomass_estimates, window = 10L)
  ),

  tar_target(
    site_occupancy,
    compute_site_occupancy(spawn_clean$long)
  ),

  # ========================================================================
  # STAGE 7b: Occupancy sub-model (collective memory)
  # ========================================================================

  tar_target(
    occupancy_data,
    prepare_occupancy_data(
      spawn_clean  = spawn_clean,
      path_legacy  = file_spawn_legacy,
      path_new     = file_spawn_new
    )
  ),

  tar_target(
    fit_occupancy_model,
    fit_occupancy(
      occupancy_data,
      chains          = 4L,
      iter_warmup     = 1000L,
      iter_sampling   = 2000L,
      adapt_delta     = 0.90
    ),
    format     = "rds",
    deployment = "main"
  ),

  tar_target(
    occupancy_posteriors,
    extract_occupancy_posteriors(
      fit  = fit_occupancy_model,
      occupancy_data = occupancy_data
    )
  ),

  # ========================================================================
  # STAGE 8: Figures (each returns saved file path)
  # ========================================================================

  tar_target(
    fig_spawn_index_file,
    save_figure(
      fig_spawn_index(spawn_clean$long),
      filename = "fig_spawn_index.pdf",
      width = 183, height = 200
    ),
    format = "file"
  ),

  tar_target(
    fig_biomass_ts_file,
    save_figure(
      fig_biomass_timeseries(posteriors_v1$biomass_estimates),
      filename = "fig_biomass_timeseries.pdf",
      width = 183, height = 120
    ),
    format = "file"
  ),

  tar_target(
    fig_fishing_file,
    save_figure(
      fig_fishing_rates(posteriors_v1$fishing_estimates),
      filename = "fig_fishing_rates.pdf",
      width = 170, height = 100
    ),
    format = "file"
  ),

  tar_target(
    fig_synchrony_file,
    save_figure(
      fig_synchrony(synchrony_metrics),
      filename = "fig_synchrony.pdf",
      width = 170, height = 120
    ),
    format = "file"
  ),

  tar_target(
    fig_portfolio_file,
    save_figure(
      fig_portfolio(portfolio_metrics),
      filename = "fig_portfolio.pdf",
      width = 170, height = 100
    ),
    format = "file"
  ),

  tar_target(
    fig_predator_file,
    save_figure(
      fig_predator_effects(predators_clean),
      filename = "fig_predator_effects.pdf",
      width = 183, height = 150
    ),
    format = "file"
  ),

  tar_target(
    fig_occupancy_file,
    save_figure(
      fig_occupancy_heatmap(occupancy_data, occupancy_posteriors),
      filename = "fig_occupancy_heatmap.pdf",
      width = 183, height = 200
    ),
    format = "file"
  ),

  tar_target(
    fig_recolonization_file,
    save_figure(
      fig_recolonization(occupancy_posteriors),
      filename = "fig_recolonization.pdf",
      width = 170, height = 100
    ),
    format = "file"
  ),

  # ========================================================================
  # STAGE 9: Reversibility / hysteresis analysis figures
  # These targets read from Output/diagnostics/reversibility_*.csv files
  # produced by Code/run_reversibility_suite.sh.  They are downstream of
  # the posterior-extraction + portfolio targets (stages 6-7) because the
  # diagnostic CSVs depend on m1_stier_11 posterior outputs.
  #
  # Discrimination table file target (the headline output)
  # ========================================================================

  tar_target(
    reversibility_discrimination_file,
    {
      path <- here::here(
        "Output", "diagnostics", "reversibility_discrimination_table.csv"
      )
      if (!file.exists(path)) {
        stop("reversibility_discrimination_table.csv not found. ",
             "Run Code/run_reversibility_suite.sh first.")
      }
      path
    },
    format = "file"
  ),

  tar_target(
    fig_reversibility_lambda_file,
    save_figure(
      fig_lambda_trajectory(),
      filename = "reversibility_lambda_trajectory.pdf",
      width = 170, height = 120
    ),
    format = "file"
  ),

  tar_target(
    fig_reversibility_state_df_file,
    save_figure(
      fig_state_dependent_dF(),
      filename = "reversibility_state_df.pdf",
      width = 170, height = 140
    ),
    format = "file"
  ),

  tar_target(
    fig_reversibility_potential_file,
    save_figure(
      fig_potential_pre_post(),
      filename = "reversibility_potential.pdf",
      width = 183, height = 120
    ),
    format = "file"
  ),

  tar_target(
    fig_reversibility_driver_loop_file,
    save_figure(
      fig_driver_loop(),
      filename = "reversibility_driver_loop.pdf",
      width = 170, height = 140
    ),
    format = "file"
  ),

  tar_target(
    fig_reversibility_controls_file,
    save_figure(
      fig_controls_panel(),
      filename = "reversibility_controls.pdf",
      width = 183, height = 130
    ),
    format = "file"
  )
)
