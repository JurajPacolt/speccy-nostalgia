;###############################################################################
;##### ASM unit for the torches with the burning fire on the poles. ############
;##### The torches are standing on the ground of the surface rooms. ############
;###############################################################################

; Frames for one image of the fire.
TORCHES_FIRE_DELAY  equ 4
; Length of the flickering sequence, it must be a power of two.
TORCHES_SEQ_LENGTH  equ 8
; Number of the rooms in the table with the torches.
TORCHES_ROOMS_COUNT equ 12
; Height of the fire in the pixel lines, it's burning over the pole.
TORCHES_FIRE_HEIGHT equ 16

;-------------------------------------------------------------------------------
; BEGIN - TorchesInRooms - Main torches method, it's called once per frame.
TorchesInRooms:
        ; The poles are drawn again always, when the showed room is changed.
        ld    a,(ActualRoomInMap)
        ld    hl,_TIR_Room
        cp    (hl)
        jr    z,_TIR_Flicker
        ld    (hl),a
        xor   a
        ld    (_TIR_Delay),a
        call  _TIR_DrawPoles
        ; The fire must burn at once, before the stars are looking for the free
        ; cells of the room.
        jr    _TIR_DrawFires

_TIR_Flicker:
        ; Slow down the flickering of the fire.
        ld    hl,_TIR_Delay
        inc   (hl)
        ld    a,(hl)
        cp    TORCHES_FIRE_DELAY
        ret   nz
        ld    (hl),0
        ld    hl,_TIR_Step
        inc   (hl)

;-------------------------------------------------------------------------------
; BEGIN - _TIR_DrawFires - The actual image of the fire on every torch.
_TIR_DrawFires:
        call  _TIR_RoomTorches
        ld    (_TIR_Pointer),hl
        xor   a
        ld    (_TIR_Index),a

_TIR_DF_Loop:
        ld    hl,(_TIR_Pointer)
        ld    a,(hl)
        or    a
        ret   z ; End of the torches in the room.
        ld    c,a ; C - Xos.
        inc   hl
        ld    a,(hl)
        sub   TORCHES_FIRE_HEIGHT ; The fire is burning over the pole.
        ld    b,a ; B - Yos.
        inc   hl
        ld    (_TIR_Pointer),hl

        push  bc
        ; Every torch is flickering in an other step of the sequence.
        ld    a,(_TIR_Step)
        ld    hl,_TIR_Index
        add   a,(hl)
        and   TORCHES_SEQ_LENGTH-1
        add   a,a ; Two bytes for the address of one image.
        ld    e,a
        ld    d,0
        ld    hl,_TIR_FireSequence
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        push  de
        pop   ix ; IX - actual image of the fire.
        pop   bc

        ; The attributes are written directly to the screen, so the fire is
        ; flickering with her color too.
        ld    de,22528
        call  DrawSprite

        ld    hl,_TIR_Index
        inc   (hl)
        jr    _TIR_DF_Loop
; END - _TIR_DrawFires
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _TIR_DrawPoles - The poles of the torches of the actual room.
_TIR_DrawPoles:
        call  _TIR_RoomTorches
        ld    (_TIR_Pointer),hl

_TIR_DP_Loop:
        ld    hl,(_TIR_Pointer)
        ld    a,(hl)
        or    a
        ret   z ; End of the torches in the room.
        ld    c,a ; C - Xos.
        inc   hl
        ld    b,(hl) ; B - Yos.
        inc   hl
        ld    (_TIR_Pointer),hl

        ld    ix,SPRITE_TORCH_POLE
        ld    de,22528
        call  DrawSprite
        jr    _TIR_DP_Loop
; END - _TIR_DrawPoles
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _TIR_RoomTorches - Torches of the actual room.
; return HL - address of the list with the torches.
_TIR_RoomTorches:
        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl) ; Room's ID number.
        cp    TORCHES_ROOMS_COUNT
        jr    nc,_TIR_RT_None
        ld    hl,_TorchesRooms
        ld    e,a
        ld    d,0
        add   hl,de
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        ex    de,hl
        ret
_TIR_RT_None:
        ld    hl,_TorchesNone
        ret
; END - _TIR_RoomTorches
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetTorches - The poles will be drawn again.
ResetTorches:
        ld    a,255 ; It's not a valid room in the map.
        ld    (_TIR_Room),a
        ret
; END - ResetTorches
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Room, for which are the poles actually drawn. 255 - none.
_TIR_Room:
        defb  255

; Actual step of the flickering sequence.
_TIR_Step:
        defb  0

; Counter of the frames between two images of the fire.
_TIR_Delay:
        defb  0

; Pointer to the list of the torches, it's used while they are drawn.
_TIR_Pointer:
        defw  0

; Number of the actually drawn torch.
_TIR_Index:
        defb  0

; Sequence of the images of the fire. Every image has an other shape and an
; other color, so the fire is flickering.
_TIR_FireSequence:
        defw  SPRITE_FIRE_1
        defw  SPRITE_FIRE_2
        defw  SPRITE_FIRE_1
        defw  SPRITE_FIRE_3
        defw  SPRITE_FIRE_2
        defw  SPRITE_FIRE_1
        defw  SPRITE_FIRE_3
        defw  SPRITE_FIRE_2

;-------------------------------------------------------------------------------
; BEGIN - TORCHES IN THE ROOMS
; One torch: Xos of the pole, Yos of the top of the pole. The pole is standing
; on the ground and the fire is burning over her. Zero is the end of the list.
_TorchesRooms:
        defw  _TorchesNone  ; 000 - blank room
        defw  _TorchesRoom1 ; 001
        defw  _TorchesRoom2 ; 002
        defw  _TorchesRoom3 ; 003
        defw  _TorchesRoom4 ; 004
        defw  _TorchesRoom5 ; 005
        defw  _TorchesRoom6 ; 006
        defw  _TorchesRoom7 ; 007
        defw  _TorchesNone  ; 008 - underground
        defw  _TorchesNone  ; 009 - underground
        defw  _TorchesNone  ; 010 - underground
        defw  _TorchesNone  ; 011 - underground

_TorchesNone:
        defb  0

_TorchesRoom1:
        defb  3*8, 136
        defb  23*8, 136
        defb  0

_TorchesRoom2:
        defb  3*8, 136
        defb  27*8, 136
        defb  0

_TorchesRoom3:
        defb  3*8, 136
        defb  22*8, 136
        defb  0

_TorchesRoom4:
        defb  10*8, 136
        defb  20*8, 136
        defb  0

_TorchesRoom5:
        defb  3*8, 136
        defb  12*8, 136
        defb  0

_TorchesRoom6:
        defb  7*8, 136
        defb  25*8, 136
        defb  0

_TorchesRoom7:
        defb  9*8, 136
        defb  28*8, 136
        defb  0
; END
;-------------------------------------------------------------------------------
