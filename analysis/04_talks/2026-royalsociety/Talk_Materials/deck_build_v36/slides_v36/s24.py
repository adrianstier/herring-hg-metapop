"""S24 — Results summary: five things"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s24(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "WHAT WE FOUND", dark=False)
    title_h1(s, "Five things.", dark=False,
             x=0.4, y=0.65, w=12.5, h=0.9, size=34)

    # ── RIGHT 35% — optional anchoring image ──────────────────────────────
    img_w = 4.4
    img_h = 4.4
    img_x = DECK_W_IN - img_w - 0.4
    img_y = 1.9
    takeaways = asset_opt("13_takeaways.png")
    if takeaways is not None:
        add_image(s, takeaways, img_x, img_y, w=img_w, h=img_h)
        bullets_w = img_x - 0.6           # leave gap
    else:
        bullets_w = DECK_W_IN - 0.8

    # ── LEFT 65% — five short bullets ─────────────────────────────────────
    bullets_x = 0.4
    bullets_y = 1.9

    bullets = [
        "Aggregate biomass partly rebounds — but spatial structure has collapsed.",
        "Synchrony rose ~60% post-1994; bad years are bad years everywhere.",
        "Productivity drained ~8-fold across subpopulations.",
        "Ocean conditions are necessary but not the barrier.",
        "Recovered predators + lost elders are the leading mechanisms — both "
        "consistent with the data, neither yet proven causally.",
    ]

    runs = []
    for i, b in enumerate(bullets):
        # Number marker (rust mono) + bullet text (Calibri body)
        runs.append({"text": f"{i+1}  ", "font": MONO, "size": 16,
                     "bold": True, "color": C_RUST,
                     "new_para": True if i > 0 else False})
        runs.append({"text": b, "font": BODY, "size": 19,
                     "color": C_INK_DARK})

    add_multi_text(s, runs, bullets_x, bullets_y, bullets_w, 4.8,
                   line_spacing=1.45)

    # ── Speaker note: verbatim Spoken from outline ────────────────────────
    speaker_note(s,
        "To pull it together. Five things. Aggregate biomass is partly "
        "rebounding — but the spatial structure that supported it has "
        "collapsed. Synchrony rose about sixty percent after 1994 — bad "
        "years are bad years everywhere. Productivity drained about "
        "eight-fold across subpopulations. Ocean conditions are necessary "
        "but they're not the barrier. And the two leading mechanisms — "
        "recovered predators and lost elders — are both consistent with "
        "the data, neither yet proven causally.")
