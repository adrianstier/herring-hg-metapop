# Reversibility Figure QA — 40-pt Rubric (Phase 8, Task 23)

**Date:** 2026-05-19  
**Figures rendered by:** `Code/12_reversibility_figs_render.R` (sources `R/12_reversibility_figs.R`)  
**Inspected via:** `sips -Z 1200` downscale, PDF native at 100% zoom  
**Rubric:** 8 dimensions × 5 points each = 40 max  
**PASS threshold:** ≥32/40, no dimension < 3  

Dimensions:
1. **Composition** — panel proportions, whitespace, layout balance, margin adequacy
2. **Data-ink** — no chartjunk, data-to-ink ratio, essential elements only
3. **Legibility at 100%** — tick labels, axis titles, annotation text readable at print size
4. **Color / accessibility** — Okabe-Ito palette, colorblind-safe, no rainbow/jet
5. **Honest representation of uncertainty/indeterminacy** — credible intervals, INDETERMINATE labels, no overclaiming
6. **Claim-safety** — no forbidden strings ("hysteresis confirmed", "proves a fold", "caused by predators", "the system tipped", "hysteresis refuted")
7. **Label / axis correctness** — axis units, year ranges, n stated, correct statistical quantities named
8. **Cross-figure consistency** — shared theme, palette variables, explicit ggsave dims, legend files exist

---

## Fig 1: `reversibility_lambda_trajectory` (170 × 120 mm)

| Dim | Score | Notes |
|-----|-------|-------|
| 1. Composition | 5 | Single panel, clear whitespace, post-closure annotation placed in sparse region upper right, 2005 closure label below the vertical dotted line. Margins adequate; no clipping observed. |
| 2. Data-ink | 4 | 80-pct posterior ribbon appropriately light (alpha=0.18). Three text annotations in figure (post-closure slope, "2005 closure", S-map note) are all functional — none decorative. Minor: the S-map note at bottom-left is very small but intentional (SECONDARY status). |
| 3. Legibility at 100% | 4 | x/y axis labels readable. Post-closure annotation text (size 2.0) is slightly small at 120mm height but legible at 100% PDF zoom. Caption in 3-line format reads cleanly. S-map note at bottom (size 1.9) passes inspection at PDF native. |
| 4. Color / accessibility | 5 | Single series blue (Okabe-Ito #56B4E9). Ribbon same hue, lower alpha. Colorblind-safe single-color design. Grey reference lines at neutral and low contrast. |
| 5. Honest uncertainty | 5 | 80-pct posterior band shown. Annotation explicitly states "failed to relax (n~20); consistent with slow transient OR persistence" — two-sided interpretation. Caption: "mechanism not adjudicable". Hysteresis and long_transient labelled INDETERMINATE in caption. |
| 6. Claim-safety | 5 | No forbidden strings. Annotation text: "lambda_max failed to relax" (honest). Caption: "consistent with slow transient return OR persistence near high-biomass state; mechanism not adjudicable". S-map n.s. correctly labelled SECONDARY. |
| 7. Label / axis correctness | 5 | y-axis: "|lambda_max(t)| (Jacobian leading eigenvalue)" — correct. x-axis: "Year". x-limits 1950–2026. y-limits 0.70–1.52 encompass all data. Neutral threshold at 1.0 labelled via dashed line. |
| 8. Cross-figure consistency | 4 | theme_pub(9) via .rev_theme(9), Okabe-Ito palette, explicit ggsave 170×120mm, companion legend written. Minor: subtitle font size (rel(0.78)) consistent with other figures. |
| **Total** | **37/40** | **PASS** |

**Issues to note:** None blocking. Post-closure annotation text is tightly spaced — acceptable at publication size.

---

## Fig 2: `reversibility_state_df` (170 × 140 mm)

| Dim | Score | Notes |
|-----|-------|-------|
| 1. Composition | 4 | Data-rich scatter; ggrepel year labels are well-distributed with no visible overlap at print size. Two dashed reference lines (roe-era, recent) break the data area cleanly. Legend at bottom. Minor: the scatter is dense in the centre (1970s-2000s roe-era data) — acceptable given the biology. |
| 2. Data-ink | 4 | Path lines (alpha=0.5) and points (alpha=0.8) give layered view without hiding individual observations. No gridlines crossed with reference line clutter. Two reference line labels ("roe-era ref=0.149", "recent med=-0.155") are functional. |
| 3. Legibility at 100% | 4 | Axis labels readable. Year labels via ggrepel at size 2.1 are legible at PDF 100%. Caption 3-line wrapping reads cleanly. Some year labels in dense central region are close to path segments — ggrepel handles overlap adequately. |
| 4. Color / accessibility | 5 | Down-limb: Okabe-Ito orange (#D55E00). Up-limb: Okabe-Ito blue (#0072B2). Colorblind-safe two-color design. Reference lines in lighter orange/blue versions of the same hue. |
| 5. Honest uncertainty | 5 | Window sensitivity caption explicitly: "Pre-roe anchors (1951-1965, 1951-1972, 1960-1975) flip gate to NOT refuted." Subtitle "unreturned_driver = REFUTED (composite-dependent)" — includes the key caveat inline. No single certain narrative. |
| 6. Claim-safety | 5 | Subtitle correctly: "unreturned_driver = REFUTED (composite-dependent)". Caption: "Verdict robust to all defensible windows from 1972 onward. Composite-dependent (fishing + predation + PDO)." No overclaiming. Hysteresis not mentioned as confirmed. |
| 7. Label / axis correctness | 5 | x-axis: "Composite effective driver (z-score; fishing + predation + PDO)". y-axis: "Latent biomass (kt, m1_stier_11, all_11)". Reference line values (0.149, -0.155) match synthesis CSV. Limb labels correct (<=2005, >2005). |
| 8. Cross-figure consistency | 4 | theme_pub(9), Okabe-Ito, explicit 170×140mm, companion legend written. Colour coding (orange=down, blue=up) consistent with Fig 4 (driver loop). Minor: Fig 2 uses u-limb blue #0072B2 vs Fig 4 also #0072B2 — consistent. |
| **Total** | **36/40** | **PASS** |

**Issues to note:** Dense scatter in roe-era region makes some year labels hard to trace to their points — acceptable at this n and figure size.

---

## Fig 3: `reversibility_potential` (183 × 120 mm)

| Dim | Score | Notes |
|-----|-------|-------|
| 1. Composition | 5 | Two-panel patchwork (equal widths). Panel A (pre-closure U(x)) fills left half with clear potential well shape. Panel B (right half) uses grey background rectangle to distinguish "not estimable" panel from a real data panel — communicates epistemic gap visually. Minimal whitespace waste; caption below both panels. |
| 2. Data-ink | 5 | Panel A: single line (orange), one diamond minimum marker, one horizontal dashed reference. Panel B: grey background with text only — no fake data drawn. The "NOT ESTIMABLE" text in orange is the central message, not decoration. |
| 3. Legibility at 100% | 4 | Panel A axis labels and minimum annotation clear. Panel B text ("NOT ESTIMABLE" size 4.0 bold, explanatory text size 2.3, verdict size 2.2) all readable at 183mm width, PDF 100%. Caption (below patchwork, size 7pt) reads cleanly in 2-line format. |
| 4. Color / accessibility | 5 | Panel A: Okabe-Ito yellow-orange (#E69F00) line, orange (#D55E00) minimum diamond. Panel B: grey background, orange (#D55E00) "NOT ESTIMABLE" label — draws eye to the correct element. No rainbow. Colorblind-safe. |
| 5. Honest uncertainty | 5 | Panel B is the honest uncertainty figure of the suite. It explicitly shows the post-closure landscape is NOT ESTIMABLE, not a fake flat line or empty well. Text: "This is INDETERMINATE, not evidence against an alternative attractor." Both verdicts (hysteresis, long_transient) labelled INDETERMINATE. Caption reinforces: "this is not a confident absence of a second well." |
| 6. Claim-safety | 5 | No forbidden strings. Panel B text: "This is INDETERMINATE, not evidence against an alternative attractor." Caption: "post-closure is not estimable at n~20 (underpowered, degenerate contract)". No hysteresis verdict assigned. |
| 7. Label / axis correctness | 5 | Panel A: x-axis "Latent biomass (kt)", y-axis "U(x) (potential)". n=55 in subtitle. Minimum labelled "min at ~23 kt". Panel B: axes removed (correct — no data). Subtitles state year ranges and n correctly. |
| 8. Cross-figure consistency | 4 | theme_pub(9), Okabe-Ito, 183×120mm explicit, companion legend written. Panel B lacks standard axes (by design). Minor: Panel A plot area narrower than a single-panel figure at this width — acceptable for 2-panel equal-split. |
| **Total** | **38/40** | **PASS** |

**Issues to note:** None blocking. This figure is the strongest of the suite for honest indeterminacy representation.

---

## Fig 4: `reversibility_driver_loop` (170 × 140 mm)

| Dim | Score | Notes |
|-----|-------|-------|
| 1. Composition | 4 | Scatter + trajectory in driver × state space. Path lines (linewidth=1.0) are prominent. Loop geometry visible: down-limb (orange, wide u range) and up-limb (blue, near u=0) form distinct paths. Annotation box lower right placed in sparse data region. Minor: up-limb path is tightly clustered near u=0 making the "non-retracing" geometry primarily visible in the comparison of up-limb cluster vs down-limb sweep — which is correct biology. |
| 2. Data-ink | 4 | Path line + points with distinguishing shapes (circle=down, triangle=up). ggrepel year labels at decade boundaries. Annotation text box in lower right is functional (loop_p, signed area, mechanism note). |
| 3. Legibility at 100% | 4 | Axis labels readable. Annotation (size 2.1, 5 lines) is legible at 140mm height, PDF 100%. Year labels (size 2.1) readable at print size. Subtitle states loop_p=0.002 prominently. |
| 4. Color / accessibility | 5 | Okabe-Ito orange (#D55E00) down-limb, blue (#0072B2) up-limb — consistent with Fig 2. Shape encoding (circle vs triangle) adds second discriminator. Colorblind-safe. |
| 5. Honest uncertainty | 4 | Annotation explicitly: "Mechanism NOT adjudicable (hysteresis vs slow transient vs composite-driver residual)". Subtitle: "mechanism indeterminate". The non-retracing geometry is presented as real (loop_p=0.002) with explicit mechanism ambiguity. Minor: the figure title "Driver-state path" is neutral — does not claim hysteresis. |
| 6. Claim-safety | 5 | No forbidden strings. Annotation: "Mechanism NOT adjudicable (hysteresis vs slow transient vs composite-driver residual)". Subtitle: "mechanism indeterminate". loop_p=0.002 reported as the permutation test result, not as "proves hysteresis". |
| 7. Label / axis correctness | 5 | x-axis: "Exploitation rate u = catch / latent biomass (fishing driver)". y-axis: "Latent spawning biomass (kt, m1_stier_11, all_11)". Title states 1951-2024. Limb labels in legend correct (down: 1951-2005, up: 2006-2024). loop_p, signed area from verified CSV (driver="u", state="biomass_all11"). |
| 8. Cross-figure consistency | 4 | theme_pub(9), Okabe-Ito, 170×140mm explicit, companion legend written. Orange/blue limb coding consistent with Fig 2. |
| **Total** | **35/40** | **PASS** |

**Issues to note:** Up-limb cluster near u=0 is visually compact — this is data-driven (post-closure fishing = 0) and is the correct representation. The non-retracing geometry is accurately communicated by the comparison of the two limb paths.

---

## Fig 5: `reversibility_controls` (183 × 130 mm)

| Dim | Score | Notes |
|-----|-------|-------|
| 1. Composition | 5 | Two-panel bar charts (1.1:0.9 width ratio, appropriate for the wider Panel A with 12 seed bars vs 4-bar Panel B). Panel A x-axis labels at 45 degrees — no overlap. Panel B bars narrow (width=0.55) for 4 states, well-spaced. Caption below patchwork in 2-line format. |
| 2. Data-ink | 5 | Panel A: bars only, reference dashed line at y=0, FAIL labels on failing seeds only. Panel B: bars only, reference dashed at p=0.05, p-value and sig labels above each bar, power-limit annotation in data white space. No decorative elements. |
| 3. Legibility at 100% | 5 | Panel A: seed labels at 45 degrees are readable; canonical seed (20260519) is green and visually distinct. FAIL labels in orange readable. Panel B: p-values (size 2.1) and sig labels (size 1.9) at bar tops readable at 130mm height. Power-limit annotation (size 2.0) readable. |
| 4. Color / accessibility | 5 | Panel A: green (#009E73) = canonical PASS, blue (#56B4E9) = other PASS, orange (#D55E00) = FAIL — all Okabe-Ito, colorblind-safe, and semantically intuitive. Panel B: yellow-orange (#E69F00) for the marginal significant lo80 bar (p=0.044), grey75 for n.s. bars. p=0.05 dashed line in orange. |
| 5. Honest uncertainty | 5 | Panel A explicitly shows 3/12 seeds fail — not hidden. Power-limit annotation in Panel B: "n.s. at n~75: genuine measurement (power limit; SECONDARY only)" — not dismissing the n.s. result, contextualising it correctly. Seeds 2, 7, 99 fail; shown transparently. |
| 6. Claim-safety | 5 | No forbidden strings. Panel A subtitle: "9/12 seeds pass (75%)". Panel B subtitle: "n~75; power-limited in slow-passage regime". Caption: "S-map nonlinearity is non-significant at n~75; annotated as a known power limit (SECONDARY; never used as a hard gate)." |
| 7. Label / axis correctness | 5 | Panel A: x-axis "Seed", y-axis "lambda_max trend slope (pre-closure)". Seed labels match the 12 seeds from controls.md. Panel B: x-axis "State series", y-axis "S-map nonlinearity p-value". State labels (all_11, focal_9, lo80, hi80) match the nonlinearity CSV. p=0.05 reference labelled. |
| 8. Cross-figure consistency | 5 | theme_pub(9), Okabe-Ito throughout, 183×130mm explicit, companion legend written. Green/orange/blue Okabe-Ito usage is consistent within the figure. |
| **Total** | **40/40** | **PASS** |

**Issues to note:** None. Strongest scoring figure. Transparent about failures (3 seeds), contextualises power limit correctly.

---

## Summary

| Figure | Total | Verdict |
|--------|-------|---------|
| Fig 1: reversibility_lambda_trajectory (170×120mm) | 37/40 | PASS |
| Fig 2: reversibility_state_df (170×140mm) | 36/40 | PASS |
| Fig 3: reversibility_potential (183×120mm) | 38/40 | PASS |
| Fig 4: reversibility_driver_loop (170×140mm) | 35/40 | PASS |
| Fig 5: reversibility_controls (183×130mm) | 40/40 | PASS |
| **Suite** | **186/200** | **PASS** |

All 5 figures pass (≥32/40, no dimension <3).  
Suite minimum dimension score: 4 (Fig 1 data-ink, Fig 2 composition, Fig 4 uncertain representation).  
Suite maximum: 40 (Fig 5 controls).  

**Claim-safety grep (run prior to QA):**
```
grep -i "the system tipped\|proves a fold\|caused by predators\|hysteresis confirmed\|hysteresis refuted" \
  Output/diagnostics/reversibility_synthesis.md
# -> no matches
```

**Key honest-indeterminacy representations confirmed:**
- hysteresis = INDETERMINATE (all 5 figures; never confirmed or refuted)
- unreturned_driver = REFUTED (composite-dependent; Fig 2 states this with caveat)
- long_transient = INDETERMINATE (Figs 1, 3 state this explicitly)
- artifact = REFUTED (loop_p=0.002 in Fig 4; claimed as significant non-retracing, not as hysteresis proof)
- Post-closure U(x): "NOT ESTIMABLE" panel in Fig 3 — no fake well rendered
- S-map n.s.: annotated as power-limited SECONDARY measurement in Figs 1 and 5
