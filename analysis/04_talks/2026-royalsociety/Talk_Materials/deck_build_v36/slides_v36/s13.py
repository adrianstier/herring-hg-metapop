"""S13 — THE PUZZLE: two collapses, one lifetime, opposite recoveries"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s13(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker top-left
    kicker(s, "THE PUZZLE", dark=False)

    # h1 — the question
    title_h1(s,
             "Same fish. Same coast. Twice collapsed. Why did one come back?",
             dark=False,
             x=0.4, y=0.7, w=12.5, h=0.9, size=28)

    # Full-width chart (90% of slide) — aggregate biomass w/ both collapses
    # Chart sits below the h1 from y ~ 1.7 to y ~ 6.7 (5 in tall) × 12 wide
    chart_x, chart_y = 0.6, 1.75
    chart_w, chart_h = 12.0, 5.0
    add_image(s, asset("05_two_collapses.png"),
              chart_x, chart_y, w=chart_w, h=chart_h)

    # Mono callout #1 — 1967 collapse (left side, on chart)
    add_text(s, "1967: collapse → 5-yr recovery",
             1.0, 2.2, 4.5, 0.4,
             font=MONO, size=11, color=C_RUST, dark=False)

    # Mono callout #2 — post-1994 collapse (right side, on chart)
    add_text(s, "Post-1994: collapse → no recovery in 30 yr",
             7.4, 2.2, 5.4, 0.4,
             font=MONO, size=11, color=C_RUST, dark=False)

    # Footer source credit
    credit(s, "Source: DFO Pacific Herring SR 2024/2025.", dark=False, y=7.0)

    speaker_note(s,
        "Now back out to the aggregate. Two collapses in one lifetime. The first — "
        "driven by industrial fishing — closed in 1967, and the population came back "
        "in about five years. The second — beginning in the 1990s — has not "
        "recovered in thirty. Same fish, same coast, opposite outcomes. Why?")
