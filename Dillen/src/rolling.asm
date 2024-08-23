; Example
; TODO

;-------------------------------------------------------------------------------
; BEGIN - Rolling
; Rolling in one line, one attribute height.
Rolling:
        ld    hl,16415
        ld    b,8
.Rolling1:
        push  bc
        ld    b,32
.Rolling2:
        rl    (hl)
        dec   hl
        djnz  .Rolling2
        ld    de,288
        add   hl,de
        pop   bc
        djnz  .Rolling1
        ret
; END - Rolling
;-------------------------------------------------------------------------------
