"""Generate the sprites the rooms of Dark Island 1 are built from.

    py -3 tools/generate_sprites.py

Writes `src/sprites_land.asm` and the sheet `gfx/sprites.png`. Every sprite is
a bitmap by pixel lines followed by one attribute for every one of its
characters, which is what `DrawSprite` in `sprite_utils.asm` reads.

The flat things - the ground, the grass, the ladder - are written as ASCII art,
because a wall wants a straight edge. The dead tree is painted with the round
brush of `pen.py` instead: a branch has to keep its thickness wherever it turns,
and no amount of typing dots gets that right.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image

import zx
from pen import Brush, line

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "src" / "sprites_land.asm"
PREVIEW_PATH = ROOT / "gfx" / "sprites.png"


# ---------------------------------------------------------------------------
# The artwork.

# A 4x4 Bayer matrix. At Spectrum resolution an ordered pattern reads as a
# stable half-tone on a CRT, while random isolated pixels only look noisy.
_BAYER_4 = (
    (0, 8, 2, 10),
    (12, 4, 14, 6),
    (3, 11, 1, 9),
    (15, 7, 13, 5),
)


def ground_art(width: int) -> str:
    """A block of ground, lit at the top and fading into broken stone.

    The phase changes between character cells. This keeps five copies of the
    long block from looking like a strip of identical 8x8 tiles.
    """
    levels = (16, 15, 14, 13, 11, 10, 8, 7)
    lines = []
    for y in range(8):
        row = []
        for x in range(width):
            phase = (x // 8) % 4
            dither = _BAYER_4[(y + phase) % 4][(x + phase * 2) % 4]
            row.append("#" if dither < levels[y] else ".")
        lines.append("".join(row))
    return "\n".join(lines)


def shaded_art(mask: str, levels, horizontal_falloff: int = 0,
               solid_base: bool = False) -> str:
    """Fill a silhouette with ordered light and a solid top-left rim.

    `levels` gives the amount of ink on every line, from 0 to 16. A lit edge is
    kept continuous; the shadow edge is allowed to dissolve into the dither.
    """
    source = zx.art_lines(mask)
    width = max(len(line) for line in source)
    source = [line.ljust(width, ".") for line in source]
    height = len(source)
    lines = []
    for y, line in enumerate(source):
        row = []
        for x, char in enumerate(line):
            if char != "#":
                row.append(".")
                continue
            left_empty = x == 0 or source[y][x - 1] != "#"
            above_empty = y == 0 or source[y - 1][x] != "#"
            below_empty = y + 1 == height or source[y + 1][x] != "#"
            lit_edge = left_empty or above_empty or (solid_base and below_empty)
            fade = (x * horizontal_falloff) // max(1, width - 1)
            level = max(0, min(16, levels[min(y, len(levels) - 1)] - fade))
            ink = lit_edge or _BAYER_4[y % 4][x % 4] < level
            row.append("#" if ink else ".")
        lines.append("".join(row))
    return "\n".join(lines)


def ladder_art() -> str:
    """Two rounded rails and five rungs with a dithered lower edge."""
    lines = []
    for y in range(24):
        row = ["."] * 16
        # One solid edge keeps each rail continuous; its other edge catches
        # every second pixel and gives a suggestion of rounded wood.
        row[0] = "#"
        row[12] = "#"
        if y % 2 == 0:
            row[1] = "#"
            row[13] = "#"
        if y % 6 == 2:
            for x in range(14):
                row[x] = "#"
        elif y % 6 == 3:
            for x in range(2, 12, 2):
                row[x] = "#"
        lines.append("".join(row))
    return "\n".join(lines)


def crate_art() -> str:
    """A framed two-plank crate with bracing and shaded wooden faces."""
    pixels = [bytearray(16) for _ in range(16)]

    def plot(x, y):
        if 0 <= x < 16 and 0 <= y < 16:
            pixels[y][x] = 1

    # The outer frame and the board separating the two halves.
    for x in range(16):
        plot(x, 0)
        plot(x, 8)
        plot(x, 15)
    for y in range(16):
        plot(0, y)
        plot(15, y)

    # Cross-braces in both halves. Their one-pixel diagonals stay crisp; the
    # lightly stippled faces behind them supply the wood grain and shadow.
    for top in (1, 9):
        for offset in range(6):
            x = 2 + offset * 2
            plot(x, top + offset)
            plot(x + 1, top + offset)
            plot(13 - offset * 2, top + offset)
            plot(12 - offset * 2, top + offset)
    for y in list(range(1, 8)) + list(range(9, 15)):
        level = 4 if y < 8 else 3
        for x in range(1, 15):
            if _BAYER_4[y % 4][x % 4] < level:
                plot(x, y)

    return "\n".join(
        "".join("#" if value else "." for value in row) for row in pixels
    )


def cloud_mask_art() -> str:
    """A broad low cloud made from overlapping rounded lobes."""
    width, height = 40, 24
    lobes = (
        (10.0, 10.0, 9.5, 6.0),
        (20.0, 6.0, 10.5, 6.5),
        (30.0, 10.0, 9.0, 6.0),
        (20.0, 12.0, 19.0, 7.0),
    )
    lines = []
    for y in range(height):
        row = []
        for x in range(width):
            inside = any(
                ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0
                for cx, cy, rx, ry in lobes
            )
            row.append("#" if inside else ".")
        lines.append("".join(row))
    return "\n".join(lines)


def broken_ladder_art() -> str:
    """The same ladder with a snapped section crossed by loose rails."""
    pixels = [list(row) for row in zx.art_lines(ladder_art())]
    for y in range(13, 20):
        for x in range(2, 12):
            pixels[y][x] = "."
    for offset in range(7):
        pixels[13 + offset][3 + offset] = "#"
        pixels[13 + offset][10 - offset] = "#"
    return "\n".join("".join(row) for row in pixels)


def spikes_art() -> str:
    """Four uneven iron spikes with broken dither on their shadow side."""
    width, height = 32, 16
    pixels = [bytearray(width) for _ in range(height)]
    for centre, top in ((4, 3), (12, 1), (20, 4), (28, 2)):
        for y in range(top, 15):
            half = (y - top) // 3
            for x in range(centre - half, centre + half + 1):
                if 0 <= x < width:
                    edge = x in (centre - half, centre + half)
                    if edge or _BAYER_4[y % 4][x % 4] < 11:
                        pixels[y][x] = 1
    for x in range(width):
        if x % 8 not in (6, 7):
            pixels[15][x] = 1
    return "\n".join(
        "".join("#" if value else "." for value in row) for row in pixels
    )


def brick_wall_art() -> str:
    """A five-course wall with offset joints and rough brick faces."""
    width, height = 48, 40
    lines = []
    for y in range(height):
        course = y // 8
        row = []
        for x in range(width):
            horizontal = y % 8 in (0, 1)
            offset = 6 if course % 2 else 0
            vertical = (x + offset) % 12 in (0, 1)
            texture = _BAYER_4[y % 4][x % 4] < 3
            row.append("#" if horizontal or vertical or texture else ".")
        lines.append("".join(row))
    return "\n".join(lines)


def rope_art() -> str:
    """A twisted rope segment that joins seamlessly when stacked."""
    pattern = (
        "..##....",
        ".#..#...",
        "#....#..",
        ".#..#...",
        "..##....",
        "...##...",
        "..#..#..",
        ".#....#.",
    )
    return "\n".join(pattern[y % len(pattern)] for y in range(24))


# The ground comes in two pieces: a long one, five of which fill the whole
# width of the game field, and a short one for the ledges.
GROUND = ground_art(48)
GROUND_SMALL = ground_art(16)

GRASS = """
    ................
    .......#........
    ..#....#.....#..
    ..#....#....#...
    ...#...#....#...
    ...#..##...#....
    #..#..##...#..#.
    .#..#.##..#..#..
    .#..#.##..#..#..
    ..#..###.#..#...
    ..#..###.#.#....
    ...#.####.#.....
    ...######.#.....
    ....#####.......
    .....####.......
    ......##........
"""

GRASS_WIND = """
    ................
    ............#...
    ...........#....
    ......#...#.....
    .....#...#...#..
    .....#..#...#...
    .#...#.#...#....
    ..#..#.#..#.....
    ..#..##...#.....
    ...#.##..#......
    ...####.#.......
    ....###.#.......
    ....####........
    .....###........
    .....###........
    ......##........
"""

GRASS_LOW = """
    ................
    ................
    ................
    .#............#.
    ..#....#.....#..
    ..#....#....#...
    ...#...#...#....
    #..#...#...#..#.
    .#.#..##..#..#..
    .#..#.##.#..#...
    ..#.#.###..#....
    ...#.####.#.....
    ....######......
    ....#####.......
    .....###........
    ......##........
"""

GRASS_SMALL = """
    ........
    ...#....
    #..#..#.
    .#.#.#..
    .#.##...
    ..###...
    ..###...
    ...#....
"""

ROCK_SMALL_MASK = """
    ........
    ...###..
    .######.
    ########
    ########
    .######.
    ..####..
    ........
"""

ROCK_SMALL = shaded_art(
    ROCK_SMALL_MASK,
    (0, 16, 16, 15, 14, 13, 12, 0),
    horizontal_falloff=1,
    solid_base=True,
)

ROCK_FLAT_MASK = """
    ................
    ......#####.....
    ...##########...
    .##############.
    ################
    .##############.
    ..############..
    ................
"""

ROCK_FLAT = shaded_art(
    ROCK_FLAT_MASK,
    (0, 16, 16, 15, 15, 14, 13, 0),
    horizontal_falloff=1,
    solid_base=True,
)

ROCK = """
    ................
    ......##........
    ....#####..##...
    ...#####.#####..
    ..############..
    .#######.######.
    ####.####.#####.
    ######.#########
    ###.####.######.
    .####.###.######
    .##.###.###.###.
    .###.###.#####..
    ..##.###.######.
    ..###..###.###..
    ...###########..
    ................
"""

# A ladder of two poles and the rungs between them - the way up and down on
# every page of the map.
LADDER = ladder_art()
LADDER_BROKEN = broken_ladder_art()

SPIKES = spikes_art()
BRICK_WALL = brick_wall_art()
ROPE = rope_art()

CLOUD_MASK = cloud_mask_art()

CLOUD = shaded_art(
    CLOUD_MASK,
    (16, 16, 16, 16, 16, 16, 15, 15, 14, 14, 13, 13,
     12, 11, 10, 9, 8, 7, 6, 5, 0, 0, 0, 0),
    horizontal_falloff=2,
)

RAIN_DROP = """
    ........
    ...#....
    ..###...
    .#####..
    #######.
    #######.
    .#####..
    ..###...
    ...#....
    ........
    ........
    ........
    ........
    ........
    ........
    ........
"""

FIRE = """
    .......#........
    ......##........
    .....###........
    ...#.####.......
    ...######.......
    ..########......
    .##########.....
    ..########......
    ...######.......
    ..#.####.#......
    ...######.......
    ....####........
    ...######.......
    ..########......
    .##########.....
    ############....
    .##########.....
    ..########......
    ...######.......
    ....####........
    ...######.......
    ..########......
    .##########.....
    ..########......
"""

# The wooden crate the tools of the island are packed in.
CRATE = crate_art()


def dead_tree(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    """A tree the island has killed: a bent trunk and bare branches."""

    def plot(x, y):
        canvas.pixel(x, y, ink, bright)

    Brush(6.0).stroke(plot, [(24.0, 39.0), (22.0, 27.0), (24.0, 17.0)])
    Brush(4.4).stroke(plot, [(23.0, 27.0), (15.0, 21.0), (8.0, 13.0)])
    Brush(4.2).stroke(plot, [(23.5, 22.0), (31.0, 16.0), (40.0, 8.0)])
    Brush(3.4).stroke(plot, [(24.0, 19.0), (21.0, 11.0), (20.0, 3.0)])
    Brush(2.4).stroke(plot, [(11.0, 16.0), (5.0, 14.0), (1.0, 10.0)])
    Brush(2.4).stroke(plot, [(35.0, 12.0), (41.0, 12.0), (46.0, 7.0)])
    Brush(2.4).stroke(plot, [(21.0, 9.0), (28.0, 4.0)])
    Brush(2.4).stroke(plot, [(20.0, 8.0), (13.0, 4.0)])
    Brush(2.6).stroke(plot, [(17.0, 22.0), (12.0, 17.0), (10.0, 10.0)])
    # The roots, gripping the stone.
    Brush(3.2).stroke(plot, [(23.0, 37.0), (35.0, 39.0)])
    Brush(3.2).stroke(plot, [(23.0, 37.0), (12.0, 39.0)])

    # Broken highlights and bark cuts turn the broad trunk from a flat white
    # fork into weathered wood. They stay inside the thick strokes, so no limb
    # loses its silhouette or becomes disconnected.
    for x, y in (
        (25, 37), (22, 34), (24, 31), (21, 28), (24, 25), (21, 22),
        (25, 20), (18, 21), (30, 17), (14, 18), (21, 14), (38, 11),
    ):
        canvas.clear_pixel(x, y)


def living_tree(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    """A wind-shaped living tree with a broad, broken crown."""

    def plot(x, y):
        canvas.pixel(x, y, ink, bright)

    Brush(5.4).stroke(plot, [(24.0, 39.0), (23.0, 28.0), (24.0, 18.0)])
    Brush(3.2).stroke(plot, [(23.0, 24.0), (16.0, 17.0), (11.0, 12.0)])
    Brush(3.2).stroke(plot, [(24.0, 22.0), (31.0, 16.0), (36.0, 12.0)])
    crown = Brush(13.0)
    for x, y in ((10, 13), (18, 8), (27, 8), (36, 13), (17, 16), (29, 16)):
        crown.stamp(plot, x, y)
    Brush(3.0).stroke(plot, [(23.0, 37.0), (14.0, 39.0)])
    Brush(3.0).stroke(plot, [(23.0, 37.0), (34.0, 39.0)])

    # Sparse holes keep the crown leafy instead of turning it into one disc.
    for y in range(24):
        for x in range(canvas.width):
            if canvas.pixels[y][x] and _BAYER_4[y % 4][x % 4] == 15:
                canvas.clear_pixel(x, y)


def shipwreck(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    """The broken boat where the castaway begins the island."""

    def plot(x, y):
        canvas.pixel(x, y, ink, bright)

    hull = Brush(2.8)
    hull.stroke(plot, [(3.0, 25.0), (9.0, 35.0), (47.0, 38.0), (61.0, 29.0)])
    hull.stroke(plot, [(3.0, 25.0), (55.0, 25.0), (61.0, 29.0)])
    Brush(1.8).stroke(plot, [(8.0, 30.0), (54.0, 31.0)])
    Brush(1.8).stroke(plot, [(11.0, 34.0), (48.0, 36.0)])
    # The mast, snapped boom and the torn triangular sail.
    Brush(2.6).stroke(plot, [(20.0, 27.0), (20.0, 5.0)])
    Brush(2.0).stroke(plot, [(20.0, 8.0), (39.0, 21.0)])
    line(plot, 22, 9, 22, 23)
    line(plot, 22, 9, 37, 20)
    line(plot, 22, 23, 37, 20)
    for y in range(12, 22, 3):
        line(plot, 23, y, min(36, 23 + (y - 9)), y + 1)
    # Loose boards at the stern.
    Brush(2.0).stroke(plot, [(48.0, 24.0), (58.0, 18.0)])
    Brush(1.6).stroke(plot, [(51.0, 27.0), (62.0, 25.0)])


def guillotine(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    """A rough timber guillotine with a cold triangular blade."""

    canvas.rectangle(3, 2, 4, 44, ink, bright)
    canvas.rectangle(25, 2, 4, 44, ink, bright)
    canvas.rectangle(2, 2, 28, 5, ink, bright)
    canvas.rectangle(0, 44, 32, 4, ink, bright)
    canvas.rectangle(15, 6, 2, 9, ink, bright)
    # The blade widens towards its cutting edge.
    for y in range(14, 32):
        half = 2 + (y - 14) // 3
        for x in range(16 - half, 17 + half):
            canvas.pixel(x, y, ink, bright)
    for x in range(8, 24):
        if x % 2 == 0:
            canvas.clear_pixel(x, 31)


def worker(canvas: zx.Canvas, ink: int, bright: bool, tool: str) -> None:
    """One of the island's silent workers, holding the named tool."""

    def plot(x, y):
        canvas.pixel(x, y, ink, bright)

    Brush(7.0).stamp(plot, 12.0, 6.0)
    Brush(4.6).stroke(plot, [(12.0, 11.0), (12.0, 27.0)])
    Brush(3.0).stroke(plot, [(11.0, 26.0), (6.0, 39.0)])
    Brush(3.0).stroke(plot, [(13.0, 26.0), (18.0, 39.0)])
    if tool == "saw":
        Brush(2.6).stroke(plot, [(10.0, 15.0), (4.0, 21.0)])
        Brush(2.6).stroke(plot, [(14.0, 15.0), (8.0, 21.0)])
        line(plot, 1, 23, 11, 20)
        for x in range(2, 11, 2):
            plot(x, 24 - x // 4)
    elif tool == "screwdriver":
        Brush(2.6).stroke(plot, [(10.0, 15.0), (5.0, 20.0)])
        Brush(2.6).stroke(plot, [(14.0, 15.0), (19.0, 19.0)])
        line(plot, 18, 19, 23, 19)
        plot(23, 18)
        plot(23, 20)
    else:  # pliers
        Brush(2.6).stroke(plot, [(10.0, 15.0), (5.0, 19.0)])
        Brush(2.6).stroke(plot, [(14.0, 15.0), (19.0, 19.0)])
        line(plot, 4, 20, 1, 17)
        line(plot, 4, 20, 1, 23)
        line(plot, 20, 20, 23, 17)
        line(plot, 20, 20, 23, 23)


def worker_saw(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    worker(canvas, ink, bright, "saw")


def worker_screwdriver(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    worker(canvas, ink, bright, "screwdriver")


def worker_pliers(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    worker(canvas, ink, bright, "pliers")


# Attribute shading works at the Spectrum's real 8x8 colour resolution. It is
# deliberately broad: fine shading belongs to the bitmap dithering above.
GRASS_ATTRIBUTES = (
    ((zx.GREEN, True), (zx.GREEN, True)),
    ((zx.GREEN, False), (zx.GREEN, False)),
)

GRASS_WIND_ATTRIBUTES = (
    ((zx.GREEN, False), (zx.GREEN, True)),
    ((zx.GREEN, False), (zx.GREEN, False)),
)

GRASS_LOW_ATTRIBUTES = (
    ((zx.GREEN, True), (zx.GREEN, False)),
    ((zx.GREEN, False), (zx.GREEN, False)),
)

GRASS_SMALL_ATTRIBUTES = (
    ((zx.GREEN, True),),
)

ROCK_ATTRIBUTES = (
    ((zx.WHITE, True), (zx.WHITE, False)),
    ((zx.WHITE, False), (zx.WHITE, False)),
)

ROCK_FLAT_ATTRIBUTES = (
    ((zx.WHITE, True), (zx.WHITE, False)),
)

ROCK_SMALL_ATTRIBUTES = (
    ((zx.WHITE, False),),
)

LADDER_ATTRIBUTES = (
    ((zx.YELLOW, True), (zx.YELLOW, False)),
    ((zx.YELLOW, True), (zx.YELLOW, False)),
    ((zx.YELLOW, False), (zx.YELLOW, False)),
)

SPIKES_ATTRIBUTES = (
    ((zx.WHITE, True),) * 4,
    ((zx.WHITE, False),) * 4,
)

BRICK_WALL_ATTRIBUTES = (
    ((zx.RED, True),) * 6,
    ((zx.RED, False),) * 6,
    ((zx.RED, False),) * 6,
    ((zx.RED, False),) * 6,
    ((zx.RED, False),) * 6,
)

ROPE_ATTRIBUTES = (
    ((zx.YELLOW, True),),
    ((zx.YELLOW, False),),
    ((zx.YELLOW, False),),
)

CLOUD_ATTRIBUTES = (
    ((zx.WHITE, True),) * 5,
    ((zx.WHITE, True), (zx.WHITE, False), (zx.WHITE, False),
     (zx.CYAN, True), (zx.CYAN, False)),
    ((zx.CYAN, True),) + ((zx.CYAN, False),) * 4,
)

RAIN_DROP_ATTRIBUTES = (
    ((zx.CYAN, True),),
    ((zx.CYAN, False),),
)

FIRE_ATTRIBUTES = (
    ((zx.YELLOW, True), (zx.YELLOW, True)),
    ((zx.YELLOW, True), (zx.RED, True)),
    ((zx.RED, True), (zx.RED, True)),
)

CRATE_ATTRIBUTES = (
    ((zx.YELLOW, True), (zx.YELLOW, False)),
    ((zx.YELLOW, False), (zx.RED, False)),
)

TREE_ATTRIBUTES = (
    ((zx.YELLOW, True),) * 6,
    ((zx.YELLOW, True),) * 3 + ((zx.YELLOW, False),) * 3,
    ((zx.YELLOW, False),) * 6,
    ((zx.YELLOW, False),) * 6,
    ((zx.YELLOW, False),) * 6,
)

LIVING_TREE_ATTRIBUTES = (
    ((zx.GREEN, True),) * 6,
    ((zx.GREEN, True),) * 6,
    ((zx.GREEN, False),) * 6,
    ((zx.GREEN, False), (zx.GREEN, False), (zx.YELLOW, False),
     (zx.YELLOW, False), (zx.GREEN, False), (zx.GREEN, False)),
    ((zx.YELLOW, False),) * 6,
)

SHIPWRECK_ATTRIBUTES = (
    ((zx.WHITE, False),) * 8,
    ((zx.YELLOW, False),) * 8,
    ((zx.YELLOW, False),) * 8,
    ((zx.RED, False),) * 8,
    ((zx.RED, False),) * 8,
)

GUILLOTINE_ATTRIBUTES = (
    ((zx.RED, False),) * 4,
    ((zx.RED, False), (zx.WHITE, True), (zx.WHITE, True), (zx.RED, False)),
    ((zx.RED, False), (zx.WHITE, False), (zx.WHITE, False), (zx.RED, False)),
    ((zx.RED, False), (zx.WHITE, False), (zx.WHITE, False), (zx.RED, False)),
    ((zx.RED, False),) * 4,
    ((zx.RED, False),) * 4,
)

WORKER_ATTRIBUTES = (
    ((zx.WHITE, False),) * 3,
    ((zx.YELLOW, True),) * 3,
    ((zx.YELLOW, False),) * 3,
    ((zx.YELLOW, False),) * 3,
    ((zx.YELLOW, False),) * 3,
)


SPRITES = [
    {
        "label": "SpriteGround",
        "name": "GROUND",
        "note": "The ground of the island; five of these fill the game field.",
        "art": GROUND,
        "ink": zx.RED,
        "bright": False,
    },
    {
        "label": "SpriteGroundSmall",
        "name": "GROUND_SMALL",
        "note": "A short piece of the ground, for the ledges.",
        "art": GROUND_SMALL,
        "ink": zx.RED,
        "bright": False,
    },
    {
        "label": "SpriteGrass",
        "name": "GRASS",
        "note": "A tall tuft of the hard grass that grows on the rock.",
        "art": GRASS,
        "ink": zx.GREEN,
        "bright": True,
        "attributes": GRASS_ATTRIBUTES,
    },
    {
        "label": "SpriteGrassWind",
        "name": "GRASS_WIND",
        "note": "A tuft of grass bent by the wind from the sea.",
        "art": GRASS_WIND,
        "ink": zx.GREEN,
        "bright": True,
        "attributes": GRASS_WIND_ATTRIBUTES,
    },
    {
        "label": "SpriteGrassLow",
        "name": "GRASS_LOW",
        "note": "A low wide tuft of grass growing close to the stone.",
        "art": GRASS_LOW,
        "ink": zx.GREEN,
        "bright": True,
        "attributes": GRASS_LOW_ATTRIBUTES,
    },
    {
        "label": "SpriteGrassSmall",
        "name": "GRASS_SMALL",
        "note": "A young tuft of grass, one character square.",
        "art": GRASS_SMALL,
        "ink": zx.GREEN,
        "bright": True,
        "attributes": GRASS_SMALL_ATTRIBUTES,
    },
    {
        "label": "SpriteRockSmall",
        "name": "ROCK_SMALL",
        "note": "A small loose stone, one character square.",
        "art": ROCK_SMALL,
        "ink": zx.WHITE,
        "bright": False,
        "attributes": ROCK_SMALL_ATTRIBUTES,
    },
    {
        "label": "SpriteRockFlat",
        "name": "ROCK_FLAT",
        "note": "A flat weathered stone, two characters wide.",
        "art": ROCK_FLAT,
        "ink": zx.WHITE,
        "bright": False,
        "attributes": ROCK_FLAT_ATTRIBUTES,
    },
    {
        "label": "SpriteRock",
        "name": "ROCK",
        "note": "An irregular boulder, two characters square.",
        "art": ROCK,
        "ink": zx.WHITE,
        "bright": False,
        "attributes": ROCK_ATTRIBUTES,
    },
    {
        "label": "SpriteLadder",
        "name": "LADDER",
        "note": "The ladder between the levels of the island.",
        "art": LADDER,
        "ink": zx.YELLOW,
        "bright": True,
        "attributes": LADDER_ATTRIBUTES,
    },
    {
        "label": "SpriteLadderBroken",
        "name": "LADDER_BROKEN",
        "note": "A ladder with a snapped and crossed middle section.",
        "art": LADDER_BROKEN,
        "ink": zx.YELLOW,
        "bright": True,
        "attributes": LADDER_ATTRIBUTES,
    },
    {
        "label": "SpriteSpikes",
        "name": "SPIKES",
        "note": "A row of four rusted spikes.",
        "art": SPIKES,
        "ink": zx.WHITE,
        "bright": True,
        "attributes": SPIKES_ATTRIBUTES,
    },
    {
        "label": "SpriteBrickWall",
        "name": "BRICK_WALL",
        "note": "A rough five-course brick barrier.",
        "art": BRICK_WALL,
        "ink": zx.RED,
        "bright": False,
        "attributes": BRICK_WALL_ATTRIBUTES,
    },
    {
        "label": "SpriteRope",
        "name": "ROPE",
        "note": "A twisted hanging rope segment.",
        "art": ROPE,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": ROPE_ATTRIBUTES,
    },
    {
        "label": "SpriteCloud",
        "name": "CLOUD",
        "note": "A low cloud - on this island it always carries rain.",
        "art": CLOUD,
        "ink": zx.WHITE,
        "bright": True,
        "attributes": CLOUD_ATTRIBUTES,
    },
    {
        "label": "SpriteRainDrop",
        "name": "RAIN_DROP",
        "note": "One heavy drop falling below a rain cloud.",
        "art": RAIN_DROP,
        "ink": zx.CYAN,
        "bright": True,
        "attributes": RAIN_DROP_ATTRIBUTES,
    },
    {
        "label": "SpriteFire",
        "name": "FIRE",
        "note": "The hanging fire in the middle levels of the island.",
        "art": FIRE,
        "ink": zx.YELLOW,
        "bright": True,
        "attributes": FIRE_ATTRIBUTES,
    },
    {
        "label": "SpriteCrate",
        "name": "CRATE",
        "note": "A wooden crate, the kind the tools are packed in.",
        "art": CRATE,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": CRATE_ATTRIBUTES,
    },
    {
        "label": "SpriteDeadTree",
        "name": "DEAD_TREE",
        "note": "A dead tree, six characters wide and five high.",
        "size": (48, 40),
        "draw": dead_tree,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": TREE_ATTRIBUTES,
    },
    {
        "label": "SpriteLivingTree",
        "name": "LIVING_TREE",
        "note": "A living tree with a broad wind-shaped crown.",
        "size": (48, 40),
        "draw": living_tree,
        "ink": zx.GREEN,
        "bright": True,
        "attributes": LIVING_TREE_ATTRIBUTES,
    },
    {
        "label": "SpriteShipwreck",
        "name": "SHIPWRECK",
        "note": "The broken boat where the castaway reaches the island.",
        "size": (64, 40),
        "draw": shipwreck,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": SHIPWRECK_ATTRIBUTES,
    },
    {
        "label": "SpriteGuillotine",
        "name": "GUILLOTINE",
        "note": "A timber guillotine with a cold blade.",
        "size": (32, 48),
        "draw": guillotine,
        "ink": zx.RED,
        "bright": False,
        "attributes": GUILLOTINE_ATTRIBUTES,
    },
    {
        "label": "SpriteWorkerSaw",
        "name": "WORKER_SAW",
        "note": "The islander carrying a saw.",
        "size": (24, 40),
        "draw": worker_saw,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": WORKER_ATTRIBUTES,
    },
    {
        "label": "SpriteWorkerScrewdriver",
        "name": "WORKER_SCREWDRIVER",
        "note": "The islander carrying a screwdriver.",
        "size": (24, 40),
        "draw": worker_screwdriver,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": WORKER_ATTRIBUTES,
    },
    {
        "label": "SpriteWorkerPliers",
        "name": "WORKER_PLIERS",
        "note": "The islander carrying a pair of pliers.",
        "size": (24, 40),
        "draw": worker_pliers,
        "ink": zx.YELLOW,
        "bright": False,
        "attributes": WORKER_ATTRIBUTES,
    },
]


HEADER = """;###############################################################################
;##### The sprites the rooms of Dark Island 1 are built from. Every sprite is ###
;##### the width in characters and the height in pixel lines, then the bitmap ###
;##### by pixel lines, and after it one attribute for every character. ##########
;##### #########################################################################
;##### GENERATED by tools/generate_sprites.py - do not edit it here. ############
;###############################################################################"""


def build(entry) -> zx.Canvas:
    if "art" in entry:
        width, height = zx.art_size(entry["art"])
        canvas = zx.Canvas(width, (height + 7) // 8 * 8)
        canvas.blit(entry["art"], 0, 0, ink=entry["ink"], bright=entry["bright"])
    else:
        width, height = entry["size"]
        canvas = zx.Canvas(width, height)
        entry["draw"](canvas, entry["ink"], entry["bright"])
    # A sprite is drawn as a whole, so the cells it never touches still need a
    # colour; they take the colour of the sprite.
    for index in range(len(canvas.inks)):
        if canvas.inks[index] is None:
            canvas.inks[index] = (entry["ink"], entry["bright"])
    if "attributes" in entry:
        rows = entry["attributes"]
        if len(rows) != canvas.rows or any(len(row) != canvas.cols for row in rows):
            raise ValueError(
                "{} attributes do not match its {}x{} cells".format(
                    entry["name"], canvas.cols, canvas.rows
                )
            )
        canvas.inks = [colour for row in rows for colour in row]
    return canvas


def source(built) -> str:
    out = [HEADER, ""]
    for entry, canvas in built:
        bitmap, attributes = canvas.sprite_data()
        out.append(";" + "-" * 79)
        out.append("; " + entry["note"])
        out.append(entry["label"] + ":")
        out.append("        defb    {}, {}".format(canvas.cols, canvas.height))
        out.append("")
        out.append(entry["label"].replace("Sprite", "SpriteData") + ":")
        out.append(zx.defb_block(bitmap, per_line=canvas.cols))
        out.append("")
        out.append(entry["label"].replace("Sprite", "SpriteAttributes") + ":")
        out.append(zx.defb_block(attributes, per_line=canvas.cols))
        out.append("")
    out.append(";" + "-" * 79)
    out.append("; The names the rooms call the sprites by.")
    for entry, _ in built:
        out.append("SPRITE_{:<24} equ {}".format(entry["name"], entry["label"]))
    out.append("")
    return "\n".join(out)


def preview(built) -> Image.Image:
    gap = 8
    width = sum(canvas.width + gap for _, canvas in built) + gap
    height = max(canvas.height for _, canvas in built) + 2 * gap
    width = (width + 7) // 8 * 8
    height = (height + 7) // 8 * 8
    sheet = zx.Canvas(width, height, strict=False)
    x = gap
    for _, canvas in built:
        for y in range(canvas.height):
            for column in range(canvas.width):
                if canvas.pixels[y][column]:
                    colour = canvas.inks[(y // 8) * canvas.cols + column // 8]
                    sheet.pixel(x + column, gap + y, colour[0], colour[1])
        x += canvas.width + gap
    return sheet.preview(scale=4)


def main() -> None:
    built = [(entry, build(entry)) for entry in SPRITES]
    zx.write_source(SOURCE_PATH, source(built))
    zx.write_preview(PREVIEW_PATH, preview(built))


if __name__ == "__main__":
    main()
