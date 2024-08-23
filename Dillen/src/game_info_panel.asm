;-------------------------------------------------------------------------------
; BEGIN - CleanGameInfoPanelField
; Total cleaning game info panel field, reset pixels and attributes.
CleanGameInfoPanelField:
        ; Hide all graphics.
        ld    a,0
        call  SetGameInfoPanelFieldAttributes
        ; Clean pixels.
        ld    hl,GAME_INFO_PANEL_START_ADDRESS
        ld    de,GAME_INFO_PANEL_START_ADDRESS+1
        ld    b,8
.CleanGameInfoPanelField1:
        push  hl
        push  de
        push  bc        
        ld    bc,(GAME_INFO_PANEL_WIDTH*GAME_INFO_PANEL_HEIGHT)-1
        ld    (hl),0
        ldir
        pop   bc
        pop   de
        pop   hl
        call  DownHL
        call  DownDE
        djnz  .CleanGameInfoPanelField1
        ; Set base color;
        ld    a,7
        call  SetGameInfoPanelFieldAttributes
        ret
; END - CleanGameInfoPanelField
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - SetGameInfoPanelFieldAttributes
; A - Attribute color number.
SetGameInfoPanelFieldAttributes:
        ld    hl,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES
        ld    de,GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES+1
        ld    bc,(GAME_INFO_PANEL_WIDTH*GAME_INFO_PANEL_HEIGHT)-1
        ld    (hl),a
        ldir
        ret
; END - SetGameInfoPanelFieldAttributes
;-------------------------------------------------------------------------------

; Start address of the game info panel field.
GAME_INFO_PANEL_START_ADDRESS             equ 16384

; Start attributes address of the game info panel field.
GAME_INFO_PANEL_START_ADDRESS_ATTRIBUTES  equ 22528

; Info panel width.
GAME_INFO_PANEL_WIDTH equ 32

; Info panel height.
GAME_INFO_PANEL_HEIGHT equ 4
