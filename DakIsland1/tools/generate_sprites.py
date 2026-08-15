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
from pen import Brush

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "src" / "sprites_land.asm"
PREVIEW_PATH = ROOT / "gfx" / "sprites.png"


# ---------------------------------------------------------------------------
# The artwork.

def ground_art(width: int) -> str:
    """A block of the ground: solid, with the stone showing through it.

    The holes follow a pattern that does not repeat every character, so a row
    of these blocks reads as one broken surface and not as a row of tiles.
    """
    holes = {2: (0, 3, 5), 4: (1, 4, 6), 6: (2, 3, 7), 7: (5,)}
    lines = []
    for y in range(8):
        row = []
        for x in range(width):
            hole = y in holes and (x % 8) in holes[y] and (x // 8 + y) % 3 != 0
            row.append("." if hole else "#")
        lines.append("".join(row))
    return "\n".join(lines)


# The ground comes in two pieces: a long one, five of which fill the whole
# width of the game field, and a short one for the ledges.
GROUND = ground_art(48)
GROUND_SMALL = ground_art(16)

GRASS = """
    ........
    ...#....
    #..#..#.
    #..#.##.
    #.###.#.
    ##.##.##
    .####.##
    ...##...
"""

ROCK = """
    ................
    .....######.....
    ...##########...
    ..###.########..
    .###############
    .####.#####.####
    ################
    ###.#########.##
    ################
    .####.#####.####
    ..############..
    ...##########...
    ................
    ................
    ................
    ................
"""

# A ladder of two poles and the rungs between them - the way up and down on
# every page of the map.
LADDER = """
    ##..........##..
    ##..........##..
    ################
    ################
    ##..........##..
    ##..........##..
    ##..........##..
    ##..........##..
    ################
    ################
    ##..........##..
    ##..........##..
    ##..........##..
    ##..........##..
    ################
    ################
    ##..........##..
    ##..........##..
    ##..........##..
    ##..........##..
    ################
    ################
    ##..........##..
    ##..........##..
"""

CLOUD = """
    ......########..........
    ....############........
    ..################......
    .###################....
    .#####################..
    ########################
    .######################.
    ...##################...
    ........................
    ........................
    ........................
    ........................
    ........................
    ........................
    ........................
    ........................
"""

# The wooden crate the tools of the island are packed in.
CRATE = """
    ################
    #..............#
    #.##........##.#
    #...##....##...#
    #.....####.....#
    #.....####.....#
    #...##....##...#
    #.##........##.#
    #..............#
    #..............#
    #.##........##.#
    #...##....##...#
    #.....####.....#
    #.....####.....#
    #...##....##...#
    ################
"""


def dead_tree(canvas: zx.Canvas, ink: int, bright: bool) -> None:
    """A tree the island has killed: a bent trunk and bare branches."""

    def plot(x, y):
        canvas.pixel(x, y, ink, bright)

    Brush(4.2).stroke(plot, [(15.0, 23.0), (14.0, 16.0), (15.5, 10.0)])
    Brush(3.0).stroke(plot, [(14.5, 15.0), (9.0, 11.0), (5.0, 7.0)])
    Brush(3.0).stroke(plot, [(15.0, 12.5), (20.0, 9.0), (25.0, 5.0)])
    Brush(2.4).stroke(plot, [(15.5, 11.0), (13.0, 6.0), (12.0, 2.0)])
    Brush(1.6).stroke(plot, [(7.0, 9.0), (3.0, 8.0), (1.0, 5.0)])
    Brush(1.6).stroke(plot, [(22.0, 7.0), (26.0, 7.0), (29.0, 4.0)])
    Brush(1.6).stroke(plot, [(13.0, 5.0), (17.0, 2.0)])
    Brush(1.6).stroke(plot, [(12.5, 4.0), (8.0, 2.0)])
    # The roots, gripping the stone.
    Brush(2.2).stroke(plot, [(15.0, 22.0), (20.0, 23.0)])
    Brush(2.2).stroke(plot, [(15.0, 22.0), (10.0, 23.0)])


SPRITES = [
    {
        "label": "SpriteGround",
        "name": "GROUND",
        "note": "The ground of the island; five of these fill the game field.",
        "art": GROUND,
        "ink": zx.WHITE,
        "bright": False,
    },
    {
        "label": "SpriteGroundSmall",
        "name": "GROUND_SMALL",
        "note": "A short piece of the ground, for the ledges.",
        "art": GROUND_SMALL,
        "ink": zx.WHITE,
        "bright": False,
    },
    {
        "label": "SpriteGrass",
        "name": "GRASS",
        "note": "A tuft of the hard grass that grows on the rock.",
        "art": GRASS,
        "ink": zx.GREEN,
        "bright": True,
    },
    {
        "label": "SpriteRock",
        "name": "ROCK",
        "note": "A boulder, two characters wide.",
        "art": ROCK,
        "ink": zx.WHITE,
        "bright": False,
    },
    {
        "label": "SpriteLadder",
        "name": "LADDER",
        "note": "The ladder between the levels of the island.",
        "art": LADDER,
        "ink": zx.YELLOW,
        "bright": True,
    },
    {
        "label": "SpriteCloud",
        "name": "CLOUD",
        "note": "A low cloud - on this island it always carries rain.",
        "art": CLOUD,
        "ink": zx.WHITE,
        "bright": True,
    },
    {
        "label": "SpriteCrate",
        "name": "CRATE",
        "note": "A wooden crate, the kind the tools are packed in.",
        "art": CRATE,
        "ink": zx.YELLOW,
        "bright": False,
    },
    {
        "label": "SpriteDeadTree",
        "name": "DEAD_TREE",
        "note": "A dead tree, four characters wide and three high.",
        "size": (32, 24),
        "draw": dead_tree,
        "ink": zx.WHITE,
        "bright": False,
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
