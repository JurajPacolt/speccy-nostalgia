# Repository Guidelines

## Project Structure & Module Organization

This directory holds a ZX Spectrum 128 game written for SjASMPlus. `src/main.asm` is the entry point, includes every other module and writes both `DarkIsland1.sna` and the self-starting `DarkIsland1.tap` (staged by `tape_loader.asm`). `src/screen.asm` is constants only - the layout of the screen - and must stay the first include, because sjasmplus needs an `equ` before the expression that uses it. Keep responsibilities where they already are: the keys in `keyboard.asm`, the rooms in `rooms.asm`, the drawing helpers in `sprite_utils.asm`, the panel in `game_info_panel.asm`.

Four files under `src/` are generated and must never be hand-edited: `font_8x8.asm`, `font_4x8.asm`, `game_panel_picture.asm` and `sprites_land.asm`. Their sources are the scripts and the ASCII art in `tools/`. Artwork, previews and the paper map live in `gfx/`.

## Build, Test, and Development Commands

- `sjasmplus -Isrc src/main.asm` builds by hand from this directory (SjASMPlus 1.23.1 on `PATH`).
- `build.bat` runs that same command on Windows; `build_and_run.bat` also opens the snapshot in SpecEmu.
- `./build.sh` and `./build_and_run.sh` do the same through Wine.
- `py -3 tools/generate_font.py`, `generate_panel.py`, `generate_sprites.py` regenerate the artwork (they need Pillow) and refresh the PNGs in `gfx/`.
- `py -3 tools/preview_screen.py` draws the whole screen into `gfx/screen.png` without an emulator and reports any sprite hanging out of the game field.

## Testing Guidelines

There is no automated test suite. A change is verified when the assembler reports **0 errors and 0 warnings** - a "Label has different value in pass 3" warning is a real bug in the include order, not noise - and then:

- run `tools/preview_screen.py` for anything that touches the panel, the border, a sprite or a room, and look at the PNG;
- load the snapshot in an emulator for anything that moves, changes over time or reads the keyboard;
- walk the whole map with Caps Shift and the cursor keys after touching `RoomsMap`, and check that the name in the panel changes with the room;
- press `A`, `S`, `D` and `F` after touching the panel or the state, and watch the energy change colour and the lives run out.

When you touch the tape path, also load `DarkIsland1.tap` with `LOAD ""` and confirm that it starts by itself.

## Coding Style & Naming Conventions

Follow the surrounding Z80 style: spaces for aligned mnemonics and operands, semicolon comments, one instruction per line. `PascalCase` for global labels such as `ClearScreenToBlack`, `.DotPrefixed` for local ones, `_Module_Prefixed` for module-private labels and variables, `UPPER_SNAKE_CASE` for `equ` constants. Document a routine's register inputs immediately above its label. Add new modules through the include list in `src/main.asm` and remember that the include order is the link order. Comments and in-game text are in English; the paper map is in Slovak and quoting it is fine. No formatter or linter is configured, so preserve nearby layout.

Python in `tools/` runs on Python 3.7, so no walrus operator and no `list[int]` outside annotations.

## Commit & Pull Request Guidelines

History uses brief, lowercase summaries, often in Slovak (for example `vylepsenie panelu`). Keep commits focused and name the affected feature. Pull requests should explain the player-visible change, list the manual steps taken, and include a screenshot or the regenerated PNG for anything graphical.
