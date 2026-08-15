;###############################################################################
;##### How the screen of the game is divided. Everything that has to know #######
;##### where something is on the screen reads it from here, so this is the ######
;##### one place to change if the panel ever grows or the field moves. ##########
;###############################################################################
;
;   row  0 |                                              |
;   row  1 |  the panel: the name of the island, the moon  |
;   row  2 |  over it, the lives, the energy and the name  |
;   row  3 |  of the room                                  |
;   row  4 |                                              |
;   row  5 +----------------------------------------------+  <- the rope border
;   row  6 |                                              |
;    ...   |  the game field, 30x17 characters            |
;   row 22 |                                              |
;   row 23 +----------------------------------------------+
;
;-------------------------------------------------------------------------------
; The panel begins in the left upper corner of the screen.
GAME_INFO_PANEL_START_ADDRESS             equ 16384
GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES  equ 22528

; The panel is as wide as the screen and five character rows high.
GAME_INFO_PANEL_WIDTH  equ 32
GAME_INFO_PANEL_HEIGHT equ 5

; How many rows of the panel the generated picture covers.
PANEL_PICTURE_ROWS     equ 5

;-------------------------------------------------------------------------------
; The border begins in the first character row under the panel, and the field
; is the rectangle inside it.
BORDER_START_ROW                equ GAME_INFO_PANEL_HEIGHT
BORDER_START_ADDRESS            equ 16384+(32*BORDER_START_ROW)
BORDER_START_ATTRIBUTES_ADDRESS equ 22528+(32*BORDER_START_ROW)

; The colour of the rope: old yellow, so it looks like hemp.
BORDER_COLOR                    equ 6
; The colour the empty field gets after it is cleaned.
GAME_FIELD_COLOR                equ 71

; The field, in characters, and where it begins inside the border.
GAME_FIELD_WIDTH                equ 30
GAME_FIELD_HEIGHT               equ 17
GAME_FIELD_FIRST_ROW            equ BORDER_START_ROW+1
GAME_FIELD_FIRST_COL            equ 1

;-------------------------------------------------------------------------------
; What stands where inside the panel.
; The lives, one skull for one life, next to the word LIVES.
PANEL_LIVES_ROW           equ 3
PANEL_LIVES_COL           equ 4
PANEL_LIVES_MAX           equ 5

; The energy, a row of stones next to the word ENERGY.
PANEL_ENERGY_ROW          equ 3
PANEL_ENERGY_COL          equ 14
PANEL_ENERGY_CELLS        equ 10
PANEL_ENERGY_LOW          equ 3 ; Under this the row is red.
PANEL_ENERGY_HALF         equ 6 ; Under this the row is yellow.

; The name of the room, in the last row of the panel. It is written with the
; gothic font and stands in the middle of the row, so it may be 32 characters
; long at the most.
PANEL_TEXT_ROW            equ 4
PANEL_TEXT_COL            equ 0
PANEL_TEXT_LENGTH         equ 32

; How many rooms the table of the names in the panel has.
PANEL_ROOMS_COUNT         equ 24

; The colours of the panel. The colours of the picture are in its own data.
PANEL_SKULL_ATTR          equ 71 ; Bright white, bone in the moonlight.
PANEL_ENERGY_FULL_ATTR    equ 68 ; Bright green.
PANEL_ENERGY_HALF_ATTR    equ 70 ; Bright yellow.
PANEL_ENERGY_LOW_ATTR     equ 66 ; Bright red.
PANEL_ENERGY_EMPTY_ATTR   equ 1  ; Blue, a spent stone is only a shadow.
;-------------------------------------------------------------------------------
