; BASIC COMPILER CONFIGURATION
        device zxspectrum128

; COMPILE TO ADDRESS
        org 25000

; ENTRY POINT
@EntryPoint:
        di

        call  ClearScreenToBlack

        call  CleanGameInfoPanelField

        call  DrawBorder

        ld    ix,@TitleText
        ld    hl,@MainFontData
        ld    de,16384
        call  Print

        ei
        jp    GameMainLoop

; INCLUDES
        include "common.asm" ; Common procedures.
        include "kempston_joystick.asm"
        include "keyboard.asm"
        include "rolling.asm"
        include "sprite_utils.asm"
        include "sprites_land.asm"
        include "rooms.asm" ; Showing rooms.
        include "game.asm" ; Here is main game loop.
        include "game_field.asm" ; Game border graphics.
        include "game_info_panel.asm" ; Info panel for game.
        include "stars_on_background.asm" ; Stars on background.
        include "animations_in_rooms.asm" ; Individual animations in rooms.

; STRING DATA
@TitleText:
        defb    "Skusobny text ... 1 2 3", 0

; BINARY DATA
@MainFontData:
        incbin "..\gfx\std8x8.chr"

; COMPILER OUTPUT
        savesna "Dillen.sna", @EntryPoint
