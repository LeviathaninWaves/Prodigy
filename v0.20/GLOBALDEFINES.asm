; VDP VALUES =========================
VDPCONTROLPORT				    equ 0x00C00004
VDPDATAPORT				        equ 0x00C00000

VDPWRITEPALETTES		        equ 0xF0000000
VDPWRITETILES		                equ 0x40000000
VDPWRITEPE		                	equ 0x40000000
VDPWRITEPLANEA	        	   equ 0x40000003
VDPWRITETILESB                    equ 0x60000000
VDPWRITEPLANEB          	    equ 0x60000002
VDPWRITESPRITE           	    equ 0x60000003
VDPWRITEHSCROLL                equ 0x70000003
VDPWRITEVSCROLL                equ 0x70000013
VDPREADVSCROLL                equ 0x30000013
;=PSG VALUES===============================
PSGCONTROLPORT                   equ 0x00C00011
;GamePad 1 values============================
PADDATAPORT                        equ 0x00A10003
PADBUTTONUP                       equ 0x0
PADBUTTONDOWN                  equ 0x1
PADBUTTONLEFT                     equ 0x2
PADBUTTONRIGHT                  equ 0x3
PADBUTTONA                          equ 0xC
PADBUTTONB                          equ 0x4
PADBUTTONC                          equ 0x5
PADBUTTONSTART                   equ 0xD


;======="Current Screen" data====================
;The idea behind this is to use these to send which screen of the tracker
;we're on, for use with input to change screens, and also for layout drawing.
;=============================================


UNINITIALIZED                  equ 0xFF
MAINSCREEN                    equ 0x02
OPTIONSCREEN                equ 0x03
NOTESCREEN                    equ 0x04
PHRASESCREEN               equ 0x04
CHAINSCREEN                   equ 0x05
SYNTHSCREEN                    equ 0x06
;======RAM Table data=================================
;Organizing Ram map data
;================================================

hblank_counter                      equ 0x00FF0000  ; Long Start of main RAM, this is supposed to be an hblank counter, non-functional
vblank_counter                       equ 0x00FF0004   ; Long vblank counter
CURRENTSCREENDRAWN      equ 0x00FF0008  ;Byte, 0 = no, 1 = yes, used to prevent redrawing of layout, which only needs done once.
CURRENTSCREEN                    equ 0x00FF0010
CURRENTLABELDRAWN          equ 0x00FF000A ; same thing as above, just with labels now.
CURRENTTABLERAM              equ 0x00FF000C
CURRENTTABLESLOT             equ  0x00FF0012  ;Which slot of data table we're on
COLUMNCOORD                     equ 0x00FF0016 ;For determining number of table columns to write in the TextHandler
CURRENTTABLERAMA           equ  0x00FF001A
TABLESLOTMODIFIER             equ 0x00FF001C
TABLESLOTMODDIRECTION   equ 0x00FF0020   ;Word 0xUDLR  1= on  0x0100 would be down for example.
PATTABLESCROLL                  equ 0x00FF0024
PATTABLEPOSITION                equ 0x00FF0028 ;byte describing current position of screen, 0,1,2,3,4/
TABLESLOTPOSITION              equ 0x00FF002C ;byte describing current position of slot, 0,1,2,3,4,5,6,7,8,9 For processing table scroll
TABLESLOTWINDOW              equ 0x00FF0030 ; Mathematical window for governing scroll position.
TABLESLOTWINDOW2            equ 0x00FF0034 ; Mathematical window for governing scroll position.
PLANEBWIPED                        equ 0x00FF0038; Check to see if plane B was wiped before drawing new tables.
CURSORRESET                         equ 0x00FF003A
CURSBOUNDARYMINX             equ 0x00FF0040             ;CURSBOUNDARY describes the cursors movement boundaries, min and max x, y coords
CURSBOUNDARYMAXX            equ 0x00FF0042
CURSBOUNDARYMINY             equ 0x00FF0044
CURSBOUNDARYMAXY            equ 0x00FF0046

MAINCURRENTSLOTDATA   equ 0x00FF0048   ;Data is long word, and is where the current slot's data for the main screen will be stored
CHAINCURRENTSLOTDATA  equ 0x00FF0050 ;Long, current slot data for Chain Entry
MAINCURRENTSLOT              equ 0x00FF0054 ; This is the actual byte number of the value in the current slot, used for reading current chain column
CHAINCURRENTSLOT            equ 0x00FF0056 ; Same as above, but will be used for reading the phrase column
CURRENTSLOTADDRESS       equ 0x00FF005A ; Starting address for the current slot
NOTECURRENTSLOTDATA         equ 0x00FFF004    ;TODO This idea may not work, Having separate storage in ram for Note, instr, ve, cmd.
PCURRENTSLOTADDRESS         equ 0x00FFF008


PATTABLERAM                       equ 0x00FF0060 ; Pattern table starts here, ends at 0x145
CHAINTABLERAM                   equ 0x00FF0146 ; Chain table array starts here, ends at 0xB45
PHRASETABLERAM                 equ 0x00FF0B46 ; Phrase table starts here, ends at 0x8345
SYNTHTABLERAM                    equ 0x00FF8346 ;  Synth table starts here, ends at :0xAB45
SYNTHPSGTABLERAM            equ 0x00FFAB46; PSG synth table starts here, ends at 0xB685


SpecialCursor                         equ 0x00FFF000
ABUTTON                                equ 0x00FFF070  ;A Pressed?
BBUTTON                                 equ 0x00FFF072  ;B Pressed?
CBUTTON                                 equ 0x00FFF074  ;C Pressed?    A, B, C  all 0=no, 1=yes, all bytes
CURSORRAMX                        equ 0x00FFF080
CURSORRAMY                        equ 0x00FFF082
CURSORRAM2X                      equ 0x00FFF084
CURSORRAM3X                      equ 0x00FFF104
CURSORPOSITIONRAM           equ 0x00FFF09A ;y all
CURSORPOSITIONRAM2         equ 0x00FFF098 ;x1
CURSORPOSITIONRAM3         equ 0x00FFF09C ;x2
CURSORPOSITIONRAM4         equ 0x00FFF100 ;x3
CURSORATTRIBUTERAM         equ 0x00FFF0A0
CURSORATTRIBUTERAM2       equ 0x00FFF0A8
CURSORATTRIBUTERAM3        equ 0x00FFF0AC
CHANNELNUMBER                      equ 0x00FFF0B0 ;This stores which sound channel we're using. Should be set on the song screen, once a chain has been chosen.
CRELEASED                                 equ 0x00FFe002 ; This is used to flag whether C has been released yet 0 for no 1 for yes
PRELISTENTOGGLE                    equ  0x00FFe000 ;This flags the prelisten function to run
CURRENTCHAINADDRESS           equ 0x00FFe004  ; Address for the current chain
CURRENTCHAINID                       equ 0x00FFe008 ; Chain number
CURRENTCHAINSLOT                   equ 0x00FFe00C
CURRENTCHAINSLOTLABEL         equ 0x00FFe0B2
CURRENTSPECIALSCREEN            equ 0x00FFe0B4
NOTATIONEDITMODE                    equ 0x00FFe0b6   ;  0 = Notation Edit, 1 = Instrument Edit, 2 = Velocity Edit, 3 = Tracker Command Edit
INSTRCURRENTSLOTDATA            equ 0x00FFe0b8
CURRENTTABLESLOTNOTE            equ 0x00FFe0c0  ;For the cursor handler and slot getters.
NOTESLOTWINDOW                      equ 0x00FFE0C2
NOTESLOTWINDOW2                     equ 0x00FFE0C4
NOTETABLEPOSITION                    equ 0x00FFE0C6
NOTESLOTPOSITION                      equ 0x00FFE0C8
SYNTHCURRENTSLOTDATA           equ 0x00FFD00C
CURRENTSYNTHSLOTADDRESS     equ 0x00FFD000
CURRENTSLOTDIGITS                     equ 0x00FFD004
SYNTHEDITMODE                           equ 0x00FFD008      ;Cursor/Digit handling for synth tables
PLAYBACKMODE                            equ 0x00FFD010     ; 0=Stop, 1=Playback, 2=Live mode.
PLAYBACKCURRENTNOTE             equ 0x00FFD012     ;Current note for current row playback
PLAYBACKNOTEADDRESS             equ 0x00FFD128   ; This saves the row address for tracker playback for the next row
FRAMETARGET                              equ 0x00FFD01A  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED                                equ 0x00FFD020 ;This is the Speed, or the number of frames to wait before updating the playback data
LASTNOTE                                      equ 0x00FFD024 ;This is the last note we have entered on the Note entry Screen, should be wiped every time we leave this screen.
KEYTARGET                                   equ 0x00FFD026 ; This is for input timing, this needs to be equal to vblank_counter to exectude gamepad reads
KEYDELAY                                     equ 0x00FFD02A ; This is for input timing, the number of frames that must elapse in order to read gamepad again
KEYREPEAT                                   equ 0x00FFD02C ; (PLACEHOLDER)This is for input timing, after the delay, how many frames to skip to reread input
STARTRELEASED                           equ 0x00FFD030 ;Button released 0=no, 1=yes
UPRELEASED                                equ 0x00FFD031 ;Button released 0=no, 1=yes
DOWNRELEASED                           equ 0x00FFD032 ;Button released 0=no, 1=yes
LEFTRELEASED                              equ 0x00FFD033 ;Button released 0=no, 1=yes
RIGHTRELEASED                           equ 0x00FFD034 ;Button released 0=no, 1=yes
SYNTHINSTRUMENTNUMBER         equ 0x00FFD038 ;This is the address for the instrument number slot in the Synth Edit screen
INSTRUMENTNUMBERCACHE        equ 0x00FFD03C ;This is holds that last instrument number used in Note Entry.
NOTEINSTRUMENTNUMBERCACHE  equ 0x00FFD03E ;This is holds that last instrument number used in Note Entry for Prelisten
PLAYBACKCURRENTINSTRUMENT equ 0x00FFD040 ;This is the current FM instrument for the playback engine
VELOCITYCURRENTSLOTDATA       equ 0x00FFD042
PLAYBACKCURRENTVELOCITY       equ 0x00FFD044 ;Velocity for Playback
PRELISTENCURRENTVELOCITY      equ 0x00FFD046 ;Velocity for Prelisten
FMALGORITHM                              equ 0x00FFD048 ;Cached algorithm value use to apply Velocity to correct Operators' TL
PLAYBACKCURRENTSONGROW     equ 0x00FFD120 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN            equ 0x00FFD124 ; The current chain for playback
PLAYBACKPHRASECOUNTER        equ 0x00FFD054; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH           equ 0x00FFD058; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER            equ 0x00FFD05A; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH              equ 0x00FFD05E ; 1 means it's time to update the Chain address in the playback engine
CHANNEL1NOPLAY                        equ 0x00FFD05f ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
NOTEDIGITS                                  equ 0x00FFD060 ; This is to be fed into the CURSORUPDATENOTATION routine

PLAYBACKCURRENTINSTRUMENT2 equ 0x00FFD062 ;This is the current FM instrument for the playback engine
PLAYBACKCURRENTVELOCITY2       equ 0x00FFD064 ;Velocity for Playback
PLAYBACKCURRENTSONGROW2     equ 0x00FFD130 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN2            equ 0x00FFD134 ; The current chain for playback
PLAYBACKPHRASECOUNTER2        equ 0x00FFD06e; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH2           equ 0x00FFD06f; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER2            equ 0x00FFD070; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH2              equ 0x00FFD071 ; 1 means it's time to update the Chain address in the playback engine
CHANNEL2NOPLAY                       equ 0x00FFD072 ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE2             equ 0x00FFD074     ;Current note for current row playback
PLAYBACKNOTEADDRESS2             equ 0x00FFD138   ; This saves the row address for tracker playback for the next row
FRAMETARGET2                              equ 0x00FFD07c  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED2                                equ 0x00FFD080 ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENT3 equ 0x00FFD084 ;This is the current FM instrument for the playback engine
PLAYBACKCURRENTVELOCITY3       equ 0x00FFD088 ;Velocity for Playback
PLAYBACKCURRENTSONGROW3     equ 0x00FFD140 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN3            equ 0x00FFD144 ; The current chain for playback
PLAYBACKPHRASECOUNTER3        equ 0x00FFD094; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH3           equ 0x00FFD095; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER3            equ 0x00FFD096; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH3              equ 0x00FFD097 ; 1 means it's time to update the Chain address in the playback engine
CHANNEL3NOPLAY                         equ 0x00FFD098 ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE3             equ 0x00FFD09a     ;Current note for current row playback
PLAYBACKNOTEADDRESS3             equ 0x00FFD148   ; This saves the row address for tracker playback for the next row
FRAMETARGET3                              equ 0x00FFD0a4  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED3                                equ 0x00FFD0a8 ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENT4 equ 0x00FFD0ac ;This is the current FM instrument for the playback engine
PLAYBACKCURRENTVELOCITY4       equ 0x00FFD0b0 ;Velocity for Playback
PLAYBACKCURRENTSONGROW4     equ 0x00FFD150 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN4            equ 0x00FFD154 ; The current chain for playback
PLAYBACKPHRASECOUNTER4        equ 0x00FFD0ba; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH4           equ 0x00FFD0bb; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER4            equ 0x00FFD0bc; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH4              equ 0x00FFD0bd ; 1 means it's time to update the Chain address in the playback engine
CHANNEL4NOPLAY                         equ 0x00FFD0be ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE4             equ 0x00FFD0c0     ;Current note for current row playback
PLAYBACKNOTEADDRESS4             equ 0x00FFD158   ; This saves the row address for tracker playback for the next row
FRAMETARGET4                              equ 0x00FFD0c8  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED4                                equ 0x00FFD0cc ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENT5 equ 0x00FFD0d0 ;This is the current FM instrument for the playback engine
PLAYBACKCURRENTVELOCITY5       equ 0x00FFD0d4 ;Velocity for Playback
PLAYBACKCURRENTSONGROW5     equ 0x00FFD160 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN5            equ 0x00FFD164 ; The current chain for playback
PLAYBACKPHRASECOUNTER5        equ 0x00FFD0de; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH5           equ 0x00FFD0df; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER5            equ 0x00FFD0e0; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH5              equ 0x00FFD0e1 ; 1 means it's time to update the Chain address in the playback engine
CHANNEL5NOPLAY                         equ 0x00FFD0e2 ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE5             equ 0x00FFD0e4     ;Current note for current row playback
PLAYBACKNOTEADDRESS5             equ 0x00FFD168   ; This saves the row address for tracker playback for the next row
FRAMETARGET5                              equ 0x00FFD0ec  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED5                                equ 0x00FFD0f0 ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENT6 equ 0x00FFD0f4 ;This is the current FM instrument for the playback engine
PLAYBACKCURRENTVELOCITY6       equ 0x00FFD0f8 ;Velocity for Playback
PLAYBACKCURRENTSONGROW6     equ 0x00FFD170 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN6            equ 0x00FFD174 ; The current chain for playback
PLAYBACKPHRASECOUNTER6        equ 0x00FFD100; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH6           equ 0x00FFD101; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER6            equ 0x00FFD102; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH6              equ 0x00FFD103 ; 1 means it's time to update the Chain address in the playback engine
CHANNEL6NOPLAY                         equ 0x00FFD104 ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE6             equ 0x00FFD106     ;Current note for current row playback
PLAYBACKNOTEADDRESS6             equ 0x00FFD178   ; This saves the row address for tracker playback for the next row
FRAMETARGET6                              equ 0x00FFD110  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED6                                equ 0x00FFD114 ;This is the Speed, or the number of frames to wait before updating the playback data

SYNTHSCREENPSGFM                 equ 0x00FFD180 ; This is a flag for which synth screen we're on, 0 for FM, 1 for PSG

PSG0ADSRSTATE                          equ 0x00FFD181
PSG0ADSRSTARTCOUNTER      equ 0x00FFD182
PSG0ATTACKTARGET                 equ 0x00FFD186
PSG0DECAYTARGET                   equ 0x00FFD18a
PSG0SUSTAINTARGET                equ 0x00FFD18e
PSG0RELEASETARGET               equ 0x00FFD192
PSG0AttackRate                          equ 0x00FFD196
PSG0OldAttackVolume               equ 0x00FFD198
PSG0MIDDLEVOLUME                  equ 0x00FFD19c
PSG0DecayRate                           equ 0x00FFD1a0
PSG0ReleaseRate                       equ 0x00FFD1a2

PSG1ADSRSTATE                          equ 0x00FFD1a4
PSG1ADSRSTARTCOUNTER      equ 0x00FFD1a6
PSG1ATTACKTARGET                 equ 0x00FFD1aa
PSG1DECAYTARGET                   equ 0x00FFD1ae
PSG1SUSTAINTARGET                equ 0x00FFD1b2
PSG1RELEASETARGET               equ 0x00FFD1b6
PSG1AttackRate                          equ 0x00FFD1ba
PSG1OldAttackVolume               equ 0x00FFD1bc
PSG1MIDDLEVOLUME                  equ 0x00FFD1be
PSG1DecayRate                           equ 0x00FFD1c0
PSG1ReleaseRate                       equ 0x00FFD1c2

psg2ADSRSTATE                          equ 0x00FFD1c4
psg2ADSRSTARTCOUNTER      equ 0x00FFD1c6
psg2ATTACKTARGET                 equ 0x00FFD1ca
psg2DECAYTARGET                   equ 0x00FFD1ce
psg2SUSTAINTARGET                equ 0x00FFD1d2
psg2RELEASETARGET               equ 0x00FFD1d6
psg2AttackRate                          equ 0x00FFD1da
psg2OldAttackVolume               equ 0x00FFD1dc
psg2MIDDLEVOLUME                  equ 0x00FFD1de
psg2DecayRate                           equ 0x00FFD1e0
psg2ReleaseRate                       equ 0x00FFD1e2

psg3ADSRSTATE                          equ 0x00FFD1e4
psg3ADSRSTARTCOUNTER      equ 0x00FFD1e8
psg3ATTACKTARGET                 equ 0x00FFD1ec
psg3DECAYTARGET                   equ 0x00FFD1f0
psg3SUSTAINTARGET                equ 0x00FFD1f4
psg3RELEASETARGET               equ 0x00FFD1f8
psg3AttackRate                          equ 0x00FFD1fc
psg3OldAttackVolume               equ 0x00FFD1fe
psg3MIDDLEVOLUME                  equ 0x00FFD200
psg3DecayRate                           equ 0x00FFD202
psg3ReleaseRate                       equ 0x00FFD204

;PSG PLAYBACK
PLAYBACKCURRENTINSTRUMENT7 equ 0x00FFD206 ;This is the current PSG instrument for the playback engine
PLAYBACKCURRENTVELOCITY7       equ 0x00FFD20a ;Velocity for Playback
PLAYBACKCURRENTSONGROW7     equ 0x00FFD20e ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN7            equ 0x00FFD212 ; The current chain for playback
PLAYBACKPHRASECOUNTER7        equ 0x00FFD216; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH7           equ 0x00FFD218; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER7            equ 0x00FFD21a; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH7              equ 0x00FFD21c ; 1 means it's time to update the Chain address in the playback engine
CHANNEL7NOPLAY                         equ 0x00FFD21e ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE7             equ 0x00FFD220     ;Current note for current row playback
PLAYBACKNOTEADDRESS7             equ 0x00FFD222   ; This saves the row address for tracker playback for the next row
FRAMETARGET7                              equ 0x00FFD226  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED7                                equ 0x00FFD22a ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENT8 equ 0x00FFD22e ;This is the current PSG instrument for the playback engine
PLAYBACKCURRENTVELOCITY8       equ 0x00FFD232 ;Velocity for Playback
PLAYBACKCURRENTSONGROW8     equ 0x00FFD236 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN8            equ 0x00FFD23a ; The current chain for playback
PLAYBACKPHRASECOUNTER8        equ 0x00FFD23e; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH8           equ 0x00FFD242; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER8            equ 0x00FFD244; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH8              equ 0x00FFD246 ; 1 means it's time to update the Chain address in the playback engine
CHANNEL8NOPLAY                         equ 0x00FFD248 ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE8             equ 0x00FFD24a     ;Current note for current row playback
PLAYBACKNOTEADDRESS8             equ 0x00FFD24e   ; This saves the row address for tracker playback for the next row
FRAMETARGET8                              equ 0x00FFD252  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED8                                equ 0x00FFD256 ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENT9 equ 0x00FFD25a ;This is the current PSG instrument for the playback engine
PLAYBACKCURRENTVELOCITY9       equ 0x00FFD25e ;Velocity for Playback
PLAYBACKCURRENTSONGROW9     equ 0x00FFD262 ;The current Song screen row for playback
PLAYBACKCURRENTCHAIN9            equ 0x00FFD266 ; The current chain for playback
PLAYBACKPHRASECOUNTER9        equ 0x00FFD26a; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCH9           equ 0x00FFD26c; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTER9            equ 0x00FFD26e; Chain counter is always going to be 8
PLAYBACKCHAINSWITCH9              equ 0x00FFD270 ; 1 means it's time to update the Chain address in the playback engine
CHANNEL9NOPLAY                         equ 0x00FFD272 ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTE9             equ 0x00FFD274     ;Current note for current row playback
PLAYBACKNOTEADDRESS9             equ 0x00FFD276   ; This saves the row address for tracker playback for the next row
FRAMETARGET9                              equ 0x00FFD27a  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEED9                                equ 0x00FFD27e ;This is the Speed, or the number of frames to wait before updating the playback data

PLAYBACKCURRENTINSTRUMENTa equ 0x00FFD282 ;This is the current PSG instrument for the playback engine
PLAYBACKCURRENTVELOCITYa       equ 0x00FFD286 ;Velocity for Playback
PLAYBACKCURRENTSONGROWa     equ 0x00FFD28a ;The current Song screen row for playback
PLAYBACKCURRENTCHAINa            equ 0x00FFD28e ; The current chain for playback
PLAYBACKPHRASECOUNTERa        equ 0x00FFD292; This counter represents # of rows in a phrase, init in tracker initialization, and set in options.
PLAYBACKPHRASESWITCHa           equ 0x00FFD294; This switch controls updating of the Note Address in the playback engine. Set to 1, means update address.
PLAYBACKCHAINCOUNTERa            equ 0x00FFD296; Chain counter is always going to be 8
PLAYBACKCHAINSWITCHa              equ 0x00FFD298 ; 1 means it's time to update the Chain address in the playback engine
CHANNELaNOPLAY                         equ 0x00FFD29a ; This is a flag set by the STARTSEEK routine, 1 = do not play this channel.
PLAYBACKCURRENTNOTEa             equ 0x00FFD29c     ;Current note for current row playback
PLAYBACKNOTEADDRESSa             equ 0x00FFD300   ; This saves the row address for tracker playback for the next row
FRAMETARGETa                              equ 0x00FFD304  ;This is the target value for the vblankcounter, when this is=vblankcounter update playback
FRAMESPEEDa                                equ 0x00FFD308 ;This is the Speed, or the number of frames to wait before updating the playback data

ARELEASED                                   equ 0x00FFD30C

PLAYBACKCURRENTCOMMAND  equ 0x00FFD30E ;This is the current tracker command for channel 1


COMMANDSCURRENTSLOTDATA  equ  0x00FFD310  ;Data for the Current command slot
CHANNEL1PORTAMENTOSTATE    equ 0x00FFD312 ; State engine for Portamento 0 off 1 up 2 down.
CHANNEL1COMMANDVALUE          equ 0x00FFD314  ;The Command's parameters
CHANNEL1OLDPITCHMSB             equ 0x00FFD316
CHANNEL1OLDPITCHLSB               equ 0x00FFD318
CHANNEL1OLDPortaNoteMSB       equ 0x00FFD31a
CHANNEL1OLDPortaNoteLSB        equ 0x00FFD31c
CurrentYMOCTAVE                            equ 0x00FFD31E ; This is for proper portamento handling.
DestinationYMOCTAVE                     equ 0x00FFD31F ; This is for proper portamento handling.
Channel1ArpeggioFlag                    equ 0x00FFD320 ;Timing flag for the Arp command
Channel1ArpOctave                          equ 0x00FFD322 ;Octave Number for the Arp in use
Channel1ArpBase                             equ 0x00FFD324 ;Base note for Arp command.
DEBUG                                                  equ 0x00FFd400


