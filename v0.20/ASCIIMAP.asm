ASCIISTART: equ 0x00 ; First ASCII code in table

ASCIIMAP:
    dc.b 0x00   ; SPACE (ASCII code 0x20)
    dc.b 0x01   ; ! Exclamation mark
    dc.b 0x02   ; " Double quotes
    dc.b 0x03   ; # Hash
    dc.b 0x04   ; UNUSED
    dc.b 0x05   ; UNUSED
    dc.b 0x06   ; b flat
    dc.b 0x07   ; ' Single quote
    dc.b 0x08   ; ( Open parenthesis
    dc.b 0x09   ; ) Close parenthesis
    dc.b 0x0A   ; UNUSED
    dc.b 0x0B   ; UNUSED
    dc.b 0x0C   ; , Comma
    dc.b 0x0D   ; - Minus
    dc.b 0x0E   ; . Full stop
    dc.b 0x0F   ; / Slash or divide
    dc.b 0x10   ; 0 Zero
    dc.b 0x11   ; 1 One
    dc.b 0x12   ; 2 Two
    dc.b 0x13   ; 3 Three
    dc.b 0x14   ; 4 Four
    dc.b 0x15   ; 5 Five
    dc.b 0x16   ; 6 Six
    dc.b 0x17   ; 7 Seven
    dc.b 0x18   ; 8 Eight
    dc.b 0x19   ; 9 Nine
    dc.b 0x1A   ; : Colon
    dc.b 0x1B   ; UNUSED
    dc.b 0x1C   ; UNUSED
    dc.b 0x1D   ; UNUSED
    dc.b 0x1E   ; UNUSED
    dc.b 0x1F   ; ? Question mark
    dc.b 0x20   ; @
    dc.b 0x21   ; A
    dc.b 0x22   ; B
    dc.b 0x23   ; C
    dc.b 0x24   ; D
    dc.b 0x25   ; E
    dc.b 0x26   ; F
    dc.b 0x27   ; G
    dc.b 0x28   ; H
    dc.b 0x29   ; I
    dc.b 0x2A   ; J
    dc.b 0x2B   ; K
    dc.b 0x2C   ; L
    dc.b 0x2D   ; M
    dc.b 0x2E   ; N
    dc.b 0x2F   ; O
    dc.b 0x30  ; P
    dc.b 0x31   ; Q
    dc.b 0x32   ; R
    dc.b 0x33   ; S
    dc.b 0x34   ; T
    dc.b 0x35   ; U
    dc.b 0x36   ; V
    dc.b 0x37   ; W
    dc.b 0x38   ; X
    dc.b 0x39   ; Y
    dc.b 0x3A  ; Z (ASCII code 0x5A)
    dc.b 0x40  ; [
    dc.b 0x41  ; \
    dc.b 0x42  ; ]
    dc.b 0x43  ; ^
    dc.b 0x44  ; _
    ;dc.b 0x45

    nop         0,8

    dc.l        PATTERNTABLES
;PATTABLESTART:  equ #0x00
PATTERNTABLES:
    dc.b       0x00
    dc.b       0x01
    dc.b       0x02
    dc.b       0x03
    dc.b       0x04
    dc.b       0x05
    dc.b       0x06
    dc.b       0x07
    dc.b       0x08
    dc.b       0x09
    dc.b       0x0A
    dc.b       0x0B
    dc.b       0x0C
    dc.b       0x0D
    dc.b       0x0E
    dc.b       0x0F
    dc.b       0x10
    dc.b       0x11
    dc.b       0x12
    dc.b       0x13
    dc.b       0x14
    dc.b       0x15
    dc.b       0x16
    dc.b       0x17
    dc.b       0x18
    dc.b       0x19
    dc.b       0x1A
    dc.b       0x1B
    dc.b       0x1C
    dc.b       0x1D
    dc.b       0x1E
    dc.b       0x1F
    dc.b       0x20
    dc.b       0x21
    dc.b       0x22
    dc.b       0x23
    dc.b       0x24
    dc.b       0x25
    dc.b       0x26
    dc.b       0x27
    dc.b       0x28
    dc.b       0x29
    dc.b       0x2A
    dc.b       0x2B
    dc.b       0x2C
    dc.b       0x2D
    dc.b       0x2E
    dc.b       0x2F
    dc.b       0x30
    dc.b       0x31
    dc.b       0x32
    dc.b       0x33
    dc.b       0x34
    dc.b       0x35
    dc.b       0x36
    dc.b       0x37
    dc.b       0x38
    dc.b       0x39
    dc.b       0x3A
    dc.b       0x3B
    dc.b       0x3C
    dc.b       0x3D
    dc.b       0x3E
    dc.b       0x3F
    dc.b       0x40
    dc.b       0x41
    dc.b       0x42
    dc.b       0x43
    dc.b       0x44
    dc.b       0x45
    dc.b       0x46
    dc.b       0x47
    dc.b       0x48
    dc.b       0x49
    dc.b       0x4A
    dc.b       0x4B
    dc.b       0x4C
    dc.b       0x4D
    dc.b       0x4E
    dc.b       0x4F
    dc.b       0x50
    dc.b       0x51
    dc.b       0x52
    dc.b       0x53
    dc.b       0x54
    dc.b       0x55
    dc.b       0x56
    dc.b       0x57
    dc.b       0x58
    dc.b       0x59
    dc.b       0x5A
    dc.b       0x5B
    dc.b       0x5C
    dc.b       0x5D
    dc.b       0x5E
    dc.b       0x5F
    dc.b       0x60
    dc.b       0x61
    dc.b       0x62
    dc.b       0x63
    dc.b       0x64
    dc.b       0x65
    dc.b       0x66
    dc.b       0x67
    dc.b       0x68
    dc.b       0x69
    dc.b       0x6A
    dc.b       0x6B
    dc.b       0x6C
    dc.b       0x6D
    dc.b       0x6E
    dc.b       0x6F
    dc.b       0x70
    dc.b       0x71
    dc.b       0x72
    dc.b       0x73
    dc.b       0x74
    dc.b       0x75
    dc.b       0x76
    dc.b       0x77
    dc.b       0x78
    dc.b       0x79
    dc.b       0x7A
    dc.b       0x7B
    dc.b       0x7C
    dc.b       0x7D
    dc.b       0x7E
    dc.b       0x7F
    dc.b       0x80
    dc.b       0x81
    dc.b       0x82
    dc.b       0x83
    dc.b       0x84
    dc.b       0x85
    dc.b       0x86
    dc.b       0x87
    dc.b       0x88
    dc.b       0x89
    dc.b       0x8A
    dc.b       0x8B
    dc.b       0x8C
    dc.b       0x8D
    dc.b       0x8E
    dc.b       0x8F
    dc.b       0x90
    dc.b       0x91
    dc.b       0x92
    dc.b       0x93
    dc.b       0x94
    dc.b       0x95
    dc.b       0x96
    dc.b       0x97
    dc.b       0x98
    dc.b       0x99
    dc.b       0x9A
    dc.b       0x9B
    dc.b       0x9C
    dc.b       0x9D
    dc.b       0x9E
    dc.b       0x9F
    dc.b       0xA0
    dc.b       0xA1
    dc.b       0xA2
    dc.b       0xA3
    dc.b       0xA4
    dc.b       0xA5
    dc.b       0xA6
    dc.b       0xA7
    dc.b       0xA8
    dc.b       0xA9
    dc.b       0xAA
    dc.b       0xAB
    dc.b       0xAC
    dc.b       0xAD
    dc.b       0xAE
    dc.b       0xAF
    dc.b       0xB0
    dc.b       0xB1
    dc.b       0xB2
    dc.b       0xB3
    dc.b       0xB4
    dc.b       0xB5
    dc.b       0xB6
    dc.b       0xB7
    dc.b       0xB8
    dc.b       0xB9
    dc.b       0xBA
    dc.b       0xBB
    dc.b       0xBC
    dc.b       0xBD
    dc.b       0xBE
    dc.b       0xBF
    dc.b       0xC0
    dc.b       0xC1
    dc.b       0xC2
    dc.b       0xC3
    dc.b       0xC4
    dc.b       0xC5
    dc.b       0xC6
    dc.b       0xC7
    dc.b       0xC8
    dc.b       0xC9
    dc.b       0xCA
    dc.b       0xCB
    dc.b       0xCC
    dc.b       0xCD
    dc.b       0xCE
    dc.b       0xCF
    dc.b       0xD0
    dc.b       0xD1
    dc.b       0xD2
    dc.b       0xD3
    dc.b       0xD4
    dc.b       0xD5
    dc.b       0xD6
    dc.b       0xD7
    dc.b       0xD8
    dc.b       0xD9
    dc.b       0xDA
    dc.b       0xDB
    dc.b       0xDC
    dc.b       0xDD
    dc.b       0xDE
    dc.b       0xDF
    dc.b       0xE0
    dc.b       0xE1
    dc.b       0xE2
    dc.b       0xE3
    dc.b       0xE4
    dc.b       0xE5
PATTERNTABLESEND

PTSIZEB:                        equ (PATTERNEDITOREND-PATTERNEDITOR)    ;Size in Bytes
PTSIZEW:                       equ (PTSIZEB/2)                                                     ;Size in Word
PTSIZEL:                        equ (PTSIZEB/4)                                                   ;Size in Long
PTLINEWIDTH:              equ 0x01                                                             ;1 byte for each line (x)
PTLINEHEIGHT:             equ 0x1E                                                             ;30 lines total (y)
PTDIMENSIONS:           equ 0x011E                                                         ; Dimensions (W/H)
PTVRAM:                         EQU 0X000                                        ;Start Address for the font in memory
PTID:                                  EQU (PTVRAM/32)                             ;I.D. of first font tile.
