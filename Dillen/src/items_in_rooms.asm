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
ITEM_SPRITE_HEIGHT    equ 16

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

        ; Dropping changes an item's X and Y, so a new game must restore the
        ; complete placement from the paper map as well as the room states.
        ld    hl,ItemInitialDrawRecords
        ld    de,ItemDrawRecords
        ld    bc,ITEM_COUNT*ITEM_DRAW_RECORD_SIZE
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
        jp    c,_ItemsActionFailed
        cp    ITEM_COUNT+1
        jp    nc,_ItemsActionFailed
        ld    c,a

        call  _ItemsGetActualRoomId
        ld    b,a
        ld    a,c
        call  _ItemsGetStateAddress
        ld    a,(hl)
        cp    b
        jp    nz,_ItemsActionFailed

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
        jp    c,_ItemsActionFailed
        cp    ITEM_COUNT+1
        jp    nc,_ItemsActionFailed
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
        call  _ItemsRefreshRoom
        scf
        ret
; END - UseItem
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - IsBridgeHoleOpen - Query the permanent state of the old bridge.
; return Z - the pickaxe has opened the hole, NZ - the bridge is still whole.
IsBridgeHoleOpen:
        ld    a,(ItemStates+ITEM_PICKAXE-1)
        cp    ITEM_STATE_USED
        ret
; END - IsBridgeHoleOpen
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ApplyUsedItemsToRoom - Apply permanent item effects after ShowRoom
; has drawn the static sprites and before it copies their attributes.
ApplyUsedItemsToRoom:
        call  _ItemsGetActualRoomId
        cp    BRIDGE_ROOM_ID
        ret   nz

        call  IsBridgeHoleOpen
        ret   nz

        ld    ix,SpriteBridgeHole
        ld    b,BRIDGE_HOLE_Y
        ld    c,BRIDGE_HOLE_X
        ld    de,RoomsAttrCache
        jp    DrawSprite
; END - ApplyUsedItemsToRoom
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

;-------------------------------------------------------------------------------
; BEGIN - DropItem - Move a carried item out of the inventory, into the room the
; player is currently standing in.
; A - item ID (ITEM_*).
; return CF=1 - dropped, CF=0 - invalid ID or the item is not carried.
DropItem:
        cp    1
        jr    c,_ItemsActionFailed
        cp    ITEM_COUNT+1
        jr    nc,_ItemsActionFailed
        ld    c,a

        call  _ItemsGetActualRoomId
        ld    b,a ; The room he is standing in now.
        ld    a,c
        call  _ItemsGetStateAddress
        ld    a,(hl)
        cp    ITEM_STATE_CARRIED
        jr    nz,_ItemsActionFailed

        ld    (hl),b

        ; Point HL at this item's mutable draw record. DrawSprite works on byte
        ; columns, therefore keep X on the same grid while aligning the bottom
        ; of the 16-pixel item with the player's feet.
        ld    a,c
        dec   a
        add   a,a
        add   a,a
        ld    e,a
        ld    d,0
        ld    hl,ItemDrawRecords
        add   hl,de

        ld    a,(PlayerX)
        and   %11111000
        ld    (hl),a
        inc   hl
        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT-ITEM_SPRITE_HEIGHT
        ld    (hl),a

        call  _ItemsRefreshRoom
        scf
        ret
; END - DropItem
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ItemsForceRedraw - Public entry point to force the room and her items
; to be drawn again from scratch, e.g. after the inventory window has painted
; over the game field.
ItemsForceRedraw:
        jp    _ItemsRefreshRoom
; END - ItemsForceRedraw
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
ItemInitialDrawRecords:
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

; Mutable X, Y and sprite records. ResetItems restores the initial placement.
ItemDrawRecords:
        block  ITEM_COUNT*ITEM_DRAW_RECORD_SIZE,0

; Names of the items, for the inventory window. Indexed by ID-1.
ItemNames:
        defw  _ItemNamePickaxe
        defw  _ItemNameCross
        defw  _ItemNameMatch
        defw  _ItemNameDynamite
        defw  _ItemNameKey

_ItemNamePickaxe:
        defb  "Pickaxe", 0
_ItemNameCross:
        defb  "Cross", 0
_ItemNameMatch:
        defb  "Match", 0
_ItemNameDynamite:
        defb  "Dynamite", 0
_ItemNameKey:
        defb  "Key", 0

; Mutable item locations/states. ResetItems initializes this table.
ItemStates:
        block  ITEM_COUNT,ITEM_STATE_USED

_ItemsDrawnMapRoom:
        defb  255
_ItemsActualRoomId:
        defb  255

;-------------------------------------------------------------------------------
; Three empty cells overwrite the middle of the bridge. Their white-ink
; attributes describe non-solid scenery to the player collision code, while
; the zero bitmap leaves a clearly visible black opening.
SpriteBridgeHole:
        defb  BRIDGE_HOLE_WIDTH,8
        block BRIDGE_HOLE_WIDTH*8,0
        block BRIDGE_HOLE_WIDTH,71

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
