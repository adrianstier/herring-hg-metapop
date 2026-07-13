"""S03 — Contrast: WITHOUT | WITH herring (split panel)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s03(prs):
    s = add_slide(prs, dark=False)  # LIGHT background per spec

    half = DECK_W_IN / 2.0  # 6.6665"

    # LEFT panel: before water (dark Pacific)
    add_image(s, asset("s03_before_water.png"), 0, 0,
              w=half, h=DECK_H_IN, send_to_back=True)
    # RIGHT panel: after plume (turquoise/milky)
    add_image(s, asset("s03_after_plume.png"), half, 0,
              w=half, h=DECK_H_IN, send_to_back=True)

    # Small mono labels — top corners (light text on dark imagery)
    add_text(s, "MOST OF THE YEAR",
             0.3, 0.3, 4.0, 0.4,
             font=MONO, size=11, color=C_INK, dark=True)
    add_text(s, "WHEN THE HERRING ARRIVE",
             half + 0.3, 0.3, 4.5, 0.4,
             font=MONO, size=11, color=C_INK, dark=True)

    # Bottom caption strip — small dark band with italic caption
    add_rect(s, 0, DECK_H_IN - 0.85, DECK_W_IN, 0.55, C_DARK)
    add_text(s, "In a matter of days.",
             0, DECK_H_IN - 0.82, DECK_W_IN, 0.5,
             font=HEAD, size=18, italic=True, color=C_INK,
             align=PP_ALIGN.CENTER, dark=True)

    # Footage credit bottom-right (on the dark strip)
    footage_credit(s, dark=True)

    speaker_note(s,
        "This is what the water looks like. On the left — most of the year. "
        "Dark, clear, cold. On the right — when the herring arrive. The whole "
        "bay turns turquoise. You can see it from a satellite. The shift "
        "happens in days.")
