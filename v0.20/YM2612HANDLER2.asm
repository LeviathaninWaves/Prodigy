FMCHANNEL4:

    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE  ;Check Playback State to avoid conflicts with Note Entry and Notation Handler
    beq                           @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    bra.w                         @GetPrelistenData
    @GetPlaybackData:
    move.w                     PLAYBACKCURRENTNOTE4, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @FMNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOYMNOTE
    move.l                             #SYNTHTABLERAM, a1  ;This loads the synthesizer parameters into a1 to prepare for writes.
    moveq                           #0x0, d2
    move.b                          PLAYBACKCURRENTINSTRUMENT4, d2
    mulu.w                          #0x0040, d2
    adda.l                               d2, a1
    adda.l                           #0x00000001, a1  ; This skips the Operator # parameter, we will implement this later :TODO
    bra.w                           @ProcessFM
    @GetPrelistenData:
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @FMNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOYMNOTE
    move.l                             #SYNTHTABLERAM, a1  ;This loads the synthesizer parameters into a1 to prepare for writes.
    moveq                           #0x0, d2
    move.b                          NOTEINSTRUMENTNUMBERCACHE, d2
    mulu.w                          #0x0040, d2
    adda.l                               d2, a1
    adda.l                           #0x00000001, a1  ; This skips the Operator # parameter, we will implement this later :TODO
    jsr                                 ConvertVelocityToTotalLevelPrelisten
    @ProcessFM:
    ;First we need permission from the Zilog-80 CPU, request BUS access.

    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION


    move.b                    #LFO, YM2612FM1CONTROL

    move.b                          (a1)+, d4  ; ========combine LFO+LFOFREQ
    move.b                          (a1)+, d5

    rol.b                               #0x03, d4
    add.b                               d4, d5
    move.b                            d5, YM2612FM1DATA   ;Turn LFO off
    jsr                                 KILLTIME
    move.b                      #CH14FBAL, YM2612FM2CONTROL

    move.b                      (a1)+, d4  ; ==========Combine Feedback+Algorithm
    move.b                      (a1)+, d5
    move.b                      d5, FMALGORITHM ;Save the algorithm value, we're going to need it to apply Velocity to the correct Operators.
    rol.b                               #0x03, d4
    add.b                         d4, d5
    move.b                      d5, YM2612FM2DATA



    move.b                      #Op1D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op2D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op3D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op4D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op1TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME


    move.b                     #CH14STLFOS, YM2612FM2CONTROL

    move.b                      (a1)+, d4 ;AMS
    move.b                      (a1)+, d5 ; FMS
    move.b                       (a1)+, d6 ;Stereo
    rol.b                           #0x04, d4
    ror.b                           #0x02, d6
    add.b                          d4, d5
    add.b                          d5, d6
    move.b                    d6, YM2612FM2DATA
    jsr                         KILLTIME
    move.b                     #TIMERSCH36MODE, YM2612FM1CONTROL
    jsr                                 KILLTIME
    move.b                      #0x00, YM2612FM1DATA  ; Turn off Channel 3 special mode.
    jsr                                 KILLTIME
    move.b                       #KEYONOFF, YM2612FM1CONTROL
    jsr                                 KILLTIME
   ; move.b                         #0x00, YM2612FM1DATA   ; Turn all channels off
  ;  jsr                                 KILLTIME
   ; move.b                        #0x01, YM2612FM1DATA
   ; jsr                                 KILLTIME
  ;  move.b                        #0x02, YM2612FM1DATA
 ;   jsr                                 KILLTIME
    move.b                       #0x04, YM2612FM1DATA
    jsr                                 KILLTIME
   ; move.b                       #0x04, YM2612FM1DATA
  ;  jsr                                 KILLTIME
   ; move.b                       #0x05, YM2612FM1DATA
   ; jsr                                 KILLTIME
 ;   move.b                        #0x06, YM2612FM1DATA
 ;   jsr                                 KILLTIME
    move.b                        #DAC2, YM2612FM1CONTROL
    jsr                                 KILLTIME
    move.b                         #0x00, YM2612FM1DATA     ;Turn off DAC
    jsr                                 KILLTIME


    move.b                        #Op1DM14, YM2612FM2CONTROL

    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                       d5, YM2612FM2DATA
    jsr                                KILLTIME
    move.b                        #Op2DM14, YM2612FM2CONTROL
    jsr                               KILLTIME
    adda.l                           #0x00000009, a1  ;offset address for Operator 2 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3DM14, YM2612FM2CONTROL

    adda.l                            #0x00000009, a1  ;offset address for Operator 3 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4DM14, YM2612FM2CONTROL

    adda.l                            #0x00000009, a1  ;offset address for Operator 2 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    nop
    nop
    suba.l                            #0x00000021, a1         ;Get back on track to where we were!! :D


    cmp.b                           #0x00, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x01, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x02, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x03, FMALGORITHM                ; This is important. We need to do compares and branches
    ble                                @FMALGO0123                                 ; to make sure that we feed each operator the correct
    cmp.b                           #0x04, FMALGORITHM                ; volume/velocity values to control the TL of the instrument.
    beq                                @FMALGO4
    cmp.b                           #0x05, FMALGORITHM
    beq                                 @FMALGO56
    cmp.b                           #0x06, FMALGORITHM
    beq                                 @FMALGO56
    cmp.b                           #0x07, FMALGORITHM
    beq                                 @FMALGO7
    bra.w                           @DoneTotalLevel

    @FMALGO0123:
    move.b                        #Op1TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity0
    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    ;jsr                                 KILLTIME
    bra.w                               @NextValue0
    @PrelistenModeVelocity0:

    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    ;jsr                                 KILLTIME
    @NextValue0:
    bra.w                           @DoneTotalLevel

    @FMALGO4:
    move.b                        #Op1TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity1
    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue1
    @PrelistenModeVelocity1:
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue1:
    bra.w                           @DoneTotalLevel

    @FMALGO56:
    move.b                        #Op1TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity2
    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue2
    @PrelistenModeVelocity2:
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue2:
    bra.w                           @DoneTotalLevel

    @FMALGO7:
    move.b                        #Op1TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity3
    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY4, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue3
    @PrelistenModeVelocity3:
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue3:
    bra.w                           @DoneTotalLevel



    @DoneTotalLevel:

    move.b                          #Op1RsaR14, YM2612FM2CONTROL

    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME

    move.b                          #Op2RsaR14, YM2612FM2CONTROL

    adda.l                               #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                               #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op3RsaR14, YM2612FM2CONTROL

    adda.l                              #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op4RsaR14, YM2612FM2CONTROL

    adda.l                               #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    suba.l                               #0x00000025, a1 ; Return to where we were

    move.b                          #Op11DRAM14, YM2612FM2CONTROL

    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                           #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op21DRAM14, YM2612FM2CONTROL

    adda.l                               #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                           #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op31DRAM14, YM2612FM2CONTROL

    adda.l                               #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                            #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op41DRAM14, YM2612FM2CONTROL

    adda.l                              #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                          #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                             KILLTIME
    suba.l                          #0x00000026, a1  ; Return to where we were
    move.b                          #Op12DR14, YM2612FM2CONTROL

    nop
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op22DR14, YM2612FM2CONTROL

    adda.l                           #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op32DR14, YM2612FM2CONTROL

    adda.l                         #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op42DR14, YM2612FM2CONTROL

    adda.l                        #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                           KILLTIME
    suba.l                           #0x00000020, a1 ; Return to where we were

    move.b                      #Op1D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op2D1LRR14,YM2612FM2CONTROL

    adda.l                            #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op3D1LRR14,YM2612FM2CONTROL

    adda.l                            #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op4D1LRR14,YM2612FM2CONTROL

    adda.l                           #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    suba.l                           #0x0000001F, a1 ; Return to where we were

    move.b                     #Op1SSGEG14, YM2612FM2CONTROL

    move.b                      (a1), d4 ;SSGEG
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op2SSGEG14, YM2612FM2CONTROL

    move.b                      (a1), d4 ;SSGEG
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op3SSGEG14, YM2612FM2CONTROL

    move.b                      (a1), d4
    adda.l                     #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op4SSGEG14, YM2612FM2CONTROL

    move.b                      (a1), d4
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME



    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0x04, YM2612FM1DATA
    jsr                         KILLTIME

    move.b                    #CH14FREQMSB, YM2612FM2CONTROL
    jsr                           KILLTIME
    move.b                  d3, YM2612FM2DATA
    jsr                         KILLTIME
    move.b                    #CH14FREQLSB, YM2612FM2CONTROL
    jsr                           KILLTIME
    move.b                  d1, YM2612FM2DATA
    jsr                         KILLTIME

    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0xf4, YM2612FM1DATA
    jsr                         KILLTIME


    @SkipProcessing:

    rts

    @FMNOTEOFF:
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION2:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION2





    move.b                      #Op1D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op2D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op3D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op4D1LRR14,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op1TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op2TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op3TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4TL14, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA

    rts























FMCHANNEL5:

    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE  ;Check Playback State to avoid conflicts with Note Entry and Notation Handler
    beq                           @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    bra.w                         @GetPrelistenData
    @GetPlaybackData:
    move.w                     PLAYBACKCURRENTNOTE5, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @FMNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOYMNOTE
    move.l                             #SYNTHTABLERAM, a1  ;This loads the synthesizer parameters into a1 to prepare for writes.
    moveq                           #0x0, d2
    move.b                          PLAYBACKCURRENTINSTRUMENT5, d2
    mulu.w                          #0x0040, d2
    adda.l                               d2, a1
    adda.l                           #0x00000001, a1  ; This skips the Operator # parameter, we will implement this later :TODO
    bra.w                           @ProcessFM
    @GetPrelistenData:
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @FMNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOYMNOTE
    move.l                             #SYNTHTABLERAM, a1  ;This loads the synthesizer parameters into a1 to prepare for writes.
    moveq                           #0x0, d2
    move.b                          NOTEINSTRUMENTNUMBERCACHE, d2
    mulu.w                          #0x0040, d2
    adda.l                               d2, a1
    adda.l                           #0x00000001, a1  ; This skips the Operator # parameter, we will implement this later :TODO
    jsr                                 ConvertVelocityToTotalLevelPrelisten
    @ProcessFM:
    ;First we need permission from the Zilog-80 CPU for us to request BUS access.

    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION


    move.b                    #LFO, YM2612FM1CONTROL

    move.b                          (a1)+, d4  ; ========combine LFO+LFOFREQ
    move.b                          (a1)+, d5

    rol.b                               #0x03, d4
    add.b                               d4, d5
    move.b                            d5, YM2612FM1DATA   ;Turn LFO off
    jsr                                 KILLTIME
    move.b                      #CH25FBAL, YM2612FM2CONTROL

    move.b                      (a1)+, d4  ; ==========Combine Feedback+Algorithm
    move.b                      (a1)+, d5
    move.b                      d5, FMALGORITHM ;Save the algorithm value, we're going to need it to apply Velocity to the correct Operators.
    rol.b                               #0x03, d4
    add.b                         d4, d5
    move.b                      d5, YM2612FM2DATA



    move.b                      #Op1D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op2D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op3D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op4D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op1TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME


    move.b                     #CH25STLFOS, YM2612FM2CONTROL

    move.b                      (a1)+, d4 ;AMS
    move.b                      (a1)+, d5 ; FMS
    move.b                       (a1)+, d6 ;Stereo
    rol.b                           #0x04, d4
    ror.b                           #0x02, d6
    add.b                          d4, d5
    add.b                          d5, d6
    move.b                    d6, YM2612FM2DATA
    jsr                         KILLTIME
    move.b                     #TIMERSCH36MODE, YM2612FM1CONTROL
    jsr                                 KILLTIME
    move.b                      #0x00, YM2612FM1DATA  ; Turn off Channel 3 special mode.
    jsr                                 KILLTIME
    move.b                       #KEYONOFF, YM2612FM1CONTROL
    jsr                                 KILLTIME
   ; move.b                         #0x00, YM2612FM1DATA   ; Turn all channels off
    ;jsr                                 KILLTIME
  ;  move.b                        #0x01, YM2612FM1DATA
  ;  jsr                                 KILLTIME
   ; move.b                        #0x02, YM2612FM1DATA
 ;   jsr                                 KILLTIME
 ;   move.b                       #0x03, YM2612FM1DATA
 ;   jsr                                 KILLTIME
    move.b                       #0x05, YM2612FM1DATA
    jsr                                 KILLTIME
  ;  move.b                       #0x05, YM2612FM1DATA
 ;   jsr                                 KILLTIME
 ;   move.b                        #0x06, YM2612FM1DATA
 ;   jsr                                 KILLTIME
    move.b                        #DAC2, YM2612FM1CONTROL
    jsr                                 KILLTIME
    move.b                         #0x00, YM2612FM1DATA     ;Turn off DAC
    jsr                                 KILLTIME


    move.b                        #Op1DM25, YM2612FM2CONTROL

    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                       d5, YM2612FM2DATA
    jsr                                KILLTIME
    move.b                        #Op2DM25, YM2612FM2CONTROL
    jsr                               KILLTIME
    adda.l                           #0x00000009, a1  ;offset address for Operator 2 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3DM25, YM2612FM2CONTROL

    adda.l                            #0x00000009, a1  ;offset address for Operator 3 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4DM25, YM2612FM2CONTROL

    adda.l                            #0x00000009, a1  ;offset address for Operator 2 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    nop
    nop
    suba.l                            #0x00000021, a1         ;Get back on track to where we were!! :D


    cmp.b                           #0x00, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x01, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x02, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x03, FMALGORITHM                ; This is important. We need to do compares and branches
    ble                                @FMALGO0123                                 ; to make sure that we feed each operator the correct
    cmp.b                           #0x04, FMALGORITHM                ; volume/velocity values to control the TL of the instrument.
    beq                                @FMALGO4
    cmp.b                           #0x05, FMALGORITHM
    beq                                 @FMALGO56
    cmp.b                           #0x06, FMALGORITHM
    beq                                 @FMALGO56
    cmp.b                           #0x07, FMALGORITHM
    beq                                 @FMALGO7
    bra.w                           @DoneTotalLevel

    @FMALGO0123:
    move.b                        #Op1TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity0
    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    ;jsr                                 KILLTIME
    bra.w                               @NextValue0
    @PrelistenModeVelocity0:

    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    ;jsr                                 KILLTIME
    @NextValue0:
    bra.w                           @DoneTotalLevel

    @FMALGO4:
    move.b                        #Op1TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity1
    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue1
    @PrelistenModeVelocity1:
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue1:
    bra.w                           @DoneTotalLevel

    @FMALGO56:
    move.b                        #Op1TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity2
    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue2
    @PrelistenModeVelocity2:
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue2:
    bra.w                           @DoneTotalLevel

    @FMALGO7:
    move.b                        #Op1TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity3
    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY5, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue3
    @PrelistenModeVelocity3:
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue3:
    bra.w                           @DoneTotalLevel



    @DoneTotalLevel:

    move.b                          #Op1RsaR25, YM2612FM2CONTROL

    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME

    move.b                          #Op2RsaR25, YM2612FM2CONTROL

    adda.l                               #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                               #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op3RsaR25, YM2612FM2CONTROL

    adda.l                              #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op4RsaR25, YM2612FM2CONTROL

    adda.l                               #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    suba.l                               #0x00000025, a1 ; Return to where we were

    move.b                          #Op11DRAM25, YM2612FM2CONTROL

    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                           #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op21DRAM25, YM2612FM2CONTROL

    adda.l                               #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                           #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op31DRAM25, YM2612FM2CONTROL

    adda.l                               #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                            #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op41DRAM25, YM2612FM2CONTROL

    adda.l                              #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                          #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                             KILLTIME
    suba.l                          #0x00000026, a1  ; Return to where we were
    move.b                          #Op12DR25, YM2612FM2CONTROL

    nop
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op22DR25, YM2612FM2CONTROL

    adda.l                           #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op32DR25, YM2612FM2CONTROL

    adda.l                         #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op42DR25, YM2612FM2CONTROL

    adda.l                        #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                           KILLTIME
    suba.l                           #0x00000020, a1 ; Return to where we were

    move.b                      #Op1D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op2D1LRR25,YM2612FM2CONTROL

    adda.l                            #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op3D1LRR25,YM2612FM2CONTROL

    adda.l                            #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op4D1LRR25,YM2612FM2CONTROL

    adda.l                           #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    suba.l                           #0x0000001F, a1 ; Return to where we were

    move.b                     #Op1SSGEG25, YM2612FM2CONTROL

    move.b                      (a1), d4 ;SSGEG
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op2SSGEG25, YM2612FM2CONTROL

    move.b                      (a1), d4 ;SSGEG
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op3SSGEG25, YM2612FM2CONTROL

    move.b                      (a1), d4
    adda.l                     #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op4SSGEG25, YM2612FM2CONTROL

    move.b                      (a1), d4
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME



    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0x05, YM2612FM1DATA
    jsr                         KILLTIME

    move.b                    #CH25FREQMSB, YM2612FM2CONTROL
    jsr                           KILLTIME
    move.b                  d3, YM2612FM2DATA
    jsr                         KILLTIME
    move.b                    #CH25FREQLSB, YM2612FM2CONTROL
    jsr                           KILLTIME
    move.b                  d1, YM2612FM2DATA
    jsr                         KILLTIME

    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0xf5, YM2612FM1DATA
    jsr                         KILLTIME


    @SkipProcessing:

    rts

    @FMNOTEOFF:
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION2:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION2






    move.b                      #Op1D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op2D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op3D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op4D1LRR25,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op1TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op2TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op3TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4TL25, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA

    rts






















































FMCHANNEL6:

    moveq                       #0x0, d0
    cmp.b                       #0x01, PLAYBACKMODE  ;Check Playback State to avoid conflicts with Note Entry and Notation Handler
    beq                           @GetPlaybackData
    move.w                     NOTECURRENTSLOTDATA, d0
    bra.w                         @GetPrelistenData
    @GetPlaybackData:
    move.w                     PLAYBACKCURRENTNOTE6, d0
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @FMNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOYMNOTE
    move.l                             #SYNTHTABLERAM, a1  ;This loads the synthesizer parameters into a1 to prepare for writes.
    moveq                           #0x0, d2
    move.b                          PLAYBACKCURRENTINSTRUMENT6, d2
    mulu.w                          #0x0040, d2
    adda.l                               d2, a1
    adda.l                           #0x00000001, a1  ; This skips the Operator # parameter, we will implement this later :TODO
    bra.w                           @ProcessFM
    @GetPrelistenData:
    cmp.w                     #0xEFFB, d0  ;skip processing if note is blank
    beq                             @SkipProcessing
    cmp.w                       #0x999B, d0
    beq                             @FMNoteOFF
    ror.l                           #0x04, d0  ; data is now Zero, Note, Flat/Sharp/Neither, Octave
    jsr                              CONVERTTOYMNOTE
    move.l                             #SYNTHTABLERAM, a1  ;This loads the synthesizer parameters into a1 to prepare for writes.
    moveq                           #0x0, d2
    move.b                          NOTEINSTRUMENTNUMBERCACHE, d2
    mulu.w                          #0x0040, d2
    adda.l                               d2, a1
    adda.l                           #0x00000001, a1  ; This skips the Operator # parameter, we will implement this later :TODO
    jsr                                 ConvertVelocityToTotalLevelPrelisten
    @ProcessFM:
    ;First we need permission from the Zilog-80 CPU for us to request BUS access.

    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION


    move.b                    #LFO, YM2612FM1CONTROL

    move.b                          (a1)+, d4  ; ========combine LFO+LFOFREQ
    move.b                          (a1)+, d5

    rol.b                               #0x03, d4
    add.b                               d4, d5
    move.b                            d5, YM2612FM1DATA   ;Turn LFO off
    jsr                                 KILLTIME
    move.b                      #CH36FBAL, YM2612FM2CONTROL

    move.b                      (a1)+, d4  ; ==========Combine Feedback+Algorithm
    move.b                      (a1)+, d5
    move.b                      d5, FMALGORITHM ;Save the algorithm value, we're going to need it to apply Velocity to the correct Operators.
    rol.b                               #0x03, d4
    add.b                         d4, d5
    move.b                      d5, YM2612FM2DATA



    move.b                      #Op1D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op2D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op3D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op4D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op1TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME


    move.b                     #CH36STLFOS, YM2612FM2CONTROL

    move.b                      (a1)+, d4 ;AMS
    move.b                      (a1)+, d5 ; FMS
    move.b                       (a1)+, d6 ;Stereo
    rol.b                           #0x04, d4
    ror.b                           #0x02, d6
    add.b                          d4, d5
    add.b                          d5, d6
    move.b                    d6, YM2612FM2DATA
    jsr                         KILLTIME
    move.b                     #TIMERSCH36MODE, YM2612FM1CONTROL
    jsr                                 KILLTIME
    move.b                      #0x00, YM2612FM1DATA  ; Turn off Channel 3 special mode.
    jsr                                 KILLTIME
    move.b                       #KEYONOFF, YM2612FM1CONTROL
    jsr                                 KILLTIME
   ; move.b                         #0x00, YM2612FM1DATA   ; Turn all channels off
    ;jsr                                 KILLTIME
    ;move.b                        #0x01, YM2612FM1DATA
  ;  jsr                                 KILLTIME
   ; move.b                        #0x02, YM2612FM1DATA
 ;   jsr                                 KILLTIME
 ;   move.b                       #0x03, YM2612FM1DATA
 ;   jsr                                 KILLTIME
  ;  move.b                       #0x04, YM2612FM1DATA
   ; jsr                                 KILLTIME
    move.b                       #0x06, YM2612FM1DATA
    jsr                                 KILLTIME
 ;   move.b                        #0x06, YM2612FM1DATA
 ;   jsr                                 KILLTIME
    move.b                        #DAC2, YM2612FM1CONTROL
    jsr                                 KILLTIME
    move.b                         #0x00, YM2612FM1DATA     ;Turn off DAC
    jsr                                 KILLTIME


    move.b                        #Op1DM36, YM2612FM2CONTROL

    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                       d5, YM2612FM2DATA
    jsr                                KILLTIME
    move.b                        #Op2DM36, YM2612FM2CONTROL
    jsr                               KILLTIME
    adda.l                           #0x00000009, a1  ;offset address for Operator 2 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3DM36, YM2612FM2CONTROL

    adda.l                            #0x00000009, a1  ;offset address for Operator 3 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4DM36, YM2612FM2CONTROL

    adda.l                            #0x00000009, a1  ;offset address for Operator 2 Mul+Det
    move.b                      (a1)+, d4 ;Multiple
    move.b                       (a1)+, d5 ; Detune
    rol.b                           #0x04, d5
    add.b                           d4, d5
    move.b                        d5, YM2612FM2DATA
    nop
    nop
    suba.l                            #0x00000021, a1         ;Get back on track to where we were!! :D


    cmp.b                           #0x00, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x01, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x02, FMALGORITHM
    beq                               @FMALGO0123
    cmp.b                           #0x03, FMALGORITHM                ; This is important. We need to do compares and branches
    ble                                @FMALGO0123                                 ; to make sure that we feed each operator the correct
    cmp.b                           #0x04, FMALGORITHM                ; volume/velocity values to control the TL of the instrument.
    beq                                @FMALGO4
    cmp.b                           #0x05, FMALGORITHM
    beq                                 @FMALGO56
    cmp.b                           #0x06, FMALGORITHM
    beq                                 @FMALGO56
    cmp.b                           #0x07, FMALGORITHM
    beq                                 @FMALGO7
    bra.w                           @DoneTotalLevel

    @FMALGO0123:
    move.b                        #Op1TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity0
    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    ;jsr                                 KILLTIME
    bra.w                               @NextValue0
    @PrelistenModeVelocity0:

    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    ;jsr                                 KILLTIME
    @NextValue0:
    bra.w                           @DoneTotalLevel

    @FMALGO4:
    move.b                        #Op1TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity1
    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue1
    @PrelistenModeVelocity1:
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue1:
    bra.w                           @DoneTotalLevel

    @FMALGO56:
    move.b                        #Op1TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    move.b                         d4, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity2
    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue2
    @PrelistenModeVelocity2:
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue2:
    bra.w                           @DoneTotalLevel

    @FMALGO7:
    move.b                        #Op1TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 1
    adda.l                             #0x0000000a, a1 ;offset for next op
    cmp.b                           #0x00, PLAYBACKMODE ;Are we on Prelisten? If not we need Playback velocity values.
    beq                               @PrelistenModeVelocity3
    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op

    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were

    move.b                         PLAYBACKCURRENTVELOCITY6, YM2612FM2DATA
    jsr                                 KILLTIME
    bra.w                           @NextValue3
    @PrelistenModeVelocity3:
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 2
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 3
    adda.l                              #0x0000000a, a1 ;offset for next op
    move.b                        PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    nop
    move.b                          (a1)+, d4  ; Total Level for Operator 4
    suba.l                             #0x00000021, a1 ;Return to where we were
    move.b                         PRELISTENCURRENTVELOCITY, YM2612FM2DATA
    jsr                                 KILLTIME
    @NextValue3:
    bra.w                           @DoneTotalLevel



    @DoneTotalLevel:

    move.b                          #Op1RsaR36, YM2612FM2CONTROL

    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME

    move.b                          #Op2RsaR36, YM2612FM2CONTROL

    adda.l                               #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                               #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op3RsaR36, YM2612FM2CONTROL

    adda.l                              #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op4RsaR36, YM2612FM2CONTROL

    adda.l                               #0x00000006, a1  ;Offset to next op
    move.b                           (a1), d4  ;Attack Rate
    adda.l                              #0x00000005, a1 ; offset to Rate Scaling
    move.b                          (a1), d5 ; Rate Scaling
    ror.b                               #0x02, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    suba.l                               #0x00000025, a1 ; Return to where we were

    move.b                          #Op11DRAM36, YM2612FM2CONTROL

    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                           #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op21DRAM36, YM2612FM2CONTROL

    adda.l                               #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                           #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op31DRAM36, YM2612FM2CONTROL

    adda.l                               #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                            #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                          #Op41DRAM36, YM2612FM2CONTROL

    adda.l                              #0x00000005, a1 ; offset to next op
    move.b                         (a1), d4 ;Decay Rate 1
    adda.l                          #0x00000006, a1 ; Offset to AM
    move.b                         (a1), d5
    ror.b                                #0x01, d5
    add.b                               d4, d5
    move.b                          d5, YM2612FM2DATA
    jsr                             KILLTIME
    suba.l                          #0x00000026, a1  ; Return to where we were
    move.b                          #Op12DR36, YM2612FM2CONTROL

    nop
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op22DR36, YM2612FM2CONTROL

    adda.l                           #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op32DR36, YM2612FM2CONTROL

    adda.l                         #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                          #Op42DR36, YM2612FM2CONTROL

    adda.l                        #0x0000000B, a1 ; offset to next op
    move.b                      (a1), d4 ;Decay Rate 2
    move.b                        d4, YM2612FM2DATA
    jsr                           KILLTIME
    suba.l                           #0x00000020, a1 ; Return to where we were

    move.b                      #Op1D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op2D1LRR36,YM2612FM2CONTROL

    adda.l                            #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op3D1LRR36,YM2612FM2CONTROL

    adda.l                            #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    move.b                      #Op4D1LRR36,YM2612FM2CONTROL

    adda.l                           #0x0000000A, a1 ;offset to next op
    move.b                       (a1)+, d4 ;Decay Level
    move.b                       (a1), d5 ; Release rate
    rol.b                           #0x04, d4
    add.b                          d4, d5
    move.b                      d5, YM2612FM2DATA
    jsr                               KILLTIME
    suba.l                           #0x0000001F, a1 ; Return to where we were

    move.b                     #Op1SSGEG36, YM2612FM2CONTROL

    move.b                      (a1), d4 ;SSGEG
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op2SSGEG36, YM2612FM2CONTROL

    move.b                      (a1), d4 ;SSGEG
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op3SSGEG36, YM2612FM2CONTROL

    move.b                      (a1), d4
    adda.l                     #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME
    move.b                     #Op4SSGEG36, YM2612FM2CONTROL

    move.b                      (a1), d4
    adda.l                        #0x0000000B, a1
    move.b                      d4, YM2612FM2DATA
    jsr                             KILLTIME



    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0x06, YM2612FM1DATA
    jsr                         KILLTIME

    move.b                    #CH36FREQMSB, YM2612FM2CONTROL
    jsr                           KILLTIME
    move.b                  d3, YM2612FM2DATA
    jsr                         KILLTIME
    move.b                    #CH36FREQLSB, YM2612FM2CONTROL
    jsr                           KILLTIME
    move.b                  d1, YM2612FM2DATA
    jsr                         KILLTIME

    move.b                      #KEYONOFF, YM2612FM1CONTROL
    jsr                         KILLTIME
    move.b                  #0xf6, YM2612FM1DATA
    jsr                         KILLTIME


    @SkipProcessing:

    rts

    @FMNOTEOFF:
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION2:
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION2






    move.b                      #Op1D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op2D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op3D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                      #Op4D1LRR36,YM2612FM2CONTROL
    jsr                              KILLTIME
    move.b                     #0xFF, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op1TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op2TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op3TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA
    jsr                                 KILLTIME
    move.b                        #Op4TL36, YM2612FM2CONTROL
    jsr                                 KILLTIME
    move.b                         #0x7F, YM2612FM2DATA

    rts
