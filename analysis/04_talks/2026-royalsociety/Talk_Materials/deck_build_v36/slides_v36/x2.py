"""X2 — BACKUP: Portfolio came apart (synchrony rose at 1994).

LIGHT background. Same sim animation as X1 (continuation).
Synchrony EXACTLY 0.17 → 0.28 per claim-control.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_x2(prs):
    s = add_slide(prs, dark=False)

    # Kicker + h1
    kicker(s, "BACKUP · PORTFOLIO CAME APART", dark=False)
    title_h1(s, "The parts came into phase.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.7, size=28)

    # Subtitle (italic)
    add_text(s,
             "Synchrony rose substantially post-1994; the buffer disappeared.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=16, italic=True,
             color=C_SOFT_D, dark=False)

    # ── LEFT 60% — embedded video (or fallback) ────────────────────────────
    video_x = 0.4
    video_y = 2.1
    video_w = DECK_W_IN * 0.60 - 0.5
    video_h = 4.5

    try:
        video_path = asset("sim_anim_v2.mp4")
        poster_path = asset_opt("sim_anim_v2_poster.jpg")
        add_video(s, video_path, poster_path,
                  video_x, video_y, video_w, video_h)
    except Exception:
        # Fall back to 09_synchrony.png
        fb = asset_opt("09_synchrony.png") or asset_opt("sim_anim_v2_poster.jpg")
        if fb:
            add_image(s, fb, video_x, video_y, w=video_w, h=video_h)

    # ── RIGHT 40% sidebar — DATA CALLOUT ───────────────────────────────────
    right_x = DECK_W_IN * 0.60 + 0.2
    right_w = DECK_W_IN - right_x - 0.4

    cy = video_y

    add_text(s, "DATA CALLOUT",
             right_x, cy, right_w, 0.4,
             font=MONO, size=12, bold=True, color=C_RUST, dark=False)
    cy += 0.50

    # Big synchrony number
    add_text(s, "φ: 0.17 → 0.28",
             right_x, cy, right_w, 0.9,
             font=HEAD, size=36, bold=True, color=C_INK_DARK, dark=False)
    cy += 1.0

    # +>60% increase
    add_text(s, "+>60% increase post-1994",
             right_x, cy, right_w, 0.5,
             font=BODY, size=18, bold=True, color=C_INK_DARK, dark=False)
    cy += 0.65

    # Amber rule
    add_amber_rule(s, right_x, cy, right_w - 0.3)
    cy += 0.20

    # Italic gloss
    add_text(s, "Value lagged structure by a decade.",
             right_x, cy, right_w, 1.0,
             font=HEAD, size=16, italic=True, color=C_SOFT_D, dark=False,
             line_spacing=1.3)

    # Source footer
    credit(s, "Source: Stier et al. 2020 Ecosphere.",
           dark=False, y=7.05)

    speaker_note(s,
        "And then something changed. Around 1994, the cove-level cycles started "
        "to come into phase with each other. Synchrony rose more than sixty "
        "percent — what you're watching is the portfolio coming apart. "
        "Asynchronous sub-stocks were buffering the whole; when they come into "
        "phase, the buffer disappears. And here's the load-bearing finding: "
        "total roe value held high through the 1980s while the structure that "
        "produced it was already failing. Value lagged structure by a decade. "
        "The catch statistics told the right story — too late.")
