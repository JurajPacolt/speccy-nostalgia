;###############################################################################
;##### The game's panel. It takes the first five character rows over the ########
;##### field: the blackletter name of the game with the island under the ########
;##### moon, the lives of the shipwright as skulls, his energy as a row of ######
;##### stones, and the name of the room he stands in. ##########################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - InitGamePanel - The still picture of the panel; it is drawn only once.
;                         The skulls, the energy and the name of the room are
;                         drawn into its empty places by the game loop.
InitGamePanel:
        call  CleanGameInfoPanelField

        ; Every character of the picture has its tile in the map.
        ld    ix,PanelMap
        ld    b,0 ; Character row.
_GP_IP_Row:
        ld    c,0 ; Character column.
_GP_IP_Cell:
        ld    a,(ix+0)
        inc   ix
        or    a
        jr    z,_GP_IP_Next ; The empty character is not stored.

        dec   a
        ld    l,a
        ld    h,0
        add   hl,hl
        add   hl,hl
        add   hl,hl ; Every tile has eight bytes.
        ld    de,PanelTiles
        add   hl,de
        ex    de,hl ; DE - the data of the tile.

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

        ; The colours of the picture.
        ld    hl,PanelAttributes
        ld    de,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES
        ld    bc,GAME_INFO_PANEL_WIDTH*PANEL_PICTURE_ROWS
        ldir
        ret
; END - InitGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetGamePanel - Everything in the panel is drawn again.
ResetGamePanel:
        ld    a,255 ; Not a valid value, so nothing is held as shown.
        ld    (_GP_ShowedRoom),a
        ld    (_GP_ShowedLives),a
        ld    (_GP_ShowedEnergy),a
        ld    (_GP_SkullStep),a ; The gnashing begins with its first step.
        ld    a,1
        ld    (_GP_SkullTimer),a
        ret
; END - ResetGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ShowGamePanel - The main routine of the panel, called once per frame.
;                         Every part is drawn again only when its value changed.
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
        jr    z,_GP_ShowSkulls
        ld    (hl),a
        call  _GP_DrawEnergy

_GP_ShowSkulls:
        jp    _GP_GnashSkulls
; END - ShowGamePanel
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_GnashSkulls - The skulls of the lives are not still: they wait for
;                           a long while, a light passes through their eyes and
;                           then their jaws snap twice. Every step of it has its
;                           own picture and its own time.
_GP_GnashSkulls:
        ld    hl,_GP_SkullTimer
        dec   (hl)
        ret   nz ; The picture that is shown stays a while longer.

        ld    hl,_GP_SkullStep
        inc   (hl)
        ld    a,(hl)
        cp    PANEL_SKULL_STEPS
        jr    c,_GP_GS_Step
        xor   a ; It begins again.
        ld    (hl),a

_GP_GS_Step:
        ; Every step has three bytes: its picture and its time.
        ld    e,a
        ld    d,0
        ld    h,d
        ld    l,a
        add   hl,hl
        add   hl,de
        ld    de,_GP_SkullGnash
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        inc   hl
        ld    a,(hl)
        ld    (_GP_SkullTimer),a
        ld    (_GP_SkullImage),de
        jp    _GP_DrawLives
; END - _GP_GnashSkulls
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_DrawLives - The lives of the player, one skull for one life.
_GP_DrawLives:
        ; Wipe the old skulls away.
        ld    b,PANEL_LIVES_ROW
        ld    c,PANEL_LIVES_COL
        ld    a,PANEL_LIVES_MAX
        call  _GP_ClearChars

        ld    a,(PlayerLives)
        or    a
        ret   z ; The player is dead, there is nothing to show.
        cp    PANEL_LIVES_MAX+1
        jr    c,_GP_DL_Skulls
        ld    a,PANEL_LIVES_MAX ; There is no room for more skulls.

_GP_DL_Skulls:
        ld    b,a ; B - how many skulls.
        ld    c,PANEL_LIVES_COL
_GP_DL_Skull:
        push  bc
        ld    b,PANEL_LIVES_ROW
        push  bc
        call  _GP_CharAddr
        ld    de,(_GP_SkullImage) ; The picture of the actual step.
        call  DrawChar
        pop   bc
        call  _GP_AttrAddr
        ld    (hl),PANEL_SKULL_ATTR
        pop   bc
        inc   c
        djnz  _GP_DL_Skull
        ret
; END - _GP_DrawLives
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_DrawEnergy - The energy of the player, a row of stones. The colour
;                          of the row tells how bad it already is.
_GP_DrawEnergy:
        call  _GP_EnergyColor
        ld    (_GP_BarColor),a

        xor   a
        ld    (_GP_BarCell),a
_GP_DE_Cell:
        ; Is this stone still there, or is it already spent?
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
        push  af ; The attribute of the cell.
        push  de ; The picture of the cell.
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
; BEGIN - _GP_EnergyColor - The colour of the energy, by how much of it is left.
; return A - the attribute
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
; BEGIN - _GP_DrawDescription - The name of the room the player stands in, in
;                               the gothic font, in the middle of the last row
;                               of the panel.
_GP_DrawDescription:
        ld    b,PANEL_TEXT_ROW
        ld    c,PANEL_TEXT_COL
        ld    a,PANEL_TEXT_LENGTH
        call  _GP_ClearChars

        ; The room's number in the map gives its identity, and that gives the
        ; address of its name.
        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl)
        cp    PANEL_ROOMS_COUNT
        ret   nc ; A wall of the map has no name.
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

        ; How long the name is, so it can stand in the middle.
        ld    b,0
        push  ix
        pop   hl
_GP_DD_Length:
        ld    a,(hl)
        or    a
        jr    z,_GP_DD_Center
        inc   hl
        inc   b
        jr    _GP_DD_Length

_GP_DD_Center:
        ld    a,PANEL_TEXT_LENGTH
        sub   b
        jr    nc,_GP_DD_Fits
        xor   a ; A name longer than the row begins at its first character.
_GP_DD_Fits:
        srl   a
        ld    c,a
        ld    b,PANEL_TEXT_ROW
        call  _GP_CharAddr
        ex    de,hl ; DE - the place on the screen.
        ld    hl,Font8x8
        jp    Print
; END - _GP_DrawDescription
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _GP_ClearChars - Erase the pixels of some characters in one row.
; B - the character row
; C - the first character column
; A - how many characters
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
; BEGIN - _GP_CharAddr - The address of a character of the panel in the VRAM.
; B - the character row, C - the character column
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
; BEGIN - _GP_AttrAddr - The address of the attribute of a character.
; B - the character row, C - the character column
; return HL
_GP_AttrAddr:
        push  de
        ld    h,0
        ld    l,b
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl ; The row, times 32.
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
; BEGIN - CleanGameInfoPanelField - Erase the whole panel, pixels and colours.
CleanGameInfoPanelField:
        ld    a,0
        call  SetGameInfoPanelFieldAttributes
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
        ld    a,7
        call  SetGameInfoPanelFieldAttributes
        ret
; END - CleanGameInfoPanelField
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetGameInfoPanelFieldAttributes
; A - the attribute
SetGameInfoPanelFieldAttributes:
        ld    hl,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES
        ld    de,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES+1
        ld    bc,(GAME_INFO_PANEL_WIDTH*GAME_INFO_PANEL_HEIGHT)-1
        ld    (hl),a
        ldir
        ret
; END - SetGameInfoPanelFieldAttributes
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Where the panel is and what stands where inside it: all of it is in screen.asm.

;-------------------------------------------------------------------------------
; The variables of the panel; they hold what is on the screen right now.
_GP_ShowedRoom:
        defb  255

_GP_ShowedLives:
        defb  255

_GP_ShowedEnergy:
        defb  255

; The cell of the energy that is being drawn, and its colour.
_GP_BarCell:
        defb  0

_GP_BarColor:
        defb  0

; The actual step of the gnashing of the skulls, its time and its picture.
_GP_SkullStep:
        defb  255

_GP_SkullTimer:
        defb  1

_GP_SkullImage:
        defw  SpriteDataSkull

;-------------------------------------------------------------------------------
; The gnashing of the skulls. Every step: the picture and how many frames it is
; shown. A long rest, a light in the eyes, and two snaps of the jaw.
_GP_SkullGnash:
        defw  SpriteDataSkull        ; Nothing happens, for two seconds.
        defb  100
        defw  SpriteDataSkullGlint   ; A light passes through the eyes.
        defb  8
        defw  SpriteDataSkull
        defb  6
        defw  SpriteDataSkullChatter ; The first snap.
        defb  7
        defw  SpriteDataSkull
        defb  7
        defw  SpriteDataSkullChatter ; The second one.
        defb  7
        defw  SpriteDataSkull
        defb  25
_GP_SkullGnashEnd:

PANEL_SKULL_STEPS equ (_GP_SkullGnashEnd-_GP_SkullGnash)/3

;-------------------------------------------------------------------------------
; The name of every room, the index is the number of the room.
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
        defw  _GP_Room012
        defw  _GP_Room013
        defw  _GP_Room014
        defw  _GP_Room015
        defw  _GP_Room016
        defw  _GP_Room017
        defw  _GP_Room018
        defw  _GP_Room019
        defw  _GP_Room020
        defw  _GP_Room021
        defw  _GP_Room022
        defw  _GP_Room023

; The gothic font is eight pixels wide, so a name has to hold to the 32
; characters of the row.
_GP_Room000:
        defb  "NOWHERE", 0
_GP_Room001:
        defb  "THE UPPER GARDEN", 0
_GP_Room002:
        defb  "THE HIGH LADDER", 0
_GP_Room003:
        defb  "THE SPIKE PASSAGE", 0
_GP_Room004:
        defb  "THE SAWYER", 0
_GP_Room005:
        defb  "THE RAIN CATCHER", 0
_GP_Room006:
        defb  "THE CHARRED ROPE", 0
_GP_Room007:
        defb  "THE BRICK BARRIER", 0
_GP_Room008:
        defb  "THE ROPE LEDGE", 0
_GP_Room009:
        defb  "THE EMPTY LANDING", 0
_GP_Room010:
        defb  "THE LOWER TREE", 0
_GP_Room011:
        defb  "THE SCREWDRIVER MAN", 0
_GP_Room012:
        defb  "THE HANGING FIRE", 0
_GP_Room013:
        defb  "THE MAN WITH PLIERS", 0
_GP_Room014:
        defb  "THE SHIPWRECK", 0
_GP_Room015:
        defb  "THE SPIKE SHAFT", 0
_GP_Room016:
        defb  "THE EMPTY PASSAGE", 0
_GP_Room017:
        defb  "THE LONG LADDER", 0
_GP_Room018:
        defb  "THE RAIN GALLERY", 0
_GP_Room019:
        defb  "THE DEEP LADDER", 0
_GP_Room020:
        defb  "THE SILENT CELL", 0
_GP_Room021:
        defb  "THE BROKEN LADDER", 0
_GP_Room022:
        defb  "THE GUILLOTINE", 0
_GP_Room023:
        defb  "THE LOWEST RAIN", 0
;-------------------------------------------------------------------------------
