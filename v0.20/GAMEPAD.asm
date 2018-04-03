READPAD:

    move.l              #0x0, d7                              ;Clear d0
    move.b             PADDATAPORT, d7            ;Read upper byte from the pad 1's data port
    rol.w                 #0x8, d7                              ;Move that byte to the upper byte of d0
    move.b              #0x40, PADDATAPORT      ;write bit 7 to data port (bit 7 is 0x40 in hex) to tell it we want to read the lower byte
    move.b             PADDATAPORT, d7            ;Read lower byte from data port
    move.b             #0x00, PADDATAPORT     ;Turn off bit 7

    rts
