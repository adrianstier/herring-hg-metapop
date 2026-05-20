"""S18 — SUSPECT 3: PRODUCTIVITY drained ~8-fold across almost every site"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s18(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker + h1
    kicker(s, "SUSPECT 3: PRODUCTIVITY", dark=False)

    title_h1(s, "Productivity drained — at almost every site.",
             dark=False,
             x=0.4, y=0.7, w=12.5, h=0.7, size=30)

    # Subtitle (italic)
    add_text(s,
             "Per-subpopulation process variance fell ~8-fold post-1995.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=18, italic=True,
             color=C_SOFT_D, dark=False)

    # Full-width chart
    img = asset("08_realized_growth.png")
    img_w = 12.0
    img_x = (DECK_W_IN - img_w) / 2.0
    img_y = 2.1
    img_h = 4.6
    add_image(s, img, img_x, img_y, w=img_w, h=img_h)

    # Optional mono callout on top of the chart
    add_text(s,
             "δ²σ: 0.08 (1950–68) → 0.01 (1996–2015)",
             1.0, 2.3, 6.2, 0.4,
             font=MONO, size=11, color=C_RUST, dark=False)

    speaker_note(s,
        "Productivity eroded too. The capacity of each subpopulation to grow — "
        "measured as process variance — fell about eight-fold between the "
        "pre-collapse period and today. This is happening at almost every "
        "section. It didn't flip off — it drained away over decades. This is "
        "the leading proximate explanation for why the door didn't reopen. "
        "But there are two more pressures that may matter more.")
