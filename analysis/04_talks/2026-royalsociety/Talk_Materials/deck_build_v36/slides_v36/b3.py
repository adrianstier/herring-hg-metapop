"""B3 — BACKUP Q&A: How would you operationalise an EWS? Isn't CSD fragile?"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_b3(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "BACKUP Q&A · B3", dark=False)

    # h1 — the question
    title_h1(s,
             "How would you operationalise an EWS for an ES tipping point? "
             "Isn't CSD fragile?",
             dark=False, x=0.4, y=0.7, w=12.5, h=1.2, size=24)

    # Amber rule
    add_amber_rule(s, 0.4, 2.1, 12.5)

    # Body — calibrated answer
    body = (
        "Yes — CSD needs dense time series and produces false alarms. We're not "
        "proposing CSD on biomass. The honest framing is to monitor the slow "
        "variables themselves — spatial synchrony, portfolio breadth, the age "
        "structure that carries the migratory map — as resilience-state "
        "indicators, not bifurcation predictors. We're labelling spatial "
        "early-warning as a research frontier, not a deployed signal "
        "(S28 frontier line, one hedge)."
    )
    add_text(s, body,
             0.4, 2.35, 12.5, 4.4,
             font=BODY, size=16, color=C_INK_DARK, dark=False,
             line_spacing=1.4)

    # Footer mono source
    add_text(s,
             "Scheffer et al. 2009 Nature · Dakos et al. 2008 PNAS · "
             "Stier et al. 2020 Ecosphere · this talk S28.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=9, color=C_SOFT_D,
             align=PP_ALIGN.LEFT, dark=False)

    speaker_note(s,
        "Calibrated answer to the EWS / CSD-fragility question. Pre-emptive "
        "concession on fragility of CSD; redirect to slow-variable state "
        "monitoring as resilience-state indicators, not bifurcation predictors.")
