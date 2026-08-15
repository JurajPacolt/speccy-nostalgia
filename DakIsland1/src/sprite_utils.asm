;###############################################################################
;##### Drawing the sprites and finding the addresses on the screen. ############
;##### #########################################################################
;##### A sprite is the width in characters and the height in pixel lines, ######
;##### then the bitmap by pixel lines, and after the whole bitmap one ###########
;##### attribute for every character of it. ####################################
;###############################################################################

;-------------------------------------------------------------------------------
; BEGIN - DrawSprite
; Draw a sprite with the colours it carries itself.
; IX - address of the sprite
; B - Yos in the pixel lines
; C - Xos in the pixels, it has to be a whole character
; DE - address of the attributes: the cache of the rooms, or 22528 for the screen
DrawSprite:
        push  de
        push  bc
        call  ScreenAddr
        ld    c,(ix+1) ; Height.
        ld    b,(ix+0) ; Width.
        push  bc
.DrawSprite2:
        push  bc
        push  hl
.DrawSprite1:
        ld    a,(ix+2)
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .DrawSprite1
        pop   hl
        call  DownHL
        pop   bc
        dec   c
        jr    nz,.DrawSprite2
        pop   de
        pop   bc
        call  AttrAddrViaPixelPos
        ld    bc,de
        ld    a,c
        rrca
        rrca
        rrca
        ld    c,a

        pop   de
        add   hl,de

        ld    de,32
.DrawSprite3:
        push  bc
        push  hl
.DrawSprite4:
        ld    a,(ix+2)
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .DrawSprite4
        pop   hl
        add   hl,de
        pop   bc
        dec   c
        jr    nz,.DrawSprite3
        ret
; END - DrawSprite
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawSpriteWithCustomColor
; The same sprite, but painted with one colour given from the outside. The same
; stone is grey on the shore and green in the grass this way.
; IX - address of the sprite
; B - Yos, C - Xos
; A - the attribute
; DE - address of the attributes
DrawSpriteWithCustomColor:
        push  de
        push  af
        push  bc
        call  ScreenAddr
        ld    c,(ix+1) ; Height.
        ld    b,(ix+0) ; Width.
        push  bc
.DrawSpriteCC2:
        push  bc
        push  hl
.DrawSpriteCC1:
        ld    a,(ix+2)
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .DrawSpriteCC1
        pop   hl
        call  DownHL
        pop   bc
        dec   c
        jr    nz,.DrawSpriteCC2
        pop   de
        pop   bc
        call  AttrAddrViaPixelPos
        ld    bc,de
        ld    a,c
        rrca
        rrca
        rrca
        ld    c,a
        pop   af

        pop   de
        add   hl,de

        ld    de,32
.DrawSpriteCC3:
        push  bc
        push  hl
.DrawSpriteCC4:
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .DrawSpriteCC4
        pop   hl
        add   hl,de
        pop   bc
        dec   c
        jr    nz,.DrawSpriteCC3
        ret
; END - DrawSpriteWithCustomColor
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawSpriteWithoutAttrs
; Mix the bitmap into what is already on the screen and leave the colours alone.
; IX - address of the sprite
; B - Yos, C - Xos
DrawSpriteWithoutAttrs:
        call  ScreenAddr
        ld    c,(ix+1)
        ld    b,(ix+0)
.DrawSpriteWA2:
        push  bc
        push  hl
.DrawSpriteWA1:
        ld    a,(ix+2)
        or    (hl)
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .DrawSpriteWA1
        pop   hl
        call  DownHL
        pop   bc
        dec   c
        jr    nz,.DrawSpriteWA2
        ret
; END - DrawSpriteWithoutAttrs
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DownHL
; One pixel line down.
DownHL:
        inc   h
        ld    a,h
        and   7
        ret   nz
        ld    a,l
        add   a,32
        ld    l,a
        ret   c
        ld    a,h
        sub   8
        ld    h,a
        ret
; END - DownHL
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DownDE
; One pixel line down, in DE.
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
; END - DownDE
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - AttrAddr
; The attribute of one character cell.
; B - the character row, C - the character column
; return A - the attribute, HL - its address
AttrAddr:
        ld    a,b
        rrca
        rrca
        rrca
        ld    l,a
        and   3
        add   a,88
        ld    h,a
        ld    a,l
        and   224
        ld    l,a
        ld    a,c
        add   a,l
        ld    l,a
        ld    a,(hl)
        ret
; END - AttrAddr
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - AttrAddrViaPixelPos
; How far the attribute of a pixel position is from the beginning of the
; attributes. It is an offset and not an address, so the same routine serves
; the screen and the cache of the rooms.
; B - Yos, C - Xos
; return HL - the offset
AttrAddrViaPixelPos:
        push  af
        push  bc
        ld    a,b
        sra   a
        sra   a
        sra   a
        sla   a
        sla   a
        sla   a
        ld    b,a
        ld    h,0
        ld    l,b
        add   hl,hl
        add   hl,hl
        ld    a,c
        rrca
        rrca
        rrca
        and   %00011111 ; The low bits of Xos rotate up, they are not the column.
        ld    c,a
        ld    b,0
        add   hl,bc
        pop   bc
        pop   af
        ret
; END - AttrAddrViaPixelPos
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - ScreenAddr
; The address of a pixel position in the VRAM.
; B - Yos, C - Xos
; return HL
ScreenAddr:
        push  af
        push  bc
        ld    a,b
        and   a
        rra
        scf
        rra
        and   a
        rra
        xor   b
        and   #F8
        xor   b
        ld    h,a
        ld    a,c
        rlca
        rlca
        rlca
        xor   b
        and   #C7
        xor   b
        rlca
        rlca
        ld    l,a
        ld    a,c
        and   #07
        pop   bc
        pop   af
        ret
; END - ScreenAddr
;-------------------------------------------------------------------------------
