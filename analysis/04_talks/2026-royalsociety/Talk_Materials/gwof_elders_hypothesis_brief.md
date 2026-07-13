# "Go With the Elders" — Hypothesis & Haida Gwaii Findings

*US–UK Royal Society **Tipping Points in Ocean Systems** Forum,
London, 20 May 2026 — Session 5 (Ecosystem Services). Background brief
for the herring talk and companion to the metapopulation paper.*

---

## The hypothesis in one sentence

Pacific herring learn their migration routes by joining schools of older,
experienced spawners; strip out the elders and the route knowledge — and
the spawning site — go with them.

## Provenance

- **MacCall, Francis, Punt, Siple, Armitage, Cleary, Dressel, Jones, Kitka,
  Lee, Levin, McIsaac, Okamoto, Poe, Reifenstuhl, Schmidt, Shelton, Silver,
  Thornton, Voss, Woodruff. 2019.** *A heuristic model of socially learned
  migration behaviour exhibits distinctive spatial and reproductive
  dynamics.* **ICES JMS 76(2):598–608.** Formal "Go With the Older Fish"
  (**GWOF**) model — biomass-based heuristic, no philopatry, recruits
  distribute in proportion to local adult biomass (i.e. they follow the
  elders). [`Literature/MacCall_et_al_2019_ICESJMS_Socially_Learned_Migration_GWOF.pdf`]
- **Haida knowledge.** Chief Gidansta (Guujaaw) to PL, 18 Jan 2017:
  *"Once herring lost the elders they lost their way to their spawning
  grounds."* Cited verbatim in MacCall et al. (2019, p. 3). Convergent
  oral histories in Southeast Alaska (HK) and BC (RJ).
- **Atlantic mechanism.** Corten 2002 *Rev. Fish Biol. Fish.* — "role of
  conservatism in herring migrations"; Huse et al. 2002, 2010 — Norwegian
  spring-spawners, **first-time : repeat-spawner ratio** as the
  demographic driver of migration-pattern change.
- **Recent test.** Ono et al. 2025 *Nature* — Norwegian herring 800-km
  spawning shift consistent with collective-memory loss.
- **Theory.** Fagan et al. 2012 *Theor. Ecol.* — leadership / social
  learning and the *collapse* of migratory populations.

## What MacCall's model predicts (and why it fits HG)

Under GWOF, exploitation does **not** scale all sites down proportionally.
Instead the spatial portfolio reorganizes:

- **Site abandonment**, especially of lower-quality sites; biomass
  concentrates at a few productive cores.
- **Flattened, non-stationary stock–recruit relationship**; aggregate
  productivity ≈ 65 % of the equivalent diffusion-strategy population.
- **B₀ underestimated** because abandoned historical sites drop out of
  the fitted SRR.
- **Decades to recolonize** after fishing relaxes (MacCall cites Tlingit
  knowledge of 1925–1955 reduction sites taking 30–50 yr to recover or
  never recovering).
- Genetically homogeneous yet behaviourally structured "memes" of
  spawning groups — reproduces the known Pacific-herring oddities
  (Dickey-Collas 2009; McKechnie 2014 archaeology).

This is the GWOF *spatial signature*. It is what you would observe at
Haida Gwaii — abandoned southern sections, regional contraction,
19-year closure without recolonization — even without measuring a single
fish's age.

## What we tested in this repo

- **Data.** Public DFO Appendix B number-at-age extract
  (CSAS 2018/028, whole-HG SAR, 1951–2017, `extracted_public_provisional`)
  + processed core regional and 11-section spawn covariates.
- **Indices.** Repeat:first-time ratio = N(age ≥ 4)/N(age = 3) — the
  exact quantity Corten/Huse used and MacCall names; experienced share
  (prop. age ≥ 4); mean age (plus-group floored).
- **Targets.** Effective number of spawning sites = exp(Shannon entropy
  of section spawn shares), MacCall Eq 6–7; regional spawn index.
- **Test.** Spearman cross-correlation, levels and **first differences**
  (shared-trend control), lags 0–8 yr (positive lag = age index leads
  target). Three streams compared so the gear confound is visible, not
  hidden: pooled (mixed gears across decades), Gear2 roe-seine only, and
  the **gear-confound-free Gear2 1980–2017 window**.
- **Stability.** Start-year sensitivity (1975, 80, 85, 90, 95) with
  2000-bootstrap 95 % CIs; year-by-year leave-one-out.
- Script: `Code/07bx_elder_age_spatial_coupling_screen.R`.

## What we found

### Headline

Within the gear-confound-free 1980–2017 Gear2 roe-seine window:

| Coupling | Lag | ρ_firstdiff | p ≈ | n |
|---|---|---|---|---|
| **repeat:first-time ratio → effective # spawning sites** | **6 yr** | **+0.374** | **0.035** | **32** |
| mean age → regional spawn index (independent corroboration) | 7 yr | +0.433 | 0.015 | 31 |

Sign-consistent and lag-consistent at **~1 herring generation** across two
independent age metrics, in the direction GWOF predicts.

### Stability

- **Start-year sensitivity** — ρ at lag 6 strengthens as the window
  tightens to the modern roe era: **0.31 → 0.37 → 0.45 → 0.42 → 0.57**
  as start moves 1975 → 80 → 85 → 90 → 95. Bootstrap 95 % CIs are above
  zero from 1980 onward (with 1990 marginal). The fact that the signal
  *grows* as the gear regime narrows is itself supporting evidence that
  the full-record dilution was the gear confound, not a real-effect
  attenuation.
- **Leave-one-out** — ρ at lag 6 ranges [0.09, 0.57], median 0.26. The
  three most-influential years are **2005, 2009, 2010 — all post-
  closure**. Dropping them pulls ρ to ~0.10. Biologically coherent
  (post-closure is the cleanest GWOF test window — constant gear,
  fishing pressure released, age structure relaxing, spatial response
  can follow), but n is effectively smaller than 32. Must be stated.

### What does *not* hold

- Pooled-across-fleets and Gear2-full-record streams give weak,
  non-significant, and partly sign-flipped signals — the gear confound
  is real and visible in the data.
- `prop_age_ge4` is the metric most affected by the confound (sign flip
  between pooled and Gear2). `repeat_ratio` and `mean_age` are the
  reliable ones.
- This is a **regional** screen. It cannot test the *subpopulation-
  specific* GWOF prediction.

## What it means

**For the talk.** A quantitative motivating coupling at the predicted
generation-scale lag, in the GWOF-predicted direction, after the gear
confound is controlled. *Slide-able as supporting evidence behind the
spatial signature*, with explicit n, window, and post-closure-leverage
caveats. See `elder_age_coupling_brief.md` for safe slide language.

**For the paper.** GWOF gets evidence at both temporal ends — the
**precursor** (this age-lead at one generation) and the **consequence**
(post-closure non-recolonization by section, 19-year closure;
`m1_stier_11_postclosure_recovery_by_section.csv`; the occupancy model).
Neither alone is causal; together at the same biological timescale they
form the GWOF temporal architecture.

**What we still cannot say.**

- That fishing-driven age truncation *caused* site abandonment at HG.
- That the age signal explains any specific section's loss.
- That the regional Appendix B series is an HG-estimated parameter or an
  independent validation of `m1_stier_11`.

The subpopulation-specific test requires **section-resolved biological
samples** (length, age, weight by Statistical Area / Section). This is
already specified in
`docs/dfo-hg-biological-input-request-packet.md` and is the
single highest-leverage missing input.

## Where this lives

| | Path |
|---|---|
| MacCall 2019 PDF | `Literature/MacCall_et_al_2019_ICESJMS_Socially_Learned_Migration_GWOF.pdf` |
| Idea bank (H8) | `docs/herring-non-recovery-hypotheses.md` |
| Doherty-style gap table | `docs/doherty-style-hg-gap-table.md` |
| DFO biosample request | `docs/dfo-hg-biological-input-request-packet.md` |
| Analysis script | `Code/07bx_elder_age_spatial_coupling_screen.R` |
| Diagnostic write-up | `Output/diagnostics/elder_age_spatial_coupling.md` |
| Slide-language brief | `analysis/04_talks/2026-royalsociety/Talk_Materials/elder_age_coupling_brief.md` |
| Figure | `Output/figures/elder_age_spatial_coupling.{pdf,png}` |
| Talk-claim firewall | `docs/talk-model-claim-control-sheet.md` |
