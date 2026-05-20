"""S09 — Archaeological record (10,000 years of herring at the centre)"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR


def build_s09(prs):
    s = add_slide(prs, dark=False)

    # ── Kicker + h1 ────────────────────────────────────────────────────────
    kicker(s, "THE RECORD", dark=False)
    title_h1(s, "10,000 years of herring at the centre.",
             dark=False, x=0.4, y=0.7, w=12.5, h=0.9, size=30)

    # ── Image LEFT 60% — McKechnie 2014 PNAS panel ─────────────────────────
    add_image(s, asset("04_baseline.png"),
              x=0.4, y=1.8, w=7.6, h=4.9)

    # ── RIGHT 40% stacked data callouts ────────────────────────────────────
    rx = 8.3
    rw = 4.7
    # Each row: small mono label + Georgia number
    # Layout: stack 6 callouts vertically across ~5" of height starting at 1.8
    # Use generous spacing — 4 quantitative + 2 contextual lines

    # 49% of fish bones
    add_multi_text(s, [
        {"text": "OF FISH BONES", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "49%", "font": HEAD, "size": 30, "bold": True,
         "color": C_INK_DARK, "italic": True, "new_para": True},
    ], rx, 1.8, rw, 1.1, line_spacing=1.0)

    # 171 sites
    add_multi_text(s, [
        {"text": "ARCHAEOLOGICAL SITES", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "171", "font": HEAD, "size": 30, "bold": True,
         "color": C_INK_DARK, "italic": True, "new_para": True},
    ], rx, 2.95, rw, 1.1, line_spacing=1.0)

    # <±10% regional variance
    add_multi_text(s, [
        {"text": "REGIONAL VARIANCE", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "<±10%", "font": HEAD, "size": 26, "bold": True,
         "color": C_INK_DARK, "italic": True, "new_para": True},
    ], rx, 4.10, rw, 1.0, line_spacing=1.0)

    # ~10,700 years
    add_multi_text(s, [
        {"text": "SPANNING", "font": MONO, "size": 10, "color": C_RUST, "bold": True},
        {"text": "~10,700 years", "font": HEAD, "size": 22, "bold": True,
         "color": C_INK_DARK, "italic": True, "new_para": True},
    ], rx, 5.10, rw, 1.0, line_spacing=1.0)

    # Two contextual lines — k'aaw + place-name (smaller, body italic)
    add_amber_rule(s, rx, 6.05, 1.0)
    add_multi_text(s, [
        {"text": "kʼaaw harvest evidence in middens", "font": BODY, "size": 12,
         "italic": True, "color": C_INK_DARK},
        {"text": "place-name encoding (iinang = “plentiful”)",
         "font": BODY, "size": 12, "italic": True, "color": C_INK_DARK,
         "new_para": True},
    ], rx, 6.18, rw, 0.9, line_spacing=1.2)

    # ── Footer source ──────────────────────────────────────────────────────
    credit(s, "Source: McKechnie et al. 2014 PNAS · HMTK.",
           dark=False, y=7.10, x=0.4, w=12.5)

    speaker_note(s,
        "And the record shows it. Across one hundred and seventy-one "
        "archaeological sites — over ten thousand seven hundred years — herring "
        "is roughly half of the fish bone we find. With less than ten percent "
        "variance across the region. For ten millennia this fish was the "
        "dominant fish people ate, and it was both variable and reliable at the "
        "same time. The Haida even encoded it in their language — iinang means "
        "'plentiful,' and it's the word for herring.")
