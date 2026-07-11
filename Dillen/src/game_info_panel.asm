;###############################################################################
;##### Game's info panel. It's showed over the game field, in the first three ###
;##### character rows: the name of the game, the lives, the energy and the ######
;##### description of the actual room. #########################################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - InitGamePanel - Static graphics of the panel, it's drawn only once.
InitGamePanel:
        call  CleanGameInfoPanelField

        ; The rule over the game field, with the pattern of her border.
        ld    c,0
_GP_InitRule:
        push  bc
        ld    b,PANEL_TITLE_ROW
        push  bc
        call  _GP_CharAddr
        ld    de,GfxGameBorderItem
        call  DrawChar
        pop   bc
        call  _GP_AttrAddr
        ld    (hl),PANEL_RULE_ATTR
        pop   bc
        inc   c
        ld    a,c
        cp    GAME_INFO_PANEL_WIDTH
        jr    nz,_GP_InitRule

        ; The name of the game, like a plate on the middle of the rule.
        ld    ix,_GP_TitleText
        ld    b,PANEL_TITLE_ROW
        ld    c,PANEL_TITLE_COL
        call  _GP_PrintText
        ld    b,PANEL_TITLE_ROW
        ld    c,PANEL_TITLE_COL
        ld    d,PANEL_TITLE_LENGTH
        ld    e,PANEL_TITLE_ATTR
        call  _GP_FillAttr

        ; The label of the energy.
        ld    ix,_GP_EnergyText
        ld    b,PANEL_INFO_ROW
        ld    c,PANEL_ENERGY_LABEL_COL
        call  _GP_PrintText
        ld    b,PANEL_INFO_ROW
        ld    c,PANEL_ENERGY_LABEL_COL
        ld    d,PANEL_ENERGY_LABEL_LENGTH
        ld    e,PANEL_LABEL_ATTR
        call  _GP_FillAttr

        ; The color of the room's description.
        ld    b,PANEL_TEXT_ROW
        ld    c,0
        ld    d,GAME_INFO_PANEL_WIDTH
        ld    e,PANEL_TEXT_ATTR
        call  _GP_FillAttr

        ; The lives, the energy and the description are drawn by the game loop.
; END - InitGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetGamePanel - Everything in the panel will be drawn again.
ResetGamePanel:
        ld    a,255 ; It's not a valid value, so nothing is showed.
        ld    (_GP_ShowedRoom),a
        ld    (_GP_ShowedLives),a
        ld    (_GP_ShowedEnergy),a
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
        ret   z
        ld    (hl),a
        jp    _GP_DrawEnergy
; END - ShowGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_DrawLives - The lives of the player, one heart for one life.
_GP_DrawLives:
        ; Clean the old hearts.
        ld    b,PANEL_INFO_ROW
        ld    c,PANEL_LIVES_COL
        ld    a,PANEL_LIVES_MAX*2
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
        ld    b,PANEL_INFO_ROW
        push  bc
        call  _GP_CharAddr
        ld    de,SpriteDataHeart
        call  DrawChar
        pop   bc
        call  _GP_AttrAddr
        ld    (hl),PANEL_HEART_ATTR
        pop   bc
        inc   c
        inc   c ; One empty character between two hearts.
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
        ld    b,PANEL_INFO_ROW
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
        ld    c,0
        ld    a,GAME_INFO_PANEL_WIDTH
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
        ld    c,PANEL_TEXT_COL
        jp    _GP_PrintText
; END - _GP_DrawDescription
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_PrintText - Print the text to the panel.
; IX - Address of the text.
; B - character row.
; C - character column.
_GP_PrintText:
        call  _GP_CharAddr
        ex    de,hl ; DE - address in the VRAM.
        ld    hl,@MainFontData
        jp    Print
; END - _GP_PrintText
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
; Rows of the panel.
PANEL_TITLE_ROW           equ 0 ; The rule with the name of the game.
PANEL_INFO_ROW            equ 1 ; The lives and the energy.
PANEL_TEXT_ROW            equ 2 ; The description of the room.

; The name of the game.
PANEL_TITLE_COL           equ 12
PANEL_TITLE_LENGTH        equ 8

; The lives, one heart for one life, with a space between them.
PANEL_LIVES_COL           equ 1
PANEL_LIVES_MAX           equ 5

; The energy.
PANEL_ENERGY_LABEL_COL    equ 12
PANEL_ENERGY_LABEL_LENGTH equ 6
PANEL_ENERGY_COL          equ 19
PANEL_ENERGY_CELLS        equ 10
PANEL_ENERGY_LOW          equ 3 ; Under this value is the bar red.
PANEL_ENERGY_HALF         equ 6 ; Under this value is the bar yellow.

; The description of the room.
PANEL_TEXT_COL            equ 1

; Number of the rooms in the table with the descriptions.
PANEL_ROOMS_COUNT         equ 12

; Colors of the panel.
PANEL_RULE_ATTR           equ 8  ; Black ink on blue, like the game's border.
PANEL_TITLE_ATTR          equ 79 ; Bright white ink on blue.
PANEL_HEART_ATTR          equ 66 ; Bright red ink.
PANEL_LABEL_ATTR          equ 70 ; Bright yellow ink.
PANEL_TEXT_ATTR           equ 71 ; Bright white ink.
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
; Texts of the panel.
_GP_TitleText:
        defb  " DILLEN ", 0

_GP_EnergyText:
        defb  "ENERGY", 0

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
