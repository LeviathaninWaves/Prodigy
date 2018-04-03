    include 'CURSORMOVE.asm' ; Contains the MOVE cursor functions that this handler refers to.


;=====Draw cursor to screen====================================
LOADCURSORTABLES1:
   ; a0 - Sprite data address
   ; d0 - Number of sprites
    move.l                      #VDPWRITESPRITE, VDPCONTROLPORT

    subq.b                       #0x1, d0                ; 2 sprites attributes
    @AttrCopy:
    move.l                        (a0)+, VDPDATAPORT
    move.l                        (a0)+, VDPDATAPORT
    move.l                        (a1)+, VDPDATAPORT
    move.l                        (a1)+, VDPDATAPORT
    move.l                        (a6)+, VDPDATAPORT
    move.l                        (a6)+, VDPDATAPORT
    dbra                             d0, @AttrCopy

    rts
;==============Cursor checking====================================
;This code checks what screen we're on and defines cursor x, y boundaries for each screen
;================================================================

CHECKCURSORSCREEN:
    cmp.b             #MAINSCREEN, CURRENTSCREEN
    beq                 CURSORMAINMETA
    cmp.b             #CHAINSCREEN, CURRENTSCREEN
    beq                 CURSORCHAINMETA
    cmp.b             #PHRASESCREEN, CURRENTSCREEN
    beq                 CURSORPHRASEMETA
    cmp.b              #SYNTHSCREEN, CURRENTSCREEN
    beq                 CURSORSYNTHPSGFM
    rts

CURSORMAINMETA:
    move.l              d7, -(sp)
    move.w          #0x98, CURSBOUNDARYMINY
    move.w          #0xA0, CURSBOUNDARYMINX
    move.w          #0x148, CURSBOUNDARYMAXY
    move.w          #0x140, CURSBOUNDARYMAXX
    move.b          #0x17, d7

    jsr                 MOVECURSOR
    move.l              (sp)+, d7
    rts
CURSORCHAINMETA:
    move.l              d7, -(sp)
    move.w          #0x98, CURSBOUNDARYMINY
    move.w          #0xA0, CURSBOUNDARYMINX
    move.w          #0xD0, CURSBOUNDARYMAXY
    move.w          #0xC8, CURSBOUNDARYMAXX
    move.b            #0x08, d7
    jsr                 MOVECURSOR
    move.l              (sp)+, d7
    rts


CURSORSYNTHPSGFM:

    cmp.b           #0x00, SYNTHSCREENPSGFM
    beq                CURSORSYNTHMETA
    cmp.b           #0x01, SYNTHSCREENPSGFM
    beq                 CURSORSYNTHPSGMETA
    rts

CURSORSYNTHMETA:
    move.l              d7, -(sp)
    move.w          #0x88, CURSBOUNDARYMINY
    move.w          #0xb8, CURSBOUNDARYMINX
    move.w          #0x150, CURSBOUNDARYMAXY  ;#0x150 is the name slot y, #0x148 is the instrument number slot y.
    move.w          #0x158, CURSBOUNDARYMAXX
    move.b            #0x08, d7
    jsr                 MOVECURSORSYNTH

    move.l              (sp)+, d7
    rts
CURSORSYNTHPSGMETA:
    move.l              d7, -(sp)
    move.w          #0x88, CURSBOUNDARYMINY
    move.w          #0xb8, CURSBOUNDARYMINX
    move.w          #0x150, CURSBOUNDARYMAXY  ;#0x150 is the name slot y, #0x148 is the instrument number slot y.
    move.w          #0x158, CURSBOUNDARYMAXX
    move.b            #0x08, d7
    jsr                 MOVECURSORSYNTHPSG

    move.l              (sp)+, d7
    rts
CURSORPHRASEMETA:         ; Note Entry cursor handling
    move.w          #0x98, CURSBOUNDARYMINY
    move.w          #0xA0, CURSBOUNDARYMINX
    move.w          #0x148, CURSBOUNDARYMAXY
    move.w          #0xA8, CURSBOUNDARYMAXX
    cmp.b               #0x00, NOTATIONEDITMODE       ;Are we editing notes?
    beq                MOVECURSORNOTATION
    cmp.b             #0x01, NOTATIONEDITMODE           ; Are we editing Instrument number?
    beq                 MOVECURSORINSTRUMENTNUMBER
    cmp.b             #0x02, NOTATIONEDITMODE           ; Are we editing velocity?
    beq                 MOVECURSORINSTRUMENTNUMBER
    cmp.b              #0x03, NOTATIONEDITMODE           ;Are we editing tracker commands?
    beq                  MOVECURSORCOMMANDS
    rts
;=====================More Cursor Checking=====================================
;Now we need to check the screen real quick to see if anything has changed, then reset cursor position
;and change the rules for the cursor according to which screen we're on
;===================================================
CHECKCURSORMETA:
    move.b                  CURRENTSCREEN, d0
    cmp.b                      #MAINSCREEN, d0
    beq                         CHECKCURSOR
    cmp.b                      #CHAINSCREEN, d0
    beq                         CHECKCURSOR
    cmp.b                       #PHRASESCREEN, d0
    beq                           CHECKCURSORNOTATION
    cmp.b                      #SYNTHSCREEN, d0
    beq                         CHECKCURSORSYNTHMETA
    rts
CHECKCURSOR:

    cmp.b                   #0x00, CURSORRESET  ;Does cursor need resetting?
    bne                       @Done
    move.w                #0xA0, CURSORRAMX       ; reset x, and y coords for cursor back to 0
    move.w                 #0x98, CURSORRAMY
    move.w                  #0xA8, CURSORRAM2X

    move.w                #0xA0, CURSORPOSITIONRAM2   ;These values are directly responsible for the cursors actual position
    move.w                 #0x98, CURSORPOSITIONRAM
    move.w                  #0xA8, CURSORPOSITIONRAM3

    move.b                  #0x00, PATTABLEPOSITION          ;Need to reset the scrolling too.
    move.b                  #0x01, CURSORRESET        ;Cursor no longer needs resetting
    jsr                          SCROLLTABLE
    @Done:

    rts
CHECKCURSORNOTATION:

    cmp.b                   #0x00, CURSORRESET  ;Does cursor need resetting?
    bne                       @Done
    move.w                #0xA0, CURSORRAMX       ; reset x, and y coords for cursor back to 0
    move.w                 #0x98, CURSORRAMY
    move.w                  #0xA8, CURSORRAM2X
    move.w                  #0xB0, CURSORRAM3X   ;3rd sprite
    move.w                #0xA0, CURSORPOSITIONRAM2   ;These values are directly responsible for the cursors actual position
    move.w                 #0x98, CURSORPOSITIONRAM
    move.w                  #0xA8, CURSORPOSITIONRAM3
    move.w                   #0xB0, CURSORPOSITIONRAM4 ;3rd sprite
    move.b                  #0x00, PATTABLEPOSITION          ;Need to reset the scrolling too.
    move.b                  #0x01, CURSORRESET        ;Cursor no longer needs resetting
    jsr                          SCROLLTABLE
    @Done:

    rts

CHECKCURSORSYNTHMETA:
    cmp.b                   #0x00, SYNTHSCREENPSGFM
    beq                       CHECKCURSORSYNTH
    cmp.b                   #0x01, SYNTHSCREENPSGFM
    beq                         CHECKCURSORSYNTHPSG
    rts
CHECKCURSORSYNTH:
    cmp.b                   #0x00, CURSORRESET  ;Does cursor need resetting?
    bne                       @Done
    move.w                #0x108, CURSORRAMX       ; reset x, and y coords for cursor back to 0
    move.w                 #0x88, CURSORRAMY
    move.w                  #0x110, CURSORRAM2X

    move.w                #0x108, CURSORPOSITIONRAM2   ;These values are directly responsible for the cursors actual position
    move.w                 #0x88, CURSORPOSITIONRAM
    move.w                  #0x110, CURSORPOSITIONRAM3

    move.b                  #0x00, PATTABLEPOSITION          ;Need to reset the scrolling too.
    move.b                  #0x01, CURSORRESET        ;Cursor no longer needs resetting
    jsr                          SCROLLTABLE
    @Done:

    rts

CHECKCURSORSYNTHPSG:
    cmp.b                   #0x00, CURSORRESET  ;Does cursor need resetting?
    bne                       @Done
    move.w                #0xd0, CURSORRAMX       ; reset x, and y coords for cursor back to 0
    move.w                 #0x88, CURSORRAMY
    move.w                  #0xd8, CURSORRAM2X

    move.w                #0xd0, CURSORPOSITIONRAM2   ;These values are directly responsible for the cursors actual position
    move.w                 #0x88, CURSORPOSITIONRAM
    move.w                  #0xd8, CURSORPOSITIONRAM3

    move.b                  #0x00, PATTABLEPOSITION          ;Need to reset the scrolling too.
    move.b                  #0x01, CURSORRESET        ;Cursor no longer needs resetting
    jsr                          SCROLLTABLE
    @Done:

    rts
;==============UPDATE CURSOR META==================
;A meta routine to check screen and tables before drawing the cursor
;========================Cursor movement============
UPDATECURSORMETA:
    move.b                  CURRENTSCREEN, d0
    cmp.b                   #MAINSCREEN, d0
    beq                       UPDATECURSORY
    cmp.b                    #CHAINSCREEN, d0
    beq                        METAUPDATECURSORY
    cmp.b                   #PHRASESCREEN, d0
    beq                       UPDATENOTEENTRYCURSOR     ; Note Entry screen has multiple rules for the cursor, we'll handle them here
    cmp.b                    #SYNTHSCREEN, d0
    beq                        SYNTHUPDATECURSORMETA
    rts
UPDATENOTEENTRYCURSOR:
    cmp.b               #0x00, NOTATIONEDITMODE
    beq                   UPDATECURSORNOTATION
    cmp.b               #0x01, NOTATIONEDITMODE
    beq                     UPDATECURSORY
    cmp.b               #0x02, NOTATIONEDITMODE
    beq                     UPDATECURSORY
    cmp.b               #0x03, NOTATIONEDITMODE
    beq                     UPDATECURSORYFF
    rts

SYNTHUPDATECURSORMETA:
    cmp.b                  #0x00, SYNTHEDITMODE
    beq                     UPDATECURSORY
    cmp.b                  #0x01, SYNTHEDITMODE
    beq                     UPDATECURSORY
    cmp.b                  #0x02, SYNTHEDITMODE
    beq                     UPDATECURSORALPHABET
    rts


METAUPDATECURSORY: ;Specifically for the Chain screen, to differentiate Chain and Transpose values.
    cmp.b                   #0x07, CURRENTTABLESLOT
    ble                        UPDATECURSORY
    cmp.b                   #0x08, CURRENTTABLESLOT
    ble                        UPDATECURSORYFF

UPDATECURSORY:
    move.b                  CURRENTSLOTDIGITS, d2
    jsr                         CONVERTBYTETOFONT
    add.w                     #0x4040, d2    ; offset tile id to the white highlight fonts
    move.b                   d2, d1            ; Digit 2
    ror.w                       #0x08, d2
    move.b                   d2, d4         ;Digit 1
    moveq                     #0x0, d2
    move.b                     d1, d2           ;2?
    moveq                      #0x0, d1
    move.b                     d4, d1           ;1?
    moveq                      #0x0, d4
    move.l                #CURSORATTRIBUTERAM, a0  ; For the VDP Control Port
    move.l                #CURSORATTRIBUTERAM2, a1  ;Again,  VDP Control Port
    move.l                 #CURSORPOSITIONRAM, a2  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM2, a3  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM3, a4  ;The cursor Y position
    move.l                 (a0), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x01, VDPDATAPORT
    move.w                  d1, VDPDATAPORT
    move.w                  (a3), VDPDATAPORT
    move.l                 (a1), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x00, VDPDATAPORT
    move.w                  d2, VDPDATAPORT
    move.w                  (a4), VDPDATAPORT

    rts

UPDATECURSORYFF:
    move.b                  CURRENTSLOTDIGITS, d2
    jsr                         CONVERTBYTETOFONTFF
    add.w                     #0x4040, d2    ; offset tile id to the white highlight fonts
    move.b                   d2, d1            ; Digit 2
    ror.w                       #0x08, d2
    move.b                   d2, d4         ;Digit 1
    moveq                     #0x0, d2
    move.b                     d1, d2           ;2?
    moveq                      #0x0, d1
    move.b                     d4, d1           ;1?
    moveq                      #0x0, d4
    move.l                #CURSORATTRIBUTERAM, a0  ; For the VDP Control Port
    move.l                #CURSORATTRIBUTERAM2, a1  ;Again,  VDP Control Port
    move.l                 #CURSORPOSITIONRAM, a2  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM2, a3  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM3, a4  ;The cursor Y position
    move.l                 (a0), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x01, VDPDATAPORT
    move.w                  d1, VDPDATAPORT
    move.w                  (a3), VDPDATAPORT
    move.l                 (a1), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x00, VDPDATAPORT
    move.w                  d2, VDPDATAPORT
    move.w                  (a4), VDPDATAPORT

    rts


UPDATECURSORNOTATION:
    ;Cursor sprites 1, and 2
    move.l                   #NOTEDIGITS, a0
    move.b                  (a0)+,  d2            ;We need to load the table result into cursor's' tile ID so that changes made to table are reflected by cursor as well.
    moveq                    #0x0, d5
    move.b                   (a0), d5
    jsr                         ConvertHextoNotation
    add.w                     #0x4040, d2    ; offset tile id to the white highlight fonts
    move.b                   d2, d1            ; Digit 2
    ror.w                       #0x08, d2
    move.b                   d2, d4         ;Digit 1
    moveq                     #0x0, d2
    move.b                     d1, d2           ;2?
    moveq                      #0x0, d1
    move.b                     d4, d1           ;1?
    moveq                      #0x0, d4
    move.l                #CURSORATTRIBUTERAM, a0  ; For the VDP Control Port
    move.l                #CURSORATTRIBUTERAM2, a1  ;Again,  VDP Control Port
    move.l                 #CURSORPOSITIONRAM, a2  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM2, a3  ;The cursor x1 position
    move.l                 #CURSORPOSITIONRAM3, a4  ;The cursor x2 position
    move.l                 (a0), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x01, VDPDATAPORT
    move.w                  d1, VDPDATAPORT
    move.w                  (a3), VDPDATAPORT
    move.l                 (a1), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x02, VDPDATAPORT
    move.w                  d2, VDPDATAPORT
    move.w                  (a4), VDPDATAPORT
    ;Cursor Sprite 3 ONLY.
    moveq                     #0x0, d2
    move.b                    d5, d2
    moveq                        #0x0, d5
    moveq                      #0x0, d4

    jsr                         ConvertHextoOctave

    add.w                     #0x4000, d2    ; offset tile id to the white highlight fonts

    ror.w                       #0x08, d2
    move.b                   d2, d4         ;Digit 1

    move.l                #CURSORATTRIBUTERAM3, a0  ; For the VDP Control Port
    move.l                 #CURSORPOSITIONRAM, a2  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM4, a3  ;The cursor x3 position

    move.l                 (a0), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x00, VDPDATAPORT ;Link data
    move.w                  d4, VDPDATAPORT
    move.w                  (a3), VDPDATAPORT

    rts

UPDATECURSORALPHABET:
    moveq                   #0x0, d2
    move.b                  CURRENTSLOTDIGITS, d2
    add.b                     #0x40, d2    ; offset tile id to the white highlight fonts
    move.l                #CURSORATTRIBUTERAM, a0  ; For the VDP Control Port
    move.l                 #CURSORPOSITIONRAM, a2  ;The cursor Y position
    move.l                 #CURSORPOSITIONRAM2, a3  ;The cursor Y position
    move.l                 (a0), VDPCONTROLPORT
    move.w               (a2), VDPDATAPORT
    move.w                 #0x00, VDPDATAPORT
    move.w                  d2, VDPDATAPORT
    move.w                  (a3), VDPDATAPORT

    rts
