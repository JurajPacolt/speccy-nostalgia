; Menu system
; Ponozkovy Paradox

;-------------------------------------------------------------------------------
; Show menu with available exits and return selection
; Returns: A = direction (1=N, 2=S, 3=E, 4=W) or 0 if cancelled
ShowNavigationMenu:
        ; Get current room nav data
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
        ld      (MenuNavPtr),de
        
        ; Build menu
        call    BuildMenu
        
        ; Display menu
        call    DisplayMenu
        
        ; Wait for selection
        call    WaitForKey
        
        ; Process selection
        or      a
        ret     z       ; SPACE = cancel
        
        cp      6
        ret     nc      ; Invalid
        
        ; Check if this option is valid
        ld      hl,MenuOptions
        dec     a
        ld      e,a
        ld      d,0
        add     hl,de
        ld      a,(hl)
        
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Build menu from navigation data
BuildMenu:
        ; Clear menu
        ld      hl,MenuOptions
        ld      de,MenuOptions+1
        ld      bc,4
        ld      (hl),0
        ldir
        
        ld      hl,(MenuNavPtr)
        ld      de,MenuOptions
        ld      b,4
        ld      c,1             ; Direction counter (1=N,2=S,3=E,4=W)
        
.loop:
        ld      a,(hl)
        cp      255
        jr      z,.skip
        
        ; Valid exit - add to menu
        ld      a,c
        ld      (de),a
        inc     de
        
.skip:
        inc     hl
        inc     c
        djnz    .loop
        
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Display menu
DisplayMenu:
        ; TEST: Just show a simple message first
        ld      ix,TestMessage
        ld      hl,MainFontData
        ld      de,16384+32*8*16
        call    Print
        
        ; Draw menu title
        ld      ix,MenuTitle
        ld      hl,MainFontData
        ld      de,16384+32*8*18
        call    Print
        
        ; Show "SPACE to cancel"
        ld      ix,MenuCancel
        ld      hl,MainFontData
        ld      de,16384+32*8*22
        call    Print
        
        ret
;-------------------------------------------------------------------------------

TestMessage:    defb "MENU TEST - funguje!", 0

;-------------------------------------------------------------------------------
; Get direction name
; Input: A = direction (1=N,2=S,3=E,4=W)
; Output: HL = pointer to name string
GetDirectionName:
        dec     a
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,DirNames
        add     hl,de
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        ret
;-------------------------------------------------------------------------------

; Menu data
MenuNavPtr:     defw 0
MenuOptions:    defs 5,0
MenuNumberBuf:  defb "0",0

MenuTitle:      defb "Kam ist?", 0
MenuCancel:     defb "SPACE-zrusit", 0

DirNames:
        defw DirNorth, DirSouth, DirEast, DirWest
        
DirNorth:       defb "-Sever", 0
DirSouth:       defb "-Juh", 0
DirEast:        defb "-Vychod", 0
DirWest:        defb "-Zapad", 0
