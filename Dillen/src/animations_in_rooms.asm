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

        cp    1
        jr    nz, _air_jump_0
        jp  _AIR_Room1
_air_jump_0:
        cp    3
        jr    nz, _air_jump_1
        jp  _AIR_Room3
_air_jump_1:
        cp    4
        jr    nz, _air_jump_2
        jp  _AIR_Room4
_air_jump_2:
        cp    7
        jr    nz, _air_jump_3
        jp  DeathInRoom ; The Death with the scythe, in death_in_room.asm.
_air_jump_3:
        cp    8
        jr    nz, _air_jump_4
        jp  _AIR_Room8
_air_jump_4:
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

        cp    1
        jr    z,_AIR_ICR_Room1
        cp    3
        jr    z,_AIR_ICR_Room3
        cp    7
        jr    z,_AIR_ICR_Room7
        jr    _AIR_ICR_Free

;----- Room 1 - the draught is blowing up from the chasm. ----------------------
_AIR_ICR_Room1:
        ld    a,c ; The wisps are rising in the columns over the chasm.
        cp    AIR_WIND_ROOM1_COL
        jr    c,_AIR_ICR_Free
        cp    AIR_WIND_ROOM1_COL+AIR_WIND_ROOM1_MASK+1
        jr    nc,_AIR_ICR_Free
        ld    a,b ; They are dying out under the sky, higher is a free place.
        cp    AIR_WIND_ROOM1_TOP/8
        jr    c,_AIR_ICR_Free
        jr    _AIR_ICR_Reserved

;----- Room 3 - the drop is falling from the cloud. ----------------------------
_AIR_ICR_Room3:
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
        jr    _AIR_ICR_Reserved

;----- Room 7 - the Death with the scythe is guarding the path. ----------------
_AIR_ICR_Room7:
        call  IsDeathCellReserved ; She knows her own place, no star is
        jr    c,_AIR_ICR_Reserved ; twinkling through her bones.
        jr    _AIR_ICR_Free

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

;###############################################################################
;##### The draught, it's blowing up from the underground. ######################
;##### Room 1 has the chasm under the bridge and room 8 is the shaft, ##########
;##### both of them are the entrance to the underground. The cold air is #######
;##### rising from the deep and it's blowing out to the sky. ###################
;###############################################################################

; How many wisps of the air are rising in the draught.
WIND_MAX            equ 4
; Size of one wisp's record: Xos, Yos, speed, is the wisp showed?
WIND_ITEM_SIZE      equ 4
; The slowest wisp is rising by so many pixel lines in one frame.
WIND_SPEED_MIN      equ 1
; Mask for the random speed, the fastest wisp is rising by two pixel lines.
WIND_SPEED_MASK     equ 1
; Height over the end of the draught, where the wisp is only a few points.
WIND_DYING_HEIGHT   equ 24
; Height over the end of the draught, where the wisp is losing her power.
WIND_WEAK_HEIGHT    equ 48

; Room 1 - the chasm under the bridge, the columns 11 - 18 of the game field.
AIR_WIND_ROOM1_COL    equ 11
AIR_WIND_ROOM1_MASK   equ 7
AIR_WIND_ROOM1_TOP    equ 88
AIR_WIND_ROOM1_BOTTOM equ 176
AIR_WIND_ROOM1_STEP   equ 22

; Room 8 - the shaft to the deep, the columns 16 - 19 of the game field.
AIR_WIND_ROOM8_COL    equ 16
AIR_WIND_ROOM8_MASK   equ 3
AIR_WIND_ROOM8_TOP    equ 40
AIR_WIND_ROOM8_BOTTOM equ 176
AIR_WIND_ROOM8_STEP   equ 34

;-------------------------------------------------------------------------------
; BEGIN - _AIR_Room1 - Animations for room 1. The draught is blowing up from the
;                      chasm under the bridge, high to the sky.
_AIR_Room1:
        ld    hl,_AIR_WindRoom1
        jp    _AIR_Wind
; END - _AIR_Room1
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_Room8 - Animations for room 8. The draught is blowing up from the
;                      deep of the shaft, out to the room over the underground.
_AIR_Room8:
        ld    hl,_AIR_WindRoom8
        jp    _AIR_Wind
; END - _AIR_Room8
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetWind - The wisps of the draught will be placed again.
ResetWind:
        ld    a,255 ; It's not a valid room in the map.
        ld    (_AIR_WindActualRoom),a
        ret
; END - ResetWind
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_Wind - Main method of the draught, it's called once per frame.
; HL - the draught of the actual room.
_AIR_Wind:
        ld    (_AIR_WindCfg),hl

        ; The wisps are placed again always, when the showed room is changed.
        ; The old room is forgotten, she is drawn again, without the draught.
        ld    a,(ActualRoomInMap)
        ld    hl,_AIR_WindActualRoom
        cp    (hl)
        jr    z,_AIR_W_Blow
        ld    (hl),a
        jp    _AIR_W_Place

_AIR_W_Blow:
        ; At first all the wisps are cleaned from the screen. Two of them can
        ; rise in one column, so no wisp is allowed to look for the free space,
        ; while an other one is still showed on her old position.
        ld    ix,_AIR_WindData
        ld    b,WIND_MAX
_AIR_W_HideLoop:
        push  bc
        call  _AIR_W_Hide
        call  _AIR_W_Next
        pop   bc
        djnz  _AIR_W_HideLoop

        ld    ix,_AIR_WindData
        ld    b,WIND_MAX
_AIR_W_ShowLoop:
        push  bc
        call  _AIR_W_Rise ; The air is blowing the wisp up.
        call  _AIR_W_Show ; The wisp is drawn to her new position.
        call  _AIR_W_Next
        pop   bc
        djnz  _AIR_W_ShowLoop
        ret
; END - _AIR_Wind
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Place - The wisps are spread in the whole height of the draught,
;                        so the air is blowing at once, when the room is showed.
;                        The wisps of the old room aren't cleaned, the new room
;                        is already drawn over them.
_AIR_W_Place:
        ld    ix,_AIR_WindData

        call  _AIR_W_CfgBottom
        ld    a,(hl)
        ld    (_AIR_WindPlaceY),a

        ld    b,WIND_MAX
_AIR_W_P_Loop:
        push  bc
        call  _AIR_W_Spawn ; The random column and the random speed.

        ld    a,(_AIR_WindPlaceY) ; Every wisp is rising in an other height.
        ld    (ix+1),a
        call  _AIR_W_CfgStep
        ld    a,(_AIR_WindPlaceY)
        sub   (hl)
        ld    (_AIR_WindPlaceY),a

        call  _AIR_W_Show
        call  _AIR_W_Next
        pop   bc
        djnz  _AIR_W_P_Loop
        ret
; END - _AIR_W_Place
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Spawn - A new wisp is coming from the deep of the underground.
; IX - Record of the wisp.
_AIR_W_Spawn:
        call  _AIR_W_Random ; The random column of the draught.
        ld    hl,(_AIR_WindCfg)
        inc   hl
        and   (hl) ; The count of the columns is a power of two.
        dec   hl
        add   a,(hl)
        add   a,a
        add   a,a
        add   a,a ; The character column - Xos.
        ld    (ix+0),a

        call  _AIR_W_CfgBottom
        ld    a,(hl) ; The wisp is blowing from the bottom of the draught.
        ld    (ix+1),a

        call  _AIR_W_Random ; Every wisp is rising with an other speed.
        and   WIND_SPEED_MASK
        add   a,WIND_SPEED_MIN
        ld    (ix+2),a

        ld    (ix+3),0 ; The new wisp isn't showed on the screen.
        ret
; END - _AIR_W_Spawn
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Rise - The next position of the wisp, she is rising up.
; IX - Record of the wisp.
_AIR_W_Rise:
        ld    a,(ix+1)
        sub   (ix+2) ; Yos - speed.
        ld    e,a
        call  _AIR_W_CfgTop
        ld    a,e
        cp    (hl)
        jp    c,_AIR_W_Spawn ; The wisp is blowed out, a new one is coming.
        ld    (ix+1),e
        ret
; END - _AIR_W_Rise
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Hide - The wisp is cleaned from her old position. She was drawn
;                       only on the black background, so the black color is
;                       coming back.
; IX - Record of the wisp.
_AIR_W_Hide:
        ld    a,(ix+3)
        or    a
        ret   z ; The wisp isn't showed on the screen.
        ld    (ix+3),0

        ld    c,(ix+0) ; Xos.
        ld    b,(ix+1) ; Yos.
        call  ScreenAddr
        ld    b,8
_AIR_W_H_Line:
        ld    (hl),0
        call  DownHL
        djnz  _AIR_W_H_Line
        ret
; END - _AIR_W_Hide
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Show - The wisp is drawn to her actual position. The air is
;                       flowing only through the free space, behind the rocks or
;                       the bridge is the wisp hidden.
; IX - Record of the wisp.
_AIR_W_Show:
        ld    c,(ix+0) ; Xos.
        ld    b,(ix+1) ; Yos.
        call  ScreenAddr ; HL - place of the wisp in the VRAM.
        push  hl

        ld    b,8 ; Is the place of the wisp empty?
        ld    c,0
_AIR_W_S_Empty:
        ld    a,(hl)
        or    c
        ld    c,a
        call  DownHL
        djnz  _AIR_W_S_Empty

        pop   hl
        ld    a,c
        or    a
        ret   nz ; No, here is a rock or the bridge, the wisp isn't showed.

        ; The wisp is losing her power, while she is rising to the end of the
        ; draught.
        push  hl
        ld    a,(ix+1)
        call  _AIR_W_CfgTop
        sub   (hl) ; Height over the end of the draught.
        cp    WIND_DYING_HEIGHT
        jr    c,_AIR_W_S_Dying
        cp    WIND_WEAK_HEIGHT
        jr    c,_AIR_W_S_Weak

        ld    a,(ix+1) ; The strong wisp is waving, while she is rising.
        srl   a
        srl   a
        and   1
        jr    _AIR_W_S_Image
_AIR_W_S_Weak:
        ld    a,2
        jr    _AIR_W_S_Image
_AIR_W_S_Dying:
        ld    a,3

_AIR_W_S_Image:
        add   a,a
        add   a,a
        add   a,a ; Eight bytes for one image of the wisp.
        ld    e,a
        ld    d,0
        ld    hl,_AIR_WindShapes
        add   hl,de
        ex    de,hl ; DE - the actual image of the wisp.

        pop   hl ; HL - place of the wisp in the VRAM.
        ld    b,8
_AIR_W_S_Line:
        ld    a,(de)
        ld    (hl),a ; The background is black, the wisp can be putted here.
        inc   de
        call  DownHL
        djnz  _AIR_W_S_Line

        ld    (ix+3),1 ; The wisp must be cleaned in the next frame.
        ret
; END - _AIR_W_Show
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Next - The record of the next wisp.
_AIR_W_Next:
        ld    de,WIND_ITEM_SIZE
        add   ix,de
        ret
; END - _AIR_W_Next
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Cfg* - Items of the draught of the actual room.
; return HL - address of the item.
_AIR_W_CfgTop:
        ld    hl,(_AIR_WindCfg)
        inc   hl
        inc   hl
        ret

_AIR_W_CfgBottom:
        ld    hl,(_AIR_WindCfg)
        ld    de,3
        add   hl,de
        ret

_AIR_W_CfgStep:
        ld    hl,(_AIR_WindCfg)
        ld    de,4
        add   hl,de
        ret
; END - _AIR_W_Cfg*
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - _AIR_W_Random - Next random number.
; return A - random number.
_AIR_W_Random:
        push  hl
        push  bc
        ld    hl,_AIR_WindSeed
        call  Random8bit
        pop   bc
        pop   hl
        ret
; END - _AIR_W_Random
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; The draught of one room: the first character column of the wisps, the mask for
; their random column, Yos where they are dying out, Yos where they are blowing
; from and the distance between them, when the room is showed.
_AIR_WindRoom1:
        defb  AIR_WIND_ROOM1_COL, AIR_WIND_ROOM1_MASK
        defb  AIR_WIND_ROOM1_TOP, AIR_WIND_ROOM1_BOTTOM
        defb  AIR_WIND_ROOM1_STEP

_AIR_WindRoom8:
        defb  AIR_WIND_ROOM8_COL, AIR_WIND_ROOM8_MASK
        defb  AIR_WIND_ROOM8_TOP, AIR_WIND_ROOM8_BOTTOM
        defb  AIR_WIND_ROOM8_STEP

; The draught of the actually showed room.
_AIR_WindCfg:
        defw  _AIR_WindRoom1

; Room, for which are the wisps actually placed. 255 - none.
_AIR_WindActualRoom:
        defb  255

; Yos of the wisp, which is actually placed to the draught.
_AIR_WindPlaceY:
        defb  0

; Seed of the random numbers.
_AIR_WindSeed:
        defb  151

; Records of the wisps.
_AIR_WindData:
        block WIND_MAX*WIND_ITEM_SIZE

; Images of the wisps. The strong air is waving (0, 1), then she is losing her
; power (2) and on the end of the draught she is dying out (3).
_AIR_WindShapes:
        ; 0 - the strong wisp, waving to the left
        defb  %00011000
        defb  %00110000
        defb  %00110000
        defb  %00011000
        defb  %00011000
        defb  %00001100
        defb  %00001100
        defb  %00011000
        ; 1 - the strong wisp, waving to the right
        defb  %00011000
        defb  %00001100
        defb  %00001100
        defb  %00011000
        defb  %00011000
        defb  %00110000
        defb  %00110000
        defb  %00011000
        ; 2 - the weak wisp
        defb  %00000000
        defb  %00010000
        defb  %00110000
        defb  %00010000
        defb  %00011000
        defb  %00001000
        defb  %00000000
        defb  %00000000
        ; 3 - the dying wisp
        defb  %00000000
        defb  %00000000
        defb  %00010000
        defb  %00001000
        defb  %00000000
        defb  %00010000
        defb  %00000000
        defb  %00000000
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
