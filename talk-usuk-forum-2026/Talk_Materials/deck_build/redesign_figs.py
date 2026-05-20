#!/usr/bin/env python3
"""
Redesigned figures for slides 8, 9, 10 of the Royal Society herring deck.

Old versions were data-faithful but visually weak:
  S8 was a spaghetti slope chart, S9 a noisy 65-yr time series, S10 a busy
  two-panel area+pct chart. New versions land each slide's punchline:
    S8 — diverging-bar showing per-section growth change, sorted, magnitude up front
    S9 — before/after epoch bars + small inset time series for context
    S10 — single stacked-area of predator demand with the 100% reference and the
          239% mark called out as the actual headline

Style matches the baked deck chrome: dark bg #0e0e0e, ink #f0eee9, rust accent,
track-color contract (eco=kelp, cultural=plum, economic=rust, governance=marine,
window=amber). Output: 3840×2160 PNGs that go straight through the bake_chrome
pipeline in preprocess_figures.py.
"""
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path
from matplotlib import font_manager as fm
from matplotlib import rcParams

# Portable repo root derived from this script's location:
# <repo>/talk-usuk-forum-2026/Talk_Materials/deck_build/redesign_figs.py
REPO = Path(__file__).resolve().parents[3]
DIAG = REPO / "Output" / "diagnostics"
PRED = REPO / "Data" / "processed" / "predators"
OUT = REPO / "talk-usuk-forum-2026" / "Talk_Materials" / "deck_assets" / "_originals"
OUT.mkdir(parents=True, exist_ok=True)

# Deck palette
BG = "#0e0e0e"
INK = "#f0eee9"
INK_SOFT = "#a8a59f"
RUST = "#d9714f"
MARINE = "#6e9bc4"
KELP = "#8aa074"
PLUM = "#b685a8"
AMBER = "#cfa055"
GRID = "#2a2825"

# Fonts: portable — Liberation/DejaVu on the Linux sandbox, else Georgia/
# Courier on macOS. Georgia is the deck HEAD font (build_pptx_native.js) so
# the baked chrome stays visually consistent on either platform.
def _pick(*cands):
    for c in cands:
        if Path(c).is_file():
            return c
    return None

_LIB = "/usr/share/fonts/truetype/liberation"
_MAC = "/System/Library/Fonts/Supplemental"
SERIF        = _pick(f"{_LIB}/LiberationSerif-Regular.ttf", f"{_MAC}/Georgia.ttf")
SERIF_BOLD   = _pick(f"{_LIB}/LiberationSerif-Bold.ttf",    f"{_MAC}/Georgia Bold.ttf")
SERIF_ITALIC = _pick(f"{_LIB}/LiberationSerif-Italic.ttf",  f"{_MAC}/Georgia Italic.ttf")
MONO         = _pick("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
                      f"{_MAC}/Courier New.ttf")
for p in [SERIF, SERIF_BOLD, SERIF_ITALIC, MONO]:
    if p:
        fm.fontManager.addfont(p)
rcParams["font.family"] = "Georgia" if (SERIF and "Georgia" in SERIF) else "Liberation Serif"
rcParams["text.color"] = INK
rcParams["axes.labelcolor"] = INK
rcParams["xtick.color"] = INK
rcParams["ytick.color"] = INK
rcParams["axes.edgecolor"] = INK_SOFT
rcParams["axes.facecolor"] = BG
rcParams["figure.facecolor"] = BG
rcParams["savefig.facecolor"] = BG
rcParams["axes.grid"] = False
rcParams["font.size"] = 14

# Target render: figures get baked with chrome — content zone is 3840×1500.
# Render figures at 3840 wide, 1500 tall, then the bake adds top/bottom chrome.
W_IN = 19.2     # 3840/200 → 200 dpi
H_IN = 7.5      # 1500/200
DPI = 200


def s8_diverging_growth():
    """S8 — diverging-bar of per-section change in realized growth (median).
    Sorted by change. Negative = rust (decline), positive = kelp (gain)."""
    df = pd.read_csv(DIAG / "stier2020_updated_fig5_growth_periods.csv")
    hist = df[df["period"].str.contains("historical")].set_index("section_name")
    post = df[df["period"].str.contains("post-1994")].set_index("section_name")
    j = (post[["median"]].rename(columns={"median": "post"})
         .join(hist[["median"]].rename(columns={"median": "hist"})))
    j["delta"] = j["post"] - j["hist"]
    j["delta_pct"] = 100 * (j["post"] - j["hist"]) / j["hist"]
    j = j.sort_values("delta_pct", ascending=True)

    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.18, right=0.96, top=0.92, bottom=0.12)

    colors = [RUST if v < 0 else KELP for v in j["delta_pct"]]
    y = np.arange(len(j))
    bars = ax.barh(y, j["delta_pct"], color=colors, height=0.65, edgecolor="none")

    # zero line, amber
    ax.axvline(0, color=AMBER, lw=2.0, alpha=0.75)
    ax.text(0, len(j) - 0.4, " no change", color=AMBER, fontsize=14,
            ha="left", va="center", style="italic", fontfamily="DejaVu Sans Mono")

    # value labels at bar tips
    for i, (name, row) in enumerate(j.iterrows()):
        v = row["delta_pct"]
        x = v + (0.6 if v >= 0 else -0.6)
        ha = "left" if v >= 0 else "right"
        ax.text(x, i, f"{v:+.1f}%", color=INK, ha=ha, va="center",
                fontsize=18, fontweight="bold")

    ax.set_yticks(y)
    ax.set_yticklabels(j.index, fontsize=18, color=INK)
    ax.set_xlabel("Change in realized growth rate, post-1994 vs historical  (%)",
                  fontsize=18, color=INK_SOFT, labelpad=14)
    ax.set_xlim(min(j["delta_pct"].min() * 1.25, -1), max(j["delta_pct"].max() * 1.25, 1))
    ax.set_xticks(np.arange(-15, 6, 5))
    ax.tick_params(axis="x", labelsize=15)
    ax.tick_params(axis="y", labelsize=18, pad=8)
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    ax.spines["left"].set_color(BG)
    ax.spines["bottom"].set_color(INK_SOFT)

    # headline number, anchored bottom-right, won't collide with bar tips
    n_dec = int((j["delta_pct"] < 0).sum())
    n_tot = len(j)
    ax.text(0.985, 0.14, f"{n_dec} of {n_tot} declined",
            transform=ax.transAxes, ha="right", va="bottom",
            fontsize=30, fontweight="bold", color=KELP, style="italic")
    ax.text(0.985, 0.06, "Port Louis the lone outlier",
            transform=ax.transAxes, ha="right", va="bottom",
            fontsize=16, color=INK_SOFT, style="italic")

    fig.savefig(OUT / "08_realized_growth.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig)
    print("wrote 08_realized_growth.png")


def s9_portfolio_before_after():
    """S9 — epoch bars (pre/post-1994) showing mean synchrony, with a small
    time-series inset for context. Headline: +60% rise."""
    df = pd.read_csv(DIAG / "deck_s09_synchrony_rolling.csv")
    df["year"] = df["window_mid"].astype(int)
    pre = df[df["year"] < 1994]["synchrony"].mean()
    post = df[df["year"] >= 1994]["synchrony"].mean()
    pct_rise = 100 * (post - pre) / pre

    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.04, right=0.97, top=0.88, bottom=0.12)

    # Big bars
    bx = [0.20, 0.50]
    bw = 0.16
    bars = ax.bar(bx, [pre, post], width=bw, color=[INK_SOFT, KELP],
                  edgecolor="none", zorder=3)
    # bar value labels
    for x, v, c, lbl in [(0.20, pre, INK_SOFT, "1955–1993"), (0.50, post, KELP, "1994–2020")]:
        ax.text(x, v + 0.012, f"{v:.2f}", color=INK, fontsize=48, fontweight="bold",
                ha="center", va="bottom")
        ax.text(x, -0.04, lbl, color=INK_SOFT, fontsize=20, ha="center", va="top",
                fontfamily="DejaVu Sans Mono")

    # rise arrow
    ax.annotate("", xy=(0.42, post + 0.005), xytext=(0.28, pre + 0.005),
                arrowprops=dict(arrowstyle="-|>", lw=4, color=AMBER,
                                mutation_scale=30, shrinkA=4, shrinkB=4))
    ax.text(0.35, (pre + post) / 2 + 0.04, f"+{pct_rise:.0f}%",
            color=AMBER, fontsize=64, fontweight="bold", ha="center", va="center",
            style="italic")
    ax.text(0.35, (pre + post) / 2 - 0.05, "synchrony rose",
            color=INK_SOFT, fontsize=18, ha="center", va="center",
            style="italic")

    # right-side inset: full time series for context
    inset = ax.inset_axes([0.65, 0.15, 0.32, 0.75])
    inset.plot(df["year"], df["synchrony"], color=KELP, lw=2.5, alpha=0.95)
    inset.axvline(1994, color=AMBER, lw=1.5, ls="--", alpha=0.7)
    inset.text(1994, df["synchrony"].max() * 1.05, "1994", color=AMBER,
               fontsize=14, ha="center", fontfamily="DejaVu Sans Mono")
    inset.set_xlim(1955, int(df["year"].max()))  # to latest data (10-yr rolling → ~2020), no empty trailing years
    inset.set_ylim(0.05, df["synchrony"].max() * 1.15)
    inset.set_facecolor(BG)
    inset.grid(True, color=GRID, lw=0.8, alpha=0.7)
    for s in inset.spines.values():
        s.set_color(INK_SOFT)
    inset.tick_params(colors=INK_SOFT, labelsize=12)
    inset.set_title("Subpopulation synchrony, 10-yr rolling window",
                    color=INK_SOFT, fontsize=14, style="italic", pad=10)

    ax.set_xlim(0, 1)
    ax.set_ylim(-0.06, max(pre, post) * 1.55)
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)

    fig.savefig(OUT / "09_synchrony.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig)
    print("wrote 09_synchrony.png")


def s10_predator_demand():
    """S10 — single stacked-area of predator consumption (kt) with the herring
    annual-spawn line as a benchmark. 239% callout as headline."""
    cg = pd.read_csv(PRED / "hg_predator_consumption_by_group_year.csv")
    pr = pd.read_csv(PRED / "hg_predation_pressure_index_audited.csv")

    # pivot consumption by group
    cg_w = cg.pivot_table(index="year", columns="group", values="C_kt",
                          aggfunc="sum", fill_value=0)
    # canonical group order/colors
    group_order = [g for g in ["mammals", "fish", "salmon", "birds"] if g in cg_w.columns]
    cg_w = cg_w.reindex(columns=group_order, fill_value=0)
    group_color = {"mammals": MARINE, "fish": KELP, "salmon": AMBER, "birds": PLUM}

    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.subplots_adjust(left=0.08, right=0.94, top=0.92, bottom=0.13)

    # stack
    ys = [cg_w[g].values for g in group_order]
    ax.stackplot(cg_w.index, ys, labels=group_order,
                 colors=[group_color[g] for g in group_order], alpha=0.92,
                 edgecolor=BG, linewidth=0.5)

    # overlay HG annual spawn (from pressure file)
    pr_clean = pr.dropna(subset=["HG_spawn_kt"])
    ax.plot(pr_clean["year"], pr_clean["HG_spawn_kt"], color=RUST, lw=3.5,
            zorder=5, label="HG annual spawn")
    # fill under spawn faintly to show the reference
    ax.fill_between(pr_clean["year"], pr_clean["HG_spawn_kt"], 0, color=RUST,
                    alpha=0.12, zorder=4)

    # 2015–24 mean predator demand percentage callout (window capped at 2024)
    recent = pr.dropna(subset=["pressure_pct"])
    recent_mean = recent[(recent["year"] >= 2015) & (recent["year"] <= 2024)]["pressure_pct"].mean()
    # arrow + callout in upper-right
    ax.text(0.97, 0.92, f"≈{recent_mean:.0f}%",
            transform=ax.transAxes, ha="right", va="top",
            fontsize=84, fontweight="bold", color=AMBER, style="italic")
    ax.text(0.97, 0.74, "of annual spawn eaten\nby predators, 2015–24",
            transform=ax.transAxes, ha="right", va="top",
            fontsize=20, color=INK_SOFT, style="italic")

    ax.set_xlim(1910, 2024)
    ax.set_ylim(0, max(cg_w.sum(axis=1).max(), pr_clean["HG_spawn_kt"].max()) * 1.05)
    ax.set_ylabel("kt · yr⁻¹", color=INK_SOFT, fontsize=18, labelpad=10)
    ax.tick_params(labelsize=15)
    ax.grid(True, axis="y", color=GRID, lw=0.8, alpha=0.6)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(INK_SOFT)
    ax.spines["bottom"].set_color(INK_SOFT)

    # legend top-left
    handles = [mpatches.Patch(color=group_color[g], label=g.capitalize()) for g in group_order]
    handles.append(plt.Line2D([], [], color=RUST, lw=3.5, label="HG annual spawn"))
    leg = ax.legend(handles=handles, loc="upper left", frameon=False,
                    fontsize=17, ncol=len(group_order) + 1, columnspacing=2)
    for t in leg.get_texts():
        t.set_color(INK)

    fig.savefig(OUT / "10_predators.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig)
    print("wrote 10_predators.png")


def s12_four_clocks_timeline():
    """S12 — four layers on one time axis, each with a tipping mark. Management
    window shaded amber. Co-governance rises while three layers fall — the
    visual carries the 'gap is the management window' thesis without prose."""
    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    # bigger left+right margins so the track labels and notes have room
    fig.subplots_adjust(left=0.20, right=0.78, top=0.92, bottom=0.16)

    # x-axis: years
    yr_lo, yr_hi = 1980, 2026
    ax.set_xlim(yr_lo, yr_hi)
    # 4 vertical tracks
    tracks = [
        dict(label="Cultural service — k'aaw", color=PLUM, y=4.0,
             tip_year=1990, motion="falls", note="spawn-area contraction · post-2002 functional closure"),
        dict(label="Ecological structure",      color=KELP, y=3.0,
             tip_year=1993, motion="falls", note="subpopulation synchrony rises >60%"),
        dict(label="Economic value (HG 2E roe)", color=RUST, y=2.0,
             tip_year=2005, motion="falls", note="landed value peaks 1980s; declines through 1990s"),
        dict(label="Co-governance",              color=MARINE, y=1.0,
             tip_year=1985, motion="rises", note="Athlii Gwaii 1985 → AMB → 2024 Rebuilding Plan"),
    ]
    # management-window band (amber): from earliest fall (~1990) through latest fall (~2005)
    ax.axvspan(1990, 2005, color=AMBER, alpha=0.10, zorder=0)
    ax.text(1997.5, 4.85, "management window",
            color=AMBER, fontsize=18, ha="center", va="center",
            style="italic", fontweight="bold")
    ax.annotate("", xy=(2005, 4.7), xytext=(1990, 4.7),
                arrowprops=dict(arrowstyle="|-|", color=AMBER, lw=2.2))

    for t in tracks:
        y = t["y"]
        # track baseline
        ax.hlines(y, yr_lo, yr_hi, colors=t["color"], linestyles=":",
                  linewidth=2.0, alpha=0.35)
        # tipping marker — arrows now stay tight to their own track to avoid
        # colliding with neighboring labels
        if t["motion"] == "falls":
            ax.annotate("", xy=(t["tip_year"], y - 0.20), xytext=(t["tip_year"], y + 0.20),
                        arrowprops=dict(arrowstyle="-|>", color=t["color"], lw=4,
                                        mutation_scale=28))
            ax.scatter([t["tip_year"]], [y + 0.20], s=160, color=t["color"], zorder=5)
            # year label tucked to the right of the dot (in-track, won't collide)
            ax.text(t["tip_year"] + 0.6, y + 0.20, f"~{t['tip_year']}",
                    color=t["color"], fontsize=15, ha="left", va="center",
                    fontfamily="DejaVu Sans Mono", clip_on=False, fontweight="bold")
        else:
            # rising arrow at a shallower angle, kept within the track
            ax.annotate("", xy=(t["tip_year"] + 18, y + 0.25), xytext=(t["tip_year"], y - 0.18),
                        arrowprops=dict(arrowstyle="-|>", color=t["color"], lw=4,
                                        mutation_scale=28))
            ax.scatter([t["tip_year"]], [y - 0.18], s=160, color=t["color"], zorder=5)
            ax.text(t["tip_year"] - 0.6, y - 0.18, f"{t['tip_year']}→",
                    color=t["color"], fontsize=15, ha="right", va="center",
                    fontfamily="DejaVu Sans Mono", clip_on=False, fontweight="bold")
        # left-side label
        ax.text(yr_lo - 0.5, y, t["label"], color=t["color"],
                fontsize=22, fontweight="bold", ha="right", va="center",
                clip_on=False)
        # right-side note
        ax.text(yr_hi + 0.5, y, t["note"], color=INK_SOFT,
                fontsize=14, ha="left", va="center", style="italic",
                clip_on=False)

    ax.set_ylim(0.2, 5.4)
    ax.set_yticks([])
    ax.set_xticks([1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025])
    ax.tick_params(labelsize=15)
    for s in ("top", "left", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_color(INK_SOFT)
    ax.xaxis.set_tick_params(colors=INK_SOFT)

    fig.savefig(OUT / "12_decoupling.png", dpi=DPI,
                bbox_inches=None, pad_inches=0)
    plt.close(fig)
    print("wrote 12_decoupling.png")


if __name__ == "__main__":
    s8_diverging_growth()
    s9_portfolio_before_after()
    s10_predator_demand()
    s12_four_clocks_timeline()
    print("done.")
