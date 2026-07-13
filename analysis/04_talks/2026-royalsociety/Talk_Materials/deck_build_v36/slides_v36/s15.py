"""S15 — How we know: methods grid (2×2, text-only)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s15(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker + h1
    kicker(s, "HOW WE KNOW", dark=False)

    title_h1(s,
             "Seventy-five years of data; ten thousand years of context; "
             "eleven subpopulations resolved.",
             dark=False,
             x=0.4, y=0.7, w=12.5, h=1.2, size=24)

    # 2×2 grid of method cards (each ~5.5 × 2 in)
    # Start at y=2.4. Two rows × two columns with gutters.
    card_w, card_h = 5.5, 2.0
    gutter_x = 0.5
    gutter_y = 0.5
    grid_w = 2 * card_w + gutter_x
    left_x = (DECK_W_IN - grid_w) / 2.0  # center horizontally
    top_y = 2.4

    cards = [
        # row, col, header, body
        (0, 0, "DATA",
         "DFO spawn-thickness surveys 1950–present · 11 sections"),
        (0, 1, "BASELINE",
         "Archaeological record · ~10,700 yr (S9)"),
        (1, 0, "MODEL",
         "Bayesian state-space metapopulation · m1_stier_11"),
        (1, 1, "PREDATORS",
         "Audited external pressure · never fitted"),
    ]

    for row, col, header, body in cards:
        cx = left_x + col * (card_w + gutter_x)
        cy = top_y + row * (card_h + gutter_y)

        # Thin amber rule on top of each card
        add_amber_rule(s, cx, cy, card_w)

        # Header (mono, rust) below the amber rule
        add_text(s, header,
                 cx, cy + 0.12, card_w, 0.4,
                 font=MONO, size=12, bold=True, color=C_RUST, dark=False)

        # Body text below header (Calibri)
        add_text(s, body,
                 cx, cy + 0.65, card_w, card_h - 0.7,
                 font=BODY, size=16, color=C_INK_DARK, dark=False,
                 line_spacing=1.25)

    speaker_note(s,
        "How do we interrogate this? Seventy-five years of DFO spawn-thickness "
        "data, resolved at eleven sub-population sites. Ten thousand years of "
        "archaeological baseline. A Bayesian state-space metapopulation model — "
        "m1-stier-11 — across the sub-population network. Predator demand enters "
        "as an audited external pressure, never as a fitted parameter. So we can "
        "interrogate the suspects.")
