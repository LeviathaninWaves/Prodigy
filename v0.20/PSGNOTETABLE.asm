;This is a lookup table for the PSG, all these values are word, and are converted using a formula to convert real note frequencies in hz, to
; PSG frequency data for it's tone registers. This has been a bitch to create and will likely be a bitch to work with.

OCTAVE0:
    dc.w    0x0000 ;padding
    dc.w    0x086a  ;Ab
    dc.w    0x0fe1 ;A
    dc.w    0x0eff  ;Bb
    dc.w    0x0e27;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x0d5c  ;C
    dc.w    0x0c9c ;C#
    dc.w    0x0be7  ;D
    dc.w    0x0b3c  ;Eb
    dc.w    0x0a9a  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0a02 ;F
    dc.w    0x0972  ;F#
    dc.w    0x08ea  ;G
OCTAVE1:
    dc.w    0x0000 ;padding
    dc.w    0x086a  ;Ab
    dc.w    0x07f1 ;A
    dc.w    0x077f  ;Bb
    dc.w    0x0713;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x0d5c  ;C
    dc.w    0x0c9c ;C#
    dc.w    0x0be7  ;D
    dc.w    0x0b3c  ;Eb
    dc.w    0x0a9a  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0a02 ;F
    dc.w    0x0972  ;F#
    dc.w    0x08ea  ;G

OCTAVE2:
    dc.w    0x0000 ;padding
    dc.w    0x0435  ;Ab
    dc.w    0x03f8 ;A
    dc.w    0x03bf  ;Bb
    dc.w    0x0389;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x06ae  ;C
    dc.w    0x064e  ;C#
    dc.w    0x05f3  ;D
    dc.w    0x059e  ;Eb
    dc.w    0x054d  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0501 ;F
    dc.w    0x04b9  ;F#
    dc.w    0x0475  ;G

OCTAVE3:
    dc.w    0x0000 ;padding
    dc.w    0x021a  ;Ab
    dc.w    0x01fc ;A
    dc.w    0x01df  ;Bb
    dc.w    0x01c4;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x0357  ;C
    dc.w    0x0327  ;C#
    dc.w    0x02f9  ;D
    dc.w    0x02cf  ;Eb
    dc.w    0x02a6  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0280 ;F
    dc.w    0x025c  ;F#
    dc.w    0x023a  ;G


OCTAVE4:
    dc.w    0x0000 ;padding
    dc.w    0x010d  ;Ab
    dc.w    0x00fe ;A
    dc.w    0x00ef  ;Bb
    dc.w    0x00e2;B
    dc.w    0x0000 ;padding
    dc.w    0x01ab  ;C
    dc.w    0x0193  ;C#
    dc.w    0x017c  ;D
    dc.w    0x0167 ;Eb
    dc.w    0x0153  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0140 ;F
    dc.w    0x012e ;F#
    dc.w    0x011d  ;G

OCTAVE5:
    dc.w    0x0000 ;padding
    dc.w    0x0086 ;Ab
    dc.w    0x007f ;A
    dc.w    0x0077  ;Bb
    dc.w    0x0072;B
    dc.w    0x0000 ;padding
    dc.w    0x00d5  ;C
    dc.w    0x00c9  ;C#
    dc.w    0x00be  ;D
    dc.w    0x00b3 ;Eb
    dc.w    0x00a9  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x00a0 ;F
    dc.w    0x0097 ;F#
    dc.w    0x008e  ;G

OCTAVE6:
    dc.w    0x0000 ;padding
    dc.w    0x0043 ;Ab
    dc.w    0x003f ;A
    dc.w    0x003b  ;Bb
    dc.w    0x0038;B
    dc.w    0x0000 ;padding
    dc.w    0x006a  ;C
    dc.w    0x0064  ;C#
    dc.w    0x005f  ;D
    dc.w    0x0059 ;Eb
    dc.w    0x0054  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0050 ;F
    dc.w    0x004b ;F#
    dc.w    0x0047  ;G

OCTAVE7:
    dc.w    0x0000 ;padding
    dc.w    0x0021 ;Ab
    dc.w    0x001f ;A
    dc.w    0x001d  ;Bb
    dc.w    0x001c;B
    dc.w    0x0000 ;padding
    dc.w    0x0035  ;C
    dc.w    0x0032  ;C#
    dc.w    0x002f  ;D
    dc.w    0x002c ;Eb
    dc.w    0x002a  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0028 ;F
    dc.w    0x0025 ;F#
    dc.w    0x0023  ;G

OCTAVE8:
    dc.w    0x0000 ;padding
    dc.w    0x0010 ;Ab
    dc.w    0x000f ;A
    dc.w    0x000e  ;Bb
    dc.w    0x000e;B
    dc.w    0x0000 ;padding
    dc.w    0x001a  ;C
    dc.w    0x0019  ;C#
    dc.w    0x0017  ;D
    dc.w    0x0016 ;Eb
    dc.w    0x0015  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x0014 ;F
    dc.w    0x0012 ;F#
    dc.w    0x0011  ;G
