    include 'INIT.asm'
    include 'GLOBALDEFINES.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\PATTERNEDITOR\MAINSCR.asm'
    include 'TEXTHANDLER.asm'
    include 'LAYOUTHANDLER.asm'
    include 'GAMEPAD.asm'
    include 'VBLANKTIMINGS.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\NOTEENTRY\NOTEENTRY.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\NOTEENTRY\NOTEENTRYROWS.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\CHAINENTRY\CHAINENTRY.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\OPTIONSMENU\OPTIONSMENU.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\SYNTHESIZER\SYNTHESIZER.asm'
    include '\dosgames\Dev\68000\TEST68K\Prodigy\v0.20\SYNTHESIZER\SYNTHESIZERPSG.asm'
    include 'GAMEPADHANDLER.asm'
    include 'FUNCTIONS.asm'
    include 'CURSORHANDLER.asm'
    include 'TRACKERINITIALIZATION.asm'
    include 'NOTATIONHANDLER.asm'
    include 'PSGHANDLER.asm'
    include 'PSGNOTETABLE.asm'
    include 'YM2612HANDLER.asm'
    include 'YM2612HANDLER2.asm'
    include 'YM2612GLOBALS.asm'
    include 'YM2612NOTETABLE.asm'
    include 'PLAYBACKENGINE.asm'
    include 'CONVERSIONLUT.asm'
    include 'ADSR.asm'
    include 'COMMANDENGINE.asm'
    include 'IntegerNoteTable.asm'
;=========================================================
; Prodigy V 0.20
; A Sega Genesis music tracker programmed in
; M68K Assembly language
; By Count SymphoniC 'Cory C. Culley'
; Official Project start date is 9/20/2014

;==================Overview=========================
;Tracker commands
;Maybe some graphical updates
;=======Color Loading=========================================
; First we must load the color palette to CRAM.... CRAM? Let's eat some CRAM. lol :)
;==========================================================
INITPALETTE:
    move.l              #VDPWRITEPLANEA, VDPCONTROLPORT     ;Set the VDP to write to VRAM
    move.w             #0x8F02, VDPCONTROLPORT             ;Set auto increment to 2
    move.l              #0xC0000003, VDPCONTROLPORT     ;Set the VDP to write to CRAM

    lea                    MAINSCR_pal, a0                                 ;Load the palette address into address register 0
    move.l              #0x07, d0                                              ;32 bytes (8 Long, - 1 for the counter)
    @PALLOOP:                                                                            ;Loop label
    move.l              (a0)+, VDPDATAPORT                                      ;Move the address to the VDP Data port while using a counter
    dbra                 d0, @PALLOOP                                                             ;Decrement and branch

;========Font Loading=============================================
;Then we must load the fonts for planes A and B
;==============================================================
INITFONT:
    lea                     FONTTILES, a0                         ;Load tiles address a0
    move.l               #FONTVRAM, d0                     ;Load Vram destination address to d0
    move.l               #FONTSIZET, d1                     ;Move number of font tiles to d1
    jsr                      LOADFONT                              ;jump to subroutine LOADFONT in TEXTHANDLER.ASM

;===========Tracker Initialization====================================
;This sets the CURRENTSCREEN byte to 0xFF and prepares start up layout
;==============================================================
    move.b              #UNINITIALIZED, CURRENTSCREEN ; 0xFF for uninitialized screen, CHECKCURRENTSCREEN
    move.l                  #0x90118C81,  d5
    move.l                  d5, VDPCONTROLPORT            ;set scroll size  64 x 32 cells, set display width to 40 cells                                                                                            ; needs to know this for initialization.
    jsr                        CHECKCURRENTSCREEN

    jsr                     INITTRACKER
    move.b             #0x01, CRELEASED
;=====================================================================
;
;                                    ---------->>>>>MAIN PROGRAM LOOP<<<<<------------
;
;=====================================================================
MAINYMDJLOOP:
;====================Program logic======================================
    jsr                         CLEANREGISTERS

    jsr                         READGAMEPAD

    jsr                         CHECKTRACKERSTATE        ;Toggling sound
    jsr                        CHECKCURRENTSCREEN     ;Check what screen we're on, and draw it if it has not been drawn already
    jsr                     DRAWCHAINID ;Draws the current Chain ID in Tracker Info box
    jsr                         DRAWCHANNELID ;Draws the current Channel ID onto the top right corner of the screen
    jsr                         CHECKCURSORMETA ;Check to see if we need to reset cursor and change it's rules
    jsr                        CHECKCURRENTTABLESLOT;   Update which slot we're supposed to be on when editing tables.
    jsr                           CHECKBUTTONSRELEASED;  Does a check to see which buttons have been released.

    jsr                          PRELISTENMETA ; Note Preview
    jsr                          TRACKERPLAYBACK    ;FM1
    jsr                           CHANNEL1COMMAND ;Tracker command processing for Channel 1
    jsr                          TRACKERPLAYBACK2   ;FM2
    jsr                          TRACKERPLAYBACK3   ;FM3
    jsr                          TRACKERPLAYBACK4   ;FM4
    jsr                          TRACKERPLAYBACK5   ;FM5
    jsr                          TRACKERPLAYBACK6   ;FM6
    jsr                          TRACKERPLAYBACK7   ;PSG1
    jsr                          TRACKERPLAYBACK8   ;PSG2
    jsr                          TRACKERPLAYBACK9   ;PSG3
    jsr                          TRACKERPLAYBACKa   ;PSG4
    jsr                           PSG0ADSRUpdate    ;ADSR amplitude updating for PSG channel 1
    jsr                           PSG1ADSRUpdate    ;ADSR amplitude updating for PSG channel 2
    jsr                           PSG2ADSRUpdate    ;ADSR amplitude updating for PSG channel 3
    jsr                           PSG3ADSRUpdate    ;ADSR amplitude updating for PSG channel 4

;==============Update Graphics VSYNC==============================
;Start of Vertical Blank
;=============================================================


    jsr                           WAITVBLANKSTART

    jsr                           WIPEDATAREGISTERS

    jsr                         UPDATECURSORMETA               ;Then draw cursor.

    jsr                        CHECKCURRENTTABLES   ;Check current screen, read table data for that screen from RAM and draw that to screen


    jsr                           WAITVBLANKEND


;=================VSYNC DONE===================================
;End of Vertical Blank
;============================================================
    move.b                  #0x00, ABUTTON                 ;We're done checking for A being press... weird place to put it but it works for now.
    jmp                        MAINYMDJLOOP          ;Return to beginning of program loop

;===============================================================
;
;                               ---------->>>>>>END OF MAIN LOOP<<<<<<-------
;
;===============================================================

CHECKBUTTONSRELEASED:
    jsr                          READPAD
    btst                        #PADBUTTONA, d7
    beq                         @ABUTTONHELD

    move.b                    #0x01, ARELEASED

    @ABUTTONHELD:

    btst                        #PADBUTTONC, d7
    beq                         @CBUTTONHELD

    move.b                    #0x01, CRELEASED
    move.w                     #0x00, PRELISTENTOGGLE
    @CBUTTONHELD:
    btst                        #PADBUTTONSTART, d7
    beq                         @STARTBUTTONHELD

    move.b                    #0x01, STARTRELEASED
    @STARTBUTTONHELD:
    btst                        #PADBUTTONUP, d7
    beq                         @UPBUTTONHELD

    move.b                    #0x01, UPRELEASED
    @UPBUTTONHELD:
    btst                        #PADBUTTONDOWN, d7
    beq                         @DOWNBUTTONHELD

    move.b                    #0x01, DOWNRELEASED
    @DOWNBUTTONHELD:
    btst                        #PADBUTTONLEFT, d7
    beq                         @LEFTBUTTONHELD

    move.b                    #0x01, LEFTRELEASED
    @LEFTBUTTONHELD:
    btst                        #PADBUTTONRIGHT, d7
    beq                         @RIGHTBUTTONHELD

    move.b                    #0x01, RIGHTRELEASED
    @RIGHTBUTTONHELD:
    rts

    ;Labels for the Pattern Editor channel columns "FM1 FM2..... PSG4"
ChannelLabels:
    dc.l     0x262d1100
    dc.l     0x262d1200
    dc.l     0x262d1300
    dc.l     0x262d1400
    dc.l     0x262d1500
    dc.l     0x262d1600
    dc.l    0x30331100
    dc.l    0x30331200
    dc.l    0x30331300
    dc.l    0x30331400
    dc.l     0x00000000

ChainLabel:
    dc.l   0x23282129
    dc.l   0x2E000000
    dc.l   0x00000000
    dc.l   0x00000000
    dc.l   0x00000000
    dc.l   0x00000000
    dc.l   0x00000000
    dc.l   0x00000000
    dc.l   0x00000000
    dc.l   0x00000000

ChannelIDLabels:
    dc.l     0x262d1100;FM1-FM6
    dc.l     0x262d1200
    dc.l     0x262d1300
    dc.l     0x262d1400
    dc.l     0x262d1500
    dc.l     0x262d1600
    dc.l     0x30332711;PSG1-PSG4
    dc.l     0x30332712
    dc.l     0x30332713
    dc.l     0x30332714

;Quick and dirty way to wipe all registers clean. Mainly used for debugging, but can be used in a pinch.
CLEANREGISTERS:

    moveq                 #0x0, d0
    movem.l               (d0), d1-d7/a0-a6
    rts

;In theory this should be a quicker way to clean registers. Research necessary here though.
;The idea is, address registers won't need cleaning as often because when they are written to, their pointer values are
; usually overwritten first before writing data to what they point to, so cleaning them is pointless... lol
;Data registers however are a much different story. My carelessness on many occasions has caused many glitches and crashes, because
; I have trouble keeping up with what data may be left in a register.
WIPEDATAREGISTERS:
    moveq                  #0x0, d0
    moveq                  #0x0, d1
    moveq                  #0x0, d2
    moveq                  #0x0, d3
    moveq                  #0x0, d4
    moveq                  #0x0, d5
    moveq                  #0x0, d6
    moveq                  #0x0, d7
    rts
;===========Playback Management============================
;This code checks to see if we're in playback/live mode or holding c to prelisten.
;If not, we stop all sound.
;=================
CHECKTRACKERSTATE:

    cmp.b                    #0x01, CRELEASED
    bne                        @Skip
    cmp.b                   #0x00, PLAYBACKMODE
    bne                         @Skip
    jsr                          STOPSOUND
    @Skip:
    rts
