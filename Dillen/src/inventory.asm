;###############################################################################
;##### Player's inventory: carrying up to three items and a window to put ######
;##### one of them back down. #####################################################
;###############################################################################
;
; ENTER while standing on a ground item picks it up (if there is a free slot)
; and always opens the inventory window. ENTER anywhere else just opens it. In
; the window, 7/Q (up) and 6/A (down) - the digits are the same keys used by
; the debug room switcher - move a highlight (a bright color bar, not text -
; the font has no glyph for '<','=' or '>') between the three carried slots;
; ENTER uses the pickaxe when the player is on the old bridge. In every other
; case it drops the selected item here and closes the window.
; SPACE closes the window without dropping anything.
;
; The window is a modal pause: while it is open, GameMainLoop (game.asm) skips
; the whole room/player pipeline, so nothing animates underneath it. Closing it
; does not restore saved pixels - it simply invalidates every room-scoped
; module's dirty-room cache (the same trick CollectItem already relies on), so
; the ordinary per-frame pipeline repaints the whole field, items included, on
; the very next frame.
;-------------------------------------------------------------------------------

INV_MAX_ITEMS      equ 3
INV_STATE_CLOSED   equ 0
INV_STATE_OPEN     equ 1

; Character-cell geometry of the window. It sits entirely inside the game
; field (rows 5-22, columns 1-30), well clear of the 1-character border.
INV_WIN_ROW        equ 7
INV_WIN_COL        equ 4
INV_WIN_WIDTH      equ 24
INV_WIN_HEIGHT     equ 8

; Each carried slot is one plain text row.
INV_ROW_SLOT1      equ INV_WIN_ROW+3
INV_ROW_SLOT2      equ INV_WIN_ROW+4
INV_ROW_SLOT3      equ INV_WIN_ROW+5

; Where a slot's name starts - a blank column in from the border, so the text
; doesn't sit flush against it.
INV_TEXT_COL       equ INV_WIN_COL+2

; Colors. A dark window: a dim green frame (yellow at her corners) around a
; black interior with white text, and a bright green highlight bar for
; whichever row the cursor is on - color carries the selection, since the
; font has no usable marker character to draw one with.
INV_ATTR_BORDER    equ 4   ; Green ink on black paper, not bright - a dim frame.
INV_ATTR_CORNER    equ 70  ; Bright yellow ink on black paper.
INV_ATTR_BASE      equ 71  ; Bright white ink on black paper.
INV_ATTR_HILITE    equ 96  ; Bright black ink on green paper.

;-------------------------------------------------------------------------------
; BEGIN - InventoryReset - Empty the inventory and close the window.
InventoryReset:
        ld    hl,PlayerInventory
        ld    de,PlayerInventory+1
        ld    bc,INV_MAX_ITEMS-1
        ld    (hl),0
        ldir
        xor   a
        ld    (_INV_State),a
        ld    (_INV_EnterLatch),a
        ld    (_INV_UpLatch),a
        ld    (_INV_DownLatch),a
        ld    (_INV_SpaceLatch),a
        ld    (_INV_Cursor),a
        ld    (_INV_PendingOpen),a
        ret
; END - InventoryReset
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - InventoryScanEnterKey - Called once per frame while the window is
; closed. A fresh ENTER press picks up a ground item, then opens the window
; one frame later - not on the very same frame - so the ordinary pipeline
; (ShowRoom, ItemsInRooms and the rest, still each called exactly once per
; frame, the way every other part of the game relies on) gets to redraw the
; field and let the picked-up item vanish before the window is drawn over it.
; Opening one frame late is not something a player can perceive.
InventoryScanEnterKey:
        ld    a,(_INV_PendingOpen)
        or    a
        jr    z,.ISEK_CheckKey
        xor   a
        ld    (_INV_PendingOpen),a
        jp    InventoryOpen

.ISEK_CheckKey:
        call  _INV_ReadEnterEdge
        ret   z ; No fresh press this frame.

        call  InventoryTryPickUp
        ld    a,1
        ld    (_INV_PendingOpen),a
        ret
; END - InventoryScanEnterKey
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - InventoryHandleOpen - Called once per frame while the window is
; open. Moves the highlight, drops the highlighted item, or closes.
InventoryHandleOpen:
        call  _INV_ReadUpEdge
        jr    z,.IHO_CheckDown
        ld    a,255
        call  _INV_MoveCursor
        call  _INV_DrawContents
        ret
.IHO_CheckDown:
        call  _INV_ReadDownEdge
        jr    z,.IHO_CheckEnter
        ld    a,1
        call  _INV_MoveCursor
        call  _INV_DrawContents
        ret
.IHO_CheckEnter:
        call  _INV_ReadEnterEdge
        jr    z,.IHO_CheckSpace

        ld    a,(_INV_Cursor)
        ld    hl,PlayerInventory
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl)
        or    a
        ret   z ; Nothing carried in this slot, ENTER does nothing.
        ld    (hl),0
        ld    c,a
        cp    ITEM_PICKAXE
        jr    z,.IHO_TryUseItem
        cp    ITEM_CROSS
        jr    z,.IHO_TryUseItem
        cp    ITEM_MATCH
        jr    z,.IHO_TryUseItem
        cp    ITEM_DYNAMITE
        jr    z,.IHO_TryUseItem
        cp    ITEM_KEY
        jr    nz,.IHO_DropItem
.IHO_TryUseItem:
        call  UseItem
        jr    nc,.IHO_DropItem
        call  BeeperSfxUseItem
        jr    .IHO_Close
.IHO_DropItem:
        ld    a,c
        call  DropItem
.IHO_Close:
        jp    InventoryClose
.IHO_CheckSpace:
        call  _INV_ReadSpaceEdge
        ret   z
        jp    InventoryClose
; END - InventoryHandleOpen
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - InventoryTryPickUp - Pick up the item under the player, if any and if
; a slot is free. Silently does nothing otherwise.
; return CF=1 - an item was picked up, CF=0 - nothing to pick up or no free slot.
InventoryTryPickUp:
        call  PlayerStandsOnItem
        or    a
        ret   z ; CF=0 already, nothing under the player.

        ld    c,a ; The item's ID.
        ld    ix,PlayerInventory
        ld    b,INV_MAX_ITEMS
.ITU_FindSlot:
        ld    a,(ix+0)
        or    a
        jr    z,.ITU_SlotFree
        inc   ix
        djnz  .ITU_FindSlot
        or    a ; CF=0, already carrying three items.
        ret

.ITU_SlotFree:
        ld    a,c
        call  CollectItem ; CF=1 on success, kept through the LD below.
        ld    (ix+0),c
        ret
; END - InventoryTryPickUp
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - PlayerStandsOnItem - Is the player's footprint over a ground item in
; the actual room?
; return A - the item's ID (1..ITEM_COUNT), or 0.
PlayerStandsOnItem:
        ld    hl,RoomsMap
        ld    a,(ActualRoomInMap)
        ld    e,a
        ld    d,0
        add   hl,de
        ld    a,(hl)
        ld    (_INV_CheckRoomId),a

        ld    iy,ItemStates
        ld    ix,ItemDrawRecords
        ld    b,ITEM_COUNT
.PSOI_Loop:
        ld    a,(iy+0)
        ld    hl,_INV_CheckRoomId
        cp    (hl)
        jr    nz,.PSOI_Next

        ld    a,(ix+0)
        ld    (_INV_ItemLeft),a
        add   a,16
        ld    (_INV_ItemRight),a
        ld    a,(ix+1)
        ld    (_INV_ItemTop),a
        add   a,16
        ld    (_INV_ItemBottom),a

        ; Player's left edge must be left of the item's right edge.
        ld    a,(PlayerX)
        ld    hl,_INV_ItemRight
        cp    (hl)
        jr    nc,.PSOI_Next

        ; Player's right edge must be right of the item's left edge.
        ld    a,(PlayerX)
        add   a,PLAYER_FOOT_WIDTH
        ld    hl,_INV_ItemLeft
        cp    (hl)
        jr    c,.PSOI_Next
        jr    z,.PSOI_Next

        ; Player's top edge must be above the item's bottom edge.
        ld    a,(PlayerY)
        ld    hl,_INV_ItemBottom
        cp    (hl)
        jr    nc,.PSOI_Next

        ; Player's bottom edge must be below the item's top edge.
        ld    a,(PlayerY)
        add   a,PLAYER_SPRITE_HEIGHT
        ld    hl,_INV_ItemTop
        cp    (hl)
        jr    c,.PSOI_Next
        jr    z,.PSOI_Next

        ld    a,ITEM_COUNT
        sub   b
        inc   a
        ret

.PSOI_Next:
        inc   iy
        ld    de,ITEM_DRAW_RECORD_SIZE
        add   ix,de
        djnz  .PSOI_Loop

        xor   a
        ret
; END - PlayerStandsOnItem
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - InventoryOpen - Show the window, highlight on the first slot.
InventoryOpen:
        ld    a,INV_STATE_OPEN
        ld    (_INV_State),a
        xor   a
        ld    (_INV_Cursor),a
        ld    (_INV_UpLatch),a
        ld    (_INV_DownLatch),a
        ld    (_INV_SpaceLatch),a

        call  _INV_DrawWindow
        call  _INV_DrawContents
        jp    BeeperSfxInventoryOpen
; END - InventoryOpen
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BEGIN - InventoryClose - Hide the window by forcing every room-scoped module
; to repaint the field from scratch on the next frame.
InventoryClose:
        xor   a
        ld    (_INV_State),a
        call  BeeperSfxInventoryClose
        call  ItemsForceRedraw
        call  ResetTorches
        call  ResetStars
        call  ResetDeath
        ret
; END - InventoryClose
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Move the cursor to the next (or previous) of the three slots and redraw.
; A - +1 (down) or 255/-1 (up).
_INV_MoveCursor:
        cp    1
        jr    z,.IMC_Down

        ld    a,(_INV_Cursor)
        or    a
        jr    nz,.IMC_UpDec
        ld    a,3
.IMC_UpDec:
        dec   a
        ld    (_INV_Cursor),a
        ret

.IMC_Down:
        ld    a,(_INV_Cursor)
        inc   a
        cp    3
        jr    nz,.IMC_DownStore
        xor   a
.IMC_DownStore:
        ld    (_INV_Cursor),a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Edge-detected key readers. Each keeps its own latch, so a held key only
; fires once, and releasing it re-arms the next press.
;
; Port 49150 (H, J, K, L, Enter): bit 0 - Enter.
_INV_ReadEnterEdge:
        ld    bc,49150
        in    a,(c)
        bit   0,a
        jr    nz,.IRE_Released

        ld    a,(_INV_EnterLatch)
        or    a
        jr    nz,.IRE_NoEdge

        ld    a,1
        ld    (_INV_EnterLatch),a
        or    a
        ret
.IRE_Released:
        xor   a
        ld    (_INV_EnterLatch),a
        ret
.IRE_NoEdge:
        xor   a
        ret

; "Up" is key 7 (port 61438, bit 3, the debug cursor's "up") or key Q (port
; 64510, bit 0).
_INV_ReadUpEdge:
        ld    bc,61438
        in    a,(c)
        bit   3,a
        jr    z,.IUE_IsPressed
        ld    bc,64510
        in    a,(c)
        bit   0,a
        jr    z,.IUE_IsPressed

        xor   a
        ld    (_INV_UpLatch),a
        ret
.IUE_IsPressed:
        ld    a,(_INV_UpLatch)
        or    a
        jr    nz,.IUE_NoEdge

        ld    a,1
        ld    (_INV_UpLatch),a
        or    a
        ret
.IUE_NoEdge:
        xor   a
        ret

; "Down" is key 6 (port 61438, bit 4, the debug cursor's "down") or key A
; (port 65022, bit 0).
_INV_ReadDownEdge:
        ld    bc,61438
        in    a,(c)
        bit   4,a
        jr    z,.IDE_IsPressed
        ld    bc,65022
        in    a,(c)
        bit   0,a
        jr    z,.IDE_IsPressed

        xor   a
        ld    (_INV_DownLatch),a
        ret
.IDE_IsPressed:
        ld    a,(_INV_DownLatch)
        or    a
        jr    nz,.IDE_NoEdge

        ld    a,1
        ld    (_INV_DownLatch),a
        or    a
        ret
.IDE_NoEdge:
        xor   a
        ret

; Port 32766 (B, N, M, Symbol Shift, Space): bit 0 - Space.
_INV_ReadSpaceEdge:
        ld    bc,32766
        in    a,(c)
        bit   0,a
        jr    nz,.ISE_Released

        ld    a,(_INV_SpaceLatch)
        or    a
        jr    nz,.ISE_NoEdge

        ld    a,1
        ld    (_INV_SpaceLatch),a
        or    a
        ret
.ISE_Released:
        xor   a
        ld    (_INV_SpaceLatch),a
        ret
.ISE_NoEdge:
        xor   a
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw the whole window: a bordered box, reusing the field's own border tiles,
; with a blank black interior.
_INV_DrawWindow:
        xor   a
        ld    (_INV_DrawRow),a
.IDW_RowLoop:
        xor   a
        ld    (_INV_DrawCol),a
.IDW_ColLoop:
        call  _INV_TileForCell ; DE - tile data, A - her attribute.
        ld    (_INV_TileAttr),a

        ld    a,(_INV_DrawRow)
        add   a,INV_WIN_ROW
        ld    b,a
        ld    a,(_INV_DrawCol)
        add   a,INV_WIN_COL
        ld    c,a
        call  _INV_DrawTile

        ld    a,(_INV_DrawRow)
        add   a,INV_WIN_ROW
        ld    b,a
        ld    a,(_INV_DrawCol)
        add   a,INV_WIN_COL
        ld    c,a
        ld    a,(_INV_TileAttr)
        call  _INV_SetAttr

        ld    hl,_INV_DrawCol
        inc   (hl)
        ld    a,(hl)
        cp    INV_WIN_WIDTH
        jr    nz,.IDW_ColLoop

        ld    hl,_INV_DrawRow
        inc   (hl)
        ld    a,(hl)
        cp    INV_WIN_HEIGHT
        jr    nz,.IDW_RowLoop
        ret

; Which tile (and attribute) belongs at (_INV_DrawRow, _INV_DrawCol), relative
; to the window.
; return DE - tile data address, A - attribute.
_INV_TileForCell:
        ld    a,(_INV_DrawRow)
        or    a
        jr    z,.ITFC_EdgeRow
        cp    INV_WIN_HEIGHT-1
        jr    z,.ITFC_EdgeRow

        ld    a,(_INV_DrawCol)
        or    a
        jr    z,.ITFC_Vertical
        cp    INV_WIN_WIDTH-1
        jr    z,.ITFC_Vertical
        ld    de,_INV_GfxBlank
        ld    a,INV_ATTR_BASE
        ret
.ITFC_Vertical:
        ld    de,GfxGameBorderItem
        ld    a,INV_ATTR_BORDER
        ret
.ITFC_EdgeRow:
        ld    a,(_INV_DrawCol)
        or    a
        jr    z,.ITFC_Corner
        cp    INV_WIN_WIDTH-1
        jr    z,.ITFC_Corner
        ld    de,GfxGameBorderItem
        ld    a,INV_ATTR_BORDER
        ret
.ITFC_Corner:
        ld    de,GfxGameBorderCorner
        ld    a,INV_ATTR_CORNER
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw one 8x8 tile at a character cell.
; B - character row, C - character column, DE - tile data address.
_INV_DrawTile:
        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a
        ld    a,c
        add   a,a
        add   a,a
        add   a,a
        ld    c,a
        call  ScreenAddr
        call  DrawChar
        ret

; Set one character cell's attribute.
; B - character row, C - character column, A - attribute.
_INV_SetAttr:
        push  af
        call  AttrAddr
        pop   af
        ld    (hl),a
        ret

; Clear one character row of pixels, from character column C, for D characters.
; B - character row.
_INV_ClearRow:
.ICR_Char:
        push  bc
        push  de
        ld    a,b
        add   a,a
        add   a,a
        add   a,a
        ld    b,a
        ld    a,c
        add   a,a
        add   a,a
        add   a,a
        ld    c,a
        call  ScreenAddr
        ld    b,8
.ICR_Line:
        ld    (hl),0
        call  DownHL
        djnz  .ICR_Line
        pop   de
        pop   bc
        inc   c
        dec   d
        jr    nz,.ICR_Char
        ret

; Fill a rectangle of attributes.
; B - first char row, C - first char col, D - width in chars, E - height in
; rows, A - attribute.
_INV_FillBand:
        ld    (_INV_FillAttr),a
        ld    a,b
        ld    (_INV_FillRow),a
        ld    a,c
        ld    (_INV_FillFirstCol),a
        ld    a,d
        ld    (_INV_FillWidth),a
        ld    a,e
        ld    (_INV_FillRowsLeft),a
.IFB_RowLoop:
        ld    a,(_INV_FillFirstCol)
        ld    (_INV_FillCol),a
        ld    a,(_INV_FillWidth)
        ld    (_INV_FillColsLeft),a
.IFB_ColLoop:
        ld    a,(_INV_FillRow)
        ld    b,a
        ld    a,(_INV_FillCol)
        ld    c,a
        ld    a,(_INV_FillAttr)
        call  _INV_SetAttr

        ld    hl,_INV_FillCol
        inc   (hl)
        ld    hl,_INV_FillColsLeft
        dec   (hl)
        jr    nz,.IFB_ColLoop

        ld    hl,_INV_FillRow
        inc   (hl)
        ld    hl,_INV_FillRowsLeft
        dec   (hl)
        jr    nz,.IFB_RowLoop
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Redraw the three slots, highlighting whichever one the cursor is on with a
; bright color bar (there is no usable '>' glyph in this font). Cheap enough
; to just redo in full on every keypress.
_INV_DrawContents:
        xor   a
        call  _INV_DrawOneSlotBySelection
        ld    a,1
        call  _INV_DrawOneSlotBySelection
        ld    a,2
        jp    _INV_DrawOneSlotBySelection

; A - slot index (0..2). Draws that slot's row, highlighted if it's the
; cursor.
_INV_DrawOneSlotBySelection:
        ld    (_INV_TempSlot),a

        ld    hl,_INV_Cursor
        cp    (hl)
        ld    c,0
        jr    nz,.IDOSBS_NotSelected
        ld    c,1
.IDOSBS_NotSelected:

        ld    a,(_INV_TempSlot)
        add   a,INV_ROW_SLOT1
        ld    b,a
        ld    a,(_INV_TempSlot)
        jp    _INV_DrawSlotRow

; A - slot index, B - the row's char row, C - selected flag (0/1).
_INV_DrawSlotRow:
        ld    (_INV_SlotIndex),a
        ld    a,b
        ld    (_INV_DrawScreenRow),a
        ld    a,c
        ld    (_INV_Selected),a

        ; Clear the row's pixels first, so a dropped item's longer old name
        ; never leaves stray pixels behind.
        ld    a,(_INV_DrawScreenRow)
        ld    b,a
        ld    c,INV_WIN_COL+1
        ld    d,INV_WIN_WIDTH-2
        call  _INV_ClearRow

        ; The row's background color carries the selection.
        ld    a,(_INV_Selected)
        or    a
        ld    a,INV_ATTR_BASE
        jr    z,.IDSR_FillReady
        ld    a,INV_ATTR_HILITE
.IDSR_FillReady:
        push  af
        ld    a,(_INV_DrawScreenRow)
        ld    b,a
        ld    c,INV_WIN_COL+1
        ld    d,INV_WIN_WIDTH-2
        ld    e,1
        pop   af
        call  _INV_FillBand

        ; The item's name (or a placeholder for an empty slot).
        call  _INV_BuildSlotLine
        ld    ix,_INV_LineBuffer
        ld    a,(_INV_DrawScreenRow)
        ld    b,a
        ld    c,INV_TEXT_COL*2
        jp    Print4x8

; Build "1 Pickaxe" (or the empty placeholder) into _INV_LineBuffer, from
; _INV_SlotIndex.
_INV_BuildSlotLine:
        ld    de,_INV_LineBuffer
        ld    a,(_INV_SlotIndex)
        add   a,'1'
        ld    (de),a
        inc   de
        ld    a,' '
        ld    (de),a
        inc   de

        ld    a,(_INV_SlotIndex)
        ld    hl,PlayerInventory
        push  de
        ld    e,a
        ld    d,0
        add   hl,de
        pop   de
        ld    a,(hl)
        or    a
        jr    nz,.IBSL_HasItem
        ld    hl,_INV_EmptyText
        jp    _INV_CopyStr
.IBSL_HasItem:
        dec   a
        push  de
        ld    l,a
        ld    h,0
        add   hl,hl
        ld    de,ItemNames
        add   hl,de
        ld    e,(hl)
        inc   hl
        ld    d,(hl)
        ex    de,hl
        pop   de
        jp    _INV_CopyStr

; HL - source, DE - destination. Copies until (and including) a zero byte.
_INV_CopyStr:
        ld    a,(hl)
        ld    (de),a
        inc   hl
        inc   de
        or    a
        jr    nz,_INV_CopyStr
        ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; State.
_INV_State:            defb  INV_STATE_CLOSED
_INV_Cursor:            defb  0
_INV_EnterLatch:        defb  0
_INV_UpLatch:           defb  0
_INV_DownLatch:         defb  0
_INV_SpaceLatch:        defb  0
_INV_PendingOpen:       defb  0

; Scratch for PlayerStandsOnItem's box test.
_INV_CheckRoomId:       defb  0
_INV_ItemLeft:          defb  0
_INV_ItemRight:         defb  0
_INV_ItemTop:           defb  0
_INV_ItemBottom:        defb  0

; Scratch for drawing the window and her rows.
_INV_DrawRow:           defb  0
_INV_DrawCol:           defb  0
_INV_TileAttr:          defb  0
_INV_DrawScreenRow:     defb  0
_INV_SlotIndex:         defb  0
_INV_TempSlot:          defb  0
_INV_Selected:          defb  0
_INV_FillRow:           defb  0
_INV_FillFirstCol:      defb  0
_INV_FillCol:           defb  0
_INV_FillWidth:         defb  0
_INV_FillColsLeft:      defb  0
_INV_FillRowsLeft:      defb  0
_INV_FillAttr:          defb  0
_INV_LineBuffer:        block 16,0

_INV_EmptyText:
        defb  "-- empty --", 0
_INV_GfxBlank:
        defb  0, 0, 0, 0, 0, 0, 0, 0

;-------------------------------------------------------------------------------
; Player's carried items, one slot per byte: 0 - empty, else an item ID.
PlayerInventory:
        block INV_MAX_ITEMS,0
;-------------------------------------------------------------------------------
