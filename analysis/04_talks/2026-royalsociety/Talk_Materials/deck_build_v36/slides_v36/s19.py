"""S19 — Suspect 1: Ocean — necessary, not the barrier"""
from helpers_v36 import *
from pptx.enum.text import PP_ALIGN


def build_s19(prs):
    s = add_slide(prs, dark=False)  # LIGHT background

    # ── Kicker + h1 + subtitle ─────────────────────────────────────────────
    kicker(s, "SUSPECT 1: OCEAN", dark=False)
    title_h1(s, "Necessary, not the barrier.", dark=False,
             x=0.4, y=0.65, w=12.5, h=0.85, size=32)
    add_text(s,
        "Cool, productive PDO years drove the 1960s rebound. "
        "Comparable cool years since 2000 did not.",
        0.4, 1.45, 12.5, 0.5,
        font=HEAD, size=16, italic=True, color=C_SOFT_D, dark=False)

    # ── Chart full-width (~90% of slide width) ─────────────────────────────
    # Place PDO chart prominently — center it
    chart_w = 12.0
    chart_h = 4.4
    chart_x = (DECK_W_IN - chart_w) / 2.0   # ~0.67
    chart_y = 2.05
    add_image(s, asset("06_climate_pdo.png"),
              chart_x, chart_y, w=chart_w, h=chart_h)

    # ── Annotation callouts (mono small) ──────────────────────────────────
    # Floating callout over the chart area for the Blob period
    add_text(s,
        "Blob 2014-2016 · no detectable signal",
        chart_x + chart_w - 4.2, chart_y + 0.15, 4.0, 0.32,
        font=MONO, size=10, color=C_RUST, dark=False,
        align=PP_ALIGN.RIGHT)

    # ── Corrected take-home punch line (amber rule + italic) ──────────────
    # Sits below chart, overrides any baked-in take-home in the PNG
    rule_y = chart_y + chart_h + 0.18
    add_amber_rule(s, 0.4, rule_y, 1.2)
    add_text(s,
        "Climate is necessary — but it is not the barrier.",
        0.4, rule_y + 0.13, 12.5, 0.55,
        font=HEAD, size=20, italic=True, color=C_INK_DARK, dark=False)

    # ── Footer credit ──────────────────────────────────────────────────────
    credit(s,
        "Analysis: Stier et al. 2020 · PDO data: NOAA",
        dark=False, y=7.1)

    # ── Speaker note: verbatim Spoken from outline ────────────────────────
    speaker_note(s,
        "First suspect: ocean conditions. The dominant hypothesis in the "
        "literature has long been bottom-up: cold, productive PDO years "
        "create phytoplankton and zooplankton blooms; if those blooms align "
        "with herring spawning, larvae have food and recruit. The ocean does "
        "slosh back and forth — strings of good years and bad years. Cold "
        "productive years drove the 1960s recovery. But here's the thing: "
        "we've had strings of cold, productive years since two thousand — "
        "and the fish have not walked through the door. Climate is "
        "necessary, but it is not what's holding them back. I'll also flag "
        "the warm Blob — and our analysis doesn't show it meaningfully "
        "exacerbated the failed recovery either.")
