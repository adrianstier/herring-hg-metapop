# Coupled Tipping Points in Pacific Herring & Haida Gwaii
### Talk production plan — slide sequence, build specs, and visual treatments
**Royal Society · Session 5 · 20 May 2026 · 9:30 am · ~20 min + Q**

*Last updated: Saturday, 16 May 2026, 2:35 PM PDT*

This is a slide plan, not a graphics list. The previous version paired every finding with a chart; a 20-minute talk cannot carry thirteen figures, and a room of senior scientists remembers three images and two phrases. So every finding here is assigned a *treatment* — and most of them are not charts.

---

## The argument in one frame

**Thesis.** Ecological tipping points and ecosystem-service tipping points are empirically separable. Services have their own breakpoints that lead, lag, or decouple from ecological state change. The gap between them is the interval in which management still has leverage.

**Three layers.** Ecological state → biophysical service delivery → economic and social value. Each layer tips on its own schedule. Hysteresis is the mechanism that makes the gaps consequential: a recovered ecological state does not retrace its path back up through the service and value layers.

**Three structural predictions** *(reconstructed from the separability thesis — confirm wording against the finalized abstract):*

1. **Separability** — service-delivery breakpoints are not coincident with ecological-state breakpoints; they lead, lag, or decouple.
2. **Hysteresis** — recovery of ecological state does not restore service delivery along the collapse path; service recovery lags and may not occur on management-relevant timescales.
3. **Management window** — the temporal offset between layer breakpoints is a measurable interval; the herring case shows the system after that window has closed.

---

## Five treatments

Every slide gets exactly one. The discipline is in refusing to make everything a chart.

| Tag | Treatment | When to use it |
|-----|-----------|----------------|
| **SPINE** | The recurring three-layer animation | The backbone — returned to 3–4× across the talk, advancing one layer each time |
| **BUILD** | Interactive / animated graphic, click- or drag-driven | When the *motion* is the finding (convergence, crossover, irreversibility) |
| **CHART** | Static built figure, one idea, minimal ink | When the *number* is the finding and motion adds nothing |
| **PHOTO** | A photograph | When the thing itself is more eloquent than any plot of it |
| **TEXT** | Typography on a near-empty slide | When a name, a prediction, or a contrast carries more than an image would |

**Rhythm rule.** Plan heavy–light–heavy. Never two BUILDs back to back; a PHOTO or TEXT slide has to breathe between hero moments.

---

## Slide sequence

| # | Working title | Treatment | Weight | Core content |
|---|---------------|-----------|--------|--------------|
| 1 | Title | TEXT | – | Coupled tipping points in Pacific herring & Haida Gwaii |
| 2 | The argument | SPINE (intro) | H | Three empty layers + thesis line; predictions stated |
| 3 | Ten thousand years | PHOTO | L | White-water spawn; the baseline |
| 4 | The clean tipping point | CHART | L | 1967 coastwide reduction collapse |
| 5 | The portfolio comes apart | BUILD #3 | H | Animated subpopulation convergence |
| 6 | What drove it | CHART | L | Causal chain: predator recovery, not climate |
| 7 | A bigger mouth than the fishery | BUILD #4 | H | Mortality-source crossover, year scrubber |
| 8 | The value peaked while the system fell | SPINE + CHART | H | Biomass vs. landed value — the keystone |
| 9 | Ten thousand years / now | PHOTO + TEXT | L | The named *k'aaw* bays; cultural threshold |
| 10 | It does not come back | BUILD #2 | H | Draggable hysteresis phase portrait |
| 11 | Two systems, same data | TEXT | L | Divided mental models |
| 12 | Co-governance | PHOTO | L | The AMB / Athlii Gwaii / 2024 signing |
| 13 | The negative control | CHART | L | Strait of Georgia counterfactual |
| 14 | Zero, and still below the line | CHART | H | 2025 forecast vs. LRP — the close |
| 15 | The window has closed | SPINE (final) | H | All layers tipped; window shaded shut |
| — | *Egg vs. adult harvest* | CHART | – | **Backup** — deploy only if time, as the economics bridge |

Fifteen content slides, six heavy. The SPINE recurs at 2 / 8 / 15. No two BUILDs are adjacent.

---

## The four dynamic builds

These are the talk. Built in this environment, in the timeline artifact's visual language (see Design System). All are **event-driven, not auto-playing** — they advance on click so the motion tracks your speech.

### BUILD #1 — The three-layer spine *(slides 2, 8, 15)*

The backbone. One shared time axis, 1950→present. Three trajectories drawn in sequence across the talk:

- **Slide 2** — axis and three empty layer tracks appear. Nothing moves yet. You state the thesis against blank scaffolding.
- **Slide 8** — the ecological curve (already drawn by this point via Build #3) is joined by the value curve, which *rises to a 1993 peak, then collapses a decade later.* The horizontal gap between the two breakpoints shades in: the management window, measured.
- **Slide 15** — the cultural curve completes the set: flat across the entire baseline, then a late drop. All three breakpoints now visible at different x-positions. The window shades shut.

The whole figure is one SVG with a step index; each return advances the index. **Wire in:** the synchrony series (Stier 2020) for the ecological track, coastwide landed value 1985–2010 for the value track, a schematic cultural track anchored to the ~2022 closure.

### BUILD #2 — Hysteresis, made draggable *(slide 10)*

The most important interaction in the deck. Hysteresis is undersold whenever it is merely *stated*. Make it tactile.

A phase portrait: x-axis a driver (predation pressure / cumulative mortality), y-axis system state, with the classic folded curve — an upper stable branch, a lower stable branch, an unstable middle. A draggable handle sets the driver; a dot shows system state.

- Drag the driver **right** — the dot rides the upper branch, then falls off the fold to the lower branch. Collapse.
- Drag the driver **back left** — the dot **does not retrace.** It stays on the lower branch well past the point where it fell.

The audience does not get told irreversibility; they fail to undo it with their own hand. End with the dot stuck and a caption: *the driver is back where it started. The system is not.* This can live inside the Build #1 artifact as the mechanism layer.

### BUILD #3 — The portfolio comes apart *(slide 5)*

Do not show Stier 2020 as a finished plot. Animate it.

Nine subpopulation biomass lines start visibly **fanned** in the early decades — independent trajectories. On click, time runs forward: post-1994 the lines **braid into a single strand.** A second element — the asynchrony index, 1→0 — ticks down a counter as the lines merge. The convergence *is* the tipping point; let people watch the structure dissolve rather than reading that it did.

**Wire in:** the nine focal subpopulation series and the asynchrony index, 65-year span. Key annotations on reveal: *2.1× more stable than a homogeneous metapopulation* (the lost portfolio effect); *local harvest 65% while the archipelago-wide rate was 4%* (what aggregate management hid).

### BUILD #4 — A bigger mouth than the fishery *(slide 7)*

A year scrubber, 1970→2025. The viewer (or you) drags it; a stacked composition of herring mortality by source updates live. Early on the commercial-fishery band dominates. As the scrubber advances, the humpback-predation band grows and **overtakes it.** Park the handle on the crossover year and hold.

**Wire in:** Doherty 2025 bioenergetics — humpbacks now ≈62% of all herring predation mortality, exceeding the historical fishery; BC humpback abundance 2,145 (2006) → 4,833 (2022); southern Haida Gwaii natural mortality roughly doubled since 1973. The crossover reframes the policy problem: closing the fishery no longer controls the dominant mortality term.

---

## The charts *(static, one idea each, minimal ink)*

**Slide 4 — the 1967 collapse.** Coastwide catch, 1935–1972: the climb to ~240,000 t, the three-season fall (241k→181k→135k), the shaded 1968–71 closure. One callout naming the four leading indicators that were present and ignored — spatial contraction, rising search effort, reduced spawn, truncated age structure. A setup slide; keep it quiet.

**Slide 6 — what drove it.** A five-node causal chain: *humpback recovery → mobile, spatially coupled predation → loss of asynchrony → portfolio collapse.* Show climate forcing and larval dispersal as struck-through branches — Stier 2020 explicitly rejected them. A transition slide, not a model figure.

**Slide 8 — biomass vs. value (the keystone, fused with the SPINE).** Dual-axis, 1985–2010: ecological state left, landed value right. The value curve *peaks at the 1993 ~$40M high while the metapopulation is already failing,* then collapses ~93% by 2006. The horizontal offset between the two breakpoints is Prediction 1 made visible. Slide line: *the aggregate landed value is the last thing to fall.*

**Slide 13 — the Strait of Georgia counterfactual.** A two-column comparison panel, Haida Gwaii vs. SoG, matched rows: stock status, current biomass (~100,000+ t at SoG), residency vs. migration, predation structure, fishery history. Rows aligned so the eye reads the difference. This is the negative control — it immunizes the talk against "you just picked a collapsed stock."

**Slide 14 — zero, and still below the line.** The 2025 forecast as a probability distribution with the LRP as a vertical rule and the 37.8%-below-LRP mass shaded — *even with no fishing.* A second small panel: several management procedures, including "no fishing," as overlapping distributions, none clearing the LRP cleanly. The visual close: once the service threshold is crossed, the fishery is no longer the lever.

**Backup — egg vs. adult harvest asymmetry.** A two-axis operating-space diagram, egg harvest against adult harvest, depletion contour across it, with "fishery target space" and "predator-protective space" overlapping rather than conflicting (Shelton et al. 2014). Deploy only if pacing allows — it is the cleanest bridge to Kubiszewski's ecological-economics frame.

---

## The photo slides

This is the "not a graph" half of the talk. Source real imagery; placeholders will not survive this room.

**Slide 3 — ten thousand years.** Open on **white water** — spawn turning a bay milky turquoise. Most of the audience has never seen it. Under or after it, the deep-time evidence: fish bones in fine-screen archaeological stratigraphy, the cedar herring rake. Numbers spoken, not plotted — McKechnie et al. 2014: 435,777 bones, 171 sites, herring 49% of all bones, 99% ubiquity, temporal variance under ±10% across the record. The flatness is the point, and a photograph plus a sentence delivers it harder than a ribbon chart.

**Slide 9 — the named bays.** The cultural-service threshold is not a stock metric; show the places. Photographs of Burnaby Narrows, Skidegate Inlet, Louscoone — paired with the roll call of closed *k'aaw* sites as TEXT (see below). A map with colored dots is the weaker option; the bays themselves are not.

**Slide 12 — co-governance.** Kill the org chart. Governance is people: the AMB table, the Athlii Gwaii blockade on Lyell Island, the 2024 *iináang | iinang* rebuilding-plan signing. One line of text — six seats, three federal and three Haida, consensus not majority, first ecosystem-based rebuilding plan in BC. The photograph carries the institution.

---

## The text slides

**Slide 1 — title.** Set in the timeline's masthead language.

**Slide 9 (paired with the photo) — the roll call.** The closed sites read as liturgy: *Burnaby Narrows · Skidegate Inlet · Louscoone Inlet · Cumshewa · Selwyn · Rennell Sound · Hunter Point · Marble Island · Scudder Point · Juan Perez · Skincuttle.* Then one line: *functionally closed for traditional harvest for the first time in approximately ten thousand years.* If you keep one TEK datum, keep the place name *Teeshoshum* — "waters white with herring spawn," a site with no documented spawning since 1998. A name on a near-black slide does what the 7.6%-per-decade contraction curve cannot. (That curve, Gerrard 2014, is backup only.)

**Slide 11 — two systems, same data.** Stier et al. 2016: 27 regional experts, two structurally distinct mental models of the herring food web, and the clustering is *unrelated* to background, experience, or affiliation. Under a simulated recovery the two clusters diverge by 182% / 78% / 89% on reorganization, abundance change, and whale increase — and disagree on the *direction* of response for pink and chum salmon. Treat this as text plus, at most, two small contrasting network glyphs. The finding is that the disagreement is structural, not noise — and that lands as a sentence.

---

## Design system — use the one you already have

The timeline artifact is a finished design language: Crimson Pro / IBM Plex type, the rust-and-marine palette, the editorial masthead. Build every talk graphic inside it. The deck, the timeline, and the spine should read as one object — do not let the slides drift into generic LTER scientific-figure styling.

Concretely: shared SVG conventions, the same six-domain color coding (climate, fishery, ecology, culture, governance, science) carried from the timeline into the spine and builds, event-driven JavaScript for every animation, and ruthless ink restraint — a talk is not a paper.

---

## What got cut, and why

- **The governance org chart** — replaced with photographs. An institutional flow diagram is the least engaging object available; the people are the institution.
- **The TEK contraction curve** — demoted to backup. The place name out-performs the regression.
- **Egg/adult asymmetry** — moved to backup. Strong finding, but the main line is full; it returns only as the economics bridge if pacing allows.
- **Per-finding charts generally** — thirteen figures became five charts plus four builds. The cuts are the improvement.

---

## Closing positioning

The herring case is the empirical spine. Two comparative systems sharpen it without competing for airtime:

- **Moorea (MCR LTER)** — the COVID natural experiment: tourism collapse, fishing-pressure spike, reef-fish biomass holding, with real livelihood data. Use it as *one slide* — a fast, clean test of the management-window concept — not a second case study.
- **Kelp forests (SBC LTER)** — the fast-turnover counterfactual. Kelp recovers on a timescale herring and reefs do not, which is exactly its value: it demonstrates the *mechanism* of the framework. Frame it as the control, not a competing collapse.

For Session 5 specifically: slide 8 and the egg/adult backup are the bridge to Kubiszewski's ecological-economics frame. Dropping kelp as a primary system keeps clear water between this talk and White's and Smale's.
