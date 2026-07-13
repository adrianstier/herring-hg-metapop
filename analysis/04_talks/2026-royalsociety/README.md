# US–UK Forum 2026 — Talk Workspace

Self-contained working dossier for Adrian Stier's talk at the **US–UK
Scientific Forum on Shifts and Tipping Points in Ocean Systems** (The Royal
Society, London; Wed 20 May 2026, 09:30, Session 5 — *Tipping Points in
Ecosystem Services*; ~25 min).

Moved here from `~/Desktop/USUK_Forum_2026_Project` on 2026-05-16 so the forum
work is integrated into the repo, version-aware, and traveling with the
project — **but firewalled from the core analysis.**

---

## ⚠️ Separation rule (read this)

This directory is **TALK-ONLY**. It is *not* part of the herring
metapopulation analysis.

- **Do NOT** import anything here into the modeling pipeline (`R/`,
  `inst/stan/`, `Data/`, `Output/`, `_targets.R`, `Code/`). Nothing in this
  folder is a model input, a data product, or an analysis artifact.
- The core analysis must remain reproducible and unaffected by talk prep.
  Predator/portfolio numbers used in the talk must be pulled *from* the core
  analysis (current `m1_stier_11`), never the reverse.
- Reference PDFs here are a **curated forum subset**, not the maintained
  literature library (`Literature/` + Google Drive remain canonical).

## Relationship to the rest of the talk infrastructure

`docs/HERRING_TALK_ASSETS.md` is the **single source of truth / master
index**. It points at three stores; this directory is one of them:

1. **This in-repo dossier** (`analysis/04_talks/2026-royalsociety/`) — forum-specific working
   materials: agenda, the 9 curated reference papers, HG timeline, trip
   logistics, and where the talk **outline / drafts / deck** will live.
2. **Google Drive asset library** (`1fboyHfQj…`) — the large photo/figure/deck
   library + 60-paper set (see index §3f).
3. **This modeling repo** — the quantitative herring results the talk cites.

Always update `docs/HERRING_TALK_ASSETS.md` (Talk Build State) when work here
changes — that is how multiple Claude/Codex sessions stay in sync.

## Talk direction (current)

- The **submitted abstract is NOT the guide** — it was early concepts only.
- Working direction: **Spine B — coupled social–ecological tipping points**
  (ecological regime shift that did *not* recover after fishing stopped
  [hysteresis] + a coupled social/knowledge/governance threshold; co-governance
  as a structural intervention). **Not** "portfolio/asynchrony as an
  early-warning indicator." Solutions-forward (chair's explicit ask).
- The outline is still being finalized — see `docs/HERRING_TALK_ASSETS.md`.

## Contents

| Path | Tracked in git? | What it is |
|---|---|---|
| `INDEX.txt` | yes | Original archive index (provenance, exported 2026-05-16 Tahiti) |
| `Forum_Documents/*.pdf` | no (gitignored) | Draft agenda — use `*_readable.pdf`; the other is a zipped image bundle |
| `Talk_Materials/herring_haida_gwaii_timeline.html` | yes | Interactive HG herring timeline (open in browser) |
| `Trip_Dossier/*.html` | no (gitignored) | Private trip plan: flights, programme, forms, accommodation, contacts |
| `Reference_Papers/ACQUISITION_LOG.md` | yes | Source/acquisition status for the forum reference subset |
| `Reference_Papers/*.pdf` | no (gitignored) | Curated cited papers on disk + Drive; not stored in git |

Heavy PDFs are gitignored on purpose (same policy as `Literature/`): too large
for git, kept on disk + Drive. Trip logistics are also gitignored because they
contain private travel/contact details. The structure, README, INDEX, working
text/HTML, and paper-acquisition log are tracked so the talk state travels with
the repo without storing private itinerary details.

**Not yet included** (per `INDEX.txt`): the Participant Information PDF and the
full Programme Booklet — add when retrieved (Gmail msg `19e21e7b74b30c97`).

## Suggested home for new talk work

- `Talk_Materials/` — outline, slide drafts, speaker notes, the working deck.
- Keep analysis figures pulled from the core repo's `Output/figures/` by
  reference (path/ID) — do not fork or hand-edit them here.
