"""S20 — Suspect 2: Fishing — the average hid the extremes"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s20(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # ── Kicker + h1 + subtitle ─────────────────────────────────────────────
    kicker(s, "SUSPECT 2: FISHING", dark=False)
    title_h1(s, "The average hid the extremes.", dark=False,
             x=0.4, y=0.65, w=12.5, h=0.85, size=32)
    add_text(s,
        "Archipelago-wide harvest was modest. Cove-level harvest was devastating.",
        0.4, 1.45, 12.5, 0.5,
        font=HEAD, size=16, italic=True, color=C_SOFT_D, dark=False)

    # ── LEFT 60% — two_scales.png ─────────────────────────────────────────
    chart_x = 0.4
    chart_y = 2.1
    chart_w = DECK_W_IN * 0.58       # ~7.7"
    chart_h = 4.6
    add_image(s, asset("07_two_scales.png"),
              chart_x, chart_y, w=chart_w, h=chart_h)

    # ── RIGHT 40% — big mono callouts ─────────────────────────────────────
    rx = chart_x + chart_w + 0.35
    rw = DECK_W_IN - rx - 0.3

    # Callout 1 — 4% archipelago-wide
    add_multi_text(s, [
        {"text": "4%", "font": MONO, "size": 48, "bold": True,
         "color": C_INK_DARK},
        {"text": "  archipelago-wide", "font": BODY, "size": 14,
         "color": C_SOFT_D, "italic": True},
    ], rx, chart_y, rw, 1.0, line_spacing=1.1)

    add_rect(s, rx, chart_y + 1.05, rw - 0.2, 0.015, C_SOFT)

    # Callout 2 — 50-70% in coves
    add_multi_text(s, [
        {"text": "50–70%", "font": MONO, "size": 42, "bold": True,
         "color": C_RUST},
        {"text": "  in coves", "font": BODY, "size": 14,
         "color": C_SOFT_D, "italic": True, "new_para": True},
    ], rx, chart_y + 1.2, rw, 1.2, line_spacing=1.05)

    add_rect(s, rx, chart_y + 2.45, rw - 0.2, 0.015, C_SOFT)

    # Callout 3 — 91% in some subpops
    add_multi_text(s, [
        {"text": "91%", "font": MONO, "size": 48, "bold": True,
         "color": C_RUST},
        {"text": "  in some subpops", "font": BODY, "size": 14,
         "color": C_SOFT_D, "italic": True, "new_para": True},
    ], rx, chart_y + 2.6, rw, 1.2, line_spacing=1.05)

    # Amber rule + italic punch line
    add_amber_rule(s, rx, chart_y + 3.9, 1.0)
    add_text(s,
        "The coastwide number looked safe — that was the problem.",
        rx, chart_y + 4.05, rw, 0.7,
        font=HEAD, size=14, italic=True, color=C_INK_DARK, dark=False,
        line_spacing=1.2)

    # ── Footer credit ──────────────────────────────────────────────────────
    credit(s,
        "Stier et al. 2020 · Okamoto et al. 2020",
        dark=False, y=7.1)

    # ── Speaker note: verbatim Spoken from outline ────────────────────────
    speaker_note(s,
        "Second suspect: fishing. The archipelago-wide harvest rate looked "
        "modest — about four percent. But at the cove scale, harvest rates "
        "were fifty to seventy percent, and in some sub-populations as high "
        "as ninety-one. The coastwide number looked safe — that was the "
        "problem. Fishing drove the first collapse — the uncontested part "
        "of the story. But aggregate indicators are resilience-blind. They "
        "hide the cove-scale damage that IS the portfolio failure.")
