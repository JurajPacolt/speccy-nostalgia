;###############################################################################
;##### Collectible items drawn in the rooms from the original paper map. #######
;###############################################################################

; Public item IDs. They are the numbers written by the items in dillen-map.gif.
ITEM_PICKAXE   equ 1
ITEM_CROSS     equ 2
ITEM_MATCH     equ 3
ITEM_DYNAMITE  equ 4
ITEM_KEY       equ 5
ITEM_COUNT     equ 5

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
; pickaxe 2, cross 8, match 11, dynamite 5 and key 9.
ItemInitialRooms:
        defb  2, 8, 11, 5, 9

; Room IDs containing the numbered use marks in the drawing.
ItemUseRooms:
        defb  1, 7, 6, 6, 6

; X, Y, sprite. Positions follow the relative placement in the paper rooms and
; every 16x16 footprint stays in empty cells immediately above the terrain.
ItemDrawRecords:
        defb  25*8, 18*8
        defw  SpriteItemPickaxe
        defb  14*8, 17*8
        defw  SpriteItemCross
        defb  24*8, 17*8
        defw  SpriteItemMatch
        defb  16*8, 17*8
        defw  SpriteItemDynamite
        defb  12*8, 18*8
        defw  SpriteItemKey

; Mutable item locations/states. ResetItems initializes this table.
ItemStates:
        block  ITEM_COUNT,ITEM_STATE_USED

_ItemsDrawnMapRoom:
        defb  255
_ItemsActualRoomId:
        defb  255

;-------------------------------------------------------------------------------
; Spectrum sprites use the same high-contrast, slightly rough silhouettes as
; the cave scenery. Bright colors keep small items readable on black ground.
SpriteItemPickaxe:
        defb  2,16
        defb  %00000011,%11000000
        defb  %00011111,%11111000
        defb  %01111101,%10111110
        defb  %11100001,%10000111
        defb  %10000001,%10000001
        defb  %00000001,%11000000
        defb  %00000001,%11000000
        defb  %00000000,%11100000
        defb  %00000000,%11100000
        defb  %00000000,%01110000
        defb  %00000000,%01110000
        defb  %00000000,%00111000
        defb  %00000000,%00111000
        defb  %00000000,%00011100
        defb  %00000000,%00011100
        defb  %00000000,%00001110
        ; Steel head arches up in the middle and curves both tips downward.
        defb  71,71,70,70

SpriteItemCross:
        defb  2,16
        defb  %00000011,%11000000
        defb  %00000111,%11100000
        defb  %00000011,%11000000
        defb  %00000011,%11000000
        defb  %01111111,%11111110
        defb  %11111111,%11111111
        defb  %01111011,%11011110
        defb  %01111111,%11111110
        defb  %00000011,%11000000
        defb  %00000011,%11000000
        defb  %00000011,%11000000
        defb  %00000011,%11000000
        defb  %00000011,%11000000
        defb  %00000111,%11100000
        defb  %00000011,%11000000
        defb  %00000000,%00000000
        defb  70,70,70,70

SpriteItemMatch:
        defb  2,16
        defb  %00000000,%00110000
        defb  %00000000,%01111000
        defb  %00000000,%11111100
        defb  %00000000,%01111000
        defb  %00000000,%00110000
        defb  %00000000,%01100000
        defb  %00000000,%11000000
        defb  %00000001,%10000000
        defb  %00000011,%00000000
        defb  %00000110,%00000000
        defb  %00001100,%00000000
        defb  %00011000,%00000000
        defb  %00110000,%00000000
        defb  %01100000,%00000000
        defb  %11000000,%00000000
        defb  %00000000,%00000000
        ; Unlit red match head over its yellow wooden stem.
        defb  70,66,70,70

SpriteItemDynamite:
        defb  2,16
        defb  %00000000,%00001000
        defb  %00000000,%00011100
        defb  %00000000,%00001000
        defb  %00000000,%00110000
        defb  %00000000,%11100000
        defb  %00000011,%10000000
        defb  %00000110,%00000000
        defb  %00000110,%00000000
        defb  %01111011,%11011110
        defb  %01111011,%11011110
        defb  %01001010,%01010010
        defb  %01001010,%01010010
        defb  %01111011,%11011110
        defb  %01111011,%11011110
        defb  %01111011,%11011110
        defb  %00110001,%10001100
        ; Yellow fuse above three compact red sticks and their bindings.
        defb  70,70,66,66

SpriteItemKey:
        defb  2,16
        defb  %00000000,%00000000
        defb  %00111100,%00000000
        defb  %01100110,%00000000
        defb  %11000011,%00000000
        defb  %11000011,%11111111
        defb  %01100111,%11111111
        defb  %00111100,%00000110
        defb  %00000000,%00000110
        defb  %00000000,%00001111
        defb  %00000000,%00001100
        defb  %00000000,%00001111
        defb  %00000000,%00000011
        defb  %00000000,%00000000
        defb  %00000000,%00000000
        defb  %00000000,%00000000
        defb  %00000000,%00000000
        ; Bright brass above, darker yellow teeth below for simple depth.
        defb  70,70,6,6
;-------------------------------------------------------------------------------
