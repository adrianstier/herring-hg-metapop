// NATIVE PowerPoint deck — image-rendered figures + native conceptual slides.
// Cleaned 2026-05-18: removed duplicate masthead/title overlays on figure slides
// (S5–S10 carry their own baked-in chrome), fixed title wrapping on S11/S13,
// added top scrim to S1, made S4 caption full width, moved the DFO corroboration
// slide into the backup section after S14 (per the 14-slide canonical outline).
const PptxGenJS = require('pptxgenjs');
const path = require('path'), fs = require('fs');
const DA = path.join(__dirname, '..', 'deck_assets');     // R-fig PNGs (16:9)
const PH = path.join(__dirname, 'photos');                  // photos

const C = { dark:'0E0E0E', light:'FBFAF7', ink:'F0EEE9', inkD:'1C1916',
  soft:'A8A59F', softD:'6F6860', rust:'D9714F', marine:'6E9BC4',
  kelp:'8AA074', plum:'B685A8', amber:'CFA055', rule:'2E2C28' };
const HEAD='Georgia', BODY='Calibri', MONO='Consolas';
const W=13.333, H=7.5;

const p = new PptxGenJS();
p.defineLayout({ name:'W', width:W, height:H }); p.layout='W';
p.author='Adrian C. Stier';
p.title='Coupled Tipping Points in Pacific Herring & Haida Gwaii';

function base(dark){ const s=p.addSlide(); s.background={color: dark?C.dark:C.light}; return s; }
function masthead(s,dark){ s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
  {x:0.5,y:0.32,w:9,h:0.3,fontFace:MONO,fontSize:11,color:C.rust,charSpacing:3}); }
function title(s,txt,dark){ s.addText(txt,{x:0.5,y:0.7,w:12.3,h:1.0,fontFace:HEAD,
  fontSize:34,bold:true,color:dark?C.ink:C.inkD}); }
function takeaway(s,txt,dark){ s.addShape(p.ShapeType.rect,{x:0.5,y:6.35,w:0.06,h:0.62,fill:{color:C.amber}});
  s.addText(txt,{x:0.7,y:6.3,w:12.1,h:0.72,fontFace:HEAD,fontSize:18,italic:true,
  color:dark?C.ink:C.inkD,valign:'middle'}); }
function caption(s,txt,dark){ s.addText(txt,{x:0.5,y:7.05,w:12.3,h:0.4,fontFace:MONO,
  fontSize:9,color:dark?C.soft:C.softD}); }
// Full-bleed image — assumes 16:9 source so no distortion.
function fullbleed(s,file){ s.addImage({path:file,x:0,y:0,w:W,h:H}); }
// cover-fill a photo into the whole slide (crop ok for photos)
function photo(s,file){ s.addImage({path:file,x:0,y:0,w:W,h:H,sizing:{type:'cover',w:W,h:H}}); }

/* S1 — Title */ {
  const s=base(true); photo(s,path.join(PH,'s01_title.png'));
  // thin top scrim sized for the masthead only (not a fat band)
  s.addShape(p.ShapeType.rect,{x:0,y:0,w:W,h:0.78,fill:{color:'0E0E0E',transparency:30}});
  // bottom scrim for title block
  s.addShape(p.ShapeType.rect,{x:0,y:4.35,w:W,h:3.15,fill:{color:'0E0E0E',transparency:22}});
  // larger, brighter masthead on the title slide
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.6,y:0.28,w:12.2,h:0.34,fontFace:MONO,fontSize:13,color:C.rust,charSpacing:3});
  // Title broken three ways so "Pacific Herring" stands alone on its own line
  s.addText('Coupled Tipping Points in',
    {x:0.6,y:4.05,w:12,h:0.65,fontFace:HEAD,fontSize:36,bold:true,color:C.ink});
  s.addText('Pacific Herring',
    {x:0.6,y:4.6,w:12,h:0.85,fontFace:HEAD,fontSize:48,bold:true,italic:true,color:C.rust});
  s.addText('& Haida Gwaii',
    {x:0.6,y:5.4,w:12,h:0.7,fontFace:HEAD,fontSize:38,bold:true,color:C.ink});
  s.addText('Ecological vs. ecosystem-service tipping points — the gap is where management acts.',
    {x:0.6,y:6.25,w:12,h:0.5,fontFace:HEAD,fontSize:17,italic:true,color:'E8E3DA'});
  s.addText('Adrian Stier · UC Santa Barbara · US–UK Forum · Session 5 · 20 May 2026',
    {x:0.6,y:6.95,w:12,h:0.35,fontFace:MONO,fontSize:12,color:'D4CDC0'});
  s.addNotes('Thank Ida. Genuine Haida-partnership acknowledgment. State the idea before any story (the hook): ecological vs ecosystem-service tipping points can separate; the gap is where management acts. Then: "to test that idea I start ten thousand years ago." ~40s.');
}

/* S2 — The shore comes alive */ {
  const s=base(true);
  s.addMedia({ type:'video', path:path.join(PH,'s02_shore.mp4'),
    cover:'data:image/jpeg;base64,'+fs.readFileSync(path.join(PH,'s02_shore.jpg')).toString('base64'),
    x:0, y:0, w:W, h:H });
  // thin top scrim + masthead for consistency across the deck
  s.addShape(p.ShapeType.rect,{x:0,y:0,w:W,h:0.78,fill:{color:'0E0E0E',transparency:30}});
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.6,y:0.28,w:12.2,h:0.34,fontFace:MONO,fontSize:13,color:C.rust,charSpacing:3});
  // bottom scrim for the date tag — make it a statement, not a caption
  s.addShape(p.ShapeType.rect,{x:0,y:6.05,w:7.2,h:1.45,fill:{color:'0E0E0E',transparency:25}});
  s.addText([{text:'~10,000 ',options:{color:C.amber}},
    {text:'years ago',options:{italic:true,color:'E8E3DA'}}],
    {x:0.6,y:6.25,w:8,h:0.8,fontFace:HEAD,fontSize:36,bold:true});
  s.addText('Pacific herring spawn aggregation, Haida Gwaii',
    {x:0.6,y:7.05,w:9,h:0.35,fontFace:MONO,fontSize:11,color:'BDB6AB',italic:true});
  s.addNotes('Cold open — do not rush. Quiet shores, then each spring the water turns — silver bait balls offshore. What a forage fish is. It pulls the ecosystem shoreward. Transition: "and they pulled in people."');
}

/* S3 — The people and the fish (PAIRED: harvest + roe macro — locked decision) */ {
  const s=base(true);
  // paired side-by-side, each photo cover-cropped into its half (cropping a
  // photo is allowed; no distortion — addresses #2/#3)
  s.addImage({ path:path.join(PH,'s03_harvest.jpg'),     x:0,   y:0, w:W/2, h:H, sizing:{type:'cover', w:W/2, h:H} });
  s.addImage({ path:path.join(PH,'s03_roe_closeup.jpg'), x:W/2, y:0, w:W/2, h:H, sizing:{type:'cover', w:W/2, h:H} });
  s.addShape(p.ShapeType.rect,{x:W/2-0.012,y:0,w:0.024,h:H,fill:{color:'0E0E0E',transparency:18}});
  // dark scrim band so the rust masthead actually reads against the bright sky/forest
  s.addShape(p.ShapeType.rect,{x:0,y:0,w:W,h:0.78,fill:{color:'0E0E0E',transparency:8}});
  s.addShape(p.ShapeType.rect,{x:0,y:5.0,w:W,h:2.5,fill:{color:'0E0E0E',transparency:22}});
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.6,y:0.28,w:12.2,h:0.34,fontFace:MONO,fontSize:13,color:C.rust,charSpacing:3});
  // title with parallel italic accent
  s.addText([{text:'The people, ',options:{}},
    {text:'the fish',options:{italic:true,color:C.rust}}],
    {x:0.6,y:5.4,w:11,h:0.9,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('Haida kʼaaw — roe-on-branch, a cultural keystone for 10,000+ years',
    {x:0.6,y:6.3,w:11,h:0.5,fontFace:HEAD,fontSize:18,italic:true,color:'D9D4CC'});
  s.addText('Left: A. Salomon · used with permission · Council of the Haida Nation     ·     Right: A. Stier (roe on kelp)',
    {x:0.6,y:6.95,w:12.2,h:0.35,fontFace:MONO,fontSize:10,color:'BDB6AB'});
  s.addNotes('Haida harvest for as long as we can measure — adults and eggs; kʼaaw still alive today. A cultural keystone — your differentiator. Credit on slide. Transition: "we can put numbers on how long this lasted."');
}

/* S3.5 — Herring: the wasp-waist of the system (NEW slide; #4).
   Native dark slide mirroring S11 chrome. Asset is a square, light-bg diagram
   so it reads as a clean card on the dark slide; the Oceana / Seattle-Times
   credit is baked into the figure (kept visible — Adrian cleared on-slide use,
   no rights blocker per board 2026-05-19). */ {
  const s=base(true); masthead(s,true);
  s.addText([{text:'Herring — the ',options:{}},
    {text:'wasp-waist',options:{italic:true,color:C.rust}},
    {text:' of the system',options:{}}],
    {x:0.5,y:0.62,w:12.3,h:0.72,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  // square diagram, centered; sized to clear title above and the two text lines below
  { const h=4.95,w=h,x=(W-w)/2;
    s.addImage({path:path.join(PH,'s03b_foodweb_oceana.png'),x,y:1.42,w,h}); }
  s.addText('One forage fish is the single channel from ocean productivity up to the fishery, marine mammals, seabirds — and people. Change the waist and everything above it changes.',
    {x:0.7,y:6.48,w:11.9,h:0.52,fontFace:HEAD,fontSize:15,italic:true,color:'D9D4CC',align:'center'});
  s.addText('Diagram: Oceana / M. Nowlin, The Seattle Times — credit retained on figure.',
    {x:0.5,y:7.06,w:12.3,h:0.32,fontFace:MONO,fontSize:9,color:C.soft,align:'center'});
  s.addNotes('Set this up explicitly for non-experts — it underpins S10 (predators) and the close (S14). Plankton in; herring is the pinch-point; salmon, halibut, humpbacks, sea lions, seabirds, the seine fleet and Haida kʼaaw all hang off that one waist. Change the waist and everything above it changes. Diagram credit retained on-figure (Oceana / M. Nowlin, The Seattle Times) — Adrian cleared on-slide use, no rights blocker.');
}

/* S4 — The baseline, measured */ {
  const s=base(false); masthead(s,false);
  title(s,[{text:'The baseline, '},{text:'measured',options:{italic:true,color:C.rust}}],false);
  // #5: cut 5 stats → 3 (dropped 435,777-bones + 99%-ubiquity). Bigger
  // numerals, one roomy column — no cramped 2.5in box.
  const stats=[['171','archaeological sites — BC coast & Haida Gwaii'],
    ['49%','of all fish bones — herring'],
    ['<±10%','variance across ~10,700 years']];
  stats.forEach((v,i)=>{ const y=2.15+i*1.45;
    s.addText(v[0],{x:0.5,y,w:2.6,h:0.95,fontFace:HEAD,fontSize:44,bold:true,color:C.rust,valign:'middle'});
    s.addText(v[1],{x:3.2,y,w:3.9,h:0.95,fontFace:BODY,fontSize:18,color:C.softD,valign:'middle'}); });
  // #6: swap bones chart → McKechnie Fig-1 dual site-map panel (2380×2160)
  { const w=5.07, h=w*(2160/2380); s.addImage({path:path.join(PH,'s04_mckechnie_map_crop.png'),
    x:7.4,y:1.6,w,h}); }
  takeaway(s,'A ten-thousand-year measurement of natural variability. Everything next is a departure from it.',false);
  // caption: wider, smaller, keep inside slide
  s.addText('Map & data: McKechnie et al. 2014, PNAS — ▲ archaeological sites, red = herring spawn. (Mongabay photo dropped with the bones chart.)',
    {x:0.5,y:7.05,w:12.3,h:0.4,fontFace:MONO,fontSize:9,color:C.softD});
  s.addNotes('Credibility anchor: a ten-thousand-year measurement of natural variability. State numbers cleanly. Transition: "hold onto that — everything next is a departure."');
}

/* S5–S10 — image-rendered figure slides. Each PNG already carries its own
   masthead + title (S5/S7 by design, S6/S8/S9/S10 baked-in by preprocess_figures.py),
   so we DO NOT overlay native chrome on top — that is what was causing every
   text-on-axis collision in the prior build. */

/* S5 — Two collapses */ {
  const s=base(true); fullbleed(s,path.join(DA,'05_two_collapses.png'));
  s.addNotes('The engine of the talk — REAL spawn-index data. Reduction fishery 1930s; 1960s collapse rebounded ~5 yr (the control). Roe fishery 1972; closed 1994; still ~10% of historic, has not recovered. Land the contrast: one came back, one did not.');
}

/* S6 — climate / PDO */ {
  const s=base(true); fullbleed(s,path.join(DA,'06_climate_pdo.png'));
  s.addNotes('Bayesian state-space models separate drivers. Ocean productivity is a first-order driver — cool, productive PDO phases raise herring growth ~15%, warm phases ~8% lower: a ~1.25× swing across the observed PDO range (the real model number — not a 3× claim). Necessary, not sufficient: it does not explain non-recovery. Guardrail: no promoted predator coefficient for HG (claim-control sheet). Transition: "so we looked at space."');
}

/* S7 — The two scales */ {
  const s=base(true); fullbleed(s,path.join(DA,'07_two_scales.png'));
  s.addNotes('The conceptual hinge — slow down. Same fishery, two scales: managed at ~3% archipelago-wide (looked sustainable, under the 20% rule in all but one year), but fished coves were pushed to ~50% (upper CI ~70%) — the 20% HCR was exceeded 22 of 75 years at the cove scale, only once archipelago-wide. The average hid the extremes; the cove is where herring spawn, the fleet seines, humpbacks feed. Benchmark provenance: DFO "cut-off + 20% harvest-rate" HCR for Major SARs, in force ~1983–2017 (Minor SAR coves dropped to 10% after 1994; policy reviewed 2017; DFO 2020 / HG Rebuilding Plan 2024). Figure provenance: updated Stier et al. 2020 method, catch matrix extended to 2025 — scale-mismatch / serial-depletion result, NOT an m1_stier_11 output (numbers_provenance.md / claim-control sheet).');
}

/* S8 — realized growth */ {
  const s=base(true); fullbleed(s,path.join(DA,'08_realized_growth.png'));
  s.addNotes('At the cove scale realized growth fell in nearly every section — the aggregate looked survivable, the cove signal did not. Structural, system-wide, invisible at the management scale.');
}

/* S9 — synchrony / portfolio */ {
  const s=base(true); fullbleed(s,path.join(DA,'09_synchrony.png'));
  s.addNotes('Coves used to keep their own rhythm — a portfolio. Synchrony up >60% since the mid-1990s (Stier 2020, measured). Then offer the EWS reading as a PROPOSAL, not a finding — the leading-indicator analysis is not done.');
}

/* S9b — async→sync portfolio ANIMATION (video slide, after S9) */ {
  const s=base(true);
  s.addMedia({ type:'video', path:path.join(DA,'sim_anim_v2.mp4'),
    cover:'data:image/jpeg;base64,'+fs.readFileSync(path.join(DA,'sim_anim_v2_poster.jpg')).toString('base64'),
    x:0, y:0, w:W, h:H });
  s.addNotes('Animation (restyle of the 2020 Ecosphere sim_anim): subpopulations wander asynchronously and buffer the portfolio, then after the 1994 roe-fishery closure they synchronize and the buffering collapses. Illustrative simulation CALIBRATED to Haida Gwaii — 11 subpopulations, synchrony tuned to the real S9 metric (0.31→0.40). It demonstrates the mechanism behind S9; it is not the observed series. If the venue PC will not play the embedded MP4, skip to S10 (S9 already carries the measured result).');
}

/* S10 — predators */ {
  const s=base(true); fullbleed(s,path.join(DA,'10_predators.png'));
  s.addNotes('Marine mammals recovered; humpback predation likely the largest mortality source; mobile predators also synchronise. Panel A: HG herring eaten by predator group 1910–2024 (mammals the hero band). Panel B: predator demand as % of HG spawn, 2015–24 ≈239%. Honest: a conservation triumph AND a tipping cascade (ties to Lenton). TEK 2nd hypothesis. Guardrail (baked in figure caption): predator demand is a LARGE ecological pressure, NOT a promoted/fitted m1_stier_11 coefficient (claim-control sheet).');
}

/* S11 — A system in a new state (native; title split to two clean lines) */ {
  const s=base(true); masthead(s,true);
  s.addText('A system in a new state',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('the triple bottom line, hit',
    {x:0.5,y:1.25,w:12.3,h:0.6,fontFace:HEAD,fontSize:28,italic:true,color:C.rust});
  // tighter top → body gap (was wasting ~120px of vertical space)
  // chip strings — parallel structure ("~YEAR · two-word phrase"), tight enough to fit one line
  // #19/#20: rewritten to the NEW-STATE thesis. Every on-slide number is
  // primary-source-grounded (Rebuilding Plan 2024 §5.2.3, DFO fish slips —
  // see S8_landed_value_provenance.md). NO unsourced "$40M→$2.78M".
  const col=[['Ecosystem',C.kelp,
      'Predator-dominated. Marine mammals recovered; predator demand ≈239% of HG annual spawn (2015–24). The spatial portfolio eroded — synchrony up since the mid-1990s.',
      '~1993 · the structural shift'],
    ['People',C.plum,
      'Access lost on both sides. Haida kʼaaw fell below the abundance it needs for the first time in ~10,000 yr; the last commercial HG roe fishery was 2002 — the commercial sector lost its fishery.',
      '~1990 · the slow erosion'],
    ['Economy',C.rust,
      [{text:'The roe '},{text:'market',options:{italic:true}},
       {text:' collapsed, not just the stock. BC roe-herring landed value peaked in the 1980s, high to the mid-1990s, then declined. Spawn-on-kelp price: '},
       {text:'$62.88/lb (1995)',options:{bold:true}},{text:' → '},
       {text:'$11–14/lb',options:{bold:true}},{text:' now.'}],
      '~2005 · the fast crash']];
  col.forEach((c,i)=>{ const x=0.5+i*4.2;
    s.addShape(p.ShapeType.rect,{x,y:2.05,w:3.95,h:0.05,fill:{color:c[1]}});
    s.addText(c[0].toUpperCase(),{x,y:2.18,w:3.95,h:0.35,fontFace:MONO,fontSize:14,color:c[1],charSpacing:2});
    s.addText(c[2],{x,y:2.65,w:3.95,h:2.7,fontFace:BODY,fontSize:15,color:C.ink,lineSpacing:22});
    // chip cue: serif italic instead of mono — cleaner kerning in any renderer
    s.addText(c[3],{x,y:5.45,w:3.95,h:0.45,fontFace:HEAD,fontSize:15,italic:true,color:c[1],bold:true}); });
  takeaway(s,'Herring is now worth more as forage and as kʼaaw than as roe for export — the value moved, it didn’t vanish.',true);
  caption(s,'~10% of historic / alternative stable state = current m1_stier_11 + DFO SR 2025/005. Roe value/price = 2024 HG Herring Rebuilding Plan §5.2.3 (DFO fish slips).',true);
  s.addNotes('A genuinely new state across all three bottom lines. ECOSYSTEM: predator-dominated, portfolio eroded (synchrony up since the mid-1990s; predator demand ≈239% of HG spawn 2015–24 — a pressure, not a fitted m1_stier_11 coefficient). PEOPLE: kʼaaw below the abundance it needs for the first time in ~10,000 yr; commercial sector lost its fishery (last HG roe fishery 2002 — Rebuilding Plan §5.2.3.5.2). ECONOMY: the roe MARKET collapsed, not just the stock — BC roe-herring landed value peaked in the 1980s, stayed high to the mid-1990s, then declined (1995–2005 and again post-2008; modest 2016–18 uptick); spawn-on-kelp real price peaked $62.88/lb in 1995 and is $11–14/lb recently (Rebuilding Plan §5.2.3.4.3, DFO fish slips). WHY the roe price fell (sourced, NOTES only — keep off-slide): the BC sac-roe fishery was built almost entirely for the Japanese kazunoko (herring-roe) market; Japanese demand and prices fell sharply from the early-1990s peak (changing consumption + oversupply), and HG stock decline plus the closures removed supply — so price AND fishery contracted together (Rebuilding Plan §5.2.3.5.2 narrative; price/value series = Figs 31/32, DFO fish slips). Commercial demand still exists but the price point is structurally lower. On-slide claims = the Rebuilding-Plan price/value trajectory only. Decoupling timing lives in the chips: cultural ~1990 (slow), ecological ~1993 (structural), economic ~2005 (fast).');
}

/* S12 — Recovery is a moving target (#21: native two-state slide replacing
   the confusing 12_decoupling.png four-clocks; mirrors S11/S13 chrome) */ {
  const s=base(true); masthead(s,true);
  s.addText('Recovery is a moving target',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('the reference point moved',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  const cW=5.45, cH=3.7, cY=2.15, oX=0.7, nX=oX+cW+1.0;
  // --- OLD reference point card (faded; unreachable) ---
  s.addShape(p.ShapeType.rect,{x:oX,y:cY,w:cW,h:cH,fill:{color:'151311'},line:{color:C.rule,width:1}});
  s.addShape(p.ShapeType.rect,{x:oX,y:cY,w:cW,h:0.05,fill:{color:C.soft}});
  s.addText('OLD REFERENCE POINT',{x:oX+0.25,y:cY+0.2,w:cW-0.5,h:0.35,fontFace:MONO,fontSize:14,color:C.soft,charSpacing:2});
  s.addText('The pre-1990 baseline — a system stable for ~10,000 years. The level we once called recovered.',
    {x:oX+0.25,y:cY+0.65,w:cW-0.5,h:1.45,fontFace:BODY,fontSize:16,color:C.soft,lineSpacing:22});
  s.addText('✕',{x:oX,y:cY+2.05,w:cW,h:1.0,fontFace:HEAD,fontSize:80,bold:true,color:C.softD,align:'center',valign:'middle'});
  s.addText('unreachable',{x:oX+0.25,y:cY+3.15,w:cW-0.5,h:0.4,fontFace:HEAD,fontSize:14,italic:true,color:C.softD,align:'center'});
  // --- arrow ---
  s.addText('→',{x:oX+cW,y:cY+cH/2-0.45,w:1.0,h:0.9,fontFace:HEAD,fontSize:44,bold:true,color:C.rust,align:'center',valign:'middle'});
  // --- NEW equilibrium card (active) ---
  s.addShape(p.ShapeType.rect,{x:nX,y:cY,w:cW,h:cH,fill:{color:'1C1916'},line:{color:C.rust,width:1}});
  s.addShape(p.ShapeType.rect,{x:nX,y:cY,w:cW,h:0.05,fill:{color:C.rust}});
  s.addText('NEW EQUILIBRIUM',{x:nX+0.25,y:cY+0.2,w:cW-0.5,h:0.35,fontFace:MONO,fontSize:14,color:C.rust,charSpacing:2});
  s.addText('~10% of historic. Predator-dominated, spatially synchronised. DFO at the Limit Reference Point — ~0-t Haida Gwaii catch since 2002.',
    {x:nX+0.25,y:cY+0.65,w:cW-0.5,h:1.9,fontFace:BODY,fontSize:16,color:C.ink,lineSpacing:22});
  s.addText('a different system — judge resilience against THIS state',
    {x:nX+0.25,y:cY+cH-0.95,w:cW-0.5,h:0.8,fontFace:HEAD,fontSize:15,italic:true,color:C.rust,valign:'middle'});
  takeaway(s,'Define recovery against the system we have, not the one we lost — and it means different things for harvest, culture, ecology, and economy.',true);
  caption(s,'~10% of historic / alternative stable state = current m1_stier_11 + DFO SR 2025/005. Co-governance is an institutional milestone, not an outcome metric.',true);
  s.addNotes('The historical reference point — the pre-collapse, ~10,000-year baseline — is unreachable. The system settled into a new, lower equilibrium: ~10% of historic, predator-dominated, synchronised, DFO at the LRP with ~0-t HG catch since 2002. So resilience must be judged against the NEW state, and what "recovery" means differs for harvest, culture, ecology, and economy. Claim guard: ~10% / alternative stable state cites m1_stier_11 + DFO SR 2025/005; co-governance is an institutional milestone, not an outcome metric.');
}

/* S13 — Three transferable lessons (native; title split to two clean lines) */ {
  const s=base(true); masthead(s,true);
  s.addText('Three transferable lessons',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('what this case teaches',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  const t=[['1','Match management scale to biological scale.','Herring spawn, fleets seine, and whales feed at the cove scale. Manage there — finer-scale escapement costs more but preserves the portfolio, and the portfolio is the resilience.'],
    ['2','Manage the ecosystem, not the stock.','The ecosystem is now the largest consumer of herring. A quota set as if predators are not there is a fiction — integrate species interactions.'],
    ['3','Allocate explicitly across the triple bottom line.','Ecosystem, people (commercial & Haida), and economy cannot all be maximised at once — decide across them through co-governance (AMB, Gwaii Haanas, 2024 Rebuilding Plan).']];
  // numerals now vertically aligned with the headline (not the paragraph centerline)
  t.forEach((r,i)=>{ const y=2.15+i*1.30;
    s.addText(r[0],{x:0.5,y:y-0.05,w:0.8,h:0.7,fontFace:HEAD,fontSize:42,bold:true,color:C.rust,valign:'top'});
    s.addText(r[1],{x:1.35,y,w:11.4,h:0.5,fontFace:HEAD,fontSize:20,bold:true,color:C.ink});
    s.addText(r[2],{x:1.35,y:y+0.5,w:11.4,h:0.75,fontFace:BODY,fontSize:15,color:C.soft,lineSpacing:20}); });
  s.addShape(p.ShapeType.rect,{x:0.5,y:6.15,w:0.06,h:0.85,fill:{color:C.amber}});
  // separated the rust prefix from the italic continuation with a line break
  s.addText([{text:'One thread we are testing, a proposal — not a result:\n',options:{bold:true,color:C.amber}},
    {text:'the early-warning signal here may be spatial — observation scale decides what anyone can see — and recovery has to be redefined against the new state.',options:{italic:true}}],
    {x:0.7,y:6.1,w:12.1,h:0.95,fontFace:HEAD,fontSize:14,color:C.soft,valign:'middle'});
  s.addNotes('Deliver the three crisply. Do not add a fourth. The spatial-EWS thread is a proposal, not a finding (keep hypothesis strength) — and it now ties to the new-state thesis: recovery is redefined against the system we have. Transition: "let me close."');
}

/* S14 — Close */ {
  const s=base(true); photo(s,path.join(PH,'s14_close.png'));
  s.addShape(p.ShapeType.rect,{x:0,y:0,w:W,h:0.78,fill:{color:'0E0E0E',transparency:30}});
  s.addShape(p.ShapeType.rect,{x:0,y:4.2,w:W,h:3.3,fill:{color:'0E0E0E',transparency:30}});
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.6,y:0.28,w:12.2,h:0.34,fontFace:MONO,fontSize:13,color:C.rust,charSpacing:3});
  // #23: drop the "thresholds" framing; close on the new century-of-change /
  // recalibrate thesis that ties back to S3.5 (herring at the food-web centre)
  s.addText([{text:'A century of change —\n',options:{}},
    {text:'recalibrate what herring is.',options:{italic:true,color:C.rust}}],
    {x:0.6,y:4.35,w:12,h:1.35,fontFace:HEAD,fontSize:34,bold:true,color:C.ink,lineSpacing:38});
  s.addText('The economy, the way we extract, and the ecosystem itself all shifted. Recovery is a moving target — herring is not a stock to maximise but the centre of the food web.',
    {x:0.6,y:5.7,w:12,h:0.9,fontFace:HEAD,fontSize:17,italic:true,color:'E8E3DA',lineSpacing:24});
  s.addText('Thank you.',
    {x:0.6,y:6.62,w:12,h:0.4,fontFace:HEAD,fontSize:19,bold:true,color:'E8E3DA'});
  s.addText('With gratitude to the Haida Nation and collaborators.',
    {x:0.6,y:7.05,w:12,h:0.38,fontFace:HEAD,fontSize:13,italic:true,color:'BDB6AB'});
  s.addNotes('Slow down. A century of change — the economy, the means of extraction, and the ecosystem itself all shifted. Recovery is a moving target; herring is not a stock to maximise but the centre of the food web (ties back to S3.5, the wasp-waist). "A century of change — recalibrate what herring is. Thank you." Stop.');
}

/* ======================== BACKUP DECK ======================== */

/* Q&A divider — proper title slide, polished */ {
  const s=base(true);
  // masthead for continuity
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.5,y:0.32,w:12.3,h:0.3,fontFace:MONO,fontSize:11,color:C.rust,charSpacing:3,align:'center'});
  // centered title block
  s.addText([{text:'Q & A — ',options:{}},{text:'backup',options:{italic:true,color:C.rust}}],
    {x:0.5,y:2.9,w:12.3,h:1.2,fontFace:HEAD,fontSize:54,bold:true,color:C.ink,align:'center'});
  // amber accent rule actually centered under the title (slide-centerline)
  s.addShape(p.ShapeType.rect,{x:(W-1.5)/2,y:4.18,w:1.5,h:0.04,fill:{color:C.amber}});
  s.addText('20 audience-anchored backup cards — qa_backup_slides.md',
    {x:0.5,y:4.35,w:12.3,h:0.45,fontFace:HEAD,fontSize:18,italic:true,color:C.soft,align:'center'});
  // "Most-likely pulls" line now in serif italic (matches the subtitle family) instead of fighting mono
  s.addText('Most-likely pulls:  B7 (EWS rigor)  ·  B1 (predators)  ·  B5 (hysteresis vs transient)  ·  B2 (non-identifiability)  ·  B18 (service valuation)  ·  B20 (solutions)',
    {x:1.0,y:4.95,w:11.3,h:0.6,fontFace:HEAD,fontSize:14,italic:true,color:C.softD,align:'center'});
  s.addNotes('Hidden until needed. Full text + proof objects in qa_backup_slides.md.');
}

/* B-DFO — Spawning biomass at LRP (corroboration, moved out of the 14-slide spine) */ {
  const s=base(true); fullbleed(s,path.join(DA,'dfo_spawning_biomass.png'));
  s.addNotes("DFO's own assessment confirms it, independently. Aggregate single-stock SCA (Cleary SR 2025/005, distinct from m1_stier_11). HG spawning biomass sits at the Limit Reference Point (~6.45 kt = 0.3*SB0; SB0 ~21.5 kt). Even at zero catch (HG=0 t since 2002), P(SB2025<LRP)=0.38, P(SB2025<0.75*SB_Prod)=0.95 — the keystone number, and it's DFO's, not ours. Real Table 15/19 data, 2015-2024 + 2025 forecast.");
}

/* ===== Supplementary / Q&A backup figures (SB1–SB7) ===== */

/* SB1 — Portfolio metrics across six management eras */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb1_portfolio_periods.png'));
  s.addNotes('Direct portfolio metrics across the six management eras (m1_stier_11 all-11). Simpson effective sections fell from ~3.7 (1951-65) to ~3.3 (2017-25); top-3 share rose from 80% to 84%. Pull when audience asks "is the portfolio claim a single metric or multiple?" — show two metrics agreeing.');
}

/* SB2 — Predator demand by species */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb2_predator_species.png'));
  s.addNotes('Pull for B1 (predators). Top-12 species ranked by mean recent annual demand on HG herring. Humpback whale ~5 kt/yr; Pacific cod ~3 kt/yr; Steller sea lion ~2.4 kt/yr. Mammals + fish dominate; salmon and birds are smaller bands. Guardrail (claim-control sheet): demand is a pressure, NOT a fitted m1_stier_11 coefficient.');
}

/* SB3 — Climate / Blob context */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb3_climate_blob.png'));
  s.addNotes('Pull for Smale / Cavan style heatwave question. PDO 1951-2024 with 2014-16 Blob shaded. HG herring failed to recover both before and after the Blob — the heatwave is a useful stress-test period, not a promoted non-recovery explanation. PDO is necessary but not sufficient (slide 6).');
}

/* SB4 — m1_stier_11 vs DFO independent confirmation */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb4_dfo_vs_m1.png'));
  s.addNotes('Pull when audience challenges with "is this just your model?" Two independent assessments (m1_stier_11 metapop vs DFO SR 2025/005 SCA, Cleary 2025) reach the same conclusion: HG at the LRP. Methods differ; trajectory agrees. Strongest single piece of external validation.');
}

/* SB5 — Co-governance timeline */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb5_cogovernance_timeline.png'));
  s.addNotes('Pull for B20 (solutions) / co-governance question. 40-year institutional spine: Athlii Gwaii 1985 (Haida assertion of title) → South Moresby Agreement 1988 → Gwaii Haanas Agreement 1993 → AMB 1996 → 2024 minister-signed Rebuilding Plan. The point: nation-to-nation governance came BEFORE the stock-rebuilding plan.');
}

/* SB6 — Cod vs herring grammar */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb6_cod_vs_herring.png'));
  s.addNotes('Pull for B5 (hysteresis vs transient). Schematic comparison: cod recovered post-moratorium (Newfoundland; North Sea); HG herring did not. Same family of stressors, different post-stressor trajectories. The lesson is that removing the stressor is not the same as reversing the tip — the message of the talk.');
}

/* SB7 — EWS as hypothesis (not result) */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb7_ews_hypothesis.png'));
  s.addNotes('Pull for B7 (EWS rigor). Schematic showing what variance/autocorrelation should look like if the portfolio erosion is true critical slowing-down. EXPLICITLY a hypothesis we are testing, not a fitted result. Honest hedging — claim-control sheet keeps this at hypothesis strength.');
}

const out = path.join(__dirname,'..','Herring_RoyalSociety_Stier_2026_clean.pptx');
p.writeFile({fileName:out}).then(()=>console.log('WROTE (native)',out));
