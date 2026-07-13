# Large model fits — archived in Google Drive

*Created: 2026-07-13*

The Bayesian model-fit `.rds` posteriors (m1/m2/m3/m5 families, 700–917 MB each)
are **gitignored** (far over GitHub limits) and reproducible from the Stan
pipeline, but expensive to regenerate (AWS runs). One copy of **every unique
fit** (67 files, ~22 GB) is archived in Google Drive at:

`Stier Lab/People/Adrian Stier/Projects/In Progress/Herring-Predator-Dynamics/large-data/stier-2027-herring-metapopulation/`

(mirrors repo paths; `INDEX.txt` there lists every file + size)

Locally the canonical copies live in `Data/processed/*_fit.rds` (pipeline path,
read by 90+ scripts) and `Output/posteriors/fit_*.rds`. Redundant
`cloud/aws_results/` copies were removed on 2026-07-13 (10 GB reclaimed) after
this archive; each had an identical retained copy.

Note: `Data/processed/` and `Output/posteriors/` still hold identical copies of
the same fits (~13.7 GB duplication) — both are referenced by code, so they were
left intact.
