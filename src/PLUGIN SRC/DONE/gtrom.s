
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
		.asciiz "GTROM Flasher"

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
.ifdef NSFCART
	cmp #$02
	bne :+
	jmp nsf_cart
.endif

	:
		ldx currbank
		stx $5000
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
					sta $5000
					cmp flashsize
				bcc :-
				sbc flashsize
				sta currbank
				sta $5000
			:
			inc temp1+0
		bne :---
		inc temp1+1
		bne :---
		inc currbank
		dec temp3+1
		dec temp3+1
	bne :----

	lda #0
	sta $5000

	lda flasherror
	jsr send_byte
	rts

direct_prog:
	:
		ldx currbank
		stx $5000
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
		bne :--
		inc currbank
		dec temp3+1
		dec temp3+1
	bne :---

	lda #0
	sta $5000

	lda flasherror
	jsr send_byte
	rts

.ifdef NSFCART
nsf_cart:
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
				jsr dobyte
			:
			inc temp1+0
		bne :--
			inc temp1+1
			lda #$c0
			cmp temp1+1
		bne :--
		lda #$1f
		sta currbank
		dec temp3+1
	bne :---

	lda #0
	sta $c000

	lda flasherror
	jsr send_byte
	rts
.endif

dobyte:
        ldx #$AA
        stx $D555
        ldx #$55
        stx $AAAA
        ldx #$A0
        stx $D555

	ldx currbank
	stx $5000
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
				lda #$20   ; SST39SF040 only
				rts

eraseflash:
        lda #$AA
        sta $D555
        ldx #$55
        stx $AAAA
        ldy #$80
        sty $D555
        sta $D555
        stx $AAAA
        lda #$10
        sta $D555


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