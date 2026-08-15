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
; Where the shipwright wakes up: beside the wreck in the middle-left of the map.
StartRoomInMap:
        defb  042

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
; 255 is a wall. The outer wall keeps the cursor switcher inside the table;
; inside it, the irregular eight-level shape follows the original paper map.
ROOMS_MAP_WIDTH equ  8
RoomsMap:
        defb  255, 255, 255, 255, 255, 255, 255, 255
        defb  255, 001, 002, 255, 255, 255, 255, 255
        defb  255, 255, 003, 004, 005, 006, 007, 255
        defb  255, 255, 255, 255, 255, 008, 009, 255
        defb  255, 255, 255, 010, 011, 012, 013, 255
        defb  255, 255, 014, 015, 255, 016, 017, 255
        defb  255, 255, 255, 255, 255, 018, 019, 255
        defb  255, 255, 255, 255, 255, 020, 021, 255
        defb  255, 255, 255, 255, 255, 022, 023, 255
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
        defw  Room007
        defw  Room008
        defw  Room009
        defw  Room010
        defw  Room011
        defw  Room012
        defw  Room013
        defw  Room014
        defw  Room015
        defw  Room016
        defw  Room017
        defw  Room018
        defw  Room019
        defw  Room020
        defw  Room021
        defw  Room022
        defw  Room023
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

; The upper-left garden of the paper map. The gas mask belongs here later; for
; now only the plants and loose stones are drawn.
Room001:
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

        defb  24, 160, 0
        defw  SPRITE_GRASS
        defb  72, 168, 0
        defw  SPRITE_GRASS_SMALL
        defb  104, 168, 0
        defw  SPRITE_ROCK_FLAT
        defb  192, 160, 0
        defw  SPRITE_GRASS_WIND
        defb  0

; The second upper room: the living tree, the long ladder to the spike passage
; and the grass beside it. The marked gas mask is deliberately not drawn yet.
Room002:
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

        defb  24, 136, 0
        defw  SPRITE_LIVING_TREE
        defb  144, 56, 0
        defw  SPRITE_LADDER
        defb  144, 80, 0
        defw  SPRITE_LADDER
        defb  144, 104, 0
        defw  SPRITE_LADDER
        defb  144, 128, 0
        defw  SPRITE_LADDER
        defb  144, 152, 0
        defw  SPRITE_LADDER
        defb  112, 168, 0
        defw  SPRITE_ROCK_SMALL
        defb  216, 168, 0
        defw  SPRITE_GRASS_SMALL
        defb  0

; Directly under the upper ladder: grass on the left, iron spikes on the right
; and the marked key omitted until collectible items exist.
Room003:
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

        defb  144, 56, 0
        defw  SPRITE_LADDER
        defb  144, 80, 0
        defw  SPRITE_LADDER
        defb  144, 104, 0
        defw  SPRITE_LADDER
        defb  144, 128, 0
        defw  SPRITE_LADDER
        defb  144, 152, 0
        defw  SPRITE_LADDER
        defb  24, 160, 0
        defw  SPRITE_GRASS_LOW
        defb  88, 160, 0
        defw  SPRITE_SPIKES
        defb  216, 168, 0
        defw  SPRITE_ROCK_SMALL
        defb  0

; The first worker on the paper map. The loose wood at his feet is a future
; collectible, but the man and his saw already belong to the room.
Room004:
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

        defb  32, 168, 0
        defw  SPRITE_ROCK_FLAT
        defb  104, 168, 0
        defw  SPRITE_GRASS_SMALL
        defb  152, 136, 0
        defw  SPRITE_WORKER_SAW
        defb  0

; A rain cloud over the place where the bucket, water and glue will be handled.
; Those items are omitted, but the cloud and its heavy drop follow the map.
Room005:
        defb  72, 56, 0
        defw  SPRITE_CLOUD
        defb  88, 104, 0
        defw  SPRITE_RAIN_DROP

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

        defb  32, 160, 0
        defw  SPRITE_GRASS_WIND
        defb  200, 168, 0
        defw  SPRITE_ROCK_SMALL
        defb  0

; The warning room with the long scorched rope. Its marked consumable is left
; out; only the permanent rope and bare ground are part of this pass.
Room006:
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

        defb  128, 56, 0
        defw  SPRITE_ROPE
        defb  128, 80, 0
        defw  SPRITE_ROPE
        defb  128, 104, 0
        defw  SPRITE_ROPE
        defb  128, 128, 0
        defw  SPRITE_ROPE
        defb  128, 152, 0
        defw  SPRITE_ROPE
        defb  32, 168, 0
        defw  SPRITE_ROCK_FLAT
        defb  200, 160, 0
        defw  SPRITE_GRASS_WIND
        defb  0

; The brick barrier at the far right of the upper passage. The nails marked on
; the paper are a future item; the wall itself is permanent scenery.
Room007:
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

        defb  176, 136, 0
        defw  SPRITE_BRICK_WALL
        defb  32, 160, 0
        defw  SPRITE_GRASS_LOW
        defb  144, 168, 0
        defw  SPRITE_ROCK_SMALL
        defb  0

; The short landing between the upper rope and the rooms below. The bottle of
; glue on the paper is not drawn yet.
Room008:
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

        defb  64, 112, 0
        defw  SPRITE_GROUND_SMALL
        defb  80, 112, 0
        defw  SPRITE_GROUND_SMALL
        defb  96, 112, 0
        defw  SPRITE_GROUND_SMALL
        defb  112, 112, 0
        defw  SPRITE_GROUND_SMALL
        defb  144, 56, 0
        defw  SPRITE_ROPE
        defb  144, 80, 0
        defw  SPRITE_ROPE
        defb  144, 104, 0
        defw  SPRITE_ROPE
        defb  144, 128, 0
        defw  SPRITE_ROPE
        defb  144, 152, 0
        defw  SPRITE_ROPE
        defb  0

; The blank landing to the right of the rope, between the wall and the worker
; with the pliers.
Room009:
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

        defb  40, 168, 0
        defw  SPRITE_ROCK_FLAT
        defb  200, 168, 0
        defw  SPRITE_GRASS_SMALL
        defb  0

; The living tree over the shipwreck and the ladder down beside it.
Room010:
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

        defb  24, 136, 0
        defw  SPRITE_LIVING_TREE
        defb  136, 56, 0
        defw  SPRITE_LADDER
        defb  136, 80, 0
        defw  SPRITE_LADDER
        defb  136, 104, 0
        defw  SPRITE_LADDER
        defb  136, 128, 0
        defw  SPRITE_LADDER
        defb  136, 152, 0
        defw  SPRITE_LADDER
        defb  216, 160, 0
        defw  SPRITE_GRASS
        defb  0

; The man with the screwdriver under a rain cloud.
Room011:
        defb  64, 56, 0
        defw  SPRITE_CLOUD
        defb  80, 104, 0
        defw  SPRITE_RAIN_DROP

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

        defb  160, 136, 0
        defw  SPRITE_WORKER_SCREWDRIVER
        defb  32, 160, 0
        defw  SPRITE_GRASS_WIND
        defb  0

; The hanging flame in the centre of the island. The hammer marked beside it
; is not a part of this scenery pass.
Room012:
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

        defb  136, 56, 0
        defw  SPRITE_ROPE
        defb  136, 80, 0
        defw  SPRITE_ROPE
        defb  136, 104, 0
        defw  SPRITE_ROPE
        defb  128, 128, 0
        defw  SPRITE_FIRE
        defb  40, 168, 0
        defw  SPRITE_ROCK_FLAT
        defb  0

; The man with the pliers and the first section of the deep right-hand ladder.
Room013:
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

        defb  144, 56, 0
        defw  SPRITE_LADDER
        defb  144, 80, 0
        defw  SPRITE_LADDER
        defb  144, 104, 0
        defw  SPRITE_LADDER
        defb  144, 128, 0
        defw  SPRITE_LADDER
        defb  144, 152, 0
        defw  SPRITE_LADDER
        defb  184, 136, 0
        defw  SPRITE_WORKER_PLIERS
        defb  32, 160, 0
        defw  SPRITE_GRASS_LOW
        defb  0

; The shipwreck at which the game begins.
Room014:
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

        defb  16, 136, 0
        defw  SPRITE_SHIPWRECK
        defb  208, 160, 0
        defw  SPRITE_GRASS_WIND
        defb  0

; The shaft immediately right of the wreck: spikes on the left, the ladder in
; the middle and a tuft at the far wall.
Room015:
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

        defb  80, 56, 0
        defw  SPRITE_LADDER
        defb  80, 80, 0
        defw  SPRITE_LADDER
        defb  80, 104, 0
        defw  SPRITE_LADDER
        defb  80, 128, 0
        defw  SPRITE_LADDER
        defb  80, 152, 0
        defw  SPRITE_LADDER
        defb  16, 160, 0
        defw  SPRITE_SPIKES
        defb  200, 160, 0
        defw  SPRITE_GRASS
        defb  0

; The empty passage drawn between the spike shaft and the long right-hand
; ladder. The tape marked on the paper is a future collectible.
Room016:
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

        defb  104, 168, 0
        defw  SPRITE_GRASS_SMALL
        defb  184, 168, 0
        defw  SPRITE_ROCK_SMALL
        defb  0

; The next section of the long ladder down the right side of the paper map.
Room017:
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

        defb  152, 56, 0
        defw  SPRITE_LADDER
        defb  152, 80, 0
        defw  SPRITE_LADDER
        defb  152, 104, 0
        defw  SPRITE_LADDER
        defb  152, 128, 0
        defw  SPRITE_LADDER
        defb  152, 152, 0
        defw  SPRITE_LADDER
        defb  32, 160, 0
        defw  SPRITE_GRASS_LOW
        defb  0

; The lower rain gallery. The roll of tape is omitted until items are active.
Room018:
        defb  64, 56, 0
        defw  SPRITE_CLOUD
        defb  80, 104, 0
        defw  SPRITE_RAIN_DROP

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

        defb  32, 168, 0
        defw  SPRITE_ROCK_SMALL
        defb  200, 160, 0
        defw  SPRITE_GRASS_WIND
        defb  0

; Another uninterrupted section of the deep ladder.
Room019:
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

        defb  152, 56, 0
        defw  SPRITE_LADDER
        defb  152, 80, 0
        defw  SPRITE_LADDER
        defb  152, 104, 0
        defw  SPRITE_LADDER
        defb  152, 128, 0
        defw  SPRITE_LADDER
        defb  152, 152, 0
        defw  SPRITE_LADDER
        defb  0

; The deliberately empty cell to the left of the broken ladder.
Room020:
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
        defb  0

; The crossed break drawn halfway down the right-hand ladder.
Room021:
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

        defb  152, 56, 0
        defw  SPRITE_LADDER
        defb  152, 80, 0
        defw  SPRITE_LADDER
        defb  152, 104, 0
        defw  SPRITE_LADDER_BROKEN
        defb  152, 128, 0
        defw  SPRITE_LADDER
        defb  152, 152, 0
        defw  SPRITE_LADDER
        defb  0

; The bottom-left chamber: the guillotine and the toolbox represented by the
; permanent crate. Their future interactions are outside this room pass.
Room022:
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

        defb  24, 160, 0
        defw  SPRITE_CRATE
        defb  80, 128, 0
        defw  SPRITE_GUILLOTINE
        defb  184, 168, 0
        defw  SPRITE_ROCK_FLAT
        defb  0

; The lowest rain room and the final section of the ladder.
Room023:
        defb  48, 56, 0
        defw  SPRITE_CLOUD
        defb  64, 104, 0
        defw  SPRITE_RAIN_DROP

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

        defb  152, 56, 0
        defw  SPRITE_LADDER
        defb  152, 80, 0
        defw  SPRITE_LADDER
        defb  152, 104, 0
        defw  SPRITE_LADDER
        defb  152, 128, 0
        defw  SPRITE_LADDER
        defb  152, 152, 0
        defw  SPRITE_LADDER
        defb  0
; END
;-------------------------------------------------------------------------------
