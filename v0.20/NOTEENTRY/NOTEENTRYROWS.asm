;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exported throught MappyWin 1423
;; with help of MDPPY 0.1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NOTEENTRYROWS1:

	dc.l	NOTEENTRYROWS_maps


NOTEENTRYROWS_maps:
	dc.l	NOTEENTRYROWS

NOTEENTRYROWS:
; line 0
	dc.w	0x80
	dc.w	0x90
	dc.w	0x90
; line 1
	dc.w	0x80
	dc.w	0x90
	dc.w	0x91
; line 2
	dc.w	0x80
	dc.w	0x90
	dc.w	0x92
; line 3
	dc.w	0x80
	dc.w	0x90
	dc.w	0x93
; line 4
	dc.w	0x80
	dc.w	0x90
	dc.w	0x94
; line 5
	dc.w	0x80
	dc.w	0x90
	dc.w	0x95
; line 6
	dc.w	0x80
	dc.w	0x90
	dc.w	0x96
; line 7
	dc.w	0x80
	dc.w	0x90
	dc.w	0x97
; line 8
	dc.w	0x80
	dc.w	0x90
	dc.w	0x98
; line 9
	dc.w	0x80
	dc.w	0x90
	dc.w	0x99
; line 10
	dc.w	0x80
	dc.w	0x90
	dc.w	0xA1
; line 11
	dc.w	0x80
	dc.w	0x90
	dc.w	0xA2
; line 12
	dc.w	0x80
	dc.w	0x90
	dc.w	0xA3
; line 13
	dc.w	0x80
	dc.w	0x90
	dc.w	0xA4
; line 14
	dc.w	0x80
	dc.w	0x90
	dc.w	0xA5
; line 15
	dc.w	0x80
	dc.w	0x90
	dc.w	0xA6
; line 16
	dc.w	0x80
	dc.w	0x91
	dc.w	0x90
; line 17
	dc.w	0x80
	dc.w	0x91
	dc.w	0x91
; line 18
	dc.w	0x80
	dc.w	0x91
	dc.w	0x92
; line 19
	dc.w	0x80
	dc.w	0x91
	dc.w	0x93
; line 20
	dc.w	0x80
	dc.w	0x91
	dc.w	0x94
; line 21
	dc.w	0x80
	dc.w	0x91
	dc.w	0x95
; line 22
	dc.w	0x80
	dc.w	0x91
	dc.w	0x96
; line 23
	dc.w	0x80
	dc.w	0x91
	dc.w	0x97
; line 24
	dc.w	0x80
	dc.w	0x91
	dc.w	0x98
; line 25
	dc.w	0x80
	dc.w	0x91
	dc.w	0x99
; line 26
	dc.w	0x80
	dc.w	0x91
	dc.w	0xA1
; line 27
	dc.w	0x80
	dc.w	0x91
	dc.w	0xA2
; line 28
	dc.w	0x80
	dc.w	0x91
	dc.w	0xA3
; line 29
	dc.w	0x80
	dc.w	0x91
	dc.w	0xA4
; line 30
	dc.w	0x80
	dc.w	0x91
	dc.w	0xA5
; line 31
	dc.w	0x80
	dc.w	0x91
	dc.w	0xA6
; line 32
	dc.w	0x80
	dc.w	0x80
	dc.w	0x80
; line 33
	dc.w	0x80
	dc.w	0x80
	dc.w	0x80
; line 34
	dc.w	0x80
	dc.w	0x80
	dc.w	0x80
; line 35
	dc.w	0x80
	dc.w	0x80
	dc.w	0x80
NOTEENTRYROWSEND                           ;YMDJ Pattern editor end address.

NERSIZEB:                        equ (NOTEENTRYROWSEND-NOTEENTRYROWS)    ;Size in Bytes
NERSIZEW:                       equ (NERSIZEB/2)                                                     ;Size in Word
NERSIZEL:                        equ (NERSIZEB/4)                                                   ;Size in Long
NERLINEWIDTH:              equ 0x02                                                             ;40 words for each line (x)
NERLINEHEIGHT:             equ 0x1f                                                              ;28 lines total (y)
NERDIMENSIONS:           equ 0x281C                                                         ; Dimensions (W/H)
NERVRAM:       EQU 0X000                                        ;Start Address
NERID:              EQU (NERVRAM/32)                             ;I.D. of first font tile.
