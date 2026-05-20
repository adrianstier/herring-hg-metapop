"""S07 — The predators came back"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s07(prs):
    s = add_slide(prs, dark=False)

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "WHAT ELSE CHANGED", dark=False)
    title_h1(s, "The predators came back.", dark=False,
             x=0.4, y=0.7, w=12.5, h=0.9, size=32)

    # ── Hero image LEFT ~60% — sea lion colony still ──────────────────────
    # Frame: x=0.4, y=1.8, w=7.6, h=4.6 (60% of 13.333 ≈ 8.0; leave margin)
    img_x, img_y, img_w, img_h = 0.4, 1.8, 7.6, 4.7
    add_image(s, poster("v1_15_sea_lion_colony.jpg"),
              img_x, img_y, w=img_w, h=img_h)

    # ── RIGHT 40% data callouts ────────────────────────────────────────────
    rx = 8.3
    rw = 4.6

    # Callout 1 — Humpback whales
    add_multi_text(s, [
        {"text": "HUMPBACK WHALES", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "~1,000", "font": HEAD, "size": 26, "bold": True,
         "color": C_INK_DARK, "italic": True, "new_para": True},
        {"text": "  (1970s)", "font": BODY, "size": 13, "color": C_SOFT_D},
        {"text": "→ ", "font": BODY, "size": 16, "color": C_SOFT_D},
        {"text": "25,000–33,000", "font": HEAD, "size": 22, "bold": True,
         "color": C_RUST, "italic": True},
        {"text": "  (2021)", "font": BODY, "size": 13, "color": C_SOFT_D},
    ], rx, 1.8, rw, 1.4, line_spacing=1.15)

    # Rule
    add_rect(s, rx, 3.3, rw - 0.1, 0.015, C_SOFT)

    # Callout 2 — Harbour seals
    add_multi_text(s, [
        {"text": "HARBOUR SEALS", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "~10,000", "font": HEAD, "size": 26, "bold": True,
         "color": C_INK_DARK, "italic": True, "new_para": True},
        {"text": "  →  ", "font": BODY, "size": 16, "color": C_SOFT_D},
        {"text": "~105,000", "font": HEAD, "size": 26, "bold": True,
         "color": C_RUST, "italic": True},
    ], rx, 3.45, rw, 1.2, line_spacing=1.15)

    # Rule
    add_rect(s, rx, 4.7, rw - 0.1, 0.015, C_SOFT)

    # Callout 3 — Steller sea lions
    add_multi_text(s, [
        {"text": "STELLER SEA LIONS", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": ">4×", "font": HEAD, "size": 32, "bold": True,
         "color": C_RUST, "italic": True, "new_para": True},
        {"text": "  since 1970", "font": BODY, "size": 14, "color": C_SOFT_D},
    ], rx, 4.85, rw, 1.4, line_spacing=1.15)

    # ── Punch line (amber rule, italic) ────────────────────────────────────
    add_amber_rule(s, 0.4, 6.65, 1.2)
    add_text(s, "The mouth eating herring now is bigger than the fishery ever was.",
             0.4, 6.78, 8.0, 0.55,
             font=HEAD, size=17, italic=True, color=C_INK_DARK, dark=False)

    # ── Footage credit bottom-right ────────────────────────────────────────
    footage_credit(s, dark=False, text="Footage: Pacific Wild")

    speaker_note(s,
        "But the coast you just saw — full of bears and wolves and eagles and "
        "sea lions — looks like that for a different reason today than it did "
        "fifty years ago. In the 1960s, commercial whaling had left the ocean "
        "nearly predator-free. Since then: humpbacks went from about a thousand "
        "to twenty-five to thirty-five thousand. Sea lions doubled, then doubled "
        "again. The mouth eating herring today is bigger than the fishery ever was.")
