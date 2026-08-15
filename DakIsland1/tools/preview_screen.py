"""Draw the screen of Dark Island 1 without starting an emulator.

    py -3 tools/preview_screen.py

The game builds its screen out of three things: the picture of the panel, the
rope border and the list of sprites of the room. All three are here as well -
the panel and the sprites come from the other generators, the border and the
rooms are read straight out of `src/game_field.asm` and `src/rooms.asm` - so
this draws what the Spectrum would draw, and a wrong coordinate shows up in
`gfx/screen.png` instead of on the television.

It is a check as much as a picture: every sprite is measured against the walls
of the game field and anything hanging out of it is reported.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image

import generate_panel as gp
import zx
from font_art import FONT_8X8
from generate_panel import build as build_panel
from generate_sprites import SPRITES, build as build_sprite

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
SCREEN_PATH = ROOT / "gfx" / "screen.png"
ROOMS_PATH = ROOT / "gfx" / "rooms.png"

SCREEN_COLS = 32
SCREEN_ROWS = 24

# The same numbers as src/screen.asm.
PANEL_ROWS = 5
BORDER_ROW = PANEL_ROWS
FIELD_FIRST_ROW = BORDER_ROW + 1
FIELD_FIRST_COL = 1
FIELD_WIDTH = 30
FIELD_HEIGHT = 17
BORDER_COLOR = 6
FIELD_COLOR = 71


def read(name: str) -> str:
    with open(str(SRC / name), "r", encoding="ascii", errors="replace") as handle:
        return handle.read()


def border_tiles():
    """The two characters the rope is drawn with, out of the source."""
    text = read("game_field.asm")
    tiles = {}
    for label in ("GfxGameBorderCorner", "GfxGameBorderItem"):
        match = re.search(label + r":\s*((?:\s*defb\s+%[01]{8}\n){8})", text)
        if not match:
            raise ValueError("no data found for " + label)
        tiles[label] = [
            int(value, 2) for value in re.findall(r"%([01]{8})", match.group(1))
        ]
    return tiles["GfxGameBorderCorner"], tiles["GfxGameBorderItem"]


def rooms_map():
    text = read("rooms.asm")
    match = re.search(r"RoomsMap:\s*((?:\s*defb[^\n]*\n)+)", text)
    rows = []
    for line in match.group(1).strip().split("\n"):
        rows.append([int(value) for value in re.findall(r"\d+", line.split("defb")[1])])
    return rows


def room_lists():
    """Every room as a list of (x, y, colour, sprite name)."""
    text = read("rooms.asm")
    rooms = {}
    for match in re.finditer(r"^Room(\d+):\s*$", text, re.MULTILINE):
        number = int(match.group(1))
        body = text[match.end():]
        end = re.search(r"^Room\d+:", body, re.MULTILINE)
        if end:
            body = body[: end.start()]
        records = []
        for record in re.finditer(
            r"defb\s+(\d+),\s*(\d+),\s*(\d+)\s*\n\s*defw\s+(SPRITE_\w+)", body
        ):
            records.append(
                (
                    int(record.group(1)),
                    int(record.group(2)),
                    int(record.group(3)),
                    record.group(4),
                )
            )
        rooms[number] = records
    return rooms


def room_names():
    text = read("game_info_panel.asm")
    names = {}
    for match in re.finditer(r'_GP_Room(\d+):\s*\n\s*defb\s+"([^"]*)"', text):
        names[int(match.group(1))] = match.group(2)
    return names


def sprite_canvases():
    return dict(
        ("SPRITE_" + entry["name"], build_sprite(entry)) for entry in SPRITES
    )


class Screen:
    """A whole Spectrum screen: the pixels and one attribute per character."""

    def __init__(self):
        self.pixels = [bytearray(256) for _ in range(192)]
        self.attrs = [0] * (SCREEN_COLS * SCREEN_ROWS)

    def char(self, col, row, data, attr):
        for line in range(8):
            value = data[line]
            for bit in range(8):
                if value & (0x80 >> bit):
                    self.pixels[row * 8 + line][col * 8 + bit] = 1
        self.attrs[row * SCREEN_COLS + col] = attr

    def image(self, scale=3):
        image = Image.new("RGB", (256, 192), (0, 0, 0))
        put = image.load()
        for y in range(192):
            for x in range(256):
                if not self.pixels[y][x]:
                    continue
                attr = self.attrs[(y // 8) * SCREEN_COLS + x // 8]
                put[x, y] = zx.rgb(attr & 7, bool(attr & 64))
        return image.resize((256 * scale, 192 * scale), Image.NEAREST)


def draw_panel(screen, panel, lives=3, energy=7, name=""):
    """The still picture of the panel, and over it what the game draws itself."""
    for row in range(panel.rows):
        for col in range(panel.cols):
            colour = panel.cell_ink(col, row)
            attr = 0 if colour is None else zx.attribute(colour[0], colour[1])
            screen.char(col, row, panel.char_bytes(col, row), attr)

    skull = zx.glyph_bytes(gp.SKULL_REST)
    for index in range(lives):
        screen.char(gp.SKULL_COL + index, gp.STAT_ROW, skull, 71)

    full = zx.glyph_bytes(gp.ENERGY_FULL)
    empty = zx.glyph_bytes(gp.ENERGY_EMPTY)
    colour = 68 if energy > 6 else (70 if energy > 3 else 66)
    for index in range(gp.ENERGY_CELLS):
        lit = index < energy
        screen.char(gp.ENERGY_COL + index, gp.STAT_ROW,
                    full if lit else empty, colour if lit else 1)

    # The name of the room, in the gothic font, in the middle of the row.
    line = zx.Canvas(256, 8, strict=False)
    line.text(FONT_8X8, name, (SCREEN_COLS - len(name)) // 2 * 8, 0,
              ink=zx.CYAN, bright=True, advance=8)
    for col in range(SCREEN_COLS):
        screen.char(col, gp.TEXT_ROW, line.char_bytes(col, 0), 69)


def draw_border(screen):
    corner, item = border_tiles()
    last_row = BORDER_ROW + FIELD_HEIGHT + 1
    screen.char(0, BORDER_ROW, corner, BORDER_COLOR)
    screen.char(31, BORDER_ROW, corner, BORDER_COLOR)
    screen.char(0, last_row, corner, BORDER_COLOR)
    screen.char(31, last_row, corner, BORDER_COLOR)
    for col in range(1, 31):
        screen.char(col, BORDER_ROW, item, BORDER_COLOR)
        screen.char(col, last_row, item, BORDER_COLOR)
    for row in range(BORDER_ROW + 1, last_row):
        screen.char(0, row, item, BORDER_COLOR)
        screen.char(31, row, item, BORDER_COLOR)


def draw_room(screen, records, sprites, report):
    # The field starts as empty, in the colour the game cleans it to.
    for row in range(FIELD_FIRST_ROW, FIELD_FIRST_ROW + FIELD_HEIGHT):
        for col in range(FIELD_FIRST_COL, FIELD_FIRST_COL + FIELD_WIDTH):
            screen.attrs[row * SCREEN_COLS + col] = FIELD_COLOR

    left = FIELD_FIRST_COL * 8
    right = (FIELD_FIRST_COL + FIELD_WIDTH) * 8
    top = FIELD_FIRST_ROW * 8
    bottom = (FIELD_FIRST_ROW + FIELD_HEIGHT) * 8

    for x, y, colour, name in records:
        canvas = sprites[name]
        if x < left or x + canvas.width > right or y < top or y + canvas.height > bottom:
            report.append(
                "{} at {},{} ({}x{}) hangs out of the field".format(
                    name, x, y, canvas.width, canvas.height
                )
            )
        for line in range(canvas.height):
            for column in range(canvas.width):
                if canvas.pixels[line][column]:
                    screen.pixels[y + line][x + column] = 1
        for cell_row in range(canvas.rows):
            for cell_col in range(canvas.cols):
                own = canvas.inks[cell_row * canvas.cols + cell_col]
                attr = colour if colour else zx.attribute(own[0], own[1])
                index = (y // 8 + cell_row) * SCREEN_COLS + x // 8 + cell_col
                screen.attrs[index] = attr


def build_screen(records, panel, sprites, report, name=""):
    screen = Screen()
    draw_panel(screen, panel, name=name)
    draw_border(screen)
    draw_room(screen, records, sprites, report)
    return screen


def main() -> None:
    panel, _ = build_panel()
    sprites = sprite_canvases()
    rooms = room_lists()
    names = room_names()
    grid = rooms_map()
    report = []

    # The room the game starts in, taken from the map the same way it does.
    start = int(re.search(r"StartRoomInMap:\s*\n\s*defb\s+(\d+)", read("rooms.asm")).group(1))
    start_room = grid[start // len(grid[0])][start % len(grid[0])]

    screen = build_screen(rooms[start_room], panel, sprites, report,
                          names.get(start_room, ""))
    zx.write_preview(SCREEN_PATH, screen.image(scale=3))

    drawn = sorted(number for number in rooms if rooms[number])
    rows = (len(drawn) + 1) // 2
    sheet = Image.new("RGB", (256 * 2 + 12, rows * (192 + 6)), (24, 24, 24))
    for index, number in enumerate(drawn):
        one = build_screen(rooms[number], panel, sprites, report,
                           names.get(number, ""))
        sheet.paste(one.image(scale=1),
                    ((index % 2) * (256 + 12), (index // 2) * (192 + 6)))
    zx.write_preview(ROOMS_PATH, sheet)

    print("the game starts in room {} - {}".format(start_room, names.get(start_room)))
    if report:
        print("PROBLEMS:")
        for line in report:
            print("  " + line)
    else:
        print("every sprite of every room stands inside the game field")


if __name__ == "__main__":
    main()
