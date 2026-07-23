"""Generate Dillen's text-free title background and runtime preview."""

from __future__ import annotations

import argparse
import random
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

from generate_game_won_screen import (
    PALETTES,
    choose_cell_colors,
    spectrum_bitmap_offset,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "gfx" / "dillen-title-source.png"
DEFAULT_BACKGROUND_PREVIEW = ROOT / "gfx" / "dillen-title-background.png"
DEFAULT_PREVIEW = ROOT / "gfx" / "dillen-title-screen.png"
DEFAULT_SCREEN = ROOT / "src" / "binary" / "dillen-title.scr"
DEFAULT_COMPRESSED = ROOT / "src" / "binary" / "dillen-title.lzs"
DEFAULT_LOGO = ROOT / "src" / "binary" / "dillen-title-logo.bin"

GAME_FONT_PATH = ROOT / "src" / "font_4x8.asm"
PLAYER_SPRITES_PATH = ROOT / "src" / "player_sprites.asm"
STAR_SHAPES_PATH = ROOT / "src" / "stars_on_background.asm"
COMIC_FONT_PATH = Path(
    "/usr/share/fonts/truetype/msttcorefonts/comic.ttf"
)

WIDTH = 256
HEIGHT = 192
CELL = 8

LOGO_TEXT = "Dillen"
LOGO_X = 80
LOGO_Y = 0
LOGO_WIDTH = 96
LOGO_HEIGHT = 24
LOGO_WIDTH_BYTES = LOGO_WIDTH // 8

CONTROL_TEXT = (
    ("CONTROLS", 7, 10, 69),
    ("Z/X OR O/P", 9, 9, 70),
    ("MOVE", 10, 12, 71),
    ("SPACE - JUMP", 12, 8, 70),
    ("ENTER - INVENTORY", 14, 5, 70),
    ("Q/A - ITEM UP/DOWN", 16, 5, 70),
)
START_TEXT = "ENTER OR SPACE - START"
START_ROW = 22
START_COLUMN = 21

PROMPT_ATTR_COLUMN = START_COLUMN // 2
PROMPT_ATTR_WIDTH = 12

TITLE_STARS_MAX = 8
TITLE_STAR_ROW_MIN = 6
TITLE_STAR_ROW_MAX = 21
TITLE_STAR_COL_MIN = 1
TITLE_STAR_COL_MAX = 30

def draw_background_layout(image: Image.Image) -> None:
    """Reserve clean runtime overlay areas without baking in any text."""
    draw = ImageDraw.Draw(image)

    # Logo and walking-hero lane. Both are added later by runtime code.
    draw.rectangle((0, 0, WIDTH - 1, 47), fill=PALETTES[1][0])

    # Controls panel. All lettering is drawn later by the game's 4x8 routine.
    draw.rectangle((8, 48, 103, 143), fill=PALETTES[0][0])
    draw.rectangle((8, 48, 103, 49), fill=PALETTES[1][5])
    draw.rectangle((8, 142, 103, 143), fill=PALETTES[1][3])
    draw.rectangle((8, 48, 9, 143), fill=PALETTES[1][1])
    draw.rectangle((102, 48, 103, 143), fill=PALETTES[1][1])

    # Start prompt area, also kept completely text-free in the background.
    draw.rectangle((64, 172, 191, 187), fill=PALETTES[0][0])


def compose_background(source: Image.Image) -> Image.Image:
    """Fit generated artwork and add only non-text screen decoration."""
    image = ImageOps.fit(
        source.convert("RGB"),
        (WIDTH, HEIGHT),
        method=Image.Resampling.LANCZOS,
    )
    # Two-by-two source pixels keep silhouettes clear and compress efficiently.
    image = image.resize(
        (WIDTH // 2, HEIGHT // 2),
        Image.Resampling.BILINEAR,
    ).resize((WIDTH, HEIGHT), Image.Resampling.NEAREST)
    draw_background_layout(image)
    return image


def generate_logo() -> tuple[bytes, Image.Image]:
    """Rasterize a thin Comic Sans logo into a 1-bit runtime bitmap."""
    if not COMIC_FONT_PATH.exists():
        raise FileNotFoundError(
            f"Comic title font is missing: {COMIC_FONT_PATH}"
        )

    font = ImageFont.truetype(COMIC_FONT_PATH, 60)
    scratch = Image.new("L", (256, 80))
    draw = ImageDraw.Draw(scratch)
    bounds = draw.textbbox((0, 0), LOGO_TEXT, font=font)
    draw.text(
        (-bounds[0], -bounds[1]),
        LOGO_TEXT,
        font=font,
        fill=255,
    )
    glyph = scratch.crop(
        (
            0,
            0,
            bounds[2] - bounds[0] + 2,
            bounds[3] - bounds[1] + 2,
        )
    )

    glyph.thumbnail((LOGO_WIDTH, LOGO_HEIGHT - 2), Image.Resampling.LANCZOS)
    glyph = glyph.resize(
        (LOGO_WIDTH, glyph.height),
        Image.Resampling.LANCZOS,
    )
    logo = Image.new("1", (LOGO_WIDTH, LOGO_HEIGHT))
    left = (LOGO_WIDTH - glyph.width) // 2
    top = (LOGO_HEIGHT - glyph.height) // 2
    logo.paste(
        glyph.point(lambda value: 255 if value >= 128 else 0),
        (left, top),
    )

    packed = bytearray()
    pixels = logo.load()
    for y in range(LOGO_HEIGHT):
        for byte_x in range(LOGO_WIDTH_BYTES):
            value = 0
            for bit in range(8):
                value = (value << 1) | int(
                    bool(pixels[byte_x * 8 + bit, y])
                )
            packed.append(value)

    return bytes(packed), logo


def convert(image: Image.Image) -> tuple[bytes, Image.Image]:
    """Convert RGB art to a strict 6912-byte Spectrum screen."""
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


def force_worm_bright(screen: bytes) -> bytes:
    """Make every yellow attribute cell covering the large hero BRIGHT."""
    output = bytearray(screen)
    for cell_y in range(6, 20):
        for cell_x in range(15, 25):
            index = 6144 + cell_y * 32 + cell_x
            attribute = output[index]
            ink = attribute & 7
            paper = (attribute >> 3) & 7
            if ink == 6 or paper == 6:
                output[index] = attribute | 64
    return bytes(output)


def compress_lzss(data: bytes) -> bytes:
    """Compress bytes with the small LZSS format used by title_screen.asm."""
    max_offset = 4095
    max_length = 255
    chains: dict[bytes, list[int]] = {}
    tokens: list[tuple[int, ...]] = []
    position = 0

    while position < len(data):
        key = data[position : position + 3]
        best_length = 0
        best_offset = 0

        for candidate in reversed(chains.get(key, ())):
            offset = position - candidate
            if offset > max_offset:
                break

            length = 0
            while (
                length < max_length
                and position + length < len(data)
                and data[candidate + length] == data[position + length]
            ):
                length += 1

            if length > best_length:
                best_length = length
                best_offset = offset
            if length == max_length:
                break

        if best_length >= 3:
            tokens.append((1, best_offset, best_length))
            for matched in range(best_length):
                index = position + matched
                if index + 3 <= len(data):
                    chains.setdefault(data[index : index + 3], []).append(index)
            position += best_length
        else:
            tokens.append((0, data[position]))
            chains.setdefault(key, []).append(position)
            position += 1

    output = bytearray()
    for first in range(0, len(tokens), 8):
        group = tokens[first : first + 8]
        flags = 0
        payload = bytearray()

        for bit, token in enumerate(group):
            if token[0] == 0:
                payload.append(token[1])
                continue

            flags |= 1 << bit
            _, offset, length = token
            length_code = min(length - 3, 15)
            payload.extend(
                (
                    offset & 255,
                    ((offset >> 8) << 4) | length_code,
                )
            )
            if length_code == 15:
                payload.append(length - 18)

        output.append(flags)
        output.extend(payload)

    return bytes(output)


def decompress_lzss(data: bytes, output_size: int) -> bytes:
    """Reference decoder used to verify compressed assets during generation."""
    source = 0
    flags = 0
    bits = 0
    output = bytearray()

    while len(output) < output_size:
        if bits == 0:
            flags = data[source]
            source += 1
            bits = 8

        is_match = flags & 1
        flags >>= 1
        bits -= 1

        if not is_match:
            output.append(data[source])
            source += 1
            continue

        offset_low = data[source]
        token = data[source + 1]
        source += 2
        offset = offset_low | ((token >> 4) << 8)
        length_code = token & 15
        if length_code == 15:
            length = data[source] + 18
            source += 1
        else:
            length = length_code + 3

        for _ in range(length):
            output.append(output[-offset])

    if len(output) != output_size:
        raise AssertionError(
            f"decompressed past output: expected {output_size}, got {len(output)}"
        )
    return bytes(output)


def load_game_font() -> bytes:
    """Read the 96 glyphs directly from the game's Font4x8 assembly data."""
    source = GAME_FONT_PATH.read_text()
    font_source = source.split("Font4x8:", 1)[1]
    values: list[int] = []

    for line in font_source.splitlines():
        if line.startswith("; END"):
            break
        match = re.search(r"\bdefb\s+([^;]+)", line)
        if not match:
            continue
        values.extend(
            int(value.strip(), 0)
            for value in match.group(1).split(",")
        )

    if len(values) != 96 * 8:
        raise ValueError(
            f"{GAME_FONT_PATH} contains {len(values)} font bytes, expected 768"
        )
    return bytes(values)


def load_player_walk_frame(frame: int = 0) -> bytes:
    """Read one 16x24 right-walk frame from the real player sprite data."""
    source = PLAYER_SPRITES_PATH.read_text()
    frame_source = source.split(f"PlayerSpriteWalkRight{frame}:", 1)[1]
    values: list[int] = []
    for line in frame_source.splitlines():
        match = re.search(r"\bdefb\s+([^;]+)", line)
        if not match:
            if values:
                break
            continue
        values.extend(
            int(value.strip(), 0)
            for value in match.group(1).split(",")
        )
        if len(values) >= 48:
            break
    if len(values) != 48:
        raise ValueError(
            f"walk frame {frame} contains {len(values)} bytes, expected 48"
        )
    return bytes(values)


def load_star_shapes() -> bytes:
    """Read the game's eight real twinkle phases from assembly data."""
    source = STAR_SHAPES_PATH.read_text()
    shape_source = source.split("_StarsShapes:", 1)[1]
    values: list[int] = []
    for line in shape_source.splitlines():
        match = re.search(r"\bdefb\s+([^;]+)", line)
        if not match:
            if len(values) >= 64:
                break
            continue
        values.extend(
            int(value.strip().replace("%", "0b"), 0)
            for value in match.group(1).split(",")
        )
        if len(values) >= 64:
            break
    if len(values) != 64:
        raise ValueError(
            f"{STAR_SHAPES_PATH} contains {len(values)} star bytes, expected 64"
        )
    return bytes(values)


def draw_logo_to_screen(screen: bytearray, logo: bytes) -> None:
    """Simulate TitleScreenDrawLogo for the review preview."""
    for y in range(LOGO_HEIGHT):
        for byte_x in range(LOGO_WIDTH_BYTES):
            screen[spectrum_bitmap_offset(LOGO_Y + y, LOGO_X // 8 + byte_x)] = (
                logo[y * LOGO_WIDTH_BYTES + byte_x]
            )


def draw_4x8_text(
    screen: bytearray,
    font: bytes,
    text: str,
    row: int,
    column: int,
) -> None:
    """Simulate the OR-based Print4x8 routine exactly."""
    for character in text:
        glyph_offset = (ord(character) - 32) * 8
        byte_x = column // 2
        for y in range(8):
            value = font[glyph_offset + y]
            if column & 1:
                value >>= 4
            offset = spectrum_bitmap_offset(row * 8 + y, byte_x)
            screen[offset] |= value
        column += 1


def set_attr_run(
    screen: bytearray,
    row: int,
    column: int,
    width: int,
    color: int,
) -> None:
    start = 6144 + row * 32 + column
    screen[start : start + width] = bytes((color,)) * width


def draw_walking_hero(
    screen: bytearray,
    sprite: bytes,
    x: int = 0,
) -> None:
    """Simulate one frame of the byte-aligned title-screen walk."""
    byte_x = x // 8
    for y in range(24):
        offset = spectrum_bitmap_offset(24 + y, byte_x)
        screen[offset : offset + 2] = sprite[y * 2 : y * 2 + 2]
    for row in range(3, 6):
        set_attr_run(screen, row, byte_x, 2, 70)


def draw_preview_stars(screen: bytearray) -> None:
    """Show one deterministic sample of the runtime-random game stars."""
    candidates: list[tuple[int, int]] = []
    for row in range(TITLE_STAR_ROW_MIN, TITLE_STAR_ROW_MAX + 1):
        for column in range(TITLE_STAR_COL_MIN, TITLE_STAR_COL_MAX + 1):
            if row < 18 and column < 13:
                continue
            attribute = screen[6144 + row * 32 + column]
            if attribute & 56:
                continue
            if any(
                screen[spectrum_bitmap_offset(row * 8 + y, column)]
                for y in range(8)
            ):
                continue
            candidates.append((row, column))

    rng = random.Random(73)
    shapes = load_star_shapes()
    for index, (row, column) in enumerate(
        rng.sample(
            candidates,
            min(TITLE_STARS_MAX, len(candidates)),
        )
    ):
        phase = (index + 2) % 8
        shape = shapes[phase * 8 : phase * 8 + 8]
        for y, value in enumerate(shape):
            screen[spectrum_bitmap_offset(row * 8 + y, column)] = value
        screen[6144 + row * 32 + column] = 68 + rng.randrange(4)


def render_screen(screen: bytes) -> Image.Image:
    """Render a strict Spectrum screen back to RGB for review."""
    image = Image.new("RGB", (WIDTH, HEIGHT))
    pixels = image.load()

    for y in range(HEIGHT):
        for byte_x in range(32):
            value = screen[spectrum_bitmap_offset(y, byte_x)]
            attribute = screen[6144 + (y // 8) * 32 + byte_x]
            bright = 1 if attribute & 64 else 0
            ink = PALETTES[bright][attribute & 7]
            paper = PALETTES[bright][(attribute >> 3) & 7]
            for bit in range(8):
                pixels[byte_x * 8 + bit, y] = (
                    ink if value & (0x80 >> bit) else paper
                )

    return image


def create_runtime_preview(screen: bytes, logo: bytes) -> Image.Image:
    """Compose code-drawn logo, Font4x8 copy and one animation frame."""
    preview = bytearray(screen)
    font = load_game_font()

    draw_logo_to_screen(preview, logo)
    for text, row, column, color in CONTROL_TEXT:
        draw_4x8_text(preview, font, text, row, column)
        first_attr = column // 2
        last_attr = (column + len(text) - 1) // 2
        set_attr_run(
            preview,
            row,
            first_attr,
            last_attr - first_attr + 1,
            color,
        )

    draw_4x8_text(preview, font, START_TEXT, START_ROW, START_COLUMN)
    set_attr_run(
        preview,
        START_ROW,
        PROMPT_ATTR_COLUMN,
        PROMPT_ATTR_WIDTH,
        70,
    )

    for row in range(3):
        start = 6144 + row * 32 + LOGO_X // 8
        preview[start : start + LOGO_WIDTH_BYTES] = bytes((69,)) * (
            LOGO_WIDTH_BYTES
        )

    draw_walking_hero(preview, load_player_walk_frame())
    draw_preview_stars(preview)
    return render_screen(preview)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument(
        "--background-preview",
        type=Path,
        default=DEFAULT_BACKGROUND_PREVIEW,
    )
    parser.add_argument("--preview", type=Path, default=DEFAULT_PREVIEW)
    parser.add_argument("--screen", type=Path, default=DEFAULT_SCREEN)
    parser.add_argument(
        "--compressed",
        type=Path,
        default=DEFAULT_COMPRESSED,
    )
    parser.add_argument("--logo", type=Path, default=DEFAULT_LOGO)
    args = parser.parse_args()

    background = compose_background(Image.open(args.input))
    screen, _ = convert(background)
    screen = force_worm_bright(screen)
    background_preview = render_screen(screen)
    logo, _ = generate_logo()
    if len(screen) != 6912:
        raise AssertionError(f"expected 6912 screen bytes, got {len(screen)}")
    if len(logo) != LOGO_WIDTH_BYTES * LOGO_HEIGHT:
        raise AssertionError(f"unexpected logo size: {len(logo)}")

    # The logo decompresses immediately after VRAM at 0x5B00, still below code.
    decompressed = screen + logo
    compressed = compress_lzss(decompressed)
    if decompress_lzss(compressed, len(decompressed)) != decompressed:
        raise AssertionError("compressed title data did not round-trip")

    runtime_preview = create_runtime_preview(screen, logo)
    for path in (
        args.background_preview,
        args.preview,
        args.screen,
        args.compressed,
        args.logo,
    ):
        path.parent.mkdir(parents=True, exist_ok=True)

    background_preview.save(args.background_preview)
    runtime_preview.save(args.preview)
    args.screen.write_bytes(screen)
    args.compressed.write_bytes(compressed)
    args.logo.write_bytes(logo)
    print(
        f"wrote {args.background_preview} "
        f"({background_preview.width}x{background_preview.height}, no text)"
    )
    print(
        f"wrote {args.preview} "
        f"({runtime_preview.width}x{runtime_preview.height}, runtime composite)"
    )
    print(f"wrote {args.screen} ({len(screen)} background bytes)")
    print(f"wrote {args.logo} ({len(logo)} runtime logo bytes)")
    print(
        f"wrote {args.compressed} "
        f"({len(compressed)} bytes, {100 * len(compressed) // len(decompressed)}%)"
    )


if __name__ == "__main__":
    main()
