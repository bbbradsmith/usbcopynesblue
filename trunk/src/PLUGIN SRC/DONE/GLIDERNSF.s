;4/30/14
;Optimized flashing routine with major speed boosts.
;DG
;4/29/14
;Added copynes version detection. (Parallel port copynes wires EXP0 to port+$00, D2
;				  USB copynes wires EXP0 to port+$00, D3
;				  At least Parallel port has a difference from USB
;				  in the value written to port+$02, (Data direction register)
;				  that can be detected, specifically D5 is OUT on parallel port
;                                 and IN on USB.)
;DG
;11/13/13
;Reverse engineered from glider.bin (was not open sourced. :( )
;RE'd by DG
;ORIGINAL SOURCE:
;03/05/06
;Written by KH
;Version 1.0
	
	;vectors for standard system calls

.import port
.import send_byte
.import baton
.import chk_vram
.import chk_wram
.import wr_ppu
.import read_byte
.import init_crc
.import do_crc
.import finish_crc
.import crc0
.import crc1
.import crc2
.import crc3

.segment "ZEROPAGE"	;Temp variables
temp1:		.res 2
temp2:		.res 2
temp3:		.res 2
temp4:		.res 1
ferror:		.res 1
currbank:	.res 1
mappermode:	.res 1
flashmode:	.res 1
romsize:	.res 1

	.segment "TITLE"	;Plugin header that describes what it does
	.asciiz "Glider NSF Flasher"

.macro bankwrite bank
	ldx bank
	ora mappermode
	sta port	;enable the mapper, disable flash writing  exp0=1
	stx $8000
	and flashmode
	sta port	;disable mapper, enable flash writing  exp0=0
.endmacro

.macro flashwrite bank, address, data
	bankwrite bank
	ldx #data
	stx address
.endmacro

.segment "RAMCODE"

	lda #$08
	sta mappermode
	lda #$f7
	sta flashmode
	lda port+$02
	and #$20
	beq :+			;USB copynes uses D6 as /RXE in output mode.
		lda #$04	;Parallel port copynes uses D6 as read handshake in input mode.
		sta mappermode
		lda #$fb
		sta flashmode	;Parallel port copynes has its EXP0 line shifted to D2.
	:

	lda #$f0
	sta $8000       ;reset flash ROM
	
	lda #0
	sta port+$03       ;input mode
	
	jsr read_byte
	sta temp3+1      ;receive number of sectors to erase
	sta romsize
	
	lda #0
	sta ferror
	sta currbank
	
	lda #$ff
	sta port+$03      ;output mode
	
	:
		jsr erasesector
		
		lda currbank
		jsr send_byte
		
		inc currbank
		lda currbank
		cmp temp3+1
	bne :-
	asl temp3+1
	asl temp3+1	;pre-shift 
	
	lda #0
	sta port+$03     ;input mode
	sta currbank
	:
		lda #$80
		sta temp1+1
		lda #$00
		sta temp1+0      ;start of bank to program
		:
			jsr read_byte
			sta temp2
			inc temp2
			beq :+
				jsr dobyte
			:
			inc temp1+0
		bne :--
			inc temp1+1
			lda #$c0
			cmp temp1+1
		bne :--			;program all 16K
		lda #$1C
		sta currbank
		dec temp3+1
		dec temp3+1
		dec temp3+1
		dec temp3+1
	bne :---
	
	lda #$ff
	sta port+$03      ;set to output mode
	lda ferror
	jsr send_byte
	lda port
	bankwrite #$00
	rts
	
	

dobyte:      
	lda port
	flashwrite #$04, $9555, $AA
	flashwrite #$00, $AAAA, $55
	flashwrite #$04, $9555, $A0
	bankwrite currbank
	dec temp2	;It was incremented earlier to check if the received byte was $FF.
	lda temp2
	ldy #$00
	sta (temp1),y    ;byte to program
	:
		lda (temp1),y
		tax
		eor (temp1),y
		and #$40
		beq pgm_done     ;if bit clear, program is done (no toggle)
		txa
		and #$20
	beq :-      ;if error bit clear, not done
	lda (temp1),y
	eor (temp1),y
	beq pgm_done
	lda #$f0
	sta (temp1),y 
	sta ferror       ;we're fucked

pgm_done:    rts 


erasesector:
	lda #$08
	cmp romsize
	bne :+
		lda currbank
		beq :+
		rts		;We were asked to erase the entire rom, so we did so.
	:			;and are now skipping the operation on the remaining banks.
	lda port
	flashwrite #$04, $9555, $AA
	flashwrite #$00, $AAAA, $55
	flashwrite #$04, $9555, $80
	flashwrite #$04, $9555, $AA
	flashwrite #$00, $AAAA, $55

	ldx #$08
	cpx romsize
	beq :++
		flashwrite currbank, $8000, $30
		:
			lda $8000
			eor $8000
		bne :-
		lda #$f0
		sta (temp1),y  ;reset to read mode
		rts
	:

	flashwrite #$04, $9555, $10	;otherwise, chip erase the entire chip at once.
	:
		lda $9555
		eor $9555
	bne :-
	lda #$f0
	sta (temp1),y  ;reset to read mode
	rts

