"""S14 — Zoom in: two contrasting coves (one rising, one falling)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s14(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker
    kicker(s, "ZOOM IN", dark=False)

    # h1
    title_h1(s, "Not all places responded the same.",
             dark=False,
             x=0.4, y=0.7, w=12.5, h=0.7, size=30)

    # Subtitle (italic)
    add_text(s,
             "Some historically productive coves have collapsed. Others have grown.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=18, italic=True,
             color=C_SOFT_D, dark=False)

    # Primary asset: try the contrast composite first (more contentful)
    # then fall back to v36 placeholder
    img = (asset_opt("14_section_contrast.png")
           or asset_opt("s14_two_coves_PLACEHOLDER.png"))

    # Place at 90% width centered, below the subtitle
    img_w = 12.0
    img_x = (DECK_W_IN - img_w) / 2.0
    img_y = 2.1
    img_h = 4.7
    add_image(s, img, img_x, img_y, w=img_w, h=img_h)

    # Footer
    credit(s,
           "Source: DFO Pacific Herring assessments · Stier et al. 2020.",
           dark=False, y=7.0)

    speaker_note(s,
        "When we zoom in past the aggregate to the cove scale, the story is more "
        "nuanced. Not all locations around the island responded the same. Some "
        "places — historically the most productive — have collapsed. Others have "
        "actually increased. Here are two specific sections to show that "
        "contrast. The aggregate hides directional divergence at the cove scale.")
