# Ponožkový Paradox 🧦

Textová adventúra pre ZX Spectrum 128K napísaná v assembleri.

## 📖 Príbeh

Je 7:55 ráno a budík už reve. Máš len 5 minút na to, aby si našiel druhú ponožku a stihl autobus! Preskúmaj byt, riešaj hádanky a komunikuj s obyvateľmi (mačkou Murom, Cicou v práčke a umeleckým holubom).

## 🎮 Ovládanie

### Pohyb po miestnostiach
- **Q** - Sever (North)
- **A** - Juh (South)
- **O** - Východ (East)
- **P** - Západ (West)

### Akcie
- **T** - Zober predmet (Take)
  - Pri viacerých predmetoch: **Q/A** na výber, **SPACE/ENTER** na potvrdenie, **BACKSPACE** na zrušenie
- **E** - Preskúmaj predmet (Examine)
  - Zobrazí detailný popis predmetov v miestnosti a inventári
  - Pri viacerých predmetoch: **Q/A** na výber, **SPACE/ENTER** na potvrdenie
- **U** - Použi predmet (Use)
  - Použi predmet z inventára v aktuálnej miestnosti
  - Pri viacerých predmetoch: **Q/A** na výber, **SPACE/ENTER** na potvrdenie, **BACKSPACE** na zrušenie

## 🗺️ Herné miestnosti

1. **Spálňa** - Tvoja chaotická izba, kde všetko začína
2. **Chodba** - Spojovací uzol medzi miestnosťami
3. **Kúpeľňa** - S prácou plnou záhad
4. **Kuchyňa** - Miesto kde nájdeš dôležité veci
5. **Obývačka** - Kráľovstvo mačky Mura
6. **Balkón** - S holubom čo má umelecké ambície
7. **Pod pohovkou** - Temný svet pod nábytkom
8. **Práčka** - Domov Cici, ktorá hľadá látkové pecivo
9. **Tajná miestnosť** - Zámečok je kľúčom
10. **Finále** - Cieľ tvojej cesty!

## 📦 Objekty a ich použitie

- **SOCK1** - Prvá ponožka (spálňa)
- **STRING** - Šnúrka (chodba) → použi na balkóne pre holuba
- **NOTE** - Lístok (kuchyňa) → nakŕm Mura v obývačke
- **KEY** - Kľúč (kuchyňa)
- **CLOTH** - Látka/zašpinená bunda (pod pohovkou) → daj Cici v práčke
- **SMALL_KEY** - Malý kľúč (od Cici) → odomkne tajnú miestnosť
- **DIRTY_CLOTH** - Čistá bunda (od holuba)
- **SOCK2** - Druhá ponožka! (finále) - **VÝHRA!** 🎉

## 🎯 Riešenie hry

1. Zober **SOCK1** v spálni
2. Zober **STRING** v chodbe
3. Zober **NOTE** a **KEY** v kuchyni
4. **Použi NOTE (U)** v obývačke → nakŕmi Mura → **odomkne sa JUH**
5. Choď JUH pod pohovku, zober **CLOTH**
6. Choď do práčky (cez kúpeľňu), **použi CLOTH (U)** → daj ho Cici → získaš **SMALL_KEY**
7. Choď na balkón, **použi STRING (U)** → daj šnúrku holubovi → získaš **DIRTY_CLOTH**
8. Vráť sa do spálne, **použi SMALL_KEY (U)** → **odomkne sa VÝCHOD**
9. Choď VÝCHOD do tajnej miestnosti → VÝCHOD do finále
10. Zober **SOCK2** → **VÝHRA!** 🧦🧦

## 🛠️ Štruktúra projektu

```
SockParadox/
├── src/
│   ├── main.asm           - Hlavný vstupný bod
│   ├── game_engine.asm    - Herný engine (pohyb, akcie, UI)
│   ├── text_utils.asm     - 4×8 font rendering engine
│   ├── font4x8.asm        - Font data (64×24 znakov)
│   └── game_data.asm      - Auto-generované herné dáta
├── gfx/
│   └── font4x8.png        - Zdrojový obrázok fontu
├── rooms.json             - Definícia miestností, objektov, NPCs
├── strings.xml            - Všetky texty hry
├── generate_game_data.py  - Python generátor herných dát
├── build.bat              - Build script (Windows)
├── build.sh               - Build script (Linux/Mac)
└── SockParadox.sna        - Výsledný snapshot
```

## 🔨 Build

### Windows
```bash
build.bat
```

### Linux/Mac
```bash
chmod +x build.sh
./build.sh
```

**Build proces:**
1. Spustí `generate_game_data.py` ktorý vytvorí `src/game_data.asm` z `rooms.json` a `strings.xml`
2. Skompiluje ASM súbory pomocou **sjasmplus**
3. Vytvorí `SockParadox.sna` snapshot súbor

### Požiadavky
- **Python 3.x**
- **sjasmplus** (Z80 cross-assembler)

## 🚀 Spustenie

Nahrajte `SockParadox.sna` do emulátora ZX Spectrum:
- **Fuse** (http://fuse-emulator.sourceforge.net/)
- **ZXSpin** (http://zxspin.webpark.pl/)
- **SpecEmu** (http://www.specem.com/)
- **Retro Virtual Machine** (https://www.retrovirtualmachine.org/)

## 📊 Technické detaily

- **Platforma:** ZX Spectrum 128K
- **Formát:** .SNA snapshot
- **Video mód:** Text 64×24 znakov (4×8 pixelov/znak)
- **VRAM layout:** Štandardný ZX Spectrum layout (3 tretiny)
- **Assembler:** sjasmplus
- **Veľkosť inventára:** Max 9 predmetov
- **Počet miestností:** 10
- **Počet objektov:** 9
- **Počet NPCs:** 3

## 🧩 Pridávanie obsahu

### Nová miestnosť
Pridaj do `rooms.json`:
```json
{
  "roomCode": "NEW_ROOM",
  "nameKey": "room_new_name",
  "descriptionKey": "room_new_desc",
  "objects": ["OBJECT_CODE"],
  "compass": [
    { "direction": "NORTH", "wayTo": "OTHER_ROOM" }
  ]
}
```

### Nový objekt
Pridaj do `objectDefinitions` v `rooms.json`:
```json
{
  "code": "NEW_OBJECT",
  "nameKey": "obj_new_name",
  "descriptionKey": "obj_new_desc",
  "pickable": true
}
```

### Nový text
Pridaj do `strings.xml`:
```xml
<string name="room_new_name">Nazov miestnosti</string>
<string name="room_new_desc">Popis miestnosti.</string>
```

### Použitie predmetu s efektom
V `rooms.json` pridaj do NPC alebo miestnosti:
```json
"actions": [
  {
    "commandKey": "action_use_key",
    "conditions": [{ "hasObject": "KEY" }],
    "resultKey": "action_use_key_result",
    "effects": [
      { "unlockRoom": "SECRET_ROOM" },
      { "removeFromInventory": "KEY" },
      { "addToInventory": "NEW_ITEM" }
    ]
  }
]
```

Po zmene `rooms.json` alebo `strings.xml` **znovu spusti build!**

## 🙏 Poďakovanie

- **sjasmplus** - https://github.com/z00m128/sjasmplus
- Inšpirované klasickými text adventures ZX Spectrum éry
- Font design: Custom 4×8 pixel font

---

**Vyrobené s ❤️ pre ZX Spectrum retro nadšencov**
