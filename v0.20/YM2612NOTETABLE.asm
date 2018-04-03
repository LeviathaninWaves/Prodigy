;The Ym2612 seems to handle notes differently (thank god), I only need one set of note frequencies... but I also need octave data in it's own table.
YMNOTETABLELOW:
    dc.w    0x0000 ;padding
    dc.w    0x01fe  ;Ab
    dc.w    0x021d ;A
    dc.w    0x023d  ;Bb
    dc.w    0x025f ;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x0141  ;C
    dc.w    0x0155 ;C#
    dc.w    0x0169  ;D
    dc.w    0x017e  ;Eb
    dc.w    0x0195  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x01ad ;F
    dc.w    0x01c7  ;F#
    dc.w    0x01e2  ;G

YMNOTETABLEMED:
    dc.w    0x0000 ;padding
    dc.w    0x03fd  ;Ab
    dc.w    0x043a ;A
    dc.w    0x047b  ;Bb
    dc.w    0x04bf ;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x0283  ;C
    dc.w    0x02aa ;C#
    dc.w    0x02d2  ;D
    dc.w    0x02fd  ;Eb
    dc.w    0x032b  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x035b;F
    dc.w    0x038e  ;F#
    dc.w    0x03c4  ;G

YMNOTETABLEHI:
    dc.w    0x0000 ;padding
    dc.w    0x07fb  ;Ab
    dc.w    0x07fc ;A
    dc.w    0x07fd  ;Bb
    dc.w    0x07fe ;B
    dc.w    0x0000  ;Padding for table
    dc.w    0x0507  ;C
    dc.w    0x0554 ;C#
    dc.w    0x05a5  ;D
    dc.w    0x05fb  ;Eb
    dc.w    0x0656  ;E
    dc.w    0x0000  ;Padding for table usage
    dc.w    0x06b6;F
    dc.w    0x071c  ;F#
    dc.w    0x0789 ;G




