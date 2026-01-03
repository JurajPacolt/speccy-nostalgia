;###############################################################################
;##### ASM unit for animations viewed in individual rooms. #####################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - AnimationsInRooms - Main animations-in-rooms method.
AnimationsInRooms:

        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl)

        cp    3
        jr    nz, _air_jump_1
        jp  _AIR_Room3
_air_jump_1:
        cp    4
        jr    nz, _air_jump_2
        jp  _AIR_Room4
_air_jump_2:
        ret
; END - AnimationsInRooms
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_Room3 - Animations for room 3.
_AIR_Room3:
        ; Check pause counter
        ld    hl,_AIR_Room3_pause
        ld    a,(hl)
        and   a
        jr    z,_AIR_Room3_continue
        dec   (hl)
        ret
_AIR_Room3_continue:
        ; Slow down animation
        ld    hl,_AIR_Room3_delay
        ld    a,(hl)
        inc   a
        ld    (hl),a
        cp    3
        ret    nz
        ld    (hl),0
        
        ; Restore old background from buffer
        ld    ix,_AIR_Room3_buffer
        ld    a,(_AIR_Room3_pos)
        ld    b,a
        ld    c,80
        call  _AIR_RestoreBackground

        ; Update position
        ld    hl,_AIR_Room3_pos
        ld    a,(hl)
        cp    152
        jr    nc,_AIR_Room3_reset
        add   a,8
        ld    (hl),a
        jr    _AIR_Room3_jmp1
_AIR_Room3_reset:
        ld    (hl),88
        ; Set random pause (0-150 frames, ~0-3 seconds at 50fps)
        ld    a,r
        and   127
        add   a,23
        ld    hl,_AIR_Room3_pause
        ld    (hl),a
        ret
_AIR_Room3_jmp1:
        ; Save new background to buffer
        ld    ix,_AIR_Room3_buffer
        ld    a,(_AIR_Room3_pos)
        ld    b,a
        ld    c,80
        call  _AIR_SaveBackground

        ; Draw drop at new position
        ld    ix,SpriteDrop
        ld    a,(_AIR_Room3_pos)
        ld    b,a
        ld    c,80
        call  DrawSpriteWithoutAttrs
        ret

_AIR_Room3_pos:
        defb  88

_AIR_Room3_pause:
        defb  0

_AIR_Room3_delay:
        defb  0

_AIR_Room3_buffer:
        block 8
; END - _AIR_Room3
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_Room4 - Animations for room 4.
_AIR_Room4:
        ; TODO Dopracovat animovane padane kvapky s rozbitim na zemi.
        ret
; END - _AIR_Room4
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_SaveBackground - Save background before drawing sprite
; IX - Buffer address
; B - Yos
; C - Xos
_AIR_SaveBackground:
        call  ScreenAddr
        ld    b,8  ; height
_AIR_SB_loop:
        ld    a,(hl)
        ld    (ix+0),a
        inc   ix
        call  DownHL
        djnz  _AIR_SB_loop
        ret
; END - _AIR_SaveBackground
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_RestoreBackground - Restore background from buffer
; IX - Buffer address
; B - Yos
; C - Xos
_AIR_RestoreBackground:
        call  ScreenAddr
        ld    b,8  ; height
_AIR_RB_loop:
        ld    a,(ix+0)
        ld    (hl),a
        inc   ix
        call  DownHL
        djnz  _AIR_RB_loop
        ret
; END - _AIR_RestoreBackground
;-------------------------------------------------------------------------------
