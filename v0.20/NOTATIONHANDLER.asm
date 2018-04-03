NESLOTMETA:
    cmp.b                 #0x00, NOTATIONEDITMODE
    beq                     PHRASESLOTMETA
    cmp.b                #0x01, NOTATIONEDITMODE
    beq                     INSTRNUMSLOTMETA
    cmp.b                #0x02, NOTATIONEDITMODE
    beq                     VELOCITYSLOTMETA
    cmp.b                #0x03, NOTATIONEDITMODE
    beq                     COMMANDSSLOTMETA
    rts

PHRASESLOTMETA:
    move.l              #PHRASETABLERAM, d2
    move.w               NOTECURRENTSLOTDATA, d1
    move.w              d1, (a0)
    jsr                     CURRENTTABLENOTE
    move.w              (a0), NOTEDIGITS
    rts

INSTRNUMSLOTMETA:
    move.l              #PHRASETABLERAM, d2
    add.l                   #0x00002800, d2
    move.b               INSTRCURRENTSLOTDATA, d1
    move.b              d1, (a0)
    jsr                     CURRENTTABLE
    move.b              (a0), d7
    cmp.b                 #0xEF, d7
    beq                      @NoUpdate
    move.b              (a0), NOTEINSTRUMENTNUMBERCACHE  ;Remember the instrument number we used here for songwriting convenience.
    move.b              NOTEINSTRUMENTNUMBERCACHE, SYNTHINSTRUMENTNUMBER
    @NoUpdate:
    rts

VELOCITYSLOTMETA:
    move.l                #PHRASETABLERAM, d2
    add.l                   #0x00002800, d2
    move.b                 VELOCITYCURRENTSLOTDATA, d1
    move.b                  d1, (a0)
    jsr                         CURRENTTABLE
    rts

COMMANDSSLOTMETA:
    move.l                #PHRASETABLERAM, d2
    add.l                   #0x00005000, d2
    move.b                 COMMANDSCURRENTSLOTDATA, d1
    move.b                  d1, (a0)
    jsr                         CURRENTTABLEFFNORM
    rts
;=================Notation Slot handling==================
;This code is made to handle Notation, sharps, flats, and octave number.
;I've had problems getting this basic idea started because for some reason
;it would conflict with the hex handler for standard tables.
;===================================================

CURRENTTABLENOTE:                          ;This code selects which slot on the pattern table we're going to edit , and handles digit boundaries

    move.w              TABLESLOTMODDIRECTION, d7
    cmp.b                #0x01, CBUTTON   ; Is C button being pressed?
    bne                    ENDNoteSKIP


    moveq               #0x0, d2
    move.w            (a0), d2
    cmp.b                 #0x01, ABUTTON ;If A is being held in addition to C, then we need to write OFF.
    beq                     ENTERNOTEOFF
    cmp.b                 #0x01, BBUTTON  ;If B is being held in addition to C, then we need to default slot.
    beq                      DefaultSlotNote
    cmp.w              #0xEFFB, d2
    beq                     InitSlotNote
    cmp.w              #0x999B, d2 ;We can init OFF notes too.
    beq                     InitSlotNote
    moveq                #0x0, d3
    moveq                 #0x0, d4
    move.b               d2, d3           ;Isolate lower byte
    ror.w                   #0x04, d3
    ror.w                   #0x08, d2
    move.b               d2, d4           ;Isolate upper byte
    ror.w                   #0x08, d2
    cmp.w                #0x1000, d7    ; C + Up Button?
    beq                    AddOctave

    cmp.w                #0x0100, d7 ; C + Down Button?
    beq                    SubOctave

    cmp.w                #0x0010, d7    ; C + Left Button?
    beq                    SubNote

    cmp.w                #0x0001, d7 ; C+ Right Button?
    beq                    AddNote


    bra.w                   ENDNoteSKIPRemembernote  ;This will skip processing digits, but will memorize our Note and Instrument number for us.

AddOctave:
    cmp.b                   #0x07, d3
    bge                      TopNote
    add.w                   #0x0010, d2
    move.w             d2, (a0)
    bra.w                  ENDNOTE

TopNote:
    move.w              #0x208b, d2
    move.w              d2, (a0)
    bra.w                   ENDNOTE
BottomNote:
    move.w                #0x220B, d2
    move.w                d2, (a0)
    bra.w                   ENDNOTE

SubOctave:
    cmp.b                   #0x01, d3
    ble                      BottomNote
    sub.w                   #0x0010, d2
    move.w             d2, (a0)
    bra.w                  ENDNOTE

AddNote:
    cmp.w                   #0x208b, d2 ;Check to see if we're at the Sega Genesis' maximum supported note and octave
    beq                         ENDNOTE     ;we are, so we don't do anything here
    cmp.b                    #0x01, d4
    beq                       AflattoA
    cmp.b                     #0x00, d4
    beq                       AtoBflat
    cmp.b                   #0x11, d4
    beq                        BflattoB
    cmp.b                     #0x10, d4
    beq                         BtoC       ;add octave number
    cmp.b                    #0x20, d4
    beq                         CtoCsharp
    cmp.b                     #0x22, d4
    beq                         CsharptoD
    cmp.b                      #0x30, d4
    beq                         DtoEflat
    cmp.b                      #0x41, d4
    beq                          EflattoE
    cmp.b                      #0x50, d4
    beq                         FtoFsharp
    cmp.b                      #0x52, d4
    beq                        FsharptoG
    add.w                   #0x1000, d2
    cmp.w                   #0x7000,d2
    bge                        ResettoA
    move.w                d2, (a0)
    bra.w                   ENDNOTE
ResettoA:

    sub.w                   #0x7000, d2 ;Resets note to A
    add.w                   #0x0100, d2 ;Flag it as a flat note.

    move.w                d2, (a0)
    bra.w                   ENDNOTE

AflattoA:
    sub.w                   #0x0100, d2
    move.w                 d2, (a0)
    bra.w                     ENDNOTE
AtoBflat:
    add.w                    #0x1100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
BflattoB:
    sub.w                     #0x0100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
BtoC:
    add.w                       #0x1000, d2
    add.w                      #0x0010, d2
    move.w                     d2, (a0)
    bra.w                       ENDNOTE
CtoCsharp:
    add.w                     #0x0200, d2
    move.w                  d2, (a0)
    bra.w                       ENDNOTE
CsharptoD:
    Sub.w                     #0x0200, d2
    add.w                     #0x1000, d2
    move.w                   d2, (a0)
    bra.w                      ENDNOTE
DtoEflat:
    add.w                       #0x1100, d2
    move.w                      d2, (a0)
    bra.w                         ENDNOTE
EflattoE:
    sub.w                       #0x0100, d2
    move.w                     d2, (a0)
    bra.w                       ENDNOTE
FtoFsharp:
    add.w                       #0x0200, d2
    move.w                      d2, (a0)
    bra.w                           ENDNOTE
FsharptoG:
    sub.w                         #0x0200, d2
    add.w                          #0x1000, d2
    move.w                      d2, (a0)
    bra.w                           ENDNOTE

SubNote:
    cmp.w                   #0x220b, d2 ;Check to see if we're at the Sega Genesis' minimum supported note and octave
    beq                         ENDNOTE     ;we are, so we don't do anything here
    cmp.b                      #0x10, d4
    beq                         BtoBflat
    cmp.b                      #0x11, d4
    beq                        BflattoA
    cmp.b                    #0x00, d4
    beq                         AtoAflat
    cmp.b                    #0x01, d4
    beq                         ResettoG
    cmp.b                    #0x60, d4
    beq                        GtoFsharp
    cmp.b                    #0x52, d4
    beq                        FsharptoF
    cmp.b                    #0x40, d4
    beq                        EtoEflat
    cmp.b                   #0x41, d4
    beq                       EflattoD
    cmp.b                    #0x30, d4
    beq                         DtoCsharp
    cmp.b                    #0x22, d4
    beq                         CsharptoC
    cmp.b                    #0x20, d4
    beq                         CtoB
    sub.w                   #0x1000, d2

    move.w                d2, (a0)
    bra.w                   ENDNOTE

BtoBflat:
    add.w                  #0x0100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
BflattoA:
    sub.w                   #0x1100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
AtoAflat:
    add.w                   #0x0100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
GtoFsharp:
    add.w                    #0x0200, d2
    sub.w                     #0x1000, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
FsharptoF:
    sub.w                      #0x0200, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
EtoEflat:
    add.w                      #0x0100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
EflattoD:
    sub.w                      #0x1100, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
DtoCsharp:
    sub.w                      #0x1000, d2
    add.w                       #0x0200, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
CsharptoC:
    sub.w                      #0x0200, d2
    move.w                  d2, (a0)
    bra.w                      ENDNOTE
CtoB:
    sub.w                       #0x0010, d2
    sub.w                       #0x1000, d2
    move.w                    d2, (a0)
    bra.w                       ENDNOTE
ResettoG:
    add.w                   #0x6000, d2 ;resets note to G
    sub.w                   #0x0100, d2
    move.w                d2, (a0)
    bra.w                   ENDNOTE

ENTERNOTEOFF:
    cmp.b               #0x01, BBUTTON
    beq                     ENDNOTESKIP
    move.w             #0x999B, (a0)
    bra.w                   ENDNOTESKIP

DefaultSlotNote:
    move.w             #0xEFFB, (a0)
    bra.w                   ENDNOTESKIP

InitSlotNote:
    cmp.b                   #0x01, BBUTTON
    beq                     ENDNote
    move.w               LASTNOTE, d2
    move.w             d2, (a0)
    ;======Also initiate instrument number slot=======
    moveq                   #0x0, d6
    move.l                  a0, d6  ;Copy the note table offset so we can use that to get our instrument number slot offset
    add.l                   #0x00002800, d6
    move.l                  d6, a1
    move.b                 INSTRUMENTNUMBERCACHE, (a1)
    bra.w                   ENDNote

ENDNote:
    move.w                  d2, LASTNOTE   ;Remember the last note we entered to make composition easier.
    move.b               #0x01, PRELISTENTOGGLE
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    move.b                #0x00, BBUTTON
    rts

ENDNOTESKIP:

    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    move.b                #0x00, BBUTTON
    rts

ENDNOTESKIPremembernote:
    move.w                  (a0), LASTNOTE   ;Remember the last note we entered to make composition easier.
    move.b                  NOTEINSTRUMENTNUMBERCACHE, INSTRUMENTNUMBERCACHE
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts
;====Converting hexadecimal bytes to musical notation===============
;My magnum opus in programming, finally I get to do something with music!
;Basically I already have it figured out on pen and paper, but I HAVE to see
; how this one turns out. This code converts hex bytes, into the proper values
; for the font. See legend below
;=================
;Upper byte Note/#b-
;Lower byte Octave/Blank tile
;Note = the upper number in this byte 0-6 represent A-G, and can be converted by adding 21 to this number.
;#b- or Sharp, Flat, Blank tile = The lower numbers of this byte 0-2 represent Blank/Flat/Sharp and
; the conversion is as follows, 0 is left alone, 1 is added to 5 for flat, and 2 is added to 1 for sharp
;Octave = quite simply the upper number of the lower byte represents the octave numbers 0-9, no conversion is necessary
;Blank tile = the lower value of this byte will always be B. This letter means that the final byte in this conversion process must always be
; 0x00, that way this extra tile is never drawn to screen and is therefor invisible.

ConvertHextoNotation:
    ;d2 is the upper byte to be converted.
    cmp.b           #0xEF, d2
    beq               @Unused
    cmp.b             #0x99, d2
    beq                 @OFFPart1
    movem.l                d3-d4, -(sp)
    moveq                   #0x0, d3
    moveq                   #0x0, d4
    rol.w                     #0x04, d2
    move.b                   d2, d4
    ror.b                       #0x04, d4
    ror.w                       #0x08, d2
    move.b                     d2, d3
; d3 now has the first value, d4 has the second. Now we just need to convert them to Notation form.
    add.b                       #0x21, d3   ;d3 is now ready to be drawn as a note.
    cmp.b                       #0x00, d4
    beq                           NumbertoBlank
    cmp.b                       #0x01, d4
    beq                           NumbertoFlat
    cmp.b                       #0x02, d4
    beq                           NumbertoSharp

    @Unused:
    move.w          #0x0D0D, d2
    rts
    @OFFPart1:
    move.w          #0x2F26, d2
    rts
NumbertoBlank:
    move.w          #0x0000, d4
    bra.w                   FinishConversion
NumbertoFlat:
    addq.b                      #0x05, d4
    bra.w                         FinishConversion
NumbertoSharp:
    addq.b                      #0x01, d4
    bra.w                          FinishConversion


FinishConversion:
    rol.w                        #0x08, d3
    moveq                      #0x0, d2
    move.b                     d4, d2
    add.w                       d3, d2
    movem.l                  (sp)+, d3-d4
    rts

ConvertHextoOctave:
;d2 has the value to convert.

    cmp.b                       #0xFB, d2
    beq                            @UnusedandBlank
    cmp.b                       #0x9B,   d2
    beq                             @OFFPart2
    movem.l                d3-d4, -(sp)
    moveq                       #0x0, d3
    moveq                       #0x0, d4
    move.b                      d2, d4
    ror.w                          #0x04, d4 ; The octave number in d4 is now isolated.
    add.b                           #0x10, d4
    moveq                        #0x0, d2
    move.b                      d4, d2
    rol.w                           #0x08, d2
    move.b                        d3, d2
    movem.l                  (sp)+, d3-d4
    rts

    @UnusedandBlank:
    move.w                      #0x0D00, d2
    rts

    @OFFPart2:
    move.w                     #0x2600, d2
    rts
