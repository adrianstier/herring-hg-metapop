# Backbone QA Report

Generated: 2026-05-19 22:39:34 UTC

## Shape
- Rows: 385
- Regions: HG, PRD, CC, SoG, WCVI
- Year range: 1950–2026

## Layer coverage
- L0 institutions: present (regime + fishery_open)
- L1 biology (biomass_t, HG only): 75 non-NA rows
- L2 harvest (catch_total_t, HG only): 51 non-zero rows
- L3a digitized value/price: present (15 rows)
- L3b kazunoko: ABSENT (Comtrade key needed)
- L3c FX (fx_jpy_per_cad): present (50 rows)
- L3c deflator (roe_value_cad_real2020): ABSENT (FRED key needed)

## Anchor reconciliation
- HG 1956 total catch: 83,653 t (Hourston 1980 anchor 77,500; DFO source ~83,653; gap ~8% — methodology)
- HG 1979 ex-vessel roe (CAD/ton): 5500
- HG 1995 SOK price (CAD/lb): 40

## Known caveats (carry into Lens C/D)
- SOK price 1975 and 2015 rows are nominal midpoints of Rebuilding Plan real-2020$ bands (`$16-31/lb 1970s; $11-14/lb recent`).
- IFMP Fig 9 values are chart-read (±10%), not yet formally digitized.
- HG-specific landed values are not separable in DFO records (PFMA-level reporting).
- 1979 vs 1990s anchors are different baskets (gillnet roe-quality vs fleet-average all-gear) — not strictly comparable on one $/t axis.
- BoC FXJPYCAD ~2017+ only; pre-2017 CAD-JPY needs alternate source (FRED DEXJPUS x DEXCAUS).
- HS 030520 (Japan kazunoko proxy) covers all fish roe — over-broad.
