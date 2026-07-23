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

        call  PlayerBuildWalkCache

        call  InitAYMusicIM2
        jp    GameMainLoop

; INCLUDES
        include "common.asm" ; Common procedures.
        include "font_4x8.asm" ; Font 4x8 and her printing.
        include "kempston_joystick.asm"
        include "keyboard.asm"
        include "rolling.asm"
        include "sprite_utils.asm"
        include "sprites_land.asm"
        include "player.asm" ; Main character, controls and masked animation.
        include "rooms.asm" ; Showing rooms.
        include "items_in_rooms.asm" ; Collectible and usable items from the map.
        include "inventory.asm" ; Carrying, picking up and dropping items.
        include "life_lost.asm" ; Sad modal message after losing a life.
        include "game.asm" ; Here is main game loop.
        include "game_field.asm" ; Game border graphics.
        include "game_info_panel.asm" ; Info panel for game.
        include "game_panel_picture.asm" ; Picture of the info panel.
        include "torches_in_rooms.asm" ; Torches with the fire in the rooms.
        include "stars_on_background.asm" ; Stars on background.
        include "animations_in_rooms.asm" ; Individual animations in rooms.
        include "death_in_room.asm" ; The Death with the scythe, in room 7.
        include "ay_music.asm" ; Cheerful AY background music and IM2 player.

; COMPILER OUTPUT
        savesna "Dillen.sna", @EntryPoint
