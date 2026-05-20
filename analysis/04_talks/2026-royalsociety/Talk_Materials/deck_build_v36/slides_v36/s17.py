"""S17 — THE PORTFOLIO CHANGE: synchrony rose after the most recent collapse

CLAIM-CONTROL CRITICAL: synchrony φ: 0.17 → 0.28 (>60% increase).
NOT 0.31 → 0.40 (that was an old/incorrect pair).
Source: Stier et al. 2020 Ecosphere.
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s17(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # Kicker + h1
    kicker(s, "THE PORTFOLIO CHANGE", dark=False)

    title_h1(s, "The parts came into phase.",
             dark=False,
             x=0.4, y=0.7, w=12.5, h=0.7, size=30)

    # Subtitle (italic)
    add_text(s, "Bad years became bad years everywhere.",
             0.4, 1.45, 12.5, 0.5,
             font=HEAD, size=18, italic=True,
             color=C_SOFT_D, dark=False)

    # LEFT 60% — embedded video (async→sync animation)
    video_x = 0.4
    video_y = 2.1
    video_w = DECK_W_IN * 0.60 - 0.5   # ~7.5"
    video_h = 4.5
    video_path = asset("sim_anim_v2.mp4")
    poster_path = asset("sim_anim_v2_poster.jpg")
    try:
        add_video(s, video_path, poster_path,
                  video_x, video_y, video_w, video_h)
    except Exception:
        # Fallback to poster image if embedding fails
        add_image(s, poster_path, video_x, video_y, w=video_w, h=video_h)

    # RIGHT 40% — data callouts
    right_x = DECK_W_IN * 0.60 + 0.2   # ~8.2"
    right_w = DECK_W_IN - right_x - 0.4  # ~4.7"

    cy = video_y  # start aligned with top of video

    # Big number: synchrony shift
    add_text(s, "φ: 0.17 → 0.28",
             right_x, cy, right_w, 0.9,
             font=HEAD, size=40, bold=True,
             color=C_RUST, dark=False)
    cy += 1.0

    # Amber rule
    add_amber_rule(s, right_x, cy, right_w - 0.3)
    cy += 0.20

    # "+>60% increase post-1994"
    add_text(s, "+>60% increase post-1994",
             right_x, cy, right_w, 0.5,
             font=BODY, size=18, bold=True,
             color=C_INK_DARK, dark=False)
    cy += 0.7

    # Italic gloss
    add_text(s, "Bad years became bad years everywhere.",
             right_x, cy, right_w, 1.0,
             font=HEAD, size=16, italic=True,
             color=C_SOFT_D, dark=False, line_spacing=1.3)
    cy += 1.4

    # Mono source footer
    add_text(s, "Source: Stier et al. 2020 Ecosphere",
             right_x, cy, right_w, 0.4,
             font=MONO, size=10, color=C_SOFT_D, dark=False)

    speaker_note(s,
        "Here's a pattern: after the most recent collapse, the cove-level "
        "populations became increasingly similar to one another. Not so after "
        "the 1960s collapse — back then the parts were still asynchronous. "
        "Now they move together. Synchrony rose more than sixty percent. "
        "What does that mean? It means bad years are bad years everywhere. "
        "That's bad for the local predators — humpbacks, sea lions, eagles — "
        "that depend on at least one cove being productive. And it's bad for "
        "Haida people who want to be able to go to one site for subsistence "
        "and cultural harvest. When the portfolio collapses, the buffer "
        "disappears. So — why is this happening? Two likely drivers. "
        "We get to those next.")
