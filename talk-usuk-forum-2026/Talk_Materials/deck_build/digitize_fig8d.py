#!/usr/bin/env python3
# Digitize the black SPAWNING-BIOMASS median line from DFO SR 2025/005 Fig 8(d)
# (Haida Gwaii SCA, 1951-2024). Reproducible pixel trace — NOT eyeballed.
#
# y-calibration is INTERNAL & EXACT: the red horizontal line = LRP = 0.3*SB0 =
# 6.452 kt and the blue line = 0.75*SB_Prod = 19.107 kt (DFO SR 2025/005
# Table 19). Two known values -> exact linear pixel->kt map.
# x-calibration: detect the major decade vertical gridlines (1950..2020).
import numpy as np
from PIL import Image
import csv, os

SRC = os.path.join(os.path.dirname(__file__), "dfo_src",
                   "SR2025005_page35_400dpi.png")
OUT = os.path.join(os.path.dirname(__file__), "dfo_src")
im = Image.open(SRC).convert("RGB")
W, H = im.size
a = np.asarray(im).astype(int)               # (H,W,3)

# Panel (d) lives mid-right; crop generous then work in crop coords.
x0, y0, x1, y1 = int(W*0.50), int(H*0.295), int(W*0.99), int(H*0.505)
c = a[y0:y1, x0:x1]                           # crop
ch, cw, _ = c.shape
R, G, B = c[:,:,0], c[:,:,1], c[:,:,2]

# --- y-calibration from the red & blue reference lines ---
red  = (R > 150) & (G < 95) & (B < 95)
blue = (B > 150) & (R < 95) & (G < 130)
red_rows  = np.where(red.sum(axis=1)  > 0.45*cw)[0]
blue_rows = np.where(blue.sum(axis=1) > 0.45*cw)[0]
y_red  = red_rows.mean()
y_blue = blue_rows.mean()
V_RED, V_BLUE = 6.452, 19.107                 # Table 19 medians (kt)
# value = m*ypix + k
m = (V_RED - V_BLUE) / (y_red - y_blue)
k = V_RED - m*y_red
def y2v(yp): return m*yp + k

mx = np.maximum(np.maximum(R,G),B); mn = np.minimum(np.minimum(R,G),B)
blackpx = (mx < 110) & ((mx-mn) < 45)         # near-black/neutral

# --- plot interior X-extent from the red/blue reference-line span ---
# geom_hline spans the full panel data region -> its column extent = panel.
ref = red | blue
refcols = np.where(ref.sum(axis=0) > 0)[0]
xL, xR = int(refcols.min()), int(refcols.max())
# ggplot continuous-x default expansion = mult 0.05 each side.
# Fig 8(d) data x-range = 1951..2025 (incl. 2025 forecast pt). The decade
# tick LABELS are 1950..2020; gridlines sit at those years inside the panel.
# Detect decade vertical gridlines strictly INSIDE (xL,xR), in a clean upper
# band (few data here except the 1956 bar) using neutral light-grey columns.
yb0, yb1 = max(0,int(min(y_red,y_blue))-9999), 0  # placeholder
# clean band = top ~12% of interior (above most data); interior top approx:
itop = max(0, int(y_red - (V_RED)/((V_BLUE-V_RED)/(y_blue-y_red+1e-9))) ) if False else 5
band = c[itop:itop+ max(20,int(0.10*ch)), xL+3:xR-3]
mxb = np.maximum(np.maximum(band[:,:,0],band[:,:,1]),band[:,:,2])
mnb = np.minimum(np.minimum(band[:,:,0],band[:,:,1]),band[:,:,2])
gl  = (mxb < 225) & (mxb > 120) & ((mxb-mnb) < 25)   # grey gridline
prof = gl.sum(axis=0)
thr = max(3, 0.5*band.shape[0])
cols = np.where(prof >= thr)[0] + (xL+3)
# cluster
if len(cols):
    groups,cur=[],[cols[0]]
    for v in cols[1:]:
        if v-cur[-1]<=4: cur.append(v)
        else: groups.append(int(np.mean(cur))); cur=[v]
    groups.append(int(np.mean(cur))); groups=np.array(sorted(groups))
else:
    groups=np.array([])
years_dec = np.array([1950,1960,1970,1980,1990,2000,2010,2020])
# Robust: anchor X by the panel edges + ggplot 0.05 expansion (data 1951..2025)
dmin,dmax = 1951.0, 2025.0
pad = 0.05*(dmax-dmin)
panel_lo, panel_hi = dmin-pad, dmax+pad         # years at xL, xR
def yr2x(y): return xL + (y-panel_lo)/(panel_hi-panel_lo)*(xR-xL)
def x2yr(xp): return panel_lo + (xp-xL)/(xR-xL)*(panel_hi-panel_lo)
# QA the edge model against detected decade gridlines (if any)
if len(groups)>=6:
    gy = np.array([x2yr(g) for g in groups])
    # snap to nearest decade and report residual
    snap = np.round(gy/10)*10
    resid = np.abs(gy-snap)
    print(f"x-edge model: xL={xL} xR={xR} panel[{panel_lo:.1f},{panel_hi:.1f}]"
          f"  gridline-decade residual median={np.median(resid):.2f} yr (n={len(groups)})")
else:
    print(f"x-edge model: xL={xL} xR={xR} panel[{panel_lo:.1f},{panel_hi:.1f}]  (no gridline check)")
y_top = max(0, int(min(y_red, y_blue)) - 250)

# --- isolate the black SB line ---
# near-black & neutral; exclude red/blue line rows; exclude ribbon (mid grey)
black = (mx < 95) & ((mx-mn) < 38)
black[red] = False; black[blue] = False
# NOTE: do NOT blank the red/blue rows wholesale — the SB line hugs the LRP
# in the recent low period; per-pixel colour exclusion above is enough.
# restrict to plot interior using the (solid) y-calibration: the value=0
# baseline is at pixel (0-k)/m; ignore anything at/below it (axis, labels,
# catch-bar bases) and anything implausibly high (> 85 kt).
y_zero = int(round((0.0 - k)/m))
y_hi   = int(round((85.0 - k)/m))
black[y_zero+1:, :] = False
black[:max(0,y_hi), :] = False

rows = []
for year in range(1951, 2025):
    xp = int(round(yr2x(year)))
    if xp < 2 or xp >= cw-2: continue
    band = black[:, xp-1:xp+2].any(axis=1)
    ys = np.where(band)[0]
    if len(ys) == 0:
        rows.append((year, None)); continue
    # the SB line: among black pixels, exclude very-bottom catch-bar tops by
    # taking the densest vertical cluster's centre, preferring the cluster
    # whose value is plausible (>0). Use median of the largest run.
    ys.sort()
    runs, cur = [], [ys[0]]
    for v in ys[1:]:
        if v-cur[-1] <= 4: cur.append(v)
        else: runs.append(cur); cur=[v]
    runs.append(cur)
    # choose run with most pixels (the continuous stroke), tie -> upper
    run = max(runs, key=lambda r:(len(r), -np.mean(r)))
    yc = float(np.mean(run))
    rows.append((year, round(y2v(yc), 3)))

# --- QA print ---
print(f"y-cal: red@{y_red:.1f}=6.452  blue@{y_blue:.1f}=19.107  m={m:.5f} k={k:.3f}")
print(f"x-cal: edge model panel[{panel_lo:.1f},{panel_hi:.1f}] xL={xL} xR={xR}")
anch = {1955:'~55-61',1968:'low ~2-5',1980:'~28-33',1990:'~25-31',
        2010:'~9-12',2024:'≈6.4 (Table15)'}
d = dict(rows)
for y,exp in anch.items():
    print(f"  {y}: digitized={d.get(y)}  expect {exp}")

with open(os.path.join(OUT,"dfo_sr2025005_fig8d_SB_digitized_1951_2024.csv"),"w",newline="") as f:
    w=csv.writer(f); w.writerow(["year","sb_kt_digitized","source","note"])
    for y,v in rows:
        w.writerow([y,v,"DFO CSAS SR 2025/005 Fig 8(d)",
                    "black SB median line; auto pixel-trace; y-cal from red LRP=6.452 & blue 0.75SBprod=19.107 (Table 19)"])
print("WROTE dfo_sr2025005_fig8d_SB_digitized_1951_2024.csv  (n="+str(len([r for r in rows if r[1] is not None]))+")")

# --- visual QA overlay ---
ov = Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8)).convert("RGB")
pix = ov.load()
for year,v in rows:
    if v is None: continue
    xp=int(round(yr2x(year))); yp=int(round((v-k)/m))
    for dx in range(-2,3):
        for dy in range(-2,3):
            X,Y=xp+dx,yp+dy
            if 0<=X<cw and 0<=Y<ch: pix[X,Y]=(255,0,255)
ov.save(os.path.join(OUT,"fig8d_digitize_overlay.png"))
print("WROTE fig8d_digitize_overlay.png")
