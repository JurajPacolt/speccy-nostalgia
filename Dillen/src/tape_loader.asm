;###############################################################################
;##### Self-starting TAP: BASIC loader, loading screen and game code. ##########
;###############################################################################

TAPE_BASIC_ADDRESS      equ 23552
TAPE_SCREEN_ADDRESS     equ 16384
TAPE_SCREEN_LENGTH      equ 6912
TAPE_CLEAR_ADDRESS      equ @EntryPoint-1

TAPE_BASIC_SCREEN       equ 0xAA
TAPE_BASIC_CODE         equ 0xAF
TAPE_BASIC_USR          equ 0xC0
TAPE_BASIC_BORDER       equ 0xE7
TAPE_BASIC_LOAD         equ 0xEF
TAPE_BASIC_RANDOMIZE    equ 0xF9
TAPE_BASIC_CLEAR        equ 0xFD
TAPE_BASIC_NUMBER       equ 0x0E

; A one-line autorun program:
;   10 BORDER 0:CLEAR 24999:LOAD "" SCREEN$:LOAD "" CODE:
;      RANDOMIZE USR 25000
        org   TAPE_BASIC_ADDRESS
TapeBasicLoader:
        defb  0,10
        defw  .LineEnd-.LineStart
.LineStart:
        defb  TAPE_BASIC_BORDER,"0",TAPE_BASIC_NUMBER,0,0
        defw  0
        defb  0,":"

        defb  TAPE_BASIC_CLEAR,"24999",TAPE_BASIC_NUMBER,0,0
        defw  TAPE_CLEAR_ADDRESS
        defb  0,":"

        defb  TAPE_BASIC_LOAD,'"','"',TAPE_BASIC_SCREEN,":"
        defb  TAPE_BASIC_LOAD,'"','"',TAPE_BASIC_CODE,":"

        defb  TAPE_BASIC_RANDOMIZE,TAPE_BASIC_USR
        defb  "25000",TAPE_BASIC_NUMBER,0,0
        defw  @EntryPoint
        defb  0,13
.LineEnd:
TapeBasicLoaderEnd:

; Assemble the strict 6912-byte screen into VRAM only after the SNA has already
; been saved. This makes it available to SAVETAP without changing Dillen.sna.
        org   TAPE_SCREEN_ADDRESS
TapeLoadingScreen:
        incbin  "binary/dillen-loading.scr"
TapeLoadingScreenEnd:
        assert TapeLoadingScreenEnd-TapeLoadingScreen == TAPE_SCREEN_LENGTH

        emptytap "Dillen.tap"
        savetap  "Dillen.tap",BASIC,"DILLEN",TapeBasicLoader,TapeBasicLoaderEnd-TapeBasicLoader,10
        savetap  "Dillen.tap",CODE,"DILLEN SCR",TapeLoadingScreen,TAPE_SCREEN_LENGTH,TAPE_SCREEN_ADDRESS
        savetap  "Dillen.tap",CODE,"DILLEN",@EntryPoint,@ProgramEnd-@EntryPoint,@EntryPoint
