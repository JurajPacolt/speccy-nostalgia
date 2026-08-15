"""Generate the picture of the game's panel of Dark Island 1.

    py -3 tools/generate_panel.py

The panel is the top five character rows of the screen. This script draws all
of its still parts - the blackletter logo, the small picture of the island and
the two labels - into one canvas, cuts the canvas into characters and writes
them as `src/game_panel_picture.asm`. The places of the skulls, of the energy
and of the room's description stay empty there; the game draws them itself.

The graphics the game draws into those places are generated here as well, so
every pixel of the panel comes out of this one file. `gfx/panel.png` shows how
it will look.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image

import zx
from font_art import FONT_4X8, FONT_8X8
from logo_alphabet import alphabet
from pen import Brush

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "src" / "game_panel_picture.asm"
PREVIEW_PATH = ROOT / "gfx" / "panel.png"

# -- the shape of the panel --------------------------------------------------

PANEL_COLS = 32
PANEL_ROWS = 5

LOGO = "DARK ISLAND 1"
LOGO_X = 8
LOGO_Y = 0
LOGO_GAP = 1
LOGO_SPACE = 5

VIGNETTE_COL = 24
VIGNETTE_X = VIGNETTE_COL * 8
VIGNETTE_W = 64
VIGNETTE_H = 32

STAT_ROW = 3
LIVES_LABEL_COL = 0
SKULL_COL = 4
SKULL_MAX = 5
ENERGY_LABEL_COL = 10
ENERGY_COL = 14
ENERGY_CELLS = 10
TEXT_ROW = 4

# -- the colours of the panel ------------------------------------------------

LOGO_LIGHT = (zx.YELLOW, True)   # the two upper rows of the letters
LOGO_SHADOW = (zx.YELLOW, False)  # the last row, so the gold has a shadow
MOON = (zx.YELLOW, True)
ISLAND = (zx.WHITE, True)
SEA = (zx.CYAN, True)
LABEL = (zx.WHITE, False)
ROOM_TEXT = (zx.CYAN, True)


# ---------------------------------------------------------------------------
# The small picture of the island.

def disc(canvas, cx, cy, radius, ink, bright, hole=None):
    """A filled circle, with a second circle cut out of it - a moon."""
    for y in range(int(cy - radius) - 1, int(cy + radius) + 2):
        for x in range(int(cx - radius) - 1, int(cx + radius) + 2):
            if (x - cx) ** 2 + (y - cy) ** 2 > radius * radius:
                continue
            if hole is not None:
                hx, hy, hr = hole
                if (x - hx) ** 2 + (y - hy) ** 2 <= hr * hr:
                    continue
            canvas.pixel(x, y, ink, bright)


def mound(canvas, edge, bottom, x0, y0, ink, bright):
    """A hill: the line over it is given, everything under it is stone."""
    for index in range(len(edge) - 1):
        (ax, ay), (bx, by) = edge[index], edge[index + 1]
        for x in range(int(ax), int(bx) + 1):
            part = 0.0 if bx == ax else (x - ax) / float(bx - ax)
            top = ay + (by - ay) * part
            for y in range(int(round(top)), bottom + 1):
                canvas.pixel(x0 + x, y0 + y, ink, bright)


def vignette(canvas, x0, y0):
    """The moon over the island, the dead tree on it and the sea under it."""
    ink, bright = MOON
    disc(canvas, x0 + 7.5, y0 + 6.0, 6.2, ink, bright, hole=(x0 + 10.8, y0 + 5.2, 6.0))

    ink, bright = ISLAND
    # The island itself: a rock standing out of the water, and it is a rock, so
    # its back is broken and not round.
    mound(
        canvas,
        [(12, 24), (15, 22), (17, 23), (20, 20), (23, 21), (26, 18), (29, 19),
         (32, 17), (35, 18), (38, 16), (42, 16), (45, 17), (48, 18), (51, 17),
         (54, 19), (57, 20), (60, 22), (64, 24)],
        23,
        x0,
        y0,
        ink,
        bright,
    )
    # The cracks between the layers of the stone.
    for start, end, y in [(18, 21, 22), (26, 30, 21), (33, 37, 20), (46, 50, 20),
                          (54, 57, 21), (23, 27, 23), (40, 44, 22), (50, 54, 22),
                          (15, 18, 23), (35, 38, 23)]:
        for x in range(start, end + 1):
            canvas.clear_pixel(x0 + x, y0 + y)

    def plot(x, y):
        canvas.pixel(x0 + x, y0 + y, ink, bright)

    # The dead tree: a trunk, three bare branches and a few twigs on them.
    Brush(3.4).stroke(plot, [(42.0, 20.0), (41.0, 14.0), (42.0, 9.5)])
    Brush(2.6).stroke(plot, [(41.5, 13.5), (36.0, 9.0), (32.0, 5.0)])
    Brush(2.6).stroke(plot, [(42.0, 11.5), (47.0, 8.0), (51.0, 4.0)])
    Brush(2.2).stroke(plot, [(42.0, 10.0), (39.0, 5.5), (38.0, 2.0)])
    Brush(1.4).stroke(plot, [(34.0, 7.5), (30.0, 7.0), (28.0, 4.5)])
    Brush(1.4).stroke(plot, [(48.5, 6.5), (52.0, 7.0), (55.0, 4.5)])
    Brush(1.4).stroke(plot, [(39.5, 6.0), (43.0, 3.0)])
    # The roots, holding the tree on the rock.
    Brush(1.8).stroke(plot, [(42.0, 19.0), (46.0, 21.0)])
    Brush(1.8).stroke(plot, [(42.0, 19.0), (37.0, 21.0)])

    # The sea, in the last row of the picture: four rows of short swells, each
    # one a piece of a wave and every row moved against the one over it.
    ink, bright = SEA
    waves = [
        (25.4, 0.0, [(0, 9), (14, 25), (30, 41), (46, 57), (60, 63)]),
        (27.4, 3.5, [(4, 15), (20, 31), (36, 47), (52, 63)]),
        (29.4, 1.5, [(0, 5), (9, 20), (25, 36), (41, 52), (57, 63)]),
        (31.2, 5.0, [(2, 13), (18, 29), (34, 45), (50, 61)]),
    ]
    for base, phase, runs in waves:
        for start, end in runs:
            for x in range(start, end + 1):
                y = base - 0.95 * math.sin((x + phase) * 0.55)
                canvas.pixel(x0 + x, y0 + int(round(y)), ink, bright)


# ---------------------------------------------------------------------------
# The whole panel.

def build() -> zx.Canvas:
    canvas = zx.Canvas(PANEL_COLS * 8, PANEL_ROWS * 8)

    # The blackletter logo. Its two upper rows are gold and the last one is
    # darker, so the letters look cut into the panel.
    glyphs = alphabet()
    cursor = LOGO_X
    for char in LOGO:
        if char == " ":
            cursor += LOGO_SPACE + LOGO_GAP
            continue
        art = zx.trim_columns(zx.art_lines(glyphs[char]))
        width, _ = canvas.blit("\n".join(art), cursor, LOGO_Y, ink=LOGO_LIGHT[0],
                               bright=LOGO_LIGHT[1])
        cursor += width + LOGO_GAP
    logo_width = cursor - LOGO_GAP - LOGO_X
    for col in range(VIGNETTE_COL):
        if canvas.cell_ink(col, 2) is not None:
            canvas.inks[2 * PANEL_COLS + col] = LOGO_SHADOW

    vignette(canvas, VIGNETTE_X, 0)

    # The two labels of the panel, in the small font.
    canvas.text(FONT_4X8, "LIVES", LIVES_LABEL_COL * 8 + 2, STAT_ROW * 8,
                ink=LABEL[0], bright=LABEL[1], advance=4)
    canvas.text(FONT_4X8, "ENERGY", ENERGY_LABEL_COL * 8, STAT_ROW * 8,
                ink=LABEL[0], bright=LABEL[1], advance=4)

    # The last row stays empty - the game writes the name of the room into it -
    # but it needs its colour now, because the game only writes pixels there.
    for col in range(PANEL_COLS):
        canvas.set_cell_ink(col, TEXT_ROW, ROOM_TEXT[0], ROOM_TEXT[1])

    return canvas, logo_width


# ---------------------------------------------------------------------------
# The graphics the game draws into the panel itself.

SKULL_REST = """
    ..###..
    .#####.
    #..#..#
    #..#..#
    ##.#.##
    .#####.
    .#.#.#.
    .......
"""

SKULL_GLINT = """
    ..###..
    .#####.
    #..#..#
    ##.#.##
    ##.#.##
    .#####.
    .#.#.#.
    .......
"""

SKULL_CHATTER = """
    ..###..
    .#####.
    #..#..#
    #..#..#
    ##.#.##
    .#####.
    .#####.
    ..###..
"""

ENERGY_FULL = """
    ........
    ...##...
    ..####..
    .######.
    ..####..
    ...##...
    ........
    ........
"""

ENERGY_EMPTY = """
    ........
    ...##...
    ..#..#..
    .#....#.
    ..#..#..
    ...##...
    ........
    ........
"""

ICONS = [
    ("SpriteDataSkull", SKULL_REST, "The skull of one life, at rest."),
    ("SpriteDataSkullGlint", SKULL_GLINT, "A spark of light in its eyes."),
    ("SpriteDataSkullChatter", SKULL_CHATTER, "Its jaw drops for a moment."),
    ("GfxEnergyFull", ENERGY_FULL, "One point of the energy the player has."),
    ("GfxEnergyEmpty", ENERGY_EMPTY, "One point the player has already spent."),
]


# ---------------------------------------------------------------------------
# The assembly file.

HEADER = """;###############################################################################
;##### The picture of the game's panel: the blackletter logo of the game, the ###
;##### island under the moon and the two labels. The panel is 32x5 characters ###
;##### and every character of it is one tile; tile 0 is the empty one and is #####
;##### not stored. The places of the skulls, of the energy and of the room's ####
;##### description are empty here, the game draws them by itself. ##############
;##### #########################################################################
;##### GENERATED by tools/generate_panel.py - do not edit it here. #############
;###############################################################################"""


def source(canvas: zx.Canvas) -> str:
    tiles, tile_map, attributes = canvas.tiles()
    out = [HEADER, "", "PanelTiles:"]
    for number, data in enumerate(tiles, start=1):
        out.append("        ; Tile {}".format(number))
        out.append(zx.defb_binary(data))
    out.append("")
    out.append("; Number of the tile for every character of the panel.")
    out.append("PanelMap:")
    for row in range(canvas.rows):
        out.append(zx.defb_block(tile_map[row * PANEL_COLS:(row + 1) * PANEL_COLS],
                                 per_line=PANEL_COLS))
    out.append("")
    out.append("; Color of every character of the panel.")
    out.append("PanelAttributes:")
    for row in range(canvas.rows):
        out.append(zx.defb_block(attributes[row * PANEL_COLS:(row + 1) * PANEL_COLS],
                                 per_line=PANEL_COLS))
    out.append("")
    out.append(";" + "-" * 79)
    out.append("; The graphics the game draws into the panel: the skulls of the lives in")
    out.append("; the three moments of their gnashing, and one cell of the energy bar.")
    for label, art, note in ICONS:
        out.append("")
        out.append("; " + note)
        out.append(label + ":")
        out.append(zx.defb_binary(zx.glyph_bytes(art)))
    out.append("")
    return "\n".join(out)


def preview(canvas: zx.Canvas) -> Image.Image:
    """The panel as it will be on the screen, with the parts the game draws."""
    shown = zx.Canvas(canvas.width, canvas.height, strict=False)
    shown.pixels = [bytearray(row) for row in canvas.pixels]
    shown.inks = list(canvas.inks)

    for index in range(3):
        shown.blit(SKULL_REST, (SKULL_COL + index) * 8, STAT_ROW * 8,
                   ink=zx.WHITE, bright=True)
    for index in range(ENERGY_CELLS):
        full = index < 7
        shown.blit(ENERGY_FULL if full else ENERGY_EMPTY,
                   (ENERGY_COL + index) * 8, STAT_ROW * 8,
                   ink=zx.GREEN if full else zx.BLUE, bright=full)
    name = "WHERE THE SEA LEFT YOU"
    shown.text(FONT_8X8, name, (PANEL_COLS - len(name)) // 2 * 8, TEXT_ROW * 8,
               ink=ROOM_TEXT[0], bright=ROOM_TEXT[1], advance=8)
    return shown.preview(scale=3)


def main() -> None:
    canvas, logo_width = build()
    print("the logo is {} pixels wide".format(logo_width))
    zx.write_source(SOURCE_PATH, source(canvas))
    zx.write_preview(PREVIEW_PATH, preview(canvas))


if __name__ == "__main__":
    main()
