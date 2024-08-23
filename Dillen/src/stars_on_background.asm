;;;;; IT'S NEEDED TO COMPLETE ;;;;;

; Method for stars showing.
; IY - Address with data needed for this method:
;      0 ... cash for star bg
;      2 ... star state
;      There is needed 3 bytes of memory space.
; HL - VRAM Address for star position.
StarOnBackground:
        ; Interval for slower motion.
        ld    hl, _SOB_Interval
        inc   (hl)
        ld    a, (hl)
        cp    4
        ret   nz
        ld    (hl), 0

        ; TODO - Address for star position in VRAM.
        ld    hl, BORDER_START_ADDRESS+32+1

        ; Putting to cache data from VRAM.
        ld    de, _CacheForStarBg
        push  hl
        push  de
        ld    a, (hl)
        xor   a ; TODO doriesit lepsie cache, zatial nastavime na 0
        ld    (de), a
        call  DownHL
        ld    a, (hl)
        inc   de
        xor   a ; TODO doriesit lepsie cache, zatial nastavime na 0
        ld    (de), a
        pop   de
        pop   hl

        ; Obtaining state value.
        push  hl
        ld    hl, _StarState
        ld    c, (hl)
        ld    b, 0
        pop   hl

        ; Draw the start with her state.
        ld    ix, _StarsMotion
        add   ix, bc
        ld    a, (de)
        or    (ix+0)
        ld    (hl), a
        call  DownHL
        inc   de
        ld    a, (de)
        inc   ix
        or    (ix+0)
        ld    (hl), a

        ; Move state to next step.
        ld    hl, _StarState
        ld    a, (hl)
        add   a, 2
        ld    (hl), a
        cp    20
        jr    nz, _SOB_JumpToEnd
        ld    (hl), 0

_SOB_JumpToEnd:
        ret

_SOB_Interval:
        defb  0

_CacheForStarBg:
        defb  0, 0

_StarState:
        defb  0

_StarsMotion:
        defb  0, 0
        defb  0, 8
        defb  16, 8
        defb  24, 8
        defb  24, 24

        defb  24, 24
        defb  24, 8
        defb  16, 8
        defb  0, 8
        defb  0, 0
