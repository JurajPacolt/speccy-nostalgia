;===============================================================================
; Dillen - player movement, animation and masked 16x24 drawing.
; Controls: Z/X, O/P or Kempston left/right; Space or Kempston fire to jump.
;-------------------------------------------------------------------------------

PLAYER_STATE_IDLE              equ 0
PLAYER_STATE_WALK              equ 1
PLAYER_STATE_JUMP              equ 2
PLAYER_INPUT_RIGHT             equ 1
PLAYER_INPUT_LEFT              equ 2
PLAYER_INPUT_JUMP              equ 16
PLAYER_X_MIN                   equ 8
PLAYER_X_MAX                   equ 232
PLAYER_Y_MIN                   equ 40
PLAYER_FLOOR_Y                 equ 160
PLAYER_JUMP_PHASES             equ 17
PLAYER_JUMP_CURL_PHASE         equ 6
PLAYER_JUMP_FALL_PHASE         equ 11
PLAYER_WALK_SPEED              equ 2  ; Pixels per tick, and so the width of the
                                      ; strip every step uncovers in front of him.
PLAYER_FOOT_WIDTH              equ 16 ; The frame is 24 lines high and 16 wide.
PLAYER_CELL_HEIGHT             equ 8  ; One attribute, the step he still walks up.
PLAYER_IDLE_BLINK_START        equ 80
PLAYER_IDLE_BLINK_END          equ 84
PLAYER_IDLE_HOP_SQUASH_START   equ 192
PLAYER_IDLE_HOP_AIR_START      equ 196
PLAYER_IDLE_HOP_LAND_START     equ 208
PLAYER_IDLE_HOP_END            equ 212
PLAYER_OVERLAP_NONE            equ 0
PLAYER_OVERLAP_SAME_COLUMN     equ 1
PLAYER_OVERLAP_NEW_RIGHT       equ 2
PLAYER_OVERLAP_NEW_LEFT        equ 3

; The ink of an attribute tells what the room painted there. It is the whole
; material table of the game.
PLAYER_INK_GRASS               equ 4 ; Green, the grass growing in front of the rooms.
PLAYER_INK_SCENERY             equ 7 ; White: the empty room, the clouds and the
                                     ; railing of the bridge he walks behind.

;-------------------------------------------------------------------------------
; Reset the player on the bridge in the starting room.
PlayerReset:
        ld    a,112
        ld    (PlayerX),a
        ld    (PlayerY),a
        ld    a,1
        ld    (PlayerDirection),a
        xor   a
        ld    (PlayerState),a
        ld    (PlayerAnimationTick),a
        ld    (PlayerIdleTick),a
        ld    (PlayerJumpPhase),a
        ld    (PlayerJumpDirection),a
        ld    (PlayerJumpLatch),a
        ld    (PlayerKnockbackPending),a
        ld    (PlayerBackgroundValid),a
        ld    a,255
        ld    (PlayerDrawnRoom),a
        ret

;-------------------------------------------------------------------------------
; Pre-shift every walking frame used by the two-pixel movement. This runs once
; during start-up, outside the game loop, so walking only has to copy a prepared
; frame instead of shifting 24 bitmap and mask rows every tick.
PlayerBuildWalkCache:
        ld    de,PlayerPreparedWalkFrames
        ld    (PlayerWalkCacheWriteAddress),de
        xor   a
        ld    (PlayerWalkCacheDirection),a
        ld    (PlayerWalkCacheFrame),a
        ld    (PlayerWalkCacheShift),a
.PlayerBuildWalkCacheFrame:
        ld    a,PLAYER_STATE_WALK
        ld    (PlayerState),a
        ld    a,(PlayerWalkCacheDirection)
        ld    (PlayerDirection),a
        ld    a,(PlayerWalkCacheFrame)
        add   a,a
        add   a,a
        ld    (PlayerAnimationTick),a
        call  PlayerSelectFrame
        ld    a,(PlayerWalkCacheShift)
        call  PlayerPrepareShiftedFrame

        ld    hl,PlayerShiftedBitmap
        ld    de,(PlayerWalkCacheWriteAddress)
        ld    bc,PLAYER_SPRITE_HEIGHT*3
        ldir
        ld    hl,PlayerShiftedMask
        ld    bc,PLAYER_SPRITE_HEIGHT*3
        ldir
        ld    (PlayerWalkCacheWriteAddress),de

        ld    a,(PlayerWalkCacheShift)
        add   a,PLAYER_WALK_SPEED
        cp    8
        jr    nc,.PlayerBuildWalkCacheNextFrame
        ld    (PlayerWalkCacheShift),a
        jr    .PlayerBuildWalkCacheFrame
.PlayerBuildWalkCacheNextFrame:
        xor   a
        ld    (PlayerWalkCacheShift),a
        ld    a,(PlayerWalkCacheFrame)
        inc   a
        cp    4
        jr    nc,.PlayerBuildWalkCacheNextDirection
        ld    (PlayerWalkCacheFrame),a
        jr    .PlayerBuildWalkCacheFrame
.PlayerBuildWalkCacheNextDirection:
        xor   a
        ld    (PlayerWalkCacheFrame),a
        ld    a,(PlayerWalkCacheDirection)
        inc   a
        cp    2
        ret   nc
        ld    (PlayerWalkCacheDirection),a
        jr    .PlayerBuildWalkCacheFrame

;-------------------------------------------------------------------------------
; Restore the bytes covered by the previous player frame.
; Used when the new position cannot directly replace the old horizontal strip.
; The saved bytes belong to the room that was on the screen when they were taken,
; which is LastShowedRoomInMap and not the room he is already walking in: when he
; leaves a room he is still drawn over the old picture for that one frame.
PlayerErase:
        ld    a,(PlayerBackgroundValid)
        or    a
        ret   z
        ld    a,(LastShowedRoomInMap)
        ld    hl,PlayerDrawnRoom
        cp    (hl)
        jr    z,.PlayerEraseRestore
        xor   a
        ld    (PlayerBackgroundValid),a
        ret

.PlayerEraseRestore:
        ld    hl,(PlayerOldScreenAddress)
        ld    de,PlayerBackground
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerEraseRow:
        push  bc
        push  hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        pop   hl
        call  DownHL
        pop   bc
        djnz  .PlayerEraseRow
        xor   a
        ld    (PlayerBackgroundValid),a
        ret

;-------------------------------------------------------------------------------
; Redraw only when position or animation changed. An unchanged frame is merely
; overlaid again, so dynamic scenery cannot hide it and no blank frame is shown.
PlayerRender:
        call  PlayerSelectFrame
        ld    (PlayerSelectedSprite),hl
        ld    (PlayerSelectedMask),de
        ld    a,(PlayerBackgroundValid)
        or    a
        jr    z,.PlayerRenderChanged
        ld    a,(LastShowedRoomInMap)
        ld    hl,PlayerDrawnRoom
        cp    (hl)
        jr    nz,.PlayerRenderChanged
        ld    a,(PlayerX)
        ld    hl,PlayerRenderedX
        cp    (hl)
        jr    nz,.PlayerRenderChanged
        ld    a,(PlayerY)
        ld    hl,PlayerRenderedY
        cp    (hl)
        jr    nz,.PlayerRenderChanged
        ld    hl,(PlayerSelectedSprite)
        ld    de,(PlayerRenderedSprite)
        or    a
        sbc   hl,de
        jp    z,PlayerOverlayPrepared
        jp    PlayerRedrawSamePosition
.PlayerRenderChanged:
        ; Prepare the shifted frame while the old one is still visible. The
        ; background and final image are also composed before any screen erase.
        ld    hl,(PlayerSelectedSprite)
        ld    (PlayerRenderedSprite),hl
        ld    a,(PlayerState)
        cp    PLAYER_STATE_WALK
        jr    nz,.PlayerRenderPrepareDynamic
        ld    a,(PlayerX)
        and   1
        jr    nz,.PlayerRenderPrepareDynamic
        call  PlayerPrepareWalkFrame
        jr    .PlayerRenderPrepared
.PlayerRenderPrepareDynamic:
        ld    hl,(PlayerSelectedSprite)
        ld    de,(PlayerSelectedMask)
        ld    a,(PlayerX)
        and   7
        call  PlayerPrepareShiftedFrame
.PlayerRenderPrepared:
        call  PlayerComposePrepared

        ; Horizontal movement at the same height can replace the old frame
        ; directly. At a byte boundary only the one column left behind needs
        ; restoring; the player is never completely removed from the screen.
        ld    a,(PlayerOverlapMode)
        or    a
        jr    z,.PlayerRenderEraseAll
        ld    a,(PlayerY)
        ld    hl,PlayerRenderedY
        cp    (hl)
        jr    nz,.PlayerRenderEraseAll
        ld    a,(PlayerOverlapMode)
        cp    PLAYER_OVERLAP_SAME_COLUMN
        jp    z,PlayerDrawComposed
        call  PlayerEraseOutgoingColumn
        jp    PlayerDrawComposed
.PlayerRenderEraseAll:
        call  PlayerErase
        jp    PlayerDrawComposed

;-------------------------------------------------------------------------------
; Read keyboard and Kempston controls into PlayerInput.
PlayerReadInput:
        ld    d,0

        ld    bc,57342 ; Y, U, I, O, P
        in    a,(c)
        bit   1,a ; O - left
        jr    nz,.PlayerReadInputRight
        set   1,d
.PlayerReadInputRight:
        bit   0,a ; P - right
        jr    nz,.PlayerReadInputZX
        set   0,d
.PlayerReadInputZX:
        ld    bc,65278 ; V, C, X, Z, Caps Shift
        in    a,(c)
        bit   1,a ; Z - left
        jr    nz,.PlayerReadInputX
        set   1,d
.PlayerReadInputX:
        bit   2,a ; X - right
        jr    nz,.PlayerReadInputJump
        set   0,d
.PlayerReadInputJump:
        ld    bc,32766 ; B, N, M, Symbol Shift, Space
        in    a,(c)
        bit   0,a
        jr    nz,.PlayerReadInputKempston
        set   4,d
.PlayerReadInputKempston:
        in    a,(31)
        and   31
        cp    31 ; An absent Kempston interface usually leaves every bit high.
        jr    z,.PlayerReadInputKeyboardOnly
        and   PLAYER_INPUT_LEFT+PLAYER_INPUT_RIGHT+PLAYER_INPUT_JUMP
        or    d
        jr    .PlayerReadInputSave
.PlayerReadInputKeyboardOnly:
        ld    a,d
.PlayerReadInputSave:
        ld    (PlayerInput),a
        ret

;-------------------------------------------------------------------------------
; Advance movement and animation by one 50 Hz game tick.
PlayerUpdate:
        call  PlayerReadInput

        ld    a,(PlayerInput)
        and   PLAYER_INPUT_JUMP
        jr    nz,.PlayerUpdateKeepLatch
        xor   a
        ld    (PlayerJumpLatch),a
.PlayerUpdateKeepLatch:

        ld    a,(PlayerState)
        cp    PLAYER_STATE_JUMP
        jp    z,PlayerUpdateJump

        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        call  PlayerFootingSolid
        jr    nz,.PlayerUpdateOnGround
        call  PlayerBeginFall
        ret

.PlayerUpdateOnGround:
        ld    a,(PlayerInput)
        and   PLAYER_INPUT_JUMP
        jr    z,.PlayerUpdateHorizontal
        ld    a,(PlayerJumpLatch)
        or    a
        jr    nz,.PlayerUpdateHorizontal
        ld    a,1
        ld    (PlayerJumpLatch),a
        call  PlayerStartJump
        ret

.PlayerUpdateHorizontal:
        ld    a,(PlayerInput)
        and   PLAYER_INPUT_LEFT
        jr    z,.PlayerUpdateRight
        xor   a
        ld    (PlayerDirection),a
        ld    a,PLAYER_STATE_WALK
        ld    (PlayerState),a
        xor   a
        ld    (PlayerIdleTick),a
        call  PlayerWalkLeft
        jr    z,.PlayerUpdateIdle
        jr    .PlayerUpdateWalkAnimation

.PlayerUpdateRight:
        ld    a,(PlayerInput)
        and   PLAYER_INPUT_RIGHT
        jr    z,.PlayerUpdateIdle
        ld    a,1
        ld    (PlayerDirection),a
        ld    a,PLAYER_STATE_WALK
        ld    (PlayerState),a
        xor   a
        ld    (PlayerIdleTick),a
        call  PlayerWalkRight
        jr    z,.PlayerUpdateIdle

.PlayerUpdateWalkAnimation:
        ; The walked step has already followed the ground up or down, or it has
        ; started the fall over an edge.
        ld    hl,PlayerAnimationTick
        inc   (hl)
        ret

.PlayerUpdateIdle:
        xor   a
        ld    (PlayerState),a
        ld    (PlayerAnimationTick),a
        ld    hl,PlayerIdleTick
        inc   (hl)
        ret

;-------------------------------------------------------------------------------
; Start a jump. The direction is fixed at take-off for a clean jump arc.
PlayerStartJump:
        ld    a,PLAYER_STATE_JUMP
        ld    (PlayerState),a
        xor   a
        ld    (PlayerJumpPhase),a
        ld    (PlayerIdleTick),a
        ld    (PlayerJumpDirection),a

        ld    a,(PlayerInput)
        and   PLAYER_INPUT_LEFT
        jr    z,.PlayerStartJumpRight
        ld    a,254 ; -2 pixels per tick
        ld    (PlayerJumpDirection),a
        xor   a
        ld    (PlayerDirection),a
        ret
.PlayerStartJumpRight:
        ld    a,(PlayerInput)
        and   PLAYER_INPUT_RIGHT
        ret   z
        ld    a,2
        ld    (PlayerJumpDirection),a
        ld    a,1
        ld    (PlayerDirection),a
        ret

;-------------------------------------------------------------------------------
; Falling uses the descending half of the jump curve.
PlayerBeginFall:
        ld    a,PLAYER_STATE_JUMP
        ld    (PlayerState),a
        ld    a,9
        ld    (PlayerJumpPhase),a
        xor   a
        ld    (PlayerJumpDirection),a
        ret

;-------------------------------------------------------------------------------
; Queue a jump-like knockback after the current collision probe has finished.
; A - horizontal direction: 254/-2 for left, 2 for right.
PlayerQueueKnockback:
        ld    (PlayerKnockbackDirection),a
        ld    a,1
        ld    (PlayerKnockbackPending),a
        ret

; Apply a queued knockback after PlayerUpdate, where walking or landing can no
; longer overwrite the new jump state.
PlayerApplyKnockback:
        ld    a,(PlayerKnockbackPending)
        or    a
        ret   z
        xor   a
        ld    (PlayerKnockbackPending),a
        ld    (PlayerJumpPhase),a
        ld    (PlayerIdleTick),a
        ld    (PlayerAnimationTick),a

        ld    a,PLAYER_STATE_JUMP
        ld    (PlayerState),a
        ld    a,1
        ld    (PlayerJumpLatch),a

        ld    a,(PlayerKnockbackDirection)
        ld    (PlayerJumpDirection),a
        cp    254
        ld    a,1
        jr    nz,.PlayerApplyKnockbackDirectionReady
        xor   a
.PlayerApplyKnockbackDirectionReady:
        ld    (PlayerDirection),a
        ret

;-------------------------------------------------------------------------------
; Apply the jump table and land on the first solid pixel crossed by the feet.
PlayerUpdateJump:
        ld    a,(PlayerJumpDirection)
        cp    254
        jr    nz,.PlayerUpdateJumpRight
        call  PlayerFlyLeft
        jr    .PlayerUpdateJumpVertical
.PlayerUpdateJumpRight:
        cp    2
        jr    nz,.PlayerUpdateJumpVertical
        call  PlayerFlyRight

.PlayerUpdateJumpVertical:
        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        ld    (PlayerLandingProbe),a

        ld    a,(PlayerJumpPhase)
        ld    e,a
        ld    d,0
        ld    hl,PlayerJumpDeltas
        add   hl,de
        ld    a,(hl)
        ld    (PlayerVerticalDelta),a

        ld    hl,PlayerY
        add   a,(hl)
        ld    (hl),a

        ld    a,(PlayerVerticalDelta)
        or    a
        jp    p,.PlayerUpdateJumpAdvancePhase
        ld    a,(PlayerY)
        cp    PLAYER_Y_MIN
        jr    nc,.PlayerUpdateJumpAdvancePhase
        ld    a,PLAYER_Y_MIN
        ld    (PlayerY),a
        ld    a,9 ; Start descending after touching the top of the field.
        ld    (PlayerJumpPhase),a

.PlayerUpdateJumpAdvancePhase:
        ld    a,(PlayerJumpPhase)
        cp    PLAYER_JUMP_PHASES-1
        jr    nc,.PlayerUpdateJumpCheckLanding
        inc   a
        ld    (PlayerJumpPhase),a

.PlayerUpdateJumpCheckLanding:
        ld    a,(PlayerVerticalDelta)
        or    a
        ret   z
        jp    m,.PlayerUpdateJumpNoLanding

        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        ld    (PlayerLandingEnd),a
.PlayerUpdateJumpLandingLoop:
        ld    a,(PlayerLandingProbe)
        call  PlayerLandingSolid
        jr    nz,.PlayerUpdateJumpLanded
        ld    a,(PlayerLandingProbe)
        ld    hl,PlayerLandingEnd
        cp    (hl)
        ret   z
        inc   a
        ld    (PlayerLandingProbe),a
        jr    .PlayerUpdateJumpLandingLoop

.PlayerUpdateJumpLanded:
        ld    a,(PlayerLandingProbe)
        and   %11111000 ; He lands on the top line of the attribute he hit, so he
                        ; stands exactly where a walked step would put him.
        sub   PLAYER_SPRITE_HEIGHT
        ld    (PlayerY),a
        xor   a
        ld    (PlayerState),a
        ld    (PlayerJumpPhase),a
        ld    (PlayerJumpDirection),a
        ret

.PlayerUpdateJumpNoLanding:
        ret

;===============================================================================
; The ground he walks on.
;
; A room is only a picture, there is no map beside it, so the surface is read
; back from the screen. Every sprite of a room stands on the attribute grid, so
; the surface is always the top line of an attribute cell and he always stands on
; such a line. That is why one attribute is the step he can walk up: the blocks
; in front of the old bridge are stacked exactly like that, one attribute apart,
; and they carry him from the stones up onto the deck. Anything taller is a wall
; and has to be jumped over.
;
; His own frame is still on the screen while he is updated, so the terrain is
; only ever read where he is not drawn: under his feet, or in the narrow strip
; his step uncovers in front of him.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Walk one step to the left, following the ground. At the side of the field he
; walks into the next room instead.
; return NZ - he walked, Z - something stopped him.
PlayerWalkLeft:
        ld    a,(PlayerX)
        cp    PLAYER_X_MIN+PLAYER_WALK_SPEED
        jr    c,.PlayerWalkLeftLeaves
        sub   PLAYER_WALK_SPEED
        ld    (PlayerStepX),a
        ld    (PlayerLeadX),a ; His left edge uncovers the strip in front of him.
        jp    PlayerWalkStep
.PlayerWalkLeftLeaves:
        ld    a,(ActualRoomInMap)
        dec   a ; The room on the left hand in the map.
        call  PlayerEnterRoom
        ret   z ; The map has no room there, the side of the field holds him.
        ld    a,PLAYER_X_MAX
        ld    (PlayerX),a ; He comes in at the other side.
        or    1
        ret

;-------------------------------------------------------------------------------
; Walk one step to the right, following the ground. At the side of the field he
; walks into the next room instead.
; return NZ - he walked, Z - something stopped him.
PlayerWalkRight:
        ld    a,(PlayerX)
        cp    PLAYER_X_MAX
        jr    nc,.PlayerWalkRightLeaves
        add   a,PLAYER_WALK_SPEED
        ld    (PlayerStepX),a
        add   a,PLAYER_FOOT_WIDTH-PLAYER_WALK_SPEED
        ld    (PlayerLeadX),a ; The strip is the front of his new footprint.
        jp    PlayerWalkStep
.PlayerWalkRightLeaves:
        ld    a,(ActualRoomInMap)
        inc   a ; The room on the right hand in the map.
        call  PlayerEnterRoom
        ret   z
        ld    a,PLAYER_X_MIN
        ld    (PlayerX),a
        or    1
        ret

;-------------------------------------------------------------------------------
; Walk into another room of the map. He keeps his height, so the ground of the
; new room catches him or he falls, exactly as inside one room.
; A - the map index he walks into.
; return NZ - the room was changed.
PlayerEnterRoom:
        ld    (PlayerNextRoom),a
        call  RoomSwitcherRoomsMap
        ret   z ; A wall of the map, or a room that is not drawn.
        ld    a,(PlayerNextRoom)
        ld    (ActualRoomInMap),a
        or    1
        ret

;-------------------------------------------------------------------------------
; How the ground answers one walked step.
; PlayerStepX - where he wants to stand, PlayerLeadX - the uncovered strip.
; return NZ - he walked, Z - the way is walled.
PlayerWalkStep:
        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        ld    (PlayerGroundY),a ; Top line of the attribute he is standing on.

        sub   PLAYER_CELL_HEIGHT*2
        call  PlayerLeadSolid
        jr    nz,.PlayerWalkStepWalled ; Higher than one attribute, he has to jump.

        ld    a,(PlayerGroundY)
        sub   PLAYER_CELL_HEIGHT
        call  PlayerLeadSolid
        jr    z,.PlayerWalkStepLevel

        ; The ground rises by one attribute and he walks up on it. The strip he
        ; steps on carries him, so his footing is not asked again - it would read
        ; his own frame at the height he just left.
        ld    a,(PlayerStepX)
        ld    (PlayerX),a
        ld    hl,PlayerY
        ld    a,(hl)
        sub   PLAYER_CELL_HEIGHT
        ld    (hl),a
        or    1
        ret

.PlayerWalkStepLevel:
        ld    a,(PlayerStepX)
        ld    (PlayerX),a
        call  PlayerFollowDown
        or    1
        ret

.PlayerWalkStepWalled:
        xor   a
        ret

;-------------------------------------------------------------------------------
; Follow the ground down after a step that kept its height. Only the lines under
; his feet are read, never the lines his own frame covers.
PlayerFollowDown:
        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        call  PlayerFootingSolid
        ret   nz ; The attribute under his feet still carries him.

        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT+PLAYER_CELL_HEIGHT
        call  PlayerFootingSolid
        jp    z,PlayerBeginFall ; Deeper than one attribute, he falls.

        ld    hl,PlayerY
        ld    a,(hl)
        add   a,PLAYER_CELL_HEIGHT
        ld    (hl),a ; The ground drops by one attribute and he walks down on it.
        ret

;-------------------------------------------------------------------------------
; Move one step in the air. Nothing is followed there, but a wall still stops him.
PlayerFlyLeft:
        ld    a,(PlayerX)
        cp    PLAYER_X_MIN+PLAYER_WALK_SPEED
        ret   c
        sub   PLAYER_WALK_SPEED
        ld    (PlayerStepX),a
        ld    (PlayerLeadX),a
        jp    PlayerFlyStep

PlayerFlyRight:
        ld    a,(PlayerX)
        cp    PLAYER_X_MAX
        ret   nc
        add   a,PLAYER_WALK_SPEED
        ld    (PlayerStepX),a
        add   a,PLAYER_FOOT_WIDTH-PLAYER_WALK_SPEED
        ld    (PlayerLeadX),a
        jp    PlayerFlyStep

; The whole height of the frame has to fit into the uncovered strip.
PlayerFlyStep:
        ld    a,(PlayerY)
        ld    (PlayerProbeY),a
        ld    a,PLAYER_SPRITE_HEIGHT
        ld    (PlayerProbeRows),a
        ld    a,(PlayerLeadX)
        ld    (PlayerProbeX),a
        ld    a,PLAYER_WALK_SPEED
        ld    (PlayerProbeCount),a
        call  PlayerTerrainSolid
        ret   nz
        ld    a,(PlayerStepX)
        ld    (PlayerX),a
        ret

;-------------------------------------------------------------------------------
; Is the attribute of the strip in front of him filled with terrain?
; A - top line of the attribute.
; return NZ - the strip carries terrain.
PlayerLeadSolid:
        ld    (PlayerProbeY),a
        ld    a,PLAYER_CELL_HEIGHT
        ld    (PlayerProbeRows),a
        ld    a,(PlayerLeadX)
        ld    (PlayerProbeX),a
        ld    a,PLAYER_WALK_SPEED
        ld    (PlayerProbeCount),a
        jp    PlayerTerrainSolid

;-------------------------------------------------------------------------------
; Is the attribute under his whole footprint filled with terrain? One pixel of it
; is enough, which is what keeps the sparse artwork of the bridge walkable.
; A - top line of the attribute under his feet.
; return NZ - he is carried.
PlayerFootingSolid:
        ld    (PlayerProbeY),a
        ld    a,PLAYER_CELL_HEIGHT
        ld    (PlayerProbeRows),a
        ld    a,(PlayerX)
        ld    (PlayerProbeX),a
        ld    a,PLAYER_FOOT_WIDTH
        ld    (PlayerProbeCount),a
        jp    PlayerTerrainSolid

;-------------------------------------------------------------------------------
; Does one pixel line carry his footprint? The fall ends on a line, not on an
; attribute, so that the jump curve is not cut short.
; A - the pixel line under his feet.
; return NZ - the line carries him.
PlayerLandingSolid:
        ld    (PlayerProbeY),a
        ld    a,1
        ld    (PlayerProbeRows),a
        ld    a,(PlayerX)
        ld    (PlayerProbeX),a
        ld    a,PLAYER_FOOT_WIDTH
        ld    (PlayerProbeCount),a
        jp    PlayerTerrainSolid

;-------------------------------------------------------------------------------
; Is there terrain inside one rectangle of the game field?
; PlayerProbeX / PlayerProbeCount - the pixel columns.
; PlayerProbeY / PlayerProbeRows  - the pixel lines.
; return NZ - the rectangle carries terrain he cannot enter.
PlayerTerrainSolid:
        ld    a,(PlayerProbeY)
        ld    (PlayerProbeLine),a
        ld    a,(PlayerProbeRows)
        ld    b,a
.PlayerTerrainLine:
        push  bc
        call  PlayerLineSolid
        pop   bc
        ret   nz
        ld    hl,PlayerProbeLine
        inc   (hl)
        djnz  .PlayerTerrainLine
        xor   a
        ret

; One pixel line of the rectangle.
PlayerLineSolid:
        ld    a,(PlayerProbeX)
        ld    (PlayerProbeColumn),a
        ld    a,(PlayerProbeCount)
        ld    b,a
.PlayerLineColumn:
        push  bc
        ld    a,(PlayerProbeLine)
        ld    b,a
        ld    a,(PlayerProbeColumn)
        ld    c,a
        call  PlayerPixelSolid
        pop   bc
        ret   nz
        ld    hl,PlayerProbeColumn
        inc   (hl)
        djnz  .PlayerLineColumn
        xor   a
        ret

;-------------------------------------------------------------------------------
; Is one pixel of the game field terrain that carries him?
; B - Yos, C - Xos, both in pixels.
; return NZ - the pixel is solid.
PlayerPixelSolid:
        ; The Death is a dynamic room sprite, but unlike the other animations
        ; she is a solid obstacle which hurts the player on first contact.
        call  IsDeathPixelSolid
        ret   nz

        ld    a,b
        cp    PLAYER_FLOOR_Y
        jr    c,.PlayerPixelInk
        or    1 ; The bottom floor is solid even where its artwork has holes.
        ret
.PlayerPixelInk:
        push  bc
        call  PlayerInkAt
        pop   bc
        cp    PLAYER_INK_GRASS
        jr    z,.PlayerPixelScenery
        cp    PLAYER_INK_SCENERY
        jr    z,.PlayerPixelScenery

        push  bc
        call  ScreenAddr ; HL - the byte holding the pixel. A stays untouched.
        ld    d,(hl)
        pop   bc
        ld    a,c
        and   7
        ld    c,a
        ld    b,0
        ld    hl,PlayerPixelMasks
        add   hl,bc
        ld    a,(hl)
        and   d
        ret
.PlayerPixelScenery:
        xor   a
        ret

;-------------------------------------------------------------------------------
; Ink of the attribute cell holding one pixel, asked of the room and not of the
; screen. ShowRoom paints the room into RoomsAttrCache, while the torches, the
; fire, the items, the stars and the animations of a room are drawn straight to
; the screen. The cache is therefore the room alone, which is exactly the ground,
; and everything the other units paint over it stays background he walks through.
; B - Yos, C - Xos, both in pixels.
; return A - the ink, the material of the cell.
PlayerInkAt:
        call  AttrAddrViaPixelPos ; HL - offset of the cell, BC is kept.
        ld    de,RoomsAttrCache
        add   hl,de
        ld    a,(hl)
        and   7
        ret

;-------------------------------------------------------------------------------
; Select the current bitmap in HL and its matching mask in DE.
PlayerSelectFrame:
        ld    a,(PlayerState)
        cp    PLAYER_STATE_JUMP
        jp    z,.PlayerSelectJump
        cp    PLAYER_STATE_WALK
        jr    z,.PlayerSelectWalk

        xor   a
        ld    (PlayerFrameIndex),a
        ld    a,(PlayerIdleTick)
        cp    PLAYER_IDLE_BLINK_START
        jr    c,.PlayerSelectIdleNormal
        cp    PLAYER_IDLE_BLINK_END
        jr    c,.PlayerSelectIdleBlink
        cp    PLAYER_IDLE_HOP_SQUASH_START
        jr    c,.PlayerSelectIdleNormal
        cp    PLAYER_IDLE_HOP_AIR_START
        jr    c,.PlayerSelectIdleSquash
        cp    PLAYER_IDLE_HOP_LAND_START
        jr    c,.PlayerSelectIdleHop
        cp    PLAYER_IDLE_HOP_END
        jr    nc,.PlayerSelectIdleNormal
        ld    a,2
        jr    .PlayerSelectIdleReady
.PlayerSelectIdleBlink:
        ld    a,1
        jr    .PlayerSelectIdleReady
.PlayerSelectIdleSquash:
        ld    a,2
        jr    .PlayerSelectIdleReady
.PlayerSelectIdleHop:
        ld    a,3
        jr    .PlayerSelectIdleReady
.PlayerSelectIdleNormal:
        xor   a
.PlayerSelectIdleReady:
        ld    (PlayerFrameIndex),a
        ld    hl,PlayerIdleSpriteFrames
        call  PlayerPointerFromTable
        ld    (PlayerCurrentSprite),hl
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerIdleMaskFrames
        call  PlayerPointerFromTable
        ex    de,hl
        ld    hl,(PlayerCurrentSprite)
        ret

.PlayerSelectWalk:
        ld    a,(PlayerAnimationTick)
        rrca
        rrca
        and   3
        ld    (PlayerFrameIndex),a
        ld    a,(PlayerDirection)
        or    a
        jr    z,.PlayerSelectWalkLeft
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerWalkRightSpriteFrames
        call  PlayerPointerFromTable
        ld    (PlayerCurrentSprite),hl
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerWalkRightMaskFrames
        jr    .PlayerSelectWalkMask
.PlayerSelectWalkLeft:
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerWalkLeftSpriteFrames
        call  PlayerPointerFromTable
        ld    (PlayerCurrentSprite),hl
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerWalkLeftMaskFrames
.PlayerSelectWalkMask:
        call  PlayerPointerFromTable
        ex    de,hl
        ld    hl,(PlayerCurrentSprite)
        ret

.PlayerSelectJump:
        ld    a,(PlayerJumpPhase)
        cp    PLAYER_JUMP_CURL_PHASE
        jr    c,.PlayerSelectJumpRise
        cp    PLAYER_JUMP_FALL_PHASE
        jr    c,.PlayerSelectJumpCurl
        ld    a,2
        jr    .PlayerSelectJumpFrameReady
.PlayerSelectJumpCurl:
        ld    a,1
        jr    .PlayerSelectJumpFrameReady
.PlayerSelectJumpRise:
        xor   a
.PlayerSelectJumpFrameReady:
        ld    (PlayerFrameIndex),a

        ld    a,(PlayerJumpDirection)
        cp    254
        jr    z,.PlayerSelectJumpLeft
        cp    2
        jr    z,.PlayerSelectJumpRight
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerJumpUpSpriteFrames
        call  PlayerPointerFromTable
        ld    (PlayerCurrentSprite),hl
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerJumpUpMaskFrames
        jr    .PlayerSelectJumpMask
.PlayerSelectJumpLeft:
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerJumpLeftSpriteFrames
        call  PlayerPointerFromTable
        ld    (PlayerCurrentSprite),hl
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerJumpLeftMaskFrames
        jr    .PlayerSelectJumpMask
.PlayerSelectJumpRight:
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerJumpRightSpriteFrames
        call  PlayerPointerFromTable
        ld    (PlayerCurrentSprite),hl
        ld    a,(PlayerFrameIndex)
        ld    hl,PlayerJumpRightMaskFrames
.PlayerSelectJumpMask:
        call  PlayerPointerFromTable
        ex    de,hl
        ld    hl,(PlayerCurrentSprite)
        ret

; A is a word index, HL is the table. Return the selected pointer in HL.
PlayerPointerFromTable:
        add   a,a
        ld    e,a
        ld    d,0
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        ex    de,hl
        ret

;-------------------------------------------------------------------------------
; Shift a 16-pixel frame into three bytes for arbitrary pixel X positions.
; HL is bitmap, DE is mask, A is shift (0-7).
PlayerPrepareShiftedFrame:
        ld    (PlayerPixelShift),a
        ld    ix,PlayerShiftedBitmap
        ld    iy,PlayerShiftedMask
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerPrepareRow:
        push  bc
        push  de
        ld    d,(hl)
        inc   hl
        ld    e,(hl)
        inc   hl
        ld    c,0
        ld    a,(PlayerPixelShift)
        or    a
        jr    z,.PlayerPrepareBitmapReady
        ld    b,a
.PlayerPrepareBitmapShift:
        srl   d
        rr    e
        rr    c
        djnz  .PlayerPrepareBitmapShift
.PlayerPrepareBitmapReady:
        ld    (ix+0),d
        ld    (ix+1),e
        ld    (ix+2),c

        pop   de
        push  hl
        ld    a,(de)
        ld    h,a
        inc   de
        ld    a,(de)
        ld    l,a
        inc   de
        ld    c,255
        ld    a,(PlayerPixelShift)
        or    a
        jr    z,.PlayerPrepareMaskReady
        ld    b,a
.PlayerPrepareMaskShift:
        scf
        rr    h
        rr    l
        rr    c
        djnz  .PlayerPrepareMaskShift
.PlayerPrepareMaskReady:
        ld    (iy+0),h
        ld    (iy+1),l
        ld    (iy+2),c
        pop   hl

        inc   ix
        inc   ix
        inc   ix
        inc   iy
        inc   iy
        inc   iy
        pop   bc
        djnz  .PlayerPrepareRow
        ret

; Copy one cached walking frame into the regular drawing buffers. The cache is
; ordered by direction, animation frame and the shifts 0, 2, 4 and 6.
PlayerPrepareWalkFrame:
        ld    a,(PlayerDirection)
        rlca
        rlca
        rlca
        rlca
        ld    b,a
        ld    a,(PlayerFrameIndex)
        add   a,a
        add   a,a
        add   a,b
        ld    b,a
        ld    a,(PlayerX)
        and   7
        rrca
        add   a,b

        ld    l,a
        ld    h,0
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,hl
        ld    d,h
        ld    e,l
        add   hl,hl
        add   hl,hl
        add   hl,hl
        add   hl,de
        ld    de,PlayerPreparedWalkFrames
        add   hl,de

        ld    de,PlayerShiftedBitmap
        ld    bc,PLAYER_SPRITE_HEIGHT*3
        ldir
        ld    de,PlayerShiftedMask
        ld    bc,PLAYER_SPRITE_HEIGHT*3
        ldir
        ret

;-------------------------------------------------------------------------------
; Build the new background and final masked image before the old player is
; erased. Bytes covered by the old frame are recovered from PlayerBackground,
; because reading them directly from the screen would capture the player.
PlayerComposePrepared:
        ld    a,(PlayerY)
        ld    b,a
        ld    a,(PlayerX)
        ld    c,a
        call  ScreenAddr
        ld    (PlayerNextScreenAddress),hl
        call  PlayerFindBackgroundOverlap

        ld    hl,(PlayerNextScreenAddress)
        ld    de,PlayerNextBackground
        ld    a,(PlayerY)
        ld    (PlayerComposeY),a
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerComposeCaptureRow:
        push  bc
        push  hl

        ; Start with the bytes currently visible at the new position.
        push  de
        ld    a,(hl)
        ld    (de),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
        pop   de
        pop   hl

        ld    a,(PlayerOverlapMode)
        or    a
        jr    z,.PlayerComposeCaptureNext

        ; Does this new scanline cross the old 24-line frame?
        ld    a,(PlayerRenderedY)
        ld    c,a
        ld    a,(PlayerComposeY)
        sub   c
        jr    c,.PlayerComposeCaptureNext
        cp    PLAYER_SPRITE_HEIGHT
        jr    nc,.PlayerComposeCaptureNext

        ; HL = matching scanline in the saved old background.
        push  hl
        push  de
        ld    c,a
        ld    b,0
        ld    h,b
        ld    l,c
        add   hl,hl
        add   hl,bc
        ld    bc,PlayerBackground
        add   hl,bc

        ld    a,(PlayerOverlapMode)
        cp    PLAYER_OVERLAP_SAME_COLUMN
        jr    z,.PlayerComposeCopyThree
        cp    PLAYER_OVERLAP_NEW_RIGHT
        jr    z,.PlayerComposeCopyRight

        ; The new byte strip starts one byte left of the old strip.
        inc   de
        jr    .PlayerComposeCopyTwo
.PlayerComposeCopyRight:
        ; The new strip starts one byte right, so old byte zero is outside it.
        inc   hl
.PlayerComposeCopyTwo:
        ld    a,(hl)
        ld    (de),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
        jr    .PlayerComposeOldRowReady
.PlayerComposeCopyThree:
        ld    a,(hl)
        ld    (de),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
.PlayerComposeOldRowReady:
        pop   de
        pop   hl

.PlayerComposeCaptureNext:
        ld    a,(PlayerComposeY)
        inc   a
        ld    (PlayerComposeY),a
        inc   de
        inc   de
        inc   de
        call  DownHL
        pop   bc
        djnz  .PlayerComposeCaptureRow

        ; Compose all layers in RAM while the old frame is still on screen.
        ld    ix,PlayerNextBackground
        ld    iy,PlayerShiftedMask
        ld    hl,PlayerShiftedBitmap
        ld    de,PlayerComposedFrame
        ld    b,PLAYER_SPRITE_HEIGHT*3
.PlayerComposeByte:
        ld    a,(ix+0)
        and   (iy+0)
        or    (hl)
        ld    (de),a
        inc   ix
        inc   iy
        inc   hl
        inc   de
        djnz  .PlayerComposeByte
        ret

; Determine how the three byte columns at the new position overlap the old
; frame. A room redraw invalidates the old screen image, so it never overlaps.
PlayerFindBackgroundOverlap:
        xor   a
        ld    (PlayerOverlapMode),a
        ld    a,(PlayerBackgroundValid)
        or    a
        ret   z
        ld    a,(LastShowedRoomInMap)
        ld    hl,PlayerDrawnRoom
        cp    (hl)
        ret   nz

        ld    a,(PlayerX)
        rrca
        rrca
        rrca
        and   31
        ld    c,a
        ld    a,(PlayerRenderedX)
        rrca
        rrca
        rrca
        and   31
        ld    b,a
        cp    c
        jr    z,.PlayerOverlapSame
        inc   a
        cp    c
        jr    z,.PlayerOverlapRight
        ld    a,c
        inc   a
        cp    b
        ret   nz
        ld    a,PLAYER_OVERLAP_NEW_LEFT
        ld    (PlayerOverlapMode),a
        ret
.PlayerOverlapSame:
        ld    a,PLAYER_OVERLAP_SAME_COLUMN
        ld    (PlayerOverlapMode),a
        ret
.PlayerOverlapRight:
        ld    a,PLAYER_OVERLAP_NEW_RIGHT
        ld    (PlayerOverlapMode),a
        ret

; Prepare the position used by the byte-level dynamic animation helpers.
; B/C - pixel Y/X. All other registers except A are preserved.
PlayerBeginDynamicArea:
        push  bc
        push  hl
        ld    a,b
        ld    (PlayerDynamicY),a
        ld    a,c
        rrca
        rrca
        rrca
        and   31
        ld    (PlayerDynamicStartColumn),a
        ld    (PlayerDynamicColumn),a
        ld    a,(PlayerRenderedX)
        rrca
        rrca
        rrca
        and   31
        ld    (PlayerDynamicPlayerColumn),a

        xor   a
        ld    (PlayerDynamicActive),a
        ld    a,(PlayerBackgroundValid)
        or    a
        jr    z,.PlayerBeginDynamicDone
        ld    a,(LastShowedRoomInMap)
        ld    hl,PlayerDrawnRoom
        cp    (hl)
        jr    nz,.PlayerBeginDynamicDone
        ld    a,1
        ld    (PlayerDynamicActive),a
.PlayerBeginDynamicDone:
        pop   hl
        pop   bc
        ret

; Move the dynamic animation cursor to the start of the next pixel line.
PlayerAdvanceDynamicRow:
        ld    a,(PlayerDynamicY)
        inc   a
        ld    (PlayerDynamicY),a
        ld    a,(PlayerDynamicStartColumn)
        ld    (PlayerDynamicColumn),a
        ret

; Draw an OR-composited sprite behind the already rendered player.
; IX - sprite address, B/C - pixel Y/X.
PlayerDrawDynamicSpriteWithoutAttrs:
        call  PlayerBeginDynamicArea
        call  ScreenAddr
        ld    c,(ix+1)
        ld    b,(ix+0)
.PlayerDrawDynamicWARow:
        push  bc
        push  hl
.PlayerDrawDynamicWAByte:
        ld    a,(ix+2)
        call  PlayerOverlayDynamicByte
        ld    (hl),a
        inc   hl
        inc   ix
        ld    a,(PlayerDynamicColumn)
        inc   a
        ld    (PlayerDynamicColumn),a
        djnz  .PlayerDrawDynamicWAByte
        pop   hl
        call  DownHL
        call  PlayerAdvanceDynamicRow
        pop   bc
        dec   c
        jr    nz,.PlayerDrawDynamicWARow
        ret

; Draw a byte-aligned dynamic sprite behind the already rendered player.
; The animation byte becomes the new saved player background, while the screen
; receives the animation and player composited together in one write.
; IX - sprite address, B/C - pixel Y/X, DE - attribute destination.
PlayerDrawDynamicSprite:
        ld    a,(PlayerBackgroundValid)
        or    a
        jp    z,DrawSprite
        ld    a,(LastShowedRoomInMap)
        ld    hl,PlayerDrawnRoom
        cp    (hl)
        jp    nz,DrawSprite

        push  bc
        ld    a,b
        ld    (PlayerDynamicY),a
        ld    a,(ix+1)
        add   a,b
        ld    hl,PlayerRenderedY
        cp    (hl)
        jp    c,.PlayerDrawDynamicFallback
        jp    z,.PlayerDrawDynamicFallback
        ld    a,(PlayerRenderedY)
        add   a,PLAYER_SPRITE_HEIGHT
        cp    b
        jp    c,.PlayerDrawDynamicFallback
        jp    z,.PlayerDrawDynamicFallback

        ld    a,c
        rrca
        rrca
        rrca
        and   31
        ld    (PlayerDynamicStartColumn),a
        ld    c,a
        ld    a,(PlayerRenderedX)
        rrca
        rrca
        rrca
        and   31
        ld    (PlayerDynamicPlayerColumn),a
        ld    b,a
        ld    a,(ix+0)
        add   a,c
        cp    b
        jp    c,.PlayerDrawDynamicFallback
        jp    z,.PlayerDrawDynamicFallback
        ld    a,b
        add   a,3
        cp    c
        jp    c,.PlayerDrawDynamicFallback
        jp    z,.PlayerDrawDynamicFallback
        pop   bc
        call  PlayerBeginDynamicArea

        ; Pixel data. This follows DrawSprite's IX convention, so after the last
        ; byte IX points two bytes before the attribute data.
        push  de
        ld    a,(PlayerDynamicY)
        ld    b,a
        ld    a,(PlayerDynamicStartColumn)
        rlca
        rlca
        rlca
        ld    c,a
        push  bc
        call  ScreenAddr
        pop   bc
        push  bc
        ld    c,(ix+1)
        ld    b,(ix+0)
        push  bc
.PlayerDrawDynamicRow:
        push  bc
        push  hl
        ld    a,(PlayerDynamicStartColumn)
        ld    (PlayerDynamicColumn),a
.PlayerDrawDynamicByte:
        ld    a,(ix+2)
        call  PlayerCompositeDynamicByte
        ld    (hl),a
        inc   hl
        inc   ix
        ld    a,(PlayerDynamicColumn)
        inc   a
        ld    (PlayerDynamicColumn),a
        djnz  .PlayerDrawDynamicByte
        pop   hl
        call  DownHL
        ld    a,(PlayerDynamicY)
        inc   a
        ld    (PlayerDynamicY),a
        pop   bc
        dec   c
        jr    nz,.PlayerDrawDynamicRow

        ; Attribute data, identical to DrawSprite.
        pop   de
        pop   bc
        call  AttrAddrViaPixelPos
        ld    bc,de
        ld    a,c
        rrca
        rrca
        rrca
        ld    c,a
        pop   de
        add   hl,de
        ld    de,32
.PlayerDrawDynamicAttrRow:
        push  bc
        push  hl
.PlayerDrawDynamicAttrByte:
        ld    a,(ix+2)
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .PlayerDrawDynamicAttrByte
        pop   hl
        add   hl,de
        pop   bc
        dec   c
        jr    nz,.PlayerDrawDynamicAttrRow
        ret

.PlayerDrawDynamicFallback:
        pop   bc
        jp    DrawSprite

; A - byte currently visible on screen. Return the clean animation/background
; byte saved underneath the player when this position overlaps him.
PlayerReadDynamicBackgroundByte:
        ld    (PlayerDynamicSource),a
        push  bc
        push  de
        push  hl
        call  PlayerDynamicBufferOffset
        jr    nc,.PlayerReadDynamicRaw
        ld    hl,PlayerBackground
        add   hl,bc
        ld    a,(hl)
        jr    .PlayerReadDynamicReady
.PlayerReadDynamicRaw:
        ld    a,(PlayerDynamicSource)
.PlayerReadDynamicReady:
        ld    (PlayerDynamicComposed),a
        pop   hl
        pop   de
        pop   bc
        ld    a,(PlayerDynamicComposed)
        ret

; A - sprite byte. OR it into the clean background and return a screen byte
; which keeps the player in front. HL points to the current screen byte.
PlayerOverlayDynamicByte:
        ld    (PlayerDynamicOverlay),a
        push  bc
        ld    a,(hl)
        call  PlayerReadDynamicBackgroundByte
        ld    c,a
        ld    a,(PlayerDynamicOverlay)
        or    c
        pop   bc
        jp    PlayerCompositeDynamicByte

; A - byte of the dynamic animation. Return the byte with the player over it.
PlayerCompositeDynamicByte:
        ld    (PlayerDynamicSource),a
        push  bc
        push  de
        push  hl
        call  PlayerDynamicBufferOffset
        jr    nc,.PlayerCompositeDynamicRaw

        ld    hl,PlayerBackground
        add   hl,bc
        ld    a,(PlayerDynamicSource)
        ld    (hl),a

        ld    hl,PlayerShiftedMask
        add   hl,bc
        ld    a,(PlayerDynamicSource)
        and   (hl)
        ld    (PlayerDynamicComposed),a
        ld    hl,PlayerShiftedBitmap
        add   hl,bc
        ld    a,(PlayerDynamicComposed)
        or    (hl)
        jr    .PlayerCompositeDynamicReady

.PlayerCompositeDynamicRaw:
        ld    a,(PlayerDynamicSource)
.PlayerCompositeDynamicReady:
        pop   hl
        pop   de
        pop   bc
        ret

; Return CF=1 and BC = byte offset in the player's three-byte scanline buffer
; when the current dynamic animation byte overlaps the rendered player.
PlayerDynamicBufferOffset:
        ld    a,(PlayerDynamicActive)
        or    a
        jr    z,.PlayerDynamicBufferOutside

        ld    a,(PlayerRenderedY)
        ld    c,a
        ld    a,(PlayerDynamicY)
        sub   c
        jr    c,.PlayerDynamicBufferOutside
        cp    PLAYER_SPRITE_HEIGHT
        jr    nc,.PlayerDynamicBufferOutside
        ld    e,a

        ld    a,(PlayerDynamicPlayerColumn)
        ld    c,a
        ld    a,(PlayerDynamicColumn)
        sub   c
        jr    c,.PlayerDynamicBufferOutside
        cp    3
        jr    nc,.PlayerDynamicBufferOutside
        ld    d,a

        ld    a,e
        add   a,a
        add   a,e
        add   a,d
        ld    c,a
        ld    b,0
        scf
        ret
.PlayerDynamicBufferOutside:
        or    a
        ret

; Restore the one old byte column which is outside a horizontally adjacent new
; frame. The two overlapping columns are replaced by PlayerDrawComposed.
PlayerEraseOutgoingColumn:
        ld    hl,(PlayerOldScreenAddress)
        ld    de,PlayerBackground
        ld    a,(PlayerOverlapMode)
        cp    PLAYER_OVERLAP_NEW_RIGHT
        jr    z,.PlayerEraseOutgoingReady
        cp    PLAYER_OVERLAP_NEW_LEFT
        ret   nz
        inc   hl
        inc   hl
        inc   de
        inc   de
.PlayerEraseOutgoingReady:
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerEraseOutgoingRow:
        push  bc
        push  hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        inc   de
        inc   de
        pop   hl
        call  DownHL
        pop   bc
        djnz  .PlayerEraseOutgoingRow
        ret

; Copy the already composed frame to the screen. Only writes remain between
; PlayerErase and this routine, which keeps the blank interval short.
PlayerDrawComposed:
        ld    hl,(PlayerNextScreenAddress)
        ld    (PlayerOldScreenAddress),hl
        ld    de,PlayerComposedFrame
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerDrawComposedRow:
        push  bc
        push  hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(de)
        ld    (hl),a
        inc   de
        pop   hl
        call  DownHL
        pop   bc
        djnz  .PlayerDrawComposedRow

        ; Keep the uncomposited bytes for erasing this frame next time.
        ld    hl,PlayerNextBackground
        ld    de,PlayerBackground
        ld    bc,PLAYER_SPRITE_HEIGHT*3
        ldir

        ld    a,1
        ld    (PlayerBackgroundValid),a
        ld    a,(LastShowedRoomInMap) ; The picture the saved bytes come from.
        ld    (PlayerDrawnRoom),a
        ld    a,(PlayerX)
        ld    (PlayerRenderedX),a
        ld    a,(PlayerY)
        ld    (PlayerRenderedY),a
        ret

; Reapply the already shifted frame without erasing it or replacing its saved
; background. This is idempotent and prevents visible idle flicker.
PlayerOverlayPrepared:
        ld    hl,(PlayerOldScreenAddress)
        ld    ix,PlayerShiftedBitmap
        ld    iy,PlayerShiftedMask
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerOverlayPreparedRow:
        push  bc
        push  hl
        ld    a,(hl)
        and   (iy+0)
        or    (ix+0)
        ld    (hl),a
        inc   hl
        ld    a,(hl)
        and   (iy+1)
        or    (ix+1)
        ld    (hl),a
        inc   hl
        ld    a,(hl)
        and   (iy+2)
        or    (ix+2)
        ld    (hl),a
        inc   ix
        inc   ix
        inc   ix
        inc   iy
        inc   iy
        inc   iy
        pop   hl
        call  DownHL
        pop   bc
        djnz  .PlayerOverlayPreparedRow
        ret

; Replace an animation frame at the same position by compositing it directly
; over the saved background. The old frame is never exposed on screen as blank.
PlayerRedrawSamePosition:
        ld    hl,(PlayerSelectedSprite)
        ld    de,(PlayerSelectedMask)
        ld    a,(PlayerX)
        and   7
        call  PlayerPrepareShiftedFrame

        ld    hl,(PlayerOldScreenAddress)
        ld    ix,PlayerShiftedBitmap
        ld    iy,PlayerShiftedMask
        ld    de,PlayerBackground
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerRedrawSamePositionRow:
        push  bc
        push  hl
        ld    a,(de)
        and   (iy+0)
        or    (ix+0)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(de)
        and   (iy+1)
        or    (ix+1)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(de)
        and   (iy+2)
        or    (ix+2)
        ld    (hl),a
        inc   de
        inc   ix
        inc   ix
        inc   ix
        inc   iy
        inc   iy
        inc   iy
        pop   hl
        call  DownHL
        pop   bc
        djnz  .PlayerRedrawSamePositionRow

        ld    hl,(PlayerSelectedSprite)
        ld    (PlayerRenderedSprite),hl
        ret

;-------------------------------------------------------------------------------
; Player state and drawing buffers.
PlayerX:                       defb 112
PlayerY:                       defb 112
PlayerDirection:               defb 1
PlayerState:                   defb PLAYER_STATE_IDLE
PlayerInput:                   defb 0
PlayerAnimationTick:           defb 0
PlayerIdleTick:                defb 0
PlayerFrameIndex:              defb 0
PlayerJumpPhase:               defb 0
PlayerJumpDirection:           defb 0
PlayerJumpLatch:               defb 0
PlayerKnockbackPending:        defb 0
PlayerKnockbackDirection:      defb 0
PlayerVerticalDelta:           defb 0
PlayerLandingProbe:            defb 0
PlayerLandingEnd:              defb 0
PlayerStepX:                   defb 0
PlayerLeadX:                   defb 0
PlayerGroundY:                 defb 0
PlayerNextRoom:                defb 0
PlayerProbeX:                  defb 0
PlayerProbeCount:              defb 0
PlayerProbeY:                  defb 0
PlayerProbeRows:               defb 0
PlayerProbeColumn:             defb 0
PlayerProbeLine:               defb 0
PlayerPixelShift:              defb 0
PlayerBackgroundValid:         defb 0
PlayerDrawnRoom:               defb 255
PlayerOldScreenAddress:        defw 0
PlayerNextScreenAddress:       defw 0
PlayerCurrentSprite:           defw 0
PlayerSelectedSprite:          defw 0
PlayerSelectedMask:            defw 0
PlayerRenderedSprite:          defw 0
PlayerRenderedX:               defb 0
PlayerRenderedY:               defb 0
PlayerWalkCacheWriteAddress:   defw 0
PlayerWalkCacheDirection:      defb 0
PlayerWalkCacheFrame:          defb 0
PlayerWalkCacheShift:          defb 0
PlayerOverlapMode:             defb PLAYER_OVERLAP_NONE
PlayerComposeY:                defb 0
PlayerDynamicY:                defb 0
PlayerDynamicStartColumn:      defb 0
PlayerDynamicPlayerColumn:     defb 0
PlayerDynamicColumn:           defb 0
PlayerDynamicActive:           defb 0
PlayerDynamicSource:           defb 0
PlayerDynamicComposed:         defb 0
PlayerDynamicOverlay:          defb 0

PlayerJumpDeltas:
        defb  -4, -4, -3, -3, -2, -2, -1, -1, 0, 1, 1, 2, 2, 3, 3, 4, 4
PlayerPixelMasks:
        defb  128, 64, 32, 16, 8, 4, 2, 1

PlayerBackground:              block PLAYER_SPRITE_HEIGHT*3,0
PlayerNextBackground:          block PLAYER_SPRITE_HEIGHT*3,0
PlayerComposedFrame:           block PLAYER_SPRITE_HEIGHT*3,0
PlayerShiftedBitmap:           block PLAYER_SPRITE_HEIGHT*3,0
PlayerShiftedMask:             block PLAYER_SPRITE_HEIGHT*3,255
PlayerPreparedWalkFrames:      block 2*4*4*PLAYER_SPRITE_HEIGHT*3*2,0

        include "player_sprites.asm"
;===============================================================================
