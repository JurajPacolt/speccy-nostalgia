; Text printing system for 4x8 font
; Screen: 64 columns x 24 rows

; Current cursor position
TextCursorX:    defb 0      ; 0-63
TextCursorY:    defb 0      ; 0-23

;-------------------------------------------------------------------------------
; Print string at current cursor position
; IX = pointer to string
; Moves cursor automatically
PrintStringAt:
        ld      a,(ix+0)
        or      a
        ret     z
        
        cp      10          ; Newline?
        jr      z,.newline
        
        ; Print character
        call    PrintCharAt
        
        ; Move cursor right
        ld      a,(TextCursorX)
        inc     a
        cp      64
        jr      c,.no_wrap
        
        ; Wrap to next line
        xor     a
        ld      (TextCursorX),a
        ld      a,(TextCursorY)
        inc     a
        cp      24
        jr      c,.no_scroll
        ld      a,23        ; Stay on last line
.no_scroll:
        ld      (TextCursorY),a
        jr      .next
        
.no_wrap:
        ld      (TextCursorX),a
        jr      .next
        
.newline:
        xor     a
        ld      (TextCursorX),a
        ld      a,(TextCursorY)
        inc     a
        cp      24
        jr      c,.nl_ok
        ld      a,23
.nl_ok:
        ld      (TextCursorY),a
        
.next:
        inc     ix
        jr      PrintStringAt
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Print single character at current cursor position
; A = ASCII character
; For 4x8 font: 2 chars per byte (left char in bits 7-4, right char in bits 3-0)
PrintCharAt:
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        
        ; Save character
        ld      (SavedChar),a
        
        ; Calculate screen address for character row Y
        ; Address = 16384 + (Y/8)*2048 + (Y%8)*32 + X/2
        
        ld      a,(TextCursorY)
        
        ; First: (Y % 8) * 32
        and     7
        ld      h,0
        ld      l,a
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl       ; * 32
        
        ; Save in DE
        ex      de,hl
        
        ; Second: (Y / 8) * 2048
        ; Y/8 gives us which third (0, 1, 2)
        ; We need to add this to base 0x40 in high byte
        ld      a,(TextCursorY)
        rrca
        rrca
        rrca
        and     3           ; Get third number (0, 1, 2)
        add     a,a
        add     a,a
        add     a,a         ; * 8 to get 0, 8, 16
        or      0x40        ; Add base 0x40
        ld      h,a
        ld      l,0
        
        ; Combine: HL = third_base + row_offset
        add     hl,de
        
        ; Add X / 2
        ld      a,(TextCursorX)
        srl     a
        ld      e,a
        ld      d,0
        add     hl,de
        
        ; HL now points to correct screen byte
        ex      de,hl       ; DE = screen position
        
        ; Check if odd or even position
        ld      a,(TextCursorX)
        and     1
        ld      (IsOddChar),a
        
        ; Calculate font offset
        ld      a,(SavedChar)
        sub     32
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl       ; * 8
        ld      bc,MainFontData
        add     hl,bc
        
        ; HL = font data, DE = screen position
        ; Copy 8 pixel rows
        ld      b,8
.copy_loop:
        ld      a,(hl)
        
        ; Check if odd position
        ld      c,a
        ld      a,(IsOddChar)
        or      a
        ld      a,c
        jr      z,.even_pos
        
        ; Odd position - shift right 4 bits
        srl     a
        srl     a
        srl     a
        srl     a
        
        ; Combine with existing byte
        ld      c,a
        ld      a,(de)
        and     0xF0
        or      c
        ld      (de),a
        jr      .next_row
        
.even_pos:
        ; Even position
        ld      c,a
        ld      a,(de)
        and     0x0F
        or      c
        ld      (de),a
        
.next_row:
        inc     hl
        
        ; Move DE down one pixel line
        inc     d
        ld      a,d
        and     7
        jr      nz,.no_adj
        ld      a,e
        add     a,32
        ld      e,a
        jr      c,.no_adj
        ld      a,d
        sub     8
        ld      d,a
.no_adj:
        
        djnz    .copy_loop
        
        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

IsOddChar:      defb 0
SavedChar:      defb 0
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Set cursor position
; B = X (0-63)
; C = Y (0-23)
SetCursor:
        ld      a,b
        ld      (TextCursorX),a
        ld      a,c
        ld      (TextCursorY),a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Clear screen and reset cursor
ClearTextScreen:
        call    ClearScreenToBlack
        xor     a
        ld      (TextCursorX),a
        ld      (TextCursorY),a
        ret
;-------------------------------------------------------------------------------
