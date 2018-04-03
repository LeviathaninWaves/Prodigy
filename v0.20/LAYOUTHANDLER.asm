    nop 0, 8
;==============================
;                           TRACKER INTIALIZATION
;==================================================
;   Check "current screen"" byte so we know which screen we're using
;=================================================
CHECKCURRENTSCREEN:

    move.b             CURRENTSCREEN, d0
    cmp.b              #UNINITIALIZED, d0
    beq                    INITIALIZE

    move.b               CURRENTSCREENDRAWN, d0
    cmp.b                 #0x01, d0
    beq                     @SkipDrawing

    jsr                     WIPEPLANEB                                              ;Wipe VRAM for new Plane data
    jsr                     WIPEPLANEA

    jsr                     CHECKCURRENTLABELS                             ; check to see if we need to draw labels.

    move.b             CURRENTSCREEN, d0
    cmp.b               #MAINSCREEN, d0
    beq                    DRAWPATTERNEDITORMETAROUTINE

    cmp.b               #NOTESCREEN, d0
    beq                    DRAWNOTEENTRYMETAROUTINE

    cmp.b              #OPTIONSCREEN, d0
    beq                   DRAWOPTIONSMENUMETAROUTINE

    cmp.b              #CHAINSCREEN, d0
    beq                   DRAWCHAINENTRYMETAROUTINE

    move.b              CURRENTSPECIALSCREEN, d1
    cmp.b               #SYNTHSCREEN, d1
    jsr                     DRAWSYNTHESIZERPSGORFM
    @SkipDrawing:

    rts

INITIALIZE:
;==================Table initialization======================
;First we load all tracker tables to ram, then we start up the pattern editor!
;=====================================================

    move.b            #0x00, CURRENTTABLESLOT

    move.l            #0x00000E6, d1                         ; Number of table entries
    move.l             #PATTABLERAM, a2         ;Load starting RAM address into d2 for Chain table data
    move.b              #0xEF, d2                        ; 0xEF we will convert to 0x0D0D for "--" when drawing tables.

;=======Pattern Array==============================================
;Since  pattern and chain arrays are similar in functioning, they will be handled similarly
;===============================================================
    @ptCopy:
    add.b                d2, (a2)
    sub.w            #0x01, d1                          ;minus counter
    adda.l            #0x00000001, a2
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END                        ;break loop if done
    bra.s                  @ptCopy                   ;continue copying

    @END:
;========Chain Array==
;Similar to above process.
;==================
    move.l            #0x0000100, d1                         ; Number of table entries
    move.l             #CHAINTABLERAM, a2         ;Load starting RAM address into d2 for Chain table data
    move.b              #0xEF, d2
    move.b               #0x00, d4
    @ctCopy:
    move.b                d2, (a2)+
    move.b                d2, (a2)+
    move.b                d2, (a2)+
    move.b                d2, (a2)+
    move.b                d2, (a2)+
    move.b                d2, (a2)+
    move.b                d2, (a2)+
    move.b                d2, (a2)+

    move.b                d4, (a2)+
    move.b                d4, (a2)+
    move.b                d4, (a2)+
    move.b                d4, (a2)+
    move.b                d4, (a2)+
    move.b                d4, (a2)+
    move.b                d4, (a2)+
    move.b                d4, (a2)+
    sub.w            #0x01, d1                          ;minus counter
    ;adda.l            #0x00000002, a2
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END2                         ;break loop if done
    bra.s                  @ctCopy                   ;continue copying

@END2:
;=========Phrase Array=====================================================
;Special rules apply to reading and writing the Phrase tables. Refer to Legend below for details.
;=============================================================================
    movem.l         d0-d7/a0-a6, -(sp)
    move.l            #0x0001400, d1                         ; Number of table entries
    move.l             #PHRASETABLERAM, a2         ;Load starting RAM address into d2 for Chain table data
    move.l              #0x00000000, d2

;===============Phrase array Legend================
; NOTE=w, INS+VEL=w, CMD1=w,
;NOTE = E*F,FF / INS+VEL = FF,FF / CMD1 = EF,00/
;=====================================================================
    move.w              #0xEFFB, d2                ;This adheres to the legend. D2-D4 contains, NOTE,I+V,CMD1
    move.w              #0xEF70, d3
    move.w              #0x0000, d4

    @ntCopy:
    move.w                d2, (a2)                                   ;Note                   ;write phrase table to RAM
    adda.l            #0x00000002, a2
    sub.w            #0x01, d1                          ;minus counter
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END3                         ;break loop if done
    bra.s                  @ntCopy                   ;continue copying

    @END3:
    move.l            #0x0001400, d1                         ; Number of table entries

    @ivCopy:
    move.w          d3, (a2)
    adda.l           #0x00000002, a2                    ;INS/VE
    sub.w            #0x01, d1                          ;minus counter
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END4                         ;break loop if done
    bra.s                  @ivCopy                   ;continue copying

    @END4:
    move.l            #0x0001400, d1                         ; Number of table entries

    @cmdCopy:
    move.w          d4, (a2)
    adda.l           #0x00000002, a2                    ;CMD
    sub.w            #0x01, d1                          ;minus counter
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END5                         ;break loop if done
    bra.s                  @cmdCopy                   ;continue copying

    @END5:


;=======Synth Array==============================================
;Time to layout the synth arrays
;===============================================================
    move.l            #0x000027c0, d1                         ; Number of table entries
    move.l             #SYNTHTABLERAM, a2         ;Load starting RAM address into d2 for Chain table data
    move.b              #0x00, d2                        ; 0xEF we will convert to 0x0D0D for "--" when drawing tables.

    @stCopy:
    add.b                d2, (a2)
    sub.w            #0x01, d1                          ;minus counter
    adda.l            #0x00000001, a2
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END6                        ;break loop if done
    bra.s                  @stCopy                   ;continue copying

    @END6:
;==============PSG instrument arrays========================
    move.l            #0x00000b2e, d1                         ; Number of table entries
    move.l             #SYNTHPSGTABLERAM, a2         ;Load starting RAM address into d2 for Chain table data
    move.b              #0x00, d2                        ; 0xEF we will convert to 0x0D0D for "--" when drawing tables.

    @stpCopy:
    add.b                d2, (a2)
    sub.w            #0x01, d1                          ;minus counter
    adda.l            #0x00000001, a2
    cmp.w              #0x00, d1                        ;compare to see if counter is done
    beq.b                    @END7                        ;break loop if done
    bra.s                  @stpCopy                   ;continue copying

    @END7:

    movem.l         (sp)+, d0-d7/a0-a6
    bsr                   DRAWPATTERNEDITORMETAROUTINE
    rts

;================SCREEN LAYOUT META ROUTINES=======
;These are used to prepare for the actual layout drawing routines
;===============================================

;===============================================
;Tracker Information drawing.
;=============================================
DRAWCHANNELID:
    move.b           CURRENTSCREEN, d0
    cmp.b              #MAINSCREEN, d0
    bne                  @SKIPUPDATE
    jsr                    UPDATECHANNELID

    @SKIPUPDATE:
    cmp.b             #SYNTHSCREEN, CURRENTSPECIALSCREEN
    beq                 @SkipDrawing
    moveq           #0x0, d2
    move.b          CHANNELNUMBER, d2
    moveq           #0x0, d0
    moveq           #0x0, d1
    moveq           #0x0, d4
    moveq              #0x0, d5
    moveq           #0x0, d6
    mulu.w          #0x04, d2
    lea                 ChannelIDLabels, a0
    adda.l            d2, a0
    move.b          (a0)+, d4
    move.b          (a0)+, d3
    move.b          (a0)+, d5
    move.b          (a0)+, d6


    add.w              #0x0080, d4
    add.w               #0x0080, d3
    add.w               #0x0080, d5
    add.w               #0x0080, d6
    move.w          #0x0046, d1
    swap              d1
    add.l               #VDPWRITEPLANEA, d1
    move.l              d1, VDPCONTROLPORT
    move.w             d4, VDPDATAPORT
    move.w              d3, VDPDATAPORT
    move.w              d5, VDPDATAPORT
    move.w              d6, VDPDATAPORT
    @SkipDrawing:
    rts

UPDATECHANNELID:
    move.b              TABLESLOTPOSITION, CHANNELNUMBER
    rts
DRAWCHAINID:
    cmp.b           #SYNTHSCREEN, CURRENTSCREEN
    beq               @SkipDrawing
    move.b          CURRENTCHAINID, d2
    jsr                 CONVERTBYTETOFONT
    moveq           #0x0, d3
    move.b          d2, d3
     ror.l              #0x08, d2
     moveq          #0x0, d4
    move.b          d2, d4
    moveq           #0x0, d1
    move.w          #0x0848, d1
    swap               d1
    add.w              #0x0080, d4
    add.w               #0x0080, d3
    add.l               #VDPWRITEPLANEA, d1
    move.l              d1, VDPCONTROLPORT
    move.w             d4, VDPDATAPORT
    move.w              d3, VDPDATAPORT
    @SkipDrawing:
    rts

;========================================
;Draw Pattern Editor ALSO FOR TRACKER INITIALIZATION
;========================================
DRAWPATTERNEDITORMETAROUTINE:
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    lea                    PATTERNEDITOR, a0                              ;Load address into a0
    move.w            #PESIZEW, d0                       ;Size in words
    move.l              #0x00, d1                               ; Y offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    move.l               #0x0, d3                         ;Palette ID
    move.l                #PELINEWIDTH, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWLAYOUTPLANEA  ;Draw the current layout
    movem.l           (sp)+, d0-d7/a0-a6                               ;Restore original registers from stack
    move.b              #0x01, CURRENTSCREENDRAWN    ;Let the program know this screen has been drawn
    move.b              #MAINSCREEN, CURRENTSCREEN
    rts

;;=================
;Draw Note Entry screen
;=================
DRAWNOTEENTRYMETAROUTINE:
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    lea                    NOTEENTRY, a0                              ;Load address into a0
    move.w            #NESIZEW, d0                       ;Size in words
    move.l              #0x00, d1                               ; Y offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    move.l               #0x0, d3                         ;Palette ID
    move.l                #NELINEWIDTH, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWLAYOUTPLANEA  ;Draw the current layout
    movem.l           (sp)+, d0-d7/a0-a6                               ;Restore original registers from stack
    move.b              #0x01, CURRENTSCREENDRAWN    ;Let the program know this screen has been drawn
    move.b              #NOTESCREEN, CURRENTSCREEN
    rts
;;===================
;Draw Options Menu screen
;===================
DRAWOPTIONSMENUMETAROUTINE:
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    lea                    OPTIONSMENU, a0                              ;Loadaddress into a0
    move.w            #OMSIZEW, d0                       ;Size in words
    move.l              #0x00, d1                               ; Y offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    move.l               #0x0, d3                         ;Palette ID
    move.l                #OMLINEWIDTH, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWLAYOUTPLANEA  ;Draw the current layout
    movem.l           (sp)+, d0-d7/a0-a6                               ;Restore original registers from stack
    move.b              #0x01, CURRENTSCREENDRAWN    ;Let the program know this screen has been drawn
    rts

;;=================
;Draw Chain Entry screen
;==================
DRAWCHAINENTRYMETAROUTINE:
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    lea                    CHAINENTRY, a0                              ;Load address into a0
    move.w            #CESIZEW, d0                       ;Size in words
    moveq             #0x0, d1                               ; Y offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    moveq               #0x0, d3                         ;Palette ID
    move.l                #CELINEWIDTH, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWLAYOUTPLANEA  ;Draw the current layout
    movem.l           (sp)+, d0-d7/a0-a6                               ;Restore original registers from stack
    move.b              #0x01, CURRENTSCREENDRAWN    ;Let the program know this screen has been drawn
    move.b               #CHAINSCREEN, CURRENTSCREEN
    rts

;====================
;Before drawing Synth screen
;we need to know which synth
;screen to draw.
;===========
DRAWSYNTHESIZERPSGORFM:
    move.b             SYNTHSCREENPSGFM, d0
    cmp.b                #0x00, d0
    beq                    DRAWSYNTHESIZERMETAROUTINE
    cmp.b                #0x01, d0
    beq                     DRAWSYNTHESIZERPSGMETAROUTINE
    rts

;;=================
;Draw Synth FM screen
;=================
DRAWSYNTHESIZERMETAROUTINE:
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    lea                    SYNTHESIZER, a0                              ;Load string address into a0
    move.w            #SYSIZEW, d0                       ;Size in words
    moveq              #0x0, d1                               ; x, 1 offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    moveq               #0x0, d3                         ;Palette ID
    move.l                #SYLINEWIDTH, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWLAYOUTPLANEA  ;Draw the current layout
    movem.l           (sp)+, d0-d7/a0-a6                               ;Restore original registers from stack
    move.b              #0x01, CURRENTSCREENDRAWN    ;Let the program know this screen has been drawn
    move.b              #SYNTHSCREEN, CURRENTSCREEN

    rts

;;=================
;Draw Synth PSG screen
;=================
DRAWSYNTHESIZERPSGMETAROUTINE:
    movem.l             d0-d7/a0-a6, -(sp)         ;Send previous register data to stack
    lea                    SYNTHESIZERPSG, a0                              ;Load string address into a0
    move.w            #SYPSIZEW, d0                       ;Size in words
    moveq              #0x0, d1                               ; x, 1 offset in d1
    move.l              #FONTID, d2                           ;Load FontID to d2
    moveq               #0x0, d3                         ;Palette ID
    move.l                #SYPLINEWIDTH, d5   ;Set up x coord counter in d0 to prevent drawing off screen
    move.l                 d5, d6                             ; make a copy for the counter reset
    move.l                  #0x00800000, d7
    bsr                      DRAWLAYOUTPLANEA  ;Draw the current layout
    movem.l           (sp)+, d0-d7/a0-a6                               ;Restore original registers from stack
    move.b              #0x01, CURRENTSCREENDRAWN    ;Let the program know this screen has been drawn
    move.b              #SYNTHSCREEN, CURRENTSCREEN

    rts
;============Layout drawing==
; Time to draw the layout to screen
;=========================
DRAWLAYOUTPLANEA:
	; a0 (l) - Pattern editor address
	; d0 (w) - Size in words
	; d1 (bb)- XY coord (in tiles)
	; d2 (b) - Palette

    add.l                  #VDPWRITEPLANEA, d1           ; Add PlaneA write cmd + address
	move.l                d1, VDPCONTROLPORT
    sub.b                  #0x1C, d0             ; Num words in d0, minus 1 for counter (odd stuff happens here) There's an extra tile off display being drawn???

    @layXCopy:
	move.w                  (a0)+, d4              ; Move tile ID from map data to lower d4
	add.w                       d2, d4                 ; Add first tile offset to d4
	move.w                    d4, VDPDATAPORT          ; Move to VRAM
	subq.b                     #0x01, d5                  ; minus 1 for the counter
	cmp.b                      #0x00, d5                        ;test counter
	beq                           @layYCopy                          ;branch to reset the x,y's, counter, and restart this loop'
	dbra                          d0, @layXCopy              ; Loop

    rts

    @layYCopy:
    add.l                   d7, d1
	move.l                d1, VDPCONTROLPORT
    move.b               d6, d5  ; reset counter
    cmp.w                  #0x0000, d0
    beq                     @Done
    jmp                     @layXCopy

    @Done:
    rts

DRAWLAYOUTPLANEB:
	; a0 (l) - Pattern editor address
	; d0 (w) - Size in words
	; d1 (bb)- XY coord (in tiles)
	; d2 (b) - Palette

    add.l                  #VDPWRITEPLANEB, d1           ; Add PlaneA write cmd + address
	move.l                d1, VDPCONTROLPORT
    sub.b                  #0x1C, d0             ; Num words in d0, minus 1 for counter (odd stuff happens here) There's an extra tile off display being drawn???

    @layXCopy:
	move.w                  (a0)+, d4              ; Move tile ID from map data to lower d4
	add.w                       d2, d4                 ; Add first tile offset to d4
	move.w                    d4, VDPDATAPORT          ; Move to VRAM
	subq.b                     #0x01, d5                  ; minus 1 for the counter
	cmp.b                      #0x00, d5                        ;test counter
	beq                           @layYCopy                          ;branch to reset the x,y's, counter, and restart this loop'
	dbra                          d0, @layXCopy              ; Loop

    rts

    @layYCopy:
    add.l                   d7, d1
	move.l                d1, VDPCONTROLPORT
    move.b               d6, d5  ; reset counter
    cmp.w                  #0x0000, d0
    beq                     @Done
    jmp                     @layXCopy

    @Done:
    rts

WIPEPLANEA:          ;Clears Plane A for new layout to be drawn

    move.l                  #VDPWRITEPLANEA, VDPCONTROLPORT
    move.b                  #0x00, d7   ; Empty tile
    move.w                  #0x0800, d6   ;counter
    @Wipe:
    move.b                  d7, VDPDATAPORT
    sub.w                     #0x0001, d6
    cmp.w                     #0x0000, d6
    bne                         @Wipe
    rts
WIPEPLANEB:          ;Clears Plane B for new tables to be drawn

    move.l                  #VDPWRITEPLANEB, VDPCONTROLPORT
    move.b                  #0x00, d7   ; Empty tile
    move.w                  #0x0800, d6   ;counter
    @Wipe:
    move.b                  d7, VDPDATAPORT
    sub.w                     #0x0001, d6
    cmp.w                     #0x0000, d6
    bne                         @Wipe
    rts


;==========Screen moving================================
;This code changes the screens
;====================================================

MOVECURRENTSCREENRIGHT:              ;Whew, this has to be one of the more difficult things I've done so far...
    move.b               CURRENTSCREEN, d0
    cmp.b                 #MAINSCREEN, d0                       ;check to see if the current screen is Main, if so move to Chain
    beq                     MovetoChain                              ; if not however, we check next screen and move as appropriate
    cmp.b                  #CHAINSCREEN, d0
    beq                     MovetoNote
    rts
MovetoChain:
    movem.l             d0-d7/a0-a6, -(sp)
    move.b                TABLESLOTPOSITION, CHANNELNUMBER
    jsr                      GETCURRENTSLOTMETA                       ;We need to get the current slot data for current screen loaded into ram.
    cmp.b              #0xEF, MAINCURRENTSLOTDATA      ;First check to see if there's a chain slot to move to from this position
    beq                     @Skip                                                      ; There isn't, so we stay on Main Screen
    move.b              MAINCURRENTSLOTDATA, d6                           ;This is the byte converted from previous slot's values
    move.b              d6, CURRENTCHAINID                                   ; This is used to draw the number of the current chain onto Tracker Info.
    move.b             CURRENTTABLESLOT, CURRENTCHAINSLOT
    muls.w               #0x0010, d6                                            ; Multiply to get the ID for the new slot
    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    move.b              #CHAINSCREEN, CURRENTSCREEN
    move.b               #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped
    move.l                 #CHAINTABLERAM, d1
    add.l                    d6,d1
    move.l                d1, CURRENTSLOTADDRESS         ;This is mainly needed for Chain table drawing routines;
     move.l              d1, CURRENTCHAINADDRESS                    ; This is for the cache... when we come back to chain we need to know where we left off.

    jsr                         GETCURRENTSLOTCHAIN             ;This was tricky to figure out, we now need the address for the new slot, using the ID we just obtained by multiplying

    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting
    jsr                        DEFAULTSLOTWINDOW                ; Reset slot window to prevent scrolling glitches
    @Skip:
    movem.l             (sp)+, d0-d7/a0-a6
    rts

MovetoNote:
    movem.l             d0-d7/a0-a6, -(sp)

    jsr                      GETCURRENTSLOTMETA                       ;We need to get the current slot data for current screen loaded into ram.

    cmp.b              #0xEF, CHAINCURRENTSLOTDATA      ;First check to see if there's a chain slot to move to from this position
    beq                     @Skip2                                                      ; There isn't, so we stay on Main Screen
    cmp.b                  #0x08, CURRENTTABLESLOT
    bge                      @Skip2
    move.b              CHAINCURRENTSLOTDATA, d6                           ;This is the byte converted from previous slot's values


    muls.w               #0x0040, d6 ; Probably have to change this to account for the extra columns might need #0x08 or #0x10 more than this
    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    move.b              #NOTESCREEN, CURRENTSCREEN
    move.b               #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped
    move.l                 #PHRASETABLERAM, d1
    add.l                    d6,d1
    move.l                d1, PCURRENTSLOTADDRESS         ;This is mainly needed for PHRASE table drawing routines;

    jsr                         GETCURRENTSLOTPHRASE            ;This was tricky to figure out, we now need the address for the new slot, using the ID we just obtained by multiplying

    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting

    jsr                        DEFAULTSLOTWINDOW                ; Reset slot window to prevent scrolling glitches

    @Skip2:
    movem.l             (sp)+, d0-d7/a0-a6
    rts
MOVECURRENTSCREENLEFT:              ;Whew, this has to be one of the more difficult things I've done so far...
    move.b               CURRENTSCREEN, d0
    cmp.b                 #CHAINSCREEN, d0                       ;check to see if the current screen is Main, if so move to Chain
    beq                     MovetoMain                              ; if not however, we check next screen and move as appropriate
    cmp.b                  #PHRASESCREEN, d0
    beq                     MovetoChainfromPhrase
    rts

MovetoMain:
    movem.l             d0-d7/a0-a6, -(sp)

    move.b                #MAINSCREEN, CURRENTSCREEN
    move.b                #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped

    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    jsr                         DEFAULTSLOTWINDOW
    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting

    movem.l             (sp)+, d0-d7/a0-a6
    rts

MovetoChainfromPhrase:
    movem.l             d0-d7/a0-a6, -(sp)
    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    move.w               #0x0000, CURRENTTABLESLOTNOTE             ;Reset Note table slot
    move.b              #CHAINSCREEN, CURRENTSCREEN
    move.b               #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped
    move.l                CURRENTCHAINADDRESS, CURRENTSLOTADDRESS         ;This is mainly needed for Chain table drawing routines;
    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting
    move.b                  #0x00, NOTATIONEDITMODE                 ;restore default setting for the editing mode on Note Entry
    jsr                        DEFAULTSLOTWINDOW                ; Reset slot window to prevent scrolling glitches
    move.w                  #0x203B, LASTNOTE  ;Initiate Last note to C octave 3.
    jsr                         SCROLLRESETVERTICAL
    move.b                    #0x00, INSTRUMENTNUMBERCACHE ;Reset default instrument number
    move.b                    #0x00, NOTEINSTRUMENTNUMBERCACHE ;Reset default instrument number
    movem.l             (sp)+, d0-d7/a0-a6
    rts

SPECIALSCREENUP:              ;This is for special screens that scroll in. Like the synth screen
    move.b               CURRENTSCREEN, d0
    cmp.b                 #NOTESCREEN, d0                       ;check to see if the current screen is NOTE, if so Call synthesizer
    beq                     CALLSYNTHESIZERMETA
    ;cmp.b                  #MAINSCREEN, d0
    ;beq                     CALLOPTIONS
    rts

CALLSYNTHESIZERMETA:
    move.b              CHANNELNUMBER, d0
    cmp.b                  #0x05, d0
    ble                         CALLSYNTHESIZER
    cmp.b                   #0x06, d0
    bge                         CALLSYNTHESIZERPSG
    rts

CALLSYNTHESIZER:
    movem.l             d0-d7/a0-a6, -(sp)
    move.b                  #SYNTHSCREEN, CURRENTSCREEN
    move.b                  #0x00, SYNTHSCREENPSGFM  ; 0 for FM synth
    move.l                   #SYNTHTABLERAM, CURRENTSYNTHSLOTADDRESS
    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    move.w               #0x0000, CURRENTTABLESLOTNOTE             ;Reset Note table slot
    move.b               #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    jsr                         WIPEPLANEB
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped
    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting
    move.b                  #0x00, NOTATIONEDITMODE                 ;restore default setting for the editing mode on Note Entry
    move.b                  NOTEINSTRUMENTNUMBERCACHE, SYNTHINSTRUMENTNUMBER  ;Load the most recently used on Note Entry, synth!
    jsr                        DEFAULTSLOTWINDOW                ; Reset slot window to prevent scrolling glitches
    jsr                         SCROLLRESETVERTICAL
    @Skip:
    movem.l             (sp)+, d0-d7/a0-a6
    rts

CALLSYNTHESIZERPSG:
    movem.l             d0-d7/a0-a6, -(sp)
    move.b                  #SYNTHSCREEN, CURRENTSCREEN
    move.b                  #0x01, SYNTHSCREENPSGFM  ; 1 for PSG synth
    move.l                   #SYNTHPSGTABLERAM, CURRENTSYNTHSLOTADDRESS
    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    move.w               #0x0000, CURRENTTABLESLOTNOTE             ;Reset Note table slot
    move.b               #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    jsr                         WIPEPLANEB
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped
    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting
    move.b                  #0x00, NOTATIONEDITMODE                 ;restore default setting for the editing mode on Note Entry
    move.b                  NOTEINSTRUMENTNUMBERCACHE, SYNTHINSTRUMENTNUMBER  ;Load the most recently used on Note Entry, synth!
    jsr                        DEFAULTSLOTWINDOW                ; Reset slot window to prevent scrolling glitches
    jsr                         SCROLLRESETVERTICAL
    @Skip:
    movem.l             (sp)+, d0-d7/a0-a6
    rts

SPECIALSCREENDOWN:              ;This is for special screens that scroll in. Like the synth screen
    move.b               CURRENTSCREEN, d0
    cmp.b                 #SYNTHSCREEN, d0                       ;check to see if the current screen is SYNTH, if so, return to Note Entry
    beq                     RETURNTONOTEENTRY
    ;cmp.b                  #MAINSCREEN, d0
    ;beq                     CALLOPTIONS
    rts

RETURNTONOTEENTRY:
    movem.l             d0-d7/a0-a6, -(sp)

    move.b                  #NOTESCREEN, CURRENTSCREEN
    ;move.l                   #SYNTHTABLERAM, CURRENTSYNTHSLOTADDRESS
    move.w               #0x0000, CURRENTTABLESLOT             ;Reset table slot
    move.w               #0x0000, CURRENTTABLESLOTNOTE             ;Reset Note table slot
    move.b               #0x00, CURRENTSCREENDRAWN           ;Screen hasn't been drawn
    move.b                #0x00, CURRENTLABELDRAWN            ;Labels haven't been drawn
    move.b                #0x00, PLANEBWIPED                          ;Plane B hasn't been wiped
    move.b                #0x00, CURSORRESET                           ;Cursor needs resetting
    move.b                #0x00, SYNTHEDITMODE                 ;restore default setting for the editing mode on Synth screen

    jsr                        DEFAULTSLOTWINDOW                ; Reset slot window to prevent scrolling glitches
    jsr                         SCROLLRESETVERTICAL
    @Skip:
    movem.l             (sp)+, d0-d7/a0-a6
    rts
