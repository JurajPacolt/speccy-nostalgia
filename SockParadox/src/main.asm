; BASIC COMPILER CONFIGURATION
        device zxspectrum128

; COMPILE TO ADDRESS
        org 32768

; ENTRY POINT
Start:
        ; DO NOT disable interrupts!
        
        call  GameMainLoop
        
        ret

; INCLUDES - DATA MUST BE FIRST
        include "game_data.asm"

; BINARY DATA
MainFontData:
        incbin "..\gfx\font4x8.chr"

        include "text_utils.asm"
        include "text_system.asm"
        include "keyboard.asm"
        include "object_select.asm"
        include "action_system.asm"
        include "game_engine.asm"

; COMPILER OUTPUT
        savesna "SockParadox.sna", Start
