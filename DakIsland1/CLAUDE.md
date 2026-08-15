# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Dark Island 1 is a ZX Spectrum 128 game in Z80 assembly, built with SjASMPlus. It is a nostalgia project based on a room map its author drew on paper as a boy (`gfx/dark.island.1-map.gif`, labelled in Slovak). It is a sibling of the `Dillen` project in the same repository and follows the same conventions; when something here is unclear, look there for the grown-up version of the same idea.

Right now the game is the screen only: the panel, the field, the map and six rooms. There is no player, no item, no sound.

## Build

```powershell
sjasmplus -Isrc src/main.asm     # run from this directory
```

SjASMPlus **1.23.1** on `PATH`. A successful build writes two gitignored files: `DarkIsland1.sna` (from `savesna`) and the self-starting `DarkIsland1.tap` (staged by `tape_loader.asm`, assembled after the SNA). `build.bat` runs the same command, `build_and_run.bat` also opens SpecEmu, the `.sh` pair does it through Wine.

The build must be clean of **warnings** as well as errors. A "Label has different value in pass 3" warning means an `equ` was used before it was defined and the emitted code may be wrong - fix the include order rather than ignore it.

There is no test suite. Verification is: 0 errors and 0 warnings, then `py -3 tools/preview_screen.py` to see the screen without an emulator, then an emulator for anything that moves.

## The generated sources

Four files under `src/` are **output, not source** - never hand-edit them:

| Generated file | Made by | From |
| --- | --- | --- |
| `src/font_8x8.asm`, `src/font_4x8.asm` | `tools/generate_font.py` | the ASCII art in `tools/font_art.py` |
| `src/game_panel_picture.asm` | `tools/generate_panel.py` | the pen strokes in `tools/logo_alphabet.py` and the drawing code in the generator |
| `src/sprites_land.asm` | `tools/generate_sprites.py` | the ASCII art and brush strokes in the generator |

All of them need Pillow and are run from this directory (`py -3 tools/generate_font.py`). Each also writes a PNG into `gfx/` to look at.

`tools/zx.py` is the shared floor under them: a `Canvas` is a one-bit picture plus **one ink per 8x8 cell**, and it refuses a second ink in a cell, so an attribute clash is a build error in Python instead of a surprise on the screen. A sheet that is only ever a PNG passes `strict=False`.

`tools/pen.py` has two tools. `Pen` is a broad calligraphy nib held at a fixed angle - it makes the blackletter of the logo, where the direction of a stroke has to change its weight. `Brush` is round and equally thick in every direction - it makes the trees, where a branch must not thin out when it turns. Using the wrong one is the most likely reason a drawing looks wrong.

`tools/preview_screen.py` is the closest thing to a test: it reads the border tiles out of `src/game_field.asm` and the room records out of `src/rooms.asm`, composes the screen the Spectrum would compose into `gfx/screen.png` and `gfx/rooms.png`, and reports every sprite that hangs out of the game field. Run it after touching a room.

## The screen

`src/screen.asm` holds nothing but constants and is the single place the layout lives; everything that needs a coordinate reads it from there. **It must be the first include**, because sjasmplus needs an `equ` before the expression that uses it.

- Rows 0-4: the panel (`game_info_panel.asm` over the generated picture).
- Row 5: the top of the rope border.
- Rows 6-22: the game field, 30x17 characters. In pixels: X from 8 to 247, Y from 48 to 183.
- Row 23: the bottom of the border.

Code assembles from `org 25000` upward and currently reaches to about 31100, so roughly 17K is still free under the screen buffers. Nothing yet claims high memory, so there is no ceiling like Dillen's `0xBE00` - but the moment an IM2 music player arrives there will be one. `main.asm` sets `SP` to just under the code, into the memory the BASIC loader has cleared away.

## Architecture

`main.asm` is the entry point and the include list; **new modules go there**, and the include order is the link order. It re-enables interrupts (`di / im 1 / ei`) because the main loop waits on `halt` and the loader may have left them off.

`GameMainLoop` (`game.asm`) runs once per frame: `ShowRoom`, `ShowGamePanel`, then the keys. Both drawing routines are lazy - see below - so an ordinary frame is nearly nothing.

### Everything is drawn only when it changed

`ShowRoom` compares `ActualRoomInMap` with `LastShowedRoomInMap` and returns at once when they match. `ShowGamePanel` does the same for the room name, the lives and the energy against `_GP_ShowedRoom` / `_GP_ShowedLives` / `_GP_ShowedEnergy`. Any new module that draws into a room should cache the room it drew and expose a `Reset*` routine called from `ResetGame`.

### Room map index vs. room number

Two different numbers, and confusing them is the classic bug:

- `ActualRoomInMap` is an **index into `RoomsMap`**, a grid `ROOMS_MAP_WIDTH` (8) wide where `255` marks a place there is no way to. Navigation arithmetic (±1, ±`ROOMS_MAP_WIDTH`) happens on this index.
- The **room number** is `RoomsMap[ActualRoomInMap]`, and it indexes `Rooms` (the sprite lists) and `_GP_RoomTexts` (the names in the panel).

`StartRoomInMap equ 009` is an index, not a number. Adding a room means updating `RoomsMap` and `Rooms` in `rooms.asm` and `_GP_RoomTexts` plus `PANEL_ROOMS_COUNT` in `screen.asm`, in step.

### Sprites and the attribute cache

A sprite is `defb width_in_characters, height_in_pixel_lines`, then the bitmap by pixel lines, then one attribute per character. `sprite_utils.asm` has `DrawSprite` (the sprite's own colours), `DrawSpriteWithCustomColor` (one flat attribute in `A`) and `DrawSpriteWithoutAttrs` (ORs the bitmap in and leaves the colours alone).

`DE` passed to those routines is where the **attributes** go, and this is the subtle part: `ShowRoom` points it at `RoomsAttrCache`, a 768-byte shadow of the attributes, so sprites that overlap compose off-screen; only afterwards are rows 6..22 blitted into the real attributes in one pass. Anything drawing straight onto a live screen passes `22528` instead.

A room record is five bytes - `defb X_pixels, Y_pixels, attr` then `defw sprite_address` - and the list ends with a **zero X byte**, so no sprite can stand in column 0. A non-zero `attr` means "paint the whole sprite this colour", which is how the burnt room re-uses the ordinary ground and trees in red.

### The panel

The still part of the panel (logo, island picture, the words LIVES and ENERGY) is a generated tile map; `InitGamePanel` walks `PanelMap`, draws each tile once and copies `PanelAttributes`. Tile 0 is the empty character and is not stored. The places of the skulls, of the energy and of the room name are deliberately empty in that picture - the game draws them.

The skulls are not still: `_GP_GnashSkulls` steps through `_GP_SkullGnash`, a table of three bytes per step (a picture and how many frames it is shown), so they rest, their eyes catch a light and their jaws snap twice. Same shape as Dillen's beating hearts.

The name of the room is written in the **gothic font** (`Print` with `Font8x8`), centred in the last row of the panel, so a name may be at most `PANEL_TEXT_LENGTH` (32) characters long. The small font and `Print4x8` are built in and currently unused at runtime - the words LIVES and ENERGY are set in it, but they are baked into the generated picture. It is there for the longer texts that are coming (item names, hints, the modal windows).

## Conventions

Follow the surrounding style: aligned mnemonics with spaces, one instruction per line, `;` comments. `PascalCase` for global labels, `.DotPrefixed` for locals, `_Module_Prefixed` for module-private labels, `UPPER_SNAKE_CASE` for `equ`. Document a routine's register inputs in a comment directly above its label - that is the only calling-convention documentation this codebase has. Comments and in-game text are in English; the paper map is in Slovak and quoting it is fine. Commit messages are short and lowercase, often Slovak.
