;-------------------------------------------------------------------------------
; BEGIN - GameMainLoop
GameMainLoop:
        call  ResetGame
.GameMainLoop
        call  ShowRoom
        call  ShowGamePanel
        call  TorchesInRooms ; Before the stars, they must know about the fire.
        call  ItemsInRooms ; Static collectible items, before the stars are placed.
        call  StarOnBackground
        call  AnimationsInRooms
        call  PlayerUpdate
        call  PlayerRender
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

        ld    a,PLAYER_LIVES_START
        ld    (PlayerLives),a
        ld    a,PLAYER_ENERGY_MAX
        ld    (PlayerEnergy),a

        call  ResetGamePanel
        call  ResetItems
        call  ResetTorches
        call  ResetStars
        call  ResetWind
        call  ResetDeath
        call  PlayerReset
        ret
; END - ResetGame
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Player's state, it's showed in the game's panel.
; Lives on the begin of the game.
PLAYER_LIVES_START equ 3
; Full energy of the player.
PLAYER_ENERGY_MAX  equ 10

PlayerLives:
        defb  PLAYER_LIVES_START

PlayerEnergy:
        defb  PLAYER_ENERGY_MAX
;-------------------------------------------------------------------------------
