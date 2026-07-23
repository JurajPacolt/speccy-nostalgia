;###############################################################################
;##### AY title/game music, start fanfare and IM2 player. ######################
;###############################################################################

; The tune runs at 150 BPM on a 50 Hz PAL machine. One step takes 5 frames and
; equals a sixteenth note, one pattern of 16 steps equals one bar. The 32-bar
; song therefore loops after 32*16*5/50 = 51.2 seconds.
;
; The song is a brisk country two-step in C major with an AABA shape:
;   bars  1..8   A  section, ends on the dominant then on the tonic
;   bars  9..16  A  section again, closed with a run that opens the bridge
;   bars 17..24  B  section in A minor, the contrasting middle
;   bars 25..32  A  section once more, which is also the loop point
; The melody of the A section is built from a single syncopated motif (a dotted
; C5-B4 followed by A4-G4), so the ear recognizes it every time it returns.
;
; Four things carry the drive: the melody is accented off the beat, plucked notes
; decay and then pick up a vibrato and a tremolo, the bass is a hardware envelope
; buzz, and the chord channel chops on the second eighth of each beat.

AY_REGISTER_PORT       equ 65533 ; 0xFFFD
AY_DATA_PORT           equ 49149 ; 0xBFFD
AY_FRAMES_PER_STEP     equ 5
AY_STEPS_PER_PATTERN   equ 16
AY_ORDER_LENGTH        equ 32
AY_TITLE_ORDER_LENGTH  equ 8
AY_VICTORY_ORDER_LENGTH equ 8
AY_CHORD_MINOR         equ 128

AY_SONG_GAME           equ 0
AY_SONG_TITLE          equ 1
AY_SONG_VICTORY        equ 2

; Keep the IM2 table and handler well above the growing game/music data. Every
; byte in the 257-byte table points to the same 0xF1F1 handler address.
AY_IM2_VECTOR_HIGH     equ 0xF0
AY_IM2_HANDLER_BYTE    equ 0xF1
AY_IM2_VECTOR_ADDRESS  equ 0xF000
AY_IM2_HANDLER_ADDRESS equ 0xF1F1

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

; A step holding this value keeps the previous note ringing instead of playing a
; new one. Longer note values are written as a note followed by N_HOLD steps.
N_HOLD equ 127

; Added to a melody note it plays that note louder. The accents are what make
; the line snap.
AY_ACCENT equ 128

; A repeating sawtooth. Run at the pitch of the bass note it turns channel B into
; the classic AY buzz bass instead of a plain square wave.
AY_ENVELOPE_SAW        equ 8
AY_ENVELOPE_VOLUME     equ 16 ; Channel volume bit that hands the level over to it.

; Frames a melody note has to ring before the vibrato and the tremolo set in.
AY_SHIMMER_DELAY       equ 8

;-------------------------------------------------------------------------------
; InitAYMusicIM2 - start the title tune and switch to the music IM2 handler.
; EntryPoint already disabled interrupts before this routine is called.
InitAYMusicIM2:
        call  AYMusicStartTitleSong
        ld    a,AY_IM2_VECTOR_HIGH
        ld    i,a
        im    2
        ei
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Select the slower D-minor title tune and restart the shared player.
AYMusicStartTitleSong:
        ld    a,AY_SONG_TITLE
        ld    (AYMusicSong),a
        ld    a,7
        ld    (AYMusicFramesPerStep),a
        jp    AYMusicInit
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Select and restart the original in-game country tune.
AYMusicStartGameSong:
        ld    a,AY_SONG_GAME
        ld    (AYMusicSong),a
        ld    a,AY_FRAMES_PER_STEP
        ld    (AYMusicFramesPerStep),a
        jp    AYMusicInit
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Select the bright victory march used by both ending screens.
AYMusicStartVictorySong:
        ld    a,AY_SONG_VICTORY
        ld    (AYMusicSong),a
        ld    a,6
        ld    (AYMusicFramesPerStep),a
        jp    AYMusicInit
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicInit:
        xor   a
        ld    (AYMusicEnabled),a
        ld    (AYMusicOrderIndex),a
        ld    (AYMusicStepIndex),a
        ld    (AYMusicArpeggioPhase),a
        ld    (AYMusicMelodyNote),a
        ld    (AYMusicMelodyAccent),a
        ld    (AYMusicMelodyAge),a
        ld    (AYMusicMelodyTie),a
        ld    (AYMusicBassNote),a
        ld    (AYMusicBassAge),a
        ld    (AYMusicChord),a
        ld    (AYMusicDrumType),a
        ld    (AYMusicDrumTimer),a

        ld    a,4
        ld    (AYMusicChordVolume),a

        ld    a,1 ; The first interrupt immediately loads step zero.
        ld    (AYMusicStepTimer),a

        ld    e,0
        ld    a,8
        call  AYMusicWriteRegister
        ld    a,9
        call  AYMusicWriteRegister
        ld    a,10
        call  AYMusicWriteRegister
        ld    e,AY_ENVELOPE_SAW ; The buzz shape the bass runs on.
        ld    a,13
        call  AYMusicWriteRegister
        ld    e,56 ; Tone A/B/C on, noise A/B/C off.
        ld    a,7
        call  AYMusicWriteRegister

        ld    a,1
        ld    (AYMusicEnabled),a
        ret
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

        ld    a,(AYMusicFramesPerStep)
        ld    (AYMusicStepTimer),a
        call  AYMusicLoadStep

.Render:
        call  AYMusicRenderMelodyAndBass
        call  AYMusicRenderChordOrDrum
        jp    AYMusicAgeNotes
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Count the frames a note has been ringing; the renderers turn that into a decay.
AYMusicAgeNotes:
        ld    hl,AYMusicMelodyAge
        ld    a,(hl)
        cp    60 ; Saturate, no note is ever that long.
        jr    nc,.Bass
        inc   (hl)
.Bass:
        ld    hl,AYMusicBassAge
        ld    a,(hl)
        cp    60
        ret   nc
        inc   (hl)
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Load the melody note, bass note and chord of the current pattern step.
AYMusicLoadStep:
        ld    a,(AYMusicOrderIndex)
        ld    e,a
        ld    d,0
        ld    hl,AYMusicOrder
        ld    a,(AYMusicSong)
        or    a
        jr    z,.OrderReady
        cp    AY_SONG_TITLE
        jr    nz,.VictoryOrder
        ld    hl,AYTitleMusicOrder
        jr    .OrderReady
.VictoryOrder:
        ld    hl,AYVictoryMusicOrder
.OrderReady:
        add   hl,de
        ld    a,(hl) ; Pattern number.
        add   a,a
        ld    e,a
        ld    d,0
        ld    hl,AYMusicPatternTable
        push  af
        ld    a,(AYMusicSong)
        or    a
        jr    z,.PatternTableReady
        cp    AY_SONG_TITLE
        jr    nz,.VictoryPatternTable
        ld    hl,AYTitleMusicPatternTable
        jr    .PatternTableReady
.VictoryPatternTable:
        ld    hl,AYVictoryMusicPatternTable
.PatternTableReady:
        pop   af
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
        cp    N_HOLD
        jr    z,.MelodyHeld ; A held step keeps the note that is already playing.
        ld    c,a
        and   127
        ld    (AYMusicMelodyNote),a
        ld    a,c
        and   AY_ACCENT
        ld    (AYMusicMelodyAccent),a
        xor   a
        ld    (AYMusicMelodyAge),a ; A new note starts at full volume.
.MelodyHeld:
        inc   hl
        ld    a,(hl)
        cp    N_HOLD
        jr    z,.BassHeld
        ld    (AYMusicBassNote),a
        xor   a
        ld    (AYMusicBassAge),a
.BassHeld:
        inc   hl
        ld    a,(hl)
        ld    (AYMusicChord),a
        xor   a
        ld    (AYMusicArpeggioPhase),a ; Start every picking figure on its root.

        ; The accompaniment chops: quiet on the beat, loud on the second eighth.
        ld    a,(AYMusicStepIndex)
        and   2
        ld    a,4
        jr    z,.ChordVolumeReady
        ld    a,8
.ChordVolumeReady:
        ld    (AYMusicChordVolume),a

        ; Peek at the melody of the next step so a note that is held over is not
        ; re-articulated by the short release at the end of the current step.
        inc   hl ; HL = melody byte of the next step.
        ld    d,0
        ld    a,(AYMusicStepIndex)
        cp    AY_STEPS_PER_PATTERN-1
        jr    z,.TieReady ; Notes never hold across a bar line.
        ld    a,(hl)
        cp    N_HOLD
        jr    nz,.TieReady
        inc   d
.TieReady:
        ld    a,d
        ld    (AYMusicMelodyTie),a

        call  AYMusicLoadRhythm

        ld    a,(AYMusicStepIndex)
        inc   a
        cp    AY_STEPS_PER_PATTERN
        jr    c,.StoreStep

        xor   a
        ld    (AYMusicStepIndex),a
        ld    a,(AYMusicOrderIndex)
        inc   a
        ld    b,AY_ORDER_LENGTH
        ld    c,a
        ld    a,(AYMusicSong)
        or    a
        jr    z,.OrderLengthReady
        cp    AY_SONG_TITLE
        jr    nz,.VictoryOrderLength
        ld    b,AY_TITLE_ORDER_LENGTH
        jr    .OrderLengthReady
.VictoryOrderLength:
        ld    b,AY_VICTORY_ORDER_LENGTH
.OrderLengthReady:
        ld    a,c
        cp    b
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
        ld    a,(AYMusicSong)
        or    a
        jr    z,.RhythmOrderReady
        cp    AY_SONG_TITLE
        jr    nz,.VictoryRhythmOrder
        ld    hl,AYTitleMusicRhythmOrder
        jr    .RhythmOrderReady
.VictoryRhythmOrder:
        ld    hl,AYVictoryMusicRhythmOrder
.RhythmOrderReady:
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
; The melody is plucked: loud at the attack, decaying with the note age, and once
; it has been ringing for a while it starts to shimmer with vibrato and tremolo.
; The bass is a buzz: channel B hands its level to the hardware envelope.
AYMusicRenderMelodyAndBass:
        ld    a,(AYMusicMelodyNote)
        call  AYMusicNotePeriod
        ld    a,h
        or    l
        jr    z,.WriteMelodyTone
        call  AYMusicApplyVibrato
.WriteMelodyTone:
        ld    e,l
        xor   a
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,1
        call  AYMusicWriteRegister

        ld    a,(AYMusicMelodyNote)
        or    a
        jr    z,.MelodySilent

        ld    a,(AYMusicMelodyAge)
        srl   a
        ld    c,a
        ld    a,(AYMusicMelodyAccent)
        or    a
        ld    a,13
        jr    z,.MelodyDecay
        ld    a,15 ; An accented note snaps out above the rest.
.MelodyDecay:
        sub   c
        jr    c,.MelodySustain
        cp    9
        jr    nc,.MelodyDecayed
.MelodySustain:
        ld    a,9
.MelodyDecayed:
        ld    e,a

        ld    a,(AYMusicMelodyAge)
        cp    AY_SHIMMER_DELAY
        jr    c,.MelodyRelease
        and   4 ; Tremolo: the level flutters four frames on, four frames off.
        jr    z,.MelodyRelease
        dec   e

.MelodyRelease:
        ld    a,(AYMusicStepTimer)
        cp    1
        jr    nz,.MelodyVolume
        ld    a,(AYMusicMelodyTie)
        or    a
        jr    nz,.MelodyVolume ; A held note rings on without a gap.
        ld    e,4 ; A short release articulates the note that follows.
        jr    .MelodyVolume

.MelodySilent:
        ld    e,0
.MelodyVolume:
        ld    a,8
        call  AYMusicWriteRegister

        ld    a,(AYMusicBassNote)
        or    a
        jr    z,.BassSilent
        call  AYMusicNotePeriod
        push  hl
        ld    e,l
        ld    a,2
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,3
        call  AYMusicWriteRegister
        pop   hl

        ; The envelope runs one full sawtooth per wave of the note, so it buzzes
        ; at the pitch of the bass: its period is the tone period divided by 16.
        srl   h
        rr    l
        srl   h
        rr    l
        srl   h
        rr    l
        srl   h
        rr    l
        ld    e,l
        ld    a,11
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,12
        call  AYMusicWriteRegister

        ld    a,(AYMusicBassAge)
        or    a
        jr    nz,.BassBuzzing
        ld    e,AY_ENVELOPE_SAW ; Restart the sawtooth, but only on the attack.
        ld    a,13
        call  AYMusicWriteRegister
.BassBuzzing:
        ld    e,AY_ENVELOPE_VOLUME
        ld    a,9
        jp    AYMusicWriteRegister

.BassSilent:
        ld    hl,0
        ld    e,l
        ld    a,2
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,3
        call  AYMusicWriteRegister
        ld    e,0
        ld    a,9
        jp    AYMusicWriteRegister
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; HL = tone period of the melody. Detunes it by one vibrato unit, a 64th of the
; period, following a slow triangle. The attack of the note is left clean.
AYMusicApplyVibrato:
        ld    a,(AYMusicMelodyAge)
        cp    AY_SHIMMER_DELAY
        ret   c
        srl   a ; One LFO step every two frames: a full sweep takes 16 frames.
        and   7
        ld    e,a
        ld    d,0
        push  hl
        ld    hl,AYMusicVibrato
        add   hl,de
        ld    a,(hl)
        pop   hl
        or    a
        ret   z
        ld    b,a ; B = signed LFO step.

        ld    a,l ; C = period / 64.
        rlca
        rlca
        and   3
        ld    c,a
        ld    a,h
        add   a,a
        add   a,a
        add   a,c
        ld    c,a
        or    a
        ret   z ; Too high a note to detune by a whole period unit.

        ld    a,b
        or    a
        jp    p,.Sharp
        neg
        ld    b,a
.Flat:
        ld    a,l
        sub   c
        ld    l,a
        ld    a,h
        sbc   a,0
        ld    h,a
        djnz  .Flat
        ret
.Sharp:
        ld    a,l
        add   a,c
        ld    l,a
        ld    a,h
        adc   a,0
        ld    h,a
        djnz  .Sharp
        ret
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
        ld    e,14
        ld    a,(AYMusicDrumTimer)
        cp    2
        jr    z,.VolumeReady
        ld    e,10
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
        add   a,2
        ld    e,a ; Volumes 14, 10, 6.
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
        ld    e,7
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
        add   a,3 ; Volumes 9, 7, 5.
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
        ld    e,12
        ld    a,(AYMusicDrumTimer)
        cp    2
        jr    z,.VolumeReady
        ld    e,8
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
        ld    a,(AYMusicChordVolume) ; Chops off the beat, stays under the melody.
        ld    e,a
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
; Play a short rising three-voice fanfare while the title remains visible.
; The background player is disabled, but IM2 remains active so HALT still gives
; exact 50 Hz timing. Each data item is duration, notes A/B/C and volume.
AYMusicPlayStartFanfare:
        ld    ix,AYMusicStartFanfareData
        jp    AYMusicPlayFanfare

; Play the longer triumphant fanfare when Dillen clears the castle door.
AYMusicPlayVictoryFanfare:
        ld    ix,AYMusicVictoryFanfareData

AYMusicPlayFanfare:
        xor   a
        ld    (AYMusicEnabled),a
        call  AYMusicSilence

        ld    e,56 ; Tone A/B/C on, all noise off.
        ld    a,7
        call  AYMusicWriteRegister

.NextFanfareChord:
        ld    a,(ix+0)
        or    a
        jr    z,.FanfareDone
        ld    b,a

        ld    a,(ix+1)
        call  AYMusicWriteFanfareToneA
        ld    a,(ix+2)
        call  AYMusicWriteFanfareToneB
        ld    a,(ix+3)
        call  AYMusicWriteFanfareToneC

        ld    e,(ix+4)
        ld    a,8
        call  AYMusicWriteRegister
        ld    e,(ix+4)
        ld    a,9
        call  AYMusicWriteRegister
        ld    e,(ix+4)
        ld    a,10
        call  AYMusicWriteRegister

.FanfareWait:
        halt
        djnz  .FanfareWait

        ld    de,5
        add   ix,de
        jr    .NextFanfareChord

.FanfareDone:
        jp    AYMusicSilence
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicWriteFanfareToneA:
        call  AYMusicNotePeriod
        ld    e,l
        xor   a
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,1
        jp    AYMusicWriteRegister

AYMusicWriteFanfareToneB:
        call  AYMusicNotePeriod
        ld    e,l
        ld    a,2
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,3
        jp    AYMusicWriteRegister

AYMusicWriteFanfareToneC:
        call  AYMusicNotePeriod
        ld    e,l
        ld    a,4
        call  AYMusicWriteRegister
        ld    e,h
        ld    a,5
        jp    AYMusicWriteRegister
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Silence every channel and disconnect tone/noise until a song starts again.
AYMusicSilence:
        ld    e,0
        ld    a,8
        call  AYMusicWriteRegister
        ld    a,9
        call  AYMusicWriteRegister
        ld    a,10
        call  AYMusicWriteRegister
        ld    e,63
        ld    a,7
        jp    AYMusicWriteRegister
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
AYMusicEnabled:
        defb  0
AYMusicSong:
        defb  AY_SONG_TITLE
AYMusicFramesPerStep:
        defb  7
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
AYMusicMelodyAccent:
        defb  0
AYMusicMelodyAge:
        defb  0
AYMusicMelodyTie:
        defb  0
AYMusicBassNote:
        defb  0
AYMusicBassAge:
        defb  0
AYMusicChord:
        defb  0
AYMusicChordVolume:
        defb  4
AYMusicDrumType:
        defb  0
AYMusicDrumTimer:
        defb  0
;-------------------------------------------------------------------------------

; One slow triangle sweep of the melody vibrato, in vibrato units.
AYMusicVibrato:
        defb  0,1,1,0,0,-1,-1,0
;-------------------------------------------------------------------------------

; AY periods for C2..B5 at the 1.7734 MHz ZX Spectrum AY clock.
AYMusicNotePeriods:
        defw  1695,1599,1510,1425,1345,1270,1198,1131,1068,1008,951,898
        defw  847,800,755,712,673,635,599,566,534,504,476,449
        defw  424,400,377,356,336,317,300,283,267,252,238,224
        defw  212,200,189,178,168,159,150,141,133,126,119,112

; A compact major-chord rise: C, F, G and the final C resolution. Short silent
; gaps articulate the first three hits; the last chord rings long enough to
; bridge cleanly into the game.
AYMusicStartFanfareData:
        defb  5,N_C4,N_E4,N_G4,13
        defb  2,N_REST,N_REST,N_REST,0
        defb  5,N_F4,N_A4,N_C5,13
        defb  2,N_REST,N_REST,N_REST,0
        defb  6,N_G4,N_B4,N_D5,14
        defb  2,N_REST,N_REST,N_REST,0
        defb  20,N_C5,N_E5,N_G5,15
        defb  0

; Thirty-two bars = 51.2 seconds. A A B A, where the second A closes with the
; run that leads into the bridge.
AYMusicOrder:
        defb  0,1,2,3,   0,4,5,6
        defb  0,1,2,3,   0,4,5,7
        defb  8,9,10,11, 8,9,10,11
        defb  0,1,2,3,   0,4,5,6

; A separate rhythm order lets the repeated melody return with a different feel:
; the two-step opens, the train beat drives the repeat, the bridge is syncopated
; and every eight-bar phrase ends with a fill.
AYMusicRhythmOrder:
        defb  0,0,2,0, 0,0,2,4
        defb  1,1,2,1, 1,1,2,4
        defb  2,2,1,2, 2,2,1,4
        defb  1,0,2,1, 1,2,1,5

; The title has its own eight-bar order and restrained percussion. At seven
; frames per step it loops after 17.92 seconds, clearly apart from the game tune.
AYTitleMusicOrder:
        defb  0,1,2,3, 0,1,3,0

AYTitleMusicRhythmOrder:
        defb  6,6,6,6, 6,6,6,6

; An eight-bar C-major victory march, about 15.36 seconds per loop.
AYVictoryMusicOrder:
        defb  0,1,0,2, 0,1,2,3

AYVictoryMusicRhythmOrder:
        defb  7,7,7,7, 7,7,7,7

AYMusicRhythmTable:
        defw  AYMusicRhythm0,AYMusicRhythm1,AYMusicRhythm2
        defw  AYMusicRhythm3,AYMusicRhythm4,AYMusicRhythm5
        defw  AYTitleMusicRhythm,AYVictoryMusicRhythm

; 0: driving two-step with a kick pushed onto the "and" of two.
AYMusicRhythm0:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_KICK
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_HAT

; 1: train beat, hats on every sixteenth.
AYMusicRhythm1:
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_SNARE

; 2: syncopated groove, the kicks fall between the beats.
AYMusicRhythm2:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_KICK
        defb  AY_DRUM_SNARE,AY_DRUM_HAT,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_NONE,AY_DRUM_KICK
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_HAT

; 3: sparse breakdown with an open hat.
AYMusicRhythm3:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_NONE,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_OPEN_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_KICK

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

; A distant pulse for the title: two low impacts and two quiet points of light.
AYTitleMusicRhythm:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_NONE,AY_DRUM_NONE
        defb  AY_DRUM_NONE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_TOM,AY_DRUM_NONE,AY_DRUM_NONE,AY_DRUM_NONE
        defb  AY_DRUM_NONE,AY_DRUM_NONE,AY_DRUM_OPEN_HAT,AY_DRUM_NONE

; A firm four-beat march for the win tune, with a small tom lift into each loop.
AYVictoryMusicRhythm:
        defb  AY_DRUM_KICK,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_HAT,AY_DRUM_NONE
        defb  AY_DRUM_KICK,AY_DRUM_HAT,AY_DRUM_KICK,AY_DRUM_HAT
        defb  AY_DRUM_SNARE,AY_DRUM_NONE,AY_DRUM_TOM,AY_DRUM_SNARE

AYMusicPatternTable:
        defw  AYMusicPattern0,AYMusicPattern1,AYMusicPattern2,AYMusicPattern3
        defw  AYMusicPattern4,AYMusicPattern5,AYMusicPattern6,AYMusicPattern7
        defw  AYMusicPattern8,AYMusicPattern9,AYMusicPattern10,AYMusicPattern11

AYTitleMusicPatternTable:
        defw  AYTitleMusicPattern0,AYTitleMusicPattern1
        defw  AYTitleMusicPattern2,AYTitleMusicPattern3

AYVictoryMusicPatternTable:
        defw  AYVictoryMusicPattern0,AYVictoryMusicPattern1
        defw  AYVictoryMusicPattern2,AYVictoryMusicPattern3

; Every step: melody note, bass note, chord root/type. The bass plays the country
; root-fifth "boom" on the four beats and walks into the next chord on the last
; eighth of the bar; the melody moves in dotted eighths, eighths and sixteenths.

; 0: A section, bars 1 and 5 over C. The motif: a dotted C5 tipped by B4, then a
; falling A4-G4. Everything else in the A section answers this bar.
AYMusicPattern0:
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_B4,          N_REST,N_C3
        defb  N_A4+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_G4,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_A4+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_G4,          N_REST,N_C3
        defb  N_E4+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_G4,          N_E2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3

; 1: A section, bar 2 over F. The same rhythm, answered a step lower.
AYMusicPattern1:
        defb  N_A4+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_G4,          N_REST,N_F3
        defb  N_F4+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_A4,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_C5+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_A4,          N_REST,N_F3
        defb  N_G4+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_F4,          N_D2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3

; 2: A section, bar 3 over C. The motif again, an octave of energy higher.
AYMusicPattern2:
        defb  N_E5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_D5,          N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_G4,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_D5,          N_REST,N_C3
        defb  N_E5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_C5,          N_A2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3

; 3: A section, bar 4 over G. Half cadence, the question stays open on D.
AYMusicPattern3:
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_C5,          N_REST,N_G3
        defb  N_B4+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_G4,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_A4+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_HOLD,        N_B2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3

; 4: A section, bar 6 over F. Climbs to F5 and rolls back down.
AYMusicPattern4:
        defb  N_A4+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_C5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_A4+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_C5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_F5+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_E5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_D5+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_C5,          N_A2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3

; 5: A section, bar 7 over G. Pushes forward onto the leading tone B.
AYMusicPattern5:
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_G4+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_E5,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_B2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3

; 6: A section, bar 8 over C. Full cadence, capped by a bright G5.
AYMusicPattern6:
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_B4,          N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_G5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_B2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3

; 7: A section, bar 16 over C. Ends with a sixteenth run that falls into the
; bridge.
AYMusicPattern7:
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_B4,          N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_G5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_E5+AY_ACCENT,N_G2,  N_C3
        defb  N_D5,          N_HOLD,N_C3
        defb  N_C5,          N_G2,  N_C3
        defb  N_B4,          N_HOLD,N_C3

; 8: bridge, bar 1 over A minor. The same shape as the motif, but darker and
; running up the whole chord.
AYMusicPattern8:
        defb  N_A4+AY_ACCENT,N_A2,  N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_A3+AY_CHORD_MINOR
        defb  N_C5,          N_REST,N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_REST,N_A3+AY_CHORD_MINOR
        defb  N_E5+AY_ACCENT,N_E3,  N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_A3+AY_CHORD_MINOR
        defb  N_A5,          N_REST,N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_REST,N_A3+AY_CHORD_MINOR
        defb  N_G5+AY_ACCENT,N_A2,  N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_A3+AY_CHORD_MINOR
        defb  N_E5,          N_REST,N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_REST,N_A3+AY_CHORD_MINOR
        defb  N_C5+AY_ACCENT,N_E3,  N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_A3+AY_CHORD_MINOR
        defb  N_E5,          N_G2,  N_A3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_A3+AY_CHORD_MINOR

; 9: bridge, bar 2 over F. The highest point of the whole song.
AYMusicPattern9:
        defb  N_A4+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_C5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_F5+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_A5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_G5+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_F5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_E5+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_C5,          N_D2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3

; 10: bridge, bar 3 over C.
AYMusicPattern10:
        defb  N_G4+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_C5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_E5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_G5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_E5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_C5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_G4+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_B4,          N_A2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3

; 11: bridge, bar 4 over G. Ends on B, which pulls the music back to the A part.
AYMusicPattern11:
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_G5,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_A4+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_B4,          N_B2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3

; The title tune is a slower, moonlit D-minor theme. Its broad held notes and
; sparse bass make it deliberately calmer and darker than the in-game two-step.

; Title 0: D minor establishes the descending D5-A4-F4 motif.
AYTitleMusicPattern0:
        defb  N_D5+AY_ACCENT,N_D2,  N_D3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_D3+AY_CHORD_MINOR
        defb  N_HOLD,        N_REST,N_D3+AY_CHORD_MINOR
        defb  N_A4,          N_REST,N_D3+AY_CHORD_MINOR
        defb  N_F4+AY_ACCENT,N_A2,  N_D3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_D3+AY_CHORD_MINOR
        defb  N_A4,          N_REST,N_D3+AY_CHORD_MINOR
        defb  N_HOLD,        N_REST,N_D3+AY_CHORD_MINOR
        defb  N_C5+AY_ACCENT,N_D2,  N_D3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_D3+AY_CHORD_MINOR
        defb  N_A4,          N_REST,N_D3+AY_CHORD_MINOR
        defb  N_F4,          N_REST,N_D3+AY_CHORD_MINOR
        defb  N_D5+AY_ACCENT,N_A2,  N_D3+AY_CHORD_MINOR
        defb  N_HOLD,        N_HOLD,N_D3+AY_CHORD_MINOR
        defb  N_C5,          N_REST,N_D3+AY_CHORD_MINOR
        defb  N_A4,          N_HOLD,N_D3+AY_CHORD_MINOR

; Title 1: B-flat major opens the theme into a warmer answer.
AYTitleMusicPattern1:
        defb  N_F5+AY_ACCENT,N_AS2, N_AS2
        defb  N_HOLD,        N_HOLD,N_AS2
        defb  N_HOLD,        N_REST,N_AS2
        defb  N_D5,          N_REST,N_AS2
        defb  N_AS4+AY_ACCENT,N_F2, N_AS2
        defb  N_HOLD,        N_HOLD,N_AS2
        defb  N_D5,          N_REST,N_AS2
        defb  N_HOLD,        N_REST,N_AS2
        defb  N_F5+AY_ACCENT,N_AS2, N_AS2
        defb  N_HOLD,        N_HOLD,N_AS2
        defb  N_E5,          N_REST,N_AS2
        defb  N_D5,          N_REST,N_AS2
        defb  N_C5+AY_ACCENT,N_F2,  N_AS2
        defb  N_HOLD,        N_HOLD,N_AS2
        defb  N_D5,          N_REST,N_AS2
        defb  N_HOLD,        N_HOLD,N_AS2

; Title 2: C major lifts the middle of the phrase before the dominant arrives.
AYTitleMusicPattern2:
        defb  N_G5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_D5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_C5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_E5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_D5,          N_REST,N_C3
        defb  N_C5,          N_REST,N_C3
        defb  N_G4+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_C5,          N_REST,N_C3
        defb  N_HOLD,        N_HOLD,N_C3

; Title 3: A major uses C-sharp as the bright leading colour and points back
; toward D minor at the next bar.
AYTitleMusicPattern3:
        defb  N_E5+AY_ACCENT,N_A2,  N_A3
        defb  N_HOLD,        N_HOLD,N_A3
        defb  N_CS5,         N_REST,N_A3
        defb  N_HOLD,        N_REST,N_A3
        defb  N_A4+AY_ACCENT,N_E3,  N_A3
        defb  N_HOLD,        N_HOLD,N_A3
        defb  N_B4,          N_REST,N_A3
        defb  N_CS5,         N_REST,N_A3
        defb  N_E5+AY_ACCENT,N_A2,  N_A3
        defb  N_HOLD,        N_HOLD,N_A3
        defb  N_CS5,         N_REST,N_A3
        defb  N_B4,          N_REST,N_A3
        defb  N_A4+AY_ACCENT,N_E3,  N_A3
        defb  N_HOLD,        N_HOLD,N_A3
        defb  N_CS5,         N_REST,N_A3
        defb  N_HOLD,        N_HOLD,N_A3

;-------------------------------------------------------------------------------
; The ordinary game and music data must never grow into the reserved IM2 area.
        assert $ <= AY_IM2_VECTOR_ADDRESS

; The vector table covers every possible byte supplied by the floating bus.
; Each vector resolves to AY_IM2_HANDLER_ADDRESS, where the handler is assembled.
        org   AY_IM2_VECTOR_ADDRESS
AYMusicIM2VectorTable:
        defs  257,AY_IM2_HANDLER_BYTE

; The vector table ends at 0xF101. Its otherwise unused 240-byte gap before the
; fixed handler holds the 233 bytes used only by the victory fanfare and song.
; None of these bytes can be read as an IM2 vector.
AYMusicVictoryFanfareData:
        defb  4,N_C4,N_E4,N_G4,13
        defb  4,N_E4,N_G4,N_C5,13
        defb  6,N_G4,N_C5,N_E5,14
        defb  8,N_C5,N_E5,N_G5,15
        defb  2,N_REST,N_REST,N_REST,0
        defb  6,N_A4,N_C5,N_F5,13
        defb  6,N_B4,N_D5,N_G5,14
        defb  20,N_C5,N_E5,N_G5,15
        defb  0

; The victory song is an emphatic C-major march. Rising triads answer the
; darker title theme and turn the ending into a clear musical reward.

; Victory 0: the main C-major trumpet-like call.
AYVictoryMusicPattern0:
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_G5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_E5,          N_HOLD,N_C3
        defb  N_G5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_E5+AY_ACCENT,N_G2,  N_C3
        defb  N_D5,          N_HOLD,N_C3
        defb  N_C5,          N_B2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3

; Victory 1: F major broadens the answer and reaches the high A.
AYVictoryMusicPattern1:
        defb  N_F5+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_A5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_C5+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_F5,          N_REST,N_F3
        defb  N_HOLD,        N_REST,N_F3
        defb  N_A5+AY_ACCENT,N_F2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_G5,          N_REST,N_F3
        defb  N_F5,          N_REST,N_F3
        defb  N_E5+AY_ACCENT,N_C3,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3
        defb  N_C5,          N_A2,  N_F3
        defb  N_HOLD,        N_HOLD,N_F3

; Victory 2: G major climbs to B5 and drives into the final cadence.
AYVictoryMusicPattern2:
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_G5,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_B5+AY_ACCENT,N_D3,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_A5,          N_REST,N_G3
        defb  N_G5,          N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_G2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3
        defb  N_G5,          N_REST,N_G3
        defb  N_HOLD,        N_REST,N_G3
        defb  N_D5+AY_ACCENT,N_D3,  N_G3
        defb  N_C5,          N_HOLD,N_G3
        defb  N_B4,          N_B2,  N_G3
        defb  N_HOLD,        N_HOLD,N_G3

; Victory 3: a full C-major resolution that settles before the loop repeats.
AYVictoryMusicPattern3:
        defb  N_E5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_G5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_G2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_G5,          N_REST,N_C3
        defb  N_C5+AY_ACCENT,N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3
        defb  N_E5,          N_REST,N_C3
        defb  N_HOLD,        N_REST,N_C3
        defb  N_G5+AY_ACCENT,N_G2,  N_C3
        defb  N_E5,          N_HOLD,N_C3
        defb  N_C5,          N_C2,  N_C3
        defb  N_HOLD,        N_HOLD,N_C3

        assert $ <= AY_IM2_HANDLER_ADDRESS

        org   AY_IM2_HANDLER_ADDRESS
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
