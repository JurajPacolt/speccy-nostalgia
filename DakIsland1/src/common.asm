;###############################################################################
;##### Small procedures the whole game uses: cleaning the screen, writing #######
;##### with the gothic font, waiting and a random number. ######################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - ClearScreenToBlack
; Everything black, the border too.
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
; Write a text, ended with a zero, character by character.
; IX - address of the text
; HL - address of the font
; DE - address in the VRAM of the first character
Print:
        ld    a,(ix+0)
        or    a
        ret   z ; End of the text.
        push  hl
        push  de
        call  PrintChar
        pop   de
        pop   hl
        inc   de
        inc   ix
        jr    Print
; END - Print
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PrintChar
; Write one character of the gothic font.
; A - the character
; HL - address of the font
; DE - address in the VRAM
PrintChar:
        sub   32 ; The font begins with the space.
        ld    b,0
        ld    c,a
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc
        add   hl,bc ; Every character has eight bytes.
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
; Put the eight bytes of one character on the screen.
; HL - address in the VRAM
; DE - address of the data of the character
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
; BEGIN - Delay
; Wait for BC frames, fifty of them are one second.
; BC - number of the frames
Delay:
        halt
        dec   bc
        ld    a,b
        or    c
        jr    nz,Delay
        ret
; END - Delay
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetScreenAttributes
; One colour for the whole screen.
; A - the attribute
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
; The next number of a random row.
; HL - address of the number, it is changed in place
; return A - the new number
Random8bit:
        ld    a,(hl)
        ld    b,a

        rrca
        rrca
        rrca
        xor   0x1f

        add   a,b
        sbc   a,255

        ld    (hl),a
        ret
; END - Random8bit
;-------------------------------------------------------------------------------
