;###############################################################################
;##### Reading the keyboard. Until the castaway himself can walk, these keys ####
;##### move the world around him: Caps Shift with the cursor keys walks #########
;##### through the map of the island, and A, S, D, F take and give back his #####
;##### energy and his lives, so the panel can be seen working. ##################
;##### #########################################################################
;##### Both routines count a key once for one press: it has to be let go ########
;##### before it counts again, or a single touch would run through the whole ####
;##### island in half a second. ################################################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - ScanCursorKeysForRoomSwitch
; Caps Shift together with a cursor key steps into the room next to this one.
; The places of the map that hold a 255 are walls and the step into them is
; refused.
ScanCursorKeysForRoomSwitch:
        ld    bc,65278
        in    a,(c)
        and   1
        jr    nz,.Release ; Caps Shift is not held down.

        ld    bc,63486
        in    a,(c)
        cpl
        and   %00010000 ; The key 5, the cursor to the left.
        ld    d,a
        ld    bc,61438
        in    a,(c)
        cpl
        and   %00011100 ; The keys 6, 7 and 8: down, up and to the right.
        ld    e,a
        or    d
        jr    z,.Release ; No cursor key is held down.

        ld    a,(_KB_LastCursorKeys)
        or    a
        jr    nz,.Remember ; The same press as in the frame before this one.

        ld    hl,ActualRoomInMap
        bit   4,d
        jr    z,.Right
        ld    a,(hl)
        dec   a
        jr    .Step
.Right:
        bit   2,e
        jr    z,.Up
        ld    a,(hl)
        inc   a
        jr    .Step
.Up:
        bit   3,e
        jr    z,.Down
        ld    a,(hl)
        sub   ROOMS_MAP_WIDTH
        jr    .Step
.Down:
        bit   4,e
        jr    z,.Remember
        ld    a,(hl)
        add   a,ROOMS_MAP_WIDTH

.Step:
        ld    b,a ; The place of the map he would step into.
        call  RoomSwitcherRoomsMap
        jr    z,.Remember ; There is a wall, or nothing at all.
        ld    (hl),b

.Remember:
        ld    a,d
        or    e
        ld    (_KB_LastCursorKeys),a
        ret

.Release:
        xor   a
        ld    (_KB_LastCursorKeys),a
        ret
; END - ScanCursorKeysForRoomSwitch
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ScanStateKeys
; A takes one point of energy, S gives one back, D takes a whole life and F
; gives one. They are here to show the panel working and they go away with the
; first version that has a castaway in it.
ScanStateKeys:
        ld    bc,65022 ; G, F, D, S, A
        in    a,(c)
        cpl
        and   %00011111 ; Now a bit stands for every key that is held down.
        ld    b,a

        ld    a,(_KB_LastStateKeys)
        cpl
        and   b ; Only the keys that were not held down in the frame before.
        ld    c,a
        ld    a,b
        ld    (_KB_LastStateKeys),a

        bit   0,c ; A
        jr    z,.ScanStateKeysS
        push  bc
        call  PlayerLoseEnergy
        pop   bc

.ScanStateKeysS:
        bit   1,c ; S
        jr    z,.ScanStateKeysD
        push  bc
        call  PlayerGainEnergy
        pop   bc

.ScanStateKeysD:
        bit   2,c ; D
        jr    z,.ScanStateKeysF
        push  bc
        ld    a,PLAYER_ENERGY_MAX
        call  PlayerLoseEnergyAmount
        pop   bc

.ScanStateKeysF:
        bit   3,c ; F
        jr    z,.ScanStateKeysEnd
        call  PlayerGainLife

.ScanStateKeysEnd:
        ret
; END - ScanStateKeys
;-------------------------------------------------------------------------------

; The keys that were held down in the frame before this one.
_KB_LastCursorKeys:
        defb  0

_KB_LastStateKeys:
        defb  0

; Port: Keys:
;-----------------------------------
; 32766 B, N, M, Symbol Shift, Space
; 49150 H, J, K, L, Enter
; 57342 Y, U, I, O, P
; 61438 6, 7, 8, 9, 0
; 63486 5, 4, 3, 2, 1
; 64510 T, R, E, W, Q
; 65022 G, F, D, S, A
; 65278 V, C, X, Z, Caps Shift
