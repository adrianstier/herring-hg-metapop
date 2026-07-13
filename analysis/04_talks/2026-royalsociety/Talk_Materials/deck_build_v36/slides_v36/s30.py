"""S30 — CLOSE: bookend the take-home.

DARK background. Same full-bleed dawn-coast image as S1.
The SECOND and FINAL appearance of "Recovery is a moving target."
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN
from pptx.oxml.ns import qn


def build_s30(prs):
    s = add_slide(prs, dark=True)

    # Full-bleed image (same as S1)
    add_image(s, asset("01_title.png"), 0, 0,
              w=DECK_W_IN, h=DECK_H_IN, send_to_back=True)

    # Dark scrim at bottom — using 60% alpha black covering full slide
    scrim = add_rect(s, 0, 0, DECK_W_IN, DECK_H_IN, C_DARK)
    sp = scrim.fill.fore_color._xFill
    alpha = sp.makeelement(qn('a:alpha'), {'val': '60000'})
    sp.append(alpha)

    # Kicker top-left (mono rust)
    kicker(s, "IN ONE LIFETIME, THE FISH CHANGED TWICE.", dark=True)

    # h1 — Georgia bold 44pt CENTERED in amber (the bookend phrase)
    add_text(s, "Recovery is a moving target.",
             0.5, 3.0, DECK_W_IN - 1.0, 1.2,
             font=HEAD, size=44, bold=True, color=C_AMBER,
             align=PP_ALIGN.CENTER, dark=True)

    # Below: smaller italic Georgia 18pt centered
    add_text(s,
             "Same fish. Same coast. Once it came back. Once it has not.",
             0.5, 4.3, DECK_W_IN - 1.0, 0.6,
             font=HEAD, size=18, italic=True, color=C_INK,
             align=PP_ALIGN.CENTER, dark=True)

    # Bottom: small italic Calibri — acknowledgments
    add_text(s,
             "Thank you — to the Haida Nation, to the Pacific Herring program at "
             "Fisheries and Oceans Canada, and to colleagues at UCSB, OSU, UBC "
             "and beyond.",
             0.5, 6.3, DECK_W_IN - 1.0, 0.5,
             font=BODY, size=13, italic=True, color=C_INK,
             align=PP_ALIGN.CENTER, dark=True)

    # Bottom-right credit
    credit(s,
           "Adrian Stier · UC Santa Barbara · US–UK Forum · Session 5 · 20 May 2026",
           dark=True, y=7.05)

    speaker_note(s,
        "The take-home is one sentence — the same one I started with. "
        "Recovery is a moving target. Thank you to the Haida Nation, to the "
        "Pacific Herring program at Fisheries and Oceans Canada, and to "
        "colleagues across UCSB, OSU, and UBC who made this work possible.")
