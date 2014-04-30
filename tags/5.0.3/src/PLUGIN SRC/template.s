;04/24/14
;Written by DG
;Version 1.0
;based off TEMPLATE.ASM by KH

	;vectors for standard system calls

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
temp1:	.res 2
temp2:	.res 2
temp3:	.res 2

.segment "TITLE"	;Plugin header that describes what it does
		.asciiz "Template plugin file "
		.asciiz "DG"

.segment "RAMCODE"

;check mirroring

	ldx #$00
	lda #$20
	jsr wr_ppu
	lda #$55
	sta $2007
	lda #$aa
	sta $2007
	lda #$24
	jsr wr_ppu
	lda $2007
	lda $2007
	cmp #$55
	bne horiz_mir
	lda $2007
	cmp #$aa
	bne horiz_mir
	lda #020h
	jsr wr_ppu
	lda #0aah
	sta 2007h
	lda #024h
	jsr wr_ppu
	lda 2007h
	lda 2007h
	cmp #0aah
	bne horz_mir
	inx

horiz_mir:
	txa
	jsr send_byte	;send byte

;dump 32K of PRG data

	lda #$80
	jsr send_byte
	lda #$00
	jsr send_byte	;send size as number of pages
	lda #$01
	jsr send_byte	;send PRG

	ldy #0
	sty temp1+0
	lda #$80
	sta temp1+1	;set pointer to $8000

	ldx #$80	;$80 pages

	:
		lda (temp1),y	;dump 1 byte to the PC
		jsr send_byte
		iny
	bne :-
		inc temp1+1
		dex
	bne :-


; dump 8K of CHR data

	lda #$20	;$20 pages (8K bytes)
	tax
	jsr send_byte
	lda #$00
	jsr send_byte
	lda #$02
	jsr send_byte	;send CHR header

	lda #$00
	sta $2006
	lda #$00
	sta $2006	;set PPU address to $0000
	lda $2007	;read garbage byte
	ldy #0

	:
		lda $2007	;send 1 byte to the PC
		jsr send_byte
		iny
	bne :-
		jsr baton	;send 1 page
		dex
	bne :-

	lda #$00
	jsr send_byte	;send end flag
	lda #$00
	jsr send_byte	;send end flag
	lda #$00
	jsr send_byte	;send end flag
	rts		;done

	;Rest of 1K data filled in automatically by cc65 linker.