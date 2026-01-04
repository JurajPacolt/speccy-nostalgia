; Keyboard input

;-------------------------------------------------------------------------------
; Scan keyboard for any key
; Returns: A = ASCII code of key, or 255 if no key pressed
ScanKeyboard:
        ; Test Q (port 64510, bit 0)
        ld      bc,64510
        in      a,(c)
        bit     0,a
        jr      nz,.not_q
        ld      a,'Q'
        ret
.not_q:
        
        ; Test E (port 64510, bit 2)
        ld      bc,64510
        in      a,(c)
        bit     2,a
        jr      nz,.not_e
        ld      a,'E'
        ret
.not_e:
        
        ; Test T (port 64510, bit 4)
        ld      bc,64510
        in      a,(c)
        bit     4,a
        jr      nz,.not_t
        ld      a,'T'
        ret
.not_t:
        
        ; Test A (port 65022, bit 0)
        ld      bc,65022
        in      a,(c)
        bit     0,a
        jr      nz,.not_a
        ld      a,'A'
        ret
.not_a:
        
        ; Test O (port 57342, bit 1)
        ld      bc,57342
        in      a,(c)
        bit     1,a
        jr      nz,.not_o
        ld      a,'O'
        ret
.not_o:
        
        ; Test P (port 57342, bit 0)
        ld      bc,57342
        in      a,(c)
        bit     0,a
        jr      nz,.not_p
        ld      a,'P'
        ret
.not_p:
        
        ; Test SPACE (port 32766, bit 0)
        ld      bc,32766
        in      a,(c)
        bit     0,a
        jr      nz,.not_space
        ld      a,' '
        ret
.not_space:
        
        ; Test ENTER (port 49150, bit 0)
        ld      bc,49150
        in      a,(c)
        bit     0,a
        jr      nz,.not_enter
        ld      a,13        ; CR
        ret
.not_enter:
        
        ; Test BACKSPACE (Caps Shift + 0, port 65278 bit 0 + port 61438 bit 0)
        ; Simpler: use CS alone on port 65278, bit 0
        ld      bc,65278
        in      a,(c)
        bit     0,a
        jr      nz,.not_backspace
        ld      a,8         ; BS
        ret
.not_backspace:
        
        ; Test U (port 57342, bit 3)
        ld      bc,57342
        in      a,(c)
        bit     3,a
        jr      nz,.not_u
        ld      a,'U'
        ret
.not_u:
        
        ; No key pressed
        ld      a,255
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Wait for key release
WaitKeyRelease:
        call    ScanKeyboard
        cp      255
        jr      nz,WaitKeyRelease
        ret
;-------------------------------------------------------------------------------

TestQ:
        ld      bc,64510
        in      a,(c)
        bit     0,a
        ret     nz
        ld      a,1
        ret

TestA:
        ld      bc,65022
        in      a,(c)
        bit     0,a
        ret     nz
        ld      a,2
        ret

TestO:
        ld      bc,57342
        in      a,(c)
        bit     1,a
        ret     nz
        ld      a,3
        ret

TestP:
        ld      bc,57342
        in      a,(c)
        bit     0,a
        ret     nz
        ld      a,4
        ret
