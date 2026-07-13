#!/usr/bin/env python3
"""
Supplementary / Q&A backup figures for the Royal Society herring deck.

Seven figures, each pre-wired to a likely audience question:

  SB1 — Portfolio metrics across six management eras       (general)
  SB2 — Predator demand decomposed by species              (Q&A B1, predators)
  SB3 — Climate context: PDO + Blob years                  (general / heatwave Q)
  SB4 — m1_stier_11 vs DFO SR 2025/005 cross-comparison    (independent confirmation)
  SB5 — Co-governance institutional timeline               (Q&A B20, solutions)
  SB6 — Cod vs herring recovery trajectories               (Q&A B5, hysteresis vs transient)
  SB7 — Early-warning signal — a hypothesis to test        (Q&A B7, EWS rigor)

Output: 3840×1500 unframed PNGs in deck_assets/_originals/. preprocess_figures.py
adds the deck chrome (masthead, title, takeaway, provenance) afterwards.

Run order:
  python3 supplementary_figs.py
  python3 preprocess_figures.py
  node build_pptx_native.js
"""
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path
from matplotlib import font_manager as fm
from matplotlib import rcParams

# Portable repo root derived from this script's location:
# <repo>/analysis/04_talks/2026-royalsociety/Talk_Materials/deck_build/supplementary_figs.py
REPO = Path(__file__).resolve().parents[3]
DIAG = REPO / "Output" / "diagnostics"
PRED = REPO / "Data" / "processed" / "predators"
DFO  = DIAG / "dfo_newer_public_pdf_extract"
OUT  = REPO / "analysis/04_talks/2026-royalsociety" / "Talk_Materials" / "deck_assets" / "_originals"

# Deck palette (must match preprocess_figures.py)
BG, INK, INK_SOFT = "#0e0e0e", "#f0eee9", "#a8a59f"
RUST, MARINE, KELP, PLUM, AMBER = "#d9714f", "#6e9bc4", "#8aa074", "#b685a8", "#cfa055"
GRID = "#2a2825"

# Portable fonts: Liberation on the Linux sandbox, else Georgia/Courier on
# macOS (mirrors redesign_figs.py so the chrome stays visually consistent).
def _pick(*cands):
    for c in cands:
        if Path(c).is_file():
            return c
    return None

_LIB = "/usr/share/fonts/truetype/liberation"
_MAC = "/System/Library/Fonts/Supplemental"
SERIF        = _pick(f"{_LIB}/LiberationSerif-Regular.ttf",    f"{_MAC}/Georgia.ttf")
SERIF_BOLD   = _pick(f"{_LIB}/LiberationSerif-Bold.ttf",       f"{_MAC}/Georgia Bold.ttf")
SERIF_ITALIC = _pick(f"{_LIB}/LiberationSerif-Italic.ttf",     f"{_MAC}/Georgia Italic.ttf")
MONO         = _pick("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
                     f"{_MAC}/Courier New.ttf")
for p in [SERIF, SERIF_BOLD, SERIF_ITALIC, MONO]:
    if p:
        fm.fontManager.addfont(p)
rcParams.update({
    "font.family": ("Georgia" if (SERIF and "Georgia" in SERIF)
                    else "Liberation Serif"), "text.color": INK,
    "axes.labelcolor": INK, "xtick.color": INK, "ytick.color": INK,
    "axes.edgecolor": INK_SOFT, "axes.facecolor": BG, "figure.facecolor": BG,
    "savefig.facecolor": BG, "axes.grid": False, "font.size": 14
})

W_IN, H_IN, DPI = 19.2, 7.5, 200


def sb1_portfolio_periods():
    """Portfolio metrics across six management eras, all-11 sections."""
    df = pd.read_csv(DIAG / "m1_stier_11_portfolio_period_summary.csv")
    df = df[df["report_set"] == "all_11"].copy()
    # short period labels for the x-axis
    short = {
        "1951-1965 early industrial": "1951–65\nearly\nindustrial",
        "1966-1971 late reduction":   "1966–71\nlate\nreduction",
        "1972-2004 roe fishery":      "1972–04\nroe\nfishery",
        "2005-2013 closure":          "2005–13\nclosure",
        "2014-2016 marine heatwave":  "2014–16\nmarine\nheatwave",
        "2017-2025 recent closure":   "2017–25\nrecent\nclosure",
    }
    df["lbl"] = df["period"].map(short)

    fig, axes = plt.subplots(1, 2, figsize=(W_IN, H_IN), dpi=DPI,
                             gridspec_kw=dict(wspace=0.25))
    fig.subplots_adjust(left=0.06, right=0.97, top=0.85, bottom=0.18)

    # left: Simpson effective sections (lower = portfolio narrower)
    ax = axes[0]
    x = np.arange(len(df))
    bars = ax.bar(x, df["simpson_effective_sections"], color=KELP, width=0.62,
                  edgecolor="none")
    # highlight last two periods
    bars[-1].set_color(RUST); bars[-2].set_color(AMBER)
    for i, v in enumerate(df["simpson_effective_sections"]):
        ax.text(i, v + 0.06, f"{v:.2f}", ha="center", va="bottom",
                fontsize=18, fontweight="bold", color=INK)
    ax.set_xticks(x)
    ax.set_xticklabels(df["lbl"], fontsize=12, color=INK_SOFT,
                       fontfamily="DejaVu Sans Mono", rotation=0)
    ax.set_ylim(0, df["simpson_effective_sections"].max() * 1.18)
    ax.set_ylabel("Simpson effective sections", color=INK_SOFT, fontsize=16, labelpad=10)
    ax.set_title("Portfolio diversity narrowed", fontsize=20,
                 color=INK, pad=14, loc="left", fontweight="bold")
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(INK_SOFT); ax.spines["bottom"].set_color(INK_SOFT)
    ax.tick_params(axis="y", labelsize=13)

    # right: top-3 share (higher = more concentrated)
    ax = axes[1]
    ax.bar(x, df["top3_share"] * 100, color=PLUM, width=0.62, edgecolor="none")
    for i, v in enumerate(df["top3_share"] * 100):
        ax.text(i, v + 1.0, f"{v:.0f}%", ha="center", va="bottom",
                fontsize=18, fontweight="bold", color=INK)
    ax.set_xticks(x)
    ax.set_xticklabels(df["lbl"], fontsize=12, color=INK_SOFT,
                       fontfamily="DejaVu Sans Mono", rotation=0)
    ax.set_ylim(0, 100)
    ax.set_ylabel("Top-3 sections' share of total biomass (%)", color=INK_SOFT,
                  fontsize=16, labelpad=10)
    ax.set_title("Concentration rose", fontsize=20,
                 color=INK, pad=14, loc="left", fontweight="bold")
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(INK_SOFT); ax.spines["bottom"].set_color(INK_SOFT)
    ax.tick_params(axis="y", labelsize=13)

    fig.savefig(OUT / "sb1_portfolio_periods.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb1_portfolio_periods.png")


def sb2_predator_species():
    """Top predator species by mean recent demand (kt/yr)."""
    df = pd.read_csv(PRED / "hg_predator_consumption_by_species_recent.csv")
    df = df.sort_values("mean_consumption_t", ascending=True).tail(12)
    df["mean_kt"] = df["mean_consumption_t"] / 1000.0
    group_color = {"mammals": MARINE, "fish": KELP, "salmon": AMBER, "birds": PLUM}
    colors = [group_color.get(g, INK_SOFT) for g in df["group"]]

    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.20, right=0.95, top=0.88, bottom=0.10)
    y = np.arange(len(df))
    bars = ax.barh(y, df["mean_kt"], color=colors, height=0.72, edgecolor="none")
    for i, v in enumerate(df["mean_kt"]):
        ax.text(v + 0.08, i, f"{v:.2f} kt", color=INK, va="center", ha="left",
                fontsize=14, fontweight="bold")
    ax.set_yticks(y)
    ax.set_yticklabels(df["species"], fontsize=16, color=INK)
    ax.set_xlabel("Mean recent annual herring demand (kt · yr$^{-1}$)",
                  color=INK_SOFT, fontsize=16, labelpad=10)
    ax.set_xlim(0, df["mean_kt"].max() * 1.18)
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(BG); ax.spines["bottom"].set_color(INK_SOFT)
    ax.tick_params(axis="x", labelsize=13)
    ax.tick_params(axis="y", labelsize=15, pad=8)

    handles = [mpatches.Patch(color=group_color[g], label=g.capitalize())
               for g in ["mammals", "fish", "salmon", "birds"]]
    leg = ax.legend(handles=handles, loc="lower right", frameon=False,
                    fontsize=14, ncol=4, columnspacing=2.0)
    for t in leg.get_texts(): t.set_color(INK)

    fig.savefig(OUT / "sb2_predator_species.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb2_predator_species.png")


def sb3_climate_blob():
    """PDO time series with the 2014–16 marine heatwave / Blob shaded."""
    df = pd.read_csv(DIAG / "pdo_climate_yearly.csv")
    df = df.dropna(subset=["pdo"])
    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.06, right=0.97, top=0.88, bottom=0.14)

    # shaded epoch — the Blob years
    ax.axvspan(2013.5, 2016.5, color=AMBER, alpha=0.18, zorder=0)
    ax.text(2015, df["pdo"].max() * 0.95, "the Blob\n2014–2016",
            color=AMBER, ha="center", va="top", fontsize=20,
            fontweight="bold", style="italic")

    # PDO as filled area split by sign
    yrs = df["year"].values; pdo = df["pdo"].values
    ax.fill_between(yrs, pdo, 0, where=(pdo > 0), color=RUST, alpha=0.65,
                    interpolate=True, label="warm phase")
    ax.fill_between(yrs, pdo, 0, where=(pdo <= 0), color=MARINE, alpha=0.65,
                    interpolate=True, label="cool / productive phase")
    ax.plot(yrs, pdo, color=INK, lw=1.5, alpha=0.9)
    ax.axhline(0, color=INK_SOFT, lw=1.0, ls="--", alpha=0.6)

    ax.set_xlim(1951, 2025)
    ax.set_ylabel("PDO index", color=INK_SOFT, fontsize=16, labelpad=10)
    ax.set_xlabel("year", color=INK_SOFT, fontsize=14, labelpad=8)
    ax.tick_params(labelsize=13)
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(INK_SOFT); ax.spines["bottom"].set_color(INK_SOFT)
    leg = ax.legend(loc="lower left", frameon=False, fontsize=14, ncol=2)
    for t in leg.get_texts(): t.set_color(INK)

    fig.savefig(OUT / "sb3_climate_blob.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb3_climate_blob.png")


def sb4_dfo_vs_m1():
    """Independent confirmation: m1_stier_11 total biomass (this work) vs DFO
    SR 2025/005 SCA spawning biomass (Cleary 2025). Different metrics (total
    vs spawning) but same direction — both at historical lows. Dual y-axes so
    the trajectories are directly comparable."""
    m1 = pd.read_csv(DIAG / "m1_stier_11_total_biomass_by_year.csv")
    m1 = m1[m1["report_set"] == "all_11"].copy()
    dfo = pd.read_csv(DFO / "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv")

    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.07, right=0.92, top=0.86, bottom=0.14)

    # left axis: m1_stier_11 total biomass (kt). Median + 50% CI to avoid the
    # huge recent uncertainty band dominating the plot — the trajectory is the
    # point, not the marginal posterior width.
    # use lo80/hi80 trimmed: clip y to median × 3 ceiling for legibility
    ax.fill_between(m1["year"], m1["lo80"] / 1000, m1["hi80"] / 1000,
                    color=RUST, alpha=0.12, zorder=2)
    ax.plot(m1["year"], m1["median"] / 1000, color=RUST, lw=3.4, zorder=4,
            label="m1_stier_11 total biomass  (median, 80% CI)")
    ax.set_ylabel("m1_stier_11 total biomass (kt)", color=RUST,
                  fontsize=15, labelpad=10)
    ax.tick_params(axis="y", labelsize=13, colors=RUST)
    # clip y-axis to a readable range — uncertainty band can blow up post-1994
    ax.set_ylim(0, max(m1["median"]) / 1000 * 2.2)

    # right axis: DFO spawning biomass (kt) with 90% interval
    ax2 = ax.twinx()
    ax2.fill_between(dfo["year"], dfo["spawning_biomass_kt_p05"],
                     dfo["spawning_biomass_kt_p95"],
                     color=MARINE, alpha=0.22, zorder=2)
    ax2.plot(dfo["year"], dfo["spawning_biomass_kt_median"], color=MARINE,
             lw=3.2, marker="o", ms=8, zorder=5,
             label="DFO SR 2025/005 spawning biomass  (median, 90% CI)")
    # LRP horizontal line
    ax2.axhline(6.45, color=AMBER, lw=2.0, ls="--", alpha=0.85, zorder=3)
    ax2.text(2024.5, 6.45, "  LRP\n  6.45 kt", color=AMBER,
             fontsize=12, ha="left", va="center", fontweight="bold",
             fontfamily="DejaVu Sans Mono")
    ax2.set_ylabel("DFO SCA spawning biomass (kt)", color=MARINE,
                   fontsize=15, labelpad=12)
    ax2.tick_params(axis="y", labelsize=13, colors=MARINE)
    ax2.set_ylim(0, dfo["spawning_biomass_kt_p95"].max() * 1.4)

    ax.set_xlim(1951, 2026)
    ax.set_xlabel("year", color=INK_SOFT, fontsize=14, labelpad=8)
    ax.tick_params(axis="x", labelsize=13)
    for s in ("top",): ax.spines[s].set_visible(False); ax2.spines[s].set_visible(False)
    ax.spines["left"].set_color(RUST); ax.spines["bottom"].set_color(INK_SOFT)
    ax2.spines["right"].set_color(MARINE)
    ax.grid(True, axis="y", color=GRID, lw=0.8, alpha=0.35)

    # combined legend (top-left, away from data)
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    leg = ax.legend(h1 + h2, l1 + l2, loc="upper right", frameon=False, fontsize=14)
    for t in leg.get_texts(): t.set_color(INK)

    fig.savefig(OUT / "sb4_dfo_vs_m1.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb4_dfo_vs_m1.png")


def sb5_cogovernance_timeline():
    """Co-governance institutional timeline: Athlii Gwaii → AMB → 2024 Plan."""
    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.06, right=0.96, top=0.92, bottom=0.10)

    events = [
        (1985, "Athlii Gwaii blockade", "Haida assertion of title", PLUM),
        (1988, "South Moresby Agreement",
         "Federal commitment to Gwaii Haanas reserve", MARINE),
        (1993, "Gwaii Haanas Agreement",
         "Haida ↔ Canada co-governance formalized", KELP),
        (1996, "Gwaii Haanas Archipelago\nManagement Board (AMB)",
         "First nation-to-nation\nmarine-area board", AMBER),
        (2010, "Marine NMCA reserve",
         "Land + sea co-management extended", MARINE),
        (2024, "HG Herring Rebuilding Plan",
         "Minister-signed; AMB-led", RUST),
    ]
    yr_lo, yr_hi = 1982, 2027
    ax.set_xlim(yr_lo, yr_hi); ax.set_ylim(-1.6, 2.2)
    # baseline rail
    ax.axhline(0, color=INK_SOFT, lw=2.0, alpha=0.5)
    # alternating up/down lollipops
    for i, (y_, t, sub, c) in enumerate(events):
        up = (i % 2 == 0); h = 1.05 if up else -0.95
        ax.plot([y_, y_], [0, h], color=c, lw=3.0)
        ax.scatter([y_], [h], s=240, color=c, zorder=5)
        ax.scatter([y_], [0], s=80, color=c, zorder=5)
        va = "bottom" if up else "top"
        ax.text(y_, h + (0.18 if up else -0.18), t, color=c,
                ha="center", va=va, fontsize=15, fontweight="bold")
        ax.text(y_, h + (0.62 if up else -0.55), sub, color=INK_SOFT,
                ha="center", va=va, fontsize=12, style="italic")
        ax.text(y_, -0.18 if up else 0.18, str(y_), color=c,
                ha="center", va="top" if up else "bottom",
                fontsize=13, fontfamily="DejaVu Sans Mono", fontweight="bold")

    ax.set_xticks([1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025])
    ax.tick_params(labelsize=13)
    for s in ("top", "left", "right"): ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_color(INK_SOFT)
    ax.set_yticks([])

    fig.savefig(OUT / "sb5_cogovernance_timeline.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb5_cogovernance_timeline.png")


def sb6_cod_vs_herring():
    """Two-panel schematic — cod (recovered) vs herring (didn't). The shapes
    are stylized; the point is the contrast of trajectories after the stressor
    was removed."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(W_IN, H_IN), dpi=DPI,
                                   gridspec_kw=dict(wspace=0.18))
    fig.subplots_adjust(left=0.06, right=0.97, top=0.85, bottom=0.13)

    # Cod — falls, then rebuilds (schematic)
    t = np.linspace(0, 1, 200)
    cod = 1.0 - 0.85 * np.exp(-((t - 0.35) ** 2) / 0.018) + 0.55 * (t > 0.5) * (
        1 - np.exp(-(t - 0.5) / 0.18))
    cod = np.clip(cod, 0.1, 1.0)
    ax1.plot(t, cod, color=MARINE, lw=4.0)
    ax1.fill_between(t, cod, 0, color=MARINE, alpha=0.18)
    ax1.axvline(0.5, color=AMBER, lw=2.0, ls="--", alpha=0.7)
    ax1.text(0.5, 1.08, "moratorium\n(stressor removed)", color=AMBER,
             ha="center", va="bottom", fontsize=14, fontweight="bold")
    ax1.text(0.85, 0.78, "recovery", color=KELP, fontsize=18,
             fontweight="bold", style="italic")
    ax1.set_title("Cod — Newfoundland / North Sea grammar",
                  color=INK, fontsize=20, fontweight="bold", loc="left", pad=12)
    ax1.set_xlim(0, 1); ax1.set_ylim(0, 1.2)
    ax1.set_xticks([]); ax1.set_yticks([])
    ax1.set_xlabel("time", color=INK_SOFT, fontsize=14)
    for s in ("top", "right"): ax1.spines[s].set_visible(False)
    ax1.spines["left"].set_color(INK_SOFT); ax1.spines["bottom"].set_color(INK_SOFT)

    # Herring — falls, fishery closes, STAYS low (sigmoid drop that
    # plateaus, NOT a symmetric Gaussian dip — the old Gaussian rebounded
    # to ~0.95 by t=1, visually contradicting the "no recovery" label).
    herr = 1.0 - 0.82 / (1.0 + np.exp(-(t - 0.33) / 0.045))
    herr = herr + 0.02 * np.sin((t - 0.5) * 16) * (t > 0.5)  # faint wobble
    herr = np.clip(herr, 0.10, 1.0)
    ax2.plot(t, herr, color=RUST, lw=4.0)
    ax2.fill_between(t, herr, 0, color=RUST, alpha=0.18)
    ax2.axvline(0.5, color=AMBER, lw=2.0, ls="--", alpha=0.7)
    ax2.text(0.5, 1.08, "closure\n(stressor removed)", color=AMBER,
             ha="center", va="bottom", fontsize=14, fontweight="bold")
    ax2.text(0.85, 0.18, "no recovery", color=RUST, fontsize=18,
             fontweight="bold", style="italic")
    ax2.set_title("Haida Gwaii herring", color=INK, fontsize=20,
                  fontweight="bold", loc="left", pad=12)
    ax2.set_xlim(0, 1); ax2.set_ylim(0, 1.2)
    ax2.set_xticks([]); ax2.set_yticks([])
    ax2.set_xlabel("time", color=INK_SOFT, fontsize=14)
    for s in ("top", "right"): ax2.spines[s].set_visible(False)
    ax2.spines["left"].set_color(INK_SOFT); ax2.spines["bottom"].set_color(INK_SOFT)

    # shared y-axis label sketch
    fig.text(0.025, 0.5, "biomass / abundance", color=INK_SOFT,
             ha="center", va="center", rotation="vertical", fontsize=16)

    fig.savefig(OUT / "sb6_cod_vs_herring.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb6_cod_vs_herring.png")


def sb7_ews_hypothesis():
    """Early-warning-signal schematic: variance + autocorrelation rise as
    system approaches the tipping point. Annotated as PROPOSAL, not a result."""
    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.07, right=0.95, top=0.88, bottom=0.13)

    t = np.linspace(0, 1, 400)
    # state variable with growing variance as t→tipping
    rng = np.random.default_rng(1)
    base = 1.0 - 0.05 * t - 0.4 * (1 / (1 + np.exp(-25 * (t - 0.78))))
    var_amp = 0.02 + 0.16 * t ** 3
    state = base + var_amp * rng.standard_normal(len(t))
    ax.plot(t, state, color=KELP, lw=2.3, alpha=0.95)

    # rolling-window variance proxy
    win = 30
    var_proxy = pd.Series(state).rolling(win, center=True).std()
    ax.plot(t, 0.45 + 4.0 * var_proxy, color=AMBER, lw=3.0,
            label="rolling-window variance")

    # tipping line
    tip = 0.78
    ax.axvline(tip, color=RUST, lw=2.0, ls="--", alpha=0.85)
    ax.text(tip + 0.005, 1.12, "tipping point", color=RUST,
            ha="left", va="bottom", fontsize=16, fontweight="bold")

    # annotation block
    ax.text(0.03, 1.18, "EWS — a hypothesis we are testing, not a result",
            color=AMBER, fontsize=18, fontweight="bold", style="italic")
    ax.text(0.03, 1.06,
            "If portfolio erosion is a true critical slowing-down, variance\n"
            "and autocorrelation should rise on the approach. Test ongoing.",
            color=INK_SOFT, fontsize=14)

    ax.set_xlim(0, 1); ax.set_ylim(0.05, 1.2)
    ax.set_xlabel("time", color=INK_SOFT, fontsize=14)
    ax.set_ylabel("system state  /  variance proxy", color=INK_SOFT, fontsize=14)
    ax.set_xticks([]); ax.set_yticks([])
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(INK_SOFT); ax.spines["bottom"].set_color(INK_SOFT)
    leg = ax.legend(loc="lower left", frameon=False, fontsize=14)
    for t_ in leg.get_texts(): t_.set_color(INK)

    fig.savefig(OUT / "sb7_ews_hypothesis.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig); print("wrote sb7_ews_hypothesis.png")


if __name__ == "__main__":
    sb1_portfolio_periods()
    sb2_predator_species()
    sb3_climate_blob()
    sb4_dfo_vs_m1()
    sb5_cogovernance_timeline()
    sb6_cod_vs_herring()
    sb7_ews_hypothesis()
    print("done.")
