;###############################################################################
;##### DARK ISLAND 1 ###########################################################
;##### #########################################################################
;##### A ZX Spectrum 128 game in Z80 assembly, built with SjASMPlus. It is ######
;##### drawn after a map its author drew on paper as a boy - the paper is #######
;##### in gfx/dark.island.1-map.gif. ###########################################
;##### #########################################################################
;##### This is the beginning of it: the screen of the game. The panel over ######
;##### the field carries the name of the island, the moon over it, the lives ####
;##### and the energy; the field under the panel is where the rooms are. ########
;###############################################################################

; BASIC COMPILER CONFIGURATION
        device zxspectrum128

; COMPILE TO ADDRESS
        org 25000

; ENTRY POINT
@EntryPoint:
        ; The stack goes right under the code, into the memory the BASIC loader
        ; cleared away for us; the game never returns to whoever called it.
        di
        ld    sp,@EntryPoint-1
        ; The game waits for the frame interrupt in its loop, so the interrupts
        ; have to be running whatever the loader left behind.
        im    1
        ei

        call  ClearScreenToBlack
        call  DrawBorder
        call  InitGamePanel

        jp    GameMainLoop

; INCLUDES
        include "screen.asm" ; How the screen is divided; only constants.
        include "common.asm" ; Small procedures the whole game uses.
        include "font_8x8.asm" ; The gothic font of the game.
        include "font_4x8.asm" ; The small font of the panel.
        include "font_print.asm" ; Writing with the small font.
        include "sprite_utils.asm" ; Drawing the sprites.
        include "sprites_land.asm" ; The sprites the rooms are built from.
        include "rooms.asm" ; The rooms of the island and the map of them.
        include "game.asm" ; The main loop and the state of the run.
        include "keyboard.asm" ; Reading the keys.
        include "game_field.asm" ; The field and the rope around it.
        include "game_info_panel.asm" ; The panel over the field.
        include "game_panel_picture.asm" ; The picture of the panel.

; COMPILER OUTPUT
@ProgramEnd:
        savesna "DarkIsland1.sna", @EntryPoint
        include "tape_loader.asm" ; The BASIC loader and the tape of the game.
