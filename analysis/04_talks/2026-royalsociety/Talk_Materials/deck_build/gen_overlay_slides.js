// Generates the photo + placeholder slide HTML (S1,S2,S3,S4,S10,S14) in the
// deck visual language. Text is baked into the rendered PNG (no live fonts on
// the venue PC). 3840x2160, 16:9, zero stretch (photos cover-cropped centred;
// placeholders are branded). Per deck_design_system.md.
const fs = require('fs'), path = require('path');
const OUT = path.join(__dirname, 'slides_html');
fs.mkdirSync(OUT, { recursive: true });

const FONTS = `<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Crimson+Pro:ital,wght@0,400;0,600;0,700;1,400&family=IBM+Plex+Sans:wght@300;400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet">`;
const BASE = `*{margin:0;box-sizing:border-box}html,body{width:3840px;height:2160px;overflow:hidden}
body{font-family:"IBM Plex Sans",sans-serif;background:#0e0e0e;color:#f0eee9;position:relative}
.kick{position:absolute;top:96px;left:140px;font-family:"IBM Plex Mono",monospace;font-size:34px;letter-spacing:.18em;text-transform:uppercase;color:#d9714f;z-index:3}
.bg{position:absolute;inset:0;background-size:cover;background-position:center;z-index:0}
.scrim{position:absolute;inset:0;z-index:1}
.wrap{position:absolute;z-index:2}`;

// photo slide: full-bleed cover image + scrim + title block lower-third
function photo(file, img, opts) {
  const o = opts || {};
  const scrim = o.scrim || 'linear-gradient(180deg,rgba(14,14,14,.30) 0%,rgba(14,14,14,.05) 38%,rgba(14,14,14,.78) 100%)';
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8">${FONTS}<style>${BASE}
  .bg{background-image:url("photos/${img}")}
  .scrim{background:${scrim}}
  .title{bottom:200px;left:140px;right:300px}
  h1{font-family:"Crimson Pro",serif;font-weight:600;font-size:150px;line-height:1.05}
  h1 .a{font-style:italic;color:#e08a5f}
  .sub{font-family:"Crimson Pro",serif;font-size:62px;color:#d9d4cc;margin-top:26px;line-height:1.3}
  .credit{position:absolute;bottom:70px;right:140px;font-family:"IBM Plex Mono",monospace;font-size:30px;color:#bdb6ab;z-index:3}
  .kicker2{position:absolute;bottom:120px;left:140px;font-family:"IBM Plex Mono",monospace;font-size:40px;letter-spacing:.12em;color:#cfa055;z-index:3}
  </style></head><body>
  <div class="bg"></div><div class="scrim"></div>
  <div class="kick">Coupled tipping points | Pacific herring | Haida Gwaii</div>
  ${o.title ? `<div class="wrap title"><h1>${o.title}</h1>${o.sub ? `<div class="sub">${o.sub}</div>` : ''}</div>` : ''}
  ${o.kicker ? `<div class="kicker2">${o.kicker}</div>` : ''}
  ${o.credit ? `<div class="credit">${o.credit}</div>` : ''}
  </body></html>`;
  fs.writeFileSync(path.join(OUT, file), html);
}

// branded placeholder/callout slide (light) — for assets to be dropped in
function placeholder(file, o) {
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8">${FONTS}<style>${BASE}
  body{background:#fbfaf7;color:#1c1916}
  .kick{color:#8b3a23}
  .wrap{top:300px;left:140px;right:140px}
  h1{font-family:"Crimson Pro",serif;font-weight:600;font-size:140px;color:#1c1916;line-height:1.05;margin-bottom:40px}
  h1 .a{font-style:italic;color:#8b3a23}
  .calls{display:flex;gap:60px;flex-wrap:wrap;margin:50px 0}
  .c{font-family:"Crimson Pro",serif}
  .c b{display:block;font-size:118px;font-weight:700;color:#8b3a23;line-height:1}
  .c span{font-size:42px;color:#6f6860}
  .slot{margin-top:60px;border:4px dashed #b85042;border-radius:14px;height:680px;
    display:flex;align-items:center;justify-content:center;color:#b85042;
    font-family:"IBM Plex Mono",monospace;font-size:46px;text-align:center;padding:40px;background:#f5efe9}
  .take{position:absolute;bottom:150px;left:140px;right:140px;font-family:"Crimson Pro",serif;
    font-size:60px;border-left:8px solid #a07028;padding-left:34px;line-height:1.35}
  .src{position:absolute;bottom:60px;left:140px;right:140px;font-family:"IBM Plex Mono",monospace;
    font-size:26px;color:#6f6860;border-left:6px solid #8b3a23;padding-left:20px;line-height:1.4}
  </style></head><body>
  <div class="kick">Coupled tipping points | Pacific herring | Haida Gwaii</div>
  <div class="wrap"><h1>${o.title}</h1>
  ${o.calls ? `<div class="calls">${o.calls.map(c => `<div class="c"><b>${c[0]}</b><span>${c[1]}</span></div>`).join('')}</div>` : ''}
  <div class="slot">${o.slot}</div></div>
  ${o.take ? `<div class="take">${o.take}</div>` : ''}
  ${o.src ? `<div class="src">${o.src}</div>` : ''}
  </body></html>`;
  fs.writeFileSync(path.join(OUT, file), html);
}

// dark placeholder (S10 predators)
function darkPlaceholder(file, o) {
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8">${FONTS}<style>${BASE}
  .wrap{top:300px;left:140px;right:140px}
  h1{font-family:"Crimson Pro",serif;font-weight:600;font-size:140px;line-height:1.05;margin-bottom:30px}
  h1 .a{font-style:italic;color:#e08a5f}
  .slot{margin-top:40px;border:4px dashed #6e9bc4;border-radius:14px;height:1080px;
    display:flex;align-items:center;justify-content:center;color:#6e9bc4;
    font-family:"IBM Plex Mono",monospace;font-size:46px;text-align:center;padding:50px;line-height:1.5;background:#13161c}
  .take{position:absolute;bottom:150px;left:140px;right:140px;font-family:"Crimson Pro",serif;
    font-size:60px;border-left:8px solid #cfa055;padding-left:34px;line-height:1.35;color:#f0eee9}
  .src{position:absolute;bottom:56px;left:140px;right:140px;font-family:"IBM Plex Mono",monospace;
    font-size:26px;color:#a8a59f;border-left:6px solid #d9714f;padding-left:20px;line-height:1.4}
  </style></head><body>
  <div class="kick">Coupled tipping points | Pacific herring | Haida Gwaii</div>
  <div class="wrap"><h1>${o.title}</h1><div class="slot">${o.slot}</div></div>
  <div class="take">${o.take}</div><div class="src">${o.src}</div>
  </body></html>`;
  fs.writeFileSync(path.join(OUT, file), html);
}

photo('s01.html', 's01_title.png', {
  title: 'Coupled Tipping Points in<br><span class="a">Pacific Herring</span> &amp; Haida Gwaii',
  sub: 'Ecological tipping points and ecosystem-service tipping points are not the same event — the gap is where management acts.',
  credit: 'Adrian Stier · UC Santa Barbara · US–UK Forum · Session 5 · 20 May 2026' });
photo('s02.html', 's02_shore.jpg', { kicker: '~10,000 years ago',
  scrim: 'linear-gradient(180deg,rgba(14,14,14,.25),rgba(14,14,14,.15) 50%,rgba(14,14,14,.55))' });
photo('s03.html', 's03_people.jpg', {
  title: 'The people and the fish',
  sub: 'Haida kʼaaw — roe-on-branch, a cultural keystone for 10,000+ years',
  credit: 'Photo: A. Salomon · used with permission · Council of the Haida Nation' });
photo('s14.html', 's14_close.png', {
  title: 'The herring is the example.<br><span class="a">The lesson is about thresholds.</span>',
  sub: 'Thank you. — With gratitude to the Haida Nation and collaborators.',
  scrim: 'linear-gradient(180deg,rgba(14,14,14,.35),rgba(14,14,14,.15) 40%,rgba(14,14,14,.82))' });

placeholder('s04.html', {
  title: 'The baseline, <span class="a">measured</span>',
  calls: [['171', 'archaeological sites'], ['435,777', 'identified fish bones'],
          ['49%', 'of all fish — herring'], ['99%', 'site ubiquity'], ['<±10%', 'variance over ~10,700 yr']],
  slot: 'DROP FIGURE: McKechnie et al. 2014 (PNAS) — site map or NISP proportions.<br>Crop from Literature/McKechnie_et_al_2014_PNAS_Archaeological_Herring.pdf.<br>(Verify callouts vs the PDF text before final.)',
  take: 'A ten-thousand-year measurement of natural variability. Everything next is a departure from it.',
  src: 'Source: McKechnie et al. 2014, PNAS. Numbers verify against the PDF text. Accessible-image alt (credit-gated): Mongabay 2014 "By the bones".' });

darkPlaceholder('s10.html', {
  title: 'The predators <span class="a">came back</span>',
  slot: 'DROP: humpback-feeding video / still (Adrian sourcing) + inset: marine-mammal recovery figure\n(/Users/adrianstier/pacific-herring-predators/Output/figures/century_scale_predator_field.pdf)',
  take: 'A conservation win became a driver — species interactions can’t be managed around.',
  src: 'Predator demand is a large ecological pressure; NOT a promoted HG causal coefficient (claim-control sheet). Recovery figure pulled from the sibling predator repo by reference.' });

console.log('overlay slides written to', OUT);
