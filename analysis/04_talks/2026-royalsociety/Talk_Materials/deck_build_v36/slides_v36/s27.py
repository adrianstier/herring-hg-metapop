"""S27 — Three transferable lessons (text-only, spare)."""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s27(prs):
    s = add_slide(prs, dark=False)

    # Kicker + h1
    kicker(s, "LESSONS", dark=False)
    title_h1(s, "What this teaches.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.8, size=30)

    # Three numbered rows centered
    rows = [
        ("1",
         "Condition reference points on the current system state.",
         "SB₀ is pinned to a baseline the system has left."),
        ("2",
         "Match management scale to biological scale.",
         "The portfolio IS the resilience; you cannot manage it at a scale "
         "finer than the data you take."),
        ("3",
         "Manage ecological, cultural, and economic resources together.",
         "They came apart; only co-governance spans all three keystones."),
    ]

    row_h = 1.5
    row_w = 11.0
    row_x = (DECK_W_IN - row_w) / 2.0
    top_y = 2.1

    for i, (num, lead, gloss) in enumerate(rows):
        ry = top_y + i * row_h

        # Amber rule atop each row
        add_amber_rule(s, row_x, ry, row_w - 0.4)

        # Mono number left (rust)
        add_text(s, num,
                 row_x, ry + 0.12, 0.6, 0.7,
                 font=MONO, size=22, bold=True, color=C_RUST,
                 align=PP_ALIGN.LEFT, dark=False)

        # Bold lead line (Georgia 22pt)
        add_text(s, lead,
                 row_x + 0.7, ry + 0.10, row_w - 0.7, 0.6,
                 font=HEAD, size=22, bold=True, color=C_INK_DARK, dark=False)

        # Gloss explanation (Calibri 16pt italic)
        add_text(s, gloss,
                 row_x + 0.7, ry + 0.70, row_w - 0.7, 0.7,
                 font=BODY, size=16, italic=True, color=C_SOFT_D, dark=False,
                 line_spacing=1.3)

    speaker_note(s,
        "Three transferable lessons. First: condition reference points on the "
        "current state. SB-zero is pinned to a baseline this system has left; "
        "below-LRP is by construction. Second: match management scale to "
        "biological scale. The portfolio IS the resilience. Manage it at the "
        "cove scale. Third: in coupled systems, manage the ecological and the "
        "social-economic tip together — they came apart, and only co-governance "
        "spans all three keystones.")
