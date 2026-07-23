"""Convert the generated ending artwork to a real ZX Spectrum .scr screen."""

from __future__ import annotations

import argparse
from itertools import combinations_with_replacement
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "gfx" / "game-won-source.png"
DEFAULT_PREVIEW = ROOT / "gfx" / "game-won-screen.png"
DEFAULT_SCREEN = ROOT / "src" / "binary" / "game-won.scr"
FONT_PATH = ROOT / "gfx" / "std8x8.chr"

WIDTH = 256
HEIGHT = 192
CELL = 8
TITLE = "CONGRATULATION"

# The conventional RGB approximation of the Spectrum's normal and BRIGHT
# palettes. BRIGHT affects ink and paper together inside one attribute cell.
PALETTES = (
    (
        (0, 0, 0),
        (0, 0, 205),
        (205, 0, 0),
        (205, 0, 205),
        (0, 205, 0),
        (0, 205, 205),
        (205, 205, 0),
        (205, 205, 205),
    ),
    (
        (0, 0, 0),
        (0, 0, 255),
        (255, 0, 0),
        (255, 0, 255),
        (0, 255, 0),
        (0, 255, 255),
        (255, 255, 0),
        (255, 255, 255),
    ),
)


def squared_distance(left: tuple[int, int, int], right: tuple[int, int, int]) -> int:
    return sum((a - b) * (a - b) for a, b in zip(left, right))


def draw_exact_title(image: Image.Image) -> None:
    """Replace generated lettering with deterministic 2x Spectrum ROM glyphs."""
    font = FONT_PATH.read_bytes()
    if len(font) != 96 * 8:
        raise ValueError(f"{FONT_PATH} must contain 96 eight-byte glyphs")

    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, WIDTH - 1, 31), fill=PALETTES[1][0])
    scale = 2
    glyph_width = 8 * scale
    start_x = (WIDTH - len(TITLE) * glyph_width) // 2
    start_y = 8

    for character_index, character in enumerate(TITLE):
        glyph_offset = (ord(character) - 32) * 8
        for row in range(8):
            bits = font[glyph_offset + row]
            for column in range(8):
                if bits & (0x80 >> column):
                    x = start_x + character_index * glyph_width + column * scale
                    y = start_y + row * scale
                    draw.rectangle(
                        (x, y, x + scale - 1, y + scale - 1),
                        fill=PALETTES[1][6],
                    )


def choose_cell_colors(
    pixels: list[tuple[int, int, int]],
) -> tuple[int, int, int, list[int], list[tuple[int, int, int]]]:
    best: tuple[
        int, int, int, int, list[int], list[tuple[int, int, int]]
    ] | None = None

    for bright, palette in enumerate(PALETTES):
        for first, second in combinations_with_replacement(range(8), 2):
            first_color = palette[first]
            second_color = palette[second]
            bits: list[int] = []
            rendered: list[tuple[int, int, int]] = []
            score = 0

            for pixel in pixels:
                first_error = squared_distance(pixel, first_color)
                second_error = squared_distance(pixel, second_color)
                if second_error < first_error:
                    bits.append(1)
                    rendered.append(second_color)
                    score += second_error
                else:
                    bits.append(0)
                    rendered.append(first_color)
                    score += first_error

            candidate = (score, bright, first, second, bits, rendered)
            if best is None or candidate[0] < best[0]:
                best = candidate

    assert best is not None
    _, bright, paper, ink, bits, rendered = best

    # Whichever color covers most of the cell is the paper. Swapping produces
    # the same picture but gives conventional, easier-to-inspect attributes.
    if sum(bits) > len(bits) // 2:
        paper, ink = ink, paper
        bits = [1 - bit for bit in bits]
        rendered = [
            PALETTES[bright][ink] if bit else PALETTES[bright][paper]
            for bit in bits
        ]

    return bright, paper, ink, bits, rendered


def spectrum_bitmap_offset(y: int, byte_x: int) -> int:
    return (
        ((y & 0xC0) << 5)
        | ((y & 0x07) << 8)
        | ((y & 0x38) << 2)
        | byte_x
    )


def convert(image: Image.Image) -> tuple[bytes, Image.Image]:
    image = ImageOps.fit(
        image.convert("RGB"),
        (WIDTH, HEIGHT),
        method=Image.Resampling.LANCZOS,
    )
    draw_exact_title(image)

    bitmap = bytearray(6144)
    attributes = bytearray(768)
    preview = Image.new("RGB", (WIDTH, HEIGHT))
    source_pixels = image.load()
    preview_pixels = preview.load()

    for cell_y in range(HEIGHT // CELL):
        for cell_x in range(WIDTH // CELL):
            pixels = [
                source_pixels[cell_x * CELL + x, cell_y * CELL + y]
                for y in range(CELL)
                for x in range(CELL)
            ]
            bright, paper, ink, bits, rendered = choose_cell_colors(pixels)
            attributes[cell_y * 32 + cell_x] = (
                (bright << 6) | (paper << 3) | ink
            )

            for y in range(CELL):
                value = 0
                for x in range(CELL):
                    index = y * CELL + x
                    value = (value << 1) | bits[index]
                    preview_pixels[
                        cell_x * CELL + x, cell_y * CELL + y
                    ] = rendered[index]
                screen_y = cell_y * CELL + y
                bitmap[spectrum_bitmap_offset(screen_y, cell_x)] = value

    return bytes(bitmap + attributes), preview


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--preview", type=Path, default=DEFAULT_PREVIEW)
    parser.add_argument("--screen", type=Path, default=DEFAULT_SCREEN)
    args = parser.parse_args()

    screen, preview = convert(Image.open(args.input))
    if len(screen) != 6912:
        raise AssertionError(f"expected 6912 screen bytes, got {len(screen)}")

    args.preview.parent.mkdir(parents=True, exist_ok=True)
    args.screen.parent.mkdir(parents=True, exist_ok=True)
    preview.save(args.preview)
    args.screen.write_bytes(screen)
    print(f"wrote {args.preview} ({preview.width}x{preview.height})")
    print(f"wrote {args.screen} ({len(screen)} bytes)")


if __name__ == "__main__":
    main()
