; BASIC COMPILER CONFIGURATION
        device zxspectrum128

; BASIC loader to auto-start the game
        org 23755

BasicStart:
        defb 0,10               ; Line 10
        defw BasicLineEnd-BasicLine
BasicLine:
        defb 0xEF               ; REM
        defb 0x22               ; "
BasicCode:
        org 25000

; ENTRY POINT
@EntryPoint:
        di
        
        call  GameMainLoop
        
        ei
        ret

; INCLUDES
        include "text_utils.asm"
        include "keyboard.asm"
        include "menu.asm"
        include "game_engine.asm"
        include "game_data.asm"

; BINARY DATA
MainFontData:
        incbin "..\gfx\std8x8.chr"

BasicLineEnd:
        defb 0x0D               ; End of line
        
        org BasicLine+1
        defb 0xFD               ; CLEAR
        defb 0xB0               ; VAL
        defb '"'
        defm "24999"
        defb '"',':'
        defb 0xF9               ; RANDOMIZE
        defb 0xC0               ; USR
        defb 0xB0               ; VAL
        defb '"'
        defm "25000"
        defb '"',0x0D

; COMPILER OUTPUT
        savesna "SockParadox.sna", BasicStart
