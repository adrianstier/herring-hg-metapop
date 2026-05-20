# S8 landed-value figures — provenance & reproduction

Extracted 2026-05-17 for the value-layer slide (now S12, originally S8:
"the value peaked while the system fell").
**Do not invent numbers.** These are page renders of a published DFO/CHN/Parks
Canada figure; the underlying slip-level data is DFO-confidential (see below).

## Source document

DFO / Council of the Haida Nation / Parks Canada (2024). *Haida Gwaii
ʹíináang | iinang Pacific Herring Rebuilding Plan: An Ecosystem Approach.*
- On disk: `analysis/04_talks/2026-royalsociety/Reference_Papers/HG_Herring_Rebuilding_Plan_2024_CHN_DFO_ParksCanada.pdf`
  (identical copy also in repo: `Output/diagnostics/dfo_assessment_public_sources/dfo_hg_rebuilding_plan_2024.pdf`)
- DFO WAVES: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf
- The figures are on **PDF page 192** (List-of-Figures printed pp. ~190–191).
  Rendered at 200 dpi with `pdftoppm`.

## Files here

| File | What it is |
|---|---|
| `RebuildingPlan2024_p192_Fig31-32_roe_landed_value_FULLPAGE.png` | Full page 192 — both figures + captions + source line (self-documenting; the provenance anchor) |
| `RebuildingPlan2024_Fig31_roe_gillnet_landed_value_2020dollars.png` | Crop: Figure 31 (roe gillnet) |
| `RebuildingPlan2024_Fig32_roe_seine_landed_value_2020dollars.png` | Crop: Figure 32 (roe seine) |
| `RebuildingPlan2024_p190_Fig27_SOK_landed_value.png` | Context: Fig 27 spawn-on-kelp landed value |
| `RebuildingPlan2024_p191_Fig29-30_roe_catch.png` | Context: Fig 29/30 roe *catch* (not value) |

## What the figures show (transcribed from the rendered page; titles confirmed against the PDF text layer)

- **Figure 31. Commercial roe gillnet landed value trends in British Columbia
  (coastwide) and Haida Gwaii Major SAR (2E).** Y-axis: *Roe Herring Gillnet
  Landed Value (adjusted to 2020$)* (also a nominal "(2020$)" variant exists in
  the doc). Coastwide series reaches the ~$1.4–1.6×10⁸ range; Haida Gwaii (2E)
  is the much smaller series; annotation notes the HG gillnet fishery has been
  closed since 1995. **Source (in figure): DFO fish slips.**
- **Figure 32. Commercial roe seine landed value trends in British Columbia
  (coastwide) and Haida Gwaii Major (2E) and Minor (2W) SARs.** Y-axis: *Roe
  Herring Seine Landed Value (adjusted to 2020$)*. Annotation: the HG roe seine
  fishery has been closed since 2002. **Source (in figure): DFO fish slips.**

Companion narrative (Rebuilding Plan §5.2.3.5.2): BC roe-herring landed +
wholesale value **"peaked in the 1980s, was relatively high until the
mid-1990s, dropped … 1995-2005, and then again declined from 2008-present …
modest increase … 2016-18."** (verbatim quotes + page refs in
`../S8_landed_value_provenance.md`).

## ⚠️ Two honesty guardrails for the slide

1. **Coastwide vs Haida Gwaii are different magnitudes.** The big curve is
   *BC coastwide*; the *Haida Gwaii* series is far smaller. S8 must state which
   it plots. (For the HG case, HG-specific value is the relevant one.)
2. **The older "1993 peak / ~$40M" wording is still unsourced.** The current
   production plan has been corrected to the published source: "peaked in the
   1980s, high to mid-1990s, then declined." If an exact peak year/$ is needed
   on the slide, read it off these figures explicitly (state "digitized from
   Rebuilding Plan Fig 31/32") or request the raw series — do not assert
   1993/$40M.

## The raw "fish slips" — status

Raw DFO commercial **fish-slip** (sales-slip) records are **confidential** (DFO
suppresses where <3 licence holders); they are not a public download. The
authoritative *public* renderings are exactly these Rebuilding Plan figures
(DFO fish-slip basis). A tabular series is **not** in the public PDF; Rebuilding
Plan "Appendix E (available on request)" covers commercial fishery detail.
Routes to exact points, in order:
1. **Reproduce/redraw Fig 31/32** with attribution (defensible now — no new
   data needed). Recommended for the talk.
2. **Digitize** the bars from these PNGs (WebPlotDigitizer) — label any derived
   number "digitized from Rebuilding Plan 2024 Fig 31/32 (DFO fish slips)".
3. **Formal DFO data request** / Rebuilding Plan authors / DFO Pacific Region
   commercial catch & landed-value statistics — for the underlying annual
   series. (Complementary public source: the DFO Pacific Herring **IFMP
   2024–25** has recent-year landed-value *shares*, e.g. roe-herring = 79% of
   total herring landed value in 2020 — repo extract
   `Output/diagnostics/dfo_assessment_public_sources/dfo_herring_ifmp_2024_2025.txt`.)
