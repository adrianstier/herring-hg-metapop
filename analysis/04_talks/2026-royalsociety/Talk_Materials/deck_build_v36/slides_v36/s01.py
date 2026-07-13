"""S01 — Title + Thesis + Take-home"""
from helpers_v36 import *  # palette, fonts, helpers, paths
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s01(prs):
    s = add_slide(prs, dark=True)

    # Full-bleed dark Haida Gwaii coast at dawn
    add_image(s, asset("01_title.png"), 0, 0, w=DECK_W_IN, h=DECK_H_IN, send_to_back=True)

    # Soft dark scrim so type reads (semi-transparent dark overlay)
    scrim = add_rect(s, 0, 0, DECK_W_IN, DECK_H_IN, C_DARK)
    scrim.fill.transparency = 0
    # Use XML to set transparency on the fill
    from pptx.oxml.ns import qn
    sp = scrim.fill.fore_color._xFill
    # Add alpha (40% opacity black scrim — text legibility without killing the image)
    alpha = sp.makeelement(qn('a:alpha'), {'val': '60000'})
    sp.append(alpha)

    # Kicker — mono, top-left
    kicker(s, "SESSION 5 · TIPPING POINTS IN ECOSYSTEM SERVICES", dark=True)

    # h1 — Georgia 48pt
    title_h1(s, "Pacific Herring at Haida Gwaii", dark=True,
             x=0.6, y=1.4, w=12.2, h=1.2, size=48)

    # Subtitle — italic Georgia
    add_text(s, "A coupled social–ecological system — drawn down twice in one lifetime, and back only once.",
             0.6, 2.8, 12.2, 0.7,
             font=HEAD, size=20, italic=True, color=C_INK, dark=True)

    # Amber rule + take-home (bookend phrase)
    add_amber_rule(s, 0.6, 4.1, 1.2)
    add_text(s, "“Recovery is a moving target.”",
             0.6, 4.25, 12.2, 1.0,
             font=HEAD, size=32, bold=True, italic=True, color=C_AMBER, dark=True)

    # Bottom-right credit
    credit(s, "Adrian Stier · UC Santa Barbara · US–UK Forum · Session 5 · 20 May 2026",
           dark=True, y=7.05)

    speaker_note(s,
        "Pacific herring at Haida Gwaii — one of the longest-studied forage-fish "
        "systems on the planet — has collapsed twice in one lifetime. The first "
        "time it came back in five years. The second time it has not come back "
        "in thirty. Recovery is a moving target.")
