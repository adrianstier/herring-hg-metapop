"""X1 — BACKUP: Portfolio theory (diversification removes variance, not yield).

LIGHT background. Embed sim_anim_v2.mp4 LEFT 60%. Sidebar RIGHT 40%.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_x1(prs):
    s = add_slide(prs, dark=False)

    # Kicker + h1
    kicker(s, "BACKUP · PORTFOLIO THEORY", dark=False)
    title_h1(s, "Diversification removes variance, not yield.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.7, size=28)

    # Subtitle (italic)
    add_text(s,
             "The resilience of wildly variable systems lives in their structure — not their mean.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=16, italic=True,
             color=C_SOFT_D, dark=False)

    # ── LEFT 60% — embedded video ──────────────────────────────────────────
    video_x = 0.4
    video_y = 2.1
    video_w = DECK_W_IN * 0.60 - 0.5   # ~7.5"
    video_h = 4.5

    video_path = asset("sim_anim_v2.mp4")
    poster_path = asset_opt("sim_anim_v2_poster.jpg")
    try:
        add_video(s, video_path, poster_path,
                  video_x, video_y, video_w, video_h)
    except Exception:
        if poster_path:
            add_image(s, poster_path, video_x, video_y, w=video_w, h=video_h)

    # Window callout top-right OF FIGURE (overlaid as mono small)
    add_text(s, "Haida Gwaii spawn-thickness · 1950–1967 · 11 sections",
             video_x, video_y - 0.30, video_w, 0.3,
             font=MONO, size=9, color=C_RUST, align=PP_ALIGN.RIGHT, dark=False)

    # ── RIGHT 40% sidebar ──────────────────────────────────────────────────
    right_x = DECK_W_IN * 0.60 + 0.2   # ~8.2"
    right_w = DECK_W_IN - right_x - 0.4  # ~4.7"

    cy = video_y

    # Sidebar header — mono
    add_text(s, "WHAT IS A PORTFOLIO?",
             right_x, cy, right_w, 0.4,
             font=MONO, size=12, bold=True, color=C_RUST, dark=False)
    cy += 0.45

    add_amber_rule(s, right_x, cy, right_w - 0.3)
    cy += 0.20

    # Body Calibri
    add_multi_text(s, [
        {"text": "Markowitz, 1952",
         "font": BODY, "size": 16, "bold": True, "color": C_INK_DARK},
        {"text": " — diversification removes variance, not yield.",
         "font": BODY, "size": 16, "color": C_INK_DARK},

        {"text": "Same math in ecology",
         "font": BODY, "size": 16, "bold": True, "color": C_INK_DARK,
         "new_para": True},
        {"text": " — a metapopulation of asynchronous sub-stocks IS a portfolio.",
         "font": BODY, "size": 16, "color": C_INK_DARK},

        {"text": "Schindler et al. 2010 Nature",
         "font": BODY, "size": 16, "bold": True, "color": C_INK_DARK,
         "new_para": True},
        {"text": " — Bristol Bay sockeye demonstration.",
         "font": BODY, "size": 16, "color": C_INK_DARK},
    ], right_x, cy, right_w, 4.0, line_spacing=1.35)

    # Footer source strip — bottom-right
    credit(s,
           "Markowitz 1952 · Schindler et al. 2010 · Doak et al. · Tilman · Loreau & de Mazancourt.",
           dark=False, y=7.05)

    speaker_note(s,
        "Quick detour into the theory. In 1952 an economist named Harry "
        "Markowitz won a Nobel Prize for showing that if you hold a portfolio "
        "of assets that don't all move together — that are imperfectly "
        "correlated — you get the same long-run return as any one of them "
        "but with much less variance. Diversification removes risk without "
        "removing yield. In ecology, it's the same math. A metapopulation of "
        "asynchronous sub-stocks IS a portfolio. From 1950 to the late 1960s, "
        "this is what the Haida Gwaii data look like — eleven coves, each on "
        "its own clock, and the regional whole stays steady. Schindler and "
        "colleagues showed this for Bristol Bay sockeye in 2010. The "
        "structure does the work. Asynchrony IS the buffer.")
