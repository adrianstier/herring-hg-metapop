"""S11 — Economics of herring: value through time"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s11(prs):
    s = add_slide(prs, dark=False)

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "VALUE THROUGH TIME", dark=False)
    title_h1(s, "The economics of herring",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.9, size=30)

    # Subtitle italic
    add_text(s,
             "The foreign demand engine that created the BC roe fishery in 1972 has weakened on both blades.",
             0.4, 1.45, 12.5, 0.45,
             font=HEAD, size=14, italic=True, color=C_SOFT_D, dark=False)

    # ── LEFT 70%: roe-seine landed-value chart ─────────────────────────────
    # Chart frame ~ x=0.4, w=8.9 (about 67% of canvas)
    add_image(s, asset("RebuildingPlan2024_Fig32_roe_seine_landed_value_2020dollars.png"),
              x=0.4, y=2.0, w=8.9, h=5.0)

    # ── RIGHT 30% sidebar: regime annotations + audited $ markers ──────────
    rx = 9.5
    rw = 3.5

    # Sidebar header — small mono kicker
    add_text(s, "REGIMES",
             rx, 2.0, rw, 0.3,
             font=MONO, size=10, bold=True, color=C_RUST, dark=False)

    # Four regime rows: era label + years
    add_multi_text(s, [
        # Reduction era
        {"text": "Reduction era", "font": HEAD, "size": 14, "bold": True,
         "color": C_INK_DARK},
        {"text": "  1930s–1967", "font": MONO, "size": 11, "color": C_SOFT_D},
        # Kazunoko luxury
        {"text": "Kazunoko luxury", "font": HEAD, "size": 14, "bold": True,
         "color": C_INK_DARK, "new_para": True},
        {"text": "  1972–1996", "font": MONO, "size": 11, "color": C_SOFT_D},
        # Demand collapse
        {"text": "Demand collapse", "font": HEAD, "size": 14, "bold": True,
         "color": C_INK_DARK, "new_para": True},
        {"text": "  1996–2006", "font": MONO, "size": 11, "color": C_SOFT_D},
        # Present absence
        {"text": "Present absence", "font": HEAD, "size": 14, "bold": True,
         "color": C_RUST, "italic": True, "new_para": True},
        {"text": "  2007–today", "font": MONO, "size": 11, "color": C_SOFT_D},
    ], rx, 2.4, rw, 3.0, line_spacing=1.4)

    # Amber rule between regimes and $ markers
    add_amber_rule(s, rx, 5.55, 1.0)

    # $ markers — audited numbers (HARD RULE)
    add_multi_text(s, [
        {"text": "SOK peak", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "  $62.88/lb", "font": HEAD, "size": 14, "bold": True,
         "color": C_INK_DARK, "italic": True},
        {"text": "  (1995)", "font": MONO, "size": 10, "color": C_SOFT_D},
        # arrow row
        {"text": "→  ", "font": HEAD, "size": 14, "color": C_RUST,
         "new_para": True},
        {"text": "$11–14/lb", "font": HEAD, "size": 14, "bold": True,
         "color": C_INK_DARK, "italic": True},
        {"text": "  (2004)", "font": MONO, "size": 10, "color": C_SOFT_D},
        # last HG roe
        {"text": "Last HG roe:", "font": MONO, "size": 10, "color": C_RUST,
         "bold": True, "new_para": True},
        {"text": "  2002", "font": HEAD, "size": 14, "bold": True,
         "color": C_INK_DARK, "italic": True},
    ], rx, 5.70, rw, 1.4, line_spacing=1.25)

    # ── Footer source ──────────────────────────────────────────────────────
    credit(s, "Source: 2024 HG Herring Rebuilding Plan + KCAW 2024.",
           dark=False, y=7.10, x=0.4, w=12.5)

    speaker_note(s,
        "The economics of this fish have changed dramatically across one human "
        "lifetime. Early industrial — reduction era — herring was ground into "
        "fishmeal and oil. After the 1960s collapse, the fishery reopened in "
        "1972 to supply the Japanese kazunoko market — herring roe as luxury "
        "food. Prices climbed to sixty-three dollars a pound by 1995. Then the "
        "demand engine weakened on both sides. Japan rebuilt domestic supply "
        "through Hokkaido hatcheries. AND Japanese kazunoko demand structurally "
        "declined as the consumer base aged out. Prices collapsed to about "
        "twelve dollars by 2004. The last commercial roe fishery at Haida Gwaii "
        "was 2002. Zero since. The 1980s–90s rent environment is unrecoverable "
        "on current trends. The economic non-recovery may be more permanent "
        "than the ecological one.")
