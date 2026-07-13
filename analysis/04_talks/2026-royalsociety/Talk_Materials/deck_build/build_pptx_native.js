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
  s.addNotes('Thank Ida. Genuine Haida-partnership acknowledgment. State the idea before any story (the hook): ecological vs ecosystem-service tipping points can separate; the gap is where management acts. Then: "to test that idea, start with where this happens." ~40s. (Next is the place locator S1b; the deep-time 10,000-yr framing deliberately arrives at S4, not here.)');
}

/* S1b — Sense of place (real ESRI/Maxar satellite imagery of Haida Gwaii
   with deck-styled annotations: shelf edge, upwelling, protected spawning
   coves, plus amber dots for Skidegate/Cumshewa/Selwyn — the inlets the
   talk later cites). Authored as a full-bleed baked PNG via
   `s01b_haida_gwaii_place.html`; no native text overlay (no font-substitution
   risk). FAST beat (~25s). */ {
  const s=base(true);
  fullbleed(s,path.join(DA,'01b_sense_of_place.png'));
  s.addNotes('SENSE OF PLACE — ~25s. Orient the room: Haida Gwaii is a fragmented archipelago ~100 km off mainland British Columbia — two main islands (Graham in the north, Moresby in the south) plus hundreds of smaller ones. The continental shelf edge runs along the west coast: deep, productive Pacific water rises along the slope and bathes the sheltered east-facing coves. THAT geometry — open-ocean upwelling outside, hundreds of protected coves inside — is what built the spawning network. Archaeological evidence puts herring as the dominant fish at these sites continuously over ~10,700 years (McKechnie 2014 PNAS — picked up explicitly at S4). The three inlets marked — Skidegate, Cumshewa, Selwyn — are the names you will hear again: Selwyn was once the richest spawn ("Million Dollar Bay"), and is now empty. Transition: "and every spring, the shore comes alive."');
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

/* S2b — The big event (NEW; ③ spawn-in-cove bridge: herring move inshore →
   the shore turns turquoise — the event everything shows up for). Full-bleed
   aerial, pre-cropped ~16:9 so no distortion. */ {
  const s=base(true);
  s.addImage({path:path.join(PH,'s02b_spawn_turquoise.jpg'),x:0,y:0,w:W,h:H});
  s.addShape(p.ShapeType.rect,{x:0,y:0,w:W,h:0.78,fill:{color:'0E0E0E',transparency:30}});
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.6,y:0.28,w:12.2,h:0.34,fontFace:MONO,fontSize:13,color:C.rust,charSpacing:3});
  s.addShape(p.ShapeType.rect,{x:0,y:5.95,w:W,h:1.55,fill:{color:'0E0E0E',transparency:24}});
  s.addText([{text:'Then the shore ',options:{}},
    {text:'turns turquoise.',options:{italic:true,color:C.rust}}],
    {x:0.6,y:6.05,w:12,h:0.7,fontFace:HEAD,fontSize:32,bold:true,color:C.ink});
  s.addText('Billions of eggs on kelp and rock — the one event the whole coast waits for.',
    {x:0.6,y:6.78,w:12,h:0.4,fontFace:HEAD,fontSize:15,italic:true,color:'D9D4CC'});
  s.addText('Aerial: Pacific herring spawn, Haida Gwaii (teaching-media library; rights-flag).',
    {x:0.6,y:7.16,w:12.2,h:0.28,fontFace:MONO,fontSize:9,color:'BDB6AB'});
  s.addNotes('③ THE BRIDGE — herring move inshore (S2), and THIS is the event it creates. ~10–15 s, let the image land: billions of eggs blanket kelp and rock, the water turns turquoise for miles. This is WHY everything shows up next — people and animals (S3 / S3b). Skip-safe if very tight. ⚠️ RIGHTS: aerial from the EEMB-142C teaching-media library — same discipline as the Oceana/BBC flags; Adrian to confirm reuse for the recorded talk.');
}

/* S3 — The people and the fish (PAIRED, per Adrian 2026-05-19:
   LEFT = a person holding up the herring eggs; RIGHT = cropped people
   pulling hemlock boughs from the water — the kʼaaw / SOK practice) */ {
  const s=base(true);
  // Each photo is PRE-CROPPED to the exact half-slide aspect (W/2 : H ≈
  // 0.8889) so it places 1:1 with NO stretch — pptxgenjs sizing:'cover' is
  // not reliably honoured by PowerPoint, so we crop upstream instead.
  s.addImage({ path:path.join(PH,'s03_eggs_held.jpg'),    x:0,   y:0, w:W/2, h:H });
  s.addImage({ path:path.join(PH,'s03_hemlock_pull.jpg'), x:W/2, y:0, w:W/2, h:H });
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
  s.addText('Photos: A. Salomon · used with permission · Council of the Haida Nation',
    {x:0.6,y:6.95,w:12.2,h:0.35,fontFace:MONO,fontSize:10,color:'BDB6AB'});
  s.addNotes('Haida harvest for as long as we can measure — adults and eggs; kʼaaw still alive today. A cultural keystone — your differentiator. Credit on slide. Transition: "but first — where does herring sit in this whole system?" (hands into S3.5, the wasp-waist; the "put numbers on how long this lasted" beat now lands on S4).');
}

/* S3b — …and the animals (NEW; ② egg-predators). HG bald eagle contained on
   dark; bear/wolf NAMED in copy (no rights-safe HG photo in the library —
   flagged as a wanted asset). */ {
  const s=base(true); masthead(s,true);
  s.addText([{text:'The same event feeds ',options:{}},
    {text:'the whole coast',options:{italic:true,color:C.rust}}],
    {x:0.5,y:0.66,w:12.3,h:0.8,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  { const h=4.7, w=h*(798/800), x=(W-w)/2;
    s.addImage({path:path.join(PH,'s03c_eagle.jpg'),x,y:1.5,w,h}); }
  s.addText('Bald eagle on the herring spawn, Skidegate Inlet — with gulls, sea lions and humpbacks on the fish, and on the beaches black bears and wolves. People are one of many.',
    {x:0.6,y:6.42,w:12.1,h:0.5,fontFace:HEAD,fontSize:15,italic:true,color:C.soft,align:'center'});
  s.addText('Photo: P. Levin · Skidegate Inlet, Haida Gwaii (collaborator; rights-flag). Bear & wolf egg-predation photos still wanted.',
    {x:0.6,y:7.06,w:12.1,h:0.3,fontFace:MONO,fontSize:9,color:C.softD,align:'center'});
  s.addNotes('② PEOPLE AND ANIMALS — the same spring eggs feed the whole coast: eagles and gulls on the spawn; sea lions and humpbacks on the fish; and the HG-distinctive land–sea link — black bears and wolves eating spawn on the beach. People are one consumer among many. Sets up the wasp-waist (S3.5) and the predator beat (S10/S10b). ⚠️ ASSET GAP: only an HG bald-eagle photo is rights-plausible/available — bear & wolf egg-predation photos (Adrian’s ②, "low-hanging fruit") are NOT in the media library; NAMED on-slide as a stopgap, add the photos when sourced. RIGHTS: P. Levin collaborator photo — confirm reuse for the recorded talk (same discipline as Salomon/Oceana/BBC).');
}

/* S3.5 — Herring: the wasp-waist of Haida Gwaii (④ bespoke native diagram,
   replaces the generic Oceana / Seattle-Times figure — original schematic,
   NO third-party rights). Converge→diverge funnel: ocean productivity →
   the single herring channel → HG-specific consumers, INCLUDING the
   land–sea link (black bear, wolf on the beach spawn) — the deliberate
   HG differentiator that also carries ②. */ {
  const s=base(true); masthead(s,true);
  s.addText([{text:'Herring — the ',options:{}},
    {text:'wasp-waist',options:{italic:true,color:C.rust}},
    {text:' of Haida Gwaii',options:{}}],
    {x:0.5,y:0.62,w:12.3,h:0.66,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('one forage fish channels the whole system — sea and land',
    {x:0.5,y:1.2,w:12.3,h:0.4,fontFace:HEAD,fontSize:18,italic:true,color:C.rust});
  // ---- faint converge→diverge funnel (the wasp-waist) ----
  // top inverted triangle: herring (apex, bottom) → consumers (wide top)
  s.addShape(p.ShapeType.triangle,{x:0.7,y:2.02,w:11.93,h:1.74,
    fill:{color:C.marine,transparency:88},line:{type:'none'},rotate:180});
  // bottom triangle: productivity (wide base) → herring (apex, top)
  s.addShape(p.ShapeType.triangle,{x:2.4,y:4.58,w:8.53,h:1.42,
    fill:{color:C.kelp,transparency:88},line:{type:'none'}});
  // ---- the waist: PACIFIC HERRING ----
  s.addShape(p.ShapeType.roundRect,{x:5.0,y:3.8,w:3.333,h:0.8,rectRadius:0.06,
    fill:{color:C.rust}});
  s.addText('PACIFIC HERRING',{x:5.0,y:3.9,w:3.333,h:0.34,fontFace:HEAD,
    fontSize:17,bold:true,color:C.inkD,align:'center'});
  s.addText('spawns in Haida Gwaii coves',{x:5.0,y:4.24,w:3.333,h:0.28,
    fontFace:MONO,fontSize:10,color:C.inkD,align:'center'});
  // ---- bottom: ocean productivity ----
  s.addShape(p.ShapeType.rect,{x:2.6,y:5.74,w:8.13,h:0.04,fill:{color:C.kelp}});
  s.addText('OCEAN PRODUCTIVITY   ·   phytoplankton → zooplankton',
    {x:2.6,y:5.8,w:8.13,h:0.34,fontFace:MONO,fontSize:12,color:C.kelp,
     align:'center',charSpacing:1});
  // ---- top: HG-specific consumers (6 groups, deck colour contract;
  //      LAND = the HG land–sea differentiator) ----
  const cons=[['MARINE MAMMALS',C.marine,'Humpback whale\nSteller sea lion'],
    ['GROUNDFISH',C.kelp,'Pacific cod\nhalibut · lingcod'],
    ['SALMON',C.amber,'Salmon\n(juveniles)'],
    ['SEABIRDS',C.plum,'Bald eagle\ngulls'],
    ['LAND',C.rust,'Black bear\nWolf'],
    ['PEOPLE',C.ink,'Haida kʼaaw\ncommercial (closed)']];
  cons.forEach((c,i)=>{ const x=0.67+i*2.03;
    s.addShape(p.ShapeType.rect,{x,y:1.98,w:1.85,h:0.05,fill:{color:c[1]}});
    s.addText(c[0],{x,y:2.07,w:1.85,h:0.3,fontFace:MONO,fontSize:11,color:c[1],align:'center',charSpacing:1});
    s.addText(c[2],{x,y:2.4,w:1.85,h:0.66,fontFace:BODY,fontSize:12.5,color:C.ink,align:'center',lineSpacing:14}); });
  s.addText('One fish is the single channel — and in Haida Gwaii it runs onto the beach: bears and wolves feed on the spawn. Change the waist and everything above it changes.',
    {x:0.7,y:6.34,w:11.9,h:0.6,fontFace:HEAD,fontSize:15,italic:true,color:'D9D4CC',align:'center'});
  s.addText('Original schematic (this work) — the Haida Gwaii wasp-waist (salmon shown as juvenile/recruitment context).',
    {x:0.5,y:7.06,w:12.3,h:0.32,fontFace:MONO,fontSize:9,color:C.soft,align:'center'});
  s.addNotes('④ THE BESPOKE HG WASP-WAIST — replaces the generic Oceana / Seattle-Times diagram (original schematic, no third-party rights — an improvement). Set up explicitly for non-experts: it underpins S10/S10b (predators), S10d, and the close (S14). Ocean productivity → plankton funnels into ONE pinch-point (herring), which then fans out to marine mammals (humpback, Steller), groundfish (cod, halibut, lingcod), salmon, seabirds (eagle, gulls), and people (Haida kʼaaw + the now-closed commercial fishery). THE HG DIFFERENTIATOR (carries ②): the channel runs onto the LAND — black bears and wolves eat herring spawn on the beach (a land–sea coupling the generic diagram misses). Salmon are deliberately labelled juvenile/recruitment CONTEXT only (claim-control sheet — not adult-biomass mortality). "Change the waist and everything above it changes." Transition: "but first — how did people’s relationship with it change?" (hands into S3.6, how herring’s value changed; the "put numbers on how long this lasted" beat lands on S4).');
}

/* S3.6 — How herring's value changed (economics UP FRONT — Option A ①;
   moved from the old S10c). Sets up how demand & markets changed how PEOPLE
   engaged with herring, BEFORE the mechanism. On-slide $ = primary-source
   only (Adrian's call 2026-05-19 — Rebuilding Plan §5.2.3); richer per-era $
   + Roy Jones Sr./Ernie Wilson quotes = speaker-note colour only. */ {
  const s=base(true); masthead(s,true);
  s.addText('How herring’s value changed',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('same fish — three price regimes',
    {x:0.5,y:1.25,w:7.6,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  // value-of-the-catch axis cue
  s.addText('VALUE OF THE CATCH  ↑',
    {x:9.2,y:1.32,w:3.6,h:0.3,fontFace:MONO,fontSize:11,color:C.soft,charSpacing:2,align:'right'});
  // ---- value-height motif: industrial-low → luxury-peak → demand-crash ----
  const yB=4.45;                                  // shared baseline
  const acts=[
    {x:0.5,bx:0.85,name:'ACT 1 — INDUSTRIAL INPUT',yr:'1930s – 1967',col:C.softD,
     h:0.55, body:'Reduction fishery — herring to fishmeal and oil, the lowest-value use. No market price signal; the only value was Haida kʼaaw.'},
    {x:4.7,bx:5.05,name:'ACT 2 — KAZUNOKO LUXURY',yr:'1972 – ~1996',col:C.amber,
     h:2.30, body:'The fish did not change — the market did. Japan’s own herring collapse turned BC roe into a near-price-inelastic New-Year luxury.'},
    {x:8.9,bx:9.25,name:'ACT 3 — DEMAND COLLAPSE',yr:'~1996 – 2006',col:C.marine,
     h:0.28, body:'Demand-side, not stock-side: Japanese consumption shifted and low-cost competitors flooded the one market — then the closures.'}];
  const bw=3.35;
  // baseline + faint inter-regime dividers
  s.addShape(p.ShapeType.rect,{x:0.5,y:yB,w:12.33,h:0.018,fill:{color:C.rule}});
  [4.6,8.8].forEach(dx=>s.addShape(p.ShapeType.rect,{x:dx,y:2.0,w:0.012,h:4.2,fill:{color:C.rule}}));
  // rose / fell cues between the bars
  s.addText('↑',{x:3.95,y:3.05,w:1.0,h:0.7,fontFace:HEAD,fontSize:32,bold:true,color:C.amber,align:'center',valign:'middle'});
  s.addText('↓',{x:8.25,y:2.70,w:1.0,h:0.7,fontFace:HEAD,fontSize:32,bold:true,color:C.marine,align:'center',valign:'middle'});
  acts.forEach(a=>{
    const top=yB-a.h;
    s.addShape(p.ShapeType.rect,{x:a.bx,y:top,w:bw,h:a.h,fill:{color:a.col}});
  });
  // Act-2 peak value INSIDE the tall amber bar (Set A: Rebuilding Plan)
  s.addText('$62.88 / lb',{x:5.05,y:2.32,w:bw,h:0.42,fontFace:HEAD,fontSize:20,bold:true,color:C.inkD,align:'center'});
  s.addText('1995 peak · spawn-on-kelp',{x:5.05,y:2.76,w:bw,h:0.28,fontFace:MONO,fontSize:10,color:C.inkD,align:'center'});
  // Act-1 "no price signal" tag above its low bar
  s.addText('no market price',{x:0.85,y:3.46,w:bw,h:0.3,fontFace:MONO,fontSize:11,italic:true,color:C.softD,align:'center'});
  // Act-3 collapsed value above its tiny bar (Set A endpoints only)
  s.addText('$11–14 / lb today',{x:9.25,y:3.46,w:bw,h:0.34,fontFace:HEAD,fontSize:17,bold:true,color:C.marine,align:'center'});
  s.addText('last HG roe fishery 2002',{x:9.25,y:3.84,w:bw,h:0.26,fontFace:MONO,fontSize:10,color:C.soft,align:'center'});
  // ---- act narrative band (below baseline) ----
  acts.forEach(a=>{
    s.addShape(p.ShapeType.rect,{x:a.x,y:4.72,w:3.95,h:0.05,fill:{color:a.col}});
    s.addText(a.name,{x:a.x,y:4.84,w:3.95,h:0.3,fontFace:MONO,fontSize:13,color:a.col,charSpacing:1});
    s.addText(a.yr,{x:a.x,y:5.13,w:3.95,h:0.26,fontFace:MONO,fontSize:11,color:C.soft});
    s.addText(a.body,{x:a.x,y:5.42,w:3.95,h:0.86,fontFace:BODY,fontSize:13,color:C.ink,lineSpacing:17});
  });
  takeaway(s,'Same fish, three regimes — industrial input → luxury export → near-worthless in ~35 years. How people engaged with herring was set by the market, not by the fish.',true);
  caption(s,'Spawn-on-kelp price = 2024 HG Herring Rebuilding Plan §5.2.3 (DFO fish slips). Kazunoko-demand-collapse driver = documented context.',true);
  s.addNotes('THE ECONOMIC STORY — same fish, three price regimes; ~40s. Supply-vs-demand answer is BOTH, coupled. ACT 1 (industrial input, 1930s–1967): reduction fishery, herring → fishmeal/oil, the lowest-value use, harvested for sheer volume (coastwide >200 kt/yr early 1960s, 240 kt in 1963; HG record 77,500 t in 1956 off the 1951 year-class). No ex-vessel price signal this era; the only high-value product was Haida kʼaaw/SOK — largely a trade good (bartered Tsimshian/Tlingit for eulachon grease, soapberries) or artisanal (Ernie Wilson: dried kʼaaw $0.22/lb, 1930s, Jedway). Overfishing + poor recruitment shut the fishery 1967/68. ACT 2 (kazunoko explosion, 1972–~1996): the resource did not change, the MARKET did — Japan’s own domestic herring fishery collapsed early-1970s, turning fishmeal fish into an overnight luxury (only female roe = kazunoko, a near-price-inelastic Japanese New-Year delicacy). Roy Jones Sr.: early-70s roe $0.85/lb from a Vancouver middleman (“change the address, ship to Japan”). SOK $1.2M (111 t, 1977) → $22.4M (256 t, 1996); coastwide roe ~$50M/yr on ~32,000 t (1993–2002); seine peak ≈$40M (1993); premium dried kʼaaw direct to Japanese buyers up to $24/lb. ACT 3 (demand collapse, ~1996–2006): DEMAND-side, not stock-side — Japan’s post-bubble stagnation, a generational shift away from kazunoko, and low-cost Alaska/Russia supply into the same single market. SOK ~$40/lb (1995) → <$6/lb (2004), ~85% in under a decade; coastwide roe $50M → ~$12M (2004) → $2.78M (2006); near-worthless by 2006 (Food&Bait $0.15/lb, Special Use $0.62/lb). HG fishery closed 1999–2001, then 2003–present. ⚠️ ON-SLIDE $ ARE PRIMARY-SOURCE ONLY (Adrian’s call 2026-05-19): spawn-on-kelp $62.88/lb (1995) → $11–14/lb recently + last HG roe fishery 2002 — all 2024 HG Herring Rebuilding Plan §5.2.3 / DFO fish slips. The richer per-era figures and the Roy Jones Sr./Ernie Wilson quotes above are SPOKEN COLOUR / NOTES ONLY — teaching-deck-sourced, they differ from the primary source ($40 vs $62.88/lb in 1995); do NOT put them on-slide for the recorded talk. SET-UP, UP FRONT (Option A ①) — placed before the mechanism to establish how demand & markets changed the way PEOPLE engaged with herring. The full round trip — industrial → luxury → near-worthless in ~35 yr — shows the MARKET, not the fish, set human use; the stock collapse is roughly concurrent and disentangling demand- vs supply-driven is an open question revisited later. Do NOT deliver the "value moved, it didn’t vanish" payoff here — that lands at S11; here, just establish the trajectory and that human engagement tracked the market. Transition: "now — how long has this lasted?" (hands into S4, the ~10,000-yr baseline). Claim-control: the kazunoko/Japan-collapse mechanism is well-documented context; on-slide quantitative claims = the Rebuilding-Plan price trajectory only.');
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
  takeaway(s,'A ten-thousand-year measurement of natural variability — the baseline every later change departs from.',false);
  // caption: wider, smaller, keep inside slide
  s.addText('Map & data: McKechnie et al. 2014, PNAS — ▲ archaeological sites, red = herring spawn.',
    {x:0.5,y:7.05,w:12.3,h:0.4,fontFace:MONO,fontSize:9,color:C.softD});
  s.addNotes('Credibility anchor: a ten-thousand-year measurement of natural variability. State numbers cleanly. Transition: "hold onto that baseline — first, how we know it." (Next is S4b, the methods/legitimacy beat; the departures begin one slide later at S5.)');
}

/* S5–S10 — image-rendered figure slides. Each PNG already carries its own
   masthead + title (S5/S7 by design, S6/S8/S9/S10 baked-in by preprocess_figures.py),
   so we DO NOT overlay native chrome on top — that is what was causing every
   text-on-axis collision in the prior build. */

/* S4b — How we know this (methods/legitimacy; OUR m1_stier_11, NOT Okamoto) */ {
  const s=base(true); masthead(s,true);
  s.addText('How we know this',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('a Bayesian metapopulation model of the spawn record',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  const mr=[['Data','75 years of DFO spawn-index surveys, 11 spawning sections across Haida Gwaii — surface and dive eras.'],
    ['Model','Bayesian state-space metapopulation (m1_stier_11): spatially-correlated process error, section-specific observation error, two-era survey scaling (q), ambiguous zeros treated as missing.'],
    ['Lineage','Extends the Stier et al. 2020 (Ecosphere) Haida Gwaii metapopulation analysis; focal-9 reporting as a sensitivity.'],
    ['Reading','We infer section-scale biomass with its uncertainty — not one coastwide number. Predator demand enters only as audited external pressure, never a fitted mortality term.']];
  mr.forEach((v,i)=>{ const y=2.15+i*1.18;
    s.addText(v[0].toUpperCase(),{x:0.5,y,w:2.1,h:0.5,fontFace:MONO,fontSize:15,color:C.amber,charSpacing:2});
    s.addText(v[1],{x:2.8,y,w:10.0,h:1.08,fontFace:BODY,fontSize:15,color:C.ink,lineSpacing:20}); });
  caption(s,'m1_stier_11 (this work) — Bayesian state-space metapopulation, updated from Stier et al. 2020 Ecosphere. Honest uncertainty; no promoted predator coefficient.',true);
  s.addNotes('LEGITIMACY beat (~40s) — give a non-fisheries tipping-points audience reason to trust the inference. This is OUR model (m1_stier_11), NOT Okamoto: a Bayesian state-space metapopulation fit to 75 yr of DFO spawn-index surveys across 11 sections, with spatial process error, section-specific observation error, two-era survey scaling, zeros treated as missing (Stier-2020 lineage, extended). We report section-scale biomass with uncertainty, not one coastwide tonnage. Predator demand is audited external pressure only — never a fitted mortality coefficient (claim-control). Okamoto et al. 2020 appears later as the SOLUTION, not here. Transition: "now — every departure from that baseline." (hands into S5, the two collapses).');
}

/* S5 — Two collapses */ {
  const s=base(true); fullbleed(s,path.join(DA,'05_two_collapses.png'));
  s.addNotes('The engine of the talk — REAL m1_stier_11 estimated total HG biomass (focal-9, median + 80% CI). Reduction fishery 1930s; 1960s collapse rebounded to the historic level in ~5 yr (the control). Roe fishery 1972; closed 1994; the median has stayed WELL BELOW the historic level for 30+ yr. Be precise: the recent up-tick is a weakly-constrained terminal-year band (80% CI runs off-chart, 90% far higher) — uncertainty, not a measured recovery; a modest partial rebound at most. Do NOT say "~10% of historic" here — that is the DFO spawning-biomass-vs-reference number (a different quantity; it lives on S11/S12 + the DFO backup). On THIS slide the honest claim is "still below the historic level, has not recovered". Land the contrast and POSE THE PUZZLE for the rest of the talk: same fish, same place — one collapse came back fast, the other has not in 30+ yr. The talk’s answer is NOT "a dramatic flip into a new stable state" — it is that the SPATIAL PORTFOLIO was slowly drawn down and never rebuilt (a slow tipping point); "a new stable state" is one hypothesis of several, not proven.');
}

/* S6 — climate / PDO */ {
  const s=base(true); fullbleed(s,path.join(DA,'06_climate_pdo.png'));
  s.addNotes('Bayesian state-space models separate drivers. Ocean productivity is a first-order driver — cool, productive PDO phases raise herring growth ~15%, warm phases ~8% lower: a ~1.25× swing across the observed PDO range (the real model number — not a 3× claim). Necessary, not sufficient: it does not explain non-recovery. The biomass panel is the same focal-9 m1 series as S5 (median + 80% CI, capped axis): post-1994 the median sits below the historic level; the recent up-tick is a partial rebound within a wide, weakly-constrained terminal band — not recovery. Guardrail: no promoted predator coefficient for HG (claim-control sheet). Transition: "so we looked at space." ⏱️ DROP-ON-THE-DAY: if running long, this slide is skip-safe — say one line ("productivity matters but isn’t the barrier") and move straight to the spatial story; S5 + the spatial slides carry the argument without it. Target ~20 min; S6 + S9b are the two designated cuts.');
}

/* S7 — The two scales */ {
  const s=base(true); fullbleed(s,path.join(DA,'07_two_scales.png'));
  s.addNotes('The conceptual hinge — slow down. Same fishery, two scales: managed at ~3% archipelago-wide (looked sustainable, under the 20% rule in all but one year), but fished coves were pushed to ~50% (upper CI ~70%) — the 20% HCR was exceeded 22 of 75 years at the cove scale, only once archipelago-wide. The average hid the extremes; the cove is where herring spawn, the fleet seines, humpbacks feed. Benchmark provenance: DFO "cut-off + 20% harvest-rate" HCR for Major SARs, in force ~1983–2017 (Minor SAR coves dropped to 10% after 1994; policy reviewed 2017; DFO 2020 / HG Rebuilding Plan 2024). Figure provenance: updated Stier et al. 2020 method, catch matrix extended to 2025 — scale-mismatch / serial-depletion result, NOT an m1_stier_11 output (numbers_provenance.md / claim-control sheet).');
}

/* S8 — realized growth */ {
  const s=base(true); fullbleed(s,path.join(DA,'08_realized_growth.png'));
  s.addNotes('At the cove scale realized growth fell in nearly every section — the aggregate looked survivable, the cove signal did not. Structural, system-wide, invisible at the management scale.');
}

/* S8b — THE PORTFOLIO, raw subpopulation time series (Adrian 2026-05-19:
   show the portfolio first; make the local↔HG-region scale mismatch
   explicit; sets up the synchrony change on S9). Baked figure. */ {
  const s=base(true); fullbleed(s,path.join(DA,'08b_subpop_portfolio.png'));
  s.addNotes('THE SCALE-MISMATCH SETUP — say this explicitly. Each thin line is one modelled herring subpopulation (a cove); the bold white line is the across-cove median (the Haida Gwaii region). The point: local and regional dynamics are NOT the same. Any single cove is volatile — it booms and busts on its own schedule — but for most of the record the coves peaked and troughed OUT OF PHASE, so the regional aggregate stayed comparatively steady. That asynchrony IS the portfolio: local risk did not become regional risk because the coves were independent. This connects back to S7 (managed at the archipelago scale while the action is at the cove scale — the wrong scale) and sets up S9/S9b: when the coves SYNCHRONISE, the buffer collapses and local risk becomes regional risk. THIS is the slow tipping point: the "tip" is not a fast biomass crash in one year — it is the spatial portfolio being DRAWN DOWN, cove by cove, decade on decade, until the buffer is gone. A slow, structural loss, not a sudden flip into a new basin. Do not over-claim from a single metric — S9 carries the measured synchrony rise; this slide is the raw portfolio. Guardrail: m1_stier_11 per-section biomass scaled to each subpopulation’s own 1951–90 mean (log); 9 focal solid + 2 sparse dashed; not a fitted coefficient (claim-control sheet).');
}

/* S9 — synchrony / portfolio */ {
  const s=base(true); fullbleed(s,path.join(DA,'09_synchrony.png'));
  s.addNotes('Coves used to keep their own rhythm — a portfolio. Synchrony rose ~28% after the mid-1990s closure — pre-1994 mean 0.31 → post-1994 0.40 (the measured number ON THIS SLIDE; do NOT say ">60%" — that is a stale figure and the screen shows +28%). This is the mechanism of the SLOW tipping point: the buffer eroded gradually as the coves fell into step — a slow drawdown of structure, not a fast crash. Then offer the EWS reading as a PROPOSAL, not a finding — the leading-indicator analysis is not done.');
}

/* S9b — async→sync portfolio ANIMATION (video slide, after S9) */ {
  const s=base(true);
  s.addMedia({ type:'video', path:path.join(DA,'sim_anim_v2.mp4'),
    cover:'data:image/jpeg;base64,'+fs.readFileSync(path.join(DA,'sim_anim_v2_poster.jpg')).toString('base64'),
    x:0, y:0, w:W, h:H });
  s.addNotes('Animation (restyle of the 2020 Ecosphere sim_anim): subpopulations wander asynchronously and buffer the portfolio, then after the 1994 roe-fishery closure they synchronize and the buffering collapses. Illustrative simulation CALIBRATED to Haida Gwaii — 11 subpopulations, synchrony tuned to the real S9 metric (0.31→0.40). It demonstrates the mechanism behind S9; it is not the observed series. If the venue PC will not play the embedded MP4, skip to S9c/S10 (S9 already carries the measured result). ⏱️ DROP-ON-THE-DAY: this animation is skip-safe — if running long (or the clip stalls), advance straight past it; S9 carries the measured synchrony rise. Target ~20 min; S6 + S9b are the two designated cuts.');
}

/* S9c — BBC whale lunge-feed: PREFACES the S10 predator time series
   (Adrian 2026-05-19: place it right before the predator time series so
   it foreshadows the rising-predation pattern). Same BBC clip; on-screen
   BBC credit kept. */ {
  const s=base(true);
  s.addMedia({ type:'video', path:path.join(PH,'s09c_whale.mp4'),
    cover:'data:image/jpeg;base64,'+fs.readFileSync(path.join(PH,'s09c_whale_poster.jpg')).toString('base64'),
    x:0, y:0, w:W, h:H });
  s.addShape(p.ShapeType.rect,{x:0,y:0,w:W,h:0.78,fill:{color:'0E0E0E',transparency:28}});
  s.addShape(p.ShapeType.rect,{x:0,y:5.55,w:W,h:1.95,fill:{color:'0E0E0E',transparency:26}});
  s.addText('COUPLED TIPPING POINTS  |  PACIFIC HERRING  |  HAIDA GWAII',
    {x:0.6,y:0.28,w:12.2,h:0.34,fontFace:MONO,fontSize:13,color:C.rust,charSpacing:3});
  s.addText([{text:'The predators ',options:{}},
    {text:'came back.',options:{italic:true,color:C.rust}}],
    {x:0.6,y:5.95,w:12,h:0.8,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('From near-zero through the cull era to the single biggest draw on herring — the pattern is next.',
    {x:0.6,y:6.7,w:12,h:0.45,fontFace:HEAD,fontSize:16,italic:true,color:'D9D4CC'});
  s.addText("Footage: BBC — underwater humpback lunge-feeding on a herring ball.",
    {x:0.6,y:7.08,w:12.2,h:0.3,fontFace:MONO,fontSize:9,color:'BDB6AB'});
  s.addNotes('PREFACE to the S10 predator time series — play this immediately before S10 so the humpback lunge foreshadows the rising-predation pattern. ~8–12 s, few words: the predators came back — near-zero through the cull era, now the single biggest draw on herring — then cut to S10 where the time series lands the magnitude (S10b then gives the pressure: predators now remove ~a third of the standing stock each year). Ties back to S3.5 (the wasp-waist runs both ways). Play automatically + loop in PowerPoint; if the venue PC will not play the MP4, skip straight to S10 (S10 carries the measured result). Source: BBC underwater humpback footage (EEMB142C teaching deck, slide 18); BBC credited on-screen; Adrian handling rights.');
}

/* S10 — predators: recovery in two different oceans (concept D) */ {
  const s=base(true); fullbleed(s,path.join(DA,'10_predators.png'));
  s.addNotes('The key point: the SAME fishery shock, two different predator oceans. Rust = HG herring biomass (m1_stier_11 focal-9); blue = audited marine-mammal demand on herring (kt/yr), 1950–2025. At the 1968 collapse, marine-mammal demand was ≈0.2 kt — whales had been removed by a century of commercial whaling — and herring rebounded in ~5 yr. By the 1994 collapse and since, marine mammals have recovered (humpback + Steller sea lion dominate; ≈5.6 kt by 2020 and rising) and herring has not recovered in 30+ yr. Pre-1920 context (off the left of the axis): marine mammals took ~17 kt/yr before commercial whaling — the 1960s was the anomalously predator-free window. Honest framing: marine-mammal recovery is a conservation triumph AND one of several pressures now bearing on a drawn-down stock — NOT, on its own, the proven reason recovery has failed (the empty-1960s-ocean is context, not a causal claim; TEK 2nd hypothesis). Backup SB2 has the species breakdown; the predator-pressure magnitude is on S10b — talk-safe framing: predators now remove ~a third of the standing stock each year (≈15.5 kt/yr vs ≈47 kt, ≈29% removal analogue, predator_talk_brief.md). Do NOT use the old "≈239% of spawn" line — that was demand ÷ the DFO spawn INDEX, a survey index not the standing stock (reads as biologically impossible). Guardrail: predator demand is a LARGE ecological pressure, NOT a promoted/fitted m1_stier_11 coefficient (claim-control sheet).');
}

/* S10b — The predator pit (baked figure; after S10 two-oceans, before S10c).
   A different process now sets the ceiling: closure removed fishing but a
   recovered predator field now takes ~a third of the standing stock each
   year — consumptive lock-in / alternative stable state. (The old
   "≈239% of spawn" framing was REMOVED — that was demand ÷ the DFO spawn
   INDEX, not the standing stock, and read as biologically impossible.)
   GUARDRAIL is baked into the figure provenance + restated in notes:
   audited PRESSURE, not a fitted m1 coefficient; lock-in at hypothesis
   strength. */ {
  const s=base(true); fullbleed(s,path.join(DA,'10b_predator_pit.png'));
  s.addNotes('THE PREDATOR PIT — the mechanism behind S10’s “two oceans”. The argument: a DIFFERENT process now sets the ceiling. The 1994 closure removed fishing (~0-t HG catch since 2002), yet herring has not recovered — because the predator field recovered. Left panel: audited TOTAL predator demand on herring rose from a whaling-depleted mid-century (~0 kt, the 1960s predator-free window) to a large sustained draw now. The talk-safe pressure (predator_talk_brief.md): predators now take ≈15.5 kt/yr — about a third of the ≈47 kt standing m1_stier_11 stock, ≈29% removal analogue (2015–24). ⚠️ This is NOT the old "≈239% of spawn" line — that was demand ÷ the DFO spawn INDEX (a survey index, not the standing stock) and read as biologically impossible (you can’t eat 240% of the fish); it is removed deck-wide. Right panel: who eats it now — humpback (~4.96 kt) + Steller sea lion (~2.41 kt), the recovered marine mammals, lead (audited SB2 species means). The pit: a recovered predator field now removes about a third of a stock that never rebuilt — so removing the original stressor (fishing) is not, on its own, enough. Predation is ONE of several pressures holding it down (alongside the drawn-down portfolio and age-truncation) — NOT the proven cause. ⚠️ GUARDRAIL (loud, on-figure + here): this is AUDITED predator demand / a measured ecological PRESSURE, NOT a fitted m1_stier_11 natural-mortality coefficient; any consumptive lock-in is presented at HYPOTHESIS strength, one candidate among several, not an estimated mechanism (claim-control sheet). No new analysis — reuses the audited consumption budget already behind S10/SB2 + the talk-safe brief. Ties: back to S10 (two oceans) and S3.5 (the wasp-waist runs both ways); forward to S12/S12b (recovery is a moving target — the reference point assumes a predator field that no longer exists).');
}

/* S10d — Why recovery usually fails (NEW; SB6 cod schematic promoted into
   the spine, reworded to the ⑦ generalization: failed recovery is usually
   slow drawdown + lost structure, NOT necessarily a new stable environment
   or proven feedbacks). Baked figure shared with the SB6 backup. */ {
  const s=base(true); fullbleed(s,path.join(DA,'sb6_cod_vs_herring.png'));
  s.addNotes('THE TRANSFERABLE PAYOFF — generalize beyond Haida Gwaii. Cod (Newfoundland / North Sea) is the audience anchor: stressor removed, it came back. HG herring: stressor removed (fishing ~0-t since 2002), it has not. The honest reading — and the talk’s contribution to a tipping-points forum — is that failed recovery here and in many systems is USUALLY a slow drawdown of abundance and spatial structure that never rebuilds, NOT necessarily a jump into a new stable environment or a proven feedback lock-in. Bistability/regime-shift is ONE candidate among several (sustained drawdown, age-truncation, predator pressure, portfolio loss); we do not claim it (claim-control: post-closure non-recovery does not identify a single promoted mechanism). The practical consequence is the same regardless of which mechanism dominates: you cannot manage your way back to the old baseline by only removing the original stressor — you have to manage the slow drivers (where/how/at-what-age you take it) under uncertainty. Schematic (no fitted values). Leads into S11–S12 (judge against the system we have) and S12c/S12d (the fix).');
}

/* S11 — A system in a new state (native; title split to two clean lines) */ {
  const s=base(true); masthead(s,true);
  s.addText('A system drawn down',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('the triple bottom line, hit',
    {x:0.5,y:1.25,w:12.3,h:0.6,fontFace:HEAD,fontSize:28,italic:true,color:C.rust});
  // tighter top → body gap (was wasting ~120px of vertical space)
  // chip strings — parallel structure ("~YEAR · two-word phrase"), tight enough to fit one line
  // #19/#20: rewritten to the NEW-STATE thesis. Every on-slide number is
  // primary-source-grounded (Rebuilding Plan 2024 §5.2.3, DFO fish slips —
  // see S8_landed_value_provenance.md). NO unsourced "$40M→$2.78M".
  const col=[['Ecosystem',C.kelp,
      'The spatial portfolio was drawn down — diversity narrowed, synchrony up since the mid-1990s. Predators are now one pressure among several: recovered marine mammals take ~a third of the standing stock each year.',
      '~1993 · the drawdown'],
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
  caption(s,'~10% of historic = current m1_stier_11 + DFO SR 2025/005. “A new stable state” is one hypothesis of several (drawdown / age-truncation / predator pressure), not proven. Roe value/price = 2024 HG Herring Rebuilding Plan §5.2.3.',true);
  s.addNotes('A system DRAWN DOWN across all three bottom lines — NOT a proven new equilibrium; it is one read among several (sustained drawdown / age-truncation / predator pressure / portfolio loss), none established (claim-control: post-closure non-recovery does not identify a single promoted mechanism). ECOSYSTEM: portfolio drawn down (synchrony up since the mid-1990s; predators are ONE pressure among several — recovered marine mammals take ~a third of the standing stock each year — talk-safe: 2015–24 mean ≈15.5 kt/yr vs ≈47 kt m1_stier_11 stock, ≈29% removal analogue, predator_talk_brief.md — a measured PRESSURE, not a fitted m1_stier_11 coefficient. Do NOT say "≈239% of spawn" — removed deck-wide as misleading). PEOPLE: kʼaaw below the abundance it needs for the first time in ~10,000 yr; commercial sector lost its fishery (last HG roe fishery 2002 — Rebuilding Plan §5.2.3.5.2). ECONOMY: the roe MARKET collapsed, not just the stock — BC roe-herring landed value peaked in the 1980s, stayed high to the mid-1990s, then declined (1995–2005 and again post-2008; modest 2016–18 uptick); spawn-on-kelp real price peaked $62.88/lb in 1995 and is $11–14/lb recently (Rebuilding Plan §5.2.3.4.3, DFO fish slips) — set up in full on S3.6 (economics up front). On-slide claims = the Rebuilding-Plan price/value trajectory only. Decoupling timing in the chips: cultural ~1990 (slow erosion), ecological ~1993 (drawdown), economic ~2005 (fast market crash — the MARKET was fast even though the ecology was slow).');
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
  s.addText('THE STATE WE HAVE NOW',{x:nX+0.25,y:cY+0.2,w:cW-0.5,h:0.35,fontFace:MONO,fontSize:14,color:C.rust,charSpacing:2});
  s.addText('~10% of historic. The portfolio drawn down — synchrony up, diversity narrowed. DFO at the Limit Reference Point — ~0-t Haida Gwaii catch since 2002. Whether this is a new stable state is unresolved.',
    {x:nX+0.25,y:cY+0.65,w:cW-0.5,h:2.05,fontFace:BODY,fontSize:16,color:C.ink,lineSpacing:22});
  s.addText('judge recovery against the system we have — not the one we lost',
    {x:nX+0.25,y:cY+cH-0.85,w:cW-0.5,h:0.7,fontFace:HEAD,fontSize:15,italic:true,color:C.rust,valign:'middle'});
  takeaway(s,'Define recovery against the system we have, not the one we lost — and it means different things for harvest, culture, ecology, and economy.',true);
  caption(s,'~10% of historic = current m1_stier_11 + DFO SR 2025/005. “A new stable state” is one hypothesis, not established. Co-governance is an institutional milestone, not an outcome metric.',true);
  s.addNotes('The historical reference point — the pre-collapse, ~10,000-year baseline — is out of reach: the spatial portfolio was slowly drawn down (cove by cove, decade on decade) and has not rebuilt. The system now sits at ~10% of historic, portfolio drawn down, DFO at the LRP with ~0-t HG catch since 2002. WHETHER this is a new stable equilibrium is unresolved — one hypothesis among sustained drawdown / age-truncation / predator pressure (claim-control: post-closure non-recovery does not identify a single promoted mechanism; do NOT assert bistability). The defensible point stands either way: judge recovery against the system we HAVE, not the one we lost — and "recovery" means different things for harvest, culture, ecology, economy. Claim guard: ~10% cites m1_stier_11 + DFO SR 2025/005; co-governance is an institutional milestone, not an outcome metric.');
}

/* S12b — The reference-point problem (the concrete fix) */ {
  const s=base(true); masthead(s,true);
  s.addText('The reference point is the wrong target',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('you can’t recover to a baseline the system has left',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  s.addText('DFO’s Limit Reference Point is anchored to a historical unfished-biomass baseline. Once abundance and spatial structure are drawn down and do not retrace — whatever the mechanism — the system cannot return there, so the stock is “below LRP” almost by construction, whatever managers do.',
    {x:0.6,y:2.0,w:12.1,h:1.25,fontFace:BODY,fontSize:18,color:C.ink,lineSpacing:26});
  s.addShape(p.ShapeType.rect,{x:0.5,y:3.5,w:0.06,h:1.05,fill:{color:C.amber}});
  s.addText([{text:'Even with ZERO Haida Gwaii catch since 2002, P(SB₂₀₂₅ < LRP) = 0.38.\n',options:{bold:true,color:C.amber}},
    {text:'Not fishing is not enough — the yardstick itself is the problem.',options:{italic:true}}],
    {x:0.7,y:3.45,w:12.0,h:1.15,fontFace:HEAD,fontSize:18,color:C.ink,valign:'middle'});
  s.addText('The fix: reference points conditioned on the system we have — ecosystem-state-dependent and dynamic — with recovery judged against the achievable equilibrium and expectations reset across ecology, culture and economy.',
    {x:0.6,y:4.85,w:12.1,h:1.3,fontFace:BODY,fontSize:17,color:C.soft,lineSpacing:24});
  caption(s,'P(SB<LRP) = DFO SR 2025/005 (Cleary), HG aggregate SCA. ~10% of historic = m1_stier_11 + DFO SR 2025/005; “a new stable state” is one hypothesis, not established. Co-governance = institutional milestone, not an outcome metric.',true);
  s.addNotes('THE CONCRETE FIX — the punchline. DFO’s LRP is tied to a historical SB0-based baseline the regime-shifted system can’t return to: “below LRP” by construction. Killer stat (DFO’s own, SR 2025/005, Cleary): even at ZERO HG catch since 2002, P(SB2025 < LRP) = 0.38 — not fishing is not enough; the reference point, not just the stock, is the problem. Prescribe: dynamic / ecosystem-conditioned reference points; judge recovery against the achievable new equilibrium; reset expectations across the triple bottom line; negotiate “recovery” through co-governance. Claim-safe: DFO summaries are public context, not likelihood validation of m1; co-governance is an institutional milestone, not an outcome metric.');
}

/* S12c — The solution: allocate the portfolio (Okamoto et al. 2020) */ {
  const s=base(true); masthead(s,true);
  s.addText('Allocate the portfolio',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('manage at the cove scale — split the herring three ways',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  const ok=[['Industry',C.rust,'A commercial share set by dynamically-optimised, cove-scale harvest — not one archipelago quota. Okamoto et al. show this minimises local collapse risk without sacrificing yield.'],
    ['Haida',C.plum,'An explicit kʼaaw / food-social-ceremonial allocation — the cultural keystone, negotiated through co-governance, not a residual.'],
    ['Ecosystem',C.kelp,'A predator share — herring left in the water for the marine mammals and commercial fishes (salmon, halibut, cod) the wasp-waist feeds.']];
  ok.forEach((c,i)=>{ const x=0.5+i*4.2;
    s.addShape(p.ShapeType.rect,{x,y:2.05,w:3.95,h:0.05,fill:{color:c[1]}});
    s.addText(c[0].toUpperCase(),{x,y:2.18,w:3.95,h:0.35,fontFace:MONO,fontSize:14,color:c[1],charSpacing:2});
    s.addText(c[2],{x,y:2.65,w:3.95,h:2.55,fontFace:BODY,fontSize:15,color:C.ink,lineSpacing:21}); });
  // ⑥ Shelton stage-at-harvest lever — change WHAT LIFE-STAGE you take.
  // CLAIM-CONTROL (docs/sok-vs-sacroe-quota-accounting.md): principle, NOT
  // tactic — do NOT imply "loosen SOK"; the asymmetry is strategic.
  s.addShape(p.ShapeType.rect,{x:0.5,y:5.45,w:0.06,h:0.66,fill:{color:C.amber}});
  s.addText([{text:'And change ',options:{}},{text:'what life-stage',options:{italic:true}},
    {text:' you take: a sac-roe fishery kills fish the instant before they spawn; an egg (kʼaaw / SOK) harvest does not. Shelton et al. 2014 — eggs can bear a higher sustainable rate than the lethal fishery. A policy lever, not a number.',options:{}}],
    {x:0.7,y:5.40,w:12.1,h:0.76,fontFace:HEAD,fontSize:15,color:C.ink,valign:'middle'});
  takeaway(s,'Allocate the portfolio AND rethink what life-stage we take — nested-scale harvest plus a lower-impact egg fishery. The solution is policy, not a single number.',true);
  caption(s,'Allocation: Okamoto, Hessing-Lewis, Samhouri, Shelton, Stier, Levin & Salomon 2020, Ecol. Appl. · Egg-vs-adult harvest asymmetry: Shelton, Samhouri, Stier & Levin 2014, Sci. Rep. 4:7110.',true);
  s.addNotes('THE SOLUTION (chair wants solutions-forward) — two policy levers, not biology. (1) WHERE/HOW MUCH: Okamoto et al. 2020 (Ecol Appl — Adrian co-author; the published basis for the scale-mismatch analysis) — dynamically optimising harvest at nested scales minimises local collapse risk WITHOUT sacrificing yield; allocate across the triple bottom line: industry (cove-scale dynamic commercial share), Haida (an explicit kʼaaw/FSC allocation via co-governance), ecosystem (herring left for marine-mammal + commercial-fish predators — the wasp-waist; ties to S3.5/S10). (2) WHAT LIFE-STAGE: Shelton, Samhouri, Stier & Levin 2014 (Sci Rep 4:7110 — Adrian co-author) show an ASYMMETRY: stocks tolerate egg-harvest ~h_egg 0.7–0.9 vs lethal ~h_adult 0.5, because the sac-roe fishery kills mature fish the instant before spawning (forfeiting that year’s whole egg contribution) and Beverton–Holt recruitment buffers egg removal. ⚠️ CLAIM-CONTROL (docs/sok-vs-sacroe-quota-accounting.md — Adrian-flagged): say the PRINCIPLE only — an egg fishery can sustainably bear a higher rate than an equivalent lethal one, so a flat shared-biomass conversion is biologically conservative against SOK. Do NOT say "therefore loosen/raise SOK" — Shelton is STRATEGIC not tactical; the safe zone collapses under recruitment variability, exactly where depressed low-productivity stocks like HG sit (rising M, persistent low state); it is a single well-mixed model with NO spatial portfolio (a coastwide "eggs are safe" can locally over-harvest a structured stock — the central HG lesson); eggs are ALSO an ecosystem subsidy (predator food); DFO already applies strong precaution (10% max HR, oSOK/cSOK/SR split, ponding-mortality charge). HG itself is FSC kʼaaw only (no commercial fishery since 2002/2004) — this is a GENERAL policy principle, not "do more SOK at HG". Shelton provides NO conversion factor (treaty Operational Guidelines, not in repo). Leads into S12d (who governs these levers) and S13 (general lessons; do not duplicate).');
}

/* S12d — Who governs it: the social–ecological system (NEW; ⑤). Multi-party
   co-management. CLAIM-CONTROL: co-governance = an institutional milestone,
   NOT an outcome metric (HG still below LRP, ~0-t catch — DFO SR 2025/005). */ {
  const s=base(true); masthead(s,true);
  s.addText('Who governs it',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('a social–ecological system, co-managed',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  const gov=[['Haida Nation',C.plum,'Title & rights holder. kʼaaw / FSC priority (Sparrow). Co-author of the 2024 HG Herring Rebuilding Plan. Athlii Gwaii → Gwaii Haanas → AMB lineage.'],
    ['DFO · Canada',C.marine,'Federal fisheries lead: stock assessment, reference points (LRP / USR), the harvest control rule (HS30-100, 10% max HR), the IFMP.'],
    ['British Columbia',C.kelp,'Provincial coastal & marine-planning partner; the land–sea and reconciliation context around the fishery.'],
    ['Parks Canada',C.amber,'Gwaii Haanas co-management with CHN (Archipelago Management Board) — marine protection where the herring spawn.']];
  gov.forEach((c,i)=>{ const x=0.5+i*3.15;
    s.addShape(p.ShapeType.rect,{x,y:2.05,w:2.95,h:0.05,fill:{color:c[1]}});
    s.addText(c[0].toUpperCase(),{x,y:2.18,w:2.95,h:0.6,fontFace:MONO,fontSize:13,color:c[1],charSpacing:1,lineSpacing:15});
    s.addText(c[2],{x,y:2.95,w:2.95,h:2.6,fontFace:BODY,fontSize:14,color:C.ink,lineSpacing:19}); });
  takeaway(s,'The levers are not one agency’s to pull — they are negotiated across nations and governments. The 2024 Rebuilding Plan is the institution; recovery is still the open question.',true);
  caption(s,'2024 HG Herring Rebuilding Plan = CHN · DFO · Parks Canada. Co-governance is an institutional milestone, not an outcome metric (HG still below LRP, ~0-t catch — DFO SR 2025/005).',true);
  s.addNotes('WHO pulls the levers from S12c — the social–ecological system. The HG herring system is co-managed across the Haida Nation (title & rights holder; kʼaaw/FSC priority after conservation per Sparrow 1990; co-author of the 2024 Rebuilding Plan; the Athlii Gwaii 1985 → Gwaii Haanas 1993 → Archipelago Management Board lineage), DFO/Canada (federal fisheries: assessment, reference points, the HS30-100 harvest control rule with a 10% max HR, the IFMP), British Columbia (provincial coastal/marine-planning + reconciliation context — a lighter, non-fisheries-lead role; state it modestly), and Parks Canada (Gwaii Haanas co-management with CHN via the AMB — marine protection over spawning habitat). The point: allocation, what-life-stage, and at-what-scale are negotiated decisions across nations and agencies, not one regulator’s. ⚠️ CLAIM-CONTROL: co-governance is an INSTITUTIONAL MILESTONE, NOT an outcome metric — the 2024 Rebuilding Plan existing does not mean the stock recovered (HG still below the LRP, ~0-t catch — DFO SR 2025/005). Do not present governance as a result. Source: docs/sok-vs-sacroe-quota-accounting.md; 2024 HG Herring Rebuilding Plan (CHN/DFO/Parks Canada); claim-control sheet. Leads into S13 (transferable lessons).');
}

/* S13 — Three transferable lessons (native; title split to two clean lines) */ {
  const s=base(true); masthead(s,true);
  s.addText('Three transferable lessons',
    {x:0.5,y:0.7,w:12.3,h:0.7,fontFace:HEAD,fontSize:34,bold:true,color:C.ink});
  s.addText('what this case teaches',
    {x:0.5,y:1.25,w:12.3,h:0.55,fontFace:HEAD,fontSize:24,italic:true,color:C.rust});
  const t=[['1','Match management scale to biological scale.','Herring spawn, fleets seine, and whales feed at the cove scale. Manage there — finer-scale escapement costs more but preserves the portfolio, and the portfolio is the resilience.'],
    ['2','Manage the ecosystem, not the stock.','Predators are now a major draw on herring — a quota set as if they are not there is a fiction. Integrate species interactions and the spatial portfolio, not coastwide biomass alone.'],
    ['3','Condition reference points on the current state.','A target pinned to a historical baseline misleads once abundance and structure have been drawn down and do not retrace — whatever the mechanism. Judge recovery against the state that is achievable, not the one that was lost.']];
  // numerals now vertically aligned with the headline (not the paragraph centerline)
  t.forEach((r,i)=>{ const y=2.15+i*1.30;
    s.addText(r[0],{x:0.5,y:y-0.05,w:0.8,h:0.7,fontFace:HEAD,fontSize:42,bold:true,color:C.rust,valign:'top'});
    s.addText(r[1],{x:1.35,y,w:11.4,h:0.5,fontFace:HEAD,fontSize:20,bold:true,color:C.ink});
    s.addText(r[2],{x:1.35,y:y+0.5,w:11.4,h:0.75,fontFace:BODY,fontSize:15,color:C.soft,lineSpacing:20}); });
  s.addShape(p.ShapeType.rect,{x:0.5,y:6.15,w:0.06,h:0.85,fill:{color:C.amber}});
  // separated the rust prefix from the italic continuation with a line break
  s.addText([{text:'One thread we are testing — a proposal, not a result:\n',options:{bold:true,color:C.amber}},
    {text:'the early-warning signal here may be spatial — observation scale decides what anyone can see.',options:{italic:true}}],
    {x:0.7,y:6.1,w:12.1,h:0.95,fontFace:HEAD,fontSize:14,color:C.soft,valign:'middle'});
  s.addNotes('Deliver the three crisply. Do not add a fourth. These are the GENERAL transferable lessons; they do NOT repeat S12c/S12d (the specific HOW — allocate the portfolio + change what life-stage you take, governed across the SES). Lesson 3 is deliberately mechanism-agnostic in the A spine: a historical reference point misleads once abundance and structure are drawn down and do not retrace — WHATEVER the mechanism (slow drawdown / age-truncation / predator pressure / a true regime shift) — so we do not assert hysteresis/bistability (claim-control). The unifying stance: manage exposure and scale UNDER UNCERTAINTY; do not wait for a single solved mechanism. The amber footer is the distinct spatial-EWS proposal, hypothesis strength (a finding is not claimed). Transition: "let me close."');
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
  s.addText('The economy, how we extract, and the ecosystem all shifted — herring was drawn down, not flipped. The old reference points no longer fit; it is the centre of the food web, and recovering it is a policy choice, not a number.',
    {x:0.6,y:5.62,w:12,h:0.98,fontFace:HEAD,fontSize:17,italic:true,color:'E8E3DA',lineSpacing:24});
  s.addText('Thank you.',
    {x:0.6,y:6.62,w:12,h:0.4,fontFace:HEAD,fontSize:19,bold:true,color:'E8E3DA'});
  s.addText('With gratitude to the Haida Nation and collaborators.',
    {x:0.6,y:7.05,w:12,h:0.38,fontFace:HEAD,fontSize:13,italic:true,color:'BDB6AB'});
  s.addNotes('Slow down. A century of change — the economy and how people engaged (S3.6), how we extract, and the ecosystem itself all shifted. The honest spine: herring was slowly DRAWN DOWN, not flipped into a proven new state — so the old reference points and expectations no longer fit (lands the S12/S12b punchline). Recovery is a moving target; herring is the centre of the food web (ties back to S3.5/the HG food-web diagram), and recovering it is a POLICY choice — allocation, what life-stage, governed across the SES (S12c/S12d) — not a single number. "A century of change — recalibrate what herring is. Thank you." Stop.');
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
