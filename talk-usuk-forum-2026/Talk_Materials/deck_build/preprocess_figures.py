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

# Portable: <repo>/talk-usuk-forum-2026/Talk_Materials/deck_build/preprocess_figures.py
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
         takeaway: str = "", provenance: str = "", recolor=None):
    """Compose top chrome, stretched figure, bottom amber-rule takeaway + provenance."""
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

    # figure stretched to fill content zone width-to-width (no letterbox)
    fig = fig.resize((W, ZONE_H), Image.LANCZOS)
    canvas.paste(fig, (0, BAND_TOP))

    # amber takeaway rule + text
    if takeaway:
        # amber left-rule (8×60 px)
        d.rectangle([144, TAKEAWAY_RULE_Y, 152, TAKEAWAY_RULE_Y + 80], fill=AMBER)
        # takeaway text in italic serif, ink color, sized to feel like a 22pt body line
        tk_font = font(SERIF_ITALIC, 52)
        d.text((180, TAKEAWAY_RULE_Y + 8), takeaway, fill=INK, font=tk_font)

    # provenance line
    if provenance:
        d.text((144, PROV_Y), provenance, fill=SOFT, font=font(MONO, 26))

    canvas.save(out_path, "PNG", optimize=True)
    print(f"wrote {out_path.name}")

# Per-slide content
JOBS = [
    dict(src="05_two_collapses.png",
         title_plain="Two collapses, ", title_italic="two outcomes",
         takeaway="The 1960s collapse rebounded in ~5 yr; the 1990s collapse has not.",
         provenance="m1_stier_11 estimated total HG herring biomass, focal-9 sections, 1951–2025 (median, 80% CI)."),
    dict(src="06_climate_pdo.png",
         title_plain="Ocean productivity is a ", title_italic="first-order driver",
         takeaway="≈1.25× swing across the observed PDO range — necessary, not sufficient.",
         provenance="Posterior PDO effect on subpopulation growth (m1_stier_11; Stier 2020 method, refit)."),
    dict(src="07_two_scales.png",
         title_plain="Fishing pressure — ", title_italic="the average hid the extremes",
         takeaway="Cove rate up to ~50% while archipelago-wide stayed near ~3%.",
         provenance="Updated Stier et al. 2020 method, catch matrix extended to 2025 — scale-mismatch result, not m1_stier_11."),
    dict(src="08_realized_growth.png",
         title_plain="Population growth collapsed, ", title_italic="cove by cove",
         takeaway="8 of 9 sections declined post-1994 — system-wide, invisible at the aggregate.",
         provenance="m1_stier_11 per-section mean realized growth, dense-sampled sections (Tasu Sound & Naden Harbour excluded for sparse data)."),
    dict(src="09_synchrony.png",
         title_plain="The portfolio ", title_italic="eroded",
         takeaway="Mean subpopulation synchrony rose 28% from 1955–1993 to 1994–2020.",
         provenance="m1_stier_11 + Stier 2020. Loreau & de Mazancourt index, 10-yr rolling window."),
    dict(src="10_predators.png",
         title_plain="The predators ", title_italic="came back",
         takeaway="2015–24 predator demand ≈ 239% of HG annual spawn.",
         provenance="Audited HG predator herring demand — Stier Lab predator synthesis (24 spp). A pressure, not a fitted m1_stier_11 coefficient."),
    dict(src="dfo_spawning_biomass.png",
         title_plain="Spawning biomass at the ", title_italic="limit reference point",
         takeaway="Zero catch since 2002; P(SB2025 < LRP) = 0.38 even with no fishing.",
         provenance="Cleary / DFO SR 2025/005 Fig 8(d); reference points & 2025 forecast = Table 19 (exact)."),
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
         title_plain="Independent confirmation — ", title_italic="m1_stier_11 vs DFO SR 2025/005",
         takeaway="Two independent assessments, same trajectory. DFO confirms HG is at the LRP.",
         provenance="m1_stier_11 (this work) overlaid with DFO SR 2025/005 SCA (Cleary 2025) Table 15. Methods differ; the result agrees."),
    dict(src="sb5_cogovernance_timeline.png",
         title_plain="Co-governance — ", title_italic="the institutional spine",
         takeaway="40 years of nation-to-nation governance precede a stock-rebuilding plan.",
         provenance="Athlii Gwaii 1985 · South Moresby 1988 · Gwaii Haanas 1993 · AMB 1996 · 2024 minister-signed Rebuilding Plan."),
    dict(src="sb6_cod_vs_herring.png",
         title_plain="Two systems, ", title_italic="one tipping-point grammar",
         takeaway="Removing the stressor is not the same as reversing the tip.",
         provenance="Schematic comparison. Cod recovery (Newfoundland / North Sea) is the audience anchor; HG herring is the case in hand."),
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
             provenance=j.get("provenance", ""),
             recolor=j.get("recolor"))
    print("done.")
