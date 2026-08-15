;###############################################################################
;##### The main loop of the game and the state of the run: how many lives ######
;##### the shipwright still has and how much energy is left in him. ############
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - GameMainLoop
; Once per frame: draw the room if it changed, keep the panel up to date and
; read the keyboard. The room draws itself only when the player walked into
; another one, so almost every frame is only the panel and the keys.
GameMainLoop:
        call  ResetGame
.GameMainLoop:
        call  ShowRoom
        call  ShowGamePanel
        call  ScanCursorKeysForRoomSwitch
        call  ScanStateKeys
        halt
        jr    .GameMainLoop
; END - GameMainLoop
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ResetGame - The beginning of a run.
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
        ret
; END - ResetGame
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PlayerLoseEnergy - One point of the energy is gone.
PlayerLoseEnergy:
        ld    a,1
        jp    PlayerLoseEnergyAmount
; END - PlayerLoseEnergy
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PlayerLoseEnergyAmount - Take A points of the energy. If there is not
; enough of it, or the loss spends the last point, one life is gone and the
; energy is filled again for the lives that are left.
; A - how many points
PlayerLoseEnergyAmount:
        or    a
        ret   z
        ld    b,a

        ld    a,(PlayerLives)
        or    a
        ret   z ; He is already dead.

        ld    hl,PlayerEnergy
        ld    a,(hl)
        cp    b
        jr    c,.PlayerLoseEnergyLife
        sub   b
        ld    (hl),a
        ret   nz

.PlayerLoseEnergyLife:
        xor   a
        ld    (PlayerEnergy),a
        ld    hl,PlayerLives
        dec   (hl)
        ret   z ; After the last life nothing is filled again.

        ld    a,PLAYER_ENERGY_MAX
        ld    (PlayerEnergy),a
        ret
; END - PlayerLoseEnergyAmount
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PlayerGainEnergy - One point of the energy comes back.
PlayerGainEnergy:
        ld    a,(PlayerLives)
        or    a
        ret   z
        ld    hl,PlayerEnergy
        ld    a,(hl)
        cp    PLAYER_ENERGY_MAX
        ret   nc
        inc   (hl)
        ret
; END - PlayerGainEnergy
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PlayerGainLife - One more life, up to the place the panel has.
PlayerGainLife:
        ld    hl,PlayerLives
        ld    a,(hl)
        cp    PANEL_LIVES_MAX
        ret   nc
        inc   (hl)
        ld    a,PLAYER_ENERGY_MAX
        ld    (PlayerEnergy),a
        ret
; END - PlayerGainLife
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; The state of the run, all of it is shown in the panel.
; The lives at the beginning of the game.
PLAYER_LIVES_START equ 3
; The whole energy of the player.
PLAYER_ENERGY_MAX  equ 10

PlayerLives:
        defb  PLAYER_LIVES_START

PlayerEnergy:
        defb  PLAYER_ENERGY_MAX
;-------------------------------------------------------------------------------
