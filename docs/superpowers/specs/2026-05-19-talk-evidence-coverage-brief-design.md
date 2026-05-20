# Talk Evidence Coverage Brief — design spec

**Date:** 2026-05-19 · **Author:** Adrian + Claude · **Status:** approved (design), pending implementation plan

## Problem

The "Herring Haida Gwaii" NotebookLM notebook now holds 161 vetted sources
(incl. the OCR-repaired papers and the real Pikitch et al. 2012 *Little Fish,
Big Impact*). The Royal Society talk (Wed 20 May 2026) has not leveraged the
full corpus — some evidence and story threads in the notebook are not yet
reflected in the narrative. We want to know, beat by beat, whether the talk
tells a *complete, fully-supported* story, and where the corpus offers
something the talk is not using. This is a synthesis/coverage job, **not** a
rebuild of the talk.

## Goal

A single read-only reference brief the presenter can rehearse from tonight that
answers, per talk beat: what grounded evidence the corpus supports, what
high-value evidence/threads are underused, and what must not be said.

## Non-goals (YAGNI / firewall)

- Does **not** edit NARRATIVE_v3, slides, the deck, or any talk doc.
- Does **not** touch the modeling pipeline (`R/`, `inst/stan/`, `Data/`,
  `Output/`, `Code/`, `_targets.R`) — repo firewall.
- Not a structured DB/CSV, not a new schema, not per-source exhaustive notes.
- Not a retool of the narrative or slide order.

## Artifact

`analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md` — one Markdown
file, organized by the NARRATIVE_v3 23-slide spine grouped into the ~14 content
beats used by `SLIDE_REVISION_TODO_2026-05-19.md` (so it aligns with what is
being revised for tomorrow).

### Structure

Top of file:
- **Top 5 story gaps to fix before tomorrow** — highest-leverage things the
  full corpus supports that the talk is not using.

Per beat:
- **Story job** — one line, from NARRATIVE_v3: what this beat must land.
- **Evidence in hand** — 1–4 items, each: claim → exact number → NotebookLM-
  verified source(s) → safe phrasing (consistent with
  `talk-model-claim-control-sheet.md`).
- **⚠️ Underused / story gap** — sources or threads among the 161 that would
  strengthen/complete the beat but are not used yet; or "well covered."
- **🚩 Risk flag** — claims that are weak, contested, or would violate the
  claim-control sheet (so they are *not* said on stage).

## Method

1. **Read current spine:** NARRATIVE_v3, `SLIDE_REVISION_TODO_2026-05-19.md`,
   `docs/herring-non-recovery-hypotheses.md`, `docs/talk-model-claim-control-sheet.md`.
2. **Prerequisite — Pikitch swap (approved):**
   - File `~/Downloads/Pikitch et al 2012 - Little Fish, Big Impact.pdf` →
     `analysis/04_talks/2026-royalsociety/Reference_Papers/Pikitch_2012_LittleFishBigImpact_Lenfest.pdf`
     (120 pp, ~345k chars, text-clean — verified).
   - Delete the broken NotebookLM Cloudflare-stub source
     `b513bbe5-9f13-4abb-88e5-4da87a0596d4` (currently mis-titled
     `Pikitch_2014_ForageFishContribution.pdf`); upload the real 2012 report as
     a new source; verify it indexes via a grounded query.
   - **2012 ≠ 2014:** the Lenfest *Little Fish, Big Impact* report (Pikitch
     et al. 2012) is a different publication from Pikitch et al. 2014 *Fish &
     Fisheries* (DOI 10.1111/faf.12004). Only the 2012 report is in hand; the
     2014 paper remains a separate, still-missing item — do **not** rename or
     conflate them. Leave the local `Pikitch_2014_ForageFishContribution.pdf`
     stub + its `.preocr.bak` untouched; update ACQUISITION_LOG accordingly.
3. **NotebookLM sweep** of the 161-source notebook
   (`63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`):
   - one targeted query per beat (claims + exact numbers + source IDs);
   - 4 corpus-wide gap sweeps: (a) what a critical forage-fish / tipping-points
     expert would say the story is missing; (b) strongest counter-evidence to
     the non-recovery framing; (c) orphan evidence (sources nothing else
     corroborates); (d) what Pikitch 2012 uniquely adds.
   - Async queries (`notebook_query_start` → poll) given notebook size.
4. **Cross-check** every number against the claim-control sheet; conflicts are
   flagged in the 🚩 line, never smoothed. Every claim keeps its source for
   on-stage traceability.
5. **Compile** into the brief; write the Top-5 summary last.

## Success criteria (Done =)

- Every beat has ≥1 grounded claim or an explicit "thin evidence" note.
- Every beat has a gap/underused verdict.
- Top-5 story-gap summary written.
- No claim contradicts `talk-model-claim-control-sheet.md` without a 🚩 flag.
- Pikitch 2012 present and indexed in the notebook (verified by a grounded
  query) before the sweep relies on it.

## Risks

- NotebookLM async queries are slow on a 161-source notebook and the CLI
  `--wait` is unreliable → use `notebook_query_start` + polling, pace sweeps.
- Corpus may surface claims that contradict the locked narrative → these go in
  🚩/⚠️ for the presenter to decide, not silently into "evidence in hand."
- Time budget (talk is next day) → beats are processed highest-uncertainty
  first; partial completion still yields a usable Top-5 + covered beats.
