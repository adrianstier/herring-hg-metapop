"""S04 — When the herring arrive (2-clip video sequence)"""
from helpers_v36 import *
from pathlib import Path


def build_s04(prs):
    s = add_slide(prs, dark=True)

    # Dark backdrop (deck is already dark; explicit rect for safety in case media don't fully cover)
    add_rect(s, 0, 0, DECK_W_IN, DECK_H_IN, C_DARK)

    half = DECK_W_IN / 2.0

    # LEFT: aerial whitewater spawn — primary movie embedded with poster
    aerial_clip = clip("v2_01_aerial_whitewater_spawn.mp4")
    aerial_poster = poster("v2_01_aerial_whitewater_spawn.jpg")
    add_video(s, aerial_clip, aerial_poster, 0, 0, half, DECK_H_IN)

    # RIGHT: underwater school (herring_schooling.mp4 lives at top-level Herring_Talk_Clips/)
    # Use v2_02_underwater_school.jpg as poster (no dedicated poster for herring_schooling.mp4)
    underwater_path = CLIPS_TOP / "herring_schooling.mp4"
    if not underwater_path.exists():
        underwater_path = Path(clip("v2_02_underwater_school.mp4"))
    underwater_poster = poster("v2_02_underwater_school.jpg")
    add_video(s, str(underwater_path), underwater_poster, half, 0, half, DECK_H_IN)

    # Footage credit (no overlay text)
    footage_credit(s, dark=True)

    speaker_note(s,
        "[silence over aerial ~3 s] This is the change you're seeing — "
        "[cut to underwater on the dash] — made by these. "
        "[silence over remaining underwater footage]")
