"""S25 — Solutions: allocate the portfolio + re-couple the strands.

Two-column TEXT-LED layout on LIGHT background.
kʼaaw framing: "the right and the ritual persisted; access did not."
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s25(prs):
    s = add_slide(prs, dark=False)

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "SOLUTIONS", dark=False)

    title_h1(s, "Allocate the portfolio. Re-couple the strands.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.9, size=30)

    # ── Two columns ─────────────────────────────────────────────────────────
    col_w = 6.0
    col_gutter = 0.4
    left_x = 0.4
    right_x = left_x + col_w + col_gutter   # ~6.8
    top_y = 1.9

    # Amber rules atop each column
    add_amber_rule(s, left_x, top_y, col_w - 0.3)
    add_amber_rule(s, right_x, top_y, col_w - 0.3)

    # ── LEFT COLUMN — ALLOCATE ─────────────────────────────────────────────
    add_text(s, "1 · ALLOCATE",
             left_x, top_y + 0.12, col_w, 0.4,
             font=MONO, size=12, bold=True, color=C_RUST, dark=False)

    add_multi_text(s, [
        {"text": "Manage at the cove scale ",
         "font": BODY, "size": 16, "color": C_INK_DARK},
        {"text": "(Okamoto: predicts far fewer collapses · no aggregate yield loss).",
         "font": BODY, "size": 16, "italic": True, "color": C_SOFT_D},

        {"text": "Shift life-stage harvest: ",
         "font": BODY, "size": 16, "color": C_INK_DARK, "new_para": True},
        {"text": "egg/kʼaaw non-lethal vs sac-roe ",
         "font": BODY, "size": 16, "color": C_INK_DARK},
        {"text": "(Shelton et al. 2014).",
         "font": BODY, "size": 16, "italic": True, "color": C_SOFT_D},
    ], left_x, top_y + 0.65, col_w, 3.4, line_spacing=1.35)

    # Italic small footer for LEFT column
    add_text(s,
             "Rebuild the portfolio at the scale it varies — "
             "portfolio management, literally.",
             left_x, top_y + 3.85, col_w, 1.0,
             font=HEAD, size=14, italic=True, color=C_SOFT_D, dark=False,
             line_spacing=1.35)

    # ── RIGHT COLUMN — RE-COUPLE ───────────────────────────────────────────
    add_text(s, "2 · RE-COUPLE",
             right_x, top_y + 0.12, col_w, 0.4,
             font=MONO, size=12, bold=True, color=C_RUST, dark=False)

    add_multi_text(s, [
        {"text": "Predator field already takes ~⅓ of stock. ",
         "font": BODY, "size": 16, "color": C_INK_DARK},
        {"text": "Value moved — it didn't vanish.",
         "font": BODY, "size": 16, "italic": True, "color": C_SOFT_D},

        {"text": "kʼaaw is the ",
         "font": BODY, "size": 16, "color": C_INK_DARK, "new_para": True},
        {"text": "LATENT proof-of-concept",
         "font": BODY, "size": 16, "bold": True, "color": C_RUST},
        {"text": " of the re-coupled regime.",
         "font": BODY, "size": 16, "color": C_INK_DARK},

        {"text": "The right · the knowledge · the kin-based logic · the low-impact gear  ALL survive.",
         "font": BODY, "size": 15, "color": C_INK_DARK, "new_para": True},
    ], right_x, top_y + 0.65, col_w, 3.4, line_spacing=1.35)

    # Italic small footer for RIGHT column
    add_text(s,
             "Only access is currently missing. "
             "Restoring access at the cove scale IS the management lever.",
             right_x, top_y + 3.85, col_w, 1.0,
             font=HEAD, size=14, italic=True, color=C_SOFT_D, dark=False,
             line_spacing=1.35)

    # Footer source
    credit(s,
           "Okamoto et al. 2020 · Shelton et al. 2014 · 2024 HG Herring Rebuilding Plan.",
           dark=False, y=7.05)

    speaker_note(s,
        "Two things. First — allocate the portfolio. Manage at the cove scale, "
        "not the archipelago scale. Okamoto and colleagues predict you get far "
        "fewer collapses with no aggregate yield loss. And shift the life-stage "
        "harvest — kʼaaw, spawn-on-kelp, is non-lethal; you take the eggs and "
        "leave the adults. Second — re-couple the strands. A recovered predator "
        "field already takes about a third of the stock. Value moved, it didn't "
        "vanish — herring is worth more as forage and as kʼaaw than as roe for "
        "export. And kʼaaw is the LATENT proof-of-concept of the re-coupled "
        "regime: the right, the knowledge, the kin-based harvest logic, the "
        "low-impact gear, all still survive. Only access is currently missing. "
        "Re-couple them and the demonstration becomes operational. Restoring "
        "access at the cove scale IS the management lever.")
