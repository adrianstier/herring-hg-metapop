# Q&A Backup Slides — Royal Society Tipping Points Forum

Created: 2026-05-18. **Supersedes and expands** the 8-row B1–B8 list in
`talk_production_plan.md` (those are folded in below, renumbered, themed, and
wired to concrete proof objects from `slide_asset_map.md` / the asset audit).

**Format (per production-plan rule):** each card = one question as the title,
one answer line you deliver from, one proof object already on disk, one ⚠
do-not-say guardrail (`../../docs/talk-model-claim-control-sheet.md`). These are
appendix cards — they must not compete with the 14-slide spine. Keep them in a
hidden section after slide 14; pull one up only if asked.

**Audience model.** ~40 tipping-points/regime-shift experts. Cards are tagged
with the archetype most likely to ask (Lenton = tipping/positive-tipping
keynote; Pinsky = climate range shifts/reshuffling; Will White = spatial mgmt /
connectivity / bioeconomics; Smale = marine heatwaves; Cavan = bottom-up /
biological pump; Costello = fisheries economics; Kubiszewski = chair,
ecosystem-services valuation). The goal the cards defend: **ecological and
ecosystem-service tips are separable; the gap is the management window;
solutions under deep uncertainty** — *not* a solved mechanism, *not* promoted
predators, *not* a tested early-warning signal.

Build status: **13 of 14 are drop-in** (proof object already rendered in
`Output/figures/`, the sibling predator repo, or a diagnostics `.md`). Only
B12's "what would test the EWS" mini-schematic is an optional small build.

---

## Theme A — Mechanism & causality (the "what actually caused it" press)

### B1 · "Isn't this just the predators coming back?"
*(asker: most of the room; Lenton/Smale framing it as a cascade)*
- **Answer line:** Predator demand is now large enough to be a serious
  pressure, and Doherty 2025 shows the mechanism *can* dominate on WCVI — but
  the Haida Gwaii model does **not** promote a predator coefficient, and
  Surma & Pitcher 2015 put the current HG whale effect at only ~6–12% of
  biomass. Large enough to prioritize data; not clean enough to promote a cause.
- **Proof object:** `/Users/adrianstier/pacific-herring-predators/Output/figures/MASTER_HG_predation_AUDITED.pdf`; `Output/diagnostics/predator_talk_brief.md`; held-branch rows in `Output/diagnostics/model_decision_ledger.md`.
- **⚠ Do not say:** "the model shows predators caused non-recovery." `m5_stier_predation_pressure` / `m5_stier_predator_demand_total` are held screens, no calibration gain.

### B2 · "So what *is* the mechanism?"  — the non-identifiability card
*(asker: Lenton, Pinsky — the sharpest tipping-points question)*
- **Answer line:** Every single-mechanism story is individually weak for HG —
  density dependence poorly supported, the predator pit weak (≠ WCVI), and
  even PDO is confounded (asynchrony was lost during *cold, productive* years).
  The robust result is the **spatial-structure / portfolio erosion pattern**;
  that the driver was removed and no single mechanism re-identifies it **is
  itself the tipping-point signature**, not a gap in the analysis.
- **Proof object:** `Output/diagnostics/postclosure_recovery_mechanism_screen.md`; `Output/diagnostics/covariate_readiness_registry.md`; `docs/herring-non-recovery-hypotheses.md` §2/§11.
- **⚠ Do not say:** name one ecological cause. The defensible claim is the H6 pattern + non-identifiability.

### B3 · "Is it bottom-up — the Blob / zooplankton energy?"
*(asker: Smale, Cavan, Le Quéré)*
- **Answer line:** Bottom-up is one of the two best-supported HG strands (with
  spatial erosion). PDO drives subpopulation intrinsic growth, the 2014–16
  heatwave hit in the study's final years, and OSMOSE-type work points to
  starvation limiting northern BC herring — but the new heatwave scope
  diagnostic says the Blob is a stress-test period, **not** the promoted
  explanation for HG non-recovery.
- **Proof object:** `Output/diagnostics/heatwave_bottomup_scope.md`;
  `Output/figures/heatwave_bottomup_scope.pdf`;
  `Output/figures/pdo_climate_signal_screen.pdf`,
  `Output/figures/mhw_recovery_screen.pdf`,
  `Output/figures/pdo_window_sensitivity.pdf`; idea-bank H3.
- **⚠ Do not say:** "warm PDO = bad" as a clean rule (Stier 2020: asynchrony loss in cold productive years).

### B4 · "Could this be a 3-year recruitment-return lag, not adult mortality?"
*(asker: Will White, fisheries-dynamics audience)*
- **Answer line:** Biologically plausible and worth testing — if predation acts
  on eggs/juveniles the adult signal returns ~age-3 — but our current lag
  screens are audit targets, not promoted evidence, and the public age proxies
  are not independent juvenile data.
- **Proof object:** `Output/figures/future_lag_negative_control_audit.pdf`; `Output/diagnostics/future_lag_negative_control_audit.md`.
- **⚠ Do not say:** treat spawn-normalized age proxies or DFO SCA age-2 recruitment as independent validation.

---

## Theme B — Is it really a tipping point? (the regime-shift purists)

### B5 · "Is this true hysteresis, or just a long transient?"
*(asker: Lenton, Scheffer/Dakos-canon listeners — the highest-rigor question)*
- **Answer line:** We frame it as a system in an alternative state held by
  reconfigured feedbacks, not a proven fold. The honest cross-system read:
  Atlantic cod's "non-recovery" was partly a long transient (Frank 2011), and
  Barents cod recovered when favorable climate **plus** precautionary control
  rules synergized — so recovery is *contingent*, not automatic. That
  contingency, not a clean bifurcation, is the claim.
- **Proof object:** the slide-12 decoupling figure (4-layer; to build) + idea-bank §3 contested-recovery; Frank 2011 / Kjesbu 2014 cites in `herring-non-recovery-hypotheses.md` §9.
- **⚠ Do not say:** assert a measured fold/bifurcation or quantified hysteresis loop.

### B6 · "Is this spatial *reshuffling*, not real loss?" (the Hay 2009 objection)
*(asker: Pinsky — climate-driven redistribution)*
- **Answer line:** Engage it directly. Hay 2009 is right that fine-scale spawn
  shifts can be normal redistribution — but the McKechnie 10,000-year
  archaeological baseline shows herring were consistently superabundant, and
  Stier 2020 / Okamoto 2020 show the aggregate index hid genuine local
  extirpation. The deep baseline is what lets us call this loss, not noise.
- **Proof object:** `Literature/McKechnie_et_al_2014_PNAS_Archaeological_Herring.pdf` (slide 4 fig); `Output/figures/m1_stier_11_spatial_concentration.pdf`; idea-bank §3.
- **⚠ Do not say:** dismiss the reshuffling hypothesis — the answer is the baseline + scale evidence, not denial.

### B7 · "You call rising synchrony an early-warning signal — is that tested?"
*(asker: Scheffer/Dakos-canon; the EWS rigor trap)*
- **Answer line:** No — and I want to be explicit: the >60% synchrony rise is a
  measured result (Stier 2020); framing it as a *leading indicator* is a
  proposal I'm putting to this room, not a finding. The spatial-EWS analysis is
  not done. What would test it: out-of-sample lead time of the spatial signal
  vs. the aggregate, on the maintained `m1_stier_11` series.
- **Proof object:** `Output/figures/synchrony.pdf` / `portfolio_metrics_combined.pdf`; optional small "what would test it" schematic (the only B-card build).
- **⚠ Do not say:** call the EWS a result, a contribution, or "our finding." Hypothesis strength only — this is the single most-flagged item in the spine.

---

## Theme C — Scale, spatial structure & connectivity (Will White's domain)

### B8 · "What spatial management actually preserves the portfolio?"
*(asker: Will White, Costello — the design question)*
- **Answer line:** Govern the *proportion of stock exposed*, not a re-tuned
  archipelago quota (Walters & Maguire 1996). Manage at the cove/section scale
  where biology, the fishery, and predators all operate; that is closer to how
  salmon are managed river-by-river. The distance-decay structure is consistent
  with rescue among nearby coves — the mechanism the portfolio depends on.
- **Proof object:** `Output/figures/m3_stier_distance_postfit.pdf` (held spatial branch — context); `Output/figures/section_action_matrix.pdf`; idea-bank §5.2.
- **⚠ Do not say:** present `m3_stier_distance` as a promoted result — it is held context (no calibration gain).

### B9 · "Why is Strait of Georgia the right comparison?"
*(asker: BC/DFO-literate audience; negative control)*
- **Answer line:** SoG is the negative control: coastwide BC herring trended up
  since the mid-2000s while HG stayed depleted with no sustained growth and a
  0-tonne recommendation despite no fishery since 2002. Same species, same
  agency, different geometry — that within-coast contrast is the sharpest
  quasi-experiment we have.
- **Proof object:** `Output/figures/hg_dfo_sca_external_comparison.pdf`; DFO SR 2025/005 plug points (`cleary_sr2025005_plug_points.md`); idea-bank §3.
- **⚠ Do not say:** compare raw LOOIC across likelihood units; SR 2025/005 is aggregate SCA, not `m1_stier_11`.

### B10 · "Aggregate biomass looks okay — show me the scale artifact."
*(asker: Costello, assessment-literate audience)*
- **Answer line:** Archipelago-wide exploitation looked ~4% while local cove
  rates reached ~65% (Stier 2020) — the average hid the extremes, exactly the
  hyperaggregation that hid the cod collapse. The state variable that tipped is
  spatial structure and service delivery, not coastwide biomass.
- **Proof object:** slide-7 two-scale figure (`DRV-ASSETS 05-data-graphs/slide_herring_fishing_rate_subpop_vs_archipelago.png`); `Output/diagnostics/m1_stier_11_portfolio_metrics.md`.
- **⚠ Do not say:** present "4% / 65%" or "2.1×" as current `m1_stier_11` output — they are **Stier et al. 2020 published**, labelled as such.

---

## Theme D — Model & data rigor (the quantitative skeptics)

### B11 · "Are the zeros real absences?"
*(asker: state-space / Bayesian audience)*
- **Answer line:** Not by default. The baseline treats zero / no-survey cells
  as ambiguous unless a survey was designed to establish absence; some HG
  site-years are unsurveyed for governance/access reasons, so absent effort ≠
  low biomass. Detection-aware models are sensitivity analyses, not the baseline.
- **Proof object:** `Output/figures/survey_coverage_zero_ambiguity.pdf`; `Output/diagnostics/survey_coverage_zero_ambiguity.md`; claim-control sheet.

### B12 · "How robust is the baseline model?"
*(asker: methods-focused; Will White)*
- **Answer line:** `m1_stier_11` is the promoted Stier-aligned baseline:
  ambiguous zeros, two-era catchability, 11 fitted sections, focal-9 reporting.
  Sampler-clean; the one high Pareto-k point was resolved by exact re-LOO
  (ΔLOOIC 0.06); every held branch failed the calibration gates.
- **Proof object:** `Output/diagnostics/latest_model_status.md`; `Output/figures/m1_stier_11_fit_quality_summary.pdf`; `Output/diagnostics/model_decision_ledger.md`.

### B13 · "How close are you to a full Doherty catch-at-age predation model?"
*(asker: Doherty-aware fisheries audience)*
- **Answer line:** We replicated the data-readiness logic and built a
  biomass-scale proxy bridge; the exact HG age/weight/length/selectivity inputs
  and effective sample sizes for a full catch-at-age predation-mortality
  replication are still missing. It is a source-traceable gap table, not a
  finished HG Doherty model.
- **Proof object:** `docs/doherty-style-hg-gap-table.md`; `Output/figures/wcvi_predation_replication_bridge.pdf`; `Output/figures/hg_dfo_sca_external_comparison.pdf`.
- **⚠ Do not say:** describe WCVI/Doherty selectivity as HG-estimated parameters.

---

## Theme E — Generality & transfer (the "does this travel?" press)

### B14 · "How general is this — cod, or forage fish broadly?"
*(asker: Lenton, Pinsky, the comparative-systems room)*
- **Answer line:** Cod is the right *governance* analogue (assessment
  illusions, contested recovery, precaution under uncertainty) but the wrong
  *ecological* one — cod is a long-lived predator, herring a short-lived
  wasp-waist forage fish. The forage-fish ecological analogue is the
  sardine–anchovy regime flip and Essington 2015 (fishing amplifies forage-fish
  collapses). One tipping-point grammar; two trophic roles.
- **Proof object:** idea-bank §1/§11.4; `Reference_Papers/Essington_2015_…pdf`, `Pikitch_2014_…pdf`; cod↔herring synthesis in `herring-non-recovery-hypotheses.md`.
- **⚠ Do not say:** equate cod and herring ecology; keep cod as governance grammar only.

### B15 · "Does this travel to systems without a 10,000-year baseline?"
*(asker: Le Quéré, Kubiszewski — transferability/policy)*
- **Answer line:** The deep baseline made the *diagnosis* unusually firm here;
  most systems lack it, which is the point — recovery targets set on recent
  decades are a shifting baseline and likely far too low. The transferable move
  is to find each system's best long baseline (archaeology, 500-yr cod
  reconstructions) and to manage exposure and structure when you can't.
- **Proof object:** McKechnie 2014 (slide 4); idea-bank §3/§5.4.
- **⚠ Do not say:** claim the HG result transfers quantitatively; it transfers as method + caution.

### B16 · "Collective memory loss — the Ono 2025 / Norwegian story?"
*(asker: TEK-aware and Nature-reading audience)*
- **Answer line:** It's a credited hypothesis (H8), not a promoted HG result:
  entrainment is socially learned, heavy adult harvest can erase spawning-site
  memory, and Ono 2025 shows an 800 km Norwegian shift plus Guujaaw's "lost the
  elders, lost their way." Consistent with HG range contraction (~7.6%/decade,
  Gerrard 2014) but we have not formally fit a memory model.
- **Proof object:** `Output/figures/observed_occupancy_transition_screen.pdf`; idea-bank H8/§9; Ono 2025 (motivation).
- **⚠ Do not say:** present collective-memory loss as a tested HG mechanism.

---

## Theme F — Solutions & valuation (the chair's explicit ask)

### B17 · "What's the cost of fine-scale management — is it economically viable?"
*(asker: Costello, Will White — the bioeconomics challenge)*
- **Answer line:** Benson 2015 is right that fine-scale management normally
  needs far more data and observation error can *raise* collapse risk — which
  is exactly why place-based Indigenous monitoring matters: it *is* the
  low-cost, high-resolution observation system the critique says you'd
  otherwise lack. Co-governance turns the cost objection into the solution.
- **Proof object:** idea-bank §11.5/§5; `S20_solution_payload.md`; Benson 2015 (`Reference_Papers/Benson_2015_…pdf`).
- **⚠ Do not say:** claim fine-scale management is costless; the answer concedes the cost and answers it.

### B18 · "How do you value the *service* tipping point — why isn't $ the metric?"
*(asker: Ida Kubiszewski, chair — ecosystem-services valuation)*
- **Answer line:** The service tip is not one number. Commercial value is one
  axis (Rebuilding Plan Figs 31/32 — peaked 1980s, declined; not the unsourced
  "$40M→$2.78M"); the cultural keystone axis has *no* quantitative k'aaw
  tonnage threshold and shouldn't be forced into one — it's spatial contraction
  + lost intergenerational knowledge against a 10,000-yr baseline. Three
  bottom lines, three clocks; collapsing them to GDP is the error.
- **Proof object:** slide-11 triple-bottom-line; `figs/RebuildingPlan2024_Fig31/32_*.png`; `S8_landed_value_provenance.md`; idea-bank §11.2.
- **⚠ Do not say:** assert "$40M→$2.78M" or a quantitative cultural threshold — both unsourced.

### B19 · "Has co-governance (AMB) actually fixed it?"
*(asker: Kubiszewski, governance-minded audience)*
- **Answer line:** Honest answer strengthens it: AMB / Gwaii Haanas / the 2024
  Rebuilding Plan are a social and institutional success and the
  scale-matched governance design for deep uncertainty — but HG is still below
  the limit reference point with a 0-tonne recommendation, so it has **not yet
  reversed the ecological tip**. It's the right structure acting inside the
  management window, not a completed cure.
- **Proof object:** `S19_cogovernance_imagery_provenance.md`; `S20_solution_payload.md`; DFO SR 2025/005 (P(SB2025<LRP)=0.378) via `cleary_sr2025005_plug_points.md`.
- **⚠ Do not say:** claim co-governance has restored the stock.

### B20 · "Without a solved mechanism, what should managers do now?" — positive-tipping close
*(asker: Lenton — ties to his positive-tipping keynote; the chair's solutions ask)*
- **Answer line:** Don't wait for one coefficient. Three moves under deep
  uncertainty: (1) measure the right variable at the right scale; (2) manage
  the proportion exposed and preserve spatial structure (refuges > re-tuned
  TACs); (3) allocate explicitly across the triple bottom line via
  scale-matched co-governance — the *positive* tipping lever in this system.
- **Proof object:** `S20_solution_payload.md`; idea-bank §5; build1_spine.html management-window panel.
- **⚠ Do not say:** imply the solution depends on first solving the mechanism.

---

## Use notes

- **Sequencing:** keep as a hidden appendix after slide 14. Most-likely pulls in
  this room, in order: **B7 (EWS rigor), B1 (predators), B5 (hysteresis vs
  transient), B2 (non-identifiability), B18 (service valuation — the chair),
  B20 (solutions).** Have those six one click away.
- **Discipline:** every card's answer line is already claim-control-safe; the ⚠
  lines are the phrases that lose the room if said loosely.
- **Build:** only B7's optional "what would test the EWS" mini-schematic is a
  new build. All other proof objects exist (asset audit / `slide_asset_map.md`).
- **Supersedes** the `talk_production_plan.md` B1–B8 list (folded in: old
  B1→B1, B2→B13, B3→B11, B4→B4, B5→B12, B6→B4, B7→B9, B8→B20).
