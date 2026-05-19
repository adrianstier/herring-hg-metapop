# Design Spec — Comprehensive Early-Warning-Indicator (EWS) Analysis of the Haida Gwaii Herring Metapopulation

Date: 2026-05-19
Status: Approved design (brainstorming complete) — pending user review before plan
Author: Claude (brainstorming session with Adrian Stier)
Repo: `stier-2027-herring-metapopulation`

---

## 1. Purpose and deliverable

Build a **comprehensive, paper-grade early-warning-signal analysis** of the
Haida Gwaii Pacific herring (*Clupea pallasii*) metapopulation (11 sections,
spawn record 1951–2025), with **a claim-safe subset carved out for the Royal
Society *Tipping Points in Ocean Systems* talk (London, Wed 20 May 2026, 09:30,
Session 5)**.

The analysis answers, rigorously: **is metapopulation synchrony (and its change
over time) an early warning indicator of resilience loss, and how does it
compare to the full battery of generic and spatial EWS?**

Two tracks, sequenced:

- **Paper-grade track** (primary, multi-day) — full battery, surrogate nulls,
  sensitivity grid, false-positive audit, power controls, lead-time matrix,
  synthesis. Lives in the core pipeline.
- **Talk subset** (Phase 0, attempt tonight, best-effort, degradable) — one
  claim-safe slide + backup + speaker notes, firewalled into
  `talk-usuk-forum-2026/`. Explicit degrade rule if it cannot be made
  claim-safe in time.

This spec is the contract for a single implementation plan. Approach **A**
(comprehensive dual-track EWS compendium) was selected over a spatial-first or
methods-benchmark framing.

---

## 2. Framing and claim structure

### 2.1 Retrospective logic — multi-candidate transitions, not one asserted tip

The HG record has **no single agreed regime shift**, and the project's
hypotheses doc (`docs/herring-non-recovery-hypotheses.md` §11) explicitly makes
**non-identifiability the scientific point**. Therefore the analysis does not
assert a transition. It:

1. Objectively detects **candidate regime-shift points** via STARS
   (sequential-t / Rodionov) and breakpoint analysis run on (a) aggregate
   biomass, (b) synchrony φ, and (c) occupancy / effective-n.
2. Also tests against the **three documented era boundaries**: the 1960s
   reduction-fishery crash, the 2005 fishery closure, and the recent
   synchronization episode.
3. For each candidate, tests whether each indicator rose in the lead-up.

**Primary deliverable = a lead-time matrix:** which indicators lead which
candidate transitions, by how many years, with surrogate significance — *not*
"the system tipped in year X".

### 2.2 Claim boundaries (hard-wired; per `docs/talk-model-claim-control-sheet.md`)

- EWS are **correlative resilience indicators, never proof of a
  fold/bifurcation**. Every output, figure, and slide carries this framing.
- Latent layer = `m1_stier_11` only. No held branches
  (`m1_stier_obs_hier`, `m2_*`, `m3_*`, `m5_*`, etc.) ever enter.
- The **early surface-era positive-spawn calibration caveat**
  (`Output/diagnostics/positive_spawn_fit_caveat.md`) is attached to every
  pre-~1970 indicator value.
- "Loss of synchrony-based portfolio buffering" ≠ "biomass recovered."
  Structure and biomass are reported as **distinct state variables**.
- DFO SCA outputs are **not** an EWS data layer (control-sheet rule); context
  only, never co-equal.
- A standing **claim-control addendum**
  (`Output/diagnostics/ews_claim_control.md`) maps every EWS result to a safe
  sentence and a "do not say".

### 2.3 Honest-failure design

The analysis is built to be able to fail. If the survey-artifact audit (§5.3)
shows the documented two-era catchability shift alone reproduces the
AR(1)/variance/synchrony rise, **that becomes the headline** ("the apparent
signal is a measurement artifact"), not a buried caveat.

---

## 3. Indicator battery

Three tiers. Synchrony is treated three ways so it sits *inside* EWS theory,
not as a loose metric.

### Tier 1 — Generic temporal EWS (rolling window, on aggregate biomass / total spawn)

Rising variance & SD · lag-1 autocorrelation AR(1) · AR(1)-fit coefficient /
return rate · skewness · kurtosis (flickering) · CV · detrended fluctuation
analysis (DFA) exponent · conditional heteroskedasticity (Dakos & Kéfi 2014) ·
spectral reddening (low:high frequency density ratio) · time-varying AR(1) via
DLM and nonparametric drift–diffusion–jump (Carpenter–Brock) as the advanced
sibling.

### Tier 2 — Metapopulation / spatial EWS (synchrony heart)

| Indicator | Definition | EWS rationale | Repo reuse |
|---|---|---|---|
| Loreau–de Mazancourt φ | `var(Σ Xj)/(Σ sd(Xj))²` | rising φ = loss of portfolio buffering = resilience loss | `R/05_portfolio.R::compute_synchrony_lm` |
| Mean pairwise cross-correlation | moving-window Spearman | synchronization → shared collapse | `R/05_portfolio.R::compute_synchrony` |
| Gross η synchrony | bounded −1..1 sibling | robustness check on φ | new |
| Spatial variance & spatial skew | variance/skew across sections within year | recognized spatial EWS (Kéfi/Génin) | new |
| Spatial correlation / Moran's I | uses section lat/long (in spawn CSV) | rising spatial autocorrelation precedes transitions | new |
| **Dominant eigenvalue λ_max of cross-section covariance / leading EOF** | PCA of section×year matrix | **formal link: near a transition fluctuations align along one mode; λ_max grows; φ is its scalar shadow** | new |
| **MAR(1) community-matrix eigenvalue** | largest eigenvalue of estimated B / interaction matrix | multivariate critical slowing down; ties to repo state-space covariance machinery | new (MARSS or existing Stan) |
| Portfolio CV-ratio collapse | mean subpop CV / aggregate CV | structural EWS of buffering loss | `R/05_portfolio.R::compute_portfolio` |
| Occupancy / range-contraction ratchet | n occupied, effective-n | slow structural state variable | `portfolio_metrics_annual.csv`, `R/05_portfolio.R::compute_site_occupancy` |

### Tier 3 — Composite

Standardized, rank-aggregated multi-indicator composite (Drake & Griffen
style) + **Kendall's τ trend statistic per indicator** over each candidate
pre-transition window with surrogate-based significance.

**Synchrony answer** is therefore three-fold: (1) directly via φ and pairwise
correlation; (2) elevated into theory via covariance λ_max / leading EOF
(synchrony = scalar projection of growing dominant-mode variance); (3) as
multivariate critical slowing down via the MAR(1) eigenvalue — all benchmarked
against the generic battery so we can state whether synchrony *leads* the
other indicators.

---

## 4. Data layers, windowing, detrending

### 4.1 Two co-equal, posterior-aware layers

- **Observed:** `Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv`
  (section×year spawn, 1951–2025). Zeros handled with the `m1_stier_11`
  ambiguous-zero convention; low-coverage years flagged from
  `Output/diagnostics/survey_coverage_zero_ambiguity*` and
  `survey_coverage_low_coverage_years.csv`. Uneven spacing handled explicitly
  (interpolate only where defensible; the observed/latent asymmetry is itself
  reported).
- **Latent:** `m1_stier_11` posterior section/total biomass via the existing
  posterior-extraction layer (`R/05_portfolio.R` consumes
  `extract_posteriors()`-style output; `Output/diagnostics/m1_stier_11_section_biomass_by_year.csv`,
  `m1_stier_11_total_biomass_by_year.csv`). **EWS computed over posterior
  draws → every indicator gets a credible interval, not a point estimate.**

Both layers are reported side by side; the discrepancy is a headline result
("is the signal real or model-made").

### 4.2 Spatial unit — both co-equal primary

- **core-9** (drop `Tasu Sound & Gowgaia Bay`, `Naden Harbour`; matches Stier
  2020 and the existing portfolio default; current-biomass uncertainty is
  ~92% driven by those two sparse sections) **and**
- **all-11**

are run as **co-equal primary** spatial units (both reported as headline, not
one as a sensitivity of the other). **Leave-one-section-out** remains a
sensitivity within the grid (§5.2).

### 4.3 Windowing and detrending — reported as surfaces

These are where EWS papers are attacked, so both are swept, not chosen once:

- **Rolling-window sweep:** 10 / 15 / 20 / 25-yr + half-series convention
  (repo currently uses 10-yr).
- **Detrending sweep:** none / first-difference / linear / Gaussian-kernel
  with bandwidth sweep (Dakos default) / loess.

An indicator only "counts" if its Kendall-τ sign and significance survive the
grid.

### 4.4 Software

R. `earlywarnings` (Dakos) for generic temporal; `spatialwarnings`
(Génin/Kéfi) for spatial; bespoke code for synchrony (reuse/extend
`R/05_portfolio.R`), covariance EOF/λ_max, MAR(1) eigenvalue (`MARSS` or the
existing Stan state-space), composite, Kendall τ + surrogates. Latent-layer
indicators computed over posterior draws via the existing extraction layer.

---

## 5. Nulls, significance, sensitivity, audits

1. **Trend significance.** AR(1) / phase-randomized surrogate series
   (Dakos 2008) → null distribution of Kendall τ per indicator; bootstrap CIs
   on rolling indicators; for the latent layer, combine surrogate + posterior
   uncertainty.
2. **Sensitivity grid.** window × detrending × sections-unit (core-9 / all-11 /
   leave-one-out) × estimator (φ vs η; Pearson vs Spearman) → a heatmap of τ
   sign/significance. Robust = holds across the grid.
3. **Survey-method false-positive audit (headline-capable).** Simulate a
   metapopulation with *no resilience change* but *with* the documented
   two-era catchability shift, zero-ambiguity, and survey-coverage changes
   (parameterized from `m1_stier_11` q estimates +
   `survey_coverage_zero_ambiguity*` tables). Any indicator that "detects" a
   transition in this artifact-only null is **disqualified for the observed
   layer**; if the real observed signal is reproduced by the artifact alone,
   that is the result.
4. **Power calibration (Boettiger–Hastings caution).** Positive control
   (simulated approaching saddle-node / Allee metapopulation at HG cadence +
   noise → battery must detect) and negative control (stationary
   metapopulation → low false-positive rate), run *before* interpreting HG.

---

## 6. Architecture, deliverables, firewall

### 6.1 Code (follows repo conventions: numbered `R/` lib + `Code/` diagnostics + `_targets.R` + `Output/diagnostics/`)

- `R/11_early_warning.R` — reusable functions: `generic_ews_battery()`,
  `spatial_ews_battery()`, `synchrony_ews()` (wraps/extends `05_portfolio.R`),
  `covariance_eofs()`, `mar1_eigenvalue()`, `composite_ews()`,
  `kendall_surrogate_test()`, `ews_sensitivity_grid()`,
  `survey_artifact_null()`, `ews_positive_negative_controls()`,
  `detect_candidate_transitions()`, `ews_lead_time_matrix()`.
- `Code/11_ews_*.R` family, dependency-ordered:
  aggregate-generic → spatial-synchrony → covariance-eigenstructure →
  candidate-transitions → surrogate-significance → sensitivity-grid →
  survey-artifact-audit → controls-power → lead-time-matrix → synthesis.
  (Exact filenames finalized in the plan; `11_ews_*` chosen to avoid the
  crowded `07*` namespace.)
- `Code/run_ews_suite.sh` — dependency-ordered runner mirroring
  `Code/08_refresh_may9_analysis_suite.sh`.
- `_targets.R` — new EWS stage downstream of posterior extraction + portfolio.

### 6.2 Outputs (`Output/diagnostics/`)

`ews_lead_time_matrix.{csv,md}` · `ews_generic_aggregate.csv` ·
`ews_spatial_synchrony.csv` · `ews_covariance_eigenstructure.csv` ·
`ews_candidate_transitions.csv` · `ews_surrogate_significance.csv` ·
`ews_sensitivity_grid.csv` · `ews_survey_artifact_audit.md` ·
`ews_controls_power.md` · `ews_synthesis.md` (readable narrative) ·
`ews_claim_control.md` (safe-sentence ↔ do-not-say map).

### 6.3 Figures (pub-figure-pipeline / `theme_pub`)

EWS dashboard (indicator trajectories vs candidate transitions, observed vs
latent) · synchrony↔eigenvalue panel · sensitivity heatmap · surrogate-null
panel · survey-artifact-audit panel. All via the Figure Iteration Protocol.

### 6.4 Firewall

Nothing imported from `talk-usuk-forum-2026/` into the core pipeline. Talk
numbers are pulled **from** these core EWS outputs only, never the reverse.
Consistent with `CLAUDE.md` and `talk-usuk-forum-2026/README.md`.

---

## 7. Talk-subset sequencing (talk is tomorrow 09:30 London)

The full build is multi-day; the talk is in hours.

- **Phase 0 (attempt tonight; claim-safe; firewalled into
  `talk-usuk-forum-2026/`):** reuse already-computed
  `Data/processed/portfolio_metrics_rolling.csv` (φ 0.75→0.40,
  growth-corr 0.04→0.36) and add the single most defensible new panel only —
  synchrony φ + covariance λ_max / leading-EOF share, on **both** observed and
  `m1_stier_11` latent, with Kendall τ + AR(1)-surrogate p, and the
  survey-artifact caveat printed on the slide. One slide + one backup +
  speaker-note block with claim-control sentences.
- **Explicit degrade rule:** if Phase 0 cannot be made claim-safe in time
  (e.g., the artifact audit is unfinished), fall back to the existing
  portfolio framing already in the deck and show **no** EWS slide rather than
  overclaim.
- **Phase 1–N (post-talk):** the full paper-grade battery, controls,
  sensitivity grid, lead-time matrix, synthesis — per §3–§6.

---

## 8. Numerical robustness / edge cases ("error handling" for an analysis)

- Short series / short windows: enforce minimum n per window; emit NA + reason,
  never a silent number.
- Sparse sections / all-zero windows: explicit guards (mirror existing
  `compute_synchrony_lm` valid-column logic); record dropped units.
- Uneven spacing & missing years: documented interpolation policy; observed vs
  latent asymmetry reported, not hidden.
- Posterior draws: indicators summarized as median + CI; never collapse to a
  point before the CI is computed.
- Determinism: fixed seeds for all surrogate/simulation steps; seeds recorded
  in outputs.

## 9. Verification / testing

- Unit-level: synchrony/EOF/λ_max functions checked against analytic cases
  (perfect synchrony φ→1, perfect asynchrony φ→0; known-covariance λ_max).
- Power controls (§5.4) are the integration test: battery must detect a
  simulated approaching fold and stay quiet on a stationary system before any
  HG interpretation is trusted.
- Reproducibility: `Code/run_ews_suite.sh` regenerates all outputs in
  dependency order from a clean state; `_targets.R` invalidation respected.
- Cross-figure consistency via `audit_figure_consistency()`.

## 10. Out of scope (YAGNI)

- No new Stan model branches; no promotion of held branches.
- No age-structured / Doherty catch-at-age EWS.
- No DFO-SCA EWS layer (context only).
- No new field/data acquisition.
- No talk-deck redesign beyond the single Phase-0 panel + backup.

---

## 11. Key references

Scheffer et al. 2009 *Nature* (EWS / critical slowing down); Carpenter et al.
2011 *Science* (whole-lake EWS proof); Dakos et al. 2008 *PNAS*, 2012 *PLoS
ONE* (methods + surrogates); Dakos & Kéfi 2014 (conditional heteroskedasticity,
spatial EWS); Génin et al. 2018 (`spatialwarnings`); Kéfi et al. 2014 (spatial
EWS); Boettiger & Hastings 2012 *J R Soc Interface* (EWS false-alarm caution);
Drake & Griffen 2010 *Nature* (composite EWS); Loreau & de Mazancourt 2008 *Am
Nat* (synchrony φ); Gross et al. 2014 *Am Nat* (synchrony η); Schindler et al.
2010 *Nature* (portfolio effect); Stier et al. 2020 *Ecosphere* (HG portfolio
erosion); Ono et al. 2025 *Nature* (collective-memory loss).
