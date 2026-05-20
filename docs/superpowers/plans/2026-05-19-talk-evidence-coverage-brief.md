# Talk Evidence Coverage Brief — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a read-only, per-beat evidence-coverage brief that shows whether the Royal Society herring talk leverages the full 161-source NotebookLM corpus to tell a complete, supported story.

**Architecture:** Swap the real Pikitch 2012 report into the notebook; scaffold one Markdown brief from the NARRATIVE_v3 23-slide spine; populate each beat via targeted NotebookLM queries plus 4 corpus-wide gap sweeps; cross-check every number against the claim-control sheet; finish with a Top-5 gap summary.

**Tech Stack:** `nlm` CLI v0.6.10 + notebooklm-mcp async query tools; NotebookLM notebook `63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e` ("Herring Haida Gwaii"); Markdown.

**Commit policy:** User config = commit only when asked. This plan contains **no git steps**; Task 6 ends by *offering* a commit. Do not auto-commit.

**Spec:** `docs/superpowers/specs/2026-05-19-talk-evidence-coverage-brief-design.md`

---

## File Structure

- Create: `analysis/04_talks/2026-royalsociety/Reference_Papers/Pikitch_2012_LittleFishBigImpact_Lenfest.pdf` — the real report, filed.
- Create: `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md` — the deliverable brief.
- Modify: `analysis/04_talks/2026-royalsociety/Reference_Papers/ACQUISITION_LOG.md` — record the 2012 swap + 2012≠2014 note.
- NotebookLM (no local file): delete stub source `b513bbe5-9f13-4abb-88e5-4da87a0596d4`, add the 2012 report.

The brief is one file (one responsibility: talk evidence coverage). It is never edited by, and never edits, the modeling pipeline or the talk narrative/slides.

---

### Task 1: Swap in the real Pikitch 2012 report and verify it indexes

**Files:**
- Create: `analysis/04_talks/2026-royalsociety/Reference_Papers/Pikitch_2012_LittleFishBigImpact_Lenfest.pdf`
- Modify: `analysis/04_talks/2026-royalsociety/Reference_Papers/ACQUISITION_LOG.md`

- [ ] **Step 1: File the PDF with the convention name and verify it is text-clean**

Run:
```bash
cd /Users/adrianstier/stier-2027-herring-metapopulation/analysis/04_talks/2026-royalsociety/Reference_Papers
cp "/Users/adrianstier/Downloads/Pikitch et al 2012 - Little Fish, Big Impact.pdf" \
   "Pikitch_2012_LittleFishBigImpact_Lenfest.pdf"
echo "header=$(head -c5 Pikitch_2012_LittleFishBigImpact_Lenfest.pdf) pages=$(mdls -name kMDItemNumberOfPages -raw Pikitch_2012_LittleFishBigImpact_Lenfest.pdf) chars=$(pdftotext Pikitch_2012_LittleFishBigImpact_Lenfest.pdf - | tr -d '[:space:]' | wc -c | tr -d ' ')"
```
Expected: `header=%PDF- pages=120 chars=~345000` (chars > 300000).

- [ ] **Step 2: Delete the broken Cloudflare-stub NotebookLM source**

Use the `mcp__notebooklm-mcp__source_delete` tool (load via ToolSearch `select:mcp__notebooklm-mcp__source_delete` if not loaded):
`source_id="b513bbe5-9f13-4abb-88e5-4da87a0596d4"`, `confirm=true`.
Expected: `{"status":"success", "deleted_count":1}`. (Deletion of this stub was pre-approved in the spec.)

- [ ] **Step 3: Upload the real 2012 report (retry; `--wait` is broken so omit it)**

Run:
```bash
cd /Users/adrianstier/stier-2027-herring-metapopulation/analysis/04_talks/2026-royalsociety/Reference_Papers
NB=63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e
for a in 1 2 3 4 5; do
  o=$(nlm source add "$NB" --file "Pikitch_2012_LittleFishBigImpact_Lenfest.pdf" 2>&1)
  echo "$o" | grep -q "✓ Added source" && { echo "$o" | grep -E "Source ID"; break; } || { echo "attempt $a failed"; sleep 8; }
done
```
Expected: a line `Source ID: <uuid>`. Record that UUID as `PIKITCH2012_SID`.

- [ ] **Step 4: Verify it is indexed via a grounded scoped query**

Use `mcp__notebooklm-mcp__notebook_query_start` (load via ToolSearch if needed):
- `notebook_id="63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e"`
- `source_ids=["<PIKITCH2012_SID>"]`
- `query="State the Lenfest Forage Fish Task Force's headline recommendation and one concrete number (e.g., the global value of forage fish as catch vs. as prey)."`

Then poll `mcp__notebooklm-mcp__notebook_query_status` (pace with a backgrounded `sleep 60`) until `status:"completed"`.
Expected: a grounded answer citing `<PIKITCH2012_SID>` with a real number (e.g., ~$5.6B catch vs ~$11.3B supportive value). If it reports "no readable text," STOP — the wrong file was uploaded; recheck Step 1.

- [ ] **Step 5: Record the swap in ACQUISITION_LOG.md**

Append a dated `## UPDATE 2026-05-19b — Pikitch 2012 (real report) acquired` section stating: the Lenfest *Little Fish, Big Impact* (Pikitch et al. 2012, 120 pp) is now filed and indexed as `Pikitch_2012_LittleFishBigImpact_Lenfest.pdf` / source `<PIKITCH2012_SID>`; it is **distinct from** the still-missing Pikitch et al. 2014 *Fish & Fisheries* paper (DOI 10.1111/faf.12004); the old Cloudflare stub source was deleted; the local `Pikitch_2014_ForageFishContribution.pdf` stub + `.preocr.bak` are left untouched.

- [ ] **Step 6: Verify Task 1 done**

Run: `nlm source list 63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e 2>/dev/null | grep -i pikitch`
Expected: shows `Pikitch_2012_LittleFishBigImpact_Lenfest.pdf`; the old `Pikitch_2014_ForageFishContribution.pdf` source is gone.

---

### Task 2: Scaffold the brief from the NARRATIVE_v3 23-slide spine

**Files:**
- Create: `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`
- Read: `analysis/04_talks/2026-royalsociety/Talk_Materials/NARRATIVE_v3_social-ecological-double-helix.md` (lines 126–249, the 23-slide outline), `analysis/04_talks/2026-royalsociety/Talk_Materials/SLIDE_REVISION_TODO_2026-05-19.md`, `docs/herring-non-recovery-hypotheses.md`, `docs/talk-model-claim-control-sheet.md`

- [ ] **Step 1: Read the four spine documents**

Read all four files above in full. From NARRATIVE_v3 capture each slide's one-line ecological take-home (the "Story job"). From `talk-model-claim-control-sheet.md` capture the "must hold" / "must not say" anchors verbatim.

- [ ] **Step 2: Create the brief with the fixed scaffold**

Create `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md` with exactly this skeleton (fill each `Story job:` from NARRATIVE_v3; leave evidence/gap/risk blank for later tasks; one `## Slide N` block for **all 23 slides**):

```markdown
# Talk Evidence Coverage — Royal Society herring talk (built 2026-05-19)

Read-only synthesis of the 161-source "Herring Haida Gwaii" NotebookLM
notebook against the NARRATIVE_v3 23-slide spine. Does NOT change the talk.

## ⏱ Top 5 story gaps to fix before tomorrow
*(written last — see Task 6)*

## 🔒 Claim-control anchors (must hold / must NOT say)
*(verbatim from docs/talk-model-claim-control-sheet.md — Task 2 Step 3)*

---

## Slide 1 — Title
**Story job:** <one line from NARRATIVE_v3>
**Evidence in hand:** _(bookend — see Task 6)_
**⚠️ Underused / story gap:**
**🚩 Risk flag:**

## Slide 2 — The thesis, up front
**Story job:** <one line>
**Evidence in hand:**
**⚠️ Underused / story gap:**
**🚩 Risk flag:**

<... repeat through Slide 23 — every slide from the outline ...>
```

- [ ] **Step 3: Paste the claim-control anchors**

Fill the `## 🔒 Claim-control anchors` section with the must-hold / must-not-say items copied verbatim from `docs/talk-model-claim-control-sheet.md`.

- [ ] **Step 4: Verify scaffold completeness**

Run: `grep -c '^## Slide ' analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`
Expected: `23`. Then run `grep -c 'Story job:' …/TALK_EVIDENCE_COVERAGE.md` → Expected `23`, none left as `<one line>`.

---

### Task 3: Per-beat NotebookLM evidence sweep (Slides 2–22)

**Files:**
- Modify: `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`

Slides 1 and 23 are verbatim bookends — skip here, handled in Task 6. For **each** Slide 2–22, run one targeted query using this exact template, substituting `<FOCUS>` from the table below:

> Query text: `"Using only these sources, what is the strongest evidence for: <FOCUS>? Give specific claims with exact numbers, and name the source for each. If the corpus does not support it, say so plainly."`

Per-slide `<FOCUS>` (derived from NARRATIVE_v3 take-homes):

| Slide | `<FOCUS>` |
|---|---|
| 2 | structure (not the mean) is what confers resilience; ecological vs ecosystem-service tipping points can separate |
| 3 | Pacific herring as a productive-upwelling forage-fish boom-bust archetype on this coast |
| 4 | one forage fish channels ocean energy to whales/bears/wolves and to the Haida (wasp-waist) |
| 5 | the ~10,000-yr archaeological herring baseline: ~49% of fish bones, low long-run variance; kʼaaw egg harvest as cultural keystone |
| 6 | two collapses under fishing — 1960s rebounded in ~5 yr, post-1994 has not in 30; value-regime shifts (reduction→sac-roe→SOK price collapse) |
| 7 | monitoring since 1950 and Bayesian state-space metapopulation methods; predation as audited external pressure |
| 8 | ocean productivity (cool/productive years) drove the 1960s rebound but not post-1994 recovery |
| 9 | fishing concentrated ~50–70% in coves vs ~3% archipelago-wide; aggregate indices hide cove-scale depletion |
| 10 | portfolio theory (Markowitz) applied to metapopulations; asynchronous subpopulations buffer regional variance |
| 11 | Haida Gwaii data showing each cove ran its own cycle and asynchrony held the region steady |
| 12 | post-1994 rise in spawning synchrony (~0.31→0.40) and loss of spatial diversity |
| 13 | erosion of herring productivity as the leading proximate explanation for non-recovery |
| 14 | recovery of wide-ranging predators after the end of commercial whaling |
| 15 | predator demand ≈ one-third of standing stock; synchrony + predator-pit mechanism |
| 16 | persistence below the limit reference point at near-zero catch since 2002 (P(SB<LRP)≈0.38) |
| 17 | reference points pinned to a departed baseline; ecological vs market value decoupling |
| 18 | cod-vs-herring contrast: stressor removed, cod rebounds, HG herring does not |
| 19 | cove-scale management and life-stage choice (egg/kʼaaw vs sac-roe; Okamoto; Shelton 2014) |
| 20 | recovered predator field takes ~⅓ of stock; value moved not vanished; triple-bottom-line allocation |
| 21 | co-governance: Haida Nation, DFO, BC, Parks Canada; ~40 yr nation-to-nation precedes 2024 Rebuilding Plan |
| 22 | transferable lessons: state-conditioned reference points; match management to biological scale; manage coupled tips together; spatial early-warning |

- [ ] **Step 1: Run the query for the current slide (async)**

`mcp__notebooklm-mcp__notebook_query_start` with `notebook_id="63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e"`, no `source_ids` (whole corpus), `query=` the template with this slide's `<FOCUS>`.

- [ ] **Step 2: Poll until complete**

Background `sleep 60`, then poll `mcp__notebooklm-mcp__notebook_query_status` with the `query_id`; repeat the sleep+poll until `status:"completed"`. Do not hammer (≤1 poll per ~45s).

- [ ] **Step 3: Write the evidence into the slide block**

Under that slide's `**Evidence in hand:**`, add 1–4 bullets, each:
`claim → exact number → source (NotebookLM citation/title) → safe phrasing`.
If the answer says the corpus does not support it, write: `THIN EVIDENCE — corpus offers little; <one line of what was found or not>`.

- [ ] **Step 4: Repeat Steps 1–3 for every Slide 2–22**

- [ ] **Step 5: Verify per-beat coverage**

Run: `awk '/^## Slide (2|3|4|5|6|7|8|9|1[0-9]|2[0-2]) /{s=1} /Evidence in hand:/{if(s)getline l; if(s && l !~ /[A-Za-z]/) print "EMPTY:",$0; s=0}' analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`
Expected: no `EMPTY:` lines (every Slide 2–22 has an evidence bullet or a THIN EVIDENCE note).

---

### Task 4: Corpus-wide gap sweeps

**Files:**
- Modify: `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`

Run these **4 exact queries** (whole corpus, async, same start/poll pattern as Task 3):

- [ ] **Step 1: Sweep A — critical-expert missing**

Query: `"You are a skeptical forage-fish / tipping-points expert in the audience. Based only on these sources, what important evidence, caveat, or counter-argument is this story most likely missing or glossing over? Be specific and cite sources."`

- [ ] **Step 2: Sweep B — counter-evidence to non-recovery framing**

Query: `"Using only these sources, what is the strongest evidence AGAINST the claim that Haida Gwaii herring have failed to recover and that the system has structurally changed? Cite sources."`

- [ ] **Step 3: Sweep C — orphan evidence**

Query: `"Which sources in this notebook make claims that are NOT corroborated by other sources here — unique or outlier findings worth knowing about? List source + claim."`

- [ ] **Step 4: Sweep D — what Pikitch 2012 uniquely adds**

Query: `"What does the Lenfest 'Little Fish, Big Impact' (Pikitch et al. 2012) report contribute that no other source in this notebook provides — specific numbers, recommendations, or framings? Cite it."`

- [ ] **Step 5: Distribute findings**

For each sweep result: file each finding under the most relevant slide's `**⚠️ Underused / story gap:**` line (claim → source → why it strengthens/completes that beat). Cross-cutting items that don't map to one slide go in a new `## ⚠️ Cross-cutting underused evidence` section above `## Slide 1`.

- [ ] **Step 6: Ensure every beat has a gap verdict**

For any Slide 2–22 whose `**⚠️ Underused / story gap:**` is still blank, write `Well covered — no high-value unused source found.`
Verify: `awk '/^## Slide (2|3|4|5|6|7|8|9|1[0-9]|2[0-2]) /{s=1} /Underused/{if(s)getline l; if(s && l !~ /[A-Za-z]/) print "NOVERDICT:",$0; s=0}' …/TALK_EVIDENCE_COVERAGE.md` → no `NOVERDICT:` lines.

---

### Task 5: Claim-control cross-check and risk flags

**Files:**
- Modify: `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`
- Read: `docs/talk-model-claim-control-sheet.md`

- [ ] **Step 1: Re-read the claim-control sheet**

Read `docs/talk-model-claim-control-sheet.md` fully.

- [ ] **Step 2: Audit every numeric/causal claim in the brief**

Walk every `**Evidence in hand:**` bullet. For each claim that is (a) contradicted by, (b) stronger than, or (c) outside the safe language of the claim-control sheet, append a `**🚩 Risk flag:**` entry on that slide: `<the claim> — <why risky / what the safe-language contract allows instead>`. Do **not** rewrite or soften the evidence bullet; the flag stands beside it.

- [ ] **Step 3: Verify no silent contradictions**

Produce, at the end of the file, a `## 🚩 Risk-flag register` listing every flagged claim + slide. Manually confirm every numeric claim in `Evidence in hand` has a source citation.
Verify: `grep -c '🚩 Risk flag:' …/TALK_EVIDENCE_COVERAGE.md` ≥ number of flagged claims, and the register lists them all.

---

### Task 6: Top-5 summary, bookends, finalize

**Files:**
- Modify: `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`

- [ ] **Step 1: Fill the bookend slides**

Slides 1 and 23: under `**Evidence in hand:**` write `Bookend — mirrors Slide 2 thesis; no independent evidence needed.` Add any ⚠️/🚩 only if a gap sweep flagged the framing.

- [ ] **Step 2: Write the Top 5 story gaps**

From Task 4's distributed gaps + Task 5's flags, synthesize the 5 highest-leverage things the full corpus supports that the talk is not using (or is saying riskily). Write them into `## ⏱ Top 5 story gaps to fix before tomorrow`, each as: gap → which slide → source → one-sentence fix.

- [ ] **Step 3: Final spec-criteria check**

Confirm against the spec "Done =":
```bash
F=analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md
echo "slides: $(grep -c '^## Slide ' $F) (expect 23)"
echo "thin-or-evidence beats 2-22: should be 21 covered"
echo "top5 filled: $(grep -A6 'Top 5 story gaps' $F | grep -c '^[0-9]\.')"
grep -q 'Risk-flag register' $F && echo "risk register: present"
```
Expected: slides=23, Top-5 has 5 numbered items, risk register present, no `<one line>` placeholders (`grep -c '<one line>' $F` → 0).

- [ ] **Step 4: Offer the commit**

Do not commit. Tell the user the brief is complete at `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`, summarize the Top-5, and ask if they want it (and the ACQUISITION_LOG/spec/plan) committed to git.

---

## Self-Review

**1. Spec coverage:**
- Artifact + location → Task 2. ✔
- Per-beat structure (story job/evidence/underused/risk) → Task 2 scaffold + Tasks 3–5. ✔
- Top-5 → Task 6. ✔
- Method step 1 (read spine) → Task 2 Step 1. ✔
- Method step 2 (Pikitch swap, 2012≠2014) → Task 1. ✔
- Method step 3 (per-beat + 4 gap sweeps, async) → Tasks 3 & 4. ✔
- Method step 4 (claim-control cross-check, no smoothing) → Task 5. ✔
- Success criteria (every beat grounded/thin + verdict; Top-5; no unflagged contradiction; Pikitch verified) → Task 6 Step 3 + Task 1 Step 4. ✔
- Non-goals (no edits to narrative/slides/pipeline; not a DB) → respected; brief is the only created talk file. ✔

**2. Placeholder scan:** No "TBD/TODO/handle appropriately". The only `<...>` are explicit fill-from-named-source instructions with the source given, and verification asserts none remain (`grep -c '<one line>' → 0`). OK.

**3. Type consistency:** File path `analysis/04_talks/2026-royalsociety/Talk_Materials/TALK_EVIDENCE_COVERAGE.md`, notebook id `63dbc0f0-3a56-4fc0-9a2e-3302ff949b2e`, and the `PIKITCH2012_SID` token are used identically across all tasks. Query start/poll tool names consistent. OK.
