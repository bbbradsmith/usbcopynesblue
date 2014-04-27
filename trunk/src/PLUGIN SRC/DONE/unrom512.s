
.import send_byte
.import read_byte

.segment "ZEROPAGE"
temp1:       .res 2
temp2:       .res 2
temp3:       .res 2
temp4:       .res 2
flasherror:      .res 1
currbank:    .res 1
flashsize:   .res 1
romsize:     .res 1

.segment "TITLE"
		.asciiz "UNROM 512 Flasher"

.segment "RAMCODE"

	lda #$f0
	sta $8000

	jsr read_byte
	sta temp3+1

	lda #0
	sta flasherror
	sta currbank
	sta temp1+0

	jsr softwareid
	sta temp3+1
	jsr send_byte
	lda temp3+1
	sta flashsize
	cmp #0
	bne :+
		txa
		jsr send_byte
		tya
		jsr send_byte
		rts
	:
	jsr read_byte
	sta romsize
	sta temp3+1
	jsr eraseflash
	jsr send_byte

	lda romsize
	cmp flashsize
	beq direct_prog

	:
		ldx currbank
		stx $c000
		lda #$80
		sta temp1+1
		lda #0
		sta temp1+0
		:
			jsr read_byte
			cmp #$FF
			beq :++
				sta temp2
				:
					ldy #0
					jsr dobyte
					clc
					lda currbank
					adc romsize
					sta currbank
					sta $c000
					cmp flashsize
				bcc :-
				sbc flashsize
				sta currbank
				sta $c000
			:
			inc temp1+0
		bne :---
		inc temp1+1
		lda #$c0
		cmp temp1+1
		bne :---
		inc currbank
		dec temp3+1
	bne :----

	lda #0
	sta $c000

	lda flasherror
	jsr send_byte
	rts

direct_prog:
	:
		ldx currbank
		stx $c000
		lda #$80
		sta temp1+1
		lda #0
		sta temp1+0
		:
			jsr read_byte
			cmp #$FF
			beq :+
				sta temp2
				ldy #0
				jsr dobyte
			:
			inc temp1+0
		bne :--
		inc temp1+1
		lda #$c0
		cmp temp1+1
		bne :--
		inc currbank
		dec temp3+1
	bne :---

	lda #0
	sta $c000

	lda flasherror
	jsr send_byte
	rts

dobyte:
	ldx #1
	stx $c000
	lda #$aa
	sta $9555

	sty $c000
	lda #$55
	sta $aaaa

	stx $c000
	ldx #$a0
	stx $9555

	ldx currbank
	stx $c000
	lda temp2
	sta (temp1),y

	:
		lda (temp1),y
		cmp (temp1),y
	bne :-
	cmp temp2
	beq :+
		lda #$F0
		sta flasherror
	:
	rts

softwareid:
	ldx #1
	stx $c000
	lda #$aa
	sta $9555

	ldy #0
	sty $c000
	lda #$55
	sta $aaaa

	stx $c000
	lda #$90
	sta $9555

	ldx $8000
	ldy $8001

	lda #$F0
	sta $8000

	cpx #$bf
	bne :+++
		cpy #$b5
		beq :++
			cpy #$b6
			beq :+
				cpy #$b7
				bne :+++
				lda #$20
				rts
			:
			lda #$10
			rts
		:
		lda #$08
		rts
	:
	lda #0
	rts

eraseflash:
	ldx #1
	stx $c000
	lda #$aa
	sta $9555

	ldy #0
	sty $c000
	lda #$55
	sta $aaaa

	stx $c000
	lda #$80
	sta $9555

	lda #$aa
	sta $9555

	sty $c000
	lda #$55
	sta $aaaa

	stx $c000
	lda #$10
	sta $9555

	:
		lda $9555
		cmp $9555
	bne :-
	lda $9555
	cmp #$FF
	beq :+
		lda #$FF
		rts
	:
	lda temp3+1
	rts