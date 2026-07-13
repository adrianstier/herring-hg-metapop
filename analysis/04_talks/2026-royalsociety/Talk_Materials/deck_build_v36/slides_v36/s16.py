"""S16 — Model output: predicted pattern at two scales (text-only preview card)

Build-phase note: the m1_stier_11 posterior figure is not yet rendered to a
publication-quality PNG for talk use. This slide is a clean text-led card
describing what the model predicts at two scales. NO 'ASSET NEEDED' placeholder
must ever be visible on stage.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s16(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker + h1
    kicker(s, "MODEL OUTPUT", dark=False)

    title_h1(s, "What the model predicts — at two scales.",
             dark=False,
             x=0.4, y=0.7, w=12.5, h=0.7, size=30)

    # Subtitle (italic)
    add_text(s,
             "Variation among subpopulations + declines across most sections "
             "+ archipelago aggregate.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=18, italic=True,
             color=C_SOFT_D, dark=False)

    # ── Two-column "model output preview" cards ──────────────────────────────
    # Geometry: two equal cards spanning the central content area
    gutter = 0.4
    card_w = 5.9
    card_h = 4.0
    total_w = card_w * 2 + gutter
    left_x = (DECK_W_IN - total_w) / 2.0
    right_x = left_x + card_w + gutter
    card_y = 2.2

    # Card frames (light rectangle outlines, very subtle)
    for cx in (left_x, right_x):
        # Soft frame: thin rule-colored stroke via thin rect (use a very thin
        # rectangle border by stacking a slightly-larger frame behind)
        frame = s.shapes.add_shape(MSO_SHAPE.RECTANGLE,
                                   Inches(cx), Inches(card_y),
                                   Inches(card_w), Inches(card_h))
        frame.fill.background()
        frame.line.color.rgb = C_SOFT
        frame.line.width = Pt(0.75)
        frame.shadow.inherit = False

    # Top amber rule + column header (left)
    add_amber_rule(s, left_x + 0.3, card_y + 0.35, 0.9)
    add_text(s, "ARCHIPELAGO AGGREGATE",
             left_x + 0.3, card_y + 0.45, card_w - 0.6, 0.4,
             font=MONO, size=12, bold=True, color=C_RUST, dark=False)

    add_text(s,
             "Posterior median + 95% CI",
             left_x + 0.3, card_y + 0.95, card_w - 0.6, 0.5,
             font=HEAD, size=22, bold=True, color=C_INK_DARK, dark=False)

    add_text(s,
             "1950 — 2024",
             left_x + 0.3, card_y + 1.55, card_w - 0.6, 0.4,
             font=MONO, size=12, color=C_SOFT_D, dark=False)

    add_text(s,
             "Spawning biomass at the regional scale: a single posterior "
             "trajectory with credible bounds, summarising the eleven "
             "subpopulations as one archipelago-level signal.",
             left_x + 0.3, card_y + 2.05, card_w - 0.6, 1.7,
             font=BODY, size=14, italic=True, color=C_SOFT_D, dark=False,
             line_spacing=1.3)

    # Top amber rule + column header (right)
    add_amber_rule(s, right_x + 0.3, card_y + 0.35, 0.9)
    add_text(s, "11 SUBPOPULATIONS",
             right_x + 0.3, card_y + 0.45, card_w - 0.6, 0.4,
             font=MONO, size=12, bold=True, color=C_RUST, dark=False)

    add_text(s,
             "Per-section trajectories",
             right_x + 0.3, card_y + 0.95, card_w - 0.6, 0.5,
             font=HEAD, size=22, bold=True, color=C_INK_DARK, dark=False)

    add_text(s,
             "with uncertainty bands · majority declining",
             right_x + 0.3, card_y + 1.55, card_w - 0.6, 0.4,
             font=MONO, size=12, color=C_SOFT_D, dark=False)

    add_text(s,
             "Cove-scale dynamics resolved separately: heterogeneous declines "
             "with a few stable or recovering sites, but most sections "
             "trending down post-1990s.",
             right_x + 0.3, card_y + 2.05, card_w - 0.6, 1.7,
             font=BODY, size=14, italic=True, color=C_SOFT_D, dark=False,
             line_spacing=1.3)

    # Caption text below the cards
    cap_y = card_y + card_h + 0.18
    add_text(s,
             "Aggregate spawn-biomass posterior + 11-section trajectories",
             0.4, cap_y, 12.5, 0.4,
             font=BODY, size=14, italic=True,
             color=C_SOFT_D, align=PP_ALIGN.CENTER, dark=False)

    # Footer
    credit(s, "Source: m1_stier_11 (Output/diagnostics/).",
           dark=False, y=7.0)

    speaker_note(s,
        "This is the model's view of the system. At the regional scale and at "
        "the local scale. We're not interpreting the mechanism here — that "
        "comes next. We're just showing that the model predicts heterogeneous "
        "patterns. The majority of subpopulations have declined. The archipelago "
        "aggregate is below where it was. So that sets up the rest: we're going "
        "to interrogate the drivers of these patterns in the slides that follow.")
