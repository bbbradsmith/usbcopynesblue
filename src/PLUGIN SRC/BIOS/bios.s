.out ""
.ifdef PARALLELPORT
	.out "Assembling Parallel port version of the bios"
.else
	.out "Assembling USB version of the bios"
.endif


;protocol:   
;
;3ah  : read CPU space
;xxxx : start address
;yy   : # pages
;a3h  : confirm
;<sends data>

;4bh  : write CPU space
;xxxx : start address
;yyyy : # pages
;b4h  : confirm
;<store data bytes

;5ch  : read PPU space
;xxxx : start address
;yyyy : # of pages
;c5h  : confirm
;<sends data>

;6dh  : write PPU space
;xxxx : start address
;yyyy : # of pages
;d6h  : confirm
;<stores data bytes>

;7eh  : execute code
;xxxx : start address
;e7h  : confirm

;from above code, NES can send its own data packets.  format:

;8fh    : incoming data packet
;nn     : bitwise:
;    0 - 0 = Horiz mirror, 1 = Vert mirror
;    1 - 0 = no WRAM, 1= WRAM
;    2 - 0 = no 4 screen, 1 = 4 screen
;    3 - 0 = normal, 1 = CPU ROM only
;mm     : Mapper #
;xxxxxx : # of bytes of CPU
;xxxxxx : # of bytes of PPU
;f8h    : confirm
;nn...  : data sent



;MAJOR CHANGES FOR USB
;  all lcd code removed
;  handshaking changed, handshaking pinouts changed
;  bios vers 4





.segment "ZEROPAGE"

bc:
c:		.res 1
b:		.res 1

joy_pad:	.res 1
;80 = A
;40 = B
;20 = select
;10 = start
;08 = U 
;04 = D
;02 = L
;01 = R

old_but:	.res 1
char_ctr:	.res 1
temp:		.res 1
baton_c:	.res 1
tempbank:	.res 1
mtype:		.res 1
addl:		.res 1
addh:		.res 1
npage:		.res 1
mtype2:		.res 1
temp_x:		.res 1

temp1:
temp1_lo:	.res 1
temp1_hi:	.res 1
temp2:
temp2_lo:	.res 1
temp2_hi:	.res 1

temp_byte:	.res 1
type_4016:	.res 1

;nsf header info:

load:		.res 2
init:		.res 2
play:		.res 2
len:		.res 3
banks:		.res 8
initsng:	.res 2

.ifndef PARALLELPORT
nmicounter:	.res 1
irqcounter:	.res 1
.endif

crc0		:= $80
crc1		:= $81
crc2		:= $82
crc3		:= $83

s_init		:= $01fc
s_play		:= $01fe

;was $4800, some mappers use this location.
port		:= $4a00

topostack	:= $ec
realstack	:= $f4

;1 frame = 262 scanlines
;
;a) rendering:
; 1 garbage scanline
; 240 visible
; 1 unusable
;
;b) vblank:
; 20 usable
;

render		:= 27507	;# of cycles during rendering phase
vblank		:= 2273		;# of cycles during vblank phase

; 1ed - instruction counter for vblank
; 1ee - PPU 2005 1st write
; 1ef - PPU 2005 2nd write
;
; 1f0 - emu temp
; 1f1 - cycle count low
; 1f2 - cycle count high
; 1f3 - stack level 1
; 1f4 - stack level 0
; 1f5 - Acc
; 1f6 - X reg
; 1f7 - Y reg
; 1f8 - flags
; 1f9 - stack pointer
; 1fa - pcl
; 1fb - pch
; 1fc - instruction
; 1fd - address low
; 1fe - address high
; 1ff - rts

;ppustat bits:
;
;0 - if we read 2007 before or not
;1 - interrupt enable (when set, NMIs will be performed)
;2 - PPU increment quantity
;3 - rendering enabled
;4 - sprites enabled
;5 - PPU enable (when set, we will worry about the PPU)
;6 - which load of 2005/2006 we are on
;7 - NMI enable (1 = yes, 0 = no)

icount		:=$01ed		;# of instructions to perform in vblank
p2005		:=$01ee		;PPU scrolling registers
emutemp		:=$01f0		
cyclecount	:=$01f1		;2 bytes to hold the current cycle count
         ;	:=$01f2		;stack level 1
         ;	:=$01f3		;stack level 0
reg_a		:=$01f5
reg_x		:=$01f6
reg_y		:=$01f7
reg_p		:=$01f8
reg_s		:=$01f9
reg_pcl		:=$01fa
reg_pch		:=$01fb
ramloc		:=$01fc


controlbus	:=port+$00   ;port B data
         ;        port+$01   ;port A data
         ;        port+$02   ;port B direction register
         ;        port+$03   ;port A direction register
         ;        port+$04   ;timer 1 low byte
         ;        port+$05   ;timer 1 high byte
brkpt		:=port+$06   ;timer 1 period low (store breakpoint lo here!)
         ;        port+$07   ;timer 1 period high (store breakpoint hi here!)
         ;        port+$08   ;timer 2 low byte
         ;        port+$09   ;timer 2 high byte
ppustat		:=port+$0a   ;shift register (store PPU status here!)
nothreg1	:=port+$0b   ;mode control reg 1 (use bit 6 only!)
p2006lo		:=port+$0c   ;mode control reg 2 (2006 low)
         ;        port+$0d   ;IRQ status
p2006hi		:=port+$0e   ;use bits 0-6 (2006 high)
         ;        port+$0f   ;port A mirror

.segment "STACK"
.segment "RAM"

.segment "MAIN"

	rts

start:
	sei
	cld
	ldx #$f8
	txs
.ifdef PARALLELPORT
	jsr set_in	;input mode

	ldx #$00
	stx type_4016
	stx $4016

	lda #$20
	bit port+$01
	beq :+
		lda #$02
		sta type_4016
		sta $4016
	:
.endif
	jsr init_port
	lda port+$00
	sta temp_byte
.ifdef PARALLELPORT
	jsr init_lcd
	jsr load_chars
	jsr init_ppu
	jsr lcd_clr
	lda #0		;message 0: "welcome message"
	jsr sho_msg
.else
	jsr init_ppu
.endif

	ldx #7
	:
		lda ram_dat,x
		sta $1f8,x
		dex
	bpl :-

	lda port+$00
	and #$40
	beq :+
.ifdef PARALLELPORT
		lda #3		;message 3: "Playing Game"
		jsr sho_msg
.endif
		jmp $1f8
	:
	
	ldx #$fb
	txs
	ldx #0
	txa
	:
		cmp #<(temp_byte)	;don't clobber temp_byte
		beq :+
		cmp #<(char_ctr)	;don't clobber char_ctr
		beq :+
			sta 0, x
		:
	.BYTE	$9D, $FC, $00	;absolute write
		sta $200, x
		sta $300, x
		sta $400, x
		sta $500, x
		sta $600, x
		sta $700, x
		dex
	bne :--


	ldx #0
	ldy #0
	:
		lda #$4c
		sta $200,x
		inx
		lda vec_tab,y
		iny
		sta $200,x
		inx
		lda vec_tab,y
		iny
		sta $200,x
		inx
		cmp #$ff
	bne :-

	main:
.ifdef PARALLELPORT
		jsr set_out
		jsr lcd_clr
		lda #4
		jsr sho_msg	;message 4: "Waiting for Host"
.endif
		jsr set_in	;set 6522 input mode

		jsr read_byte	;get mode byte
		cmp #$3a
		beq mode_1	;read CPU space
		cmp #$4b
		beq mode_2	;write CPU space
		cmp #$5c
		beq mde_3	;read PPU space
		cmp #$6d
		beq mde_4	;write PPU space
		cmp #$7e
		beq mde_5	;execute code
		cmp #$8e
		beq mde_6	;load nsf
		cmp #$9f
		beq mde_7	;run nsf
		cmp #$a0
		beq mde_8	;run emulator
		cmp #$a1
		beq mde_9	;send identifier string
		cmp #$a2
		beq mde_10	;send version #
	jmp main

mde_3:	jmp mode_3
mde_4:	jmp mode_4
mde_5:	jmp mode_5
mde_6:	jmp loadnsf
mde_7:	jmp runnsf
mde_8:	lda temp_byte
	sta emutemp
	jmp main2	;run the emulator
mde_9:	jmp identify
mde_10:	jmp identify2

;read CPU space
mode_1:	jsr read_pack
	lda mtype2
	cmp #$a3
	bne main
	jsr set_out	;set 6522 output mode
.ifdef PARALLELPORT
	lda #5
	jsr sho_msg	;message 5: "Transferring..."
.endif
	ldy #0
	:
		lda (addl),y
		jsr write_byte
		iny
	bne :-
		inc addh
.ifdef PARALLELPORT
		jsr baton
.endif
		dec npage
	bne :-
.ifdef PARALLELPORT
	lda #6		;message 6: "Transfer Done!"
	jsr sho_msg
.endif
	lda #120
	jsr wait_vbl
	jmp main

;write CPU space
mode_2:
	jsr read_pack
	lda mtype2
	cmp #$b4
	beq :+

j_main:	jmp main
	:
.ifdef PARALLELPORT
	;lda #5
	;jsr sho_msg
.endif
	ldy #0
	:
		jsr read_byte
		sta (addl),y
		iny
	bne :-
		inc addh
.ifdef PARALLELPORT
		;jsr baton
.endif
		dec npage
	bne :-
.ifdef PARALLELPORT
	jsr set_out
	lda #$80
	jsr lcd_ins
	lda $400
	jsr sho_hex
	lda $401
	jsr sho_hex

;	lda #6
;	jsr sho_msg
.endif
	lda #6
	jsr wait_vbl
	jmp main
	
;run code
mode_5:
	jsr read_pack
	lda mtype2
	cmp #$e7
	bne j_main
	jsr set_out
.ifdef PARALLELPORT
	lda #5
	jsr sho_msg
.endif
	lda #>(back_rd-1)
	pha
	lda #<(back_rd-1)
	pha
	jmp (addl)

back_rd:
.ifdef PARALLELPORT
	lda #6
	jsr sho_msg
.endif
	lda #60
	jsr wait_vbl
	jmp main

mode_3:
mode_4:	jmp main

;---------------------------------------
;NSF player stuff

loadnsf:
	lda #$1f
	sta temp2

	:
		ldx #$10
		lda #0
		sta temp1_lo
		lda #$80
		sta temp1_hi
		lda temp2
		sta $5ff8
		ldy #0
		tya

		:
			sta (temp1),y
			iny
		bne :-
			inc temp1_hi
			dex
		bne :-
		dec temp2
	bpl :--

	ldy #0

	:
		jsr read_byte
		sta load,y
		iny
		cpy #19
	bne :-			;read header
	jsr work_bank

	lda load
	sta temp1_lo
	lda load+1
	and #$0f
	ora #$80
	sta temp1_hi		;adjust to get offset into bank
	ldy #0

	:
		jsr read_byte
		sta (temp1),y
		inc temp1_lo
		bne :+			;load 256 bytes
			inc temp1_hi
			lda #$90
			cmp temp1_hi
		bne :+			;load 4K banks
			inc temp2
			lda temp2
			sta $5ff8
			lda #$80
			sta temp1_hi	;inc bank and reset pointers

		:
		dec len
		lda #$ff
		cmp len
	bne :--
		dec len+1
		cmp len+1
	bne :--
		dec len+2
		cmp len+2
	bne :--			;dec length counter

	ldx #3

	:
		lda init,x
		sta s_init,x
		dex
	bpl :-		;save vectors

replaynsf:
	lda banks
	sta $5ff8
	lda #$60
	sta temp1_hi
	ldx #$20
	lda #0
	sta temp1_lo
	tay

	:
		sta (temp1),y
		iny
	bne :-
		inc temp1_hi
		dex
	bne :-

	ldx #0
	:
		lda init_sound,x
		sta $4000,x
		inx
		cpx #$14
	bne :-

	lda #$0f
	sta $4015

.ifdef PARALLELPORT
	jsr set_out
	lda #7
	jsr sho_msg
	lda initsng+1
	jsr sho_hex
	lda #8
	jsr sho_msg
	lda initsng
	jsr sho_hex
.endif

	ldy initsng+1

	ldx #0
	txa

	:
	.byte	$9d, $01, $00	;don't overwrite $00
	.byte	$9d, $fc, $00	; sta $00fc,x (absolute!!! ZP does not work)
		sta $200,x
		sta $300,x
		sta $400,x
		sta $500,x
		sta $600,x
		sta $700,x
		dex
	bne :-

	lda #>(back_rd2-1)
	pha
	lda #<(back_rd2-1)
	pha
	tya
	clc
	sbc #0
	tax
	tay
	jmp (s_init)

back_rd2:
	lda #$85
	sta port+$04					;timer value
	lda #$74
	sta port+$05	;timer value			;timer value
	lda #$40
	sta port+$0b	;timer interrupts continuous	;timer mode
	sta port+$0e	;enable interrupts		;timer enable

:	bit port+$0d
	bvc :-		;wait for timer 1
	lda #>(back_rd3-1)
	pha
	lda #<(back_rd3-1)
	pha
	jmp (s_play)	;JSR play routine

back_rd3:
	lda port+$04					;reset irq flag
	jmp :-

init_sound:
	.byte 0,0,0,0
	.byte 0,0,0,0
	.byte 0,0,0,0
	.byte $10,0,0,0
	.byte 0,0,0,0

runnsf:
	ldy #0
	:
		jsr read_byte
		sta banks,y
		iny
		cpy #10
	bne :-
	jsr work_bank
	lda banks
	sta $5ff8
	jmp replaynsf

work_bank:
	ldx #7
	lda #0
	sta $5ff7

	:
		ora banks, x	;check to see if all bank bytes are $00
		pha
		txa
		sta $5ff8, x	;and set banks up to 0,1,2,3,4,5,6,7
		pla
		dex
	bpl :-
	cmp #0
	beq :++

		ldx #7
		:
			lda banks,x
			sta $5ff8,x
			dex
		bpl :-
		lda #0
		sta $5ff8
		sta temp2
		rts	;if the banks were non-zero, load them up
	:
	lda load+1
	lsr a
	lsr a
	lsr a
	lsr a
	and #$07
	sta $5ff8
	sta temp2	;start loading at proper bank if non-banked
	rts

;--------------------------------------------------------------------------
;Main bulk of the emulator code goes here
;--------------------------------------------------------------------------
;The first 256 bytes of the emulator code needs to be aligned to a page
;boundary.
.align 256

	jmp main2

mode_indx:
	jsr pcfetch7	;clear carry here
	adc reg_x
	jsr indydo
	jmp fixaddy

mode_indy:
	jsr pcfetch
	jsr indydo
	jmp indycon

mode_zerx:
	jsr pcfetch7	;clear carry here
	adc reg_x
	jmp zpcon

mode_zery:
	jsr pcfetch7	;clear carry here
	adc reg_y
	jmp zpcon

mode_zero:
	jsr pcfetch

zpcon:
	sta ramloc+1
	lda #$00
	sta ramloc+2
	jmp idone

mode_absx:
	jsr pcfetch4	;not a whole lot I can do.. only 2 stack levels
	jsr pcfetch5
	jsr pcfetch6
	lda reg_x
	jmp absocon

mode_absy:
	jsr pcfetch4
	jsr pcfetch5
	jsr pcfetch6

indycon:
	lda reg_y

absocon:
	adc ramloc+1	;carry cleared in pcfetch6
	sta ramloc+1
	bcc fixaddy
	jsr pagecross
	bcs fixaddy	;carry will always be set

mode_abso:
	jsr pcfetch4
	jsr pcfetch5
	jsr pcfetch6

fixaddy:
	jmp fixaddy2

mode_immd:
	jsr pcfetch
	ldx #$60
	stx ramloc+2
.byte	$2c		;skip with a BIT

mode_impl:
	lda #$60
	sta ramloc+1
	tya
	jmp execute

mode_nop3:
	jsr pcfetch
mode_nop2:
	jsr pcfetch
	jmp edone

mode_op08:
	lda reg_p
	ora #$30
	jmp m08cont

mode_op48:
	lda reg_a

m08cont:
	jsr safepush
	jmp edone

mode_op78:
	lda #$04
	ora reg_p
	bne m78cont

mode_op58:
	lda #$fb
	and reg_p
	jmp m78cont

mode_op28:
	jsr safepop
	ora #$30	;turn on B and unimplemented flags

m78cont:
	sta reg_p
	jmp edone

mode_op68:
	jsr safepop
	sta reg_a
	lda #<(reg_a)
	sta ramloc+1
	lda #>(reg_a)
	sta ramloc+2
	lda #$ad
	jmp execute

mode_op20:
	jsr pcfetch
	tay
	lda reg_pch
	jsr safepush
	lda reg_pcl
	jsr safepush
	jmp m4ccont

mode_op4c:
	jsr pcfetch
	tay

m4ccont:
	jsr pcfetch
	sta reg_pch
	sty reg_pcl
	jmp edone

mode_op00:
	jmp op_00
mode_op40:
	jmp op_40
mode_op60:
	jmp op_60
mode_op6c:
	jmp op_6c
mode_op9a:
	jmp op_9a
mode_opba:
	jmp op_ba
mode_halt:
	jmp ehalt

mode_bran:
	tya
;--- end of critical 256 byte code block

	rol a
	rol a
	rol a
	and #$03
	tax
	tya
	and #$20
	bne rels

relc:
	lda reltab,x
	bit reg_p
	beq dorel
	bne norel

reltab:
	.byte $80, $40, $01, $02

rels:
	lda reltab,x
	bit reg_p
	bne dorel

norel:
	jsr pcfetch
	jmp edone

dorel:
	jsr pagecross2
	jsr pcfetch
	bpl relpos
	clc
	adc reg_pcl
	sta reg_pcl
	bcs reldone
	dec reg_pch
	
reldone:
	jmp edone

relpos:
	clc
	adc reg_pcl
	sta reg_pcl
	bcc reldone
	inc reg_pch
	jsr pagecross2
	jmp edone

indydo:
	tax
	lda 0,x
	sta ramloc+1
	lda 1,x
	sta ramloc+2	;pull address from zeropage
	clc
	rts

;-------------------------
;opcode routines, one per

op_00:
	jsr pcfetch
	lda reg_pch
	jsr safepush
	lda reg_pcl
	jsr safepush
	lda reg_p
	ora #$24	;set unimplemented and I flag
	and #$ef	;clear break flag
	jsr safepush
	lda $fffe
	sta reg_pcl
	lda $ffff
	sta reg_pch
	jmp edone

op_40:
	jsr safepop
	ora #$30
	sta reg_p
	jsr safepop
	sta reg_pcl
	jsr safepop
	sta reg_pch
	jmp edone

op_60:
	jsr safepop
	sta reg_pcl
	jsr safepop
	sta reg_pch
	jsr pcfetch2	;do increment
	jmp edone

op_6c:
	jsr pcfetch4	;do address mode
	jsr pcfetch5
	jsr pcfetch6
	jsr ramloc
	sta reg_pcl
	inc ramloc+1
	jsr ramloc
	sta reg_pch
	jmp edone

op_9a:
	lda reg_x
	sta reg_s
	lda #topostack
	cmp reg_s
	bcs :+
		lda #topostack
		sta reg_s
	:
	jmp edone

op_ba:
	lda reg_s
	sta reg_x
	lda #<(reg_x)
	sta ramloc+1
	lda #>(reg_x)
	sta ramloc+2
	lda #$ae
	jmp execute	;ldx absolute

fixaddy2:
	lda ramloc+2	;filter out bad read/writes
	bmi idone	;if in ROM, we're done automatically
	cmp #$01
	beq stackstuff
	cmp #$09
	beq stackstuff	;Somebody could otherwise make life difficult. :)
	and #$f8
	cmp #$48
	beq portwrite	;port chip at 4800-4fff
	cmp #$40
	beq chksprite
	and #$e0
	cmp #$20
	bne idone
	jmp ppuaddy

portwrite:
	lda #$42	;force bogus addresses to 4200-42ff
	sta ramloc+2
	bne idone

chksprite:
	lda ramloc+1
	cmp #$14
	bne idone
	lda ramloc+2
	cmp #$40
	bne idone
	dec cyclecount+1
	dec cyclecount+1	;subtract 512 cycles for sprites (close 'nuff)
	jsr ppuwait
	bne idone

stackstuff:
	lda #topostack
	cmp ramloc+1
	bcs idone
	lda #topostack^$ff
	adc ramloc+1
	sta ramloc+1	;wrap in page 1 if needed

idone:
	tya
	and #$e3
	ora #$0c	;force all opcodes to be absolute

execute:
	sta ramloc+0
	lda reg_p
	tax
	ora #$04	;no IRQs allowed
	pha
	txa
	and #$04
	sta reg_p	;blow away all the bits in P except I
	ldx reg_x
	ldy reg_y
	lda reg_a
	plp
	jsr ramloc
	php
	sta reg_a
	sty reg_y
	stx reg_x
	pla
	and #$fb	;strip IRQ flag
	ora reg_p
	sta reg_p	;OR new bits on

edone:
.ifdef PARALLELPORT
	lda port+$01	;check if byte waiting to be read(/RXE=0)
	cmp #$aa
.else
	lda port+$00	;read control bus
	and #$20	;isolate /RXE D5
.endif
	beq ebreak	;byte waiting to be read

	bit p2006hi	;p2206hi bit6->V
	bvc continue	;if v clear, goto continue	run code was $40 to break
	lda #$00	;if v set, done send code 0	run code was $C0 once
	beq emul8done

continue:
	lda reg_pcl	;see if breakpoint hit
	cmp brkpt+0
	bne :+
		lda reg_pch
		cmp brkpt+1
	bne :+
		lda #$02	;breakpoint hit
		bne emul8done
	:
	jmp emul8	;nope, continue executing

ehalt:
	lda #$01	;HLT hit, report same

emul8done:
	jsr write_byte2
	jmp mainx

;break encountered from the PC
ebreak:
.ifndef PARALLELPORT
	jsr read_byte	;NEW read the break byte that was waiting
.endif
	lda #$03
	jsr write_byte2
	jmp mainx

;------------------------------------------------------------------
;emulate code

;port chip usage
go2brk:
	lda #$40	;run to breakpoint
	.byte $2c

emulate:
	lda #$c0	;run 1 instruction
	sta p2006hi

.ifdef PARALLELPORT
;RAM chip usage
;emulate:     lda #040h
;             ora p2006hi
;             sta p2006hi
;             bne emul8
;
;go2brk:      lda #0bfh
;             and p2006hi
;             sta p2006hi
.endif

emul8:
	bit $2002
	bpl noblank
	lda p2005+0
	sta $2005	;reload the scroll registers
	lda p2005+1
	sta $2005
	lda p2006hi
	sta $2006
	lda p2006lo
	sta $2006
	lda icount
	and #$3f
	sta $2000

noblank:
	lda #$ad
	sta ramloc+0	;LDA abs
	lda #$60
	sta ramloc+3	;RTS
	lda reg_pcl
	sta ramloc+1
	lda reg_pch
	sta ramloc+2	;current PC
	jsr ramloc	;get opcode
	tay
	lda cyclecount+0
	sec
	sbc cyctab,y
	sta cyclecount+0
	bcs continuem
	dec cyclecount+1

continuem:
	bit cyclecount+1
	bmi doppu
	inc reg_pcl
	bne :+
		inc reg_pch	;inc PC
	:
	lda amode,y
	sta ramloc+1
	lda #>(mode_indx)
	sta ramloc+2
	jmp (ramloc+1)

doppu:
	bit nothreg1
	bvs goblank
	lda icount
	and #$7f
	sta icount	;clear vblank flag
	lda #$40
	sta nothreg1	;put us in rendering
	clc
	lda cyclecount+0
	adc #<(render)
	sta cyclecount+0
	lda cyclecount+1
	adc #>(render)
	sta cyclecount+1	;load cycle count for rendering
	bne continuem

goblank:
	lda #$00
	sta nothreg1	;bit 6 holds PPU mode (0 = vbl, 1 = rendering)
	lda icount
	ora #$80
	sta icount	;set vblank flag
	lda cyclecount+0
	adc #<(vblank)
	sta cyclecount+0
	lda cyclecount+1
	adc #>(vblank)
	sta cyclecount+1	;load cycle count for rendering
	lda #$02
	bit ppustat
	bpl continuem	;do we need an NMI?
	beq continuem	;if NMIs disabled, don't do them at all
	lda reg_pch
	jsr safepush
	lda reg_pcl
	jsr safepush
	lda reg_p
	ora #$30
	jsr safepush
	lda $fffa	;get new address
	sta reg_pcl
	lda $fffb
	sta reg_pch
	jmp noblank

;PPU is about to be read from / written to 
ppuaddy:
	lda ramloc+1	;PPU at 2000
	and #$07
	cmp #$07
	beq ppu2007
	tax
	beq ppu2000
	dex
	beq ppu2001
	dex
	beq ppu2002
	cpx #$03	;2005
	beq ppu2005
	cpx #$04	;2006
	beq ppu2006
	jsr ppuwait	;for 2003, 2004 wait for PPU to be ready first
	jmp idone

ppu2000:
	jmp ppu2000x
ppu2001:
	jmp ppu2001x
ppu2002:
	jmp ppu2002x
ppu2005:
	jmp ppu2005x
ppu2006:
	jmp ppu2006x
ppu2007:
	jmp ppu2007x

.macro	sax addr
	.byte $8f
	.word addr
.endmacro

.macro	lax addr
	.byte $af
	.word addr
.endmacro

;----------------------------------------------------------------------
;PPU register 2000h

ppu2000x:
	lda #<(ramloc+0)
	sta ramloc+1
	lda #>(ramloc+0)
	sta ramloc+2
	tya
	and #$e3
	ora #$0c	;force all opcodes to be absolute
	sta ramloc+0
	ldx reg_x
	ldy reg_y
	lda reg_a
	jsr ramloc	;execute formed instruction
	sta reg_a
	sty reg_y
	stx reg_x
	lda ramloc+0
	ldx #$7f
	sax $2000	;write byte to $2000 , without bit 7
	ora #$7b	;turn the other 6 bits on for the AND coming up
	tax
	lda ppustat
	ora #$84	;make sure bits ripple thru
	sax ppustat
	lda ramloc+0
	and #$3f
	sta ramloc+0
	lda icount	;copy $2000 register over
	and #$c0
	ora ramloc+0
	sta icount
	jmp edone

;----------------------------------------------------------------------
;PPU register 2001h
ppu2001x:
	lda #<(ramloc+0)
	sta ramloc+1
	lda #>(ramloc+0)
	sta ramloc+2
	tya
	and #$e3
	ora #$0c	;force all opcodes to be absolute
	sta ramloc+0
	ldx reg_x
	ldy reg_y
	lda reg_a
	jsr ramloc	;execute formed instruction
	sta reg_a
	sty reg_y
	stx reg_x
	lda ramloc+0
	sta $2001
	ora #$e7	;set all but the 2 bits of interest
	tax
	lda ppustat
	ora #$18
	sax ppustat

p2002w:
	jmp edone

;----------------------------------------------------------------------
;PPU register 2002h
ppu2002x:
	tya
	and #$20
	beq p2002w
	lda #<(icount)
	sta ramloc+1
	lda #>(icount)
	sta ramloc+2
	lda #$bf
	and icount
	sta icount
	lax $2002
	and #$40
	ora icount
	sta icount	;copy over sprite 0 hit flag
	txa
	bpl :+
		jsr ppu2002r
	:
	lda ppustat	;reset 2005/2006 flipflop
	and #$bf
	sta ppustat
	tya
	and #$e3
	ora #$0c	;force all opcodes to be absolute
	sta ramloc+0
	lda reg_p
	tax
	ora #$04	;no IRQs allowed
	pha
	txa
	and #$04
	sta reg_p	;blow away all the bits in P except I
	ldx reg_x
	ldy reg_y
	lda reg_a
	plp
	jsr ramloc	;execute formed instruction
	php
	sta reg_a
	sty reg_y
	stx reg_x
	pla
	and #$fb	;strip IRQ flag
	ora reg_p
	sta reg_p	;OR new bits on
	lda #$7f
	and icount
	sta icount	;clear that flag
	jmp edone

;----------------------------------------------------------------------
;PPU register 2005h
ppu2005x:
	lda #>(p2005+0)
	sta ramloc+2		;store upper 8 bits of pointer
	bit ppustat
	bvc p2005l		;check bit state
	lda #<(p2005+1)
	sta ramloc+1
	lda ppustat
	and #$bf
	sta ppustat
	jmp idone

p2005l:
	lda #<(p2005+0)
	sta ramloc+1
	lda ppustat
	ora #040h
	sta ppustat
	jmp idone

;----------------------------------------------------------------------
;PPU register 2006h
ppu2006x:
	bit ppustat
	bvs p2006l	;check bit state

	lda #<(ramloc+0)
	sta ramloc+1
	lda #>(ramloc+0)
	sta ramloc+2
	tya
	and #$e3
	ora #$0c	;force all opcodes to be absolute
	sta ramloc+0
	ldx reg_x
	ldy reg_y
	lda reg_a
	jsr ramloc	;execute formed instruction
	sta reg_a
	sty reg_y
	stx reg_x

	lda #$3f	;port chip code
	sta p2006hi	;#
	lda ramloc+0	;#
	and #$3f	;#
	ora #$80	;#
	sta p2006hi	;#

.ifdef PARALLELPORT
	;lda #$40	;RAM code
	;and p2006hi	;#
	;sta p2006hi	;#
	;lda ramloc+0	;#
	;and #$3f	;#
	;ora p2006hi	;#
	;sta p2006hi	;#
.endif

	lda #$40	;set bit we'll check
	ora ppustat
	sta ppustat
	jmp edone

p2006l:
	lda #<(p2006lo)
	sta ramloc+1
	lda #>(p2006lo)
	sta ramloc+2
	lda ppustat
	and #$bf
	sta ppustat
	jmp idone

;----------------------------------------------------------------------
;PPU register 2007h
ppu2007x:
	lda #$18
	bit ppustat	;check state of PPU to see if rendering
	beq :++		;nope, so we're free to read/write
		:
			bit $2002	;wait for PPU to be ready
		bpl :-
	:
	lda p2006hi	;write new address
	sta $2006
	lda p2006lo
	sta $2006
	lda #$04
	bit ppustat
	beq :+		;perform increment (by 1 or by 32)
		lda #$20
		.byte $2c
	:
	lda #$01
	clc
	adc p2006lo
	sta p2006lo
	bcs :+
		jmp noi2006
	:

.ifdef PARALLELPORT
	;lda p2006hi	;code for RAM use
	;tax		;#
	;and #$40	;#
	;sta p2006hi	;#
	;txa		;#
	;adc #$00	;#
	;and #$3f	;#
	;ora p2006hi	;#
	;sta p2006hi	;#
.endif

	lda p2006hi	;code for port chip use
	ldx #$3f	;#
	stx p2006hi	;# clear lower 6 bits only
	adc #$00	;# add on upper bit
	and #$3f	;# strip middle bit
	ora #$80
	sta p2006hi

noi2006:
	tya
	and #$20	;check to see if this is a load or store
	beq p2007w	;store
	lda ppustat	;see if this is the first load
	lsr a
	bcc fload	;yep
	ldx $2007	;do load, this isn't the first time
	sec
	rol a		;set bit
	sta ppustat
	bne fload	;shifted in carry = always nonzero

p2007w:
	lda ppustat	;writing... reset flag
	and #$fe
	sta ppustat

fload:
	tya		;do the read/write on $2007
	and #$e3
	ora #$0c	;force all opcodes to be absolute
	sta ramloc+0
	lda reg_p
	tax
	ora #$04	;no IRQs allowed
	pha
	txa
	and #$04
	sta reg_p	;blow away all the bits in P except I
	ldx reg_x
	ldy reg_y
	lda reg_a
	plp
	jsr ramloc	;execute formed instruction
	php
	sta reg_a
	sty reg_y
	stx reg_x
	pla
	and #$fb	;strip IRQ flag
	ora reg_p
	sta reg_p	;OR new bits on
	lda p2005+0
	sta $2005
	lda p2005+1	;reload 2005/2000
	sta $2005
	lda icount
	and #$3f
	sta $2000
	jmp edone

;----------------------------------------------------------------------
;wait for PPU vblank & restore registers
ppuwait:
	lda #$20
	bit ppustat
	beq :++		;if clear, don't worry about PPU waits
		:
			bit $2002
		bpl :-

ppu2002r:	lda p2005+0
		sta $2005
		lda p2005+1
		sta $2005
		lda p2006hi
		sta $2006
		lda p2006lo
		sta $2006
		lda icount
		and #$3f
		sta $2000
	:
	rts


;------------------------------
;grab data from PC and inc

;reload LDA opcode and grab byte from RAM and inc PC
pcfetch2:
	lda #$ad
	sta ramloc+0

;same as below, but clear carry here to save bytes later
pcfetch7:
	clc
;grab byte from RAM and inc PC
pcfetch:
	lda reg_pcl
	sta ramloc+1
	lda reg_pch
	sta ramloc+2
	inc reg_pcl
	bne :+
		inc reg_pch
	:
	jmp ramloc

;PC fetch for absolute stuff
pcfetch4:
	lda reg_pcl
	sta ramloc+1
	lda reg_pch
	sta ramloc+2
	jmp ramloc

pcfetch5:
	tax
	inc reg_pcl
	inc ramloc+1
	bne :+
		inc reg_pch
		inc ramloc+2
	:
	jmp ramloc

pcfetch6:
	sta ramloc+2
	stx ramloc+1
	inc reg_pcl
	bne :+
		inc reg_pch
	:
	clc		;clear this for later
	rts

;handle page crossings
pagecross:
	inc ramloc+2
pagecross2:
	lda cyclecount+0
	ora cyclecount+1
	beq :++
		lda cyclecount+0
		bne :+
			dec cyclecount+1
		:
		dec cyclecount+0
	:
	rts

;---------------------------------
;stack stuff

;push acc onto stack safely
safepush:
	ldx reg_s
	sta $100,x
	dex
	cpx #$ff
	bne :+
		ldx #topostack
	:
	stx reg_s
	rts

;----------
;pop acc from stack safely
safepop:
	ldx reg_s
	cpx #topostack
	bne :+
		ldx #$ff
	:
	inx
	stx reg_s
	lda $100,x
	rts


;0  - emulate 1 instruction at the current PC
;1  - load registers
;2  - read registers
;3  - disassemble (no invalid opcodes)
;4  - dump address space
;5  - read back PC
;6  - write new PC
;7  - do disassembly with invalid opcodes
;8  - perform NMI
;9  - perform reset
;A  - perform IRQ
;B  - write byte to address space
;C  - grab bank data
;D  - execute to breakpoint
;E  - set emulation mode flags


	jmp mainx

emustrt:
	ldx #realstack
	txs

	lda $fffc
	sta reg_pcl
	lda $fffd
	sta reg_pch


	lda #$00
	sta reg_a
	sta reg_x
	sta reg_y
	sta reg_p
	sta brkpt+0
	sta brkpt+1
	lda #topostack
	sta reg_s	;load emulator variables

	lda #$22
	sta ppustat

	lda #$7f	;make it run continuously
	sta p2006hi

	jmp emul8

main2:
	lda $fffc
	sta reg_pcl
	lda $fffd
	sta reg_pch

	lda #<(vblank)	;set up cycle count for vblank
	sta cyclecount+0
	lda #>(vblank)
	sta cyclecount+1
	lda #$00
	sta nothreg1	;bit 6 holds PPU mode (0 = vbl, 1 = rendering)
	lda #$22
	sta ppustat

	lda #$00
	sta reg_a
	sta reg_x
	sta reg_y
	lda #$34
	sta reg_p
	lda #topostack
	sta reg_s	;load emulator variables

	ldx #realstack
	txs

mainx:
	jsr read_byte2		;wait for PC to send something
	and #$0f
	asl a
	tax
	lda wheretab+0,x
	sta ramloc+1
	lda wheretab+1,x
	sta ramloc+2
	jmp (ramloc+1)

wheretab:
	.word emulate,loadregs,readregs,dodis	;0 1 2 3
	.word dump,rdpc,wrpc,dodis2		;4 5 6 7
	.word donmi,dorst,doirq,wbyte		;8 9 A B
	.word gbanks,go2brk,setmode,mainx	;C D E F

setmode:
	jsr read_byte2
	and #$22	;only allow updating 2 bits
	sta ramloc+0
	lda ppustat
	and #$dd
	ora ramloc+0
	sta ppustat
	jmp mainx

gbanks:
	lda #$ad
	sta ramloc+0
	lda #$80
	sta ramloc+1
	sta ramloc+2

	ldy #$20
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		jsr write_byte2
		lda #$04
		clc
		adc ramloc+1
		sta ramloc+1
		sta ramloc+2
		dey
	bne :-			;write out 32 bytes of PRG ROM

	ldy #$1f
	:
		sty $2006
		sty $2006
		lda $2007
		lda $2007
		jsr write_byte2	;write out 32 bytes of CHR ROM
		dey
	bpl :-
	jmp mainx

wbyte:
	jsr read_byte2
	sta ramloc+1
	jsr read_byte2
	sta ramloc+2
	jsr read_byte2
	ldx #$8d
	stx ramloc+0
	ldx #$60
	stx ramloc+3
	jsr ramloc	;write byte out
	jmp mainx

dorst:
	ldy #$fc
	lda #$04
	ora reg_p
	sta reg_p
	bne genirq

doirq:
	ldy #$fe
	lda #$04
	ora reg_p
	sta reg_p	;set I flag
	bne genirq

donmi:
	ldy #$fa

genirq:
	lda reg_pch
	jsr safepush
	lda reg_pcl
	jsr safepush
	lda reg_p
	ora #$30
	jsr safepush
	lda $ff00,y	;get new address
	sta reg_pcl
	lda $ff01,y
	sta reg_pch
	jmp mainx

rdpc:
	lda reg_pcl
	jsr write_byte2
	lda reg_pch
	jsr write_byte2
	jmp mainx

wrpc:
	jsr read_byte2
	sta reg_pcl
	jsr read_byte2
	sta reg_pch
	jmp mainx

dump:
	jsr read_byte2
	sta ramloc+1
	jsr read_byte2
	sta ramloc+2
	jsr read_byte2
	tay
	lda #$ad
	sta ramloc+0
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		jsr write_byte2
		inc ramloc+1
		bne :+
			inc ramloc+2
		:
		dey
	bne :--
	jmp mainx

;store register set from PC into emulator
loadregs:
	ldy #0
	:
		jsr read_byte2
		sta reg_a,y
		iny
		cpy #$07
	bne :-
	jsr read_byte2
	sta brkpt+0
	jsr read_byte2
	sta brkpt+1
	jmp mainx

;read back register set from PC into emulator
readregs:
	ldy #0
	:
		lda reg_a,y
		jsr write_byte2
		iny
		cpy #$07
	bne :-
	lda brkpt+0
	jsr write_byte2
	lda brkpt+1
	jsr write_byte2
	lda cyclecount+0	;write out cycle count
	jsr write_byte2
	lda cyclecount+1
	jsr write_byte2
	lda nothreg1
	jsr write_byte2
	jmp mainx

;figure out where disassembly should start by counting bytes in front of
;current disassembly position
dodis:
	lda #$ad	;LDA abs
	sta ramloc+0

	lda reg_pcl
	sec
	sbc #$3f	;points to PC-40h
	sta ramloc+1
	ldx reg_pch
	bcs :+
		dex
	:
	stx ramloc+2	;make LDA abs,y instruction

	ldy #$00
	ldx #$00	;# of entries
	:
		lda #$60	;rts
		sta ramloc+3
		jsr ramloc	;calculated LDA abs,y : RTS
		stx ramloc+3
		tax
		tya
		sec
		adc insize,x
		tay
		sec
		lda ramloc+1
		adc insize,x
		sta ramloc+1
		bcc :+
			inc ramloc+2
		:
		ldx ramloc+3
		inx
		cpy #$3f
	bcc :--
	txa
	sbc #$08	;go back 8 entries (note: carry will be set)
	tax

	lda reg_pcl
	sec
	sbc #$3f	;point to PC-$40
	sta ramloc+1
	ldy reg_pch
	bcs :+
		dey
	:
	sty ramloc+2	;make LDA abs,y instruction

	ldy #$00
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		stx ramloc+3
		tax
		tya
		sec
		adc insize,x
		tay
		sec
		lda ramloc+1
		adc insize,x
		sta ramloc+1
		bcc :+
			inc ramloc+2
		:
		ldx ramloc+3
		dex
	bne :--		;get us where we wanna go
	tya
	eor #$ff
	clc
	adc #$40	;-Y+$3f
	jsr write_byte2
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		jsr write_byte2
		inc ramloc+1
		bne :+
			inc ramloc+2
		:
		iny
		cpy #$3f
	bcc :--		;send out bytes up to current PC

;--- send out data at PC down to 8 instructions

	lda reg_pcl
	sta ramloc+1
	lda reg_pch
	sta ramloc+2	;get current PC
	ldy #$08
;	lda #$ad
;	sta ramloc+0	;change to LDA instruction
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		jsr write_byte2	;opcode
		lda #$60
		sta ramloc+3
		jsr ramloc
		tax
		inc ramloc+1
		bne :+
			inc ramloc+2
		:
		lda insize,x
		tax
		inx
		txa
		stx ramloc+0
		jsr write_byte2	;size
		ldx ramloc+0
		lda #$ad
		sta ramloc+0
		dex
		beq :+++
			:
				lda #$60
				sta ramloc+3
				jsr ramloc
				stx ramloc+0
				jsr write_byte2	;byte 1/2 (if used)
				ldx ramloc+0
				lda #$ad
				sta ramloc+0
				inc ramloc+1
				bne :+
					inc ramloc+2
				:
				dex
			bne :--			;sent all bytes
		:
		dey
	bne :-----
	lda #$69
	jsr write_byte2
	jmp mainx


;second copy that uses invalid opcodes

dodis2:
	lda #$ad	;LDA abs
	sta ramloc+0

	lda reg_pcl
	sec
	sbc #$3f	;points to PC-40h
	sta ramloc+1
	ldx reg_pch
	bcs :+
		dex
	:
	stx ramloc+2	;make LDA abs,y instruction

	ldy #$00
	ldx #$00	;# of entries
	:
		lda #$60	;rts
		sta ramloc+3
		jsr ramloc	;calculated LDA abs,y : RTS
		stx ramloc+3
		tax
		tya
		sec
		adc insize2,x
		tay
		sec
		lda ramloc+1
		adc insize2,x
		sta ramloc+1
		bcc :+
			inc ramloc+2
		:
		ldx ramloc+3
		inx
		cpy #$3f
	bcc :--
	txa
	sbc #$08	;go back 8 entries (note: carry will be set)
	tax

	lda reg_pcl
	sec
	sbc #$3f	;point to PC-$40
	sta ramloc+1
	ldy reg_pch
	bcs :+
		dey
	:
	sty ramloc+2	;make LDA abs,y instruction

	ldy #$00
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		stx ramloc+3
		tax
		tya
		sec
		adc insize2,x
		tay
		sec
		lda ramloc+1
		adc insize2,x
		sta ramloc+1
		bcc :+
			inc ramloc+2
		:
		ldx ramloc+3
		dex
	bne :--		;get us where we wanna go
	tya
	eor #$ff
	clc
	adc #$40	;-Y+$3f
	jsr write_byte2
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		jsr write_byte2
		inc ramloc+1
		bne :+
			inc ramloc+2
		:
		iny
		cpy #$3f
	bcc :--		;send out bytes up to current PC

;--- send out data at PC down to 8 instructions

	lda reg_pcl
	sta ramloc+1
	lda reg_pch
	sta ramloc+2	;get current PC
	ldy #$08
;	lda #$ad
;	sta ramloc+0	;change to LDA instruction
	:
		lda #$60
		sta ramloc+3
		jsr ramloc
		jsr write_byte2	;opcode
		lda #$60
		sta ramloc+3
		jsr ramloc
		tax
		inc ramloc+1
		bne :+
			inc ramloc+2
		:
		lda insize2,x
		tax
		inx
		txa
		stx ramloc+0
		jsr write_byte2	;size
		ldx ramloc+0
		lda #$ad
		sta ramloc+0
		dex
		beq :+++
			:
				lda #$60
				sta ramloc+3
				jsr ramloc
				stx ramloc+0
				jsr write_byte2	;byte 1/2 (if used)
				ldx ramloc+0
				lda #$ad
				sta ramloc+0
				inc ramloc+1
				bne :+
					inc ramloc+2
				:
				dex
			bne :--			;sent all bytes
		:
		dey
	bne :-----
	lda #$69
	jsr write_byte2
	jmp mainx

;---------------------
;I/O routines
.ifdef PARALLELPORT
read_byte2:
	lda #$00
	sta port+$03	;set_in
	:
		nop
		nop
		nop
		nop
		lda port+$00
		nop
		nop
		nop
		nop
		cmp port+$00	;catch noise
	bne :-
	nop
	nop
	nop
	nop
	tax
	eor emutemp
	and #$40
	beq read_byte2	;wait for state change
	stx emutemp
	nop
	nop
	nop
	nop
	ldx port+$01
	lda port+$00
	eor #$10
	sta port+$00	;write "got byte"
	txa
	rts

write_byte2:
	sta port+$01
	lda #$ff
	sta port+$03	;set_out
	nop
	nop
	nop
	nop
	:
		lda port+$00
		sta ramloc+3
		nop
		nop
		nop
		nop
		cmp port+$00
	bne :-
	eor #$20
	sta port+$00	;toggle "byte ready"
	nop
	nop
	nop
	nop
	:
		lda port+$00	;loading data port
		eor ramloc+3
		and #$80
	beq :-			;wait for state change
		nop
		nop
		nop
		nop
		lda port+$00
		eor ramloc+3
		and #$80
	beq :-			;make sure
	lda #$00
	sta port+$03	;direction change
	rts
.else
read_byte2:
read_byte:
	lda #$00
	sta port+$03	;set 6522 data port to input mode
	:
		lda port+$00	;load control bus
		and #$20
	bne :-			;make sure read enabled /RXE D5 = 0

	lda port+$00	;load control bus
	and #$EF	;set read /RD D4 = 0
	sta port+$00	;store new control bus

	ldx port+$01	;read data bus

	lda port+$00	;load control bus
	ora #$10	;set read /RD D4 = 1
	sta port+$00	;store new control bus

	txa	;put new data in a
	rts

write_byte2:
write_byte:
	sta port+$01	;set data bus
	lda #$ff
	sta port+$03	;set 6522 data port to output mode
	:
		lda port+$00	;load control bus
		and #$80
	bne :-			;make sure read enabled /TXE D7 = 0

	lda port+$00	;load control bus
	ora #$04
	sta port+$00	;set write WR D2 = 1

	lda port+$00	;load control bus
	and #$fb
	sta port+$00	;set write WR D2 = 0

	lda #$00
	sta port+$03	;set 6522 data port to input mode
	rts

init_port:
	lda #$00
	sta port+$0b		;ACR register timer disabled

	lda #$ff
	sta port+$0c		;PCR register
	sta port+$01		;set data bus

	lda #$fa		;carten=0, wr=0			1111 1010
	sta port+$00		;set control port data

	lda #$1f		;				7654 3210	0=in  1=out
	sta port+$02		;set control port DIRECTION	0001 1111
								;D7 in = /TXE
								;D6 in = PLAY/COPY
								;D5 in = /RXE
								;D4 out = /RD
								;D3 out = EXP0
								;D2 out = WR
								;D1 out = enable/disable bios
								;D0 out = enable/disable cart

	lda #$00
	sta port+$03		;set data to input mode
	rts

.endif

;---------------------------------------------------------
;Subroutines
;---------------------------------------------------------
.segment "SUBROUTINE"
ram_dat:
	lda #$fc	;disabled decoder totally
	sta port+$00	;turning off bios - control D1=0 D0=0
	jmp ($fffc)	;reset vector

but_wait:
	jsr read_it
	beq but_wait
	rts

read_it:
	ldx #9
	stx $4016
	dex
	stx $4016

	:
		lda $4016
		ror a
		rol joy_pad
		dex
	bne :-
	lda joy_pad
	cmp old_but
	beq :+
		sta old_but
		ora #0
		rts
	:
	lda #0
	rts

wait_vbl:
	tay
	:
		lda $2002
	bpl :-
		jsr read_it
		bne :+
		dey
	bne :-
	
	:
	rts

read_pack:
	ldy #0

	:
		jsr read_byte
		sta addl,y
		iny
		cpy #4
	bne :-
	rts

.ifdef PARALLELPORT
read_byte:
	lda port+$00
	tax
	eor temp_byte
	and #$40
	beq read_byte
	stx temp_byte
	ldx port+$01
	lda port+$00
	eor #$10
	sta port+$00
	txa
	rts

write_byte:
	stx temp_x
	sta port+$01
	jsr set_out
	lda port+$00
	sta temp
	eor #$20
	sta port+$00
	ldx #$00
	:
		lda port+$00
		eor temp
		and #$80
		beq :+
			ldx temp_x
			rts
		:
		dex
	bne :--
	beq :--
	ldx temp_x
	rts

init_port:
	lda #$00
	sta port+$0b		;ACR register timer disabled

	lda #$ff
	sta port+$0c		;PCR register
	sta port+$01		;set data bus

	lda #$fe		;carten=0, wr=0			1111 1110
	sta port+$00		;set control port data

	lda #$3f		;				7654 3210	0=in  1=out
	sta port+$02		;set control port DIRECTION	0011 1111
								;D7 in = write handshake
								;D6 in = PLAY/COPY
								;D5 out = read handshake
								;D4 out = read handshake
								;D3 out = lcd rs
								;D2 out = EXP0
								;D1 out = enable/disable bios
								;D0 out = enable/disable cart

	lda #$ff
	sta port+$03		;set data to input mode
	rts

cart_on:
	lda #$fe	;enabling cart D0=0
	sta port+$00
	rts

cart_off:
	lda #$ff	;disabling cart D0=1
	sta port+$00
	rts
.endif

init_ppu:
	lda #0
	sta $2000
	sta $2001	;turn off PPU

:	lda $2002
	bpl :-
:	lda $2002
	bpl :-		;wait 2 screens
	rts

.IFDEF PARALLELPORT
sho_hex:
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	jsr sho_nyb
	pla

sho_nyb:
	and #$0f
	tax
	lda hex_tab,x
	jmp lcd_char

hex_tab:
	.byte "0123456789ABCDEF"

baton:	
	;rts

	stx temp_x
	inc baton_c
	lda #3
	and baton_c
	tax
	lda #$c7
	jsr lcd_ins
	lda baton_d,x
	jsr lcd_dat
	ldx temp_x
	rts

baton_d:
	.byte $7C, $2F, $2D, $08	;"|/-\"

.ELSE
baton:
	rts		;removed lcd code	;;TODO - Get source code of parallel port copynes, for inclusion as a DEFINE.
.ENDIF

set_in:
	lda #$00	;set data port to all inputs
	sta port+$03
	rts

set_out:
	lda #$ff	;set data port to all outputs
	sta port+$03
	rts

.IFDEF PARALLELPORT

init_lcd:
	lda #$38
	jsr lcd_ins
	lda #$0c
	jmp lcd_ins

lcd_clr:
	lda #0
	sta char_ctr
	lda #1
	jsr lcd_ins
	jsr ld_loop
	jsr ld_loop
	jsr ld_loop
	jmp ld_loop	;extra delay for screen clearing

lcd_char:
	pha
	inc char_ctr
	lda char_ctr
	cmp #9
	bne :+
		lda #$c0
		jsr lcd_ins
		jmp :++
	:
	cmp #$11
	bne :+
		lda #0
		sta char_ctr
		lda #$80
		jsr lcd_ins
	:
	pla

lcd_dat:
	sta port+$01	;write data
	lda port+$00	;get status
	ora #$08
	sta port+$00	;turn lcd rs = 1
	and #$fb
	sta port+$00	;lcd /enable = 0
	ora #$04
	sta port+$00	;lcd /enable = 1
	bne l_dlay

lcd_ins:
	sta port+$01	;write_data
	lda port+$00	;get status
	and #$f7
	sta port+$00	;lcd rs = 0
	and #$fb
	sta port+$00	;lcd /enable = 0
	ora #$04
	sta port+$00	;lcd /enable = 1

l_dlay:
	lda #40
	sec

ld_loop:
	sbc #1
	bcs ld_loop
	rts

sho_msg:
	asl a
	tax
	lda msgs,x
	sta c
	inx
	lda msgs,x
	sta b		;get message pointer
	ldy #0
	:
		lda (bc),y
		bne :+
			rts
		:
		cmp #'~'
		bne :+
			jsr lcd_clr
			jmp :++
		:
			jsr lcd_char
		:
		iny
	bne :----
	rts

int_err:
	sei
	lda #0
	sta $2000
	sta $2001
	sta $4015
	sta $4017
	lda #2
	jsr sho_msg
	:
	jmp :-

load_chars:
	ldx #0
	lda #$40
	jsr lcd_ins
	:
		lda cchar,x
		jsr lcd_dat
		inx
		cpx #8
	bne :-
	lda #$80
	jsr lcd_ins
	rts

msgs:
	.word msg_0,msg_1,msg_2,msg_3,msg_4,msg_5,msg_6
	.word msg_7,msg_8

msg_0:		 ;0123456789ABCDEF
	.asciiz "~CopyNES by K.H. "
msg_1:
	.asciiz "~ A-Copy, B-Play "
msg_2:
	.asciiz "~INTERRUPT!"
msg_3:
	.asciiz "~  Playing Cart"
msg_4:		 ;0123456789ABCDEF
	.asciiz "~Waiting for Host"
msg_5:
	.asciiz "~Transferring..."
msg_6:
	.asciiz "~Transfer Done!"
msg_7:
	.asciiz "~Playing "
msg_8:
	.asciiz " of "
		 ;0123456789ABCDEF

.ELSE

nmi:	inc nmicounter
	rti

irq:	inc irqcounter
	rti

.ENDIF

chk_vram:
	lda #0
	jsr wr_ppu
	lda #$55
	sta $2007
	lda #$aa
	sta $2007
	lda #0
	jsr wr_ppu
	lda $2007
	lda $2007
	cmp #$55
	bne :+
		lda $2007
		cmp #$aa
	bne :+
		lda #0
		jsr wr_ppu
		lda #$aa
		sta $2007
		lda #0
		jsr wr_ppu
		lda $2007
		lda $2007
		cmp #$aa
	:
	rts

wr_ppu:
	sta $2006
	lda #0
	sta $2006
	rts

chk_wram:
	lda $6000
	sta temp1_hi
	lda $6080
	sta temp1_lo
	lda #$55
	sta $6000
	eor #$ff
	sta $6080

	ldy $6000
	ldx $6080
	lda temp1_hi
	sta $6000
	lda temp1_lo
	sta $6080
	cpy #$55
	bne :+
		cpx #$aa
	bne :+

		lda #$aa
		sta $6000
		eor #$ff
		sta $6080
		ldy $6000
		ldx $6080
		lda temp1_hi
		sta $6000
		lda temp1_lo
		sta $6080
		cpy #$aa
	bne :+
		cpx #$55
	bne :+
	:
	rts

vec_tab:
	.word write_byte, baton, chk_vram, chk_wram
	.word wr_ppu, read_byte, init_crc, do_crc
	.word finish_crc
	.word $ffff

.ifdef PARALLELPORT
cchar:
	.byte $00	;        ;
	.byte $10	;   #    ;
	.byte $08	;    #   ;
	.byte $04	;     #  ;
	.byte $02	;      # ;
	.byte $01	;       #;
	.byte $00	;        ;
	.byte $00	;        ;
.endif

init_crc:
	lda #$ff
	sta crc0
	sta crc1
	sta crc2
	sta crc3
	rts

do_crc:
	eor crc0	;xor with first CRC
	tax		;to get table entry
	lda crc_tab0,x
	eor crc1
	sta crc0
	lda crc_tab1,x
	eor crc2
	sta crc1
	lda crc_tab2,x
	eor crc3
	sta crc2
	lda crc_tab3,x
	sta crc3
	rts

finish_crc:
	ldx #3
	:
		lda #$ff
		eor crc0,x
		sta crc0,x
		dex
	bpl :-
	rts

identify2:
	jsr set_out
	lda #COPYNESVER
	jsr write_byte
	jmp main

identify:
	ldy #$00
	jsr set_out
	:
		lda footer_start,y
		jsr write_byte
		iny
		cpy #(footer_end-footer_start)
	bne :-
	jmp main

;----------------------------------------------------------------
;make sure these tables are page-aligned

;make sure it takes up a page on its own to prevent page cross slowdown
;size of each instruction, in bytes
.align 256

insize:
	.byte 1,1,0,0,0,1,1,0,0,1,0,0,0,2,2,0
	.byte 1,1,0,0,0,1,1,0,0,2,0,0,0,2,2,0
	.byte 2,1,0,0,1,1,1,0,0,1,0,0,2,2,2,0
	.byte 1,1,0,0,0,1,1,0,0,2,0,0,0,2,2,0
	.byte 0,1,0,0,0,1,1,0,0,1,0,0,2,2,2,0
	.byte 1,1,0,0,0,1,1,0,0,2,0,0,0,2,2,0
	.byte 0,1,0,0,0,1,1,0,0,1,0,0,2,2,2,0
	.byte 1,1,0,0,0,1,1,0,0,2,0,0,0,2,2,0
	.byte 0,1,0,0,1,1,1,0,0,0,0,0,2,2,2,0
	.byte 1,1,0,0,1,1,1,0,0,2,0,0,0,2,0,0
	.byte 1,1,1,0,1,1,1,0,0,1,0,0,2,2,2,0
	.byte 1,1,0,0,1,1,1,0,0,2,0,0,2,2,2,0
	.byte 1,1,0,0,1,1,1,0,0,1,0,0,2,2,2,0
	.byte 1,1,0,0,0,1,1,0,0,2,0,0,0,2,2,0
	.byte 1,1,0,0,1,1,1,0,0,1,0,0,2,2,2,0
	.byte 1,1,0,0,0,1,1,0,0,2,0,0,0,2,2,0

;all the invalid opcodes enabled
insize2:
	.byte 1,1,0,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 2,1,0,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 0,1,0,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 0,1,0,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 0,1,0,1,1,1,1,1,0,0,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 1,1,1,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,1,0,1,2,2,2,2
	.byte 1,1,0,1,1,1,1,1,0,2,0,2,2,2,2,2

indx      := <(mode_indx)
indy      := <(mode_indy)
halt      := <(mode_halt)
zero      := <(mode_zero)
zerx      := <(mode_zerx)
zery      := <(mode_zery)
immd      := <(mode_immd)
impl      := <(mode_impl)
abso      := <(mode_abso)
absx      := <(mode_absx)
absy      := <(mode_absy)
bran      := <(mode_bran)
nop2      := <(mode_nop2)
nop3      := <(mode_nop3)

op00      := <(mode_op00)
op08      := <(mode_op08)
op20      := <(mode_op20)
op28      := <(mode_op28)
op40      := <(mode_op40)
op48      := <(mode_op48)
op4c      := <(mode_op4c)
op60      := <(mode_op60)
op68      := <(mode_op68)
op6c      := <(mode_op6c)
op58      := <(mode_op58)
op78      := <(mode_op78)
op9a      := <(mode_op9a)
opba      := <(mode_opba)


amode:
	.byte op00,indx,halt,indx,zero,zero,zero,zero,op08,immd,impl,immd,abso,abso,abso,abso
	.byte bran,indy,halt,indy,zerx,zerx,zerx,zerx,impl,absy,impl,absy,absx,absx,absx,absx
	.byte op20,indx,halt,indx,zero,zero,zero,zero,op28,immd,impl,immd,abso,abso,abso,abso
	.byte bran,indy,halt,indy,nop2,zerx,zerx,zerx,impl,absy,impl,absy,nop3,absx,absx,absx
	.byte op40,indx,halt,indx,nop2,zero,zero,zero,op48,immd,impl,immd,op4c,abso,abso,abso
	.byte bran,indy,halt,indy,nop2,zerx,zerx,zerx,op58,absy,impl,absy,nop3,absx,absx,absx
	.byte op60,indx,halt,indx,nop2,zero,zero,zero,op68,immd,impl,immd,op6c,abso,abso,abso
	.byte bran,indy,halt,indy,nop2,zerx,zerx,zerx,op78,absy,impl,absy,nop3,absx,absx,absx
	.byte immd,indx,halt,indx,zero,zero,zero,zero,impl,immd,impl,immd,abso,abso,abso,abso
	.byte bran,indy,halt,indy,zerx,zerx,zery,zery,impl,absy,op9a,absy,absx,absx,absy,absy
	.byte immd,indx,immd,indx,zero,zero,zero,zero,impl,immd,impl,immd,abso,abso,abso,abso
	.byte bran,indy,halt,indy,zerx,zerx,zery,zery,impl,absy,opba,absy,absx,absx,absy,absy
	.byte immd,indx,halt,indx,zero,zero,zero,zero,impl,immd,impl,immd,abso,abso,abso,abso
	.byte bran,indy,halt,indy,nop2,zerx,zerx,zerx,impl,absy,impl,absy,nop3,absx,absx,absx
	.byte immd,indx,halt,indx,zero,zero,zero,zero,impl,immd,impl,immd,abso,abso,abso,abso
	.byte bran,indy,halt,indy,nop2,zerx,zerx,zerx,impl,absy,impl,absy,nop3,absx,absx,absx

;cycle counts for the length of each instruction
cyctab:
	.byte 7,6,0,8,3,3,5,5,3,2,2,2,4,4,6,6
	.byte 2,5,0,7,4,4,6,6,2,4,2,4,4,4,7,7
	.byte 6,6,0,8,3,3,5,5,4,2,2,2,4,4,6,6
	.byte 2,5,0,7,4,4,6,6,2,4,2,4,4,4,7,7
	.byte 6,6,0,8,3,3,5,5,3,2,2,2,4,4,6,6
	.byte 2,5,0,7,4,4,6,6,2,4,2,4,4,4,7,7
	.byte 6,6,0,8,3,3,5,5,4,2,2,2,4,4,6,6
	.byte 2,5,0,7,4,4,6,6,2,4,2,4,4,4,7,7
	.byte 2,6,0,6,3,3,3,3,2,2,2,2,4,4,4,4
	.byte 2,6,0,5,4,4,4,4,2,4,2,4,4,4,4,4
	.byte 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4
	.byte 2,5,0,5,4,4,4,4,2,4,2,4,4,4,4,4
	.byte 2,6,0,8,3,3,5,5,2,2,2,2,4,4,6,6
	.byte 2,5,0,7,4,4,6,6,2,4,2,6,4,4,7,7
	.byte 2,6,0,8,3,3,5,5,2,2,2,2,4,4,6,6
	.byte 2,5,0,7,4,4,6,6,2,4,2,6,4,4,7,7

crc_tab0:
	.byte $00,$96,$2C,$BA,$19,$8F,$35,$A3,$32,$A4,$1E,$88,$2B,$BD,$07,$91
	.byte $64,$F2,$48,$DE,$7D,$EB,$51,$C7,$56,$C0,$7A,$EC,$4F,$D9,$63,$F5
	.byte $C8,$5E,$E4,$72,$D1,$47,$FD,$6B,$FA,$6C,$D6,$40,$E3,$75,$CF,$59
	.byte $AC,$3A,$80,$16,$B5,$23,$99,$0F,$9E,$08,$B2,$24,$87,$11,$AB,$3D
	.byte $90,$06,$BC,$2A,$89,$1F,$A5,$33,$A2,$34,$8E,$18,$BB,$2D,$97,$01
	.byte $F4,$62,$D8,$4E,$ED,$7B,$C1,$57,$C6,$50,$EA,$7C,$DF,$49,$F3,$65
	.byte $58,$CE,$74,$E2,$41,$D7,$6D,$FB,$6A,$FC,$46,$D0,$73,$E5,$5F,$C9
	.byte $3C,$AA,$10,$86,$25,$B3,$09,$9F,$0E,$98,$22,$B4,$17,$81,$3B,$AD
	.byte $20,$B6,$0C,$9A,$39,$AF,$15,$83,$12,$84,$3E,$A8,$0B,$9D,$27,$B1
	.byte $44,$D2,$68,$FE,$5D,$CB,$71,$E7,$76,$E0,$5A,$CC,$6F,$F9,$43,$D5
	.byte $E8,$7E,$C4,$52,$F1,$67,$DD,$4B,$DA,$4C,$F6,$60,$C3,$55,$EF,$79
	.byte $8C,$1A,$A0,$36,$95,$03,$B9,$2F,$BE,$28,$92,$04,$A7,$31,$8B,$1D
	.byte $B0,$26,$9C,$0A,$A9,$3F,$85,$13,$82,$14,$AE,$38,$9B,$0D,$B7,$21
	.byte $D4,$42,$F8,$6E,$CD,$5B,$E1,$77,$E6,$70,$CA,$5C,$FF,$69,$D3,$45
	.byte $78,$EE,$54,$C2,$61,$F7,$4D,$DB,$4A,$DC,$66,$F0,$53,$C5,$7F,$E9
	.byte $1C,$8A,$30,$A6,$05,$93,$29,$BF,$2E,$B8,$02,$94,$37,$A1,$1B,$8D
	
crc_tab1:
	.byte $00,$30,$61,$51,$C4,$F4,$A5,$95,$88,$B8,$E9,$D9,$4C,$7C,$2D,$1D
	.byte $10,$20,$71,$41,$D4,$E4,$B5,$85,$98,$A8,$F9,$C9,$5C,$6C,$3D,$0D
	.byte $20,$10,$41,$71,$E4,$D4,$85,$B5,$A8,$98,$C9,$F9,$6C,$5C,$0D,$3D
	.byte $30,$00,$51,$61,$F4,$C4,$95,$A5,$B8,$88,$D9,$E9,$7C,$4C,$1D,$2D
	.byte $41,$71,$20,$10,$85,$B5,$E4,$D4,$C9,$F9,$A8,$98,$0D,$3D,$6C,$5C
	.byte $51,$61,$30,$00,$95,$A5,$F4,$C4,$D9,$E9,$B8,$88,$1D,$2D,$7C,$4C
	.byte $61,$51,$00,$30,$A5,$95,$C4,$F4,$E9,$D9,$88,$B8,$2D,$1D,$4C,$7C
	.byte $71,$41,$10,$20,$B5,$85,$D4,$E4,$F9,$C9,$98,$A8,$3D,$0D,$5C,$6C
	.byte $83,$B3,$E2,$D2,$47,$77,$26,$16,$0B,$3B,$6A,$5A,$CF,$FF,$AE,$9E
	.byte $93,$A3,$F2,$C2,$57,$67,$36,$06,$1B,$2B,$7A,$4A,$DF,$EF,$BE,$8E
	.byte $A3,$93,$C2,$F2,$67,$57,$06,$36,$2B,$1B,$4A,$7A,$EF,$DF,$8E,$BE
	.byte $B3,$83,$D2,$E2,$77,$47,$16,$26,$3B,$0B,$5A,$6A,$FF,$CF,$9E,$AE
	.byte $C2,$F2,$A3,$93,$06,$36,$67,$57,$4A,$7A,$2B,$1B,$8E,$BE,$EF,$DF
	.byte $D2,$E2,$B3,$83,$16,$26,$77,$47,$5A,$6A,$3B,$0B,$9E,$AE,$FF,$CF
	.byte $E2,$D2,$83,$B3,$26,$16,$47,$77,$6A,$5A,$0B,$3B,$AE,$9E,$CF,$FF
	.byte $F2,$C2,$93,$A3,$36,$06,$57,$67,$7A,$4A,$1B,$2B,$BE,$8E,$DF,$EF

crc_tab2:
	.byte $00,$07,$0E,$09,$6D,$6A,$63,$64,$DB,$DC,$D5,$D2,$B6,$B1,$B8,$BF
	.byte $B7,$B0,$B9,$BE,$DA,$DD,$D4,$D3,$6C,$6B,$62,$65,$01,$06,$0F,$08
	.byte $6E,$69,$60,$67,$03,$04,$0D,$0A,$B5,$B2,$BB,$BC,$D8,$DF,$D6,$D1
	.byte $D9,$DE,$D7,$D0,$B4,$B3,$BA,$BD,$02,$05,$0C,$0B,$6F,$68,$61,$66
	.byte $DC,$DB,$D2,$D5,$B1,$B6,$BF,$B8,$07,$00,$09,$0E,$6A,$6D,$64,$63
	.byte $6B,$6C,$65,$62,$06,$01,$08,$0F,$B0,$B7,$BE,$B9,$DD,$DA,$D3,$D4
	.byte $B2,$B5,$BC,$BB,$DF,$D8,$D1,$D6,$69,$6E,$67,$60,$04,$03,$0A,$0D
	.byte $05,$02,$0B,$0C,$68,$6F,$66,$61,$DE,$D9,$D0,$D7,$B3,$B4,$BD,$BA
	.byte $B8,$BF,$B6,$B1,$D5,$D2,$DB,$DC,$63,$64,$6D,$6A,$0E,$09,$00,$07
	.byte $0F,$08,$01,$06,$62,$65,$6C,$6B,$D4,$D3,$DA,$DD,$B9,$BE,$B7,$B0
	.byte $D6,$D1,$D8,$DF,$BB,$BC,$B5,$B2,$0D,$0A,$03,$04,$60,$67,$6E,$69
	.byte $61,$66,$6F,$68,$0C,$0B,$02,$05,$BA,$BD,$B4,$B3,$D7,$D0,$D9,$DE
	.byte $64,$63,$6A,$6D,$09,$0E,$07,$00,$BF,$B8,$B1,$B6,$D2,$D5,$DC,$DB
	.byte $D3,$D4,$DD,$DA,$BE,$B9,$B0,$B7,$08,$0F,$06,$01,$65,$62,$6B,$6C
	.byte $0A,$0D,$04,$03,$67,$60,$69,$6E,$D1,$D6,$DF,$D8,$BC,$BB,$B2,$B5
	.byte $BD,$BA,$B3,$B4,$D0,$D7,$DE,$D9,$66,$61,$68,$6F,$0B,$0C,$05,$02

crc_tab3:
	.byte $00,$77,$EE,$99,$07,$70,$E9,$9E,$0E,$79,$E0,$97,$09,$7E,$E7,$90
	.byte $1D,$6A,$F3,$84,$1A,$6D,$F4,$83,$13,$64,$FD,$8A,$14,$63,$FA,$8D
	.byte $3B,$4C,$D5,$A2,$3C,$4B,$D2,$A5,$35,$42,$DB,$AC,$32,$45,$DC,$AB
	.byte $26,$51,$C8,$BF,$21,$56,$CF,$B8,$28,$5F,$C6,$B1,$2F,$58,$C1,$B6
	.byte $76,$01,$98,$EF,$71,$06,$9F,$E8,$78,$0F,$96,$E1,$7F,$08,$91,$E6
	.byte $6B,$1C,$85,$F2,$6C,$1B,$82,$F5,$65,$12,$8B,$FC,$62,$15,$8C,$FB
	.byte $4D,$3A,$A3,$D4,$4A,$3D,$A4,$D3,$43,$34,$AD,$DA,$44,$33,$AA,$DD
	.byte $50,$27,$BE,$C9,$57,$20,$B9,$CE,$5E,$29,$B0,$C7,$59,$2E,$B7,$C0
	.byte $ED,$9A,$03,$74,$EA,$9D,$04,$73,$E3,$94,$0D,$7A,$E4,$93,$0A,$7D
	.byte $F0,$87,$1E,$69,$F7,$80,$19,$6E,$FE,$89,$10,$67,$F9,$8E,$17,$60
	.byte $D6,$A1,$38,$4F,$D1,$A6,$3F,$48,$D8,$AF,$36,$41,$DF,$A8,$31,$46
	.byte $CB,$BC,$25,$52,$CC,$BB,$22,$55,$C5,$B2,$2B,$5C,$C2,$B5,$2C,$5B
	.byte $9B,$EC,$75,$02,$9C,$EB,$72,$05,$95,$E2,$7B,$0C,$92,$E5,$7C,$0B
	.byte $86,$F1,$68,$1F,$81,$F6,$6F,$18,$88,$FF,$66,$11,$8F,$F8,$61,$16
	.byte $A0,$D7,$4E,$39,$A7,$D0,$49,$3E,$AE,$D9,$40,$37,$A9,$DE,$47,$30
	.byte $BD,$CA,$53,$24,$BA,$CD,$54,$23,$B3,$C4,$5D,$2A,$B4,$C3,$5A,$2D

.segment "FOOTER"

footer_start:
.ifdef PARALLELPORT
COPYNESVER	:= $03
	.byte "Parallel Port CopyNES BIOS V3.01 (c) Kevin Horton    Built on 04.27.2014"
.else
COPYNESVER	:= $04
	.byte "USB CopyNES BIOS V4.01 (c) Kevin Horton & Brian Parker    Built on 04.27.2014"
.endif
	.asciiz " - Modified for CopyNES Blue"
footer_end:

.segment "VECTORS"
.ifdef PARALLELPORT
	.word int_err
	.word start
	.word int_err
.else
	.word nmi
	.word start
	.word irq
.endif