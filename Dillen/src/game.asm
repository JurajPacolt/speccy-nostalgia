;-------------------------------------------------------------------------------
; BEGIN - GameMainLoop
GameMainLoop:
        call  ResetGame
.GameMainLoop
        call  ShowRoom
        call  StarOnBackground
        call  AnimationsInRooms
        call  ScanCursorKeysForRoomSwitch
        halt
        jr    .GameMainLoop
; END - GameMainLoop
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetGame
ResetGame:
        xor   a
        ld    (LastShowedRoomInMap),a
        ld    a,(StartRoomInMap)
        ld    (ActualRoomInMap),a
        ret
; END - ResetGame
;-------------------------------------------------------------------------------
