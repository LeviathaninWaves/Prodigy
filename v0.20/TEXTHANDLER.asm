    include 'ASCIIMAP.asm'
    include 'DIGITHANDLER.asm'
    nop 0,8

LOADFONT:
;a0 = Font address Long
;d0 = Vram Destination address Word
;d1 = Number of characters/tiles Word

    swap                 d0                                                          ;Swap Vram address to upper word.
    add.l                 #VDPWRITETILES, d0                            ;Add Vram to VDP control to send to port
    move.l              d0, VDPCONTROLPORT
    subq.b             #0x1, d1                                                ;Number of characters minus one

    @CHARCOPY:
    move.w            #0x07, d2                                             ;8 Long in tile

    @LONGCOPY:
    move.l              (a0)+, VDPDATAPORT
    dbra                  d2, @LONGCOPY
    dbra                  d1, @CHARCOPY


LOADFONTB:
;a0 = Font address Long
;d0 = Vram Destination address Word
;d1 = Number of characters/tiles Word
    ;================Re-init. Font================================
    lea                     FONTTILES, a0                         ;Load tiles address a0
    move.l               #FONTVRAM, d0                     ;Load Vram destination address to d0
    move.l               #FONTSIZET, d1                     ;Move number of font tiles to d1

    swap                 d0                                                          ;Swap Vram address to upper word.
    add.l                 #VDPWRITETILESB, d0                            ;Add Vram to VDP control to send to port
    move.l              d0, VDPCONTROLPORT
    subq.b             #0x1, d1                                                ;Number of characters minus one

    @CHARCOPY:
    move.w            #0x07, d2                                             ;8 Long in tile

    @LONGCOPY:
    move.l              (a0)+, VDPDATAPORT
    dbra                  d2, @LONGCOPY
    dbra                  d1, @CHARCOPY

    rts

;=================Label checking and drawing==============================
;This code checks which screen we're on and draws appropriate labels.
;==============================================================

CHECKCURRENTLABELS:



    move.b               CURRENTLABELDRAWN, d0
    cmp.b                 #0x01, d0
    beq                     @SkipDrawing

    move.b             CURRENTSCREEN, d0
    cmp.b               #MAINSCREEN, d0
    beq                    DRAWPELABELSMETA


    ;move.b             CURRENTSCREEN, d0
    ;cmp.b              #NOTESCREEN, d0
    ;beq                   DRAWNELABLEMETA
    @SkipDrawing:
    rts

DRAWPELABELSMETA:
    lea                 ChannelLabels, a6              ;Load the label string into a6
    move.l           #FONTID, d0
    move.w          #0x0402, d1                       ; x, y coords
    move.b           #0x29, d4                            ;number of characters
    jsr                   DRAWLABELS
    move.b           #0x01, CURRENTLABELDRAWN
    rts

DRAWCELABELSMETA:
    lea           CURRENTCHAINID, a6              ;Load the label string into a6
    move.l           #FONTID, d0
    move.w          #0x2410, d1                       ; x, y coords
    move.b           #0x02, d4                            ;number of characters
   ; jsr                   DRAWCURRENTCHAINID
    ;move.b           #0x01, CURRENTLABELDRAWN
    rts

DRAWNELABLEMETA:   ;We don't need labels for this screen technically, since the labels are specified in layout.
    move.b           #0x01, CURRENTLABELDRAWN
    rts

DRAWLABELS:
;a6 Label address
;d0  FONTID
;d1   x,y coords 04 02
    clr.l                         d3                     ; Clear d3 ready to work with
	move.b                   d1, d3                 ; Move Y coord (lower byte of d1) to d3
	mulu.w                   #0x0040, d3            ; Multiply Y by line width (H40 mode - 64 lines horizontally) to get Y offset
	ror.l                        #0x8, d1               ; Shift X coord from upper to lower byte of d1
	add.b                     d1, d3                 ; Add X coord to offset
	mulu.w                   #0x2, d3               ; Convert to words
	swap                        d3                     ; Shift address offset to upper word
	add.l                       #VDPWRITEPLANEB, d3 ; Add PlaneA write cmd + address
	move.l                    d3, VDPCONTROLPORT       ; Send to VDP control port

	clr.l                           d3                     ; Clear d3 ready to work with again
    lea                              ASCIIMap, a1           ; Load address of ASCII map into a1

	@CharCopy:
	move.b                       (a6)+, d2              ; Move ASCII byte to lower byte of d2
    move.b                    (a1,d2.w), d3          ; Move tile ID from table (index in lower word of d2) to lower byte of d3

	move.w                      d3, VDPDATAPORT          ; Move palette and pattern IDs to VDP data port
	sub.b                          #0x01, d4
	bne                              @CharCopy              ; Next character

	rts

;============Current screen and table checking===========================
;We're going to check the current screen, so we know which tables to draw to screen
;================================================================
CHECKCURRENTTABLES:
    move.b             CURRENTSCREEN, d0
    cmp.b               #MAINSCREEN, d0
    beq                    DRAWPATTABLEMETAROUTINE

    ;move.b             CURRENTSCREEN, d0
    cmp.b              #CHAINSCREEN, d0
    beq                   DRAWCHAINTABLEMETAROUTINE

    ;move.b             CURRENTSCREEN, d0
    cmp.b              #NOTESCREEN, d0
    beq                   DRAWNOTETABLEMETAROUTINE

    ;move.b             CURRENTSCREEN, d0
    cmp.b              #SYNTHSCREEN, d0
    beq                   DRAWSYNTHTABLEPSGORFM
    rts

DRAWPATTABLEMETAROUTINE:
    movem.l           d0-d7/a0-a6, -(sp)
    jsr                     CLEANREGISTERS
    lea                    PATTABLERAM, a0                              ;Load table data address into a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x0403, d1                          ;(4,3) x,y. coords
    move.w                 #0x0917, d4          ; Counter first byte is the number of columns, second byte is rows, 10 columns of 16 rows
    jsr                       DRAWTABLES                ;Draw Pattern Table

    movem.l             (sp)+, d0-d7/a0-a6
    rts
DRAWCHAINTABLEMETAROUTINE:
    movem.l           d0-d7/a0-a6, -(sp)
    jsr                     CLEANREGISTERS
    move.l              CURRENTSLOTADDRESS, d1
    move.l             d1, a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x0403, d1                          ;(4,3) x,y. coords
    move.w              #0x0108, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWCHTABLES                 ;Draw Chain Table
    movem.l             (sp)+, d0-d7/a0-a6
    rts

DRAWNOTETABLEMETAROUTINE:
;=============Note Entry Rows=================
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    jsr                     CLEANREGISTERS
    lea                    NOTEENTRYROWS, a0                              ;Load address into a0

    move.w            #NERSIZEW, d0                       ;Size in words
    move.l              #0x00, d1                               ; Y offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    move.l               #0x0, d3                         ;Palette ID
    move.l                #0x03, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWNOTEROWS  ;Draw the current layout

;============Note Tables==================
    jsr                     CLEANREGISTERS
    move.l              PCURRENTSLOTADDRESS, d1
    move.l             d1, a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x0403, d1                          ;(4,3) x,y. coords
    move.w              #0x0020, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWNOTETABLES                 ;Draw NOTE Table
    jsr                     CLEANREGISTERS
;============Instrument and Velocity Tables====
    move.l              PCURRENTSLOTADDRESS, d1
    add.l               #0x00002800, d1         ;Offset to Instr + Vel tables
    move.l             d1, a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x0903, d1                          ;(4,3) x,y. coords
    move.w              #0x0020, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                         DRAWIVTABLES   ;Draw Instrument and Velocity Tables
;============Command Tables======================
    move.l              PCURRENTSLOTADDRESS, d1
    add.l               #0x00005000, d1         ;Offset to Command tables
    move.l             d1, a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x1003, d1                          ;(4,3) x,y. coords
    move.w              #0x0020, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                         DRAWCOMMANDTABLES   ;Draw Command Tables
    movem.l             (sp)+, d0-d7/a0-a6
    rts


DRAWSYNTHTABLEPSGORFM:
    move.b              SYNTHSCREENPSGFM, d0
    cmp.b                 #0x00, d0
    beq                     DRAWSYNTHTABLEMETAROUTINE
    cmp.b                  #0x01, d0
    beq                     DRAWSYNTHPSGTABLEMETAROUTINE
    rts

DRAWSYNTHTABLEMETAROUTINE:
    movem.l           d0-d7/a0-a6, -(sp)
    jsr                     CLEANREGISTERS
    move.l              CURRENTSYNTHSLOTADDRESS, d1
    move.b              SYNTHINSTRUMENTNUMBER, d0  ;The Patch ID we're drawing to screen
    mulu.w                #0x40, d0            ;We're getting the offset for which FM patch's data we're drawing to screen
    add.l                  d0, d1
    move.l             d1, a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x1101, d1                          ; x,y. coords
    move.w              #0x0008, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES

    move.w             #0x0f0a, d1                          ; x,y. coords
    move.w              #0x000b, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES                 ;Draw Chain Table

    move.w             #0x130a, d1                          ;x,y. coords
    move.w              #0x000b, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES

    move.w             #0x170a, d1                          ; x,y. coords
    move.w              #0x000b, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES

    move.w             #0x1b0a, d1                          ; x,y. coords
    move.w              #0x000b, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES
    ;=================Instrument Name Table============================
    move.w             #0x071a, d1                          ; x,y. coords
    move.w              #0x000C, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHNAMETABLES
    ;=========================================================================
    move.l              #SYNTHINSTRUMENTNUMBER, d1
    move.l                 d1, a0
    move.w             #0x0d19, d1                          ;x,y. coords
    move.w              #0x0001, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES
    movem.l             (sp)+, d0-d7/a0-a6
    rts


DRAWSYNTHPSGTABLEMETAROUTINE:
    movem.l           d0-d7/a0-a6, -(sp)
    jsr                     CLEANREGISTERS
    move.l              CURRENTSYNTHSLOTADDRESS, d1
    move.b              SYNTHINSTRUMENTNUMBER, d0  ;The Patch ID we're drawing to screen
    mulu.w                #0x12, d0            ;We're getting the offset for which FM patch's data we're drawing to screen
    add.l                  d0, d1
    move.l             d1, a0
    move.l              #FONTID, d0                           ;Load FontID to d0
    move.w             #0x0a01, d1                          ; x,y. coords
    move.w              #0x0005, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES

    move.w             #0x1506, d1                          ; x,y. coords
    move.w              #0x0001, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES                 ;Draw Chain Table

    ;=================Instrument Name Table============================
    move.w             #0x071a, d1                          ; x,y. coords
    move.w              #0x000C, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHNAMETABLES
    ;=========================================================================
    move.l              #SYNTHINSTRUMENTNUMBER, d1
    move.l                 d1, a0
    move.w             #0x0d19, d1                          ;x,y. coords
    move.w              #0x0001, d4          ; Counter first byte is the number of columns, second byte is rows
    jsr                       DRAWSYNTHTABLES
    movem.l             (sp)+, d0-d7/a0-a6
    rts
;=====Draw Song table=======================
;This code draws the pattern/song tables to the screen.
;=======================================
DRAWTABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                  #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x01, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2                                                         ;value 2
    jsr                        CONVERTBYTETOFONT
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers
    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0017, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabXCopy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy

;=============Chain Table drawing============================
;This code is responsible for drawing the chain and transpose tables to screen
;========================================================

DRAWCHTABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                   #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                      d3
	moveq                  #0x0, d5
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                  #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x01, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2                                                         ;value 2
    jsr                        CONVERTBYTETOFONT
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers
    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @TabX2Copy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2                                                         ;value 2
    jsr                        CONVERTBYTETOFONTFF
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers
    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabX2Copy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0008, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabX2Copy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy

;========Note table drawing========================
; A specialized function for drawing the note tables out in the phrase screen
DRAWNOTETABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                   #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x01, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2
    jsr                        ConvertHextoNotation
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers

    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2
    jsr                        ConvertHextoOctave
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers

    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0017, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabXCopy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy


DRAWSYNTHTABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEA, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                  #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x01, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2                                                         ;value 2
    jsr                        CONVERTBYTETOFONT
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers
    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0017, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                  d3
	add.l                  #VDPWRITEPLANEA, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabXCopy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy


DRAWSYNTHNAMETABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEA, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                  #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x0C, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2                                                         ;value 2
   ; jsr                        CONVERTBYTETOFONT
    ;ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port


    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers
    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0017, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                  d3
	add.l                  #VDPWRITEPLANEA, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabXCopy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy



DRAWNOTEROWS:
	; a0 (l) - Note Rows address
	; d0 (w) - Size in words
	; d1 (bb)- XY coord (in tiles)
	; d2 (b) - Palette
    add.l              #0x01800000, d1                       ; Yoffset in address
    add.l                  #VDPWRITEPLANEB, d1           ; Add PlaneA write cmd + address
	move.l                d1, VDPCONTROLPORT
    sub.b                  #0x1C, d0             ; Num words in d0, minus 1 for counter (odd stuff happens here) There's an extra tile off display being drawn???

    @layXCopy:
	move.w                  (a0)+, d4              ; Move tile ID from map data to lower d4
	add.w                       d2, d4                 ; Add first tile offset to d4
	move.w                    d4, VDPDATAPORT          ; Move to VRAM
	subq.b                     #0x01, d5                  ; minus 1 for the counter
	cmp.b                      #0x00, d5                        ;test counter
	beq                           @layYCopy                          ;branch to reset the x,y's, counter, and restart this loop'
	dbra                          d0, @layXCopy              ; Loop

    rts

    @layYCopy:
    add.l                   d7, d1
	move.l                d1, VDPCONTROLPORT
    move.b               d6, d5  ; reset counter
    cmp.w                  #0x0000, d0
    beq                     @Done
    jmp                     @layXCopy

    @Done:
    rts
;========Instrument + Velocity table drawing========================
; A specialized function for drawing the Instr + vel tables out in the phrase screen
DRAWIVTABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                   #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x01, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2
    jsr                        ConvertBytetoFont
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    move.b                  #0x00, VDPDATAPORT
    move.b                  #0x00, VDPDATAPORT
    adda.l                  #0x00000001, a0    ;increase offset for table headers

    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2
    jsr                        ConvertByteToFont
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers

    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0020, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabXCopy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy




;========COMMAND table drawing========================
; A specialized function for drawing the Instr + vel tables out in the phrase screen
DRAWCOMMANDTABLES:
	; a0 (l) - data table address
	; d0 (w) - First tile ID of font
	; d1 (bb)- XY coord (in tiles)
	; d4 is the column counter
    move.w                #0x08F02, VDPDATAPORT
	moveq                 #0x0, d5
	move.w                  d1, COLUMNCOORD
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	moveq                  #0x0, d5
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7

	moveq                   #0x0, d3                     ; Clear d3 so it's' ready to work with again

	lea                        ASCIIMAP, a1
    move.b               #0x01, d6  ; reset counter

;Table copying routines======
;a0  Table header
;a1 ASCIIMAP address
;================
    @TabXCopy:
    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2
    jsr                        ConvertBytetoFontFF
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5

    adda.l                  #0x00000001, a0    ;increase offset for table headers

    moveq                 #0x0, d2
	move.b                (a0), d2                  ;Load value into d2
    jsr                        ConvertByteToFontFF
    ror.w                      #0x08, d2
    add.b                   #ASCIISTART, d2     ; first ASCII code to get table entry index
	move.b                 d2, d3        ; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.b                   d0, d3                      ; Offset tile ID by first tile ID in font

    move.w                d3, VDPDATAPORT ; Move palette and pattern IDs to VDP data port

    ror.w                     #0x08, d2
    move.b                  d2, d5
    add.b                   d0, d5                      ; Offset tile ID by first tile ID in font

    move.w                  d5, VDPDATAPORT
    moveq                   #0x0, d3
    moveq                   #0x0, d5
    adda.l                  #0x00000001, a0    ;increase offset for table headers

    subq.b                  #0x01, d4                 ;loop counter MAIN
    subq.b                  #0x01, d6                 ;loop counter vertical spacing
	cmp.b                   #0x00, d4
	beq                       @ENDCOLUMN
	cmp.b                   #0x00, d6
	beq                       @TabYCopy
	jmp                       @TabXCopy          ;Next Character

    @ENDCOLUMN:
    cmp.w                   #0x0000, d4
    beq                       @DONE
    sub.w                   #0x0100, d4        ; subtract column count from counter
    add.w                   #0x0020, d4        ; reset row count for counter
    add.w                #0x0400, COLUMNCOORD    ;Increase x offset for drawing next column
    move.w              COLUMNCOORD, d1
    moveq                #0x0, d3                                      ;All of this loads xy coords to the control port /Start
	move.b              d1, d3
	mulu.w             #0x0040, d3
	ror.l                   #0x08, d1
	add.b                d1,d3
	move.w                d3, d5           ; multiply by 2, optimized by adding to itself instead
	add.w                  d5, d3
	swap                  d3
	add.l                  #VDPWRITEPLANEB, d3
	move.l               d3, VDPCONTROLPORT    ;/End
	move.l                d3, d7
	move.b               #0x01, d6
    bra.w                   @TabXCopy

    @DONE:
    move.w               #0x8F02, d3
    move.w               d3, VDPCONTROLPORT ;auto increment  back to 2
    rts

    @TabYCopy:
    add.l                   #0x00800000, d7
	move.l                d7, VDPCONTROLPORT
    move.b               #0x01, d6  ; reset counter
    jmp                     @TabXCopy




SCROLLTABLE:

    move.l  #VDPWRITEHSCROLL, VDPCONTROLPORT
    move.b         PATTABLEPOSITION, d1
    mulu.w           #0x0020, d1
    move.l          #0x00000000, d2
    sub.w               d1, d2
    move.w       #0x0000, VDPDATAPORT
    move.w      d2, VDPDATAPORT

    rts

SCROLLTABLEVERTICAL: ;For Note Entry screen

    move.l  #VDPWRITEVSCROLL, VDPCONTROLPORT
    move.b         NOTETABLEPOSITION, d1       ;TODO
    mulu.w           #0x0008, d1
    move.l          #0x00000000, d2
    add.w               d1, d2
    move.w       #0x0000, VDPDATAPORT
    move.w      d2, VDPDATAPORT

    rts

SCROLLRESETVERTICAL: ;For Note Entry screen

    move.l  #VDPWRITEVSCROLL, VDPCONTROLPORT
    ;move.w              #0x0000, d1       ;TODO

    move.w       #0x0000, VDPDATAPORT
    move.w      #0x0000, VDPDATAPORT

    rts

CHECKSLOTWINDOWRIGHT:
    movem.l    d0-d1, -(sp) ; push data to the stack, registers are full
    move.b     TABLESLOTWINDOW, d0
    move.b     TABLESLOTPOSITION, d1
    cmp.b       d0, d1
    ble             @DoneCheck
    add.b       #0x01, TABLESLOTWINDOW
    add.b       #0x01, TABLESLOTWINDOW2
    add.b       #0x01, PATTABLEPOSITION
    add.w       #0x1700, CURRENTTABLESLOT
    jsr             SCROLLTABLE
    @DoneCheck:
    movem.l   (sp)+, d0-d1 ; return prior register status.
    rts

CHECKSLOTWINDOWLEFT:
    movem.l    d0-d1, -(sp) ; push data to the stack, registers are full
    move.b     TABLESLOTWINDOW2, d0
    move.b     TABLESLOTPOSITION, d1
    cmp.b       d0, d1
    bge             @DoneCheck
    sub.b       #0x01, TABLESLOTWINDOW
    sub.b       #0x01, TABLESLOTWINDOW2
    sub.b       #0x01, PATTABLEPOSITION
    sub.w       #0x1700, CURRENTTABLESLOT
    jsr             SCROLLTABLE
    @DoneCheck:
    movem.l   (sp)+, d0-d1 ; return prior register status.
    rts

CHECKSLOTWINDOWDOWN:
    movem.l    d0-d1, -(sp) ; push data to the stack, registers are full
    move.b     NOTESLOTWINDOW, d0
    move.b     NOTESLOTPOSITION, d1
    cmp.b       d0, d1
    ble             @DoneCheck
    add.b       #0x01, NOTESLOTWINDOW
    add.b       #0x01, NOTESLOTWINDOW2
    add.b       #0x01, NOTETABLEPOSITION
    add.b       #0x02, CURRENTTABLESLOT
    add.b       #0x01, CURRENTTABLESLOTNOTE
    jsr             SCROLLTABLEVERTICAL
    @DoneCheck:
    movem.l   (sp)+, d0-d1 ; return prior register status.
    rts

CHECKSLOTWINDOWUP:
    movem.l    d0-d1, -(sp) ; push data to the stack, registers are full
    move.b    NOTESLOTWINDOW2, d0
    move.b     NOTESLOTPOSITION, d1
    cmp.b       d0, d1
    bge             @DoneCheck
    sub.b       #0x01, NOTESLOTWINDOW
    sub.b       #0x01, NOTESLOTWINDOW2
    sub.b       #0x01, NOTETABLEPOSITION
    sub.b       #0x02, CURRENTTABLESLOT
    sub.b       #0x01, CURRENTTABLESLOTNOTE
    jsr             SCROLLTABLEVERTICAL
    @DoneCheck:
    movem.l   (sp)+, d0-d1 ; return prior register status.
    rts
