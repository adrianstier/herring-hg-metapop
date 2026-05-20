"""S21 — Two ultimate mechanisms — title card (text-only)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s21(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "WHY THE DOOR HASN'T REOPENED", dark=False)
    title_h1(s, "Two complementary mechanisms.", dark=False,
             x=0.4, y=0.7, w=12.5, h=0.9, size=34)

    # ── Two cards, ~5.5 × 4 in, with breathing room ──────────────────────
    card_w = 5.5
    card_h = 4.0
    gutter = 0.4
    total_w = card_w * 2 + gutter
    left_x = (DECK_W_IN - total_w) / 2.0   # center horizontally
    card_y = 2.4
    right_x = left_x + card_w + gutter

    # ── LEFT CARD: Recovered Predator Pit ─────────────────────────────────
    # Thin amber rule on top
    add_amber_rule(s, left_x, card_y, card_w)

    # Header (mono, rust)
    add_text(s, "1 · RECOVERED PREDATOR PIT",
             left_x, card_y + 0.25, card_w, 0.5,
             font=MONO, size=14, bold=True, color=C_RUST, dark=False)

    # Body italic
    add_text(s,
        "Wide-ranging predators correlate the assets.",
        left_x, card_y + 1.1, card_w, card_h - 1.2,
        font=HEAD, size=22, italic=True, color=C_INK_DARK, dark=False,
        line_spacing=1.3)

    # ── RIGHT CARD: Lost Elders / GWOF ────────────────────────────────────
    add_amber_rule(s, right_x, card_y, card_w)

    add_text(s, "2 · LOST ELDERS / GWOF",
             right_x, card_y + 0.25, card_w, 0.5,
             font=MONO, size=14, bold=True, color=C_RUST, dark=False)

    add_text(s,
        "The migration knowledge held by repeat-spawners has been truncated.",
        right_x, card_y + 1.1, card_w, card_h - 1.2,
        font=HEAD, size=22, italic=True, color=C_INK_DARK, dark=False,
        line_spacing=1.3)

    # ── Speaker note: verbatim Spoken from outline ────────────────────────
    speaker_note(s,
        "We think two mechanisms are most likely. One: a recovered predator "
        "field that creates a kind of predator pit. Two: lost elders — the "
        "knowledge of where to spawn that's held by older repeat-spawners. "
        "We look at each.")
