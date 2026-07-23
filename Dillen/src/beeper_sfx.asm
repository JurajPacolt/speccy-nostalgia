;###############################################################################
;##### Short 1-bit BEEPER effects which leave the IM2 AY music running. ########
;###############################################################################

BEEPER_PORT       equ 254
BEEPER_LEVEL_HIGH equ 16

;-------------------------------------------------------------------------------
; Alternate two dry clicks for successive walking steps.
BeeperSfxFootstep:
        push  af
        push  bc

        ld    a,(BeeperFootstepPhase)
        xor   1
        ld    (BeeperFootstepPhase),a
        ld    a,116
        jr    z,.FootstepPitchReady
        ld    a,92
.FootstepPitchReady:
        ld    b,5
        call  BeeperPlayTone

        pop   bc
        pop   af
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; A fast rising chirp at the instant of take-off.
BeeperSfxJump:
        push  af
        push  bc

        ld    a,120
        ld    b,5
        call  BeeperPlayTone
        ld    a,90
        ld    b,5
        call  BeeperPlayTone
        ld    a,60
        ld    b,7
        call  BeeperPlayTone

        pop   bc
        pop   af
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Two rising notes when the inventory window appears.
BeeperSfxInventoryOpen:
        push  af
        push  bc

        ld    a,130
        ld    b,4
        call  BeeperPlayTone
        ld    a,85
        ld    b,6
        call  BeeperPlayTone

        pop   bc
        pop   af
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; The inverse two-note gesture when the inventory closes.
BeeperSfxInventoryClose:
        push  af
        push  bc

        ld    a,85
        ld    b,5
        call  BeeperPlayTone
        ld    a,130
        ld    b,5
        call  BeeperPlayTone

        pop   bc
        pop   af
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; A four-note confirmation heard only after a successful item action.
BeeperSfxUseItem:
        push  af
        push  bc

        ld    a,120
        ld    b,5
        call  BeeperPlayTone
        ld    a,90
        ld    b,5
        call  BeeperPlayTone
        ld    a,65
        ld    b,5
        call  BeeperPlayTone
        ld    a,45
        ld    b,6
        call  BeeperPlayTone

        pop   bc
        pop   af
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - BeeperPlayTone - Emit B complete square-wave pulses.
; A - half-wave delay and therefore inverse pitch, B - pulse count.
; Interrupts deliberately remain enabled: the IM2 handler keeps AY music moving
; and restores every register before this short delay loop resumes.
BeeperPlayTone:
        push  af
        push  bc
        push  de
        ld    c,a

.BeeperPulse:
        ld    a,BEEPER_LEVEL_HIGH
        out   (BEEPER_PORT),a
        ld    d,c
.BeeperHighDelay:
        dec   d
        jr    nz,.BeeperHighDelay

        xor   a
        out   (BEEPER_PORT),a
        ld    d,c
.BeeperLowDelay:
        dec   d
        jr    nz,.BeeperLowDelay
        djnz  .BeeperPulse

        xor   a
        out   (BEEPER_PORT),a
        pop   de
        pop   bc
        pop   af
        ret
; END - BeeperPlayTone
;-------------------------------------------------------------------------------

BeeperFootstepPhase:
        defb  0

        assert $ <= 65536
