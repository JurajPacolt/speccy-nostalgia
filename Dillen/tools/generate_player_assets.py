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
MASK_OUTLINE_RADIUS = 1
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


def canvas() -> list[list[str]]:
    return [[TRANSPARENT for _ in range(FRAME_WIDTH)] for _ in range(FRAME_HEIGHT)]


def put(grid: list[list[str]], x: int, y: int, value: str = INK) -> None:
    if 0 <= x < FRAME_WIDTH and 0 <= y < FRAME_HEIGHT:
        grid[y][x] = value


def span(grid: list[list[str]], y: int, x0: int, x1: int, value: str = INK) -> None:
    for x in range(x0, x1 + 1):
        put(grid, x, y, value)


def finish(grid: list[list[str]]) -> tuple[str, ...]:
    return frame(*("".join(row) for row in grid))


def shifted(rows: tuple[str, ...], dx: int, dy: int) -> tuple[str, ...]:
    grid = canvas()
    for y, row in enumerate(rows):
        for x, value in enumerate(row):
            if value != TRANSPARENT:
                put(grid, x + dx, y + dy, value)
    return finish(grid)


def outline_mask(rows: tuple[str, ...]) -> tuple[str, ...]:
    """Expand opaque pixels so the mask clears a dark rim around the sprite."""
    grid = canvas()
    for y, row in enumerate(rows):
        for x, value in enumerate(row):
            if value == TRANSPARENT:
                continue
            for offset_y in range(-MASK_OUTLINE_RADIUS, MASK_OUTLINE_RADIUS + 1):
                for offset_x in range(-MASK_OUTLINE_RADIUS, MASK_OUTLINE_RADIUS + 1):
                    put(grid, x + offset_x, y + offset_y, PAPER)
    return finish(grid)


def draw_front_head(
    grid: list[list[str]], top: int, blink: bool = False, surprised: bool = False
) -> None:
    """Draw the worm's antennae and large front-facing comic head."""
    put(grid, 4, top)
    put(grid, 11, top)
    put(grid, 5, top + 1)
    put(grid, 10, top + 1)
    put(grid, 5, top + 2)
    put(grid, 10, top + 2)
    span(grid, top + 3, 4, 11)
    span(grid, top + 4, 3, 12)
    span(grid, top + 5, 2, 13)
    span(grid, top + 6, 2, 13)
    span(grid, top + 7, 1, 14)
    span(grid, top + 8, 2, 13)
    span(grid, top + 9, 3, 12)
    span(grid, top + 10, 4, 11)

    if blink:
        span(grid, top + 6, 4, 5, PAPER)
        span(grid, top + 6, 10, 11, PAPER)
    else:
        for y in (top + 5, top + 6):
            span(grid, y, 4, 5, PAPER)
            span(grid, y, 10, 11, PAPER)

    if surprised:
        span(grid, top + 8, 7, 8, PAPER)
        span(grid, top + 9, 7, 8, PAPER)
    else:
        put(grid, 5, top + 8, PAPER)
        put(grid, 10, top + 8, PAPER)
        span(grid, top + 9, 6, 9, PAPER)


def front_idle(blink: bool = False) -> tuple[str, ...]:
    grid = canvas()
    draw_front_head(grid, 3, blink=blink)

    # The broad head narrows into a segmented S-shaped body and tapered tail.
    spans = (
        (14, 4, 11),
        (15, 3, 12),
        (16, 2, 13),
        (17, 3, 12),
        (18, 4, 11),
        (19, 3, 11),
        (20, 2, 10),
        (21, 2, 12),
        (22, 6, 14),
    )
    for y, x0, x1 in spans:
        span(grid, y, x0, x1)
    span(grid, 17, 6, 9, PAPER)
    span(grid, 20, 5, 7, PAPER)
    span(grid, 22, 8, 10, PAPER)
    return finish(grid)


def front_squash() -> tuple[str, ...]:
    grid = canvas()
    draw_front_head(grid, 5, surprised=True)
    spans = (
        (16, 2, 13),
        (17, 1, 14),
        (18, 2, 13),
        (19, 3, 12),
        (20, 2, 11),
        (21, 4, 14),
        (22, 7, 14),
    )
    for y, x0, x1 in spans:
        span(grid, y, x0, x1)
    span(grid, 18, 6, 9, PAPER)
    span(grid, 21, 8, 10, PAPER)
    return finish(grid)


IDLE_0 = front_idle()
IDLE_BLINK = front_idle(blink=True)
IDLE_HOP_SQUASH = front_squash()
IDLE_HOP_AIR = shifted(IDLE_0, 0, -2)


def draw_side_head(grid: list[list[str]], top: int) -> None:
    """Draw the right-facing head; left-facing frames are mirrored."""
    put(grid, 9, top)
    put(grid, 12, top)
    put(grid, 9, top + 1)
    put(grid, 11, top + 1)
    put(grid, 10, top + 2)
    put(grid, 11, top + 2)
    span(grid, top + 3, 7, 12)
    span(grid, top + 4, 6, 13)
    span(grid, top + 5, 5, 13)
    span(grid, top + 6, 5, 14)
    span(grid, top + 7, 6, 13)
    span(grid, top + 8, 6, 13)
    span(grid, top + 9, 7, 12)
    span(grid, top + 10, 7, 11)

    span(grid, top + 5, 10, 11, PAPER)
    span(grid, top + 6, 10, 11, PAPER)
    put(grid, 12, top + 8, PAPER)
    put(grid, 11, top + 9, PAPER)


def side_walk(phase: int) -> tuple[str, ...]:
    """Four peristaltic crawl poses with a bobbing head and travelling body wave."""
    grid = canvas()
    head_top = (1, 2, 1, 2)[phase]
    draw_side_head(grid, head_top)
    centers = (
        (9, 8, 7, 6, 5, 5, 6, 7, 8, 7, 5),
        (9, 8, 7, 6, 6, 7, 8, 9, 8, 6, 3),
        (9, 8, 8, 7, 7, 6, 5, 4, 5, 7, 9),
        (9, 8, 7, 6, 5, 4, 4, 5, 6, 5, 3),
    )[phase]
    widths = (4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 2)
    for y, (center, width) in enumerate(zip(centers, widths), start=11):
        span(grid, y, center - width, center + width)

    # Dark joints make the curved body read as a worm rather than a solid tail.
    for y, offset in ((13, 0), (16, -1), (19, 1)):
        center = centers[y - 11]
        span(grid, y, center + offset, center + offset + 1, PAPER)
    return finish(grid)


def jump_up(pose: int) -> tuple[str, ...]:
    grid = canvas()
    top = (1, 1, 4)[pose]
    draw_front_head(grid, top, surprised=True)
    body_spans = (
        (
            (11, 5, 10),
            (12, 4, 11),
            (13, 5, 10),
            (14, 4, 10),
            (15, 3, 9),
            (16, 4, 10),
            (17, 5, 11),
            (18, 6, 12),
            (19, 7, 12),
            (20, 8, 13),
            (21, 10, 14),
        ),
        (
            (11, 3, 12),
            (12, 2, 13),
            (13, 2, 13),
            (14, 3, 12),
            (15, 4, 11),
            (16, 3, 12),
            (17, 2, 11),
            (18, 3, 13),
        ),
        (
            (14, 3, 12),
            (15, 2, 13),
            (16, 1, 14),
            (17, 2, 13),
            (18, 3, 12),
            (19, 2, 11),
            (20, 4, 14),
            (21, 7, 14),
        ),
    )[pose]
    for y, x0, x1 in body_spans:
        span(grid, y, x0, x1)
    joint_rows = (14, 14, 17)
    y = joint_rows[pose]
    span(grid, y, 6, 9, PAPER)
    return finish(grid)


def jump_side(pose: int) -> tuple[str, ...]:
    grid = canvas()
    head_top = (1, 3, 5)[pose]
    draw_side_head(grid, head_top)
    body_shapes = (
        (
            (11, 9, 4),
            (12, 8, 4),
            (13, 7, 4),
            (14, 6, 4),
            (15, 5, 3),
            (16, 4, 3),
            (17, 4, 3),
            (18, 5, 3),
            (19, 6, 3),
            (20, 5, 3),
            (21, 3, 2),
        ),
        (
            (13, 9, 4),
            (14, 8, 4),
            (15, 7, 4),
            (16, 6, 4),
            (17, 6, 3),
            (18, 7, 3),
            (19, 8, 3),
            (20, 6, 3),
        ),
        (
            (15, 9, 4),
            (16, 8, 4),
            (17, 7, 4),
            (18, 6, 4),
            (19, 5, 4),
            (20, 6, 4),
            (21, 8, 4),
        ),
    )[pose]
    for y, center, width in body_shapes:
        span(grid, y, center - width, center + width)
    joint_y = (14, 16, 18)[pose]
    span(grid, joint_y, 6, 7, PAPER)
    return finish(grid)


FRAMES = {
    "Idle0": IDLE_0,
    "IdleBlink": IDLE_BLINK,
    "IdleHopSquash": IDLE_HOP_SQUASH,
    "IdleHopAir": IDLE_HOP_AIR,
    "WalkRight0": side_walk(0),
    "WalkRight1": side_walk(1),
    "WalkRight2": side_walk(2),
    "WalkRight3": side_walk(3),
    "WalkLeft0": mirror(side_walk(0)),
    "WalkLeft1": mirror(side_walk(1)),
    "WalkLeft2": mirror(side_walk(2)),
    "WalkLeft3": mirror(side_walk(3)),
    "JumpUpRise": jump_up(0),
    "JumpUpCurl": jump_up(1),
    "JumpUpFall": jump_up(2),
    "JumpRightRise": jump_side(0),
    "JumpRightCurl": jump_side(1),
    "JumpRightFall": jump_side(2),
    "JumpLeftRise": mirror(jump_side(0)),
    "JumpLeftCurl": mirror(jump_side(1)),
    "JumpLeftFall": mirror(jump_side(2)),
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
        "; Each 16x24 bitmap is followed by a mask with a one-pixel dark outline.",
        "",
        "PLAYER_SPRITE_WIDTH_BYTES equ 2",
        "PLAYER_SPRITE_HEIGHT      equ 24",
        "",
    ]
    for name, rows in FRAMES.items():
        bitmap = [value for row in rows for value in row_bytes(row, mask=False)]
        mask_rows = outline_mask(rows)
        mask = [value for row in mask_rows for value in row_bytes(row, mask=True)]
        lines.extend((f"PlayerSprite{name}:", "        defb    " + ", ".join(map(str, bitmap)), ""))
        lines.extend((f"PlayerMask{name}:", "        defb    " + ", ".join(map(str, mask)), ""))

    lines.extend(
        (
            "PlayerIdleSpriteFrames:",
            "        defw    PlayerSpriteIdle0, PlayerSpriteIdleBlink, PlayerSpriteIdleHopSquash, PlayerSpriteIdleHopAir",
            "PlayerIdleMaskFrames:",
            "        defw    PlayerMaskIdle0, PlayerMaskIdleBlink, PlayerMaskIdleHopSquash, PlayerMaskIdleHopAir",
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
            "PlayerJumpUpSpriteFrames:",
            "        defw    PlayerSpriteJumpUpRise, PlayerSpriteJumpUpCurl, PlayerSpriteJumpUpFall",
            "PlayerJumpUpMaskFrames:",
            "        defw    PlayerMaskJumpUpRise, PlayerMaskJumpUpCurl, PlayerMaskJumpUpFall",
            "",
            "PlayerJumpRightSpriteFrames:",
            "        defw    PlayerSpriteJumpRightRise, PlayerSpriteJumpRightCurl, PlayerSpriteJumpRightFall",
            "PlayerJumpRightMaskFrames:",
            "        defw    PlayerMaskJumpRightRise, PlayerMaskJumpRightCurl, PlayerMaskJumpRightFall",
            "",
            "PlayerJumpLeftSpriteFrames:",
            "        defw    PlayerSpriteJumpLeftRise, PlayerSpriteJumpLeftCurl, PlayerSpriteJumpLeftFall",
            "PlayerJumpLeftMaskFrames:",
            "        defw    PlayerMaskJumpLeftRise, PlayerMaskJumpLeftCurl, PlayerMaskJumpLeftFall",
            "",
        )
    )
    ASM_PATH.write_text("\n".join(lines), encoding="ascii")


def render_frame(rows: tuple[str, ...], scale: int = SCALE) -> Image.Image:
    image = Image.new("RGBA", (FRAME_WIDTH * scale, FRAME_HEIGHT * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for y, row in enumerate(outline_mask(rows)):
        for x, value in enumerate(row):
            if value != TRANSPARENT:
                draw.rectangle(
                    (x * scale, y * scale, (x + 1) * scale - 1, (y + 1) * scale - 1),
                    fill=(8, 12, 18, 255),
                )
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
        for y, row in enumerate(outline_mask(sprite)):
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
    idle_names = (
        ["Idle0"] * 7
        + ["IdleBlink", "Idle0"]
        + ["Idle0"] * 7
        + ["IdleHopSquash", "IdleHopAir", "IdleHopAir", "IdleHopSquash", "Idle0"]
    )
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
    jump_poses = ("Rise", "Rise", "Rise", "Rise", "Curl", "Curl", "Curl", "Curl", "Fall", "Fall", "Fall", "Fall", "Fall")
    for direction, start_x, dx in arcs:
        for index, offset_y in enumerate(arc_y):
            canvas = checker((240, 192))
            draw = ImageDraw.Draw(canvas)
            draw.rectangle((0, 176, 239, 191), fill=(90, 72, 52, 255))
            x = start_x + dx * index
            name = direction + jump_poses[index]
            canvas.alpha_composite(render_frame(FRAMES[name]), (x, 16 + offset_y))
            jump_images.append(canvas.convert("P", palette=Image.Palette.ADAPTIVE))
    save_gif(GFX_PATH / "player-jump.gif", jump_images, [70] * len(jump_images))


if __name__ == "__main__":
    GFX_PATH.mkdir(parents=True, exist_ok=True)
    emit_asm()
    emit_sheet()
    emit_previews()
    print(f"Generated {len(FRAMES)} player frames in {ASM_PATH.relative_to(ROOT)} and {GFX_PATH.relative_to(ROOT)}")
