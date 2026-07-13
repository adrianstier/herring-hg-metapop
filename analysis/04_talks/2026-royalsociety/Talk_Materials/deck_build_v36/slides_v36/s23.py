"""S23 — Mechanism: Lost elders / GWOF (Guujaaw quote + science convergence)

CLAIM-CONTROL:
  - Regional age-lead result framed as "consistent-with, modest, regional,
    descriptive — not demonstrated as cause at subpopulation scale".
  - Use Guujaaw attribution per claim-control sheet.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s23(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # ── Kicker + h1 (kicker only; quote IS the visual h1) ─────────────────
    kicker(s, "MECHANISM: LOST ELDERS", dark=False)

    # ── Small fallback image top-right (3 x 3 in) ─────────────────────────
    img_w = 3.0
    img_h = 3.0
    img_x = DECK_W_IN - img_w - 0.4
    img_y = 0.75
    decoupling = asset_opt("12_decoupling.png")
    if decoupling is not None:
        add_image(s, decoupling, img_x, img_y, w=img_w, h=img_h)

    # ── Guujaaw quote: large center-left ──────────────────────────────────
    quote_x = 0.4
    quote_y = 1.1
    quote_w = DECK_W_IN - img_w - 1.0   # leave room for top-right image
    quote_h = 2.8

    add_text(s,
        "“Once herring lost the elders they lost their way to their "
        "spawning grounds.”",
        quote_x, quote_y, quote_w, quote_h,
        font=HEAD, size=28, italic=True, color=C_INK_DARK, dark=False,
        line_spacing=1.25)

    # Attribution (mono small)
    add_text(s,
        "— Chief Gidansta (Guujaaw)",
        quote_x, quote_y + 2.8, quote_w, 0.35,
        font=MONO, size=11, color=C_SOFT_D, dark=False)

    # ── Right panel: convergence list (mono small) ────────────────────────
    panel_x = DECK_W_IN - 4.0
    panel_y = 4.05
    panel_w = 3.7
    add_text(s, "SCIENCE CONVERGENCE",
             panel_x, panel_y, panel_w, 0.35,
             font=MONO, size=10, bold=True, color=C_RUST, dark=False)
    add_amber_rule(s, panel_x, panel_y + 0.32, 0.8)

    add_multi_text(s, [
        {"text": "MacCall 2019", "font": MONO, "size": 11,
         "color": C_INK_DARK},
        {"text": "Corten 2002", "font": MONO, "size": 11,
         "color": C_INK_DARK, "new_para": True},
        {"text": "Huse 2002 / 2010", "font": MONO, "size": 11,
         "color": C_INK_DARK, "new_para": True},
        {"text": "Ono et al. 2025 Nature", "font": MONO, "size": 11,
         "color": C_INK_DARK, "new_para": True},
        {"text": "Jesmer et al. 2018 Science (bighorn / moose)",
         "font": MONO, "size": 11, "color": C_INK_DARK, "new_para": True},
    ], panel_x, panel_y + 0.5, panel_w, 2.0, line_spacing=1.4)

    # ── Bottom strip: regional result panel (mono small) ──────────────────
    strip_y = 5.85
    strip_x = 0.4
    strip_w = DECK_W_IN - 0.8
    add_text(s, "REGIONAL RESULT",
             strip_x, strip_y, strip_w, 0.35,
             font=MONO, size=10, bold=True, color=C_RUST, dark=False)
    add_amber_rule(s, strip_x, strip_y + 0.32, 0.8)

    add_multi_text(s, [
        {"text": "ρ_firstdiff = +0.37  (p ≈ 0.035, n = 32)",
         "font": MONO, "size": 12, "color": C_INK_DARK},
        {"text": "mean-age → spawn-index, 7-yr lag, ρ = +0.43  (p ≈ 0.015)",
         "font": MONO, "size": 12, "color": C_INK_DARK, "new_para": True},
    ], strip_x, strip_y + 0.45, strip_w, 0.8, line_spacing=1.3)

    # ── Disclaimer (small italic) ──────────────────────────────────────────
    add_text(s,
        "Consistent-with, modest, regional, descriptive — not demonstrated "
        "as cause at subpopulation scale (per claim-control sheet).",
        strip_x, strip_y + 1.05, strip_w, 0.4,
        font=BODY, size=12, italic=True, color=C_SOFT_D, dark=False,
        line_spacing=1.2)

    # ── Speaker note: verbatim Spoken from outline ────────────────────────
    speaker_note(s,
        "Second — lost elders. Chief Gidansta — Guujaaw — said it best: "
        "'Once herring lost the elders they lost their way to their "
        "spawning grounds.' This is the Go-With-Older-Fish hypothesis, and "
        "the published science has converged on it — MacCall 2019, Ono 2025, "
        "Jesmer's bighorn migration work. Our regional age-lead test is "
        "consistent with the precursor: the ratio of repeat-to-first-time "
        "spawners leads loss of spawning sites by about one herring "
        "generation. Modest, regional, consistent-with — not yet "
        "demonstrated as the cause at the subpopulation scale. The "
        "social-ecological double helix in one slide: Haida knowledge and "
        "the published science name the same mechanism.")
