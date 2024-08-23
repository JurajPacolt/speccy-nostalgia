;-------------------------------------------------------------------------------
; BEGIN - ScanCursor
ScanCursorKeysForRoomSwitch:

        ld    bc,65278
        in    a,(c)
        and   1
        or    a
        jr    nz,.ScanKeysForRoomSwitchCache4 ; If 'Caps Shift' is not presented, jump to end.

        ld    bc,63486
        in    a,(c)
        bit   4,a ; cursor key to left
        jr    nz,.ScanKeysForRoomSwitchCache2

        ld    hl,ActualRoomInMap
        ld    a,(hl)
        dec   a
        call  RoomSwitcherRoomsMap
        jr    z,.ScanKeysForRoomSwitchCache2
        dec   (hl)

.ScanKeysForRoomSwitchCache2:
        ld    bc,61438
        in    a,(c)
        bit   2,a ; cursor key to right
        jr    nz,.ScanKeysForRoomSwitchCache1

        ld    hl,ActualRoomInMap
        ld    a,(hl)
        inc   a
        call  RoomSwitcherRoomsMap
        jr    z,.ScanKeysForRoomSwitchCache1
        inc   (hl)

.ScanKeysForRoomSwitchCache1:
        ld    bc,61438
        in    a,(c)
        bit   3,a ; cursor key to up
        jr    nz,.ScanKeysForRoomSwitchCache3

        ld    hl,ActualRoomInMap
        ld    a,(hl)
        scf
        sbc   a,ROOMS_MAP_WIDTH-1
        call  RoomSwitcherRoomsMap
        jr    z,.ScanKeysForRoomSwitchCache3
        ld    a,(hl)
        scf
        sbc   a,ROOMS_MAP_WIDTH-1
        ld    (hl),a

.ScanKeysForRoomSwitchCache3:
        ld    bc,61438
        in    a,(c)
        bit   4,a ; cursor key to down
        jr    nz,.ScanKeysForRoomSwitchCache4

        ld    hl,ActualRoomInMap
        ld    a,(hl)
        add   a,ROOMS_MAP_WIDTH
        call  RoomSwitcherRoomsMap
        jr    z,.ScanKeysForRoomSwitchCache4
        ld    a,(hl)
        add   a,ROOMS_MAP_WIDTH
        ld    (hl),a

.ScanKeysForRoomSwitchCache4:
        ret
; END - ScanCursor
;-------------------------------------------------------------------------------

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
