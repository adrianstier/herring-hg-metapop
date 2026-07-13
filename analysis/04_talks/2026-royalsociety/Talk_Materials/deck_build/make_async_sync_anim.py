#!/usr/bin/env python3
"""
Async -> synchronous portfolio animation — deck-styled restyle of the 2020
Ecosphere `sim_anim.mp4`.

Restyle target: Code/archive/stier-2020-ecosphere-herring/_animation/sim_anim.mp4
(subpop series wander asynchronously -> "Major Event" -> lock synchronous).

DESIGN DECISION (Adrian, 2026-05-19): like the 2020 original this is an
ILLUSTRATIVE SIMULATION (real annual HG spawn is too zero-spiky to read as an
animation — it was always a simulation for this reason), but **calibrated to
Haida Gwaii**: 11 subpopulations, and the synchrony parameter is tuned so the
computed Loreau & de Mazancourt synchrony rises from the real pre-1994 value
to the real post-1994 value (the actual S9 result). The "major event" is the
1994 roe-fishery closure. Explicitly labelled illustrative on-figure — it
demonstrates the mechanism behind S9, it is not the observed series.

Output: deck_assets/sim_anim_v2.mp4 (+ sim_anim_v2_poster.jpg), embedded by
build_pptx_native.js as a video slide near S9. Canonical deck aesthetic
(dark #0e0e0e, track-colour contract, portable fonts) per deck_build/README.md.
Run standalone:  python3 make_async_sync_anim.py
"""
import numpy as np, pandas as pd
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm, rcParams
from matplotlib.animation import FuncAnimation, FFMpegWriter

REPO = Path(__file__).resolve().parents[3]
ROLL = REPO / "Output" / "diagnostics" / "deck_s09_synchrony_rolling.csv"
DA   = Path(__file__).resolve().parents[1] / "deck_assets"
OUT  = DA / "sim_anim_v2.mp4"
POSTER = DA / "sim_anim_v2_poster.jpg"

BG="#0e0e0e"; INK="#f0eee9"; SOFT="#a8a59f"; RUST="#d9714f"; AMBER="#cfa055"
KELP="#8aa074"; GRID="#2a2825"

def _pick(*c):
    for x in c:
        if Path(x).is_file(): return x
    return None
_LIB="/usr/share/fonts/truetype/liberation"; _MAC="/System/Library/Fonts/Supplemental"
SERIF=_pick(f"{_LIB}/LiberationSerif-Regular.ttf", f"{_MAC}/Georgia.ttf")
SERIF_B=_pick(f"{_LIB}/LiberationSerif-Bold.ttf", f"{_MAC}/Georgia Bold.ttf")
for p in (SERIF, SERIF_B):
    if p: fm.fontManager.addfont(p)
rcParams["font.family"]="Georgia" if (SERIF and "Georgia" in SERIF) else "Liberation Serif"
rcParams["text.color"]=INK
for k in ("axes.edgecolor","xtick.color","ytick.color","axes.labelcolor"): rcParams[k]=SOFT

# --- real HG synchrony calibration target (from the S9 rolling metric) -------
YEARS=np.arange(1951,2026); EVENT=1994; NSUB=11
try:
    r=pd.read_csv(ROLL); r["y"]=r["window_mid"].astype(int)
    PHI_PRE=float(r[r["y"]<EVENT]["synchrony"].mean())
    PHI_POST=float(r[r["y"]>=EVENT]["synchrony"].mean())
except Exception:
    PHI_PRE, PHI_POST = 0.31, 0.40
PHI_RATIO=PHI_POST/PHI_PRE

def synchrony(M):                       # Loreau & de Mazancourt (verbatim Code/04 form)
    sds=M.std(axis=0, ddof=0)
    act=sds>0
    if act.sum()<2: return np.nan
    Ma=M[:,act]
    return np.var(Ma.sum(axis=1), ddof=0)/(Ma.std(axis=0, ddof=0).sum()**2)

def smooth(x, k=5):
    ker=np.ones(k)/k
    return np.convolve(x, ker, mode="same")

def simulate(w):
    """11 subpops = shared latent factor (weight w) + idiosyncratic, smoothed.
    w low pre-1994 (asynchronous) -> high post-1994 (synchronous)."""
    rng=np.random.default_rng(7)
    n=len(YEARS)
    common=smooth(np.cumsum(rng.normal(0,1,n)))
    common=(common-common.mean())/common.std()
    wt=np.where(YEARS<EVENT, w[0], w[1])
    # smooth the synchrony transition over ~4 yr around the event
    for t in range(1,n): wt[t]=0.6*wt[t]+0.4*wt[t-1]
    S=np.zeros((n,NSUB))
    for i in range(NSUB):
        idio=smooth(np.cumsum(rng.normal(0,1,n)))
        idio=(idio-idio.mean())/(idio.std()+1e-9)
        lvl=3.0+0.5*rng.normal()
        S[:,i]=lvl + (wt*common + (1-wt)*idio)*0.9 + rng.normal(0,0.05,n)
    return S

# tiny deterministic calibration: hold w_pre, search w_post so the simulated
# pre/post synchrony ratio matches the real one.
best=None
for wpre in (0.18,):
    for wpost in np.linspace(0.55,0.95,17):
        S=simulate((wpre,wpost))
        pre=synchrony(S[YEARS<EVENT]); post=synchrony(S[YEARS>=EVENT])
        err=abs((post/pre)-PHI_RATIO)
        if best is None or err<best[0]: best=(err,wpre,wpost,pre,post)
_,WPRE,WPOST,sim_pre,sim_post=best
S=simulate((WPRE,WPOST))
agg=S.mean(axis=1)
ramp=plt.cm.YlGnBu(np.linspace(0.32,0.93,NSUB))
phi_txt=(f"subpopulation synchrony  {PHI_PRE:.2f}  ->  {PHI_POST:.2f}"
         f"   (+{round((PHI_RATIO-1)*100)}%, real HG / S9)")

FPS=12; HOLD=20; frames=len(YEARS)+HOLD
fig,ax=plt.subplots(figsize=(16,9), dpi=120)
fig.patch.set_facecolor(BG)
YMAX=S.max()*1.03; YMIN=S.min()-0.2

def draw(i):
    ax.clear(); ax.set_facecolor(BG)
    k=min(i, len(YEARS)-1); yv=YEARS[:k+1]
    for j in range(NSUB):
        ax.plot(yv, S[:k+1,j], color=ramp[j], lw=1.9, alpha=0.85)
    ax.plot(yv, agg[:k+1], color=SOFT, lw=5.0, alpha=0.55,
            solid_capstyle="round", zorder=1)
    cur=YEARS[k]
    if cur>=EVENT:
        ax.axvline(EVENT, color=AMBER, lw=2.4, ls="--", alpha=0.9)
        ax.text(EVENT+0.7, YMAX*0.97, "major event:\nroe fishery closed · 1994",
                color=AMBER, fontsize=14.5, va="top",
                fontfamily=rcParams["font.family"], linespacing=1.1)
    phase=("asynchronous portfolio — subpopulations buffer each other"
           if cur<EVENT else
           "synchronized — the portfolio no longer buffers")
    ax.text(0.012,0.965,"The portfolio eroded", transform=ax.transAxes,
            fontsize=27, fontweight="bold", color=INK, va="top")
    ax.text(0.012,0.905,f"{cur}   ·   {phase}", transform=ax.transAxes,
            fontsize=15.5, color=(SOFT if cur<EVENT else RUST), va="top")
    ax.set_xlim(YEARS.min(), YEARS.max()); ax.set_ylim(YMIN, YMAX)
    ax.set_xlabel("Year", fontsize=15)
    ax.set_ylabel("Subpopulation biomass (illustrative)", fontsize=15)
    ax.set_yticks([])
    ax.tick_params(labelsize=12)
    for sp in ("top","right","left"): ax.spines[sp].set_visible(False)
    ax.spines["bottom"].set_color(SOFT)
    ax.grid(True, axis="x", color=GRID, lw=0.7, alpha=0.5)
    ax.text(0.012,0.05, phi_txt, transform=ax.transAxes, fontsize=14,
            color=AMBER, style="italic")
    ax.text(0.988,0.05,
            "Illustrative simulation calibrated to Haida Gwaii (11 subpopulations;"
            " synchrony tuned to the real S9 metric) — mechanism, not observed series",
            transform=ax.transAxes, fontsize=10.5, color=SOFT, ha="right")
    fig.tight_layout(rect=[0.01,0.01,0.99,0.99])
    return []

anim=FuncAnimation(fig, draw, frames=frames, blit=False)
OUT.parent.mkdir(parents=True, exist_ok=True)
anim.save(str(OUT), writer=FFMpegWriter(fps=FPS, bitrate=2400,
          extra_args=["-pix_fmt","yuv420p"]))
draw(frames-1); fig.savefig(str(POSTER), dpi=120, facecolor=BG); plt.close(fig)
print(f"wrote {OUT.name} ({OUT.stat().st_size//1024} KB) + {POSTER.name} | "
      f"calib w_post={WPOST:.2f} sim phi {sim_pre:.2f}->{sim_post:.2f} "
      f"(target real {PHI_PRE:.2f}->{PHI_POST:.2f})")
