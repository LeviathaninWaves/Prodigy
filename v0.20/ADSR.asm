
;This code is all for ADSR handling. Mainly for PSG ADSR amplitude but possibly for drawing routines too. We'll see how large the source gets.


;=====PSG ADSR Key On=============================
;At key on only, we need to set our counters, ADSR state to Attack.
;================================================
PSG0ADSRKeyOn:
;Set counters
    move.l              vblank_counter, PSG0ADSRSTARTCOUNTER
;We need our ADSR settings from the PSG patch.
    moveq               #0x0, d0
    cmp.b                 #0x00, PLAYBACKMODE
    bne                     @PlaybackADSR
    move.b             NOTEINSTRUMENTNUMBERCACHE, d0
    bra.w               @Continue
    @PlaybackADSR:
    move.b              PLAYBACKCURRENTINSTRUMENT7, d0
    @Continue:
    move.l              #SYNTHPSGTABLERAM, d1
    mulu.w             #0x12, d0
    add.l                  d0, d1 ;Now we add the RAM offset for our PSG patch!
    move.l                d1, a0 ;Ready to read ADSR

;Time to set up our counters, First we get the ADSR values
; from the PSG instrument patch that is current then we update the target counters.
    adda.l              #0x00000001, a0 ; points to Attack
    move.l              PSG0ADSRSTARTCOUNTER, d0
    moveq               #0x0, d2
    moveq               #0x0, d3
    moveq               #0x0, d4
    moveq               #0x0, d5

    move.b              (a0)+, d2
    cmp.b               #0x00, d2
    bne                    @Skip1
    move.b               #0x01, d2

    @Skip1:                                                                      ;Get ADSR values, check if zero, if so set to 1, then set counter target for timing
    add.l                 d2, d0
    move.l              d0, PSG0ATTACKTARGET
    move.b             (a0)+, d3
    cmp.b               #0x00, d3
    bne                    @Skip2
    move.b              #0x01, d3

    @Skip2:
    add.l                  d3, d0
    move.l              d0, PSG0DECAYTARGET
    move.b             (a0)+, d4
    cmp.b               #0x00, d4
    bne                    @Skip3
    move.b              #0x01, d4

    @Skip3:
    add.l                  d4, d0
    move.l              d0, PSG0SUSTAINTARGET
    move.b             (a0)+, d5
    cmp.b               #0x00, d5
    bne                    @Skip4
    move.b              #0x01, d5

    @Skip4:
    add.l                  d5, d0
    move.l              d0, PSG0RELEASETARGET

    ;And now to trigger the ADSR mechanism with the ATTACK state set.
    move.b              #0x01, PSG0ADSRSTATE
    rts


;=======PSG ADSR Calculations==================================================
;I'm pretty sure this code needs to be executed only once per note.  These are the majority of calculations
; behind the ADSR. It involves converting values and getting the ADSR rates. Velocity is to be taken into
; account with both prelisten and playback. The velocity value is converted to a PSG VOLUME, not attenuation,
;but volume value by means of the Lookup table found in CONVERSIONLUT.asm. This value is used to determine the overall max volume
; of the Attack/Decay states and is divided to get the Sustain volume which is also the loudest
; of the Release volume. For the latter, division can cause problems, so if the velocity happens to result in
; a really low value such as 1, then it will be necessary to use cmp and branches to determine the volume of Sustain/Release.
;==========================================================
PSG0ADSRCalculations:
    moveq                #0x0, d0
    cmp.b               #0x00, PLAYBACKMODE
    bne                     @PlaybackVelocity
    move.b              PRELISTENCURRENTVELOCITY, d0
    bra.w                 @Continue
    @PlaybackVelocity:
    move.b              PLAYBACKCURRENTVELOCITY7, d0
    @Continue:
    move.l               #CONVERT7Fto0F, d1
    add.l                   d0, d1
    move.l                 d1, a0 ;This should point to the value that we need for our ADSR volume.
    moveq                 #0x0, d0
    moveq                 #0x0, d6
    move.b                (a0), d0 ;This should have the volume value.
    ror.w                  #0x04, d0 ; This value is ready to be used for calculations.
    move.l                 d2, DEBUG
    ;d2-d5 contain actual A(d2) D(d3) S(d4) R(d5) values.
    ;First let's get our attack rate.
    move.l              d0, d1
    divu                    #0x0002, d1 ; This value is our middle volume for the end of decay, sustain and start of release
    move.w              d1, PSG0MIDDLEVOLUME
    move.l              d0, d1
    divu                d2, d1  ;This is our Attack rate
    move.w                #0xF000, d0
    ;move.w              d0, d6 ; Original Volume.
    ;sub.w               d1, d6  ;This value is the next frame's value
    move.w             d1, PSG0AttackRate ;Store the Attack rate for future operations.

    move.w            d0, PSG0OldAttackVolume ;This is stored for future use.
    rol.l                  #0x04, d0
    swap                d0
    add.b                #0x90, d0  ;PSG Channel 1
    move.b             d0, PSGCONTROLPORT  ; Init note to full attenuation PSG channel 1.
    ;That was all for Attack and initialization of the PSG
    ;Now we need to get our decay rate, by dividing the decay value from the Middle volume.
    moveq           #0x0, d0
    move.w             PSG0MIDDLEVOLUME, d0
    divu                    d3, d0
    move.w               d0, PSG0DecayRate
    ;Finally we need our Release Rate. The quotient will always be found by dividing the Release value from 0x1000.
    moveq                   #0x0, d0
    move.w                 PSG0MIDDLEVOLUME, d0
    ;move.w                  #0xf000, d1
   ; sub.w                     d0, d1
    divu                     d5, d0
    move.w              d0, PSG0ReleaseRate

;NOTE I think that the result of the division will be a word technically. 0x1234, the 1 represents the number used to update the PSG itself
;While the rest of the numbers 234 are just decimals. This value is going to be added/subtracted each frame to/from the previous
;frame's volume, then the left most nybble of the word updates the PSG volume, the rest is just for accuracy as stated before.
    rts


;================================================================================================
;This code must be updated once per frame/tick, regardless of the playback engine's frame target. This code involves checking to see
;what state of the ADSR envelope we're in, doing the rest of arithmetic (add, sub new PSG volume to/from old PSG volume, and
; taking the first valid non zero number on the left most side of the result to update the PSG volume.
;========================================================================
PSG0ADSRUpdate:
;First we check our current state, 00=OFF, 01=Attack, 02=Decay, 03=Sustain, 04=Release
    cmp.b               #0x01, PSG0ADSRSTATE
    beq                    CHECKPSG0ATTACKTIMING
    cmp.b               #0x02, PSG0ADSRSTATE
    beq                    CHECKPSG0DECAYTIMING
    cmp.b               #0x03, PSG0ADSRSTATE
    beq                    CHECKPSG0SUSTAINTIMING
    cmp.b               #0x04, PSG0ADSRSTATE
    beq                    CHECKPSG0RELEASETIMING
    rts

CHECKPSG0ATTACKTIMING:
    move.l              vblank_counter, d0
    move.l              PSG0ATTACKTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGAttackStatetoDecay ;Then it's time to start Decay.
    bra.w               @UpdatePSG0Attack
    rts
    @UpdatePSG0Attack:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG0OLDATTACKVOLUME, d0
    move.w          PSG0OLDATTACKVOLUME, d1
    move.w          PSG0AttackRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0x90, d0
    move.b           d0, PSGCONTROLPORT
    sub.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG0OLDATTACKVOLUME
    rts

    @ChangePSGAttackStatetoDecay:
    move.b             #0x02, PSG0ADSRSTATE
    rts

CHECKPSG0DECAYTIMING:
    move.l              vblank_counter, d0
    move.l              PSG0DECAYTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGDecayStatetoSustain ;Then it's time to start Decay.
    bra.w               @UpdatePSG0Decay
    rts
    @UpdatePSG0Decay:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG0OLDATTACKVOLUME, d0
    move.w          PSG0OLDATTACKVOLUME, d1
    move.w          PSG0DecayRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0x90, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG0OLDATTACKVOLUME
    rts

    @ChangePSGDecayStatetoSustain:
    move.b             #0x03, PSG0ADSRSTATE
    rts

CHECKPSG0SUSTAINTIMING:
    move.l              vblank_counter, d0
    move.l              PSG0SUSTAINTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGSustainStatetoRelease ;Then it's time to start Decay.
    rts

    @ChangePSGSustainStatetoRelease:
    move.b             #0x04, PSG0ADSRSTATE
    rts


CHECKPSG0RELEASETIMING:
    move.l              vblank_counter, d0
    move.l              PSG0RELEASETARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGReleaseStatetoOFF ;Then it's time to start Decay.
    bra.w               @UpdatePSG0Release
    rts
    @UpdatePSG0Release:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG0OLDATTACKVOLUME, d0
    move.w          PSG0OLDATTACKVOLUME, d1
    move.w          PSG0ReleaseRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0x90, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG0OLDATTACKVOLUME
    rts

    @ChangePSGReleaseStatetoOFF:
    move.b             #0x00, PSG0ADSRSTATE
    move.b             #0x9f, PSGCONTROLPORT ;Turn sound off.
    rts












































PSG1ADSRKeyOn:
;Set counters
    move.l              vblank_counter, PSG1ADSRSTARTCOUNTER
;We need our ADSR settings from the PSG patch.
    moveq               #0x0, d0
    cmp.b                 #0x00, PLAYBACKMODE
    bne                     @PlaybackADSR
    move.b             NOTEINSTRUMENTNUMBERCACHE, d0
    bra.w               @Continue
    @PlaybackADSR:
    move.b              PLAYBACKCURRENTINSTRUMENT8, d0
    @Continue:
    move.l              #SYNTHPSGTABLERAM, d1
    mulu.w             #0x12, d0
    add.l                  d0, d1 ;Now we add the RAM offset for our PSG patch!
    move.l                d1, a0 ;Ready to read ADSR

;Time to set up our counters, First we get the ADSR values
; from the PSG instrument patch that is current then we update the target counters.
    adda.l              #0x00000001, a0 ; points to Attack
    move.l              PSG1ADSRSTARTCOUNTER, d0
    moveq               #0x0, d2
    moveq               #0x0, d3
    moveq               #0x0, d4
    moveq               #0x0, d5

    move.b              (a0)+, d2
    cmp.b               #0x00, d2
    bne                    @Skip1
    move.b               #0x01, d2

    @Skip1:                                                                      ;Get ADSR values, check if zero, if so set to 1, then set counter target for timing
    add.l                 d2, d0
    move.l              d0, PSG1ATTACKTARGET
    move.b             (a0)+, d3
    cmp.b               #0x00, d3
    bne                    @Skip2
    move.b              #0x01, d3

    @Skip2:
    add.l                  d3, d0
    move.l              d0, PSG1DECAYTARGET
    move.b             (a0)+, d4
    cmp.b               #0x00, d4
    bne                    @Skip3
    move.b              #0x01, d4

    @Skip3:
    add.l                  d4, d0
    move.l              d0, PSG1SUSTAINTARGET
    move.b             (a0)+, d5
    cmp.b               #0x00, d5
    bne                    @Skip4
    move.b              #0x01, d5

    @Skip4:
    add.l                  d5, d0
    move.l              d0, PSG1RELEASETARGET

    ;And now to trigger the ADSR mechanism with the ATTACK state set.
    move.b              #0x01, PSG1ADSRSTATE
    rts


;=======PSG ADSR Calculations==================================================
;I'm pretty sure this code needs to be executed only once per note.  These are the majority of calculations
; behind the ADSR. It involves converting values and getting the ADSR rates. Velocity is to be taken into
; account with both prelisten and playback. The velocity value is converted to a PSG VOLUME, not attenuation,
;but volume value by means of the Lookup table found in CONVERSIONLUT.asm. This value is used to determine the overall max volume
; of the Attack/Decay states and is divided to get the Sustain volume which is also the loudest
; of the Release volume. For the latter, division can cause problems, so if the velocity happens to result in
; a really low value such as 1, then it will be necessary to use cmp and branches to determine the volume of Sustain/Release.
;==========================================================
PSG1ADSRCalculations:
    moveq                #0x0, d0
    cmp.b               #0x00, PLAYBACKMODE
    bne                     @PlaybackVelocity
    move.b              PRELISTENCURRENTVELOCITY, d0
    bra.w                 @Continue
    @PlaybackVelocity:
    move.b              PLAYBACKCURRENTVELOCITY8, d0
    @Continue:
    move.l               #CONVERT7Fto0F, d1
    add.l                   d0, d1
    move.l                 d1, a0 ;This should point to the value that we need for our ADSR volume.
    moveq                 #0x0, d0
    moveq                 #0x0, d6
    move.b                (a0), d0 ;This should have the volume value.
    ror.w                  #0x04, d0 ; This value is ready to be used for calculations.
    move.l                 d2, DEBUG
    ;d2-d5 contain actual A(d2) D(d3) S(d4) R(d5) values.
    ;First let's get our attack rate.
    move.l              d0, d1
    divu                    #0x0002, d1 ; This value is our middle volume for the end of decay, sustain and start of release
    move.w              d1, PSG1MIDDLEVOLUME
    move.l              d0, d1
    divu                d2, d1  ;This is our Attack rate
    move.w                #0xF000, d0
    ;move.w              d0, d6 ; Original Volume.
    ;sub.w               d1, d6  ;This value is the next frame's value
    move.w             d1, PSG1AttackRate ;Store the Attack rate for future operations.

    move.w            d0, PSG1OldAttackVolume ;This is stored for future use.
    rol.l                  #0x04, d0
    swap                d0
    add.b                #0xb0, d0  ;PSG Channel 1
    move.b             d0, PSGCONTROLPORT  ; Init note to full attenuation PSG channel 1.
    ;That was all for Attack and initialization of the PSG
    ;Now we need to get our decay rate, by dividing the decay value from the Middle volume.
    moveq           #0x0, d0
    move.w             PSG1MIDDLEVOLUME, d0
    divu                    d3, d0
    move.w               d0, PSG1DecayRate
    ;Finally we need our Release Rate. The quotient will always be found by dividing the Release value from 0x1000.
    moveq                   #0x0, d0
    move.w                 PSG1MIDDLEVOLUME, d0
    ;move.w                  #0xf000, d1
   ; sub.w                     d0, d1
    divu                     d5, d0
    move.w              d0, PSG1ReleaseRate

;NOTE I think that the result of the division will be a word technically. 0x1234, the 1 represents the number used to update the PSG itself
;While the rest of the numbers 234 are just decimals. This value is going to be added/subtracted each frame to/from the previous
;frame's volume, then the left most nybble of the word updates the PSG volume, the rest is just for accuracy as stated before.
    rts


;================================================================================================
;This code must be updated once per frame/tick, regardless of the playback engine's frame target. This code involves checking to see
;what state of the ADSR envelope we're in, doing the rest of arithmetic (add, sub new PSG volume to/from old PSG volume, and
; taking the first valid non zero number on the left most side of the result to update the PSG volume.
;========================================================================
PSG1ADSRUpdate:
;First we check our current state, 00=OFF, 01=Attack, 02=Decay, 03=Sustain, 04=Release
    cmp.b               #0x01, PSG1ADSRSTATE
    beq                    CHECKPSG1ATTACKTIMING
    cmp.b               #0x02, PSG1ADSRSTATE
    beq                    CHECKPSG1DECAYTIMING
    cmp.b               #0x03, PSG1ADSRSTATE
    beq                    CHECKPSG1SUSTAINTIMING
    cmp.b               #0x04, PSG1ADSRSTATE
    beq                    CHECKPSG1RELEASETIMING
    rts

CHECKPSG1ATTACKTIMING:
    move.l              vblank_counter, d0
    move.l              PSG1ATTACKTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGAttackStatetoDecay ;Then it's time to start Decay.
    bra.w               @UpdatePSG1Attack
    rts
    @UpdatePSG1Attack:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG1OLDATTACKVOLUME, d0
    move.w          PSG1OLDATTACKVOLUME, d1
    move.w          PSG1AttackRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xb0, d0
    move.b           d0, PSGCONTROLPORT
    sub.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG1OLDATTACKVOLUME
    rts

    @ChangePSGAttackStatetoDecay:
    move.b             #0x02, PSG1ADSRSTATE
    rts

CHECKPSG1DECAYTIMING:
    move.l              vblank_counter, d0
    move.l              PSG1DECAYTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGDecayStatetoSustain ;Then it's time to start Decay.
    bra.w               @UpdatePSG1Decay
    rts
    @UpdatePSG1Decay:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG1OLDATTACKVOLUME, d0
    move.w          PSG1OLDATTACKVOLUME, d1
    move.w          PSG1DecayRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xb0, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG1OLDATTACKVOLUME
    rts

    @ChangePSGDecayStatetoSustain:
    move.b             #0x03, PSG1ADSRSTATE
    rts

CHECKPSG1SUSTAINTIMING:
    move.l              vblank_counter, d0
    move.l              PSG1SUSTAINTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGSustainStatetoRelease ;Then it's time to start Decay.
    rts

    @ChangePSGSustainStatetoRelease:
    move.b             #0x04, PSG1ADSRSTATE
    rts


CHECKPSG1RELEASETIMING:
    move.l              vblank_counter, d0
    move.l              PSG1RELEASETARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGReleaseStatetoOFF ;Then it's time to start Decay.
    bra.w               @UpdatePSG1Release
    rts
    @UpdatePSG1Release:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG1OLDATTACKVOLUME, d0
    move.w          PSG1OLDATTACKVOLUME, d1
    move.w          PSG1ReleaseRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xb0, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG1OLDATTACKVOLUME
    rts

    @ChangePSGReleaseStatetoOFF:
    move.b             #0x00, PSG1ADSRSTATE
    move.b             #0xbf, PSGCONTROLPORT ;Turn sound off.
    rts

































    PSG2ADSRKeyOn:
;Set counters
    move.l              vblank_counter, PSG2ADSRSTARTCOUNTER
;We need our ADSR settings from the PSG patch.
    moveq               #0x0, d0
    cmp.b                 #0x00, PLAYBACKMODE
    bne                     @PlaybackADSR
    move.b             NOTEINSTRUMENTNUMBERCACHE, d0
    bra.w               @Continue
    @PlaybackADSR:
    move.b              PLAYBACKCURRENTINSTRUMENT9, d0
    @Continue:
    move.l              #SYNTHPSGTABLERAM, d1
    mulu.w             #0x12, d0
    add.l                  d0, d1 ;Now we add the RAM offset for our PSG patch!
    move.l                d1, a0 ;Ready to read ADSR

;Time to set up our counters, First we get the ADSR values
; from the PSG instrument patch that is current then we update the target counters.
    adda.l              #0x00000001, a0 ; points to Attack
    move.l              PSG2ADSRSTARTCOUNTER, d0
    moveq               #0x0, d2
    moveq               #0x0, d3
    moveq               #0x0, d4
    moveq               #0x0, d5

    move.b              (a0)+, d2
    cmp.b               #0x00, d2
    bne                    @Skip1
    move.b               #0x01, d2

    @Skip1:                                                                      ;Get ADSR values, check if zero, if so set to 1, then set counter target for timing
    add.l                 d2, d0
    move.l              d0, PSG2ATTACKTARGET
    move.b             (a0)+, d3
    cmp.b               #0x00, d3
    bne                    @Skip2
    move.b              #0x01, d3

    @Skip2:
    add.l                  d3, d0
    move.l              d0, PSG2DECAYTARGET
    move.b             (a0)+, d4
    cmp.b               #0x00, d4
    bne                    @Skip3
    move.b              #0x01, d4

    @Skip3:
    add.l                  d4, d0
    move.l              d0, PSG2SUSTAINTARGET
    move.b             (a0)+, d5
    cmp.b               #0x00, d5
    bne                    @Skip4
    move.b              #0x01, d5

    @Skip4:
    add.l                  d5, d0
    move.l              d0, PSG2RELEASETARGET

    ;And now to trigger the ADSR mechanism with the ATTACK state set.
    move.b              #0x01, PSG2ADSRSTATE
    rts


;=======PSG ADSR Calculations==================================================
;I'm pretty sure this code needs to be executed only once per note.  These are the majority of calculations
; behind the ADSR. It involves converting values and getting the ADSR rates. Velocity is to be taken into
; account with both prelisten and playback. The velocity value is converted to a PSG VOLUME, not attenuation,
;but volume value by means of the Lookup table found in CONVERSIONLUT.asm. This value is used to determine the overall max volume
; of the Attack/Decay states and is divided to get the Sustain volume which is also the loudest
; of the Release volume. For the latter, division can cause problems, so if the velocity happens to result in
; a really low value such as 1, then it will be necessary to use cmp and branches to determine the volume of Sustain/Release.
;==========================================================
PSG2ADSRCalculations:
    moveq                #0x0, d0
    cmp.b               #0x00, PLAYBACKMODE
    bne                     @PlaybackVelocity
    move.b              PRELISTENCURRENTVELOCITY, d0
    bra.w                 @Continue
    @PlaybackVelocity:
    move.b              PLAYBACKCURRENTVELOCITY9, d0
    @Continue:
    move.l               #CONVERT7Fto0F, d1
    add.l                   d0, d1
    move.l                 d1, a0 ;This should point to the value that we need for our ADSR volume.
    moveq                 #0x0, d0
    moveq                 #0x0, d6
    move.b                (a0), d0 ;This should have the volume value.
    ror.w                  #0x04, d0 ; This value is ready to be used for calculations.
    move.l                 d2, DEBUG
    ;d2-d5 contain actual A(d2) D(d3) S(d4) R(d5) values.
    ;First let's get our attack rate.
    move.l              d0, d1
    divu                    #0x0002, d1 ; This value is our middle volume for the end of decay, sustain and start of release
    move.w              d1, PSG2MIDDLEVOLUME
    move.l              d0, d1
    divu                d2, d1  ;This is our Attack rate
    move.w                #0xF000, d0
    ;move.w              d0, d6 ; Original Volume.
    ;sub.w               d1, d6  ;This value is the next frame's value
    move.w             d1, PSG2AttackRate ;Store the Attack rate for future operations.

    move.w            d0, PSG2OldAttackVolume ;This is stored for future use.
    rol.l                  #0x04, d0
    swap                d0
    add.b                #0xd0, d0  ;PSG Channel 1
    move.b             d0, PSGCONTROLPORT  ; Init note to full attenuation PSG channel 1.
    ;That was all for Attack and initialization of the PSG
    ;Now we need to get our decay rate, by dividing the decay value from the Middle volume.
    moveq           #0x0, d0
    move.w             PSG2MIDDLEVOLUME, d0
    divu                    d3, d0
    move.w               d0, PSG2DecayRate
    ;Finally we need our Release Rate. The quotient will always be found by dividing the Release value from 0x1000.
    moveq                   #0x0, d0
    move.w                 PSG2MIDDLEVOLUME, d0
    ;move.w                  #0xf000, d1
   ; sub.w                     d0, d1
    divu                     d5, d0
    move.w              d0, PSG2ReleaseRate

;NOTE I think that the result of the division will be a word technically. 0x1234, the 1 represents the number used to update the PSG itself
;While the rest of the numbers 234 are just decimals. This value is going to be added/subtracted each frame to/from the previous
;frame's volume, then the left most nybble of the word updates the PSG volume, the rest is just for accuracy as stated before.
    rts


;================================================================================================
;This code must be updated once per frame/tick, regardless of the playback engine's frame target. This code involves checking to see
;what state of the ADSR envelope we're in, doing the rest of arithmetic (add, sub new PSG volume to/from old PSG volume, and
; taking the first valid non zero number on the left most side of the result to update the PSG volume.
;========================================================================
PSG2ADSRUpdate:
;First we check our current state, 00=OFF, 01=Attack, 02=Decay, 03=Sustain, 04=Release
    cmp.b               #0x01, PSG2ADSRSTATE
    beq                    CHECKPSG2ATTACKTIMING
    cmp.b               #0x02, PSG2ADSRSTATE
    beq                    CHECKPSG2DECAYTIMING
    cmp.b               #0x03, PSG2ADSRSTATE
    beq                    CHECKPSG2SUSTAINTIMING
    cmp.b               #0x04, PSG2ADSRSTATE
    beq                    CHECKPSG2RELEASETIMING
    rts

CHECKPSG2ATTACKTIMING:
    move.l              vblank_counter, d0
    move.l              PSG2ATTACKTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGAttackStatetoDecay ;Then it's time to start Decay.
    bra.w               @UpdatePSG2Attack
    rts
    @UpdatePSG2Attack:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG2OLDATTACKVOLUME, d0
    move.w          PSG2OLDATTACKVOLUME, d1
    move.w          PSG2AttackRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xd0, d0
    move.b           d0, PSGCONTROLPORT
    sub.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG2OLDATTACKVOLUME
    rts

    @ChangePSGAttackStatetoDecay:
    move.b             #0x02, PSG2ADSRSTATE
    rts

CHECKPSG2DECAYTIMING:
    move.l              vblank_counter, d0
    move.l              PSG2DECAYTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGDecayStatetoSustain ;Then it's time to start Decay.
    bra.w               @UpdatePSG2Decay
    rts
    @UpdatePSG2Decay:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG2OLDATTACKVOLUME, d0
    move.w          PSG2OLDATTACKVOLUME, d1
    move.w          PSG2DecayRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xd0, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG2OLDATTACKVOLUME
    rts

    @ChangePSGDecayStatetoSustain:
    move.b             #0x03, PSG2ADSRSTATE
    rts

CHECKPSG2SUSTAINTIMING:
    move.l              vblank_counter, d0
    move.l              PSG2SUSTAINTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGSustainStatetoRelease ;Then it's time to start Decay.
    rts

    @ChangePSGSustainStatetoRelease:
    move.b             #0x04, PSG2ADSRSTATE
    rts


CHECKPSG2RELEASETIMING:
    move.l              vblank_counter, d0
    move.l              PSG2RELEASETARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGReleaseStatetoOFF ;Then it's time to start Decay.
    bra.w               @UpdatePSG2Release
    rts
    @UpdatePSG2Release:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG2OLDATTACKVOLUME, d0
    move.w          PSG2OLDATTACKVOLUME, d1
    move.w          PSG2ReleaseRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xd0, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG2OLDATTACKVOLUME
    rts

    @ChangePSGReleaseStatetoOFF:
    move.b             #0x00, PSG2ADSRSTATE
    move.b             #0xdf, PSGCONTROLPORT ;Turn sound off.
    rts



































PSG3ADSRKeyOn:
;Set counters
    move.l              vblank_counter, PSG3ADSRSTARTCOUNTER
;We need our ADSR settings from the PSG patch.
    moveq               #0x0, d0
    cmp.b                 #0x00, PLAYBACKMODE
    bne                     @PlaybackADSR
    move.b             NOTEINSTRUMENTNUMBERCACHE, d0
    bra.w               @Continue
    @PlaybackADSR:
    move.b              PLAYBACKCURRENTINSTRUMENTa, d0
    @Continue:
    move.l              #SYNTHPSGTABLERAM, d1
    mulu.w             #0x12, d0
    add.l                  d0, d1 ;Now we add the RAM offset for our PSG patch!
    move.l                d1, a0 ;Ready to read ADSR

;Time to set up our counters, First we get the ADSR values
; from the PSG instrument patch that is current then we update the target counters.
    adda.l              #0x00000001, a0 ; points to Attack
    move.l              PSG3ADSRSTARTCOUNTER, d0
    moveq               #0x0, d2
    moveq               #0x0, d3
    moveq               #0x0, d4
    moveq               #0x0, d5

    move.b              (a0)+, d2
    cmp.b               #0x00, d2
    bne                    @Skip1
    move.b               #0x01, d2

    @Skip1:                                                                      ;Get ADSR values, check if zero, if so set to 1, then set counter target for timing
    add.l                 d2, d0
    move.l              d0, PSG3ATTACKTARGET
    move.b             (a0)+, d3
    cmp.b               #0x00, d3
    bne                    @Skip2
    move.b              #0x01, d3

    @Skip2:
    add.l                  d3, d0
    move.l              d0, PSG3DECAYTARGET
    move.b             (a0)+, d4
    cmp.b               #0x00, d4
    bne                    @Skip3
    move.b              #0x01, d4

    @Skip3:
    add.l                  d4, d0
    move.l              d0, PSG3SUSTAINTARGET
    move.b             (a0)+, d5
    cmp.b               #0x00, d5
    bne                    @Skip4
    move.b              #0x01, d5

    @Skip4:
    add.l                  d5, d0
    move.l              d0, PSG3RELEASETARGET

    ;And now to trigger the ADSR mechanism with the ATTACK state set.
    move.b              #0x01, PSG3ADSRSTATE
    rts


;=======PSG ADSR Calculations==================================================
;I'm pretty sure this code needs to be executed only once per note.  These are the majority of calculations
; behind the ADSR. It involves converting values and getting the ADSR rates. Velocity is to be taken into
; account with both prelisten and playback. The velocity value is converted to a PSG VOLUME, not attenuation,
;but volume value by means of the Lookup table found in CONVERSIONLUT.asm. This value is used to determine the overall max volume
; of the Attack/Decay states and is divided to get the Sustain volume which is also the loudest
; of the Release volume. For the latter, division can cause problems, so if the velocity happens to result in
; a really low value such as 1, then it will be necessary to use cmp and branches to determine the volume of Sustain/Release.
;==========================================================
PSG3ADSRCalculations:
    moveq                #0x0, d0
    cmp.b               #0x00, PLAYBACKMODE
    bne                     @PlaybackVelocity
    move.b              PRELISTENCURRENTVELOCITY, d0
    bra.w                 @Continue
    @PlaybackVelocity:
    move.b              PLAYBACKCURRENTVELOCITYa, d0
    @Continue:
    move.l               #CONVERT7Fto0F, d1
    add.l                   d0, d1
    move.l                 d1, a0 ;This should point to the value that we need for our ADSR volume.
    moveq                 #0x0, d0
    moveq                 #0x0, d6
    move.b                (a0), d0 ;This should have the volume value.
    ror.w                  #0x04, d0 ; This value is ready to be used for calculations.
    move.l                 d2, DEBUG
    ;d2-d5 contain actual A(d2) D(d3) S(d4) R(d5) values.
    ;First let's get our attack rate.
    move.l              d0, d1
    divu                    #0x0002, d1 ; This value is our middle volume for the end of decay, sustain and start of release
    move.w              d1, PSG3MIDDLEVOLUME
    move.l              d0, d1
    divu                d2, d1  ;This is our Attack rate
    move.w                #0xF000, d0
    ;move.w              d0, d6 ; Original Volume.
    ;sub.w               d1, d6  ;This value is the next frame's value
    move.w             d1, PSG3AttackRate ;Store the Attack rate for future operations.

    move.w            d0, PSG3OldAttackVolume ;This is stored for future use.
    rol.l                  #0x04, d0
    swap                d0
    add.b                #0xf0, d0  ;PSG Channel 1
    move.b             d0, PSGCONTROLPORT  ; Init note to full attenuation PSG channel 1.
    ;That was all for Attack and initialization of the PSG
    ;Now we need to get our decay rate, by dividing the decay value from the Middle volume.
    moveq           #0x0, d0
    move.w             PSG3MIDDLEVOLUME, d0
    divu                    d3, d0
    move.w               d0, PSG3DecayRate
    ;Finally we need our Release Rate. The quotient will always be found by dividing the Release value from 0x1000.
    moveq                   #0x0, d0
    move.w                 PSG3MIDDLEVOLUME, d0
    ;move.w                  #0xf000, d1
   ; sub.w                     d0, d1
    divu                     d5, d0
    move.w              d0, PSG3ReleaseRate

;NOTE I think that the result of the division will be a word technically. 0x1234, the 1 represents the number used to update the PSG itself
;While the rest of the numbers 234 are just decimals. This value is going to be added/subtracted each frame to/from the previous
;frame's volume, then the left most nybble of the word updates the PSG volume, the rest is just for accuracy as stated before.
    rts


;================================================================================================
;This code must be updated once per frame/tick, regardless of the playback engine's frame target. This code involves checking to see
;what state of the ADSR envelope we're in, doing the rest of arithmetic (add, sub new PSG volume to/from old PSG volume, and
; taking the first valid non zero number on the left most side of the result to update the PSG volume.
;========================================================================
PSG3ADSRUpdate:
;First we check our current state, 00=OFF, 01=Attack, 02=Decay, 03=Sustain, 04=Release
    cmp.b               #0x01, PSG3ADSRSTATE
    beq                    CHECKPSG3ATTACKTIMING
    cmp.b               #0x02, PSG3ADSRSTATE
    beq                    CHECKPSG3DECAYTIMING
    cmp.b               #0x03, PSG3ADSRSTATE
    beq                    CHECKPSG3SUSTAINTIMING
    cmp.b               #0x04, PSG3ADSRSTATE
    beq                    CHECKPSG3RELEASETIMING
    rts

CHECKPSG3ATTACKTIMING:
    move.l              vblank_counter, d0
    move.l              PSG3ATTACKTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGAttackStatetoDecay ;Then it's time to start Decay.
    bra.w               @UpdatePSG3Attack
    rts
    @UpdatePSG3Attack:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG3OLDATTACKVOLUME, d0
    move.w          PSG3OLDATTACKVOLUME, d1
    move.w          PSG3AttackRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xf0, d0
    move.b           d0, PSGCONTROLPORT
    sub.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG3OLDATTACKVOLUME
    rts

    @ChangePSGAttackStatetoDecay:
    move.b             #0x02, PSG3ADSRSTATE
    rts

CHECKPSG3DECAYTIMING:
    move.l              vblank_counter, d0
    move.l              PSG3DECAYTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGDecayStatetoSustain ;Then it's time to start Decay.
    bra.w               @UpdatePSG3Decay
    rts
    @UpdatePSG3Decay:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG3OLDATTACKVOLUME, d0
    move.w          PSG3OLDATTACKVOLUME, d1
    move.w          PSG3DecayRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xf0, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG3OLDATTACKVOLUME
    rts

    @ChangePSGDecayStatetoSustain:
    move.b             #0x03, PSG3ADSRSTATE
    rts

CHECKPSG3SUSTAINTIMING:
    move.l              vblank_counter, d0
    move.l              PSG3SUSTAINTARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGSustainStatetoRelease ;Then it's time to start Decay.
    rts

    @ChangePSGSustainStatetoRelease:
    move.b             #0x04, PSG3ADSRSTATE
    rts


CHECKPSG3RELEASETIMING:
    move.l              vblank_counter, d0
    move.l              PSG3RELEASETARGET, d1
    cmp.l               d0, d1 ;If the end of our attack phase has come
    beq                   @ChangePSGReleaseStatetoOFF ;Then it's time to start Decay.
    bra.w               @UpdatePSG3Release
    rts
    @UpdatePSG3Release:
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d2
    move.w          PSG3OLDATTACKVOLUME, d0
    move.w          PSG3OLDATTACKVOLUME, d1
    move.w          PSG3ReleaseRate, d2
    rol.l               #0x04, d0
    swap            d0
    add.b            #0xf0, d0
    move.b           d0, PSGCONTROLPORT
    add.w              d2, d1                       ;Next Attack step
    move.w          d1, PSG3OLDATTACKVOLUME
    rts

    @ChangePSGReleaseStatetoOFF:
    move.b             #0x00, PSG3ADSRSTATE
    move.b             #0xff, PSGCONTROLPORT ;Turn sound off.
    rts
