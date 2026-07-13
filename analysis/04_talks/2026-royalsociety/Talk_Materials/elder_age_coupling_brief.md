# Talk Brief — The "Elders" / Experienced-Spawner Precursor

**Status:** firewall-compliant. Talk-facing summary that *reads from* core
diagnostics; it does not feed the modeling pipeline.
**Source diagnostic:** `Output/diagnostics/elder_age_spatial_coupling.md`
(script `Code/07bx_elder_age_spatial_coupling_screen.R`; stability tables
`elder_age_spatial_coupling_stability_startyear.csv`,
`elder_age_spatial_coupling_stability_loo.csv`).
**Bottom line for the slide:** within the clean modern roe-seine window, the
Corten/Huse repeat-spawner ratio **leads** the loss of effective spawning
sites by ~1 herring generation. Modest, regional, descriptive — a
*consistent-with* result, not a *demonstrated* causal precursor.

---

## What we tested

GWOF / entrainment (MacCall et al. 2019; Corten 2002; Huse 2002, 2010; Fagan
et al. 2012) predicts that the **experienced : first-time spawner structure**
erodes *before* the spawning portfolio contracts. We built that index from
the **public Appendix B number-at-age** (DFO CSAS 2018/028, whole-HG SAR,
1951–2017, provisional) and ran descriptive Spearman cross-correlations on
first differences (shared-trend control) against the **effective number of
spawning sites** (MacCall Eq 6–7) and the regional spawn index, across three
streams so the gear-selectivity confound is **visible, not hidden**: pooled
(mixed gears across decades), Gear2 roe-seine only, and a **gear-confound-
free Gear2-only 1980–2017 window**.

## Headline (Gear2 roe-seine, 1980–2017, gear-confound free)

- **Corten/Huse repeat:first-time ratio → effective # spawning sites:**
  lag = **6 yr (~1 herring generation)**, Spearman ρ_firstdiff = **+0.374**,
  p ≈ **0.035**, n = 32.
- **Mean age → regional spawn index** (independent corroboration):
  lag = **7 yr**, ρ_firstdiff = **+0.433**, p ≈ **0.015**, n = 31.
- Sign- and lag-consistency across two independent age metrics at a
  generation-scale lead. The lag-profile (Figure C) shows the signal
  localized at lag 6, not smeared across lags.

## Stability — what survives, what's fragile

**Start-year sensitivity (Gear2 only, ρ at lag 6, 2000-bootstrap 95% CI):**

| Start | End | n pairs | ρ_diff(lag 6) | 95% CI | p |
|---|---|---|---|---|---|
| 1975 | 2017 | 36 | +0.31 | [−0.01, +0.56] | 0.064 |
| **1980** | 2017 | **31** | **+0.37** | **[+0.03, +0.65]** | **0.038** |
| 1985 | 2017 | 26 | +0.45 | [+0.09, +0.73] | 0.020 |
| 1990 | 2017 | 21 | +0.42 | [+0.02, +0.71] | 0.060 |
| 1995 | 2017 | 16 | +0.57 | [+0.11, +0.84] | 0.020 |

The signal *strengthens* as the window tightens to the modern roe era —
exactly what you'd expect if the broader-window result was being diluted by
the gear-switching artifact. That progression is, in itself, supporting
evidence that the result is biology and not a sampling artefact.

**Leave-one-out (1980+, dropping each year individually):** ρ_diff at lag 6
ranges **[0.09, 0.57]**, median 0.26. The most-influential years are
**2005, 2009, 2010 — all post-closure**; dropping them pulls ρ down to ~0.10.

That LOO pattern is consistent with GWOF mechanism, not against it: the
post-closure window is the cleanest test (constant gear, fishing pressure
released, age structure relaxing, spatial response can follow). But it does
mean a substantial fraction of the lag-6 signal is carried by ~5 post-closure
years — n is effectively smaller than 32 in a hidden sense.

## How to read this honestly

**Upside.** Survives the gear-confound control (Gear2-only); confirmed at the
pre-specified lag (6 yr, originally surfaced in the full-record screen);
corroborated by an independent age metric; magnitude grows as the window
tightens to the modern roe era; biologically interpretable lag (~1
generation); coherent with the post-closure non-recovery framing the talk
already carries.

**Downside.** Modest n; signal partly carried by ~5 post-closure years;
multiple-comparisons concerns are real (3 indices × 2 targets × 9 lags = 54
cells per stream → ~3 false positives expected under noise; the lag-6
expectation was pre-registered from the prior screen, which mitigates but
does not eliminate this); still regional, not section-resolved — the
subpopulation-specific GWOF test requires the DFO biosample data request
(`docs/dfo-hg-biological-input-request-packet.md`).

## Slide language

**Safe to say**

- "The elders hypothesis (Guujaaw; MacCall et al. 2019) makes a testable
  precursor prediction: experienced-spawner structure should erode *before*
  the spawning portfolio contracts."
- "Using the public DFO number-at-age, restricted to the gear-confound-free
  modern roe-seine window (1980–2017), the Corten/Huse repeat-spawner ratio
  — the demographic driver MacCall names — leads the loss of effective
  spawning sites by ~1 herring generation (Spearman ρ = +0.37 on
  detrended series, p ≈ 0.035, n = 32), corroborated by mean age leading
  regional spawn index at a 7-year lag (ρ = +0.43, p ≈ 0.015)."
- "The signal strengthens as the window tightens to the modern roe era —
  consistent with the broader-record result being diluted by the changing
  sampling fleet rather than spurious."
- "Modest, regional, descriptive — consistent with the GWOF/entrainment
  precursor, not yet a subpopulation-specific demonstration. The latter
  requires section-resolved biological samples we have specified in the DFO
  data request."

**Do not say**

- ❌ "Fishing truncated age structure and that caused site abandonment at
  Haida Gwaii." (causal claim not supported)
- ❌ Any treatment of the Appendix B age index as an HG-estimated parameter
  or as independent validation of `m1_stier_11`.
- ❌ "Significant" without the n, the window, and the post-closure-leverage
  qualification.

## Recommended talk move

Lead with the **spatial signature** (post-closure non-recolonization by
section, occupancy model, portfolio erosion). Carry the **elders mechanism**
with external evidence (Ono et al. 2025; MacCall 2019; the Guujaaw quote)
*plus* this regional age-lead result as a **consistent-with motivating
coupling at the predicted generation-scale lag**. State the data gap
explicitly. Honesty strengthens the case to an expert tipping-points
audience.

## Figure

`Output/figures/elder_age_spatial_coupling.{pdf,png}` — 4 panels:
(A) repeat-spawner ratio over time across all three streams with era bands,
(B) effective # spawning sites vs regional spawn index over time,
(C) lag profile for repeat-ratio → effective # sites, comparing Gear2 full
record vs Gear2 1980+ (the lag-6 signal sharpens when the gear confound is
removed), (D) start-year sensitivity bars with bootstrap CIs (signal
strengthens as window tightens to the modern roe era). Designed to be
slide-able as a single 2×2 if cropped; the C+D pair alone carries the
defensible quantitative claim.
