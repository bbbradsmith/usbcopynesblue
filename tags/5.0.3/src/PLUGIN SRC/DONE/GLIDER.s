;4/29/14
;Added copynes version detection.
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

	.segment "TITLE"	;Plugin header that describes what it does
	.asciiz "Glider Flasher"

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
	
	lda #0
	sta ferror
	sta currbank
	
	lda #$ff
	sta port+$03      ;output mode
	
	:
		ldx currbank
		jsr selbank
		jsr erasesector
		
		lda currbank
		jsr send_byte
		
		inc currbank
		lda currbank
		cmp temp3+1
	bne :-
	
	lda #0
	sta port+$03     ;input mode
	sta currbank
	:
		ldx currbank
		jsr selbank      ;select desired bank
		lda #$80
		sta temp1+1
		lda #$00
		sta temp1+0      ;start of bank to program
		:
			jsr read_byte
			sta temp2
			ldy #$00
			jsr dobyte
			inc temp1+0
		bne :-
			inc temp1+1
			lda #$c0
			cmp temp1+1
		bne :-			;program all 16K
		inc currbank
		dec temp3+1
	bne :--
	
	lda #$ff
	sta port+$03      ;set to output mode
	lda ferror
	jsr send_byte
	rts
	
	

;temp1 = address, acc =data
dobyte:      
	ldx #$01
	jsr selbank
	ldx #$AA 
	stx $9555      ;5555 = $AA


	ldx #$00
	jsr selbank
	ldx #$55 
	stx $AAAA      ;2AAA = $55
 
	ldx #$01
	jsr selbank
	ldx #$A0 
	stx $9555      ;5555 = $A0

	ldx currbank
	jsr selbank
	lda temp2
	sta (temp1),y    ;byte to program


;wtloop3:     lda 08000h
;	eor 08000h
;	bne wtloop3   ;check toggle
;	lda #000h
;	lda #0f0h
;	sta (temp1),y  ;reset to read mode
;	rts


	
wtloop2:
	lda (temp1),y
	tax
	eor (temp1),y
	and #$40
	beq pgm_done     ;if bit clear, program is done (no toggle)
	txa
	and #$20
	beq wtloop2      ;if error bit clear, not done
	lda (temp1),y
	eor (temp1),y
	beq pgm_done
	lda #$f0
	sta (temp1),y 
	sta ferror       ;we're fucked

pgm_done:    rts 


erasesector:       
	ldx #$01
	jsr selbank
	lda #$aa    ;erase sector command
	sta $9555  ;write to 5555

	ldx #$00
	jsr selbank
	lda #$55
	sta $aaaa  ;write to 2AAA

	ldx #$01
	jsr selbank
	lda #$80
	sta $9555  ;write to 5555

	ldx #$01
	jsr selbank
	lda #$aa
	sta $9555   ;write to 5555

	ldx #$00
	jsr selbank
	lda #$55
	sta $aaaa   ;write to 2AAA

	ldx currbank
	jsr selbank
	lda #$30
	sta $8000   ;write to 5555
	
wtloop:
	lda $8000
	eor $8000
	bne wtloop
	lda #$f0
	sta (temp1),y  ;reset to read mode
	rts


selbank:
	lda port
	ora mappermode
	sta port   ;enable the mapper, disable flash writing  exp0=1
	stx temp4
	asl temp4
	asl temp4
	ldx temp4
	stx $8000
	and flashmode
	sta port   ;disable mapper, enable flash writing   exp0=0
	rts

