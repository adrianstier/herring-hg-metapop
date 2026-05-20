#!/usr/bin/env python3
"""
Preprocess figure PNGs for the Royal Society herring deck — v3.

v3 (responding to graphic-design critique):
  - amber-rule takeaway strip baked into every figure slide bottom — fixes the
    missing-takeaway critique on S5/S6/S8/S9/S10
  - bottom provenance / source line under the takeaway strip
  - S9 line color shifted from plum to kelp (ecological track contract)
  - top chrome band stays the same: rust mono masthead + bold serif title

Canvas: 3840×2160. Chrome:
  band_top   ≈ 280 px → masthead + title
  zone       ≈ 1500 px → figure (stretched to width, no letterbox)
  band_bot   ≈ 380 px → amber-rule takeaway + provenance line
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# Portable: <repo>/analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/preprocess_figures.py
DA = Path(__file__).resolve().parents[1] / "deck_assets"
ORIG = DA / "_originals"

W, H = 3840, 2160
BG = (14, 14, 14)
INK = (240, 238, 233)
SOFT = (168, 165, 159)
RUST = (217, 113, 79)
AMBER = (207, 160, 85)
KELP = (138, 160, 116)
PLUM = (182, 133, 168)

BAND_TOP = 280
BAND_BOT = 380
ZONE_H = H - BAND_TOP - BAND_BOT          # 1500
TITLE_Y = 110
MAST_Y = 38
TAKEAWAY_RULE_Y = H - BAND_BOT + 50       # y of the amber rule
TAKEAWAY_TEXT_Y = TAKEAWAY_RULE_Y + 22
PROV_Y = H - 80                            # provenance row near bottom

def _pick(*cands):
    for c in cands:
        if Path(c).is_file():
            return c
    return cands[-1]

_LIB = "/usr/share/fonts/truetype/liberation"
_MAC = "/System/Library/Fonts/Supplemental"
SERIF_BOLD        = _pick(f"{_LIB}/LiberationSerif-Bold.ttf",       f"{_MAC}/Georgia Bold.ttf")
SERIF_BOLD_ITALIC = _pick(f"{_LIB}/LiberationSerif-BoldItalic.ttf", f"{_MAC}/Georgia Bold Italic.ttf")
SERIF_ITALIC      = _pick(f"{_LIB}/LiberationSerif-Italic.ttf",     f"{_MAC}/Georgia Italic.ttf")
SERIF             = _pick(f"{_LIB}/LiberationSerif-Regular.ttf",    f"{_MAC}/Georgia.ttf")
MONO              = _pick("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
                          f"{_MAC}/Courier New.ttf")

def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()

def tw(d, t, f):
    return d.textbbox((0, 0), t, font=f)[2]

def recolor_line(fig: Image.Image, frm: tuple, to: tuple, tol: int = 50) -> Image.Image:
    """Replace pixels close to `frm` with `to`. Used to fix S9 plum→kelp."""
    fig = fig.convert("RGB")
    px = fig.load()
    w, h = fig.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if (abs(r - frm[0]) < tol and abs(g - frm[1]) < tol and abs(b - frm[2]) < tol):
                px[x, y] = to
    return fig

def bake(figure_path: Path, out_path: Path, title_plain: str, title_italic: str,
         takeaway: str = "", takeaway2: str = "", provenance: str = "", recolor=None):
    """Compose top chrome, stretched figure, bottom amber-rule takeaway + provenance.

    If takeaway2 is provided, it is rendered as a second indented line below takeaway,
    sharing the same amber left-rule (rule height auto-expands to 110 px).
    """
    fig = Image.open(figure_path).convert("RGB")
    if recolor is not None:
        fig = recolor_line(fig, recolor[0], recolor[1], recolor[2])

    canvas = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(canvas)

    # masthead (rust mono kicker)
    d.text((144, MAST_Y), "COUPLED TIPPING POINTS   |   PACIFIC HERRING   |   HAIDA GWAII",
           fill=RUST, font=font(MONO, 38))

    # title — plain white + italic rust accent
    title_font = font(SERIF_BOLD, 120)
    title_it_font = font(SERIF_BOLD_ITALIC, 120)
    x = 144
    if title_plain:
        d.text((x, TITLE_Y), title_plain, fill=INK, font=title_font)
        x += tw(d, title_plain, title_font)
    if title_italic:
        d.text((x, TITLE_Y), title_italic, fill=RUST, font=title_it_font)

    # Fit the figure into the content zone PRESERVING ASPECT RATIO.
    # Sources are rendered at exactly 3840×1500 (= W × ZONE_H) so this is a
    # no-op for them; the guard exists so a 16:9 (3840×2160) source can never
    # again be vertically squished into 1500 px (the old "stretched text /
    # funky y-axis" bug on S5/S6/S7).
    fw, fh = fig.size
    sc = min(W / fw, ZONE_H / fh)
    nw, nh = int(round(fw * sc)), int(round(fh * sc))
    if (nw, nh) != (fw, fh):
        fig = fig.resize((nw, nh), Image.LANCZOS)
    canvas.paste(fig, ((W - nw) // 2, BAND_TOP + (ZONE_H - nh) // 2))

    # amber takeaway rule + text (supports optional second line via takeaway2)
    if takeaway:
        tk_font = font(SERIF_ITALIC, 52)
        # amber left-rule: taller when two lines present
        rule_h = 110 if takeaway2 else 80
        d.rectangle([144, TAKEAWAY_RULE_Y, 152, TAKEAWAY_RULE_Y + rule_h], fill=AMBER)
        # line 1
        d.text((180, TAKEAWAY_RULE_Y + 8), takeaway, fill=INK, font=tk_font)
        if takeaway2:
            # line 2: slightly dimmer (SOFT) so line 1 reads as lead; indented to align
            bbox = d.textbbox((0, 0), "Ag", font=tk_font)
            line_h = bbox[3] - bbox[1]
            d.text((180, TAKEAWAY_RULE_Y + 8 + line_h + 6), takeaway2, fill=SOFT, font=tk_font)

    # provenance line
    if provenance:
        d.text((144, PROV_Y), provenance, fill=SOFT, font=font(MONO, 26))

    canvas.save(out_path, "PNG", optimize=True)
    print(f"wrote {out_path.name}")

# Per-slide content
JOBS = [
    dict(src="05_two_collapses.png",
         title_plain="Two collapses, ", title_italic="two outcomes",
         takeaway="The 1960s collapse rebounded to the historic level in ~5 yr; after 1994 it has stayed well below it.",
         provenance="m1_stier_11 estimated total HG biomass, focal-9, 1951–2025 (median + 80% CI). Recent years weakly constrained — terminal CI runs off-chart. Historic level = m1 1951–65 mean (NOT the DFO spawning-biomass LRP — different quantity, see DFO backup)."),
    dict(src="06_climate_pdo.png",
         title_plain="Ocean productivity matters — ", title_italic="but it isn't the barrier",
         takeaway="Cool, productive years drove the 1960s rebound; after 1994 they did not — a partial uptick, still below historic.",
         provenance="PDO index + m1_stier_11 estimated biomass (focal-9, median + 80% CI), same series as S5. Climate is necessary, not sufficient — not the barrier to recovery. Recent estimate weakly constrained."),
    dict(src="07_two_scales.png",
         title_plain="Fishing pressure — ", title_italic="the average hid the extremes",
         takeaway="Cove rate up to ~50% while archipelago-wide stayed near ~3%.",
         provenance="Updated Stier et al. 2020 method, catch matrix extended to 2025 — scale-mismatch result, not m1_stier_11."),
    dict(src="08_realized_growth.png",
         title_plain="Population growth collapsed, ", title_italic="cove by cove",
         takeaway="9 of 11 sections declined post-1994 — system-wide, invisible at the aggregate.",
         provenance="m1_stier_11 per-section mean realized growth, all 11 sections (Tasu Sound & Naden Harbour flagged sparse, not hidden)."),
    dict(src="08b_subpop_portfolio.png",
         title_plain="Local coves, ", title_italic="one region",
         takeaway="Each cove ran its own cycle — that local spread is what kept the Haida Gwaii region steady.",
         provenance="m1_stier_11 per-section biomass, each scaled to its own 1951–90 mean (log); 11 subpopulations (9 focal + 2 sparse). Local-vs-region scale mismatch — not a fitted coefficient."),
    dict(src="09_synchrony.png",
         title_plain="The portfolio ", title_italic="eroded",
         takeaway="Subpopulation synchrony rose after the 1994 closure — the portfolio eroded.",
         provenance="m1_stier_11 + Stier 2020. Loreau & de Mazancourt index, 10-yr rolling window."),
    dict(src="10_predators.png",
         title_plain="Recovery in ", title_italic="two different oceans",
         takeaway="The 1960s collapse rebounded with the whales gone; today's non-recovery sits under a recovered marine-mammal field.",
         provenance="m1_stier_11 focal-9 biomass + audited HG marine-mammal demand (Stier-Lab synthesis, 5-yr running mean); x≥1950 (pre-1920 mammal demand ~17 kt). A pressure, not a fitted m1_stier_11 coefficient."),
    dict(src="10b_predator_pit.png",
         title_plain="The predator pit — ", title_italic="a different ceiling",
         takeaway="Closure removed fishing, but a recovered predator field now takes ~a third of the standing stock every year — the low state is held in place.",
         provenance="Audited Stier-Lab predator synthesis; predator_talk_brief.md talk-safe claim: 2015–24 mean ≈15.5 kt/yr taken vs ≈47 kt m1_stier_11 stock (≈29% removal analogue). A measured PRESSURE, NOT a fitted m1_stier_11 mortality coefficient — lock-in at hypothesis strength."),
    dict(src="dfo_spawning_biomass.png",
         title_plain="Spawning biomass at the ", title_italic="limit reference point",
         takeaway="SB2024 ≈ LRP — P(SB2024 < LRP) = 0.52: a coin-flip from the critical zone after 24 yr of zero catch.",
         takeaway2="P(SB2025 < LRP) = 0.38 even at zero fishing (forward projection, DFO SR 2025/005).",
         provenance="Cleary / DFO SR 2025/005 Fig 8(d); SB2024 median = 6,415 t, LRP = 6,452 t (0.3×SB0); 2025 forecast Table 19 (exact)."),
    dict(src="12_decoupling.png",
         title_plain="Four layers, ", title_italic="four clocks",
         takeaway="Three layers fall, one rises — the horizontal gap is the management window.",
         provenance="Anchored to cited sources. Co-governance = institutional milestones, not an outcome metric (HG still below LRP, 0-t catch — DFO SR 2025/005)."),

    # ===== Supplementary / Q&A backup figures =====
    dict(src="sb1_portfolio_periods.png",
         title_plain="Portfolio metrics across ", title_italic="six management eras",
         takeaway="Effective sections fell from ~3.7 to ~3.3 while the top-3 share rose to 84%.",
         provenance="m1_stier_11 portfolio_period_summary (all-11 fitted sections). Simpson and entropy effective sections agree on direction."),
    dict(src="sb2_predator_species.png",
         title_plain="Predator demand ", title_italic="by species",
         takeaway="Humpback whale leads (~5 kt/yr); top-12 spans mammals, fish, salmon.",
         provenance="Audited Stier Lab predator synthesis (24 species). Mean of recent years where each species was estimable."),
    dict(src="sb3_climate_blob.png",
         title_plain="The 2014–2016 ", title_italic="marine heatwave context",
         takeaway="PDO does not explain non-recovery — recovery failed before and after the Blob.",
         provenance="Annual PDO index 1951–2024. The Blob is a useful stress-test period, not a promoted HG-non-recovery explanation."),
    dict(src="sb4_dfo_vs_m1.png",
         title_plain="Independent confirmation — ", title_italic="m1 vs DFO SR 2025/005",
         takeaway="Two independent assessments, same trajectory. DFO confirms HG is at the LRP.",
         provenance="m1_stier_11 (this work) overlaid with DFO SR 2025/005 SCA (Cleary 2025) Table 15. Methods differ; the result agrees."),
    dict(src="sb5_cogovernance_timeline.png",
         title_plain="Co-governance — ", title_italic="the institutional spine",
         takeaway="40 years of nation-to-nation governance precede a stock-rebuilding plan.",
         provenance="Athlii Gwaii 1985 · South Moresby 1988 · Gwaii Haanas 1993 · AMB 1996 · 2024 minister-signed Rebuilding Plan."),
    dict(src="sb6_cod_vs_herring.png",
         title_plain="Why recovery ", title_italic="usually fails",
         takeaway="Often it is slow drawdown and lost structure — not necessarily a new stable environment or proven feedbacks.",
         provenance="Schematic comparison (cod = audience anchor; HG herring = the case in hand). Failed recovery is commonly sustained drawdown + lost spatial structure, NOT necessarily bistable feedbacks — claim-safe (no single promoted mechanism)."),
    dict(src="sb7_ews_hypothesis.png",
         title_plain="Early-warning signal — ", title_italic="a hypothesis to test",
         takeaway="If portfolio erosion is true critical slowing-down, variance should rise. Test ongoing.",
         provenance="Schematic / proposal. NOT a fitted leading-indicator result (claim-control sheet: hypothesis strength only)."),
]

if __name__ == "__main__":
    for j in JOBS:
        src = ORIG / j["src"]
        dst = DA / j["src"]
        bake(src, dst, j["title_plain"], j["title_italic"],
             takeaway=j.get("takeaway", ""),
             takeaway2=j.get("takeaway2", ""),
             provenance=j.get("provenance", ""),
             recolor=j.get("recolor"))
    print("done.")
