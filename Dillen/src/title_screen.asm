;###############################################################################
;##### Animated title screen, runtime lettering and ENTER/SPACE start. #########
;###############################################################################

TITLE_SCREEN_LOGO_ADDRESS     equ 23296 ; First byte immediately after VRAM.
TITLE_SCREEN_LOGO_WIDTH_BYTES equ 12
TITLE_SCREEN_LOGO_HEIGHT      equ 24
TITLE_SCREEN_DATA_END         equ 23584 ; 6912-byte screen + 288-byte logo.

TITLE_SCREEN_PROMPT_ATTR      equ 22528+22*32+10
TITLE_SCREEN_PROMPT_WIDTH     equ 12

TITLE_STARS_MAX               equ 8
TITLE_STAR_ROW_MIN            equ 6
TITLE_STAR_ROW_MAX            equ 21
TITLE_STAR_COL_MIN            equ 1
TITLE_STAR_COL_MAX            equ 30
TITLE_STAR_TRIES              equ 48
TITLE_STAR_PHASES             equ 8
TITLE_STAR_ITEM_SIZE          equ 5

TITLE_HERO_WALK_RIGHT_TO_MIDDLE equ 0
TITLE_HERO_ACTION_RIGHT         equ 1
TITLE_HERO_WALK_RIGHT_TO_EDGE   equ 2
TITLE_HERO_WALK_LEFT_TO_MIDDLE  equ 3
TITLE_HERO_ACTION_LEFT          equ 4
TITLE_HERO_WALK_LEFT_TO_EDGE    equ 5

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenShow - Display the text-free background, add every letter
; at runtime and wait for a fresh ENTER or SPACE press. InitAYMusicIM2 must
; already be active so HALT advances animation and music at 50 Hz.
TitleScreenShow:
        xor   a
        out   (254),a ; Black hardware border around the title artwork.

        call  TitleScreenDecompress

        xor   a
        ld    (TitleScreenAnimationTick),a
        ld    (TitleScreenAnimationPhase),a
        ld    (TitleScreenHeroX),a
        ld    (TitleScreenHeroFrame),a
        ld    (TitleScreenHeroState),a
        call  TitleScreenDrawLogo
        call  TitleScreenDrawText
        call  TitleScreenDrawWalkingHero
        call  TitleScreenPlaceStars

        ; A key held while the snapshot opens must be released first.
.TitleScreenWaitInitialRelease:
        halt
        call  TitleScreenAnimate
        call  TitleScreenReadStartKeys
        jr    nz,.TitleScreenWaitInitialRelease

.TitleScreenWaitPress:
        halt
        call  TitleScreenAnimate
        call  TitleScreenReadStartKeys
        jr    z,.TitleScreenWaitPress

        ; Consume the start key so SPACE does not immediately jump and ENTER
        ; does not immediately open the inventory on the first gameplay frame.
.TitleScreenWaitFinalRelease:
        halt
        call  TitleScreenAnimate
        call  TitleScreenReadStartKeys
        jr    nz,.TitleScreenWaitFinalRelease
        ret
; END - TitleScreenShow
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenDecompress - Expand the text-free 6912-byte background and
; the separate 800-byte comic logo into the free memory below the game code.
TitleScreenDecompress:
        ld    ix,TitleScreenPicture
        ld    de,16384
        xor   a
        ld    (TitleScreenLZBits),a

.TitleScreenLZLoop:
        ld    a,(TitleScreenLZBits)
        or    a
        jr    nz,.TitleScreenLZFlagsReady

        ld    a,(ix+0)
        inc   ix
        ld    (TitleScreenLZFlags),a
        ld    a,8

.TitleScreenLZFlagsReady:
        dec   a
        ld    (TitleScreenLZBits),a
        ld    a,(TitleScreenLZFlags)
        srl   a
        ld    (TitleScreenLZFlags),a
        jr    c,.TitleScreenLZMatch

        ; Flag bit 0: one literal byte.
        ld    a,(ix+0)
        inc   ix
        ld    (de),a
        inc   de
        jr    .TitleScreenLZCheckEnd

.TitleScreenLZMatch:
        ; Flag bit 1: 12-bit backwards offset and a 3..255-byte match.
        ld    l,(ix+0)
        inc   ix
        ld    a,(ix+0)
        inc   ix
        ld    (TitleScreenLZToken),a
        and   15
        cp    15
        jr    z,.TitleScreenLZLongMatch
        add   a,3
        jr    .TitleScreenLZLengthReady

.TitleScreenLZLongMatch:
        ld    a,(ix+0)
        inc   ix
        add   a,18

.TitleScreenLZLengthReady:
        ld    c,a
        ld    b,0
        ld    a,(TitleScreenLZToken)
        and   240
        rrca
        rrca
        rrca
        rrca
        ld    h,a

        ; LDIR deliberately supports overlapping matches such as long zero runs.
        push  de
        ex    de,hl ; HL - destination, DE - backwards offset.
        or    a
        sbc   hl,de ; HL - already decompressed match source.
        pop   de
        ldir

.TitleScreenLZCheckEnd:
        ld    a,d
        cp    TITLE_SCREEN_DATA_END/256
        jr    nz,.TitleScreenLZLoop
        ld    a,e
        cp    TITLE_SCREEN_DATA_END&255
        jr    nz,.TitleScreenLZLoop
        ret
; END - TitleScreenDecompress
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenDrawLogo - Draw the curved Comic Sans Bold "Dillen"
; bitmap. It is stored separately after the decompressed background, so the
; source .scr itself contains no letters.
TitleScreenDrawLogo:
        ld    ix,TITLE_SCREEN_LOGO_ADDRESS
        ld    b,0
        ld    c,80
        call  ScreenAddr
        ld    e,TITLE_SCREEN_LOGO_HEIGHT

.TitleScreenDrawLogoRow:
        push  hl
        ld    b,TITLE_SCREEN_LOGO_WIDTH_BYTES
.TitleScreenDrawLogoByte:
        ld    a,(ix+0)
        ld    (hl),a
        inc   ix
        inc   hl
        djnz  .TitleScreenDrawLogoByte
        pop   hl
        call  DownHL
        dec   e
        jr    nz,.TitleScreenDrawLogoRow
        ret
; END - TitleScreenDrawLogo
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenDrawText - Draw all small copy with the game's existing
; Font4x8 and Print4x8 routine, then give each line a bright ink attribute.
TitleScreenDrawText:
        ld    ix,TitleScreenTextControls
        ld    b,7
        ld    c,10
        call  Print4x8

        ld    ix,TitleScreenTextMoveKeys
        ld    b,9
        ld    c,9
        call  Print4x8

        ld    ix,TitleScreenTextMove
        ld    b,10
        ld    c,12
        call  Print4x8

        ld    ix,TitleScreenTextJump
        ld    b,12
        ld    c,8
        call  Print4x8

        ld    ix,TitleScreenTextInventory
        ld    b,14
        ld    c,5
        call  Print4x8

        ld    ix,TitleScreenTextInventoryMove
        ld    b,16
        ld    c,5
        call  Print4x8

        ld    ix,TitleScreenTextStart
        ld    b,22
        ld    c,21
        call  Print4x8

        ; The thin comic logo stays a calm, fixed bright cyan.
        ld    hl,22528+10
        ld    b,TITLE_SCREEN_LOGO_WIDTH_BYTES
        ld    a,69
        call  TitleScreenFillAttributes
        ld    hl,22528+1*32+10
        ld    b,TITLE_SCREEN_LOGO_WIDTH_BYTES
        ld    a,69
        call  TitleScreenFillAttributes
        ld    hl,22528+2*32+10
        ld    b,TITLE_SCREEN_LOGO_WIDTH_BYTES
        ld    a,69
        call  TitleScreenFillAttributes

        ld    hl,22528+7*32+5
        ld    b,4
        ld    a,69 ; Bright cyan.
        call  TitleScreenFillAttributes
        ld    hl,22528+9*32+4
        ld    b,6
        ld    a,70 ; Bright yellow.
        call  TitleScreenFillAttributes
        ld    hl,22528+10*32+6
        ld    b,2
        ld    a,71 ; Bright white.
        call  TitleScreenFillAttributes
        ld    hl,22528+12*32+4
        ld    b,6
        ld    a,70
        call  TitleScreenFillAttributes
        ld    hl,22528+14*32+2
        ld    b,9
        ld    a,70
        call  TitleScreenFillAttributes
        ld    hl,22528+16*32+2
        ld    b,10
        ld    a,70
        call  TitleScreenFillAttributes
        ld    hl,TITLE_SCREEN_PROMPT_ATTR
        ld    b,TITLE_SCREEN_PROMPT_WIDTH
        ld    a,70
        jp    TitleScreenFillAttributes
; END - TitleScreenDrawText
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Fill B consecutive screen attributes at HL with A.
TitleScreenFillAttributes:
        ld    (hl),a
        inc   hl
        djnz  TitleScreenFillAttributes
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenReadStartKeys - Read the two accepted start keys.
; return Z=0 - ENTER or SPACE is pressed, Z=1 - both keys are released.
TitleScreenReadStartKeys:
        ld    bc,49150 ; H, J, K, L, Enter: bit 0 - Enter.
        in    a,(c)
        bit   0,a
        jr    z,.TitleScreenStartPressed

        ld    bc,32766 ; B, N, M, Symbol Shift, Space: bit 0 - Space.
        in    a,(c)
        bit   0,a
        jr    z,.TitleScreenStartPressed

        xor   a
        ret

.TitleScreenStartPressed:
        ld    a,1
        or    a
        ret
; END - TitleScreenReadStartKeys
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenAnimate - Advance the game's real star sequence every
; display frame. The hero scene and start prompt advance every eight frames.
TitleScreenAnimate:
        ld    hl,TitleScreenAnimationTick
        inc   (hl)
        call  TitleScreenAnimateStars

        ld    a,(TitleScreenAnimationTick)
        and   7
        call  z,TitleScreenAnimateWalkingHero

        ld    a,(TitleScreenAnimationTick)
        and   7
        ret   nz

        ld    a,(TitleScreenAnimationPhase)
        inc   a
        and   3
        ld    (TitleScreenAnimationPhase),a

        jp    TitleScreenAnimatePrompt
; END - TitleScreenAnimate
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Erase the old 16x24 player and advance the current scene. The hero walks more
; slowly in both directions, turns at the edges, and performs a hop-and-blink
; action whenever he reaches the middle.
TitleScreenAnimateWalkingHero:
        call  TitleScreenClearWalkingHero

        ld    a,(TitleScreenHeroState)
        cp    TITLE_HERO_ACTION_RIGHT
        jr    z,.TitleScreenHeroAction
        cp    TITLE_HERO_ACTION_LEFT
        jr    z,.TitleScreenHeroAction

        ld    a,(TitleScreenHeroFrame)
        inc   a
        and   3
        ld    (TitleScreenHeroFrame),a

        ld    a,(TitleScreenHeroState)
        cp    TITLE_HERO_WALK_LEFT_TO_MIDDLE
        jr    nc,.TitleScreenHeroWalkLeft

        ; Right-facing half of the route.
        ld    a,(TitleScreenHeroX)
        add   a,8
        ld    (TitleScreenHeroX),a

        ld    a,(TitleScreenHeroState)
        cp    TITLE_HERO_WALK_RIGHT_TO_MIDDLE
        jr    nz,.TitleScreenHeroCheckRightEdge
        ld    a,(TitleScreenHeroX)
        cp    120
        jr    nz,.TitleScreenHeroDraw
        ld    a,TITLE_HERO_ACTION_RIGHT
        ld    (TitleScreenHeroState),a
        xor   a
        ld    (TitleScreenHeroFrame),a
        jr    .TitleScreenHeroDraw

.TitleScreenHeroCheckRightEdge:
        ld    a,(TitleScreenHeroX)
        cp    240
        jr    nz,.TitleScreenHeroDraw
        ld    a,TITLE_HERO_WALK_LEFT_TO_MIDDLE
        ld    (TitleScreenHeroState),a
        jr    .TitleScreenHeroDraw

.TitleScreenHeroWalkLeft:
        ld    a,(TitleScreenHeroX)
        sub   8
        ld    (TitleScreenHeroX),a

        ld    a,(TitleScreenHeroState)
        cp    TITLE_HERO_WALK_LEFT_TO_MIDDLE
        jr    nz,.TitleScreenHeroCheckLeftEdge
        ld    a,(TitleScreenHeroX)
        cp    120
        jr    nz,.TitleScreenHeroDraw
        ld    a,TITLE_HERO_ACTION_LEFT
        ld    (TitleScreenHeroState),a
        xor   a
        ld    (TitleScreenHeroFrame),a
        jr    .TitleScreenHeroDraw

.TitleScreenHeroCheckLeftEdge:
        ld    a,(TitleScreenHeroX)
        or    a
        jr    nz,.TitleScreenHeroDraw
        ld    a,TITLE_HERO_WALK_RIGHT_TO_MIDDLE
        ld    (TitleScreenHeroState),a
        jr    .TitleScreenHeroDraw

.TitleScreenHeroAction:
        ld    a,(TitleScreenHeroFrame)
        inc   a
        cp    8
        jr    c,.TitleScreenHeroStoreActionFrame

        xor   a
        ld    (TitleScreenHeroFrame),a
        ld    a,(TitleScreenHeroState)
        cp    TITLE_HERO_ACTION_RIGHT
        ld    a,TITLE_HERO_WALK_RIGHT_TO_EDGE
        jr    z,.TitleScreenHeroStoreActionState
        ld    a,TITLE_HERO_WALK_LEFT_TO_EDGE
.TitleScreenHeroStoreActionState:
        ld    (TitleScreenHeroState),a
        jr    .TitleScreenHeroDraw

.TitleScreenHeroStoreActionFrame:
        ld    (TitleScreenHeroFrame),a

.TitleScreenHeroDraw:
        jp    TitleScreenDrawWalkingHero
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Clear the previous byte-aligned player bitmap and its six attributes.
TitleScreenClearWalkingHero:
        ld    a,(TitleScreenHeroX)
        ld    c,a
        ld    b,24
        call  ScreenAddr
        ld    e,24
.TitleScreenClearWalkingHeroRow:
        push  hl
        xor   a
        ld    (hl),a
        inc   hl
        ld    (hl),a
        pop   hl
        call  DownHL
        dec   e
        jr    nz,.TitleScreenClearWalkingHeroRow

        xor   a
        jp    TitleScreenSetWalkingHeroAttributes
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Select a real right/left walk frame or the middle hop-and-blink pose, then
; draw it at the current title-screen X.
TitleScreenDrawWalkingHero:
        ld    a,(TitleScreenHeroFrame)
        add   a,a
        ld    e,a
        ld    d,0

        ld    a,(TitleScreenHeroState)
        cp    TITLE_HERO_ACTION_RIGHT
        jr    z,.TitleScreenHeroUseActionFrames
        cp    TITLE_HERO_ACTION_LEFT
        jr    z,.TitleScreenHeroUseActionFrames
        cp    TITLE_HERO_WALK_LEFT_TO_MIDDLE
        ld    hl,PlayerWalkRightSpriteFrames
        jr    c,.TitleScreenHeroFrameTableReady
        ld    hl,PlayerWalkLeftSpriteFrames
        jr    .TitleScreenHeroFrameTableReady

.TitleScreenHeroUseActionFrames:
        ld    hl,TitleScreenHeroActionFrames

.TitleScreenHeroFrameTableReady:
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        push  de
        pop   ix

        ld    a,(TitleScreenHeroX)
        ld    c,a
        ld    b,24
        call  ScreenAddr
        ld    e,24
.TitleScreenDrawWalkingHeroRow:
        push  hl
        ld    a,(ix+0)
        ld    (hl),a
        inc   ix
        inc   hl
        ld    a,(ix+0)
        ld    (hl),a
        inc   ix
        pop   hl
        call  DownHL
        dec   e
        jr    nz,.TitleScreenDrawWalkingHeroRow

        ld    a,70 ; Bright yellow ink on black paper.
        jp    TitleScreenSetWalkingHeroAttributes
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Set the two-by-three attribute rectangle under the walking player to A.
TitleScreenSetWalkingHeroAttributes:
        push  af
        ld    a,(TitleScreenHeroX)
        srl   a
        srl   a
        srl   a
        ld    c,a
        ld    b,3
        call  AttrAddr
        pop   af

        ld    de,30
        ld    b,3
.TitleScreenSetWalkingHeroAttributeRow:
        ld    (hl),a
        inc   hl
        ld    (hl),a
        inc   hl
        add   hl,de
        djnz  .TitleScreenSetWalkingHeroAttributeRow
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - TitleScreenPlaceStars - Place the game's real twinkling stars into
; random empty black cells. The logo, hero lane, controls and prompt are kept
; clear, and already occupied artwork cells are rejected.
TitleScreenPlaceStars:
        xor   a
        ld    (TitleScreenStarsCount),a
        ld    a,r
        xor   73
        ld    (TitleScreenStarsSeed),a

        ld    ix,TitleScreenStarsData
        ld    b,TITLE_STARS_MAX
.TitleScreenPlaceStarLoop:
        push  bc
        call  TitleScreenFindFreeStarCell
        jr    nc,.TitleScreenPlaceStarNext

        ld    (ix+0),l
        ld    (ix+1),h
        call  TitleScreenStarsRandom
        and   TITLE_STAR_PHASES-1
        ld    (ix+2),a
        call  TitleScreenStarsRandom
        and   3
        add   a,3
        ld    (ix+3),a
        ld    (ix+4),a
        call  TitleScreenDrawStar

        ld    de,TITLE_STAR_ITEM_SIZE
        add   ix,de
        ld    hl,TitleScreenStarsCount
        inc   (hl)

.TitleScreenPlaceStarNext:
        pop   bc
        djnz  .TitleScreenPlaceStarLoop
        ret
; END - TitleScreenPlaceStars
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Find one random empty black 8x8 cell in the illustration area.
; return CF=1 and HL - screen address; CF=0 - no free cell was found.
TitleScreenFindFreeStarCell:
        ld    b,TITLE_STAR_TRIES
.TitleScreenFindStarTry:
        push  bc

        call  TitleScreenStarsRandom
        and   31
        cp    TITLE_STAR_COL_MIN
        jr    c,.TitleScreenFindStarNext
        cp    TITLE_STAR_COL_MAX+1
        jr    nc,.TitleScreenFindStarNext
        ld    c,a

        call  TitleScreenStarsRandom
        and   15
        add   a,TITLE_STAR_ROW_MIN
        ld    b,a

        ; Keep the complete controls panel free of decorative stars.
        cp    18
        jr    nc,.TitleScreenFindStarCheckPaper
        ld    a,c
        cp    13
        jr    c,.TitleScreenFindStarNext

.TitleScreenFindStarCheckPaper:
        push  bc
        call  AttrAddr
        and   56
        pop   bc
        jr    nz,.TitleScreenFindStarNext

        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a
        ld    a,c
        add   a,a
        add   a,a
        add   a,a
        ld    c,a
        call  ScreenAddr
        call  TitleScreenStarCellIsEmpty
        jr    nc,.TitleScreenFindStarNext

        ; The star uses a random bright green/cyan/yellow/white ink on black.
        push  hl
        srl   b
        srl   b
        srl   b
        srl   c
        srl   c
        srl   c
        call  AttrAddr
        call  TitleScreenStarsRandom
        and   3
        add   a,68
        ld    (hl),a
        pop   hl

        pop   bc
        scf
        ret

.TitleScreenFindStarNext:
        pop   bc
        djnz  .TitleScreenFindStarTry
        or    a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Test whether all eight pixel rows of a candidate cell are empty.
TitleScreenStarCellIsEmpty:
        push  bc
        push  hl
        ld    b,8
        ld    c,0
.TitleScreenStarCellLoop:
        ld    a,(hl)
        or    c
        ld    c,a
        call  DownHL
        djnz  .TitleScreenStarCellLoop
        ld    a,c
        pop   hl
        pop   bc
        or    a
        ret   nz
        scf
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Advance every star independently, using the same 8-phase sequence and
; per-star 3..6 frame speed as stars in outdoor game rooms.
TitleScreenAnimateStars:
        ld    a,(TitleScreenStarsCount)
        or    a
        ret   z
        ld    b,a
        ld    ix,TitleScreenStarsData
.TitleScreenAnimateStarLoop:
        push  bc
        dec   (ix+3)
        jr    nz,.TitleScreenAnimateStarNext
        ld    a,(ix+4)
        ld    (ix+3),a
        ld    a,(ix+2)
        inc   a
        cp    TITLE_STAR_PHASES
        jr    c,.TitleScreenAnimateStarDraw
        xor   a
.TitleScreenAnimateStarDraw:
        ld    (ix+2),a
        call  TitleScreenDrawStar
.TitleScreenAnimateStarNext:
        ld    de,TITLE_STAR_ITEM_SIZE
        add   ix,de
        pop   bc
        djnz  .TitleScreenAnimateStarLoop
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw one of the exact _StarsShapes frames used by the game.
TitleScreenDrawStar:
        ld    a,(ix+2)
        add   a,a
        add   a,a
        add   a,a
        ld    e,a
        ld    d,0
        ld    hl,_StarsShapes
        add   hl,de
        ex    de,hl
        ld    l,(ix+0)
        ld    h,(ix+1)
        ld    b,8
.TitleScreenDrawStarRow:
        ld    a,(de)
        ld    (hl),a
        inc   de
        call  DownHL
        djnz  .TitleScreenDrawStarRow
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Return the next title-star pseudo-random byte in A.
TitleScreenStarsRandom:
        push  hl
        push  bc
        ld    hl,TitleScreenStarsSeed
        call  Random8bit
        pop   bc
        pop   hl
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Pulse only the 4x8 start prompt; stars now animate their real bitmap shapes.
TitleScreenAnimatePrompt:
        ld    a,(TitleScreenAnimationPhase)
        ld    e,a
        ld    d,0
        ld    hl,TitleScreenPromptColors
        add   hl,de

        ld    a,(hl)
        ld    hl,TITLE_SCREEN_PROMPT_ATTR
        ld    de,TITLE_SCREEN_PROMPT_ATTR+1
        ld    bc,TITLE_SCREEN_PROMPT_WIDTH-1
        ld    (hl),a
        ldir
        ret
;-------------------------------------------------------------------------------

TitleScreenAnimationTick:
        defb  0

TitleScreenAnimationPhase:
        defb  0

TitleScreenHeroX:
        defb  0

TitleScreenHeroFrame:
        defb  0

TitleScreenHeroState:
        defb  0

TitleScreenStarsCount:
        defb  0

TitleScreenStarsSeed:
        defb  73

TitleScreenStarsData:
        block TITLE_STARS_MAX*TITLE_STAR_ITEM_SIZE

TitleScreenLZFlags:
        defb  0

TitleScreenLZBits:
        defb  0

TitleScreenLZToken:
        defb  0

TitleScreenTextControls:
        defb  "CONTROLS", 0
TitleScreenTextMoveKeys:
        defb  "Z/X OR O/P", 0
TitleScreenTextMove:
        defb  "MOVE", 0
TitleScreenTextJump:
        defb  "SPACE - JUMP", 0
TitleScreenTextInventory:
        defb  "ENTER - INVENTORY", 0
TitleScreenTextInventoryMove:
        defb  "Q/A - ITEM UP/DOWN", 0
TitleScreenTextStart:
        defb  "ENTER OR SPACE - START", 0

; Stop, squash, rise, hang, land, recover, wink and look forward again.
TitleScreenHeroActionFrames:
        defw  PlayerSpriteIdle0
        defw  PlayerSpriteIdleHopSquash
        defw  PlayerSpriteIdleHopAir
        defw  PlayerSpriteIdleHopAir
        defw  PlayerSpriteIdleHopSquash
        defw  PlayerSpriteIdle0
        defw  PlayerSpriteIdleBlink
        defw  PlayerSpriteIdle0

TitleScreenPromptColors:
        defb  70, 71, 69, 71

TitleScreenPicture:
        incbin  "binary/dillen-title.lzs"
