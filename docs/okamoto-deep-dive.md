# Deep Dive: Borrowing from Okamoto et al. (2020)

This note was revised after checking the local PDFs directly:

- [Okamoto et al. 2020](/Users/adrianstier/stier-2027-herring-metapopulation/Literature/Okamoto%20et%20al.%20%28Ecological%20Applicaitons%29%202020.pdf)
- [DFO Haida Gwaii 2025 data summary](/Users/adrianstier/stier-2027-herring-metapopulation/Data/raw/dfo-spawn/DataSummary.HG.2025.pdf)
- [Daniel 2014 DFO herring assessment](/Users/adrianstier/stier-2027-herring-metapopulation/Literature/Daniel_2014_DFO_BC_Herring_Stock_Assessment_2013.pdf)
- NotebookLM notebook `Herring Haida Gwaii`

The earlier version of this note overstated what the sources support. The main corrections are below.

## 1. What Okamoto Actually Supports

Okamoto's empirical Model 2 is a biomass-based Bayesian hierarchical state-space model, not a section-level age-structured model. The model:

- uses site-specific demographic parameters,
- estimates spatially correlated process error,
- estimates location-specific observation error, and
- uses a common survey-bias parameter with `ln q ~ normal(0, 0.05)`.

That supports three defensible borrowings for this project:

1. site-specific observation error,
2. spatially correlated process error, and
3. a much tighter survey-bias prior than the vague v1/v2 specification.

## 2. The DFO Spawn Index Is Not Absolute Biomass

The DFO 2025 data summary states that the spawn index:

- "is not scaled by the spawn survey scaling parameter, q", and
- should be treated as a minimum observed spawning biomass derived from egg counts.

So the correct interpretation is not "the spawn index is already absolute biomass." Instead:

- a survey-scaling term is still needed,
- a tight prior on `q` is useful for identifiability, and
- any prior centered far from the documented source value needs explicit support.

## 3. What To Do With q

There are two distinct source-backed ideas here:

1. Okamoto / Martell support a tight prior on a common survey-bias term:
   `ln q ~ normal(0, 0.05)`.
2. Stier 2020 estimated separate `q` values for surface and SCUBA survey eras.

For Haida Gwaii, the defensible path is:

- keep method-specific survey effects because the data span surface and dive eras,
- use the strongest prior support on the dive-era scaling term,
- avoid inventing a new prior mean unless a source explicitly justifies it.

Important correction:
The historical `m3_v4` experiment used a dive prior centered near `q = 0.57`. That value is not supported by the local Okamoto excerpt checked here. Treat that model as exploratory provenance, not a current promotion candidate.

## 4. Zero Spawn Observations Need Dataset-Specific Handling

NotebookLM surfaced the Stier 2020 choice to treat zero spawn records as missing because, in that earlier analysis, zeros were considered ambiguous.

That choice is now the preferred baseline direction for this project unless survey metadata clearly justify a stronger nondetection interpretation.

Our current Haida Gwaii section-level DFO survey data contain zero records, but not every zero or lack of survey effort is biological evidence for low biomass. Some site-years may be unsurveyed for governance/access reasons, including Haida preferences. For this dataset, the defensible options are:

- Stier-aligned ambiguous zeros treated as missing,
- left-censored or detection-aware zeros as a sensitivity analysis,
- or a carefully justified rule tied to explicit survey metadata.

Defaulting all zeros to informative nondetections would overinterpret the survey process. Defaulting all zeros to missing is more faithful to Stier et al.; the detection-aware branch should be reported as sensitivity.

## 5. Additional DFO Data Worth Adding

The DFO materials support adding more information, but mostly as shared covariates or priors, not as a full section-level age-structured model.

Useful additions:

- age composition from commercial and test-fishery samples,
- regional weight-at-age time series,
- spawn timing,
- substrate-specific spawn observations (`surface`, `Macrocystis`, `understory`),
- catch sources not always captured cleanly in the section catch matrix,
- predator time series as regional covariates.

What these are best for:

- regional covariates on productivity or recruitment,
- informative priors,
- observation-model refinement,
- posterior interpretation.

What they probably do not support cleanly:

- a full independent age-structured model for each of the 11 sections.

The Daniel 2014 DFO assessment is explicit that ISCAM is fit at the stock-area level using catch, spawn index, and age composition. That is a different data-resolution problem than the section-level metapopulation analysis here.

## Recommended Next Step

The most defensible near-term path is:

1. finish `m3_v3` and `m5_v3`,
2. compare them against `m1_v3`,
3. treat `m3_v4` as experimental until the `q = 0.57` prior source is verified,
4. prepare a next-round model that adds regional age/weight-at-age and spawn-timing covariates without forcing a section-level age-structured model.
