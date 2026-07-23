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
        jp    _ItemsDrawCastleDynamite
; END - ItemsInRooms
;-------------------------------------------------------------------------------

; Draw the planted dynamite directly to the screen like an ordinary room item.
; It remains visible at the foot of the wall until the match is used.
_ItemsDrawCastleDynamite:
        ld    a,(_ItemsActualRoomId)
        cp    CASTLE_ROOM_ID
        ret   nz

        call  IsDynamiteUsed
        ret   nz
        call  IsMatchUsed
        ret   z

        ld    ix,SpriteItemDynamite
        ld    b,CASTLE_DYNAMITE_Y
        ld    c,CASTLE_DYNAMITE_X
        ld    de,22528
        jp    DrawSprite

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

        xor   a
        ld    (_CastleExplosionTimer),a
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
; return CF=1 - used, CF=0 - not carried, invalid ID, wrong room or too far
; from the item-specific target.
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
        jp    nz,_ItemsActionFailed

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
        jp    nz,_ItemsActionFailed

        ; Some item marks cover a whole room on the paper map, but the actions
        ; themselves work only beside their exact target.
        ld    a,c
        cp    ITEM_CROSS
        jr    z,.UseCross
        cp    ITEM_DYNAMITE
        jr    z,.UseDynamite
        cp    ITEM_MATCH
        jr    z,.UseMatch
        jr    .UseItemReady

.UseCross:
        push  hl
        call  CanUseCrossAtDeath
        pop   hl
        jp    nc,_ItemsActionFailed
        jr    .UseItemReady

.UseDynamite:
        push  hl
        call  CanUseCastleItemAtWall
        pop   hl
        jp    nc,_ItemsActionFailed
        jr    .UseItemReady

.UseMatch:
        push  hl
        call  CanLightCastleDynamite
        pop   hl
        jp    nc,_ItemsActionFailed

.UseItemReady:
        ld    (hl),ITEM_STATE_USED

        ; Lighting the planted dynamite begins a short blocking explosion. The
        ; passage becomes solid-free only when its last frame is erased.
        ld    a,c
        cp    ITEM_MATCH
        jr    nz,.UseItemRefresh
        ld    a,CASTLE_EXPLOSION_FRAMES
        ld    (_CastleExplosionTimer),a

.UseItemRefresh:
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
; BEGIN - IsCrossUsed - Query the permanent frightened state of the Death.
; return Z - the cross has frightened her, NZ - she is still guarding the path.
IsCrossUsed:
        ld    a,(ItemStates+ITEM_CROSS-1)
        cp    ITEM_STATE_USED
        ret
; END - IsCrossUsed
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; State queries for the castle wall sequence.
; return Z - the queried condition is true, NZ - it is false.
IsDynamiteUsed:
        ld    a,(ItemStates+ITEM_DYNAMITE-1)
        cp    ITEM_STATE_USED
        ret

IsMatchUsed:
        ld    a,(ItemStates+ITEM_MATCH-1)
        cp    ITEM_STATE_USED
        ret

IsCastleWallDestroyed:
        call  IsDynamiteUsed
        ret   nz
        jp    IsMatchUsed

IsCastleWallOpen:
        call  IsCastleWallDestroyed
        ret   nz
        ld    a,(_CastleExplosionTimer)
        or    a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ApplyUsedItemsToRoom - Apply permanent item effects after ShowRoom
; has drawn the static sprites and before it copies their attributes.
ApplyUsedItemsToRoom:
        call  _ItemsGetActualRoomId
        cp    BRIDGE_ROOM_ID
        jr    z,.ApplyBridgeHole
        cp    CASTLE_ROOM_ID
        ret   nz

        call  IsCastleWallDestroyed
        ret   nz

        ld    ix,SpriteCastleWallHole
        ld    b,CASTLE_WALL_HOLE_Y
        ld    c,CASTLE_WALL_X
        ld    de,RoomsAttrCache
        jp    DrawSprite

.ApplyBridgeHole:
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
; BEGIN - CanUseCastleItemAtWall - Is the player beside the wall's bottom block?
; The caller has already checked Room006.
; return CF=1 - close enough, CF=0 - too far away.
CanUseCastleItemAtWall:
        ld    a,(PlayerX)
        add   a,PLAYER_FOOT_WIDTH+CASTLE_ITEM_USE_RANGE
        cp    CASTLE_WALL_X
        jr    c,.CastleItemTooFar

        ld    a,(PlayerX)
        cp    CASTLE_WALL_X+CASTLE_WALL_WIDTH*8+CASTLE_ITEM_USE_RANGE
        jr    nc,.CastleItemTooFar

        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        cp    CASTLE_WALL_HOLE_Y
        jr    c,.CastleItemTooFar

        ld    a,(PlayerY)
        cp    CASTLE_WALL_HOLE_Y+CASTLE_WALL_HOLE_HEIGHT*8
        jr    nc,.CastleItemTooFar

        scf
        ret

.CastleItemTooFar:
        or    a
        ret
; END - CanUseCastleItemAtWall
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - CanLightCastleDynamite - The match works only after the dynamite has
; been planted and while the player is still beside it.
; return CF=1 - it can be lit, CF=0 - dynamite missing or player too far away.
CanLightCastleDynamite:
        call  IsDynamiteUsed
        jr    nz,.CastleMatchFailed
        jp    CanUseCastleItemAtWall

.CastleMatchFailed:
        or    a
        ret
; END - CanLightCastleDynamite
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - IsCastleWallPixelSolid - Explicit collision for the castle's white
; right wall. The upper wall always remains solid; the bottom block becomes
; free only after both items are used and the explosion has finished.
; B - pixel Y.
; C - pixel X.
; return NZ - solid wall pixel, Z - this routine does not block the pixel.
IsCastleWallPixelSolid:
        push  hl
        push  de

        call  _ItemsGetActualRoomId
        cp    CASTLE_ROOM_ID
        jr    nz,.CastleWallPixelFree

        ld    a,c
        cp    CASTLE_WALL_X
        jr    c,.CastleWallPixelFree
        cp    CASTLE_WALL_X+CASTLE_WALL_WIDTH*8
        jr    nc,.CastleWallPixelFree

        ld    a,b
        cp    CASTLE_WALL_Y
        jr    c,.CastleWallPixelFree
        cp    CASTLE_WALL_Y+CASTLE_WALL_HEIGHT*8
        jr    nc,.CastleWallPixelFree

        cp    CASTLE_WALL_HOLE_Y
        jr    c,.CastleWallPixelSolid
        call  IsCastleWallOpen
        jr    z,.CastleWallPixelFree

.CastleWallPixelSolid:
        pop   de
        pop   hl
        ld    a,1
        or    a
        ret

.CastleWallPixelFree:
        pop   de
        pop   hl
        xor   a
        ret
; END - IsCastleWallPixelSolid
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - CastleExplosionInRoom - Draw the blast over the newly cleared block.
; The last tick erases it with the same blank sprite used by ShowRoom.
CastleExplosionInRoom:
        ld    hl,_CastleExplosionTimer
        ld    a,(hl)
        or    a
        ret   z

        dec   (hl)
        cp    1
        ld    ix,SpriteCastleExplosion
        jr    nz,.CastleExplosionDraw
        ld    ix,SpriteCastleWallHole

.CastleExplosionDraw:
        ld    b,CASTLE_WALL_HOLE_Y
        ld    c,CASTLE_WALL_X
        ld    de,22528
        jp    PlayerDrawDynamicSprite
; END - CastleExplosionInRoom
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

; Counts down only while Room006 is active. Zero means that the cleared wall
; block is already safe to walk through.
_CastleExplosionTimer:
        defb  0

;-------------------------------------------------------------------------------
; Three empty cells overwrite the middle of the bridge. Their white-ink
; attributes describe non-solid scenery to the player collision code, while
; the zero bitmap leaves a clearly visible black opening.
SpriteBridgeHole:
        defb  BRIDGE_HOLE_WIDTH,8
        block BRIDGE_HOLE_WIDTH*8,0
        block BRIDGE_HOLE_WIDTH,71

;-------------------------------------------------------------------------------
; The blank block permanently overwrites the lowest castle-wall segment.
SpriteCastleWallHole:
        defb  CASTLE_WALL_WIDTH,CASTLE_WALL_HOLE_HEIGHT*8
        block CASTLE_WALL_WIDTH*CASTLE_WALL_HOLE_HEIGHT*8,0
        block CASTLE_WALL_WIDTH*CASTLE_WALL_HOLE_HEIGHT,71

; A short, bright burst fills exactly the block removed from the castle wall.
; The animation routine replaces it with SpriteCastleWallHole on its last tick.
SpriteCastleExplosion:
        defb  CASTLE_WALL_WIDTH,CASTLE_WALL_HOLE_HEIGHT*8
        defb  %00000000,%00011000,%00000000
        defb  %00001000,%00011000,%00010000
        defb  %00000100,%00111100,%00100000
        defb  %00000010,%01111110,%01000000
        defb  %00010001,%11111111,%10001000
        defb  %00001011,%11011011,%11010000
        defb  %00000111,%11111111,%11100000
        defb  %00111111,%11100111,%11111100
        defb  %00011111,%11111111,%11111000
        defb  %01111111,%11011011,%11111110
        defb  %00111111,%11111111,%11111100
        defb  %11111110,%11111111,%01111111
        defb  %01111111,%11111111,%11111110
        defb  %00111111,%10111101,%11111100
        defb  %01111111,%11111111,%11111110
        defb  %00011111,%01111110,%11111000
        defb  %00001111,%11100111,%11110000
        defb  %00000111,%11011011,%11100000
        defb  %00001011,%11111111,%11010000
        defb  %00010001,%01111110,%10001000
        defb  %00100000,%00111100,%00000100
        defb  %01000000,%00011000,%00000010
        defb  %00010000,%00011000,%00001000
        defb  %00000000,%00000000,%00000000
        defb  66,70,66
        defb  70,71,70
        defb  66,70,66

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
