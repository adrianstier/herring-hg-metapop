"""S05 — Look closer: cove-scale portfolio + life-history primer sidebar"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s05(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker + title + subtitle
    kicker(s, "LOOK CLOSER", dark=False)
    title_h1(s, "At the cove scale, it's a different story.", dark=False,
             x=0.4, y=0.7, w=12.5, h=0.9, size=30)
    add_text(s,
        "Eleven subpopulations, one archipelago — each cove its own dynasty.",
        0.4, 1.55, 12.5, 0.5,
        font=HEAD, size=16, italic=True, color=C_SOFT_D, dark=False)

    # MAIN figure ~70% width left — y from ~2.2 to ~6.7 (h ~4.5)
    chart_y = 2.2
    chart_h = 4.5
    chart_w = DECK_W_IN * 0.66  # ~8.8"
    chart_img = asset_opt("s05_spawn_index_realdata.png") or asset_opt("08b_subpop_portfolio.png") or asset("sb1_portfolio_periods.png")
    add_image(s, chart_img, 0.4, chart_y, w=chart_w, h=chart_h)

    # RIGHT sidebar ~30%
    side_x = 0.4 + chart_w + 0.3
    side_w = DECK_W_IN - side_x - 0.3

    # Sidebar mono header
    add_text(s, "LIFE HISTORY",
             side_x, chart_y, side_w, 0.4,
             font=MONO, size=11, color=C_RUST, dark=False)

    # Amber rule under header
    add_amber_rule(s, side_x, chart_y + 0.42, 0.8)

    # Three life-history lines
    add_multi_text(s, [
        {"text": "Adults spend most of the year in the open ocean.",
         "font": HEAD, "size": 15, "italic": False, "color": C_INK_DARK},
        {"new_para": True,
         "text": "They return to specific natal coves to spawn.",
         "font": HEAD, "size": 15, "italic": False, "color": C_INK_DARK},
        {"new_para": True,
         "text": "Juveniles follow the older fish on their first round trip out and back — learning the route.",
         "font": HEAD, "size": 15, "italic": False, "color": C_INK_DARK},
    ],
    side_x, chart_y + 0.7, side_w, chart_h - 0.7,
    line_spacing=1.35, dark=False)

    # Source credit bottom
    credit(s,
        "Data: DFO · Stier et al. 2020 · Life-history: McQuinn 1997 / MacCall et al. 2019",
        dark=False, y=7.1)

    speaker_note(s,
        "Step closer. Same fish, same archipelago — but at the cove scale, "
        "almost every section ran on its own clock. Here's why: each cove is "
        "essentially a dynasty. Pacific herring spend most of their lives in "
        "the open ocean, but they return to specific natal coves to spawn — "
        "and the juveniles follow the older fish on their first round trip "
        "out and back, learning the route. Each cove has its own school, its "
        "own institutional memory. So when you stop averaging and start "
        "looking section by section, you see eleven independent clocks. The "
        "whole archipelago looked relatively steady because the parts were "
        "out of phase. When parts are out of phase, the whole is buffered. "
        "That's a portfolio. We'll come back to that. And later — we'll come "
        "back to what happens when the route-keepers, those older spawners, "
        "disappear.")
