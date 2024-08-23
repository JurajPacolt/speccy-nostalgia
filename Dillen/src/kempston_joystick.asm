; Example of the kempston joystick event reading.

; TODO

KYloop1:
        in    a,(31)
        cp    KEMP_JOY_FIRE
        jr    z,KYend
        jp    KYloop1
KYend:
        ret

; Kempston joystick constants.

KEMP_JOY_FIRE   equ 16
KEMP_JOY_UP     equ 8
KEMP_JOY_DOWN   equ 4
KEMP_JOY_LEFT   equ 2
KEMP_JOY_RIGHT  equ 1
KEMP_JOY_NONE   equ 0
