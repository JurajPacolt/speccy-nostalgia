"""Generate Dillen's deterministic ZX Spectrum loading screen."""

from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FONT_PATH = ROOT / "gfx" / "std8x8.chr"
SPRITES_PATH = ROOT / "src" / "player_sprites.asm"
PREVIEW_PATH = ROOT / "gfx" / "dillen-loading-screen.png"
SCREEN_PATH = ROOT / "src" / "binary" / "dillen-loading.scr"
MANIFEST_PATH = ROOT / "gfx" / "dillen-loading-screen-manifest.json"

WIDTH = 256
HEIGHT = 192
CELL = 8
BITMAP_SIZE = 6144
ATTRIBUTE_SIZE = 768

BLACK = 0
BLUE = 1
RED = 2
MAGENTA = 3
GREEN = 4
CYAN = 5
YELLOW = 6
WHITE = 7

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


def spectrum_bitmap_offset(y: int, byte_x: int) -> int:
    return (
        ((y & 0xC0) << 5)
        | ((y & 0x07) << 8)
        | ((y & 0x38) << 2)
        | byte_x
    )


class SpectrumScreen:
    """One-bit bitmap with one bright ink colour on black in every cell."""

    def __init__(self) -> None:
        self.pixels = [bytearray(WIDTH) for _ in range(HEIGHT)]
        self.cell_inks: list[int | None] = [None] * ATTRIBUTE_SIZE

    def clear_cells(self, left: int, top: int, right: int, bottom: int) -> None:
        for cell_y in range(top, bottom + 1):
            for cell_x in range(left, right + 1):
                for y in range(cell_y * CELL, cell_y * CELL + CELL):
                    start = cell_x * CELL
                    self.pixels[y][start : start + CELL] = b"\0" * CELL
                self.cell_inks[cell_y * 32 + cell_x] = None

    def pixel(self, x: int, y: int, ink: int) -> None:
        if not 0 <= x < WIDTH or not 0 <= y < HEIGHT:
            return
        cell_index = (y // CELL) * 32 + x // CELL
        old_ink = self.cell_inks[cell_index]
        if old_ink is not None and old_ink != ink:
            raise ValueError(
                f"attribute clash at cell {x // CELL},{y // CELL}: "
                f"ink {old_ink} versus {ink}"
            )
        self.cell_inks[cell_index] = ink
        self.pixels[y][x] = 1

    def line(self, x0: int, y0: int, x1: int, y1: int, ink: int) -> None:
        dx = abs(x1 - x0)
        sx = 1 if x0 < x1 else -1
        dy = -abs(y1 - y0)
        sy = 1 if y0 < y1 else -1
        error = dx + dy
        while True:
            self.pixel(x0, y0, ink)
            if x0 == x1 and y0 == y1:
                return
            twice_error = 2 * error
            if twice_error >= dy:
                error += dy
                x0 += sx
            if twice_error <= dx:
                error += dx
                y0 += sy

    def text(
        self,
        font: bytes,
        value: str,
        x: int,
        y: int,
        ink: int,
        scale: int = 1,
    ) -> None:
        for character_index, character in enumerate(value):
            glyph = ord(character) - 32
            if not 0 <= glyph < 96:
                raise ValueError(f"unsupported loading-screen character: {character!r}")
            offset = glyph * 8
            for row in range(8):
                bits = font[offset + row]
                for column in range(8):
                    if not bits & (0x80 >> column):
                        continue
                    pixel_x = x + character_index * 8 * scale + column * scale
                    pixel_y = y + row * scale
                    for scale_y in range(scale):
                        for scale_x in range(scale):
                            self.pixel(pixel_x + scale_x, pixel_y + scale_y, ink)

    def stone(self, cell_x: int, cell_y: int, ink: int, variant: int) -> None:
        x = cell_x * CELL
        y = cell_y * CELL
        self.line(x, y, x + 7, y, ink)
        self.line(x, y + 7, x + 7, y + 7, ink)
        if variant & 1:
            self.line(x + 1, y + 3, x + 5, y + 3, ink)
            self.pixel(x + 5, y + 4, ink)
        else:
            self.line(x + 3, y + 1, x + 3, y + 4, ink)
            self.line(x + 3, y + 4, x + 6, y + 4, ink)

    def scaled_sprite(
        self,
        sprite: bytes,
        source_width: int,
        source_height: int,
        x: int,
        y: int,
        scale: int,
        ink: int,
    ) -> None:
        width_bytes = source_width // 8
        for source_y in range(source_height):
            for source_x in range(source_width):
                value = sprite[source_y * width_bytes + source_x // 8]
                if not value & (0x80 >> (source_x & 7)):
                    continue
                for scale_y in range(scale):
                    for scale_x in range(scale):
                        self.pixel(
                            x + source_x * scale + scale_x,
                            y + source_y * scale + scale_y,
                            ink,
                        )

    def to_scr(self) -> bytes:
        bitmap = bytearray(BITMAP_SIZE)
        attributes = bytearray(ATTRIBUTE_SIZE)
        for y in range(HEIGHT):
            for byte_x in range(WIDTH // 8):
                value = 0
                for bit in range(8):
                    value = (value << 1) | self.pixels[y][byte_x * 8 + bit]
                bitmap[spectrum_bitmap_offset(y, byte_x)] = value
        for index, ink in enumerate(self.cell_inks):
            attributes[index] = 64 | (ink if ink is not None else BLACK)
        return bytes(bitmap + attributes)

    def preview(self) -> Image.Image:
        image = Image.new("RGB", (WIDTH, HEIGHT), PALETTES[1][BLACK])
        output = image.load()
        for y in range(HEIGHT):
            for x in range(WIDTH):
                ink = self.cell_inks[(y // CELL) * 32 + x // CELL]
                color = ink if self.pixels[y][x] and ink is not None else BLACK
                output[x, y] = PALETTES[1][color]
        return image


def load_idle_sprite() -> bytes:
    source = SPRITES_PATH.read_text(encoding="utf-8")
    match = re.search(
        r"PlayerSpriteIdle0:\s*defb\s+([^\r\n]+)",
        source,
        flags=re.MULTILINE,
    )
    if not match:
        raise ValueError(f"PlayerSpriteIdle0 was not found in {SPRITES_PATH}")
    values = bytes(int(value.strip()) for value in match.group(1).split(","))
    if len(values) != 16 // 8 * 24:
        raise ValueError(f"expected a 48-byte idle sprite, got {len(values)}")
    return values


def draw_castle(screen: SpectrumScreen) -> None:
    # Massive cold-blue masonry framing a black central exit.
    for cell_y in range(10, 20):
        for cell_x in range(4, 9):
            screen.stone(cell_x, cell_y, CYAN if (cell_x + cell_y) % 3 else BLUE, cell_x + cell_y)
        for cell_x in range(23, 28):
            screen.stone(cell_x, cell_y, CYAN if (cell_x + cell_y) % 3 else BLUE, cell_x + cell_y)

    for cell_x in range(8, 24):
        screen.stone(cell_x, 7, CYAN if cell_x % 3 else WHITE, cell_x)
    for cell_x in range(7, 25):
        screen.stone(cell_x, 8, CYAN if cell_x % 4 else BLUE, cell_x + 1)
    for cell_x in range(6, 10):
        screen.stone(cell_x, 9, CYAN, cell_x)
    for cell_x in range(22, 26):
        screen.stone(cell_x, 9, CYAN, cell_x)

    # Cyan arched doorway and sparse blue light in its depth.
    for cell_x in range(13, 19):
        screen.line(cell_x * 8, 79, cell_x * 8 + 7, 79, CYAN)
    screen.line(96, 80, 88, 95, CYAN)
    screen.line(159, 80, 167, 95, CYAN)
    screen.line(88, 95, 88, 159, CYAN)
    screen.line(167, 95, 167, 159, CYAN)

    for cell_y in range(11, 20):
        for cell_x in range(13, 19):
            if (cell_x * 5 + cell_y * 3) % 7 == 0:
                x = cell_x * 8 + 3
                y = cell_y * 8 + 3
                screen.pixel(x, y, BLUE)
                screen.pixel(x + 1, y, BLUE)


def draw_torches(screen: SpectrumScreen) -> None:
    for cell_x in (6, 25):
        x = cell_x * 8
        # A separate red flame cell and white bracket cell avoid clashes.
        screen.clear_cells(cell_x, 11, cell_x, 13)
        for px, py in ((3, 0), (2, 1), (4, 1), (1, 3), (3, 3), (5, 3), (2, 5), (4, 5), (3, 7)):
            screen.pixel(x + px, 88 + py, RED)
        screen.line(x + 3, 96, x + 3, 111, WHITE)
        screen.line(x + 1, 111, x + 5, 111, WHITE)


def build_screen() -> SpectrumScreen:
    font = FONT_PATH.read_bytes()
    if len(font) != 96 * 8:
        raise ValueError(f"{FONT_PATH} must contain 768 font bytes")

    screen = SpectrumScreen()

    # Bright cyan masthead and the game's exact subtitle.
    screen.text(font, "DILLEN", 80, 8, CYAN, scale=2)
    screen.line(32, 27, 223, 27, BLUE)
    screen.text(font, "ESCAPE FROM UNDERGROUND", 36, 32, YELLOW)

    # Small stars link the loading screen visually with the animated title.
    for x, y in ((17, 55), (30, 72), (226, 53), (239, 76)):
        screen.pixel(x, y, WHITE)
        screen.pixel(x - 1, y, WHITE)
        screen.pixel(x + 1, y, WHITE)
        screen.pixel(x, y - 1, WHITE)
        screen.pixel(x, y + 1, WHITE)

    draw_castle(screen)
    draw_torches(screen)

    # Reserve a clean four-by-six-cell silhouette for the recognizable hero.
    screen.clear_cells(14, 13, 17, 18)
    screen.scaled_sprite(load_idle_sprite(), 16, 24, 112, 104, 2, YELLOW)

    screen.line(48, 164, 207, 164, CYAN)
    screen.text(font, "LOADING...", 88, 168, WHITE)
    screen.text(font, "PLEASE WAIT", 84, 184, CYAN)
    return screen


def main() -> None:
    screen = build_screen()
    payload = screen.to_scr()
    if len(payload) != BITMAP_SIZE + ATTRIBUTE_SIZE:
        raise AssertionError(f"expected 6912 bytes, got {len(payload)}")

    preview = screen.preview()
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    SCREEN_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_PATH)
    SCREEN_PATH.write_bytes(payload)

    manifest = {
        "title": "Dillen loading screen",
        "concept": "Dillen framed by a cold castle arch, facing the lit exit.",
        "dimensions": [WIDTH, HEIGHT],
        "format": "ZX Spectrum SCR",
        "byte_length": len(payload),
        "attribute_rule": "bright ink on black; one ink per 8x8 cell",
        "exact_copy": ["DILLEN", "ESCAPE FROM UNDERGROUND", "LOADING...", "PLEASE WAIT"],
        "source_sprite": str(SPRITES_PATH.relative_to(ROOT)),
        "preview": str(PREVIEW_PATH.relative_to(ROOT)),
        "screen": str(SCREEN_PATH.relative_to(ROOT)),
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"wrote {PREVIEW_PATH} ({WIDTH}x{HEIGHT})")
    print(f"wrote {SCREEN_PATH} ({len(payload)} bytes)")
    print(f"wrote {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
