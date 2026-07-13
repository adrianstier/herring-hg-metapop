#!/usr/bin/env python3
"""S13/S10 alternative concepts — visualize that the 1960s herring collapse
happened under DEPLETED (post-whaling) marine-mammal predation, while today
whales + sea lions dominate. Builds 5 candidate figures into
deck_build/s13_candidates/ for Adrian to pick. Selection stage only — the
chosen one gets folded into redesign_figs.py s10 + the chrome bake.

Data: Data/processed/predators/* (audited Stier-Lab predator synthesis) +
Output/diagnostics/m1_stier_11_total_biomass_by_year.csv (focal_9).
Guardrail: predator demand is a LARGE ecological pressure, NOT a fitted
m1_stier_11 coefficient (claim-control sheet).
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from matplotlib import font_manager as fm, rcParams
import pandas as pd, numpy as np
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
PRED = REPO / "Data" / "processed" / "predators"
DIAG = REPO / "Output" / "diagnostics"
OUT = Path(__file__).resolve().parent / "s13_candidates"
OUT.mkdir(exist_ok=True)

BG="#0e0e0e"; INK="#f0eee9"; INK_SOFT="#a8a59f"; RUST="#d9714f"
MARINE="#6e9bc4"; KELP="#8aa074"; PLUM="#b685a8"; AMBER="#cfa055"; GRID="#2a2825"

def _pick(*c):
    for x in c:
        if Path(x).is_file(): return x
    return None
_MAC="/System/Library/Fonts/Supplemental"; _LIB="/usr/share/fonts/truetype/liberation"
SERIF=_pick(f"{_LIB}/LiberationSerif-Regular.ttf", f"{_MAC}/Georgia.ttf")
SERIF_BOLD=_pick(f"{_LIB}/LiberationSerif-Bold.ttf", f"{_MAC}/Georgia Bold.ttf")
MONO=_pick("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", f"{_MAC}/Courier New.ttf")
for f in (SERIF, SERIF_BOLD, MONO):
    if f: fm.fontManager.addfont(f)
rcParams["font.family"]=fm.FontProperties(fname=SERIF).get_name()
rcParams["axes.unicode_minus"]=False
SB=fm.FontProperties(fname=SERIF_BOLD); MN=fm.FontProperties(fname=MONO)

W_IN, H_IN, DPI = 19.2, 7.5, 200

# ---- data ----
g = pd.read_csv(PRED/"hg_predator_consumption_by_group_year.csv")
mam = g[g.group=="mammals"].sort_values("year")
pr = pd.read_csv(PRED/"hg_predation_pressure_index_audited.csv").sort_values("year")
sp = pd.read_csv(PRED/"hg_predator_consumption_by_species_recent.csv")
bm = pd.read_csv(DIAG/"m1_stier_11_total_biomass_by_year.csv")
bm = bm[bm.report_set=="focal_9"].sort_values("year")

C68 = float(np.interp(1968, mam.year, mam.C_kt))   # mammal demand at 1960s collapse
C20 = float(mam[mam.year<=2020].C_kt.iloc[-1])      # recent mammal demand
C10 = float(mam.iloc[0].C_kt)                       # 1910 pre-whaling-collapse

def base(title, sub):
    fig, ax = plt.subplots(figsize=(W_IN, H_IN), dpi=DPI)
    fig.patch.set_facecolor(BG); ax.set_facecolor(BG)
    fig.subplots_adjust(left=0.075, right=0.965, top=0.80, bottom=0.135)
    fig.text(0.075, 0.93, title, color=INK, fontproperties=SB, fontsize=40)
    fig.text(0.075, 0.86, sub, color=RUST, fontproperties=SB, fontsize=24,
             style="italic")
    fig.text(0.075, 0.045,
             "Audited HG predator demand (Stier-Lab predator synthesis) + m1_stier_11 focal-9 biomass. "
             "Predator demand is a large ecological pressure, NOT a fitted m1_stier_11 coefficient.",
             color=INK_SOFT, fontproperties=MN, fontsize=12)
    for s in ("top","right"): ax.spines[s].set_visible(False)
    for s in ("left","bottom"): ax.spines[s].set_color(INK_SOFT)
    ax.tick_params(colors=INK_SOFT, labelsize=15)
    ax.grid(True, axis="y", color=GRID, lw=0.8, alpha=0.5)
    return fig, ax

kt = FuncFormatter(lambda v,_: f"{v:.0f}")

# ===== A — "Two oceans" mammal-predation timeline =====
def A():
    fig, ax = base("Two collapses, two oceans",
                   "the 1960s collapse happened with the whales gone")
    ax.fill_between(mam.year, 0, mam.C_kt, color=MARINE, alpha=0.30, lw=0)
    ax.plot(mam.year, mam.C_kt, color=MARINE, lw=3.4)
    ax.axvspan(1925, 1972, color=GRID, alpha=0.55, lw=0)
    ax.text(1948, mam.C_kt.max()*0.78, "commercial whaling era\n— marine mammals depleted",
            color=INK_SOFT, fontproperties=SB, fontsize=17, ha="center",
            style="italic", linespacing=1.15)
    ax.text(2002, mam.C_kt.max()*0.72, "marine-mammal\nrecovery", color=MARINE,
            fontproperties=SB, fontsize=18, ha="center", style="italic",
            linespacing=1.1)
    for x, lab, c in [(1968, f"1968 collapse\nmammal demand ≈{C68:.1f} kt\n— rebounded in ~5 yr", AMBER),
                      (1994, f"1994 collapse\nmammal demand rising  to ≈{C20:.1f} kt\n— no recovery, 30+ yr", AMBER)]:
        ax.axvline(x, color=c, lw=2.4, ls=(0,(6,4)), alpha=0.9)
        ax.scatter([x],[mam.C_kt.max()*1.02], marker="*", s=620, color=c, clip_on=False, zorder=6)
    ax.annotate("", xy=(1968, C68+0.6), xytext=(1968, 6.2),
                arrowprops=dict(arrowstyle="-|>", color=AMBER, lw=1.6))
    ax.text(1972, 6.4, f"1968 collapse\nmammal demand ≈{C68:.1f} kt — rebounded ~5 yr",
            color=AMBER, fontproperties=SB, fontsize=16, linespacing=1.15)
    ax.text(1996, mam.C_kt.max()*0.40,
            f"1994 collapse\nmammal demand rising\n≈{C20:.1f} kt now — no recovery",
            color=AMBER, fontproperties=SB, fontsize=16, linespacing=1.15)
    ax.set_xlim(mam.year.min(), 2020); ax.set_ylim(0, mam.C_kt.max()*1.12)
    ax.set_ylabel("Marine-mammal demand on HG herring (kt yr$^{-1}$)",
                  color=INK_SOFT, fontproperties=SERIF, fontsize=18)
    ax.yaxis.set_major_formatter(kt)
    fig.savefig(OUT/"A_two_oceans_timeline.png", facecolor=BG); plt.close(fig)
    print("A_two_oceans_timeline.png")

# ===== B — Then-vs-now paired panels =====
def B():
    fig = plt.figure(figsize=(W_IN, H_IN), dpi=DPI); fig.patch.set_facecolor(BG)
    fig.text(0.06, 0.93, "The same shock, a different predator world",
             color=INK, fontproperties=SB, fontsize=40)
    fig.text(0.06, 0.86, "1968 vs today — marine-mammal demand on herring",
             color=RUST, fontproperties=SB, fontsize=24, style="italic")
    fig.text(0.06, 0.045,
             "Audited HG predator demand (Stier-Lab synthesis). Pressure, not a fitted m1_stier_11 coefficient.",
             color=INK_SOFT, fontproperties=MN, fontsize=12)
    gs = fig.add_gridspec(1, 2, left=0.06, right=0.96, top=0.72, bottom=0.14, wspace=0.18)
    # Same group-year series for BOTH bars (consistent): 1968 vs 2020.
    ymax = C20*1.30
    for i,(ax_i, title, val, sub, col) in enumerate([
        (fig.add_subplot(gs[0]), "1968 collapse", C68,
         "whales commercially gone —\nherring rebounded in ~5 yr", AMBER),
        (fig.add_subplot(gs[1]), "today", C20,
         "whales + Steller sea lions back —\nno recovery, 30+ yr", MARINE)]):
        ax_i.set_facecolor(BG)
        for s in ("top","right"): ax_i.spines[s].set_visible(False)
        for s in ("left","bottom"): ax_i.spines[s].set_color(INK_SOFT)
        ax_i.tick_params(colors=INK_SOFT, labelsize=14)
        ax_i.set_xlim(-0.7,0.7); ax_i.set_xticks([])
        ax_i.set_ylim(0, ymax)
        ax_i.bar([0], [val], width=0.5, color=col, alpha=0.88)
        ax_i.text(0, val+ymax*0.04, f"≈{val:.1f} kt", color=col,
                  fontproperties=SB, fontsize=30, ha="center")
        ax_i.text(0, ymax*0.93, sub, color=INK_SOFT, fontproperties=SB,
                  fontsize=16, ha="center", style="italic", linespacing=1.2)
        ax_i.set_title(title, color=INK, fontproperties=SB, fontsize=22, pad=10)
        if i==0:
            ax_i.set_ylabel("Mammal demand on HG herring (kt yr$^{-1}$)",
                            color=INK_SOFT, fontproperties=SERIF, fontsize=17)
        if i==1:
            ax_i.text(0, -ymax*0.085,
                      "≈9 of every 10 kt = humpback whale + Steller sea lion\n(recent species means)",
                      color=INK_SOFT, fontproperties=SB, fontsize=14, ha="center",
                      style="italic", linespacing=1.2, clip_on=False)
    fig.text(0.5, 0.20, f"a  ~{C20/C68:.0f}×  shift in the predator world",
             color=RUST, fontproperties=SB, fontsize=22, ha="center", style="italic")
    fig.savefig(OUT/"B_then_vs_now_panels.png", facecolor=BG); plt.close(fig)
    print("B_then_vs_now_panels.png")

# ===== C — Predation pressure (% of spawn) over time =====
def C():
    fig, ax = base("Predation pressure flipped",
                    "near-zero at the 1960s collapse  to ≈239% today")
    d = pr.dropna(subset=["pressure_pct"]).copy()
    d["pp"]=d.pressure_pct*100 if d.pressure_pct.max()<5 else d.pressure_pct
    d["pp_s"]=d.pp.rolling(5, center=True, min_periods=2).mean()
    cap = 360.0  # readable cap; spikes exceed it (annotated)
    recent = d[d.year>=2015].pp.mean()
    ax.fill_between(d.year, 0, d.pp.clip(upper=cap), color=RUST, alpha=0.14, lw=0)
    ax.plot(d.year, d.pp.clip(upper=cap), color=RUST, lw=1.4, alpha=0.45)
    ax.plot(d.year, d.pp_s.clip(upper=cap), color=RUST, lw=3.6)
    ax.axhline(100, color=INK_SOFT, lw=1.4, ls=(0,(5,4)), alpha=0.7)
    ax.text(d.year.min()+1, 110, "100% = predators eat a full year's spawn",
            color=INK_SOFT, fontproperties=SB, fontsize=15, style="italic")
    ax.scatter([2020],[min(recent,cap)], s=260, color=RUST, zorder=6,
               clip_on=False)
    ax.text(2021, min(recent,cap), f" 2015–24 mean ≈ {recent:.0f}% of annual spawn",
            color=RUST, fontproperties=SB, fontsize=17, va="center")
    ax.text(2002, cap*0.97, "(annual spikes run higher — axis capped)",
            color=INK_SOFT, fontproperties=SB, fontsize=13, style="italic", ha="center")
    for x, lab in [(1968,"1968 collapse\npredation ≈ 0%"),
                   (1994,"1994 collapse\npredation climbing")]:
        if x>=d.year.min():
            ax.axvline(x, color=AMBER, lw=2.2, ls=(0,(6,4)), alpha=0.9)
            ax.text(x+1, cap*0.55, lab,
                    color=AMBER, fontproperties=SB, fontsize=16, linespacing=1.15)
    ax.set_xlim(d.year.min(), d.year.max()); ax.set_ylim(0, cap*1.05)
    ax.set_ylabel("Predator demand as % of HG annual spawn",
                  color=INK_SOFT, fontproperties=SERIF, fontsize=18)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda v,_: f"{v:.0f}%"))
    fig.savefig(OUT/"C_pressure_pct_timeline.png", facecolor=BG); plt.close(fig)
    print("C_pressure_pct_timeline.png")

# ===== D — Herring biomass x mammal-predation overlay =====
def D():
    # Own layout (NOT base()) so the secondary axis + its label fit on-canvas.
    fig = plt.figure(figsize=(W_IN, H_IN), dpi=DPI); fig.patch.set_facecolor(BG)
    ax = fig.add_axes([0.075, 0.165, 0.835, 0.595])   # leaves room for right axis+label
    ax2 = ax.twinx()
    ax.set_facecolor(BG)
    fig.text(0.075, 0.925, "Recovery in two different oceans",
             color=INK, fontproperties=SB, fontsize=40)
    fig.text(0.075, 0.855, "herring biomass vs the marine-mammal field that eats it",
             color=RUST, fontproperties=SB, fontsize=23, style="italic")
    fig.text(0.075, 0.045,
             "m1_stier_11 focal-9 biomass + audited HG marine-mammal demand "
             "(Stier-Lab synthesis). x-axis from 1950 — see note for the pre-whaling "
             "baseline. Predator demand is a large ecological pressure, NOT a fitted "
             "m1_stier_11 coefficient.",
             color=INK_SOFT, fontproperties=MN, fontsize=12)

    X0, X1 = 1950, 2025
    b = bm[(bm.year >= X0) & (bm.year <= X1)]
    m = mam[(mam.year >= X0) & (mam.year <= X1)]

    # mammal demand (blue, right axis) — light fill + line
    ax2.fill_between(m.year, 0, m.C_kt, color=MARINE, alpha=0.22, lw=0, zorder=1)
    ax2.plot(m.year, m.C_kt, color=MARINE, lw=3.0, zorder=2)
    # herring biomass (rust, left axis)
    ax.plot(b.year, b["median"], color=RUST, lw=3.6, zorder=5)

    for x in (1968, 1994):
        ax.axvline(x, color=AMBER, lw=2.2, ls=(0, (6, 4)), alpha=0.85, zorder=3)
    ax.text(1969, 112000,
            "1968 collapse\nmammal demand ≈0.2 kt\nherring rebounds in ~5 yr",
            color=AMBER, fontproperties=SB, fontsize=16, va="top", linespacing=1.18)
    ax.text(1996, 112000,
            "1994 collapse\nmammal demand rising to ≈5.6 kt\nno recovery, 30+ yr",
            color=AMBER, fontproperties=SB, fontsize=16, va="top", linespacing=1.18)
    ax.text(1951, 6000,
            "Before commercial whaling (pre-1920) marine mammals took ~17 kt yr$^{-1}$; "
            "whaling left the 1960s ocean nearly predator-free.",
            color=INK_SOFT, fontproperties=SB, fontsize=14, style="italic", va="bottom")

    ax.set_xlim(X0, X1)
    ax.set_ylim(0, 120000)
    ax.set_xlabel("")
    ax.set_ylabel("HG herring biomass  (m1_stier_11)", color=RUST,
                  fontproperties=SERIF, fontsize=18, labelpad=10)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v/1000:.0f} kt"))
    ax.tick_params(colors=INK_SOFT, labelsize=15)
    ax.tick_params(axis="y", colors=RUST)
    for s in ("top",): ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(RUST); ax.spines["bottom"].set_color(INK_SOFT)
    ax.spines["right"].set_visible(False)
    ax.grid(True, axis="y", color=GRID, lw=0.8, alpha=0.4)

    ax2.set_ylim(0, 6.6)
    ax2.set_ylabel("marine-mammal demand on herring  (kt yr$^{-1}$)",
                   color=MARINE, fontproperties=SERIF, fontsize=18, labelpad=12,
                   rotation=270, va="bottom")
    ax2.tick_params(colors=MARINE, labelsize=15)
    for s in ("top",): ax2.spines[s].set_visible(False)
    ax2.spines["right"].set_color(MARINE); ax2.spines["left"].set_visible(False)

    # direct color-coded legend inside the plot (no axis-label hack)
    ax.plot([], [], color=RUST, lw=3.6, label="herring biomass")
    ax.plot([], [], color=MARINE, lw=3.0, label="marine-mammal demand")
    leg = ax.legend(loc="upper right", frameon=False, fontsize=15,
                    handlelength=2.2, labelcolor=INK,
                    bbox_to_anchor=(0.995, 0.99))
    fig.savefig(OUT/"D_herring_x_predation_overlay.png", facecolor=BG); plt.close(fig)
    print("D_herring_x_predation_overlay.png")

# ===== E — Predator-regime era bars + modern composition =====
def E():
    fig = plt.figure(figsize=(W_IN, H_IN), dpi=DPI); fig.patch.set_facecolor(BG)
    fig.text(0.06, 0.93, "Who eats the herring — then and now",
             color=INK, fontproperties=SB, fontsize=40)
    fig.text(0.06, 0.86, "marine-mammal demand: pre-whaling  to 1960s collapse  to today",
             color=RUST, fontproperties=SB, fontsize=23, style="italic")
    fig.text(0.06, 0.045,
             "Audited HG predator demand (Stier-Lab synthesis). Pressure, not a fitted m1_stier_11 coefficient.",
             color=INK_SOFT, fontproperties=MN, fontsize=12)
    gs = fig.add_gridspec(1, 2, left=0.06, right=0.965, top=0.74, bottom=0.14,
                          width_ratios=[1.15,1.0], wspace=0.20)
    axL = fig.add_subplot(gs[0]); axR = fig.add_subplot(gs[1])
    for ax in (axL,axR):
        ax.set_facecolor(BG)
        for s in ("top","right"): ax.spines[s].set_visible(False)
        for s in ("left","bottom"): ax.spines[s].set_color(INK_SOFT)
        ax.tick_params(colors=INK_SOFT, labelsize=14)
    eras=[("~1910\npre-whaling", C10, INK_SOFT),
          ("1960s\ncollapse", C68, AMBER),
          ("today", C20, MARINE)]
    xs=range(len(eras))
    axL.bar(list(xs),[e[1] for e in eras], width=0.6,
            color=[e[2] for e in eras], alpha=0.85)
    for i,e in enumerate(eras):
        axL.text(i, e[1]+C10*0.03, f"{e[1]:.1f} kt", color=e[2],
                 fontproperties=SB, fontsize=20, ha="center")
    axL.set_xticks(list(xs)); axL.set_xticklabels([e[0] for e in eras],
        color=INK_SOFT, fontproperties=SB, fontsize=15)
    axL.set_ylim(0, C10*1.18)
    axL.set_ylabel("Mammal demand on HG herring (kt yr$^{-1}$)",
                   color=INK_SOFT, fontproperties=SERIF, fontsize=16)
    axL.grid(True, axis="y", color=GRID, lw=0.8, alpha=0.5)
    axL.text(1, C10*0.55, "the 1960s collapse\nhappened HERE —\nwhales gone",
             color=AMBER, fontproperties=SB, fontsize=16, ha="center",
             style="italic", linespacing=1.15)
    modern=(sp[sp.group=="mammals"].assign(kt=lambda d:d.mean_consumption_t/1000)
            .sort_values("kt"))
    cols={"Humpback whale":MARINE,"Steller sea lion":"#4f7da6",
          "California sea lion":PLUM,"Harbour seal":KELP}
    axR.barh(modern.species, modern.kt,
             color=[cols.get(s,INK_SOFT) for s in modern.species], alpha=0.9)
    for i,(s,v) in enumerate(zip(modern.species, modern.kt)):
        axR.text(v+0.08, i, f"{v:.2f} kt", color=INK, fontproperties=SB,
                 fontsize=15, va="center")
    axR.set_xlim(0, modern.kt.max()*1.25)
    axR.set_title("today's mammal community  (recent annual mean by species)",
                  color=INK, fontproperties=SB, fontsize=18, pad=8)
    axR.tick_params(axis="y", labelsize=15)
    for lab in axR.get_yticklabels(): lab.set_color(INK); lab.set_fontproperties(SB)
    axR.grid(True, axis="x", color=GRID, lw=0.8, alpha=0.5)
    fig.savefig(OUT/"E_era_bars_composition.png", facecolor=BG); plt.close(fig)
    print("E_era_bars_composition.png")

if __name__=="__main__":
    A(); B(); C(); D(); E()
    print("done ->", OUT)
