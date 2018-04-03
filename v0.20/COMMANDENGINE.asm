
CHANNEL1COMMAND:
    move.b             PLAYBACKMODE, d0
    cmp.b               0x00, d0
    beq                    @NoProcessing
    jsr                  CHANNEL1COMMANDPROCESSING
    cmp.b           #0x01, CHANNEL1PORTAMENTOSTATE
    beq                 CHANNEL1ARPEGGIO
    cmp.b           #0x02, CHANNEL1PORTAMENTOSTATE
    beq                  CHANNEL1PORTAMENTO
    cmp.b           #0x03, CHANNEL1PORTAMENTOSTATE
    beq                  CHANNEL1PORTAMENTO
    cmp.b           #0x04, CHANNEL1PORTAMENTOSTATE
    beq                  CHANNEL1PORTAMENTONOTE
    @NoProcessing:
    rts


CHANNEL1COMMANDPROCESSING:
    move.w            PLAYBACKCURRENTCOMMAND, d0
    ror.w                 #0x08, d0
    cmp.b               #0x00, d0
    beq                    @Skip
    cmp.b               #0x01, d0   ;Arpeggio?
    beq                    Channel1Arpeggios
    cmp.b               #0x02, d0     ;Portamento Up?
    beq                   Channel1PortamentoUp
    cmp.b               #0x03, d0     ;Portamento Down?
    beq                   Channel1PortamentoDown
    cmp.b               #0x04, d0     ;Portamento to Note?
    beq                   Channel1PortamentotoNote
    @Skip:
    rts

Channel1Arpeggios:
    move.b          #0x01, CHANNEL1PORTAMENTOSTATE
    rol.w               #0x08, d0
    move.b            d0, CHANNEL1COMMANDVALUE
    cmp.b               #0x00, d0  ;Is Portamento value set to 00?
    beq                   @DisablePortamento
    rts

    @DisablePortamento:
    move.b              #0x00, CHANNEL1PORTAMENTOSTATE
    move.b                  #0x00, Channel1ArpeggioFlag
    rts

Channel1PortamentoUp:
    move.b          #0x02, CHANNEL1PORTAMENTOSTATE
    rol.w               #0x08, d0
    move.b            d0, CHANNEL1COMMANDVALUE
    cmp.b               #0x00, d0  ;Is Portamento value set to 00?
    beq                   @DisablePortamento
    rts

    @DisablePortamento:
    move.b              #0x00, CHANNEL1PORTAMENTOSTATE
    rts

Channel1PortamentoDown:
    move.b          #0x03, CHANNEL1PORTAMENTOSTATE
    rol.w               #0x08, d0
    move.b            d0, CHANNEL1COMMANDVALUE
    cmp.b               #0x00, d0  ;Is Portamento value set to 00?
    beq                   @DisablePortamento
    rts

    @DisablePortamento:
    move.b              #0x00, CHANNEL1PORTAMENTOSTATE
    rts

Channel1PortamentotoNote:
    move.b          #0x04, CHANNEL1PORTAMENTOSTATE
    rol.w               #0x08, d0
    move.b            d0, CHANNEL1COMMANDVALUE
    cmp.b               #0x00, d0  ;Is Portamento value set to 00?
    beq                   @DisablePortamento
    rts

    @DisablePortamento:
    move.b              #0x00, CHANNEL1PORTAMENTOSTATE
    rts









CHANNEL1ARPEGGIO:
    ;We're using a flag system to determine which note value to process this tick.
    moveq              #0x0, d0
    moveq               #0x0, d1
    moveq               #0x0, d2
    moveq               #0x0, d3
    move.b              CHANNEL1COMMANDVALUE, d1
    cmp.b               #0x00, CHANNEL1ARPEGGIOFLAG ;Uninitialized?
    beq                   @GetBaseNote
    cmp.b               #0x01, CHANNEL1ARPEGGIOFLAG ;First Note?
    beq                    @FirstNote
    cmp.b               #0x02, CHANNEL1ARPEGGIOFLAG ; Second Note?
    beq                     @SecondNote
    cmp.b                 #0x03, CHANNEL1ARPEGGIOFLAG ; Third Note?
    beq                     @ThirdNote
    rts

    @GetBaseNote:
    ;We are initializing the Arpeggio command. First we convert the base note to an integer. Then we set the Arp flag to 2.
    ;That is all, nothing else needs to be done because the base note is already playing.

    move.w              PLAYBACKCURRENTNOTE, d0
    jsr                       ConvertNoteToInteger
    move.b                d7, Channel1ArpBase
    rol.l                     #0x08, d0
    and.b                   #%11110000, d0 ;Mask out B in lower nybble, keep octave number
    move.b                 d0, Channel1ArpOctave
    move.b                   #0x02, Channel1ArpeggioFlag ; we set flag to 2nd note and do nothing else this tick.
    rts


    @FirstNote:
    move.b             Channel1ArpBase, d2
    move.b              Channel1ArpOctave, d3
    jsr                      GetNotefromInteger
    ;d4 contains the raw note. We need to add the octave number to it.
    add.b                   d3, d4 ;Note is ready for the YMnote conversion process.
    moveq                   #0x0, d0
    move.w                 d4, d0 ;Prepare for conversion
    and.b                   #%11110000, d0
    ror.w                       #0x04, d0
    jsr                           CONVERTTOYMNOTE
    ;Now d0 has LSB and d3 has MSB
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION1:
    moveq                        #0x0, d7
    move.b                     Z80BUSREQ, d7    ;Read from z80 for status
    btst                           #0x0, d7               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION1

    move.b                    #CH14FREQMSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d3, YM2612FM1DATA

    nop
    nop
    move.b                    #CH14FREQLSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d1, YM2612FM1DATA

    move.b                   #0x02, Channel1ArpeggioFlag ; we set flag to 2nd note
    rts



    @SecondNote:
    and.b                #%11110000, d1 ;Clear Lower nybble of command value.
    ror.b                   #0x04, d1            ; d1 ready for addition.
    move.b             Channel1ArpBase, d2
    move.b              Channel1ArpOctave, d3
    add.b                 d1, d2
    cmp.b                 #0x0c, d2  ;Has the note range been surpassed?
    bge                      @AdjustNoteAndOctave2
    bra.w                   @Continue2
    @AdjustNoteAndOctave2:
    sub.b                  #0x0c, d2
    add.b                 #0x10, d3

    @Continue2:
    jsr                      GetNotefromInteger
    ;d4 contains the raw note. We need to add the octave number to it.
    add.b                   d3, d4 ;Note is ready for the YMnote conversion process.
    moveq                   #0x0, d0
    move.w                 d4, d0 ;Prepare for conversion
    and.b                   #%11110000, d0
    ror.w                       #0x04, d0
    jsr                           CONVERTTOYMNOTE
    ;stop #$2700
    ;Now d0 has LSB and d3 has MSB
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION2:
    moveq                        #0x0, d7
    move.b                     Z80BUSREQ, d7    ;Read from z80 for status
    btst                           #0x0, d7               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION2

    move.b                    #CH14FREQMSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d3, YM2612FM1DATA

    nop
    nop
    move.b                    #CH14FREQLSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d1, YM2612FM1DATA

    move.b                   #0x03, Channel1ArpeggioFlag ; we set flag to 3rd note
    rts

    @ThirdNote:
    and.b                #%00001111, d1 ;Clear Upper nybble of command value.
    move.b             Channel1ArpBase, d2
    move.b              Channel1ArpOctave, d3
    add.b                 d1, d2

    cmp.b                 #0x0c, d2  ;Has the note range been surpassed?
    bge                      @AdjustNoteAndOctave3
    bra.w                   @Continue3
    @AdjustNoteAndOctave3:
    sub.b                  #0x0c, d2
    add.b                 #0x10, d3

    @Continue3:
    jsr                      GetNotefromInteger

    ;d4 contains the raw note. We need to add the octave number to it.
    add.b                   d3, d4 ;Note is ready for the YMnote conversion process.
    moveq                   #0x0, d0
    move.w                 d4, d0 ;Prepare for conversion
    and.b                   #%11110000, d0
    ror.w                       #0x04, d0
    jsr                           CONVERTTOYMNOTE

    ;Now d0 has LSB and d3 has MSB
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION3:
    moveq                        #0x0, d7
    move.b                     Z80BUSREQ, d7    ;Read from z80 for status
    btst                           #0x0, d7               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION3

    move.b                    #CH14FREQMSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d3, YM2612FM1DATA

    nop
    nop
    move.b                    #CH14FREQLSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d1, YM2612FM1DATA

    move.b                   #0x01, Channel1ArpeggioFlag ; we set flag to 1st note
    rts



CHANNEL1PORTAMENTO:
    moveq                #0x0, d1
    move.b            CHANNEL1COMMANDVALUE, d1
    moveq               #0x0, d2
    move.b             CHANNEL1OLDPITCHMSB, d2
    moveq               #0x0, d3
    move.b             d2, d3
    moveq               #0x0, d4
    move.b             CHANNEL1OLDPITCHLSB, d4

    and.b               #%00000111, d2   ;Mask out the octave block
    and.b               #%11111000, d3   ;Mask out the frequency data

    rol.w               #0x08, d2
    add.w               d2, d4          ; MSB + LSB, no octave block, which is stored in d3

    cmp.b              #0x02, CHANNEL1PORTAMENTOSTATE
    beq                  @PortUP
    cmp.b              #0x03, CHANNEL1PORTAMENTOSTATE
    beq                   @PortDOWN
    rts

    @PortUP:
    add.w              d1, d4
    cmp.w              #0x0800, d4
    bge                   @Resetto400
    bra.w               @UpdateFrequency
    @Resetto400:
    add.w                 #0x0008, d3
    sub.w                 #0x0800, d4
    add.w            #0x0400, d4
    rol.w                #0x08, d3
    add.w                d3, d4
    cmp.w               #0x3FFF, d4
    bge                     @HoldPitch
    bra.w                 @Continue
    @HoldPitch:
    move.w              #0x3FFF, d4
    bra.w                  @Continue
    @UpdateFrequency:
    rol.w                #0x08, d3
    add.w                d3, d4
    @Continue:
    move.b          d4, CHANNEL1OLDPITCHLSB
    ror.w               #0x08, d4
    move.b             d4, CHANNEL1OLDPITCHMSB
    ;stop                    #$2700
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION:
    moveq                        #0x0, d0
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION

    move.b                    #CH14FREQMSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d4, YM2612FM1DATA
    ror.w                      #0x08, d4
    nop
    nop
    move.b                    #CH14FREQLSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d4, YM2612FM1DATA

    rts


    @PortDOWN:
    ;d1 cmd value, d3 oct block, d4 pitch
    sub.w              d1, d4

    cmp.w              #0x0000, d4
    ble                   @Resetto4002
    bra.w               @UpdateFrequency2
    @Resetto4002:
    sub.w                 #0x0008, d3
    move.w                 #0x0000, d4

    rol.w                #0x08, d3
    add.w                d3, d4
    cmp.w              #0x0800, d4
    ble                     @HoldPitch2
    bra.w                 @Continue2
    @HoldPitch2:
    move.l              #0x00000800, d4
    bra.w                  @Continue2
    @UpdateFrequency2:
    rol.w                #0x08, d3
    add.w                d3, d4
    @Continue2:
    move.b          d4, CHANNEL1OLDPITCHLSB
    ror.w               #0x08, d4
    move.b             d4, CHANNEL1OLDPITCHMSB
    ;stop                    #$2700
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION2:
    moveq                        #0x0, d0
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION2

    move.b                    #CH14FREQMSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d4, YM2612FM1DATA
    ror.w                      #0x08, d4
    nop
    nop
    move.b                    #CH14FREQLSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d4, YM2612FM1DATA

    rts





CHANNEL1PORTAMENTONOTE:

    moveq                #0x0, d1
    move.b            CHANNEL1COMMANDVALUE, d1
    moveq               #0x0, d2
    move.b             CHANNEL1OLDPortaNoteMSB, d2
    moveq               #0x0, d3
    move.b             d2, d3
    moveq               #0x0, d4
    move.b             CHANNEL1OLDPortaNoteLSB, d4

    and.b               #%00000111, d2   ;Mask out the octave block
    and.b               #%11111000, d3   ;Mask out the frequency data

    rol.w               #0x08, d2
    add.w               d4, d2          ; MSB + LSB, no octave block, which is stored in d3
    moveq              #0x0, d4
    move.b             CHANNEL1OLDPITCHMSB, d4
    moveq               #0x0, d0
    move.b             d4, d0
    moveq               #0x0, d5
    move.b             CHANNEL1OLDPITCHLSB, d5

    and.b               #%00000111, d4   ;Mask out the octave block
    and.b               #%11111000, d0   ;Mask out the frequency data

    rol.w               #0x08, d4
    add.w               d5, d4          ; MSB + LSB, no octave block, which is stored in d7
    moveq               #0x0, d5

    ;We need to read our octave number. First we need the octave number from the start/current note/pitch.
    ;Then we need the destination octave number. We can then determine based off of the octave number how to handle the frequency math.
    move.b             CurrentYMOCTAVE, d5
    move.b              DestinationYMOCTAVE, d6

    cmp.b               d5, d6 ;Are they both the same octave?
    beq                   @SpecifyUpDownSame ; We need clarification on the relativity of both pitches

    cmp.b               #0x00, d5
    beq                   @Octave0
    cmp.b               #0x01, d5
    beq                   @Octave1
    cmp.b               #0x02, d5
    beq                   @Octave2
    cmp.b               #0x03, d5
    beq                   @Octave3
    cmp.b               #0x04, d5
    beq                   @Octave4
    cmp.b               #0x05, d5
    beq                   @Octave5
    cmp.b               #0x06, d5
    beq                   @Octave6
    cmp.b               #0x07, d5
    beq                   @Octave7
    cmp.b               #0x08, d5
    beq                   @Octave8

    @SpecifyUpDownSame:
    ;In this case both old and destination frequencies fall within the same octave. So we need to compare the two pitches to get
    ; our portamento direction. But we also still need to specify boundaries and arithmetic variable for d7.
    moveq              #0x0, d6
    moveq               #0x0, d7
    cmp.w              d2, d4
    blt                    @PortDown
    cmp.w              d2, d4
    beq                  @TargetNoteReached
    cmp.w              d2, d4
    bgt                    @PortUp

    @Octave0:
    ;If we've made it to this code block in the tracker, that means that our destination note resides in a higher octave.
    ;So we need the upper pitch boundary in d6 and the new pitch in d7 should we surpass that boundary.
    cmp.b              d5, d6
    blt                     @Oct0Down
    move.w          #0x0283, d6
    move.w          #0x0142, d7
    bra.w               @PortUP
    @Oct0Down:
    move.w             #0x0141, d6
    move.w              #0x0000, d7
    bra.w                 @PortDOWN

    @Octave1:
    cmp.b               d5, d6
    blt                     @Oct1Down
    move.w             #0x283, d6
    move.w                #0x142, d7
    bra.w                   @PortUP
    @Oct1Down:
    move.w                  #0x0141, d6
    move.w                   #0x0142, d7
    bra.w                     @PortDOWN

    @Octave2:
    cmp.b               d5, d6
    blt                     @Oct2Down
    move.w             #0x0507, d6
    move.w                #0x0284, d7
    bra.w                   @PortUP
    @Oct2Down:
    move.w                  #0x0141, d6
    move.w                  #0x0142, d7
    bra.w                     @PortDOWN

    @Octave3:
    cmp.b               d5, d6
    blt                     @Oct3Down
    move.w             #0x0507, d6
    move.w                #0x0284, d7
    bra.w                   @PortUP
    @Oct3Down:
    move.w                  #0x0283, d6
    move.w                  #0x0284, d7
    bra.w                     @PortDOWN

    @Octave4:
    cmp.b               d5, d6
    blt                     @Oct4Down
    move.w             #0x0507, d6
    move.w                #0x0284, d7
    bra.w                   @PortUP
    @Oct4Down:
    move.w                  #0x0283, d6
    move.w                  #0x0284, d7
    bra.w                     @PortDOWN

    @Octave5:
    cmp.b               d5, d6
    blt                     @Oct5Down
    move.w             #0x0507, d6
    move.w                #0x0284, d7
    bra.w                   @PortUP
    @Oct5Down:
    move.w                  #0x0283, d6
    move.w                  #0x0284, d7
    bra.w                     @PortDOWN

    @Octave6:
    cmp.b               d5, d6
    blt                     @Oct6Down
    move.w             #0x0507, d6
    move.w                #0x0284, d7
    bra.w                   @PortUP
    @Oct6Down:
    move.w                  #0x0283, d6
    move.w                  #0x0284, d7
    bra.w                     @PortDOWN

    @Octave7:
    cmp.b               d5, d6
    blt                     @Oct7Down
    move.w             #0x0507, d6
    moveq                 #0x0, d7
    bra.w                   @PortUP
    @Oct7Down:
    move.w                  #0x0283, d6
    move.w                  #0x0284, d7
    bra.w                     @PortDOWN

    @Octave8:
    cmp.b               d5, d6
    blt                     @Oct8Down
    move.w             #0x0507, d6
    moveq                 #0x0, d7
    bra.w                   @PortUP
    @Oct8Down:
    move.w                  #0x0283, d6
    move.w                  #0x0284, d7
    bra.w                     @PortDOWN





;d1 = Portamento Value
;d2 = Starting/Current Pitch Value
;d3 = Starting/Current Octave Block
;d4 = Destination Pitch
;d0 = Destination Octave Block
;d6 = Frequency Octave Boundary
;d7 = Amount to add/subtract to adjust to new octave while bending pitch
    @PortUP:
    add.w              d1, d2
    rol.w               #0x08, d0
    add.w              d0, d4
    cmp.w               #0x0000, d6
    beq                     @UpdateFrequency
    cmp.w              d6, d2
    bge                   @Resetto400
    bra.w               @UpdateFrequency

    @Resetto400:
    move.b               CurrentYMOCTAVE, d0
    add.b                   #0x01, d0
    move.b              d0, CurrentYMOCTAVE
    add.w                 #0x0008, d3
    sub.w                 d7, d2
    rol.w                #0x08, d3
    add.w                d3, d2
    cmp.w               #0x3FFF, d2
    bge                     @HoldPitch
    bra.w                 @Continue

    @HoldPitch:
    move.b              #0x08, CurrentYMOCTAVE
    move.w              #0x3FFF, d2
    bra.w                  @Continue
;d1 = Portamento Value
;d2 = Starting/Current Pitch Value
;d3 = Starting/Current Octave Block
;d4 = Destination Pitch
;d0 = Destination Octave Block
;d6 = Frequency Octave Boundary
;d7 = Amount to add/subtract to adjust to new octave while bending pitch
    @PortDOWN:
    sub.w              d1, d2
    rol.w               #0x08, d0
    add.w              d0, d4
    cmp.w               #0x0000, d6
    beq                     @UpdateFrequency2
    cmp.w              d6, d2
    ble                   @Resetto4002
    bra.w               @UpdateFrequency2

    @Resetto4002:
    move.b               CurrentYMOCTAVE, d0
    sub.b                   #0x01, d0
    move.b              d0, CurrentYMOCTAVE
    sub.w                 #0x0008, d3
    add.w                 d7, d2
    rol.w                #0x08, d3
    add.w                d3, d2
    cmp.w               #0x0941, d2
    ble                     @HoldPitch2
    bra.w                 @Continue2

    @HoldPitch2:
    move.b              #0x00, CurrentYMOCTAVE
    move.l              #0x00000941, d2
    bra.w                  @Continue

    @UpdateFrequency:
    rol.w                #0x08, d3
    add.w                d3, d2

    @Continue:
    cmp.w             d2, d4 ;Have we reached or passed the target note?
    ble                 @TargetNoteReached
    bra.w               @Finish

    @TargetNoteReached:
    move.w          d4, d2
    move.b           #0x00, CHANNEL1PORTAMENTOSTATE
    move.w          #0x0000, PLAYBACKCURRENTCOMMAND
    bra.w               @Finish

    @UpdateFrequency2:
    rol.w                #0x08, d3
    add.w                d3, d2


    @Continue2:
    cmp.w             d2, d4 ;Have we reached or passed the target note?
    bge                 @TargetNoteReached2
    bra.w               @Finish

    @TargetNoteReached2:
    move.w          d4, d2
    move.b           #0x00, CHANNEL1PORTAMENTOSTATE
    move.w          #0x0000, PLAYBACKCURRENTCOMMAND
    @Finish:
    move.b          d2, CHANNEL1OLDPortaNoteLSB
    ror.w               #0x08, d2
    move.b             d2, CHANNEL1OLDPortaNoteMSB
    move.w                      #0x100, Z80BUSREQ
    move.w                      #0x100, Z80RESET

    @WAITFORPERMISSION:
    moveq                        #0x0, d0
    move.b                     Z80BUSREQ, d0    ;Read from z80 for status
    btst                           #0x0, d0               ;Test if bit 0 is 0 or 1
    bne                           @WAITFORPERMISSION

    move.b                    #CH14FREQMSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d2, YM2612FM1DATA
    ror.w                      #0x08, d2
    nop
    nop
    move.b                    #CH14FREQLSB, YM2612FM1CONTROL
    nop
    nop
    nop
    move.b                  d2, YM2612FM1DATA

    @SkipPorta:
    rts
