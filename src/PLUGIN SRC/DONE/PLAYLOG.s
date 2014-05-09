
.import read_byte
.import port

.segment "ZEROPAGE"
temp1:       .res 2
temp2:       .res 2
temp3:       .res 2
temp4:       .res 2

.segment "TITLE"
		.asciiz "NSF Log Player (any)"

.segment "RAMCODE"

	lda #0
	sta $2000
	sta $2001
	sta port+$03	;set to input mode
	
	; timer setup borrowed from RDUMP1.ASM
	lda #$85
	sta port+$04
	lda #$74
	sta port+$05	;timer value
	lda #$40
	sta port+$0b	;timer interrupts continuous
	sta port+$0e	;enable interrupts
	
	
read_loop:
	jsr read_byte
	cmp #$c0	;VRC7
	bcc :+
		and #$3f
		sta $9010
		jsr read_byte
		sta $9030
		jmp read_loop
	:
	cmp #$a8	;NES APU
	bcc :+
		sbc #$a8
		tay
		jsr read_byte
		sta $4000,y
		jmp read_loop
	:
	cmp #$a5	;VRC6 $B00x
	bcc :+
		sbc #$a5
		tay
		jsr read_byte
		sta $b000,y
		jmp read_loop
	:
	cmp #$a2	;VRC6 $A00x
	bcc :+
		sbc #$a2
		tay
		jsr read_byte
		sta $a000,y
		jmp read_loop
	:
	cmp #$9e	;VRC6 $900x
	bcc :+
		sbc #$9e
		tay
		jsr read_byte
		sta $9000,y
		jmp read_loop
	:
	cmp #$9d	;namco 163 $F800
	bne :+
		jsr read_byte
		sta $f800
		jmp read_loop
	:
	cmp #$9c	;namco 163	$4800
	bne :+
		jsr read_byte
		sta $480a
		jmp read_loop
	:
	cmp #$02
	bne :+
		jsr read_byte
		jmp do_write
	:
	cmp #$01
	bne do_write
		:
			bit port+$0d	;Wait for timer interrupt trigger
		bvc :-
		lda port+$04	;Acknowledge the interrupt. (It remains disabled till acknowledged. :) )
		jmp read_loop
	
do_write:
	sta $01
	jsr read_byte
	sta $00
	jsr read_byte
	ldy #0
	sta ($00),y
	jmp read_loop