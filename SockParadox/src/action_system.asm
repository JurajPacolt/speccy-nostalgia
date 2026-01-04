; Action system - handles item usage and room actions

;-------------------------------------------------------------------------------
; Use item from inventory
; Selects item and attempts to use it in current room
UseItem:
        ; Count items in inventory
        ld      b,NUM_OBJECTS
        ld      c,0
        xor     a
        ld      (ObjectCount),a
        
        ; Build list of objects in inventory
        ld      hl,ObjectList
        
.count_loop:
        push    bc
        push    hl
        
        ; Check if object is in inventory (255)
        ld      hl,ObjectLocations
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        cp      255
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
        
        ; Check if any objects in inventory
        ld      a,(ObjectCount)
        or      a
        jr      z,.no_items
        
        ; Only one item? Auto-select
        cp      1
        jr      z,.auto
        
        ; Initialize selection to 0
        xor     a
        ld      (SelectedIndex),a
        
        ; Show selection menu
        call    ShowInventoryMenu
        cp      255
        ret     z           ; Cancelled
        
        ; Try to use selected item
        jr      .try_use
        
.auto:
        ld      hl,ObjectList
        ld      a,(hl)
        
.try_use:
        ; A = object index to use
        call    TryUseObject
        ret
        
.no_items:
        call    ClearTextScreen
        ld      b,0
        ld      c,0
        call    SetCursor
        ld      ix,NoItemsText
        call    PrintStringAt
        
        ; Wait for key
        ld      b,0
        ld      c,5
        call    SetCursor
        ld      ix,PressKeyText
        call    PrintStringAt
        
.wait:
        call    ScanKeyboard
        cp      255
        jr      z,.wait
        
        call    WaitKeyRelease
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Show inventory selection menu
; Returns: A = selected object index, or 255 if cancelled
ShowInventoryMenu:
        ; Clear screen
        call    ClearTextScreen
        
        ; Show title
        ld      b,0
        ld      c,0
        call    SetCursor
        ld      ix,UseItemText
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
        jp      ShowInventoryMenu
        
.move_down:
        call    WaitKeyRelease
        ld      a,(SelectedIndex)
        inc     a
        ld      b,a
        ld      a,(ObjectCount)
        cp      b
        jr      c,.input_loop
        jr      z,.input_loop
        ld      a,b
        ld      (SelectedIndex),a
        jp      ShowInventoryMenu
        
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

;-------------------------------------------------------------------------------
; Try to use object in current room
; Input: A = object index
TryUseObject:
        ld      (UsedObject),a
        
        ; Check for room-specific actions
        ; Hardcode actions based on room.json
        
        ld      a,(CurrentRoom)
        cp      0           ; BEDROOM
        jr      z,.bedroom_actions
        
        cp      4           ; LIVING_ROOM
        jr      z,.living_room_actions
        
        cp      5           ; BALCONY
        jr      z,.balcony_actions
        
        cp      7           ; WASHING_MACHINE
        jr      z,.washing_machine_actions
        
        ; No action for this object in this room
        jr      .no_action
        
.bedroom_actions:
        ; Check if using SMALL_KEY (object 5)
        ld      a,(UsedObject)
        cp      5
        jr      nz,.no_action
        
        ; Unlock BEDROOM_SECRET (room 8)
        ; Set navigation East to 8
        call    UnlockBedroomSecret
        
        ld      ix,UsedKeyText
        jr      .show_result
        
.living_room_actions:
        ; Check if using NOTE (object 6) - feed MURO
        ld      a,(UsedObject)
        cp      6
        jr      nz,.no_action
        
        ; Unlock SOFA_UNDERWORLD (room 6)
        call    UnlockSofaUnderworld
        
        ld      ix,FedMuroText
        jr      .show_result
        
.balcony_actions:
        ; Check if using STRING (object 2) - get DIRTY_JACKET
        ld      a,(UsedObject)
        cp      2
        jr      nz,.no_action
        
        ; Add DIRTY_JACKET (object 7) to inventory
        ld      a,7
        ld      hl,ObjectLocations
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (hl),255    ; Move to inventory
        
        ; Remove STRING from inventory
        ld      a,2
        ld      hl,ObjectLocations
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (hl),254    ; Remove from game
        
        ld      ix,UsedStringText
        jr      .show_result
        
.washing_machine_actions:
        ; Check if using CLOTH (object 4) - get SMALL_KEY
        ld      a,(UsedObject)
        cp      4
        jr      nz,.no_action
        
        ; Add SMALL_KEY (object 5) to inventory
        ld      a,5
        ld      hl,ObjectLocations
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (hl),255    ; Move to inventory
        
        ; Remove CLOTH from inventory
        ld      a,4
        ld      hl,ObjectLocations
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (hl),254    ; Remove from game
        
        ld      ix,GaveClothText
        jr      .show_result
        
.no_action:
        ld      ix,CantUseText
        
.show_result:
        call    ClearTextScreen
        ld      b,0
        ld      c,0
        call    SetCursor
        call    PrintStringAt
        
        ; Wait for key
        ld      b,0
        ld      c,10
        call    SetCursor
        ld      ix,PressKeyText
        call    PrintStringAt
        
.wait:
        call    ScanKeyboard
        cp      255
        jr      z,.wait
        
        call    WaitKeyRelease
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Unlock BEDROOM_SECRET - set east exit in BEDROOM
UnlockBedroomSecret:
        ; BEDROOM (room 0) nav data is Room_0_Nav
        ; East = offset 2
        ld      hl,Room_0_Nav
        inc     hl
        inc     hl          ; Point to East
        ld      (hl),8      ; Room 8 = BEDROOM_SECRET
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Unlock SOFA_UNDERWORLD - set south exit in LIVING_ROOM
UnlockSofaUnderworld:
        ; LIVING_ROOM (room 4) nav data is Room_4_Nav
        ; South = offset 1
        ld      hl,Room_4_Nav
        inc     hl          ; Point to South
        ld      (hl),6      ; Room 6 = SOFA_UNDERWORLD
        ret
;-------------------------------------------------------------------------------

UsedObject:     defb 0

; Action result texts
NoItemsText:    defb "Nemas ziadne predmety.", 0
UseItemText:    defb "Pouzit predmet:", 0
CantUseText:    defb "Toto tu nemozem pouzit.", 0
UsedKeyText:    defb "Odomkol si skrinku v spalni!", 0
FedMuroText:    defb "Dal si listok Murovi. Odisiel spod pohovky!", 0
UsedStringText: defb "Pouzil si snurku a ziskal si bundu!", 0
GaveClothText:  defb "Dal si handru Cice a dostal si maly kluc!", 0
