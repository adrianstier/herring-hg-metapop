"""S08 — Introduce the Haida (present-tense, sovereign)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s08(prs):
    s = add_slide(prs, dark=False)

    # ── Hero image (contemporary Haida k'aaw harvest) ─────────────────────
    # Image has baked-in chrome at bottom-left from previous deck — place
    # the image at the top filling the slide width but with margins; crop
    # via aspect-fit by using a centered placement that keeps focal area visible.
    # Use a large right-aligned area so any baked-in lower-left chrome is
    # less prominent and gets covered by the credit line / our type.
    img_path = asset("03_people.png")
    # Compose: wide image left/center ~ 9.5" wide, ~5.0" tall, vertically centered
    add_image(s, img_path, x=0.4, y=1.6, w=12.5, h=5.0)

    # ── Type: spare ────────────────────────────────────────────────────────
    kicker(s, "THE HAIDA", dark=False)
    title_h1(s, "On these islands for 10,000 years — and here now.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.9, size=28)

    # ── Single attribution credit, bottom-right (mono soft) ───────────────
    credit(s,
           "Photo: A. Salomon — used with permission · Council of the Haida Nation",
           dark=False, y=7.05)

    speaker_note(s,
        "The Haida are an Indigenous nation. These islands are their home — "
        "Haida Gwaii. They have been here for at least ten thousand years and "
        "they are here now. Their language, ceremony, and marine knowledge are "
        "alive and active. The Council of the Haida Nation is their government, "
        "and since 1985 the Haida and the Canadian state have co-governed parts "
        "of the archipelago together.")
