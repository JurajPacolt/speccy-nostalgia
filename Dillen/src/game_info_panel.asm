;###############################################################################
;##### Game's info panel. It's showed over the game field, in the first three ###
;##### character rows: the name of the game, the lives, the energy and the ######
;##### description of the actual room. #########################################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - InitGamePanel - The picture of the panel, it's drawn only once. The
;                         lives, the energy and the room's description are drawn
;                         to her free places by the game loop.
InitGamePanel:
        call  CleanGameInfoPanelField

        ; Every character of the picture has her tile in the map.
        ld    ix,PanelMap
        ld    b,0 ; Character row.
_GP_IP_Row:
        ld    c,0 ; Character column.
_GP_IP_Cell:
        ld    a,(ix+0)
        inc   ix
        or    a
        jr    z,_GP_IP_Next ; Empty character.

        dec   a
        ld    l,a
        ld    h,0
        add   hl,hl
        add   hl,hl
        add   hl,hl ; Every tile has eight bytes.
        ld    de,PanelTiles
        add   hl,de
        ex    de,hl ; DE - data of the tile.

        push  bc
        push  de
        call  _GP_CharAddr
        pop   de
        call  DrawChar
        pop   bc

_GP_IP_Next:
        inc   c
        ld    a,c
        cp    GAME_INFO_PANEL_WIDTH
        jr    nz,_GP_IP_Cell
        inc   b
        ld    a,b
        cp    PANEL_PICTURE_ROWS
        jr    nz,_GP_IP_Row

        ; The colors of the picture.
        ld    hl,PanelAttributes
        ld    de,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES
        ld    bc,GAME_INFO_PANEL_WIDTH*PANEL_PICTURE_ROWS
        ldir
        ret
; END - InitGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetGamePanel - Everything in the panel will be drawn again.
ResetGamePanel:
        ld    a,255 ; It's not a valid value, so nothing is showed.
        ld    (_GP_ShowedRoom),a
        ld    (_GP_ShowedLives),a
        ld    (_GP_ShowedEnergy),a
        ld    (_GP_HeartStep),a ; The beat begins with her first step.
        ld    a,1
        ld    (_GP_HeartTimer),a
        ret
; END - ResetGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ShowGamePanel - Main panel method, it's called once per frame. Every
;                         part is drawn again only when her value is changed.
ShowGamePanel:
        ld    a,(ActualRoomInMap)
        ld    hl,_GP_ShowedRoom
        cp    (hl)
        jr    z,_GP_ShowLives
        ld    (hl),a
        call  _GP_DrawDescription

_GP_ShowLives:
        ld    a,(PlayerLives)
        ld    hl,_GP_ShowedLives
        cp    (hl)
        jr    z,_GP_ShowEnergy
        ld    (hl),a
        call  _GP_DrawLives

_GP_ShowEnergy:
        ld    a,(PlayerEnergy)
        ld    hl,_GP_ShowedEnergy
        cp    (hl)
        jr    z,_GP_BeatHearts
        ld    (hl),a
        call  _GP_DrawEnergy
; END - ShowGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_BeatHearts - The hearts of the lives are beating like a live heart.
;                          Every step of the beat has her own image and her own
;                          time, so the beat is not regular: two fast hits and a
;                          rest after them.
_GP_BeatHearts:
        ld    hl,_GP_HeartTimer
        dec   (hl)
        ret   nz ; The actual image of the heart is showed further.

        ; The next step of the beat.
        ld    hl,_GP_HeartStep
        inc   (hl)
        ld    a,(hl)
        cp    PANEL_HEART_BEAT_STEPS
        jr    c,_GP_BH_Step
        xor   a ; The beat begins again.
        ld    (hl),a

_GP_BH_Step:
        ; Every step of the beat has three bytes: her image and her time.
        ld    e,a
        ld    d,0
        ld    h,d
        ld    l,a
        add   hl,hl
        add   hl,de
        ld    de,_GP_HeartBeat
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        inc   hl
        ld    a,(hl)
        ld    (_GP_HeartTimer),a
        ld    (_GP_HeartImage),de
        jp    _GP_DrawLives
; END - _GP_BeatHearts
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_DrawLives - The lives of the player, one heart for one life.
_GP_DrawLives:
        ; Clean the old hearts.
        ld    b,PANEL_LIVES_ROW
        ld    c,PANEL_LIVES_COL
        ld    a,PANEL_LIVES_MAX
        call  _GP_ClearChars

        ld    a,(PlayerLives)
        or    a
        ret   z ; The player is dead.
        cp    PANEL_LIVES_MAX+1
        jr    c,_GP_DL_Hearts
        ld    a,PANEL_LIVES_MAX ; There is no place for more hearts.

_GP_DL_Hearts:
        ld    b,a ; B - number of the hearts.
        ld    c,PANEL_LIVES_COL
_GP_DL_Heart:
        push  bc
        ld    b,PANEL_LIVES_ROW
        push  bc
        call  _GP_CharAddr
        ld    de,(_GP_HeartImage) ; The actual image of the beat.
        call  DrawChar
        pop   bc
        call  _GP_AttrAddr
        ld    (hl),PANEL_HEART_ATTR
        pop   bc
        inc   c
        djnz  _GP_DL_Heart
        ret
; END - _GP_DrawLives
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_DrawEnergy - The energy of the player, like a bar of the cells.
;                          The color of the bar is showing, how bad it is.
_GP_DrawEnergy:
        call  _GP_EnergyColor
        ld    (_GP_BarColor),a

        xor   a
        ld    (_GP_BarCell),a
_GP_DE_Cell:
        ; Is the cell full or empty?
        ld    a,(_GP_BarCell)
        ld    hl,PlayerEnergy
        cp    (hl)
        jr    nc,_GP_DE_Empty
        ld    de,GfxEnergyFull
        ld    a,(_GP_BarColor)
        jr    _GP_DE_Draw
_GP_DE_Empty:
        ld    de,GfxEnergyEmpty
        ld    a,PANEL_ENERGY_EMPTY_ATTR

_GP_DE_Draw:
        push  af ; Attribute of the cell.
        push  de ; Image of the cell.
        ld    a,(_GP_BarCell)
        add   a,PANEL_ENERGY_COL
        ld    c,a
        ld    b,PANEL_ENERGY_ROW
        push  bc
        call  _GP_CharAddr
        pop   bc
        pop   de
        push  bc
        call  DrawChar
        pop   bc
        call  _GP_AttrAddr
        pop   af
        ld    (hl),a

        ld    hl,_GP_BarCell
        inc   (hl)
        ld    a,(hl)
        cp    PANEL_ENERGY_CELLS
        jr    nz,_GP_DE_Cell
        ret
; END - _GP_DrawEnergy
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_EnergyColor - Color of the energy bar, by her actual value.
; return A - attribute.
_GP_EnergyColor:
        ld    a,(PlayerEnergy)
        cp    PANEL_ENERGY_LOW+1
        jr    c,_GP_EC_Low
        cp    PANEL_ENERGY_HALF+1
        jr    c,_GP_EC_Half
        ld    a,PANEL_ENERGY_FULL_ATTR
        ret
_GP_EC_Half:
        ld    a,PANEL_ENERGY_HALF_ATTR
        ret
_GP_EC_Low:
        ld    a,PANEL_ENERGY_LOW_ATTR
        ret
; END - _GP_EnergyColor
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_DrawDescription - The description of the actual room.
_GP_DrawDescription:
        ld    b,PANEL_TEXT_ROW
        ld    c,PANEL_TEXT_COL
        ld    a,PANEL_TEXT_LENGTH
        call  _GP_ClearChars

        ; Address of the text of the actual room.
        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl) ; Room's ID number.
        cp    PANEL_ROOMS_COUNT
        ret   nc
        ld    hl,_GP_RoomTexts
        ld    e,a
        ld    d,0
        add   hl,de
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        push  de
        pop   ix

        ld    b,PANEL_TEXT_ROW
        ld    c,PANEL_TEXT_HALF_COL
        jp    Print4x8 ; The font 4x8, two characters in one character of the screen.
; END - _GP_DrawDescription
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_ClearChars - Clean the pixels of the characters in one row.
; B - character row.
; C - first character column.
; A - number of the characters.
_GP_ClearChars:
        ld    d,a
_GP_CC_Char:
        push  de
        push  bc
        call  _GP_CharAddr
        ld    b,8
_GP_CC_Line:
        ld    (hl),0
        call  DownHL
        djnz  _GP_CC_Line
        pop   bc
        pop   de
        inc   c
        dec   d
        jr    nz,_GP_CC_Char
        ret
; END - _GP_ClearChars
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_FillAttr - Set the same attribute to the characters in one row.
; B - character row.
; C - first character column.
; D - number of the characters.
; E - attribute.
_GP_FillAttr:
        call  _GP_AttrAddr
        ld    b,d
        ld    a,e
_GP_FA_Loop:
        ld    (hl),a
        inc   hl
        djnz  _GP_FA_Loop
        ret
; END - _GP_FillAttr
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_CharAddr - Address of the character in the VRAM.
; B - character row.
; C - character column.
; return HL
_GP_CharAddr:
        push  bc
        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a ; Yos.
        ld    a,c
        add   a,a
        add   a,a
        add   a,a
        ld    c,a ; Xos.
        call  ScreenAddr
        pop   bc
        ret
; END - _GP_CharAddr
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_AttrAddr - Address of the attribute of the character.
; B - character row.
; C - character column.
; return HL
_GP_AttrAddr:
        push  de
        ld    h,0
        ld    l,b
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl ; Row * 32.
        ld    d,0
        ld    e,c
        add   hl,de
        ld    de,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES
        add   hl,de
        pop   de
        ret
; END - _GP_AttrAddr
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - CleanGameInfoPanelField
; Total cleaning game info panel field, reset pixels and attributes.
CleanGameInfoPanelField:
        ; Hide all graphics.
        ld    a,0
        call  SetGameInfoPanelFieldAttributes
        ; Clean pixels.
        ld    hl,GAME_INFO_PANEL_START_ADDRESS
        ld    de,GAME_INFO_PANEL_START_ADDRESS+1
        ld    b,8
.CleanGameInfoPanelField1:
        push  hl
        push  de
        push  bc
        ld    bc,(GAME_INFO_PANEL_WIDTH*GAME_INFO_PANEL_HEIGHT)-1
        ld    (hl),0
        ldir
        pop   bc
        pop   de
        pop   hl
        call  DownHL
        call  DownDE
        djnz  .CleanGameInfoPanelField1
        ; Set base color;
        ld    a,7
        call  SetGameInfoPanelFieldAttributes
        ret
; END - CleanGameInfoPanelField
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetGameInfoPanelFieldAttributes
; A - Attribute color number.
SetGameInfoPanelFieldAttributes:
        ld    hl,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES
        ld    de,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES+1
        ld    bc,(GAME_INFO_PANEL_WIDTH*GAME_INFO_PANEL_HEIGHT)-1
        ld    (hl),a
        ldir
        ret
; END - SetGameInfoPanelFieldAttributes
;-------------------------------------------------------------------------------

; Start address of the game info panel field.
GAME_INFO_PANEL_START_ADDRESS             equ 16384

; Start attributes address of the game info panel field.
GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES  equ 22528

; Info panel width.
GAME_INFO_PANEL_WIDTH equ 32

; Info panel height.
GAME_INFO_PANEL_HEIGHT equ 4

;-------------------------------------------------------------------------------
; Rows of the picture of the panel.
PANEL_PICTURE_ROWS        equ 3

; The lives, one heart for one life. They are in the picture over the flowers.
PANEL_LIVES_ROW           equ 0
PANEL_LIVES_COL           equ 27
PANEL_LIVES_MAX           equ 5

; The energy, like a bar of the cells under the lives.
PANEL_ENERGY_ROW          equ 1
PANEL_ENERGY_COL          equ 22
PANEL_ENERGY_CELLS        equ 10
PANEL_ENERGY_LOW          equ 3 ; Under this value is the bar red.
PANEL_ENERGY_HALF         equ 6 ; Under this value is the bar yellow.

; The description of the room, between the plants on the both edges. It's
; written with the font 4x8, so there is a place for 60 characters.
PANEL_TEXT_ROW            equ 2
PANEL_TEXT_COL            equ 1
PANEL_TEXT_LENGTH         equ 30
PANEL_TEXT_HALF_COL       equ PANEL_TEXT_COL*2

; Number of the rooms in the table with the descriptions.
PANEL_ROOMS_COUNT         equ 12

; Colors of the panel. The colors of the picture are in her data.
PANEL_HEART_ATTR          equ 66 ; Bright red ink.
PANEL_ENERGY_FULL_ATTR    equ 68 ; Bright green ink.
PANEL_ENERGY_HALF_ATTR    equ 70 ; Bright yellow ink.
PANEL_ENERGY_LOW_ATTR     equ 66 ; Bright red ink.
PANEL_ENERGY_EMPTY_ATTR   equ 1  ; Blue ink, the empty cell is only a shadow.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Variables of the panel, they are holding the showed values.
_GP_ShowedRoom:
        defb  255

_GP_ShowedLives:
        defb  255

_GP_ShowedEnergy:
        defb  255

; Actually drawn cell of the energy bar and her color.
_GP_BarCell:
        defb  0

_GP_BarColor:
        defb  0

; Actual step of the beat of the hearts, her time and her image.
_GP_HeartStep:
        defb  255

_GP_HeartTimer:
        defb  1

_GP_HeartImage:
        defw  SpriteDataHeart

;-------------------------------------------------------------------------------
; The beat of the hearts. Every step: image of the heart and how many frames she
; is showed. Two fast hits and a long rest, like a live heart.
_GP_HeartBeat:
        defw  SpriteDataHeart      ; The heart is resting.
        defb  55
        defw  SpriteDataHeartBig   ; The first hit.
        defb  6
        defw  SpriteDataHeartSmall
        defb  5
        defw  SpriteDataHeartBig   ; The second hit.
        defb  6
        defw  SpriteDataHeart
        defb  8
_GP_HeartBeatEnd:

PANEL_HEART_BEAT_STEPS equ (_GP_HeartBeatEnd-_GP_HeartBeat)/3

;-------------------------------------------------------------------------------
; Graphics of the panel.
; One cell of the energy bar, full and empty.
GfxEnergyFull:
        defb  %00000000
        defb  %01111110
        defb  %11111111
        defb  %11101111
        defb  %11110111
        defb  %11111111
        defb  %01111110
        defb  %00000000

GfxEnergyEmpty:
        defb  %00000000
        defb  %01111110
        defb  %10000001
        defb  %10000001
        defb  %10000001
        defb  %10000001
        defb  %01111110
        defb  %00000000

;-------------------------------------------------------------------------------
; Description of every room, the index is the room's ID number.
_GP_RoomTexts:
        defw  _GP_Room000
        defw  _GP_Room001
        defw  _GP_Room002
        defw  _GP_Room003
        defw  _GP_Room004
        defw  _GP_Room005
        defw  _GP_Room006
        defw  _GP_Room007
        defw  _GP_Room008
        defw  _GP_Room009
        defw  _GP_Room010
        defw  _GP_Room011

_GP_Room000:
        defb  "Nowhere", 0
_GP_Room001:
        defb  "The old bridge over the gap", 0
_GP_Room002:
        defb  "The stony plain", 0
_GP_Room003:
        defb  "Rain over the plain", 0
_GP_Room004:
        defb  "Under the clouds", 0
_GP_Room005:
        defb  "The rocky hill", 0
_GP_Room006:
        defb  "The door to the freedom", 0
_GP_Room007:
        defb  "The grassy plain", 0
_GP_Room008:
        defb  "The deep ravine", 0
_GP_Room009:
        defb  "The stone cave", 0
_GP_Room010:
        defb  "The iced cave", 0
_GP_Room011:
        defb  "The low tunnel", 0
;-------------------------------------------------------------------------------
