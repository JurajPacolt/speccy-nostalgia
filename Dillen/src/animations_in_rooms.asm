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
; BEGIN - AIR_IsCellReserved - Is the character cell used by an animation of the
;                              actual room? Other effects (stars) must keep away
;                              from it, the animation is saving and restoring
;                              the background under itself.
; B - character row.
; C - character column.
; return CF=1 - the cell must stay free.
AIR_IsCellReserved:
        push  hl
        push  de
        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl) ; Room's ID number.

        cp    3
        jr    nz,_AIR_ICR_Free

        ld    a,c ; The drop is falling in one column of the room.
        cp    AIR_ROOM3_DROP_X/8
        jr    z,_AIR_ICR_Reserved

        ld    a,b ; The splash is breaking on the ground.
        cp    AIR_ROOM3_GROUND_Y/8
        jr    nz,_AIR_ICR_Free
        ld    a,c
        cp    AIR_ROOM3_SPLASH_X/8
        jr    c,_AIR_ICR_Free
        cp    AIR_ROOM3_SPLASH_X/8+3
        jr    nc,_AIR_ICR_Free

_AIR_ICR_Reserved:
        scf
        jr    _AIR_ICR_End
_AIR_ICR_Free:
        or    a ; CF=0
_AIR_ICR_End:
        pop   de
        pop   hl
        ret
; END - AIR_IsCellReserved
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_Room3 - Animations for room 3. A drop is falling from the cloud
;                      and it's breaking to the splash on the ground.

; Xos of the falling drop.
AIR_ROOM3_DROP_X        equ 80
; Yos, where the drop is beginning to fall, under the cloud.
AIR_ROOM3_DROP_Y        equ 88
; Yos, where the drop is hitting the ground.
AIR_ROOM3_GROUND_Y      equ 152
; Xos of the splash, it's wider than the drop.
AIR_ROOM3_SPLASH_X      equ AIR_ROOM3_DROP_X-8
; Frames for one step of the falling drop.
AIR_ROOM3_FALL_DELAY    equ 3
; Frames for one image of the splash.
AIR_ROOM3_SPLASH_DELAY  equ 3

; States of the animation.
AIR_ROOM3_STATE_FALL    equ 0
AIR_ROOM3_STATE_SPLASH  equ 1
AIR_ROOM3_STATE_PAUSE   equ 2

_AIR_Room3:
        ld    a,(_AIR_Room3_state)
        cp    AIR_ROOM3_STATE_SPLASH
        jp    z,_AIR_R3_Splash
        cp    AIR_ROOM3_STATE_PAUSE
        jp    z,_AIR_R3_Pause

;----- The drop is falling down. -----------------------------------------------
_AIR_R3_Fall:
        ; Slow down the animation.
        ld    hl,_AIR_Room3_delay
        inc   (hl)
        ld    a,(hl)
        cp    AIR_ROOM3_FALL_DELAY
        ret   nz
        ld    (hl),0

        ; Clean the drop from her old position.
        ld    ix,_AIR_Room3_buffer
        ld    a,(_AIR_Room3_pos)
        ld    b,a
        ld    c,AIR_ROOM3_DROP_X
        ld    d,1
        call  _AIR_RestoreBackground

        ; The next position of the drop.
        ld    hl,_AIR_Room3_pos
        ld    a,(hl)
        cp    AIR_ROOM3_GROUND_Y
        jr    nc,_AIR_R3_Hit ; The drop is on the ground.
        add   a,8
        ld    (hl),a

        ; Save the background under the new position of the drop.
        ld    ix,_AIR_Room3_buffer
        ld    b,a
        ld    c,AIR_ROOM3_DROP_X
        ld    d,1
        call  _AIR_SaveBackground

        ; Draw the drop to her new position.
        ld    ix,SPRITE_DROP
        ld    a,(_AIR_Room3_pos)
        ld    b,a
        ld    c,AIR_ROOM3_DROP_X
        call  DrawSpriteWithoutAttrs
        ret

;----- The drop is hitting the ground. -----------------------------------------
_AIR_R3_Hit:
        xor   a
        ld    (_AIR_Room3_delay),a
        ld    (_AIR_Room3_image),a ; The splash begins with her first image.
        ld    a,AIR_ROOM3_STATE_SPLASH
        ld    (_AIR_Room3_state),a

        ; Save the background under the splash. The drop is already cleaned,
        ; so there is only the empty ground in the buffer.
        call  _AIR_R3_SaveSplash
        jr    _AIR_R3_DrawSplash

;----- The drop is breaking to the splash. -------------------------------------
_AIR_R3_Splash:
        ; Slow down the animation.
        ld    hl,_AIR_Room3_delay
        inc   (hl)
        ld    a,(hl)
        cp    AIR_ROOM3_SPLASH_DELAY
        ret   nz
        ld    (hl),0

        ; Clean the old image of the splash.
        call  _AIR_R3_RestoreSplash

        ; The next image of the splash.
        ld    hl,_AIR_Room3_image
        inc   (hl)
        ld    a,(hl)
        cp    SPRITE_BREAK_DROP_COUNT
        jr    c,_AIR_R3_DrawSplash

        ; The splash is finished, the next drop will fall after a pause.
        ld    a,AIR_ROOM3_DROP_Y
        ld    (_AIR_Room3_pos),a
        ld    a,r ; Random pause, 23 - 150 frames.
        and   127
        add   a,23
        ld    (_AIR_Room3_pause),a
        ld    a,AIR_ROOM3_STATE_PAUSE
        ld    (_AIR_Room3_state),a
        ret

_AIR_R3_DrawSplash:
        ld    a,(_AIR_Room3_image)
        add   a,a ; Every image has her address in the table.
        ld    e,a
        ld    d,0
        ld    hl,SPRITE_BREAK_DROP_IMAGES
        add   hl,de
        ld    a,(hl)
        inc   hl
        ld    h,(hl)
        ld    l,a
        push  hl
        pop   ix
        ld    b,AIR_ROOM3_GROUND_Y
        ld    c,AIR_ROOM3_SPLASH_X
        call  DrawSpriteWithoutAttrs
        ret

;----- Waiting for the next drop. ----------------------------------------------
_AIR_R3_Pause:
        ld    hl,_AIR_Room3_pause
        dec   (hl)
        ret   nz
        xor   a
        ld    (_AIR_Room3_delay),a
        ld    a,AIR_ROOM3_STATE_FALL
        ld    (_AIR_Room3_state),a
        ret

_AIR_R3_SaveSplash:
        ld    ix,_AIR_Room3_splash_buffer
        ld    b,AIR_ROOM3_GROUND_Y
        ld    c,AIR_ROOM3_SPLASH_X
        ld    d,3
        jp    _AIR_SaveBackground

_AIR_R3_RestoreSplash:
        ld    ix,_AIR_Room3_splash_buffer
        ld    b,AIR_ROOM3_GROUND_Y
        ld    c,AIR_ROOM3_SPLASH_X
        ld    d,3
        jp    _AIR_RestoreBackground

_AIR_Room3_state:
        defb  AIR_ROOM3_STATE_FALL

_AIR_Room3_pos:
        defb  AIR_ROOM3_DROP_Y

_AIR_Room3_image:
        defb  0

_AIR_Room3_pause:
        defb  0

_AIR_Room3_delay:
        defb  0

_AIR_Room3_buffer:
        block 8

_AIR_Room3_splash_buffer:
        block 24
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
; D - Width of the sprite in the characters.
_AIR_SaveBackground:
        call  ScreenAddr
        ld    b,8  ; height
_AIR_SB_Line:
        push  bc
        push  hl
        ld    b,d
_AIR_SB_Byte:
        ld    a,(hl)
        ld    (ix+0),a
        inc   ix
        inc   hl
        djnz  _AIR_SB_Byte
        pop   hl
        call  DownHL
        pop   bc
        djnz  _AIR_SB_Line
        ret
; END - _AIR_SaveBackground
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_RestoreBackground - Restore background from buffer
; IX - Buffer address
; B - Yos
; C - Xos
; D - Width of the sprite in the characters.
_AIR_RestoreBackground:
        call  ScreenAddr
        ld    b,8  ; height
_AIR_RB_Line:
        push  bc
        push  hl
        ld    b,d
_AIR_RB_Byte:
        ld    a,(ix+0)
        ld    (hl),a
        inc   ix
        inc   hl
        djnz  _AIR_RB_Byte
        pop   hl
        call  DownHL
        pop   bc
        djnz  _AIR_RB_Line
        ret
; END - _AIR_RestoreBackground
;-------------------------------------------------------------------------------
