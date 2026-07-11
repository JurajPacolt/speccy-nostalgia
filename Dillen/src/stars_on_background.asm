;###############################################################################
;##### ASM unit for the twinkling stars on the sky of the outdoor rooms. #######
;###############################################################################

; How many stars can twinkle in one room.
STARS_MAX       equ 12
; Character rows of the game field, where the stars can be placed.
STARS_ROW_MIN   equ 5
STARS_ROW_MAX   equ 18
; Character columns of the game field, where the stars can be placed.
STARS_COL_MIN   equ 1
STARS_COL_MAX   equ 30
; How many cells are tried, before one star is given up.
STARS_TRIES     equ 40
; Number of the images in the twinkle sequence.
STARS_PHASES    equ 8
; Size of one star's record: VRAM address (2), phase, tick, speed.
STARS_ITEM_SIZE equ 5

;-------------------------------------------------------------------------------
; BEGIN - StarOnBackground - Main stars method, it's called once per frame.
StarOnBackground:
        ; The stars are placed again always, when the showed room is changed.
        ld    a,(ActualRoomInMap)
        ld    hl,_StarsRoom
        cp    (hl)
        jr    z,_SOB_Twinkle
        ld    (hl),a
        call  _SOB_PlaceStars

_SOB_Twinkle:
        ld    a,(_StarsCount)
        or    a
        ret   z ; Room without the stars.
        ld    b,a
        ld    ix,_StarsData
_SOB_TwinkleLoop:
        push  bc
        dec   (ix+3) ; Tick to the next image of the star.
        jr    nz,_SOB_TwinkleNext
        ld    a,(ix+4) ; Speed, new value for the tick.
        ld    (ix+3),a
        ld    a,(ix+2) ; Actual phase.
        inc   a
        cp    STARS_PHASES
        jr    c,_SOB_TwinkleDraw
        xor   a ; The sequence begins again.
_SOB_TwinkleDraw:
        ld    (ix+2),a
        call  _SOB_DrawStar
_SOB_TwinkleNext:
        ld    de,STARS_ITEM_SIZE
        add   ix,de
        pop   bc
        djnz  _SOB_TwinkleLoop
        ret
; END - StarOnBackground
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetStars - The stars are forgotten, the room will be filled again.
ResetStars:
        xor   a
        ld    (_StarsCount),a
        dec   a ; 255, it's not a valid room in the map.
        ld    (_StarsRoom),a
        ret
; END - ResetStars
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _SOB_PlaceStars - Put the stars to the free cells of the actual room.
_SOB_PlaceStars:
        xor   a
        ld    (_StarsCount),a

        call  _SOB_RoomHasSky
        ret   nc ; Underground room, without the sky, without the stars.

        ld    ix,_StarsData
        ld    b,STARS_MAX
_SOB_PS_Loop:
        push  bc
        call  _SOB_FindFreeCell
        jr    nc,_SOB_PS_Next ; No free cell, this star isn't used.

        ld    (ix+0),l
        ld    (ix+1),h ; Cell of the star in the VRAM.
        call  _SOB_Random
        and   STARS_PHASES-1
        ld    (ix+2),a ; Every star begins in an other phase.
        call  _SOB_Random
        and   3
        add   a,3
        ld    (ix+3),a ; Tick.
        ld    (ix+4),a ; Speed, 3 - 6 frames for one phase.

        ld    de,STARS_ITEM_SIZE
        add   ix,de
        ld    hl,_StarsCount
        inc   (hl)
_SOB_PS_Next:
        pop   bc
        djnz  _SOB_PS_Loop
        ret
; END - _SOB_PlaceStars
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _SOB_FindFreeCell - Random cell of the game field, where is a place
;                             for the star.
; return CF=1 and HL - VRAM address of the free cell.
; return CF=0 - no free cell was found.
_SOB_FindFreeCell:
        ld    b,STARS_TRIES
_SOB_FFC_Try:
        push  bc

        call  _SOB_Random
        and   31
        cp    STARS_COL_MIN
        jr    c,_SOB_FFC_Next ; Out of the game field.
        cp    STARS_COL_MAX+1
        jr    nc,_SOB_FFC_Next ; Out of the game field.
        ld    c,a ; C - character column.

        call  _SOB_Random
        and   15
        cp    STARS_ROW_MAX-STARS_ROW_MIN+1
        jr    nc,_SOB_FFC_Next ; Out of the game field.
        add   a,STARS_ROW_MIN
        ld    b,a ; B - character row.

        call  AIR_IsCellReserved
        jr    c,_SOB_FFC_Next ; Here is moving an animation of the room.

        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a ; B - Yos.
        ld    a,c
        add   a,a
        add   a,a
        add   a,a
        ld    c,a ; C - Xos.
        call  ScreenAddr

        call  _SOB_CellIsEmpty
        jr    nc,_SOB_FFC_Next ; Here is showed a sprite of the room.

        pop   bc
        scf
        ret

_SOB_FFC_Next:
        pop   bc
        djnz  _SOB_FFC_Try
        or    a ; CF=0, without a result.
        ret
; END - _SOB_FindFreeCell
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _SOB_CellIsEmpty - Is the character cell black, without any sprite?
; HL - VRAM address of the cell.
; return CF=1 - all eight pixel lines of the cell are empty.
_SOB_CellIsEmpty:
        push  bc
        push  hl
        ld    b,8
        ld    c,0
_SOB_CIE_Loop:
        ld    a,(hl)
        or    c
        ld    c,a
        call  DownHL
        djnz  _SOB_CIE_Loop
        ld    a,c
        pop   hl
        pop   bc
        or    a
        ret   nz ; CF=0, there is something on the screen.
        scf
        ret
; END - _SOB_CellIsEmpty
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _SOB_RoomHasSky - Can the actual room show the stars?
; return CF=1 - the room is on the surface, under the sky.
_SOB_RoomHasSky:
        push  hl
        push  de
        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl) ; Room's ID number.
        cp    _StarsRoomsWithSkyEnd-_StarsRoomsWithSky
        jr    nc,_SOB_RHS_NoSky
        ld    hl,_StarsRoomsWithSky
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl)
        or    a
        jr    z,_SOB_RHS_NoSky
        pop   de
        pop   hl
        scf
        ret
_SOB_RHS_NoSky:
        pop   de
        pop   hl
        or    a ; CF=0
        ret
; END - _SOB_RoomHasSky
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _SOB_DrawStar - Draw the actual image of the star.
; IX - Record of the star.
; The cell of the star is always empty, so the image can be simply putted there.
_SOB_DrawStar:
        ld    a,(ix+2) ; Phase.
        add   a,a
        add   a,a
        add   a,a ; Phase * 8 bytes.
        ld    e,a
        ld    d,0
        ld    hl,_StarsShapes
        add   hl,de
        ex    de,hl ; DE - image of the actual phase.
        ld    l,(ix+0)
        ld    h,(ix+1) ; HL - cell of the star in the VRAM.
        ld    b,8
_SOB_DS_Loop:
        ld    a,(de)
        ld    (hl),a
        inc   de
        call  DownHL
        djnz  _SOB_DS_Loop
        ret
; END - _SOB_DrawStar
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _SOB_Random - Next random number.
; return A - random number.
_SOB_Random:
        push  hl
        push  bc
        ld    hl,_StarsSeed
        call  Random8bit
        pop   bc
        pop   hl
        ret
; END - _SOB_Random
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Room, for which are the stars actually placed. 255 - none.
_StarsRoom:
        defb  255

; How many stars are really placed in the actual room.
_StarsCount:
        defb  0

; Seed of the random numbers.
_StarsSeed:
        defb  73

; Records of the stars.
_StarsData:
        block STARS_MAX*STARS_ITEM_SIZE

; Rooms with the sky, where the stars can twinkle. Index is the room's ID.
_StarsRoomsWithSky:
        defb  0 ; 000 - blank room
        defb  1 ; 001
        defb  1 ; 002
        defb  1 ; 003
        defb  1 ; 004
        defb  1 ; 005
        defb  1 ; 006
        defb  1 ; 007
        defb  0 ; 008 - underground
        defb  0 ; 009 - underground
        defb  0 ; 010 - underground
        defb  0 ; 011 - underground
_StarsRoomsWithSkyEnd:

; Images of the twinkle sequence, one image for one phase.
_StarsShapes:
        ; 0 - a little point
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; 1 - a little point
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; 2 - small star
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00111000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; 3 - big star
        defb  %00000000
        defb  %00010000
        defb  %00010000
        defb  %01111100
        defb  %00010000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        ; 4 - big star
        defb  %00000000
        defb  %00010000
        defb  %00010000
        defb  %01111100
        defb  %00010000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        ; 5 - small star
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00111000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; 6 - a little point
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; 7 - a little point
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
;-------------------------------------------------------------------------------
