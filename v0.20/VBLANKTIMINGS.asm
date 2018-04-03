WAITVBLANKSTART:

    move.w                              VDPCONTROLPORT, d0      ;Read VDP Status Register to word
    andi.w                                #0x0008, d0                       ;And operation to bit 4, result from status register
    bne                                      WAITVBLANKSTART   ;Branch if not equal (wait)
    rts

WAITVBLANKEND:

    move.w                              VDPCONTROLPORT, d0      ;Read VDP Status Register to word
    andi.w                                #0x0008, d0                       ;And operation to bit 4, result from status register
    beq                                     WAITVBLANKEND   ;Branch if not equal (wait)
    rts

WaitFrames:
	; d0 - Number of frames to wait

	move.l  vblank_counter, d1 ; Get start vblank count

	@Wait:
	move.l  vblank_counter, d2 ; Get end vblank count
	sub.l  d1, d2             ; Calc delta, result in d2
	cmp.l   d0, d2             ; Compare with num frames
	bge     @End               ; Branch to end if greater or equal to num frames
	bra.w     @Wait              ; Try again

	@End:

    rts
