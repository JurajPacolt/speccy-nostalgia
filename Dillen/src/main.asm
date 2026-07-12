; BASIC COMPILER CONFIGURATION
        device zxspectrum128

; COMPILE TO ADDRESS
        org 25000

; ENTRY POINT
@EntryPoint:
        di

        call  ClearScreenToBlack

        call  DrawBorder

        call  InitGamePanel

        ei
        jp    GameMainLoop

; INCLUDES
        include "common.asm" ; Common procedures.
        include "font_4x8.asm" ; Font 4x8 and her printing.
        include "kempston_joystick.asm"
        include "keyboard.asm"
        include "rolling.asm"
        include "sprite_utils.asm"
        include "sprites_land.asm"
        include "rooms.asm" ; Showing rooms.
        include "game.asm" ; Here is main game loop.
        include "game_field.asm" ; Game border graphics.
        include "game_info_panel.asm" ; Info panel for game.
        include "game_panel_picture.asm" ; Picture of the info panel.
        include "torches_in_rooms.asm" ; Torches with the fire in the rooms.
        include "stars_on_background.asm" ; Stars on background.
        include "animations_in_rooms.asm" ; Individual animations in rooms.

; COMPILER OUTPUT
        savesna "Dillen.sna", @EntryPoint
