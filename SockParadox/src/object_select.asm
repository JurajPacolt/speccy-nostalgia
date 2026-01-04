; Object selection system
; Allows player to select which object to interact with

;-------------------------------------------------------------------------------
; Select object from current room
; Returns: A = object index, or 255 if cancelled
SelectObject:
        ; Count objects in room
        ld      b,NUM_OBJECTS
        ld      c,0
        xor     a
        ld      (ObjectCount),a
        
        ; Build list of objects in room
        ld      hl,ObjectList
        
.count_loop:
        push    bc
        push    hl
        
        ; Check if object is in current room
        ld      hl,ObjectLocations
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        ld      hl,CurrentRoom
        cp      (hl)
        jr      nz,.skip_count
        
        ; Add to list
        pop     hl
        ld      (hl),c
        inc     hl
        push    hl
        
        ld      a,(ObjectCount)
        inc     a
        ld      (ObjectCount),a
        
.skip_count:
        pop     hl
        pop     bc
        inc     c
        djnz    .count_loop
        
        ; Check if any objects
        ld      a,(ObjectCount)
        or      a
        jr      z,.none
        
        ; Only one object? Auto-select
        cp      1
        jr      z,.auto
        
        ; Initialize selection to 0
        xor     a
        ld      (SelectedIndex),a
        
        ; Show selection menu
        call    ShowObjectMenu
        ret
        
.none:
        ld      a,255
        ret
        
.auto:
        ld      hl,ObjectList
        ld      a,(hl)
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Show object selection menu
; Returns: A = selected object index, or 255 if cancelled
ShowObjectMenu:
        ; Clear screen
        call    ClearTextScreen
        
        ; Show title
        ld      b,0
        ld      c,0
        call    SetCursor
        ld      ix,SelectObjText
        call    PrintStringAt
        
        ; Show objects list
        ld      a,(ObjectCount)
        ld      b,a
        ld      c,0             ; Current index in list
        
.draw_list:
        push    bc
        
        ; Set cursor position
        ld      b,0
        ld      a,c
        add     a,2
        ld      c,a
        call    SetCursor
        
        ; Get object index from list
        pop     bc
        push    bc
        ld      hl,ObjectList
        ld      a,c
        ld      e,a
        ld      d,0
        add     hl,de
        ld      a,(hl)
        
        ; Get object name
        ld      h,0
        ld      l,a
        add     hl,hl
        add     hl,hl
        ld      de,ObjectTable
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        
        ; Print with selection marker
        pop     bc
        push    bc
        ld      a,(SelectedIndex)
        cp      c
        jr      nz,.no_marker
        ld      ix,SelectMarker
        call    PrintStringAt
        jr      .print_name
.no_marker:
        ld      ix,SpaceMarker
        call    PrintStringAt
        
.print_name:
        push    de
        pop     ix
        call    PrintStringAt
        
        pop     bc
        inc     c
        djnz    .draw_list
        
        ; Show help
        ld      a,(ObjectCount)
        add     a,4
        ld      c,a
        ld      b,0
        call    SetCursor
        ld      ix,SelectHelpText
        call    PrintStringAt
        
        ; Wait for input
.input_loop:
        call    ScanKeyboard
        cp      255
        jr      z,.input_loop
        
        ; Check Q (up)
        cp      'Q'
        jr      z,.move_up
        
        ; Check A (down)
        cp      'A'
        jr      z,.move_down
        
        ; Check SPACE or ENTER for confirm
        cp      ' '
        jr      z,.confirm
        cp      13          ; ENTER
        jr      z,.confirm
        
        ; Check BACKSPACE for cancel
        cp      8
        jr      z,.cancel
        
        jr      .input_loop
        
.move_up:
        call    WaitKeyRelease
        ld      a,(SelectedIndex)
        or      a
        jr      z,.input_loop
        dec     a
        ld      (SelectedIndex),a
        jp      ShowObjectMenu
        
.move_down:
        call    WaitKeyRelease
        ld      a,(SelectedIndex)
        inc     a
        ld      b,a
        ld      a,(ObjectCount)
        cp      b
        jr      c,.input_loop   ; If ObjectCount < new_index, stay
        jr      z,.input_loop   ; If ObjectCount == new_index, stay (0-based)
        ld      a,b
        ld      (SelectedIndex),a
        jp      ShowObjectMenu
        
.confirm:
        call    WaitKeyRelease
        ; Get selected object index
        ld      a,(SelectedIndex)
        ld      hl,ObjectList
        ld      e,a
        ld      d,0
        add     hl,de
        ld      a,(hl)
        ret
        
.cancel:
        call    WaitKeyRelease
        ld      a,255
        ret
;-------------------------------------------------------------------------------

SelectObjText:  defb "Vyber predmet:", 0
SelectMarker:   defb "> ", 0
SpaceMarker:    defb "  ", 0
SelectHelpText: defb "Q/A-pohyb SPACE/ENTER-vyber BS-zrusit", 0
SelectedIndex:  defb 0

ObjectCount:    defb 0
ObjectList:     defs 16, 0
