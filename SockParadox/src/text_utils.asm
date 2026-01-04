; Text output utilities
; Ponozkovy Paradox

;-------------------------------------------------------------------------------
; Print text to screen
; IX - address of the text
; HL - address of the font
; DE - address of VRAM, where we need put character
Print:
        ld    a,(ix+0)
        or    a
        ret   z
        push  hl
        push  de
        push  af
        call  PrintChar
        pop   af
        pop   de
        pop   hl
        inc   de
        inc   ix
        cp    a,0
        jr    Print
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Print char to screen
; HL - address of the font
; DE - address of VRAM, where we need put character
; A - ASCII character
PrintChar:
        sbc   a,32
        ld    b,0
        ld    c,a
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        ld    b,8
.PrintChar1:
        ld    a,(hl)
        ld    (de),a
        call  DownDE
        inc   hl
        djnz  .PrintChar1
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; DownDE - move DE one pixel line down
DownDE:
        inc   d
        ld    a,d
        and   7
        ret   nz
        ld    a,e
        add   a,32
        ld    e,a
        ret   c
        ld    a,d
        sub   8
        ld    d,a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Clear screen to black color
ClearScreenToBlack:
        ld    a,0
        call  SetScreenAttributes
        out   (254),a
        ld    hl,16384
        ld    de,16385
        ld    bc,6143
        ld    (hl),0
        ldir
        ld    a,7
        call  SetScreenAttributes
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Setting for attributes to custom color
; A - Attribute color number
SetScreenAttributes:
        ld    hl,22528
        ld    de,22529
        ld    bc,767
        ld    (hl),a
        ldir
        ret
;-------------------------------------------------------------------------------
