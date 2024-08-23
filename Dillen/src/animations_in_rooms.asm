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
        ; TODO Dopracovat animovane padane kvapky s rozbitim na zemi.
        ;ld    hl,BORDER_START_ADDRESS+32+1+1
        ;ld    ix,SpriteAnimBreakDrop

        ld    ix,SpriteDrop
        ld    a,(_AIR_Room3_pos)
        ld    b,a
        ld    c,80
        call  DrawSpriteWithoutAttrs

        ld    hl,_AIR_Room3_pos
        ld    a,(hl)
        add   a,8
        ld    (hl),a
        cp    160
        jr    nz,_AIR_Room3_jmp1
        ld    (hl),80
_AIR_Room3_jmp1:
        ret

_AIR_Room3_pos:
        defb  80

_AIR_Room3_buffer:
        ; TODO There is needed create method for copying background to buffer.
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
