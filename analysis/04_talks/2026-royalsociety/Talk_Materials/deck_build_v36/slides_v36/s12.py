"""S12 — Three keystones, one fish (summary + transition)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s12(prs):
    s = add_slide(prs, dark=False)

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "THE SETUP", dark=False)
    title_h1(s, "Three keystones, one fish.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.9, size=32)

    # ── Three equal columns (4.3" wide each, centered) ─────────────────────
    # Total width 3 * 4.3 = 12.9; canvas 13.333; left margin = (13.333-12.9)/2 ≈ 0.21
    # Use 0.22 left margin; gutter 0.0 (columns adjacent); body x's:
    col_w = 4.3
    x0 = 0.22                  # ECOLOGICAL
    x1 = x0 + col_w            # CULTURAL  (4.52)
    x2 = x1 + col_w            # ECONOMIC  (8.82)
    top = 1.95
    body_top = 2.45            # below header + subtitle
    subtitle_top = 2.95
    rule_y = 3.45

    # Faint vertical rules between columns
    add_rect(s, x1 - 0.005, top, 0.01, 4.4, C_SOFT)
    add_rect(s, x2 - 0.005, top, 0.01, 4.4, C_SOFT)

    # ── Column 1: ECOLOGICAL ───────────────────────────────────────────────
    add_text(s, "ECOLOGICAL",
             x0 + 0.2, top, col_w - 0.4, 0.4,
             font=MONO, size=11, bold=True, color=C_RUST, dark=False)
    add_text(s, "The channel",
             x0 + 0.2, subtitle_top - 0.6, col_w - 0.4, 0.55,
             font=HEAD, size=22, italic=True, bold=True, color=C_INK_DARK, dark=False)
    add_multi_text(s, [
        {"text": "Bears · wolves · eagles · sea lions · salmon",
         "font": BODY, "size": 14, "color": C_INK_DARK},
        {"text": "The wasp-waist of the coastal food web.",
         "font": BODY, "size": 14, "italic": True, "color": C_INK_DARK,
         "new_para": True},
        {"text": " ", "font": BODY, "size": 6, "new_para": True},
        {"text": "“The whole coast eats.”",
         "font": HEAD, "size": 15, "italic": True, "color": C_RUST,
         "bold": True, "new_para": True},
    ], x0 + 0.2, rule_y, col_w - 0.4, 3.0, line_spacing=1.30)

    # ── Column 2: CULTURAL ─────────────────────────────────────────────────
    add_text(s, "CULTURAL",
             x1 + 0.2, top, col_w - 0.4, 0.4,
             font=MONO, size=11, bold=True, color=C_RUST, dark=False)
    add_text(s, "10,000 years",
             x1 + 0.2, subtitle_top - 0.6, col_w - 0.4, 0.55,
             font=HEAD, size=22, italic=True, bold=True, color=C_INK_DARK, dark=False)
    add_multi_text(s, [
        {"text": "kʼaaw — first food of the spring",
         "font": BODY, "size": 14, "color": C_INK_DARK},
        {"text": "Trade currency · ceremony · language",
         "font": BODY, "size": 14, "italic": True, "color": C_INK_DARK,
         "new_para": True},
        {"text": " ", "font": BODY, "size": 6, "new_para": True},
        {"text": "“Part of the essence of who you are.”",
         "font": HEAD, "size": 14, "italic": True, "color": C_RUST,
         "bold": True, "new_para": True},
        {"text": "— Barbara Wilson, 2016 (Rebuilding Plan 2024)",
         "font": MONO, "size": 9, "color": C_SOFT_D, "new_para": True},
    ], x1 + 0.2, rule_y, col_w - 0.4, 3.0, line_spacing=1.30)

    # ── Column 3: ECONOMIC ─────────────────────────────────────────────────
    add_text(s, "ECONOMIC",
             x2 + 0.2, top, col_w - 0.4, 0.4,
             font=MONO, size=11, bold=True, color=C_RUST, dark=False)
    add_text(s, "150 years",
             x2 + 0.2, subtitle_top - 0.6, col_w - 0.4, 0.55,
             font=HEAD, size=22, italic=True, bold=True, color=C_INK_DARK, dark=False)
    add_multi_text(s, [
        {"text": "Reduction era → kazunoko luxury → present absence",
         "font": BODY, "size": 13, "color": C_INK_DARK},
        {"text": " ", "font": BODY, "size": 6, "new_para": True},
        {"text": "1995 SOK peak ", "font": BODY, "size": 13, "color": C_INK_DARK,
         "new_para": True},
        {"text": "$62.88/lb", "font": HEAD, "size": 14, "bold": True,
         "italic": True, "color": C_INK_DARK},
        {"text": " → ", "font": BODY, "size": 13, "color": C_SOFT_D},
        {"text": "$11–14/lb", "font": HEAD, "size": 14, "bold": True,
         "italic": True, "color": C_INK_DARK},
        {"text": " (2004)", "font": MONO, "size": 11, "color": C_SOFT_D},
        {"text": " ", "font": BODY, "size": 6, "new_para": True},
        {"text": "Last HG commercial roe fishery: ",
         "font": BODY, "size": 13, "color": C_INK_DARK, "new_para": True},
        {"text": "2002", "font": HEAD, "size": 14, "bold": True, "italic": True,
         "color": C_RUST},
        {"text": ". Zero since.", "font": BODY, "size": 13, "color": C_INK_DARK},
    ], x2 + 0.2, rule_y, col_w - 0.4, 3.0, line_spacing=1.30)

    # ── Bottom amber-rule strip + take-home italic ─────────────────────────
    add_amber_rule(s, 0.4, 6.55, 1.2)
    add_text(s, "And in one lifetime, the fish changed twice.",
             0.4, 6.68, 12.5, 0.5,
             font=HEAD, size=20, italic=True, bold=True, color=C_INK_DARK,
             align=PP_ALIGN.LEFT, dark=False)

    # ── Bottom-right source for $ figures ──────────────────────────────────
    credit(s, "Source: 2024 HG Herring Rebuilding Plan §5.2.3",
           dark=False, y=7.10, x=0.4, w=12.5)

    speaker_note(s,
        "So step back. Three keystone relationships on one fish. Ecological — "
        "herring is the channel from ocean plankton to bears, wolves, eagles, "
        "sea lions, salmon. The whole coast eats. Cultural — for the Haida, "
        "ten thousand years of relationship; kʼaaw is the first food of the "
        "spring. Economic — a hundred and fifty years of commercial harvest "
        "layered on top: the reduction era, then the kazunoko luxury market, "
        "then absence. Three keystones, one fish. And in one lifetime, the "
        "fish changed twice.")
