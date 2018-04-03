
;===========Tracker Playback Engine============
;This is the playback engine for the tracker, and is likely where I'll
; be spending lots of time during this project.
;=================================

;Note: Many functions/variables will repeat in name. Channel 1 - TRACKERPLAYBACK:, Channel 5 - TRACKERPLAYBACK5:
;In order to make groove work with separate channels, this is an unfortunate necessity on my part.

TRACKERPLAYBACK:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK
    @Stopped:
    rts

PLAYBACK:

    cmp.b                    #0x01, CHANNEL1NOPLAY  ;Is Channel 1 flagged for no playback?
    beq                         @Ch1NoPlay  ; We do not play anything on Channel 1
    jsr                         READSONG        ;Read Song data to obtain Chain data
    jsr                         READCHAIN       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         FMCHANNEL1     ; This loads up all the FM1 parameters into YM2612

    jsr                         POSTFMMISC  ;Misc. things that need doing after processing FM, like Destination Note values for Portamento to Note
    @Ch1NoPlay:
    jsr                         PLAYBACKTIMINGCORE   ;This handles the timing for the whole thing.

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN:
    move.l                  PLAYBACKCURRENTCHAIN, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS
    move.b                  #0x00, PLAYBACKPHRASESWITCH
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS, a0
    move.w              (a0), PLAYBACKCURRENTNOTE
    adda.l                  #0x00002800, a0  ;get offset for current instrument FM patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY ; load current velocity into memory
    jsr                         ConvertVelocityToTotalLevel
    adda.l                    #0x000027FF, a0 ; offset for Commands
    move.w                  (a0), PLAYBACKCURRENTCOMMAND ; load current COMMAND into memory
    moveq                 #0x0, d1
    move.w                  (a0), d1  ;Before we process synth, we need to know if there's a command for portnote or whatever
    suba.l                  #0x00005000, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS
    moveq                 #0x0, d0
    ror.w                   #0x08, d1 ; move command type to lower byte
    cmp.b                   #0x01, d1 ;Arpeggio?
    beq                       @ResetArp
    cmp.b                   #0x04, d1 ; PortatoNote?
    beq                       @PortaToNote
    moveq                 #0x0, d1

    rts

    @ResetArp:
    move.b                  #0x00, Channel1ArpeggioFlag
    move.b                  #0x00, Channel1ArpOctave
    move.b                  #0x00, Channel1ArpBase
    moveq                 #0x0, d1
    rts

    @PortaToNote:
    move.b              Channel1OldPitchMSB, Channel1OldPortaNoteMSB
    move.b              Channel1OldPitchLSB,    Channel1OldPortaNoteLSB
    moveq               #0x0, d1
    moveq               #0x0, d2
    moveq               #0x0, d3
    moveq               #0x0, d4
    moveq               #0x0, d5
    move.b               Channel1OldPortaNoteMSB, d2
    move.b               Channel1OldPortaNoteLSB, d4
    move.b                d2, d3
    and.b                  #%00000111, d2  ; Freq
    and.b                  #%11111000, d3  ;Oct block
    jsr                        GetOctaveNumberfromBlock
    move.b              d5, CurrentYMOCTAVE


    rts


    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN
    move.l                   PLAYBACKCURRENTCHAIN, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW, a0
    cmp.l                       #0x00FF0076, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN
    move.b                      #0x08, PLAYBACKCHAINCOUNTER
    move.b                     #0x01, PLAYBACKCHAINSWITCH  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK
    rts
PLAYBACKTIMINGCORE:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts



POSTFMMISC:
    move.w              PLAYBACKCURRENTCOMMAND, d0
    ror.w                   #0x08, d0
    cmp.b                   #0x04, d0
    beq                       @PortaToNoteDestinationValue
    rts


    @PortaToNoteDestinationValue:
    moveq               #0x0, d1
    moveq               #0x0, d2
    moveq               #0x0, d3
    moveq               #0x0, d4
    moveq               #0x0, d5
    move.b               Channel1oldpitchMSB, d2
    move.b               Channel1oldpitchLSB, d4
    move.b                d2, d3
    and.b                  #%00000111, d2  ; Freq
    and.b                  #%11111000, d3  ;Oct block
    jsr                        GetOctaveNumberfromBlock
    move.b              d5, DestinationYMOCTAVE
    rts
;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0060, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL1NOPLAY  ;Flag channel 1 "no playback"
    rts

CONTINUESEEK:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0060, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN
    move.b                      #0x08, PLAYBACKCHAINCOUNTER
    move.b                     #0x01, PLAYBACKCHAINSWITCH  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN
    move.b                      #0x08, PLAYBACKCHAINCOUNTER
    move.b                     #0x01, PLAYBACKCHAINSWITCH  ;It's time to update chain data per song row
    rts































;===================CHANNEL 2/FM2 PLAYBACK FUNCTIONS=========================
;CHANNEL 2-CHANNEL 2-CHANNEL 2-CHANNEL 2-CHANNEL 2-CHANNEL 2-CHANNEL 2-CHANNEL 2-CHANNEL 2
;=========================================================================

TRACKERPLAYBACK2:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET2, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK2
    @Stopped:
    rts

PLAYBACK2:

    cmp.b                    #0x01, CHANNEL2NOPLAY  ;Is Channel 2 flagged for no playback?
    beq                         @Ch2NoPlay  ; We do not play anything on Channel 2
    jsr                         READSONG2        ;Read Song data to obtain Chain data
    jsr                         READCHAIN2       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE2     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         FMCHANNEL2     ; This loads up all the FM1 parameters into YM2612

    @Ch2NoPlay:
    jsr                         PLAYBACKTIMINGCORE2   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG2:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW2, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH2 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN2, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN2 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH2
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN2:
    move.l                  PLAYBACKCURRENTCHAIN2, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH2  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS2
    move.b                  #0x00, PLAYBACKPHRASESWITCH2
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE2:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS2, a0
    move.w              (a0), PLAYBACKCURRENTNOTE2
    adda.l                  #0x00002800, a0  ;get offset for current instrument FM patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT2 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY2 ; load current velocity into memory
    jsr                         ConvertVelocityToTotalLevel2
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER2 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER2 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS2
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER2 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH2
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER2 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN2, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN2
    move.l                   PLAYBACKCURRENTCHAIN2, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER2  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW2, a0
    cmp.l                       #0x00FF008D, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW2
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK2
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN2
    move.b                      #0x08, PLAYBACKCHAINCOUNTER2
    move.b                     #0x01, PLAYBACKCHAINSWITCH2  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK2
    rts
PLAYBACKTIMINGCORE2:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED2, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET2

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK2:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW2, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0077, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW2
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL2NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK2:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0077, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW2
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW2, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW2
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN2
    move.b                      #0x08, PLAYBACKCHAINCOUNTER2
    move.b                     #0x01, PLAYBACKCHAINSWITCH2  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN2
    move.b                      #0x08, PLAYBACKCHAINCOUNTER2
    move.b                     #0x01, PLAYBACKCHAINSWITCH2  ;It's time to update chain data per song row
    rts






























;===================CHANNEL 3/FM3 PLAYBACK FUNCTIONS=========================
;CHANNEL 3-CHANNEL 3-CHANNEL 3-CHANNEL 3-CHANNEL 3-CHANNEL 3-CHANNEL 3-CHANNEL 3-CHANNEL 3
;=========================================================================

TRACKERPLAYBACK3:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET3, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK3
    @Stopped:
    rts

PLAYBACK3:

    cmp.b                    #0x01, CHANNEL3NOPLAY  ;Is Channel 3 flagged for no playback?
    beq                         @Ch3NoPlay  ; We do not play anything on Channel 3
    jsr                         READSONG3        ;Read Song data to obtain Chain data
    jsr                         READCHAIN3       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE3     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         FMCHANNEL3     ; This loads up all the FM1 parameters into YM2612

    @Ch3NoPlay:
    jsr                         PLAYBACKTIMINGCORE3   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG3:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW3, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH3 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN3, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN3 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH3
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN3:
    move.l                  PLAYBACKCURRENTCHAIN3, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH3  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS3
    move.b                  #0x00, PLAYBACKPHRASESWITCH3
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE3:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS3, a0
    move.w              (a0), PLAYBACKCURRENTNOTE3
    adda.l                  #0x00002800, a0  ;get offset for current instrument FM patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT3 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY3 ; load current velocity into memory
    jsr                         ConvertVelocityToTotalLevel3
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER3 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER3 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS3
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER3 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH3
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER3 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN3, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN3
    move.l                   PLAYBACKCURRENTCHAIN3, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER3  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW3, a0
    cmp.l                       #0x00FF00a4, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW3
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK3
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN3
    move.b                      #0x08, PLAYBACKCHAINCOUNTER3
    move.b                     #0x01, PLAYBACKCHAINSWITCH3  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK3
    rts
PLAYBACKTIMINGCORE3:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED3, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET3

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK3:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW3, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF008e, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW3
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL3NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK3:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF008e, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW3
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW3, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW3
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN3
    move.b                      #0x08, PLAYBACKCHAINCOUNTER3
    move.b                     #0x01, PLAYBACKCHAINSWITCH3  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN3
    move.b                      #0x08, PLAYBACKCHAINCOUNTER3
    move.b                     #0x01, PLAYBACKCHAINSWITCH3  ;It's time to update chain data per song row
    rts


































;===================CHANNEL 4/FM4 PLAYBACK FUNCTIONS=========================
;CHANNEL 4-CHANNEL 4-CHANNEL 4-CHANNEL 4-CHANNEL 4-CHANNEL 4-CHANNEL 4-CHANNEL 4-CHANNEL 4
;=========================================================================

TRACKERPLAYBACK4:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET4, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK4
    @Stopped:
    rts

PLAYBACK4:

    cmp.b                    #0x01, CHANNEL4NOPLAY  ;Is Channel 4 flagged for no playback?
    beq                         @Ch4NoPlay  ; We do not play anything on Channel 4
    jsr                         READSONG4        ;Read Song data to obtain Chain data
    jsr                         READCHAIN4       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE4     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         FMCHANNEL4     ; This loads up all the FM1 parameters into YM2612

    @Ch4NoPlay:
    jsr                         PLAYBACKTIMINGCORE4   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG4:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW4, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH4 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN4, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN4 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH4
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN4:
    move.l                  PLAYBACKCURRENTCHAIN4, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH4  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS4
    move.b                  #0x00, PLAYBACKPHRASESWITCH4
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE4:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS4, a0
    move.w              (a0), PLAYBACKCURRENTNOTE4
    adda.l                  #0x00002800, a0  ;get offset for current instrument FM patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT4 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY4 ; load current velocity into memory
    jsr                         ConvertVelocityToTotalLevel4
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER4 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER4 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS4
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER4 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH4
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER4 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN4, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN4
    move.l                   PLAYBACKCURRENTCHAIN4, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER4  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW4, a0
    cmp.l                       #0x00FF00bb, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW4
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK4
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN4
    move.b                      #0x08, PLAYBACKCHAINCOUNTER4
    move.b                     #0x01, PLAYBACKCHAINSWITCH4  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK4
    rts
PLAYBACKTIMINGCORE4:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED4, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET4

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK4:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW4, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00a5, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW4
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL4NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK4:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00a5, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW4
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW4, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW4
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN4
    move.b                      #0x08, PLAYBACKCHAINCOUNTER4
    move.b                     #0x01, PLAYBACKCHAINSWITCH4  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN4
    move.b                      #0x08, PLAYBACKCHAINCOUNTER4
    move.b                     #0x01, PLAYBACKCHAINSWITCH4  ;It's time to update chain data per song row
    rts







































;===================CHANNEL 5/FM5 PLAYBACK FUNCTIONS=========================
;CHANNEL 5-CHANNEL 5-CHANNEL 5-CHANNEL 5-CHANNEL 5-CHANNEL 5-CHANNEL 5-CHANNEL 5-CHANNEL 5
;=========================================================================

TRACKERPLAYBACK5:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET5, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK5
    @Stopped:
    rts

PLAYBACK5:

    cmp.b                    #0x01, CHANNEL5NOPLAY  ;Is Channel 5 flagged for no playback?
    beq                         @Ch5NoPlay  ; We do not play anything on Channel 5
    jsr                         READSONG5        ;Read Song data to obtain Chain data
    jsr                         READCHAIN5       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE5     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         FMCHANNEL5     ; This loads up all the FM1 parameters into YM2612

    @Ch5NoPlay:
    jsr                         PLAYBACKTIMINGCORE5   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG5:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW5, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH5 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN5, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN5 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH5
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN5:
    move.l                  PLAYBACKCURRENTCHAIN5, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH5  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS5
    move.b                  #0x00, PLAYBACKPHRASESWITCH5
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE5:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS5, a0
    move.w              (a0), PLAYBACKCURRENTNOTE5
    adda.l                  #0x00002800, a0  ;get offset for current instrument FM patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT5 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY5 ; load current velocity into memory
    jsr                         ConvertVelocityToTotalLevel5
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER5 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER5 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS5
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER5 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH5
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER5 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN5, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN5
    move.l                   PLAYBACKCURRENTCHAIN5, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER5  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW5, a0
    cmp.l                       #0x00FF00d2, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW5
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK5
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN5
    move.b                      #0x08, PLAYBACKCHAINCOUNTER5
    move.b                     #0x01, PLAYBACKCHAINSWITCH5  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK5
    rts
PLAYBACKTIMINGCORE5:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED5, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET5

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK5:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW5, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00bc, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW5
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL5NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK5:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00bc, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW5
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW5, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW5
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN5
    move.b                      #0x08, PLAYBACKCHAINCOUNTER5
    move.b                     #0x01, PLAYBACKCHAINSWITCH5  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN5
    move.b                      #0x08, PLAYBACKCHAINCOUNTER5
    move.b                     #0x01, PLAYBACKCHAINSWITCH5  ;It's time to update chain data per song row
    rts



































;===================CHANNEL 6/FM6 PLAYBACK FUNCTIONS=========================
;CHANNEL 6-CHANNEL 6-CHANNEL 6-CHANNEL 6-CHANNEL 6-CHANNEL 6-CHANNEL 6-CHANNEL 6-CHANNEL 6
;=========================================================================

TRACKERPLAYBACK6:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET6, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK6
    @Stopped:
    rts

PLAYBACK6:

    cmp.b                    #0x01, CHANNEL6NOPLAY  ;Is Channel 6 flagged for no playback?
    beq                         @Ch6NoPlay  ; We do not play anything on Channel 6
    jsr                         READSONG6        ;Read Song data to obtain Chain data
    jsr                         READCHAIN6       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE6     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         FMCHANNEL6     ; This loads up all the FM1 parameters into YM2612

    @Ch6NoPlay:
    jsr                         PLAYBACKTIMINGCORE6   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG6:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW6, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH6 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN6, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN6 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH6
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN6:
    move.l                  PLAYBACKCURRENTCHAIN6, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH6  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS6
    move.b                  #0x00, PLAYBACKPHRASESWITCH6
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE6:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS6, a0
    move.w              (a0), PLAYBACKCURRENTNOTE6
    adda.l                  #0x00002800, a0  ;get offset for current instrument FM patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT6 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY6 ; load current velocity into memory
    jsr                         ConvertVelocityToTotalLevel6
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER6 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER6 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS6
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER6 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH6
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER6 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN6, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN6
    move.l                   PLAYBACKCURRENTCHAIN6, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER6  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW6, a0
    cmp.l                       #0x00FF00e9, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW6
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK6
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN6
    move.b                      #0x08, PLAYBACKCHAINCOUNTER6
    move.b                     #0x01, PLAYBACKCHAINSWITCH6  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK6
    rts
PLAYBACKTIMINGCORE6:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED6, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET6

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK6:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW6, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00d3, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW6
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL6NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK6:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00d3, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW6
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW6, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW6
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN6
    move.b                      #0x08, PLAYBACKCHAINCOUNTER6
    move.b                     #0x01, PLAYBACKCHAINSWITCH6  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN6
    move.b                      #0x08, PLAYBACKCHAINCOUNTER6
    move.b                     #0x01, PLAYBACKCHAINSWITCH6  ;It's time to update chain data per song row
    rts




































;===================PSG1 PLAYBACK FUNCTIONS=========================
;PSG1 PSG1 PSG1  PSG1  PSG1  PSG1  PSG1   PSG1 PSG1  PSG1  PSG1
;=========================================================================

TRACKERPLAYBACK7:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET7, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK7
    @Stopped:
    rts

PLAYBACK7:

    cmp.b                    #0x01, CHANNEL7NOPLAY  ;Is Channel 7 flagged for no playback?
    beq                         @Ch7NoPlay  ; We do not play anything on Channel 7
    jsr                         READSONG7        ;Read Song data to obtain Chain data
    jsr                         READCHAIN7       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE7     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         PSGCHANNEL1     ; This loads up all the PSG1 parameters into PSG

    @Ch7NoPlay:
    jsr                         PLAYBACKTIMINGCORE7   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG7:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW7, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH7 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN7, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN7 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH7
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN7:
    move.l                  PLAYBACKCURRENTCHAIN7, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH7  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS7
    move.b                  #0x00, PLAYBACKPHRASESWITCH7
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE7:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS7, a0
    move.w              (a0), PLAYBACKCURRENTNOTE7
    adda.l                  #0x00002800, a0  ;get offset for current instrument PSG patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT7 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY7 ; load current velocity into memory
    ;jsr                         ConvertVelocityToTotalLevel6
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER7 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER7 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS7
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER7 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH7
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER7 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN7, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN7
    move.l                   PLAYBACKCURRENTCHAIN7, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER7  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW7, a0
    cmp.l                       #0x00FF0100, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW7
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK7
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN7
    move.b                      #0x08, PLAYBACKCHAINCOUNTER7
    move.b                     #0x01, PLAYBACKCHAINSWITCH7  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK7
    rts
PLAYBACKTIMINGCORE7:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED7, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET7

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK7:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW7, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00ea, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW7
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL7NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK7:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF00ea, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW7
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW7, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW7
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN7
    move.b                      #0x08, PLAYBACKCHAINCOUNTER7
    move.b                     #0x01, PLAYBACKCHAINSWITCH7  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN7
    move.b                      #0x08, PLAYBACKCHAINCOUNTER7
    move.b                     #0x01, PLAYBACKCHAINSWITCH7  ;It's time to update chain data per song row
    rts
































;===================PSG2 PLAYBACK FUNCTIONS=========================
;PSG2 PSG2 PSG2  PSG2  PSG2  PSG2  PSG2   PSG2 PSG2  PSG2  PSG2
;=========================================================================

TRACKERPLAYBACK8:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET8, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK8
    @Stopped:
    rts

PLAYBACK8:

    cmp.b                    #0x01, CHANNEL8NOPLAY  ;Is Channel 7 flagged for no playback?
    beq                         @Ch8NoPlay  ; We do not play anything on Channel 7
    jsr                         READSONG8        ;Read Song data to obtain Chain data
    jsr                         READCHAIN8       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE8     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         PSGCHANNEL2     ; This loads up all the PSG1 parameters into PSG

    @Ch8NoPlay:
    jsr                         PLAYBACKTIMINGCORE8   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG8:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW8, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH8 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN8, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN8 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH8
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN8:
    move.l                  PLAYBACKCURRENTCHAIN8, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH8  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS8
    move.b                  #0x00, PLAYBACKPHRASESWITCH8
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE8:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS8, a0
    move.w              (a0), PLAYBACKCURRENTNOTE8
    adda.l                  #0x00002800, a0  ;get offset for current instrument PSG patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT8 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY8 ; load current velocity into memory
    ;jsr                         ConvertVelocityToTotalLevel6
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER8 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER8 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS8
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER8 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH8
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER8 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN8, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN8
    move.l                   PLAYBACKCURRENTCHAIN8, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER8  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW8, a0
    cmp.l                       #0x00FF0117, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW8
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK8
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN8
    move.b                      #0x08, PLAYBACKCHAINCOUNTER8
    move.b                     #0x01, PLAYBACKCHAINSWITCH8  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK8
    rts
PLAYBACKTIMINGCORE8:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED8, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET8

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK8:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW8, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0101, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW8
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL8NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK8:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0101, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW8
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW8, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW8
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN8
    move.b                      #0x08, PLAYBACKCHAINCOUNTER8
    move.b                     #0x01, PLAYBACKCHAINSWITCH8  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN8
    move.b                      #0x08, PLAYBACKCHAINCOUNTER8
    move.b                     #0x01, PLAYBACKCHAINSWITCH8  ;It's time to update chain data per song row
    rts





































;===================PSG3 PLAYBACK FUNCTIONS=========================
;PSG3 PSG3 PSG3  PSG3  PSG3  PSG3  PSG3   PSG3 PSG3  PSG3  PSG3
;=========================================================================

TRACKERPLAYBACK9:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGET9, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACK9
    @Stopped:
    rts

PLAYBACK9:

    cmp.b                    #0x01, CHANNEL9NOPLAY  ;Is Channel 7 flagged for no playback?
    beq                         @Ch9NoPlay  ; We do not play anything on Channel 7
    jsr                         READSONG9        ;Read Song data to obtain Chain data
    jsr                         READCHAIN9       ; Read Chain data to obtain Phrase
    jsr                         READPHRASE9     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         PSGCHANNEL3     ; This loads up all the PSG3 parameters into PSG

    @Ch9NoPlay:
    jsr                         PLAYBACKTIMINGCORE9   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONG9:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROW9, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCH9 ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAIN9, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAIN9 ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCH9
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAIN9:
    move.l                  PLAYBACKCURRENTCHAIN9, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCH9  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESS9
    move.b                  #0x00, PLAYBACKPHRASESWITCH9
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASE9:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESS9, a0
    move.w              (a0), PLAYBACKCURRENTNOTE9
    adda.l                  #0x00002800, a0  ;get offset for current instrument PSG patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENT9 ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITY9 ; load current velocity into memory
    ;jsr                         ConvertVelocityToTotalLevel6
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTER9 ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTER9 ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESS9
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTER9 ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCH9
    sub.b                   #0x01, PLAYBACKCHAINCOUNTER9 ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAIN9, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAIN9
    move.l                   PLAYBACKCURRENTCHAIN9, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTER9  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROW9, a0
    cmp.l                       #0x00FF012e, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW9
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEK9
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN9
    move.b                      #0x08, PLAYBACKCHAINCOUNTER9
    move.b                     #0x01, PLAYBACKCHAINSWITCH9  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEK9
    rts
PLAYBACKTIMINGCORE9:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEED9, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGET9

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEK9:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW9, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0118, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW9
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNEL9NOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEK9:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF0118, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROW9
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROW9, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROW9
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN9
    move.b                      #0x08, PLAYBACKCHAINCOUNTER9
    move.b                     #0x01, PLAYBACKCHAINSWITCH9  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAIN9
    move.b                      #0x08, PLAYBACKCHAINCOUNTER9
    move.b                     #0x01, PLAYBACKCHAINSWITCH9  ;It's time to update chain data per song row
    rts


































;===================PSG4 PLAYBACK FUNCTIONS=========================
;PSG4 PSG4 PSG4  PSG4  PSG4  PSG4  PSG4   PSG4 PSG4  PSG4  PSG4
;=========================================================================

TRACKERPLAYBACKa:

    ;============================================
    ;Check to see if the desired number of frames has elapsed yet.
    ;==============================================
    cmp.b                      #0x01, PLAYBACKMODE
    bne                          @Stopped
    move.l                     FRAMETARGETa, d0  ;The Frame target is the desired vblank counter value to continue processing music data
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        PLAYBACKa
    @Stopped:
    rts

PLAYBACKa:

    cmp.b                    #0x01, CHANNELaNOPLAY  ;Is Channel 7 flagged for no playback?
    beq                         @ChaNoPlay  ; We do not play anything on Channel 7
    jsr                         READSONGa        ;Read Song data to obtain Chain data
    jsr                         READCHAINa       ; Read Chain data to obtain Phrase
    jsr                         READPHRASEa     ;We need to read the note/instrument number/vel/instrument parameters/ tracker commands for current row

    jsr                         PSGNOISECHANNEL     ; This loads up all the PSG4 parameters into PSG

    @ChaNoPlay:
    jsr                         PLAYBACKTIMINGCOREa   ;This handles the timing for the whole thing.


    moveq                  #0x0, d0
    moveq                   #0x0, d1
    move.l                  #0x00000000, a0
    rts



READSONGa:
    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTSONGROWa, a0 ;Load song row

    cmp.b                   #0x0, PLAYBACKCHAINSWITCHa ;Is it time to update the chain per song row update?
    beq                         @No                                  ;HELL NO IT ISN'T, we skip updating.
    move.b                  (a0), d0 ; Song row byte value obtained... this is for our Chain.
    rol.w                       #0x04, d0  ; After this, we need add this value to Chain Table starting address to get offset, for our chain.
    move.l                     PLAYBACKCURRENTCHAINa, d1
    add.l                       d0, d1 ; Should point to correct Chain address *cough*
    move.l                       d1, PLAYBACKCURRENTCHAINa ; ready for use
    move.b                  #0x00, PLAYBACKCHAINSWITCHa
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;    @SeekSongValue:
    ;Seek up the song rows for value, if none is found by the top address, we simply go to the bottom song row and constantly seek up
    ; This will be implemented until a more reasonable solution is found.
  ;  rts

READCHAINa:
    move.l                  PLAYBACKCURRENTCHAINa, a0
    moveq                   #0x0, d0
    move.b                  (a0), d0
    cmp.b                    #0x00, PLAYBACKPHRASESWITCHa  ;Is it time to update the note address? 1 for yes.
    beq                         @No
    move.l                   #PHRASETABLERAM, d1
    mulu.w                  #0x0040, d0   ;for offset
    add.l                      d0, d1
    move.l                   d1, PLAYBACKNOTEADDRESSa
    move.b                  #0x00, PLAYBACKPHRASESWITCHa
    @No:
    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Read Phrase table==============
;This code reads the phrase table row by row for
; tracker playback.
;============
READPHRASEa:
;When we read phrase, we read row by row and upload the data to appropriate functions.
;For FM, note data is processed by the YM2612 handler, Instrument number as well, velocity and commands will be handled by the COMMAND handler.
    move.l                     PLAYBACKNOTEADDRESSa, a0
    move.w              (a0), PLAYBACKCURRENTNOTEa
    adda.l                  #0x00002800, a0  ;get offset for current instrument PSG patch to be used
    move.b                 (a0), PLAYBACKCURRENTINSTRUMENTa ;load current instrument number into memory
    adda.l                    #0x00000001, a0 ; offset for Velocity
    move.b                  (a0), PLAYBACKCURRENTVELOCITYa ; load current velocity into memory
    ;jsr                         ConvertVelocityToTotalLevel6
    suba.l                  #0x00002801, a0; return to where we were before.
    sub.b                   #0x01, PLAYBACKPHRASECOUNTERa ;This row has been handled, time for the next one.
    cmp.b                   #0x00, PLAYBACKPHRASECOUNTERa ;Have all rows been handled in this Phrase?
    beq                      @CounterResetSwitchOn
    adda.l                 #0x00000002, a0 ;Increase offset for next note for when the next row is read.
    move.l                a0, d0
    move.l                d0, PLAYBACKNOTEADDRESSa
    moveq                 #0x0, d0
    moveq                 #0x0, d1
    rts

    @CounterResetSwitchOn:
    move.b                #0x20, PLAYBACKPHRASECOUNTERa ;Reset row counters and set Phrase update switch
    move.b                 #0x01, PLAYBACKPHRASESWITCHa
    sub.b                   #0x01, PLAYBACKCHAINCOUNTERa ;Completing a phrase also means completing a row in Chain

    moveq                   #0x0, d0
    move.l                  PLAYBACKCURRENTCHAINa, d0  ; We update our chain offset here to next chain row since a phrase is complete
    add.l                      #0x00000001, d0
    move.l                  d0, PLAYBACKCURRENTCHAINa
    move.l                   PLAYBACKCURRENTCHAINa, a0

    move.b                 (a0), d0
    cmp.b                     #0x00, PLAYBACKCHAINCOUNTERa  ;Has the entire Chain elapsed?
    beq                         @UpdateSongChainData  ;Time to update new Song row and Chain data.
    cmp.b                    #0xEF, d0 ;We check if the new Chain row is blank, if it is we need to update Song Chain Data
    beq                        @UpdateSongChainData
    rts

    @UpdateSongChainData:
    move.l                      PLAYBACKCURRENTSONGROWa, a0
    cmp.l                       #0x00FF0145, a0
    beq                           @ContinueSeek
    adda.l                      #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROWa
    move.b                       (a0), d0
    cmp.b                        #0xEF, d0
    beq                             CONTINUESEEKa
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAINa
    move.b                      #0x08, PLAYBACKCHAINCOUNTERa
    move.b                     #0x01, PLAYBACKCHAINSWITCHa  ;It's time to update chain data per song row
    rts

    @ContinueSeek:
    jsr                         CONTINUESEEKa
    rts
PLAYBACKTIMINGCOREa:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    move.l                       FRAMESPEEDa, d1
    add.l                          d1, d0
    move.l                      d0, FRAMETARGETa

    moveq                  #0x0, d0
    moveq                   #0x0, d1
    rts

;==========Seeking functions===============================================
;These functions seek for the starting/continuing points for playback when pressing start and during playback
;==================================================================================

STARTSEEKa:
    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROWa, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    beq                      @StartSeeking
    rts
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF012f, d1  ;The top boundary for seek, if we've encountered this, that means "No Play" for this channel.
    beq                      @NoPlay
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROWa
    bra.w                   @Repeat

    @NoPlay:
    move.b             #0x01, CHANNELaNOPLAY  ;Flag channel 2 "no playback"
    rts

CONTINUESEEKa:
    @StartSeeking:
    move.l                 a0, d1 ; we need the address for compares anyways.
    cmp.l                   #0x00FF012f, d1  ;The top boundary for seek, if we've encountered this, that means we've found our loop start.
    beq                      @LoopStart
    subq.b                   #0x01, d1
    move.l                  d1, a0  ;Update the address.
    move.l                  a0, PLAYBACKCURRENTSONGROWa
    bra.w                   @Repeat

    @Repeat:
    move.l                   PLAYBACKCURRENTSONGROWa, a0
    move.b                 (a0), d0
    cmp.b                   #0xEF, d0    ;Is it blank? If so we seek.
    bne                      @StartSeeking
    add.l                       #0x00000001, a0
    move.l                      a0, PLAYBACKCURRENTSONGROWa
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAINa
    move.b                      #0x08, PLAYBACKCHAINCOUNTERa
    move.b                     #0x01, PLAYBACKCHAINSWITCHa  ;It's time to update chain data per song row
    rts
    @LoopStart:
    move.l                      #CHAINTABLERAM, PLAYBACKCURRENTCHAINa
    move.b                      #0x08, PLAYBACKCHAINCOUNTERa
    move.b                     #0x01, PLAYBACKCHAINSWITCHa  ;It's time to update chain data per song row
    rts

