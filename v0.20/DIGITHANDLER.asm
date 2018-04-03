
    nop                   0, 8

CHECKCURRENTTABLESLOT: ;checks to see what screen we're on, then goes to select the correct slot for that screen's tables

    jsr                      GETCURRENTSLOTMETA
    move.b            CURRENTSCREEN, d3
    cmp.b              #MAINSCREEN, d3
    beq                  PESLOTMETA
    move.b            CURRENTSCREEN, d3
    cmp.b              #CHAINSCREEN, d3
    beq                  CESLOTMETA
    move.b            CURRENTSCREEN, d3
    cmp.b              #NOTESCREEN, d3                  ;See NOTATIONHANDLER.asm for this special function.
    beq                  NESLOTMETA
    move.b            CURRENTSCREEN, d3
    cmp.b              #SYNTHSCREEN, d3
    beq                  SYNTHSLOTPSGFM
    rts

PESLOTMETA:
    move.b               MAINCURRENTSLOTDATA, d1
    move.b              d1, (a0)
    jsr                     CURRENTTABLE
    rts
CESLOTMETA:
    move.b               CHAINCURRENTSLOTDATA, d1
    move.b              d1, (a0)
    cmp.b                 #0x08, CURRENTTABLESLOT
    bge                   @CURRENTTABLEFF
    jsr                     CURRENTTABLE
    rts

    @CURRENTTABLEFF:
    jsr                       CURRENTTABLEFF   ;For transpose values, which require a range of 00-FF
    rts

SYNTHSLOTPSGFM:
    cmp.b           #0x00, SYNTHSCREENPSGFM
    beq                 SYNTHSLOTMETA
    cmp.b           #0x01, SYNTHSCREENPSGFM
    beq                 SYNTHPSGSLOTMETA
    rts
SYNTHSLOTMETA:

    move.b               SYNTHCURRENTSLOTDATA, d1
    move.b              d1, (a0)
    jsr                     SYNTHSLOTDIGITLIMIT
    rts

SYNTHPSGSLOTMETA:

    move.b               SYNTHCURRENTSLOTDATA, d1
    move.b              d1, (a0)
    jsr                     SYNTHPSGSLOTDIGITLIMIT
    rts
SYNTHSLOTDIGITLIMIT:
;d3 hold the max value for compares on 1st digit, d4 for 2nd digit compares, d5 holds the value to insert in case of max.

; Main Parameters YM2612
    cmp.b                   #0x01, SYNTHEDITMODE
    beq                       @NormalDigitRange
    cmp.b                   #0x02, SYNTHEDITMODE
    beq                        @AlphabetSingle
    cmp.b                   #0x00, CURRENTTABLESLOT
    beq                        @OperatorsCount
    cmp.b                   #0x01, CURRENTTABLESLOT
    beq                        @LFOEnable
    cmp.b                   #0x02, CURRENTTABLESLOT
    beq                        @LFOFrequency
    cmp.b                   #0x03, CURRENTTABLESLOT
    beq                        @Feedback
    cmp.b                   #0x04, CURRENTTABLESLOT
    beq                        @Algorithm
    cmp.b                   #0x05, CURRENTTABLESLOT
    beq                        @AMSensitivity
    cmp.b                   #0x06, CURRENTTABLESLOT
    beq                        @FMSensitivity
    cmp.b                   #0x07, CURRENTTABLESLOT
    beq                        @StereoPanning

;Operator 1
    cmp.b                   #0x08, CURRENTTABLESLOT
    beq                        @Multiple
    cmp.b                   #0x09, CURRENTTABLESLOT
    beq                        @Detune
    cmp.b                   #0x0A, CURRENTTABLESLOT
    beq                        @TotalLevel
    cmp.b                   #0x0B, CURRENTTABLESLOT
    beq                        @AttackRate
    cmp.b                   #0x0C, CURRENTTABLESLOT
    beq                        @DecayRate1
    cmp.b                   #0x0D, CURRENTTABLESLOT
    beq                        @DecayRate2
    cmp.b                   #0x0E, CURRENTTABLESLOT
    beq                        @DecayLevel
    cmp.b                   #0x0F, CURRENTTABLESLOT
    beq                        @ReleaseRate
    cmp.b                   #0x10, CURRENTTABLESLOT
    beq                        @RateScaling
    cmp.b                   #0x11, CURRENTTABLESLOT
    beq                        @SSGEG
    cmp.b                   #0x12, CURRENTTABLESLOT
    beq                        @AmpModulation

 ;Operator 2
    cmp.b                   #0x13, CURRENTTABLESLOT
    beq                        @Multiple
    cmp.b                   #0x14, CURRENTTABLESLOT
    beq                        @Detune
    cmp.b                   #0x15, CURRENTTABLESLOT
    beq                        @TotalLevel
    cmp.b                   #0x16, CURRENTTABLESLOT
    beq                        @AttackRate
    cmp.b                   #0x17, CURRENTTABLESLOT
    beq                        @DecayRate1
    cmp.b                   #0x18, CURRENTTABLESLOT
    beq                        @DecayRate2
    cmp.b                   #0x19, CURRENTTABLESLOT
    beq                        @DecayLevel
    cmp.b                   #0x1A, CURRENTTABLESLOT
    beq                        @ReleaseRate
    cmp.b                   #0x1B, CURRENTTABLESLOT
    beq                        @RateScaling
    cmp.b                   #0x1C, CURRENTTABLESLOT
    beq                        @SSGEG
    cmp.b                   #0x1D, CURRENTTABLESLOT
    beq                        @AmpModulation

;Operator 3
    cmp.b                   #0x1E, CURRENTTABLESLOT
    beq                        @Multiple
    cmp.b                   #0x1F, CURRENTTABLESLOT
    beq                        @Detune
    cmp.b                   #0x20, CURRENTTABLESLOT
    beq                        @TotalLevel
    cmp.b                   #0x21, CURRENTTABLESLOT
    beq                        @AttackRate
    cmp.b                   #0x22, CURRENTTABLESLOT
    beq                        @DecayRate1
    cmp.b                   #0x23, CURRENTTABLESLOT
    beq                        @DecayRate2
    cmp.b                   #0x24, CURRENTTABLESLOT
    beq                        @DecayLevel
    cmp.b                   #0x25, CURRENTTABLESLOT
    beq                        @ReleaseRate
    cmp.b                   #0x26, CURRENTTABLESLOT
    beq                        @RateScaling
    cmp.b                   #0x27, CURRENTTABLESLOT
    beq                        @SSGEG
    cmp.b                   #0x28, CURRENTTABLESLOT
    beq                        @AmpModulation

;Operator4
    cmp.b                   #0x29, CURRENTTABLESLOT
    beq                        @Multiple
    cmp.b                   #0x2A, CURRENTTABLESLOT
    beq                        @Detune
    cmp.b                   #0x2B, CURRENTTABLESLOT
    beq                        @TotalLevel
    cmp.b                   #0x2C, CURRENTTABLESLOT
    beq                        @AttackRate
    cmp.b                   #0x2D, CURRENTTABLESLOT
    beq                        @DecayRate1
    cmp.b                   #0x2E, CURRENTTABLESLOT
    beq                        @DecayRate2
    cmp.b                   #0x2F, CURRENTTABLESLOT
    beq                        @DecayLevel
    cmp.b                   #0x30, CURRENTTABLESLOT
    beq                        @ReleaseRate
    cmp.b                   #0x31, CURRENTTABLESLOT
    beq                        @RateScaling
    cmp.b                   #0x32, CURRENTTABLESLOT
    beq                        @SSGEG
    cmp.b                   #0x33, CURRENTTABLESLOT
    beq                        @AmpModulation

    bra.w                     @NormalDigitRange
    @OperatorsCount:
    move.b               #0x00, d3
    move.b                 #0x02, d4
    move.b                  #0x03, d5
    bra.w                   @HandleDigits
    @LFOEnable:
    move.b               #0x00, d3
    move.b                 #0x00, d4
    move.b                  #0x01, d5
    bra.w                   @HandleDigits
    @LFOFrequency:
    move.b               #0x00, d3
    move.b                 #0x06, d4
    move.b                  #0x07, d5
    bra.w                   @HandleDigits
    @Feedback:
    move.b               #0x00, d3
    move.b                 #0x06, d4
    move.b                  #0x07, d5
    bra.w                   @HandleDigits
    @Algorithm:
    move.b               #0x00, d3
    move.b                 #0x06, d4
    move.b                  #0x07, d5
    bra.w                   @HandleDigits
    @AMSensitivity:
    move.b               #0x00, d3
    move.b                 #0x02, d4
    move.b                  #0x03, d5
    bra.w                   @HandleDigits
    @FMSensitivity:
    move.b               #0x00, d3
    move.b                 #0x06, d4
    move.b                  #0x07, d5
    bra.w                   @HandleDigits
    @StereoPanning:
    move.b               #0x00, d3
    move.b                 #0x02, d4
    move.b                  #0x03, d5
    bra.w                   @HandleDigits
    @Multiple:
    move.b               #0x00, d3
    move.b                 #0x0E, d4
    move.b                  #0x0F, d5
    bra.w                   @HandleDigits
    @Detune:
    move.b               #0x00, d3
    move.b                 #0x06, d4
    move.b                  #0x07, d5
    bra.w                   @HandleDigits
    @TotalLevel:
    move.b               #0x6F, d3
    move.b                 #0x7E, d4
    move.b                  #0x7F, d5
    bra.w                   @HandleDigits
    @AttackRate:
    move.b               #0x0F, d3
    move.b                 #0x1E, d4
    move.b                  #0x1F, d5
    bra.w                   @HandleDigits
    @DecayRate1:
    move.b               #0x0F, d3
    move.b                 #0x1E, d4
    move.b                  #0x1F, d5
    bra.w                   @HandleDigits
    @DecayRate2:
    move.b               #0x0F, d3
    move.b                 #0x1E, d4
    move.b                  #0x1F, d5
    bra.w                   @HandleDigits
    @DecayLevel:
    move.b               #0x00, d3
    move.b                 #0x0E, d4
    move.b                  #0x0F, d5
    bra.w                   @HandleDigits
    @ReleaseRate:
    move.b               #0x00, d3
    move.b                 #0x0E, d4
    move.b                  #0x0F, d5
    bra.w                   @HandleDigits
    @RateScaling:
    move.b               #0x00, d3
    move.b                 #0x01, d4
    move.b                  #0x02, d5
    bra.w                   @HandleDigits
    @SSGEG:
    move.b               #0x00, d3
    move.b                 #0x0E, d4
    move.b                  #0x0F, d5
    bra.w                   @HandleDigits
    @AmpModulation:
    move.b               #0x00, d3
    move.b                 #0x00, d4
    move.b                  #0x01, d5
    bra.w                   @HandleDigits

    @NormalDigitRange:
    move.b               #0x8F, d3
    move.b                 #0x9E, d4
    move.b                  #0x9F, d5
    bra.w                   @HandleDigits

    @HandleDigits:
    jsr                     CURRENTTABLESYNTH
    rts
    @AlphabetSingle:
    move.b               #0x2f, d3
    move.b                 #0x3E, d4
    move.b                  #0x3F, d5
    jsr                     CURRENTTABLEALPHABET
    rts







SYNTHPSGSLOTDIGITLIMIT:
;d3 hold the max value for compares on 1st digit, d4 for 2nd digit compares, d5 holds the value to insert in case of max.

; Main Parameters PSG
    cmp.b                   #0x01, SYNTHEDITMODE
    beq                       @NormalDigitRange
    cmp.b                   #0x02, SYNTHEDITMODE
    beq                        @AlphabetSingle
    cmp.b                   #0x00, CURRENTTABLESLOT
    beq                        @WaveType
    cmp.b                   #0x01, CURRENTTABLESLOT
    beq                        @Attack
    cmp.b                   #0x02, CURRENTTABLESLOT
    beq                        @Decay
    cmp.b                   #0x03, CURRENTTABLESLOT
    beq                        @Sustain
    cmp.b                   #0x04, CURRENTTABLESLOT
    beq                        @Release
    cmp.b                   #0x05, CURRENTTABLESLOT
    beq                        @NoiseClockSource


    bra.w                     @NormalDigitRange
    @WaveType:
    move.b               #0x00, d3
    move.b                 #0x00, d4
    move.b                  #0x01, d5
    bra.w                   @HandleDigits
    @Attack:
    move.b               #0x8f, d3
    move.b                 #0x9e, d4
    move.b                  #0x9f, d5
    bra.w                   @HandleDigits
    @Decay:
    move.b               #0x8f, d3
    move.b                 #0x9e, d4
    move.b                  #0x9f, d5
    bra.w                   @HandleDigits
    @Sustain:
    move.b               #0x8f, d3
    move.b                 #0x9e, d4
    move.b                  #0x9f, d5
    bra.w                   @HandleDigits
    @Release:
    move.b               #0x8f, d3
    move.b                 #0x9e, d4
    move.b                  #0x9f, d5
    bra.w                   @HandleDigits
    @NoiseClockSource:
    move.b               #0x00, d3
    move.b                 #0x02, d4
    move.b                  #0x03, d5
    bra.w                   @HandleDigits


    @NormalDigitRange:
    move.b               #0x8F, d3
    move.b                 #0x9E, d4
    move.b                  #0x9F, d5
    bra.w                   @HandleDigits

    @HandleDigits:
    jsr                     CURRENTTABLESYNTH
    rts
    @AlphabetSingle:
    move.b               #0x2f, d3
    move.b                 #0x3E, d4
    move.b                  #0x3F, d5
    jsr                     CURRENTTABLEALPHABET
    rts
;================Special Digit Handling==============
;This code is like the normal digit handling code, but takes into account whether certain slots have arbitrary
; Max digit values. So we can specify whether the maximum digit is 03, or 7F, instead of the normal 9F.
;=========================================================================

CURRENTTABLESYNTH:                          ;This code selects which slot on the pattern table we're going to edit , and handles digit boundaries
    move.w              TABLESLOTMODDIRECTION, d7
    cmp.b                #0x01, CBUTTON   ; Is C button being pressed?
    bne                    END

    moveq               #0x0, d2
    move.b            (a0), d2
    cmp.b              #0xEF, d2
    beq                     InitSlotSynth

    cmp.w                #0x1000, d7    ; C + Up Button?
    beq                    AddFirstDigitSynth

    cmp.w                #0x0100, d7 ; C + Down Button?
    beq                    SubFirstDigitSynth

    Cmp.w                #0x0001, d7    ; C + Left Button?
    beq                    AddSecondDigitSynth

    cmp.w                #0x0010, d7 ; C+ Right Button?
    beq                    SubSecondDigitSynth


    bra.w                   ENDSynth

InitSlotSynth:
    move.b               #0x00, d2
    move.b             d2, (a0)
    bra.w                   ENDSynth
AddFirstDigitSynth:
    cmp.w               d3, d2
    bge                   @Set9F
    add.b               #0x10, (a0)

    bra.w                 ENDSynth

    @Set9F:
    move.b             d5, (a0)
    bra.w                ENDSynth
SubFirstDigitSynth:
    cmp.w              #0x10, d2
    ble                     @SetZero
    sub.b               #0x10, (a0)
    bra.w               ENDSynth

    @SetZero:
    move.b          #0x00, (a0)
    bra.w               ENDSynth
AddSecondDigitSynth:
    add.b               #0x01, (a0)
    cmp.w               d4, d2
    bge                    @Set9F
    bra.w                 ENDSynth

    @Set9F:
    move.b             d5, (a0)
    bra.w                ENDSynth

SubSecondDigitSynth:
    cmp.w               #0x01, d2
    ble                     @SetZero
    sub.b               #0x01, (a0)
    bra.w               ENDSynth

    @SetZero:
    move.b          #0x00, (a0)
    bra.w               ENDSynth
ENDSynth:
    move.b              (a0), CURRENTSLOTDIGITS  ;Try to get cursor handling working right!!!
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts

CURRENTTABLEALPHABET:                          ;This code selects which slot on the Alphabet table we're going to edit and handles boundaries
    move.w              TABLESLOTMODDIRECTION, d7
    cmp.b                #0x01, CBUTTON   ; Is C button being pressed?
    bne                    END

    moveq               #0x0, d2
    move.b            (a0), d2
    cmp.b              #0xEF, d2
    beq                     InitSlotSynth

    cmp.w                #0x1000, d7    ; C + Up Button?
    beq                    AddFirstDigitAlphabet

    cmp.w                #0x0100, d7 ; C + Down Button?
    beq                    SubFirstDigitAlphabet

    Cmp.w                #0x0001, d7    ; C + Left Button?
    beq                    AddSecondDigitAlphabet

    cmp.w                #0x0010, d7 ; C+ Right Button?
    beq                    SubSecondDigitAlphabet


    bra.w                   ENDAlphabet

InitSlotAlphabet:
    move.b               #0x00, d2
    move.b             d2, (a0)
    bra.w                   ENDAlphabet
AddFirstDigitAlphabet:
    cmp.w               d3, d2
    bge                   @Set9F
    add.b               #0x10, (a0)

    bra.w                 ENDAlphabet

    @Set9F:
    move.b             d5, (a0)
    bra.w                ENDAlphabet
SubFirstDigitALPHABET:
    cmp.w              #0x10, d2
    ble                     @SetZero
    sub.b               #0x10, (a0)
    bra.w               ENDAlphabet

    @SetZero:
    move.b          #0x00, (a0)
    bra.w               ENDAlphabet
AddSecondDigitAlphabet:
    add.b               #0x01, (a0)
    cmp.w               d4, d2
    bge                    @Set9F
    bra.w                 ENDAlphabet

    @Set9F:
    move.b             d5, (a0)
    bra.w                ENDAlphabet

SubSecondDigitAlphabet:
    cmp.w               #0x01, d2
    ble                     @SetZero
    sub.b               #0x01, (a0)
    bra.w               ENDAlphabet

    @SetZero:
    move.b          #0x00, (a0)
    bra.w               ENDAlphabet
ENDAlphabet:
    move.b              (a0), CURRENTSLOTDIGITS  ;Try to get cursor handling working right!!!
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts


;===============Normal digit handling====================
;This code handles digits for the Song/Chain and Note Entry screen (for Instrument/Velcoity)
;==================================================================
CURRENTTABLE:                          ;This code selects which slot on the pattern table we're going to edit , and handles digit boundaries
    move.w              TABLESLOTMODDIRECTION, d7
    cmp.b                #0x01, CBUTTON   ; Is C button being pressed?
    bne                    ENDNoC

    moveq               #0x0, d2
    move.b            (a0), d2
    cmp.b                  #0x01, BBUTTON; C is already pressed. If B is pressed too we need to default slot to "--"
    beq                      DefaultSlot

    cmp.b               #0x02, NOTATIONEDITMODE  ; we need 7F restriction on digits for velocity
    beq                    @NotVelocity
    move.b                 #0x8F, d3
    move.b                  #0x9E, d4
    move.b                  #0x9F, d5
    bra.w                   @Continue
    @NotVelocity:
    move.b                 #0x6F, d3
    move.b                  #0x7E, d4
    move.b                  #0x7F, d5
    @Continue:

    cmp.b              #0xEF, d2
    beq                     InitSlot

    cmp.w                #0x1000, d7    ; C + Up Button?
    beq                    AddFirstDigit

    cmp.w                #0x0100, d7 ; C + Down Button?
    beq                    SubFirstDigit

    Cmp.w                #0x0001, d7    ; C + Left Button?
    beq                    AddSecondDigit

    cmp.w                #0x0010, d7 ; C+ Right Button?
    beq                    SubSecondDigit


    bra.w                   END

InitSlot:
    cmp.b                   #0x01, BBUTTON ;We check if B is pressed to avoid conflict aka "rapidfire init and default slot"
    beq                     END
    move.b               #0x00, d2
    move.b             d2, (a0)
    bra.w                   END

DefaultSlot:
    cmp.b                   #0x02, NOTATIONEDITMODE ; We must not be able to default a velocity slot, there must always be a number.
    beq                       END
    move.b               #0xEF, d2
    move.b             d2, (a0)
    bra.w                   END

AddFirstDigit:
    cmp.w               d3, d2
    bge                   @Set9F
    add.b               #0x10, (a0)

    bra.w                 END

    @Set9F:
    move.b             d5, (a0)
    bra.w                END
SubFirstDigit:
    cmp.w              #0x10, d2
    ble                     @SetZero
    sub.b               #0x10, (a0)
    bra.w               END

    @SetZero:
    move.b          #0x00, (a0)
    bra.w               END
AddSecondDigit:
    add.b               #0x01, (a0)
    cmp.w               d4, d2
    bge                    @Set9F
    bra.w                 END

    @Set9F:
    move.b             d5, (a0)
    bra.w                END
SubSecondDigit:
    cmp.w               #0x01, d2
    ble                     @SetZero
    sub.b               #0x01, (a0)
    bra.w               END

    @SetZero:
    move.b          #0x00, (a0)
    bra.w               END

ENDNoC:
    move.b              (a0), CURRENTSLOTDIGITS  ;Try to get cursor handling working right!!!
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts
END:
    move.b                 #0x00, BBUTTON ; we're done with the B button.
    cmp.b                   #0x01, NOTATIONEDITMODE ;Are we on Note Screen editing Instrument numher?
                                                                                                ;We need to update the Instrument number caching if so.
    beq                     @UpdateInstrumentNumberCache
    move.b              (a0), CURRENTSLOTDIGITS  ;Cursor Updating
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts
    @UpdateInstrumentNumberCache:
    move.b                  NOTEINSTRUMENTNUMBERCACHE, INSTRUMENTNUMBERCACHE
    move.b              (a0), CURRENTSLOTDIGITS  ;For Cursor Updating
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts



CURRENTTABLEFF:                          ;This code selects which slot on the pattern table we're going to edit , and handles digit boundaries
    move.w              TABLESLOTMODDIRECTION, d7
    cmp.b                #0x01, CBUTTON   ; Is C button being pressed?
    bne                    ENDNoCFF

    moveq               #0x0, d2
    move.b            (a0), d2

    move.b                 #0xEF, d3
    move.b                  #0xFE, d4
    move.b                  #0xFF, d5


    cmp.w                #0x1000, d7    ; C + Up Button?
    beq                    AddFirstDigitFF

    cmp.w                #0x0100, d7 ; C + Down Button?
    beq                    SubFirstDigitFF

    Cmp.w                #0x0001, d7    ; C + Left Button?
    beq                    AddSecondDigitFF

    cmp.w                #0x0010, d7 ; C+ Right Button?
    beq                    SubSecondDigitFF


    bra.w                   ENDFF


AddFirstDigitFF:

    add.b               #0x0C, (a0)

    bra.w                 ENDFF


SubFirstDigitFF:
    sub.b               #0x0C, (a0)
    bra.w               ENDFF

AddSecondDigitFF:
    add.b               #0x01, (a0)
    bra.w                 ENDFF


SubSecondDigitFF:
    sub.b               #0x01, (a0)
    bra.w               ENDFF

ENDNoCFF:
    move.b              (a0), CURRENTSLOTDIGITS  ;Try to get cursor handling working right!!!
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts
ENDFF:
    move.b                 #0x00, BBUTTON ; we're done with the B button.
    move.b              (a0), CURRENTSLOTDIGITS  ;Cursor Updating
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts



CURRENTTABLEFFNORM:                          ;This code selects which slot on the pattern table we're going to edit , and handles digit boundaries
    move.w              TABLESLOTMODDIRECTION, d7
    cmp.b                #0x01, CBUTTON   ; Is C button being pressed?
    bne                    ENDNoCFFNORM

    moveq               #0x0, d2
    move.b            (a0), d2

    move.b                 #0xEF, d3
    move.b                  #0xFE, d4
    move.b                  #0xFF, d5


    cmp.w                #0x1000, d7    ; C + Up Button?
    beq                    AddFirstDigitFFNORM

    cmp.w                #0x0100, d7 ; C + Down Button?
    beq                    SubFirstDigitFFNORM

    Cmp.w                #0x0001, d7    ; C + Left Button?
    beq                    AddSecondDigitFFNORM

    cmp.w                #0x0010, d7 ; C+ Right Button?
    beq                    SubSecondDigitFFNORM


    bra.w                   ENDFFNORM


AddFirstDigitFFNORM:

    add.b               #0x10, (a0)

    bra.w                 ENDFFNORM


SubFirstDigitFFNORM:
    sub.b               #0x10, (a0)
    bra.w               ENDFFNORM

AddSecondDigitFFNORM:
    add.b               #0x01, (a0)
    bra.w                 ENDFFNORM


SubSecondDigitFFNORM:
    sub.b               #0x01, (a0)
    bra.w               ENDFFNORM

ENDNoCFFNORM:
    move.b              (a0), CURRENTSLOTDIGITS  ;Try to get cursor handling working right!!!
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts
ENDFFNORM:
    move.b                 #0x00, BBUTTON ; we're done with the B button.
    move.b              (a0), CURRENTSLOTDIGITS  ;Cursor Updating
    move.w             #0x0000, TABLESLOTMODDIRECTION
    move.b              #0x00, CBUTTON
    rts
