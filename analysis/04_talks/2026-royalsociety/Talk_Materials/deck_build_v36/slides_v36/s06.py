"""S06 — Wildlife sequence (motion): everything else comes with them"""
from helpers_v36 import *


def build_s06(prs):
    s = add_slide(prs, dark=True)

    # Dark backdrop in case media gaps show through
    add_rect(s, 0, 0, DECK_W_IN, DECK_H_IN, C_DARK)

    # Layout: primary big LEFT (bear+white wolf), three thumbnails stacked RIGHT
    # Primary: take left 2/3 of width, full height
    primary_w = DECK_W_IN * 0.62  # ~8.27"
    primary_h = DECK_H_IN          # 7.5"
    add_video(s,
              clip("v2_04_bear_and_white_wolf.mp4"),
              poster("v2_04_bear_and_white_wolf.jpg"),
              0, 0, primary_w, primary_h)

    # Thumbnails — right column, three stacked
    thumb_x = primary_w
    thumb_w = DECK_W_IN - primary_w  # ~5.07"
    thumb_h = DECK_H_IN / 3.0        # 2.5"

    # Thumb 1: eagles catching fish
    add_video(s,
              clip("v1_14_eagles_catching_fish.mp4"),
              poster("v1_14_eagles_catching_fish.jpg"),
              thumb_x, 0, thumb_w, thumb_h)
    # Thumb 2: sea lion underwater
    add_video(s,
              clip("v1_02_sealion_underwater.mp4"),
              poster("v1_02_sealion_underwater.jpg"),
              thumb_x, thumb_h, thumb_w, thumb_h)
    # Thumb 3: sea lion colony
    add_video(s,
              clip("v1_15_sea_lion_colony.mp4"),
              poster("v1_15_sea_lion_colony.jpg"),
              thumb_x, 2 * thumb_h, thumb_w, thumb_h)

    # Pacific Wild footage credit
    footage_credit(s, dark=True)

    speaker_note(s,
        "And everything else comes with them. Bears. Wolves. Eagles. Sea "
        "lions. The whole coast eats.")
