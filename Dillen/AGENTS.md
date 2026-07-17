# Repository Guidelines

## Project Structure & Module Organization

This directory contains a ZX Spectrum 128 game written for SjASMPlus. `src/main.asm` defines the entry point, includes the other assembly modules, and writes the `Dillen.sna` snapshot. Keep gameplay responsibilities separated across the existing `src/*.asm` modules (for example, input in `keyboard.asm` and `kempston_joystick.asm`, rooms in `rooms.asm`, and rendering helpers in `sprite_utils.asm`). Binary data lives under `src/binary/`. Artwork, maps, fonts, and previews belong in `gfx/`. Treat `tmp/` as scratch/generated content, not as source.

## Build, Test, and Development Commands

- `build.bat` builds on Windows with `sjasmplus` available on `PATH`.
- `build_and_run.bat` builds and launches `Dillen.sna` in SpecEmu.
- `./build.sh` builds on Unix-like systems by running `sjasmplus.exe` through Wine.
- `./build_and_run.sh` builds and opens the snapshot with `myfuse`; update its local SjASMPlus path if needed.

Run commands from this directory. A successful build regenerates `Dillen.sna`. There is no automated test suite; validate changes by checking for assembler errors and exercising affected rooms, controls, graphics, and audio in an emulator.

## Coding Style & Naming Conventions

Follow the surrounding Z80 assembly style: use spaces for aligned mnemonics and operands, semicolon comments, and one instruction per line. Use descriptive PascalCase global labels such as `ClearScreenToBlack`, dot-prefixed local labels such as `.PrintChar1`, and `UPPER_SNAKE_CASE` for constants. Document routine inputs and register assumptions immediately above the label. Add new modules through the include list in `src/main.asm`, keeping related code and data together. No formatter or linter is configured, so preserve nearby layout.

## Testing Guidelines

For every behavioral change, build from a clean emulator session and test both keyboard and Kempston input when relevant. Check screen boundaries, room transitions, item state, and AY playback for regressions. Describe the manual scenarios and emulator used in the pull request.

## Commit & Pull Request Guidelines

Recent history uses brief, lowercase summaries, often in Slovak (for example, `vylepsenie panelu`). Keep commits focused and use a short imperative summary that names the affected feature. Pull requests should explain the player-visible change, list manual test steps, and link any related issue. Include screenshots or a short capture for graphics, animation, HUD, or room-layout changes; note any required emulator or tool configuration.
