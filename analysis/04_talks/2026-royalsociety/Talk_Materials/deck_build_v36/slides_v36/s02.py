"""S02 — Haida Gwaii (place)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s02(prs):
    s = add_slide(prs, dark=True)

    # Full-bleed place image — primary 01b_sense_of_place.png, fallback 02_shore.png
    img = asset_opt("01b_sense_of_place.png") or asset("02_shore.png")
    add_image(s, img, 0, 0, w=DECK_W_IN, h=DECK_H_IN, send_to_back=True)

    # Light dark scrim for type legibility
    scrim = add_rect(s, 0, 0, DECK_W_IN, 2.6, C_DARK)
    from pptx.oxml.ns import qn
    sp = scrim.fill.fore_color._xFill
    alpha = sp.makeelement(qn('a:alpha'), {'val': '55000'})
    sp.append(alpha)

    kicker(s, "THE PLACE", dark=True)

    title_h1(s, "Haida Gwaii", dark=True,
             x=0.6, y=0.75, w=12.2, h=1.0, size=44)

    add_text(s,
        "An archipelago at the productive edge of the Pacific — ~80 km off the British Columbia coast.",
        0.6, 1.85, 12.2, 0.6,
        font=HEAD, size=18, italic=True, color=C_INK, dark=True)

    speaker_note(s,
        "Haida Gwaii. An archipelago at the productive edge of the Pacific — "
        "about eighty kilometres off the British Columbia coast. One of the "
        "wildest, most productive stretches of coastline in North America. "
        "People have been here for ten thousand years. And for most of the "
        "year, you would never know what's about to happen.")
