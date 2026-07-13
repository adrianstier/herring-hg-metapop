"""S22 — Mechanism: Recovered predators (leading hypothesis, claim-control safe)

CLAIM-CONTROL CRITICAL:
  - ⅓ standing stock (~29% removal analogue) — NOT 239%.
  - Synchrony 0.17 → 0.28 — NOT 0.31 → 0.40.
  - Frame as LEADING HYPOTHESIS, never as proven causation.
  - Footage credit: Pacific Wild (sea-lion clip/poster).
"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s22(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "MECHANISM: RECOVERED PREDATORS", dark=False)
    title_h1(s, "The mouth is bigger, and it's a portfolio-killer.",
             dark=False, x=0.4, y=0.65, w=12.5, h=0.9, size=28)

    # ── LEFT 55% — sea-lion colony poster image ──────────────────────────
    # Use poster (still image fallback per outline; clip is also acceptable
    # but poster keeps the slide light on motion since S22 is information-dense).
    img_x = 0.4
    img_y = 1.65
    img_w = DECK_W_IN * 0.52        # ~6.93"
    img_h = 5.0
    add_image(s, poster("v1_15_sea_lion_colony.jpg"),
              img_x, img_y, w=img_w, h=img_h)

    # ── RIGHT 45% — mono callout sequence + headline ──────────────────────
    rx = img_x + img_w + 0.35
    rw = DECK_W_IN - rx - 0.3       # ~5.4"
    cy = 1.65  # cursor

    # Measured: synchrony rose post-1994
    add_text(s, "Measured:  synchrony rose post-1994",
             rx, cy, rw, 0.35,
             font=MONO, size=12, color=C_INK_DARK, dark=False)
    cy += 0.38
    add_text(s, "φ: 0.17 → 0.28  (Stier 2020)",
             rx, cy, rw, 0.35,
             font=MONO, size=13, bold=True, color=C_INK_DARK, dark=False)
    cy += 0.45

    # Amber rule
    add_amber_rule(s, rx, cy, rw - 0.3)
    cy += 0.18

    # Hypothesis framing
    add_text(s, "Hypothesis:  recovered predator field",
             rx, cy, rw, 0.35,
             font=MONO, size=12, color=C_INK_DARK, dark=False)
    cy += 0.38
    add_text(s, "is the leading explanation.",
             rx, cy, rw, 0.35,
             font=MONO, size=12, italic=True, color=C_INK_DARK, dark=False)
    cy += 0.5

    # Amber rule
    add_amber_rule(s, rx, cy, rw - 0.3)
    cy += 0.22

    # BIG Georgia callout — ⅓ standing stock (NOT 239%)
    add_text(s,
        "Predator demand ≈ ⅓ of standing stock",
        rx, cy, rw, 0.7,
        font=HEAD, size=20, bold=True, italic=True,
        color=C_RUST, dark=False, line_spacing=1.15)
    cy += 0.78

    add_text(s, "(~29% removal analogue)",
             rx, cy, rw, 0.35,
             font=BODY, size=12, italic=True, color=C_SOFT_D, dark=False)
    cy += 0.5

    # Footnote — claim-control language
    add_text(s,
        "Leading hypothesis — NOT a fitted HG coefficient (claim-control).",
        rx, cy, rw, 0.5,
        font=MONO, size=9.5, italic=True, color=C_SOFT_D, dark=False,
        line_spacing=1.25)

    # ── Footage credit (Pacific Wild — required) ──────────────────────────
    footage_credit(s, dark=False, text="Footage: Pacific Wild")

    # ── Speaker note: verbatim Spoken from outline ────────────────────────
    speaker_note(s,
        "First, a recovered predator field. The synchrony rise is measured. "
        "The leading hypothesis is that wide-ranging predators — humpbacks, "
        "sea lions — homogenise prey by hunting everywhere at once. They "
        "correlate the assets. Theory predicts this signature. Predator "
        "demand today is roughly a third of the standing stock — about a "
        "twenty-nine percent removal analogue. This isn't just about whales. "
        "Harbour seals doubled-and-doubled-again, Steller sea lions more "
        "than quadrupled. This increase could plausibly explain both the "
        "rise in synchrony and the failure of overall population growth.")
