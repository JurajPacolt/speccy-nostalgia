# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Dillen ("Escape from underground") is a ZX Spectrum 128 game in Z80 assembly, built with SjASMPlus. It is a nostalgia project based on room layouts the author drew on paper as a teenager (`gfx/dillen-map.gif`).

## Build

```powershell
sjasmplus -Isrc src/main.asm     # run from the repo root
```

A successful build rewrites `Dillen.sna` (gitignored) at the repo root. `build_and_run.bat` builds and launches SpecEmu; `build.sh` / `build_and_run.sh` run the same assembler through Wine on Unix (`build_and_run.sh` has a hard-coded SjASMPlus path that likely needs updating).

The assembler on PATH is SjASMPlus **1.23.1**. Note that the scripts (`build.bat` and friends) still pass `main.asm` and rely on the `-I` include path to find it — 1.07 resolved the top-level source that way, 1.23 does not, so **the scripts fail with `error: opening file: main.asm`** until their path is spelled out. Build by hand with the command above, or fix the scripts.

There is no test suite. Verification means: the build reports 0 errors, then you exercise the affected rooms, controls, graphics, and audio in an emulator. Test both keyboard and Kempston paths when touching input.

## Regenerating player art

`src/player_sprites.asm` is generated — never hand-edit it. Frames are authored as ASCII art in `tools/generate_player_assets.py` (`#` = ink, `.` = paper/outline, space = transparent), which emits the bitmaps, their masks, and the `gfx/player-*.png|gif` previews:

```powershell
py -3 .\tools\generate_player_assets.py    # needs Pillow
```

## Memory map

- Code and data assemble from `org 25000` upward.
- `ay_music.asm` ends with a hard `org 0xBE00` for the IM2 vector table (257 bytes of `0xBF`) and `org 0xBFBF` for the handler. **Code must not grow past 0xBE00** — the assembler will silently overlay it rather than warn.
- Screen: the top 4 character rows are the info panel (`16384` / attrs `22528`); the game field is 30x18 characters starting at row 4 (`16384+32*4`), with a 1-character border drawn by `game_field.asm`.

## Architecture

`main.asm` is the entry point: it disables interrupts, clears the screen, draws the border and panel, installs the IM2 music handler, then jumps to `GameMainLoop`. It also holds the include list — **new modules must be added there**, and include order defines the link order. (`player_sprites.asm` is the exception: it is included from the bottom of `player.asm`.)

### Main loop ordering is load-bearing

`game.asm` calls, once per frame, ending in `halt`:

```
ShowRoom → ShowGamePanel → TorchesInRooms → ItemsInRooms → StarOnBackground
         → AnimationsInRooms → PlayerUpdate → PlayerRender → ScanCursorKeysForRoomSwitch
```

Torches must run before the stars so the stars know where the fire is; items must be placed before the stars look for free cells. The player renders last, over everything. Reordering these breaks the scenery.

### Room map index vs. room ID — the most common source of confusion

Two different numbers are in play:

- `ActualRoomInMap` is an **index into `RoomsMap`**, a 9x5 grid (`ROOMS_MAP_WIDTH equ 9`) where `255` marks an impassable wall and `0` a blank room. Navigation arithmetic (±1, ±`ROOMS_MAP_WIDTH`) happens on this index.
- The **room ID** is `RoomsMap[ActualRoomInMap]` (0..11), and it indexes `Rooms` (sprite lists), `_GP_RoomTexts` (panel descriptions), and the dispatch in `AnimationsInRooms`.

Modules that only ask "did the room change?" compare `ActualRoomInMap` directly; modules that need room identity do the `RoomsMap` lookup first. `StartRoomInMap equ 013` is a map index, not an ID.

Adding a room means updating three tables in sync: `RoomsMap` and `Rooms` in `rooms.asm`, `_GP_RoomTexts` (plus `PANEL_ROOMS_COUNT`) in `game_info_panel.asm`, and a dispatch entry in `AnimationsInRooms` if it animates.

### The dirty-room pattern

Every room-scoped module caches the last room it drew and returns early when nothing changed — `LastShowedRoomInMap` (rooms), `_ItemsDrawnMapRoom`, `_TIR_Room` (torches), `_Death_room`, `PlayerDrawnRoom`. Static content is drawn once on entry; only animation ticks run per frame. New room-scoped modules should follow this, and must expose a `Reset*` routine called from `ResetGame`.

### Sprites and the attribute cache

A sprite is `defb width_in_characters, height_in_pixel_lines`, then bitmap bytes, then attribute bytes. `sprite_utils.asm` provides `DrawSprite` (bitmap + own attributes), `DrawSpriteWithCustomColor` (bitmap + one flat attribute in `A`), and `DrawSpriteWithoutAttrs` (ORs the bitmap in, leaving attributes alone), plus `ScreenAddr`, `AttrAddr`, `DownHL`/`DownDE`.

`DE` passed to the draw routines is the **attribute destination**, and this is the subtle part: `ShowRoom` points it at `RoomsAttrCache` (a 768-byte shadow buffer) so overlapping room sprites compose off-screen, then blits rows 5..22 into real attribute memory in one pass. Items instead pass `22528` and write attributes straight to the screen. Follow whichever convention matches when you draw.

Room definitions are 5-byte records — `defb X_pixels, Y_pixels, attr` then `defw sprite_address` — terminated by a **zero X byte**. A sprite therefore cannot sit at X=0.

### Player

`player.asm` owns a 16x24 masked sprite. It saves the 3x24 bytes of background under itself (`PlayerBackground`), pre-shifts bitmap and mask to the sub-character X offset (`PlayerShiftedBitmap`/`PlayerShiftedMask`), and composites with `AND mask` / `OR bitmap`. `PlayerRender` picks one of three paths — full erase-and-redraw on movement, redraw-over-saved-background on animation change, or idempotent re-overlay when nothing changed — so scenery drawn later in the frame can never hide the player and idle frames don't flicker.

Collision **reads the screen back** rather than consulting a map — a room is only a picture, there is nothing else to ask. Everything funnels through `PlayerPixelSolid` (is one pixel terrain?), which is where the material rule lives:

- **Ink is the material table.** Green (`PLAYER_INK_GRASS`, 4) is grass and white (`PLAYER_INK_SCENERY`, 7) is sky/clouds/stars/the bridge railing; both are walked through. Everything else with a pixel set carries the player. Room artwork colour is therefore gameplay — the bridge railing is only passable because it is painted white.
- `PLAYER_FLOOR_Y` (160) is solid regardless of artwork, so the noisy stone floor has no holes to fall through.

Because every room sprite sits on the attribute grid, **the walking surface is always the top line of an attribute cell**, and the player always stands on one (landing snaps to it). That makes one attribute (8px) the natural step: `PlayerWalkStep` reads only the 2-pixel strip his step uncovers ahead of him, and one cell up is a step he walks, two cells up is a wall he must jump. The blocks flanking the old bridge are stacked exactly one attribute apart for this. Falling off is decided separately by `PlayerFootingSolid`, which asks whether *any* pixel under the full 16-pixel footprint carries him — that "any" is what keeps the deliberately sparse bridge artwork walkable.

The probes never read the player's own frame, which is still on screen during `PlayerUpdate` (he is drawn last and erased inside `PlayerRender`). That constraint is why the step-up probe uses the uncovered strip instead of the whole footprint, and why a step up does not re-check its footing.

Jumping is a 17-entry `PlayerJumpDeltas` table, not physics. Controls: Z/X, O/P, or Kempston left/right to walk; Space or fire to jump (hold a direction at take-off to jump that way).

### Music

`ay_music.asm` is a self-contained tracker: note constants (`N_C4`, `N_HOLD`, `AY_ACCENT`), patterns, and an order list, ticked once per frame by the IM2 handler via `AYMusicTick` — independent of the main loop's timing. The header comment documents the song's structure (150 BPM, 5 frames per step, 32-bar AABA loop).

### Debug navigation

`ScanCursorKeysForRoomSwitch` (`keyboard.asm`) lets Caps Shift + cursor keys teleport between rooms, skipping `255` walls. It is a development aid wired into the main loop.

## Conventions

Follow the surrounding style: aligned mnemonics with spaces, one instruction per line, `;` comments. `PascalCase` for global labels (`ClearScreenToBlack`), `.DotPrefixed` for locals, `_Module_Prefixed` for module-private labels and variables, `UPPER_SNAKE_CASE` for `equ` constants. Document a routine's register inputs in a comment directly above its label — that is the only calling-convention documentation this codebase has. No formatter or linter exists, so match nearby layout.

`tmp/` is scratch, not source. Commit messages are short and lowercase, often Slovak (`vylepsenie panelu`).
