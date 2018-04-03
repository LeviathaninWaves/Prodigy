;=====Cursor Initialization=============================================
;Now we need to set up the cursor for when the tracker starts up.
;================================================================
INITTRACKER:
    lea                           CURSORDESCRIPTION1, a0     ; Sprite table data
    lea                         CURSORDESCRIPTION2, a1     ; Sprite table data
    lea                        CURSORDESCRIPTION3, a6
    move.w                  #0x1, d0            ; 1 sprite
    bsr                         LOADCURSORTABLES1

    jsr                         CLEANREGISTERS
    move.w                #0x00A0, d0        ;d0= Sprite 1 x, d1 = Sprite 1 and 2 y position, d2= Sprite 2 x
    move.w                #0x0098, d1
    move.w                #0x00A8, d2
    move.w                 #0x00B0, d5
    move.l                  #CURSORRAMX, a0 ;set up ram for storing x, y positions of both cursors.
    move.l                  #CURSORRAMY, a1
    move.l                  #CURSORRAM2X, a2
    move.l                   #CURSORRAM3X, a3
    move.w                   d0, (a0)
    move.w                   d1, (a1)
    move.w                   d2, (a2)
    move.w                   d5, (a3)
    move.w                   d1, CURSORPOSITIONRAM
    move.w                   d0, CURSORPOSITIONRAM2
    move.w                   d2, CURSORPOSITIONRAM3
    move.w                   d5, CURSORPOSITIONRAM4
    move.l                  #0x00, d0                    ; How many pixels to move on Y axis
    move.l                 #0x00000000, d1                     ; Sprite ID
    move.l                  #0x00000001, d2                     ;Second sprite ID
    move.b                   #0x02, d3                          ;0 = up, 1= down, 2 = NEITHER
    move.l                  #0x01, d4
    move.b                  #0x01, CURSORRESET       ; Cursor is initialized
    jsr                            CHECKCURSORSCREEN

    jsr                         DRAWPELABELSMETA              ;draw Labels for the pattern editor
    jsr                         DEFAULTSLOTWINDOW
    move.l                  #0x60100003, CURSORATTRIBUTERAM3
    move.b               #0x00, NOTATIONEDITMODE  ; Initiate Note editing cursor mode.
    move.b                  #0x00, SYNTHEDITMODE


    move.w                 #0x0005, KEYDELAY  ; Initialize the Key Delay value.
    move.w                  #0x203B, LASTNOTE  ;Initiate Last note to C octave 3.
    move.b                  #0x00, INSTRUMENTNUMBERCACHE ; Same as last note, but we want instrument 00 by default.


    move.l                 #0x00000008, FRAMESPEED  ; Initiate the Frame Speed value. Channel 1
    move.l                 #0x00000008, FRAMESPEED2  ; Initiate the Frame Speed value.  Channel 2
    move.l                 #0x00000008, FRAMESPEED3  ; Initiate the Frame Speed value. Channel 3
    move.l                 #0x00000008, FRAMESPEED4  ; Initiate the Frame Speed value.  Channel 4
    move.l                 #0x00000008, FRAMESPEED5  ; Initiate the Frame Speed value. Channel 5
    move.l                 #0x00000008, FRAMESPEED6  ; Initiate the Frame Speed value.  Channel 6
    move.l                 #0x00000008, FRAMESPEED7  ; Initiate the Frame Speed value.  Channel 7 ;PSG
    move.l                 #0x00000008, FRAMESPEED8  ; Initiate the Frame Speed value.  Channel 8
    move.l                 #0x00000008, FRAMESPEED9  ; Initiate the Frame Speed value.  Channel 9
    move.l                 #0x00000008, FRAMESPEEDa  ; Initiate the Frame Speed value.  Channel 10
    ;playback channel initialization. Channel 1
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
    ; Channel 7  PSG
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
    ; Channel 10
    move.b                  #0x01, PLAYBACKPHRASESWITCHa ; default to 1. A value of 1 means it's time to update address in the playback engine
    move.b                  #0x20, PLAYBACKPHRASECOUNTERa; The default number of rows in Phrase screen.
    move.b                   #0x01, PLAYBACKCHAINSWITCHa ; default to 1.
    move.b                     #0x08, PLAYBACKCHAINCOUNTERa ; always 8 Chain rows.
    rts
