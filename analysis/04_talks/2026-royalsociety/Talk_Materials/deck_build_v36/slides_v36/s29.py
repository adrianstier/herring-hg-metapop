"""S29 — Reserved breathing-room slot. Single quiet image full-bleed.

LIGHT background. No overlay text except a small bottom-right credit.
Assembly may drop this slide on talk day if pacing tight — leave it in.
"""
from helpers_v36 import *


def build_s29(prs):
    s = add_slide(prs, dark=False)

    # Try the quiet shoreline first; fall back to section_contrast image
    img_path = (asset_opt("02_shore.png")
                or asset_opt("14_section_contrast.png"))

    # Full-bleed
    add_image(s, img_path, 0, 0, w=DECK_W_IN, h=DECK_H_IN, send_to_back=True)

    # Small bottom-right credit only
    credit(s, "Haida Gwaii · shoreline.", dark=False, y=7.10)

    speaker_note(s,
        "[Breathing-room slide. No narration. Pause for a beat before the "
        "bookend close on S30. If pacing is tight on talk day, this slide "
        "can be dropped.]")
