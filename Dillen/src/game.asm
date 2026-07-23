;-------------------------------------------------------------------------------
; BEGIN - GameMainLoop
GameMainLoop:
        call  ResetGame
.GameMainLoop
        ld    a,(LifeLostState)
        or    a
        jr    nz,.GameMainLoopLifeLost

        ld    a,(_INV_State)
        or    a
        jr    nz,.GameMainLoopInventory

        call  ShowRoom
        call  ShowGamePanel
        call  TorchesInRooms ; Before the stars, they must know about the fire.
        call  ItemsInRooms ; Static collectible items, before the stars are placed.
        call  StarOnBackground
        call  AnimationsInRooms
        call  PlayerUpdate
        call  PlayerRender
        call  ScanCursorKeysForRoomSwitch
        call  InventoryScanEnterKey ; ENTER opens the inventory (inventory.asm).
        jr    .GameMainLoopTick

.GameMainLoopInventory:
        ; The window is a modal pause: nothing above runs while it is open.
        call  InventoryHandleOpen
        jr    .GameMainLoopTick

.GameMainLoopLifeLost:
        ; Losing a life pauses the game until its message is dismissed.
        call  LifeLostHandle

.GameMainLoopTick:
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
        call  ResetAnimationsInRooms
        call  ResetWind
        call  ResetDeath
        call  PlayerReset
        call  InventoryReset
        call  LifeLostReset
        ret
; END - ResetGame
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PlayerLoseEnergy - Remove one point of energy. Spending the last point
; also removes one life and refills the energy for the remaining lives.
PlayerLoseEnergy:
        ld    a,(PlayerLives)
        or    a
        ret   z ; The player is already dead.

        ld    hl,PlayerEnergy
        ld    a,(hl)
        or    a
        jr    z,.PlayerLoseEnergyLife
        dec   (hl)
        ret   nz

.PlayerLoseEnergyLife:
        ld    hl,PlayerLives
        dec   (hl)
        jr    z,.PlayerLoseEnergyShow ; No energy is restored after the last life.

        ld    a,PLAYER_ENERGY_MAX
        ld    (PlayerEnergy),a
.PlayerLoseEnergyShow:
        jp    LifeLostShow
; END - PlayerLoseEnergy
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
