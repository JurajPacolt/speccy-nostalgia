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
PLAYER_WALK_SPEED              equ 2  ; Pixels per tick, and so the width of the
                                      ; strip every step uncovers in front of him.
PLAYER_FOOT_WIDTH              equ 16 ; The frame is 24 lines high and 16 wide.
PLAYER_CELL_HEIGHT             equ 8  ; One attribute, the step he still walks up.

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
; Called immediately before drawing a changed position or animation frame.
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
        ; Prepare the new frame while the old one is still visible. Keeping the
        ; expensive pixel shift before PlayerErase shortens the blank interval to
        ; just the restore-and-draw pair.
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
        call  PlayerErase
        jp    PlayerDrawPrepared

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
        cp    96
        jr    c,.PlayerSelectIdleBreathe
        cp    100
        jr    nc,.PlayerSelectIdleYawn
        ld    a,2
        jr    .PlayerSelectIdleReady
.PlayerSelectIdleYawn:
        cp    224
        jr    c,.PlayerSelectIdleBreathe
        cp    236
        jr    nc,.PlayerSelectIdleBreathe
        ld    a,3
        jr    .PlayerSelectIdleReady
.PlayerSelectIdleBreathe:
        and   31
        cp    28
        jr    c,.PlayerSelectIdleNormal
        ld    a,1
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
        ld    a,(PlayerJumpDirection)
        cp    254
        jr    z,.PlayerSelectJumpLeft
        cp    2
        jr    z,.PlayerSelectJumpRight
        ld    hl,PlayerSpriteJumpUp
        ld    de,PlayerMaskJumpUp
        ret
.PlayerSelectJumpLeft:
        ld    hl,PlayerSpriteJumpLeft
        ld    de,PlayerMaskJumpLeft
        ret
.PlayerSelectJumpRight:
        ld    hl,PlayerSpriteJumpRight
        ld    de,PlayerMaskJumpRight
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
; Draw the prepared player and save the three covered bytes per scanline.
PlayerDrawPrepared:
        ld    a,(PlayerY)
        ld    b,a
        ld    a,(PlayerX)
        ld    c,a
        call  ScreenAddr
        ld    (PlayerOldScreenAddress),hl

        ld    ix,PlayerShiftedBitmap
        ld    iy,PlayerShiftedMask
        ld    de,PlayerBackground
        ld    b,PLAYER_SPRITE_HEIGHT
.PlayerDrawRow:
        push  bc
        push  hl
        ld    a,(hl)
        ld    (de),a
        and   (iy+0)
        or    (ix+0)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
        and   (iy+1)
        or    (ix+1)
        ld    (hl),a
        inc   de
        inc   hl
        ld    a,(hl)
        ld    (de),a
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
        djnz  .PlayerDrawRow

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

PlayerJumpDeltas:
        defb  -4, -4, -3, -3, -2, -2, -1, -1, 0, 1, 1, 2, 2, 3, 3, 4, 4
PlayerPixelMasks:
        defb  128, 64, 32, 16, 8, 4, 2, 1

PlayerBackground:              block PLAYER_SPRITE_HEIGHT*3,0
PlayerShiftedBitmap:           block PLAYER_SPRITE_HEIGHT*3,0
PlayerShiftedMask:             block PLAYER_SPRITE_HEIGHT*3,255
PlayerPreparedWalkFrames:      block 2*4*4*PLAYER_SPRITE_HEIGHT*3*2,0

        include "player_sprites.asm"
;===============================================================================
