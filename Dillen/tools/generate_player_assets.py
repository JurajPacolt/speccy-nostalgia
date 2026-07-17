"""Generate Dillen's 16x24 ZX Spectrum sprites, masks, and previews."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASM_PATH = ROOT / "src" / "player_sprites.asm"
GFX_PATH = ROOT / "gfx"

TRANSPARENT = " "
INK = "#"
PAPER = "."
FRAME_WIDTH = 16
FRAME_HEIGHT = 24
SCALE = 6


def frame(*rows: str) -> tuple[str, ...]:
    if len(rows) != FRAME_HEIGHT:
        raise ValueError(f"expected {FRAME_HEIGHT} rows, got {len(rows)}")
    if any(len(row) != FRAME_WIDTH for row in rows):
        bad = [(index, len(row)) for index, row in enumerate(rows) if len(row) != FRAME_WIDTH]
        raise ValueError(f"every row must be {FRAME_WIDTH} pixels wide: {bad}")
    if any(set(row) - {TRANSPARENT, INK, PAPER} for row in rows):
        raise ValueError("frames may contain only spaces, '#', and '.'")
    return rows


def mirror(rows: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(row[::-1] for row in rows)


IDLE_0 = frame(
    "       ..       ",
    "      .##.      ",
    "    ...##...    ",
    "   .########.   ",
    "   .#......#.   ",
    "   .#.####.#.   ",
    "   .#.#..#.#.   ",
    "   .#.####.#.   ",
    "    .#....#.    ",
    "     ......     ",
    "    .######.    ",
    "   .########.   ",
    "  .##.####.##.  ",
    "  .##.####.##.  ",
    "   .########.   ",
    "    .######.    ",
    "    .##..##.    ",
    "    .##..##.    ",
    "   .###..###.   ",
    "   .###..###.   ",
    "  .####..####.  ",
    "  ......  ......",
    "                ",
    "                ",
)

IDLE_BREATHE = frame(
    "                ",
    "       ..       ",
    "      .##.      ",
    "    ...##...    ",
    "   .########.   ",
    "   .#......#.   ",
    "   .#.####.#.   ",
    "   .#.#..#.#.   ",
    "   .#.####.#.   ",
    "    .#....#.    ",
    "    ..####..    ",
    "   .########.   ",
    "  .##########.  ",
    " .###.####.###. ",
    " .###.####.###. ",
    "  .##########.  ",
    "   .###..###.   ",
    "   .###..###.   ",
    "   .###..###.   ",
    "  .####..####.  ",
    "  .####..####.  ",
    "  ......  ......",
    "                ",
    "                ",
)

IDLE_BLINK = frame(
    "       ..       ",
    "      .##.      ",
    "    ...##...    ",
    "   .########.   ",
    "   .#......#.   ",
    "   .#.####.#.   ",
    "   .#......#.   ",
    "   .#.####.#.   ",
    "    .#....#.    ",
    "     ......     ",
    "    .######.    ",
    "   .########.   ",
    "  .##.####.##.  ",
    "  .##.####.##.  ",
    "   .########.   ",
    "    .######.    ",
    "    .##..##.    ",
    "    .##..##.    ",
    "   .###..###.   ",
    "   .###..###.   ",
    "  .####..####.  ",
    "  ......  ......",
    "                ",
    "                ",
)

IDLE_YAWN = frame(
    "       ..       ",
    "      .##.      ",
    "    ...##...    ",
    "   .########.   ",
    "   .#......#.   ",
    "   .#.####.#.   ",
    "   .#......#.   ",
    "   .#..##..#.   ",
    "    .#.##.#.    ",
    "     ......     ",
    "    .######.    ",
    "   .########.   ",
    "  .##.####.##.  ",
    " .###.####.###. ",
    " .##.######.##. ",
    "  .##########.  ",
    "   .###..###.   ",
    "   .###..###.   ",
    "   .###..###.   ",
    "  .####..####.  ",
    "  .####..####.  ",
    "  ......  ......",
    "                ",
    "                ",
)

def side_frame(phase: int, jumping: bool = False) -> tuple[str, ...]:
    """Build a compact right-facing pose; phases change arms, legs, and scarf."""
    grid = [[TRANSPARENT for _ in range(FRAME_WIDTH)] for _ in range(FRAME_HEIGHT)]

    def put(x: int, y: int, value: str) -> None:
        if 0 <= x < FRAME_WIDTH and 0 <= y < FRAME_HEIGHT:
            grid[y][x] = value

    def box(x0: int, y0: int, x1: int, y1: int, fill: str = INK) -> None:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                put(x, y, fill)

    # Helmet, lamp, face, nose, and backpack create a readable direction.
    box(7, 0, 8, 0, PAPER)
    box(6, 1, 9, 2, PAPER)
    box(7, 1, 8, 1, INK)
    box(4, 3, 11, 3, PAPER)
    box(5, 3, 10, 3, INK)
    box(4, 4, 11, 8, PAPER)
    box(5, 4, 10, 7, INK)
    put(9, 5, PAPER)
    put(11, 6, INK)
    put(12, 6, PAPER)
    put(10, 8, INK)
    box(2, 10, 5, 16, PAPER)
    box(3, 11, 5, 15, INK)
    box(5, 10, 11, 17, PAPER)
    box(6, 10, 10, 16, INK)
    # Scarf tail follows motion.
    scarf_y = 10 + (phase & 1)
    put(11, 10, PAPER)
    put(12, scarf_y, INK)
    put(13, scarf_y, PAPER)
    put(13, scarf_y + 1, INK)
    put(14, scarf_y + 1, PAPER)

    if jumping:
        # Arms high and knees tucked.
        for x, y in ((5, 11), (4, 10), (3, 9), (11, 11), (12, 10), (13, 9)):
            put(x, y, PAPER)
        for x, y in ((4, 10), (12, 10)):
            put(x, y, INK)
        box(5, 17, 8, 19, PAPER)
        box(6, 17, 7, 18, INK)
        box(9, 16, 12, 18, PAPER)
        box(9, 16, 11, 17, INK)
        box(3, 19, 7, 21, PAPER)
        box(4, 19, 7, 20, INK)
        box(11, 18, 14, 20, PAPER)
        box(11, 18, 13, 19, INK)
    else:
        # Alternating arms.
        arm_sets = (
            ((4, 12), (3, 13), (2, 14), (11, 12), (12, 11)),
            ((4, 12), (3, 11), (2, 10), (11, 12), (12, 13), (13, 14)),
            ((4, 12), (3, 13), (11, 12), (12, 13)),
            ((4, 12), (3, 11), (11, 12), (12, 11)),
        )
        for x, y in arm_sets[phase]:
            put(x, y, PAPER)
            put(x + (1 if x < 5 else -1), y, INK)

        # Four walk contacts: stride, passing, opposite stride, passing.
        legs = (
            ((5, 17, 7, 21), (9, 17, 13, 20)),
            ((6, 17, 8, 21), (9, 17, 11, 22)),
            ((3, 17, 7, 20), (9, 17, 11, 21)),
            ((5, 17, 7, 22), (8, 17, 10, 21)),
        )
        for x0, y0, x1, y1 in legs[phase]:
            box(x0, y0, x1, y1, PAPER)
            if x1 - x0 >= 2 and y1 - y0 >= 2:
                box(x0 + 1, y0, x1, y1 - 1, INK)

    return tuple("".join(row) for row in grid)


JUMP_UP = frame(
    "       ..       ",
    "      .##.      ",
    "    ...##...    ",
    "   .########.   ",
    "   .#......#.   ",
    "   .#.####.#.   ",
    "   .#.#..#.#.   ",
    "   .#.####.#.   ",
    "    .#....#.    ",
    "  .. ...... ..  ",
    " .##.######.##. ",
    ".###.######.###.",
    ".##..######..##.",
    " .. .######. .. ",
    "    .######.    ",
    "   .###..###.   ",
    "  .###.  .###.  ",
    " .###.    .###. ",
    " .##.      .##. ",
    "  ..        ..  ",
    "                ",
    "                ",
    "                ",
    "                ",
)


FRAMES = {
    "Idle0": IDLE_0,
    "IdleBreathe": IDLE_BREATHE,
    "IdleBlink": IDLE_BLINK,
    "IdleYawn": IDLE_YAWN,
    "WalkRight0": side_frame(0),
    "WalkRight1": side_frame(1),
    "WalkRight2": side_frame(2),
    "WalkRight3": side_frame(3),
    "WalkLeft0": mirror(side_frame(0)),
    "WalkLeft1": mirror(side_frame(1)),
    "WalkLeft2": mirror(side_frame(2)),
    "WalkLeft3": mirror(side_frame(3)),
    "JumpUp": JUMP_UP,
    "JumpRight": side_frame(1, jumping=True),
    "JumpLeft": mirror(side_frame(1, jumping=True)),
}


def row_bytes(row: str, mask: bool) -> tuple[int, int]:
    values = []
    for start in (0, 8):
        value = 0
        for char in row[start : start + 8]:
            value <<= 1
            if mask:
                value |= int(char == TRANSPARENT)
            else:
                value |= int(char == INK)
        values.append(value)
    return values[0], values[1]


def emit_asm() -> None:
    lines = [
        "; Generated by tools/generate_player_assets.py. Do not edit by hand.",
        "; Each 16x24 frame has a bitmap followed by a background-preserving mask.",
        "",
        "PLAYER_SPRITE_WIDTH_BYTES equ 2",
        "PLAYER_SPRITE_HEIGHT      equ 24",
        "",
    ]
    for name, rows in FRAMES.items():
        bitmap = [value for row in rows for value in row_bytes(row, mask=False)]
        mask = [value for row in rows for value in row_bytes(row, mask=True)]
        lines.extend((f"PlayerSprite{name}:", "        defb    " + ", ".join(map(str, bitmap)), ""))
        lines.extend((f"PlayerMask{name}:", "        defb    " + ", ".join(map(str, mask)), ""))

    lines.extend(
        (
            "PlayerIdleSpriteFrames:",
            "        defw    PlayerSpriteIdle0, PlayerSpriteIdleBreathe, PlayerSpriteIdleBlink, PlayerSpriteIdleYawn",
            "PlayerIdleMaskFrames:",
            "        defw    PlayerMaskIdle0, PlayerMaskIdleBreathe, PlayerMaskIdleBlink, PlayerMaskIdleYawn",
            "",
            "PlayerWalkRightSpriteFrames:",
            "        defw    PlayerSpriteWalkRight0, PlayerSpriteWalkRight1, PlayerSpriteWalkRight2, PlayerSpriteWalkRight3",
            "PlayerWalkRightMaskFrames:",
            "        defw    PlayerMaskWalkRight0, PlayerMaskWalkRight1, PlayerMaskWalkRight2, PlayerMaskWalkRight3",
            "",
            "PlayerWalkLeftSpriteFrames:",
            "        defw    PlayerSpriteWalkLeft0, PlayerSpriteWalkLeft1, PlayerSpriteWalkLeft2, PlayerSpriteWalkLeft3",
            "PlayerWalkLeftMaskFrames:",
            "        defw    PlayerMaskWalkLeft0, PlayerMaskWalkLeft1, PlayerMaskWalkLeft2, PlayerMaskWalkLeft3",
            "",
        )
    )
    ASM_PATH.write_text("\n".join(lines), encoding="ascii")


def render_frame(rows: tuple[str, ...], scale: int = SCALE) -> Image.Image:
    image = Image.new("RGBA", (FRAME_WIDTH * scale, FRAME_HEIGHT * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for y, row in enumerate(rows):
        for x, value in enumerate(row):
            if value == TRANSPARENT:
                continue
            color = (255, 232, 64, 255) if value == INK else (8, 12, 18, 255)
            draw.rectangle((x * scale, y * scale, (x + 1) * scale - 1, (y + 1) * scale - 1), fill=color)
    return image


def checker(size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGBA", size, (22, 27, 34, 255))
    draw = ImageDraw.Draw(image)
    tile = 12
    for y in range(0, size[1], tile):
        for x in range(0, size[0], tile):
            if (x // tile + y // tile) & 1:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(28, 35, 44, 255))
    return image


def emit_sheet() -> None:
    names = list(FRAMES)
    columns = 4
    cell_w, cell_h = FRAME_WIDTH * SCALE + 24, FRAME_HEIGHT * SCALE + 34
    rows = (len(names) + columns - 1) // columns
    sheet = checker((columns * cell_w, rows * cell_h))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, name in enumerate(names):
        x = (index % columns) * cell_w + 12
        y = (index // columns) * cell_h + 20
        sheet.alpha_composite(render_frame(FRAMES[name]), (x, y))
        draw.text((x, 4 + (index // columns) * cell_h), name, fill=(230, 235, 240, 255), font=font)
    sheet.convert("RGB").save(GFX_PATH / "player-spritesheet.png")

    mask_sheet = Image.new("RGB", sheet.size, (32, 32, 32))
    mask_draw = ImageDraw.Draw(mask_sheet)
    for index, (name, sprite) in enumerate(FRAMES.items()):
        ox = (index % columns) * cell_w + 12
        oy = (index // columns) * cell_h + 20
        mask_draw.text((ox, 4 + (index // columns) * cell_h), name, fill=(230, 235, 240), font=font)
        for y, row in enumerate(sprite):
            for x, value in enumerate(row):
                color = (255, 255, 255) if value == TRANSPARENT else (0, 0, 0)
                mask_draw.rectangle(
                    (ox + x * SCALE, oy + y * SCALE, ox + (x + 1) * SCALE - 1, oy + (y + 1) * SCALE - 1),
                    fill=color,
                )
    mask_sheet.save(GFX_PATH / "player-masks.png")


def save_gif(path: Path, images: list[Image.Image], durations: list[int]) -> None:
    images[0].save(
        path,
        save_all=True,
        append_images=images[1:],
        duration=durations,
        disposal=2,
        loop=0,
        optimize=False,
    )


def emit_previews() -> None:
    idle_names = ["Idle0"] * 7 + ["IdleBreathe", "Idle0"] + ["Idle0"] * 5 + ["IdleBlink", "Idle0"] + ["Idle0"] * 8 + ["IdleYawn", "IdleYawn", "Idle0"]
    idle_images = []
    for name in idle_names:
        canvas = checker((128, 176))
        canvas.alpha_composite(render_frame(FRAMES[name]), (16, 16))
        idle_images.append(canvas.convert("P", palette=Image.Palette.ADAPTIVE))
    save_gif(GFX_PATH / "player-idle.gif", idle_images, [100] * len(idle_images))

    walk_images = []
    walk_sequence = [(f"WalkRight{i % 4}", 8 + i * 4) for i in range(28)]
    walk_sequence += [(f"WalkLeft{i % 4}", 116 - i * 4) for i in range(28)]
    for name, x in walk_sequence:
        canvas = checker((240, 176))
        draw = ImageDraw.Draw(canvas)
        draw.rectangle((0, 160, 239, 175), fill=(90, 72, 52, 255))
        canvas.alpha_composite(render_frame(FRAMES[name]), (x, 16))
        walk_images.append(canvas.convert("P", palette=Image.Palette.ADAPTIVE))
    save_gif(GFX_PATH / "player-walk.gif", walk_images, [55] * len(walk_images))

    jump_images = []
    arcs = (("JumpUp", 72, 0), ("JumpLeft", 160, -4), ("JumpRight", 8, 4))
    arc_y = (16, 0, -12, -22, -30, -34, -36, -34, -30, -22, -12, 0, 16)
    for name, start_x, dx in arcs:
        for index, offset_y in enumerate(arc_y):
            canvas = checker((240, 192))
            draw = ImageDraw.Draw(canvas)
            draw.rectangle((0, 176, 239, 191), fill=(90, 72, 52, 255))
            x = start_x + dx * index
            canvas.alpha_composite(render_frame(FRAMES[name]), (x, 16 + offset_y))
            jump_images.append(canvas.convert("P", palette=Image.Palette.ADAPTIVE))
    save_gif(GFX_PATH / "player-jump.gif", jump_images, [70] * len(jump_images))


if __name__ == "__main__":
    GFX_PATH.mkdir(parents=True, exist_ok=True)
    emit_asm()
    emit_sheet()
    emit_previews()
    print(f"Generated {len(FRAMES)} player frames in {ASM_PATH.relative_to(ROOT)} and {GFX_PATH.relative_to(ROOT)}")
