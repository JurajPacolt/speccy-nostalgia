;###############################################################################
;##### The self starting tape: a one line BASIC loader and the game after it. ###
;##### It is assembled after the snapshot is already written, so the BASIC ######
;##### may sit in the low memory without ever landing in DarkIsland1.sna. #######
;###############################################################################

TAPE_BASIC_ADDRESS      equ 23552
TAPE_CLEAR_ADDRESS      equ @EntryPoint-1

TAPE_BASIC_CODE         equ 0xAF
TAPE_BASIC_USR          equ 0xC0
TAPE_BASIC_BORDER       equ 0xE7
TAPE_BASIC_LOAD         equ 0xEF
TAPE_BASIC_RANDOMIZE    equ 0xF9
TAPE_BASIC_CLEAR        equ 0xFD
TAPE_BASIC_NUMBER       equ 0x0E

; One line that starts by itself:
;   10 BORDER 0:CLEAR 24999:LOAD "" CODE:RANDOMIZE USR 25000
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

        defb  TAPE_BASIC_LOAD,'"','"',TAPE_BASIC_CODE,":"

        defb  TAPE_BASIC_RANDOMIZE,TAPE_BASIC_USR
        defb  "25000",TAPE_BASIC_NUMBER,0,0
        defw  @EntryPoint
        defb  0,13
.LineEnd:
TapeBasicLoaderEnd:

        emptytap "DarkIsland1.tap"
        savetap  "DarkIsland1.tap",BASIC,"DARKISLAND",TapeBasicLoader,TapeBasicLoaderEnd-TapeBasicLoader,10
        savetap  "DarkIsland1.tap",CODE,"DARKISLAND",@EntryPoint,@ProgramEnd-@EntryPoint,@EntryPoint
