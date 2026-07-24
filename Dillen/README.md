# DILLEN (Escape from underground)

This is my attempt to develop a simple game for the ZX Spectrum. Many years ago my friends and I developed some demos for the ZX Spectrum, and this is my little nostalgic moment. In the project you can find an image showing my drawing of the rooms of this simple game. It's an old paper-based drawing — I think I was maybe 15, 16 or 17 years old when I drew it. Well, those were really nostalgic and beautiful times for me.

*We are doing something for Speccy again ;)*

**To compile, use:**

SjASMPlus - Z80 Assembly Cross-Compiler<br>
[http://sourceforge.net/projects/sjasmplus/](http://sourceforge.net/projects/sjasmplus/)

1.  Download it
2.	Unpack it somewhere
3.	Add its folder to your system PATH
4.	Then you can compile

For editing you can use, for example (or VS Code):

1.	ATOM editor [http://www.atom.io](http://www.atom.io)
2.	ATOM plugin "process-palette"
3.	ATOM plugin "language-assembler-sjasmplus"
4.	ATOM plugin "language-z80asm"

Every build creates both `Dillen.sna` and the self-starting `Dillen.tap`.
Load the tape version with `LOAD ""`; its BASIC loader shows the dedicated
loading screen, loads the game and starts it automatically.

## Player controls

- `Z` / `X` (also `O` / `P`) or Kempston left / right: walk
- `Space` or Kempston fire: jump; hold left or right at take-off to jump in that direction

The 16x24 player animation and background masks are generated with:

```powershell
py -3 .\tools\generate_player_assets.py
```

The TAP loading screen and its PNG preview are generated with:

```powershell
py -3 .\tools\generate_loading_screen.py
```
