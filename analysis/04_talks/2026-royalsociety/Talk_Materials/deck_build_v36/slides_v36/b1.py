"""B1 — BACKUP Q&A: Depensation / predator pit (Walters & Kitchell 2001)."""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_b1(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "BACKUP Q&A · B1", dark=False)

    # h1 — the question
    title_h1(s,
             "Depensation / predator pit — isn't this just Walters & Kitchell 2001?",
             dark=False, x=0.4, y=0.7, w=12.5, h=1.0, size=24)

    # Amber rule
    add_amber_rule(s, 0.4, 2.0, 12.5)

    # Body — calibrated answer
    body = (
        "The predator pit is the one classical mechanism we keep by name, and we "
        "frame it precisely as the leading hypothesis at S22 — not a proven HG "
        "coefficient. The contribution is that depensation is one of three "
        "slow-variable losses running in parallel (rising synchrony, age "
        "truncation / GWOF, recovered predators), and the binding constraint on "
        "recovery is the eroded spatial portfolio — which depensation theory "
        "alone doesn't capture and which coastwide single-species management "
        "does not measure."
    )
    add_text(s, body,
             0.4, 2.25, 12.5, 4.4,
             font=BODY, size=16, color=C_INK_DARK, dark=False,
             line_spacing=1.4)

    # Footer mono source
    add_text(s,
             "Walters & Kitchell 2001 · Stier et al. 2020 · DFO Pacific Herring SR 2024/2025 · "
             "2024 HG Herring Rebuilding Plan.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=9, color=C_SOFT_D,
             align=PP_ALIGN.LEFT, dark=False)

    speaker_note(s,
        "Calibrated answer to the depensation / predator pit Reviewer-2 question. "
        "Defend the contribution as architecture, not mechanism — depensation is "
        "one of three slow-variable losses; the binding constraint is the eroded "
        "spatial portfolio.")
