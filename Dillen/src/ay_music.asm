;###############################################################################
;##### AY background music and IM2 player. #####################################
;###############################################################################

; The tune runs at 125 BPM on a 50 Hz PAL machine. One pattern has 16 steps,
; every step takes 6 frames. The 32-pattern order therefore loops after
; 32*16*6/50 = 61.44 seconds.

AY_REGISTER_PORT       equ 65533 ; 0xFFFD
AY_DATA_PORT           equ 49149 ; 0xBFFD
AY_FRAMES_PER_STEP     equ 6
AY_STEPS_PER_PATTERN   equ 16
AY_ORDER_LENGTH        equ 32
AY_CHORD_MINOR         equ 128

AY_DRUM_NONE           equ 0
AY_DRUM_KICK           equ 1
AY_DRUM_SNARE          equ 2
AY_DRUM_HAT            equ 3
AY_DRUM_OPEN_HAT       equ 4
AY_DRUM_TOM            equ 5

N_REST equ 0
N_C2   equ 1
N_CS2  equ 2
N_D2   equ 3
N_DS2  equ 4
N_E2   equ 5
N_F2   equ 6
N_FS2  equ 7
N_G2   equ 8
N_GS2  equ 9
N_A2   equ 10
N_AS2  equ 11
N_B2   equ 12
N_C3   equ 13
N_CS3  equ 14
N_D3   equ 15
N_DS3  equ 16
N_E3   equ 17
N_F3   equ 18
N_FS3  equ 19
N_G3   equ 20
N_GS3  equ 21
N_A3   equ 22
N_AS3  equ 23
N_B3   equ 24
N_C4   equ 25
N_CS4  equ 26
N_D4   equ 27
N_DS4  equ 28
N_E4   equ 29
N_F4   equ 30
N_FS4  equ 31
N_G4   equ 32
N_GS4  equ 33
N_A4   equ 34
N_AS4  equ 35
N_B4   equ 36
N_C5   equ 37
N_CS5  equ 38
N_D5   equ 39
N_DS5  equ 40
N_E5   equ 41
N_F5   equ 42
N_FS5  equ 43
N_G5   equ 44
N_GS5  equ 45
N_A5   equ 46
N_AS5  equ 47
N_B5   equ 48

;-------------------------------------------------------------------------------
; InitAYMusicIM2 - initialize AY and switch the game to the music IM2 handler.
; EntryPoint already disabled interrupts before this routine is called.
InitAYMusicIM2:
        call  AYMusicInit
        ld    a,190 ; High byte of the IM2 vector table at 0xBE00.
        ld    i,a
        im    2
        ei
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicInit:
        xor   a
        ld    (AYMusicOrderIndex),a
        ld    (AYMusicStepIndex),a
        ld    (AYMusicArpeggioPhase),a
        ld    (AYMusicMelodyNote),a
        ld    (AYMusicBassNote),a
        ld    (AYMusicChord),a
        ld    (AYMusicDrumType),a
        ld    (AYMusicDrumTimer),a

        ld    a,1 ; The first interrupt immediately loads step zero.
        ld    (AYMusicStepTimer),a
        ld    (AYMusicEnabled),a

        ld    e,0
        ld    a,8
        call  AYMusicWriteRegister
        ld    a,9
        call  AYMusicWriteRegister
        ld    a,10
        call  AYMusicWriteRegister
        ld    e,56 ; Tone A/B/C on, noise A/B/C off.
        ld    a,7
        jp    AYMusicWriteRegister
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; AYMusicTick - called once per frame by the IM2 handler.
AYMusicTick:
        ld    a,(AYMusicEnabled)
        or    a
        ret   z

        ld    a,(AYMusicStepTimer)
        dec   a
        ld    (AYMusicStepTimer),a
        jr    nz,.Render

        ld    a,AY_FRAMES_PER_STEP
        ld    (AYMusicStepTimer),a
        call  AYMusicLoadStep

.Render:
        call  AYMusicRenderMelodyAndBass
        jp    AYMusicRenderChordOrDrum
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Load the melody note, bass note and chord of the current pattern step.
AYMusicLoadStep:
        ld    a,(AYMusicOrderIndex)
        ld    e,a
        ld    d,0
        ld    hl,AYMusicOrder
        add   hl,de
        ld    a,(hl) ; Pattern number.
        add   a,a
        ld    e,a
        ld    d,0
        ld    hl,AYMusicPatternTable
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        ex    de,hl ; HL = pattern address.

        ld    a,(AYMusicStepIndex)
        ld    e,a
        add   a,a
        add   a,e ; Three bytes per step.
        ld    e,a
        ld    d,0
        add   hl,de

        ld    a,(hl)
        ld    (AYMusicMelodyNote),a
        inc   hl
        ld    a,(hl)
        ld    (AYMusicBassNote),a
        inc   hl
        ld    a,(hl)
        ld    (AYMusicChord),a
        xor   a
        ld    (AYMusicArpeggioPhase),a ; Start every picking figure on its root.

        call  AYMusicLoadRhythm

        ld    a,(AYMusicStepIndex)
        inc   a
        cp    AY_STEPS_PER_PATTERN
        jr    c,.StoreStep

        xor   a
        ld    (AYMusicStepIndex),a
        ld    a,(AYMusicOrderIndex)
        inc   a
        cp    AY_ORDER_LENGTH
        jr    c,.StoreOrder
        xor   a
.StoreOrder:
        ld    (AYMusicOrderIndex),a
        ret

.StoreStep:
        ld    (AYMusicStepIndex),a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Load one of the changing country grooves selected by the order list.
AYMusicLoadRhythm:
        ld    a,(AYMusicOrderIndex)
        ld    e,a
        ld    d,0
        ld    hl,AYMusicRhythmOrder
        add   hl,de
        ld    a,(hl)
        add   a,a
        ld    e,a
        ld    d,0
        ld    hl,AYMusicRhythmTable
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        ex    de,hl
        ld    a,(AYMusicStepIndex)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl)
        or    a
        ret   z

        cp    AY_DRUM_KICK
        jr    z,.Kick
        cp    AY_DRUM_SNARE
        jr    z,.Snare
        cp    AY_DRUM_HAT
        jr    z,.Hat
        cp    AY_DRUM_OPEN_HAT
        jr    z,.OpenHat

        ld    a,AY_DRUM_TOM
        ld    (AYMusicDrumType),a
        ld    a,2
        ld    (AYMusicDrumTimer),a
        ret

.Snare:
        ld    a,AY_DRUM_SNARE
        ld    (AYMusicDrumType),a
        ld    a,3
        ld    (AYMusicDrumTimer),a
        ret

.Kick:
        ld    a,AY_DRUM_KICK
        ld    (AYMusicDrumType),a
        ld    a,2
        ld    (AYMusicDrumTimer),a
        ret

.Hat:
        ld    a,AY_DRUM_HAT
        ld    (AYMusicDrumType),a
        ld    a,1
        ld    (AYMusicDrumTimer),a
        ret

.OpenHat:
        ld    a,AY_DRUM_OPEN_HAT
        ld    (AYMusicDrumType),a
        ld    a,3
        ld    (AYMusicDrumTimer),a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderMelodyAndBass:
        ld    a,(AYMusicMelodyNote)
        push  af
        call  AYMusicWriteToneA
        pop   af
        ld    e,0
        or    a
        jr    z,.MelodyVolume
        ld    e,12
        ld    a,(AYMusicStepTimer)
        cp    1
        jr    nz,.MelodyVolume
        ld    e,6 ; A short release keeps consecutive notes crisp.
.MelodyVolume:
        ld    a,8
        call  AYMusicWriteRegister

        ld    a,(AYMusicBassNote)
        push  af
        call  AYMusicWriteToneB
        pop   af
        ld    e,0
        or    a
        jr    z,.BassVolume
        ld    e,9
        ld    a,(AYMusicStepTimer)
        cp    1
        jr    nz,.BassVolume
        ld    e,4
.BassVolume:
        ld    a,9
        jp    AYMusicWriteRegister
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderChordOrDrum:
        ld    a,(AYMusicDrumTimer)
        or    a
        jp    z,AYMusicRenderChord

        ld    a,(AYMusicDrumType)
        cp    AY_DRUM_KICK
        jr    z,AYMusicRenderKick
        cp    AY_DRUM_SNARE
        jr    z,AYMusicRenderSnare
        cp    AY_DRUM_HAT
        jr    z,AYMusicRenderHat
        cp    AY_DRUM_OPEN_HAT
        jr    z,AYMusicRenderOpenHat
        jp    AYMusicRenderTom
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderKick:
        ld    hl,520
        ld    a,(AYMusicDrumTimer)
        cp    2
        jr    z,.PeriodReady
        ld    hl,820 ; Drop the pitch on the second frame.
.PeriodReady:
        call  AYMusicWriteToneCPeriod
        ld    e,18
        ld    a,6
        call  AYMusicWriteRegister
        ld    e,24 ; Tone and noise C on; noise A/B off.
        ld    a,7
        call  AYMusicWriteRegister
        ld    e,13
        ld    a,(AYMusicDrumTimer)
        cp    2
        jr    z,.VolumeReady
        ld    e,9
.VolumeReady:
        ld    a,10
        call  AYMusicWriteRegister
        jp    AYMusicDecreaseDrumTimer
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderSnare:
        ld    e,6
        ld    a,6
        call  AYMusicWriteRegister
        ld    e,28 ; Tone C off, noise C on; noise A/B off.
        ld    a,7
        call  AYMusicWriteRegister
        ld    a,(AYMusicDrumTimer)
        add   a,a
        add   a,a
        ld    e,a ; Volumes 12, 8, 4.
        ld    a,10
        call  AYMusicWriteRegister
        jp    AYMusicDecreaseDrumTimer
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderHat:
        ld    e,1
        ld    a,6
        call  AYMusicWriteRegister
        ld    e,28
        ld    a,7
        call  AYMusicWriteRegister
        ld    e,6
        ld    a,10
        call  AYMusicWriteRegister
        jp    AYMusicDecreaseDrumTimer
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderOpenHat:
        ld    e,2
        ld    a,6
        call  AYMusicWriteRegister
        ld    e,28
        ld    a,7
        call  AYMusicWriteRegister
        ld    a,(AYMusicDrumTimer)
        add   a,a
        add   a,2 ; Volumes 8, 6, 4.
        ld    e,a
        ld    a,10
        call  AYMusicWriteRegister
        jp    AYMusicDecreaseDrumTimer
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicRenderTom:
        ld    hl,330
        ld    a,(AYMusicDrumTimer)
        cp    2
        jr    z,.PeriodReady
        ld    hl,470
.PeriodReady:
        call  AYMusicWriteToneCPeriod
        ld    e,56 ; Pitched tom, without noise.
        ld    a,7
        call  AYMusicWriteRegister
        ld    e,11
        ld    a,(AYMusicDrumTimer)
        cp    2
        jr    z,.VolumeReady
        ld    e,7
.VolumeReady:
        ld    a,10
        call  AYMusicWriteRegister
        jp    AYMusicDecreaseDrumTimer
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicDecreaseDrumTimer:
        ld    hl,AYMusicDrumTimer
        dec   (hl)
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Banjo-like picking: root, fifth, third, fifth, octave, fifth.
AYMusicRenderChord:
        ld    a,(AYMusicChord)
        ld    c,a
        and   127
        ld    e,a ; E = chord root note.

        ld    a,(AYMusicArpeggioPhase)
        or    a
        jr    z,.NoteReady
        cp    2
        jr    z,.Third
        cp    4
        jr    z,.Octave

.Fifth:
        ld    a,e
        add   a,7
        jr    .SetNote

.Third:
        ld    a,e
        bit   7,c
        jr    nz,.MinorThird
        add   a,4
        jr    .SetNote
.MinorThird:
        add   a,3
        jr    .SetNote
.Octave:
        ld    a,e
        add   a,12
        jr    .SetNote
.NoteReady:
        ld    a,e
.SetNote:
        push  af
        call  AYMusicWriteToneC
        pop   af
        ld    e,0
        or    a
        jr    z,.ChordVolume
        ld    e,7
.ChordVolume:
        ld    a,10
        call  AYMusicWriteRegister
        ld    e,56 ; Tone A/B/C on, all noise off.
        ld    a,7
        call  AYMusicWriteRegister

        ld    a,(AYMusicArpeggioPhase)
        inc   a
        cp    6
        jr    c,.StorePhase
        xor   a
.StorePhase:
        ld    (AYMusicArpeggioPhase),a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicWriteToneA:
        call  AYMusicNotePeriod
        ld    e,l
        xor   a
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,1
        jp    AYMusicWriteRegister

AYMusicWriteToneB:
        call  AYMusicNotePeriod
        ld    e,l
        ld    a,2
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,3
        jp    AYMusicWriteRegister

AYMusicWriteToneC:
        call  AYMusicNotePeriod
AYMusicWriteToneCPeriod:
        ld    e,l
        ld    a,4
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,5
        jp    AYMusicWriteRegister
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; A = note 1..48 (C2..B5), or zero for rest. Returns its AY period in HL.
AYMusicNotePeriod:
        or    a
        jr    nz,.Note
        ld    hl,0
        ret
.Note:
        dec   a
        add   a,a
        ld    e,a
        ld    d,0
        ld    hl,AYMusicNotePeriods
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        ex    de,hl
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; A = AY register, E = value.
AYMusicWriteRegister:
        push  bc
        ld    bc,AY_REGISTER_PORT
        out   (c),a
        ld    b,191 ; AY_DATA_PORT has the same low byte 0xFD.
        out   (c),e
        pop   bc
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicEnabled:
        defb  0
AYMusicOrderIndex:
        defb  0
AYMusicStepIndex:
        defb  0
AYMusicStepTimer:
        defb  1
AYMusicArpeggioPhase:
        defb  0
AYMusicMelodyNote:
        defb  0
AYMusicBassNote:
        defb  0
AYMusicChord:
        defb  0
AYMusicDrumType:
        defb  0
AYMusicDrumTimer:
        defb  0
;-------------------------------------------------------------------------------

; AY periods for C2..B5 at the 1.7734 MHz ZX Spectrum AY clock.
AYMusicNotePeriods:
        defw  1695,1599,1510,1425,1345,1270,1198,1131,1068,1008,951,898
        defw  847,800,755,712,673,635,599,566,534,504,476,449
        defw  424,400,377,356,336,317,300,283,267,252,238,224
        defw  212,200,189,178,168,159,150,141,133,126,119,112

; Thirty-two pattern positions = 61.44 seconds.
AYMusicOrder:
        defb  0,1,2,3, 0,1,2,3
        defb  4,5,4,6, 4,5,7,6
        defb  0,1,2,3, 4,5,4,6
        defb  7,5,2,3, 4,5,7,6

; A separate rhythm order lets repeated melodies return with a different feel.
AYMusicRhythmOrder:
        defb  0,0,1,4, 0,2,1,4
        defb  1,2,1,3, 2,1,4,3
        defb  0,2,1,4, 1,2,3,4
        defb  3,1,2,4, 1,2,5,4

AYMusicRhythmTable:
        defw  AYMusicRhythm0,AYMusicRhythm1,AYMusicRhythm2
        defw  AYMusicRhythm3,AYMusicRhythm4,AYMusicRhythm5

; 0: classic country boom-chicka.
AYMusicRhythm0:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE

; 1: busy train beat.
AYMusicRhythm1:
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT

; 2: syncopated verse groove.
AYMusicRhythm2:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_KICK
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_NONE,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_HAT

; 3: sparse breakdown with an open hat.
AYMusicRhythm3:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_NONE,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_OPEN_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE

; 4: end-of-phrase tom and snare fill.
AYMusicRhythm4:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_TOM,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_SNARE,AY_DRUM_TOM,AY_DRUM_SNARE

; 5: double-time finale before the loop restarts.
AYMusicRhythm5:
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_SNARE,AY_DRUM_HAT
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_SNARE,AY_DRUM_HAT
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_SNARE,AY_DRUM_HAT
        defb  AY_DRUM_KICK,AY_DRUM_SNARE,AY_DRUM_TOM,AY_DRUM_SNARE

AYMusicPatternTable:
        defw  AYMusicPattern0,AYMusicPattern1,AYMusicPattern2,AYMusicPattern3
        defw  AYMusicPattern4,AYMusicPattern5,AYMusicPattern6,AYMusicPattern7

; Every step: melody note, bass note, chord root/type.
AYMusicPattern0:
        defb  N_E4,N_C2,N_C3
        defb  N_REST,N_REST,N_C3
        defb  N_G4,N_G2,N_C3
        defb  N_REST,N_REST,N_C3
        defb  N_A4,N_F2,N_F3
        defb  N_G4,N_REST,N_F3
        defb  N_E4,N_C3,N_F3
        defb  N_REST,N_REST,N_F3
        defb  N_F4,N_C2,N_C3
        defb  N_REST,N_REST,N_C3
        defb  N_E4,N_G2,N_C3
        defb  N_D4,N_REST,N_C3
        defb  N_G4,N_G2,N_G3
        defb  N_REST,N_REST,N_G3
        defb  N_D4,N_D3,N_G3
        defb  N_REST,N_REST,N_G3

AYMusicPattern1:
        defb  N_C5,N_C2,N_C3
        defb  N_B4,N_REST,N_C3
        defb  N_G4,N_G2,N_C3
        defb  N_E4,N_REST,N_C3
        defb  N_F4,N_F2,N_F3
        defb  N_REST,N_REST,N_F3
        defb  N_A4,N_C3,N_F3
        defb  N_REST,N_REST,N_F3
        defb  N_G4,N_G2,N_G3
        defb  N_E4,N_REST,N_G3
        defb  N_D4,N_D3,N_G3
        defb  N_REST,N_REST,N_G3
        defb  N_E4,N_C2,N_C3
        defb  N_REST,N_REST,N_C3
        defb  N_C4,N_G2,N_C3
        defb  N_REST,N_REST,N_C3

AYMusicPattern2:
        defb  N_G4,N_C2,N_C3
        defb  N_A4,N_REST,N_C3
        defb  N_C5,N_G2,N_C3
        defb  N_REST,N_REST,N_C3
        defb  N_A4,N_F2,N_F3
        defb  N_G4,N_REST,N_F3
        defb  N_F4,N_C3,N_F3
        defb  N_REST,N_REST,N_F3
        defb  N_E4,N_C2,N_C3
        defb  N_G4,N_REST,N_C3
        defb  N_A4,N_G2,N_C3
        defb  N_C5,N_REST,N_C3
        defb  N_B4,N_G2,N_G3
        defb  N_A4,N_REST,N_G3
        defb  N_G4,N_D3,N_G3
        defb  N_REST,N_REST,N_G3

AYMusicPattern3:
        defb  N_F4,N_F2,N_F3
        defb  N_A4,N_REST,N_F3
        defb  N_C5,N_C3,N_F3
        defb  N_A4,N_REST,N_F3
        defb  N_G4,N_G2,N_G3
        defb  N_B4,N_REST,N_G3
        defb  N_D5,N_D3,N_G3
        defb  N_B4,N_REST,N_G3
        defb  N_C5,N_C2,N_C3
        defb  N_C5,N_REST,N_C3
        defb  N_G4,N_G2,N_C3
        defb  N_E4,N_REST,N_C3
        defb  N_D4,N_G2,N_G3
        defb  N_G4,N_A2,N_G3
        defb  N_B4,N_B2,N_G3
        defb  N_C5,N_C3,N_G3

AYMusicPattern4:
        defb  N_C5,N_C2,N_C3
        defb  N_C5,N_REST,N_C3
        defb  N_E5,N_G2,N_C3
        defb  N_G5,N_REST,N_C3
        defb  N_E5,N_G2,N_G3
        defb  N_D5,N_REST,N_G3
        defb  N_C5,N_D3,N_G3
        defb  N_REST,N_REST,N_G3
        defb  N_D5,N_C2,N_C3
        defb  N_E5,N_REST,N_C3
        defb  N_G5,N_G2,N_C3
        defb  N_E5,N_REST,N_C3
        defb  N_E5,N_F2,N_F3
        defb  N_D5,N_REST,N_F3
        defb  N_C5,N_C3,N_F3
        defb  N_REST,N_REST,N_F3

AYMusicPattern5:
        defb  N_F5,N_F2,N_F3
        defb  N_E5,N_REST,N_F3
        defb  N_D5,N_C3,N_F3
        defb  N_C5,N_REST,N_F3
        defb  N_G4,N_C2,N_C3
        defb  N_C5,N_REST,N_C3
        defb  N_E5,N_G2,N_C3
        defb  N_G5,N_REST,N_C3
        defb  N_A4,N_D2,N_D3
        defb  N_D5,N_REST,N_D3
        defb  N_FS5,N_A2,N_D3
        defb  N_A5,N_REST,N_D3
        defb  N_G5,N_G2,N_G3
        defb  N_F5,N_REST,N_G3
        defb  N_D5,N_D3,N_G3
        defb  N_REST,N_REST,N_G3

AYMusicPattern6:
        defb  N_E5,N_C2,N_C3
        defb  N_D5,N_REST,N_C3
        defb  N_C5,N_G2,N_C3
        defb  N_E5,N_REST,N_C3
        defb  N_A4,N_C2,N_C3
        defb  N_C5,N_REST,N_C3
        defb  N_E5,N_G2,N_C3
        defb  N_G5,N_REST,N_C3
        defb  N_F5,N_F2,N_F3
        defb  N_E5,N_REST,N_F3
        defb  N_D5,N_C3,N_F3
        defb  N_C5,N_REST,N_F3
        defb  N_B4,N_G2,N_G3
        defb  N_D5,N_A2,N_G3
        defb  N_G5,N_B2,N_G3
        defb  N_C5,N_C3,N_G3

AYMusicPattern7:
        defb  N_A4,N_A2,N_A3
        defb  N_CS5,N_REST,N_A3
        defb  N_E5,N_E3,N_A3
        defb  N_A5,N_REST,N_A3
        defb  N_GS5,N_E2,N_E3
        defb  N_E5,N_REST,N_E3
        defb  N_B4,N_B2,N_E3
        defb  N_GS5,N_REST,N_E3
        defb  N_A4,N_F2,N_F3
        defb  N_C5,N_REST,N_F3
        defb  N_F5,N_C3,N_F3
        defb  N_A5,N_REST,N_F3
        defb  N_G5,N_G2,N_G3
        defb  N_D5,N_REST,N_G3
        defb  N_B4,N_D3,N_G3
        defb  N_G4,N_REST,N_G3

;-------------------------------------------------------------------------------
; The vector table covers every possible byte supplied by the floating bus.
; Each vector resolves to 0xBFBF, where the handler is assembled.
        org   0xBE00
AYMusicIM2VectorTable:
        defs  257,0xBF

        org   0xBFBF
AYMusicIM2Handler:
        push  af
        push  bc
        push  de
        push  hl
        call  AYMusicTick
        pop   hl
        pop   de
        pop   bc
        pop   af
        ei
        reti
;-------------------------------------------------------------------------------
