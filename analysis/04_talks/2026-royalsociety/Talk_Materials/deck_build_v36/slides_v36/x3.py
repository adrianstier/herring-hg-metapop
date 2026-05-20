"""X3 — BACKUP: THE CLIMAX. P(SB<LRP)=0.38 at zero catch since 2002.

LIGHT background. Big centered text. Optional small DFO inset bottom-center.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_x3(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "BACKUP · THE CLIMAX", dark=False)

    # GIANT centered headline: P(SB < LRP) = 0.38
    add_text(s, "P(SB < LRP) = 0.38",
             0.4, 2.3, DECK_W_IN - 0.8, 1.6,
             font=HEAD, size=88, bold=True, color=C_INK_DARK,
             align=PP_ALIGN.CENTER, dark=False)

    # Smaller italic line below
    add_text(s, "At zero catch since 2002.",
             0.4, 4.0, DECK_W_IN - 0.8, 0.7,
             font=HEAD, size=24, italic=True, color=C_SOFT_D,
             align=PP_ALIGN.CENTER, dark=False)

    # Optional small DFO inset bottom-center (~5 × 2 in)
    inset = asset_opt("dfo_spawning_biomass.png")
    if inset:
        inset_w = 5.0
        inset_h = 2.0
        inset_x = (DECK_W_IN - inset_w) / 2.0
        inset_y = 4.8
        add_image(s, inset, inset_x, inset_y, w=inset_w, h=inset_h)

    # Footer mono
    add_text(s, "Source: DFO Pacific Herring SR 2024/2025.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=10, color=C_SOFT_D,
             align=PP_ALIGN.CENTER, dark=False)

    speaker_note(s,
        "Even at zero catch since two thousand and two, there is a thirty-eight "
        "percent chance — next year — that spawning biomass falls below the "
        "limit reference point. We removed the original stressor. The fish are "
        "still right at the floor. Removing the stressor isn't enough — "
        "because the system has shifted state.")
