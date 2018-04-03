;=============The YM2612 is so complicated that it deserves it's own set of globals========
;=====Z80 Bus Request====================================================
Z80BUSREQ                               equ 0x00A11100 ;write to this address for bus requests, read from it for bus status
Z80BUSON                                    equ 0x100                                              ; The status is in bit 0 - 0 for busy/1 for 68k can access
Z80BUSOFF                                   equ 0x000

Z80RESET                                       equ 0x00A11200
Z80RESETON                                  equ 0x0
Z80RESETOFF                                 equ 0x100
;=====YM2612 Control and Data ports=========================================
YM2612FM1CONTROL               equ  0x00A04000
YM2612FM1DATA                       equ 0x00A04001
YM2612FM2CONTROL                equ 0x00A04002
YM2612FM2DATA                       equ 0x00A04003

;====YM2612 Memory Map================================================
;22H		LFO enable	LFO frequency
;24H	Timer A MSBs
;25H		Timer A LSBs
;26H	Timer B
;27H	Ch3 mode	Reset B	Reset A	Enable B	Enable A	Load B	Load A
;28H	Operator		Channel
;29H
;2AH	DAC
;2BH	DAC en
;30H+		DT1	MUL
;40H+		TL
;50H+	RS		AR
;60H+	AM		D1R
;70H+		D2R
;80H+	D1L	RR
;90H+		SSG-EG
;A0H+	Frequency number LSB
;A4H+		Block	Frequency Number MSB
;A8H+	Ch3 supplementary frequency number
;ACH+		Ch3 supplementary block	Ch3 supplementary frequency number
;B0H+		Feedback	Algorithm
;B4H+	L	R	AMS		FMS

;====d7|d6|d5|d4|d3|d2|d1|d0======*8 bit wide = 1byte========================
LFO                                               equ 0x22 ;bits 0-2 LFO FREQUENCY - bit 1 enable/disable
TIMERAMSB                                  equ 0x24 ; 8 bits
TIMERLSB                                      equ 0x25 ; bits 0-1 TIMER A LSB
TIMERB                                          equ 0x26 ; 8 bits
TIMERSCH36MODE                       equ  0x27 ; bits 0 Load A, 1 Load B, 2 Enable A, 3 Enable B, 4 Reset A, 5 Reset B, 6-7 Channel 3/6 mode.
KEYONOFF                                      equ 0x28 ; bits 0-2  Channel #, 3 unused, bits 4-7 Operator #
DAC1                                              equ 0x2A ; bits 0-7 DAC
DAC2                                              equ 0x2B ; bit 7 DAC enable - if enabled, the Channel 6 FM is replaced with DAC
;========PART 1 and 2========================================
;Detune/Multiple
;=================================
;Op# = Operator number/14, 25, 36 = Channels 1,3/2,4/3,5

Op1DM14                                         equ 0x30 ; bits 0-3 MUL, bits 4-7 DT1
Op1DM25                                        equ 0x31 ; bits 0-3 MUL, bits 4-7 DT1
Op1DM36                                         equ 0x32 ; bits 0-3 MUL, bits 4-7 DT1

Op2DM14                                        equ 0x34 ; bits 0-3 MUL, bits 4-7 DT1
Op2DM25                                         equ 0x35 ; bits 0-3 MUL, bits 4-7 DT1
Op2DM36                                         equ 0x36 ; bits 0-3 MUL, bits 4-7 DT1

Op3DM14                                         equ 0x38 ; bits 0-3 MUL, bits 4-7 DT1
Op3DM25                                         equ 0x39 ; bits 0-3 MUL, bits 4-7 DT1
Op3DM36                                         equ 0x3a ; bits 0-3 MUL, bits 4-7 DT1

Op4DM14                                         equ 0x3c ; bits 0-3 MUL, bits 4-7 DT1
Op4DM25                                         equ 0x3d ; bits 0-3 MUL, bits 4-7 DT1
Op4DM36                                         equ 0x3e ; bits 0-3 MUL, bits 4-7 DT1
;=======================================
; Total Level
;==============================
Op1TL14                                            equ 0x40 ;bits 0-6 Total Level
Op1TL25                                            equ 0x41 ;bits 0-6 Total Level
Op1TL36                                            equ 0x42 ;bits 0-6 Total Level

Op2TL14                                            equ 0x44 ;bits 0-6 Total Level
Op2TL25                                            equ 0x45 ;bits 0-6 Total Level
Op2TL36                                            equ 0x46 ;bits 0-6 Total Level

Op3TL14                                            equ 0x48 ;bits 0-6 Total Level
Op3TL25                                            equ 0x49 ;bits 0-6 Total Level
Op3TL36                                            equ 0x4a ;bits 0-6 Total Level

Op4TL14                                            equ 0x4c ;bits 0-6 Total Level
Op4TL25                                            equ 0x4d ;bits 0-6 Total Level
Op4TL36                                            equ 0x4e ;bits 0-6 Total Level
;======================================
; Rate Scaling, Attack Rate
;===================
Op1RSAR14                                           equ 0x50 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op1RSAR25                                           equ 0x51 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op1RSAR36                                           equ 0x52 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling

Op2RSAR14                                           equ 0x54 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op2RSAR25                                           equ 0x55 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op2RSAR36                                           equ 0x56 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling

Op3RSAR14                                           equ 0x58 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op3RSAR25                                           equ 0x59 ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op3RSAR36                                           equ 0x5a ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling

Op4RSAR14                                           equ 0x5c ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op4RSAR25                                           equ 0x5d ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling
Op4RSAR36                                           equ 0x5e ;bits 0-4 is the Attack Rate, bits 6 and 7 is the Rate Scaling

;========================================================================
; First Decay Rate, Amplitude Modulation
;==============================
Op11DRAM14                                       equ 0x60 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op11DRAM25                                       equ 0x61 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op11DRAM36                                       equ 0x62 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation

Op21DRAM14                                       equ 0x64 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op21DRAM25                                       equ 0x65 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op21DRAM36                                       equ 0x66 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation

Op31DRAM14                                       equ 0x68 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op31DRAM25                                       equ 0x69 ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op31DRAM36                                       equ 0x6a ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation

Op41DRAM14                                       equ 0x6c ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op41DRAM25                                       equ 0x6d ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation
Op41DRAM36                                       equ 0x6e ; bits 0-4 is the First Decay Rate, bit 7 is the Amplitude Modulation

;======================================
;Secondary Decay Rate
;================
Op12DR14                                              equ 0x70 ; bits 0-4 is the Secondary Decay Rate
Op12DR25                                              equ 0x71 ; bits 0-4 is the Secondary Decay Rate
Op12DR36                                              equ 0x72 ; bits 0-4 is the Secondary Decay Rate

Op22DR14                                              equ 0x74 ; bits 0-4 is the Secondary Decay Rate
Op22DR25                                              equ 0x75 ; bits 0-4 is the Secondary Decay Rate
Op22DR36                                              equ 0x76 ; bits 0-4 is the Secondary Decay Rate

Op32DR14                                              equ 0x78 ; bits 0-4 is the Secondary Decay Rate
Op32DR25                                              equ 0x79 ; bits 0-4 is the Secondary Decay Rate
Op32DR36                                              equ 0x7a ; bits 0-4 is the Secondary Decay Rate

Op42DR14                                              equ 0x7c ; bits 0-4 is the Secondary Decay Rate
Op42DR25                                              equ 0x7d ; bits 0-4 is the Secondary Decay Rate
Op42DR36                                              equ 0x7e ; bits 0-4 is the Secondary Decay Rate

;=============================
; Secondary Amplitude, Release Rate
;==========================
Op1D1LRR14                                         equ 0x80 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op1D1LRR25                                         equ 0x81 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op1D1LRR36                                         equ 0x82 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude

Op2D1LRR14                                         equ 0x84 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op2D1LRR25                                         equ 0x85 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op2D1LRR36                                         equ 0x86 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude

Op3D1LRR14                                         equ 0x88 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op3D1LRR25                                         equ 0x89 ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op3D1LRR36                                         equ 0x8a ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude

Op4D1LRR14                                         equ 0x8c ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op4D1LRR25                                         equ 0x8d ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude
Op4D1LRR36                                         equ 0x8e ; bits 0-3 is the Release Rate, 4-7 is the D1L, or Secondary Amplitude

;=============================
; SSG-EG
;=========
Op1SSGEG14                                          equ 0x90 ; bits 0-3 SSG-EG
Op1SSGEG25                                          equ 0x91 ; bits 0-3 SSG-EG
Op1SSGEG36                                          equ 0x92 ; bits 0-3 SSG-EG

Op2SSGEG14                                          equ 0x94 ; bits 0-3 SSG-EG
Op2SSGEG25                                          equ 0x95 ; bits 0-3 SSG-EG
Op2SSGEG36                                          equ 0x96 ; bits 0-3 SSG-EG

Op3SSGEG14                                          equ 0x98 ; bits 0-3 SSG-EG
Op3SSGEG25                                          equ 0x99 ; bits 0-3 SSG-EG
Op3SSGEG36                                          equ 0x9a ; bits 0-3 SSG-EG

Op4SSGEG14                                          equ 0x9c ; bits 0-3 SSG-EG
Op4SSGEG25                                          equ 0x9d ; bits 0-3 SSG-EG
Op4SSGEG36                                          equ 0x9e ; bits 0-3 SSG-EG

;=================
; Frequency number LSB
;=================
CH14FREQLSB                                     equ 0xa0 ; bits 0-7 Frequency LSB
CH25FREQLSB                                      equ 0xa1 ; bits 0-7 Frequency LSB
CH36FREQLSB                                      equ 0xa2 ; bits 0-7 Frequency LSB


;=============================
; Frequency number MSB, Octave "Block"
;=============================
CH14FREQMSB                                  equ 0xa4 ; bits 0-2 Frequency MSB, bits 3-5 give the Octave Block
CH25FREQMSB                                  equ 0xa5 ; bits 0-2 Frequency MSB, bits 3-5 give the Octave Block
CH36FREQMSB                                  equ 0xa6 ; bits 0-2 Frequency MSB, bits 3-5 give the Octave Block


;======================================
; Channel 3 Special Mode, Operator Frequencies MSB
;======================================
CH3OP2FREQMSB                           equ 0xa8 ; bits 0-7 Frequency MSB
CH3OP3FREQMSB                           equ 0xa9 ; bits 0-7 Frequency MSB
CH3OP4FREQMSB                            equ 0xaa   ; bits 0-7 Frequency MSB

;==================================================
; Channel 3 Special Mode, Operator Frequencies LSB and Octave Block
;==================================================
CH3OP2FREQLSB                              equ 0xac ; bits 0-2 Frequency LSB, bits 3-5 Octave Block
CH3OP3FREQLSB                              equ 0xad ; bits 0-2 Frequency LSB, bits 3-5 Octave Block
CH3OP4FREQLSB                              equ 0xae ; bits 0-2 Frequency LSB, bits 3-5 Octave Block

;================
; Feedback, Algorithm
;==============
CH14FBAL                                             equ 0xb0 ; bits 0-2 Operator Algorithm, bits 3-5 op1 Feedback
CH25FBAL                                             equ 0xb1 ; bits 0-2 Operator Algorithm, bits 3-5 op1 Feedback
CH36FBAL                                             equ 0xb2 ; bits 0-2 Operator Algorithm, bits 3-5 op1 Feedback

;==================
; Stereo, LFO Sensitivity

CH14STLFOS                                          equ 0xb4 ; bits 0-1 FM Sensitivity, bits 3-5 AM Sensitivity bit 6 Pan Right, bit 7 Pan Left (STEREO)
CH25STLFOS                                          equ 0xb5 ; bits 0-1 FM Sensitivity, bits 3-5 AM Sensitivity bit 6 Pan Right, bit 7 Pan Left (STEREO)
CH36STLFOS                                          equ 0xb6 ; bits 0-1 FM Sensitivity, bits 3-5 AM Sensitivity bit 6 Pan Right, bit 7 Pan Left (STEREO)
