# Large data — herring repos (Drive archive)

*Created: 2026-07-12*

Oversized data files that are **gitignored** in the herring GitHub repos (too
big for GitHub / kept out of git). Archived here so they're preserved,
shareable, and discoverable. Folder layout mirrors each repo's own path, so a
file's original location is exactly `<repo>/<relative path shown below>`.

## pacific-herring-predators  (GitHub `stier-lab/pacific-herring-predators`)

| File | Repo-relative path | Size | Source |
|------|--------------------|------|--------|
| `All Areas NuSEDS_20251103.csv` | `data/raw/nuseds_salmon/All_Areas_NuSEDS_unzipped/` | 215 MB | DFO NuSEDS (open.canada.ca) — salmon escapement |
| `HS-MSA_biology.csv` | `data/raw/dfo_synoptic_trawl/HSMSA_multispecies_trawl_2026-03_unzipped/Hecate_Strait_Multispecies_Assemblage_Trawl_Survey_EN/` | 82 MB | DFO synoptic bottom-trawl (open.canada.ca) |
| `QCS_biology.csv` | `data/raw/dfo_synoptic_trawl/QCS_synoptic_trawl_2026-03_unzipped/Queen_Charlotte_Sound_Synoptic_Bottom_Trawl_Survey_EN/` | 65 MB | DFO synoptic bottom-trawl (open.canada.ca) |

All three are the unzipped extracts of `.zip` archives that also live in the
repo at the same parent folder; they are re-extractable from those zips as well.
Exact dataset URLs are in the repo's data-source documentation.

## To restore into a fresh clone
Copy a file from here to the same relative path under the repo, e.g.:
`cp "large-data/pacific-herring-predators/data/raw/nuseds_salmon/All_Areas_NuSEDS_unzipped/All Areas NuSEDS_20251103.csv" ~/pacific-herring-predators/data/raw/nuseds_salmon/All_Areas_NuSEDS_unzipped/`

## stier-2027-herring-metapopulation  (GitHub `adrianstier/herring-hg-metapop`)

One copy of **every unique model-fit `.rds`** (67 files, ~22 GB) — the Bayesian
state-space posteriors (m1/m2/m3/m5 families incl. predator-covariate and
distance models). Gitignored in the repo; reproducible from the Stan pipeline
but expensive (AWS runs). Folder mirrors repo paths; see `INDEX.txt` for the
full list with sizes. Local repo keeps the canonical `Data/processed/` +
`Output/posteriors/` copies; redundant `cloud/aws_results/` duplicates were
removed after this archive.
