# herring-bioeconomics

Standalone bioeconomic backbone + four-lens economic analysis of the BC / Haida Gwaii Pacific herring fishery. Phase 0 reconstructs the bioeconomic panel consumed by lenses C/A/B/D. Biology is imported read-only from the stier-2027-herring-metapopulation repo (one-directional firewall). After cloning, regenerate the backbone with `Rscript -e 'targets::tar_make()'`; `data/herring_bioeconomic_backbone.csv` is a reproducible build artifact and is intentionally not committed.
