# Full Analysis Model-Farm Scope

Generated: 2026-05-10

This is the working scope for using local runs plus AWS to push the Haida Gwaii
herring metapopulation analysis forward. The goal is not to run every possible
model. The goal is to run enough well-scoped model families to separate three
questions:

1. What is happening to the population spatially?
2. Which drivers are plausible versus confounded?
3. Which model features improve inference rather than only adding complexity?

## Core Rule

Treat the analysis as iterative rounds:

1. submit a small batch of jobs;
2. collect artifacts from S3;
3. audit sampler health, posterior predictive fit, LOO/ELPD, and scientific
   interpretability;
4. promote, archive, or revise each branch;
5. generate the next manifest slice.

Do not launch all speculative branches at once. AWS gives throughput, but bad
posterior geometry still has to be diagnosed.

## Model Families

### 1. Baseline / Observation

Purpose:

- establish the best section-level biomass trajectory;
- handle ambiguous zeros;
- handle surface vs dive survey differences;
- keep the model close enough to Stier et al. to remain interpretable.

Current jobs:

- `m1_stier_11`: promoted baseline;
- `m1_stier_obs_hier`: completed clean negative result, held because
  positive-spawn calibration worsened;
- `m1_stier_method_sensitivity`: q / method / zero-treatment sensitivity.

Promotion criteria:

- 0 divergences or a clearly fixable small number;
- low treedepth pressure;
- acceptable E-BFMI;
- better early surface-era positive-spawn calibration than `m1_stier_11`;
- no loss of modern dive-era fit;
- conclusions about occupancy/concentration remain stable or are clearly
  explained.

Rerun triggers:

- surface-era residuals remain strongly biased;
- q terms are poorly identified;
- section observation variance absorbs obvious process signal;
- posterior predictive zero/positive split is worse than `m1_stier_11`.

### 2. Site Heterogeneity / Growth

Purpose:

- test whether sections differ in productivity/recovery, not just observation
  scale;
- identify whether Cumshewa, Louscoone, Naden, Skidegate, etc. have distinct
  dynamics.

Current jobs:

- `m2_stier_site_growth`.

Promotion criteria:

- sampler-clean or close;
- site-growth parameters are not pure noise;
- improves section-level residual structure;
- does not destroy the observation calibration.

Rerun triggers:

- funnel/divergence problems;
- site parameters too weakly identified;
- growth heterogeneity confounds with q or observation variance.

### 3. Spatial Process

Purpose:

- test whether residual population dynamics are spatially correlated after
  accounting for survey method and section heterogeneity;
- evaluate metapopulation synchrony/portfolio erosion mechanisms.

Current jobs:

- `m3_stier_distance`;
- `m3_stier_distance_reloo` array.

Promotion criteria:

- exact re-LOO resolves high Pareto-k points without revealing catastrophic
  instability;
- spatial range/process variance are estimable;
- spatial process improves residual autocorrelation or section synchrony
  interpretation.

Rerun triggers:

- high-k points dominate model ranking;
- distance range is unidentified;
- spatial covariance causes pathologies;
- exact re-LOO indicates PSIS was misleading.

### 4. Density Dependence

Purpose:

- test whether recovery/non-recovery reflects density-dependent dynamics.

Current jobs:

- `m3_dd_global`;
- archived/debug `m3_v5`.

Promotion criteria:

- density term is identifiable;
- posterior predictive fit improves without sampler pathology;
- density effect changes biological interpretation beyond the baseline.

Rerun triggers:

- divergence/treedepth patterns like older `m3_v5`;
- density term confounds with observation zeros;
- no material improvement over observation-only branches.

### 5. Predators

Purpose:

- evaluate whether predator indices/exposure explain recent or section-specific
  non-recovery.

Current jobs:

- `m5_v5`;
- `m5_combined`.

Important limitation:

The current predator data are heavily time-confounded and not yet a clean
section-level exposure product. These branches are exploratory until predator
exposure is spatialized.

Promotion criteria:

- predator effect remains plausible after time/fishery/climate confounding
  checks;
- effect is not just a proxy for recent years;
- posterior predictive checks improve for affected sections.

Rerun triggers:

- predator coefficient tracks calendar time;
- predator branch worsens q/observation calibration;
- no section-level exposure gradient exists.

### 6. Climate / Timing / Habitat

Purpose:

- test whether PDO, marine heatwave period, spawn timing, and substrate explain
  residual non-recovery or section differences.

Current state:

- PDO window screens are cheap and already partly done;
- spawn timing/substrate should be treated first as covariate screens, not a
  large Stan branch.

Promotion criteria:

- covariate signal is not just shared time trend;
- section-level variation supports the mechanism;
- signal explains residuals from the promoted baseline.

Rerun triggers:

- covariate is collinear with fishery closure or survey method;
- effect is sensitive to arbitrary lag/window choice.

## AWS Round Plan

### Round 0: Infrastructure Smoke

Run:

- `smoke_m1_stier_obs_hier`

Goal:

- prove container image, S3 permissions, R package stack, Stan compilation, and
  output sync work.
- run the optional `HERRING_R_STAN_PREFLIGHT_COMPILE=1` path once, so RStan
  toolchain failures are caught before long jobs.

Stop if:

- package install/container path fails;
- job role cannot read/write S3;
- logs/status files do not sync.

### Round 1: Observation Foundation

Completed / current read:

- `m1_stier_obs_hier` finished sampler-clean but did not supersede
  `m1_stier_11`;
- `m1_stier_method_sensitivity` is clean context, not promotion;
- the early surface-era positive-spawn caveat remains the key observation
  limitation.

Goal:

- prevent future AWS rounds from rerunning unchanged observation branches and
  instead focus on either exact re-LOO/promotion checks or genuinely new
  observation/data-scale ideas.

Outputs to inspect:

- sampler diagnostics;
- positive-spawn residuals by method;
- zero/ambiguous-zero behavior;
- q and observation-variance posterior summaries;
- main biomass/occupancy/concentration figures.

### Round 2: Parallel Process Branches

Run only from the promoted `m1_stier_11` baseline unless a new observation
branch clears the promotion gate:

- `m2_stier_site_growth` is already clean but held;
- `m3_stier_distance` is clean context and needs exact re-LOO triage before any
  promotion discussion;
- maybe `m3_dd_global` as a sensitivity branch.

Goal:

- separate section heterogeneity, spatial covariance, and density dependence.

### Round 3: Mechanism Branches

Run only after process branches have stable geometry:

- predator branches;
- time-varying/productivity branches;
- timing/habitat branches if screens justify them.

Goal:

- test drivers, not just fit.

### Round 4: Final Sensitivities

Run:

- q prior sensitivity;
- zero treatment sensitivity;
- surface-era variance sensitivity;
- exact re-LOO for any high-k promoted candidate;
- short reduced-iteration checks for talk figures if needed.

Goal:

- determine which conclusions are robust enough for the Monday talk and later
  manuscript work.

## Result Collection Loop

AWS output should be treated as a staging area until we explicitly promote a
job's artifacts into the working repo.

For each AWS round:

```sh
AWS_PROFILE=herring cloud/sync_model_farm_results.sh "$HERRING_S3"
```

Review:

```sh
Output/diagnostics/cloud_model_farm_status.csv
```

Promote a successful job explicitly:

```sh
cloud/promote_cloud_results.sh cloud/aws_results/<prefix>/jobs/<job_id>
```

Then rerun:

```sh
Rscript Code/03c_bayesian_fit_audit.R
Rscript Code/03d_posterior_predictive_checks_v3.R
Rscript Code/04_compare_models_v3.R
Rscript Code/04b_interpret_model_outputs.R
zsh Code/08_refresh_may9_analysis_suite.sh
```

## Decision Categories

Every branch should end in exactly one of these states:

- `promoted`: use for headline inference;
- `supporting_sensitivity`: not headline, but checks robustness;
- `needs_rerun`: useful branch with fixable computational/statistical issue;
- `archived_excluded`: sampler pathology, bad fit, or not scientifically useful;
- `data_blocked`: conceptually useful but missing covariate/data product.

## What Not To Do

- Do not use AWS to run large age/size-structured models yet.
- Do not launch predator models as headline candidates until predator exposure
  is spatialized or confounding is handled.
- Do not compare raw LOO across different likelihood units without explicit
  caveats.
- Do not promote a model solely because it has lower LOOIC if the sampler or PPC
  fails.
- Do not let surface-era fit problems get hidden by good modern dive-era fit.

## Talk-Oriented Outputs

For the Monday talk, prioritize outputs that answer:

1. Where is biomass now?
2. Which sections recovered versus remained depleted?
3. Is the portfolio spatially concentrated?
4. How much of the story is fishing history versus post-closure non-recovery?
5. Are observation-method differences changing the headline?
6. Are predators/climate plausible drivers or still confounded?

The cloud farm should serve these questions, not distract from them.
