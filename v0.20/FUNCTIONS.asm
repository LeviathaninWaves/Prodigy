;=======================GETCURRENTSLOT===================================================
;This function gets the current slot for the current screen and uploads it to ram. Handy!
;=======================================================================================

GETCURRENTSLOTMETA:
    cmp.b               #MAINSCREEN, CURRENTSCREEN
    beq                   GETCURRENTSLOTMAIN
    cmp.b               #CHAINSCREEN, CURRENTSCREEN
    beq                   GETCURRENTSLOTCHAIN
    cmp.b               #NOTESCREEN, CURRENTSCREEN
    beq                   GETCURRENTSLOTNOTEENTRY
    cmp.b               #SYNTHSCREEN, CURRENTSCREEN
    beq                   GETCURRENTSLOTSYNTHPSGFM
    rts

GETCURRENTSLOTMAIN:
    move.l             #PATTABLERAM, d2
    jsr                     GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, MAINCURRENTSLOTDATA

    rts

GETCURRENTSLOTCHAIN:
    move.l             CURRENTSLOTADDRESS, d2
    jsr                     GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, CHAINCURRENTSLOTDATA
    rts

GETCURRENTSLOTNOTEENTRY: ;Meta routine for the Note entry tables
    cmp.b               #0x00, NOTATIONEDITMODE
    beq                   GETCURRENTSLOTPHRASE    ;Note
    cmp.b               #0x01, NOTATIONEDITMODE
    beq                    GETCURRENTSLOTINSTRNUM  ;Instrument number
    cmp.b               #0x02, NOTATIONEDITMODE
    beq                     GETCURRENTSLOTVELOCITY ;Velocity/Volume
    cmp.b               #0x03, NOTATIONEDITMODE
    beq                     GETCURRENTSLOTCOMMANDS ;Velocity/Volume
    rts

GETCURRENTSLOTPHRASE:
    move.l             PCURRENTSLOTADDRESS, d2
    jsr                    GETCURRENTSLOTNOTE
    move.w               (a0), d1
    move.w              d1, NOTECURRENTSLOTDATA
    adda.l                 #0x00002800, a0
    move.b                (a0), d1
    cmp.b                   #0xEF, d1    ;Check to make sure it's not blank,if it is we skip it because it can cause errors
    beq                      @Skip
    move.b                (a0)+, NOTEINSTRUMENTNUMBERCACHE
    move.b                  (a0), PRELISTENCURRENTVELOCITY
    bra.w                      @Done
    @Skip:
    suba.l                     #0x00002800, a0
    rts
    @Done:
    suba.l                     #0x00002801, a0
    rts

GETCURRENTSLOTINSTRNUM:
    move.l             PCURRENTSLOTADDRESS, d2
    add.l               #0x00002800, d2
    jsr                    GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, INSTRCURRENTSLOTDATA
    rts

GETCURRENTSLOTVELOCITY:
    move.l             PCURRENTSLOTADDRESS, d2
    add.l               #0x00002800, d2
    jsr                    GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, VELOCITYCURRENTSLOTDATA
    rts

GETCURRENTSLOTCOMMANDS:
    move.l             PCURRENTSLOTADDRESS, d2
    add.l               #0x00005000, d2
    jsr                    GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, COMMANDSCURRENTSLOTDATA
    rts

GETCURRENTSLOTSYNTHPSGFM:
    cmp.b               #0x00, SYNTHSCREENPSGFM
    beq                   GETCURRENTSLOTSYNTH
    cmp.b               #0X01, SYNTHSCREENPSGFM
    beq                   GETCURRENTSLOTSYNTHPSG
    rts

GETCURRENTSLOTSYNTH:
    cmp.b               #0x01, SYNTHEDITMODE ;testing
    beq                    @SYNTHINSTSLOT
    move.l             CURRENTSYNTHSLOTADDRESS, d2
    move.b              SYNTHINSTRUMENTNUMBER, d0  ;The Patch ID we're editing
    mulu.w                #0x40, d0            ;We're getting the offset for which FM patch's data we're going to edit
    add.l                  d0, d2
    moveq               #0x0, d0

    jsr                     GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, SYNTHCURRENTSLOTDATA
    rts

    @SYNTHINSTSLOT:
    move.b                  SYNTHINSTRUMENTNUMBER, d1
    move.l                   #SYNTHINSTRUMENTNUMBER, a0
    move.b                  d1, SYNTHCURRENTSLOTDATA
    rts
GETCURRENTSLOTSYNTHPSG:
    cmp.b               #0x01, SYNTHEDITMODE ;testing
    beq                    @SYNTHINSTSLOT
    move.l             CURRENTSYNTHSLOTADDRESS, d2
    move.b              SYNTHINSTRUMENTNUMBER, d0  ;The Patch ID we're editing
    mulu.w                #0x12, d0            ;We're getting the offset for which PSG patch's data we're going to edit
    add.l                  d0, d2
    moveq               #0x0, d0

    jsr                     GETCURRENTSLOT
    move.b               (a0), d1
    move.b              d1, SYNTHCURRENTSLOTDATA
    rts

    @SYNTHINSTSLOT:
    move.b                  SYNTHINSTRUMENTNUMBER, d1
    move.l                   #SYNTHINSTRUMENTNUMBER, a0
    move.b                  d1, SYNTHCURRENTSLOTDATA
    rts
GETCURRENTSLOT:
; d2 is the starting address for the table we want to edit                      TODO Once tracker grows in size, I need to implement a caching
    moveq               #0x0, d0
    move.w             CURRENTTABLESLOT, d0                                                         ;system for the current slot of all tables on all screens.
    ror.w                   #0x08, d0                                                                                  ;NOTE, caching system already started!



    add.l                 d2, d0    ;Now we have our table slot, it's address and we're ready to edit it's data
    move.l               d0, a0   ; Stored in Address Register 0, remember this.

    rts


GETCURRENTSLOTNOTE:
; d2 is the starting address for the table we want to edit
    moveq               #0x0, d0
    moveq               #0x0, d1
    move.w             CURRENTTABLESLOTNOTE, d0
    move.w             d0, d1
    ror.w                   #0x08, d0
    ror.w                   #0x08, d1
    add.w                   d1, d0


    add.l                 d2, d0    ;Now we have our table slot, it's address and we're ready to edit it's data
    move.l               d0, a0   ; Stored in Address Register 0, remember this.

    rts


;=============Converting Array bytes to font compatible value=============
;In order to display data stored in our arrays to the screen, we must first convert this data
; into the tile ID.
;============

CONVERTBYTETOFONT:
; d2 contains the byte to be converted for use with font.

    cmp.b                   #0xEF, d2
    beq                       @BlankData

    movem.l                d3-d4, -(sp)
    moveq                   #0x0, d3
    moveq                   #0x0, d4
    rol.w                     #0x04, d2
    move.b                   d2, d4
    ror.b                       #0x04, d4
    ror.w                       #0x08, d2
    move.b                     d2, d3
; d3 now has the first value, d4 has the second. Now we just need to check if these are numbers or hex letters and add accordingly.
    cmp.b                      #0x09, d3
    ble                           NumberValue1
    cmp.b                       #0x0A, d3
    bge                          LetterValue1


    @BlankData:      ;This data is blank and should be shown as such in the GUI of the tracker.
    move.w                  #0x0D0D, d2
    rts

NumberValue1:
    add.b                     #0x10, d3
    bra.w                       CONVERTCONTINUE1
LetterValue1:
    add.b                     #0x17, d3
    bra.w                       CONVERTCONTINUE1

CONVERTCONTINUE1:
    exg                          d3, d4
    cmp.b                      #0x09, d3
    ble                           NumberValue2
    cmp.b                       #0x0A, d3
    bge                          LetterValue2

NumberValue2:
    add.b                     #0x10, d3
    bra.w                       CONVERTCONTINUE2
LetterValue2:
    add.b                     #0x17, d3
    bra.w                       CONVERTCONTINUE2

CONVERTCONTINUE2:
    exg                          d4, d3                 ;d3 and d4 now contains font compatible values  1 and 2.
    rol.w                        #0x08, d3
    moveq                      #0x0, d2
    move.b                     d4, d2
    add.w                       d3, d2
    movem.l                  (sp)+, d3-d4
    rts


;==========This is for displaying the full range 00-FF in digits===============

CONVERTBYTETOFONTFF:
; d2 contains the byte to be converted for use with font.



    movem.l                d3-d4, -(sp)
    moveq                   #0x0, d3
    moveq                   #0x0, d4
    rol.w                     #0x04, d2
    move.b                   d2, d4
    ror.b                       #0x04, d4
    ror.w                       #0x08, d2
    move.b                     d2, d3
; d3 now has the first value, d4 has the second. Now we just need to check if these are numbers or hex letters and add accordingly.
    cmp.b                      #0x09, d3
    ble                           NumberValue1FF
    cmp.b                       #0x0A, d3
    bge                          LetterValue1FF



NumberValue1FF:
    add.b                     #0x10, d3
    bra.w                       CONVERTCONTINUE1FF
LetterValue1FF:
    add.b                     #0x17, d3
    bra.w                       CONVERTCONTINUE1FF

CONVERTCONTINUE1FF:
    exg                          d3, d4
    cmp.b                      #0x09, d3
    ble                           NumberValue2FF
    cmp.b                       #0x0A, d3
    bge                          LetterValue2FF

NumberValue2FF:
    add.b                     #0x10, d3
    bra.w                       CONVERTCONTINUE2FF
LetterValue2FF:
    add.b                     #0x17, d3
    bra.w                       CONVERTCONTINUE2FF

CONVERTCONTINUE2FF:
    exg                          d4, d3                 ;d3 and d4 now contains font compatible values  1 and 2.
    rol.w                        #0x08, d3
    moveq                      #0x0, d2
    move.b                     d4, d2
    add.w                       d3, d2
    movem.l                  (sp)+, d3-d4
    rts

;=================Slot window init and reset========================================
;Simple function for initiation and resetting of slot windows.
;==============================================
DEFAULTSLOTWINDOW:
    move.b                  #0x05, TABLESLOTWINDOW  ;init slot windows for horizontal scroll checking
    move.b                   #0x00, TABLESLOTWINDOW2
    move.b                    #0x00, TABLESLOTPOSITION
    move.b                  #0x16, NOTESLOTWINDOW  ;init slot windows for horizontal scroll checking
    move.b                   #0x00, NOTESLOTWINDOW2
    move.b                    #0x00, NOTESLOTPOSITION
    move.b                  #0x00, NOTETABLEPOSITION
    rts


;===============Playback and prelisten stopping=================
;This code stops playback and prelisten sounds.
;=================================
STOPSOUND:
    jsr                              STOPPSG
    jsr                              STOPYM2612
    jsr                              STOPCOMMANDS
    rts

STOPYM2612:
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET
    @WAITFORPERMISSION:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION




    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0x00, YM2612FM1DATA
    jsr                         KILLTIME
    move.b                  #0x01, YM2612FM1DATA
    jsr                         KILLTIME
    move.b                  #0x02, YM2612FM1DATA
    jsr                         KILLTIME
    move.b                  #0x04, YM2612FM1DATA
    jsr                         KILLTIME
    move.b                  #0x05, YM2612FM1DATA
    jsr                         KILLTIME
    move.b                  #0x06, YM2612FM1DATA
    jsr                         KILLTIME
    rts

STOPPSG:
    move.b                      #0x9f, PSGCONTROLPORT ;silence psg channels 1-4
    move.b                      #0xbf,  PSGCONTROLPORT
    move.b                      #0xdf, PSGCONTROLPORT
    move.b                      #0xff, PSGCONTROLPORT


    move.b                      #0x80, PSGCONTROLPORT  ; reset notes for PSG channels 1-4
    move.b                      #0x00, PSGCONTROLPORT
    move.b                      #0xa0, PSGCONTROLPORT
    move.b                      #0x00, PSGCONTROLPORT
    move.b                      #0xc0, PSGCONTROLPORT
    move.b                      #0x00, PSGCONTROLPORT
    move.b                      #0xe0, PSGCONTROLPORT
    move.b                      #0x00, PSGCONTROLPORT

    move.b              #0x00, PSG0ADSRSTATE
    move.b              #0x00, PSG1ADSRSTATE
    move.b              #0x00, PSG2ADSRSTATE
    move.b              #0x00, PSG3ADSRSTATE
    rts


STOPCOMMANDS:
    move.b                  #0x00, CHANNEL1PORTAMENTOSTATE
    move.b                  #0x00, Channel1ArpeggioFlag
    move.b                  #0x00, Channel1ArpOctave
    move.b                  #0x00, Channel1ArpBase
    rts
ConvertVelocityToTotalLevel:
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PLAYBACKCURRENTVELOCITY, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PLAYBACKCURRENTVELOCITY
    rts
ConvertVelocityToTotalLevel2:
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PLAYBACKCURRENTVELOCITY2, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PLAYBACKCURRENTVELOCITY2
    rts
ConvertVelocityToTotalLevel3:
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PLAYBACKCURRENTVELOCITY3, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PLAYBACKCURRENTVELOCITY3
    rts
ConvertVelocityToTotalLevel4:
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PLAYBACKCURRENTVELOCITY4, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PLAYBACKCURRENTVELOCITY4
    rts
ConvertVelocityToTotalLevel5:
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PLAYBACKCURRENTVELOCITY5, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PLAYBACKCURRENTVELOCITY5
    rts
ConvertVelocityToTotalLevel6:
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PLAYBACKCURRENTVELOCITY6, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PLAYBACKCURRENTVELOCITY6
    rts



ConvertVelocityToTotalLevelPrelisten:
    movem.l                d0/d1, -(sp)
    moveq                   #0x0, d0
    moveq                   #0x0, d1
    move.b                  #0x7F, d1
    move.b                  PRELISTENCURRENTVELOCITY, d0
    sub.b                      d0, d1 ;Now Total Level
    move.b                  d1, PRELISTENCURRENTVELOCITY
    movem.l                (sp)+, d0/d1
    rts


;This function is for getting the YM octave number from an octave block and note range.
GetOctaveNumberfromBlock
    rol.w               #0x08, d2
    add.w             d2, d4 ; Add freq values together
    cmp.b            #0x10, d3
    beq                 @Specify1or2
    cmp.b              #0x38, d3
    beq                 @Specify7or8
    cmp.b           #0x08, d3
    beq                @Octave0
    cmp.b           #0x18, d3
    beq                 @Octave3
    cmp.b           #0x20, d3
    beq                 @Octave4
    cmp.b           #0x28, d3
    beq                 @Octave5
    cmp.b           #0x30, d3
    beq                 @Octave6


    ;Specify - We need clarification on which octave we're on, so we do that by comparing the note value with a note range
    @Specify1or2:
    cmp.w                  #0x025f, d4
    ble                      @Octave1
    cmp.w                  #0x0283, d4
    bge                      @Octave2
    rts

    @Specify7or8:
    cmp.w                  #0x0507, d4
    bge                      @Octave8
    cmp.w                  #0x0283, d4
    bge                      @Octave7
    rts

    ;Now we know which octave we're on. We need to pass the variable on to the external function.
    @Octave0:
    moveq              #0x0, d5
    rts
    @Octave1:
    move.b              #0x01, d5
    rts
    @Octave2:
    move.b              #0x02, d5
    rts
    @Octave3:
    move.b              #0x03, d5
    rts
    @Octave4:
    move.b              #0x04, d5
    rts
    @Octave5:
    move.b              #0x05, d5
    rts
    @Octave6:
    move.b              #0x06, d5
    rts
    @Octave7:
    move.b              #0x07, d5
    rts
    @Octave8:
    move.b              #0x08, d5
    rts





ConvertNoteToInteger:
;Sometimes we need to do math on our notes. This requires us to turn the notes into numbers that we can add/subtract whatever.
;This function expects the note to be converted to already be in register d0. Legend = Note, -/b/#, Octave, Blank
    ror.l                  #0x08, d0      ;Note is ready for compares.
    moveq             #0x0, d7      ;Clear Output Register
    cmp.b      #0x01, d0
    beq         @Ab
    cmp.b     #0x00, d0
    beq        @A
    cmp.b   #0x11, d0
    beq         @Bb
    cmp.b   #0x10, d0
    beq       @B
    cmp.b   #0x20, d0
    beq       @C
    cmp.b   #0x22, d0
    beq       @Csharp
    cmp.b  #0x30, d0
    beq        @D
    cmp.b     #0x41, d0
    beq          @Eb
    cmp.b     #0x40, d0
    beq           @E
    cmp.b     #0x50, d0
    beq          @F
    cmp.b      #0x52, d0
    beq            @Fsharp
    cmp.b       #0x60, d0
    beq             @G
    move.l      #0x19283746, d7
    stop #$2700 ;Invalid Note

    @Ab:
    moveq    #0x08, d7
    rts
    @A:
    moveq    #0x09, d7
    rts
    @Bb:
    moveq    #0x0a, d7
    rts
    @B:
    moveq     #0x0b, d7
    rts
    @C:
    moveq     #0x00, d7
    rts
    @Csharp:
    moveq     #0x01, d7
    rts
    @D:
    moveq     #0x02, d7
    rts
    @Eb:
    moveq     #0x03, d7
    rts
    @E:
    moveq     #0x04, d7
    rts
    @F:
    moveq     #0x05, d7
    rts
    @Fsharp:
    moveq     #0x06, d7
    rts
    @G:
    moveq     #0x07, d7
    rts

GetNoteFromInteger:
    moveq             #0x0, d4
    moveq             #0x0, d5
    move.l             #IntegerNoteTable, a6
    move.b              d2, d5
    add.b               d2, d5
    adda.l                  d5, a6
    move.w              (a6), d4 ;This should do it, the note is loaded into d3.
    rts
