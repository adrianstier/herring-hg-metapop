# Design Spec — Reversibility, Hysteresis & Alternative-State Analysis of the Haida Gwaii Herring Metapopulation

Date: 2026-05-19
Status: Approved design (brainstorming complete) — pending user review before plan
Author: Claude (brainstorming session with Adrian Stier)
Repo: `stier-2027-herring-metapopulation`
Sibling spec: `docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md`

---

## 1. Purpose and deliverable

Build a **paper-grade, HG-internal dynamical-systems analysis** that tests
whether the post-collapse Haida Gwaii Pacific herring (*Clupea pallasii*)
metapopulation occupies a **different dynamical regime** than the pre-collapse
system, and whether the absence of recovery after the fishery closure is
**path-dependent (hysteretic)** rather than slow-but-reversible.

This is the **reversibility/attractor** analysis. It is a *sibling* to the
early-warning-signal (EWS) spec, not a replacement:

- The EWS spec answers: *did generic and spatial indicators rise in the lead-up
  to candidate transitions?* (critical-slowing-down lead-time matrix;
  deliberately does **not** assert a transition).
- **This spec answers:** *is the post-collapse system in a different attractor,
  and is the failure to recover path-dependent — or did the effective driver
  simply never return?* (empirical dynamic modeling + reconstructed potential +
  driver-space geometry).

Together they form the full "tipping-point evidence" picture as **two coherent
specs**, sharing infrastructure (candidate-transition detection,
survey-artifact null, posterior extraction, portfolio functions,
claim-control discipline) and cross-referencing each other. Neither supersedes
the other.

The selected organizing spine is **integrated A+C+B**:

- **A (engine)** — empirical dynamic modeling (EDM / S-map, Sugihara school) is
  the evidence core.
- **C (frame)** — the 2005 fishery closure as a within-HG natural experiment;
  the driver–state path geometry is the identification/narrative frame.
- **B (corroboration + talk visual)** — the reconstructed effective potential
  `U(x)` before vs after is the most audience-legible corroboration and the
  single downstream talk panel.

The top-level deliverable is a **discrimination table**, *not* "the system
tipped in year X." One claim-safe talk panel is a downstream byproduct with
**no timeline pressure** (the Royal Society deck is already shipped and
claim-safe; this analysis informs the 2027 paper first and the talk only when
ready).

Approach **Integrated A+C+B** was selected over EDM-only (A), potential-only
(B), or driver-geometry-only (C). Identification backbone: **HG-internal only**
(no coastwide/WCVI control limb) — the effective-driver reconstruction, not an
external control, carries the "did the driver actually return?" discrimination.

---

## 2. The question, made falsifiable

Three coupled questions, each able to return an **honest negative** that is
itself a publishable, talk-relevant result.

### 2.1 Q1 — Nonlinearity gate

Is HG herring dynamics low-dimensional, **state-dependent nonlinear** at all?
Tested by the S-map θ (nonlinearity) test under proper surrogates. A
linear-stochastic verdict is a real result that *weakens* the scalar-fold story
and *supports* the talk's "the tip is structural/spatial, not a simple
one-dimensional fold." Alternative stable states require nonlinearity; this is
the entry gate.

### 2.2 Q2 — Alternative state / new equilibrium

Is the post-closure attractor different from the pre-collapse attractor? Tested
by (a) the reconstructed effective potential `U(x)` estimated **separately
pre-collapse vs post-closure**; (b) parametric regime-structure model selection
(Beverton–Holt vs depensatory/Allee; SETAR threshold-AR; Markov-switching AR);
(c) geometric attractor-occupancy (do equally-driven pre- and post-collapse
points occupy different regions of the reconstructed state space).

### 2.3 Q3 — Reversibility / hysteresis

Is the response to removing the driver path-dependent? Tested by (a) the
time-varying S-map Jacobian leading-eigenvalue modulus `|λ_max(t)|` —
specifically whether it rose toward 1 *before* collapse **and failed to relax
after `F → 0` at closure**; (b) the state-dependent driver coefficient
`∂N_{t+1}/∂F_t` (large in the pre-collapse state, ≈0 in the depleted state =
path-dependence); (c) the driver–state hysteresis loop (recovery limb below the
depletion limb at matched driver).

### 2.4 Primary deliverable — the discrimination table

A table mapping the four **non-exclusive** explanations of non-recovery to
their predicted vs observed signatures across the full battery, with a per-row
verdict and explicit uncertainty:

1. **(i) True hysteresis / new low-state attractor** (bistability, fold).
2. **(ii) The effective driver never returned** — `F → 0` but total pressure
   (predation ↑, carrying capacity ↓ via PDO/Blob, habitat/collective-memory
   loss) did not return to pre-collapse levels ⇒ a *moved control parameter /
   changed system*, **not** hysteresis. The design must be able to land here.
3. **(iii) Long transient** — recovery is slow, not blocked (Frank et al. 2011;
   Hastings et al. 2018).
4. **(iv) Measurement-scale artifact** — fine-scale spawn reshuffling /
   survey-method change (Hay et al. 2009).

The product is the discrimination, not an assertion. The defensible headline
may be (ii) "single-equilibrium dynamics under an unreturned effective driver"
— stating that clearly is more rigorous and more interesting to a
tipping-points audience than over-claiming a fold.

This is consistent with `docs/herring-non-recovery-hypotheses.md` §11
(non-identifiability *is* the scientific point) and the
`docs/talk-model-claim-control-sheet.md` hysteresis beat ("the driver can be
reduced without the service trajectory retracing the collapse path").

---

## 3. State variables and data layers

### 3.1 Co-equal state variables (the project's point: *structure* tips)

The full battery is run on **all three** as co-equal primary state variables:

- **Aggregate biomass** (total spawn / total latent biomass).
- **Portfolio/synchrony structural metric** (Loreau–de Mazancourt φ and the
  portfolio effect, reusing `R/05_portfolio.R`).
- **Occupancy / effective-n** (range-contraction ratchet, slow structural
  state variable).

Hysteresis is expected to be sharper in the structural variables than in
biomass (biomass partly rebounds; structure does not — "the value moved, it
didn't vanish"). Testing reversibility in structure-space, not only
biomass-space, is project-consistent and novel for the alternative-stable-state
literature, which is almost entirely scalar abundance.

### 3.2 Two layers — both reported, the discrepancy is a result

- **Observed:** `Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv`
  (section×year spawn, 1951–2025; 13 sections). Zeros handled with the
  `m1_stier_11` ambiguous-zero convention; low-coverage years flagged from
  `Output/diagnostics/survey_coverage_*`.
- **Latent:** `m1_stier_11` posterior section/total biomass
  (`Output/diagnostics/m1_stier_11_total_biomass_by_year.csv`,
  `m1_stier_11_section_biomass_by_year.csv` — median + 80/90% CI, era-tagged).
  **Every dynamical index is computed over posterior draws → median + credible
  interval, never a point estimate.** The latent layer is the primary EDM input
  (process-error-reduced).

The observed/latent discrepancy ("is the signal real or model-made") is a
headline-capable result, not a buried caveat.

### 3.3 Spatial unit — both co-equal primary

- **core-9** (drop `Tasu Sound & Gowgaia Bay`, `Naden Harbour`; matches Stier
  2020 and the portfolio default) **and**
- **all-11**

run as co-equal primary (mirrors the EWS spec). **Leave-one-section-out** =
sensitivity, not headline.

### 3.4 Driver axis

- **Primary driver:** instantaneous exploitation rate `u_t = catch_t /
  biomass_t`, built from `Data/processed/herring_catch_local_1950_2024.csv` /
  `Data/processed/catch_matrix.csv` /
  `Output/diagnostics/m1_stier_11_section_year_fishing_pressure.csv` divided by
  the latent biomass. A cumulative-pressure variant is also computed.
- **Effective-driver composite** (for the §2.4 discrimination layer only):
  `F` + predator demand (predator-repo products **as context, no promoted
  coefficient** — control-sheet-clean) + a PDO / carrying-capacity proxy drawn
  from the existing in-repo covariate products (the project's `pdo_*` screens /
  lagged-PDO covariate per `docs/herring-non-recovery-hypotheses.md` §6 H3, and
  the predator covariates in
  `Data/processed/predators/`). Used to test explanation (ii): did the *net*
  control parameter return to its pre-collapse value, or is the system held at
  a different driver level? Provenance-tagged with model-branch +
  decision-ledger status (no new covariate acquisition — YAGNI, §10).

### 3.5 Era boundaries — tested, not asserted

The 1960s reduction-fishery crash, the 2005 closure, and the mid-1990s
synchronization episode are **tested** as candidate boundaries (reusing the EWS
spec's `detect_candidate_transitions()`), never asserted. The 2005 closure is
additionally the natural-experiment pivot for the driver–state geometry.

---

## 4. Method modules (integrated A + C + B)

### 4.1 M1 — EDM engine (A)

- **Embedding:** simplex projection → optimal embedding dimension `E` and
  predictability `ρ`; Theiler window for temporal autocorrelation; library /
  prediction split with leave-one-out for the short series.
- **Nonlinearity test (Q1):** S-map θ-sweep (θ ∈ [0, 8]); `ρ(θ*) > ρ(0)` under
  surrogates ⇒ state-dependent nonlinear determinism (Sugihara 1994; Hsieh et
  al. 2005).
- **Short-series power:** multispatial CCM (Clark et al. 2015) + multiview
  embedding (Ye & Sugihara 2016) pooling the 11-section replication — the
  metapopulation structure *is* the statistical power, not a length liability.
- **Time-varying stability (Q3):** S-map local Jacobian at each time →
  leading-eigenvalue modulus `|λ_max(t)|`; per-coordinate time-varying partials
  `∂N_{t+1}/∂{N, F, PDO, predation}` (Ushio et al. 2018; Grziwotz et al. 2023).
- **Causal attribution:** CCM (direction, convergence, optimal lag via extended
  CCM) for `F → N`, `PDO/SST → N`, `predator-demand → N` — causal, not
  correlational, evidence to populate the discrimination table.
- **Significance:** twin / Ebisuzaki / phase-randomized surrogates + Theiler
  window on every ρ/θ/CCM/eigenvalue claim; all indices run over `m1_stier_11`
  posterior draws.

### 4.2 M2 — Attractor / regime structure (B)

- **Effective potential (Q2):** nonparametric drift–diffusion (Carpenter–Brock)
  / Livina potential — estimate deterministic drift `f(x)` and diffusion;
  `U(x) = −∫ f/g²`; equilibria = stable zeros of `f` (`f'<0`). Estimated
  **separately pre-collapse vs post-closure** and as a moving estimate. A
  new/moved stable well = empirical evidence of a changed equilibrium.
- **Parametric regime hypotheses (Q2):** Beverton–Holt vs depensatory (Allee)
  stock/state model; SETAR threshold-AR; Markov-switching AR (each regime its
  own mean/variance/AR). Model selection via information criteria +
  **parametric bootstrap** (not bare LRT). Single-regime/Beverton–Holt
  preference = honest negative; two-regime/depensation preference = positive
  structural evidence.
- **Modality:** Hartigan dip / Silverman bandwidth test on the
  driver-conditioned, detrended residual state, pre vs post — with the
  **hard-wired caveat: a bimodal *driver* produces a bimodal state without any
  bistable *dynamics*; modality alone proves nothing and only motivates the
  drift/Jacobian tests.**

### 4.3 M3 — Driver-space geometry (C)

- **Path geometry (Q3):** state vs driver, traced as a **down limb**
  (pre-closure, `F` high→declining) and an **up limb** (post-closure, `F ≈ 0`).
  Reversible ⇒ up retraces down; hysteresis ⇒ recovery limb below depletion
  limb at matched driver.
- **Hysteresis-loop index:** signed loop area / vertical gap at matched driver,
  with a **null**: does a single-equilibrium driven model with HG-calibrated
  process+observation noise *and the documented two-era catchability shift*
  produce a spurious loop? An index that the null reproduces is disqualified.
- **Effective-driver reconstruction:** repeat the path geometry against the
  §3.4 effective-driver composite so the analysis can land on explanation (ii)
  — "no hysteresis; the driver never returned" — as the honest headline.

### 4.4 M4 — Discrimination & synthesis

Map every method output onto the four-explanation table (§2.4): which rows each
result supports or refutes, with explicit honest-negative landing rules. The
synthesis is the readable narrative connecting EDM stability, the potential
landscape, the regime model selection, and the driver-space loop into one
verdict-with-uncertainty per explanation.

---

## 5. Nulls, controls, honesty — the spine, not an appendix

Boettiger–Hastings discipline. Controls are run and reported **before** any HG
interpretation is trusted.

1. **Surrogate batteries** per index (twin / Ebisuzaki / phase-randomized +
   Theiler window); for the latent layer, combine surrogate + posterior
   uncertainty.
2. **Positive control (sensitivity).** Simulate a system **ramped through a
   saddle-node fold** — cusp normal form `dx = (r(t) + x − x³)dt + noise`, `r`
   ramped so the upper branch disappears and the trajectory transitions to the
   **real lower attractor (no numerical clamp)** — at HG cadence + the HG
   observation model. The battery **must** detect the approach. **Detector
   priority (load-bearing):** the time-varying `|λ_max(t)|` / critical-slowing-
   down (CSD) trend is the **primary** sensitivity criterion — it must rise
   toward instability before the transition and clearly exceed the negative
   control's. Generic S-map θ nonlinearity is a **secondary** indicator,
   **known to be underpowered at the HG cadence (n≈70)**; that power limit is
   reported as an explicit finding (Boettiger–Hastings honesty), never used as
   a hard pass/fail gate.
3. **Negative control (specificity).** A **linear-stochastic single-attractor**
   process — Ornstein–Uhlenbeck / AR(1) mean-reverting to one equilibrium +
   observation noise, **not** a deterministic nonlinear map sitting at
   equilibrium. The **specificity gate is the PRIMARY `|λ_max(t)|` trend**: it
   must be flat/near-constant (no spurious CSD) on this genuinely linear
   process — and it is. The S-map θ nonlinearity result on this control is
   **reported, not gated**: empirically, at n≈70 the short-series Ebisuzaki
   surrogate makes the θ test **false-positive even on this genuinely linear
   process**. That demonstrated false positive is **itself the Boettiger–
   Hastings power finding** — direct, quantified evidence for why generic
   S-map nonlinearity cannot be the HG headline detector and must stay
   secondary. (A stationary *nonlinear* map is **not** a valid negative
   control because S-map correctly flags its nonlinearity — the prior
   mis-specification, corrected 2026-05-19.)
4. **Survey-method false-positive audit (headline-capable).** Reuse the EWS
   spec's `survey_artifact_null()`: simulate the documented two-era
   catchability shift + zero-ambiguity + survey-coverage changes with **no**
   resilience change. Any index that "detects" a transition or a loop in this
   artifact-only null is **disqualified for the observed layer**; if the real
   observed signal is reproduced by the artifact alone, **that is the
   headline.**

---

## 6. Architecture, deliverables, firewall

### 6.1 Code (repo conventions: numbered `R/` lib + `Code/` diagnostics + `_targets.R` + `Output/diagnostics/`)

- `R/12_reversibility.R` — reusable functions: `edm_embed()`,
  `smap_nonlinearity()`, `smap_jacobian_eigen()`, `ccm_drivers()`,
  `potential_landscape()`, `regime_models()`, `driver_state_loop()`,
  `effective_driver()`, `reversibility_controls()`,
  `discrimination_table()`. (Sibling to the EWS spec's
  `R/11_early_warning.R`; `12_` chosen to avoid the crowded `07*` namespace and
  to sit downstream of `11_`.)
- `Code/12_reversibility_*.R` family, dependency-ordered:
  driver-axis → embedding/nonlinearity → multispatial-CCM/multiview →
  time-varying-Jacobian → potential-landscape → regime-models →
  driver-space-loop → effective-driver → controls-power →
  discrimination-synthesis. (Exact filenames finalized in the plan.)
- `Code/run_reversibility_suite.sh` — dependency-ordered runner mirroring
  `Code/08_refresh_may9_analysis_suite.sh` and the EWS spec's runner.
- `_targets.R` — new reversibility stage downstream of posterior extraction +
  portfolio. **Reuses** the EWS spec's `detect_candidate_transitions()` and
  `survey_artifact_null()` (documented cross-spec dependency; build order:
  EWS-shared utilities before reversibility stage).

### 6.2 Outputs (`Output/diagnostics/`)

`reversibility_discrimination_table.{csv,md}` (the headline) ·
`edm_nonlinearity.csv` · `edm_jacobian_eigen.csv` ·
`ccm_driver_causality.csv` · `potential_landscape_pre_post.csv` ·
`regime_model_selection.csv` · `driver_state_hysteresis_loop.csv` ·
`reversibility_controls.md` · `reversibility_synthesis.md` (readable
narrative) · `reversibility_claim_control.md` (safe-sentence ↔ do-not-say map;
extends `docs/talk-model-claim-control-sheet.md`).

### 6.3 Figures (pub-figure-pipeline / `theme_pub`, Figure Iteration Protocol)

`|λ_max(t)|` trajectory vs candidate transitions (observed vs latent) ·
state-dependent `∂N/∂F` panel · **`U(x)` pre-vs-post (the talk visual)** ·
driver-space hysteresis loop · controls/power panel. All via the Figure
Iteration Protocol; companion legend files; `audit_figure_consistency()`.

### 6.4 Firewall

Nothing imported from `talk-usuk-forum-2026/` into the core pipeline. Talk
numbers are pulled **from** these core outputs only, never the reverse.
Consistent with `CLAUDE.md` and `talk-usuk-forum-2026/README.md`.

### 6.5 New dependency

`rEDM` (+ `multispatialCCM`) added to `renv` and pinned. (Not currently in
`renv.lock`; this is the only new dependency. Recorded in the plan with a
fallback note if a pinned source build fails.)

---

## 7. Numerical robustness / edge cases ("error handling" for an analysis)

- **Even sampling (EDM requirement).** Explicit annual-cadence policy;
  documented limited interpolation only where defensible; the observed/latent
  asymmetry and any interpolated points are reported, never hidden.
- **Short series / short windows.** Enforce a minimum n; emit `NA` + a reason,
  never a silent number. Library/prediction split with leave-one-out.
- **Autocorrelation.** Theiler window on all EDM/surrogate steps.
- **Sparse sections / all-zero windows.** Explicit guards mirroring
  `compute_synchrony_lm` valid-column logic; record dropped units.
- **Posterior draws.** Indicators summarized as median + CI; never collapsed to
  a point before the CI is computed.
- **Determinism.** Fixed seeds for every surrogate/simulation/bootstrap step;
  seeds recorded in outputs.

## 8. Verification / testing

- **Unit-level analytic cases:** known-Jacobian → recovered `|λ_max|`;
  logistic-map → S-map θ recovers known nonlinearity; perfect synchrony φ→1 /
  perfect asynchrony φ→0; a simulated known fold → `U(x)` recovers the two
  wells; a simulated single attractor → unimodal `U(x)`.
- **Integration test:** the positive/negative controls (§5.2–§5.3) are the
  integration test — the battery must detect a simulated approaching fold and
  stay quiet on a stationary system before any HG interpretation is trusted.
- **Reproducibility:** `Code/run_reversibility_suite.sh` regenerates all
  outputs in dependency order from a clean state; `_targets.R` invalidation
  respected.
- **Cross-figure consistency:** `audit_figure_consistency()` after all figures.

## 9. Relationship to the EWS spec (explicit)

| | EWS spec | This spec |
|---|---|---|
| Question | Did indicators rise before candidate transitions? | Is the post-collapse system a different attractor; is non-recovery path-dependent? |
| Core method | Generic + spatial EWS battery, lead-time matrix | EDM (S-map/CCM) + potential landscape + driver-space geometry |
| Stance on a transition | Deliberately does not assert one | Tests for an attractor change; discrimination table, still not "it tipped" |
| Shared infra | — | Reuses `detect_candidate_transitions()`, `survey_artifact_null()`, posterior extraction, `R/05_portfolio.R`, claim-control discipline |

Build order: EWS-shared utilities (`detect_candidate_transitions`,
`survey_artifact_null`) must exist before this spec's `_targets.R` stage runs.

## 10. Out of scope (YAGNI)

- No coastwide / WCVI control limb (HG-internal identification chosen).
- No new Stan model branches; no promotion of held branches.
- No age-structured / Doherty catch-at-age EDM.
- No DFO-SCA as a data layer (context only, control-sheet rule).
- No talk-deck redesign (the one panel is a downstream byproduct, no timeline
  pressure).
- No real-time / forecasting EWS product.

## 11. Key references

Sugihara & May 1990 *Nature*; Sugihara 1994 *Phil Trans R Soc A* (S-map);
Hsieh et al. 2005 *Nature* (nonlinearity in exploited fish); Sugihara et al.
2012 *Science* (CCM); Ye et al. 2015 *PNAS* (EDM causality / `rEDM`); Clark et
al. 2015 *Ecology* (multispatial CCM); Ye & Sugihara 2016 *Science* (multiview
embedding); Ushio et al. 2018 *Nature* (fluctuating interaction network /
time-varying stability); Grziwotz et al. 2023 *Science Advances* (anticipating
the occurrence and type of critical transitions via EDM); Carpenter & Brock
2006 *Ecol Lett* (drift–diffusion / variance EWS); Livina & Lenton 2007
*GRL* (potential reconstruction); Scheffer et al. 2009 *Nature* (EWS / critical
slowing down); Boettiger & Hastings 2012 *J R Soc Interface* (EWS false-alarm
caution); Hastings et al. 2018 *Science* (long transients); Dakos et al. 2015
*Phil Trans R Soc B* (EWS limits); Frank et al. 2011 *Nature* (contested
recovery / transient); Schindler et al. 2010 *Nature* (portfolio effect);
Loreau & de Mazancourt 2008 *Am Nat* (synchrony φ); Stier et al. 2020
*Ecosphere* (HG portfolio erosion). Project docs:
`docs/herring-non-recovery-hypotheses.md` (H1–H9, non-identifiability §11);
`docs/talk-model-claim-control-sheet.md` (claim boundaries);
`docs/superpowers/specs/2026-05-19-herring-ews-analysis-design.md` (sibling).
