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

# --- x-calibration: black x-axis TICK MARKS below the bottom axis ---
# bottom axis = the lowest long horizontal black run
rowblack = blackpx.sum(axis=1)
axis_rows = np.where(rowblack > 0.55*cw)[0]
y_axis = axis_rows.max()                       # bottom axis row
# tick marks hang just below the axis
tb = blackpx[y_axis+2:y_axis+18, :]
tickcols = np.where(tb.sum(axis=0) >= 3)[0]
groups, cur = [], [tickcols[0]]
for v in tickcols[1:]:
    if v-cur[-1] <= 4: cur.append(v)
    else: groups.append(int(np.mean(cur))); cur=[v]
groups.append(int(np.mean(cur)))
groups = np.array(sorted(groups))
# keep the 8 evenly-spaced decade ticks (largest near-uniform run)
diffs = np.diff(groups)
step = np.median(diffs)
# greedily select ticks ~step apart
sel=[groups[0]]
for g in groups[1:]:
    if abs((g-sel[-1]) - step) < 0.4*step or (g-sel[-1])>0.6*step:
        sel.append(g)
sel=np.array(sel)
if len(sel) >= 8:
    xs = sel[:8]
else:
    xs = np.linspace(groups[0], groups[-1], 8)
years_dec = np.array([1950,1960,1970,1980,1990,2000,2010,2020])
px = np.polyfit(years_dec, xs, 1)
def yr2x(y): return np.polyval(px, y)
def x2yr(xp): return (xp - px[1])/px[0]
# plot interior y-bounds: top gridline (~80 kt) .. bottom axis
y_top = max(0, int(min(y_red, y_blue)) - 250)

# --- isolate the black SB line ---
# near-black & neutral; exclude red/blue line rows; exclude ribbon (mid grey)
black = (mx < 95) & ((mx-mn) < 38)
black[red] = False; black[blue] = False
# drop the 2 reference-line rows +/-3 px so they don't bleed in
for yr in list(red_rows)+list(blue_rows):
    black[max(0,yr-3):yr+4,:] = False

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
print(f"x-cal: decades px={np.round(xs,1)}  year->px slope={px[0]:.3f}")
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
