;-------------------------------------------------------------------------------
; BEGIN - CleanGameField
; Cleaning game field between game's border.
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
        ld    a,71
        call  SetGameFieldAttributes
        ret
; END - CleanGameField
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetGameFieldAttributes
; Set up attributes of the game field.
; A - Color of the attributes
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
; Draw game-border on screen.
; Without input parameters. 
DrawBorder:
        ; clean game field
        call  CleanGameField
        
        ; attributes
        ld    a,BORDER_COLOR
        call  DrawBorderAttributes

        ; left-up corner
        ld    hl,BORDER_START_ADDRESS
        ld    de,GfxGameBorderCorner
        call  DrawChar

        ; up line
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
        ; right corner
        ld    de,GfxGameBorderCorner
        call  DrawChar

        ; left vertical line
        ld    hl,BORDER_START_ADDRESS+32
        ld    b,GAME_FIELD_HEIGHT
.DrawBorder2:
        push  bc
        ld    de,GfxGameBorderItem
        call  DrawChar
        pop   bc
        djnz  .DrawBorder2

        ; right vertical line
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

        ; down line
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
        ; right-down corner
        ld    de,GfxGameBorderCorner
        call  DrawChar

        ret
; END - DrawBorder
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawBorderAttributes
; Set of the game's border color.
; A - number of the attribute color
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

; Start address of the game's border.        
BORDER_START_ADDRESS            equ 16384+(32*4)
; Start address of the attributes for game's border.        
BORDER_START_ATTRIBUTES_ADDRESS equ 22528+(32*4)
; Border color constant.
BORDER_COLOR                    equ 8
; Width of the game field.
GAME_FIELD_WIDTH                equ 30
; Height of the game field.
GAME_FIELD_HEIGHT               equ 18

; Data of the corner in the border.
GfxGameBorderCorner:
        defb  195, 189, 126, 126, 126, 126, 189, 195

; Data of the item in the border.
GfxGameBorderItem:
        defb  195, 102, 126, 60, 60, 126, 102, 195
