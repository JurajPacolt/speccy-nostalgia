;###############################################################################
;##### The game field: the place the rooms of the island are drawn in, and #####
;##### the rope border around it. The panel takes the first five character ######
;##### rows, the border begins under it and the field is 30x17 characters. #####
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - CleanGameField
; Erase everything between the borders.
CleanGameField:
        ld    a,0
        call  SetGameFieldAttributes
        ld    hl,BORDER_START_ADDRESS+32+1
        ld    de,BORDER_START_ADDRESS+32+1+1
        ld    b,GAME_FIELD_HEIGHT*8
.CleanGameField1:
        push  hl
        push  bc
        ld    bc,GAME_FIELD_WIDTH-1
        ld    (hl),0
        ldir
        pop   bc
        pop   hl
        call  DownHL
        ld    de,hl
        inc   de
        djnz  .CleanGameField1
        ld    a,GAME_FIELD_COLOR
        call  SetGameFieldAttributes
        ret
; END - CleanGameField
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetGameFieldAttributes
; One colour for the whole field.
; A - the attribute
SetGameFieldAttributes:
        ld    hl,BORDER_START_ATTRIBUTES_ADDRESS+32+1
        ld    de,BORDER_START_ATTRIBUTES_ADDRESS+32+1+1
        ld    b,GAME_FIELD_HEIGHT
.SetGameFieldAttributes1:
        push  hl
        push  bc
        ld    bc,GAME_FIELD_WIDTH-1
        ld    (hl),a
        ldir
        pop   bc
        pop   hl
        ld    de,32
        add   hl,de
        ld    de,hl
        inc   de
        djnz  .SetGameFieldAttributes1
        ret
; END - SetGameFieldAttributes
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawBorder
; The rope around the game field, with a knot in every corner.
DrawBorder:
        call  CleanGameField

        ld    a,BORDER_COLOR
        call  DrawBorderAttributes

        ; The left upper knot.
        ld    hl,BORDER_START_ADDRESS
        ld    de,GfxGameBorderCorner
        call  DrawChar

        ; The upper rope, and the right upper knot after it.
        ld    hl,BORDER_START_ADDRESS+1
        ld    b,GAME_FIELD_WIDTH
.DrawBorder1:
        ld    de,GfxGameBorderItem
        push  hl
        push  bc
        call  DrawChar
        pop   bc
        pop   hl
        inc   hl
        djnz  .DrawBorder1
        ld    de,GfxGameBorderCorner
        call  DrawChar

        ; The left rope.
        ld    hl,BORDER_START_ADDRESS+32
        ld    b,GAME_FIELD_HEIGHT
.DrawBorder2:
        push  bc
        ld    de,GfxGameBorderItem
        call  DrawChar
        pop   bc
        djnz  .DrawBorder2

        ; The right rope. It ends one row under the field, in the last row.
        ld    hl,BORDER_START_ADDRESS+32+31
        ld    b,GAME_FIELD_HEIGHT
.DrawBorder3:
        push  bc
        ld    de,GfxGameBorderItem
        call  DrawChar
        pop   bc
        djnz  .DrawBorder3

        ld    de,31
        sub   hl,de

        ; The lower knot, the lower rope and the last knot.
        push  hl
        ld    de,GfxGameBorderCorner
        call  DrawChar
        pop   hl
        inc   hl
        ld    b,GAME_FIELD_WIDTH
.DrawBorder4:
        ld    de,GfxGameBorderItem
        push  hl
        push  bc
        call  DrawChar
        pop   bc
        pop   hl
        inc   hl
        djnz  .DrawBorder4
        ld    de,GfxGameBorderCorner
        call  DrawChar

        ret
; END - DrawBorder
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawBorderAttributes
; The colour of the whole rope.
; A - the attribute
DrawBorderAttributes:
        ld    hl,BORDER_START_ATTRIBUTES_ADDRESS
        ld    de,BORDER_START_ATTRIBUTES_ADDRESS+1
        ld    bc,31
        ld    (hl),a
        ldir
        inc   hl
        ld    b,GAME_FIELD_HEIGHT
        ld    de,32
.DrawBorderAttributes1:
        ld    (hl),a
        push  hl
        add   hl,de
        dec   hl
        ld    (hl),a
        pop   hl
        add   hl,de
        djnz  .DrawBorderAttributes1
        ld    hl,BORDER_START_ATTRIBUTES_ADDRESS+((GAME_FIELD_HEIGHT+1)*32)
        ld    de,BORDER_START_ATTRIBUTES_ADDRESS+((GAME_FIELD_HEIGHT+1)*32)+1
        ld    bc,31
        ld    (hl),a
        ldir
        ret
; END - DrawBorderAttributes
;-------------------------------------------------------------------------------

; Where the panel ends, where the border and the field begin and what colour
; they are: all of it is in screen.asm.

; A knot of the rope, in the corners.
GfxGameBorderCorner:
        defb  %00111100
        defb  %01111110
        defb  %11111111
        defb  %11011011
        defb  %11011011
        defb  %11111111
        defb  %01111110
        defb  %00111100

; One link of the rope, everywhere else.
GfxGameBorderItem:
        defb  %00111100
        defb  %01100110
        defb  %11000011
        defb  %11000011
        defb  %11000011
        defb  %11000011
        defb  %01100110
        defb  %00111100
