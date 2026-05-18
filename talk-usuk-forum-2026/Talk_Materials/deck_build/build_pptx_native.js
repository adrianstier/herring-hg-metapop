// NATIVE PowerPoint deck — editable text boxes + inserted figures/photos.
// No HTML-rendered slide images. Venue-safe fonts (Georgia/Calibri) so the
// Royal Society PC does not font-substitute. Figures & photos inserted with
// aspect ratio preserved (data figures = contain/never crop; photos = cover).
// Conceptual slides (S5/S7/S11/S12/S13) rebuilt with native text/shapes/charts.
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
// insert image preserving aspect inside a box (contain = letterbox, no crop)
function fig(s,file,box){ const d=sizeOf(fs.readFileSync(file)); const ar=d.width/d.height;
  let w=box.w,h=w/ar; if(h>box.h){h=box.h;w=h*ar;}
  s.addImage({path:file,x:box.x+(box.w-w)/2,y:box.y+(box.h-h)/2,w,h}); }
// cover-fill a photo into the whole slide (crop ok for photos)
function photo(s,file){ s.addImage({path:file,x:0,y:0,w:W,h:H,sizing:{type:'cover',w:W,h:H}}); }

/* S1 — Title */ {
  const s=base(true); photo(s,path.join(PH,'s01_title.png'));
  s.addShape(p.ShapeType.rect,{x:0,y:4.4,w:W,h:3.1,fill:{color:'0E0E0E',transparency:32}});
  masthead(s,true);
  s.addText([{text:'Coupled Tipping Points in ',options:{}},
    {text:'Pacific Herring',options:{italic:true,color:C.rust}},
    {text:' & Haida Gwaii',options:{}}],
    {x:0.6,y:4.7,w:11,h:1.4,fontFace:HEAD,fontSize:40,bold:true,color:C.ink});
  s.addText('Ecological tipping points and ecosystem-service tipping points are not the same event — the gap is where management acts.',
    {x:0.6,y:6.0,w:10,h:0.7,fontFace:HEAD,fontSize:17,italic:true,color:'D9D4CC'});
  s.addText('Adrian Stier · UC Santa Barbara · US–UK Forum · Session 5 · 20 May 2026',
    {x:0.6,y:6.95,w:12,h:0.35,fontFace:MONO,fontSize:11,color:'BDB6AB'});
  s.addNotes('Thank Ida. Genuine Haida-partnership acknowledgment. State the idea before any story (the hook): ecological vs ecosystem-service tipping points can separate; the gap is where management acts. Then: "to test that idea I start ten thousand years ago." ~40s.');
}
/* S2 — The shore comes alive */ {
  const s=base(true);
  s.addMedia({ type:'video', path:path.join(PH,'s02_shore.mp4'),
    cover:'data:image/jpeg;base64,'+fs.readFileSync(path.join(PH,'s02_shore.jpg')).toString('base64'),
    x:0, y:0, w:W, h:H });
  s.addText('~10,000 years ago',{x:0.6,y:6.6,w:6,h:0.5,fontFace:MONO,fontSize:18,color:C.amber});
  s.addNotes('Cold open — do not rush. Quiet shores, then each spring the water turns — silver bait balls offshore. What a forage fish is. It pulls the ecosystem shoreward. Transition: "and they pulled in people."');
}
/* S3 — The people and the fish */ {
  const s=base(true); photo(s,path.join(PH,'s03_people.jpg'));
  s.addShape(p.ShapeType.rect,{x:0,y:5.4,w:W,h:2.1,fill:{color:'0E0E0E',transparency:38}});
  masthead(s,true);
  s.addText('The people and the fish',{x:0.6,y:5.55,w:11,h:0.9,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('Haida kʼaaw — roe-on-branch, a cultural keystone for 10,000+ years',
    {x:0.6,y:6.4,w:9,h:0.5,fontFace:HEAD,fontSize:16,italic:true,color:'D9D4CC'});
  s.addText('Photo: A. Salomon · used with permission · Council of the Haida Nation',
    {x:0.6,y:6.95,w:12,h:0.35,fontFace:MONO,fontSize:10,color:'BDB6AB'});
  s.addNotes('Haida harvest for as long as we can measure — adults and eggs; kʼaaw still alive today. A cultural keystone — your differentiator. Credit on slide. Transition: "we can put numbers on how long this lasted."');
}
/* S4 — The baseline, measured */ {
  const s=base(false); masthead(s,false);
  title(s,[{text:'The baseline, '},{text:'measured',options:{italic:true,color:C.rust}}],false);
  // left: stacked stat callouts
  const stats=[['171','archaeological sites'],['435,777','identified fish bones'],
    ['49%','of all fish — herring'],['99%','site ubiquity'],['<±10%','variance / ~10,700 yr']];
  stats.forEach((v,i)=>{ const y=1.85+i*0.92;
    s.addText(v[0],{x:0.5,y,w:2.5,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.rust});
    s.addText(v[1],{x:3.0,y:y+0.1,w:3.6,h:0.5,fontFace:BODY,fontSize:14,color:C.softD,valign:'middle'}); });
  // right: the iconic ancient-herring-bones-in-hand photo (aspect preserved, no stretch)
  { const w=5.5, h=w*(443/600); s.addImage({path:path.join(PH,'s04_mckechnie_bones.png'),
    x:7.3,y:1.95,w,h}); }
  takeaway(s,'A ten-thousand-year measurement of natural variability. Everything next is a departure from it.',false);
  caption(s,'Source: McKechnie et al. 2014, PNAS. Photo: Jim Barlow / University of Oregon (via Mongabay 2014) — ⚠ confirm reuse rights/credit before the recorded talk.',false);
  s.addNotes('Credibility anchor: a ten-thousand-year measurement of natural variability. State numbers cleanly. Transition: "hold onto that — everything next is a departure."');
}
/* S5 — Two collapses (REAL archipelago spawn-index figure inserted) */ {
  const s=base(true); s.addImage({path:path.join(DA,'05_two_collapses.png'),x:0,y:0,w:W,h:H});
  masthead(s,true); title(s,'Two collapses, two outcomes',true);
  s.addNotes('The engine of the talk — REAL spawn-index data. Reduction fishery 1930s; 1960s collapse rebounded ~5 yr (the control). Roe fishery 1972; closed 1994; still ~10% of historic, has not recovered. Land the contrast: one came back, one did not.');
}
/* S6 — climate/PDO (REAL R figure inserted) */ {
  const s=base(true); s.addImage({path:path.join(DA,'06_climate_pdo.png'),x:0,y:0,w:W,h:H});
  masthead(s,true); title(s,'Ocean productivity is a first-order driver',true);
  s.addNotes('Bayesian state-space models separate drivers. Ocean productivity is a first-order driver — necessary, not sufficient. Guardrail: no promoted predator coefficient for HG (claim-control sheet). Transition: "so we looked at space."');
}

/* S7 — The two scales (native numbers + bars) */ {
  const s=base(true); masthead(s,true);
  title(s,[{text:'The two scales — '},{text:'the average hid the extremes',options:{italic:true,color:C.rust}}],true);
  // left: management scale
  s.addText('MANAGEMENT SCALE',{x:0.7,y:1.8,w:5,h:0.3,fontFace:MONO,fontSize:12,color:C.marine,charSpacing:2});
  s.addText('one quota, the whole archipelago',{x:0.7,y:2.1,w:5.6,h:0.5,fontFace:HEAD,fontSize:18,bold:true,color:C.ink});
  s.addText([{text:'~4%',options:{}},{text:'  Stier et al. 2020',options:{fontSize:11,color:C.soft}}],
    {x:0.7,y:2.7,w:5.6,h:1.4,fontFace:HEAD,fontSize:60,bold:true,color:C.marine});
  s.addText('Archipelago-wide exploitation — modest, sustainable-looking.',{x:0.7,y:4.2,w:5.6,h:0.5,fontFace:BODY,fontSize:14,color:C.soft});
  // right: biological scale (real published number, no invented bars)
  s.addText('BIOLOGICAL SCALE',{x:7.0,y:1.8,w:5,h:0.3,fontFace:MONO,fontSize:12,color:C.rust,charSpacing:2});
  s.addText('where the fish, fleet & predators operate',{x:7.0,y:2.1,w:5.6,h:0.5,fontFace:HEAD,fontSize:18,bold:true,color:C.ink});
  s.addText([{text:'up to ~65%',options:{}},{text:'  Stier et al. 2020',options:{fontSize:11,color:C.soft}}],
    {x:7.0,y:2.7,w:5.9,h:1.4,fontFace:HEAD,fontSize:60,bold:true,color:C.rust});
  s.addText('Local cove exploitation — serial depletion, cove by cove.',{x:7.0,y:4.2,w:5.6,h:0.5,fontFace:BODY,fontSize:14,color:C.soft});
  s.addShape(p.ShapeType.rect,{x:6.55,y:1.85,w:0.012,h:3.0,fill:{color:C.rule}});
  takeaway(s,'The average hid the extremes — match management scale to where biology, extraction, and predation operate.',true);
  caption(s,'Both figures are Stier et al. 2020 (Ecosphere) PUBLISHED results (serial depletion / scale mismatch) — not current m1_stier_11 outputs (numbers_provenance.md). Real published values, stated as such.',true);
  s.addNotes('The conceptual hinge — slow down. Archipelago exploitation ~4% but local cove rates reached ~65% (Stier et al. 2020, published). The average hid the extremes. The cove is where herring spawn, the fleet seines, humpbacks feed.');
}
/* S8 — realized growth (REAL R figure inserted) */ {
  const s=base(true); s.addImage({path:path.join(DA,'08_realized_growth.png'),x:0,y:0,w:W,h:H});
  masthead(s,true); title(s,'Population growth collapsed, cove by cove',true);
  s.addNotes('At the cove scale realized growth fell in nearly every section — the aggregate looked survivable, the cove signal did not. Structural, system-wide, invisible at the management scale.');
}
/* S9 — synchrony / portfolio (REAL R figure inserted) */ {
  const s=base(true); s.addImage({path:path.join(DA,'09_synchrony.png'),x:0,y:0,w:W,h:H});
  masthead(s,true); title(s,'The portfolio eroded',true);
  s.addNotes('Coves used to keep their own rhythm — a portfolio. Synchrony up >60% since the mid-1990s (Stier 2020, measured). Then offer the EWS reading as a PROPOSAL, not a finding — the leading-indicator analysis is not done.');
}
/* S10 — predators */ {
  const s=base(true); masthead(s,true);
  title(s,[{text:'The predators '},{text:'came back',options:{italic:true,color:C.rust}}],true);
  s.addShape(p.ShapeType.rect,{x:0.5,y:1.8,w:12.3,h:3.9,fill:{color:'13161C'},line:{color:C.marine,dashType:'dash',width:1}});
  s.addText('Insert: humpback-feeding video/still (Adrian) + marine-mammal recovery figure inset\n(/Users/adrianstier/pacific-herring-predators/Output/figures/century_scale_predator_field.pdf)',
    {x:0.8,y:3.2,w:11.7,h:1.2,fontFace:MONO,fontSize:16,color:C.marine,align:'center'});
  takeaway(s,'A conservation win became a driver — species interactions can’t be managed around.',true);
  caption(s,'Predator demand is a large ecological pressure; NOT a promoted HG causal coefficient (claim-control sheet).',true);
  s.addNotes('Marine mammals recovered; humpback predation likely the largest mortality source; mobile predators also synchronise. Honest: a conservation triumph AND a tipping cascade (ties to Lenton). TEK 2nd hypothesis. Guardrail: large pressure, NOT a promoted coefficient.');
}
/* S11 — triple bottom line (native 3 columns) */ {
  const s=base(true); masthead(s,true);
  title(s,[{text:'A system in a new state — '},{text:'the triple bottom line, hit',options:{italic:true,color:C.rust}}],true);
  const col=[['Ecosystem',C.kelp,'Predators; halibut & salmon downstream. Spatial structure — the portfolio — eroded.','tipped ~1993 · the shift in the middle'],
    ['People',C.plum,'Haida kʼaaw sites that once thrived — where grandparents passed oral history. The commercial sector lost its fishery.','tipped ~1990 · the slow erosion'],
    ['Economy',C.rust,'HG roe landed value peaked in the 1980s, high to the mid-1990s, then declined (2024 Rebuilding Plan, Figs 31/32).','tipped ~2005 · the fast crash']];
  col.forEach((c,i)=>{ const x=0.5+i*4.2;
    s.addShape(p.ShapeType.rect,{x,y:1.9,w:3.95,h:0.05,fill:{color:c[1]}});
    s.addText(c[0].toUpperCase(),{x,y:2.05,w:3.95,h:0.35,fontFace:MONO,fontSize:13,color:c[1],charSpacing:2});
    s.addText(c[2],{x,y:2.5,w:3.95,h:2.4,fontFace:BODY,fontSize:16,color:C.ink,lineSpacing:24});
    s.addText(c[3],{x,y:5.1,w:3.95,h:0.4,fontFace:MONO,fontSize:12,color:c[1]}); });
  takeaway(s,'The economic crash was fast, the cultural erosion slow, the ecological shift between — they decoupled.',true);
  caption(s,'~10% of historic / alternative stable state = current m1_stier_11 + DFO SR 2025/005. No "$40M→$2.78M" claim (unsourced). Cultural axis = spatial contraction + lost knowledge vs the ~10,000-yr baseline, not a number.',true);
  s.addNotes('Alternative stable state ~10% of historic. Three bottom lines, three clocks. Economic fast, cultural slow, ecological between. Transition to the decoupling figure.');
}
/* S12 — the decoupling (native multi-series line chart + window) */ {
  const s=base(true); masthead(s,true);
  title(s,[{text:'Four layers, '},{text:'four clocks',options:{italic:true,color:C.rust}}],true);
  s.addText('Each layer tipped on its own clock — the offsets are the management window. Real anchored dates, not drawn curves.',
    {x:0.5,y:1.55,w:12.3,h:0.5,fontFace:HEAD,fontSize:17,italic:true,color:C.soft});
  const rows=[
    [C.plum,'Cultural service — kʼaaw','tips ~1990','Spawn-area contraction (Gerrard 2014, ~7.6%/decade); roe-on-kelp lost at sites; post-2002 functional closure.'],
    [C.kelp,'Ecological structure','tips 1993','Subpopulation synchrony rises >60% (slide 9 — real m1_stier_11 / Stier 2020).'],
    [C.rust,'Economic value (HG 2E roe)','falls ~2005','Landed value peaked 1980s, high to mid-1990s, then declined (2024 Rebuilding Plan Figs 31/32; DFO fish slips).'],
    [C.marine,'Co-governance','rises later','Athlii Gwaii 1985 → Gwaii Haanas Agreement 1993 → Archipelago Management Board → 2024 minister-signed Rebuilding Plan.']];
  rows.forEach((r,i)=>{ const y=2.15+i*0.92;
    s.addShape(p.ShapeType.rect,{x:0.5,y:y+0.06,w:0.16,h:0.5,fill:{color:r[0]}});
    s.addText(r[1],{x:0.8,y,w:3.5,h:0.55,fontFace:HEAD,fontSize:18,bold:true,color:r[0]});
    s.addText(r[2],{x:4.3,y,w:1.9,h:0.55,fontFace:MONO,fontSize:15,color:C.ink});
    s.addText(r[3],{x:6.3,y,w:6.5,h:0.7,fontFace:BODY,fontSize:13.5,color:C.soft,lineSpacing:17}); });
  takeaway(s,'Three layers fall, one rises — the horizontal gap between them is the management window.',true);
  caption(s,'Dates anchored to cited sources (no fabricated time series). Governance = institutional milestones, NOT an outcome metric — HG still below LRP, 0-t (DFO SR 2025/005).',true);
  s.addNotes('Four layers, four clocks — anchored to real dated events: service ~1990, ecological 1993 (the real synchrony rise), economic ~2005 (Rebuilding Plan), governance rises later. Three fall, one rises. The gap is the management window. Governance is milestones, not an outcome.');
}
/* S13 — what this teaches (native numbered) */ {
  const s=base(true); masthead(s,true);
  title(s,[{text:'What this case teaches — '},{text:'three transferable lessons',options:{italic:true,color:C.rust}}],true);
  const t=[['1','Match the scale of management to the scale of biology.','Manage at the cove/section scale. Finer-scale escapement is costly, but it preserves the portfolio — and the portfolio is the resilience.'],
    ['2','Manage the ecosystem, not the stock.','Integrate species interactions. The ecosystem is the largest consumer of herring; a quota set as if predators aren’t there is a fiction.'],
    ['3','Allocate explicitly across the triple bottom line.','Ecosystem, the human sectors (commercial & Haida), and the economy — via co-governance (AMB, Gwaii Haanas reserve & WHS, 2024 Plan).']];
  t.forEach((r,i)=>{ const y=1.85+i*1.35;
    s.addText(r[0],{x:0.5,y,w:0.8,h:1.2,fontFace:HEAD,fontSize:36,bold:true,color:C.rust});
    s.addText(r[1],{x:1.35,y,w:11.4,h:0.5,fontFace:HEAD,fontSize:20,bold:true,color:C.ink});
    s.addText(r[2],{x:1.35,y:y+0.5,w:11.4,h:0.8,fontFace:BODY,fontSize:15,color:C.soft,lineSpacing:20}); });
  s.addShape(p.ShapeType.rect,{x:0.5,y:6.05,w:0.06,h:0.95,fill:{color:C.amber}});
  s.addText([{text:'One open thread, a proposal — not a result: ',options:{bold:true,color:C.amber}},
    {text:'the early-warning signal here may be spatial. If so, observation scale decides what anyone can see. That is what we are testing next.',options:{italic:true}}],
    {x:0.7,y:6.0,w:12.1,h:1.0,fontFace:HEAD,fontSize:15,color:C.soft,valign:'middle'});
  s.addNotes('Deliver the three crisply. Do not add a fourth. The EWS thread is a proposal, not a finding (keep hypothesis strength). Transition: "let me close."');
}
/* DFO corroboration — Cleary SR 2025/005 spawning biomass (REAL extract) */ {
  const s=base(true); s.addImage({path:path.join(DA,'dfo_spawning_biomass.png'),x:0,y:0,w:W,h:H});
  masthead(s,true); title(s,'Spawning biomass at the limit reference point',true);
  s.addNotes("DFO's own assessment confirms it, independently. Aggregate single-stock SCA (Cleary SR 2025/005, distinct from m1_stier_11). HG spawning biomass sits at the Limit Reference Point (~6.45 kt = 0.3*SB0; SB0 ~21.5 kt). Even at zero catch (HG=0 t since 2002), P(SB2025<LRP)=0.38, P(SB2025<0.75*SB_Prod)=0.95 — the keystone number, and it's DFO's, not ours. Real Table 15/19 data, 2015-2024 + 2025 forecast (the full 1951-2024 series is a figure-only digitization, handed off).");
}
/* S14 — close */ {
  const s=base(true); photo(s,path.join(PH,'s14_close.png'));
  s.addShape(p.ShapeType.rect,{x:0,y:4.2,w:W,h:3.3,fill:{color:'0E0E0E',transparency:30}});
  s.addText([{text:'The herring is the example. ',options:{}},
    {text:'The lesson is about thresholds.',options:{italic:true,color:C.rust}}],
    {x:0.6,y:4.9,w:12,h:1.4,fontFace:HEAD,fontSize:36,bold:true,color:C.ink});
  s.addText('Thank you. — With gratitude to the Haida Nation and collaborators.',
    {x:0.6,y:6.3,w:12,h:0.5,fontFace:HEAD,fontSize:16,italic:true,color:'D9D4CC'});
  s.addNotes('Slow down. Recovery is a moving target. Manage the gap, at the right scale, for the whole system. "The herring is the example. The lesson is about thresholds. Thank you." Stop.');
}
/* Q&A backup divider */ {
  const s=base(true);
  s.addText([{text:'Q & A — ',options:{}},{text:'backup',options:{italic:true,color:C.rust}}],
    {x:0.8,y:2.9,w:11.7,h:1.0,fontFace:HEAD,fontSize:40,bold:true,color:C.ink});
  s.addText('20 audience-anchored backup cards — qa_backup_slides.md. Most-likely pulls: B7 (EWS rigor) · B1 (predators) · B5 (hysteresis vs transient) · B2 (non-identifiability) · B18 (service valuation) · B20 (solutions).',
    {x:0.8,y:4.0,w:11.7,h:1.6,fontFace:BODY,fontSize:16,color:C.soft,lineSpacing:24});
  s.addNotes('Hidden until needed. Full text + proof objects in qa_backup_slides.md.');
}

const out = path.join(__dirname,'..','Herring_RoyalSociety_Stier_2026.pptx');
p.writeFile({fileName:out}).then(()=>console.log('WROTE (native)',out));
