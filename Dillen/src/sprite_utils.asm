;-------------------------------------------------------------------------------
; BEGIN - DrawSprite
; IX - Address of the sprite.
; B - Yos
; C - Xos
; DE - Address for attribute's cache or address for attributes on screen.
DrawSprite:
        push  de
        push  bc
        call  ScreenAddr
        ld    c,(ix+1) ; height
        ld    b,(ix+0) ; width
        push  bc
.DrawSprite2:
        push  bc
        push  hl
.DrawSprite1:
        ld    a,(ix+2) ; get byte from sprite data
        ;or    (hl) ; mix byte from screen with byte from sprite
        ld    (hl),a ; put to screen
        inc   hl
        inc   ix
        djnz  .DrawSprite1
        pop   hl
        call  DownHL ; vertical down by one pixel
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
; B - Yos
; C - Xos
; A - Attributes color.
; DE - Address for attribute's cache or address for attributes on screen.
DrawSpriteWithCustomColor:
        push  de
        push  af
        push  bc
        call  ScreenAddr
        ld    c,(ix+1) ; height
        ld    b,(ix+0) ; width
        push  bc
.DrawSpriteWithCustomColor2:
        push  bc
        push  hl
.DrawSpriteWithCustomColor1:
        ld    a,(ix+2) ; get byte from sprite data
        ;or    (hl) ; mix byte from screen with byte from sprite
        ld    (hl),a ; put to screen
        inc   hl
        inc   ix
        djnz  .DrawSpriteWithCustomColor1
        pop   hl
        call  DownHL ; vertical down by one pixel
        pop   bc
        dec   c
        jr    nz,.DrawSpriteWithCustomColor2
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
.DrawSpriteWithCustomColor3:
        push  bc
        push  hl
.DrawSpriteWithCustomColor4:
        ld    (hl),a
        inc   hl
        inc   ix
        djnz  .DrawSpriteWithCustomColor4
        pop   hl
        add   hl,de
        pop   bc
        dec   c
        jr    nz,.DrawSpriteWithCustomColor3
        ret
; END - DrawSpriteWithCustomColor
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DrawSpriteWithoutAttrs
; IX - Address of the sprite.
; B - Yos
; C - Xos
DrawSpriteWithoutAttrs:
        call  ScreenAddr
        ld    c,(ix+1) ; height
        ld    b,(ix+0) ; width
.DrawSpriteWA2:
        push  bc
        push  hl
.DrawSpriteWA1:
        ld    a,(ix+2) ; get byte from sprite data
        or    (hl) ; mix byte from screen with byte from sprite
        ld    (hl),a ; put to screen
        inc   hl
        inc   ix
        djnz  .DrawSpriteWA1
        pop   hl
        call  DownHL ; vertical down by one pixel
        pop   bc
        dec   c
        jr    nz,.DrawSpriteWA2
        ret
; END - DrawSpriteWithoutAttrs
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DownHL
; One pixel down via HL register
DownHL:
        inc   h
        ld    a, h
        and   7
        ret   nz
        ld    a, l
        add   a, 32
        ld    l, a
        ret   c
        ld    a, h
        sub   8
        ld    h, a
        ret
; END - DownHL
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - DownDE
; One pixel down via DE register
DownDE:
        inc   d
        ld    a, d
        and   7
        ret   nz
        ld    a, e
        add   a, 32
        ld    e, a
        ret   c
        ld    a, d
        sub   8
        ld    d, a
        ret
; END - DownDE
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - AttrAddr
; Address of the attribute.
; B - Yos.
; C - Xos.
; return HL
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
; Address of the attribute via pixel position.
; B - Yos.
; C - Xos.
; return HL
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
        ;ld    a,h
        ;or    88 TODO Docasne riesenie kvoli cache ...
        ;ld    h,a
        ld    a,c
        rrca
        rrca
        rrca
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
; Address on screen.
; B - Yos.
; C - Xos.
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
