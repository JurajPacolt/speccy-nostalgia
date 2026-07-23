;###############################################################################
;##### Successful end of the game after Dillen enters the castle exit. ########
;###############################################################################

GAME_WON_STATE_CLOSED          equ 0
GAME_WON_STATE_MESSAGE_PENDING equ 1
GAME_WON_STATE_MESSAGE_OPEN    equ 2
GAME_WON_STATE_PICTURE         equ 3

GAME_WON_ATTR_BODY             equ 79 ; Bright white ink on blue paper.
GAME_WON_ATTR_TITLE            equ 78 ; Bright yellow ink on blue paper.
GAME_WON_ATTR_PROMPT           equ 77 ; Bright cyan ink on blue paper.

;-------------------------------------------------------------------------------
; BEGIN - GameWonReset - Restore the ending sequence for a new game.
GameWonReset:
        xor   a
        ld    (GameWonState),a
        ld    (_GameWonInputReady),a
        ret
; END - GameWonReset
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - GameWonCheckDoorEntry - Start the ending when Dillen walks fully into
; the unlocked door at the left edge of Room006.
GameWonCheckDoorEntry:
        call  IsKeyUsed
        ret   nz

        call  _ItemsGetActualRoomId
        cp    CASTLE_ROOM_ID
        ret   nz

        ld    a,(PlayerX)
        cp    CASTLE_DOOR_X+1
        ret   nc

        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        cp    CASTLE_DOOR_Y
        ret   c

        ld    a,GAME_WON_STATE_MESSAGE_PENDING
        ld    (GameWonState),a
        xor   a
        ld    (_GameWonInputReady),a
        ret
; END - GameWonCheckDoorEntry
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - GameWonHandle - Run the modal message and then hold the ending image.
GameWonHandle:
        ld    a,(GameWonState)
        cp    GAME_WON_STATE_MESSAGE_PENDING
        jr    z,_GameWonOpenMessage
        cp    GAME_WON_STATE_MESSAGE_OPEN
        ret   nz ; The full-screen picture remains visible forever.

        ; Wait for both keys to be released before accepting the next press.
        ld    a,(_GameWonInputReady)
        or    a
        jr    nz,.GameWonCheckPressed

        ld    bc,49150 ; ENTER.
        in    a,(c)
        bit   0,a
        ret   z
        ld    bc,32766 ; SPACE.
        in    a,(c)
        bit   0,a
        ret   z
        ld    a,1
        ld    (_GameWonInputReady),a
        ret

.GameWonCheckPressed:
        ld    bc,49150
        in    a,(c)
        bit   0,a
        jr    z,_GameWonShowPicture
        ld    bc,32766
        in    a,(c)
        bit   0,a
        ret   nz

_GameWonShowPicture:
        ld    a,GAME_WON_STATE_PICTURE
        ld    (GameWonState),a
        xor   a
        out   (254),a ; Black hardware border around the ending artwork.
        ld    hl,GameWonPicture
        ld    de,16384
        ld    bc,6912
        ldir
        ret
; END - GameWonHandle
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw a dedicated blue victory page before revealing the final illustration.
_GameWonOpenMessage:
        ld    a,GAME_WON_STATE_MESSAGE_OPEN
        ld    (GameWonState),a
        call  ClearScreenToBlack
        ld    a,GAME_WON_ATTR_BODY
        call  SetScreenAttributes

        ld    a,GAME_WON_ATTR_TITLE
        ld    b,4
        call  _GameWonSetAttrRow
        ld    a,GAME_WON_ATTR_PROMPT
        ld    b,18
        call  _GameWonSetAttrRow

        ld    ix,_GameWonTitle
        ld    b,4
        ld    c,23
        call  Print4x8

        ld    ix,_GameWonLine1
        ld    b,8
        ld    c,22
        call  Print4x8
        ld    ix,_GameWonLine2
        ld    b,10
        ld    c,19
        call  Print4x8
        ld    ix,_GameWonLine3
        ld    b,12
        ld    c,20
        call  Print4x8

        ld    ix,_GameWonPrompt
        ld    b,18
        ld    c,22
        jp    Print4x8

; Set all 32 attribute cells of character row B to A.
_GameWonSetAttrRow:
        ld    (_GameWonTempAttr),a
        ld    l,b
        ld    h,0
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl
        ld    de,22528
        add   hl,de
        ld    a,(_GameWonTempAttr)
        ld    (hl),a
        ld    d,h
        ld    e,l
        inc   de
        ld    bc,31
        ldir
        ret
;-------------------------------------------------------------------------------

GameWonState:
        defb  GAME_WON_STATE_CLOSED

_GameWonInputReady:
        defb  0

_GameWonTempAttr:
        defb  0

_GameWonTitle:
        defb  "EXCELLENT, DILLEN!", 0
_GameWonLine1:
        defb  "YOU CLEVERLY OVERCAME", 0
_GameWonLine2:
        defb  "EVERY OBSTACLE AND MADE IT", 0
_GameWonLine3:
        defb  "ALL THE WAY TO THE END!", 0
_GameWonPrompt:
        defb  "PRESS ENTER OR SPACE", 0

; Exact 256x192 Spectrum bitmap (6144 bitmap bytes and 768 attributes).
GameWonPicture:
        incbin  "binary/game-won.scr"
;-------------------------------------------------------------------------------
