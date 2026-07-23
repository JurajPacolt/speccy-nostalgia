;###############################################################################
;##### Sad modal message shown whenever the player loses one life. #############
;###############################################################################

LIFE_LOST_STATE_CLOSED   equ 0
LIFE_LOST_STATE_PENDING  equ 1
LIFE_LOST_STATE_OPEN     equ 2

; Character-cell geometry inside the game field.
LIFE_LOST_WIN_ROW        equ 9
LIFE_LOST_WIN_COL        equ 6
LIFE_LOST_WIN_WIDTH      equ 20
LIFE_LOST_WIN_HEIGHT     equ 7

LIFE_LOST_MESSAGE_ROW    equ LIFE_LOST_WIN_ROW+2
LIFE_LOST_PROMPT_ROW     equ LIFE_LOST_WIN_ROW+4
LIFE_LOST_MESSAGE_COL    equ LIFE_LOST_WIN_COL*2+12
LIFE_LOST_GAME_OVER_COL  equ LIFE_LOST_WIN_COL*2+15
LIFE_LOST_PROMPT_COL     equ LIFE_LOST_WIN_COL*2+13

; Muted blue paper and cyan ink give the message a cold, sad appearance.
LIFE_LOST_ATTR_BORDER    equ 65 ; Bright blue ink on black paper.
LIFE_LOST_ATTR_CORNER    equ 69 ; Bright cyan ink on black paper.
LIFE_LOST_ATTR_INTERIOR  equ 13 ; Cyan ink on blue paper.

;-------------------------------------------------------------------------------
; BEGIN - LifeLostReset - Close the message and reset its input gate.
LifeLostReset:
        xor   a
        ld    (LifeLostState),a
        ld    (_LifeLostInputReady),a
        ret
; END - LifeLostReset
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - LifeLostShow - Schedule the message for the next game-loop frame.
LifeLostShow:
        ld    a,LIFE_LOST_STATE_PENDING
        ld    (LifeLostState),a
        xor   a
        ld    (_LifeLostInputReady),a
        ret
; END - LifeLostShow
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - LifeLostHandle - Draw or handle the open modal message.
LifeLostHandle:
        ld    a,(LifeLostState)
        cp    LIFE_LOST_STATE_PENDING
        jr    z,_LifeLostOpen

        ; Do not immediately dismiss the window when the player was holding the
        ; jump key at the moment of the hit.
        ld    a,(_LifeLostInputReady)
        or    a
        jr    nz,_LifeLostCheckPressed

        ld    bc,49150 ; H, J, K, L, Enter: bit 0 - Enter.
        in    a,(c)
        bit   0,a
        ret   z
        ld    bc,32766 ; B, N, M, Symbol Shift, Space: bit 0 - Space.
        in    a,(c)
        bit   0,a
        ret   z
        ld    a,1
        ld    (_LifeLostInputReady),a
        ret

_LifeLostCheckPressed:
        ld    bc,49150
        in    a,(c)
        bit   0,a
        jr    z,_LifeLostClose
        ld    bc,32766
        in    a,(c)
        bit   0,a
        ret   nz

_LifeLostClose:
        ld    a,(PlayerLives)
        or    a
        jr    z,_LifeLostRestartGame

        ; Consume the closing key so it cannot open the inventory or start a
        ; jump on the first frame after the message.
        ld    a,1
        ld    (_INV_EnterLatch),a
        ld    (PlayerJumpLatch),a
        xor   a
        ld    (LifeLostState),a
        ld    (_LifeLostInputReady),a
        ld    (_INV_PendingOpen),a

        ; The window painted over the playfield, so rebuild every room layer.
        call  ItemsForceRedraw
        call  ResetTorches
        call  ResetStars
        call  ResetWind
        call  ResetDeath
        ret

_LifeLostRestartGame:
        call  ResetGame
        ; ResetGame clears the input latches, so consume the key once more.
        ld    a,1
        ld    (_INV_EnterLatch),a
        ld    (PlayerJumpLatch),a
        ret
; END - LifeLostHandle
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw the window once when its pending state reaches the game loop.
_LifeLostOpen:
        ld    a,LIFE_LOST_STATE_OPEN
        ld    (LifeLostState),a
        ; The loss happened after the panel was drawn in the previous frame.
        call  ShowGamePanel
        xor   a
        ld    (_LifeLostDrawRow),a

_LifeLostDrawRowLoop:
        xor   a
        ld    (_LifeLostDrawCol),a

_LifeLostDrawColLoop:
        call  _LifeLostTileForCell
        ld    (_LifeLostTileAttr),a

        ld    a,(_LifeLostDrawRow)
        add   a,LIFE_LOST_WIN_ROW
        ld    b,a
        ld    a,(_LifeLostDrawCol)
        add   a,LIFE_LOST_WIN_COL
        ld    c,a
        ld    a,(_LifeLostTileAttr)
        call  _LifeLostDrawCell

        ld    hl,_LifeLostDrawCol
        inc   (hl)
        ld    a,(hl)
        cp    LIFE_LOST_WIN_WIDTH
        jr    nz,_LifeLostDrawColLoop

        ld    hl,_LifeLostDrawRow
        inc   (hl)
        ld    a,(hl)
        cp    LIFE_LOST_WIN_HEIGHT
        jr    nz,_LifeLostDrawRowLoop

        ld    a,(PlayerLives)
        or    a
        ld    ix,_LifeLostText
        ld    c,LIFE_LOST_MESSAGE_COL
        jr    nz,_LifeLostDrawMessage
        ld    ix,_LifeLostGameOverText
        ld    c,LIFE_LOST_GAME_OVER_COL
_LifeLostDrawMessage:
        ld    b,LIFE_LOST_MESSAGE_ROW
        call  Print4x8

        ld    ix,_LifeLostPromptText
        ld    b,LIFE_LOST_PROMPT_ROW
        ld    c,LIFE_LOST_PROMPT_COL
        call  Print4x8
        ret

; Choose the tile and its attribute for one relative window cell.
; return DE - tile data address, A - attribute.
_LifeLostTileForCell:
        ld    a,(_LifeLostDrawRow)
        or    a
        jr    z,.LifeLostTileEdgeRow
        cp    LIFE_LOST_WIN_HEIGHT-1
        jr    z,.LifeLostTileEdgeRow

        ld    a,(_LifeLostDrawCol)
        or    a
        jr    z,.LifeLostTileVertical
        cp    LIFE_LOST_WIN_WIDTH-1
        jr    z,.LifeLostTileVertical
        ld    de,_LifeLostBlankTile
        ld    a,LIFE_LOST_ATTR_INTERIOR
        ret

.LifeLostTileVertical:
        ld    de,GfxGameBorderItem
        ld    a,LIFE_LOST_ATTR_BORDER
        ret

.LifeLostTileEdgeRow:
        ld    a,(_LifeLostDrawCol)
        or    a
        jr    z,.LifeLostTileCorner
        cp    LIFE_LOST_WIN_WIDTH-1
        jr    z,.LifeLostTileCorner
        ld    de,GfxGameBorderItem
        ld    a,LIFE_LOST_ATTR_BORDER
        ret

.LifeLostTileCorner:
        ld    de,GfxGameBorderCorner
        ld    a,LIFE_LOST_ATTR_CORNER
        ret

; Draw an 8x8 tile and its attribute at character row B, column C.
; DE - tile data, A - attribute.
_LifeLostDrawCell:
        ld    (_LifeLostTileAttr),a
        push  bc
        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a
        ld    a,c
        add   a,a
        add   a,a
        add   a,a
        ld    c,a
        call  ScreenAddr
        call  DrawChar
        pop   bc

        call  AttrAddr
        ld    a,(_LifeLostTileAttr)
        ld    (hl),a
        ret
;-------------------------------------------------------------------------------

LifeLostState:
        defb  LIFE_LOST_STATE_CLOSED

_LifeLostInputReady:
        defb  0

_LifeLostDrawRow:
        defb  0

_LifeLostDrawCol:
        defb  0

_LifeLostTileAttr:
        defb  0

_LifeLostText:
        defb  "YOU LOST A LIFE", 0

_LifeLostGameOverText:
        defb  "GAME OVER", 0

_LifeLostPromptText:
        defb  "ENTER OR SPACE", 0

_LifeLostBlankTile:
        defb  0, 0, 0, 0, 0, 0, 0, 0
;-------------------------------------------------------------------------------
