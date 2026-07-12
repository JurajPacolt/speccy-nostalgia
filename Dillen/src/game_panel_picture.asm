;-------------------------------------------------------------------------------
; BEGIN - Picture of the game's panel: the name of the game and the plant with
;         the leaves and the flowers. The panel has 32x3 characters and every
;         character is one tile. Tile 0 is empty, it isn't in the data. The
;         places of the lives, of the energy and of the room's description are
;         empty, the game is drawing them.
PanelTiles:
        ; Tiles 1-10, 22-32 and 44-46 form the readable handwritten Dillen logo.
        ; Tile 1
        defb  %00000000
        defb  %00000000
        defb  %00000011
        defb  %00000111
        defb  %00000011
        defb  %00000011
        defb  %00000111
        defb  %00000111
        ; Tile 2
        defb  %00000000
        defb  %00000000
        defb  %11111111
        defb  %11111111
        defb  %11110011
        defb  %10000000
        defb  %10000000
        defb  %10000000
        ; Tile 3
        defb  %00000000
        defb  %00000000
        defb  %11100000
        defb  %11111000
        defb  %11111110
        defb  %00011110
        defb  %00001111
        defb  %00001111
        ; Tile 4
        defb  %00000000
        defb  %00000011
        defb  %00000111
        defb  %00000111
        defb  %00000000
        defb  %00000000
        defb  %00000110
        defb  %00001110
        ; Tile 5
        defb  %00000000
        defb  %10000000
        defb  %10000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; Tile 6
        defb  %00000000
        defb  %00111000
        defb  %01111000
        defb  %01111000
        defb  %01110000
        defb  %01110000
        defb  %11110000
        defb  %11100000
        ; Tile 7
        defb  %00000000
        defb  %00000011
        defb  %00000111
        defb  %00000111
        defb  %00000111
        defb  %00001111
        defb  %00001110
        defb  %00001110
        ; Tile 8
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00111110
        defb  %01111111
        defb  %11110111
        ; Tile 9
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000001
        defb  %00000011
        ; Tile 10
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %11000000
        defb  %11001111
        ; Tile 11
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %11110001
        ; Tile 12
        defb  %00111000
        defb  %01111100
        defb  %11010110
        defb  %10110010
        defb  %11000110
        defb  %01101100
        defb  %10111000
        defb  %00000000
        ; Tile 13
        defb  %00001000
        defb  %00011000
        defb  %00111100
        defb  %01101100
        defb  %00111100
        defb  %00011000
        defb  %00001000
        defb  %00001000
        ; Tile 14
        defb  %00000000
        defb  %00000001
        defb  %00000011
        defb  %00000111
        defb  %00000111
        defb  %00000010
        defb  %00000000
        defb  %00001111
        ; Tile 15
        defb  %11110000
        defb  %11111000
        defb  %10111000
        defb  %10110000
        defb  %01100000
        defb  %11000000
        defb  %00000000
        defb  %11111111
        ; Tile 16
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %11111111
        ; Tile 17
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %11111000
        ; Tile 18
        defb  %00000000
        defb  %00000000
        defb  %00000001
        defb  %00000011
        defb  %00000111
        defb  %00000111
        defb  %00000010
        defb  %00000000
        ; Tile 19
        defb  %00000000
        defb  %11110000
        defb  %11111000
        defb  %10111000
        defb  %10110000
        defb  %01100000
        defb  %11000000
        defb  %00000111
        ; Tile 20
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000111
        defb  %11111000
        ; Tile 21
        defb  %00111000
        defb  %01101100
        defb  %11000110
        defb  %10010010
        defb  %11011110
        defb  %11101100
        defb  %00111000
        defb  %00000000
        ; Tile 22
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %10000000
        ; Tile 23
        defb  %00000111
        defb  %00000111
        defb  %00001111
        defb  %00001111
        defb  %00001111
        defb  %00001111
        defb  %00000111
        defb  %00000000
        ; Tile 24
        defb  %10000000
        defb  %00000000
        defb  %00000011
        defb  %01111111
        defb  %11111111
        defb  %11110000
        defb  %00000000
        defb  %00000000
        ; Tile 25
        defb  %00011110
        defb  %01111100
        defb  %11110000
        defb  %11000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; Tile 26
        defb  %00011110
        defb  %00011110
        defb  %00011110
        defb  %00011110
        defb  %00011110
        defb  %00001111
        defb  %00000111
        defb  %00000000
        ; Tile 27
        defb  %00000000
        defb  %00000001
        defb  %00000111
        defb  %00011110
        defb  %01111100
        defb  %11110000
        defb  %11100000
        defb  %00000000
        ; Tile 28
        defb  %11100000
        defb  %11100000
        defb  %11100000
        defb  %11100000
        defb  %11111111
        defb  %01111111
        defb  %00000000
        defb  %00000000
        ; Tile 29
        defb  %00001110
        defb  %00011110
        defb  %01111110
        defb  %11101110
        defb  %11001111
        defb  %00000111
        defb  %00000000
        defb  %00000000
        ; Tile 30
        defb  %00000001
        defb  %00000011
        defb  %00000111
        defb  %00011111
        defb  %11111101
        defb  %11110000
        defb  %00000000
        defb  %00000000
        ; Tile 31
        defb  %11101110
        defb  %11011100
        defb  %11111000
        defb  %11100000
        defb  %11100011
        defb  %11111111
        defb  %01111110
        defb  %00000000
        ; Tile 32
        defb  %00000011
        defb  %00000111
        defb  %00011111
        defb  %01111111
        defb  %11100111
        defb  %10000011
        defb  %00000000
        defb  %00000000
        ; Tile 33
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %11111111
        defb  %11111111
        ; Tile 34
        defb  %00000001
        defb  %00000011
        defb  %00000111
        defb  %00000111
        defb  %00000010
        defb  %00000001
        defb  %11111111
        defb  %11111111
        ; Tile 35
        defb  %11111000
        defb  %10111001
        defb  %10110010
        defb  %01100010
        defb  %11000111
        defb  %11111111
        defb  %11111100
        defb  %00000000
        ; Tile 36
        defb  %00000000
        defb  %00000000
        defb  %00000011
        defb  %00111111
        defb  %11111111
        defb  %11101110
        defb  %00001111
        defb  %00000111
        ; Tile 37
        defb  %00001001
        defb  %00011111
        defb  %11111110
        defb  %11100000
        defb  %10000000
        defb  %11000000
        defb  %01100000
        defb  %01110000
        ; Tile 38
        defb  %11111111
        defb  %11110000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; Tile 39
        defb  %11111111
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; Tile 40
        defb  %11111111
        defb  %00000010
        defb  %00000111
        defb  %00000111
        defb  %00000011
        defb  %00000001
        defb  %00000000
        defb  %00000000
        ; Tile 41
        defb  %11111111
        defb  %11000111
        defb  %01100000
        defb  %10110000
        defb  %10111000
        defb  %11111000
        defb  %11110000
        defb  %00000000
        ; Tile 42
        defb  %01100000
        defb  %01011010
        defb  %01110111
        defb  %01101111
        defb  %11101110
        defb  %11111100
        defb  %01111000
        defb  %00100000
        ; Tile 43
        defb  %00000000
        defb  %00011110
        defb  %00111111
        defb  %01110111
        defb  %11110110
        defb  %11101100
        defb  %01011000
        defb  %00000000
        ; Tile 44
        defb  %10011111
        defb  %10111001
        defb  %11110001
        defb  %11100001
        defb  %11000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        ; Tile 45
        defb  %11000000
        defb  %11000000
        defb  %11000001
        defb  %11101111
        defb  %11111110
        defb  %01111000
        defb  %00000000
        defb  %00000000
        ; Tile 46
        defb  %00110000
        defb  %11100000
        defb  %11000000
        defb  %10000000
        defb  %00000000
        defb  %00000000
        defb  %00000000
        defb  %00000000

; Number of the tile for every character of the panel.
PanelMap:
        defb    1,   2,   3,   4,   5,   6,   7,   5,   8,   9,  10,  22,   0,   0,   0,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,  21,   0,   0,   0,   0,   0,   0
        defb   23,  24,  25,  26,  27,  28,  29,  30,  31,  32,  44,  45,  46,  33,  34,  35,  36,  37,  38,  39,  40,  41,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
        defb   42,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  43

; Color of every character of the panel.
PanelAttributes:
        defb   70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  70,   0,   0,  68,  67,  67,  68,  68,  68,  68,  68,  68,  68,  67,   0,  66,  66,  66,  66,  66
        defb   70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  70,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68,  68
        defb   68,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  71,  68
; END
;-------------------------------------------------------------------------------
