; Automaticky generovane herne data
; Ponozkovy Paradox

; === CONSTANTS ===
NUM_ROOMS     equ 10
NUM_OBJECTS   equ 9
NUM_NPCS      equ 3

; Room IDs
ROOM_BEDROOM equ 0
ROOM_HALLWAY equ 1
ROOM_BATHROOM equ 2
ROOM_KITCHEN equ 3
ROOM_LIVING_ROOM equ 4
ROOM_BALCONY equ 5
ROOM_SOFA_UNDERWORLD equ 6
ROOM_WASHING_MACHINE equ 7
ROOM_BEDROOM_SECRET equ 8
ROOM_FINAL equ 9

; === ROOM DATA ===

; Room 0: BEDROOM
Room_0_Name:
    defb "Spalna", 0
Room_0_Desc:
    defb "Budik reve, je 7:55. Na zemi vidis len jednu ponozku. Postel je v troskach a niekde mnaukne macka.", 0
Room_0_Nav:
    defb 255,1,255,255  ; N,S,E,W

; Room 1: HALLWAY
Room_1_Name:
    defb "Chodba", 0
Room_1_Desc:
    defb "Uzka chodba s obrazom stryka a bundou na vesiaku. Na zemi sa vala snurka.", 0
Room_1_Nav:
    defb 0,2,4,3  ; N,S,E,W

; Room 2: BATHROOM
Room_2_Name:
    defb "Kupelna", 0
Room_2_Desc:
    defb "Kupelna plna pasty. Pracka podivne huci a kos na bielizen je prazdny.", 0
Room_2_Nav:
    defb 1,255,255,255  ; N,S,E,W

; Room 3: KITCHEN
Room_3_Name:
    defb "Kuchyna", 0
Room_3_Desc:
    defb "Vonia tu kava. Na linke lezi odkaz od manzelky a kluc od bytu.", 0
Room_3_Nav:
    defb 255,255,1,255  ; N,S,E,W

; Room 4: LIVING_ROOM
Room_4_Name:
    defb "Obyvacka", 0
Room_4_Desc:
    defb "Tu vladne macka Muro. Na gauci spi a spod neho trci kusok latky.", 0
Room_4_Nav:
    defb 255,255,5,1  ; N,S,E,W

; Room 5: BALCONY
Room_5_Name:
    defb "Balkon", 0
Room_5_Desc:
    defb "Maly balkon s bieliznou a holubom, ktory ma umelecke ambicie.", 0
Room_5_Nav:
    defb 255,255,255,4  ; N,S,E,W

; Room 6: SOFA_UNDERWORLD
Room_6_Name:
    defb "Pod gaucom", 0
Room_6_Desc:
    defb "Pod gaucom najdes hracku a kusok latky  zrejme cast stratenej ponozky.", 0
Room_6_Nav:
    defb 4,255,255,255  ; N,S,E,W

; Room 7: WASHING_MACHINE
Room_7_Name:
    defb "Pracka", 0
Room_7_Desc:
    defb "Z pracky vyskocila Cica. V labkach drzi maly klucik.", 0
Room_7_Nav:
    defb 2,255,255,255  ; N,S,E,W

; Room 8: BEDROOM_SECRET
Room_8_Name:
    defb "Spalna  skrinka", 0
Room_8_Desc:
    defb "Vratil si sa do spalne a otvoril zamknutu skrinku. Vo vnutri je len vtipny odkaz.", 0
Room_8_Nav:
    defb 255,1,9,0  ; N,S,E,W

; Room 9: FINAL
Room_9_Name:
    defb "Finale", 0
Room_9_Desc:
    defb "Stojis v chodbe s bundou a klucom. Vo vaku nachadzas druhu ponozku. Mas par!", 0
Room_9_Nav:
    defb 255,255,255,255  ; N,S,E,W

; Room table
RoomTable:
    defw Room_0_Name, Room_0_Desc, Room_0_Nav
    defw Room_1_Name, Room_1_Desc, Room_1_Nav
    defw Room_2_Name, Room_2_Desc, Room_2_Nav
    defw Room_3_Name, Room_3_Desc, Room_3_Nav
    defw Room_4_Name, Room_4_Desc, Room_4_Nav
    defw Room_5_Name, Room_5_Desc, Room_5_Nav
    defw Room_6_Name, Room_6_Desc, Room_6_Nav
    defw Room_7_Name, Room_7_Desc, Room_7_Nav
    defw Room_8_Name, Room_8_Desc, Room_8_Nav
    defw Room_9_Name, Room_9_Desc, Room_9_Nav

; === OBJECT DATA ===

; Object 0: SOCK1
Obj_0_Name:
    defb "Cerveno-biela ponozka (lava)", 0
Obj_0_Desc:
    defb "Tvoja vitazna ponozka s logom oblubeneho timu.", 0

; Object 1: SOCK2
Obj_1_Name:
    defb "Cerveno-biela ponozka (prava)", 0
Obj_1_Desc:
    defb "Stratena ponozka, ktora sposobila vsetky tvoje problemy.", 0

; Object 2: STRING
Obj_2_Name:
    defb "Snurka", 0
Obj_2_Desc:
    defb "Zdanlivo bezcenny kusok snurky, ale mozno sa zide.", 0

; Object 3: KEY
Obj_3_Name:
    defb "Kluc od bytu", 0
Obj_3_Desc:
    defb "Kovovy kluc, ktory ta konecne dostane von z bytu.", 0

; Object 4: CLOTH
Obj_4_Name:
    defb "Kusok latky", 0
Obj_4_Desc:
    defb "Uz ohryzeny zvysok tvojej stratenej ponozky.", 0

; Object 5: SMALL_KEY
Obj_5_Name:
    defb "Maly klucik", 0
Obj_5_Desc:
    defb "Cica ho pustila po vyjednavani. Hodi sa na zamknutu skrinku.", 0

; Object 6: NOTE
Obj_6_Name:
    defb "Odkaz od manzelky", 0
Obj_6_Desc:
    defb "Sla som k mame. Macku si nekrmil! A nehladaj ponozky v chladnicke.", 0

; Object 7: DIRTY_JACKET
Obj_7_Name:
    defb "Zaspinena bunda", 0
Obj_7_Desc:
    defb "Holub sa na nej umelecky vyjadril.", 0

; Object 8: CARD
Obj_8_Name:
    defb "Karticka", 0
Obj_8_Desc:
    defb "Maly papierik s textom: V tvojom oblubenom sportovom vaku!", 0

; Object table
ObjectTable:
    defw Obj_0_Name, Obj_0_Desc
    defw Obj_1_Name, Obj_1_Desc
    defw Obj_2_Name, Obj_2_Desc
    defw Obj_3_Name, Obj_3_Desc
    defw Obj_4_Name, Obj_4_Desc
    defw Obj_5_Name, Obj_5_Desc
    defw Obj_6_Name, Obj_6_Desc
    defw Obj_7_Name, Obj_7_Desc
    defw Obj_8_Name, Obj_8_Desc

; Object locations (255 = in inventory, 254 = not visible)
ObjectLocations:
    defb 0    ; SOCK1 - in BEDROOM
    defb 9    ; SOCK2 - in FINAL
    defb 1    ; STRING - in HALLWAY
    defb 3    ; KEY - in KITCHEN
    defb 6    ; CLOTH - in SOFA_UNDERWORLD
    defb 254    ; SMALL_KEY - hidden initially
    defb 3    ; NOTE - in KITCHEN
    defb 254    ; DIRTY_JACKET - hidden initially
    defb 8    ; CARD - in BEDROOM_SECRET
