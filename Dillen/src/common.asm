;-------------------------------------------------------------------------------
; BEGIN - ClearScreenToBlack
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
; END - ClearScreenToBlack
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - Print
; Print text to screen.
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
; END - Print
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PrintChar
; Print char to screen.
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
; END - PrintChar
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawChar
; Draw char to screen.
; HL - address in VRAM
; DE - address of character data
DrawChar:
        ld    b,8
.DrawChar1:
        ld    a,(de)
        ld    (hl),a
        call  DownHL
        inc   de
        djnz  .DrawChar1
        ret
; END - DrawChar
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - EfectiveClearScreen
; Effective screen cleaning.
EfectiveClearScreen:
        ld    b,8
.EfectiveClearScreen1:
        push  bc
        ld    hl,22527
        ld    c,192
.EfectiveClearScreen2:
        ld    b,32
        or    a
.EfectiveClearScreen3:
        sla   (hl)
        dec   hl
        djnz  .EfectiveClearScreen3
        dec   c
        jr    nz,.EfectiveClearScreen2
        ld    b,1
.EfectiveClearScreen4:
        halt
        djnz  .EfectiveClearScreen4
        pop bc
        djnz  .EfectiveClearScreen1
        ret
; END - EfectiveClearScreen
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - Delay
; Waiting for (BC*(1/50)) delay.
; BC - Contains how many tacts must be doing for continue (50 tacts == 1 sec.).
Delay:
        halt
        dec   bc
        ld    a,b
        or    c
        jr  nz,Delay
; END - Delay
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetScreenAttributes
; Setting for attributes to custom color.
; A - Attribute color number.
SetScreenAttributes:
        ld    hl,22528
        ld    de,22529
        ld    bc,767
        ld    (hl),a
        ldir
        ret
; END - SetScreenAttributes
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - Random8bit
; 8-bit random number
; HL - Address of the number.
Random8bit:
        ld a, (hl)
        ld b, a

        rrca
        rrca
        rrca
        xor   0x1f

        add   a, b
        sbc   a, 255

        ld    (hl), a
        ret
; END - Random8bit
;-------------------------------------------------------------------------------
