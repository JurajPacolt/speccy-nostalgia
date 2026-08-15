"""The blackletter alphabet of the DARK ISLAND logo.

Every letter is written with the broad nib of `pen.py`, so it is a list of paths
and not a list of pixels. The nib is held at thirty degrees: a stroke pulled
down leaves a heavy stem with the slanted head and foot of the gothic letters,
a stroke pulled up to the right leaves a hairline.

The letters are gothic textura, so they are narrow, they stand upright and they
have no round parts at all - every bowl is broken into straight segments and
meets the stem in a corner. The letter box is twenty four pixels high, which is
three character rows of the screen; the capitals stand between y=3.5 and y=20.5
and the nib itself adds about one pixel over and under that.
"""

from __future__ import annotations

from typing import Dict, List, Sequence, Tuple

from pen import Pen, Sheet

HEIGHT = 24
TOP = 3.5
BASE = 20.5

NIB_ANGLE = -30.0
BROAD = 4.6
MEDIUM = 3.4
HAIR = 2.0

Point = Tuple[float, float]
Stroke = Tuple[float, List[Point]]


def broad(*points: Point) -> Stroke:
    return (BROAD, list(points))


def medium(*points: Point) -> Stroke:
    return (MEDIUM, list(points))


def hair(*points: Point) -> Stroke:
    return (HAIR, list(points))


# Every letter: the width of its box and the strokes that write it. The order of
# the strokes is the order the pen would write them.
LETTERS: Dict[str, Dict[str, object]] = {
    # The pointed arch of the gothic A: a light stroke up to the apex, a heavy
    # one down from it and a bar tying them together low, so the eye of the
    # letter stays open.
    "A": {
        "width": 17,
        "strokes": [
            medium((1.5, BASE), (7.5, TOP)),
            broad((7.5, TOP), (14.5, BASE)),
            hair((3.5, 14.5), (12.5, 14.5)),
            hair((6.0, TOP - 2.0), (9.5, TOP - 2.0)),
        ],
    },
    # The stem and a bowl broken into four straight segments.
    "D": {
        "width": 17,
        "strokes": [
            broad((3.5, TOP), (3.5, BASE)),
            broad((3.5, TOP), (9.5, TOP), (14.0, 8.0), (14.0, 16.0), (9.5, BASE), (3.5, BASE)),
            hair((1.0, 13.5), (6.5, 10.0)),
        ],
    },
    # One stem, with the hairline of the manuscript across it.
    "I": {
        "width": 9,
        "strokes": [
            broad((4.0, TOP), (4.0, BASE)),
            hair((1.0, 13.5), (7.0, 10.0)),
            hair((1.5, TOP - 2.0), (6.5, TOP - 2.0)),
            hair((1.5, BASE + 2.0), (6.5, BASE + 2.0)),
        ],
    },
    # The stem, the light arm that comes down to it and the heavy leg.
    "K": {
        "width": 16,
        "strokes": [
            broad((3.5, TOP), (3.5, BASE)),
            medium((13.0, TOP), (5.5, 11.5)),
            broad((5.0, 11.0), (13.0, BASE)),
            hair((1.0, 16.0), (6.5, 12.5)),
        ],
    },
    # A stem standing on a foot that runs out to the right.
    "L": {
        "width": 13,
        "strokes": [
            broad((3.5, TOP), (3.5, BASE)),
            broad((3.5, BASE), (11.0, BASE)),
            hair((1.0, 13.5), (6.5, 10.0)),
            hair((1.5, TOP - 2.0), (6.5, TOP - 2.0)),
        ],
    },
    # Two stems tied by the diagonal.
    "N": {
        "width": 17,
        "strokes": [
            broad((3.5, TOP), (3.5, BASE)),
            medium((3.5, TOP + 1.5), (13.0, BASE - 1.5)),
            broad((13.0, TOP), (13.0, BASE)),
            hair((1.5, TOP - 2.0), (6.0, TOP - 2.0)),
            hair((10.5, BASE + 2.0), (15.0, BASE + 2.0)),
        ],
    },
    # The stem, the small broken bowl on it and the leg that steps out of it.
    "R": {
        "width": 16,
        "strokes": [
            broad((3.5, TOP), (3.5, BASE)),
            broad((3.5, TOP), (9.0, TOP), (12.5, 6.5), (9.0, 12.5), (3.5, 12.5)),
            broad((8.0, 12.5), (13.0, BASE)),
            hair((1.0, 17.0), (6.0, 17.0)),
        ],
    },
    # The gothic S is written in one pull: two heavy hooks at the top and at the
    # bottom, joined by the light spine the nib leaves when it travels up.
    "S": {
        "width": 13,
        "strokes": [
            broad((10.5, 6.0), (9.0, TOP), (5.0, TOP), (2.5, 6.0), (5.0, 9.0)),
            medium((5.0, 9.0), (8.5, 11.5)),
            broad((8.5, 11.5), (10.5, 15.0), (8.0, BASE), (4.0, BASE), (2.0, 17.5)),
            hair((8.5, TOP - 2.0), (12.0, TOP - 2.0)),
        ],
    },
    # The numeral of the first island.
    "1": {
        "width": 10,
        "strokes": [
            broad((4.5, TOP), (4.5, BASE)),
            medium((1.0, 7.0), (4.5, TOP)),
            broad((1.5, BASE), (8.0, BASE)),
        ],
    },
}


def render(letter: str) -> str:
    """Write one letter with the pen and return it as ASCII art."""
    if letter not in LETTERS:
        raise ValueError("the logo alphabet has no letter {!r}".format(letter))
    entry = LETTERS[letter]
    sheet = Sheet(int(entry["width"]) + 3, HEIGHT)
    for width, points in entry["strokes"]:  # type: ignore[assignment]
        Pen(width=width, angle=NIB_ANGLE).stroke(sheet.plot, points)
    return sheet.art()


def alphabet() -> Dict[str, str]:
    """Every letter of the logo alphabet, as ASCII art."""
    return dict((letter, render(letter)) for letter in LETTERS)
