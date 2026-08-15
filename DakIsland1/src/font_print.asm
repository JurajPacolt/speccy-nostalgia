;###############################################################################
;##### Writing with the small font of the panel. Every character of it is #######
;##### only three pixels wide, so two of them fit in one character of the #######
;##### screen and a whole sentence fits in one row. ############################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - Print4x8 - Write a text with the small font. The pixels are mixed into
;                    what is there, so the place has to be erased before.
; IX - address of the text, it ends with a zero
; B - the character row of the screen (0 - 23)
; C - the place of the first character, counted in half characters (0 - 63)
Print4x8:
        ld    a,(ix+0)
        or    a
        ret   z ; End of the text.
        push  bc
        call  PrintChar4x8
        pop   bc
        inc   ix
        inc   c
        jr    Print4x8
; END - Print4x8
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PrintChar4x8 - Write one character of the small font.
; A - the character
; B - the character row of the screen
; C - the place of the character, in half characters
PrintChar4x8:
        ; The picture of the character.
        sub   32
        ld    l,a
        ld    h,0
        add   hl,hl
        add   hl,hl
        add   hl,hl ; Every character has eight bytes.
        ld    de,Font4x8
        add   hl,de
        push  hl

        ; Its place on the screen.
        push  bc
        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a ; Yos.
        ld    a,c
        srl   a ; Two characters are in one character of the screen.
        add   a,a
        add   a,a
        add   a,a
        ld    c,a ; Xos.
        call  ScreenAddr
        pop   bc
        ex    de,hl ; DE - the place on the screen.
        pop   hl ; HL - the picture of the character.

        bit   0,c
        jr    nz,_PC4_Right

        ; The character stands in the left half of the byte.
        ld    b,8
_PC4_LeftLine:
        ld    a,(de)
        or    (hl)
        ld    (de),a
        inc   hl
        call  DownDE
        djnz  _PC4_LeftLine
        ret

        ; The character stands in the right half of the byte.
_PC4_Right:
        ld    b,8
_PC4_RightLine:
        ld    a,(hl)
        rrca
        rrca
        rrca
        rrca ; The picture goes down into the low half of the byte.
        ld    c,a
        ld    a,(de)
        or    c
        ld    (de),a
        inc   hl
        call  DownDE
        djnz  _PC4_RightLine
        ret
; END - PrintChar4x8
;-------------------------------------------------------------------------------
