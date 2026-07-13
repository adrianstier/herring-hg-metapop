"""B4 — BACKUP Q&A: Aren't you over-claiming culture as a slow variable?"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_b4(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "BACKUP Q&A · B4", dark=False)

    # h1 — the question
    title_h1(s,
             "Aren't you over-claiming the ecological role of culture? "
             "Indigenous cultural transmission isn't a Holling slow variable.",
             dark=False, x=0.4, y=0.7, w=12.5, h=1.4, size=22)

    # Amber rule
    add_amber_rule(s, 0.4, 2.3, 12.5)

    # Body — calibrated answer
    body = (
        "We're claiming cultural transmission acted as a slow variable in the "
        "SES sense — it shaped the harvest feedback (cove-scale, mobile, kʼaaw "
        "non-lethal) that kept the system inside its basin for >10,000 years. "
        "When that feedback was overridden by aggregate single-species quota, "
        "the system was pushed; when the institution was rebuilt to span both "
        "clocks (2024 Rebuilding Plan, AMB co-governance), the management "
        "changed. Co-equal third pillar, not decoration — and the convergence "
        "of Haida knowledge (Guujaaw) with the GWOF science is the on-slide "
        "evidence (S23)."
    )
    add_text(s, body,
             0.4, 2.55, 12.5, 4.3,
             font=BODY, size=16, color=C_INK_DARK, dark=False,
             line_spacing=1.4)

    # Footer mono source
    add_text(s,
             "McKechnie et al. 2014 PNAS · Berkes 2012 · Folke et al. 2005 · "
             "MacCall et al. 2019 · Ono et al. 2025 · 2024 HG Herring Rebuilding Plan.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=9, color=C_SOFT_D,
             align=PP_ALIGN.LEFT, dark=False)

    speaker_note(s,
        "Calibrated answer to the culture-as-slow-variable question. Defend the "
        "cultural keystone as analytically substantive, not decorative — "
        "cultural transmission acted as a slow variable in the SES sense; "
        "the Haida–GWOF convergence is the on-slide evidence.")
