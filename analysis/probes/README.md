# `analysis/probes/` — reserved scaffold

**Status:** scaffold (currently empty).

Originally planned as the destination for `Code/07_*.R` dossier scripts. Those 71 post-fit probes instead went to **`Code/probes/`** because they operate on core-model outputs (`Output/diagnostics/`) and `here::here()`-relative paths — they belong with the core pipeline, not under a derivative workstream.

This directory is kept as a reserved scaffold for **future cross-workstream probes** that don't fit cleanly into `01_ews/`, `02_resilience/`, or `03_bioeconomics/` — for example, exploratory analyses that join EWS and resilience signals, or scratch work that hasn't been promoted to a named workstream yet.

## If you need a probe destination

- **Post-fit diagnostic on the core model** → `Code/probes/`
- **EWS-specific exploration** → `analysis/01_ews/scripts/`
- **Resilience/hysteresis exploration** → `analysis/02_resilience/scripts/`
- **Cross-cutting one-off** → here (`analysis/probes/`)
