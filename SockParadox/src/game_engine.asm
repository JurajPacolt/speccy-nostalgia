; Game engine
; Ponozkovy Paradox

; Game state variables
CurrentRoom:    defb ROOM_BEDROOM
Inventory:      defs 16, 0  ; Max 16 items
InventoryCount: defb 0

;-------------------------------------------------------------------------------
; Refresh inventory from ObjectLocations
RefreshInventory:
        ; Clear inventory
        xor     a
        ld      (InventoryCount),a
        
        ; Loop through all objects
        ld      b,NUM_OBJECTS
        ld      c,0             ; Object index
        ld      hl,Inventory
        
.loop:
        push    bc
        push    hl
        
        ; Check if object is in inventory (255)
        ld      hl,ObjectLocations
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        cp      255
        jr      nz,.skip
        
        ; Add to inventory
        pop     hl
        ld      (hl),c
        inc     hl
        push    hl
        
        ; Increment count
        ld      a,(InventoryCount)
        inc     a
        ld      (InventoryCount),a
        
.skip:
        pop     hl
        pop     bc
        inc     c
        djnz    .loop
        
        ret
;-------------------------------------------------------------------------------

; Initialize game
GameInit:
        call    ClearScreenToBlack
        
        ; Set starting room
        ld      a,ROOM_BEDROOM
        ld      (CurrentRoom),a
        
        ; Clear inventory
        xor     a
        ld      (InventoryCount),a
        
        ret

; Display current room
DisplayRoom:
        ; First refresh inventory from ObjectLocations
        call    RefreshInventory
        
        call    ClearTextScreen
        
        ; Get current room index
        ld      a,(CurrentRoom)
        
        ; Calculate offset in room table (6 bytes per room)
        ld      l,a
        ld      h,0
        add     hl,hl
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,de
        ld      de,RoomTable
        add     hl,de
        
        ; Store for later use
        ld      (RoomTablePtr),hl
        
        ; Set cursor to 0,0 for room name
        ld      b,0
        ld      c,0
        call    SetCursor
        
        ; Get room name pointer
        ld      hl,(RoomTablePtr)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        
        ; Print room name
        push    de
        pop     ix
        call    PrintStringAt
        
        ; Set cursor to 0,2 for description
        ld      b,0
        ld      c,2
        call    SetCursor
        
        ; Restore pointer and skip name
        ld      hl,(RoomTablePtr)
        inc     hl
        inc     hl
        
        ; Get room description pointer
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        
        ; Print room description
        push    de
        pop     ix
        call    PrintStringAt
        
        ; Set cursor 2 lines below description end
        ld      a,(TextCursorY)
        add     a,2
        ld      c,a
        ld      b,0
        call    SetCursor
        
        ; Get nav pointer
        ld      hl,(RoomTablePtr)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        
        ; Show available exits
        ex      de,hl
        call    ShowExits
        
        ; Move cursor 2 lines down
        ld      a,(TextCursorY)
        add     a,2
        ld      c,a
        ld      b,0
        call    SetCursor
        
        ; Show objects in room
        call    ShowObjects
        
        ; Move cursor 2 lines down
        ld      a,(TextCursorY)
        add     a,2
        ld      c,a
        ld      b,0
        call    SetCursor
        
        ; Show inventory
        call    ShowInventory
        
        ; Move cursor 2 lines down
        ld      a,(TextCursorY)
        add     a,2
        ld      c,a
        ld      b,0
        call    SetCursor
        
        ; Show help
        ld      ix,HelpText
        call    PrintStringAt
        
        ret

RoomTablePtr:   defw 0
DescEndY:       defb 0

; Show available exits
; Input: HL = nav data pointer
ShowExits:
        push    hl
        
        ld      ix,ExitsText
        call    PrintStringAt
        
        ; Newline
        ld      b,0
        ld      a,(TextCursorY)
        inc     a
        ld      c,a
        call    SetCursor
        
        pop     hl
        
        ; Check North
        ld      a,(hl)
        cp      255
        jr      z,.skip_n
        push    hl
        ld      ix,NorthText
        call    PrintStringAt
        ld      ix,SpaceText
        call    PrintStringAt
        pop     hl
.skip_n:
        inc     hl
        
        ; Check South
        ld      a,(hl)
        cp      255
        jr      z,.skip_s
        push    hl
        ld      ix,SouthText
        call    PrintStringAt
        ld      ix,SpaceText
        call    PrintStringAt
        pop     hl
.skip_s:
        inc     hl
        
        ; Check East
        ld      a,(hl)
        cp      255
        jr      z,.skip_e
        push    hl
        ld      ix,EastText
        call    PrintStringAt
        ld      ix,SpaceText
        call    PrintStringAt
        pop     hl
.skip_e:
        inc     hl
        
        ; Check West
        ld      a,(hl)
        cp      255
        jr      z,.skip_w
        push    hl
        ld      ix,WestText
        call    PrintStringAt
        pop     hl
.skip_w:
        
        ret

;-------------------------------------------------------------------------------
; Show objects in current room
ShowObjects:
        ld      ix,ObjectsText
        call    PrintStringAt
        
        ; Newline
        ld      b,0
        ld      a,(TextCursorY)
        inc     a
        ld      c,a
        call    SetCursor
        
        ; Reset object found flag
        xor     a
        ld      (ObjectFound),a
        
        ; Loop through all objects
        ld      b,NUM_OBJECTS
        ld      c,0             ; Object index
        
.loop:
        push    bc
        
        ; Check if object is in current room
        ld      hl,ObjectLocations
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        ld      hl,CurrentRoom
        cp      (hl)
        jr      nz,.skip
        
        ; Object is here! Print its name
        ld      a,1
        ld      (ObjectFound),a
        
        ; Get object name from ObjectTable
        ld      a,c
        ld      h,0
        ld      l,a
        add     hl,hl
        add     hl,hl           ; * 4 (name + desc pointers)
        ld      de,ObjectTable
        add     hl,de
        
        ; Get name pointer
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        
        ; Print object name
        push    de
        pop     ix
        call    PrintStringAt
        
        ; Print comma and space if not last
        pop     bc
        push    bc
        ld      a,b
        cp      1
        jr      z,.skip
        ld      ix,CommaText
        call    PrintStringAt
        
.skip:
        pop     bc
        inc     c
        djnz    .loop
        
        ; If no objects found, print "ziadne"
        ld      a,(ObjectFound)
        or      a
        ret     nz
        
        ld      ix,NoneText
        call    PrintStringAt
        
        ret

ObjectFound:    defb 0
CommaText:      defb ", ", 0
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Show inventory
ShowInventory:
        ld      ix,InventoryText
        call    PrintStringAt
        
        ; Newline
        ld      b,0
        ld      a,(TextCursorY)
        inc     a
        ld      c,a
        call    SetCursor
        
        ; Check if inventory is empty
        ld      a,(InventoryCount)
        or      a
        jr      z,.empty
        
        ; Loop through inventory
        ld      b,a             ; Count
        ld      hl,Inventory
        xor     a
        ld      (ObjectFound),a
        
.loop:
        push    bc
        push    hl
        
        ; Get object index from inventory
        ld      c,(hl)
        
        ; Print object name
        ld      a,c
        ld      h,0
        ld      l,a
        add     hl,hl
        add     hl,hl           ; * 4
        ld      de,ObjectTable
        add     hl,de
        
        ; Get name pointer
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        
        ; Print
        push    de
        pop     ix
        call    PrintStringAt
        
        ; Comma if not last
        pop     hl
        pop     bc
        push    bc
        push    hl
        ld      a,b
        cp      1
        jr      z,.no_comma
        ld      ix,CommaText
        call    PrintStringAt
        
.no_comma:
        pop     hl
        pop     bc
        inc     hl
        djnz    .loop
        ret
        
.empty:
        ld      ix,NoneText
        call    PrintStringAt
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Take object
; Input: A = object index
TakeObject:
        ; Check if object is in current room
        ld      hl,ObjectLocations
        ld      e,a
        ld      d,0
        add     hl,de
        ld      b,a             ; Save object index
        ld      a,(hl)
        ld      c,a             ; Save current location
        ld      a,(CurrentRoom)
        cp      c
        jr      nz,.not_here
        
        ; Check inventory space
        ld      a,(InventoryCount)
        cp      16
        jr      nc,.full
        
        ; Add to inventory
        ld      hl,Inventory
        ld      e,a
        add     hl,de
        ld      (hl),b          ; Store object index
        
        ; Increment count
        inc     a
        ld      (InventoryCount),a
        
        ; Set object location to 255 (in inventory)
        ld      hl,ObjectLocations
        ld      a,b
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (hl),255
        
        ; Show success message
        ld      ix,TakenText
        call    PrintStringAt
        
        ret
        
.not_here:
        ld      ix,NotHereText
        call    PrintStringAt
        ret
        
.full:
        ld      ix,InventoryFullText
        call    PrintStringAt
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Examine object
; Input: A = object index
ExamineObject:
        ; Save object index
        ld      (TempObjIndex),a
        
        ; Check if object is visible (in room or inventory)
        ld      hl,ObjectLocations
        ld      e,a
        ld      d,0
        add     hl,de
        ld      a,(hl)
        
        ; Check if in current room
        ld      b,a
        ld      a,(CurrentRoom)
        cp      b
        jr      z,.visible
        
        ; Check if in inventory (255)
        ld      a,b
        cp      255
        jr      nz,.not_visible
        
.visible:
        ; Get object description
        ld      a,(TempObjIndex)
        ld      h,0
        ld      l,a
        add     hl,hl
        add     hl,hl           ; * 4
        ld      de,ObjectTable
        add     hl,de
        
        ; Skip name, get description
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        
        ; Clear screen and print description
        call    ClearTextScreen
        
        ld      b,0
        ld      c,0
        call    SetCursor
        
        push    de
        pop     ix
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
        
        ; Redraw room
        call    DisplayRoom
        ret

.not_visible:
        ld      ix,NotHereText
        call    PrintStringAt
        ret

TempObjIndex:   defb 0

;-------------------------------------------------------------------------------
; Select object for examination (from room + inventory)
; Returns: A = object index, or 255 if none
SelectObjectForExamine:
        ; Count objects in room and inventory
        ld      b,NUM_OBJECTS
        ld      c,0
        xor     a
        ld      (ObjectCount),a
        
        ; Build list of visible objects
        ld      hl,ObjectList
        
.count_loop:
        push    bc
        push    hl
        
        ; Check object location
        ld      hl,ObjectLocations
        ld      b,0
        add     hl,bc
        ld      a,(hl)
        
        ; Is it in current room?
        ld      b,a
        ld      a,(CurrentRoom)
        cp      b
        jr      z,.add_to_list
        
        ; Is it in inventory?
        ld      a,b
        cp      255
        jr      nz,.skip_count
        
.add_to_list:
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
        jr      z,.no_objects
        
        ; Only one object? Auto-select
        cp      1
        jr      z,.auto
        
        ; Initialize selection to 0
        xor     a
        ld      (SelectedIndex),a
        
        ; Show selection menu
        call    ShowObjectMenu
        ret
        
.auto:
        ld      hl,ObjectList
        ld      a,(hl)
        ret
        
.no_objects:
        ; Show message that nothing to examine
        call    ClearTextScreen
        ld      b,0
        ld      c,0
        call    SetCursor
        ld      ix,NothingToExamineText
        call    PrintStringAt
        
        ; Wait for key
        ld      b,0
        ld      c,5
        call    SetCursor
        ld      ix,PressKeyText
        call    PrintStringAt
        
.wait_key:
        call    ScanKeyboard
        cp      255
        jr      z,.wait_key
        
        call    WaitKeyRelease
        ld      a,255
        ret
;-------------------------------------------------------------------------------

ExitsText:      defb "Moznosti:", 0
NorthText:      defb "Q-Sever", 0
SouthText:      defb "A-Juh", 0  
EastText:       defb "O-Vychod", 0
WestText:       defb "P-Zapad", 0
SpaceText:      defb " ", 0
CommandsText:   defb 0
ObjectsText:    defb "Predmety:", 0
InventoryText:  defb "Inventar:", 0
NoneText:       defb "ziadne", 0
TakenText:      defb "Vzate!", 0
NotHereText:    defb "Tu to nie je.", 0
InventoryFullText: defb "Inventar plny!", 0
PressKeyText:   defb "Stlac lubovolnu klavesu...", 0
HelpText:       defb "T-Zober E-Preskumaj U-Pouzit", 0
NothingToExamineText: defb "Niet nic na preskumanie.", 0

; Try to move in direction
; Input: A = direction (1=N, 2=S, 3=E, 4=W)
TryMove:
        push    af
        
        ; Get current room
        ld      a,(CurrentRoom)
        
        ; Calculate nav table offset (6 bytes per room)
        ld      l,a
        ld      h,0
        add     hl,hl  ; *2
        ld      d,h
        ld      e,l
        add     hl,hl  ; *4
        add     hl,de  ; *6
        ld      de,RoomTable
        add     hl,de
        
        ; Skip name and desc pointers (4 bytes)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        
        ; Get nav pointer
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        
        ; Get direction offset
        pop     af
        dec     a
        ld      e,a
        ld      d,0
        add     hl,de
        
        ; Read target room
        ld      a,(hl)
        cp      255
        ret     z       ; No exit
        
        ; Move to new room
        ld      (CurrentRoom),a
        ret

; Main game loop  
GameMainLoop:
        call    GameInit
        call    DisplayRoom
        
.loop:
        ; Wait for input
        call    ScanKeyboard
        cp      255
        jr      z,.loop
        
        ; Store key
        ld      (LastKey),a
        
        ; Check movement keys
        cp      'Q'
        jr      z,.north
        cp      'A'
        jr      z,.south
        cp      'O'
        jr      z,.east
        cp      'P'
        jr      z,.west
        
        ; Check action keys
        cp      'T'
        jr      z,.take
        cp      'E'
        jr      z,.examine
        cp      'U'
        jr      z,.use
        
        jr      .loop
        
.north:
        ld      a,1
        call    TryMove
        jr      .redraw
        
.south:
        ld      a,2
        call    TryMove
        jr      .redraw
        
.east:
        ld      a,3
        call    TryMove
        jr      .redraw
        
.west:
        ld      a,4
        call    TryMove
        jr      .redraw

.take:
        call    SelectObject
        cp      255
        jr      z,.loop
        call    TakeObject
        jr      .redraw

.examine:
        call    SelectObjectForExamine
        cp      255
        jr      z,.redraw      ; Redraw after message
        call    ExamineObject
        jr      .loop

.use:
        call    UseItem
        jr      .redraw
        
.redraw:
        ; Wait for key release
        call    WaitKeyRelease
        
        call    DisplayRoom
        jr      .loop
        
        ret

LastKey:        defb 0
