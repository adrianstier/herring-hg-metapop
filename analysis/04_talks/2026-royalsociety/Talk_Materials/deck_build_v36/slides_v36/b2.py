"""B2 — BACKUP Q&A: Biomass IS partly rebuilding — doesn't that falsify non-recovery?"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_b2(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "BACKUP Q&A · B2", dark=False)

    # h1 — the question
    title_h1(s,
             "Biomass IS partly rebuilding — doesn't that falsify the non-recovery story?",
             dark=False, x=0.4, y=0.7, w=12.5, h=1.0, size=24)

    # Amber rule
    add_amber_rule(s, 0.4, 2.0, 12.5)

    # Body — calibrated answer
    body = (
        "It supports it. Per the claim-control sheet: recent biomass partly "
        "rebounds but remains concentrated; local section recovery is uneven "
        "and portfolio diversity remains low — do not equate total biomass "
        "with recovered ES function. The driver was reduced but the service "
        "trajectory has not retraced the collapse path — once-richest spawn "
        "sites stay empty while regional biomass partly rebounds. That "
        "dissociation IS the point."
    )
    add_text(s, body,
             0.4, 2.25, 12.5, 4.4,
             font=BODY, size=16, color=C_INK_DARK, dark=False,
             line_spacing=1.4)

    # Footer mono source
    add_text(s,
             "DFO Pacific Herring SR 2024/2025 · 2024 HG Herring Rebuilding Plan · "
             "Stier et al. 2020 Ecosphere.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=9, color=C_SOFT_D,
             align=PP_ALIGN.LEFT, dark=False)

    speaker_note(s,
        "Calibrated answer to the biomass-rebuilding Reviewer-2 question. "
        "Turn the gotcha into evidence for the talk's thesis — concentrated, "
        "not recovered; ES function tracks portfolio breadth, not aggregate "
        "biomass.")
