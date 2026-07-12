
;###############################################################################
;##### Font 4x8 and her printing. Every character is only four pixels wide, #####
;##### so two characters are in one character of the screen. ###################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - Print4x8 - Print the text with the font 4x8. The text is drawn with OR,
;                    so the place of the text must be cleaned before.
; IX - Address of the text, it's ended with zero.
; B - Character row of the screen (0 - 23).
; C - Position of the first character, in the half characters (0 - 63).
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
; BEGIN - PrintChar4x8 - Print one character of the font 4x8.
; A - ASCII character.
; B - Character row of the screen.
; C - Position of the character, in the half characters.
PrintChar4x8:
        ; The image of the character.
        sub   32
        ld    l,a
        ld    h,0
        add   hl,hl
        add   hl,hl
        add   hl,hl ; Every character has eight bytes.
        ld    de,Font4x8
        add   hl,de
        push  hl

        ; The address of the character on the screen.
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
        ex    de,hl ; DE - address on the screen.
        pop   hl ; HL - image of the character.

        bit   0,c
        jr    nz,_PC4_Right

        ; The character is in the left half of the byte.
        ld    b,8
_PC4_LeftLine:
        ld    a,(de)
        or    (hl)
        ld    (de),a
        inc   hl
        call  DownDE
        djnz  _PC4_LeftLine
        ret

        ; The character is in the right half of the byte.
_PC4_Right:
        ld    b,8
_PC4_RightLine:
        ld    a,(hl)
        rrca
        rrca
        rrca
        rrca ; The image goes to the low half of the byte.
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

;-------------------------------------------------------------------------------
; BEGIN - Data of the font 4x8, from the character 32 to the character 127.
Font4x8:
        ; 32 - space
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 33 - !
        defb    0,  64,  64,  64,   0,  64,   0,   0
        ; 34 - "
        defb    0, 160, 160,   0,   0,   0,   0,   0
        ; 35 - #
        defb    0, 160, 224, 160, 224, 160,   0,   0
        ; 36 - $
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 37 - %
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 38 - &
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 39 - '
        defb    0,  64,  64,   0,   0,   0,   0,   0
        ; 40 - (
        defb    0,  32,  64,  64,  64,  32,   0,   0
        ; 41 - )
        defb    0, 128,  64,  64,  64, 128,   0,   0
        ; 42 - *
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 43 - +
        defb    0,   0,  64, 224,  64,   0,   0,   0
        ; 44 - ,
        defb    0,   0,   0,   0,   0,  64, 128,   0
        ; 45 - -
        defb    0,   0,   0, 224,   0,   0,   0,   0
        ; 46 - .
        defb    0,   0,   0,   0,   0,  64,   0,   0
        ; 47 - /
        defb    0,  32,  32,  64, 128, 128,   0,   0
        ; 48 - 0
        defb    0, 224, 160, 160, 160, 224,   0,   0
        ; 49 - 1
        defb    0,  64, 192,  64,  64, 224,   0,   0
        ; 50 - 2
        defb    0, 224,  32, 224, 128, 224,   0,   0
        ; 51 - 3
        defb    0, 224,  32,  96,  32, 224,   0,   0
        ; 52 - 4
        defb    0, 160, 160, 224,  32,  32,   0,   0
        ; 53 - 5
        defb    0, 224, 128, 224,  32, 224,   0,   0
        ; 54 - 6
        defb    0, 224, 128, 224, 160, 224,   0,   0
        ; 55 - 7
        defb    0, 224,  32,  32,  32,  32,   0,   0
        ; 56 - 8
        defb    0, 224, 160, 224, 160, 224,   0,   0
        ; 57 - 9
        defb    0, 224, 160, 224,  32, 224,   0,   0
        ; 58 - :
        defb    0,   0,  64,   0,  64,   0,   0,   0
        ; 59 - ;
        defb    0,   0,  64,   0,  64, 128,   0,   0
        ; 60 - <
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 61 - =
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 62 - >
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 63 - ?
        defb    0, 224,  32,  96,   0,  64,   0,   0
        ; 64 - @
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 65 - A
        defb    0, 224, 160, 224, 160, 160,   0,   0
        ; 66 - B
        defb    0, 192, 160, 192, 160, 192,   0,   0
        ; 67 - C
        defb    0, 224, 128, 128, 128, 224,   0,   0
        ; 68 - D
        defb    0, 192, 160, 160, 160, 192,   0,   0
        ; 69 - E
        defb    0, 224, 128, 192, 128, 224,   0,   0
        ; 70 - F
        defb    0, 224, 128, 192, 128, 128,   0,   0
        ; 71 - G
        defb    0, 224, 128, 160, 160, 224,   0,   0
        ; 72 - H
        defb    0, 160, 160, 224, 160, 160,   0,   0
        ; 73 - I
        defb    0, 224,  64,  64,  64, 224,   0,   0
        ; 74 - J
        defb    0,  32,  32,  32, 160, 224,   0,   0
        ; 75 - K
        defb    0, 160, 160, 192, 160, 160,   0,   0
        ; 76 - L
        defb    0, 128, 128, 128, 128, 224,   0,   0
        ; 77 - M
        defb    0, 160, 224, 224, 160, 160,   0,   0
        ; 78 - N
        defb    0, 160, 192, 224,  96, 160,   0,   0
        ; 79 - O
        defb    0, 224, 160, 160, 160, 224,   0,   0
        ; 80 - P
        defb    0, 224, 160, 224, 128, 128,   0,   0
        ; 81 - Q
        defb    0, 224, 160, 160, 224,  32,   0,   0
        ; 82 - R
        defb    0, 224, 160, 192, 160, 160,   0,   0
        ; 83 - S
        defb    0, 224, 128, 224,  32, 224,   0,   0
        ; 84 - T
        defb    0, 224,  64,  64,  64,  64,   0,   0
        ; 85 - U
        defb    0, 160, 160, 160, 160, 224,   0,   0
        ; 86 - V
        defb    0, 160, 160, 160, 160,  64,   0,   0
        ; 87 - W
        defb    0, 160, 160, 224, 224, 160,   0,   0
        ; 88 - X
        defb    0, 160, 160,  64, 160, 160,   0,   0
        ; 89 - Y
        defb    0, 160, 160,  64,  64,  64,   0,   0
        ; 90 - Z
        defb    0, 224,  32,  64, 128, 224,   0,   0
        ; 91 - [
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 92 - \
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 93 - ]
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 94 - ^
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 95 - _
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 96 - `
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 97 - a
        defb    0,   0, 192,  96, 160,  96,   0,   0
        ; 98 - b
        defb    0, 128, 192, 160, 160, 192,   0,   0
        ; 99 - c
        defb    0,   0,  96, 128, 128,  96,   0,   0
        ; 100 - d
        defb    0,  32,  96, 160, 160,  96,   0,   0
        ; 101 - e
        defb    0,   0,  64, 160, 192,  96,   0,   0
        ; 102 - f
        defb    0,  96,  64, 224,  64,  64,   0,   0
        ; 103 - g
        defb    0,   0,  96, 160,  96,  32, 192,   0
        ; 104 - h
        defb    0, 128, 192, 160, 160, 160,   0,   0
        ; 105 - i
        defb    0,  64,   0,  64,  64,  64,   0,   0
        ; 106 - j
        defb    0,  32,   0,  32,  32,  32, 192,   0
        ; 107 - k
        defb    0, 128, 160, 192, 192, 160,   0,   0
        ; 108 - l
        defb    0,  64,  64,  64,  64,  96,   0,   0
        ; 109 - m
        defb    0,   0, 224, 224, 160, 160,   0,   0
        ; 110 - n
        defb    0,   0, 192, 160, 160, 160,   0,   0
        ; 111 - o
        defb    0,   0,  64, 160, 160,  64,   0,   0
        ; 112 - p
        defb    0,   0, 192, 160, 192, 128, 128,   0
        ; 113 - q
        defb    0,   0,  96, 160,  96,  32,  32,   0
        ; 114 - r
        defb    0,   0, 160, 192, 128, 128,   0,   0
        ; 115 - s
        defb    0,   0,  96,  64,  32, 192,   0,   0
        ; 116 - t
        defb    0,  64, 224,  64,  64,  96,   0,   0
        ; 117 - u
        defb    0,   0, 160, 160, 160,  96,   0,   0
        ; 118 - v
        defb    0,   0, 160, 160, 160,  64,   0,   0
        ; 119 - w
        defb    0,   0, 160, 160, 224, 224,   0,   0
        ; 120 - x
        defb    0,   0, 160,  64,  64, 160,   0,   0
        ; 121 - y
        defb    0,   0, 160, 160,  96,  32, 192,   0
        ; 122 - z
        defb    0,   0, 224,  32,  64, 224,   0,   0
        ; 123 - {
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 124 - |
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 125 - }
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 126 - ~
        defb    0,   0,   0,   0,   0,   0,   0,   0
        ; 127 - 
        defb    0,   0,   0,   0,   0,   0,   0,   0
; END
;-------------------------------------------------------------------------------
