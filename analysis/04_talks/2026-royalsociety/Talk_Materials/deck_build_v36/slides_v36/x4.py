"""X4 — BACKUP: ACCESS TIPPING POINT. Six dimensions, text-led cascade.

LIGHT background. kʼaaw framing: "the right and the ritual persisted; access did not."
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_x4(prs):
    s = add_slide(prs, dark=False)

    # Kicker + h1
    kicker(s, "BACKUP · ACCESS TIPPING POINT", dark=False)
    title_h1(s, "The rights persisted. The access did not.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.7, size=28)

    # Six dimensions
    rows = [
        ("1", "Regulatory",
         " — HG commercial roe closed since 2002 · SOK since 2004 · 0 t harvest 2025."),
        ("2", "Legal",
         " — R. v. Gladstone (1996) affirmed Heiltsuk; DFO does not recognize Haida title."),
        ("3", "Economic",
         " — SOK $40/lb (1995) → <$6/lb (2004) · HG SOK $9.1M (1988) → negligible."),
        ("4", "Physical",
         " — spawn extent contracted ~48% since 1940s (Gerrard 2014)."),
        ("5", "Infrastructure",
         " — children grow up without knowing the taste."),
        ("6", "Cultural",
         " — “Herring is part of the essence of who you are.” — Barbara Wilson (2016)."),
    ]

    row_h = 0.55
    rows_w = 12.0
    rows_x = (DECK_W_IN - rows_w) / 2.0
    top_y = 1.7

    for i, (num, label, body) in enumerate(rows):
        ry = top_y + i * row_h

        # Mono number left, rust
        add_text(s, num,
                 rows_x, ry, 0.5, row_h,
                 font=MONO, size=18, bold=True, color=C_RUST,
                 align=PP_ALIGN.LEFT, dark=False)

        # Bold label + body Calibri
        add_multi_text(s, [
            {"text": label,
             "font": BODY, "size": 16, "bold": True, "color": C_INK_DARK},
            {"text": body,
             "font": BODY, "size": 16, "color": C_INK_DARK},
        ], rows_x + 0.55, ry, rows_w - 0.55, row_h, line_spacing=1.2)

    # ── Bottom amber-rule + headline italic ────────────────────────────────
    headline_y = top_y + len(rows) * row_h + 0.30  # ~5.0+
    add_amber_rule(s, rows_x, headline_y, rows_w)

    add_text(s,
             "Mobile commercial had access. Place-based Indigenous lost access "
             "site by site — decades before the regional total collapsed.",
             rows_x, headline_y + 0.18, rows_w, 0.8,
             font=HEAD, size=15, italic=True, color=C_INK_DARK,
             align=PP_ALIGN.CENTER, dark=False, line_spacing=1.3)

    # Source footer mono small
    add_text(s,
             "RP 2024 · Stier et al. 2020 · Powell 2012 · Gerrard 2014 · "
             "R. v. Gladstone 1996 · DFO IFMP.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=9, color=C_SOFT_D,
             align=PP_ALIGN.CENTER, dark=False)

    speaker_note(s,
        "And here's the second strand of the social-economic tip — access. "
        "Because kʼaaw rights are not the same as kʼaaw access. Six coupled "
        "dimensions, all in one lifetime. Regulatory closure. Legal — Gladstone "
        "affirmed Heiltsuk rights but DFO does not recognize Haida commercial "
        "title. Economic — price collapsed and licences moved out of place-based "
        "hands through the Davis Plan and IVQ pools. Physical — spawn extent "
        "contracted almost fifty percent since the 1940s; Skidegate Inlet was "
        "cleaned out by the reduction fishery and never really came back. "
        "Infrastructure decayed. And cultural — children growing up without "
        "knowing the taste. The headline asymmetry: the mobile commercial fleet "
        "always had access to whatever fish remained. Place-based Indigenous "
        "fishers are spatially constrained — by boat size, fuel costs, "
        "political and cultural boundaries — and they lost access site by "
        "site, decades before the regional total collapsed. The right and the "
        "ritual persisted; the fish, the licences, the infrastructure, and "
        "the access did not.")
