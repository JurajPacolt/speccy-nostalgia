;===============================================================================
; BEGIN - Room's procedures
;-------------------------------------------------------------------------------
; BEGIN - ShowRoom
ShowRoom:
        ld    a,(ActualRoomInMap) ; Get actual showed room.
        ld    hl,LastShowedRoomInMap
        cp    (hl) ; Is equals with 'LastShowedRoom'?
        ret   z ; Yes > end ...

        ld    (hl),a ; If not write actual room to last showed.

        push  af
        call  CleanGameField ; Cleaning game field.
        ld    a,0
        call  SetGameFieldAttributes
        ; Reset cache
        ld    hl,RoomsAttrCache
        ld    de,RoomsAttrCache+1
        ld    bc,767
        ld    (hl),71
        ldir
        pop   af

        ; Getting number of the room from room's map.
        ld    hl,RoomsMap
        ld    d,0
        ld    e,a
        add   hl,de
        ld    a,(hl)

        ; Getting room's address
        ld    hl,Rooms
        ld    d,0
        ld    e,a
        add   hl,de
        add   hl,de
        ld    de,(hl)
        push  de
        pop   ix

        ld    de,5 ; Length of the room element.

        ; Showing room's static sprites.
.ShowRoom1:
        ld    a,(ix+0)
        or    a
        jr    z,.ShowRoom2
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
        ld    de,RoomsAttrCache ; Using cache for attributes
        call  DrawSprite
        jr    .ShowRoom4
.ShowRoom3:
        ld    de,RoomsAttrCache ; Using cache for attributes
        call  DrawSpriteWithCustomColor
.ShowRoom4:
        pop   ix
        pop   de
        add   ix,de
        jr    .ShowRoom1
.ShowRoom2:

        ld    a,0
        call  SetGameFieldAttributes

        ld    hl,RoomsAttrCache+161
        ld    de,22528+161
        ld    b,18
.ShowRoom5:
        push  de
        push  hl
        push  bc
        ld    bc,30
        ldir
        pop   bc
        pop   hl
        ld    de,32
        add   hl,de
        pop   ix
        ld    de,32
        add   ix,de
        ld    de,ix
        djnz  .ShowRoom5

        ret
; END - ShowRoom
;-------------------------------------------------------------------------------
; BEGIN - RoomSwitcherRoomsMap
; Helper routine for room's ID number.
RoomSwitcherRoomsMap:
        push  hl
        ld    hl,RoomsMap
        ld    d,0
        ld    e,a
        add   hl,de
        ld    a,(hl) ; Room's ID number
        pop   hl
        cp    255 ; equals 255
        ret   z
        or    a ; or 0
        ret
; END - RoomSwitcherRoomsMap
;-------------------------------------------------------------------------------
; END
;===============================================================================

;===============================================================================
; Room's variables.
;-------------------------------------------------------------------------------
; Here is game started, if the player begin.
StartRoomInMap:
        defb  013

; Actual room, it actually showed.
ActualRoomInMap:
        defb  000

; Last showed room.
LastShowedRoomInMap:
        defb  000

; Room's attributes cache, for better showing rooms.
RoomsAttrCache:
        block 768,71 ; block 768 bytes, fill with 0

;-------------------------------------------------------------------------------
;===============================================================================

;-------------------------------------------------------------------------------
; BEGIN - ROOMS MAP
ROOMS_MAP_WIDTH equ  9
RoomsMap:
        defb  255, 255, 255, 255, 255, 255, 255, 255, 255
        defb  255, 006, 007, 002, 001, 003, 004, 005, 255
        defb  255, 000, 000, 000, 008, 000, 000, 000, 255
        defb  255, 000, 000, 009, 010, 011, 000, 000, 255
        defb  255, 255, 255, 255, 255, 255, 255, 255, 255
; END
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ROOM'S ADDRESSES
Rooms:
        defw  Room000 ; blank room
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
; END
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ROOM'S DEFINITIONS
Room000:
        defb  0 ; End of the room's data.

Room001:
        defb  17*8, 6*8, 0
        defw  SPRITE_CLOUD_1

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_BLOCK_5
        defb  6*8, 152, 0
        defw  SPRITE_BLOCK_2
        defb  7*8, 144, 0
        defw  SPRITE_BLOCK_1
        defb  9*8, 168, 0
        defw  SPRITE_SMALL_STONE
        defb  9*8, 176, 0
        defw  SPRITE_SMALL_STONE
        defb  10*8, 176, 0
        defw  SPRITE_SMALL_STONE

        defb  20*8, 144, 0
        defw  SPRITE_BLOCK_1
        defb  20*8, 152, 0
        defw  SPRITE_BLOCK_2
        defb  20*8, 160, 0
        defw  SPRITE_BLOCK_5
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  8*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  9*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  10*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  11*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  12*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  13*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  14*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  15*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  16*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  17*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  18*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  19*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT
        defb  20*8, 136, 0
        defw  SPRITE_BRIDGE_ELEMENT

        defb  8*8, 120, 0
        defw  SPRITE_HANDLE
        defb  9*8, 120, 0
        defw  SPRITE_HANDLE_MIDDLE
        defb  10*8, 120, 0
        defw  SPRITE_HANDLE
        defb  11*8, 120, 0
        defw  SPRITE_HANDLE_MIDDLE
        defb  12*8, 120, 0
        defw  SPRITE_HANDLE
        defb  13*8, 120, 0
        defw  SPRITE_HANDLE_MIDDLE
        defb  14*8, 120, 0
        defw  SPRITE_HANDLE
        defb  15*8, 120, 0
        defw  SPRITE_HANDLE_MIDDLE
        defb  16*8, 120, 0
        defw  SPRITE_HANDLE
        defb  17*8, 120, 0
        defw  SPRITE_HANDLE_MIDDLE
        defb  18*8, 120, 0
        defw  SPRITE_HANDLE
        defb  19*8, 120, 0
        defw  SPRITE_HANDLE_MIDDLE
        defb  20*8, 120, 0
        defw  SPRITE_HANDLE

        defb  9*8, 160, 0
        defw  SPRITE_GRASS_5

        defb  24*8, 144, 0
        defw  SPRITE_GRASS_1
        defb  26*8, 152, 0
        defw  SPRITE_GRASS_2
        defb  29*8, 152, 0
        defw  SPRITE_GRASS_3
        defb  30*8, 152, 0
        defw  SPRITE_GRASS_4

        defb  0

Room002:
        defb  5*8, 7*8, 0
        defw  SPRITE_CLOUD_2
        defb  16*8, 9*8, 0
        defw  SPRITE_CLOUD_2

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_STONES
        defb  10*8, 160, 0
        defw  SPRITE_STONES
        defb  13*8, 160, 0
        defw  SPRITE_STONES
        defb  16*8, 160, 0
        defw  SPRITE_STONES
        defb  19*8, 160, 0
        defw  SPRITE_STONES
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  6*8, 152, 0
        defw  SPRITE_GRASS_5

        defb  8*8, 152, 0
        defw  SPRITE_GRASS_2

        defb  19*8, 152, 0
        defw  SPRITE_GRASS_3
        defb  20*8, 144, 0
        defw  SPRITE_GRASS_1
        defb  22*8, 152, 0
        defw  SPRITE_GRASS_2

        defb  0

Room003:
        defb  5*8, 7*8, 0
        defw  SPRITE_CLOUD_1
        defb  16*8, 9*8, 0
        defw  SPRITE_CLOUD_2

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_STONES
        defb  10*8, 160, 0
        defw  SPRITE_STONES
        defb  13*8, 160, 0
        defw  SPRITE_STONES
        defb  16*8, 160, 0
        defw  SPRITE_STONES
        defb  19*8, 160, 0
        defw  SPRITE_STONES
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  5*8, 152, 0
        defw  SPRITE_GRASS_2
        defb  13*8, 152, 0
        defw  SPRITE_GRASS_2
        defb  26*8, 152, 0
        defw  SPRITE_GRASS_2

        defb  0

Room004:
        defb  5*8, 7*8, 0
        defw  SPRITE_CLOUD_2
        defb  14*8, 9*8, 0
        defw  SPRITE_CLOUD_1
        defb  24*8, 8*8, 0
        defw  SPRITE_CLOUD_2

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_STONES
        defb  10*8, 160, 0
        defw  SPRITE_STONES
        defb  13*8, 160, 0
        defw  SPRITE_STONES
        defb  16*8, 160, 0
        defw  SPRITE_STONES
        defb  19*8, 160, 0
        defw  SPRITE_STONES
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  4*8, 152, 0
        defw  SPRITE_GRASS_2
        defb  23*8, 152, 0
        defw  SPRITE_GRASS_2

        defb  0

Room005:
        defb  4*8, 7*8, 0
        defw  SPRITE_CLOUD_2

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_STONES
        defb  10*8, 160, 0
        defw  SPRITE_STONES
        defb  13*8, 160, 0
        defw  SPRITE_STONES
        defb  16*8, 160, 0
        defw  SPRITE_STONES
        defb  19*8, 160, 0
        defw  SPRITE_STONES
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  28*8, 5*8, 0
        defw  SPRITE_STONES
        defb  28*8, 8*8, 0
        defw  SPRITE_STONES
        defb  28*8, 11*8, 0
        defw  SPRITE_STONES
        defb  28*8, 14*8, 0
        defw  SPRITE_STONES
        defb  28*8, 17*8, 0
        defw  SPRITE_STONES

        defb  25*8, 17*8, 0
        defw  SPRITE_STONES

        defb  27*8, 14*8, 0
        defw  SPRITE_SMALL_STONE

        defb  26*8, 15*8, 0
        defw  SPRITE_SMALL_STONE
        defb  27*8, 15*8, 0
        defw  SPRITE_SMALL_STONE

        defb  25*8, 16*8, 0
        defw  SPRITE_SMALL_STONE
        defb  26*8, 16*8, 0
        defw  SPRITE_SMALL_STONE
        defb  27*8, 16*8, 0
        defw  SPRITE_SMALL_STONE

        defb  24*8, 17*8, 0
        defw  SPRITE_SMALL_STONE

        defb  22*8, 18*8, 0
        defw  SPRITE_SMALL_STONE
        defb  23*8, 18*8, 0
        defw  SPRITE_SMALL_STONE
        defb  24*8, 18*8, 0
        defw  SPRITE_SMALL_STONE

        defb  20*8, 19*8, 0
        defw  SPRITE_SMALL_STONE
        defb  21*8, 19*8, 0
        defw  SPRITE_SMALL_STONE
        defb  22*8, 19*8, 0
        defw  SPRITE_SMALL_STONE
        defb  23*8, 19*8, 0
        defw  SPRITE_SMALL_STONE
        defb  24*8, 19*8, 0
        defw  SPRITE_SMALL_STONE

        defb  27*8, 13*8, 0
        defw  SPRITE_GRASS_4

        defb  25*8, 15*8, 0
        defw  SPRITE_GRASS_5

        defb  22*8, 17*8, 0
        defw  SPRITE_GRASS_3
        defb  23*8, 17*8, 0
        defw  SPRITE_GRASS_4

        defb  21*8, 18*8, 0
        defw  SPRITE_GRASS_4

        defb  15*8, 19*8, 0
        defw  SPRITE_GRASS_2
        defb  18*8, 18*8, 0
        defw  SPRITE_GRASS_1

        defb  0

Room006:
        defb  23*8, 6*8, 0
        defw  SPRITE_CLOUD_2

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_STONES
        defb  10*8, 160, 0
        defw  SPRITE_STONES
        defb  13*8, 160, 0
        defw  SPRITE_STONES
        defb  16*8, 160, 0
        defw  SPRITE_STONES
        defb  19*8, 160, 0
        defw  SPRITE_STONES
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  1*8, 13*8, 0
        defw  SPRITE_EXIT_DOOR

        defb  1*8, 11*8, 7
        defw  SPRITE_BLOCK_3

        defb  1*8, 8*8, 7
        defw  SPRITE_BLOCK_4
        defb  1*8, 5*8, 7
        defw  SPRITE_BLOCK_4

        defb  4*8, 5*8, 7
        defw  SPRITE_BLOCK_5
        defb  6*8, 5*8, 7
        defw  SPRITE_BLOCK_4
        defb  9*8, 5*8, 7
        defw  SPRITE_BLOCK_5
        defb  11*8, 5*8, 7
        defw  SPRITE_BLOCK_4
        defb  14*8, 5*8, 7
        defw  SPRITE_BLOCK_5
        defb  16*8, 5*8, 7
        defw  SPRITE_BLOCK_4

        defb  16*8, 8*8, 7
        defw  SPRITE_BLOCK_4
        defb  16*8, 11*8, 7
        defw  SPRITE_BLOCK_4
        defb  16*8, 14*8, 7
        defw  SPRITE_BLOCK_4
        defb  16*8, 17*8, 7
        defw  SPRITE_BLOCK_4

        defb  19*8, 19*8, 0
        defw  SPRITE_GRASS_3

        defb  0

Room007:
        defb  3*8, 6*8, 0
        defw  SPRITE_CLOUD_1
        defb  18*8, 8*8, 0
        defw  SPRITE_CLOUD_1

        defb  1*8, 160, 0
        defw  SPRITE_STONES
        defb  4*8, 160, 0
        defw  SPRITE_STONES
        defb  7*8, 160, 0
        defw  SPRITE_STONES
        defb  10*8, 160, 0
        defw  SPRITE_STONES
        defb  13*8, 160, 0
        defw  SPRITE_STONES
        defb  16*8, 160, 0
        defw  SPRITE_STONES
        defb  19*8, 160, 0
        defw  SPRITE_STONES
        defb  22*8, 160, 0
        defw  SPRITE_STONES
        defb  25*8, 160, 0
        defw  SPRITE_STONES
        defb  28*8, 160, 0
        defw  SPRITE_STONES

        defb  5*8, 19*8, 0
        defw  SPRITE_GRASS_3

        defb  20*8, 18*8, 0
        defw  SPRITE_GRASS_1
        defb  22*8, 19*8, 0
        defw  SPRITE_GRASS_2

        defb  26*8, 19*8, 0
        defw  SPRITE_GRASS_5

        defb  0

Room008:
        defb  1*8, 5*8, 0
        defw  SPRITE_STONES
        defb  1*8, 8*8, 0
        defw  SPRITE_STONES
        defb  1*8, 11*8, 0
        defw  SPRITE_STONES
        defb  1*8, 14*8, 0
        defw  SPRITE_STONES
        defb  1*8, 17*8, 0
        defw  SPRITE_STONES
        defb  1*8, 20*8, 0
        defw  SPRITE_STONES

        defb  4*8, 5*8, 0
        defw  SPRITE_STONES
        defb  4*8, 8*8, 0
        defw  SPRITE_STONES
        defb  4*8, 11*8, 0
        defw  SPRITE_STONES
        defb  4*8, 14*8, 0
        defw  SPRITE_STONES
        defb  4*8, 17*8, 0
        defw  SPRITE_STONES
        defb  4*8, 20*8, 0
        defw  SPRITE_STONES

        defb  9*8, 5*8, 0
        defw  SPRITE_BLOCK_1
        defb  9*8, 6*8, 0
        defw  SPRITE_SMALL_STONE

        defb  7*8, 5*8, 0
        defw  SPRITE_BLOCK_5
        defb  7*8, 8*8, 0
        defw  SPRITE_BLOCK_5
        defb  7*8, 11*8, 0
        defw  SPRITE_BLOCK_5

        defb  9*8, 13*8, 0
        defw  SPRITE_GRASS_3

        defb  13*8, 13*8, 0
        defw  SPRITE_BLOCK_1
        defb  15*8, 12*8, 0
        defw  SPRITE_BLOCK_1
        defb  17*8, 11*8, 0
        defw  SPRITE_BLOCK_1

        defb  13*8, 8*8, 0
        defw  SPRITE_BLOCK_2

        defb  13*8, 19*8, 0
        defw  SPRITE_GRASS_4

        defb  7*8, 14*8, 0
        defw  SPRITE_BLOCK_4
        defb  7*8, 17*8, 0
        defw  SPRITE_STONES
        defb  7*8, 20*8, 0
        defw  SPRITE_STONES

        defb  10*8, 16*8, 0
        defw  SPRITE_SMALL_STONE

        defb  10*8, 17*8, 0
        defw  SPRITE_BLOCK_4
        defb  10*8, 20*8, 0
        defw  SPRITE_STONES

        defb  13*8, 20*8, 0
        defw  SPRITE_BLOCK_4

        defb  22*8, 5*8, 0
        defw  SPRITE_STONES
        defb  22*8, 8*8, 0
        defw  SPRITE_STONES
        defb  22*8, 11*8, 0
        defw  SPRITE_STONES
        defb  22*8, 14*8, 0
        defw  SPRITE_STONES
        defb  22*8, 17*8, 0
        defw  SPRITE_STONES
        defb  22*8, 20*8, 0
        defw  SPRITE_STONES

        defb  25*8, 5*8, 0
        defw  SPRITE_STONES
        defb  25*8, 8*8, 0
        defw  SPRITE_STONES
        defb  25*8, 11*8, 0
        defw  SPRITE_STONES
        defb  25*8, 14*8, 0
        defw  SPRITE_STONES
        defb  25*8, 17*8, 0
        defw  SPRITE_STONES
        defb  25*8, 20*8, 0
        defw  SPRITE_STONES

        defb  28*8, 5*8, 0
        defw  SPRITE_STONES
        defb  28*8, 8*8, 0
        defw  SPRITE_STONES
        defb  28*8, 11*8, 0
        defw  SPRITE_STONES
        defb  28*8, 14*8, 0
        defw  SPRITE_STONES
        defb  28*8, 17*8, 0
        defw  SPRITE_STONES
        defb  28*8, 20*8, 0
        defw  SPRITE_STONES

        defb  20*8, 5*8, 0
        defw  SPRITE_BLOCK_5
        defb  20*8, 8*8, 0
        defw  SPRITE_BLOCK_5
        defb  20*8, 11*8, 0
        defw  SPRITE_BLOCK_5
        defb  21*8, 14*8, 0
        defw  SPRITE_BLOCK_5
        defb  22*8, 17*8, 0
        defw  SPRITE_BLOCK_5
        defb  20*8, 20*8, 0
        defw  SPRITE_BLOCK_4

        defb  21*8, 19*8, 0
        defw  SPRITE_GRASS_5

        defb  0

Room009:
        defb  22*8, 19*8, 0
        defw  SPRITE_SMALL_STONE
        defb  23*8, 19*8, 0
        defw  SPRITE_SMALL_STONE
        defb  23*8, 18*8, 0
        defw  SPRITE_SMALL_STONE
        defb  24*8, 17*8, 0
        defw  SPRITE_SMALL_STONE

        defb  24*8, 18*8, 0
        defw  SPRITE_BLOCK_3

        defb  25*8, 17*8, 0
        defw  SPRITE_STONES
        defb  28*8, 17*8, 0
        defw  SPRITE_STONES

        defb  25*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  27*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  29*8, 17*8, 0
        defw  SPRITE_BLOCK_1

        defb  1*8, 20*8, 0
        defw  SPRITE_STONES
        defb  4*8, 20*8, 0
        defw  SPRITE_STONES
        defb  7*8, 20*8, 0
        defw  SPRITE_STONES
        defb  10*8, 20*8, 0
        defw  SPRITE_STONES
        defb  13*8, 20*8, 0
        defw  SPRITE_STONES
        defb  16*8, 20*8, 0
        defw  SPRITE_STONES
        defb  19*8, 20*8, 0
        defw  SPRITE_STONES
        defb  22*8, 20*8, 0
        defw  SPRITE_STONES
        defb  25*8, 20*8, 0
        defw  SPRITE_STONES
        defb  28*8, 20*8, 0
        defw  SPRITE_STONES

        defb  1*8, 5*8, 0
        defw  SPRITE_STONES
        defb  1*8, 8*8, 0
        defw  SPRITE_STONES
        defb  1*8, 11*8, 0
        defw  SPRITE_STONES
        defb  1*8, 14*8, 0
        defw  SPRITE_STONES
        defb  1*8, 17*8, 0
        defw  SPRITE_STONES

        defb  4*8, 5*8, 0
        defw  SPRITE_STONES
        defb  7*8, 5*8, 0
        defw  SPRITE_STONES
        defb  10*8, 5*8, 0
        defw  SPRITE_STONES
        defb  13*8, 5*8, 0
        defw  SPRITE_STONES
        defb  16*8, 5*8, 0
        defw  SPRITE_STONES
        defb  19*8, 5*8, 0
        defw  SPRITE_STONES
        defb  22*8, 5*8, 0
        defw  SPRITE_STONES
        defb  25*8, 5*8, 0
        defw  SPRITE_STONES
        defb  28*8, 5*8, 0
        defw  SPRITE_STONES

        defb  16*8, 8*8, 0
        defw  SPRITE_STONES
        defb  19*8, 8*8, 0
        defw  SPRITE_STONES
        defb  22*8, 8*8, 0
        defw  SPRITE_STONES
        defb  25*8, 8*8, 0
        defw  SPRITE_STONES
        defb  28*8, 8*8, 0
        defw  SPRITE_STONES

        defb  6*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  9*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  11*8, 8*8, 0
        defw  SPRITE_BLOCK_2

        defb  14*8, 8*8, 0
        defw  SPRITE_BLOCK_5

        defb  16*8, 11*8, 0
        defw  SPRITE_BLOCK_2
        defb  19*8, 11*8, 0
        defw  SPRITE_BLOCK_2
        defb  22*8, 11*8, 0
        defw  SPRITE_BLOCK_2
        defb  25*8, 11*8, 0
        defw  SPRITE_BLOCK_2
        defb  28*8, 11*8, 0
        defw  SPRITE_BLOCK_2

        defb  4*8, 8*8, 0
        defw  SPRITE_BLOCK_5
        defb  4*8, 11*8, 0
        defw  SPRITE_BLOCK_5
        defb  4*8, 14*8, 0
        defw  SPRITE_BLOCK_5
        defb  4*8, 17*8, 0
        defw  SPRITE_BLOCK_5

        defb  6*8, 18*8, 69
        defw  SPRITE_GRASS_1
        defb  8*8, 19*8, 69
        defw  SPRITE_GRASS_2

        defb  0

Room010:
        defb  1*8, 17*8, 0
        defw  SPRITE_STONES
        defb  4*8, 17*8, 0
        defw  SPRITE_STONES
        defb  7*8, 17*8, 0
        defw  SPRITE_STONES
        defb  10*8, 17*8, 0
        defw  SPRITE_STONES
        defb  13*8, 17*8, 0
        defw  SPRITE_STONES
        defb  16*8, 17*8, 0
        defw  SPRITE_STONES
        defb  19*8, 17*8, 0
        defw  SPRITE_STONES
        defb  22*8, 17*8, 0
        defw  SPRITE_STONES
        defb  25*8, 17*8, 0
        defw  SPRITE_STONES
        defb  28*8, 17*8, 0
        defw  SPRITE_STONES

        defb  1*8, 20*8, 0
        defw  SPRITE_STONES
        defb  4*8, 20*8, 0
        defw  SPRITE_STONES
        defb  7*8, 20*8, 0
        defw  SPRITE_STONES
        defb  10*8, 20*8, 0
        defw  SPRITE_STONES
        defb  13*8, 20*8, 0
        defw  SPRITE_STONES
        defb  16*8, 20*8, 0
        defw  SPRITE_STONES
        defb  19*8, 20*8, 0
        defw  SPRITE_STONES
        defb  22*8, 20*8, 0
        defw  SPRITE_STONES
        defb  25*8, 20*8, 0
        defw  SPRITE_STONES
        defb  28*8, 20*8, 0
        defw  SPRITE_STONES

        defb  1*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  3*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  5*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  7*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  9*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  11*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  13*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  15*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  17*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  19*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  21*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  23*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  25*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  27*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  29*8, 17*8, 0
        defw  SPRITE_BLOCK_1

        defb  1*8, 5*8, 0
        defw  SPRITE_STONES
        defb  4*8, 5*8, 0
        defw  SPRITE_STONES
        defb  7*8, 5*8, 0
        defw  SPRITE_STONES
        defb  10*8, 5*8, 0
        defw  SPRITE_STONES
        defb  13*8, 5*8, 0
        defw  SPRITE_BLOCK_2
        defb  13*8, 6*8, 0
        defw  SPRITE_BLOCK_3

        defb  1*8, 8*8, 0
        defw  SPRITE_STONES
        defb  4*8, 8*8, 0
        defw  SPRITE_STONES
        defb  7*8, 8*8, 0
        defw  SPRITE_BLOCK_5
        defb  9*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  12*8, 8*8, 0
        defw  SPRITE_BLOCK_1

        defb  1*8, 11*8, 0
        defw  SPRITE_BLOCK_2
        defb  4*8, 11*8, 0
        defw  SPRITE_BLOCK_2

        defb  22*8, 5*8, 0
        defw  SPRITE_STONES
        defb  25*8, 5*8, 0
        defw  SPRITE_STONES
        defb  28*8, 5*8, 0
        defw  SPRITE_STONES
        defb  20*8, 5*8, 0
        defw  SPRITE_BLOCK_5

        defb  19*8, 7*8, 0
        defw  SPRITE_GRASS_5
        defb  18*8, 8*8, 0
        defw  SPRITE_BLOCK_2

        defb  14*8, 11*8, 0
        defw  SPRITE_ICED_FLOOR

        defb  17*8, 14*8, 0
        defw  SPRITE_ICED_FLOOR

        defb  21*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  23*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  25*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  27*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  29*8, 8*8, 0
        defw  SPRITE_BLOCK_1

        defb  0

Room011:
        defb  1*8, 20*8, 0
        defw  SPRITE_STONES
        defb  4*8, 20*8, 0
        defw  SPRITE_STONES
        defb  7*8, 20*8, 0
        defw  SPRITE_STONES
        defb  10*8, 20*8, 0
        defw  SPRITE_STONES
        defb  13*8, 20*8, 0
        defw  SPRITE_STONES
        defb  16*8, 20*8, 0
        defw  SPRITE_STONES
        defb  19*8, 20*8, 0
        defw  SPRITE_STONES
        defb  22*8, 20*8, 0
        defw  SPRITE_STONES
        defb  25*8, 20*8, 0
        defw  SPRITE_STONES
        defb  28*8, 20*8, 0
        defw  SPRITE_STONES

        defb  1*8, 17*8, 0
        defw  SPRITE_STONES
        defb  4*8, 17*8, 0
        defw  SPRITE_STONES
        defb  7*8, 17*8, 0
        defw  SPRITE_BLOCK_4
        defb  10*8, 18*8, 0
        defw  SPRITE_BLOCK_3
        defb  12*8, 19*8, 0
        defw  SPRITE_BLOCK_1

        defb  1*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  3*8, 17*8, 0
        defw  SPRITE_BLOCK_1
        defb  5*8, 17*8, 0
        defw  SPRITE_BLOCK_1

        defb  1*8, 5*8, 0
        defw  SPRITE_STONES
        defb  4*8, 5*8, 0
        defw  SPRITE_STONES
        defb  7*8, 5*8, 0
        defw  SPRITE_STONES
        defb  10*8, 5*8, 0
        defw  SPRITE_STONES
        defb  13*8, 5*8, 0
        defw  SPRITE_STONES
        defb  16*8, 5*8, 0
        defw  SPRITE_STONES
        defb  19*8, 5*8, 0
        defw  SPRITE_STONES
        defb  22*8, 5*8, 0
        defw  SPRITE_STONES
        defb  25*8, 5*8, 0
        defw  SPRITE_STONES
        defb  28*8, 5*8, 0
        defw  SPRITE_STONES

        defb  28*8, 8*8, 0
        defw  SPRITE_BLOCK_4
        defb  28*8, 11*8, 0
        defw  SPRITE_BLOCK_4
        defb  28*8, 14*8, 0
        defw  SPRITE_BLOCK_4
        defb  28*8, 17*8, 0
        defw  SPRITE_BLOCK_4

        defb  1*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  3*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  6*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  8*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  11*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  13*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  16*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  18*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  21*8, 8*8, 0
        defw  SPRITE_BLOCK_1
        defb  23*8, 8*8, 0
        defw  SPRITE_BLOCK_2
        defb  26*8, 8*8, 0
        defw  SPRITE_BLOCK_1

        defb  27*8, 19*8, 69
        defw  SPRITE_GRASS_5

        defb  5*8, 16*8, 69
        defw  SPRITE_GRASS_4

        defb  0
; END
;-------------------------------------------------------------------------------
