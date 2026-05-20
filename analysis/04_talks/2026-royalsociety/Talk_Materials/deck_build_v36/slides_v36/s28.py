"""S28 — The tipping-point question (frontier hedge + final reframe).

This is the ONLY slide besides S1 that uses "tipping point" language (the reframe).
Two-line text-only slide: small frontier line on top, big italic question below.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s28(prs):
    s = add_slide(prs, dark=False)

    # Kicker
    kicker(s, "THE QUESTION", dark=False)

    # ── TOP: frontier line, italic small ───────────────────────────────────
    top_y = 2.0
    top_w = 10.0
    top_x = (DECK_W_IN - top_w) / 2.0

    # Amber rule above top line
    add_amber_rule(s, top_x, top_y, top_w - 0.5)

    add_text(s,
             "Spatial early-warning is an open hypothesis — not a result.",
             top_x, top_y + 0.20, top_w, 0.6,
             font=BODY, size=16, italic=True, color=C_SOFT_D,
             align=PP_ALIGN.LEFT, dark=False)

    # ── BOTTOM: the big question, Georgia italic 26pt centered ─────────────
    bot_y = 4.0
    bot_w = 11.0
    bot_x = (DECK_W_IN - bot_w) / 2.0

    # Amber rule above bottom block
    add_amber_rule(s, bot_x, bot_y, bot_w)

    add_text(s,
             "“And — is this actually a tipping point? I'd argue no. "
             "It looks more like the slow erosion of slow variables, "
             "and the language of bifurcation may be the wrong tool here.”",
             bot_x, bot_y + 0.35, bot_w, 2.6,
             font=HEAD, size=26, italic=True, color=C_INK_DARK,
             align=PP_ALIGN.CENTER, dark=False, line_spacing=1.30)

    speaker_note(s,
        "One open frontier — the early-warning signal may itself be spatial. "
        "A hypothesis from this work, not yet a result. And finally — and "
        "this is the question I want to leave you with. I've been calling "
        "this 'tipping points in ecosystem services' because that's the "
        "session title. But is this actually a tipping point? I'd argue no. "
        "It looks more like the slow erosion of slow variables. The applied "
        "tools we'd normally use to detect tipping points — we just don't "
        "have enough data in the collapse period to say whether we've "
        "entered a new equilibrium. Something major has happened. It's "
        "unclear if they're stuck in a predator pit, in a new equilibrium, "
        "or in slow drawdown. The language of bifurcation may be the wrong "
        "tool here.")
