;===============Read gamepad data=====================================
GAMEPADTIMING:
    moveq                       #0x0, d6 ; clear register for permission flag
    move.l                     KEYTARGET, d0  ;The Key target is the desired vblank counter value to continue processing pad data.
    move.l                     vblank_counter, d1
    cmp.l                       d0, d1
    beq                        @SetPermissionFlagto1
    cmp.l                       #0x00000000, d0  ;Not yet initialized?
    beq                         @SetPermissionFlagto1
    rts
    @SetPermissionFlagto1:
    move.b                  #0x01, d6
    rts

READGAMEPAD:
    jsr                          KEYDELAYCHECKTOCANCEL
    jsr                         READPAD    ;The end result goes into register d0

    btst                       #PADBUTTONA, d7
    bne                       @NoA
    move.b                  #0x01, ABUTTON
    @NoA:

    btst                       #PADBUTTONB, d7
    bne                       @NoB
    move.b                  #0x01, BBUTTON
    @NoB:

    btst                        #PADBUTTONC, d7 ;Test if button c is pressed, if so, place a flag  for button combinations
    bne                        @NoC
    move.b                  #0x01, CBUTTON
    cmp.b                     #0x00, CRELEASED
    beq                         @NoC
    move.b                    #0x00, CRELEASED
    move.b                   #0x01, PRELISTENTOGGLE
    @NoC:

    jsr                           GAMEPADTIMING
    cmp.b                      #0x00, d6  ;Check to see if it's okay to read start + dpad
    beq                         @Skip         ;It's not okay, so we skip the rest of the buttons
    btst                        #PADBUTTONSTART, d7
    bne                        @NoStart

    cmp.b                   #0x00, STARTRELEASED
    beq                         @NoStart
    move.b                    #0x00, STARTRELEASED
    cmp.b                   #0x00, PLAYBACKMODE    ;Tracker playback stopped?
    beq                        @SetPlay
    cmp.b                     #0x01,  PLAYBACKMODE  ;Tracker playback active?
    beq                          @SetStop
    @SetPlay:
    move.b                  #0x01, PLAYBACKMODE
    ;==========INIT TRACKER PLAYBACK==============================================================
    cmp.b                       #MAINSCREEN, CURRENTSCREEN  ;If we are on Main screen, the cursor highlighted row will be the Playback start position
    beq                           @MainScreenPlayback
    move.l                     #PHRASETABLERAM, a0
    move.l                  a0,  d0
    move.l                    d0, PLAYBACKNOTEADDRESS
    move.l                  vblank_counter, FrameTarget
    jsr                        PLAYBACK
    bra.w                   @NoStart
    @MainScreenPlayback:
    moveq                   #0x0, d0
    moveq                    #0x0, d1
    move.b                  CURRENTTABLESLOT, d0
    move.b                   TABLESLOTPOSITION, d1
    mulu.w                  #0x0016, d1
    sub.b                      d1, d0  ;Now we have available to us the value to get the offset for our starting point from within the Song screen.
    move.l                  #PATTABLERAM, d1 ; Time to get the offset for our starting point
    add.b                       d0, d1
    move.l                  d1, PLAYBACKCURRENTSONGROW  ; We now have our current starting row, for use in the playback engine.
    add.l                     #0x00000017, d1  ;Offset for channel 2
    move.l                    d1, PLAYBACKCURRENTSONGROW2
    add.l                     #0x00000017, d1  ;Offset for channel 3
    move.l                    d1, PLAYBACKCURRENTSONGROW3
    add.l                     #0x00000017, d1  ;Offset for channel 4
    move.l                    d1, PLAYBACKCURRENTSONGROW4
    add.l                     #0x00000017, d1  ;Offset for channel 5
    move.l                    d1, PLAYBACKCURRENTSONGROW5
    add.l                     #0x00000017, d1  ;Offset for channel 6
    move.l                    d1, PLAYBACKCURRENTSONGROW6
    add.l                     #0x00000017, d1  ;Offset for PSG1
    move.l                    d1, PLAYBACKCURRENTSONGROW7
    add.l                     #0x00000017, d1  ;Offset for PSG2
    move.l                    d1, PLAYBACKCURRENTSONGROW8
    add.l                     #0x00000017, d1  ;Offset for PSG3
    move.l                    d1, PLAYBACKCURRENTSONGROW9
    add.l                     #0x00000017, d1  ;Offset for PSG4
    move.l                    d1, PLAYBACKCURRENTSONGROWa

    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN ; Init starting chains.
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN2
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN3
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN4
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN5
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN6
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN7
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN8
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAIN9
    move.l                  #CHAINTABLERAM, PLAYBACKCURRENTCHAINa

    move.l                  vblank_counter, FrameTarget
    jsr                         STARTSEEK
    jsr                        PLAYBACK
    move.l                  vblank_counter, FrameTarget2
    jsr                         STARTSEEK2
    jsr                        PLAYBACK2
    move.l                  vblank_counter, FrameTarget3
    jsr                         STARTSEEK3
    jsr                        PLAYBACK3
    move.l                  vblank_counter, FrameTarget4
    jsr                         STARTSEEK4
    jsr                        PLAYBACK4
    move.l                  vblank_counter, FrameTarget5
    jsr                         STARTSEEK5
    jsr                        PLAYBACK5
    move.l                  vblank_counter, FrameTarget6
    jsr                         STARTSEEK6
    jsr                        PLAYBACK6
    move.l                  vblank_counter, FrameTarget7
    jsr                         STARTSEEK7
    jsr                        PLAYBACK7
    move.l                  vblank_counter, FrameTarget8
    jsr                         STARTSEEK8
    jsr                        PLAYBACK8
    move.l                  vblank_counter, FrameTarget9
    jsr                         STARTSEEK9
    jsr                        PLAYBACK9
    move.l                  vblank_counter, FrameTargeta
    jsr                         STARTSEEKa
    jsr                        PLAYBACKa

    ;==========END INIT TRACKER PLAYBACK===========================================================
    bra.w                   @NoStart
    @SetStop:
    move.b                  #0x00, PLAYBACKMODE
    move.b                  #0x00, CHANNEL1NOPLAY  ;FM
    move.b                  #0x00, CHANNEL2NOPLAY
    move.b                  #0x00, CHANNEL3NOPLAY
    move.b                  #0x00, CHANNEL4NOPLAY
    move.b                  #0x00, CHANNEL5NOPLAY
    move.b                  #0x00, CHANNEL6NOPLAY
    move.b                  #0x00, CHANNEL7NOPLAY ;PSG
    move.b                  #0x00, CHANNEL8NOPLAY
    move.b                  #0x00, CHANNEL9NOPLAY
    move.b                  #0x00, CHANNELaNOPLAY
    ;playback channel initialization. Channel 1 FM1
    move.b                  #0x01, PLAYBACKPHRASESWITCH ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER ; always 8 Chain rows.
    ;Channel 2
    move.b                  #0x01, PLAYBACKPHRASESWITCH2 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER2; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH2 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER2 ; always 8 Chain rows.
    ; Channel 3
    move.b                  #0x01, PLAYBACKPHRASESWITCH3 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER3; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH3 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER3 ; always 8 Chain rows.
    ; Channel 4
    move.b                  #0x01, PLAYBACKPHRASESWITCH4 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER4; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH4 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER4 ; always 8 Chain rows.
    ; Channel 5
    move.b                  #0x01, PLAYBACKPHRASESWITCH5 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER5; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH5 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER5 ; always 8 Chain rows.
    ; Channel 6
    move.b                  #0x01, PLAYBACKPHRASESWITCH6 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER6; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH6 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER6 ; always 8 Chain rows.
    ; Channel 7        PSG1
    move.b                  #0x01, PLAYBACKPHRASESWITCH7 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER7; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH7 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER7 ; always 8 Chain rows.
    ; Channel 8
    move.b                  #0x01, PLAYBACKPHRASESWITCH8 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER8; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH8 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER8 ; always 8 Chain rows.
    ; Channel 9
    move.b                  #0x01, PLAYBACKPHRASESWITCH9 ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTER9; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCH9 ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTER9 ; always 8 Chain rows.
    ; Channel a
    move.b                  #0x01, PLAYBACKPHRASESWITCHa ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTERa; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCHa ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTERa ; always 8 Chain rows.
    ;bra.w                   @NoStart
    @NoStart:

    btst                        #PADBUTTONUP, d7
    bne                         @NoUP
    move.b                    #0x00, UPRELEASED
    cmp.b                     #0x01, ABUTTON      ;A button pressed?
    beq                          @AButtonComboU
    cmp.b                   #0x01, CBUTTON                      ;Test to see if C button is pressed
    beq                        @CButtonComboU

    move.l                  #0x08, d0                    ; How many pixels to move on Y axis
    move.l                 #0x00000000, d1                     ; Sprite ID
    move.l                  #0x00000001, d2                     ;Second sprite ID
    move.b                 #0x00, d3                          ;Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right
    jsr                          CHECKCURSORSCREEN

    @CButtonComboU:
    move.b                  #0x01, TABLESLOTMODIFIER
    move.w                   #0x1000, TABLESLOTMODDIRECTION
    bra.w                   @NoUP
    @AButtonComboU:
    jsr                         SPECIALSCREENUP
    @NoUP:

    btst                        #PADBUTTONDOWN, d7
    bne                        @NoDOWN
    move.b                    #0x00, DOWNRELEASED
    cmp.b                     #0x01, ABUTTON      ;A button pressed?
    beq                          @AButtonComboD
    cmp.b                   #0x01, CBUTTON                       ;Test to see if C button is pressed
    beq                        @CButtonComboD

    move.l                  #0x08, d0                    ; How many pixels to move on Y axis
    move.l                 #0x00000000, d1                     ; Sprite ID
    move.l                  #0x00000001, d2                     ;Second sprite ID
    move.b                   #0x01, d3                         ;Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right
    jsr                          CHECKCURSORSCREEN

    @CButtonComboD:
    move.b                  #0x01, TABLESLOTMODIFIER
    move.w                  #0x0100, TABLESLOTMODDIRECTION
    bra.w                     @NoDOWN
    @AButtonComboD:
    jsr                         SPECIALSCREENDOWN
    @NoDOWN:

    btst                        #PADBUTTONLEFT, d7
    bne                        @NoLEFT
    move.b                    #0x00, LEFTRELEASED
    cmp.b                     #0x01, ABUTTON      ;A button pressed?
    beq                          @AButtonComboL
    cmp.b                   #0x01, CBUTTON                      ;Test to see if C button is pressed
    beq                        @CButtonComboL

    move.l                  #0x20, d0                    ; How many pixels to move on x axis
    move.l                 #0x00000000, d1                     ; Sprite ID
    move.l                  #0x00000001, d2                     ;Second sprite ID
    move.b                   #0x03, d3                         ;Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right
    jsr                          CHECKCURSORSCREEN
    @CButtonComboL:
    move.b                  #0x01, TABLESLOTMODIFIER
    move.w                  #0x0010, TABLESLOTMODDIRECTION
    bra.s                       @NoLeft
    @AButtonComboL:
    jsr                           MOVECURRENTSCREENLEFT
    @NoLEFT:

    btst                        #PADBUTTONRIGHT, d7
    bne                         @NoRIGHT
    move.b                    #0x00, RIGHTRELEASED
    cmp.b                     #0x01, ABUTTON      ;A button pressed?
    beq                          @AButtonComboR
    cmp.b                     #0x01, CBUTTON      ;C button pressed?
    beq                         @CButtonComboR

    move.l                  #0x20, d0                    ; How many pixels to move on x axis
    move.l                 #0x00000000, d1                     ; Sprite ID
    move.l                  #0x00000001, d2                     ;Second sprite ID
    move.b                   #0x04, d3                         ;Direction, 0 = up, 1= down, 2 = neither,3 = left,  4 = right
    jsr                          CHECKCURSORSCREEN


    @CButtonComboR:
    move.b                  #0x01, TABLESLOTMODIFIER
    move.w                  #0x0001, TABLESLOTMODDIRECTION
    bra.s                       @NoRIGHT
    @AButtonComboR:
    jsr                           MOVECURRENTSCREENRIGHT
    @NoRIGHT:

    jsr                             KEYTIMINGCORE
    @Skip:

    jsr                          CLEANREGISTERS

    rts

KEYDELAYCHECKTOCANCEL:
    ;Check if any of the buttons S/UDLR are being held, if not then we reset cancel the KEYDELAY feature by subtracting KEYDELAY from KEYTARGET


    cmp.b               #0x01, STARTRELEASED
    bne                   @KeepKeyDelay
    cmp.b               #0x01, UPRELEASED
    bne                   @KeepKeyDelay
    cmp.b               #0x01, DOWNRELEASED
    bne                   @KeepKeyDelay
    cmp.b               #0x01, LEFTRELEASED
    bne                   @KeepKeyDelay
    cmp.b               #0x01, RIGHTRELEASED
    bne                   @KeepKeyDelay
    ;At this point none of these buttons are being held, so we cancel the Key Delay feature
    move.l               KEYTARGET, d0
    move.l                vblank_counter, d2 ; We need to check to see if there even IS a key delay in progress!
    cmp.l                  d2, d0 ;If there's no key delay we still need to update the KEYTARGET variable with current vblank_counter
    bge                     @UpdateKEYTARGET
    cmp.l                   d2, d0
    ble                     @KeepKeyDelay
    moveq               #0x0, d1
    move.w              KEYDELAY, d1
    sub.l                   d1, d0

    move.l                  d0, KEYTARGET

    @KeepKeyDelay:  ;Or any one of the buttons is detected as held, so we keep Key Delay active
    rts
    @UpdateKEYTARGET:
    move.l                      vblank_counter, KEYTARGET
    rts
KEYTIMINGCORE:
    move.l                      vblank_counter, d0  ;Get blank counter value, add the desired number of frames to wait for next update, then store that.
    moveq                       #0x0, d1
    move.w                       KEYDELAY, d1
    add.l                          d1, d0
    move.l                      d0, KEYTARGET

    rts
