;=====Prelisten code======================
;This code checks to see if we're on the note screen
;If so, we play a note based on the data of the current
;note table slot.
;===========
PRELISTENMETA:
    move.b                      CURRENTSCREEN, d0
    cmp.b                         #PHRASESCREEN, d0
    bne                             @Nope
    cmp.b                          #0x00, NOTATIONEDITMODE
    bne                             @Nope
    jsr                               PRELISTEN

    @Nope:
    rts

;==================================
;We need to get the current table slot, and convert
; it's data to something the PSG understands.
; PS... this is fucking exciting!
;======================
PRELISTEN:
;Code checks for which current channel we're on
    move.l                     #PRELISTENTOGGLE, a1
    move.b                      (a1), d1
    cmp.b                      #0x00, d1
    beq                            @SKIP
    move.b                          #0x00, (a1)
    jsr                          getcurrentslotphrase
    move.b                  CHANNELNUMBER, d5
    cmp.b                      #0x00, d5
    beq                         FMCHANNEL1
    cmp.b                      #0x01, d5
    beq                         FMCHANNEL2
    cmp.b                      #0x02, d5
    beq                         FMCHANNEL3
    cmp.b                      #0x03, d5
    beq                         FMCHANNEL4
    cmp.b                      #0x04, d5
    beq                         FMCHANNEL5
    cmp.b                      #0x05, d5
    beq                         FMCHANNEL6
    cmp.b                     #0x06, d5
    beq                         PSGCHANNEL1
    cmp.b                       #0x07, d5
    beq                         PSGCHANNEL2
    cmp.b                      #0x08, d5
    beq                         PSGCHANNEL3


    cmp.b                      #0x09, d5
    beq                         PSGNOISECHANNEL


    @SKIP:                     ;We're already doing prelisten or playback engine is running

    rts

SKIPPSG:
    jsr                     STOPPSG
    rts
;Middle C is C4. 440hz is A above C4, so this would be A5
;0xFE is the data for pitch, but it's structuring in the PSG is weird
;so I'll need to figure out how to translate my notation data to PSG register data.
;try to do it without hundreds of compares and branches please.
; A5 in my data type is 0xX0,05  :Uppercase X means ''doesn't matter"
PSGNOISECHANNEL:
    movem.l                     d0-d7/a0-a6, -(sp)
    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE
    beq                             @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @PSGNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0xc0, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                       #0xe7, PSGCONTROLPORT
    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG3ADSRKeyOn
    jsr                             PSG3ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6

    rts

    @GetPlaybackData:
    moveq                       #0x0, d0
    move.w                     PLAYBACKCURRENTNOTEa, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @PSGNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0xc0, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                       #0xe7, PSGCONTROLPORT
    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG3ADSRKeyOn
    jsr                             PSG3ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6
    rts

    @PSGNoteOFF:
    move.b                  #0x00, PSG3ADSRSTATE ;Turn off ADSR
    move.b                  #0xFF, PSGCONTROLPORT ; Turn off PSG channel

    @SkipProcessing:
    movem.l                    (sp)+, d0-d7/a0-a6

    rts

PSGCHANNEL1:
    movem.l                     d0-d7/a0-a6, -(sp)
    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE
    beq                             @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0x80, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG0ADSRKeyOn
    jsr                             PSG0ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6

    rts

    @GetPlaybackData:
    moveq                       #0x0, d0
    move.w                     PLAYBACKCURRENTNOTE7, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @PSGNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0x80, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG0ADSRKeyOn
    jsr                             PSG0ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6
    rts

    @PSGNoteOFF:
    move.b                  #0x00, PSG0ADSRSTATE ;Turn off ADSR
    move.b                  #0x9F, PSGCONTROLPORT ; Turn off PSG channel

    @SkipProcessing:
    movem.l                    (sp)+, d0-d7/a0-a6

    rts




PSGCHANNEL2:
    movem.l                     d0-d7/a0-a6, -(sp)
    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE
    beq                             @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0xa0, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG1ADSRKeyOn
    jsr                             PSG1ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6

    rts

    @GetPlaybackData:
    moveq                       #0x0, d0
    move.w                     PLAYBACKCURRENTNOTE8, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @PSGNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0xa0, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG1ADSRKeyOn
    jsr                             PSG1ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6
    rts

    @PSGNoteOFF:
    move.b                  #0x00, PSG1ADSRSTATE ;Turn off ADSR
    move.b                  #0xbF, PSGCONTROLPORT ; Turn off PSG channel

    @SkipProcessing:
    movem.l                    (sp)+, d0-d7/a0-a6

    rts

PSGCHANNEL3:
    movem.l                     d0-d7/a0-a6, -(sp)
    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE
    beq                             @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0xc0, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG2ADSRKeyOn
    jsr                             PSG2ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6

    rts

    @GetPlaybackData:
    moveq                       #0x0, d0
    move.w                     PLAYBACKCURRENTNOTE9, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @PSGNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOPSGNOTE

    add.b                       #0xc0, d3                             ;latch bit for d3 Channel 1
    move.b                    d3, d0
    ror.w                          #0x08, d3
    move.b                      d3, d1

    move.b                      d0, PSGCONTROLPORT ; Latch on,Channel 0, tone, data
    move.b                     d1, PSGCONTROLPORT  ; Latch off, channel 0, tone, data
    jsr                             PSG2ADSRKeyOn
    jsr                             PSG2ADSRCalculations
    movem.l                    (sp)+, d0-d7/a0-a6
    rts

    @PSGNoteOFF:
    move.b                  #0x00, PSG2ADSRSTATE ;Turn off ADSR
    move.b                  #0xdF, PSGCONTROLPORT ; Turn off PSG channel

    @SkipProcessing:
    movem.l                    (sp)+, d0-d7/a0-a6

    rts
;======Converting tracker note data to PSG sound chip data==========
;this code converts notation data as used by the tracker into something
;readable by the PSG.
;===============
CONVERTTOPSGNOTE:
; d0 is zero,note,#/b/null,octave
;First we must use the octave number to find which octave on our lookup table to read from.

    rol.w                       #0x04, d0      ;data is now Note, b/#/n, Octave, Zero
    cmp.b                       #0x00,d0


    beq                         READOCTAVE2
    cmp.b                     #0x30, d0
    beq                         READOCTAVE3
    cmp.b                       #0x40, d0
    beq                         READOCTAVE4
    cmp.b                      #0x50, d0
    beq                         READOCTAVE5
    cmp.b                      #0x60, d0
    beq                         READOCTAVE6
    cmp.b                      #0x70, d0
    beq                         READOCTAVE7
    cmp.b                     #0x80, d0
    beq                         READOCTAVE8
    cmp.b                      #0x20, d0
    beq                           SKIPPSG
    cmp.b                       #0x10, d0
    beq                          SKIPPSG
    rts

READOCTAVE0:
    move.l                    #OCTAVE0, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts

READOCTAVE1:
    move.l                    #OCTAVE1, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts

READOCTAVE2:
    move.l                    #OCTAVE2, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
READOCTAVE3:
    move.l                    #OCTAVE3, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
READOCTAVE4:
    move.l                    #OCTAVE4, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
READOCTAVE5:
    move.l                    #OCTAVE5, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
READOCTAVE6:
    move.l                    #OCTAVE6, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
READOCTAVE7:
    move.l                    #OCTAVE7, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
READOCTAVE8:
    move.l                    #OCTAVE8, a6 ;Note lookup table
    jsr                           PSGNOTECONVERSION
    rts
PSGNOTECONVERSION:
    ror.w                      #0x04, d0         ; data is now Zero, Note, b/#/n, Octave
    ror.w                      #0x08, d0        ; data is now b/#/n, Octave, Zero, Note,
    move.b                  d0, d1  ;d1 contains the note
    moveq                   #0x0, d2 ; clear d2
    move.b                   d1, d2 ;d2 contains same value as d1, for addition to itself for getting the correct offset for this note quickly.

    add.b                    d1, d2 ; d2 add 3x to itself to get offset for our note
    add.b                    d1, d2
    add.b                    d1, d2
    add.b                       #0x04, d2
    adda.l                      d2, a6 ; should get us pointed to our note.

    moveq                       #0x0, d2 ; d2 is now cleared
    rol.l                            #0x04, d0   ;sharp and flat should now be in the lower byte of the upper half of this register.
    swap                          d0   ;#/b/null is now ready to be used as it's own byte and is isolated.
    moveq                       #0x0, d4
    move.b                         d0, d4


    cmp.b                       #0x01, d4; Flat?
    beq                           PSGFLAT
    cmp.b                       #0x02, d4; Sharp?
    beq                       PSGSHARP
PSGNOTEDERIVATIVE:
    move.w                     (a6), d3 ; we now loaded our note into d3
    moveq                       #0x0, d0 ;Cleanup
    moveq                       #0x0, d1
    moveq                       #0x0, d2
;At this point, d3 SHOULD contain our note data #0x0123 (for example), for now, we need to squeeze 8 in between the 2 and 3 for the latch
;then feed the lower byte, then the upper byte to psg.
    rol.w                       #0x04, d3
    ror.b                        #0x04, d3


;Now to feed to psg.
    rts

PSGFLAT:

    suba.l                         #0x00000002, a6
    bra.w                          PSGNOTEDERIVATIVE
PSGSHARP:
    adda.l                         #0x00000002, a6
    bra.w                           PSGNOTEDERIVATIVE

FIXABPSG:               ;Since my data format has to be so complicated we need to offset the address for notes A and B
                                ;and their derivatives
    add.b                       #0x04, d2
    rts

