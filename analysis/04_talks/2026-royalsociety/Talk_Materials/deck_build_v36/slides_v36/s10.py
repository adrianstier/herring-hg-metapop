"""S10 — Commercial fishery: high-mobility seine fleet · staging behaviour"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s10(prs):
    s = add_slide(prs, dark=False)

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "THE COMMERCIAL FISHERY", dark=False)
    title_h1(s, "High-mobility seine fleet · staging behaviour",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.9, size=28)

    # Subtitle italic
    add_text(s,
             "Cove-to-cove since the early 1900s — capturing fish as they stage to spawn.",
             0.4, 1.45, 12.5, 0.45,
             font=HEAD, size=15, italic=True, color=C_SOFT_D, dark=False)

    # ── LEFT 60%: motion clip ──────────────────────────────────────────────
    add_video(
        s,
        video_path=clip("v1_04_aerial_seine_net.mp4"),
        poster_path=poster("v1_04_aerial_seine_net.jpg"),
        x=0.4, y=2.0, w=7.6, h=4.7,
    )

    # ── RIGHT 40%: text-only schematic card ────────────────────────────────
    rx = 8.4
    rw = 4.6
    # Card background — soft rect (uses very light rule-color tint by drawing
    # a faint outlined rectangle). Keep clean: amber rule + mono lines + arrows.

    add_amber_rule(s, rx, 2.0, 1.0)
    add_text(s, "STAGING-AND-CATCH",
             rx, 2.12, rw, 0.4,
             font=MONO, size=10, bold=True, color=C_RUST, dark=False)

    # Schematic as text — mono, centered, with unicode down arrows.
    # Build line-by-line via add_multi_text for vertical rhythm.
    add_multi_text(s, [
        {"text": "[ ship offshore ]", "font": MONO, "size": 14, "bold": True,
         "color": C_INK_DARK},
        {"text": "↓", "font": HEAD, "size": 20, "color": C_RUST,
         "italic": False, "new_para": True},
        {"text": "[ cove 1: STAGE + CATCH ]", "font": MONO, "size": 14,
         "bold": True, "color": C_INK_DARK, "new_para": True},
        {"text": "↓", "font": HEAD, "size": 20, "color": C_RUST,
         "new_para": True},
        {"text": "[ ship moves ]", "font": MONO, "size": 14, "bold": True,
         "color": C_INK_DARK, "new_para": True},
        {"text": "↓", "font": HEAD, "size": 20, "color": C_RUST,
         "new_para": True},
        {"text": "[ cove 2: STAGE + CATCH ]", "font": MONO, "size": 14,
         "bold": True, "color": C_INK_DARK, "new_para": True},
    ], rx, 2.7, rw, 4.0, align=PP_ALIGN.CENTER, line_spacing=1.1)

    # Footer note under schematic
    add_text(s, "early 1900s → present",
             rx, 6.55, rw, 0.35,
             font=MONO, size=10, italic=True, color=C_SOFT_D,
             align=PP_ALIGN.CENTER, dark=False)

    # ── Footage credit ─────────────────────────────────────────────────────
    footage_credit(s, dark=False, text="Footage: Pacific Wild")

    speaker_note(s,
        "The commercial fishery has been working these coves since the early "
        "nineteen-hundreds. It uses seine nets — high-mobility vessels moving "
        "cove to cove, catching herring as they stage just before they rush in "
        "to spawn. The fleet goes where the fish are. That mobility — that "
        "ability to fish wherever the schools concentrate — is what makes the "
        "cove-scale harvest rates so high, as we'll see.")
