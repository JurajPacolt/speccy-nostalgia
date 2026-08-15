"""Shared helpers for the Dark Island 1 asset generators.

Every generator in this directory draws into a `Canvas`, which is a plain
one-bit-per-pixel picture plus one ink colour per 8x8 character cell - exactly
what the ZX Spectrum screen is. The canvas refuses a second ink in a cell, so
an attribute clash is a build error here instead of a surprise on the screen.

Artwork is written as ASCII art. A dot or a space is a hole, a hash mark is the
ink given to the blit and every other letter names its own colour:

    W w  white / grey        Y y  yellow
    C c  cyan                G g  green
    B b  blue                R r  red
    M m  magenta

An upper case letter is the bright colour, a lower case letter the normal one.
"""

from __future__ import annotations

from typing import Dict, List, Optional, Sequence, Tuple

from PIL import Image


# ZX Spectrum ink numbers. The bits are blue, red and green.
BLACK = 0
BLUE = 1
RED = 2
MAGENTA = 3
GREEN = 4
CYAN = 5
YELLOW = 6
WHITE = 7

NORMAL_LEVEL = 205
BRIGHT_LEVEL = 255

CELL = 8

# One colour of the artwork: the letter, the ink and the brightness.
ART_COLOURS = {
    "W": (WHITE, True),
    "w": (WHITE, False),
    "C": (CYAN, True),
    "c": (CYAN, False),
    "B": (BLUE, True),
    "b": (BLUE, False),
    "M": (MAGENTA, True),
    "m": (MAGENTA, False),
    "Y": (YELLOW, True),
    "y": (YELLOW, False),
    "G": (GREEN, True),
    "g": (GREEN, False),
    "R": (RED, True),
    "r": (RED, False),
    "K": (BLACK, False),
}

EMPTY_CHARS = ". _"


def rgb(ink: int, bright: bool) -> Tuple[int, int, int]:
    """The colour of one ink number, for the PNG previews."""
    level = BRIGHT_LEVEL if bright else NORMAL_LEVEL
    return (
        level if ink & 2 else 0,
        level if ink & 4 else 0,
        level if ink & 1 else 0,
    )


def attribute(ink: int, bright: bool, paper: int = BLACK) -> int:
    """One attribute byte: ink, paper and the bright bit."""
    return (ink & 7) | ((paper & 7) << 3) | (64 if bright else 0)


def art_lines(art: str) -> List[str]:
    """The lines of an ASCII art block, without the indentation of the source."""
    lines = art.strip("\n").rstrip().split("\n")
    while lines and not lines[0].strip():
        lines.pop(0)
    indent = min(
        (len(line) - len(line.lstrip(" ")) for line in lines if line.strip()),
        default=0,
    )
    return [line[indent:].rstrip("\n") for line in lines]


def art_size(art: str) -> Tuple[int, int]:
    """Width and height of an ASCII art block, in pixels."""
    lines = art_lines(art)
    return (max((len(line) for line in lines), default=0), len(lines))


class Clash(ValueError):
    """Two different inks were asked for in one character cell."""


class Canvas:
    """A one-bit picture with one ink colour per character cell."""

    def __init__(self, width: int, height: int, strict: bool = True) -> None:
        if width % CELL or height % CELL:
            raise ValueError("the canvas must be a whole number of cells")
        # A strict canvas becomes a real screen, so a second ink in a cell is an
        # error. A sheet that is only looked at in a PNG lets the last ink win.
        self.strict = strict
        self.width = width
        self.height = height
        self.cols = width // CELL
        self.rows = height // CELL
        self.pixels = [bytearray(width) for _ in range(height)]
        self.inks: List[Optional[Tuple[int, bool]]] = [None] * (self.cols * self.rows)

    # -- drawing ------------------------------------------------------------

    def cell_ink(self, col: int, row: int) -> Optional[Tuple[int, bool]]:
        return self.inks[row * self.cols + col]

    def set_cell_ink(self, col: int, row: int, ink: int, bright: bool) -> None:
        """Colour an empty cell, even when no pixel of it is set."""
        index = row * self.cols + col
        current = self.inks[index]
        if current is not None and current != (ink, bright) and self.strict:
            raise Clash(
                "cell {},{} is already ink {} bright {}".format(
                    col, row, current[0], current[1]
                )
            )
        self.inks[index] = (ink, bright)

    def pixel(self, x: int, y: int, ink: int, bright: bool) -> None:
        if not (0 <= x < self.width and 0 <= y < self.height):
            return
        self.set_cell_ink(x // CELL, y // CELL, ink, bright)
        self.pixels[y][x] = 1

    def clear_pixel(self, x: int, y: int) -> None:
        """Take one pixel out again - the cracks in a rock are made this way."""
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y][x] = 0

    def rectangle(self, x: int, y: int, width: int, height: int, ink: int, bright: bool) -> None:
        for row in range(y, y + height):
            for col in range(x, x + width):
                self.pixel(col, row, ink, bright)

    def blit(
        self,
        art: str,
        x: int,
        y: int,
        ink: int = WHITE,
        bright: bool = True,
        colours: Optional[Dict[str, Tuple[int, bool]]] = None,
    ) -> Tuple[int, int]:
        """Draw an ASCII art block. Returns its width and height in pixels."""
        palette = dict(ART_COLOURS)
        if colours:
            palette.update(colours)
        lines = art_lines(art)
        width = 0
        for row, line in enumerate(lines):
            width = max(width, len(line))
            for col, char in enumerate(line):
                if char in EMPTY_CHARS:
                    continue
                if char == "#":
                    self.pixel(x + col, y + row, ink, bright)
                    continue
                if char not in palette:
                    raise ValueError("unknown colour {!r} in the artwork".format(char))
                pixel_ink, pixel_bright = palette[char]
                self.pixel(x + col, y + row, pixel_ink, pixel_bright)
        return (width, len(lines))

    def text(
        self,
        glyphs: Dict[str, str],
        value: str,
        x: int,
        y: int,
        ink: int = WHITE,
        bright: bool = True,
        spacing: int = 0,
        space_width: int = 0,
        trim: bool = True,
        advance: Optional[int] = None,
    ) -> int:
        """Letter a word with a dictionary of ASCII art glyphs.

        Blank columns on both sides of a glyph are removed when `trim` is set,
        so the letters are spaced by their real shape and not by their cell.
        A font of a fixed width gives its cell in `advance` instead.
        Returns the width of the whole word in pixels.
        """
        cursor = x
        for index, char in enumerate(value):
            if advance is not None:
                art = glyphs.get(char)
                if art:
                    self.blit(art, cursor, y, ink=ink, bright=bright)
                cursor += advance
                continue
            if char == " ":
                cursor += space_width + spacing
                continue
            if char not in glyphs:
                raise ValueError("the alphabet has no glyph for {!r}".format(char))
            lines = art_lines(glyphs[char])
            if trim:
                lines = trim_columns(lines)
            width = max((len(line) for line in lines), default=0)
            self.blit("\n".join(lines), cursor, y, ink=ink, bright=bright)
            cursor += width
            if index + 1 < len(value):
                cursor += spacing
        return cursor - x

    # -- output -------------------------------------------------------------

    def char_bytes(self, col: int, row: int) -> bytes:
        """The eight bytes of one character cell, from the top line down."""
        out = bytearray()
        for line in range(CELL):
            value = 0
            pixels = self.pixels[row * CELL + line]
            for bit in range(CELL):
                if pixels[col * CELL + bit]:
                    value |= 0x80 >> bit
            out.append(value)
        return bytes(out)

    def attributes(self, empty: int = attribute(WHITE, False)) -> List[int]:
        """One attribute byte per cell, in the order of the screen."""
        out = []
        for index in range(self.cols * self.rows):
            colour = self.inks[index]
            out.append(empty if colour is None else attribute(colour[0], colour[1]))
        return out

    def tiles(self) -> Tuple[List[bytes], List[int], List[int]]:
        """Split the picture into unique tiles and a map of them.

        Tile number zero is the empty character and is never stored, so the
        map is mostly zeroes and only the drawn cells cost eight bytes.
        """
        tiles: List[bytes] = []
        index: Dict[bytes, int] = {}
        tile_map: List[int] = []
        for row in range(self.rows):
            for col in range(self.cols):
                data = self.char_bytes(col, row)
                if not any(data):
                    tile_map.append(0)
                    continue
                number = index.get(data)
                if number is None:
                    tiles.append(data)
                    number = len(tiles)
                    index[data] = number
                tile_map.append(number)
        return tiles, tile_map, self.attributes()

    def sprite_data(self) -> Tuple[bytes, bytes]:
        """The bytes of a sprite: the bitmap by pixel lines, then the colours.

        This is the shape the drawing routines of the game read: for every
        pixel line one byte per character column, and after the whole bitmap
        one attribute for every character of the sprite.
        """
        bitmap = bytearray()
        for y in range(self.height):
            for col in range(self.cols):
                value = 0
                pixels = self.pixels[y]
                for bit in range(CELL):
                    if pixels[col * CELL + bit]:
                        value |= 0x80 >> bit
                bitmap.append(value)
        return bytes(bitmap), bytes(self.attributes())

    def preview(self, scale: int = 4, background: Tuple[int, int, int] = (0, 0, 0)) -> Image.Image:
        image = Image.new("RGB", (self.width, self.height), background)
        put = image.load()
        for y in range(self.height):
            for x in range(self.width):
                if not self.pixels[y][x]:
                    continue
                colour = self.inks[(y // CELL) * self.cols + x // CELL]
                put[x, y] = rgb(*colour) if colour else rgb(WHITE, True)
        if scale > 1:
            image = image.resize((self.width * scale, self.height * scale), Image.NEAREST)
        return image


def trim_columns(lines: Sequence[str]) -> List[str]:
    """Remove the empty columns on the left and on the right of a glyph."""
    width = max((len(line) for line in lines), default=0)
    padded = [line.ljust(width) for line in lines]
    used = [
        col
        for col in range(width)
        if any(line[col] not in EMPTY_CHARS for line in padded)
    ]
    if not used:
        return ["" for _ in padded]
    left, right = used[0], used[-1]
    return [line[left : right + 1] for line in padded]


def glyph_bytes(art: str, width: int = 8, height: int = 8, shift: int = 0) -> bytes:
    """Eight bytes of one glyph of a font, the pixels packed from the left."""
    lines = art_lines(art)
    if len(lines) > height:
        raise ValueError("the glyph is {} lines high".format(len(lines)))
    out = bytearray()
    for row in range(height):
        line = lines[row] if row < len(lines) else ""
        value = 0
        for col in range(min(width, len(line))):
            if line[col] not in EMPTY_CHARS:
                value |= 0x80 >> col
        out.append((value >> shift) & 0xFF if shift >= 0 else (value << -shift) & 0xFF)
    return bytes(out)


# -- assembly output --------------------------------------------------------

def defb_block(values: Sequence[int], per_line: int = 16, indent: str = "        ") -> str:
    """A block of `defb` lines with the values aligned in columns."""
    lines = []
    for start in range(0, len(values), per_line):
        chunk = values[start : start + per_line]
        lines.append(indent + "defb  " + ", ".join("{:3d}".format(v) for v in chunk))
    return "\n".join(lines)


def defb_bits(values: Sequence[int], indent: str = "        ") -> str:
    """One `defb` per byte, written in binary - readable as a picture."""
    return "\n".join(
        indent + "defb  %" + format(value, "08b").replace("0", ".").replace("1", "#")
        for value in values
    )


def defb_binary(values: Sequence[int], indent: str = "        ") -> str:
    """One `defb` per byte in binary, the way the hand written sources look."""
    return "\n".join(indent + "defb  %" + format(value, "08b") for value in values)


def write_source(path, text: str) -> None:
    """Write a generated assembly file with the line ends of the project."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(str(path), "w", encoding="ascii", newline="\r\n") as handle:
        handle.write(text)
    print("written {} ({} bytes)".format(path, path.stat().st_size))


def write_preview(path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(str(path))
    print("written {} ({}x{})".format(path, image.width, image.height))
