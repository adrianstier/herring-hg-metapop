# Portfolio numbers - reconciliation and provenance (resolved)

Reconciles the portfolio/synchrony numbers wired into BUILD #1/#3 of
`talk_production_plan.md`. **Do not invent numbers.** The key correction: some
wired figures are **Stier et al. 2020 published results**, *not* outputs of the
current `m1_stier_11` refit - they must be attributed as such, not relabelled
as current analysis.

## Current `m1_stier_11` portfolio metrics (use these as the "current" numbers)

Source: `Output/diagnostics/m1_stier_11_portfolio_metrics.md` (generated
2026-05-12); figure `Output/figures/portfolio_metrics_combined.pdf` /
`m1_stier_11_portfolio_metrics_combined.pdf`; CSVs
`Output/diagnostics/m1_stier_11_portfolio_recent_summary.csv`,
`..._period_summary.csv`. Cross-checked vs `docs/saturday-talk-readiness-2026-05-16.md` (TP-01).

| Metric (recent, 10-yr windows) | All-11 | Focal-9 |
|---|---|---|
| Synchrony | **0.63** | **0.70** |
| Simpson effective sections | **3.26** | **3.31** |
| Top-three biomass share (recent **period**) | **84%** | **85%** |
| Top-three biomass share (current **year** summary) | about **76%** | n/a |

Use the **period** share (84%) when discussing portfolio erosion; the
current-year value (~76%) is a different read (per TP-01). Span/structure:
m1_stier_11 fits **11** sections with a **focal-9** reporting sensitivity;
series length is about **65 years** (1950s-present). These are consistent and
fine.

## Stier et al. 2020 results - KEEP, but attribute (NOT m1_stier_11 outputs)

These three were wired as bare BUILD #3 annotations with no attribution. They
are **Stier et al. 2020 (*Ecosphere*) published findings**, not produced by the
current refit. The current `m1_stier_11` docs do **not** report a "2.1x"
portfolio multiplier or a "0.17 to 0.28" synchrony pair.

| Wired number | Truth | Action |
|---|---|---|
| "2.1x more stable than a homogeneous metapopulation" | Stier 2020 portfolio-effect statistic | Keep only if labelled "(Stier et al. 2020)"; do not call it current |
| "local harvest 65% vs archipelago 4%" | Stier 2020 scale-mismatch / serial-depletion result | Keep, labelled "(Stier et al. 2020)" |
| "synchrony 0.17 to 0.28" (early-vs-late) | Stier 2020-era pairing | Replace the on-screen *current* number with m1_stier_11 synchrony 0.63 (all-11) / 0.70 (focal-9); if showing change-over-time, use the m1_stier_11 period summary CSV, not 0.17 to 0.28 |
| "asynchrony index 1 to 0" | schematic device | OK as a *visual* device; any on-screen number must be the current synchrony (0.63/0.70) or Simpson (3.26/3.31), sourced as above - not an unlabeled index |

## Net rule for the deck

- **Current-analysis claims** (synchrony 0.63/0.70, Simpson 3.26/3.31, top-3
  84%) cite `m1_stier_11_portfolio_metrics.md`.
- **The scale-mismatch / portfolio-effect story** ("65% vs 4%", "2.1x")
  cite **Stier et al. 2020** explicitly. It is the published motivation, not a
  re-estimated current output. Keeping both, correctly attributed, is stronger
  than blending them into one unsourced number.
- Never present a Stier-2020 figure as an `m1_stier_11` result, and never the
  early abstract's "7 of 9 since 1994" phrasing as a current number without
  checking it against `m1_stier_11`/TP-01.

## S8 realized-growth slide — ALL-11 (decision 2026-05-18)

- **Adrian's call:** S8 shows **all 11 `m1_stier_11` sections**, not the
  focal-9 Stier-2020 replication. The deck figure
  (`Output/figures/lecture/deck/s08_realized_growth.png`, `Code/07cz` S8
  block) now reads `Output/diagnostics/stier2020_updated_companion_growth_change.csv`
  (per-section mean realized growth, m1_stier_11), **not** the focal-9
  `stier2020_updated_fig5_growth_periods.csv`.
- **On-slide number:** "**9 of 11 sections declined**" — data-exact:
  `post_growth_median < hist_growth_median` for 9 of the 11 sections
  (risers = Port Louis + Tasu Sound). This is a *current `m1_stier_11`*
  number, not the early abstract's "7 of 9 / 8 of 9". Do not blend with the
  focal-9 count.
- **Metric note:** companion `hist/post_growth_median` is on a different
  scale (λ ≈ 0.94–1.17, per-era mean realized growth) than the focal-9 fig5
  (λ ≈ 1.3–1.6). They are different reads of m1_stier_11 — never mix the two
  scales or counts on one slide.
- **Sparse sensitivity:** Tasu Sound & Naden Harbour are retained in
  m1_stier_11 but excluded from Stier-2020 focal panels; on S8 they are
  drawn grey/dashed + "(sparse)"-labelled, never hidden. Medians only — no
  per-section significance claim (claim-control sheet).
