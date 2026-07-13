"""S26 — Who governs: co-governance timeline (40 years of nation-to-nation).

LIGHT background. Image full-width. Framed as institutional milestone, not outcome.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s26(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "WHO GOVERNS", dark=False)

    # h1
    title_h1(s, "Forty years of nation-to-nation co-governance.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.7, size=28)

    # Subtitle (italic)
    add_text(s,
             "Haida Nation · DFO · BC · Parks Canada · the 2024 Rebuilding Plan.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=16, italic=True,
             color=C_SOFT_D, dark=False)

    # Full-width image: co-governance timeline
    img_path = asset("sb5_cogovernance_timeline.png")
    img_w = 12.5
    img_x = (DECK_W_IN - img_w) / 2.0
    img_y = 2.1
    img_h = 4.2
    add_image(s, img_path, img_x, img_y, w=img_w, h=img_h)

    # Key-markers strip below image (mono, rust accents)
    add_text(s,
             "AMB · GayG̲ahlda Framework · 2024 plan · 0 t 2025 recommendation",
             0.4, 6.45, 12.5, 0.4,
             font=MONO, size=11, color=C_RUST,
             align=PP_ALIGN.CENTER, dark=False)

    # Footer
    credit(s,
           "Council of the Haida Nation · DFO · Archipelago Management Board · 2024 Rebuilding Plan.",
           dark=False, y=7.05)

    speaker_note(s,
        "And who does this? Forty years of nation-to-nation governance precede "
        "the 2024 Rebuilding Plan. The Council of the Haida Nation. DFO. BC. "
        "Parks Canada. The Archipelago Management Board. The GayG̲ahlda "
        "Framework. This isn't a solution that causes herring to come back. "
        "But it is a more equitable approach to governing — one that elevates "
        "voices historically disenfranchised, and that recognises non-Western "
        "forms of value: cultural connection to the ecosystem, the harvest "
        "itself, and the cultural transmission of knowledge that happens "
        "across generations when families go out to collect together. That "
        "institution exists. That's a milestone we can act on now — it is "
        "not a recovery we can claim yet.")
