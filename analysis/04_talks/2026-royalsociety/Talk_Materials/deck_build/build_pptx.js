// Assembles the Royal Society herring deck from ../deck_assets/*.png.
// 13.333x7.5in 16:9; each slide = one full-bleed 3840x2160 image (zero
// stretch, no live fonts — venue-PC safe). Speaker notes from the
// talk_architecture_2 "Say" beats + claim guardrails. Backup divider points
// to qa_backup_slides.md. Per deck_design_system.md.
const PptxGenJS = require('pptxgenjs');
const path = require('path');
const DA = path.join(__dirname, '..', 'deck_assets');

const p = new PptxGenJS();
p.defineLayout({ name: 'W16x9', width: 13.333, height: 7.5 });
p.layout = 'W16x9';
p.author = 'Adrian C. Stier';
p.title = 'Coupled Tipping Points in Pacific Herring & Haida Gwaii';

// [file, speaker note]
const SLIDES = [
  ['01_title.png',
   'Thank Ida. Genuine, unhurried acknowledgment: this is a partnership with the Haida Nation and named collaborators. Then state the idea before any story (the hook): when an ocean ecosystem crosses a tipping point, the services it provides do not necessarily cross with it — ecological and ecosystem-service tipping points can separate, and the gap is where management can still act. Then: "to test that idea I need to start ten thousand years ago." ~40s.'],
  ['02_shore.png',
   'Cold open — do not rush. 10,000 yrs ago the shores were quiet; each spring, not — water turning, silver bait balls offshore as herring arrive from the open ocean to spawn. What a forage fish is: small, oily, energy-dense; offshore most of its life; comes to the coast only to spawn. It pulls the whole ecosystem shoreward — bears, eagles, sea lions, seals. Transition: "and they pulled in people."'],
  ['03_people.png',
   'The Haida have harvested herring here for as long as we can measure — rakes, rowboats, following the spawn. Both adults and eggs; roe-on-branch / kʼaaw, still alive today. A cultural keystone, not just food. Your differentiator in this room. Credit the photographer + Nation on the slide. Transition: "we can put numbers on how long this lasted — and how stable."'],
  ['04_baseline.png',
   'Across 171 archaeological sites and 435,777 identified fish bones, herring is the single most common fish — ~half of everything, 99% of sites. Abundance barely moves: <±10% over ~10,700 yr. "For a room that argues about what natural variability even is — that is a ten-thousand-year measurement of it." Credibility anchor. Transition: "hold onto that — everything next is a departure."'],
  ['05_two_collapses.png',
   'The engine of the talk. Smallpox (one line). Reduction fishery 1930s; peak ~77,500 t in 1956; 1960s collapse; rebounded within ~5 yr — the forgiving recovery forage fish are known for (the control). Then the roe fishery from 1972 (commercial kills adults for roe; Haida take eggs after spawning — plant for slide 13). By 1993 ~1,000 t; closure 1994; 25 yr on, still ~10% of historic. Land it hard. Transition: "why didn’t it come back? — my group’s work for several years."'],
  ['06_climate_pdo.png',
   'We can ask because Haida and government scientists monitored for decades. Bayesian hierarchical state-space models separate climate, predation, habitat, density dependence. Ocean productivity is a first-order driver — cool, productive ocean phases raise herring growth ~15% (warm phases ~8% lower; a ~1.25× swing across the PDO). But climate is necessary, not sufficient. (Guardrail: no promoted predator coefficient for HG.) Transition: "so we looked at space."'],
  ['07_two_scales.png',
   'The conceptual hinge — slow down. The quota is set for the whole archipelago, but fish, fleet, and predators all operate at the cove scale. Archipelago exploitation looked ~4%; local cove rates reached ~65% — the average hid the extremes (Stier et al. 2020, published — not a current m1_stier_11 output). The cove is where herring spawn, the fleet seines, humpbacks feed. Lesson: match management scale to biology, extraction, predation.'],
  ['08_realized_growth.png',
   'At the cove scale, realized growth fell in nearly every spawning section — the aggregate looked survivable, the cove signal did not. Structural and system-wide, invisible at the management scale. Short, sharp. Transition: "and the coves did something else — together."'],
  ['09_synchrony.png',
   'Coves used to keep their own rhythm — booming/failing out of step (a portfolio; a rescue effect). Since the mid-1990s synchrony is up >60% — the portfolio eroded (measured; Stier 2020). Then offer the interpretation as a PROPOSAL, not a finding: rising synchrony MAY be a spatial early-warning signal; the leading-indicator analysis is not done; we are testing it. Do NOT call it a result. Transition: "why — two hypotheses; the first explains both."'],
  ['10_predators.png',
   'First hypothesis: far more mouths now — marine mammals recovered from whaling/sealing; humpback predation likely the single largest mortality source; mobile predators skimming cove to cove also synchronise. Be honest: the whale recovery is a conservation triumph AND, for herring, a tipping cascade (ties to Lenton). Second hypothesis (TEK): heavy adult harvest erased spawning-site memory. Guardrail: large pressure, NOT a promoted HG causal coefficient. Transition: "either way — the system is somewhere new."'],
  ['11_triple_bottom_line.png',
   'Growth near zero; after two decades of closure, an alternative stable state at ~10% of historic. Struck all three bottom lines on three clocks: ecosystem (predators; halibut & salmon), people (Haida kʼaaw sites where grandparents passed oral history; commercial sector lost its fishery), economy (roe value peaked 1980s, high to mid-90s, then declined — Rebuilding Plan; NOT "$40M→$2.78M"). Economic crash fast, cultural erosion slow, ecological shift between. Transition: "those tipping points did not happen together — the heart of what I want to leave you with."'],
  ['12_decoupling.png',
   'Walk the figure, point — don’t crowd. Four layers, four clocks: service ~1990, ecological 1993, economic ~2005, governance rises later. Three fall, one rises; they do not line up. The horizontal gap is the management window — the years intervention can still change the outcome. (Governance track is schematic institutional milestones, not an outcome metric — HG still below LRP.) Transition: "what does this teach about acting inside that window?"'],
  ['13_takeaways.png',
   'The destination. Three, crisply: (1) match scale to biology — finer-scale escapement is costly but preserves the portfolio; (2) manage the ecosystem, not the stock — integrate species interactions; (3) allocate across the triple bottom line via co-governance (AMB, Gwaii Haanas reserve & WHS, 2024 plan) — conservation and use not in opposition. One open thread, a proposal not a result: the early-warning signal may be spatial; if so, observation scale decides what you can see. Do not add a fourth. Transition: "let me close."'],
  ['14_close.png',
   'Slow down. Recovery is a moving target — the system has changed. The gap between an ecological tip and a service tip is the leverage point — manage that gap, at the right scale, for the whole system. What we still don’t know: how fast we can close the loop indicator→action, and whether this travels to systems without a 10,000-yr record. "The herring is the example. The lesson is about thresholds. Thank you." Stop — don’t tail into logistics.'],
];

SLIDES.forEach(([img, note]) => {
  const s = p.addSlide();
  s.background = { color: '0E0E0E' };
  s.addImage({ path: path.join(DA, img), x: 0, y: 0, w: 13.333, h: 7.5 }); // image is exactly 16:9 -> zero distortion
  s.addNotes(note);
});

// Q&A backup divider
const b = p.addSlide();
b.background = { color: '0E0E0E' };
b.addText('Q & A — backup', { x: 0.8, y: 3.0, w: 11.7, h: 1.0, fontFace: 'Georgia',
  fontSize: 40, color: 'D9714F', italic: true });
b.addText('20 audience-anchored backup cards — see analysis/04_talks/2026-royalsociety/Talk_Materials/qa_backup_slides.md (B1 predators · B5 hysteresis vs transient · B7 EWS rigor · B18 service valuation · B20 solutions). Each: question · answer line · proof object · claim-control guardrail.',
  { x: 0.8, y: 4.1, w: 11.7, h: 1.6, fontFace: 'Arial', fontSize: 16, color: 'A8A59F' });
b.addNotes('Hidden until needed. Most-likely pulls in this room: B7 (EWS rigor), B1 (predators), B5 (hysteresis vs transient), B2 (non-identifiability), B18 (service valuation — the chair), B20 (solutions). Full text + proof objects in qa_backup_slides.md.');

const out = path.join(__dirname, '..', 'Herring_RoyalSociety_Stier_2026.pptx');
p.writeFile({ fileName: out }).then(() => console.log('WROTE', out));
