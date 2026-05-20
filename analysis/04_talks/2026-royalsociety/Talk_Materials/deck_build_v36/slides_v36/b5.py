"""B5 — BACKUP Q&A: kʼaaw never went away — Gladstone affirmed rights.

Doesn't that contradict your access tipping-point claim?

kʼaaw framing: "the right and the ritual persisted; access did not."
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_b5(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "BACKUP Q&A · B5", dark=False)

    # h1 — the question
    title_h1(s,
             "kʼaaw never went away — Gladstone affirmed commercial rights, "
             "FSC harvest continued. Doesn't that contradict your access "
             "tipping-point claim?",
             dark=False, x=0.4, y=0.7, w=12.5, h=1.6, size=20)

    # Amber rule
    add_amber_rule(s, 0.4, 2.5, 12.5)

    # Body — calibrated answer (uses exact phrasing per claim-control)
    body = (
        "The right and the ritual persisted — that's deliberately how X4 phrases "
        "it. But the Rebuilding Plan (2024) is explicit: Haida traditional "
        "fisheries have been constrained for several decades by low herring "
        "abundances in the traditional fishing areas. DFO sets a 150-ton FSC "
        "allocation the Haida Nation has not agreed to; commercial roe has "
        "been closed since 2002; SOK since 2004; harvest = 0 t in 2025. "
        "Sporadic FSC harvests (2006–08, 2011) required chartering vessels "
        "because the local fleet and processing infrastructure had already "
        "decayed. Gladstone affirmed Heiltsuk — not Haida — commercial roe "
        "rights; DFO does not recognize Haida commercial title. So the right "
        "surviving is not the same as access surviving. That asymmetry — "
        "right persists, access doesn't — IS the access tipping point."
    )
    add_text(s, body,
             0.4, 2.75, 12.5, 4.1,
             font=BODY, size=15, color=C_INK_DARK, dark=False,
             line_spacing=1.35)

    # Footer mono source
    add_text(s,
             "R. v. Gladstone 1996 · 2024 HG Herring Rebuilding Plan · "
             "DFO IFMP · Stier et al. 2020 · Powell 2012.",
             0.4, 7.10, DECK_W_IN - 0.8, 0.3,
             font=MONO, size=9, color=C_SOFT_D,
             align=PP_ALIGN.LEFT, dark=False)

    speaker_note(s,
        "Calibrated answer to the kʼaaw / Gladstone question. The right and "
        "the ritual persisted; access did not. Rebuilding Plan 2024 explicit "
        "on constraint by low abundance and decayed infrastructure. Gladstone "
        "affirmed Heiltsuk, not Haida.")
