;04/29/14
;RET-CUFROM - used by Glider
;Written by DG
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
temp2:		.res 1
currbank:	.res 1
mappermode:	.res 1
flashmode:	.res 1

.segment "TITLE"	;Plugin header that describes what it does
		.asciiz "RET-CUFROM - 128K rom"
		.asciiz "32K chr ram, 8K wram"

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

	lda port
	and flashmode
	sta port	;disable the mapper, enable flash writing exp0=0
	ldx #$f0
	stx $8000	;reset the flash chip
	ora mappermode
	sta port	;enable the mapper, disable flash writing  exp0=1
	lda #$00
	sta currbank


	lda #$00	;Hard-wired vertical mirroring
	jsr send_byte	;send byte

;dump 128K of PRG data

	lda #$00
	jsr send_byte
	lda #$02
	jsr send_byte	;send size as number of pages
	lda #$01
	jsr send_byte	;send PRG

	:
		jsr selbank
		ldy #0
		sty temp1+0
		lda #$80
		sta temp1+1	;set pointer to $8000
		ldx #$40	;$40 pages
		:
			lda (temp1),y	;dump 1 byte to the PC
			jsr send_byte
			iny
		bne :-
			inc temp1+1
			dex
		bne :-
		inc currbank
		lda currbank
		cmp #$08
	bne :--

	lda #$07
	jsr send_byte
	lda #$09
	jsr send_byte
	lda #$05
	jsr send_byte	;Send NES2.0 info with 8K Non-battery WRAM, and 32K Non-battery Chr ram

	lda #$00
	jsr send_byte	;send end flag
	lda #$00
	jsr send_byte	;send end flag
	lda #$00
	jsr send_byte	;send end flag
	rts		;done

	;Rest of 1K data filled in automatically by cc65 linker.

selbank:
	ldx currbank
	stx temp2
	asl temp2
	asl temp2
	ldx temp2
	stx 08000h
	rts