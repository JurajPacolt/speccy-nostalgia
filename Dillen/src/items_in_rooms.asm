;###############################################################################
;##### Collectible items drawn in the rooms from the original paper map. #######
;###############################################################################

; Public item IDs. They are the numbers written by the items in dillen-map.gif.
ITEM_SHIELD    equ 1
ITEM_WEAPON    equ 2
ITEM_CROSS     equ 3
ITEM_MATCH     equ 4
ITEM_DYNAMITE  equ 5
ITEM_KEY       equ 6
ITEM_COUNT     equ 6

; A state normally contains the room ID in which the item is lying. These two
; values move the item out of all rooms without throwing its identity away.
ITEM_STATE_CARRIED equ 254
ITEM_STATE_USED    equ 255

ITEM_DRAW_RECORD_SIZE equ 4 ; X, Y, sprite address.

;-------------------------------------------------------------------------------
; BEGIN - ItemsInRooms - Draw items once, immediately after a room is redrawn.
ItemsInRooms:
        ld    a,(ActualRoomInMap)
        ld    hl,_ItemsDrawnMapRoom
        cp    (hl)
        ret   z
        ld    (hl),a

        call  _ItemsGetActualRoomId
        ld    (_ItemsActualRoomId),a

        ld    iy,ItemStates
        ld    ix,ItemDrawRecords
        ld    b,ITEM_COUNT
_ItemsDrawLoop:
        ld    a,(iy+0)
        ld    hl,_ItemsActualRoomId
        cp    (hl)
        jr    nz,_ItemsDrawNext

        push  bc
        push  ix
        push  iy
        ld    c,(ix+0)
        ld    b,(ix+1)
        ld    l,(ix+2)
        ld    h,(ix+3)
        push  hl
        pop   ix
        ld    de,22528 ; Draw attributes directly to the Spectrum screen.
        call  DrawSprite
        pop   iy
        pop   ix
        pop   bc

_ItemsDrawNext:
        inc   iy
        ld    de,ITEM_DRAW_RECORD_SIZE
        add   ix,de
        djnz  _ItemsDrawLoop
        ret
; END - ItemsInRooms
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetItems - Put every item back in its room from the paper map.
ResetItems:
        ld    hl,ItemInitialRooms
        ld    de,ItemStates
        ld    bc,ITEM_COUNT
        ldir
        jp    _ItemsRefreshRoom
; END - ResetItems
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - CollectItem - Move an item from the actual room to the inventory.
; A - item ID (ITEM_*).
; return CF=1 - collected, CF=0 - invalid ID or item is not in this room.
; This is intentionally not bound to a key or collision yet; the future hero
; can call it after touching an item.
CollectItem:
        cp    1
        jr    c,_ItemsActionFailed
        cp    ITEM_COUNT+1
        jr    nc,_ItemsActionFailed
        ld    c,a

        call  _ItemsGetActualRoomId
        ld    b,a
        ld    a,c
        call  _ItemsGetStateAddress
        ld    a,(hl)
        cp    b
        jr    nz,_ItemsActionFailed

        ld    (hl),ITEM_STATE_CARRIED
        call  _ItemsRefreshRoom
        scf
        ret
; END - CollectItem
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - UseItem - Consume a carried item at its use location from the map.
; A - item ID (ITEM_*).
; return CF=1 - used, CF=0 - not carried, invalid ID or wrong room.
UseItem:
        cp    1
        jr    c,_ItemsActionFailed
        cp    ITEM_COUNT+1
        jr    nc,_ItemsActionFailed
        ld    c,a

        call  _ItemsGetActualRoomId
        ld    b,a
        ld    a,c
        call  _ItemsGetStateAddress
        ld    a,(hl)
        cp    ITEM_STATE_CARRIED
        jr    nz,_ItemsActionFailed

        push  hl
        ld    a,c
        dec   a
        ld    e,a
        ld    d,0
        ld    hl,ItemUseRooms
        add   hl,de
        ld    a,(hl)
        pop   hl
        cp    b
        jr    nz,_ItemsActionFailed

        ld    (hl),ITEM_STATE_USED
        scf
        ret
; END - UseItem
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - IsItemCarried - Query the inventory state without changing it.
; A - item ID (ITEM_*).
; return CF=1 - carried, CF=0 - not carried or invalid ID.
IsItemCarried:
        cp    1
        jr    c,_ItemsActionFailed
        cp    ITEM_COUNT+1
        jr    nc,_ItemsActionFailed
        call  _ItemsGetStateAddress
        ld    a,(hl)
        cp    ITEM_STATE_CARRIED
        jr    nz,_ItemsActionFailed
        scf
        ret
; END - IsItemCarried
;-------------------------------------------------------------------------------

_ItemsActionFailed:
        or    a ; Clear carry.
        ret

; A - valid item ID, return HL - address of its mutable state.
_ItemsGetStateAddress:
        dec   a
        ld    e,a
        ld    d,0
        ld    hl,ItemStates
        add   hl,de
        ret

; return A - ID of the room currently selected in RoomsMap.
_ItemsGetActualRoomId:
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        ld    hl,RoomsMap
        add   hl,de
        ld    a,(hl)
        ret

; Force a clean redraw. This also removes a just-collected item's old pixels.
_ItemsRefreshRoom:
        ld    a,255
        ld    (_ItemsDrawnMapRoom),a
        ld    (LastShowedRoomInMap),a
        ret

;-------------------------------------------------------------------------------
; Item placement from dillen-map.gif, ordered by ITEM_* ID:
; shield 7, weapon 2, cross 8, match 11, dynamite 5 and key 9.
ItemInitialRooms:
        defb  7, 2, 8, 11, 5, 9

; Room IDs containing the numbered use marks in the drawing. The shield is for
; the falling-stone passage in room 10; the remaining marks are unambiguous.
ItemUseRooms:
        defb  10, 1, 7, 6, 6, 6

; X, Y, sprite. Positions follow the relative placement in the paper rooms and
; avoid the already animated cells (notably the Death in room 7).
ItemDrawRecords:
        defb  5*8, 17*8
        defw  SpriteItemShield
        defb  22*8, 18*8
        defw  SpriteItemWeapon
        defb  14*8, 17*8
        defw  SpriteItemCross
        defb  24*8, 17*8
        defw  SpriteItemMatch
        defb  22*8, 17*8
        defw  SpriteItemDynamite
        defb  10*8, 18*8
        defw  SpriteItemKey

; Mutable item locations/states. ResetItems initializes this table.
ItemStates:
        block  ITEM_COUNT,ITEM_STATE_USED

_ItemsDrawnMapRoom:
        defb  255
_ItemsActualRoomId:
        defb  255

;-------------------------------------------------------------------------------
; Spectrum sprites redrawn from real-object references. Larger objects use
; 24 pixels where their identifying construction would disappear at 16x16.
SpriteItemShield:
        defb  3,24
        defb  %00011111,%11111111,%11111000
        defb  %00110000,%00000000,%00001100
        defb  %01100000,%00000000,%00000110
        defb  %11000000,%00011000,%00000011
        defb  %11000000,%00111100,%00000011
        defb  %11000000,%01111110,%00000011
        defb  %11000000,%11111111,%00000011
        defb  %01100001,%11111111,%10000110
        defb  %01100011,%11111111,%11000110
        defb  %01100001,%11111111,%10000110
        defb  %01100000,%11111111,%00000110
        defb  %00110000,%00111100,%00001100
        defb  %00110000,%00011000,%00001100
        defb  %00011000,%00000000,%00011000
        defb  %00011000,%00000000,%00011000
        defb  %00001100,%00000000,%00110000
        defb  %00001100,%00000000,%00110000
        defb  %00000110,%00000000,%01100000
        defb  %00000110,%00000000,%01100000
        defb  %00000011,%00000000,%11000000
        defb  %00000001,%10000001,%10000000
        defb  %00000000,%11000011,%00000000
        defb  %00000000,%01100110,%00000000
        defb  %00000000,%00111100,%00000000
        defb  69,69,69,69,69,69,69,69,69

SpriteItemWeapon:
        defb  3,16
        defb  %00000000,%00000000,%00110000
        defb  %00000001,%11111111,%11111111
        defb  %00011111,%11111111,%11111111
        defb  %01111111,%11111111,%11111111
        defb  %01111111,%00111111,%11111111
        defb  %00001111,%11111111,%11100000
        defb  %00001100,%00011111,%11100000
        defb  %00011000,%00110000,%11000000
        defb  %00011000,%00110001,%10000000
        defb  %00110000,%01100011,%00000000
        defb  %00110000,%01100110,%00000000
        defb  %01100000,%11001100,%00000000
        defb  %01100001,%10011000,%00000000
        defb  %01100011,%00110000,%00000000
        defb  %00111110,%01100000,%00000000
        defb  %00011100,%00000000,%00000000
        defb  71,71,71,6,6,71

SpriteItemCross:
        defb  3,24
        defb  %00000000,%00011000,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%01111110,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %01111111,%11111111,%11111110
        defb  %11111111,%11111111,%11111111
        defb  %11100111,%11111111,%11100111
        defb  %11111111,%11111111,%11111111
        defb  %01111111,%11111111,%11111110
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%01111110,%00000000
        defb  %00000000,%00111100,%00000000
        defb  %00000000,%00011000,%00000000
        defb  %00000000,%00000000,%00000000
        defb  6,6,6,6,6,6,6,6,6

SpriteItemMatch:
        defb  2,24
        defb  %00000000,%00001100
        defb  %00000000,%00011110
        defb  %00000000,%00111111
        defb  %00000000,%00111111
        defb  %00000000,%00011110
        defb  %00000000,%00001100
        defb  %00000000,%00011000
        defb  %00000000,%00011000
        defb  %00000000,%00110000
        defb  %00000000,%00110000
        defb  %00000000,%01100000
        defb  %00000000,%01100000
        defb  %00000000,%11000000
        defb  %00000000,%11000000
        defb  %00000001,%10000000
        defb  %00000001,%10000000
        defb  %00000011,%00000000
        defb  %00000011,%00000000
        defb  %00000110,%00000000
        defb  %00000110,%00000000
        defb  %00001100,%00000000
        defb  %00001100,%00000000
        defb  %00011000,%00000000
        defb  %00011000,%00000000
        defb  70,66,70,70,70,70

SpriteItemDynamite:
        defb  3,24
        defb  %00000000,%00000000,%01100000
        defb  %00000000,%00000000,%11000000
        defb  %00000000,%00000001,%10000000
        defb  %00000000,%00000011,%00000000
        defb  %00000000,%00000110,%00000000
        defb  %00000000,%00001100,%00000000
        defb  %00000000,%00011000,%00000000
        defb  %00000000,%00110000,%00000000
        defb  %00011100,%00111000,%01110000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00100000,%00000000,%00001000
        defb  %00100000,%00000000,%00001000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00100000,%00000000,%00001000
        defb  %00100000,%00000000,%00001000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00111110,%01111100,%11111000
        defb  %00011100,%00111000,%01110000
        defb  66,70,70,66,66,66,66,66,66

SpriteItemKey:
        defb  3,16
        defb  %00000000,%00000000,%00000000
        defb  %00011110,%00000000,%00000000
        defb  %00110011,%00000000,%00000000
        defb  %01100001,%10000000,%00000000
        defb  %11000000,%11000000,%00000000
        defb  %11000000,%11000000,%00000000
        defb  %01100001,%10000000,%00000000
        defb  %00110011,%11111111,%11111111
        defb  %00011111,%11111111,%11111111
        defb  %00000000,%00000000,%00011100
        defb  %00000000,%00000000,%01111100
        defb  %00000000,%00000000,%01110000
        defb  %00000000,%00000001,%11110000
        defb  %00000000,%00000001,%10000000
        defb  %00000000,%00000000,%00000000
        defb  %00000000,%00000000,%00000000
        defb  6,6,6,6,6,6
;-------------------------------------------------------------------------------
