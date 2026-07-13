#!/bin/bash
# Render all 14 deck slides to 3840x2160 PNG into ../deck_assets/ (clearly
# labelled, slide-ordered). Overlay slides authored at native 3840; schematic
# slides authored at ~1180-1920 viewport -> render at 1920x1080 @2x.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$HOME/stier-2027-herring-metapopulation"
TM="$REPO/analysis/04_talks/2026-royalsociety/Talk_Materials"
RFIG="$REPO/Output/figures/lecture/deck"
DA="$TM/deck_assets"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p "$DA"

overlay(){ "$CH" --headless=new --disable-gpu --hide-scrollbars --force-color-profile=srgb \
  --window-size=3840,2160 --force-device-scale-factor=1 \
  --screenshot="$DA/$2" "file://$HERE/slides_html/$1" >/dev/null 2>&1 && echo "  $2"; }
schem(){ "$CH" --headless=new --disable-gpu --hide-scrollbars --force-color-profile=srgb \
  --window-size=1920,1080 --force-device-scale-factor=2 \
  --screenshot="$DA/$2" "file://$TM/$1" >/dev/null 2>&1 && echo "  $2"; }

overlay s01.html 01_title.png
overlay s02.html 02_shore.png
overlay s03.html 03_people.png
overlay s04.html 04_baseline.png
schem   s5_two_collapses.html       05_two_collapses.png
cp "$RFIG/s06_climate_pdo.png"      "$DA/06_climate_pdo.png" && echo "  06_climate_pdo.png"
schem   s7_two_scales.html          07_two_scales.png
cp "$RFIG/s08_realized_growth.png"  "$DA/08_realized_growth.png" && echo "  08_realized_growth.png"
cp "$RFIG/s09_synchrony.png"        "$DA/09_synchrony.png" && echo "  09_synchrony.png"
overlay s10.html 10_predators.png
schem   s11_triple_bottom_line.html 11_triple_bottom_line.png
schem   herring_decoupling_figure.html 12_decoupling.png
schem   s13_takeaways.html          13_takeaways.png
overlay s14.html 14_close.png
echo "Deck assets -> $DA"
