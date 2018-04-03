MOVECURSOR:
;d0 how many pixels to move (8 pixels for one row) = 0x08
;d1 sprite ID, = 0x00
;d2 sprite 2 ID, = 0x01
;d3 =Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right


    swap                  d1                ;d1 0x00000000
    move.b               #0x8, d2
    swap                  d2                ;d2 0x00080000

    add.l                    #VDPWRITESPRITE, d1              ;0x60000003
    add.l                    #VDPWRITESPRITE, d2              ;0x60010003
    move.l                  d1, CURSORATTRIBUTERAM     ;This is for the VDP control port during vblank
    move.l                  d2, CURSORATTRIBUTERAM2     ;This is for the VDP control port during vblank

    moveq                   #0x0, d4
    moveq                   #0x0, d5
    moveq                   #0x0, d6

    move.l                #CURSORRAMY, a2                     ;Ready ram address for y position
    move.w               (a2), d4                                      ; move y value to d4
    move.l                  #CURSORRAMX, a3
    move.w                (a3), d5
    move.l                  #CURSORRAM2X, a4
    move.w                  (a4), d6

    cmp.b                   #0x01, d3
    beq                       ADDY
    cmp.b                   #0x00, d3
    beq                      SUBTRACTY
    cmp.b                   #0x02, d3
    beq                         @END
    cmp.b                   #0x03, d3   ;Check to see if left button is pressed
    beq                       SUBTRACTX
    cmp.b                   #0x04, d3  ; Check to see if right button is pressed
    beq                        ADDX

    @END:
    rts

SUBTRACTY:
    cmp.w                   CURSBOUNDARYMINY, d4                               ;check y position of cursor to make sure we're staying in bounds
    ble                        @Skips
    move.b                 CURRENTTABLESLOT, d1
    sub.b                   #0x01, d1
    move.b                 d1, CURRENTTABLESLOT
    sub.w                   d0, d4                                      ;sub old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skips:
    rts

SUBTRACTX:
    cmp.b                   #0x00, TABLESLOTPOSITION
    beq                       @SkipCheck

    sub.b                    #0x01, TABLESLOTPOSITION
    cmp.b                   #MAINSCREEN, CURRENTSCREEN
    bne                       @Skipb
    move.b                  TABLESLOTPOSITION, CHANNELNUMBER
    @Skipb:
    cmp.b                    #0x00, PATTABLEPOSITION
    beq                        @SkipCheck

    jsr                         CHECKSLOTWINDOWLEFT
    @SkipCheck:
    cmp.w                   CURSBOUNDARYMINX, d5                               ;check x position of cursor to make sure we're staying in bounds
    ble                        @Skips
    move.b                 CURRENTTABLESLOT, d1
    sub.b                   d7, d1
    move.b                 d1, CURRENTTABLESLOT
    sub.w                   d0, d5                                      ;sub old x value and 16 pixels to get new x value
    sub.w                   d0, d6
    move.w                d5, CURSORRAMX
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                d6, CURSORRAM2X
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port


    @Skips:
    rts

ADDY:
    cmp.w                   CURSBOUNDARYMAXY, d4                               ;check y position of cursor to make sure we're staying in bounds
    bge                        @Skipa
    move.b                 CURRENTTABLESLOT, d1
    add.b                   #0x01, d1
    move.b                 d1, CURRENTTABLESLOT
    add.w                   d0, d4                                      ;add old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skipa:
    rts

ADDX:
    cmp.b                   #0x09, TABLESLOTPOSITION
    beq                       @SkipCheck
    add.b                    #0x01, TABLESLOTPOSITION
    cmp.b                   #MAINSCREEN, CURRENTSCREEN
    bne                       @Skipc
    move.b                  TABLESLOTPOSITION, CHANNELNUMBER
    @Skipc:
    cmp.b                    #0x04, PATTABLEPOSITION
    beq                        @SkipCheck

    cmp.b                   #CHAINSCREEN, CURRENTSCREEN
    beq                       @SkipCheck

    jsr                         CHECKSLOTWINDOWRIGHT
    @SkipCheck:
    cmp.w                   CURSBOUNDARYMAXX, d6                               ;check x position of cursor to make sure we're staying in bounds
    bge                        @Skipa
    move.b                 CURRENTTABLESLOT, d1
    add.b                   d7, d1
    move.b                d1, CURRENTTABLESLOT
    add.w                   d0, d5                                                            ;add old x value and 16 pixels to get new x value
    add.w                   d0, d6
    move.w                d5, CURSORRAMX
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                d6, CURSORRAM2X
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port

    @Skipa:
    rts



;========================Cursor movement Notation tables=======
;This code handles the cursor movement and such when it's on the Note tables.
;========================================================
MOVECURSORNOTATION:
;d0 how many pixels to move (8 pixels for one row) = 0x08
;d1 sprite ID, = 0x00
;d2 sprite 2 ID, = 0x01
;d3 =Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right
    move.w              #0x00a0, CURSORRAMX
    move.w              #0x00a8, CURSORRAM2X
    move.w              #0x00b0, CURSORRAM3X
    move.w              #0x00a0, CURSORPOSITIONRAM2
    move.w              #0x00a8, CURSORPOSITIONRAM3
    move.w              #0x00b0, CURSORPOSITIONRAM4


    swap                  d1                ;d1 0x00000000
    move.b               #0x8, d2
    swap                  d2                ;d2 0x00080000
    moveq                 #0x0, d4
    move.b                #0x10, d4
    swap                    d4

    add.l                    #VDPWRITESPRITE, d1              ;0x60000003
    add.l                    #VDPWRITESPRITE, d2              ;0x60010003
    add.l                     #VDPWRITESPRITE, d4
    move.l                  d1, CURSORATTRIBUTERAM     ;This is for the VDP control port during vblank
    move.l                  d2, CURSORATTRIBUTERAM2
    move.l                  d4, CURSORATTRIBUTERAM3
    moveq                  #0x0, d2
;TODO Cursor work.
    move.l                #CURSORRAMY, a2                     ;Ready ram address for y position
    move.w               (a2), d4                                      ; move y value to d4
    move.l                  #CURSORRAMX, a3
    move.w                (a3), d5
    move.l                  #CURSORRAM2X, a4
    move.w                  (a4), d6
    move.l                    #CURSORRAM3X, a5
    move.l                    (a5), d2

    cmp.b                   #0x01, d3
    beq                       ADDY3
    cmp.b                   #0x00, d3
    beq                      SUBTRACTY3
    cmp.b                   #0x02, d3
    beq                         @END
    cmp.b                   #0x03, d3   ;Check to see if left button is pressed
    beq                       SUBTRACTX3
    cmp.b                   #0x04, d3  ; Check to see if right button is pressed
    beq                        ADDX3

    @END:
    rts

SUBTRACTY3:
    cmp.b                   #0x00, NOTESLOTPOSITION
    beq                       @SkipCheck
    sub.b                    #0x01, NOTESLOTPOSITION
    jsr                         CHECKSLOTWINDOWUP
    @SkipCheck:
    cmp.w                   CURSBOUNDARYMINY, d4                               ;check y position of cursor to make sure we're staying in bounds
    ble                        @Skips

    sub.b                   #0x01, CURRENTTABLESLOTNOTE
    sub.b                   #0x02, CURRENTTABLESLOT
    sub.w                   d0, d4                                      ;sub old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skips:
    rts

SUBTRACTX3:

    rts

ADDY3:
    cmp.b                   #0x1f, NOTESLOTPOSITION
    beq                       @SkipCheck
    add.b                    #0x01, NOTESLOTPOSITION
    jsr                         CHECKSLOTWINDOWDOWN
   @SkipCheck:
    cmp.w                   CURSBOUNDARYMAXY, d4                               ;check y position of cursor to make sure we're staying in bounds
    bge                        @Skipa

    add.b                   #0x01, CURRENTTABLESLOTNOTE
    add.b                   #0x02, CURRENTTABLESLOT
    add.w                   d0, d4                                      ;add old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skipa:
    rts

ADDX3:
    move.b                    #0x01, NOTATIONEDITMODE ; Set edit mode to instrument number
    move.w              #0x00c8, CURSORRAMX
    move.w              #0x00d0, CURSORRAM2X
    move.w              #0x0000, CURSORRAM3X
    move.w              #0x00c8, CURSORPOSITIONRAM2
    move.w              #0x00d0, CURSORPOSITIONRAM3
    move.w              #0x0000, CURSORPOSITIONRAM4
    ;jsr                             getcurrentslotmeta
  ;  jsr                             UPDATENOTEENTRYCURSOR ; to prevent cursor drawing glitches we will immediately update it

    rts

MOVECURSORINSTRUMENTNUMBER:
;d0 how many pixels to move (8 pixels for one row) = 0x08
;d1 sprite ID, = 0x00
;d2 sprite 2 ID, = 0x01
;d3 =Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right

    swap                  d1                ;d1 0x00000000
    move.b               #0x8, d2
    swap                  d2                ;d2 0x00080000

    add.l                    #VDPWRITESPRITE, d1              ;0x60000003
    add.l                    #VDPWRITESPRITE, d2              ;0x60010003
    move.l                  d1, CURSORATTRIBUTERAM     ;This is for the VDP control port during vblank
    move.l                  d2, CURSORATTRIBUTERAM2     ;This is for the VDP control port during vblank

    moveq                   #0x0, d4
    moveq                   #0x0, d5
    moveq                   #0x0, d6

    move.l                #CURSORRAMY, a2                     ;Ready ram address for y position
    move.w               (a2), d4                                      ; move y value to d4
    move.l                  #CURSORRAMX, a3
    move.w                (a3), d5
    move.l                  #CURSORRAM2X, a4
    move.w                  (a4), d6

    cmp.b                   #0x01, d3
    beq                       ADDY4
    cmp.b                   #0x00, d3
    beq                      SUBTRACTY4
    cmp.b                   #0x02, d3
    beq                         @END
    cmp.b                   #0x03, d3   ;Check to see if left button is pressed
    beq                       SUBTRACTX4
    cmp.b                   #0x04, d3  ; Check to see if right button is pressed
    beq                        ADDX4

    @END:
    rts

SUBTRACTY4:
    cmp.b                   #0x00, NOTESLOTPOSITION
    beq                       @SkipCheck
    sub.b                    #0x01, NOTESLOTPOSITION
    jsr                         CHECKSLOTWINDOWUP
   @SkipCheck:
    cmp.w                   CURSBOUNDARYMINY, d4                               ;check y position of cursor to make sure we're staying in bounds
    ble                        @Skips
    sub.b                   #0x01, CURRENTTABLESLOTNOTE
    sub.b                   #0x02,CURRENTTABLESLOT
    sub.w                   d0, d4                                      ;sub old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skips:
    rts

SUBTRACTX4:
    cmp.b                     #0x01, NOTATIONEDITMODE
    beq                          @MoveToNoteEdit
    cmp.b                      #0x02, NOTATIONEDITMODE
    beq                          @MoveToInstrumentNumber
    @MoveToNoteEdit:
    move.b                   #0x00, NOTATIONEDITMODE  ; Set edit mode to Notation
    move.w              #0x00a0, CURSORRAMX
    move.w              #0x00a8, CURSORRAM2X
    move.w              #0x00b0, CURSORRAM3X
    move.w              #0x00a0, CURSORPOSITIONRAM2
    move.w              #0x00a8, CURSORPOSITIONRAM3
    move.w              #0x00b0, CURSORPOSITIONRAM4

    rts
    @MoveToInstrumentNumber:
    move.b                    #0x01, NOTATIONEDITMODE ; Set edit mode to instrument number
    move.w              #0x00c8, CURSORRAMX
    move.w              #0x00d0, CURSORRAM2X
    move.w              #0x0000, CURSORRAM3X
    move.w              #0x00c8, CURSORPOSITIONRAM2
    move.w              #0x00d0, CURSORPOSITIONRAM3
    move.w              #0x0000, CURSORPOSITIONRAM4
    sub.b                   #0x01, CURRENTTABLESLOT
    rts
ADDY4:
    cmp.b                   #0x1f, NOTESLOTPOSITION
    beq                       @SkipCheck
    add.b                    #0x01, NOTESLOTPOSITION
    jsr                         CHECKSLOTWINDOWDOWN
   @SkipCheck:
    cmp.w                   CURSBOUNDARYMAXY, d4                               ;check y position of cursor to make sure we're staying in bounds
    bge                        @Skipa
    add.b                   #0x01, CURRENTTABLESLOTNOTE
    add.b                   #0x02, CURRENTTABLESLOT
    add.w                   d0, d4                                      ;add old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skipa:

    rts

ADDX4:
    cmp.b                   #0x01, NOTATIONEDITMODE
    beq                     @MoveToVelocity
    cmp.b               #0x02, NOTATIONEDITMODE
    beq                     @MoveToCommands
    @MoveToVelocity:
    move.b                #0x02, NOTATIONEDITMODE
    move.w              #0x00e8, CURSORRAMX
    move.w              #0x00f0, CURSORRAM2X
    move.w              #0x0000, CURSORRAM3X
    move.w              #0x00e8, CURSORPOSITIONRAM2
    move.w              #0x00f0, CURSORPOSITIONRAM3
    move.w              #0x0000, CURSORPOSITIONRAM4
    add.b                  #0x01, CURRENTTABLESLOT
    rts

    @MoveToCommands:
    move.b                #0x03, NOTATIONEDITMODE
    move.w              #0x0100, CURSORRAMX
    move.w              #0x0108, CURSORRAM2X
    move.w              #0x0100, CURSORPOSITIONRAM2
    move.w              #0x0108, CURSORPOSITIONRAM3
    sub.b                   #0x01, CURRENTTABLESLOT
    rts






MOVECURSORCOMMANDS:
;d0 how many pixels to move (8 pixels for one row) = 0x08
;d1 sprite ID, = 0x00
;d2 sprite 2 ID, = 0x01
;d3 =Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right

    swap                  d1                ;d1 0x00000000
    move.b               #0x8, d2
    swap                  d2                ;d2 0x00080000

    add.l                    #VDPWRITESPRITE, d1              ;0x60000003
    add.l                    #VDPWRITESPRITE, d2              ;0x60010003
    move.l                  d1, CURSORATTRIBUTERAM     ;This is for the VDP control port during vblank
    move.l                  d2, CURSORATTRIBUTERAM2     ;This is for the VDP control port during vblank

    moveq                   #0x0, d4
    moveq                   #0x0, d5
    moveq                   #0x0, d6

    move.l                #CURSORRAMY, a2                     ;Ready ram address for y position
    move.w               (a2), d4                                      ; move y value to d4
    move.l                  #CURSORRAMX, a3
    move.w                (a3), d5
    move.l                  #CURSORRAM2X, a4
    move.w                  (a4), d6

    cmp.b                   #0x01, d3
    beq                       ADDY7
    cmp.b                   #0x00, d3
    beq                      SUBTRACTY7
    cmp.b                   #0x02, d3
    beq                         @END
    cmp.b                   #0x03, d3   ;Check to see if left button is pressed
    beq                       SUBTRACTX7
    cmp.b                   #0x04, d3  ; Check to see if right button is pressed
    beq                        ADDX7

    @END:
    rts

SUBTRACTY7:
    cmp.b                   #0x00, NOTESLOTPOSITION
    beq                       @SkipCheck
    sub.b                    #0x01, NOTESLOTPOSITION
    jsr                         CHECKSLOTWINDOWUP
   @SkipCheck:
    cmp.w                   CURSBOUNDARYMINY, d4                               ;check y position of cursor to make sure we're staying in bounds
    ble                        @Skips
    sub.b                   #0x01, CURRENTTABLESLOTNOTE
    sub.b                   #0x02,CURRENTTABLESLOT
    sub.w                   d0, d4                                      ;sub old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skips:
    rts

SUBTRACTX7:
    cmp.w                      #0x0110, CURSORRAMX
    beq                          @MoveToCOMMANDTYPE
    cmp.w                      #0x0100, CURSORRAMX
    beq                          @MoveToVelocity
    rts
    @MoveToCOMMANDTYPE:
    move.w              #0x0100, CURSORRAMX
    move.w              #0x0108, CURSORRAM2X
    move.w              #0x0100, CURSORPOSITIONRAM2
    move.w              #0x0108, CURSORPOSITIONRAM3
    sub.b                   #0x01, CURRENTTABLESLOT
    rts
    @MoveToVelocity:
    move.b                #0x02, NOTATIONEDITMODE
    move.w              #0x00e8, CURSORRAMX
    move.w              #0x00f0, CURSORRAM2X
    move.w              #0x00e8, CURSORPOSITIONRAM2
    move.w              #0x00f0, CURSORPOSITIONRAM3
    add.b                   #0x01, CURRENTTABLESLOT
    rts

ADDY7:
    cmp.b                   #0x1f, NOTESLOTPOSITION
    beq                       @SkipCheck
    add.b                    #0x01, NOTESLOTPOSITION
    jsr                         CHECKSLOTWINDOWDOWN
   @SkipCheck:
    cmp.w                   CURSBOUNDARYMAXY, d4                               ;check y position of cursor to make sure we're staying in bounds
    bge                        @Skipa
    add.b                   #0x01, CURRENTTABLESLOTNOTE
    add.b                   #0x02, CURRENTTABLESLOT
    add.w                   d0, d4                                      ;add old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skipa:

    rts

ADDX7:
    cmp.w                   #0x0100, CURSORRAMX
    beq                     @MoveToCommandData

    rts

    @MoveToCommandData:

    move.w              #0x0110, CURSORRAMX
    move.w              #0x0118, CURSORRAM2X
    move.w              #0x0110, CURSORPOSITIONRAM2
    move.w              #0x0118, CURSORPOSITIONRAM3
    add.b                   #0x01, CURRENTTABLESLOT
    rts





MOVECURSORSYNTH:
;d0 how many pixels to move (8 pixels for one row) = 0x08
;d1 sprite ID, = 0x00
;d2 sprite 2 ID, = 0x01
;d3 =Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right

    swap                  d1                ;d1 0x00000000
    move.b               #0x8, d2
    swap                  d2                ;d2 0x00080000

    add.l                    #VDPWRITESPRITE, d1              ;0x60000003
    add.l                    #VDPWRITESPRITE, d2              ;0x60010003
    move.l                  d1, CURSORATTRIBUTERAM     ;This is for the VDP control port during vblank
    move.l                  d2, CURSORATTRIBUTERAM2     ;This is for the VDP control port during vblank

    moveq                   #0x0, d4
    moveq                   #0x0, d5
    moveq                   #0x0, d6

    move.l                #CURSORRAMY, a2                     ;Ready ram address for y position
    move.w               (a2), d4                                      ; move y value to d4
    move.l                  #CURSORRAMX, a3
    move.w                (a3), d5
    move.l                  #CURSORRAM2X, a4
    move.w                  (a4), d6

    cmp.b                   #0x01, d3
    beq                       ADDY5
    cmp.b                   #0x00, d3
    beq                      SUBTRACTY5
    cmp.b                   #0x02, d3
    beq                         @END
    cmp.b                   #0x03, d3   ;Check to see if left button is pressed
    beq                       SUBTRACTX5
    cmp.b                   #0x04, d3  ; Check to see if right button is pressed
    beq                        ADDX5

    @END:
    rts

SUBTRACTY5:
    cmp.w                   #0xD0, d4                                                   ;Are we at the top of operator slots? If yes go back to global synth param.
    beq                         @Global
    cmp.w                   CURSBOUNDARYMINY, d4                               ;check y position of cursor to make sure we're staying in bounds
    ble                        @Skips
    cmp.w                   #0x148, d4  ;this is the y position for the bottom of the operator slots, if we're here, moving down will result in
    beq                        @ReturntoOperatorSlots
    cmp.w                   #0x150, d4
    beq                         @InstrumentSlot
    sub.b                   #0x01,CURRENTTABLESLOT
    sub.w                   d0, d4                                      ;sub old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skips:
    rts

    @ReturntoOperatorSlots:
    move.b              #0x00, SYNTHEDITMODE  ;back to normal!
    move.b              #0x12, CURRENTTABLESLOT ;Restore slot of AM operator 1
    move.w                #0x120, CURSORRAMY
    move.w                 #0x120, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00F8, d5
    move.w                   #0x0100, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    rts
    @Global:

    move.b                   #0x07, CURRENTTABLESLOT
    move.w              #0x0108, CURSORRAMX
    move.w              #0x0110, CURSORRAM2X
    move.w              #0x00c0, CURSORRAMY
    move.w              #0x00c0, CURSORPOSITIONRAM
    move.w              #0x0108, CURSORPOSITIONRAM2
    move.w              #0x0110, CURSORPOSITIONRAM3

    rts

    @InstrumentSlot:
    move.w                #0x148, CURSORRAMY
    move.w                 #0x148, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00E8, d5
    move.w                   #0x00F0, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    move.b                  #0x01, SYNTHEDITMODE    ; SYNTHEDIT MODE = 0x01, meaning we're now editing the instrument number slot
    rts
SUBTRACTX5:
    cmp.w                   #0x0700, CURRENTTABLESLOT                               ;Are we moving to the other slots?
    ble                        @Skipd
    cmp.w                   #0x150, d4   ;Are we on the instrument naming slot? We need to check X boundaries if so and handle it differently
    beq                         @CheckMinXInstrumentName
    cmp.w                   #0x00f8, d5
    beq                        @Skipd
    cmp.w                   #0x148, d4   ;Are we on the instrument number slot? No movement if so.
    beq                         @Skipd

    sub.b                   #0x0b, CURRENTTABLESLOT
    sub.w                   #0x0020, d5                                      ;add old x value and 20h pixels to get new x value
    sub.w                   #0x0020, d6                                      ;add old x value and 20h pixels to get new x value
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    @Skipd:
    rts

    @CheckMinXInstrumentName:
    cmp.w                   #0xB8, d5
    beq                        @SkipThis
    sub.b                     #0x01, CURRENTTABLESLOT
    sub.w                       #0x0008, d5
    move.w                      d5, CURSORRAMX
    move.w                        d5, CURSORPOSITIONRAM2
    @SkipThis:
    rts

ADDY5:
    cmp.w                   #0x0700, CURRENTTABLESLOT                               ;Are we moving to the other slots?
    beq                        @Skipa
    cmp.w                   #0x120, d4  ;this is the y position for the bottom of the operator slots, if we're here, moving down will result in
    beq                        @InstrumentSlot                                    ;moving to the instrument number slot, which relies on a different address.
    cmp.w                   #0x148, d4  ;this is the y position for the instrument number slot, if we're here, moving down will result in
    beq                        @InstrumentName                                   ;moving to 1st letter of the instrument name, this relies on current table being 0x34.
    cmp.w                   #0x150, d4
    beq                       @Done
    add.b                   #0x01, CURRENTTABLESLOT
    add.w                   d0, d4                                      ;add old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port

    @Done:
    rts
    @InstrumentSlot:
    move.w                #0x148, CURSORRAMY
    move.w                 #0x148, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00E8, d5
    move.w                   #0x00F0, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    move.b                  #0x01, SYNTHEDITMODE    ; SYNTHEDIT MODE = 0x01, meaning we're now editing the instrument number slot
    rts
    @InstrumentName:
    move.w                #0x150, CURSORRAMY
    move.w                 #0x150, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00B8, d5
    move.w                   #0x01F0, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    move.b                  #0x02, SYNTHEDITMODE    ; SYNTHEDIT MODE = 0x02, meaning we're now editing the instrument name slot
    move.b                  #0x34, CURRENTTABLESLOT
    rts
    @Skipa:

    add.b                   #0x01, CURRENTTABLESLOT
    move.w              #0x00f8, CURSORRAMX
    move.w              #0x0100, CURSORRAM2X
    move.w              #0x00D0, CURSORRAMY
    move.w              #0x00D0, CURSORPOSITIONRAM
    move.w              #0x00f8, CURSORPOSITIONRAM2
    move.w              #0x0100, CURSORPOSITIONRAM3

    rts
ADDX5:
    cmp.w                   #0x0700, CURRENTTABLESLOT                               ;Are we moving to the other slots?
    ble                        @Skipd
    cmp.w                   CURSBOUNDARYMAXX, d5
    beq                        @Skipd
    cmp.w                   #0x148, d4   ;Are we on the instrument number slot? No movement if so.
    beq                         @Skipd
    cmp.w                   #0x150, d4   ;Are we on the instrument naming slot? We need to check X boundaries if so and handle it differently
    beq                         @CheckMaxXInstrumentName
    add.b                   #0x0b, CURRENTTABLESLOT
    add.w                   #0x0020, d5                                      ;add old x value and 20h pixels to get new x value
    add.w                   #0x0020, d6                                      ;add old x value and 20h pixels to get new x value
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    @Skipd:
    rts

    @CheckMaxXInstrumentName:
    cmp.w                   #0x110, d5
    beq                        @SkipThis
    add.b                     #0x01, CURRENTTABLESLOT
    add.w                       #0x0008, d5
    move.w                      d5, CURSORRAMX
    move.w                        d5, CURSORPOSITIONRAM2
    @SkipThis:
    rts



MOVECURSORSYNTHPSG:
;d0 how many pixels to move (8 pixels for one row) = 0x08
;d1 sprite ID, = 0x00
;d2 sprite 2 ID, = 0x01
;d3 =Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right

    swap                  d1                ;d1 0x00000000
    move.b               #0x8, d2
    swap                  d2                ;d2 0x00080000

    add.l                    #VDPWRITESPRITE, d1              ;0x60000003
    add.l                    #VDPWRITESPRITE, d2              ;0x60010003
    move.l                  d1, CURSORATTRIBUTERAM     ;This is for the VDP control port during vblank
    move.l                  d2, CURSORATTRIBUTERAM2     ;This is for the VDP control port during vblank

    moveq                   #0x0, d4
    moveq                   #0x0, d5
    moveq                   #0x0, d6

    move.l                #CURSORRAMY, a2                     ;Ready ram address for y position
    move.w               (a2), d4                                      ; move y value to d4
    move.l                  #CURSORRAMX, a3
    move.w                (a3), d5
    move.l                  #CURSORRAM2X, a4
    move.w                  (a4), d6

    cmp.b                   #0x01, d3
    beq                       ADDY6
    cmp.b                   #0x00, d3
    beq                      SUBTRACTY6
    cmp.b                   #0x02, d3
    beq                         @END
    cmp.b                   #0x03, d3   ;Check to see if left button is pressed
    beq                       SUBTRACTX6
    cmp.b                   #0x04, d3  ; Check to see if right button is pressed
    beq                        ADDX6

    @END:
    rts

SUBTRACTY6:
    cmp.w                   #0x0500, CURRENTTABLESLOT                                                   ;Are we at the NCS slot? If yes go back to synth param.
    beq                         @SynthParam
    cmp.w                   CURSBOUNDARYMINY, d4                               ;check y position of cursor to make sure we're staying in bounds
    ble                        @Skips
    cmp.w                   #0x148, d4  ;this is the y position for the instrument number slot, if we're here, moving up should go to NCS
    beq                        @ReturntoNCS
    cmp.w                   #0x150, d4
    beq                         @InstrumentSlot
    sub.b                   #0x01,CURRENTTABLESLOT
    sub.w                   d0, d4                                      ;sub old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port
    @Skips:
    rts

    @ReturntoNCS:
    move.b              #0x00, SYNTHEDITMODE  ;back to normal!
    move.b              #0x05, CURRENTTABLESLOT ;Restore slot NCS
    move.w              #0x0128, CURSORRAMX
    move.w              #0x0130, CURSORRAM2X
    move.w              #0x00b0, CURSORRAMY
    move.w              #0x00b0, CURSORPOSITIONRAM
    move.w              #0x0128, CURSORPOSITIONRAM2
    move.w              #0x0130, CURSORPOSITIONRAM3
    rts
    @SynthParam:

    sub.b                   #0x01, CURRENTTABLESLOT
    move.w              #0x00d0, CURSORRAMX
    move.w              #0x00d8, CURSORRAM2X
    move.w              #0x00a8, CURSORRAMY
    move.w              #0x00a8, CURSORPOSITIONRAM
    move.w              #0x00d0, CURSORPOSITIONRAM2
    move.w              #0x00d8, CURSORPOSITIONRAM3

    rts

    @InstrumentSlot:
    move.w                #0x148, CURSORRAMY
    move.w                 #0x148, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00E8, d5
    move.w                   #0x00F0, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    move.b                  #0x01, SYNTHEDITMODE    ; SYNTHEDIT MODE = 0x01, meaning we're now editing the instrument number slot
    rts
SUBTRACTX6:

    cmp.w                   #0x150, d4   ;Are we on the instrument naming slot? We need to check X boundaries if so and handle it differently
    beq                         @CheckMinXInstrumentName

    rts

    @CheckMinXInstrumentName:
    cmp.w                   #0xB8, d5
    beq                        @SkipThis
    sub.b                     #0x01, CURRENTTABLESLOT
    sub.w                       #0x0008, d5
    move.w                      d5, CURSORRAMX
    move.w                        d5, CURSORPOSITIONRAM2
    @SkipThis:
    rts

ADDY6:
    cmp.w                   #0x0400, CURRENTTABLESLOT                               ;Are we moving to the Noise Clock Source slot?
    beq                        @NCS
    cmp.w                   #0x0500, CURRENTTABLESLOT  ;this is the y position for the bottom of the operator slots, if we're here, moving down will result in
    beq                        @InstrumentSlot                                    ;moving to the instrument number slot, which relies on a different address.
    cmp.w                   #0x148, d4  ;this is the y position for the instrument number slot, if we're here, moving down will result in
    beq                        @InstrumentName                                   ;moving to 1st letter of the instrument name, this relies on current table being 0x34.
    cmp.w                   #0x150, d4
    beq                       @Done
    add.b                   #0x01, CURRENTTABLESLOT
    add.w                   d0, d4                                      ;add old y value and 8 pixels to get new y value
    move.w                d4, CURSORRAMY
    move.w                 d4, CURSORPOSITIONRAM       ;This is for VDP  Data port

    @Done:
    rts
    @InstrumentSlot:
    move.w                #0x148, CURSORRAMY
    move.w                 #0x148, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00E8, d5
    move.w                   #0x00F0, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    move.b                  #0x01, SYNTHEDITMODE    ; SYNTHEDIT MODE = 0x01, meaning we're now editing the instrument number slot
    move.b                  #0x06, CURRENTTABLESLOT
    rts
    @InstrumentName:
    move.w                #0x150, CURSORRAMY
    move.w                 #0x150, CURSORPOSITIONRAM       ;This is for VDP  Data port
    move.w                   #0x00B8, d5
    move.w                   #0x01F0, d6
    move.w                d5, CURSORRAMX
    move.w                d6, CURSORRAM2X
    move.w                 d5, CURSORPOSITIONRAM2       ;This is for VDP  Data port
    move.w                 d6, CURSORPOSITIONRAM3       ;This is for VDP  Data port
    move.b                  #0x02, SYNTHEDITMODE    ; SYNTHEDIT MODE = 0x02, meaning we're now editing the instrument name slot
    move.b                  #0x06, CURRENTTABLESLOT
    rts
    @NCS:

    add.b                   #0x01, CURRENTTABLESLOT
    move.w              #0x0128, CURSORRAMX
    move.w              #0x0130, CURSORRAM2X
    move.w              #0x00b0, CURSORRAMY
    move.w              #0x00b0, CURSORPOSITIONRAM
    move.w              #0x0128, CURSORPOSITIONRAM2
    move.w              #0x0130, CURSORPOSITIONRAM3

    rts

ADDX6:


    cmp.w                   #0x150, d4   ;Are we on the instrument naming slot? We need to check X boundaries if so and handle it differently
    beq                         @CheckMaxXInstrumentName

    rts

    @CheckMaxXInstrumentName:
    cmp.w                   #0x110, d5
    beq                        @SkipThis
    add.b                     #0x01, CURRENTTABLESLOT
    add.w                       #0x0008, d5
    move.w                      d5, CURSORRAMX
    move.w                        d5, CURSORPOSITIONRAM2
    @SkipThis:
    rts
