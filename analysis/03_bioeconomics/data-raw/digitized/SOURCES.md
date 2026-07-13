# L3a digitized value/price — source attribution

Anchor points encoded in `L3_digitized_value.csv`. Three provenance tiers:

- **source_stated** — verbatim from a primary source (Rebuilding Plan §5.2.3.4.3 / §5.2.3.5.2; Powell-Harris 2012 WHQ; DFO IFMP 2006 Table 9; Haida Marine TEK Vol. 3).
- **chart_read** — extracted from a published figure (DFO Pacific Herring IFMP Figure 9, coast-wide commercial roe-seine landed value 1992–2004); ±10%; not yet a formal WebPlotDigitizer pass.
- **derived** — value÷tonnage or per-period averages (labelled in the CSV).

Authoritative sources on disk:
- `analysis/04_talks/2026-royalsociety/Reference_Papers/HG_Herring_Rebuilding_Plan_2024_CHN_DFO_ParksCanada.pdf` (Figs 25/26 SOK; 27 SOK value; 31/32 roe value; §5.2.3.4.3, §5.2.3.5.2)
- Powell-Harris 2012, *Divided Waters*, Western Historical Quarterly (via NotebookLM)
- DFO Pacific Herring IFMP (multiple years; Fig. 9 + 2006 Table 9)
- Haida Marine Traditional Knowledge Study Vol. 3 (Jones Sr., Wilson, Williams)

**Nominal-midpoint caveat:** The 1975 and 2015 SOK $/lb points are nominal midpoints of the Rebuilding Plan's real-2020$ bands ($16-31/lb 1970s; $11-14/lb recent) — flagged for Task 11 QA. The 1995 ($40/lb) and 2004 ($5.99/lb) figures are NOMINAL per IFMP.
