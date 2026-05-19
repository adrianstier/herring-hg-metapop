# Session Log 2026-05-17

## Talk/model guardrail pass

Request: execute the five next steps from the status review: make the talk
package coherent, tighten the predator story, finish the Doherty gap table,
clean/commit talk-prep files separately, and consider AWS only if justified.

Actions:

- Added `docs/talk-model-claim-control-sheet.md` as the talk-facing model-use
  contract.
- Added `docs/doherty-style-hg-gap-table.md` as the concise answer to how far
  the repository is from a full Doherty-style HG replication.
- Updated `talk-usuk-forum-2026/Talk_Materials/talk_production_plan.md` to
  resolve the predator rigor flag: predator demand is large and WCVI provides
  a mechanism analogue, but no HG predator coefficient is promoted.
- Updated the talk timeline so the 2020/2021 entries no longer claim predator
  recovery is the identified HG cause.
- Updated `docs/HERRING_TALK_ASSETS.md`, `AGENTS.md`, and `CLAUDE.md` to point
  future sessions to the claim control sheet and gap table.
- Updated talk workspace tracking policy so `Trip_Dossier/` stays local and
  gitignored because it contains private travel/contact details; the
  acquisition log remains trackable while heavy PDFs stay ignored.

Scientific state:

- `m1_stier_11` remains the only promoted baseline.
- Held branches remain held: `m1_stier_method_sensitivity`,
  `m1_stier_obs_hier`, `m2_stier_site_growth`, `m3_stier_distance`,
  `m5_stier_predation_pressure`, and `m5_stier_predator_demand_total`.
- Archived branches remain uninterpretable: `m5_v5` and `m5_combined`.
- The talk-safe predator line is: large ecological pressure and future
  data-product priority, not a promoted causal coefficient for Haida Gwaii.
- The Doherty-safe line is: public HG data extraction and proxy bridge are
  source-traceable, but exact age/weight/length/catch inputs, effective sample
  sizes, and predator age/size selectivity are still missing for a full
  catch-at-age predation-mortality replication.

Next check:

- AWS refresh attempted with `aws sts get-caller-identity --profile herring`;
  the SSO token was expired. `aws sso login --profile herring` opened the
  browser login URL but did not complete unattended, so no current AWS poll was
  possible in this session. The regenerated local AWS report is explicitly
  stale and no new model job was submitted.
- Do not submit a new job unless a later authenticated AWS poll plus the model
  ledger exposes a single justified covariate branch.
