;###############################################################################
;##### The rooms of the island and the map they are laid out on. ###############
;##### #########################################################################
;##### Two different numbers are in play here. `ActualRoomInMap` is an index ####
;##### into `RoomsMap`, the grid the island is drawn on, where 255 marks a ######
;##### place there is no way to; the number stored there is the identity of #####
;##### the room, and that one indexes `Rooms` and the names in the panel. #######
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - ShowRoom
; Draw the room the player is in, but only if it is not already on the screen.
; The room is a list of sprites; they are drawn into the field one after the
; other and their colours go into a cache first, so the sprites that overlap
; can compose there and the screen sees the result only once.
ShowRoom:
        ld    a,(ActualRoomInMap)
        ld    hl,LastShowedRoomInMap
        cp    (hl)
        ret   z ; The same room, there is nothing to do.

        ld    (hl),a

        push  af
        call  CleanGameField
        ld    a,0
        call  SetGameFieldAttributes
        ; The cache begins as the empty field.
        ld    hl,RoomsAttrCache
        ld    de,RoomsAttrCache+1
        ld    bc,767
        ld    (hl),GAME_FIELD_COLOR
        ldir
        pop   af

        ; The number of the room, out of the map.
        ld    hl,RoomsMap
        ld    d,0
        ld    e,a
        add   hl,de
        ld    a,(hl)

        ; The address of its list of sprites.
        ld    hl,Rooms
        ld    d,0
        ld    e,a
        add   hl,de
        add   hl,de
        ld    de,(hl)
        push  de
        pop   ix

        ld    de,5 ; The length of one record of the room.

.ShowRoom1:
        ld    a,(ix+0)
        or    a
        jr    z,.ShowRoom2 ; A zero Xos ends the list.
        push  de
        ld    c,a
        ld    b,(ix+1)
        ld    a,(ix+2)
        ld    hl,(ix+3)
        push  ix
        push  hl
        pop   ix
        or    a
        jr    nz,.ShowRoom3
        ld    de,RoomsAttrCache ; The colours go into the cache.
        call  DrawSprite
        jr    .ShowRoom4
.ShowRoom3:
        ld    de,RoomsAttrCache
        call  DrawSpriteWithCustomColor
.ShowRoom4:
        pop   ix
        pop   de
        add   ix,de
        jr    .ShowRoom1

.ShowRoom2:
        ; And now the cache goes to the screen, row by row.
        ld    hl,RoomsAttrCache+ROOMS_FIELD_OFFSET
        ld    de,22528+ROOMS_FIELD_OFFSET
        ld    b,GAME_FIELD_HEIGHT
.ShowRoom5:
        push  bc
        push  hl
        push  de
        ld    bc,GAME_FIELD_WIDTH
        ldir
        pop   de
        pop   hl
        ld    bc,32
        add   hl,bc
        ex    de,hl
        add   hl,bc
        ex    de,hl
        pop   bc
        djnz  .ShowRoom5

        ret
; END - ShowRoom
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - RoomSwitcherRoomsMap
; Is there a room at this place of the map? Only A is changed; the caller keeps
; the keys it read in DE.
; A - the index into the map
; return zero flag set when there is a wall or nothing there
RoomSwitcherRoomsMap:
        push  hl
        push  de
        ld    hl,RoomsMap
        ld    d,0
        ld    e,a
        add   hl,de
        ld    a,(hl) ; The number of the room.
        pop   de
        pop   hl
        cp    255
        ret   z
        or    a
        ret
; END - RoomSwitcherRoomsMap
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; The variables of the rooms.
; Where the shipwright wakes up: the shore in the left upper corner of the map.
StartRoomInMap:
        defb  009

; The room he is in now.
ActualRoomInMap:
        defb  000

; The room that is on the screen now.
LastShowedRoomInMap:
        defb  000

; Where the field begins in the attributes, counted from their beginning.
ROOMS_FIELD_OFFSET equ (GAME_FIELD_FIRST_ROW*32)+GAME_FIELD_FIRST_COL

; The colours of the room are composed here before they go to the screen.
RoomsAttrCache:
        block 768,GAME_FIELD_COLOR
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - THE MAP OF THE ISLAND
; 255 is a wall, 0 is a room that is not drawn yet.
ROOMS_MAP_WIDTH equ  8
RoomsMap:
        defb  255, 255, 255, 255, 255, 255, 255, 255
        defb  255, 001, 002, 003, 004, 255, 255, 255
        defb  255, 255, 255, 005, 006, 255, 255, 255
        defb  255, 255, 255, 255, 255, 255, 255, 255
; END
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - THE ADDRESSES OF THE ROOMS
Rooms:
        defw  Room000 ; The empty room.
        defw  Room001
        defw  Room002
        defw  Room003
        defw  Room004
        defw  Room005
        defw  Room006
; END
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - THE ROOMS THEMSELVES
; One record is: Xos in pixels, Yos in pixels, the colour, the sprite. A zero
; colour means the sprite keeps the colours it carries itself. A zero Xos ends
; the room, so no sprite can stand in the first column of the screen.
;
; The field is 30x17 characters: Xos goes from 8 to 247 and Yos from 48 to 183.
; Five pieces of the ground fill a whole row of it.

Room000:
        defb  0

; The shore. The sea has left him here with nothing but the crate, and the only
; way on is the ladder to the ledge on the right.
Room001:
        defb  24, 56, 0
        defw  SPRITE_CLOUD
        defb  168, 64, 0
        defw  SPRITE_CLOUD

        defb  8, 176, 0
        defw  SPRITE_GROUND
        defb  56, 176, 0
        defw  SPRITE_GROUND
        defb  104, 176, 0
        defw  SPRITE_GROUND
        defb  152, 176, 0
        defw  SPRITE_GROUND
        defb  200, 176, 0
        defw  SPRITE_GROUND

        defb  192, 120, 0
        defw  SPRITE_GROUND_SMALL
        defb  208, 120, 0
        defw  SPRITE_GROUND_SMALL
        defb  224, 120, 0
        defw  SPRITE_GROUND_SMALL
        defb  208, 128, 0
        defw  SPRITE_LADDER
        defb  208, 152, 0
        defw  SPRITE_LADDER

        defb  16, 160, 0
        defw  SPRITE_ROCK
        defb  48, 152, 0
        defw  SPRITE_DEAD_TREE
        defb  96, 168, 0
        defw  SPRITE_GRASS
        defb  112, 168, 0
        defw  SPRITE_GRASS
        defb  144, 160, 0
        defw  SPRITE_CRATE
        defb  176, 168, 0
        defw  SPRITE_GRASS
        defb  0

; The path east, under the trees the salt has killed.
Room002:
        defb  48, 56, 0
        defw  SPRITE_CLOUD
        defb  152, 72, 0
        defw  SPRITE_CLOUD

        defb  8, 176, 0
        defw  SPRITE_GROUND
        defb  56, 176, 0
        defw  SPRITE_GROUND
        defb  104, 176, 0
        defw  SPRITE_GROUND
        defb  152, 176, 0
        defw  SPRITE_GROUND
        defb  200, 176, 0
        defw  SPRITE_GROUND

        defb  32, 152, 0
        defw  SPRITE_DEAD_TREE
        defb  80, 168, 0
        defw  SPRITE_GRASS
        defb  96, 160, 0
        defw  SPRITE_ROCK
        defb  120, 152, 0
        defw  SPRITE_DEAD_TREE
        defb  176, 168, 0
        defw  SPRITE_GRASS
        defb  200, 152, 0
        defw  SPRITE_DEAD_TREE
        defb  0

; The sawmill: a ledge with a crate on it and the ladder down to the ground.
Room003:
        defb  32, 56, 0
        defw  SPRITE_CLOUD

        defb  8, 176, 0
        defw  SPRITE_GROUND
        defb  56, 176, 0
        defw  SPRITE_GROUND
        defb  104, 176, 0
        defw  SPRITE_GROUND
        defb  152, 176, 0
        defw  SPRITE_GROUND
        defb  200, 176, 0
        defw  SPRITE_GROUND

        defb  88, 120, 0
        defw  SPRITE_GROUND_SMALL
        defb  104, 120, 0
        defw  SPRITE_GROUND_SMALL
        defb  120, 120, 0
        defw  SPRITE_GROUND_SMALL

        defb  88, 104, 0
        defw  SPRITE_CRATE

        defb  104, 128, 0
        defw  SPRITE_LADDER
        defb  104, 152, 0
        defw  SPRITE_LADDER

        defb  176, 56, 0
        defw  SPRITE_CLOUD
        defb  176, 160, 0
        defw  SPRITE_ROCK
        defb  216, 168, 0
        defw  SPRITE_GRASS
        defb  0

; The swamp. It rains here whether the sky is grey or not.
Room004:
        defb  32, 56, 0
        defw  SPRITE_CLOUD
        defb  120, 64, 0
        defw  SPRITE_CLOUD
        defb  200, 56, 0
        defw  SPRITE_CLOUD

        defb  8, 176, 0
        defw  SPRITE_GROUND
        defb  56, 176, 0
        defw  SPRITE_GROUND
        defb  104, 176, 0
        defw  SPRITE_GROUND
        defb  152, 176, 0
        defw  SPRITE_GROUND
        defb  200, 176, 0
        defw  SPRITE_GROUND

        defb  64, 168, 0
        defw  SPRITE_GRASS
        defb  88, 168, 0
        defw  SPRITE_GRASS
        defb  104, 160, 0
        defw  SPRITE_ROCK
        defb  160, 168, 0
        defw  SPRITE_GRASS
        defb  184, 168, 0
        defw  SPRITE_GRASS
        defb  224, 160, 0
        defw  SPRITE_ROCK
        defb  0

; The quarry, under the sawmill. The ladder goes the whole way down.
Room005:
        defb  8, 176, 0
        defw  SPRITE_GROUND
        defb  56, 176, 0
        defw  SPRITE_GROUND
        defb  104, 176, 0
        defw  SPRITE_GROUND
        defb  152, 176, 0
        defw  SPRITE_GROUND
        defb  200, 176, 0
        defw  SPRITE_GROUND

        defb  32, 48, 0
        defw  SPRITE_GROUND_SMALL
        defb  48, 48, 0
        defw  SPRITE_GROUND_SMALL
        defb  64, 48, 0
        defw  SPRITE_GROUND_SMALL

        defb  48, 56, 0
        defw  SPRITE_LADDER
        defb  48, 80, 0
        defw  SPRITE_LADDER
        defb  48, 104, 0
        defw  SPRITE_LADDER
        defb  48, 128, 0
        defw  SPRITE_LADDER
        defb  48, 152, 0
        defw  SPRITE_LADDER

        defb  120, 160, 0
        defw  SPRITE_ROCK
        defb  152, 160, 0
        defw  SPRITE_ROCK
        defb  184, 160, 0
        defw  SPRITE_CRATE
        defb  216, 160, 0
        defw  SPRITE_ROCK
        defb  0

; The burnt ground. Everything here is the colour of the fire that went over it,
; and what hangs over it is smoke and not cloud.
Room006:
        defb  64, 56, 2
        defw  SPRITE_CLOUD
        defb  160, 64, 2
        defw  SPRITE_CLOUD

        defb  8, 176, 2
        defw  SPRITE_GROUND
        defb  56, 176, 2
        defw  SPRITE_GROUND
        defb  104, 176, 2
        defw  SPRITE_GROUND
        defb  152, 176, 2
        defw  SPRITE_GROUND
        defb  200, 176, 2
        defw  SPRITE_GROUND

        defb  40, 152, 2
        defw  SPRITE_DEAD_TREE
        defb  112, 160, 2
        defw  SPRITE_ROCK
        defb  160, 152, 2
        defw  SPRITE_DEAD_TREE
        defb  216, 160, 2
        defw  SPRITE_ROCK
        defb  0
; END
;-------------------------------------------------------------------------------
